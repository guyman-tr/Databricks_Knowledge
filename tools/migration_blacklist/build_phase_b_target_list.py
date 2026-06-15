"""Generate the bare-name target list of surviving output tables for Phase B
Tableau sweep.

Inputs:
  - audits/blacklist/migration_blacklist_phase_a3_2026-05-31.csv

Output:
  - audits/blacklist/_b_work/keep_tables.txt           (bare table names, one per line)
  - audits/blacklist/_b_work/keep_tables_fqn.csv       (with schema for traceability)
"""

from __future__ import annotations

import csv
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
A3_CSV  = REPO_ROOT / "audits" / "blacklist" / "migration_blacklist_phase_a3_2026-05-31.csv"
B_DIR   = REPO_ROOT / "audits" / "blacklist" / "_b_work"
OUT_TXT = B_DIR / "keep_tables.txt"
OUT_FQN = B_DIR / "keep_tables_fqn.csv"


def main() -> int:
    bare_to_fqn: dict[str, set[str]] = {}
    with A3_CSV.open("r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            if (row.get("decision") or "").strip().lower() == "blacklist":
                continue
            t = row["TableName"].strip()
            if not t or "." not in t:
                continue
            schema, bare = t.split(".", 1)
            schema = schema.strip("[]")
            bare = bare.strip("[]")
            bare_to_fqn.setdefault(bare, set()).add(f"{schema}.{bare}")

    B_DIR.mkdir(parents=True, exist_ok=True)
    bare_sorted = sorted(bare_to_fqn)
    OUT_TXT.write_text("\n".join(bare_sorted) + "\n", encoding="utf-8")
    with OUT_FQN.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["bare_table", "fqn_list"])
        for bare in bare_sorted:
            w.writerow([bare, ";".join(sorted(bare_to_fqn[bare]))])

    print(f"[b1] surviving unique bare tables: {len(bare_sorted)}")
    print(f"[b1] wrote {OUT_TXT}")
    print(f"[b1] wrote {OUT_FQN}")
    dupes = {b: list(s) for b, s in bare_to_fqn.items() if len(s) > 1}
    if dupes:
        print(f"[b1] WARN: {len(dupes)} bare names have >1 schema (will be probed once each):")
        for b, fqns in list(dupes.items())[:5]:
            print(f"        {b} -> {fqns}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
