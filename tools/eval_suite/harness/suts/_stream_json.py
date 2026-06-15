"""Parse cursor-agent --output-format stream-json into structured trace data.

cursor-agent emits one JSON object per line. The shapes we care about:

  {"type":"system","subtype":"init", session_id, model, ...}
  {"type":"user", message:{role:"user",content:[{type:"text",text:...}]}}
  {"type":"thinking","subtype":"delta", text:"..."}
  {"type":"thinking","subtype":"completed"}
  {"type":"assistant", message:{role:"assistant",content:[{type:"text",text:...}]}}
  {"type":"tool_call","subtype":"started",
     call_id,
     tool_call:{ <kind>: { args: {...} } }}
  {"type":"tool_call","subtype":"completed",
     call_id,
     tool_call:{ <kind>: { args: {...}, result: {success|failure: {...}} } }}
  {"type":"result","subtype":"success", duration_ms, result, usage:{...}}

The polymorphic <kind> for tool_call is one of:
  readToolCall, writeToolCall, editToolCall,
  shellToolCall, globToolCall, grepToolCall, listDirToolCall,
  mcpToolCall, todoWriteToolCall, ...

We extract the bits that matter for an eval audit:
  - which skills were loaded (via readToolCall on .cursor/skills/.../SKILL.md
    OR via mcpToolCall name=skills_get_skill / skills_find_skills)
  - which SQL was executed (via shellToolCall command containing dbx_query.py
    OR via mcpToolCall name=databricks_sql_execute_sql_read_only / _execute_sql)
  - tool call counts by kind/name
  - rough reasoning excerpt (concatenation of thinking deltas)
  - final assistant text and result.usage tokens
"""
from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from typing import Any


# ---------------------------------------------------------------------------
# Decoding
# ---------------------------------------------------------------------------

def decode_stream_bytes(raw: bytes) -> str:
    """Decode cursor-agent stdout to text, handling Windows BOMs."""
    if raw.startswith(b"\xff\xfe"):
        return raw[2:].decode("utf-16-le", errors="replace")
    if raw.startswith(b"\xfe\xff"):
        return raw[2:].decode("utf-16-be", errors="replace")
    if raw.startswith(b"\xef\xbb\xbf"):
        return raw[3:].decode("utf-8", errors="replace")
    return raw.decode("utf-8", errors="replace")


def parse_stream_jsonl(text: str) -> list[dict]:
    """Parse newline-delimited JSON. Tolerates partial/garbled lines."""
    events: list[dict] = []
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            # cursor-agent occasionally emits a half-line during shutdown; skip.
            continue
    return events


# ---------------------------------------------------------------------------
# Trace extraction
# ---------------------------------------------------------------------------

@dataclass
class SkillLoad:
    """One skill load event — either via direct file read or MCP."""
    method: str           # "file_read" | "mcp_get_skill" | "mcp_find_skills"
    slug: str             # path tail or skill slug
    raw_arg: str          # full path or full mcp arg (truncated)


@dataclass
class SqlExec:
    """One SQL execution attempt (success or failure)."""
    method: str           # "shell_dbx_query" | "mcp_databricks_sql"
    sql: str
    succeeded: bool
    error: str | None = None
    result_excerpt: str | None = None  # first ~400 chars of stdout/result


@dataclass
class StreamTrace:
    """Structured summary of one cursor-agent run."""
    session_id: str | None = None
    model: str | None = None
    prompt_text: str | None = None

    final_text: str | None = None
    duration_ms: int | None = None

    # Token usage (Cursor credits are computed from these)
    input_tokens: int = 0
    output_tokens: int = 0
    cache_read_tokens: int = 0
    cache_write_tokens: int = 0

    # Tool call census
    tool_call_count: int = 0
    tool_call_by_kind: dict[str, int] = field(default_factory=dict)
    mcp_tool_call_by_name: dict[str, int] = field(default_factory=dict)

    # Skills loaded (direct file read OR via MCP)
    skills_loaded: list[SkillLoad] = field(default_factory=list)

    # SQL executions (regardless of method)
    sql_execs: list[SqlExec] = field(default_factory=list)

    # Reasoning (concatenated thinking deltas, truncated downstream)
    thinking_text: str = ""

    # Errors / non-success terminals
    is_error: bool = False
    error_excerpt: str | None = None


_SKILL_PATH_RE = re.compile(
    r"\.cursor[\\/]+skills[\\/]+([^\\/]+(?:[\\/]+[^\\/]+)*?)[\\/]+SKILL\.md$",
    re.IGNORECASE,
)

_DBX_QUERY_PY_RE = re.compile(r"dbx_query\.py", re.IGNORECASE)


def _extract_sql_from_dbx_query_command(command: str) -> str | None:
    """Best-effort: pull the SQL text out of `python tools/dbx_query.py "..."`.

    Handles:
      python tools/dbx_query.py "SELECT ... FROM ..."
      python tools/dbx_query.py "SELECT
      ...
      "
      python -u tools/dbx_query.py 'SELECT ...'
    """
    if not command:
        return None
    # Find the first quoted blob after dbx_query.py
    m = re.search(r"dbx_query\.py\s+([\"'])([\s\S]+?)\1", command)
    if m:
        return m.group(2).strip()
    return None


