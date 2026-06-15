"""[DEPRECATED 2026-06-14] SUT that drives the `cursor-agent` CLI in headless mode.

DEPRECATION REASON
==================
This SUT does NOT exercise the user's custom Databricks MCP. Verified
empirically (see audits/eval_suite/probe_funded_cli.txt):

  - Headless cursor-agent CLI cannot reach the OAuth-protected
    `databricks-stg` MCP gateway from a stdio subprocess (mcp-remote
    won't complete the OAuth handshake without an interactive browser).
  - Even when reachable, workspace rule `mcp-latency-signal.mdc` rule 4
    + the `databricks-connection` skill's "prefer dbx_query.py" guidance
    actively steer the agent to `python tools/dbx_query.py` for SQL.

In practice every case routed via this SUT:
  * file_read on `.cursor/skills/...md`  (NOT `skills_get_skill`)
  * shellToolCall: `python tools/dbx_query.py "<sql>"`  (NOT `databricks_ops_execute_sql`)
  * zero MCP tool calls in the trace

The MCP-only enforcement rule + bypass detector we added were correct in
spirit but couldn't fix the underlying architectural mismatch.

For the actual Databricks MCP eval, use `direct_mcp_sut.DirectMcpSUT` —
it spawns `npx mcp-remote` directly, speaks JSON-RPC, and calls the MCP
tools by hand.

This SUT remains useful as a CONTROL/BASELINE — "what does the model
+ skill markdown achieve when the MCP is bypassed?" — but should never
again be marketed as an MCP eval. Set `enforce_mcp_only=False` if used
for that purpose.

Original docstring follows.

----

SUT that drives the `cursor-agent` CLI in headless mode.

This is the SUT that most faithfully mimics how an actual Cursor user
asks a question: a fresh agent process per question, no prior context,
the same MCP servers attached as the user has, the same model, the
same skills corpus, the same approval prompts auto-accepted.

How it works
------------

For each eval case we shell out to:

    cursor-agent --print --output-format stream-json \\
                 --model <model> \\
                 --trust --approve-mcps --force \\
                 --workspace <repo> \\
                 "<NL question>"

cursor-agent emits one JSON object PER LINE: system/init, user, thinking
deltas, assistant chunks, tool_call started/completed, and a final result
event with `usage` token counts. We parse the full stream into a
StreamTrace summary that captures:

  - which skills were loaded (file_read on .cursor/skills/, or MCP
    skills_get_skill / skills_find_skills)
  - every SQL that ran, success or failure, and its result excerpt
    (whether dispatched via `python tools/dbx_query.py` or via
    `databricks_sql_*` MCP tools)
  - tool-call counts by kind, MCP tool counts by name
  - thinking text (model's chain of thought) and final assistant text
  - token usage and cache hits

The numeric scalar is parsed from the final assistant text (same parser
as before). The structured trace rides along in `SUTResponse.raw` so the
runner / telemetry can promote selected fields into the CSV schema.

Auth
----
Requires `CURSOR_API_KEY` in the environment. Pass it via the constructor or
set it ahead of time. Costs Cursor credits per call (~3-4k output tokens at
Sonnet 4.5 rates).

MCP servers
-----------
cursor-agent inherits MCP servers from `~/.cursor/mcp.json` (or per-project
`.cursor/mcp.json`). Make sure `user-databricks-stg` is configured there
before running the SUT.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path

import atexit
import json as _json

from ..schema import CaseV1
from .base import SUT, SUTResponse
from ._stream_json import (
    StreamTrace,
    decode_stream_bytes,
    parse_stream_jsonl,
    parse_trace,
)
from ._mcp_guard import (
    activate_mcp_only_rule,
    deactivate_mcp_only_rule,
    detect_mcp_bypass_violations,
    trace_engaged_mcp_sql,
)


# No suffix — the agent gets the bare NL question, exactly as a user would
# ask it. Anything else would be the harness improving the agent's behavior,
# which defeats the point of measuring zero-shot accuracy.
_HARNESS_SUFFIX = ""



# Best-effort scalar extraction from the model's text reply.
#   -- accepts: 1234, 1234.56, 1.23e6, -42, 0
#   -- ignores: leading commentary, trailing units, the MCP-latency-signal prelude
_SCALAR_RE = re.compile(
    r"(?<![A-Za-z0-9_])"               # word boundary on the left
    r"(-?\d{1,3}(?:,\d{3})*(?:\.\d+)?" # 1,234,567.89
    r"|-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)"   # plain or scientific
    r"(?![A-Za-z0-9_])"                # word boundary on the right
)


@dataclass
class _ProcessResult:
    """Subprocess result. stdout is bytes (we decode with BOM-awareness later)."""
    stdout_bytes: bytes
    stderr: str
    returncode: int
    elapsed_ms: int


def _resolve_cursor_agent_entrypoint() -> tuple[list[str], str]:
    """Resolve the real cursor-agent entrypoint.

    Returns (argv_prefix, label):
      - argv_prefix: the prefix command/args to invoke (no shell required)
      - label: human-readable description for error messages

    On Windows, the cursor-agent CLI is shipped as a PowerShell shim that
    locates the latest versioned `node.exe + index.js` pair under
    %LOCALAPPDATA%\\cursor-agent\\versions\\<YYYY.MM.DD-hash>\\. Going through
    the .ps1 shim forces us through PowerShell argument-passing, which mangles
    embedded quotes, em-dashes, apostrophes, and newlines on systems with a
    non-UTF-8 locale (cp1255 / cp1252). We bypass the shim and call node + index.js
    directly — clean argv arrays, no shell quoting at all.

    On Linux/macOS the CLI is just a binary on PATH; pass it through.
    """
    if not sys.platform.startswith("win"):
        return (["cursor-agent"], "cursor-agent (PATH)")

    # Resolve %LOCALAPPDATA%\cursor-agent\versions\<latest>\index.js + node.exe.
    base = Path(os.environ.get("LOCALAPPDATA", "")) / "cursor-agent"
    if not base.exists():
        # Fallback: trust PATH (.ps1 shim). May still mangle non-ASCII args.
        return (["cursor-agent"], "cursor-agent (PATH .ps1 shim — non-ASCII may break)")

    # Same regex / sort as the shim does.
    version_re = re.compile(r"^\d{4}\.\d{1,2}\.\d{1,2}-[a-f0-9]+$")
    versions_dir = base / "versions"
    candidates: list[tuple[tuple[int, int, int], Path]] = []
    if versions_dir.is_dir():
        for d in versions_dir.iterdir():
            if d.is_dir() and version_re.match(d.name):
                y, m, day = d.name.split("-")[0].split(".")
                candidates.append(((int(y), int(m), int(day)), d))
    if not candidates:
        return (["cursor-agent"], "cursor-agent (PATH; no versioned install found)")

    candidates.sort(reverse=True)
    latest = candidates[0][1]
    node_exe = latest / "node.exe"
    index_js = latest / "index.js"
    if not node_exe.exists() or not index_js.exists():
        return (["cursor-agent"], "cursor-agent (PATH; latest version dir incomplete)")

    return ([str(node_exe), str(index_js)], f"node.exe + {index_js}")


_CURSOR_AGENT_ARGV_PREFIX, _CURSOR_AGENT_LABEL = _resolve_cursor_agent_entrypoint()


def _run_cursor_agent(
    *,
    prompt: str,
    api_key: str,
    model: str,
    workspace: Path,
    timeout_s: int,
    extra_args: list[str] | None = None,
) -> _ProcessResult:
    """Spawn one cursor-agent invocation. Pure subprocess, NO shell.

    We pass argv as a list to subprocess so embedded apostrophes, em-dashes,
    newlines, and other unicode in the prompt aren't mangled by cmd/PowerShell
    quoting. This is critical for eval prompts that come straight from YAML.
    """
    cmd: list[str] = list(_CURSOR_AGENT_ARGV_PREFIX) + [
        "--print",
        "--output-format", "stream-json",
        "--model", model,
        "--trust",
        "--approve-mcps",
        "--force",
        "--workspace", str(workspace),
    ]
    if extra_args:
        cmd.extend(extra_args)
    cmd.append(prompt)

    env = dict(os.environ)
    env["CURSOR_API_KEY"] = api_key
    # Encourage UTF-8 IO inside the node child + tools.
    env.setdefault("PYTHONIOENCODING", "utf-8")
    env.setdefault("PYTHONUTF8", "1")
    env.setdefault("LANG", "en_US.UTF-8")
    env.setdefault("LC_ALL", "en_US.UTF-8")

    t0 = time.monotonic()
    proc = subprocess.run(
        cmd,
        capture_output=True,
        env=env,
        timeout=timeout_s,
        # NB: shell=False is the default; explicit for emphasis.
        shell=False,
    )
    elapsed_ms = int((time.monotonic() - t0) * 1000)
    stderr = (proc.stderr or b"").decode("utf-8", errors="replace")
    return _ProcessResult(
        stdout_bytes=proc.stdout or b"",
        stderr=stderr,
        returncode=proc.returncode,
        elapsed_ms=elapsed_ms,
    )


# Numeric tokens with optional $-prefix and K/M/B suffix.
# Anchored captures so we can recover provenance (negative-sign placement,
# $ prefix, magnitude suffix) for the scoring pass.
#
# Two sign positions allowed:
#   - "-$1,234,567.89"     — sign BEFORE $
#   - "$-1,234,567.89"     — sign AFTER $ (rare but seen)
#   - "-1,234,567.89"      — bare negative (no $)
#   - "$1,234,567.89"      — positive amount
#   - "1,234,567.89"       — bare number
_MONEY_TOKEN_RE = re.compile(
    r"(?P<lead_sign>-)?"                     # optional sign before $
    r"(?P<dollar>\$)?"                       # optional $
    r"(?P<inner_sign>-)?"                    # optional sign after $
    r"\s*"
    r"(?P<num>\d{1,3}(?:,\d{3})+(?:\.\d+)?"  # 1,234,567.89
    r"|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)"      # plain or scientific
    r"\s*(?P<suffix>[KkMmBb])?"              # optional magnitude suffix
)

# Word-boundary check helpers for the noise filter (years, DateIDs, etc.)
_WORD_CHAR = re.compile(r"[A-Za-z0-9_]")

# Words that, when they FOLLOW a number, mark it as a count (not a money amount).
# We use these to disambiguate bolded counts ("**19,880** transactions") from
# bolded amounts ("**$1,234,567** revenue") in the same reply.
_COUNT_UNIT_WORDS = (
    "transactions", "customers", "users", "actions", "trades", "positions",
    "position-instances", "rows", "records", "events", "deposits", "withdrawals",
    "people",
)
# Length of the lookahead window for the count-word check (chars after the number)
_COUNT_LOOKAHEAD_CHARS = 60


@dataclass(frozen=True)
class _Candidate:
    """One numeric token in the agent's reply, with provenance for scoring."""
    value: float
    span: tuple[int, int]
    is_bold: bool
    is_dollar: bool
    is_negative: bool
    has_count_word_after: bool
    in_headline: bool  # Inside a markdown header (## ...) or first 200 chars


