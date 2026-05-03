# Review Needed: Dealing_dbo.Dealing_IndiciesIntraHour_Clients

## Items for Human Review

### 1. Instrument ID Mapping Verification

The SP hardcodes three instruments in `#IniIns`: 27, 28, 32. Based on naming and context these appear to be S&P 500, DJ30, and GER30 respectively, but this mapping should be verified against `DWH_dbo.Dim_Instrument` by a domain expert. The table name says "Indicies" (typo for "Indices") which confirms these are index instruments.

### 2. HedgeServerID NULL Semantics

HedgeServerID was added 2024-04-30 (SR-249626). Pre-2024 rows have NULL HedgeServerID. It is unclear whether NULL means "all hedge servers aggregated" or "hedge server tracking not yet implemented." Current active values observed: 5, 8, 20, 1776. Historical change log shows removal of servers 24, 25, 127 over time.

### 3. Volume Direction Convention

The volume calculation uses an inverted direction for closes: closing a buy counts as VolumeSell, closing a sell counts as VolumeBuy. This is standard market convention (closing a position requires the opposite trade), but should be confirmed with the Dealing team as the intended interpretation for reporting.

### 4. OP_Buy / OP_Sell USD Conversion

Open position values (OP_Buy, OP_Sell) use `ConversionFirst` (the LAG of USDConversionRate from PriceLog) as the USD conversion factor. This is an approximation using the prior minute's conversion rate. For index instruments denominated in USD (S&P 500, DJ30) this is trivial, but for GER30 (EUR-denominated) the conversion rate matters and may introduce small inaccuracies.

### 5. UnrealizedStart Exclusion Logic

Positions opened in the same minute are excluded from UnrealizedStart (CASE WHEN fromMinute matches → 0). This means a position opened at 14:30:00 first appears in the 14:31:00 unrealized calculation. Confirm this is intentional behavior with the report consumers.

### 6. No Jira/Confluence Search Performed

Phase 10 (Atlassian scan) was skipped in regen harness mode. The SP change history mentions SR-249626 and SR-257613 which may contain additional business context.

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | InstrumentID, HedgeServerID |
| Tier 2 | 15 | Date, Minute_Start, Minute_End, VolumeBuy, VolumeSell, OP_Buy_Units, OP_Buy, OP_Sell_Units, OP_Sell, UnrealizedStart, UnrealizedEnd, Realized, Bid, Ask, UpdateDate |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |
