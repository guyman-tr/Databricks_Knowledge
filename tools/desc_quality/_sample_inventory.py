"""Sample inventory rows for human spot-check before any auto-deploy.

For each high-confidence bucket, print a stratified sample (different schemas,
different action types, varying lengths) so the user can verify whether the
proposed source actually deserves to be auto-pushed."""
import csv
import random
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INV = ROOT / "audits" / "_weakness_inventory" / "inventory_master.csv"

random.seed(42)


def truncate(s, n):
    s = s or ""
    return (s[:n] + "...") if len(s) > n else s


def main():
    rows_by_bucket: dict[str, list[dict]] = defaultdict(list)
    with INV.open(encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            rows_by_bucket[r["bucket"]].append(r)

    for bucket in ("EMPTY_HAS_WIKI", "WEAK_TRIVIAL_HAS_RICHER"):
        print("=" * 110)
        print(f"BUCKET: {bucket}   total={len(rows_by_bucket[bucket])}")
        print("=" * 110)

        # Stratify by (schema, action) so we see multiple flavours
        by_strata: dict[tuple, list[dict]] = defaultdict(list)
        for r in rows_by_bucket[bucket]:
            by_strata[(r["schema"], r["action"])].append(r)

        # Print top 10 strata by count + 1 random row each
        ordered = sorted(by_strata.items(), key=lambda kv: -len(kv[1]))
        for (sch, action), rs in ordered[:8]:
            print(f"\n  --- {sch} / {action}  ({len(rs)} rows) ---")
            for r in random.sample(rs, min(2, len(rs))):
                print(f"    {r['table']}.{r['column']}")
                if r["current_comment"]:
                    print(f"      CUR (len={r['current_len']}): {truncate(r['current_comment'], 220)}")
                else:
                    print(f"      CUR: <empty>")
                if r["wiki_cell"]:
                    print(f"      WIKI ({r['wiki_path']} len={r['wiki_len']} r={r['wiki_rich']}):")
                    print(f"        {truncate(r['wiki_cell'], 280)}")
                if r["best_sibling_cell"]:
                    print(f"      SIB  ({r['best_sibling_path']} len={r['best_sibling_len']} r={r['best_sibling_rich']}):")
                    print(f"        {truncate(r['best_sibling_cell'], 280)}")
                print(f"      reason: {r['reason']}")
        print()


if __name__ == "__main__":
    main()
