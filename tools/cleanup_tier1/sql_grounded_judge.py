"""sql_grounded_judge.py — LLM judge that grounds every verdict in the
producing SQL expression, never in another wiki's prose.

Key precision controls (the three the plan calls out):

1. Conservative verdict ladder
     VERIFIED       — the wiki description is consistent with the SQL.
     CONTRADICTED   — the wiki description states X and the SQL clearly
                      does Y (real, citable clause).
     UNVERIFIABLE   — either the description is too vague to compare, or
                      the SQL was a passthrough through many layers and
                      no clear semantic claim is decidable from this view.

   Stylistic gripes, "missing detail", or "could be more precise" NEVER
   yield CONTRADICTED. The LLM is instructed in plain words.

2. Explicit CASE-derivation rule
     If the SQL is a CASE / COALESCE / ISNULL / IIF expression and the
     wiki description enumerates the resulting values (e.g.
     '0 = self-trade, 1 = copied'), this is VERIFIED — not "fabricated
     enum".

3. Self-critique step
     Whenever the LLM is about to output CONTRADICTED, the prompt forces
     it to list two reasons the description could still be correct.
     If EITHER reason has merit, the verdict downgrades to UNVERIFIABLE.

The cache key includes a hash of the SQL expression text, so re-running
after an SP/View is edited automatically invalidates only affected rows.
"""
from __future__ import annotations

import hashlib
import json
import os
import sys
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Literal, Optional

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "tools"))

# Reuse the proven CLI shim from the existing judge.
from tier1_audit.judge import _run_claude  # noqa: E402

DEFAULT_CACHE_DIR = REPO / "audits" / "_sql_grounded_audit_cache"
DEFAULT_TIMEOUT_S = 180


Verdict = Literal["VERIFIED", "CONTRADICTED", "UNVERIFIABLE"]
Severity = Literal["LOW", "MEDIUM", "HIGH"]


@dataclass
class SqlGroundedJudgment:
    verdict: Verdict
    severity: Optional[Severity]
    reason: str                # must cite a specific SQL clause for CONTRADICTED
    proposed_fix: Optional[str]
    sql_clause_cited: str = ""
    self_critique: list[str] = field(default_factory=list)
    raw_response: str = ""
    cached: bool = False