def _is_noise(v: float) -> bool:
    """Tokens that are NEVER the answer in our v1 case set."""
    if abs(v) <= 100:
        return True
    # Years
    if 1900 <= abs(v) <= 2099 and v == int(v):
        return True
    # YYYYMMDD-shaped integers
    if 19000000 <= abs(v) <= 21000000 and v == int(v):
        return True
    return False


def _has_count_word_after(text: str, end_pos: int) -> bool:
    window = text[end_pos: end_pos + _COUNT_LOOKAHEAD_CHARS].lower()
    # Skip leading whitespace + small unit-glyphs (`)`, `*`, etc.)
    return any(re.search(rf"\b{re.escape(w)}\b", window) for w in _COUNT_UNIT_WORDS)


def _is_bold(text: str, span: tuple[int, int]) -> bool:
    """True if the number is wrapped in markdown bold (**...** or __...__).

    We don't try to fully parse markdown — just check if there are double-stars
    or double-underscores around the span with no closing in between.
    """
    start, end = span
    # Look back up to 30 chars for an opening **; look forward up to 30 for closing.
    pre = text[max(0, start - 40): start]
    post = text[end: end + 40]
    open_pre = pre.rfind("**")
    if open_pre == -1:
        return False
    # Make sure the ** isn't already closed before our span
    close_between = pre.find("**", open_pre + 2)
    if close_between != -1:
        return False
    # Find the next ** in post
    return "**" in post