def _summarize_result_excerpt(result: dict | None) -> tuple[bool, str | None, str | None]:
    """Return (succeeded, error_excerpt, result_excerpt) from a tool_call result.

    cursor-agent results follow {"success": {...}} or {"failure": {...}}.
    """
    if not result:
        return (False, None, None)
    if "success" in result:
        s = result["success"]
        # shellToolCall: stdout/stderr; readToolCall: totalLines/path; mcpToolCall: content
        bits = []
        for k in ("stdout", "result", "content", "text"):
            v = s.get(k)
            if v:
                bits.append(str(v)[:400])
                break
        return (True, None, " | ".join(bits)[:400] if bits else None)
    if "failure" in result:
        f = result["failure"]
        bits = []
        for k in ("stderr", "error", "message", "content"):
            v = f.get(k)
            if v:
                bits.append(str(v)[:400])
                break
        return (False, " | ".join(bits)[:400] if bits else "tool failed", None)
    return (False, None, None)


def _process_completed_tool_call(trace: StreamTrace, kind: str, inner: dict) -> None:
    """Apply one completed tool_call event to the running trace."""
    args = inner.get("args") or {}
    result = inner.get("result") or {}
    succeeded, error_excerpt, result_excerpt = _summarize_result_excerpt(result)

    if kind == "readToolCall":
        path = args.get("path", "") or ""
        m = _SKILL_PATH_RE.search(path)
        if m:
            trace.skills_loaded.append(
                SkillLoad(method="file_read", slug=m.group(1).replace("\\", "/"), raw_arg=path[:300])
            )

    elif kind == "shellToolCall":
        cmd = args.get("command", "") or ""
        if _DBX_QUERY_PY_RE.search(cmd):
            sql = _extract_sql_from_dbx_query_command(cmd)
            if sql:
                trace.sql_execs.append(
                    SqlExec(
                        method="shell_dbx_query",
                        sql=sql,
                        succeeded=succeeded,
                        error=error_excerpt,
                        result_excerpt=result_excerpt,
                    )
                )

    elif kind == "mcpToolCall":
        name = args.get("name") or args.get("toolName") or ""
        # MCP arg payloads vary; common ones to handle:
        if name in ("skills_find_skills", "skills_search"):
            q = (args.get("arguments") or {}).get("query") or args.get("query") or ""
            trace.skills_loaded.append(
                SkillLoad(method="mcp_find_skills", slug=str(q)[:80], raw_arg=str(args)[:300])
            )
            trace.mcp_tool_call_by_name[name] = trace.mcp_tool_call_by_name.get(name, 0) + 1
        elif name in ("skills_get_skill", "skills_load_skill"):
            slug = (args.get("arguments") or {}).get("slug") or args.get("slug") or ""
            trace.skills_loaded.append(
                SkillLoad(method="mcp_get_skill", slug=str(slug)[:120], raw_arg=str(args)[:300])
            )
            trace.mcp_tool_call_by_name[name] = trace.mcp_tool_call_by_name.get(name, 0) + 1
        elif "databricks_sql" in name and "execute" in name:
            sql = (args.get("arguments") or {}).get("statement") or args.get("statement") or ""
            if not sql:
                sql = (args.get("arguments") or {}).get("query") or args.get("query") or ""
            if sql:
                trace.sql_execs.append(
                    SqlExec(
                        method="mcp_databricks_sql",
                        sql=str(sql),
                        succeeded=succeeded,
                        error=error_excerpt,
                        result_excerpt=result_excerpt,
                    )
                )
            trace.mcp_tool_call_by_name[name] = trace.mcp_tool_call_by_name.get(name, 0) + 1
        else:
            trace.mcp_tool_call_by_name[name or "mcp_unknown"] = (
                trace.mcp_tool_call_by_name.get(name or "mcp_unknown", 0) + 1
            )


def parse_trace(events: list[dict]) -> StreamTrace:
    """Reduce the per-line stream-json event list to a StreamTrace summary.

    Counts only `tool_call/completed` so we don't double-count pending tools.
    """
    trace = StreamTrace()
    final_text_buf: list[str] = []
    thinking_buf: list[str] = []

    for e in events:
        t = e.get("type")
        sub = e.get("subtype")

        if t == "system" and sub == "init":
            trace.session_id = e.get("session_id")
            trace.model = e.get("model")

        elif t == "user":
            try:
                blocks = e.get("message", {}).get("content", [])
                for b in blocks:
                    if b.get("type") == "text":
                        trace.prompt_text = b.get("text")
                        break
            except Exception:
                pass

        elif t == "thinking" and sub == "delta":
            txt = e.get("text") or ""
            if txt:
                thinking_buf.append(txt)

        elif t == "assistant":
            try:
                blocks = e.get("message", {}).get("content", [])
                for b in blocks:
                    if b.get("type") == "text" and b.get("text"):
                        final_text_buf.append(b["text"])
            except Exception:
                pass

        elif t == "tool_call" and sub == "completed":
            tc = e.get("tool_call", {}) or {}
            for kind, inner in tc.items():
                trace.tool_call_count += 1
                trace.tool_call_by_kind[kind] = trace.tool_call_by_kind.get(kind, 0) + 1
                if isinstance(inner, dict):
                    _process_completed_tool_call(trace, kind, inner)

        elif t == "result":
            trace.duration_ms = e.get("duration_ms")
            trace.is_error = bool(e.get("is_error"))
            res = e.get("result")
            if res and not final_text_buf:
                # Some runs only put the final text in `result.result`.
                final_text_buf.append(str(res))
            usage = e.get("usage") or {}
            trace.input_tokens = int(usage.get("inputTokens", 0) or 0)
            trace.output_tokens = int(usage.get("outputTokens", 0) or 0)
            trace.cache_read_tokens = int(usage.get("cacheReadTokens", 0) or 0)
            trace.cache_write_tokens = int(usage.get("cacheWriteTokens", 0) or 0)

    trace.final_text = "".join(final_text_buf) if final_text_buf else None
    trace.thinking_text = "".join(thinking_buf)
    return trace
