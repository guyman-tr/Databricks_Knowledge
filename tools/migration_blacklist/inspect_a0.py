"""Inspect Phase A0 CSV verdict distribution."""

from __future__ import annotations

import csv
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
A0_CSV = REPO_ROOT / "audits" / "blacklist" / "migration_blacklist_phase_a0_2026-05-31.csv"


def main() -> int:
    rows = list(csv.DictReader(A0_CSV.open("r", encoding="utf-8-sig")))
    print(f"A0 total rows: {len(rows)}")

    v: dict[str, int] = {}
    for r in rows:
        v[r["phase_a_verdict"]] = v.get(r["phase_a_verdict"], 0) + 1
    print("A0 verdict distribution:")
    for k, c in sorted(v.items(), key=lambda x: -x[1]):
        print(f"  {k:24s} {c:5d}")

    print()
    print("Sample KEEP-verdict A0 rows:")
    keep_a0 = [r for r in rows if r["phase_a_verdict"] == "KEEP"]
    for r in keep_a0[:5]:
        proc = r["ProcedureName"]
        freq = r["FrequencySP"]
        succ = r["successes_90d"]
        fail = r["failures_90d"]
        last = r["last_success"]
        print(f"  {proc:60s} freq={freq:10s} succ90d={succ} fail90d={fail} last_succ={last}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
