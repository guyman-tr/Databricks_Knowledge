"""SUT: Databricks Genie (Conversational API).

What we're evaluating
---------------------
The Databricks Genie Conversational API: a customer asks an NL question of a
configured Genie Space; Genie autonomously routes / generates SQL / returns a
text answer plus the underlying SQL. Our DDR Genie Space (or whichever space
is configured via `EVAL_GENIE_SPACE_ID`) is the system under test.

Naming note: the user calls this "Genie Code". Within Databricks, the
Conversational API is the supported interface; the "Code" label is internal
nomenclature for the autonomous-agent variant. We hit:

  POST /api/2.0/genie/spaces/{space_id}/start-conversation
       body: {"content": "<question>"}
       resp: {"conversation_id": "...", "message_id": "..."}

  GET  /api/2.0/genie/spaces/{space_id}/conversations/{cid}/messages/{mid}
       returns: status (PENDING / EXECUTING_QUERY / COMPLETED / FAILED),
                attachments (with text + query.statement_id), content

  GET  /api/2.0/genie/spaces/{space_id}/conversations/{cid}/messages/{mid}/attachments/{aid}/query-result
       returns the SQL execution result rows

We poll until the message is COMPLETED, extract the SQL it generated, and
return both the natural-language answer and a parsed scalar.

Auth
----
Same pattern as DirectSQLSUT: `databricks-sdk` WorkspaceClient picks up
`~/.databrickscfg` locally and runtime identity inside a notebook. No new
secrets needed for the harness — the Genie Space has to be already shared
with the user/runner identity though.

Configuration
-------------
  EVAL_GENIE_SPACE_ID   (required) — the Genie Space to ask
  DATABRICKS_HOST       (optional) — host override for cross-workspace
  EVAL_GENIE_TIMEOUT_S  (default 180) — poll budget per question
"""
from __future__ import annotations

import os
import re
import time
from typing import Any

from ..schema import CaseV1
from .base import SUT, SUTResponse


_DEFAULT_TIMEOUT_S = 180.0
_POLL_INTERVAL_S = 3.0
_TERMINAL_STATES = {"COMPLETED", "FAILED", "CANCELLED", "QUERY_RESULT_EXPIRED"}


_NUMERIC_RE = re.compile(r"-?\d+(?:\.\d+)?")


def _extract_scalar_from_text(text: str | None) -> float | None:
    """Mirror of databricks_mcp._extract_scalar — kept here for SUT independence."""
    if not text:
        return None
    cleaned = text.replace(",", "").replace("$", "").replace("USD", "").replace("M", "")
    nums = _NUMERIC_RE.findall(cleaned)
    if not nums:
        return None
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


def _scalar_from_query_result(rows: list[list[Any]] | None) -> float | None:
    """If Genie's underlying SQL returned a single scalar, prefer it over text."""
    if not rows:
        return None
    first = rows[0]
    if not first:
        return None
    v = first[0]
    if v is None:
        return None
    try:
        return float(v)
    except (TypeError, ValueError):
        return None


