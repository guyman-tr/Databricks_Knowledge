"""Compare Trading_* wiki §4 columns against main.etoro_kpi_prep.mv_revenue_trading."""
from __future__ import annotations
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

mv_cols = {
    "PositionID","RealCID","DateID","Occurred","Amount","Metric","ActionType",
    "IncludedInTotalRevenue","IsActiveTrade","IsSettled","MirrorID","SettlementTypeID",
    "IsSettled_Final","MirrorID_Final","SettlementTypeID_Final","IsOpenFromIBAN",
    "IsClosedToIBAN","IsCopyFund","InstrumentID","InstrumentTypeID","InstrumentType",
    "InstrumentName","Symbol","IsSQF",
}
mv_lower = {c.lower() for c in mv_cols}


def wiki_cols(path: Path) -> list[str]:
    txt = path.read_text(encoding="utf-8")
    m4 = re.search(r"## 4\. Output Columns\s*\n(.*?)(?=\n## |\Z)", txt, re.DOTALL)
    if not m4:
        return []
    out = []
    for line in m4.group(1).splitlines():
        line = line.strip()
        if not line.startswith("|") or line.startswith("|---") or "# |" in line:
            continue
        parts = [p.strip() for p in line.split("|")]
        if len(parts) < 6:
            continue
        c = parts[2].strip().strip("*").strip("`")
        if c and c.lower() != "column":
            out.append(c)
    return out


candidates = [
    "knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_Trading_Fees_Breakdown.md",
    "knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_Trading_Instrument_Level.md",
]

for w in candidates:
    p = ROOT / w
    cols = wiki_cols(p)
    lower = {c.lower() for c in cols}
    overlap = lower & mv_lower
    extra_wiki = lower - mv_lower
    missing_in_wiki = mv_lower - lower
    name = p.stem
    print(f"{name}: {len(cols)} cols  |  overlap={len(overlap)}/{len(mv_lower)}")
    print(f"  unique to wiki  ({len(extra_wiki)}): {sorted(extra_wiki)[:10]}")
    print(f"  missing from wiki ({len(missing_in_wiki)}): {sorted(missing_in_wiki)[:10]}")
    print()
