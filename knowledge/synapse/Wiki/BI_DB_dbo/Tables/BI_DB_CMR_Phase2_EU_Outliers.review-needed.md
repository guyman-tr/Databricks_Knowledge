# Review Needed: BI_DB_dbo.BI_DB_CMR_Phase2_EU_Outliers

**Batch**: 58 | **Object**: #4 | **Date**: 2026-04-23
**Confidence**: High (SP code read in full; live data sampled)

---

## Items Requiring Business Validation

### 1. Duplicate ExcelOrder 13 (SP Defect)
The SP assigns ExcelOrder = 13 to both 'Over The Weekend Fee' (line 227) and 'Lost Debt' (line 227). This produces 21 rows per date instead of 20. The duplicate ExcelOrder makes it impossible to uniquely identify rows by ExcelOrder alone -- the Metric column must be used. Business owner should confirm whether this is known and whether there are downstream consumers that rely on ExcelOrder = 13 for one specific metric.

### 2. EU Scope Implicit (No Regulation Filter in SP)
Despite the table name BI_DB_CMR_Phase2_EU_Outliers, the SP reads from BI_DB_Outliers_New without an explicit Regulation filter. The EU scope is assumed to come from how BI_DB_Outliers_New is populated. Business owner should confirm that BI_DB_Outliers_New only contains EU customers, or whether a regulation filter was inadvertently omitted.

### 3. All Zeros on Latest Available Date (2026-04-07)
The most recently loaded date (2026-04-07) shows all-zero values for both ValidToInvalid and InvalidToValid. The SP inserts rows regardless of zero values. Confirm whether this is expected (no outlier transitions on that date) or indicates a loading issue.

### 4. Zero Rows Always Inserted
The SP inserts 21 rows per date even when all metric values are zero (confirmed: latest date 2026-04-07). This inflates the table size significantly. Business owner should confirm whether this behavior is intentional for reporting completeness or if filtering out all-zero dates is preferred.

### 5. Transition Case Sensitivity
The SP filters: `Transition = 'Valid To Invalid'` (capital T, capital I) and `Transition = 'Invalid to Valid'` (capital I, lowercase t). If BI_DB_Outliers_New stores Transition values with different casing in future loads, values would silently fall to 0. Confirm case-consistency of the source table.

---

## Tier Coverage Summary

| Tier | Count | Source |
|------|-------|--------|
| Tier 2 | 6 | All data columns from BI_DB_Outliers_New or hardcoded SP strings |
| Propagation | 1 | UpdateDate (GETDATE() on insert) |

No Tier 1 assignments -- no direct passthrough from upstream production sources. No CID column.
