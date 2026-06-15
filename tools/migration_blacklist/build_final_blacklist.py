"""Build the consolidated migration blacklist combining Phase A0 + Phase A3 decisions.

Inputs:
  - audits/blacklist/migration_blacklist_phase_a0_2026-05-31.csv  (236 procs auto-blacklisted)
  - audits/blacklist/migration_blacklist_phase_a3_2026-05-31.csv  (151 procs user-blacklisted)

Output:
  - audits/blacklist/migration_blacklist_FINAL_<today>.csv         (consolidated)
  - audits/blacklist/migration_blacklist_FINAL_<today>.summary.md  (counts + breakdown)

Schema of the final CSV:
    ProcedureName, TableName, FrequencySP, ProcessName, Priority,
    blacklist_reason, source_phase, source_verdict, max_update, modify_date, days_stale
"""

from __future__ import annotations

import csv
from datetime import date
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
A0_CSV = REPO_ROOT / "audits" / "blacklist" / "migration_blacklist_phase_a0_2026-05-31.csv"
A3_CSV = REPO_ROOT / "audits" / "blacklist" / "migration_blacklist_phase_a3_2026-05-31.csv"

TODAY = date.today()
OUT_CSV = REPO_ROOT / "audits" / "blacklist" / f"migration_blacklist_FINAL_{TODAY:%Y-%m-%d}.csv"
OUT_MD  = REPO_ROOT / "audits" / "blacklist" / f"migration_blacklist_FINAL_{TODAY:%Y-%m-%d}.summary.md"


def main() -> int:
    final: list[dict] = []
    seen: set[tuple[str, str]] = set()  # (proc, table)

    a0_count = 0
    a3_count = 0

    if A0_CSV.exists():
        with A0_CSV.open("r", encoding="utf-8-sig") as f:
            for row in csv.DictReader(f):
                key = (row["ProcedureName"], row["TableName"])
                if key in seen:
                    continue
                seen.add(key)
                final.append({
                    "ProcedureName":     row["ProcedureName"],
                    "TableName":         row["TableName"],
                    "FrequencySP":       row.get("FrequencySP", ""),
                    "ProcessName":       row.get("ProcessName", ""),
                    "Priority":          row.get("Priority", ""),
                    "blacklist_reason":  row.get("phase_a_verdict", "A0"),
                    "source_phase":      "A0",
                    "source_verdict":    row.get("phase_a_verdict", ""),
                    "max_update":        "",
                    "modify_date":       "",
                    "days_stale":        "",
                })
                a0_count += 1

    if A3_CSV.exists():
        with A3_CSV.open("r", encoding="utf-8-sig") as f:
            for row in csv.DictReader(f):
                if (row["decision"] or "").strip().lower() != "blacklist":
                    continue
                key = (row["ProcedureName"], row["TableName"])
                if key in seen:
                    continue
                seen.add(key)
                verdict = row.get("verdict", "")
                # If the verdict was KEEP but the user still chose blacklist,
                # this is a user override (data is fresh, but user knows it's
                # not needed in migration — e.g. Dealing_staging copies, etc.).
                reason = "A3_USER_OVERRIDE" if verdict == "KEEP" else verdict
                final.append({
                    "ProcedureName":     row["ProcedureName"],
                    "TableName":         row["TableName"],
                    "FrequencySP":       row.get("FrequencySP", ""),
                    "ProcessName":       row.get("ProcessName", ""),
                    "Priority":          row.get("Priority", ""),
                    "blacklist_reason":  reason,
                    "source_phase":      "A3",
                    "source_verdict":    verdict,
                    "max_update":        row.get("max_update", ""),
                    "modify_date":       row.get("modify_date", ""),
                    "days_stale":        row.get("days_stale", ""),
                })
                a3_count += 1

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(
            f,
            fieldnames=[
                "ProcedureName","TableName","FrequencySP","ProcessName","Priority",
                "blacklist_reason","source_phase","source_verdict",
                "max_update","modify_date","days_stale",
            ],
        )
        w.writeheader()
        w.writerows(final)

    # --- summary stats ---
    by_phase: dict[str, int]   = {}
    by_reason: dict[str, int]  = {}
    by_schema: dict[str, int]  = {}
    by_freq: dict[str, int]    = {}
    for r in final:
        by_phase[r["source_phase"]] = by_phase.get(r["source_phase"], 0) + 1
        by_reason[r["blacklist_reason"]] = by_reason.get(r["blacklist_reason"], 0) + 1
        sch = r["TableName"].split(".", 1)[0] if "." in r["TableName"] else "(none)"
        by_schema[sch] = by_schema.get(sch, 0) + 1
        f = (r["FrequencySP"] or "(none)")
        by_freq[f] = by_freq.get(f, 0) + 1

    lines: list[str] = []
    lines.append(f"# Migration blacklist — FINAL ({TODAY:%Y-%m-%d})")
    lines.append("")
    lines.append(f"**Total blacklisted: {len(final)}** procedure->table pairs")
    lines.append("")
    lines.append(f"- Phase A0 (auto: disabled / dead 6m / failing-only): **{a0_count}**")
    lines.append(f"- Phase A3 (user-confirmed from freshness review):    **{a3_count}**")
    lines.append("")
    lines.append("## By blacklist reason")
    lines.append("")
    lines.append("| reason | count |")
    lines.append("|---|---:|")
    for k, v in sorted(by_reason.items(), key=lambda x: -x[1]):
        lines.append(f"| `{k}` | {v} |")
    lines.append("")
    lines.append("## By table schema")
    lines.append("")
    lines.append("| schema | count |")
    lines.append("|---|---:|")
    for k, v in sorted(by_schema.items(), key=lambda x: -x[1]):
        lines.append(f"| `{k}` | {v} |")
    lines.append("")
    lines.append("## By frequency")
    lines.append("")
    lines.append("| FrequencySP | count |")
    lines.append("|---|---:|")
    for k, v in sorted(by_freq.items(), key=lambda x: -x[1]):
        lines.append(f"| `{k}` | {v} |")
    lines.append("")
    lines.append(f"_Source CSV: `audits/blacklist/migration_blacklist_FINAL_{TODAY:%Y-%m-%d}.csv`_")
    OUT_MD.write_text("\n".join(lines), encoding="utf-8")

    print(f"[final] wrote {len(final)} rows -> {OUT_CSV}")
    print(f"[final] wrote summary       -> {OUT_MD}")
    print()
    print(f"  from A0: {a0_count}")
    print(f"  from A3: {a3_count}")
    print()
    print("By reason:")
    for k, v in sorted(by_reason.items(), key=lambda x: -x[1]):
        print(f"  {k:24s} {v:5d}")
    print()
    print("By schema:")
    for k, v in sorted(by_schema.items(), key=lambda x: -x[1]):
        print(f"  {k:24s} {v:5d}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
