# Review Needed — BI_DB_dbo.BI_DB_LTV_BI_Actual

**Generated**: 2026-04-23 | **Batch**: 70 | **Quality**: 9.0/10

## Tier 4 Items (Undetermined — Pending Review)

None. All 30 columns resolved to Tier 1 or Tier 2.

## Questions for Domain Expert

1. **SP code inaccessible**: `SP_LTV_BI_Actual` shows an empty sys.sql_modules definition and has no SSDT file. Column descriptions are derived from sibling wikis (BI_DB_LTV_Predictions, BI_DB_LTV_BI_Actual_Daily_Snapshot) and data sampling. Please confirm: (a) whether LTV_1Y/3Y/8Y/VolFix are passthrough from BI_DB_LTV_Predictions or recalculated, and (b) how the Revenue8Y variants differ methodologically from the multiplier-model LTV variants.

2. **DaysFromFTD vs Seniority**: Both measure customer tenure — Seniority is in months from FirstFundedMonth; DaysFromFTD is in calendar days from FirstDepositDate. Are both needed, or is one deprecated? Some customers have Seniority = NULL but non-zero DaysFromFTD (unfunded but deposited customers).

3. **Revenue8Y_LTV_All_Conv_Old**: This column is labelled "legacy" based on naming convention. Is it still used downstream, or can it be safely excluded from queries? Should it be deprecated?

4. **Relationship to BI_DB_LTV_Predictions**: Both tables have ~5.84M rows and share many columns (LTV_1Y/3Y/8Y, VolFix, GroupLevel, ClusterDetail, EquityTier, Seniority). Is BI_DB_LTV_BI_Actual a superset that reads from BI_DB_LTV_Predictions, or do both compute independently from shared upstream sources?

5. **Current_ACC_Revenue source**: The LTV_Predictions wiki states Current_ACC_Revenue is sourced from a revenue aggregation with seniority-based correction. Please confirm the exact source table for this column in SP_LTV_BI_Actual.

6. **MonthsSinceLastPosOpen**: Avg 37 months is high — does this indicate the table covers all historical depositors (many long inactive), or are inactive-for-too-long customers excluded?

## Propagation Metadata

- `UpdateDate` is ETL metadata (SP_LTV_BI_Actual run timestamp) — confirmed Propagation tier. NOT NULL. Note: in the downstream Daily_Snapshot table, this column reflects the LTV model refresh time, not the snapshot time.

## Corrections Log

*(Empty — no reviewer corrections yet)*
