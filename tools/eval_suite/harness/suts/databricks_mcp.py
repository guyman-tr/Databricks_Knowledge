"""SUT: custom Databricks MCP gateway (the user-databricks-stg server).

Architecture
------------
The MCP gateway exposes ~23 tools. One of them is `databricks_ops_ask_genie`,
which is a self-contained NL->answer endpoint: the gateway runs the agent loop
SERVER-SIDE against a configured Genie Space and returns a structured payload:

    {
      "status": "COMPLETED",
      "sql": "<the SQL Genie generated>",
      "columns": ["..."],
      "data": [["scalar"]],
      "row_count": 1,
      "text_response": "<the prose answer>",
      "conversation_id": "...",
      "message_id": "..."
    }

So this SUT is intentionally thin: open an MCP session with the cached OAuth
bearer, call `databricks_ops_ask_genie(space_id, question)`, parse the JSON,
hand the scalar back to the harness scorer.

NO Anthropic key. NO LLM-in-the-middle. This is a true black-box eval of the
custom MCP + the Genie Space it routes to.

Auth
----
Reuses the OAuth bearer cached by Cursor's `mcp-remote` shim under
  %USERPROFILE%/.mcp-auth/mcp-remote-*/<hash>_tokens.json
Refreshes via the OIDC refresh-token grant when the access_token is near
expiry. In a Databricks notebook, the cache won't be present; set
DATABRICKS_MCP_BEARER directly via Secrets.

Configuration
-------------
  EVAL_MCP_SPACE_ID    (required) — Genie Space the MCP should route the
                       question to. Default: PROD - DDR
                       (01f13712cf8516878dbc9663f5f73eb7).
  DATABRICKS_MCP_URL   (optional) — gateway URL override.
  DATABRICKS_MCP_BEARER (optional) — bypass the file cache.
  EVAL_MCP_TIMEOUT_S   (default 240) — server-side ask_genie timeout.
"""
from __future__ import annotations

import asyncio
import base64
import glob
import json
import os
import re
import time
from typing import Any

import httpx

from ..schema import CaseV1
from .base import SUT, SUTResponse


_DEFAULT_GATEWAY_URL = (
    "https://databricks-mcp-gateway-5142916747090026.6.azure.databricksapps.com/mcp"
)
_DEFAULT_OAUTH_TOKEN_URL = (
    "https://adb-5142916747090026.6.azuredatabricks.net/oidc/v1/token"
)
_DEFAULT_CLIENT_ID = "6a189100-9638-4445-bed1-04c53ca86bde"

# Default Genie Space for DDR-flavoured eval cases. Discovered via
# databricks_ops_manage_genie(action='list') on 2026-06-11.
_DEFAULT_SPACE_ID = "01f13712cf8516878dbc9663f5f73eb7"  # PROD - DDR


# ---------------------------------------------------------------------------
# Auth helpers (reused by the genie SUT and the loop_authoring probes)
# ---------------------------------------------------------------------------


def _load_cached_token() -> tuple[str | None, str | None]:
    home = os.environ.get("USERPROFILE") or os.path.expanduser("~")
    pattern = os.path.join(home, ".mcp-auth", "mcp-remote-*", "*_tokens.json")
    matches = sorted(glob.glob(pattern), key=os.path.getmtime, reverse=True)
    for path in matches:
        try:
            with open(path, "r", encoding="utf-8") as f:
                d = json.load(f)
            return d.get("access_token"), d.get("refresh_token")
        except Exception:
            continue
    return None, None


def _decode_jwt_exp(token: str) -> int | None:
    try:
        parts = token.split(".")
        if len(parts) < 2:
            return None
        payload = parts[1] + "=" * (-len(parts[1]) % 4)
        body = json.loads(base64.urlsafe_b64decode(payload))
        return int(body.get("exp")) if "exp" in body else None
    except Exception:
        return None


def _refresh_token(refresh_token: str, client_id: str = _DEFAULT_CLIENT_ID) -> tuple[str | None, str | None]:
    try:
        r = httpx.post(
            _DEFAULT_OAUTH_TOKEN_URL,
            data={
                "grant_type": "refresh_token",
                "refresh_token": refresh_token,
                "client_id": client_id,
            },
            timeout=20.0,
        )
        if r.status_code != 200:
            return None, None
        d = r.json()
        return d.get("access_token"), d.get("refresh_token") or refresh_token
    except Exception:
        return None, None


def _ensure_fresh_token() -> str | None:
    env_tok = os.environ.get("DATABRICKS_MCP_BEARER")
    if env_tok:
        return env_tok.strip()
    access, refresh = _load_cached_token()
    if not access:
        return None
    exp = _decode_jwt_exp(access)
    now = int(time.time())
    if exp and exp - now < 60 and refresh:
        new_access, _ = _refresh_token(refresh)
        if new_access:
            return new_access
    return access


# ---------------------------------------------------------------------------
# Async core: one ask_genie call per question
# ---------------------------------------------------------------------------


