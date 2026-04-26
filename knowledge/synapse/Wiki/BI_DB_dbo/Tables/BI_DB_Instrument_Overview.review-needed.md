# BI_DB_dbo.BI_DB_Instrument_Overview — Review Needed

## Tier 4 Items

None — no Tier 4 descriptions in this wiki.

## Review Questions

1. **Watchlist JOIN via Revenue table**: The SP joins #watchlist to #revenue (ON r.InstrumentID = w.InstrumentID) rather than directly to #instruments. This means instruments with zero revenue also have NULL watchlist data, even if they had watchlist activity. Is this intentional?

2. **DWH_watchlists schema**: The SP reads from `DWH_watchlists.Fact_WatchlistsItems` which is not in the standard DWH_dbo schema. Confirm this is the correct cross-schema reference.

3. **Tradable column type mismatch**: Dim_Instrument stores Tradable as int, but this DDL has varchar(100). The SP passes it through without explicit CAST — verify no data loss.

4. **Column name typo**: "Whatchlist" in column names (NewAddedToWhatchlist, DeletedManualFromWatchList) — preserved from original DDL. Consider whether this should be corrected in a future DDL change.

## Reviewer Corrections

None yet.