def _is_in_headline(text: str, span: tuple[int, int]) -> bool:
    """True if the number sits in a markdown header line OR the first 200 chars."""
    start, _end = span
    if start <= 200:
        return True
    # Find the start of the line containing this span
    line_start = text.rfind("\n", 0, start) + 1
    line_prefix = text[line_start: line_start + 4]
    return line_prefix.startswith(("## ", "### ", "# "))


def _extract_candidates(text: str) -> list[_Candidate]:
    """Walk the text once, collect all numeric candidates with provenance."""
    out: list[_Candidate] = []
    for m in _MONEY_TOKEN_RE.finditer(text):
        # Word-boundary check: skip if there's an alphanumeric directly before/after
        # the FULL match (including sign / $ / suffix). This rejects things like
        # `v1.2.3` or `id_12345`.
        s, e = m.start(), m.end()
        if s > 0 and _WORD_CHAR.match(text[s - 1]):
            continue
        if e < len(text) and _WORD_CHAR.match(text[e]):
            # But allow trailing letters that aren't word-continuations (e.g. "K" already absorbed)
            # Already absorbed K/M/B in the regex; any other letter means we hit a word.
            continue

        num_raw = m.group("num").replace(",", "")
        try:
            v = float(num_raw)
        except ValueError:
            continue
        if m.group("suffix"):
            mult = {"k": 1e3, "K": 1e3, "m": 1e6, "M": 1e6, "b": 1e9, "B": 1e9}[m.group("suffix")]
            v *= mult
        # Apply sign — either lead_sign or inner_sign means negative
        is_neg = bool(m.group("lead_sign") or m.group("inner_sign"))
        if is_neg:
            v = -abs(v)

        if _is_noise(v):
            continue

        out.append(_Candidate(
            value=v,
            span=(s, e),
            is_bold=_is_bold(text, (s, e)),
            is_dollar=bool(m.group("dollar")),
            is_negative=is_neg,
            has_count_word_after=_has_count_word_after(text, e),
            in_headline=_is_in_headline(text, (s, e)),
        ))
    return out


