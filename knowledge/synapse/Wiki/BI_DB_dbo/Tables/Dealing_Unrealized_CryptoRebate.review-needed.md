# Review Needed: BI_DB_dbo.Dealing_Unrealized_CryptoRebate

**Batch**: 58 | **Object**: #1 | **Date**: 2026-04-23
**Confidence**: High (SP code read in full; live data sampled)

---

## Items Requiring Business Validation

### 1. GuruStatus_ID — Always 0 (Confirm by Design)
Every row in the table has `GuruStatus_ID = 0`. This is an expected artifact of the eligibility filter (`GuruStatusID NOT IN (2,3,4,5,6)` excludes all PopularInvestors, leaving only standard Diamond/Platinum Plus members who have GuruStatus=0). Documented as such, but a business owner should confirm this is intentional and the column is retained for reporting schema consistency rather than analytical value.

### 2. IsCreditReportValidCB and IsGermanBaFin — Present in Unrealized Only
These two columns appear in `Dealing_Unrealized_CryptoRebate` but NOT in the realized companion `Dealing_CryptoRebate`. The SP code confirms this asymmetry. A business owner should confirm whether this is intentional (regulatory dimensions were added only to the unrealized report) or an omission in the realized table.

### 3. TotalVolume Double-Counting
`TotalVolume = OpenedVolume + ClosedVolume` sums two valuations of the same open positions (at-open rate + EOM mark-to-market). This is intentional in the bracket calculation design. Business users consuming TotalVolume for aggregate reporting should be aware it is not a net position value or a standard turnover figure.

### 4. OpenDateID >= 20220308 Gate
Positions opened before 2022-03-08 are excluded from the unrealized rebate calculation. This inception gate was added at program launch. If older open positions exist in `BI_DB_PositionPnL` for club members (positions held since before that date), they are silently excluded. A business owner should confirm whether this is still the correct cutoff or whether it should be reviewed.

### 5. $5 Minimum Threshold — Impact
70.3% of rows have TotalRebate = 0 due to the $5 minimum threshold combined with the $50K volume floor. The threshold is embedded in the SP (`CASE WHEN sum < 5 THEN 0 ELSE sum`). This is documented but should be confirmed as still the operative business rule.

---

## Tier Coverage Summary

| Tier | Count | Source |
|------|-------|--------|
| Tier 1 | 1 | CID from Customer.CustomerStatic upstream wiki (verbatim) |
| Tier 2 | 19 | SP code + Fact_SnapshotCustomer join chain |
| Propagation | 1 | UPdatedate (GETDATE() on insert) |

No Tier 3 or Tier 4 assignments — full SP code was available.

---

## Cross-Object Consistency
Column descriptions for shared columns (CID, Club, Country, Region, Regulation, GuruStatus_ID, bracket volume/rebate columns) are consistent with `Dealing_CryptoRebate.md`.
