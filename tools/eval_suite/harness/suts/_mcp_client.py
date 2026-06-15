"""Minimal JSON-RPC client for stdio-transport MCP servers.

We spawn the MCP server's launch command (e.g. ``npx mcp-remote ...``) as a
subprocess, write JSON-RPC requests one-per-line to its stdin, read responses
one-per-line from its stdout. This is the wire protocol Cursor / Claude
Desktop / etc. all use; we just speak it directly.

Why this exists
---------------
We are evaluating the user's custom Databricks MCP at
``https://databricks-mcp-gateway-...azure.databricksapps.com/mcp``. That MCP
sits behind OAuth and is reached via the ``mcp-remote`` stdio↔HTTP bridge
which handles the OAuth dance and caches tokens at ``~/.mcp-auth/``. The
Cursor IDE keeps those tokens fresh; we piggy-back on that cache and let
``mcp-remote`` worry about auth.

This is intentionally minimal:
  - No streaming notifications (we don't need progress updates).
  - No request-cancellation.
  - One outstanding request at a time per client (request_id auto-incremented).
  - Trace of every request/response for telemetry.

Usage
-----
::

    from tools.eval_suite.harness.suts._mcp_client import MCPStdioClient

    cmd = ["npx", "-y", "mcp-remote", "https://....azure.databricksapps.com/mcp",
           "33419",
           "--static-oauth-client-info", '{"client_id":"..."}',
           "--static-oauth-client-metadata", '{"scope":"all-apis offline_access"}']
    with MCPStdioClient(cmd) as cli:
        cli.initialize()
        tools = cli.list_tools()
        result = cli.call_tool("skills_find_skills", {"question": "...", "k": 5})
"""
from __future__ import annotations

import io
import json
import os
import queue
import shutil
import subprocess
import sys
import threading
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


# ---------------------------------------------------------------------------
# Errors
# ---------------------------------------------------------------------------

class MCPClientError(RuntimeError):
    """Anything that goes wrong: subprocess died, JSON-RPC error, timeout."""


class MCPTimeoutError(MCPClientError):
    """Server didn't respond to a request within the timeout."""


class MCPRpcError(MCPClientError):
    """Server returned a JSON-RPC `error` object."""

    def __init__(self, code: int, message: str, data: Any = None) -> None:
        super().__init__(f"JSON-RPC error {code}: {message}")
        self.code = code
        self.rpc_message = message
        self.data = data


# ---------------------------------------------------------------------------
# Trace records
# ---------------------------------------------------------------------------

@dataclass
class McpCallRecord:
    """One observed request/response pair, for telemetry."""
    method: str
    params: dict
    result: Any | None
    error: dict | None
    elapsed_ms: int


# ---------------------------------------------------------------------------
# The client
# ---------------------------------------------------------------------------