def _parse_scalar(text: str) -> float | None:
    """Pick the most-likely answer-bearing numeric scalar from a verbose reply.

    Strategy (deterministic, no LLM-judging):

    1. Walk the reply once, gather every numeric token with provenance:
       is_bold (inside **...**), is_dollar ($-prefixed), is_negative (sign-bearing
       with sign before OR after the $), has_count_word_after ("transactions",
       "customers", etc.), in_headline (## or first 200 chars).
    2. Filter noise (years, DateIDs, percentages <= 100, indexes).
    3. Apply the AMOUNT-FIRST cascade. The agent's output style is consistent:
       - Amount headline:  "**$1,234,567.89**" or "**Total Daily PnL: $105,436,786.57**"
       - Count headline:   "**19,880** global deposit transactions"
       So we look for an amount-shaped headline first; only fall back to a
       count-shaped headline if no amount candidate exists. This handles every
       case in the v1 suite (revenue / equity / PnL / count of customers / etc.)

       Cascade:
         a) Bolded AND $-prefixed (= bolded amount headline) → return it
         b) Bolded AND NOT followed by a count word → return it
         c) $-prefixed (anywhere) → return the largest by abs value
         d) Bolded AND followed by a count word (= bolded count) → return it
         e) Fallback: largest by abs value among non-noise (legacy behavior)

    4. Sign is preserved through the whole pipeline. `-$550M` returns `-5.5e8`.

    Why a cascade and not a numeric score? Because the v1 cases are mostly
    monotone: the question type (amount vs count) is implicit in the agent's
    formatting, and the agent is consistent about bolding the headline. A score
    would over-fit to specific reply shapes; the cascade fails closed (returns
    SOMETHING reasonable) on weirdly-shaped replies.

    If a future case truly has multiple bolded $-amounts and we want a specific
    one (e.g. YTD vs MTD), the answer is to refine the question, not the parser.
    """
    if not text:
        return None

    cands = _extract_candidates(text)
    if not cands:
        return None

    # Cascade level a: bolded $-amount
    a = [c for c in cands if c.is_bold and c.is_dollar]
    if a:
        return max(a, key=lambda c: abs(c.value)).value

    # Cascade level b: bolded number NOT followed by a count word
    b = [c for c in cands if c.is_bold and not c.has_count_word_after]
    if b:
        return max(b, key=lambda c: abs(c.value)).value

    # Cascade level c: any $-prefixed candidate
    c_lvl = [c for c in cands if c.is_dollar]
    if c_lvl:
        return max(c_lvl, key=lambda c: abs(c.value)).value

    # Cascade level d: bolded count
    d = [c for c in cands if c.is_bold]
    if d:
        return max(d, key=lambda c: abs(c.value)).value

    # Fallback: largest by abs value
    return max(cands, key=lambda c: abs(c.value)).value


