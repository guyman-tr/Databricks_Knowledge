# Review Needed: EXW_Wallet.ETL_InstrumentRates_ByHour

## Summary

All 7 columns documented at Tier 2 — grounded in SP code and DDL. No upstream wiki was available (`_no_upstream_found.txt` present). Zero Tier 4 columns.

## Open Questions

1. **Production origin of `EXW_Currency.vInstrumentRatesForWeek`**: This staging table has no upstream wiki. It appears to be a Synapse-internal staging table loaded via a generic pipeline from an external currency rate feed. The ultimate production source (e.g., a market data provider API, internal rate engine) could not be determined from the SSDT repo.

2. **InstrumentID mapping**: `InstrumentID` maps to `EXW_Currency.Instruments.Id`. No wiki exists for `EXW_Currency.Instruments`. A reviewer should confirm whether this aligns with the eToro platform `Dictionary.Instrument` or is a separate eXw-specific instrument registry.

3. **Refresh orchestration**: `SP_ETL_InstrumentRates_ByHour` is not called by any parent orchestration SP found in the SSDT repo. It may be scheduled directly via ADF or another orchestration layer. A reviewer should confirm the scheduling mechanism and frequency.

4. **Date boundary CASE logic**: The SP has a CASE expression that handles rates spanning midnight boundaries by assigning them to the target date. A 2026-04-13 update by Inessa adjusted the GROUP BY to match the CASE conditions to fix duplicates. Reviewers should verify this fix resolved the issue.

## Tier Breakdown

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 7 | InstrumentID, AskRateAvg, BidRateAvg, DateHour, Date, DateID, UpdateDate |
| Tier 1 | 0 | — |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
