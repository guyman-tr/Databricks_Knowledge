# Review Needed: BI_DB_dbo.BI_DB_CMR_Phase2_CycleGap

**Batch**: 58 | **Object**: #3 | **Date**: 2026-04-23
**Confidence**: High (SP code read in full; live data sampled)

---

## Items Requiring Business Validation

### 1. Regulation Labels Are Aggregation Groups (Confirm Mapping)
The SP hardcodes 'ASIC' for source records with Regulation IN ('ASIC', 'ASIC & GAML') and 'EU' for Regulation IN ('CySEC', 'BVI', 'NFA', 'None'). These stored values are NOT the same as the raw Regulation values in the source table or in BI_DB_CMR_Phase2_ClientBalance. Confirm whether these group labels are still accurate -- specifically whether all CySEC/BVI/NFA regulations should still be grouped as 'EU'.

### 2. IsCreditReportValidCB Filter on 'As per Cycle Gap' Only
The 'As per Cycle Gap' branch applies `IsCreditReportValidCB = 1`, meaning customers without a valid credit report are excluded from the standard cycle gap calculation. The 'As per Outliers' branch has no such filter. Business owner should confirm this asymmetry is intentional -- and whether credit-report-invalid customers' standard gaps should be excluded.

### 3. NFA and None in EU Group
Regulation values 'NFA' (National Futures Association, US) and 'None' are grouped with 'EU' (CySEC, BVI). This grouping is unusual -- NFA is a US regulator. Confirm whether this is the correct aggregation or whether it is a legacy classification.

### 4. Outlier Gap Magnitudes
'As per Outliers' rows have average absolute gap values of $2M (ASIC) and $14.6M (EU), far exceeding the standard cycle gap rows. This suggests these represent known reconciliation exceptions awaiting resolution. Business owner should confirm the expected handling workflow for outlier gap rows.

### 5. Sparsity (1.3 rows per date on average)
Most dates have only 1-2 rows. Confirm whether the expectation is that gaps are normally zero (and thus not stored) and that non-zero rows represent genuine exceptions being tracked.

---

## Tier Coverage Summary

| Tier | Count | Source |
|------|-------|--------|
| Tier 2 | 5 | All data columns from BI_DB_CB_CycleGap_Categorization or hardcoded SP strings |
| Propagation | 1 | UpdateDate (GETDATE() on insert) |

No Tier 1 assignments -- no direct passthrough from upstream production sources. No CID column.