class GenieCodeSUT(SUT):
    name = "genie_code"

    def __init__(
        self,
        *,
        space_id: str | None = None,
        profile: str | None = None,
        timeout_s: float | None = None,
    ):
        self.space_id = space_id or os.environ.get("EVAL_GENIE_SPACE_ID")
        self.profile = profile or os.environ.get("DATABRICKS_CONFIG_PROFILE") or "DEFAULT"
        self.timeout_s = float(timeout_s if timeout_s is not None else os.environ.get("EVAL_GENIE_TIMEOUT_S", _DEFAULT_TIMEOUT_S))
        self._client = None  # lazy

    def _wclient(self):
        if self._client is None:
            from databricks.sdk import WorkspaceClient
            self._client = WorkspaceClient(profile=self.profile)
        return self._client

    def _start_conversation(self, w, question: str) -> tuple[str, str]:
        """Returns (conversation_id, message_id)."""
        # Use the SDK's genie API surface; fall back to raw API client if the
        # SDK version doesn't expose it.
        if hasattr(w, "genie") and hasattr(w.genie, "start_conversation"):
            r = w.genie.start_conversation(space_id=self.space_id, content=question)
            return r.conversation_id, r.message_id
        # raw fallback
        resp = w.api_client.do(
            "POST",
            f"/api/2.0/genie/spaces/{self.space_id}/start-conversation",
            body={"content": question},
        )
        return resp["conversation_id"], resp["message_id"]

    def _get_message(self, w, cid: str, mid: str) -> dict:
        if hasattr(w, "genie") and hasattr(w.genie, "get_message"):
            r = w.genie.get_message(space_id=self.space_id, conversation_id=cid, message_id=mid)
            return r.as_dict() if hasattr(r, "as_dict") else dict(r.__dict__)
        return w.api_client.do(
            "GET",
            f"/api/2.0/genie/spaces/{self.space_id}/conversations/{cid}/messages/{mid}",
        )

    def _get_query_result(self, w, cid: str, mid: str, attachment_id: str) -> dict:
        if hasattr(w, "genie") and hasattr(w.genie, "get_message_attachment_query_result"):
            r = w.genie.get_message_attachment_query_result(
                space_id=self.space_id, conversation_id=cid,
                message_id=mid, attachment_id=attachment_id,
            )
            return r.as_dict() if hasattr(r, "as_dict") else dict(r.__dict__)
        return w.api_client.do(
            "GET",
            f"/api/2.0/genie/spaces/{self.space_id}/conversations/{cid}/messages/{mid}/attachments/{attachment_id}/query-result",
        )

    def ask(self, question: str, case: CaseV1) -> SUTResponse:
        if not self.space_id:
            return SUTResponse(
                numeric_answer=None, text_answer=None, sql_used=None,
                raw={"backend": self.name},
                error="EVAL_GENIE_SPACE_ID not set",
            )
        t0 = time.time()
        try:
            w = self._wclient()
        except Exception as e:
            return SUTResponse(
                numeric_answer=None, text_answer=None, sql_used=None,
                raw={"backend": self.name},
                error=f"WorkspaceClient init failed: {e!s}",
                elapsed_ms=int((time.time() - t0) * 1000),
            )

        try:
            cid, mid = self._start_conversation(w, question)
        except Exception as e:
            return SUTResponse(
                numeric_answer=None, text_answer=None, sql_used=None,
                raw={"backend": self.name, "space_id": self.space_id},
                error=f"start-conversation failed: {e!s}",
                elapsed_ms=int((time.time() - t0) * 1000),
            )

        deadline = time.time() + self.timeout_s
        msg: dict = {}
        last_status: str | None = None
        while time.time() < deadline:
            try:
                msg = self._get_message(w, cid, mid)
            except Exception as e:
                return SUTResponse(
                    numeric_answer=None, text_answer=None, sql_used=None,
                    raw={"backend": self.name, "space_id": self.space_id, "cid": cid, "mid": mid},
                    error=f"get-message failed: {e!s}",
                    elapsed_ms=int((time.time() - t0) * 1000),
                )
            last_status = str(msg.get("status") or "")
            if last_status in _TERMINAL_STATES:
                break
            time.sleep(_POLL_INTERVAL_S)

        if last_status != "COMPLETED":
            return SUTResponse(
                numeric_answer=None, text_answer=None, sql_used=None,
                raw={"backend": self.name, "space_id": self.space_id, "cid": cid, "mid": mid, "status": last_status, "msg": msg},
                error=f"genie did not complete (status={last_status})",
                elapsed_ms=int((time.time() - t0) * 1000),
            )

        # Compose text answer + SQL + scalar from attachments
        text_parts: list[str] = []
        sql_used: str | None = None
        scalar: float | None = None

        attachments = msg.get("attachments") or []
        for att in attachments:
            txt = (att.get("text") or {}).get("content")
            if txt:
                text_parts.append(str(txt))
            q = att.get("query") or {}
            stmt = q.get("query") or q.get("statement")
            if stmt and not sql_used:
                sql_used = str(stmt)
            attachment_id = att.get("attachment_id")
            if attachment_id and scalar is None:
                try:
                    qr = self._get_query_result(w, cid, mid, attachment_id)
                    rows = ((qr.get("statement_response") or {}).get("result") or {}).get("data_array") or qr.get("data_array")
                    scalar = _scalar_from_query_result(rows)
                except Exception:
                    pass

        # Top-level message content, if any
        if isinstance(msg.get("content"), str):
            text_parts.append(msg["content"])

        text = "\n".join(p for p in text_parts if p).strip() or None
        if scalar is None:
            scalar = _extract_scalar_from_text(text)

        return SUTResponse(
            numeric_answer=scalar,
            text_answer=text,
            sql_used=sql_used,
            raw={
                "backend": self.name,
                "space_id": self.space_id,
                "conversation_id": cid,
                "message_id": mid,
                "status": last_status,
                "attachment_count": len(attachments),
            },
            elapsed_ms=int((time.time() - t0) * 1000),
        )
