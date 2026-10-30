"""Forward local TCP connections into a container through `docker exec`.

Published ports do not work on every Docker setup, such as a rootless daemon
whose port driver resets connections. The relay listens on 127.0.0.1 and runs
one `docker exec -i` per connection. A Python one-liner inside the container
copies bytes between that exec's stdio and the target port, so the only thing
the relay needs from Docker is exec.
"""

from __future__ import annotations

import socket
import subprocess
import threading

INNER = """\
import os, socket, sys, threading
s = socket.create_connection(("127.0.0.1", {port}))
def upstream():
    while data := os.read(0, 65536):
        s.sendall(data)
    s.shutdown(socket.SHUT_WR)
threading.Thread(target=upstream, daemon=True).start()
while data := s.recv(65536):
    sys.stdout.buffer.write(data)
    sys.stdout.buffer.flush()
"""


class Relay:
    """Relay forwards 127.0.0.1:<self.port> to PORT inside CONTAINER until close() runs."""

    def __init__(self, container: str, port: int) -> None:
        self._container = container
        self._script = INNER.format(port=port)
        self._server = socket.create_server(("127.0.0.1", 0))
        self.port = self._server.getsockname()[1]
        self._closed = False
        threading.Thread(target=self._accept, daemon=True).start()

    def _accept(self) -> None:
        while not self._closed:
            try:
                conn, _ = self._server.accept()
            except OSError:
                return
            threading.Thread(target=self._serve, args=(conn,), daemon=True).start()

    def _serve(self, conn: socket.socket) -> None:
        proc = subprocess.Popen(
            ["docker", "exec", "-i", self._container, "python3", "-c", self._script],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            bufsize=0,
        )

        def downstream() -> None:
            while data := proc.stdout.read(65536):
                conn.sendall(data)
            conn.close()

        threading.Thread(target=downstream, daemon=True).start()
        try:
            while data := conn.recv(65536):
                proc.stdin.write(data)
        except OSError:
            pass
        finally:
            try:
                proc.stdin.close()
            except OSError:
                pass

    def close(self) -> None:
        self._closed = True
        self._server.close()
