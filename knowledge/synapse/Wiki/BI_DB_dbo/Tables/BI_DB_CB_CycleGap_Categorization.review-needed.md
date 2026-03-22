# Review Sidecar — BI_DB_dbo.BI_DB_CB_CycleGap_Categorization

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | ✅ | 23 columns in DDL, 23 in wiki |
| All columns have tier suffix | ✅ | 22 Tier 2 + 1 Tier 3 |
| Writer SP confirmed | ✅ | SP_CB_Gap_Categorization matches OpsDB |
| Sample data reviewed | ✅ | 5 rows sampled — gap amounts, outlier transitions consistent |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | Tableau final logic | Medium | The SP author notes "the final logic looking back and forth on gap closures is in Tableau live query." Confirm this is still the architecture — is the Tableau query documented anywhere? |
| 2 | GapCategorized column | High | The SP has a commented-out CASE expression (lines 533-540) that would compute GapCategorized (RefundAsChargeback_Gap_Explained, Cashout_Gap_Closed, Outlier_Gap_Explained, etc.). This was never enabled. Confirm it's intentionally deferred to Tableau. |
| 3 | BI_DB dependencies | Medium | SP reads from 4 BI_DB tables (Daily_CB_Gaps_All, Outliers_New, CycleGap, Client_Balance_CID_Level_New) but OpsDB shows this as a leaf node (Priority 99, no deps). These are SQL-level dependencies not tracked in OpsDB orchestration. |
| 4 | OutlierTransition values | Low | Sample shows "Etoro To DLT" and "0". Confirm full set of transition types. |
| 5 | V_Liabilities | Low | No upstream wiki exists for V_Liabilities. Multiple P99 tables reference this view — consider documenting it. |

## Reviewer Corrections

*(Empty — awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 22 | All business columns |
| Tier 3 | 1 | UpdateDate |
