"""LLM-driven merger for the wiki post-run auditor.

Stage 2 of the pipeline. Takes a per-object batch of candidate columns and
asks Claude (via the local CLI) to produce a merged description for each. The
LLM is allowed to vote SKIP if it judges the upstream is not actually better.

Why batched per object: the heuristic stage emits at most a handful of
candidates per object, and a single round-trip per object dramatically beats
one-call-per-column on token cost.

If the CLI is missing, rate-limited, or returns unparsable output, we fall
back to a deterministic stub merge so the dry-run still produces a usable
report.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Optional


# --- Data shapes -------------------------------------------------------------


@dataclass
class CandidateInput:
    column: str
    downstream_desc: str
    downstream_tier: str
    upstream_table: str
    upstream_column: str
    upstream_desc: str
    upstream_tier: str
    rules_triggered: list[str]
    rule_detail: dict[str, str]


@dataclass
class MergeResult:
    column: str
    recommendation: str  # PROMOTE | SKIP | CONFLICT
    merged_desc: str
    attribution: str
    notes: str = ""
    source: str = "llm"  # "llm" | "stub"


# --- Prompt construction -----------------------------------------------------


_SYSTEM_INSTRUCTIONS = """You are a senior data documentation reviewer.

You will receive an object name and a list of column candidates. For each candidate
you have:
  - the downstream description (what the local SP/view does to the column)
  - the upstream description (what the value semantically MEANS in finance/business terms)
  - the rules that flagged this column for review (TIER_GAP / MECH_ONLY / CONFLUENCE_GAP / LENGTH_GAP)

Your job: decide for EACH candidate whether the downstream description should be
replaced with a merged description, and if so, write the merge.

Rules of engagement:
  1. PROMOTE when the upstream genuinely adds business meaning the downstream is missing.
     The merged description must preserve any local mechanics (ABS, sign rules, post-load
     UPDATEs, NULL literals, intentional behaviour) that exist in the downstream.
  2. SKIP when the upstream is not actually better, or when the local description already
     covers the business meaning, or when both are mechanical-only and a merge wouldn't help.
  3. CONFLICT when the upstream and downstream contradict each other (e.g. different units,
     different meanings). In that case do NOT propose a merge; flag it for human review.

Output format: ONLY a JSON array with one object per candidate, in the same order as input.
No prose, no markdown fences. Each object has these keys:

  {
    "column": <string, must match input>,
    "recommendation": "PROMOTE" | "SKIP" | "CONFLICT",
    "merged_desc": <string; required if recommendation=PROMOTE, else "">,
    "attribution": <string; tier-attribution suffix to append, e.g.
                    "(Tier 1 - Fact_Deposit_State.PIPsInUSD; Tier 2 - SP_DepositWithdrawFee for ABS/sign logic)">,
    "notes": <string; short reason, e.g. "upstream cites FC playbook formula">
  }

Hard constraints:
  - Never invent business meaning that is not present in the upstream description.
  - Keep merged_desc to <= 500 characters.
  - Use plain text, not markdown bullets.
  - Preserve the column-name capitalisation as given.
  - DO NOT include a "(Tier ...)" suffix inside `merged_desc`. The tier attribution
    belongs ONLY in the `attribution` field. Putting it in both fields causes
    duplicated suffixes in the rendered output.
  - `attribution` must be a single parenthesised string of the form
    "(Tier 1 - <upstream.col>; Tier 2 - <local logic note>)".
