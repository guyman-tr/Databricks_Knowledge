# Review Needed: BI_DB_dbo.BI_DB_FCA_Liabilities

Generated: 2026-04-22 | Batch 25 #1

## Tier 4 Items (Needs SME Verification)

None — all column descriptions are Tier 1 or Tier 2.

## Questions for Business SME

1. **Liabilities unit**: The `Liabilities` and `LiabilitiesCryptoReal` columns are `bigint` and show values in the billions (e.g., 4,670,385,723). Are these values in USD cents, pence, or full USD? The V_Liabilities wiki does not specify the currency unit explicitly.

2. **Regulation filter**: The SP hard-filters to `DWHRegulationID = 2` (FCA). Is there a separate table for CySEC/ASIC liabilities, or is this FCA-only by design for regulatory reporting purposes?

3. **IsValidCustomer = IsCreditReportValidCB always**: In all 66 months of data, these two flags always have the same value (both 0 or both 1). Is this a business rule or a data quality observation? If it's always true, one of them is redundant as a GROUP BY dimension.

4. **No downstream consumers**: No downstream SP dependencies found in OpsDB for this table. Confirm it is consumed directly by reporting processes (Power BI / FCA report export) rather than other SPs.

## Data Quality Observations

- **Liabilities filter**: `WHERE vl.Liabilities <> 0` — customers with zero liabilities are excluded from the count. `Total_CIDs` therefore undercounts the full FCA customer universe.
- **Current month**: For April 2026, `Date = 2026-04-12` while `EOM = 2026-04-30` — the current month's row updates daily and does not represent the final monthly figure until the last day of the month.

## Reviewer Sign-Off

- [ ] Liabilities unit confirmed (USD / pence / cents)
- [ ] FCA-only scope confirmed (no other regulation needed)
- [ ] IsValidCustomer/IsCreditReportValidCB correlation confirmed
- [ ] Downstream consumers confirmed
