# Review Needed: BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level

**Generated**: 2026-04-23
**Pipeline Phase**: Post-11 review sidecar
**Overall Confidence**: MEDIUM-HIGH (complex SP, many components, some known bugs)

---

## Known Bugs in SP

1. **`@DateNextID` assignment bug (line 54)**: 
   ```sql
   declare @DateNextID INT = CAST(CONVERT(VARCHAR(8), @DatePrev, 112) AS INT)
   ```
   Uses `@DatePrev` instead of `@DateNext`. This means `#pnlPosNext` (which filters positions open beyond today) uses yesterday's position IDs instead of tomorrow's. **Impact**: The `OpenBeforeNotClosed` type classification for positions that are at their last day may be mis-classified. The scope of this bug is unclear — it may have minimal impact if the same positions exist in both prev and next day snapshots, but it is a known defect.

2. **`@DateNextID` used as `@DatePrevID` in temp table**: On line 54 the variable name is `@DateNextID` but the assignment formula computes the *previous* day. This means both `@DatePrevID` and `@DateNextID` contain the same value (yesterday). The second usage in `#pnlPosNext` should use tomorrow's data.

---

## Data Quality Observations

1. **RegTransferDirection=-1 rows**: These are bookkeeping rows for the OLD regulation on regulation-transfer days. They should be excluded from standard analyses (`WHERE RegTransferDirection = 1`). April 12, 2026: only 142 such rows vs 4.94M standard rows.

2. **TanganyStatus NULL vs empty**: 88.7% of rows have NULL TanganyStatus (not a Tangany customer). This is correct — NULL = no Tangany relationship.

3. **US_State empty for non-US**: US_State is set to empty string `''` for non-US customers (not NULL). Filter: `WHERE Country = 'United States' AND US_State <> ''` for state-level US analysis.

4. **Scale**: ~5M rows/day. INT overflow on COUNT(*) — total table size exceeds 2 billion rows. Avoid unfiltered SELECT * or COUNT(*) without a WHERE DateID filter.

5. **TicketFeeByPercentOnOpen precision**: decimal(38,18) can produce very small numbers displayed as "0E-18". Use `ROUND(..., 6)` for display.

---

## Open Questions

1. **`@DateNextID` bug impact**: What is the real business impact of using yesterday's positions in `#pnlPosNext`? Does this cause systematic mis-classification?

2. **CommissionVersion 1 vs 2**: When did the version change? What changed in the commission calculation between versions?

3. **SQF expansion**: Is "SQF" = "Small Quantity Fee"? What threshold defines it?

4. **C2P (CompensationReasonID=134)**: What business event triggers a C2P compensation position? Is there a business process doc?

5. **TanganyStatus "MicaCustomer"**: EU MICA regulation compliance status. Is there a regulatory tracking document for this segment?

6. **`BI_DB_Client_Balance_CID_Level_New` dependency**: The SP reads TanganyStatus and IsDLTUser from this table (which is another P20 table). Is there an execution order guarantee that CID_Level_New runs before Instrument_Level on the same day?

---

## Verification Status

| Check | Status | Notes |
|-------|--------|-------|
| DDL read from SSDT | VERIFIED | 55 cols confirmed |
| SP logic traced | VERIFIED | Full 1,626-line SP read, all temp tables and PnL components traced |
| Live data sampled | VERIFIED | ~5M rows April 12, INT overflow on total |
| InstrumentType distribution | VERIFIED | Stocks 78.5%, ETF 11.4%, Crypto 9.1% |
| Regulation distribution | VERIFIED | CySEC 59%, FCA 20%, FSA Seychelles 13% |
| RegTransferDirection | VERIFIED | 99.997% = 1, 0.003% = -1 |
| TanganyStatus | VERIFIED | 88.7% NULL, 5 non-null statuses |
| UC mapping | CHECKED | Not in generic pipeline mapping — _Not_Migrated |
| Known bugs documented | YES | @DateNextID bug flagged |
