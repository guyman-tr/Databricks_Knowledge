"""For each empty UC column, check whether the matching wiki §4 has a row for it."""
from __future__ import annotations
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))


EMPTIES = [
    ("v_mimo_optionsplatform",            "Date",                   None),
    ("v_mimo_optionsplatform",            "IsGlobalFTD",            None),
    ("v_population_balance_only_accounts","MaxAnyEquity",           "Function_Population_Balance_Only_Accounts"),
    ("v_population_otd_daterange",        "FromDateID",             "Function_Population_OTD_DateRange"),
    ("v_population_otd_daterange",        "ToDateID",               "Function_Population_OTD_DateRange"),
    ("v_revenue_optionsplatform",         "IsRecurring",            "Function_Revenue_OptionsPlatform"),
    ("v_trading_volume_and_amount",       "TotalVolume",            "Function_Trading_Volume"),
    ("v_trading_volume_and_amount",       "NetInvestedAmount",      "Function_Trading_Volume"),
    ("v_trading_volume_and_amount",       "CountTotalTransactions", "Function_Trading_Volume"),
    ("v_trading_volume_and_amount",       "IsC2P",                  "Function_Trading_Volume"),
    ("v_trading_volume_and_amount",       "IsRecurring",            "Function_Trading_Volume"),
]


def parse_wiki_cols(wiki_path: Path) -> dict[str, str]:
    """Return {col_lower: description} from §4 Output Columns."""
    txt = wiki_path.read_text(encoding="utf-8")
    m4 = re.search(r"## 4\. Output Columns\s*\n(.*?)(?=\n## |\Z)", txt, re.DOTALL)
    if not m4:
        return {}
    out: dict[str, str] = {}
    for line in m4.group(1).splitlines():
        line = line.strip()
        if not line.startswith("|") or line.startswith("|---") or "# |" in line:
            continue
        parts = [p.strip() for p in line.split("|")]
        if len(parts) < 6:
            continue
        col = parts[2].strip().strip("*").strip("`")
        if not col or col.lower() == "column":
            continue
        out[col.lower()] = (parts[3] + " | " + parts[4])[:120]
    return out


def find_wiki(name: str | None) -> Path | None:
    if not name:
        return None
    for p in ROOT.glob(f"knowledge/synapse/Wiki/BI_DB_dbo/Functions/{name}.md"):
        return p
    return None


def main() -> int:
    wiki_cache: dict[str, dict[str, str]] = {}
    for uc_view, uc_col, wiki_name in EMPTIES:
        if wiki_name is None:
            print(f"  {uc_view:38s} {uc_col:22s} -> NO WIKI MAPPED")
            continue
        wp = find_wiki(wiki_name)
        if not wp:
            print(f"  {uc_view:38s} {uc_col:22s} -> WIKI NOT FOUND: {wiki_name}")
            continue
        if wiki_name not in wiki_cache:
            wiki_cache[wiki_name] = parse_wiki_cols(wp)
        cols = wiki_cache[wiki_name]
        if uc_col.lower() in cols:
            print(f"  {uc_view:38s} {uc_col:22s} -> WIKI HAS: {cols[uc_col.lower()][:80]}")
        else:
            similar = [k for k in cols if k.startswith(uc_col.lower()[:3])]
            print(f"  {uc_view:38s} {uc_col:22s} -> WIKI MISSING (similar names: {similar[:3]})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
