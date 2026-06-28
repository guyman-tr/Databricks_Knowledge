"""Cursor SDK wrapper for live skills automation actions."""
from __future__ import annotations

import json
import os
import re
import time
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FutureTimeout
from dataclasses import dataclass
from pathlib import Path


RESULT_PREFIX = "RESULT_JSON:"
_WINDOWS_BLOCKING_STATE: dict[int, bool] = {}


@dataclass
class AgentActionResult:
    final_status: str
    pr_url: str | None
    notes: str
    raw_output: str


def _extract_text(result: object) -> str:
    """
    Best-effort extraction from cursor_sdk Agent.prompt result.
    Handles both object-like and dict-like shapes.
    """
    for key in ("result", "text", "output"):
        if hasattr(result, key):
            val = getattr(result, key)
            if isinstance(val, str):
                return val
    if isinstance(result, dict):
        for key in ("result", "text", "output"):
            val = result.get(key)
            if isinstance(val, str):
                return val
    return str(result)


def _ensure_windows_blocking_compat() -> None:
    """
    cursor-sdk currently calls os.get_blocking/os.set_blocking in bridge launch.
    On some Windows Python builds these APIs are missing.
    Provide a Windows pipe-compatible fallback so live mode works locally.
    """
    if hasattr(os, "get_blocking") and hasattr(os, "set_blocking"):
        return

    if os.name != "nt":
        return

    import ctypes
    import msvcrt
    from ctypes import wintypes

    kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
    set_pipe_state = kernel32.SetNamedPipeHandleState
    set_pipe_state.argtypes = [
        wintypes.HANDLE,
        ctypes.POINTER(wintypes.DWORD),
        ctypes.c_void_p,
        ctypes.c_void_p,
    ]
    set_pipe_state.restype = wintypes.BOOL

    PIPE_WAIT = 0x00000000
    PIPE_NOWAIT = 0x00000001

    def _set_blocking(fd: int, blocking: bool) -> None:
        handle = msvcrt.get_osfhandle(fd)
        mode = wintypes.DWORD(PIPE_WAIT if blocking else PIPE_NOWAIT)
        ok = set_pipe_state(handle, ctypes.byref(mode), None, None)
        if not ok:
            err = ctypes.get_last_error()
            raise OSError(err, "SetNamedPipeHandleState failed")
        _WINDOWS_BLOCKING_STATE[fd] = blocking

    def _get_blocking(fd: int) -> bool:
        return _WINDOWS_BLOCKING_STATE.get(fd, True)

    setattr(os, "set_blocking", _set_blocking)
    setattr(os, "get_blocking", _get_blocking)


def _patch_cursor_sdk_bridge_windows() -> None:
    """Patch cursor_sdk bridge discovery for Windows pipe compatibility."""
    if os.name != "nt":
        return
    import codecs
    import ctypes
    import msvcrt
    from ctypes import wintypes

    import cursor_sdk._bridge as bridge_mod  # type: ignore
    from cursor_sdk.errors import CursorSDKError  # type: ignore

    if getattr(bridge_mod, "_WINDOWS_DISCOVERY_PATCHED", False):
        return

    kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
    peek_named_pipe = kernel32.PeekNamedPipe
    peek_named_pipe.argtypes = [
        wintypes.HANDLE,
        ctypes.c_void_p,
        wintypes.DWORD,
        ctypes.c_void_p,
        ctypes.POINTER(wintypes.DWORD),
        ctypes.c_void_p,
    ]
    peek_named_pipe.restype = wintypes.BOOL

    def _read_discovery_windows(process, timeout):  # type: ignore[no-untyped-def]
        if process.stderr is None:
            raise CursorSDKError("Bridge process stderr is unavailable")
        fd = process.stderr.fileno()
        handle = msvcrt.get_osfhandle(fd)
        decoder = codecs.getincrementaldecoder("utf-8")(errors="replace")
        deadline = time.monotonic() + timeout
        stderr_lines: list[str] = []
        pending = ""

        while time.monotonic() < deadline:
            avail = wintypes.DWORD(0)
            ok = peek_named_pipe(handle, None, 0, None, ctypes.byref(avail), None)
            if not ok:
                exit_code = process.poll()
                if exit_code is not None:
                    raise CursorSDKError(
                        f"Bridge exited before discovery with status {exit_code}: "
                        + "".join(stderr_lines)
                        + pending
                    )
                time.sleep(0.05)
                continue

            if avail.value > 0:
                chunk = process.stderr.buffer.raw.read(avail.value)  # type: ignore[attr-defined]
                if not chunk:
                    time.sleep(0.05)
                    continue
                pending += decoder.decode(chunk)
                while "\n" in pending:
                    line, pending = pending.split("\n", 1)
                    line += "\n"
                    stderr_lines.append(line)
                    discovery = bridge_mod.parse_discovery_line(line)
                    if discovery is not None:
                        return discovery
            else:
                exit_code = process.poll()
                if exit_code is not None:
                    final_text = decoder.decode(b"", final=True)
                    if final_text:
                        pending += final_text
                    if pending:
                        stderr_lines.append(pending)
                        discovery = bridge_mod.parse_discovery_line(pending)
                        if discovery is not None:
                            return discovery
                    raise CursorSDKError(
                        f"Bridge exited before discovery with status {exit_code}: "
                        + "".join(stderr_lines)
                    )
                time.sleep(0.05)

        raise CursorSDKError("Timed out waiting for bridge discovery")

    bridge_mod._read_discovery = _read_discovery_windows  # type: ignore[attr-defined]
    bridge_mod._WINDOWS_DISCOVERY_PATCHED = True


