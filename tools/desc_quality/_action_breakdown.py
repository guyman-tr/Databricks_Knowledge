"""Action-level breakdown: how many EMPTY_HAS_WIKI rows are direct wiki §4
matches vs sibling-fallback? Direct matches are high-confidence; sibling
matches are dangerous on generic column names."""
import csv
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INV = ROOT / "audits" / "_weakness_inventory" / "inventory_master.csv"

bucket_action: dict[tuple, int] = defaultdict(int)
bucket_action_schema: dict[tuple, int] = defaultdict(int)
column_freq: dict[str, int] = defaultdict(int)

with INV.open(encoding="utf-8") as fh:
    rows = list(csv.DictReader(fh))

for r in rows:
    bucket_action[(r["bucket"], r["action"])] += 1
    bucket_action_schema[(r["bucket"], r["action"], r["schema"])] += 1
    column_freq[r["column"].lower()] += 1

print("=" * 90)
print(f"{'Bucket':<28}{'Action':<26}{'Count':>10}")
print("-" * 90)
for (b, a), c in sorted(bucket_action.items(), key=lambda kv: -kv[1]):
    print(f"{b:<28}{a:<26}{c:>10}")
print()

# Risk surface: how often does the same column name appear across the corpus?
# (high-frequency = generic = sibling fallback risky)
print("Top 15 most-collided column names (sibling-fallback risk indicator):")
for col, n in sorted(column_freq.items(), key=lambda kv: -kv[1])[:15]:
    print(f"  {n:5d}  {col}")
print()

# How many EMPTY_HAS_WIKI auto_deploy_sibling rows hit a "common" column name?
RISKY_THRESHOLD = 50  # if column appears in 50+ rows it's almost certainly generic
risky_count = 0
safe_count = 0
for r in rows:
    if r["bucket"] != "EMPTY_HAS_WIKI" or r["action"] != "auto_deploy_sibling":
        continue
    if column_freq[r["column"].lower()] >= RISKY_THRESHOLD:
        risky_count += 1
    else:
        safe_count += 1
print(f"EMPTY_HAS_WIKI / auto_deploy_sibling:")
print(f"  generic-name (>= {RISKY_THRESHOLD} occurrences corpus-wide): {risky_count} rows  <- RISKY")
print(f"  rare/canonical name (< {RISKY_THRESHOLD}):                    {safe_count} rows  <- safer")
