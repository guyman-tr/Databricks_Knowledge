#!/usr/bin/env python3
"""audit_tier1_claims.py — semantic audit of (Tier 1 -- X) column claims.

Two-layer detection:

  Layer 0 (parse + resolve): for every column tagged (Tier 1 -- X) in the
            scope, locate the source-of-truth wiki via the upstream routing
            map or sibling synapse folders. If unresolved, emit an
            "L0-unresolved" amber row.

  Layer 1 (structural, free): if the source wiki's own row for that column
            is tagged (Tier 2 ...) or higher, the claim is a TIER PROMOTION
            LIE. Severity = HIGH. No LLM needed.

  Layer 2 (semantic, LLM): if the source is a genuine Tier 1 source (OLTP
            wiki under ProdSchemas or a sibling synapse wiki whose column row
            is itself Tier 1), call the LLM judge to compare descriptions.
            The judge filters out cosmetic wording differences and only
            flags substantive semantic divergence.

Usage:
  python tools/audit_tier1_claims.py                                # full DWH_dbo run with LLM
  python tools/audit_tier1_claims.py --no-llm                       # structural only (~10 min, free)
  python tools/audit_tier1_claims.py --include-glob Fact_Snapshot*  # narrow to specific files
  python tools/audit_tier1_claims.py --max-tags 20                  # smoke test with 20 tags
  python tools/audit_tier1_claims.py --output audits/_my_run        # custom output dir
"""
from __future__ import annotations

import argparse
import os
import sys
import time
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))

from tier1_audit.parser import find_tier1_claims, parse_wiki_columns, ColumnRow  # noqa: E402
from tier1_audit.resolver import resolve, is_oltp_path, REPO as RESOLVER_REPO  # noqa: E402
from tier1_audit.source_lookup import lookup_source_column, SourceColumn  # noqa: E402
from tier1_audit.judge import (  # noqa: E402
    judge_descriptions,
    claude_cli_available,
    DEFAULT_CACHE_DIR,
)
from tier1_audit.reporter import (  # noqa: E402
    AuditRow,
    RunMetadata,
    write_csv,
    write_markdown,
    write_metadata,
    utc_timestamp,
    utc_iso,
)

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
DEFAULT_SCOPE = REPO / "knowledge" / "synapse" / "Wiki" / "DWH_dbo"
DEFAULT_OUTPUT_PARENT = REPO / "audits"
DEFAULT_BLAST_RADIUS_ROOTS = [
    REPO / "knowledge" / "synapse" / "Wiki" / "BI_DB_dbo",
    REPO / "knowledge" / "synapse" / "Wiki" / "DWH_dbo",
    REPO / "knowledge" / "UC_generated",
]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _rel(p: Path) -> str:
    try:
        return p.resolve().relative_to(REPO).as_posix()
    except Exception:
        return str(p)


def _classify_source(sc: SourceColumn) -> str:
    """Return a short 'effective source tier' string for the report."""
    if sc.is_oltp_truth and not sc.source_tier:
        return "OLTP-truth"
    if sc.source_tier:
        return sc.source_tier
    return "n/a"


# ---------------------------------------------------------------------------
# Layer 0 — gather all DWH wikis + their Tier 1 claims
# ---------------------------------------------------------------------------
def _scope_wikis(scope: Path, include_glob: str | None) -> list[Path]:
    paths: list[Path] = []
    if scope.is_file():
        return [scope]
    for sub in ("Tables", "Views"):
        d = scope / sub
        if not d.is_dir():
            continue
        for p in sorted(d.glob("*.md")):
            if p.name.endswith(".lineage.md") or p.name.endswith(".review-needed.md") \
               or p.name.endswith(".deploy-report.md"):
                continue
            if include_glob and not _matches_glob(p.name, include_glob):
                continue
            paths.append(p)
    return paths


def _matches_glob(name: str, pattern: str) -> bool:
    from fnmatch import fnmatch
    return fnmatch(name, pattern)