def _extract_pr_url(text: str) -> str | None:
    m = re.search(r"https://github\.com/eToro/DataPlatform/pull/\d+", text)
    return m.group(0) if m else None


def _parse_result_json(text: str) -> dict | None:
    for line in text.splitlines():
        if line.startswith(RESULT_PREFIX):
            candidate = line[len(RESULT_PREFIX) :].strip()
            try:
                payload = json.loads(candidate)
                if isinstance(payload, dict):
                    return payload
            except json.JSONDecodeError:
                # Relaxed parser for common model output:
                # {status:pushed,pr_url:null,notes:some_text}
                status_m = re.search(r"status\s*:\s*['\"]?([a-zA-Z_]+)['\"]?", candidate)
                pr_m = re.search(r"pr_url\s*:\s*(['\"]?[^,'\"}]+['\"]?|null)", candidate)
                notes_m = re.search(r"notes\s*:\s*['\"]?([^}\"']+)['\"]?", candidate)
                if not status_m:
                    return None
                status = status_m.group(1).strip()
                pr_raw = pr_m.group(1).strip() if pr_m else "null"
                if pr_raw.lower() == "null":
                    pr_url = None
                else:
                    pr_url = pr_raw.strip("'\"")
                notes = notes_m.group(1).strip() if notes_m else "no notes"
                return {"status": status, "pr_url": pr_url, "notes": notes}
    return None


def run_cursor_agent_prompt(
    *,
    prompt: str,
    workspace_cwd: Path,
    model_id: str | None = None,
    timeout_seconds: int | None = None,
) -> AgentActionResult:
    _ensure_windows_blocking_compat()
    try:
        from cursor_sdk import Agent, AgentOptions, LocalAgentOptions  # type: ignore
    except Exception as exc:  # noqa: BLE001
        raise RuntimeError(
            "cursor_sdk is required for live execution. Install with `pip install cursor-sdk`."
        ) from exc
    _patch_cursor_sdk_bridge_windows()
    selected_model = model_id or os.environ.get("CURSOR_AGENT_MODEL", "default")
    timeout_s = timeout_seconds or int(os.environ.get("CURSOR_AGENT_TIMEOUT_SECONDS", "180"))

    def _invoke_prompt():
        return Agent.prompt(
            prompt,
            AgentOptions(
                api_key=os.environ.get("CURSOR_API_KEY", ""),
                model=selected_model,
                local=LocalAgentOptions(cwd=str(workspace_cwd)),
            ),
        )

    with ThreadPoolExecutor(max_workers=1) as pool:
        future = pool.submit(_invoke_prompt)
        try:
            result = future.result(timeout=timeout_s)
        except FutureTimeout as exc:
            future.cancel()
            raise RuntimeError(
                f"cursor_sdk Agent.prompt timed out after {timeout_s}s"
            ) from exc
    text = _extract_text(result)
    payload = _parse_result_json(text)
    if payload:
        status = str(payload.get("status") or "error")
        notes = str(payload.get("notes") or "no notes")
        pr_url = payload.get("pr_url")
        if pr_url is not None:
            pr_url = str(pr_url)
        return AgentActionResult(
            final_status=status,
            pr_url=pr_url,
            notes=notes,
            raw_output=text,
        )

    return AgentActionResult(
        final_status="pushed" if _extract_pr_url(text) else "error",
        pr_url=_extract_pr_url(text),
        notes="live run completed (RESULT_JSON not found; parsed fallback)",
        raw_output=text,
    )
