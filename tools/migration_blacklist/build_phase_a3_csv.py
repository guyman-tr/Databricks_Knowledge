"""Phase A3: combine OpsDB execution history (Phase A0 raw) with Synapse data
freshness into a single review CSV.

Inputs:
  - audits/blacklist/_keep_universe_2026-05-31.csv
  - audits/blacklist/_a3_work/freshness_results.csv  (schema, table_name, max_update)
  - audits/blacklist/_a3_work/modify_dates.csv       (schema, table_name, object_type, create_date, modify_date)

Output:
  - audits/blacklist/migration_blacklist_phase_a3_<today>.csv

Freshness signal precedence (per output table):
  1. max_update from MAX([UpdateDate]) probe (preferred — actual data freshness)
  2. modify_date from sys.objects (fallback — DDL change / CTAS recreation time)
  3. (none)                                  -> A3_NO_SIGNAL

Verdict heuristic combining freq + days_stale:
    no signal at all                                -> A3_NO_SIGNAL
    table missing in sys.objects                    -> A3_TABLE_MISSING
    FrequencySP = Daily and stale > 365             -> A3_DAILY_365D
    FrequencySP = Daily and stale > 90              -> A3_DAILY_90D
    FrequencySP = Daily and stale > 30              -> A3_DAILY_30D
    FrequencySP = Hourly and stale > 2              -> A3_HOURLY_STALE
    FrequencySP = Monthly and stale > 45            -> A3_MONTHLY_STALE
    FrequencySP LIKE Weekly% and stale > 14         -> A3_WEEKLY_STALE
    FrequencySP = Quarterly and stale > 100         -> A3_QUARTERLY_STALE
    unknown freq and stale > 30                     -> A3_UNKNOWN_FREQ_STALE
    else                                            -> KEEP

The `decision` column is left empty for user review (DROP / KEEP / REVIEW).
"""

from __future__ import annotations

import csv
import sys
from datetime import datetime, date
from pathlib import Path

sys.stdout.reconfigure(line_buffering=True)

REPO_ROOT  = Path(__file__).resolve().parents[2]
KEEP_CSV   = REPO_ROOT / "audits" / "blacklist" / "_keep_universe_2026-05-31.csv"
FRESH_CSV  = REPO_ROOT / "audits" / "blacklist" / "_a3_work" / "freshness_results.csv"
MODIFY_CSV = REPO_ROOT / "audits" / "blacklist" / "_a3_work" / "modify_dates.csv"

TODAY = date.today()
OUT_CSV = REPO_ROOT / "audits" / "blacklist" / f"migration_blacklist_phase_a3_{TODAY:%Y-%m-%d}.csv"


def parse_dt(s: str | None):
    if not s:
        return None
    s = s.strip()
    if not s:
        return None
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M", "%Y-%m-%d"):
        try:
            return datetime.strptime(s, fmt)
        except ValueError:
            continue
    return None


def classify(freq: str, days_stale: float | None, has_signal: bool, table_exists: bool) -> str:
    if not table_exists:
        return "A3_TABLE_MISSING"
    if not has_signal or days_stale is None:
        return "A3_NO_SIGNAL"
    f = (freq or "").strip()
    d = days_stale
    if f == "Daily":
        if d > 365: return "A3_DAILY_365D"
        if d > 90:  return "A3_DAILY_90D"
        if d > 30:  return "A3_DAILY_30D"
        return "KEEP"
    if f == "Hourly":
        return "A3_HOURLY_STALE" if d > 2 else "KEEP"
    if f == "Monthly":
        return "A3_MONTHLY_STALE" if d > 45 else "KEEP"
    if f.startswith("Weekly"):
        return "A3_WEEKLY_STALE" if d > 14 else "KEEP"
    if f == "Quarterly":
        return "A3_QUARTERLY_STALE" if d > 100 else "KEEP"
    if d > 30:
        return "A3_UNKNOWN_FREQ_STALE"
    return "KEEP"


def main() -> int:
    fresh: dict[tuple[str, str], str] = {}
    if FRESH_CSV.exists():
        with FRESH_CSV.open("r", encoding="utf-8-sig") as f:
            for row in csv.DictReader(f):
                key = (row["schema"], row["table_name"])
                fresh[key] = (row.get("max_update") or "").strip()
    print(f"[a3] loaded {len(fresh)} UpdateDate probe rows", flush=True)

    modify: dict[tuple[str, str], dict] = {}
    if MODIFY_CSV.exists():
        with MODIFY_CSV.open("r", encoding="utf-8-sig") as f:
            for row in csv.DictReader(f):
                key = (row["schema"], row["table_name"])
                modify[key] = {
                    "object_type": row.get("object_type", ""),
                    "create_date": (row.get("create_date") or "").strip(),
                    "modify_date": (row.get("modify_date") or "").strip(),
                }
    print(f"[a3] loaded {len(modify)} sys.objects rows", flush=True)

    out_rows = []
    counts: dict[str, int] = {}
    sig_counts: dict[str, int] = {}
    with KEEP_CSV.open("r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            schema = row["TableSchema"].strip()
            table  = row["BareTable"].strip()
            key    = (schema, table)

            mx_raw   = fresh.get(key, "")
            mod_info = modify.get(key, {})
            mod_raw  = mod_info.get("modify_date", "")
            obj_type = mod_info.get("object_type", "")
            table_exists = bool(mod_info)

            mx_dt  = parse_dt(mx_raw)
            mod_dt = parse_dt(mod_raw)

            if mx_dt:
                freshness_dt     = mx_dt
                freshness_method = "UpdateDate"
            elif mod_dt:
                freshness_dt     = mod_dt
                freshness_method = "modify_date"
            else:
                freshness_dt     = None
                freshness_method = ""

            days = None
            if freshness_dt:
                days = (datetime.now() - freshness_dt).total_seconds() / 86400.0

            has_signal = freshness_dt is not None
            verdict = classify(row.get("FrequencySP", ""), days, has_signal, table_exists)
            counts[verdict] = counts.get(verdict, 0) + 1
            sig_counts[freshness_method or "(none)"] = sig_counts.get(freshness_method or "(none)", 0) + 1

            out_rows.append({
                "ProcedureName":    row["ProcedureName"],
                "TableName":        row["TableName"],
                "FrequencySP":      row["FrequencySP"],
                "ProcessName":      row["ProcessName"],
                "Priority":         row["Priority"],
                "object_type":      obj_type,
                "max_update":       mx_raw,
                "modify_date":      mod_raw,
                "freshness_method": freshness_method,
                "days_stale":       f"{days:.1f}" if days is not None else "",
                "verdict":          verdict,
                "decision":         "",
            })

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(
            f,
            fieldnames=[
                "ProcedureName","TableName","FrequencySP","ProcessName","Priority",
                "object_type","max_update","modify_date","freshness_method",
                "days_stale","verdict","decision",
            ],
        )
        w.writeheader()
        w.writerows(out_rows)

    print(f"[a3] wrote {len(out_rows)} rows -> {OUT_CSV}", flush=True)
    print("[a3] verdict distribution:", flush=True)
    for k in sorted(counts, key=lambda k: (-counts[k], k)):
        print(f"  {k:24s} {counts[k]:5d}", flush=True)
    print("[a3] freshness method:", flush=True)
    for k in sorted(sig_counts, key=lambda k: (-sig_counts[k], k)):
        print(f"  {k:24s} {sig_counts[k]:5d}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
