"""MCP-only enforcement for the cursor_agent SUT.

Two-part contract with the agent:

  1. PRE-RUN  (`activate_mcp_only_rule`)
     Copy the eval-only rule template into `.cursor/rules/eval-mcp-only.mdc`
     so cursor-agent loads it as an alwaysApply rule alongside the existing
     workspace rules. The new rule supersedes `mcp-latency-signal.mdc` rule 4
     and the `databricks-connection` skill's "prefer dbx_query.py" guidance.

  2. POST-RUN (`detect_mcp_bypass_violations`)
     Inspect the parsed StreamTrace. If any shell tool call invoked
     `python tools/dbx_query.py` (or other forbidden Databricks SQL paths),
     return a structured violation list. Caller raises that as the case's
     error / drift verdict.

We deliberately do BOTH: the rule tells the model NOT to use the shell path;
the bypass detector verifies the model obeyed. Belt-and-braces because rules
are advisory in cursor-agent (model can still ignore them under load).

Lifecycle:
  with mcp_only_rule_active(repo_root):
      run cursor-agent ...
  # rule file removed automatically on context exit
"""
from __future__ import annotations

import contextlib
import re
import shutil
from pathlib import Path
from typing import Iterator

from ._stream_json import StreamTrace


# Forbidden shell-command patterns. Anchored to *recognise* a SQL run, not just
# any Python invocation. We don't want to flag e.g. `python tools/list_things.py`.
_FORBIDDEN_SHELL_PATTERNS = (
    re.compile(r"\bpython(?:3|\.exe)?\s+(?:-u\s+)?(?:tools[/\\])?dbx_query\.py\b", re.IGNORECASE),
    re.compile(r"\bdatabricks\b\s+\bsql\b", re.IGNORECASE),
    re.compile(r"\bdatabricks\.sql\.connect\b", re.IGNORECASE),
    re.compile(r"\bWorkspaceClient\b.*\bstatement_execution\b", re.IGNORECASE | re.DOTALL),
)


def _rule_template_path() -> Path:
    """Path to the rule TEMPLATE file (lives next to this module's parent)."""
    return Path(__file__).resolve().parents[1] / "eval_mcp_only_rule.template.mdc"


def _rule_target_path(repo_root: Path | str) -> Path:
    return Path(repo_root) / ".cursor" / "rules" / "eval-mcp-only.mdc"


def activate_mcp_only_rule(repo_root: Path | str) -> Path:
    """Install the eval-only MCP rule. Returns the path written.

    Idempotent: safe to call when the file already exists (we overwrite it).
    """
    src = _rule_template_path()
    if not src.exists():
        raise RuntimeError(
            f"Eval rule template missing at {src}; cannot activate MCP-only mode."
        )
    dst = _rule_target_path(repo_root)
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dst)
    return dst


def deactivate_mcp_only_rule(repo_root: Path | str) -> bool:
    """Remove the eval-only MCP rule. Returns True if removed, False if absent."""
    dst = _rule_target_path(repo_root)
    if dst.exists():
        try:
            dst.unlink()
            return True
        except OSError:
            return False
    return False


@contextlib.contextmanager
def mcp_only_rule_active(repo_root: Path | str) -> Iterator[Path]:
    """Context manager: install rule on enter, remove on exit (even on error)."""
    target = activate_mcp_only_rule(repo_root)
    try:
        yield target
    finally:
        deactivate_mcp_only_rule(repo_root)


# ---------------------------------------------------------------------------
# Post-run violation detection
# ---------------------------------------------------------------------------

def detect_mcp_bypass_violations(trace: StreamTrace) -> list[dict]:
    """Return one violation record per forbidden SQL invocation found in the trace.

    Each record:
      {
        "kind": "shell_dbx_query" | "databricks_cli_sql" | "databricks_sql_python" | ...,
        "command_excerpt": "<first 240 chars of the offending command>",
        "succeeded": True/False,
        "row_in_sql_execs": int (index into trace.sql_execs)
      }

    An empty list means MCP-only enforcement held: every SQL the agent ran went
    through `mcp_user-databricks-stg_databricks_sql_*`.
    """
    violations: list[dict] = []
    for idx, x in enumerate(trace.sql_execs):
        # The parser already classifies sql_execs by `method`. Anything that
        # ISN'T `mcp_databricks_sql` is a bypass.
        if x.method == "mcp_databricks_sql":
            continue
        kind = x.method  # e.g. "shell_dbx_query"
        # Try to characterise WHICH forbidden pattern matched (for reporting)
        # We don't have the raw command on the SqlExec, but the SQL itself
        # plus method is enough; for shell methods, surface the SQL excerpt.
        excerpt = (x.sql or "")[:240]
        violations.append({
            "kind": kind,
            "command_excerpt": excerpt,
            "succeeded": x.succeeded,
            "row_in_sql_execs": idx,
        })
    return violations


def trace_engaged_mcp_sql(trace: StreamTrace) -> bool:
    """True iff at least one SQL exec went through `mcp_databricks_sql`.

    Useful as a sanity-check for cases where the agent answered without running
    any SQL at all (e.g. a malformed question that the agent declined). Without
    this, an answer-from-thin-air case would PASS the violation check trivially.
    """
    return any(x.method == "mcp_databricks_sql" for x in trace.sql_execs)