class MCPStdioClient:
    """JSON-RPC over stdio, line-delimited."""

    JSONRPC_VERSION = "2.0"
    PROTOCOL_VERSION = "2024-11-05"          # MCP spec version we target
    CLIENT_NAME = "etoro-eval-suite"
    CLIENT_VERSION = "0.1.0"

    def __init__(
        self,
        command: list[str],
        *,
        cwd: str | Path | None = None,
        env: dict[str, str] | None = None,
        startup_timeout_s: float = 20.0,
        request_timeout_s: float = 90.0,
        log_stderr: bool = True,
    ) -> None:
        self.command = command
        self.cwd = str(cwd) if cwd else None
        # Inherit parent env by default; only OVERRIDE keys explicitly given.
        merged_env = os.environ.copy()
        if env:
            merged_env.update(env)
        self.env = merged_env
        self.startup_timeout_s = startup_timeout_s
        self.request_timeout_s = request_timeout_s
        self.log_stderr = log_stderr

        # Wire protocol state
        self._proc: subprocess.Popen | None = None
        self._stdout_thread: threading.Thread | None = None
        self._stderr_thread: threading.Thread | None = None
        self._response_q: "queue.Queue[dict]" = queue.Queue()
        self._stderr_buf: list[str] = []
        self._next_id = 1

        # Telemetry
        self.call_records: list[McpCallRecord] = []
        self.initialized = False

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    def __enter__(self) -> "MCPStdioClient":
        self.start()
        return self

    def __exit__(self, exc_type, exc, tb) -> None:
        self.close()

    def start(self) -> None:
        """Spawn the MCP server subprocess and start reader threads."""
        if self._proc is not None:
            raise MCPClientError("MCPStdioClient already started")

        # Resolve the launcher (e.g. resolve `npx` → `npx.cmd` on Windows).
        cmd = self._resolve_command(self.command)

        # On Windows, pass shell=False with explicit binary path, hiding the
        # console window so we don't get a flash of cmd.exe per request.
        creationflags = 0
        if sys.platform == "win32":
            creationflags = getattr(subprocess, "CREATE_NO_WINDOW", 0)

        self._proc = subprocess.Popen(
            cmd,
            cwd=self.cwd,
            env=self.env,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=False,            # we'll decode ourselves to control encoding
            bufsize=0,             # unbuffered: we want every line as it arrives
            creationflags=creationflags,
        )

        self._stdout_thread = threading.Thread(
            target=self._stdout_reader, daemon=True, name="mcp-stdout"
        )
        self._stdout_thread.start()

        self._stderr_thread = threading.Thread(
            target=self._stderr_reader, daemon=True, name="mcp-stderr"
        )
        self._stderr_thread.start()

    def close(self) -> None:
        """Terminate the subprocess and join reader threads."""
        if self._proc is None:
            return
        try:
            if self._proc.stdin and not self._proc.stdin.closed:
                try:
                    self._proc.stdin.close()
                except Exception:  # noqa: BLE001
                    pass
            try:
                self._proc.terminate()
                self._proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self._proc.kill()
                self._proc.wait(timeout=2)
        except Exception:  # noqa: BLE001
            pass
        finally:
            self._proc = None

    # ------------------------------------------------------------------
    # Reader threads
    # ------------------------------------------------------------------

    def _stdout_reader(self) -> None:
        """Read lines from server stdout; push parsed JSON onto the queue."""
        assert self._proc and self._proc.stdout
        for raw_line in iter(self._proc.stdout.readline, b""):
            line = raw_line.decode("utf-8", errors="replace").strip()
            if not line:
                continue
            try:
                msg = json.loads(line)
            except json.JSONDecodeError:
                # Some MCP servers emit non-JSON banners / progress lines on
                # stdout before they get to the JSON-RPC. Skip silently.
                continue
            self._response_q.put(msg)

    def _stderr_reader(self) -> None:
        """Capture stderr for diagnostics. Most MCP servers log there."""
        assert self._proc and self._proc.stderr
        for raw_line in iter(self._proc.stderr.readline, b""):
            line = raw_line.decode("utf-8", errors="replace").rstrip()
            if line:
                if self.log_stderr:
                    self._stderr_buf.append(line)
                    # Cap to avoid unbounded growth in long sessions
                    if len(self._stderr_buf) > 2000:
                        self._stderr_buf = self._stderr_buf[-1000:]

    def stderr_tail(self, n: int = 40) -> str:
        return "\n".join(self._stderr_buf[-n:])

    # ------------------------------------------------------------------
    # JSON-RPC plumbing
    # ------------------------------------------------------------------

    def _send_request(self, method: str, params: dict | None = None) -> Any:
        """Send a JSON-RPC request, wait for matching response, return result.

        Records the call for telemetry. Raises MCPRpcError on JSON-RPC error.
        """
        if self._proc is None or self._proc.poll() is not None:
            raise MCPClientError(
                f"MCP server not running (exit code "
                f"{self._proc.returncode if self._proc else 'n/a'}); "
                f"stderr tail:\n{self.stderr_tail()}"
            )

        rid = self._next_id
        self._next_id += 1
        msg = {
            "jsonrpc": self.JSONRPC_VERSION,
            "id": rid,
            "method": method,
            "params": params or {},
        }
        line = (json.dumps(msg) + "\n").encode("utf-8")

        t0 = time.monotonic()
        try:
            assert self._proc.stdin
            self._proc.stdin.write(line)
            self._proc.stdin.flush()
        except (BrokenPipeError, OSError) as e:
            raise MCPClientError(
                f"Failed to write to MCP server stdin: {e}; "
                f"stderr tail:\n{self.stderr_tail()}"
            ) from e

        # Wait for the matching response (id == rid). Drop notifications
        # / unrelated messages; bail on timeout.
        deadline = t0 + self.request_timeout_s
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                self._record(method, params or {}, None,
                             {"timeout": self.request_timeout_s}, 0)
                raise MCPTimeoutError(
                    f"MCP request {method!r} timed out after "
                    f"{self.request_timeout_s}s; stderr tail:\n"
                    f"{self.stderr_tail()}"
                )
            try:
                resp = self._response_q.get(timeout=min(remaining, 1.0))
            except queue.Empty:
                # Check the proc is still alive
                if self._proc is None or self._proc.poll() is not None:
                    raise MCPClientError(
                        f"MCP server died while waiting for {method!r}; "
                        f"stderr tail:\n{self.stderr_tail()}"
                    )
                continue
            if resp.get("id") != rid:
                # Notification or response to a different request — ignore
                continue
            elapsed_ms = int((time.monotonic() - t0) * 1000)
            if "error" in resp:
                err = resp["error"]
                self._record(method, params or {}, None, err, elapsed_ms)
                raise MCPRpcError(
                    code=err.get("code", -1),
                    message=err.get("message", str(err)),
                    data=err.get("data"),
                )
            result = resp.get("result")
            self._record(method, params or {}, result, None, elapsed_ms)
            return result

    def _send_notification(self, method: str, params: dict | None = None) -> None:
        """Fire-and-forget notification (no `id`, no response expected)."""
        if self._proc is None:
            raise MCPClientError("MCP server not running")
        msg = {"jsonrpc": self.JSONRPC_VERSION, "method": method,
               "params": params or {}}
        line = (json.dumps(msg) + "\n").encode("utf-8")
        try:
            assert self._proc.stdin
            self._proc.stdin.write(line)
            self._proc.stdin.flush()
        except (BrokenPipeError, OSError):
            pass  # notifications best-effort

    def _record(
        self, method: str, params: dict, result: Any | None,
        error: dict | None, elapsed_ms: int,
    ) -> None:
        # Defensive copy of params (we'll serialize them later)
        try:
            p = json.loads(json.dumps(params, default=str))
        except (TypeError, ValueError):
            p = {"_unserialisable": True}
        self.call_records.append(
            McpCallRecord(method=method, params=p, result=result,
                          error=error, elapsed_ms=elapsed_ms)
        )

    # ------------------------------------------------------------------
    # MCP protocol surface
    # ------------------------------------------------------------------

    def initialize(self) -> dict:
        """Run the MCP `initialize` handshake. Returns the server's info dict.

        Per spec: client sends `initialize` request → server responds with
        capabilities → client sends `notifications/initialized`.
        """
        result = self._send_request("initialize", {
            "protocolVersion": self.PROTOCOL_VERSION,
            "capabilities": {},
            "clientInfo": {
                "name": self.CLIENT_NAME,
                "version": self.CLIENT_VERSION,
            },
        })
        # Per MCP spec, after a successful initialize the client sends
        # a notification (no response expected).
        self._send_notification("notifications/initialized", {})
        self.initialized = True
        return result or {}

    def list_tools(self) -> list[dict]:
        """Return the server's tool catalogue (list of {name, description, inputSchema})."""
        result = self._send_request("tools/list", {})
        return list((result or {}).get("tools") or [])

    def call_tool(self, name: str, arguments: dict | None = None) -> dict:
        """Call a tool. Returns the raw `result` body from the server.

        For the Databricks MCP this is shaped as:
            {"content": [{"type": "text", "text": "..."}], "isError": false, ...}
        and (for our tools) the JSON payload we want is in `content[0].text`.
        Caller is responsible for unwrapping.
        """
        return self._send_request("tools/call", {
            "name": name,
            "arguments": arguments or {},
        })

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _resolve_command(cmd: list[str]) -> list[str]:
        """On Windows, `npx` is `npx.cmd`; resolve to absolute path so we
        don't depend on PATHEXT being honoured by Popen."""
        if not cmd:
            return cmd
        head, rest = cmd[0], cmd[1:]
        if sys.platform == "win32":
            # Try `head`, `head.cmd`, `head.exe` in PATH
            for candidate in (head, f"{head}.cmd", f"{head}.exe"):
                resolved = shutil.which(candidate)
                if resolved:
                    return [resolved, *rest]
        else:
            resolved = shutil.which(head)
            if resolved:
                return [resolved, *rest]
        # Couldn't resolve — return unchanged; Popen will error if missing.
        return cmd