"""


def _build_prompt(object_qualified: str, candidates: list[CandidateInput]) -> str:
    payload = [asdict(c) for c in candidates]
    return (
        _SYSTEM_INSTRUCTIONS
        + "\n\nObject: "
        + object_qualified
        + "\n\nCandidates JSON (input):\n"
        + json.dumps(payload, indent=2, ensure_ascii=False)
        + "\n\nReturn ONLY the JSON array. No prose."
    )


# --- Claude CLI invocation ---------------------------------------------------


def _resolve_claude_cli() -> Optional[str]:
    """Find the claude executable. Honours $WIKI_AUDITOR_CLAUDE override."""
    override = os.environ.get("WIKI_AUDITOR_CLAUDE")
    if override and Path(override).exists():
        return override
    # Standard locations on this machine.
    for cand in [
        Path(os.environ.get("APPDATA", "")) / "npm" / "claude.cmd",
        Path(os.environ.get("APPDATA", "")) / "npm" / "claude",
    ]:
        if cand.exists():
            return str(cand)
    found = shutil.which("claude")
    return found


def _run_claude(prompt: str, timeout_s: int = 240) -> Optional[str]:
    """Invoke claude via `--print` and pipe the prompt through stdin.

    On Windows, passing a multi-thousand-character JSON-bearing prompt as a
    positional argv value through `claude.cmd` can be mangled by the batch
    wrapper -- the CLI ends up seeing an empty/short prompt and just returns
    its boot greeting. Piping through stdin avoids the issue entirely.

    --bare would skip hooks/MCP/CLAUDE.md auto-discovery for faster startup,
    but it rejects OAuth logins (only ANTHROPIC_API_KEY) -- so we don't use it.
    """
    cli = _resolve_claude_cli()
    if not cli:
        return None
    args = [cli, "--print", "--output-format", "text"]
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
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        return None
    if proc.returncode != 0:
        return None
    out = proc.stdout or ""
    if not out.strip():
        return None
    return out


# --- Response parsing --------------------------------------------------------


_JSON_FENCE_RE = re.compile(r"```(?:json)?\s*(.*?)```", re.DOTALL | re.IGNORECASE)


def _extract_json_array(text: str) -> Optional[list]:
    """Tolerant JSON extraction: strips fences and finds the first [ ... ] block."""
    if not text:
        return None
    fence = _JSON_FENCE_RE.search(text)
    if fence:
        body = fence.group(1).strip()
    else:
        body = text.strip()
    # Find the first '[' and matching ']'.
    start = body.find("[")
    if start < 0:
        return None
    depth = 0
    end = -1
    for i in range(start, len(body)):
        ch = body[i]
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    if end < 0:
        return None
    blob = body[start:end]
    try:
        parsed = json.loads(blob)
    except json.JSONDecodeError:
        return None
    if not isinstance(parsed, list):
        return None
    return parsed


# --- Stub merger (fallback when LLM unavailable) -----------------------------


def _stub_merge(c: CandidateInput) -> MergeResult:
    """Deterministic merge used when the LLM is unreachable.

    Construction:
      <upstream_desc, with trailing tier suffix stripped>
      Local handling: <downstream_desc with trailing tier suffix stripped>
      (Tier 1/4 - upstream.col; Tier 2 - downstream local logic)
    """
    from wiki_parser import description_without_tier_suffix

    up = description_without_tier_suffix(c.upstream_desc).strip().rstrip(".")
    dn = description_without_tier_suffix(c.downstream_desc).strip().rstrip(".")
    if not up:
        # Nothing to inherit -- recommend SKIP.
        return MergeResult(
            column=c.column,
            recommendation="SKIP",
            merged_desc="",
            attribution="",
            notes="stub: upstream description was empty after tier-suffix strip",
            source="stub",
        )
    merged = f"{up}. Local handling: {dn}." if dn else f"{up}."
    if len(merged) > 500:
        merged = merged[:497] + "..."
    upstream_tier_label = (
        f"Tier {c.upstream_tier}" if c.upstream_tier else "Upstream"
    )
    attribution = (
        f"({upstream_tier_label} - {c.upstream_table}.{c.upstream_column}; "
        f"Tier {c.downstream_tier or '2'} - downstream local logic)"
    )
    return MergeResult(
        column=c.column,
        recommendation="PROMOTE",
        merged_desc=merged,
        attribution=attribution,
        notes="stub: LLM unavailable, deterministic concat used",
        source="stub",
    )


# --- Public entry point ------------------------------------------------------


def merge_candidates(
    object_qualified: str,
    candidates: list[CandidateInput],
    *,
    timeout_s: int = 240,
    use_llm: bool = True,
) -> list[MergeResult]:
    """Run the LLM merger on a per-object batch.

    On any failure (no CLI / rate-limited / unparsable output / shape mismatch)
    each candidate falls back to `_stub_merge`. The caller can identify stub
    fallbacks by checking `result.source == "stub"`.
    """
    if not candidates:
        return []
    if not use_llm:
        return [_stub_merge(c) for c in candidates]

    prompt = _build_prompt(object_qualified, candidates)
    raw = _run_claude(prompt, timeout_s=timeout_s)
    if not raw:
        return [_stub_merge(c) for c in candidates]
    parsed = _extract_json_array(raw)
    if parsed is None:
        return [_stub_merge(c) for c in candidates]

    by_col = {}
    for item in parsed:
        if not isinstance(item, dict):
            continue
        col = item.get("column")
        if not col:
            continue
        rec = (item.get("recommendation") or "").upper()
        if rec not in {"PROMOTE", "SKIP", "CONFLICT"}:
            rec = "SKIP"
        by_col[col] = MergeResult(
            column=col,
            recommendation=rec,
            merged_desc=(item.get("merged_desc") or "").strip(),
            attribution=(item.get("attribution") or "").strip(),
            notes=(item.get("notes") or "").strip(),
            source="llm",
        )

    results: list[MergeResult] = []
    for c in candidates:
        if c.column in by_col:
            r = by_col[c.column]
            # Defensive: PROMOTE without merged_desc -> demote to stub.
            if r.recommendation == "PROMOTE" and not r.merged_desc:
                results.append(_stub_merge(c))
            else:
                results.append(r)
        else:
            results.append(_stub_merge(c))
    return results