class CursorAgentSUT(SUT):
    """Run each case through a fresh `cursor-agent` headless process.

    This is the most faithful mimic of how an actual Cursor user asks a
    question: a brand-new agent each question, the user's MCPs attached,
    the user's skills loaded, the user's keys signing every API call.

    Parameters
    ----------
    api_key:
        Cursor API key (`crsr_...`). Defaults to `os.environ["CURSOR_API_KEY"]`.
    model:
        Cursor model slug. Defaults to `sonnet-4-5`. Run `cursor-agent --list-models`
        to see what your account has access to.
    workspace:
        Workspace directory. Defaults to the current working directory.
        cursor-agent reads `.cursor/mcp.json` and `.cursor/skills/` from here,
        so this MUST be the repo root (Databricks_Knowledge), not somewhere else.
    timeout_s:
        Hard wall-clock cap per case. Probe runs took 45-190s; default 600s
        gives generous headroom for warm-cache misses and long-running queries.
    """
    name = "cursor_agent"

    def __init__(
        self,
        *,
        api_key: str | None = None,
        model: str = "sonnet-4-5",
        workspace: str | Path | None = None,
        timeout_s: int = 600,
        enforce_mcp_only: bool = True,
    ) -> None:
        self.api_key = api_key or os.environ.get("CURSOR_API_KEY")
        if not self.api_key:
            raise RuntimeError(
                "CursorAgentSUT requires an API key. Set CURSOR_API_KEY in env "
                "or pass api_key= to the constructor."
            )
        self.model = model
        self.workspace = Path(workspace) if workspace else Path.cwd()
        self.timeout_s = timeout_s
        self.enforce_mcp_only = enforce_mcp_only

        # Install the eval-only `.cursor/rules/eval-mcp-only.mdc` rule that
        # forbids `dbx_query.py` and any other non-MCP SQL path. The rule is
        # alwaysApply: true, so every fresh cursor-agent process this SUT
        # spawns will load it alongside the existing workspace rules.
        if self.enforce_mcp_only:
            self._mcp_rule_path = activate_mcp_only_rule(self.workspace)
            # Best-effort cleanup: even if the user forgets to call close(),
            # remove the rule file when the Python process exits.
            atexit.register(self._safe_deactivate)
        else:
            self._mcp_rule_path = None

    def close(self) -> None:
        """Remove the MCP-only rule file from .cursor/rules/.

        Safe to call multiple times; safe to skip (atexit handles it as a
        backstop). Tests / CLI users who want to be tidy should call this
        explicitly after the run finishes.
        """
        self._safe_deactivate()

    def _safe_deactivate(self) -> None:
        if self.enforce_mcp_only:
            try:
                deactivate_mcp_only_rule(self.workspace)
            except Exception:  # noqa: BLE001 — atexit must not raise
                pass

    def ask(self, question: str, case: CaseV1) -> SUTResponse:  # noqa: ARG002 — case unused by design
        """Run one case. The `case` argument is intentionally ignored.

        Production SUT contract: no leakage of pinned values, schema hints, or
        skill-coverage metadata into the agent. The agent gets only the NL
        question and whatever it discovers via its own MCP tools.
        """
        prompt = (question or "").strip() + _HARNESS_SUFFIX

        try:
            result = _run_cursor_agent(
                prompt=prompt,
                api_key=self.api_key,
                model=self.model,
                workspace=self.workspace,
                timeout_s=self.timeout_s,
            )
        except subprocess.TimeoutExpired as e:
            return SUTResponse(
                numeric_answer=None,
                text_answer=None,
                sql_used=None,
                raw={"timeout": True, "stdout": (e.stdout or b"")[:4000].decode("utf-8", errors="replace"),
                     "stderr": (e.stderr or b"")[:4000].decode("utf-8", errors="replace") if isinstance(e.stderr, (bytes, bytearray)) else (e.stderr or "")[:4000]},
                error=f"cursor-agent timed out after {self.timeout_s}s",
                elapsed_ms=self.timeout_s * 1000,
            )
        except Exception as e:  # noqa: BLE001 — SUTs must not raise
            return SUTResponse(
                numeric_answer=None, text_answer=None, sql_used=None,
                raw={"exception": str(e)},
                error=f"cursor-agent failed to launch: {e!r}",
            )

        # Decode stdout (handles UTF-16 BOM from PowerShell pipelines if any)
        stdout_text = decode_stream_bytes(result.stdout_bytes)

        if result.returncode != 0:
            return SUTResponse(
                numeric_answer=None,
                text_answer=None,
                sql_used=None,
                raw={"stdout": stdout_text[:4000], "stderr": result.stderr[:4000], "rc": result.returncode},
                error=f"cursor-agent returned rc={result.returncode}: {(result.stderr or '')[:200]}",
                elapsed_ms=result.elapsed_ms,
            )

        # Parse the stream-json event log into a structured trace.
        events = parse_stream_jsonl(stdout_text)
        if not events:
            return SUTResponse(
                numeric_answer=None,
                text_answer=stdout_text[:4000] if stdout_text else None,
                sql_used=None,
                raw={"stdout": stdout_text[:4000], "stderr": result.stderr[:4000]},
                error="cursor-agent stdout had no parseable JSON lines",
                elapsed_ms=result.elapsed_ms,
            )

        trace: StreamTrace = parse_trace(events)

        # MCP-only enforcement: detect any non-MCP SQL exec the agent attempted
        # despite the eval-only rule that forbids it. We surface this as an
        # error string on the response (and pass the structured violations
        # through `raw["mcp_bypass_violations"]` for the runner to classify).
        bypass_violations: list[dict] = []
        engaged_mcp = trace_engaged_mcp_sql(trace)
        if self.enforce_mcp_only:
            bypass_violations = detect_mcp_bypass_violations(trace)

        raw_payload = {
            "trace": _trace_to_raw(trace),
            "mcp_bypass_violations": bypass_violations,
            "mcp_engaged": engaged_mcp,
        }

        if trace.is_error:
            return SUTResponse(
                numeric_answer=None,
                text_answer=trace.final_text,
                sql_used=_pick_sql_used(trace),
                raw=raw_payload,
                error=f"cursor-agent reported is_error (excerpt: {(trace.error_excerpt or trace.final_text or '')[:200]})",
                elapsed_ms=trace.duration_ms or result.elapsed_ms,
            )

        text = trace.final_text or ""
        scalar = _parse_scalar(text)
        sql_used = _pick_sql_used(trace)

        # If MCP-only enforcement is on AND the agent bypassed it, the run is
        # invalid regardless of whether the number happens to match. Surface
        # that as a hard error so it's never silently scored as a pass.
        error_msg: str | None = None
        if self.enforce_mcp_only and bypass_violations:
            error_msg = (
                f"MCP_BYPASS_VIOLATION: agent ran {len(bypass_violations)} SQL "
                f"statement(s) outside `user-databricks-stg` MCP "
                f"(methods: {sorted({v['kind'] for v in bypass_violations})}); "
                f"this run does NOT measure MCP behaviour. Inspect "
                f"`raw['mcp_bypass_violations']` for details."
            )
        elif self.enforce_mcp_only and not engaged_mcp and trace.tool_call_count > 0:
            # Agent answered without running ANY SQL at all (and there were
            # tool calls, so it's not just a refusal). Could be a hallucination
            # or memorised answer — flag it.
            error_msg = (
                "MCP_NOT_ENGAGED: agent answered without running any SQL via "
                "the user-databricks-stg MCP. Result is not a real MCP eval."
            )
        elif scalar is None:
            error_msg = "could not parse a numeric scalar from the reply"

        return SUTResponse(
            numeric_answer=scalar,
            text_answer=text,
            sql_used=sql_used,
            raw=raw_payload,
            error=error_msg,
            elapsed_ms=trace.duration_ms or result.elapsed_ms,
        )


