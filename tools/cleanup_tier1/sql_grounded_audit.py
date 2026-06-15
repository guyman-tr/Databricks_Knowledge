"""sql_grounded_audit.py — SQL-grounded LLM column audit driver.

Replaces the old wiki-to-wiki harness with one that grounds every verdict in
the actual SQL that produces each column. Three-step pipeline per row:

  1. sql_locator.locate_sql(wiki_path)       -> producing .sql file(s)
  2. sql_extractor.extract_column(...)        -> producing SELECT expression
  3. sql_grounded_judge.judge(...)            -> VERIFIED / CONTRADICTED /
                                                  UNVERIFIABLE

Output schema is compatible with the existing
`apply_column_fixes.py` and `review_proposed_fixes.py`:

  - verdict          = "PASS"  for VERIFIED
                       "FAIL"  for CONTRADICTED
                       "UNVERIFIABLE" for UNVERIFIABLE (skipped by apply)
                       "ERROR" for failures upstream of the judge
  - sql_verdict      = the raw judge verdict
  - severity, reason, proposed_fix carry over.
  - sql_clause_cited, self_critique are new evidence fields.

Parallelism via ThreadPoolExecutor (default 4 workers). Each judge call
has its own disk cache, keyed by (column, wiki_path, wiki_description,
primary_expr, all branches) — so a SP edit re-validates only affected rows.

Usage:

  python -m cleanup_tier1.sql_grounded_audit \
      --columns Amount,IsActiveTrade,IsBuy,IsLeverage,IsCopy \
      --scope knowledge/synapse/Wiki \
      --workers 4

  # Calibration mode: only rows that match a prior FAIL set.
  python -m cleanup_tier1.sql_grounded_audit \
      --replay-fails audits/_llm_column_audit_funcs_<ts>/report.csv \
      --only-fails

Outputs land under `audits/_sql_grounded_audit_<UTC>/`.
"""
from __future__ import annotations

import argparse
import csv
import sys
import threading
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Optional

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "tools"))

from tier1_audit.parser import parse_wiki_columns, ColumnRow  # noqa: E402
from tier1_audit.judge import claude_cli_available           # noqa: E402

from cleanup_tier1.sql_locator import locate_sql               # noqa: E402
from cleanup_tier1.sql_extractor import extract_column         # noqa: E402
from cleanup_tier1.sql_grounded_judge import (                 # noqa: E402
    judge, SqlGroundedJudgment, DEFAULT_CACHE_DIR,
)


WIKI_ROOTS = [
    REPO / "knowledge" / "synapse" / "Wiki",
    REPO / "knowledge" / "UC_generated",
    REPO / "knowledge" / "ProdSchemas",
]
SKIP_PATH_FRAGMENTS = ("_discovery/upstream_wikis", "_discovery/column_lineage")
SKIP_SUFFIXES = (".lineage.md", ".review-needed.md", ".deploy-report.md",
                 ".status.json")


# ---------------------------------------------------------------------------
# Row collection (mirrors llm_column_audit.collect_rows)
# ---------------------------------------------------------------------------
def collect_rows(column_names: set[str], roots: list[Path]) -> list[ColumnRow]:
    rows: list[ColumnRow] = []
    for root in roots:
        if not root.exists():
            continue
        for md in root.rglob("*.md"):
            if any(md.name.endswith(s) for s in SKIP_SUFFIXES):
                continue
            rel = md.relative_to(REPO).as_posix()
            if any(f in rel for f in SKIP_PATH_FRAGMENTS):
                continue
            try:
                parsed = parse_wiki_columns(md)
            except Exception:
                continue
            for r in parsed:
                if r.column_name in column_names:
                    rows.append(r)
    return rows


