# BI_DB_Daily_TradeData — Review Notes

**Generated**: 2026-04-22 | **Batch**: 23 | **Priority**: 20

---

## Tier 4 Items (Low Confidence — Needs Verification)

None. All 13 columns have confirmed sourcing from SP code analysis.

---

## Open Questions for Reviewers

1. **SP description "Bla"**: The SP header says `Description: Bla` — no meaningful business context from the author. Is there a more specific business purpose for this table beyond instrument-level trade activity tracking? Is it used in any specific dashboard/report by name?

2. **IsDepositor asymmetry**: The "Open" branch requires `IsDepositor=1` but the "EOD" branch (via BI_DB_PositionPnL) does NOT. Is this intentional? Could UsersHold include demo-to-real account holders who opened positions before depositing?

3. **ROUND_ROBIN distribution**: With 409.6M rows and daily query patterns, ROUND_ROBIN means all DateID-filtered queries involve a broadcast or shuffle. Has any hash distribution (e.g., HASH(DateID) or HASH(InstrumentID)) been considered?

4. **NULL InstrumentType (~2% rows)**: These represent price-feed instruments not in Dim_Instrument. Are these intentionally included (to capture all price-feed instruments) or is this a data quality gap? Filtering `WHERE InstrumentType IS NOT NULL` excludes them from type-level aggregations.

5. **SP_Stocks_Opportunities relationship**: This SP reads from BI_DB_Daily_TradeData and BI_DB_First5Actions. What business question does it answer? Not documented in the wiki currently.

---

## Data Quality Observations

- **SP description placeholder**: SP header "Description: Bla" suggests incomplete documentation at source code level.
- **MirrorID=0 filter**: Mirror/copy positions are excluded from both branches. This table is manual-trading only.
- **EOD_Price = MAX(Bid)**: Not a true market closing price — it's the highest observed bid in the intraday feed. May differ from official market close.
- **OpenedPositions = 0 dominates** (91.7% of YTD rows): By design — price-feed-driven grain includes all instruments. Consumers should filter `WHERE OpenedPositions > 0` when interested in active instruments only.

---

## Cross-Object Consistency Checks

- **InstrumentID description**: Copied verbatim from DWH_dbo.Dim_Instrument wiki (Tier 1 — Trade.Instrument) ✓
- **Country description**: Copied verbatim from DWH_dbo.Dim_Country wiki (Tier 1 — Dictionary.Country) ✓
- **Region description**: Copied verbatim from DWH_dbo.Dim_Country.Region wiki entry (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse) ✓