# ---------------------------------------------------------------------------
# Helpers to project StreamTrace -> primitives the runner / telemetry can use
# ---------------------------------------------------------------------------


def _pick_sql_used(trace: StreamTrace) -> str | None:
    """Return the most-likely answer-producing SQL from the trace.

    Heuristic: the LAST successful SQL exec is the one whose result the agent
    quoted in its final text. SUCCESS-only because failed ones don't produce
    numbers. Falls back to the last SQL exec attempted (even if failed) so the
    user can see what the agent was trying to do when nothing worked.
    """
    successes = [x for x in trace.sql_execs if x.succeeded]
    if successes:
        return successes[-1].sql
    if trace.sql_execs:
        return trace.sql_execs[-1].sql
    return None


def _trace_to_raw(trace: StreamTrace) -> dict:
    """Serialize StreamTrace into a JSON-friendly dict for SUTResponse.raw.

    The runner pulls fields from this dict to populate CaseResult columns.
    Truncate large text fields aggressively — a CSV doesn't want the full
    thinking trace, just an excerpt.
    """
    return {
        "session_id": trace.session_id,
        "model": trace.model,
        "prompt_text": trace.prompt_text,
        "duration_ms": trace.duration_ms,
        "is_error": trace.is_error,
        "tool_call_count": trace.tool_call_count,
        "tool_call_by_kind": dict(trace.tool_call_by_kind),
        "mcp_tool_call_by_name": dict(trace.mcp_tool_call_by_name),
        "input_tokens": trace.input_tokens,
        "output_tokens": trace.output_tokens,
        "cache_read_tokens": trace.cache_read_tokens,
        "cache_write_tokens": trace.cache_write_tokens,
        "skills_loaded": [
            {"method": s.method, "slug": s.slug} for s in trace.skills_loaded
        ],
        "sql_execs": [
            {
                "method": x.method,
                "succeeded": x.succeeded,
                "sql": x.sql,
                "error": (x.error or "")[:300],
                "result_excerpt": (x.result_excerpt or "")[:300],
            }
            for x in trace.sql_execs
        ],
        # Last 2000 chars of thinking — the tail tends to contain the conclusion
        "thinking_excerpt": trace.thinking_text[-2000:] if trace.thinking_text else "",
        "final_text": trace.final_text,
    }