# ---------------------------------------------------------------------------
# Per-row audit
# ---------------------------------------------------------------------------
@dataclass
class AuditResult:
    column_name: str
    wiki_path: str
    line_no: int
    object_kind: str
    sql_path: str
    sql_locator_confidence: str
    primary_kind: str
    primary_expr: str
    branch_count: int
    chain_steps: int
    source_objects: str
    current_desc: str
    sql_verdict: str            # VERIFIED / CONTRADICTED / UNVERIFIABLE / LOCATOR / EXTRACTOR
    verdict: str                # PASS / FAIL / UNVERIFIABLE / ERROR (compat with apply)
    severity: str
    reason: str
    proposed_fix: str
    sql_clause_cited: str
    self_critique: str
    judge_status: str           # "cached" / "fresh" / "skipped" / "error"


def _audit_one(
    row: ColumnRow,
    *,
    cache_dir: Path,
    model: Optional[str],
    timeout_s: int,
) -> AuditResult:
    wp = row.wiki_path if row.wiki_path.is_absolute() else (REPO / row.wiki_path)
    rel = wp.relative_to(REPO).as_posix() if REPO in wp.parents else str(wp)

    base = dict(
        column_name=row.column_name,
        wiki_path=rel,
        line_no=row.line_no,
        current_desc=row.description,
    )

    # Step 1: locate SQL.
    loc = locate_sql(wp)
    if not loc.resolved:
        return AuditResult(
            **base,
            object_kind=loc.object_kind,
            sql_path="",
            sql_locator_confidence=loc.confidence,
            primary_kind="",
            primary_expr="",
            branch_count=0,
            chain_steps=0,
            source_objects="",
            sql_verdict="LOCATOR",
            verdict="UNVERIFIABLE",
            severity="",
            reason=f"locator: {'; '.join(loc.notes) or 'no SQL'}",
            proposed_fix="",
            sql_clause_cited="",
            self_critique="",
            judge_status="skipped",
        )

    # Step 2: extract column expression.
    target_table = loc.object_name if loc.object_kind == "table" else ""
    sql_path = loc.sql_paths[0]
    ext = extract_column(sql_path, loc.object_kind, row.column_name, target_table)

    sql_path_rel = (sql_path.relative_to(REPO) if REPO in sql_path.parents
                    else sql_path).as_posix() if hasattr(sql_path, "as_posix") else str(sql_path)
    # Try also relative to DataPlatform for prettier names.
    from cleanup_tier1.sql_locator import DATAPLATFORM
    try:
        sql_path_rel = sql_path.relative_to(DATAPLATFORM).as_posix()
    except ValueError:
        pass

    if ext.primary is None:
        return AuditResult(
            **base,
            object_kind=loc.object_kind,
            sql_path=sql_path_rel,
            sql_locator_confidence=loc.confidence,
            primary_kind="",
            primary_expr="",
            branch_count=len(ext.branches),
            chain_steps=len(ext.chain),
            source_objects=" | ".join(ext.source_objects),
            sql_verdict="EXTRACTOR",
            verdict="UNVERIFIABLE",
            severity="",
            reason=f"extractor: {'; '.join(ext.notes) or 'no expression'}",
            proposed_fix="",
            sql_clause_cited="",
            self_critique="",
            judge_status="skipped",
        )

    # Step 3: SQL-grounded judge.
    try:
        j: SqlGroundedJudgment = judge(
            column=row.column_name,
            wiki_path=rel,
            object_kind=ext.object_kind,
            wiki_description=row.description,
            primary_expr=ext.primary.expression_sql,
            primary_kind=ext.primary.kind,
            branches=ext.branches,
            chain=ext.chain,
            snippets=ext.raw_sql_snippets,
            source_objects=ext.source_objects,
            model=model,
            timeout_s=timeout_s,
            cache_dir=cache_dir,
        )
    except Exception as e:
        return AuditResult(
            **base,
            object_kind=ext.object_kind,
            sql_path=sql_path_rel,
            sql_locator_confidence=loc.confidence,
            primary_kind=ext.primary.kind,
            primary_expr=ext.primary.expression_sql[:500],
            branch_count=len(ext.branches),
            chain_steps=len(ext.chain),
            source_objects=" | ".join(ext.source_objects),
            sql_verdict="ERROR",
            verdict="ERROR",
            severity="",
            reason=f"judge exception: {e}"[:300],
            proposed_fix="",
            sql_clause_cited="",
            self_critique="",
            judge_status="error",
        )

    verdict_compat = {
        "VERIFIED": "PASS",
        "CONTRADICTED": "FAIL",
        "UNVERIFIABLE": "UNVERIFIABLE",
    }.get(j.verdict, "ERROR")

    return AuditResult(
        **base,
        object_kind=ext.object_kind,
        sql_path=sql_path_rel,
        sql_locator_confidence=loc.confidence,
        primary_kind=ext.primary.kind,
        primary_expr=ext.primary.expression_sql[:500],
        branch_count=len(ext.branches),
        chain_steps=len(ext.chain),
        source_objects=" | ".join(ext.source_objects),
        sql_verdict=j.verdict,
        verdict=verdict_compat,
        severity=j.severity or "",
        reason=j.reason,
        proposed_fix=j.proposed_fix or "",
        sql_clause_cited=j.sql_clause_cited,
        self_critique=" | ".join(j.self_critique)[:800],
        judge_status="cached" if j.cached else "fresh",
    )