# ---------------------------------------------------------------------------
# Convenience: load the databricks-stg MCP from ~/.cursor/mcp.json
# ---------------------------------------------------------------------------

def load_mcp_command_from_cursor_config(server_id: str) -> list[str]:
    """Read ``~/.cursor/mcp.json`` and return the spawn command for ``server_id``.

    Raises if the server is not present or has no ``command`` field. Lets us
    define the gateway URL + OAuth client info in exactly ONE place (the IDE
    config) and reuse it in eval runs.
    """
    cfg_path = Path.home() / ".cursor" / "mcp.json"
    if not cfg_path.exists():
        raise MCPClientError(f"Cursor MCP config not found at {cfg_path}")
    try:
        cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        raise MCPClientError(f"Cursor MCP config is not valid JSON: {e}") from e

    servers = cfg.get("mcpServers") or cfg.get("servers") or {}
    if server_id not in servers:
        raise MCPClientError(
            f"MCP server {server_id!r} not in Cursor config; available: "
            f"{sorted(servers.keys())}"
        )
    spec = servers[server_id]
    cmd = spec.get("command")
    args = spec.get("args") or []
    if not cmd:
        raise MCPClientError(
            f"MCP server {server_id!r} has no `command` (config keys: "
            f"{sorted(spec.keys())}); only stdio-transport servers are supported"
        )
    return [cmd, *args]
