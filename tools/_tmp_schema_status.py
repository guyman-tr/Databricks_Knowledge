"""Summarize per-schema in-scope counts vs already-generated wiki files."""
from __future__ import annotations
import re
import sys
from pathlib import Path

import yaml  # type: ignore

REPO = Path(__file__).resolve().parents[1]
OBJ = REPO / "knowledge" / "UC_generated"

PILOT = ["de_output", "bi_output", "bi_dealing", "etoro_kpi_prep", "etoro_kpi"]
BRONZE = [
    "general", "bi_db", "wallet", "emoney", "trading",
    "billing", "finance", "dealing", "compliance",
    "experience", "pii_data", "config",
]

def read_card(schema: str) -> list[dict]:
    card = OBJ / schema / "_schema_card.md"
    if not card.exists():
        return []
    text = card.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.+?)\n---\n", text, re.DOTALL)
    if not m:
        return []
    try:
        fm = yaml.safe_load(m.group(1)) or {}
        return fm.get("objects") or []
    except Exception:
        return []

def count_generated_mds(schema: str) -> tuple[int, int]:
    """Count wiki .md (excluding sidecar .lineage.md / .review-needed.md) in Tables/ and Views/."""
    n_tables = n_views = 0
    for folder, n in (("Tables", "n_tables"), ("Views", "n_views")):
        d = OBJ / schema / folder
        if not d.is_dir():
            continue
        for p in d.glob("*.md"):
            if p.name.endswith(".lineage.md") or p.name.endswith(".review-needed.md"):
                continue
            if folder == "Tables":
                n_tables += 1
            else:
                n_views += 1
    return n_tables, n_views

def main() -> None:
    print(f"{'kind':<8} {'schema':<22} {'objects_total':>13} {'in_scope':>9} {'generated':>10}  notes")
    print("-" * 96)
    grand_in = grand_gen = 0
    for kind, schemas in (("pilot", PILOT), ("bronze", BRONZE)):
        for sch in schemas:
            objs = read_card(sch)
            total = len(objs)
            in_scope = sum(1 for o in objs if o.get("in_scope"))
            n_t, n_v = count_generated_mds(sch)
            generated = n_t + n_v
            grand_in += in_scope
            grand_gen += generated
            note = ""
            if total == 0:
                note = "(no schema_card.md yet)"
            elif generated == 0 and in_scope > 0:
                note = "PENDING"
            elif generated > 0 and generated < in_scope:
                note = "PARTIAL"
            elif generated >= in_scope and in_scope > 0:
                note = "DONE"
            print(f"{kind:<8} {sch:<22} {total:>13} {in_scope:>9} {generated:>10}  {note}")
    print("-" * 96)
    print(f"{'TOTAL':<31} {'':>13} {grand_in:>9} {grand_gen:>10}")

if __name__ == "__main__":
    main()
