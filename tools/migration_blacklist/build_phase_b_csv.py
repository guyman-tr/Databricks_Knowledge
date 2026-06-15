"""Phase B: combine Tableau workbook bindings + view-stats + SP feeder graph
into the Phase B review CSV.

Inputs:
  - audits/blacklist/migration_blacklist_phase_a3_2026-05-31.csv  (post-A3 universe)
  - audits/blacklist/migration_blacklist_FINAL_2026-05-31.csv     (already blacklisted)
  - knowledge/tableau/_index/workbooks.csv                        (table -> workbooks, with updated_at)
  - knowledge/tableau/_index/usage.csv                            (workbook -> total_views)
  - audits/blacklist/_b_work/sp_dependencies.csv                  (SP -> referenced tables)

Tableau "freshness" signals available:
  - total_views per workbook (lifetime, no time window — `last_viewed_at` is
    not exposed in this Tableau Server REST API version)
  - workbook.updated_at (when the workbook definition was last edited;
    a proxy for "is this dashboard being maintained?")

Verdict heuristic per surviving (proc, table) pair:
  - is_feeder for live-output proc       -> B_FEEDER_KEEP
  - workbooks=0 AND not feeder           -> B_NO_TABLEAU_CONSUMER  (strong)
  - workbooks>=1 AND total_views_sum=0   -> B_NEVER_VIEWED         (strong)
  - workbooks>=1 AND total_views_sum<=5
        AND newest workbook >365d old    -> B_LOW_USE_STALE        (moderate)
  - workbooks>=1 AND total_views_sum<=20
        AND newest workbook >730d old    -> B_LOW_USE_STALE        (moderate)
  - else                                  -> KEEP

The `decision` column is left empty for user review.
"""

from __future__ import annotations

import csv
import sys
from datetime import datetime, date, timezone
from pathlib import Path

sys.stdout.reconfigure(line_buffering=True)

REPO_ROOT  = Path(__file__).resolve().parents[2]
A3_CSV     = REPO_ROOT / "audits" / "blacklist" / "migration_blacklist_phase_a3_2026-05-31.csv"
FINAL_CSV  = REPO_ROOT / "audits" / "blacklist" / "migration_blacklist_FINAL_2026-05-31.csv"
WBS_CSV    = REPO_ROOT / "knowledge" / "tableau" / "_index" / "workbooks.csv"
USAGE_CSV  = REPO_ROOT / "knowledge" / "tableau" / "_index" / "usage.csv"
DEPS_CSV       = REPO_ROOT / "audits" / "blacklist" / "_b_work" / "sp_dependencies.csv"
FEEDER_TARGETS = REPO_ROOT / "audits" / "blacklist" / "_b_work" / "feeder_targets.txt"

TODAY = date.today()
OUT_CSV = REPO_ROOT / "audits" / "blacklist" / f"migration_blacklist_phase_b_{TODAY:%Y-%m-%d}.csv"


def parse_dt(s: str | None):
    if not s:
        return None
    s = s.strip()
    if not s:
        return None
    # Tableau ISO ts: 2025-12-11T15:13:02Z
    s = s.replace("Z", "+00:00")
    for fmt in ("%Y-%m-%dT%H:%M:%S%z", "%Y-%m-%d %H:%M:%S", "%Y-%m-%d"):
        try:
            dt = datetime.strptime(s, fmt)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            return dt
        except ValueError:
            continue
    return None


