"""For each Function_PnL_Single_Day exhausted column, search the wiki corpus
for any wiki whose §4 has that column.
"""
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.desc_quality.upstream_climber import (  # noqa: E402
    _parse_wiki_cached,
    _section3_candidates,
    resolve_wiki,
)
from tools.desc_quality.wiki_parse import parse_wiki  # noqa: E402

wiki = os.path.abspath(
    "knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_PnL_Single_Day.md"
)

print(f"Function_PnL_Single_Day §3 candidates and which have ClosedOnDate / IsMarginTrade / IsCopyFund:")
for cand in _section3_candidates(wiki):
    p = resolve_wiki(cand)
    if not p:
        print(f"  {cand:55s} NO WIKI")
        continue
    tbl = _parse_wiki_cached(str(p))
    cols = {r.column.lower() for r in tbl.rows if r.column}
    flags = []
    for needle in ["closedondate", "ismargintrade", "iscopyfund"]:
        flags.append(("Y" if needle in cols else "-"))
    print(f"  {cand:55s} rows={len(tbl.rows):4d}  ClosedOnDate={flags[0]}  IsMarginTrade={flags[1]}  IsCopyFund={flags[2]}")

print()
print("Corpus-wide search for these columns (any wiki, not just §3):")
roots = [Path("knowledge/synapse/Wiki")]
needles = ["closedondate", "ismargintrade", "iscopyfund"]
hits: dict[str, list[tuple[str, str]]] = {n: [] for n in needles}
for root in roots:
    for p in root.rglob("*.md"):
        try:
            tbl = parse_wiki(p)
        except Exception:
            continue
        for r in tbl.rows:
            lc = r.column.lower()
            if lc in needles and r.semantic_cell.strip():
                hits[lc].append((str(p).replace("\\", "/"), r.semantic_cell[:120]))
                if len(hits[lc]) >= 5:
                    break
for n in needles:
    print()
    print(f"  Column '{n}':")
    if not hits[n]:
        print("    (no matches anywhere in corpus)")
        continue
    for wp, cell in hits[n][:5]:
        wikiname = wp.split("/")[-1]
        print(f"    {wikiname:55s} -> {cell}")
