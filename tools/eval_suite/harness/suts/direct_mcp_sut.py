"""DirectMcpSUT — the real Databricks-MCP eval SUT.

Drives the canonical skill-grounded flow your MCP itself prescribes,
through the OAuth-protected MCP gateway, end-to-end:

    1. NL question  →  `skills_find_skills(question, k=5)`         [MCP]
    2. Top match    →  `skills_get_skill(id)`                      [MCP]
       └→ returns body_markdown + (optional) example_sql

    3. Agentic loop with two tools:
         - `describe_table(fqn)`  -> DESCRIBE TABLE EXTENDED via MCP
         - `execute_sql(sql)`     -> the final answer-emitting query
       Loop until the model calls `execute_sql`, with a hard cap on
       rounds and wall-clock to keep cost bounded.

    4. Parse first scalar from the first row, return it.

EVERY SQL — including DESCRIBEs — goes through `databricks_ops_execute_sql`
on the MCP gateway. No databricks-sdk shortcut, no `dbx_query.py`. The
LLM never holds a Databricks credential of its own.

Why agentic instead of one-shot?
  v1 (one-shot) found that Sonnet, given a skill body, picks the right
  tables and contracts but hallucinates column names (CID vs RealCID,
  MoneyIn vs MoneyInUSD). Skills bodies don't carry full column dicts;
  the model is forced to guess. Adding a `describe_table` tool that
  the model can call before authoring the final SQL eliminates the
  guess-the-column failure mode at cost of N extra MCP round-trips.

Telemetry shape mirrors the SUTResponse contract:
    numeric_answer  = first scalar of first row in the FINAL execute_sql
    text_answer     = a one-line summary of model + grounding + result
    sql_used        = the FINAL SQL the model emitted
    raw             = {
        backend             "direct_mcp"
        mcp_calls           list of every MCP call (find/get/describe/execute)
        llm_calls           list of every LLM round-trip
        skill_top_id        top hub id from find_skills
        skill_ground_id     hub-or-sub-skill id we got_skill on
        skill_body_chars    body_markdown size
        describe_count      how many describe_table tool calls fired
        probe_count         how many probe_sql tool calls fired
        sql                 final SQL string
        sql_result_cols     column names from the final execute
        sql_result_rows     first 5 rows (capped for telemetry)
        sql_result_row_count
        agent_rounds        LLM rounds spent
        terminate_reason    'execute_sql' | 'max_rounds' | 'no_progress' | 'error'
    }
"""
from __future__ import annotations

import json
import re
import time
from typing import Any

from ..schema import CaseV1
from .base import SUT, SUTResponse
from ._mcp_client import (
    MCPStdioClient,
    MCPClientError,
    MCPRpcError,
    load_mcp_command_from_cursor_config,
)
from ._llm_driver import LLMDriver, LLMResponse, get_llm_driver, LLMError


# ---------------------------------------------------------------------------
# System prompt
# ---------------------------------------------------------------------------

