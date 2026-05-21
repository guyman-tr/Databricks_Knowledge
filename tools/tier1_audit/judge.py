"""judge.py — LLM judge for substantive-vs-cosmetic description divergence.

Uses the local `claude` CLI (mirrors the pattern in
tools/wiki-auditor/llm_merger.py and tools/tableau/judge_wiki_tableau_semantics.py).

A judgment is cached on disk keyed by the SHA-256 of the (source_wiki,
matched_column, source_desc, claim_desc) tuple so re-runs are free.

Caller passes the source description, the downstream-claim description,
the column name (for context), and the source wiki name (for context).
Returns a `Judgment` dataclass.
"""
from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import time
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Literal

REPO = Path(__file__).resolve().parents[2]
DEFAULT_CACHE_DIR = REPO / "audits" / "_tier1_audit_cache"
DEFAULT_TIMEOUT_S = 120


Verdict = Literal["PASS", "FAIL"]
Severity = Literal["LOW", "MEDIUM", "HIGH"]


@dataclass
class Judgment:
    verdict: Verdict
    severity: Severity | None
    reason: str
    proposed_fix: str | None
    raw_response: str
    cached: bool


# ---------------------------------------------------------------------------
# Claude CLI
# ---------------------------------------------------------------------------
def _resolve_claude_cli() -> str | None:
    override = os.environ.get("TIER1_AUDIT_CLAUDE") or os.environ.get("WIKI_AUDITOR_CLAUDE")
    if override and Path(override).exists():
        return override
    for cand in [
        Path(os.environ.get("APPDATA", "")) / "npm" / "claude.cmd",
        Path(os.environ.get("APPDATA", "")) / "npm" / "claude",
    ]:
        if cand.exists():
            return str(cand)
    return shutil.which("claude")


def _run_claude(prompt: str, *, model: str | None, timeout_s: int) -> tuple[str | None, str]:
    """Invoke claude --print and return (stdout, error_msg)."""
    cli = _resolve_claude_cli()
    if not cli:
        return None, (
            "claude CLI not found. Install via `npm i -g @anthropic-ai/claude-code` "
            "or set $TIER1_AUDIT_CLAUDE to its path."
        )
    args = [cli, "--print", "--output-format", "text"]
    if model:
        args += ["--model", model]
    try:
        proc = subprocess.run(
            args,
            input=prompt,
            capture_output=True,
            text=True,
            timeout=timeout_s,
            encoding="utf-8",
            errors="replace",
        )
    except subprocess.TimeoutExpired:
        return None, f"claude CLI timed out after {timeout_s}s"
    except (FileNotFoundError, OSError) as exc:
        return None, f"failed to launch claude CLI: {exc}"
    if proc.returncode != 0:
        return None, (
            f"claude CLI exited {proc.returncode}. stderr (head):\n"
            f"{(proc.stderr or '')[:600]}"
        )
    out = proc.stdout or ""
    if not out.strip():
        return None, "claude CLI returned empty stdout"
    return out, ""


# ---------------------------------------------------------------------------
# Prompt
# ---------------------------------------------------------------------------
_JUDGE_PROMPT = """\
You are auditing a data dictionary for an analytics warehouse. Compare TWO
descriptions of the same column and decide whether they convey the SAME
BUSINESS MEANING for an analyst running queries against this data.

PASS if the meanings match, even when wording is different. Examples of PASS:
  * "Foreign key to Dim_Customer" vs "Join key against Dim_Customer"
  * "Surrogate primary key" vs "Synthetic identifier (SK)"
  * "Customer email address" vs "Email used for account login (lower-cased
     copy stored separately)"
  * "Settled equity excluding unrealized PnL" vs "Realized equity (does not
     include open-position PnL)"
  * "Date of birth" vs "Customer DOB used in KYC age verification"
  * Source omits implementation detail that the claim adds (or vice versa)
    but the column quantity / population is the same.

FAIL if the column's interpretation differs in a way an analyst would
mis-query on. Examples of FAIL:
  * "Customer's total credit balance (running total)" vs
    "Non-withdrawable promotional/bonus credit"          --> different
    financial quantity entirely
  * "Gross deposit amount including fees" vs "Net deposit amount after fees"
    --> different math
  * "Last deposit attempt (success or failure)" vs "Last successful deposit"
    --> different population
  * "Withdraw amount in USD" vs "Withdraw amount in account currency"
    --> different unit
  * Source explicitly NEGATES something that the claim asserts (e.g. "NOT
    promotional" vs "promotional").

Severity guidance for FAIL:
  * HIGH: the column refers to a different real-world quantity or
    population; could cause analyst to compute the wrong number.
  * MEDIUM: same quantity but different unit, sign, or scope (a subset/superset).
  * LOW: borderline — analysts might both arrive at the right answer but
    the language is confusingly inaccurate.

----- INPUT -----

Column:        {column}
Source wiki:   {source_wiki}
Source tier:   {source_tier}
Source description:
  {source_desc}

Downstream (claimed Tier 1) description:
  {claim_desc}

----- OUTPUT -----

Return EXACTLY one JSON object on a single line, no prose before or after.
Schema:

  {{"verdict": "PASS" | "FAIL",
    "severity": "LOW" | "MEDIUM" | "HIGH" | null,
    "reason": "<one short sentence>",
    "proposed_fix": "<one-sentence corrected description anchored to the
                     source, ending with '(Tier 1 - <source>)'> or null"}}

If verdict is PASS, set severity and proposed_fix to null.
If verdict is FAIL, severity must be HIGH / MEDIUM / LOW and proposed_fix
must be a concrete rewrite drawn from the source description. Keep
proposed_fix under 220 characters.
"""