# ---------------------------------------------------------------------------
# Prompt
# ---------------------------------------------------------------------------
_SYSTEM = """\
You are auditing a data dictionary against the actual SQL that produces each
column. Your ONLY evidence is the SQL expression(s) provided. Do not invent
upstream tables, columns, or business rules. Do not consult any other wiki.

Output a VERDICT for the wiki description:

  VERIFIED       The description's claims are consistent with the SQL expression.
                 (PREFER this unless you can cite a specific SQL clause that
                 contradicts the description.)

  CONTRADICTED   The description states a fact that the SQL clearly does NOT
                 do. You MUST cite the specific SQL clause that contradicts it.
                 Reserve this for real factual lies: wrong upstream column,
                 wrong arithmetic, wrong sign, wrong unit, NEGATED filter,
                 wrong enum mapping, fabricated table reference, etc.

  UNVERIFIABLE   Either (a) the description is too vague to compare against
                 the SQL ("Standard ID field", "Customer attribute"), or
                 (b) the SQL is a multi-step passthrough whose semantic content
                 you cannot judge from the visible expression alone.

Verdict ladder rules — read carefully:

  R1.  "Description is less detailed than the SQL" is NEVER CONTRADICTED.
       A description that says "Mirror id" while the SQL is `f.MirrorID` is
       VERIFIED, not "could be more precise".

  R2.  "Description has stylistic / phrasing issues" is NEVER CONTRADICTED.
       Only real factual errors qualify.

  R3.  CASE / COALESCE / ISNULL / IIF rule.
       When the SQL is something like
            CASE WHEN frfc.MirrorID > 0 THEN 1 ELSE 0 END
       and the description enumerates the resulting values (e.g.
       "0 = self-trade, 1 = copied trade") this is VERIFIED, not "fabricated
       enum". The CASE expression literally produces those values — that is
       the textbook authority for the enum.

  R4.  Passthrough chains. If the SQL trace shows
       `Amount in Table -> Amount in #temp -> fca.Amount from
        DWH_dbo.Fact_CustomerAction`, then a description saying
       "Net amount of the customer action (passthrough from
        Fact_CustomerAction)" is VERIFIED, even though the immediate
       SQL line is just `f.Amount`. Trust the chain.

  R5.  UNION ALL with mixed CASE-and-literal branches. If branch A says
       `CASE WHEN ... THEN 1 ELSE 0 END AS IsActiveTrade` and branches B-F
       say `0 AS IsActiveTrade`, a description that says "1 only for the
       primary commission branch; 0 elsewhere" is VERIFIED.

  R6.  Source object mismatch is the most common real CONTRADICTED case.
       If the description names DWH_dbo.Fact_CustomerAction as the upstream
       and the SQL clearly draws from Trade.PositionTbl (or vice versa),
       cite the FROM clause and mark CONTRADICTED-HIGH.

Self-critique step (mandatory whenever you are about to output CONTRADICTED):

  Before finalizing CONTRADICTED, list TWO reasons the description could
  still be correct given the SQL. If EITHER reason has any merit at all
  (e.g. the SQL has a passthrough and the description names the real
  upstream that the chain eventually reaches; or the wording is ambiguous
  but compatible with both readings), DOWNGRADE to UNVERIFIABLE.

Severity for CONTRADICTED:
  HIGH    — different real-world quantity / population / table / unit.
  MEDIUM  — same quantity, wrong scope / sign / enum mapping.
  LOW     — borderline; almost CONTRADICTED but worth flagging only.

When you DOWNGRADE due to self-critique, set verdict=UNVERIFIABLE and
explain in `reason` what the self-critique exposed.

Return EXACTLY ONE JSON object on a single line, no prose before or after,
no markdown code fences. Schema:

  {"verdict": "VERIFIED" | "CONTRADICTED" | "UNVERIFIABLE",
   "severity": "HIGH" | "MEDIUM" | "LOW" | null,
   "reason": "<one short sentence>",
   "sql_clause_cited": "<exact SQL substring that grounds the verdict, or ''>",
   "self_critique": ["<reason 1 description could still be correct>",
                     "<reason 2 ...>"],
   "proposed_fix": "<corrected description anchored to SQL, or null>"}

Rules:
  - VERIFIED  -> severity=null, proposed_fix=null, sql_clause_cited may be
                 empty or a brief anchor.
  - UNVERIFIABLE -> severity=null, proposed_fix=null.
  - CONTRADICTED -> severity required, proposed_fix required and ≤ 220 chars,
                 sql_clause_cited required (exact substring from the SQL).
  - self_critique is OPTIONAL for VERIFIED/UNVERIFIABLE, REQUIRED for
                 CONTRADICTED (you must have run it before finalizing).
"""


_USER_TEMPLATE = """\
COLUMN under audit
------------------
name:           {column}
in wiki:        {wiki_path}
object kind:    {object_kind}
source object:  {source_objects_csv}

WIKI DESCRIPTION (the claim being audited)
------------------------------------------
{wiki_description}

PRODUCING SQL EXPRESSION
------------------------
primary expression  ({primary_kind}):
  {primary_expr}

{branches_block}

UPSTREAM SQL CHAIN
------------------
{chain_block}

RAW SQL SNIPPETS (for citation; pick exact substrings from here only)
---------------------------------------------------------------------
{snippets_block}

TASK
----
Apply the verdict ladder. Be conservative. Run the self-critique step
before any CONTRADICTED. Return ONE JSON object as specified.
"""


def _format_branches(branches: list) -> str:
    if not branches:
        return "(no UNION branches; single-expression projection)"
    lines = ["branches (one per UNION-ALL leg):"]
    for i, b in enumerate(branches):
        label = f" [{b.label}]" if b.label else ""
        src = f" <- {b.source_object}" if b.source_object else ""
        lines.append(f"  {i+1}.{label} ({b.kind}) {b.expression_sql}{src}")
    return "\n".join(lines)


