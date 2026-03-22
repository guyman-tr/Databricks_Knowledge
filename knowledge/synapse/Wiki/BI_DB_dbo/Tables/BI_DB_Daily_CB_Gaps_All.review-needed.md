# Review Sidecar -- BI_DB_dbo.BI_DB_Daily_CB_Gaps_All

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | OK | 11 columns in DDL, 11 in wiki |
| All columns have tier suffix | OK | 10 Tier 2 + 1 Tier 3 |
| Writer SP confirmed | OK | SP_Daily_CB_Gaps_All matches OpsDB |
| Sample data reviewed | OK | 5 rows sampled -- gaps range from -45 to +1100, consistent with HAVING > 0.01 |
| Alias-level attribution | OK | Single SELECT with #germanbafin temp |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | CycleCalculation components | High | 27 individual components summed. Verify the component list matches the current BI_DB_Client_Balance_CID_Level_New column set. |
| 2 | BI_DB_Client_Balance_CID_Level_New dependency | High | Not tracked in OpsDB dependencies but is a critical runtime dependency. Must run after SP_Client_Balance_New. |

## Reviewer Corrections

*(Empty -- awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 10 | All business columns |
| Tier 3 | 1 | UpdateDate |
