"""Verify rewritten wiki §4 still parses cleanly via the deploy script's own parser.
Also flags any cells the deploy script would silently truncate or rewrite."""
from __future__ import annotations
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

from apply_tvf_col_comments import parse_wiki_cols  # noqa: E402

TVFs = [
    "Function_Revenue_CashoutFee_ExcludeRedeem",
    "Function_Revenue_Commissions",
    "Function_PnL_Single_Day",
    "Function_Instrument_Snapshot_Enriched",
    "Function_MIMO_First_Deposit_All_Platforms",
    "Function_Revenue_AdminFee",
    "Function_Revenue_StakingFee",
    "Function_Revenue_TransferCoinFee",
]

for tvf in TVFs:
    cols = parse_wiki_cols(tvf)
    print(f"{tvf}: {len(cols)} columns parsed")
    if cols:
        first = next(iter(cols.items()))
        text = first[1]
        suffix = "..." if len(text) > 140 else ""
        print(f"  first  : {first[0]!r} -> {text[:140]!r}{suffix}")
        long_cells = [(k, len(v)) for k, v in cols.items() if len(v) > 480]
        if long_cells:
            print(f"  near-limit (>480 chars): {len(long_cells)}")
            for k, L in long_cells[:3]:
                print(f"    {k}: {L} chars")
    print()
