# BI_DB_First5Actions — Review Notes

**Generated**: 2026-04-22 | **Batch**: 23 | **Priority**: 0

---

## Tier 4 Items (Low Confidence — Needs Verification)

None. All 86 columns have confirmed sourcing from SP code analysis or direct upstream wiki inheritance.

---

## Open Questions for Reviewers

1. **LTV column disabled (column #34)**: LTV = 0 for all 46.3M rows (hardcoded since 2022-06-02). The DDL still has `LTV float NULL`. Is there a plan to repopulate this column, or should it be removed from the DDL entirely? Any downstream consumers still referencing it?

2. **Revenue360days vs Revenue365days naming mismatch**: SP sources `Revenue365days` from BI_DB_CID_BalanceDays but writes to `Revenue360days` in this table (similarly for Deposit360days and Equity360days). This is a 5-day discrepancy in the window definition. Is this intentional (legacy naming) or a defect? The column name says "360" but actually represents 365-day revenue.

3. **88.3% NULL FirstAction**: The vast majority of depositors never opened a position. Is this table primarily used for the 11.7% who did trade, or is it also used for null-action customers (e.g., to flag them for activation campaigns)? Understanding the primary use case helps determine whether the NULL population matters for derived tables.

4. **BI_DB_CustomerCross vs BI_DB_CustomerCross_New coexistence**: Both legacy and new cross sequences are maintained. Do any dashboards still use the legacy columns (FirstCross..FifthCross), or is all new development using the New suffix columns? If legacy columns are unused, are there plans to deprecate them?

5. **1900-01-01 sentinel**: The CIDFirstDates filter is `WHERE FirstDepositDate IS NOT NULL`, but BI_DB_CIDFirstDates may contain rows with 1900-01-01 as the "no deposit" sentinel (which IS NOT NULL). Are there rows in this table with FirstDepositDate = 1900-01-01? (min_ftd_date = 1900-01-01 observed in live data → some sentinel rows are present.)

6. **TRUNCATE on full refresh**: The SP uses TRUNCATE + INSERT (no date partitioning). On 46.3M rows this is a heavy operation. Is this run daily? Are there documented SLA windows for when it must complete? Any downstream jobs that have hard dependencies on its completion time?

---

## Data Quality Observations

- **1900-01-01 FirstDepositDate**: 1900-01-01 sentinel rows are present (min observed in live data). The WHERE clause in SP_First5Actions is `WHERE FirstDepositDate IS NOT NULL`, not `WHERE YEAR(FirstDepositDate) != 1900`. Consumers should add `AND YEAR(FirstDepositDate) != 1900` for FTD cohort analysis.
- **Revenue30days range**: min=-$15,567 (customer generated a loss, i.e. company paid out), max=$1.54M. Negative values are valid — they represent net revenue to eToro, which can be negative if customer unrealized gains exceed commissions.
- **max FTD amount = $10,000,000**: Same upper bound observed in BI_DB_DepositSnapshots. Likely a high-net-worth client.
- **HASH(CID) + CLUSTERED INDEX(FirstDepositDate)**: Distribution is CID-optimal, but the clustered index is on FirstDepositDate. Date-range scans on this table will touch all distributions. For cohort queries filtering on FirstDepositDate ranges, this is less efficient than a hash on FirstDepositDate.

---

## Cross-Object Consistency Checks

- **CID description**: Copied verbatim from DWH_dbo.Dim_Customer wiki (Tier 1 — Customer.CustomerStatic) ✓
- **AffiliateID description**: Copied verbatim from DWH_dbo.Dim_Customer wiki (Tier 1 — Customer.CustomerStatic) ✓