# ---------------------------------------------------------------------------
# Layer 1 + 2 — per-claim audit
# ---------------------------------------------------------------------------
def _audit_claim(
    claim: ColumnRow,
    *,
    use_llm: bool,
    cache_dir: Path,
    judge_model: str | None,
    judge_timeout_s: int,
    meta: RunMetadata,
) -> AuditRow:
    primary = claim.primary_tier_tag
    assert primary is not None, "find_tier1_claims should guarantee this"
    raw_source = primary.source_text

    res = resolve(raw_source)

    # Layer 0 — unresolved
    if not res.resolved:
        return AuditRow(
            dwh_wiki=_rel(claim.wiki_path),
            dwh_object=claim.wiki_path.stem,
            line_no=claim.line_no,
            column_index=claim.column_index or "",
            column_name=claim.column_name,
            tier_claim_raw=raw_source,
            current_desc=claim.description,
            source_wiki="",
            source_column="",
            source_tier="",
            source_desc="",
            match_method="",
            layer="L0-unresolved",
            verdict="FAIL",
            severity="LOW",
            judge_reason="cannot locate source wiki — manual lookup required",
            proposed_fix="",
            notes=" | ".join(res.notes)[:1000],
        )

    lookup = lookup_source_column(res, claim.column_name)
    best = lookup.best_match

    # Layer 0b — resolved but no column match
    if best is None:
        return AuditRow(
            dwh_wiki=_rel(claim.wiki_path),
            dwh_object=claim.wiki_path.stem,
            line_no=claim.line_no,
            column_index=claim.column_index or "",
            column_name=claim.column_name,
            tier_claim_raw=raw_source,
            current_desc=claim.description,
            source_wiki=_rel(res.candidate_paths[0]),
            source_column="",
            source_tier="",
            source_desc="",
            match_method="",
            layer="L0-unresolved",
            verdict="FAIL",
            severity="LOW",
            judge_reason="source wiki found but no matching column row",
            proposed_fix="",
            notes=" | ".join(lookup.miss_notes)[:1000],
        )

    source_tier_str = _classify_source(best)
    base_row_kwargs = dict(
        dwh_wiki=_rel(claim.wiki_path),
        dwh_object=claim.wiki_path.stem,
        line_no=claim.line_no,
        column_index=claim.column_index or "",
        column_name=claim.column_name,
        tier_claim_raw=raw_source,
        current_desc=claim.description,
        source_wiki=_rel(best.source_wiki),
        source_column=best.matched_column,
        source_tier=source_tier_str,
        source_desc=best.description,
        match_method=best.match_method,
    )

    # Layer 1 — source's own tier is 2+ (promotion lie)
    if best.source_tier and best.source_tier in ("2", "3", "4"):
        return AuditRow(
            **base_row_kwargs,
            layer="L1-structural",
            verdict="FAIL",
            severity="HIGH",
            judge_reason=(
                f"source wiki tags this column as Tier {best.source_tier} — "
                "the (Tier 1) claim is a tier promotion lie"
            ),
            proposed_fix=(
                f"{best.description} (Tier {best.source_tier} — via {best.source_wiki.stem})"
                if best.description else
                f"(Tier {best.source_tier} — via {best.source_wiki.stem})"
            )[:500],
            notes="",
        )

    # Source is N or U or anything weird — treat as L0 amber
    if best.source_tier in ("N", "U", "5"):
        return AuditRow(
            **base_row_kwargs,
            layer="L1-structural",
            verdict="FAIL",
            severity="MEDIUM",
            judge_reason=(
                f"source column is tagged Tier {best.source_tier} — not a "
                "legitimate Tier 1 source"
            ),
            proposed_fix="",
            notes="",
        )

    # At this point source is Tier 1 OR OLTP truth — proceed to Layer 2.
    if not use_llm:
        return AuditRow(
            **base_row_kwargs,
            layer="L2-skipped",
            verdict="PASS",  # Layer 1 passed; semantic check deferred
            severity="",
            judge_reason="Layer 1 PASS (source is Tier 1 / OLTP truth); Layer 2 skipped (--no-llm)",
            proposed_fix="",
            notes="",
        )

    judgment = judge_descriptions(
        column=claim.column_name,
        source_wiki=_rel(best.source_wiki),
        source_tier=source_tier_str,
        source_desc=best.description,
        claim_desc=claim.description,
        cache_dir=cache_dir,
        model=judge_model,
        timeout_s=judge_timeout_s,
    )
    if judgment.cached:
        meta.judge_cache_hits += 1
    else:
        meta.judge_calls_made += 1
    if judgment.verdict == "FAIL" and judgment.reason.startswith("judge unavailable"):
        meta.judge_failed += 1

    return AuditRow(
        **base_row_kwargs,
        layer="L2-semantic",
        verdict=judgment.verdict,
        severity=judgment.severity or "",
        judge_reason=judgment.reason,
        proposed_fix=judgment.proposed_fix or "",
        notes="cached" if judgment.cached else "",
    )


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--scope", type=Path, default=DEFAULT_SCOPE,
                   help="Folder or file to audit (default: knowledge/synapse/Wiki/DWH_dbo)")
    p.add_argument("--include-glob", type=str, default=None,
                   help="Filename glob to narrow scope (e.g. 'Fact_*.md')")
    p.add_argument("--max-tags", type=int, default=0,
                   help="Stop after N Tier-1 tags (0 = no limit). For smoke tests.")
    p.add_argument("--output", type=Path, default=None,
                   help=f"Output dir (default: {DEFAULT_OUTPUT_PARENT}/_tier1_audit_<UTC-timestamp>)")
    p.add_argument("--no-llm", action="store_true",
                   help="Layer 1 only — no LLM judge calls (free, fast)")
    p.add_argument("--judge-model", type=str, default=None,
                   help="claude --model arg (default: CLI default, usually sonnet)")
    p.add_argument("--judge-timeout", type=int, default=120,
                   help="Per-call LLM timeout in seconds")
    p.add_argument("--cache-dir", type=Path, default=DEFAULT_CACHE_DIR,
                   help="Judge cache dir (re-runs are free for cached pairs)")
    p.add_argument("--progress-every", type=int, default=25,
                   help="Print status line every N tags")
    args = p.parse_args()

    scope = args.scope.resolve()
    if not scope.exists():
        print(f"ERROR: scope not found: {scope}", file=sys.stderr)
        return 2

    out_dir = args.output.resolve() if args.output else (
        DEFAULT_OUTPUT_PARENT / f"_tier1_audit_{utc_timestamp()}"
    )
    out_dir.mkdir(parents=True, exist_ok=True)

    use_llm = not args.no_llm
    if use_llm and not claude_cli_available():
        print("WARNING: --no-llm not set but claude CLI not found; falling back to "
              "Layer 1 only.", file=sys.stderr)
        use_llm = False

    meta = RunMetadata(
        scope=_rel(scope),
        started_at=utc_iso(),
        llm_disabled=not use_llm,
        judge_model=args.judge_model,
    )

    wikis = _scope_wikis(scope, args.include_glob)
    meta.total_wikis_scanned = len(wikis)
    print(f"[tier1-audit] scope={_rel(scope)} wikis={len(wikis)} llm={'ON' if use_llm else 'OFF'}",
          flush=True)

    # Phase A — collect all claims
    all_claims: list[ColumnRow] = []
    for wiki in wikis:
        all_claims.extend(find_tier1_claims(wiki))
    meta.total_tier1_tags = len(all_claims)
    if args.max_tags and args.max_tags < len(all_claims):
        all_claims = all_claims[: args.max_tags]
        print(f"[tier1-audit] capped to first {args.max_tags} tag(s) for smoke test", flush=True)
    print(f"[tier1-audit] tier-1 claims to audit: {len(all_claims)} (of {meta.total_tier1_tags} total)",
          flush=True)

    # Phase B — audit each claim
    start_t = time.time()
    rows: list[AuditRow] = []
    layer_counts: Counter = Counter()
    verdict_counts: Counter = Counter()
    severity_counts: Counter = Counter()
    for i, claim in enumerate(all_claims, start=1):
        row = _audit_claim(
            claim,
            use_llm=use_llm,
            cache_dir=args.cache_dir,
            judge_model=args.judge_model,
            judge_timeout_s=args.judge_timeout,
            meta=meta,
        )
        rows.append(row)
        layer_counts[row.layer] += 1
        verdict_counts[row.verdict] += 1
        if row.severity:
            severity_counts[row.severity] += 1
        if args.progress_every and i % args.progress_every == 0:
            elapsed = time.time() - start_t
            rate = i / elapsed if elapsed else 0
            print(
                f"[tier1-audit] {i}/{len(all_claims)} "
                f"({100.0 * i / max(len(all_claims), 1):.1f}%) "
                f"elapsed={elapsed:.0f}s rate={rate:.1f}/s "
                f"PASS={verdict_counts['PASS']} FAIL={verdict_counts['FAIL']} "
                f"(judge_calls={meta.judge_calls_made} cache_hits={meta.judge_cache_hits})",
                flush=True,
            )

    meta.wall_clock_s = time.time() - start_t
    meta.finished_at = utc_iso()
    meta.counts_by_layer = dict(layer_counts)
    meta.counts_by_verdict = dict(verdict_counts)
    meta.counts_by_severity = dict(severity_counts)

    # Phase C — write outputs
    csv_path = out_dir / "report.csv"
    md_path = out_dir / "report.md"
    meta_path = out_dir / "_run_metadata.json"
    write_csv(rows, csv_path)
    write_markdown(rows, meta, md_path,
                   blast_radius_roots=DEFAULT_BLAST_RADIUS_ROOTS)
    write_metadata(meta, meta_path)

    print(flush=True)
    print(f"[tier1-audit] done in {meta.wall_clock_s:.1f}s", flush=True)
    print(f"[tier1-audit]   PASS: {verdict_counts['PASS']}", flush=True)
    print(f"[tier1-audit]   FAIL: {verdict_counts['FAIL']}  "
          f"(HIGH={severity_counts.get('HIGH', 0)} "
          f"MEDIUM={severity_counts.get('MEDIUM', 0)} "
          f"LOW={severity_counts.get('LOW', 0)})", flush=True)
    print(f"[tier1-audit]   judge: calls={meta.judge_calls_made} "
          f"cache_hits={meta.judge_cache_hits} failed={meta.judge_failed}", flush=True)
    print(f"[tier1-audit] wrote:", flush=True)
    print(f"  {_rel(csv_path)}", flush=True)
    print(f"  {_rel(md_path)}", flush=True)
    print(f"  {_rel(meta_path)}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
