# Review Notes — BI_DB_dbo.BI_DB_CMR_Phase2_Finra_NonCash_Comps

**Batch**: 60 | **Date**: 2026-04-23 | **Status**: Ready for SME review

## Items for SME Review

1. **CompensationReasonID set**: The SP filters to 27 specific CompensationReasonIDs (45, 60, 62–72, 75–76, 78–79, 81–89, 92). Confirm: (a) Are there other Apex corporate action reason IDs that should be included but are not? (b) Are there any IDs in this set that no longer apply?

2. **RegulationID = 8**: The join to Fact_SnapshotCustomer uses `RegulationID = 8` to scope to FINRA customers. Confirm that RegulationID=8 maps exclusively to FinCEN+FINRA and has not been reassigned.

3. **Amount sign convention**: Confirm whether positive `Amount` values represent debits (money taken from Apex to fund compensation) or credits (money added to customer balance). Corporate action signs can vary by event type (e.g. dividends = positive/credit; fees = negative/debit).

4. **DateID vs Date discrepancy risk**: The SP stores both `DateID` (from Fact_CustomerAction.DateID) and `Date` (CAST(Occurred AS DATE)). For events near midnight, these could differ. Confirm whether this edge case has been observed and whether DateID or Date should be used as the authoritative date key.

5. **'Promotion' reason**: CompensationReason = 'Promotion' is present in live data. Confirm whether Promotion events (non-Apex corporate actions) are intentionally included in FINRA non-cash comps, or whether they should be filtered out.
