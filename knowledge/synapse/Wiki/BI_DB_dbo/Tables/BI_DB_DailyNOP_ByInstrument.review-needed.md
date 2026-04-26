# BI_DB_dbo.BI_DB_DailyNOP_ByInstrument — Review Needed

## Tier 2 Items

- **HedgeServer** (Tier 2): HedgeServerID from BI_DB_PositionPnL. No Dim_HedgeServer dimension found. What do the 41 distinct HedgeServer values represent? Are they trading venue IDs, broker IDs, or internal routing identifiers?
- **NOP** (Tier 2): Confirmed as SUM of BI_DB_PositionPnL.NOP per instrument/hedge server. What are the units? Is this in shares, contracts, lots, or dollar-equivalent?
- **LastPrice** (Tier 2): BidLast from SpreadedPriceCandle60MinSplitted. Many recent rows show LastPrice = 0. Is this a data freshness issue (candle not yet available for new instruments) or a genuine data quality problem?

## Open Questions

1. What downstream dashboards consume this table? No SSDT reader SPs found — likely consumed by reporting tools directly.
2. The SP uses `WITH(NOLOCK)` on BI_DB_PositionPnL join — is this safe given Synapse snapshot isolation?
3. NOP range is extremely wide (-65.1M to 1.67B). Are these units consistent across instrument types, or does NOP mean different things for stocks vs forex vs crypto?
4. HedgeServer 0 is used as a default for price-only instruments (ISNULL). Is this value used in downstream aggregation? Should it be excluded?

## Cross-Object Consistency

- InstrumentID description copied verbatim from DWH_dbo.Dim_Instrument wiki (Tier 1) ✓
- InstrumentType values match Dim_Instrument CASE mapping (Tier 1) ✓