# ---------------------------------------------------------------------------
# Cache
# ---------------------------------------------------------------------------
def _cache_key(source_wiki: str, matched_column: str, source_desc: str, claim_desc: str) -> str:
    h = hashlib.sha256()
    h.update(source_wiki.encode("utf-8"))
    h.update(b"\x1f")
    h.update(matched_column.encode("utf-8"))
    h.update(b"\x1f")
    h.update(source_desc.encode("utf-8"))
    h.update(b"\x1f")
    h.update(claim_desc.encode("utf-8"))
    return h.hexdigest()


def _cache_path(cache_dir: Path, key: str) -> Path:
    return cache_dir / key[:2] / f"{key}.json"


def _load_from_cache(cache_dir: Path, key: str) -> Judgment | None:
    path = _cache_path(cache_dir, key)
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return Judgment(
            verdict=data["verdict"],
            severity=data.get("severity"),
            reason=data.get("reason", ""),
            proposed_fix=data.get("proposed_fix"),
            raw_response=data.get("raw_response", ""),
            cached=True,
        )
    except Exception:
        return None


def _save_to_cache(cache_dir: Path, key: str, judgment: Judgment) -> None:
    path = _cache_path(cache_dir, key)
    path.parent.mkdir(parents=True, exist_ok=True)
    snap = asdict(judgment)
    snap["cached"] = False  # always write False; loader flips on read
    path.write_text(json.dumps(snap, indent=2, ensure_ascii=False), encoding="utf-8")


# ---------------------------------------------------------------------------
# Response parsing
# ---------------------------------------------------------------------------
def _parse_judge_response(text: str) -> Judgment | None:
    """Pull the first valid JSON object out of the response."""
    # Drop common code-fence wrappers
    stripped = text.strip()
    if stripped.startswith("```"):
        stripped = stripped.strip("`")
        if "\n" in stripped:
            stripped = stripped.split("\n", 1)[1]
        stripped = stripped.rstrip("`").strip()
    # Find first { ... } that parses
    depth = 0
    start = -1
    for i, ch in enumerate(stripped):
        if ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start != -1:
                blob = stripped[start:i + 1]
                try:
                    data = json.loads(blob)
                except Exception:
                    start = -1
                    continue
                verdict = (data.get("verdict") or "").upper()
                if verdict not in ("PASS", "FAIL"):
                    return None
                severity = data.get("severity")
                if severity:
                    severity = severity.upper()
                    if severity not in ("LOW", "MEDIUM", "HIGH"):
                        severity = None
                return Judgment(
                    verdict=verdict,                # type: ignore[arg-type]
                    severity=severity,              # type: ignore[arg-type]
                    reason=str(data.get("reason") or "")[:500],
                    proposed_fix=data.get("proposed_fix") or None,
                    raw_response=text,
                    cached=False,
                )
    return None


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
def judge_descriptions(
    *,
    column: str,
    source_wiki: str,
    source_tier: str,
    source_desc: str,
    claim_desc: str,
    cache_dir: Path = DEFAULT_CACHE_DIR,
    model: str | None = None,
    timeout_s: int = DEFAULT_TIMEOUT_S,
) -> Judgment:
    """Return a Judgment for the (source_desc, claim_desc) pair.

    Caches on disk. If the LLM cannot be reached or returns malformed
    output, returns a FAIL with severity LOW and reason describing the
    error — this way the report never silently swallows judge failures.
    """
    key = _cache_key(source_wiki, column, source_desc, claim_desc)
    cached = _load_from_cache(cache_dir, key)
    if cached:
        return cached
    prompt = _JUDGE_PROMPT.format(
        column=column,
        source_wiki=source_wiki,
        source_tier=source_tier or "OLTP (no tier tag — treated as Tier 1 truth)",
        source_desc=source_desc.strip() or "(empty)",
        claim_desc=claim_desc.strip() or "(empty)",
    )
    stdout, err = _run_claude(prompt, model=model, timeout_s=timeout_s)
    if stdout is None:
        # Surface as a soft-FAIL so it appears in the report (with severity LOW)
        return Judgment(
            verdict="FAIL",
            severity="LOW",
            reason=f"judge unavailable: {err}",
            proposed_fix=None,
            raw_response="",
            cached=False,
        )
    judgment = _parse_judge_response(stdout)
    if judgment is None:
        return Judgment(
            verdict="FAIL",
            severity="LOW",
            reason=f"judge returned unparseable JSON; head: {stdout[:200]!r}",
            proposed_fix=None,
            raw_response=stdout,
            cached=False,
        )
    _save_to_cache(cache_dir, key, judgment)
    return judgment


def claude_cli_available() -> bool:
    return _resolve_claude_cli() is not None