def _format_chain(chain: list) -> str:
    if not chain:
        return "(no chain — extraction stopped at the primary expression)"
    lines = []
    for i, c in enumerate(chain):
        src = f" <- {c.source_object}" if c.source_object else ""
        lines.append(f"  step {i+1}: ({c.kind}) {c.expression_sql}{src}")
    return "\n".join(lines)


def _format_snippets(snippets: list[str], max_chars: int = 4000) -> str:
    if not snippets:
        return "(no raw snippets)"
    # Stay within an LLM-friendly budget.
    out: list[str] = []
    total = 0
    for i, s in enumerate(snippets):
        chunk = s.strip()
        if not chunk:
            continue
        if total + len(chunk) > max_chars:
            out.append(f"--- snippet {i+1} (TRUNCATED) ---")
            out.append(chunk[: max(0, max_chars - total)])
            break
        out.append(f"--- snippet {i+1} ---")
        out.append(chunk)
        total += len(chunk)
    return "\n".join(out)


def build_prompt(
    column: str,
    wiki_path: str,
    object_kind: str,
    wiki_description: str,
    primary_kind: str,
    primary_expr: str,
    branches: list,
    chain: list,
    snippets: list[str],
    source_objects: list[str],
) -> str:
    user = _USER_TEMPLATE.format(
        column=column,
        wiki_path=wiki_path,
        object_kind=object_kind,
        source_objects_csv=", ".join(source_objects) or "(none resolved)",
        wiki_description=wiki_description.strip() or "(empty)",
        primary_kind=primary_kind or "unknown",
        primary_expr=primary_expr.strip() or "(none)",
        branches_block=_format_branches(branches),
        chain_block=_format_chain(chain),
        snippets_block=_format_snippets(snippets),
    )
    return _SYSTEM + "\n\n" + user


# ---------------------------------------------------------------------------
# Cache
# ---------------------------------------------------------------------------
def _cache_key(
    column: str,
    wiki_path: str,
    wiki_description: str,
    primary_expr: str,
    branches: list,
) -> str:
    h = hashlib.sha256()
    for piece in (column, wiki_path, wiki_description, primary_expr):
        h.update((piece or "").encode("utf-8"))
        h.update(b"\x1f")
    for b in branches or []:
        h.update((b.label or "").encode("utf-8"))
        h.update(b"\x1f")
        h.update((b.expression_sql or "").encode("utf-8"))
        h.update(b"\x1e")
    return h.hexdigest()


def _cache_path(cache_dir: Path, key: str) -> Path:
    return cache_dir / key[:2] / f"{key}.json"


def _load_cache(cache_dir: Path, key: str) -> Optional[SqlGroundedJudgment]:
    p = _cache_path(cache_dir, key)
    if not p.exists():
        return None
    try:
        d = json.loads(p.read_text(encoding="utf-8"))
        return SqlGroundedJudgment(
            verdict=d["verdict"],
            severity=d.get("severity"),
            reason=d.get("reason", ""),
            proposed_fix=d.get("proposed_fix"),
            sql_clause_cited=d.get("sql_clause_cited", ""),
            self_critique=d.get("self_critique") or [],
            raw_response=d.get("raw_response", ""),
            cached=True,
        )
    except Exception:
        return None


def _save_cache(cache_dir: Path, key: str, j: SqlGroundedJudgment) -> None:
    p = _cache_path(cache_dir, key)
    p.parent.mkdir(parents=True, exist_ok=True)
    snap = asdict(j)
    snap["cached"] = False
    p.write_text(json.dumps(snap, indent=2, ensure_ascii=False), encoding="utf-8")


