"""Inspect the user-filled `decision` column in the Phase A3 review CSV."""

from __future__ import annotations

import csv
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
A3_CSV = REPO_ROOT / "audits" / "blacklist" / "migration_blacklist_phase_a3_2026-05-31.csv"


def main() -> int:
    rows = list(csv.DictReader(A3_CSV.open("r", encoding="utf-8-sig")))
    total = len(rows)
    print(f"total rows: {total}\n")

    print("=== decision distribution ===")
    dec_counts: dict[str, int] = {}
    for r in rows:
        key = (r["decision"].strip().lower() or "(blank)")
        dec_counts[key] = dec_counts.get(key, 0) + 1
    for k, v in sorted(dec_counts.items(), key=lambda x: -x[1]):
        print(f"  {k:20s} {v:5d}  ({100*v/total:5.1f}%)")

    print("\n=== decision x verdict cross-tab ===")
    xtab: dict[str, dict[str, int]] = {}
    for r in rows:
        dec = r["decision"].strip().lower() or "(blank)"
        ver = r["verdict"]
        xtab.setdefault(ver, {}).setdefault(dec, 0)
        xtab[ver][dec] += 1
    all_dec = sorted({d for v in xtab.values() for d in v})
    header = " " * 24 + " ".join(f"{d:>12s}" for d in all_dec)
    print(header)
    for v in sorted(xtab):
        line = f"{v:24s}"
        for d in all_dec:
            line += f" {xtab[v].get(d, 0):12d}"
        print(line)

    print("\n=== Surprising decisions (worth a sanity check) ===")
    print(f"  KEEP-verdict procs marked blacklist:")
    for r in rows:
        if r["verdict"] == "KEEP" and r["decision"].strip().lower() in ("blacklist", "drop"):
            print(f"    {r['ProcedureName']} -> {r['TableName']} (days_stale={r['days_stale']}, method={r['freshness_method']})")
    print(f"  Stale-verdict procs marked keep:")
    for r in rows:
        if r["verdict"] != "KEEP" and r["decision"].strip().lower() in ("keep",):
            print(f"    {r['verdict']:22s} {r['ProcedureName']} -> {r['TableName']} (days_stale={r['days_stale']})")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
