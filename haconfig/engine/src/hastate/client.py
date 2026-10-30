"""A WebSocket client for Home Assistant's API, with one request in flight at a time."""

from __future__ import annotations

import asyncio
import json
import ssl
from typing import Any
from urllib.parse import urlsplit, urlunsplit

import truststore
import websockets


class HAError(Exception):
    """HAError is a failed command, with HA's error code and message."""

    def __init__(self, command: str, code: str, message: str) -> None:
        super().__init__(f"{command}: {code}: {message}")
        self.command = command
        self.code = code
        self.message = message


class AuthError(Exception):
    """AuthError means HA rejected the access token."""


def websocket_url(url: str) -> str:
    """Return the WebSocket API URL for an HA base URL such as https://host:8123."""
    parts = urlsplit(url)
    scheme = {"https": "wss", "http": "ws", "wss": "wss", "ws": "ws"}.get(parts.scheme)
    if scheme is None or not parts.netloc:
        raise ValueError(f"not an http(s) URL: {url!r}")
    return urlunsplit((scheme, parts.netloc, parts.path.rstrip("/") + "/api/websocket", "", ""))


class Client:
    """Client sends commands over one authenticated connection.

    Use it as an async context manager. Each call waits for its own result
    and skips event messages, so callers never see two replies interleave.
    """

    def __init__(self, url: str, token: str, timeout: float = 60.0) -> None:
        self.url = url
        self._token = token
        self._timeout = timeout
        self._ws: Any = None
        self._id = 0
        self.ha_version = ""

    async def __aenter__(self) -> Client:
        target = websocket_url(self.url)
        context = truststore.SSLContext(ssl.PROTOCOL_TLS_CLIENT) if target.startswith("wss:") else None
        # Registry lists exceed the default 1 MiB message limit on large
        # instances, so the client accepts any size.
        self._ws = await websockets.connect(target, max_size=None, ssl=context, open_timeout=30)
        try:
            hello = json.loads(await self._ws.recv())
            if hello.get("type") != "auth_required":
                raise AuthError(f"unexpected greeting from {self.url}: {hello.get('type')!r}")
            self.ha_version = hello.get("ha_version", "")
            await self._ws.send(json.dumps({"type": "auth", "access_token": self._token}))
            reply = json.loads(await self._ws.recv())
            if reply.get("type") != "auth_ok":
                raise AuthError(f"{self.url} rejected the token: {reply.get('message', reply.get('type'))}")
        except BaseException:
            await self._ws.close()
            raise
        return self

    async def __aexit__(self, *exc: object) -> None:
        await self._ws.close()

    async def wait_closed(self, timeout: float) -> bool:
        """Wait until HA closes the connection, and return whether it did within TIMEOUT.

        The connection reads frames in the background, so it sees HA's close
        frame, or a missed keepalive when HA drops the socket, without a call.
        """
        try:
            async with asyncio.timeout(timeout):
                await self._ws.wait_closed()
        except TimeoutError:
            return False
        return True

    async def supervisor(self, method: str, endpoint: str, data: dict[str, Any] | None = None, timeout: float = 60.0) -> Any:
        """Call a Supervisor endpoint through HA's proxy and return its data.

        TIMEOUT bounds the Supervisor call, and the client waits a minute
        longer for HA's reply.
        """
        fields: dict[str, Any] = {"endpoint": endpoint, "method": method, "timeout": timeout}
        if data is not None:
            fields["data"] = data
        return await self.call("supervisor/api", wait=timeout + 60, **fields)

    async def call(self, command: str, /, *, wait: float | None = None, **fields: Any) -> Any:
        """Send COMMAND with FIELDS and return its result, or raise HAError.

        WAIT is how many seconds the call waits for the result. It is a
        separate name, because commands such as `supervisor/api` take a
        `timeout` field of their own.
        """
        self._id += 1
        msg_id = self._id
        await self._ws.send(json.dumps({"id": msg_id, "type": command, **fields}))
        async with asyncio.timeout(wait or self._timeout):
            while True:
                reply = json.loads(await self._ws.recv())
                if reply.get("id") == msg_id and reply.get("type") == "result":
                    break
        if not reply.get("success"):
            error = reply.get("error") or {}
            raise HAError(command, error.get("code", "unknown"), error.get("message", ""))
        return reply.get("result")