def main() -> int:
    # 1. Already-blacklisted (proc, table) pairs.
    already_blacklisted: set[tuple[str, str]] = set()
    if FINAL_CSV.exists():
        with FINAL_CSV.open("r", encoding="utf-8-sig") as f:
            for row in csv.DictReader(f):
                already_blacklisted.add((row["ProcedureName"], row["TableName"]))
    print(f"[b] already-blacklisted (A0+A3): {len(already_blacklisted)} pairs", flush=True)

    # 2. Surviving universe.
    surviving: list[dict] = []
    with A3_CSV.open("r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            if (row["ProcedureName"], row["TableName"]) in already_blacklisted:
                continue
            if (row.get("decision") or "").strip().lower() == "blacklist":
                continue
            surviving.append(row)
    print(f"[b] surviving rows: {len(surviving)}", flush=True)

    # 3. (bare_table -> [{luid, updated_at}]) from workbooks.csv.
    wb_per_table: dict[str, list[dict]] = {}
    wb_updated: dict[str, str] = {}
    if WBS_CSV.exists():
        with WBS_CSV.open("r", encoding="utf-8-sig") as f:
            for row in csv.DictReader(f):
                t = (row.get("table") or "").strip()
                luid = (row.get("workbook_luid") or "").strip()
                upd = (row.get("updated_at") or "").strip()
                if not t or not luid:
                    continue
                wb_per_table.setdefault(t, []).append({"luid": luid, "updated_at": upd})
                wb_updated[luid] = upd
        print(f"[b] tableau bindings indexed for {len(wb_per_table)} tables", flush=True)
    else:
        print(f"[b] WARN: {WBS_CSV} missing", flush=True)

    # 4. (workbook_luid -> total_views).
    usage: dict[str, int] = {}
    if USAGE_CSV.exists():
        with USAGE_CSV.open("r", encoding="utf-8-sig") as f:
            for row in csv.DictReader(f):
                luid = row["workbook_luid"]
                try:
                    usage[luid] = int(row.get("total_views") or 0)
                except (TypeError, ValueError):
                    usage[luid] = 0
        print(f"[b] tableau usage stats for {len(usage)} workbooks", flush=True)

    # 5. Feeder graph: bare table names that are read by another surviving proc
    #    (built from source-level grep of sys.sql_modules — see
    #    tools/migration_blacklist/build_feeder_graph.py).
    feeder_target_tables: set[str] = set()
    if FEEDER_TARGETS.exists():
        for line in FEEDER_TARGETS.read_text(encoding="utf-8").splitlines():
            t = line.strip()
            if t:
                feeder_target_tables.add(t)
        print(f"[b] feeder graph: {len(feeder_target_tables)} bare tables read by another surviving proc", flush=True)
    else:
        print(f"[b] WARN: {FEEDER_TARGETS} missing — feeder analysis skipped", flush=True)

    # 6. Classify.
    now = datetime.now(timezone.utc)
    out_rows: list[dict] = []
    counts: dict[str, int] = {}

    for s in surviving:
        bare = s["TableName"].split(".", 1)[-1].strip("[]") if "." in s["TableName"] else s["TableName"]
        wbs = wb_per_table.get(bare, [])
        wb_count = len(wbs)
        total_views_sum = 0
        newest_wb_dt: datetime | None = None
        for w in wbs:
            total_views_sum += usage.get(w["luid"], 0)
            dt = parse_dt(w["updated_at"])
            if dt and (newest_wb_dt is None or dt > newest_wb_dt):
                newest_wb_dt = dt
        wb_age_days = ""
        if newest_wb_dt is not None:
            wb_age_days = f"{(now - newest_wb_dt).total_seconds() / 86400.0:.0f}"

        is_feeder = bare in feeder_target_tables

        if wb_count == 0:
            verdict = "B_FEEDER_KEEP" if is_feeder else "B_NO_TABLEAU_CONSUMER"
        elif total_views_sum == 0:
            # Internal feeders override the dead-Tableau verdict — data is
            # still consumed by another KEEP proc.
            verdict = "B_FEEDER_KEEP" if is_feeder else "B_NEVER_VIEWED"
        else:
            wb_age = (now - newest_wb_dt).total_seconds() / 86400.0 if newest_wb_dt else 0
            if total_views_sum <= 5 and wb_age > 365:
                verdict = "B_FEEDER_KEEP" if is_feeder else "B_LOW_USE_STALE"
            elif total_views_sum <= 20 and wb_age > 730:
                verdict = "B_FEEDER_KEEP" if is_feeder else "B_LOW_USE_STALE"
            else:
                verdict = "KEEP"

        counts[verdict] = counts.get(verdict, 0) + 1

        newest_str = newest_wb_dt.strftime("%Y-%m-%d") if newest_wb_dt else ""

        out_rows.append({
            "ProcedureName":        s["ProcedureName"],
            "TableName":            s["TableName"],
            "FrequencySP":          s.get("FrequencySP", ""),
            "ProcessName":          s.get("ProcessName", ""),
            "Priority":             s.get("Priority", ""),
            "max_update":           s.get("max_update", ""),
            "modify_date":          s.get("modify_date", ""),
            "freshness_method":     s.get("freshness_method", ""),
            "tableau_workbooks":    wb_count,
            "total_views_sum":      total_views_sum,
            "newest_wb_updated":    newest_str,
            "newest_wb_age_days":   wb_age_days,
            "is_feeder":            "Y" if is_feeder else "",
            "verdict":              verdict,
            "decision":             "",
        })

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(
            f,
            fieldnames=[
                "ProcedureName","TableName","FrequencySP","ProcessName","Priority",
                "max_update","modify_date","freshness_method",
                "tableau_workbooks","total_views_sum",
                "newest_wb_updated","newest_wb_age_days",
                "is_feeder","verdict","decision",
            ],
        )
        w.writeheader()
        w.writerows(out_rows)

    print(f"\n[b] wrote {len(out_rows)} rows -> {OUT_CSV}")
    print("[b] verdict distribution:")
    for k, v in sorted(counts.items(), key=lambda x: -x[1]):
        print(f"  {k:24s} {v:5d}  ({100*v/len(out_rows):5.1f}%)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