async def _ask_via_mcp(
    *,
    gateway_url: str,
    bearer: str,
    space_id: str,
    question: str,
    timeout_seconds: int,
) -> dict:
    from mcp import ClientSession
    from mcp.client.streamable_http import streamablehttp_client

    headers = {"Authorization": f"Bearer {bearer}"}
    async with streamablehttp_client(gateway_url, headers=headers) as (read, write, _meta):
        async with ClientSession(read, write) as session:
            await session.initialize()
            r = await session.call_tool(
                "databricks_ops_ask_genie",
                {
                    "space_id": space_id,
                    "question": question,
                    "timeout_seconds": timeout_seconds,
                },
            )
            text = "".join(getattr(b, "text", "") or "" for b in (r.content or []))
            try:
                payload = json.loads(text)
            except json.JSONDecodeError:
                return {"_raw_text": text, "_parse_error": True}
            return payload


# ---------------------------------------------------------------------------
# Scalar extraction
# ---------------------------------------------------------------------------


def _scalar_from_data(data: Any) -> float | None:
    """Genie returns rows as a list-of-lists; the first cell of the first row
    is the scalar when the answer is a one-row-one-column query."""
    if not isinstance(data, list) or not data:
        return None
    first_row = data[0]
    if not isinstance(first_row, (list, tuple)) or not first_row:
        return None
    v = first_row[0]
    if v is None:
        return None
    if isinstance(v, (int, float)):
        return float(v)
    if isinstance(v, str):
        s = v.replace(",", "").replace("$", "").strip()
        try:
            return float(s)
        except ValueError:
            return None
    return None


_NUM_RE = re.compile(r"-?\d+(?:\.\d+)?")


def _scalar_from_text(text: str | None) -> float | None:
    if not text:
        return None
    cleaned = text.replace(",", "").replace("$", "")
    nums = _NUM_RE.findall(cleaned)
    parsed: list[float] = []
    for n in nums:
        try:
            parsed.append(float(n))
        except ValueError:
            continue
    if not parsed:
        return None
    parsed.sort(key=lambda x: abs(x), reverse=True)
    return parsed[0]


# ---------------------------------------------------------------------------
# Sync SUT facade
# ---------------------------------------------------------------------------


class DatabricksMcpSUT(SUT):
    name = "databricks_mcp"

    def __init__(
        self,
        *,
        gateway_url: str | None = None,
        space_id: str | None = None,
        timeout_seconds: int | None = None,
        bearer: str | None = None,
    ):
        self.gateway_url = gateway_url or os.environ.get("DATABRICKS_MCP_URL", _DEFAULT_GATEWAY_URL)
        self.space_id = (
            space_id
            or os.environ.get("EVAL_MCP_SPACE_ID")
            or _DEFAULT_SPACE_ID
        )
        self.timeout_seconds = int(
            timeout_seconds if timeout_seconds is not None
            else os.environ.get("EVAL_MCP_TIMEOUT_S", 240)
        )
        self._bearer_override = bearer

    def _bearer(self) -> str | None:
        return self._bearer_override or _ensure_fresh_token()

    def ask(self, question: str, case: CaseV1) -> SUTResponse:
        bearer = self._bearer()
        if not bearer:
            return SUTResponse(
                numeric_answer=None, text_answer=None, sql_used=None,
                raw={"backend": self.name},
                error=(
                    "no MCP bearer found (cache empty or refresh failed; "
                    "set DATABRICKS_MCP_BEARER, or run mcp-remote in Cursor "
                    "once to seed the cache)"
                ),
            )

        t0 = time.time()
        try:
            payload = asyncio.run(_ask_via_mcp(
                gateway_url=self.gateway_url,
                bearer=bearer,
                space_id=self.space_id,
                question=question,
                timeout_seconds=self.timeout_seconds,
            ))
        except Exception as e:
            return SUTResponse(
                numeric_answer=None, text_answer=None, sql_used=None,
                raw={"backend": self.name, "space_id": self.space_id},
                error=f"ask_genie call failed: {e!s}",
                elapsed_ms=int((time.time() - t0) * 1000),
            )

        if payload.get("_parse_error"):
            return SUTResponse(
                numeric_answer=None, text_answer=None, sql_used=None,
                raw={"backend": self.name, "space_id": self.space_id, "raw_text": payload.get("_raw_text", "")[:500]},
                error="MCP returned non-JSON",
                elapsed_ms=int((time.time() - t0) * 1000),
            )

        status = str(payload.get("status") or "")
        if status != "COMPLETED":
            return SUTResponse(
                numeric_answer=None,
                text_answer=payload.get("text_response"),
                sql_used=payload.get("sql"),
                raw={"backend": self.name, "space_id": self.space_id, "status": status, "payload_keys": list(payload.keys())},
                error=f"genie did not complete (status={status}); error={payload.get('error')}",
                elapsed_ms=int((time.time() - t0) * 1000),
            )

        # Prefer the structured scalar; fall back to text parsing.
        scalar = _scalar_from_data(payload.get("data"))
        if scalar is None:
            scalar = _scalar_from_text(payload.get("text_response"))

        return SUTResponse(
            numeric_answer=scalar,
            text_answer=payload.get("text_response"),
            sql_used=payload.get("sql"),
            raw={
                "backend": self.name,
                "space_id": self.space_id,
                "conversation_id": payload.get("conversation_id"),
                "message_id": payload.get("message_id"),
                "row_count": payload.get("row_count"),
                "columns": payload.get("columns"),
            },
            elapsed_ms=int((time.time() - t0) * 1000),
        )