# ---------------------------------------------------------------------------
# Response parsing
# ---------------------------------------------------------------------------
def parse_response(text: str) -> Optional[SqlGroundedJudgment]:
    """Pull the first valid JSON object out of the response."""
    stripped = (text or "").strip()
    if stripped.startswith("```"):
        stripped = stripped.strip("`")
        if "\n" in stripped:
            stripped = stripped.split("\n", 1)[1]
        stripped = stripped.rstrip("`").strip()
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
                if verdict not in ("VERIFIED", "CONTRADICTED", "UNVERIFIABLE"):
                    return None
                sev = data.get("severity")
                if isinstance(sev, str):
                    sev = sev.upper()
                if sev not in (None, "HIGH", "MEDIUM", "LOW"):
                    sev = None
                if verdict != "CONTRADICTED":
                    sev = None
                pf = data.get("proposed_fix")
                if verdict != "CONTRADICTED":
                    pf = None
                sc = data.get("self_critique") or []
                if not isinstance(sc, list):
                    sc = [str(sc)]
                sc = [str(x).strip() for x in sc if str(x).strip()]
                return SqlGroundedJudgment(
                    verdict=verdict,
                    severity=sev,
                    reason=str(data.get("reason") or "").strip(),
                    proposed_fix=pf,
                    sql_clause_cited=str(data.get("sql_clause_cited") or "").strip(),
                    self_critique=sc,
                    raw_response=text,
                    cached=False,
                )
    return None


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
def judge(
    *,
    column: str,
    wiki_path: str,
    object_kind: str,
    wiki_description: str,
    primary_expr: str,
    primary_kind: str,
    branches: list,
    chain: list,
    snippets: list[str],
    source_objects: list[str],
    model: str | None = None,
    timeout_s: int = DEFAULT_TIMEOUT_S,
    cache_dir: Path = DEFAULT_CACHE_DIR,
    use_cache: bool = True,
) -> SqlGroundedJudgment:
    """Run the SQL-grounded judge for one column. Returns a SqlGroundedJudgment.

    If `use_cache` and a matching judgment is on disk, returns that with
    `cached=True`. The cache key incorporates the SQL expression hash so
    edits to the SP/View automatically invalidate stale verdicts.
    """
    key = _cache_key(column, wiki_path, wiki_description, primary_expr, branches)
    if use_cache:
        cached = _load_cache(cache_dir, key)
        if cached is not None:
            return cached

    prompt = build_prompt(
        column=column,
        wiki_path=wiki_path,
        object_kind=object_kind,
        wiki_description=wiki_description,
        primary_kind=primary_kind,
        primary_expr=primary_expr,
        branches=branches,
        chain=chain,
        snippets=snippets,
        source_objects=source_objects,
    )
    raw, err = _run_claude(prompt, model=model, timeout_s=timeout_s)
    if raw is None:
        return SqlGroundedJudgment(
            verdict="UNVERIFIABLE",
            severity=None,
            reason=f"claude CLI failed: {err}",
            proposed_fix=None,
            sql_clause_cited="",
            self_critique=[],
            raw_response="",
            cached=False,
        )
    parsed = parse_response(raw)
    if parsed is None:
        return SqlGroundedJudgment(
            verdict="UNVERIFIABLE",
            severity=None,
            reason=f"failed to parse LLM response; head: {raw[:200]}",
            proposed_fix=None,
            sql_clause_cited="",
            self_critique=[],
            raw_response=raw,
            cached=False,
        )
    if use_cache:
        _save_cache(cache_dir, key, parsed)
    return parsed


# ---------------------------------------------------------------------------
# Prompt-only dry-run (for the Phase 3 gate review)
# ---------------------------------------------------------------------------
def render_prompt_only(*, column, wiki_path, object_kind, wiki_description,
                       primary_expr, primary_kind, branches, chain,
                       snippets, source_objects) -> str:
    return build_prompt(
        column=column,
        wiki_path=wiki_path,
        object_kind=object_kind,
        wiki_description=wiki_description,
        primary_kind=primary_kind,
        primary_expr=primary_expr,
        branches=branches,
        chain=chain,
        snippets=snippets,
        source_objects=source_objects,
    )