# Tools the model is given access to. Both route through MCP execute_sql.
_AGENT_TOOLS: list[dict] = [
    {
        "type": "function",
        "function": {
            "name": "describe_table",
            "description": (
                "Inspect the columns + types of a Databricks UC table or "
                "view. ALWAYS describe a table before authoring SQL against "
                "it — column names in UC mirrors are NOT the same as the "
                "Synapse originals (e.g. RealCID not CID, MoneyInUSD not "
                "MoneyIn). Returns column_name, data_type, and any column "
                "comment if set."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "fqn": {
                        "type": "string",
                        "description": (
                            "Three-part fully-qualified name: "
                            "<catalog>.<schema>.<table>. E.g. "
                            "'main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum'."
                        ),
                    },
                },
                "required": ["fqn"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "probe_sql",
            "description": (
                "Run a small exploratory SQL query and see its rows. Use "
                "this to:\n"
                "  * Enumerate the values of an enum/category column "
                "(e.g. SELECT DISTINCT Metric FROM ... WHERE DateID = N).\n"
                "  * Sanity-check a partial query before committing the "
                "final answer (e.g. row count, sample of the rows you'd "
                "aggregate over).\n"
                "  * Verify a literal exists (e.g. is 'DormantFee' "
                "actually a value of Metric, or is it 'AdminFee'?).\n"
                "Probes return up to 50 rows. Always probe before "
                "submit_answer when you're uncertain about an enum value, "
                "a category name, or whether a category has data on a "
                "given date. Never use probe_sql as the final answer."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "sql": {
                        "type": "string",
                        "description": (
                            "Databricks SQL. Should be a small, narrow "
                            "query — not the full answer. Cap your own "
                            "result with LIMIT 50."
                        ),
                    },
                },
                "required": ["sql"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "submit_answer",
            "description": (
                "Submit the FINAL Databricks SQL that answers the user's "
                "question. The harness will execute it and read row[0][0] "
                "as the numeric answer. Call this exactly ONCE per "
                "question, AFTER you have described every table you'll "
                "use AND probed any uncertain values. The eval ends here."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "sql": {
                        "type": "string",
                        "description": (
                            "Databricks SQL. Use INT YYYYMMDD for DateID "
                            "columns. Apply the valid-users SCD-2 contract "
                            "unless the question explicitly opts out. NO "
                            "trailing semicolon. Single scalar in row[0][0]."
                        ),
                    },
                },
                "required": ["sql"],
            },
        },
    },
]


_SYSTEM_PROMPT = """You author one SQL answer to a single user question against the eToro Databricks Unity Catalog warehouse.

You have THREE tools:
  - describe_table(fqn)  — inspect columns + types. Free to use.
  - probe_sql(sql)       — run a small exploratory query (up to 50 rows). Free to use.
  - submit_answer(sql)   — the final answer. Call ONCE.

Decision discipline (think before you submit):
  1. **Read the question carefully.** Is it about a *point-in-time / snapshot* fact (AUM, equity, NOP, balance, position-PnL as a snapshot, "as of date X")? Or a *flow* fact (deposits, withdrawals, fees, MIMO, revenue, transactions on day X)?
       - Snapshot questions: filter on `DateID = X`. Never `<=`. Never sum across history.
       - Flow questions: filter on `DateID = X` (the single day). Aggregate that one day.
  2. **Always describe_table each table you'll use.** UC mirror columns are not Synapse-shaped (RealCID not CID, MoneyInUSD not MoneyIn).
  3. **Probe enums and categories you don't know with certainty.** If the question says "Admin Fee" and the table has a `Metric` column, do not guess `'AdminFee'` vs `'DormantFee'` vs `'admin_fee'`. Run `SELECT DISTINCT Metric FROM ... WHERE DateID = X` first. Same for `MIMOPlatform`, `ActionType`, `RegulationName`, etc.
  4. **Probe before composing complex bundles.** If the question implies a bundle of metrics (e.g. "Full Commission combines retail commission with ticket fees"), probe what's actually in `IncludedInTotalRevenue` for that day, or what distinct Metric values appear, before unioning them.
  5. **Apply the valid-users SCD-2 contract by default** unless the question explicitly opts out (\"include non-valids\", \"internal\", \"test\"). Join `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` ON RealCID, `IsValidCustomer = 1`, `DateID BETWEEN snap.FromDateID AND snap.ToDateID`.
  6. **Final SQL: single scalar in row[0][0].** Aggregate. Use INT YYYYMMDD for DateID. No trailing semicolon. No prose.

Workflow:
  describe_table all candidate tables → probe any uncertain enum/category/bundle → submit_answer once.
"""


_USER_PROMPT_TEMPLATE = """USER QUESTION:
{question}

GROUNDING SKILL  (from skills_get_skill — canonical truth surface):
id:    {skill_id}
score: {skill_score}

body_markdown:
---
{body_markdown}
---

example_sql (may be null):
{example_sql}

Begin. Describe the tables you need, then call execute_sql once."""


# ---------------------------------------------------------------------------
# MCP response unwrapping
# ---------------------------------------------------------------------------

def _unwrap_text_content(rpc_result: Any) -> str:
    if not isinstance(rpc_result, dict):
        raise MCPClientError(f"Unexpected tools/call result type: {type(rpc_result)}")
    if rpc_result.get("isError"):
        msg = ""
        for c in rpc_result.get("content") or []:
            if c.get("type") == "text":
                msg = c.get("text", "")
                break
        raise MCPClientError(f"MCP tool reported isError=true: {msg[:500]}")
    for c in rpc_result.get("content") or []:
        if c.get("type") == "text":
            return c.get("text", "")
    raise MCPClientError(f"MCP tool returned no text content: {rpc_result!r}")


def _parse_skill_body(get_skill_text: str) -> dict:
    try:
        return json.loads(get_skill_text)
    except json.JSONDecodeError as e:
        raise MCPClientError(
            f"skills_get_skill returned non-JSON: {get_skill_text[:300]!r}"
        ) from e


def _parse_find_skills(find_skills_text: str) -> dict:
    try:
        d = json.loads(find_skills_text)
    except json.JSONDecodeError as e:
        raise MCPClientError(
            f"skills_find_skills returned non-JSON: {find_skills_text[:300]!r}"
        ) from e
    if "skills" not in d:
        raise MCPClientError(f"skills_find_skills missing `skills`: {d!r}")
    return d


def _parse_execute_sql_rows(execute_sql_text: str) -> tuple[list[str], list[list]]:
    """Parse the JSON-array shape returned by `databricks_ops_execute_sql(output_format='json')`.

    Markdown table fallback retained defensively for older server versions.
    """
    txt = (execute_sql_text or "").strip()
    if not txt:
        return [], []
    if txt.startswith("["):
        try:
            arr = json.loads(txt)
        except json.JSONDecodeError as e:
            raise MCPClientError(f"execute_sql JSON parse failed: {e}") from e
        if not arr:
            return [], []
        cols = list(arr[0].keys())
        rows = [[r.get(c) for c in cols] for r in arr]
        return cols, rows
    lines = [l for l in txt.splitlines() if l.strip()]
    if len(lines) >= 2 and lines[0].startswith("|") and re.match(r"\|\s*-+", lines[1]):
        cols = [c.strip() for c in lines[0].strip("|").split("|")]
        rows: list[list] = []
        for ln in lines[2:]:
            if ln.startswith("|"):
                cells = [c.strip() for c in ln.strip("|").split("|")]
                if len(cells) == len(cols):
                    rows.append(cells)
        return cols, rows
    return [], []


def _coerce_scalar(v: Any) -> float | None:
    if v is None:
        return None
    if isinstance(v, (int, float)) and not isinstance(v, bool):
        return float(v)
    if isinstance(v, str):
        s = v.strip().replace(",", "")
        if s == "":
            return None
        try:
            return float(s)
        except ValueError:
            return None
    return None


# ---------------------------------------------------------------------------
# DESCRIBE-result formatting
# ---------------------------------------------------------------------------

def _format_probe_for_model(
    cols: list[str],
    rows: list[list],
    *,
    row_cap: int,
    chars_cap: int,
) -> str:
    """Render a probe_sql result as a compact pipe-separated table the
    model can read without blowing its context window."""
    if not cols and not rows:
        return "(no rows)"
    if not rows:
        return f"(0 rows; columns: {' | '.join(cols)})"
    truncated_rows = rows[:row_cap]
    header = " | ".join(cols)
    out_lines = [header, "-" * min(len(header), 200)]
    for r in truncated_rows:
        cells = []
        for v in r:
            s = "" if v is None else str(v)
            s = s.replace("\n", " ").replace("\r", " ")
            if len(s) > 80:
                s = s[:77] + "..."
            cells.append(s)
        out_lines.append(" | ".join(cells))
    if len(rows) > row_cap:
        out_lines.append(f"... ({len(rows) - row_cap} more rows truncated)")
    out = "\n".join(out_lines)
    if len(out) > chars_cap:
        out = out[: chars_cap - 50] + f"\n... (truncated at {chars_cap} chars)"
    return out


def _format_describe_for_model(rows: list[list], cols: list[str]) -> str:
    """`DESCRIBE TABLE EXTENDED <fqn>` on Databricks returns rows of
    (col_name, data_type, comment) followed by a blank-row separator and
    then partition / detailed-table-information sections we don't need.

    We project to a compact column dictionary and stop at the first
    blank-name row (which marks the end of the column list).
    """
    if not rows:
        return "(no rows from DESCRIBE)"
    out_lines = ["column_name | data_type | comment"]
    for r in rows:
        if not r or len(r) < 2:
            continue
        col = (r[0] or "").strip() if isinstance(r[0], str) else str(r[0])
        if col == "" or col.startswith("#"):
            # End of column list (blank row, or '# Detailed Table Information' marker).
            break
        dtype = (r[1] or "").strip() if isinstance(r[1], str) else str(r[1])
        comment = ""
        if len(r) >= 3 and r[2] is not None:
            comment = str(r[2]).replace("\n", " ").strip()[:200]
        out_lines.append(f"{col} | {dtype} | {comment}")
    return "\n".join(out_lines)


# ---------------------------------------------------------------------------
# The SUT
# ---------------------------------------------------------------------------

class DirectMcpSUT(SUT):
    name = "direct_mcp"

    def __init__(
        self,
        *,
        mcp_server_id: str = "databricks-stg",
        mcp_command: list[str] | None = None,
        llm_backend: str = "databricks",
        llm_model: str | None = None,
        llm_kwargs: dict | None = None,
        skill_top_k: int = 5,
        sql_temperature: float = 0.0,
        body_markdown_clip_chars: int = 24000,
        request_timeout_s: float = 90.0,
        max_agent_rounds: int = 12,
        max_describe_calls: int = 8,
        max_probe_calls: int = 6,
        probe_row_cap: int = 50,
        probe_chars_cap: int = 4000,
        agent_round_max_tokens: int = 2000,
    ) -> None:
        cmd = mcp_command or load_mcp_command_from_cursor_config(mcp_server_id)
        self._cli = MCPStdioClient(cmd, request_timeout_s=request_timeout_s)
        self._cli.start()
        try:
            self._cli.initialize()
        except Exception:
            self._cli.close()
            raise

        llm_kwargs = dict(llm_kwargs or {})
        if llm_model and llm_backend == "databricks":
            llm_kwargs.setdefault("endpoint_name", llm_model)
        self._llm: LLMDriver = get_llm_driver(llm_backend, **llm_kwargs)
        self._llm_model = llm_model

        self._skill_top_k = skill_top_k
        self._sql_temperature = sql_temperature
        self._body_clip = body_markdown_clip_chars
        self._max_rounds = max_agent_rounds
        self._max_describes = max_describe_calls
        self._max_probes = max_probe_calls
        self._probe_row_cap = probe_row_cap
        self._probe_chars_cap = probe_chars_cap
        self._round_max_tokens = agent_round_max_tokens

    # ------------------------------------------------------------------

    def close(self) -> None:
        try:
            self._cli.close()
        except Exception:  # noqa: BLE001
            pass

    def __del__(self) -> None:
        try:
            self.close()
        except Exception:  # noqa: BLE001
            pass

    # ------------------------------------------------------------------

    def ask(self, question: str, case: CaseV1) -> SUTResponse:  # noqa: D401
        t_total0 = time.monotonic()
        mcp_calls_log: list[dict] = []
        llm_calls_log: list[dict] = []
        # Phase 1: skill grounding
        try:
            skill_top_id, ground_id, body_md, example_sql, top_score = \
                self._ground_in_skill(question, mcp_calls_log)
        except _SUTAbort as ab:
            return ab.to_response(t_total0, mcp_calls_log, llm_calls_log)

        # Phase 2: agentic loop
        msgs: list[dict] = [
            {"role": "system", "content": _SYSTEM_PROMPT},
            {"role": "user", "content": _USER_PROMPT_TEMPLATE.format(
                question=question,
                skill_id=ground_id,
                skill_score=top_score,
                body_markdown=body_md,
                example_sql=example_sql or "(null)",
            )},
        ]
        describe_count = 0
        probe_count = 0
        terminate_reason = "max_rounds"
        final_sql: str | None = None
        final_sql_text: str = ""

        for rnd in range(1, self._max_rounds + 1):
            try:
                llm_resp = self._llm.complete(
                    messages=msgs,
                    model=self._llm_model,
                    max_tokens=self._round_max_tokens,
                    temperature=self._sql_temperature,
                    timeout_s=120.0,
                    tools=_AGENT_TOOLS,
                    tool_choice="auto",
                )
            except LLMError as e:
                terminate_reason = "llm_error"
                return self._error("LLM call failed", e, t_total0,
                                   mcp_calls_log,
                                   extra={
                                       "llm_calls": llm_calls_log,
                                       "skill_top_id": skill_top_id,
                                       "skill_ground_id": ground_id,
                                       "skill_body_chars": len(body_md),
                                       "describe_count": describe_count,
                                       "probe_count": probe_count,
                                       "agent_rounds": rnd - 1,
                                       "terminate_reason": terminate_reason,
                                   })
            llm_calls_log.append(_llm_record_dict(llm_resp))

            tcs = llm_resp.tool_calls or []
            if not tcs:
                # No tool call. Either model is asking clarifying question (rare
                # at temp=0) or wrote SQL into content. Try to recover SQL from
                # plain content so we don't waste the round.
                final_sql = _maybe_extract_inline_sql(llm_resp.text)
                if final_sql:
                    terminate_reason = "inline_sql"
                    final_sql_text = llm_resp.text
                    break
                terminate_reason = "no_tool_call_no_sql"
                break

            # Carry the assistant message back so subsequent rounds see context
            msgs.append({
                "role": "assistant",
                "content": llm_resp.text or None,
                "tool_calls": tcs,
            })

            # Process tool calls in order
            wants_submit = False
            for tc in tcs:
                fn = (tc.get("function") or {})
                name = fn.get("name") or ""
                args_str = fn.get("arguments") or "{}"
                try:
                    args = json.loads(args_str)
                except json.JSONDecodeError:
                    args = {}
                tool_use_id = tc.get("id") or ""

                if name == "submit_answer" or name == "execute_sql":
                    # `execute_sql` kept as alias for forward-compat; both
                    # are terminal.
                    final_sql = (args.get("sql") or "").strip().rstrip(";")
                    final_sql_text = llm_resp.text or ""
                    terminate_reason = name
                    wants_submit = True
                    break  # ignore any further tool calls after terminal
                elif name == "describe_table":
                    if describe_count >= self._max_describes:
                        msgs.append({
                            "role": "tool",
                            "tool_call_id": tool_use_id,
                            "content": (
                                f"ERROR: describe_table cap of "
                                f"{self._max_describes} reached. Submit the "
                                "final answer now with what you have."
                            ),
                        })
                        continue
                    fqn = (args.get("fqn") or "").strip()
                    descr_text, descr_err = self._describe_table(
                        fqn, mcp_calls_log)
                    describe_count += 1
                    msgs.append({
                        "role": "tool",
                        "tool_call_id": tool_use_id,
                        "content": descr_err or descr_text,
                    })
                elif name == "probe_sql":
                    if probe_count >= self._max_probes:
                        msgs.append({
                            "role": "tool",
                            "tool_call_id": tool_use_id,
                            "content": (
                                f"ERROR: probe_sql cap of "
                                f"{self._max_probes} reached. Submit the "
                                "final answer now."
                            ),
                        })
                        continue
                    sql = (args.get("sql") or "").strip().rstrip(";")
                    probe_text, probe_err = self._probe_sql(sql, mcp_calls_log)
                    probe_count += 1
                    msgs.append({
                        "role": "tool",
                        "tool_call_id": tool_use_id,
                        "content": probe_err or probe_text,
                    })
                else:
                    msgs.append({
                        "role": "tool",
                        "tool_call_id": tool_use_id,
                        "content": (
                            f"ERROR: unknown tool {name!r}. Use only "
                            "describe_table, probe_sql, or submit_answer."
                        ),
                    })

            if wants_submit:
                break
        # endfor rounds

        # Phase 3: execute the final SQL the model produced
        if not final_sql:
            return self._error(
                f"agent terminated with no final SQL ({terminate_reason})",
                RuntimeError("no execute_sql"),
                t_total0, mcp_calls_log,
                extra={
                    "llm_calls": llm_calls_log,
                    "skill_top_id": skill_top_id,
                    "skill_ground_id": ground_id,
                    "skill_body_chars": len(body_md),
                    "describe_count": describe_count,
                    "probe_count": probe_count,
                    "agent_rounds": rnd,
                    "terminate_reason": terminate_reason,
                },
            )

        try:
            r3 = self._cli.call_tool("databricks_ops_execute_sql", {
                "sql_query": final_sql,
                "output_format": "json",
            })
        except (MCPClientError, MCPRpcError) as e:
            return self._error(
                "databricks_ops_execute_sql failed", e, t_total0, mcp_calls_log,
                extra={
                    "llm_calls": llm_calls_log,
                    "skill_top_id": skill_top_id,
                    "skill_ground_id": ground_id,
                    "skill_body_chars": len(body_md),
                    "describe_count": describe_count,
                    "probe_count": probe_count,
                    "agent_rounds": rnd,
                    "terminate_reason": terminate_reason,
                    "sql": final_sql,
                },
            )
        mcp_calls_log.append(_call_record_dict(self._cli.call_records[-1]))
        try:
            sql_text = _unwrap_text_content(r3)
        except MCPClientError as e:
            return self._error("execute_sql isError or no content", e,
                               t_total0, mcp_calls_log,
                               extra={
                                   "llm_calls": llm_calls_log,
                                   "skill_top_id": skill_top_id,
                                   "skill_ground_id": ground_id,
                                   "skill_body_chars": len(body_md),
                                   "describe_count": describe_count,
                                   "probe_count": probe_count,
                                   "agent_rounds": rnd,
                                   "terminate_reason": terminate_reason,
                                   "sql": final_sql,
                               })
        cols, rows = _parse_execute_sql_rows(sql_text)
        scalar = _coerce_scalar(rows[0][0]) if rows and rows[0] else None

        elapsed_ms = int((time.monotonic() - t_total0) * 1000)
        raw = {
            "backend": self.name,
            "mcp_calls": mcp_calls_log,
            "llm_calls": llm_calls_log,
            "skill_top_id": skill_top_id,
            "skill_ground_id": ground_id,
            "skill_body_chars": len(body_md),
            "describe_count": describe_count,
            "probe_count": probe_count,
            "agent_rounds": rnd,
            "terminate_reason": terminate_reason,
            "sql": final_sql,
            "sql_result_cols": cols,
            "sql_result_rows": rows[:5],
            "sql_result_row_count": len(rows),
        }
        last_llm = llm_calls_log[-1] if llm_calls_log else {}
        text_answer = (
            f"{last_llm.get('backend')}/{last_llm.get('model')} grounded "
            f"on {ground_id!r}; {describe_count} describes, "
            f"{probe_count} probes, {rnd} rounds; "
            f"row[0]={rows[0] if rows else None!r}; scalar={scalar!r}."
        )
        return SUTResponse(
            numeric_answer=scalar,
            text_answer=text_answer,
            sql_used=final_sql,
            raw=raw,
            error=None if scalar is not None else "no scalar in first row",
            elapsed_ms=elapsed_ms,
        )

    # ------------------------------------------------------------------
    # Phase 1 helper
    # ------------------------------------------------------------------

    def _ground_in_skill(
        self,
        question: str,
        mcp_calls_log: list[dict],
    ) -> tuple[str, str, str, str | None, float]:
        try:
            r1 = self._cli.call_tool("skills_find_skills", {
                "question": question,
                "k": self._skill_top_k,
            })
        except (MCPClientError, MCPRpcError) as e:
            raise _SUTAbort(f"skills_find_skills failed: {e}")
        mcp_calls_log.append(_call_record_dict(self._cli.call_records[-1]))

        try:
            payload = _parse_find_skills(_unwrap_text_content(r1))
        except (MCPClientError, ValueError) as e:
            raise _SUTAbort(f"could not parse skills_find_skills: {e}")

        skills = payload.get("skills") or []
        if not skills:
            raise _SUTAbort("skills_find_skills returned 0 skills")
        top = skills[0]
        top_id = str(top.get("id") or "").strip()
        top_score = float(top.get("score") or 0.0)
        sub_id: str | None = None
        sub_skills = top.get("matched_sub_skills") or []
        if sub_skills:
            cand = sub_skills[0]
            if isinstance(cand, dict):
                sub_id = (cand.get("id") or cand.get("name") or "").strip() or None
            elif isinstance(cand, str):
                sub_id = cand
        ground_id = sub_id or top_id

        try:
            r2 = self._cli.call_tool("skills_get_skill", {"id": ground_id})
        except (MCPClientError, MCPRpcError) as e:
            raise _SUTAbort(f"skills_get_skill({ground_id!r}) failed: {e}")
        mcp_calls_log.append(_call_record_dict(self._cli.call_records[-1]))

        try:
            body = _parse_skill_body(_unwrap_text_content(r2))
        except MCPClientError as e:
            raise _SUTAbort(f"could not parse skills_get_skill: {e}")
        body_md = (body.get("body_markdown") or "")[: self._body_clip]
        return top_id, ground_id, body_md, body.get("example_sql"), top_score

    # ------------------------------------------------------------------
    # describe_table proxy
    # ------------------------------------------------------------------

    def _describe_table(
        self,
        fqn: str,
        mcp_calls_log: list[dict],
    ) -> tuple[str, str | None]:
        """Return (describe_text_for_model, error_or_None)."""
        if not fqn or not re.match(r"^[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+$", fqn):
            return "", (
                f"ERROR: invalid fqn {fqn!r}. Expected three-part name "
                f"<catalog>.<schema>.<table>."
            )
        sql = f"DESCRIBE TABLE EXTENDED {fqn}"
        try:
            r = self._cli.call_tool("databricks_ops_execute_sql", {
                "sql_query": sql,
                "output_format": "json",
            })
        except (MCPClientError, MCPRpcError) as e:
            return "", f"ERROR: describe_table({fqn}) failed: {e}"
        mcp_calls_log.append(_call_record_dict(self._cli.call_records[-1]))
        try:
            text = _unwrap_text_content(r)
        except MCPClientError as e:
            return "", f"ERROR: describe_table({fqn}) returned isError: {e}"
        cols, rows = _parse_execute_sql_rows(text)
        return _format_describe_for_model(rows, cols), None

    # ------------------------------------------------------------------
    # probe_sql proxy
    # ------------------------------------------------------------------

    def _probe_sql(
        self,
        sql: str,
        mcp_calls_log: list[dict],
    ) -> tuple[str, str | None]:
        """Run a small exploratory SQL through the MCP gateway.

        Caps result at ``self._probe_row_cap`` rows and ``self._probe_chars_cap``
        characters of formatted output, so the model can't blow its context
        window on a runaway probe. Returns (formatted_text, error_or_None).
        """
        if not sql:
            return "", "ERROR: probe_sql requires a non-empty `sql` argument."
        # Defensive: refuse anything that doesn't START with SELECT/WITH/SHOW/DESCRIBE.
        # We don't want the model running INSERT/UPDATE/DELETE through probe.
        head = sql.lstrip().split(None, 1)[0].upper() if sql.strip() else ""
        if head not in ("SELECT", "WITH", "SHOW", "DESCRIBE", "DESC", "EXPLAIN"):
            return "", (
                "ERROR: probe_sql is read-only. Statement must start with "
                "SELECT, WITH, SHOW, DESCRIBE, or EXPLAIN."
            )
        try:
            r = self._cli.call_tool("databricks_ops_execute_sql", {
                "sql_query": sql,
                "output_format": "json",
            })
        except (MCPClientError, MCPRpcError) as e:
            return "", f"ERROR: probe_sql failed: {e}"
        mcp_calls_log.append(_call_record_dict(self._cli.call_records[-1]))
        try:
            text = _unwrap_text_content(r)
        except MCPClientError as e:
            return "", f"ERROR: probe_sql returned isError: {e}"
        cols, rows = _parse_execute_sql_rows(text)
        return _format_probe_for_model(
            cols, rows,
            row_cap=self._probe_row_cap,
            chars_cap=self._probe_chars_cap,
        ), None

    # ------------------------------------------------------------------

    @staticmethod
    def _error(
        what: str,
        exc: BaseException,
        t_total0: float,
        mcp_calls_log: list[dict],
        *,
        extra: dict | None = None,
    ) -> SUTResponse:
        elapsed_ms = int((time.monotonic() - t_total0) * 1000)
        raw: dict = {"backend": "direct_mcp", "mcp_calls": mcp_calls_log}
        if extra:
            raw.update(extra)
        return SUTResponse(
            numeric_answer=None,
            text_answer=None,
            sql_used=(extra or {}).get("sql"),
            raw=raw,
            error=f"{what}: {type(exc).__name__}: {exc}",
            elapsed_ms=elapsed_ms,
        )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

class _SUTAbort(RuntimeError):
    """Internal control-flow signal used by `_ground_in_skill`."""

    def to_response(self, t0: float, mcp_calls_log, llm_calls_log) -> SUTResponse:
        elapsed_ms = int((time.monotonic() - t0) * 1000)
        return SUTResponse(
            numeric_answer=None,
            text_answer=None,
            sql_used=None,
            raw={"backend": "direct_mcp",
                 "mcp_calls": mcp_calls_log,
                 "llm_calls": llm_calls_log},
            error=f"grounding aborted: {self}",
            elapsed_ms=elapsed_ms,
        )


_FENCE_RE = re.compile(r"```(?:sql|databricks-sql|SQL)?\s*\n(.+?)\n```", re.DOTALL)


def _maybe_extract_inline_sql(text: str | None) -> str | None:
    """Recovery: if a model writes SQL into `content` instead of using the
    execute_sql tool, pull it out so we don't waste the round."""
    if not text:
        return None
    m = _FENCE_RE.search(text)
    if m:
        return m.group(1).strip().rstrip(";")
    if "SELECT" in text.upper():
        return text.strip().rstrip(";")
    return None


def _call_record_dict(rec) -> dict:
    result_excerpt = None
    if rec.result is not None:
        try:
            txt = json.dumps(rec.result, default=str)
            result_excerpt = txt[:500] + ("..." if len(txt) > 500 else "")
        except (TypeError, ValueError):
            result_excerpt = "<unserialisable>"
    # Surface the SQL when this MCP call was an execute_sql, so describe_table
    # vs final-execute is disambiguated downstream.
    sql_excerpt = None
    if rec.method == "tools/call" and rec.params:
        nested = (rec.params.get("arguments") or {})
        sql = nested.get("sql_query")
        if isinstance(sql, str):
            sql_excerpt = sql[:200] + ("..." if len(sql) > 200 else "")
    return {
        "method": rec.method,
        "tool": (rec.params or {}).get("name"),
        "params_keys": sorted((rec.params or {}).keys()),
        "sql_excerpt": sql_excerpt,
        "elapsed_ms": rec.elapsed_ms,
        "error": rec.error,
        "result_excerpt": result_excerpt,
    }


def _llm_record_dict(resp: LLMResponse) -> dict:
    return {
        "backend": resp.backend,
        "model": resp.model,
        "elapsed_ms": resp.elapsed_ms,
        "input_tokens": resp.input_tokens,
        "output_tokens": resp.output_tokens,
        "finish_reason": resp.finish_reason,
        "tool_calls": [
            {"name": (tc.get("function") or {}).get("name"),
             "args_excerpt": ((tc.get("function") or {}).get("arguments") or "")[:200]}
            for tc in (resp.tool_calls or [])
        ],
        "text_excerpt": (resp.text or "")[:500],
    }
