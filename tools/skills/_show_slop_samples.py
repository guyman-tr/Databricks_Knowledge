"""Show sample MISMATCH and UNKNOWN_CODEPOINT rows per column for spot-check."""
from __future__ import annotations
import csv
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
AUDIT = REPO / "knowledge" / "_codepoint_claims_audit.csv"

WATCH = ("CustomerChangeTypeID", "ActionTypeID", "PlayerLevelID", "AccountTypeID",
         "VerificationLevelID", "MoveMoneyReasonID", "DocumentStatusID", "CurrencyID")


def main() -> None:
    samples: dict[str, list[dict]] = {c: [] for c in WATCH}
    with AUDIT.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            if r["verdict"] in ("MISMATCH", "UNKNOWN_CODEPOINT") and r["column"] in samples:
                if len(samples[r["column"]]) < 4:
                    samples[r["column"]].append(r)
    for col, rows in samples.items():
        if not rows:
            continue
        print(f"=== {col} ===")
        for r in rows:
            print(f"  {r['verdict']:<18} codepoint={r['codepoint']:<4} "
                  f"claimed='{r['claimed_label'][:50]}'  "
                  f"truth='{r['tier1_truth_name'][:40]}'")
            print(f"     {r['file_relpath']}:{r['line']}")
        print()


if __name__ == "__main__":
    main()
