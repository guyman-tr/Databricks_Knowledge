"""Sample 15 Phase-1 proposals with full text."""
import csv
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CSV_PATH = ROOT / "audits" / "_weakness_inventory" / "phase1_auto_deploy_wiki.csv"

random.seed(7)
rows = list(csv.DictReader(CSV_PATH.open(encoding="utf-8")))
sample = random.sample(rows, 15)
for i, r in enumerate(sample, 1):
    print(f"\n[{i}] {r['schema']}.{r['table']}.{r['column']}")
    print(f"    wiki: {r['wiki_path']}")
    print(f"    proposed ({r['wiki_len']}ch r={r['wiki_rich']}):")
    text = r["proposed_comment"]
    if len(text) > 280:
        text = text[:280] + "..."
    print(f"      {text}")
