# Review Needed: BI_DB_dbo.Dealing_CryptoRebate

## Items Requiring Human Verification

### HIGH Priority

1. **France exclusion discrepancy** — The SP change log (2025-10-20, Ofir Chloe Gal) says "Adding France country" but the actual WHERE clause does NOT include France in the exclusion list (`dc.Name NOT IN ('Austria', 'Finland', 'Greece', 'Luxembourg', 'Malta', 'Portugal', 'Sweden', 'United Kingdom')`). Confirm with Ofir Chloe Gal whether France exclusion was: (a) added in a different version, (b) applied via another mechanism (V_GermanBaFin or country logic), or (c) reverted after deployment.

2. **TotalVolume double-counting is intentional** — The wiki documents that TotalVolume = OpenedVolume + ClosedVolume (open + close notional values of the same position). This is unusual but consistent with the SP code. Confirm with Tom Boksenbojm or the Dealing team that this is the defined business metric and not a calculation error.

3. **Club prefix '1'** — The Club column contains '1 Diamond' and '1 Platinum Plus'. Is the '1' prefix a business convention or a CASE statement artifact? Is there a defined sort/rank meaning, or should this be cleaned up to just 'Diamond' / 'Platinum Plus' in reporting?

### MEDIUM Priority

4. **GuruStatusID exclusion values** — GuruStatusID NOT IN (2,3,4,5,6) is the filter. Confirm what each excluded status means (is 2=Popular Investor, 3=Champion, etc.?) — the dictionary should be checked in `DWH_dbo.Dim_GuruStatus` or equivalent.

5. **IsDiscounted=0 filter** — What does IsDiscounted represent? The wiki excludes discounted positions from volume. Confirm whether discounted positions are excluded because the spread/markup does not apply to them.

6. **OpenDateID >= 20220308 hardcoded** — The rebate plan start date is hardcoded as 20220308 in the SP. Confirm this is the definitive rebate plan launch date and whether it should be a configurable parameter.

7. **Realized vs. unrealized rows per month** — The unrealized table (786K rows) is ~3.7x larger than the realized table (210K rows). The unrealized table tracks all open positions at each month-end, while the realized table tracks positions closed within the month. This ratio makes business sense but should be confirmed with the dealing team.

### LOW Priority

8. **float type for all volume/rebate columns** — Using `float` rather than `decimal` for financial calculations can introduce floating-point rounding. Confirm whether this is intentional or should be migrated to decimal for precision-sensitive rebate payments.

9. **GuruStatus_ID vs GuruStatusID** — Column name `GuruStatus_ID` (with underscore) in the table vs `GuruStatusID` (no underscore) in OpsDB/Dim tables. Confirm this is a naming inconsistency in the DDL and not a different concept.

## Data Quality Observations

- Most Platinum Plus clients (91%) have TotalRebate=0 — they fall below the $50,000 minimum threshold or below the $5 minimum rebate. This is expected for the lower-volume tier.
- Diamond members have higher average volume ($90K vs $19K) and a higher rebate-receipt rate (27% vs 9%).
- The table spans 49 months (2022-03-31 to 2026-03-31), suggesting some months have multiple inserts (re-runs) or the DELETE-INSERT pattern preserves history.
