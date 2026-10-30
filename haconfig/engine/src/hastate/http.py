"""Plan and apply HA's HTTP server config.

HA keeps the HTTP config in `.storage/http` with two slots. `stable` is the
config in use, and `pending` is a candidate that HA boots on once. The apply
stages the desired config as pending with `http/config/configure`, which
restarts HA. After HA boots on the pending config, the apply reconnects and
promotes it with `http/config/promote`. HA restores the stable config 5
minutes after that boot unless the apply promotes the pending one, so a
config that locks the engine out reverts on its own.
"""

from __future__ import annotations

import asyncio
import ipaddress
import ssl
import time
from collections.abc import Callable
from typing import Any
from urllib.parse import urlsplit, urlunsplit

from hastate.client import AuthError, Client
from hastate.model import Change, Live

HTTP = "http"
META = ("created_at", "error", "error_message")
"""The slot fields that are not config. HA rejects them in a configure request."""


def config_of(slot: dict[str, Any] | None) -> dict[str, Any]:
    """Return SLOT without its metadata fields."""
    return {k: v for k, v in (slot or {}).items() if k not in META}


def normalize(config: dict[str, Any]) -> dict[str, Any]:
    """Return CONFIG the way HA stores it, so equal configs compare equal.

    HA turns a scalar into a list for `server_host` and
    `cors_allowed_origins`, and stores each trusted proxy as a network in
    CIDR form, so `10.0.0.1` becomes `10.0.0.1/32`.
    """
    out = dict(config)
    for key in ("server_host", "cors_allowed_origins"):
        if isinstance(out.get(key), str):
            out[key] = [out[key]]
    if out.get("trusted_proxies") is not None:
        out["trusted_proxies"] = [str(ipaddress.ip_network(p, strict=True)) for p in out["trusted_proxies"]]
    return out


def effective(desired: dict[str, Any], default: dict[str, Any]) -> dict[str, Any]:
    """Return the config HA stores for DESIRED: HA's defaults, with every key DESIRED sets."""
    return normalize({**config_of(default), **{k: v for k, v in desired.items() if v is not None}})


def target_url(url: str, config: dict[str, Any]) -> str:
    """Return the URL HA answers on under CONFIG, with the host of URL.

    HA serves only HTTPS when the config holds a certificate, and only plain
    HTTP otherwise.
    """
    parts = urlsplit(url)
    scheme = "https" if config.get("ssl_certificate") else "http"
    port = config.get("server_port")
    netloc = parts.hostname or ""
    if ":" in netloc:
        netloc = f"[{netloc}]"
    if port and port != {"https": 443, "http": 80}[scheme]:
        netloc = f"{netloc}:{port}"
    return urlunsplit((scheme, netloc, parts.path, "", ""))


def direct(url: str, stable: dict[str, Any]) -> bool:
    """Report whether URL reaches HA's own HTTP server under the STABLE config, rather than a proxy in front of it."""
    return same_url(target_url(url, stable), url)


def next_url(url: str, stable: dict[str, Any], desired: dict[str, Any]) -> str:
    """Return the URL that reaches HA after it boots on DESIRED.

    Only a URL that reaches HA directly moves with the config. Behind a
    proxy, the URL stays, because the proxy decides the scheme and port.
    """
    return target_url(url, desired) if direct(url, stable) else url


def same_url(a: str, b: str) -> bool:
    def key(u: str) -> tuple[str, str, int]:
        p = urlsplit(u)
        return (p.scheme, p.hostname or "", p.port or {"https": 443, "http": 80, "wss": 443, "ws": 80}.get(p.scheme, 0))

    return key(a) == key(b)


def plan_http(want: dict[str, Any], live: Live, url: str) -> tuple[list[Change], list[str], list[str]]:
    info = live.http or {}
    problems: list[str] = []
    warnings: list[str] = []
    try:
        desired = effective(want, info.get("default") or {})
    except ValueError as err:
        return [], [f"http: trusted_proxies holds an invalid network: {err}"], warnings
    pending = info.get("pending")
    if pending and not pending.get("error"):
        problems.append(
            f"http: HA holds a pending HTTP config (active {info.get('active_config_type')!r}, reverts at {info.get('revert_at')}); "
            "promote or discard it in the UI first"
        )
    stable = normalize(config_of(info.get("stable")))
    diff = {k: (stable.get(k), desired.get(k)) for k in sorted(set(stable) | set(desired)) if stable.get(k) != desired.get(k)}
    if not diff:
        return [], problems, warnings
    if desired.get("ssl_peer_certificate"):
        problems.append("http: ssl_peer_certificate makes HA require a client certificate, which the engine cannot present")
    if desired.get("ssl_key") and not desired.get("ssl_certificate"):
        problems.append("http: ssl_key requires ssl_certificate")
    after = next_url(url, stable, desired)
    change = Change("update", HTTP, "config", "HTTP server", diff, target=desired)
    change.notes.append("restarts HA, then confirms the new config before HA reverts it after 5 minutes")
    if not same_url(after, url):
        change.notes.append(f"HA moves to {after}, and the apply reconnects there")
        if urlsplit(url).scheme == "https" and urlsplit(after).scheme == "http":
            warnings.append(f"http: HA drops TLS, so the apply sends the token to {after} in plain text")
    elif not direct(url, stable) and any(k in diff for k in ("server_port", "ssl_certificate", "ssl_key")):
        warnings.append(f"http: {url} reaches HA through a proxy, so the apply keeps using it; update the proxy for the new port or TLS setting")
    if "ssl_certificate" in diff or "ssl_key" in diff or "server_host" in diff:
        warnings.append("http: HA checks certificate files and bind addresses only when it boots; a bad one falls back to the current config")
    return [change], problems, warnings


async def reconnect(urls: list[str], token: str, timeout: float, log: Callable[[str], None]) -> Client:
    """Return a client connected to the first of URLS that answers, trying each until TIMEOUT."""
    deadline = time.monotonic() + timeout
    errors: dict[str, str] = {}
    while True:
        for url in urls:
            client = Client(url, token, timeout=30)
            try:
                await client.__aenter__()
            except (AuthError, ssl.SSLCertVerificationError) as err:
                # HA answers, but it rejects the token or presents a
                # certificate the engine cannot trust, so waiting cannot help.
                raise RuntimeError(f"cannot reconnect to {url}: {err}") from None
            except Exception as err:
                errors[url] = str(err) or type(err).__name__
                continue
            log(f"  reconnected to {url}")
            return client
        if time.monotonic() > deadline:
            last = "; ".join(f"{u}: {e}" for u, e in errors.items())
            raise TimeoutError(f"HA did not answer at {', '.join(urls)} within {int(timeout)}s (last errors: {last})")
        await asyncio.sleep(3)


async def apply_http(client: Client, change: Change, token: str, log: Callable[[str], None]) -> Client:
    """Stage CHANGE's config, wait for HA to restart on it, and promote it. Return the client of the new instance.

    The caller must not use CLIENT afterwards, because HA closes it when it
    restarts.
    """
    desired = change.target
    stable = normalize(config_of((await client.call("http/config")).get("stable")))
    after = next_url(client.url, stable, desired)
    reply = await client.call("http/config/configure", config=desired)
    if not reply.get("restart"):
        raise RuntimeError("HA did not stage the HTTP config; it might equal the current one")
    log("  http: staged; waiting for HA to restart")
    # HA checks its config and stops its integrations before it closes the
    # connection, which takes a while on a Pi.
    if not await client.wait_closed(timeout=300):
        raise RuntimeError("HA staged the HTTP config but did not restart; check its log, then restart HA to try the config")
    # HA falls back to the stable config when the new one fails to load, and
    # then answers on the old URL.
    urls = [after] if same_url(after, client.url) else [after, client.url]
    new = await reconnect(urls, token, timeout=240, log=log)
    try:
        info = await new.call("http/config")
        if info.get("active_config_type") != "pending":
            pending = info.get("pending") or {}
            raise RuntimeError(
                f"HA booted on the {info.get('active_config_type')!r} config, not the new one "
                f"(error {pending.get('error')!r}: {pending.get('error_message')})"
            )
        await new.call("http/config/promote")
        log("  http: promoted")
    except BaseException:
        await new.__aexit__(None, None, None)
        raise
    return new
