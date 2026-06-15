"""Slice the convergence audit down to the COMPRESSION_LOSS signal,
which is the cleanest 'free-win' bucket — upstream §4 had an explicit
predicate that the deployed comment dropped.
"""
from __future__ import annotations
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "audits" / "_convergence_gap" / "convergence_candidates.csv"
DST = ROOT / "audits" / "_convergence_gap" / "compression_loss_only.csv"


def main() -> int:
    rows = list(csv.DictReader(SRC.open(encoding="utf-8")))
    only_loss = [r for r in rows if "COMPRESSION_LOSS" in r["signals"]]
    only_loss.sort(key=lambda r: r["signals"])
    with DST.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=rows[0].keys())
        w.writeheader()
        w.writerows(only_loss)
    print(f"Total convergence candidates : {len(rows)}")
    print(f"COMPRESSION_LOSS only        : {len(only_loss)}")
    print(f"Output                       : {DST.relative_to(ROOT)}")
    print()
    print("Sample (first 20):")
    for r in only_loss[:20]:
        # Pull out just the COMPRESSION_LOSS fragment
        sig = r["signals"]
        cl = sig.split("COMPRESSION_LOSS:")[1].split("||")[0].strip() if "COMPRESSION_LOSS:" in sig else ""
        print(f"  {r['uc_fqn'].split('.')[-1]:32s}  {r['column']:28s}  ->  lost: {cl[:90]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
