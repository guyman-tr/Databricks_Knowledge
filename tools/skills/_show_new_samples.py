"""Show sample mismatches for newly-resolved columns."""
from __future__ import annotations
import csv
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
AUDIT = REPO / "knowledge" / "_codepoint_claims_audit.csv"

WATCH = ("InstrumentTypeID", "TxTypeID", "ContractType", "AccountStatus",
         "CurrentTier", "EvMatchStatus", "LastWalletPoolStatus",
         "ConversionStatusID", "AuthorizationTypeID", "CardStatusID")


def main() -> None:
    samples: dict[str, list[dict]] = {c: [] for c in WATCH}
    with AUDIT.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            if r["verdict"] in ("MISMATCH", "UNKNOWN_CODEPOINT") and r["column"] in samples:
                if len(samples[r["column"]]) < 3:
                    samples[r["column"]].append(r)
    for col, rows in samples.items():
        if not rows:
            continue
        print(f"=== {col} ===")
        for r in rows:
            print(f"  {r['verdict']:<18} codepoint={r['codepoint']:<4} "
                  f"claimed='{r['claimed_label'][:50]}'  "
                  f"truth='{r['tier1_truth_name'][:40]}'")
            print(f"     dim={r['dictionary_table']}")
            print(f"     {r['file_relpath']}:{r['line']}")
        print()


if __name__ == "__main__":
    main()