# ---------------------------------------------------------------------------
# Replay/calibration support
# ---------------------------------------------------------------------------
def filter_rows_by_replay(
    rows: list[ColumnRow],
    replay_csv: Path,
    only_fails: bool,
) -> list[ColumnRow]:
    """Keep only rows whose (wiki_path, column, line_no) appear in replay_csv."""
    if not replay_csv.exists():
        raise SystemExit(f"--replay-fails: file not found: {replay_csv}")
    wanted: set[tuple[str, str, int]] = set()
    with replay_csv.open("r", encoding="utf-8", newline="") as f:
        r = csv.DictReader(f)
        for d in r:
            if only_fails and d.get("verdict") != "FAIL":
                continue
            try:
                ln = int(d.get("line_no") or 0)
            except ValueError:
                ln = 0
            wanted.add((
                (d.get("wiki_path") or "").replace("\\", "/").lower(),
                (d.get("column_name") or "").lower(),
                ln,
            ))
    out: list[ColumnRow] = []
    for row in rows:
        rel = row.wiki_path.relative_to(REPO).as_posix() if REPO in row.wiki_path.parents else str(row.wiki_path)
        key = (rel.lower(), row.column_name.lower(), row.line_no)
        if key in wanted:
            out.append(row)
    return out


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--columns", default="",
                    help="comma-separated columns (required unless --replay-fails)")
    ap.add_argument("--scope", default=",".join(
        str(r.relative_to(REPO)) for r in WIKI_ROOTS),
        help="comma-separated wiki roots (default: all 3)")
    ap.add_argument("--replay-fails", default="",
                    help="path to a prior audit report.csv; only re-audit rows "
                         "present in that report")
    ap.add_argument("--only-fails", action="store_true",
                    help="with --replay-fails, restrict to verdict=FAIL rows")
    ap.add_argument("--max-rows", type=int, default=0,
                    help="cap to first N matching rows (smoke test)")
    ap.add_argument("--out",
                    default=f"audits/_sql_grounded_audit_{time.strftime('%Y%m%dT%H%M%SZ', time.gmtime())}",
                    help="output directory")
    ap.add_argument("--cache-dir", default=str(DEFAULT_CACHE_DIR))
    ap.add_argument("--model", default=None,
                    help="claude --model (default: CLI default)")
    ap.add_argument("--timeout", type=int, default=180)
    ap.add_argument("--workers", type=int, default=4,
                    help="number of concurrent LLM judge calls (default: 4)")
    ap.add_argument("--no-llm", action="store_true",
                    help="resolve + extract only, no LLM calls (dry run)")
    ap.add_argument("--include-sources", action="store_true",
                    help="include rows under knowledge/ProdSchemas (default: skip)")
    args = ap.parse_args(argv)

    cache_dir = Path(args.cache_dir)
    out_dir = REPO / args.out
    out_dir.mkdir(parents=True, exist_ok=True)

    if not args.no_llm and not claude_cli_available():
        print("ERROR: claude CLI not available — install or pass --no-llm",
              file=sys.stderr)
        return 2

    # ---- collect rows ----
    if args.replay_fails:
        # Read the columns directly from the replay CSV.
        rep = REPO / args.replay_fails if not Path(args.replay_fails).is_absolute() \
            else Path(args.replay_fails)
        with rep.open("r", encoding="utf-8", newline="") as f:
            r = csv.DictReader(f)
            cols = {d["column_name"] for d in r if d.get("column_name")}
        columns = cols
        roots = [REPO / p.strip() for p in args.scope.split(",") if p.strip()]
        all_rows = collect_rows(columns, roots)
        rows = filter_rows_by_replay(all_rows, rep, args.only_fails)
        print(f"[1/3] replay mode: matched {len(rows)} rows from {len(all_rows)} candidates")
    else:
        if not args.columns:
            print("ERROR: --columns required (or pass --replay-fails)",
                  file=sys.stderr)
            return 2
        columns = {c.strip() for c in args.columns.split(",") if c.strip()}
        roots = [REPO / p.strip() for p in args.scope.split(",") if p.strip()]
        print(f"[1/3] collecting rows for {sorted(columns)} …", flush=True)
        rows = collect_rows(columns, roots)
        print(f"      found {len(rows)} matching rows across "
              f"{len({r.wiki_path for r in rows})} wikis")

    if not args.include_sources:
        before = len(rows)
        rows = [r for r in rows
                if "knowledge/ProdSchemas/" not in r.wiki_path.as_posix()
                and "knowledge\\ProdSchemas\\" not in str(r.wiki_path)]
        if before != len(rows):
            print(f"      filtered out ProdSchemas rows: "
                  f"{before - len(rows)} dropped, {len(rows)} remain")
    if args.max_rows and args.max_rows < len(rows):
        rows = rows[: args.max_rows]
        print(f"      capped to first {args.max_rows} (smoke test)")

    if args.no_llm:
        print("[2/3] dry-run (no LLM); printing locator + extractor verdicts …")
        for r in rows:
            wp = r.wiki_path if r.wiki_path.is_absolute() else (REPO / r.wiki_path)
            loc = locate_sql(wp)
            if not loc.resolved:
                print(f"  LOCATOR    {wp.name}:{r.line_no} {r.column_name}  -> {loc.confidence} ({'; '.join(loc.notes)})")
                continue
            target_table = loc.object_name if loc.object_kind == "table" else ""
            ext = extract_column(loc.sql_paths[0], loc.object_kind, r.column_name, target_table)
            tag = "OK   " if ext.primary else "NOPRIM"
            expr = ext.primary.expression_sql[:80] if ext.primary else "(none)"
            print(f"  {tag:6s} {wp.name}:{r.line_no} {r.column_name}  -> ({ext.primary.kind if ext.primary else '-'}) {expr}")
        return 0

    workers = max(1, args.workers)
    print(f"[2/3] auditing each row with SQL-grounded judge "
          f"({workers}-way parallel) …", flush=True)
    results: list[Optional[AuditResult]] = [None] * len(rows)
    t0 = time.time()
    verdicts: Counter = Counter()
    sql_verdicts: Counter = Counter()
    lock = threading.Lock()
    done = 0
    with ThreadPoolExecutor(max_workers=workers) as ex:
        fut_to_idx = {
            ex.submit(_audit_one, r,
                      cache_dir=cache_dir, model=args.model,
                      timeout_s=args.timeout): i
            for i, r in enumerate(rows)
        }
        for fut in as_completed(fut_to_idx):
            idx = fut_to_idx[fut]
            try:
                res = fut.result()
            except Exception as e:
                rr = rows[idx]
                rel = rr.wiki_path.relative_to(REPO).as_posix() if REPO in rr.wiki_path.parents else str(rr.wiki_path)
                res = AuditResult(
                    column_name=rr.column_name, wiki_path=rel, line_no=rr.line_no,
                    object_kind="", sql_path="", sql_locator_confidence="",
                    primary_kind="", primary_expr="", branch_count=0, chain_steps=0,
                    source_objects="", current_desc=rr.description,
                    sql_verdict="ERROR", verdict="ERROR", severity="",
                    reason=f"exception in worker: {e}"[:300],
                    proposed_fix="", sql_clause_cited="", self_critique="",
                    judge_status="error",
                )
            with lock:
                results[idx] = res
                verdicts[res.verdict] += 1
                sql_verdicts[res.sql_verdict] += 1
                done += 1
                if done % 5 == 0 or done == len(rows):
                    elapsed = time.time() - t0
                    rate = done / elapsed if elapsed else 0
                    print(
                        f"  {done}/{len(rows)}  elapsed={elapsed:.0f}s  "
                        f"rate={rate:.1f}/s  "
                        f"PASS={verdicts['PASS']} FAIL={verdicts['FAIL']} "
                        f"UV={verdicts['UNVERIFIABLE']} ERR={verdicts['ERROR']}",
                        flush=True,
                    )
    results = [r for r in results if r is not None]

    # ---- write outputs ----
    print("[3/3] writing outputs …")
    csv_path = out_dir / "report.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(
            f,
            fieldnames=list(asdict(results[0]).keys()) if results else [],
        )
        if results:
            w.writeheader()
            for r in results:
                w.writerow(asdict(r))
    print(f"      {csv_path.relative_to(REPO)}")

    md_path = out_dir / "report.md"
    with md_path.open("w", encoding="utf-8") as f:
        f.write("# SQL-grounded column audit\n\n")
        f.write(f"Total rows audited: {len(results)}\n\n")
        f.write("## Compat verdict distribution\n")
        for v, n in verdicts.most_common():
            f.write(f"- **{v}**: {n}\n")
        f.write("\n## Raw SQL verdict distribution\n")
        for v, n in sql_verdicts.most_common():
            f.write(f"- **{v}**: {n}\n")
        f.write("\n---\n\n## CONTRADICTED rows\n\n")
        for r in results:
            if r.sql_verdict != "CONTRADICTED":
                continue
            f.write(f"### {r.column_name}  —  {r.wiki_path}:{r.line_no}\n\n")
            f.write(f"- severity: **{r.severity}**\n")
            f.write(f"- reason: {r.reason}\n")
            f.write(f"- sql_clause_cited: `{r.sql_clause_cited[:300]}`\n")
            f.write(f"- current desc: {r.current_desc[:400]}\n")
            f.write(f"- **proposed**: {r.proposed_fix[:400]}\n")
            if r.self_critique:
                f.write(f"- self_critique: {r.self_critique[:400]}\n")
            f.write("\n")
        f.write("\n## UNVERIFIABLE rows (skipped by apply)\n\n")
        for r in results:
            if r.sql_verdict != "UNVERIFIABLE":
                continue
            f.write(f"- `{r.wiki_path}:{r.line_no}` {r.column_name} — {r.reason[:200]}\n")
        f.write("\n## LOCATOR/EXTRACTOR failures\n\n")
        for r in results:
            if r.sql_verdict not in ("LOCATOR", "EXTRACTOR"):
                continue
            f.write(f"- `{r.wiki_path}:{r.line_no}` {r.column_name} — {r.sql_verdict}: {r.reason[:200]}\n")
    print(f"      {md_path.relative_to(REPO)}")

    print()
    print(f"Done in {time.time() - t0:.0f}s")
    print("Compat verdicts:")
    for v, n in verdicts.most_common():
        print(f"  {v}: {n}")
    print("SQL verdicts:")
    for v, n in sql_verdicts.most_common():
        print(f"  {v}: {n}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
