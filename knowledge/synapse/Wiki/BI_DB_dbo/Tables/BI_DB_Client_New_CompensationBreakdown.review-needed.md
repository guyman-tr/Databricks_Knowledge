# Review Sidecar — BI_DB_dbo.BI_DB_Client_New_CompensationBreakdown

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | ✅ | 31 columns in DDL, 31 in wiki |
| All columns have tier suffix | ✅ | 30 Tier 2 + 1 Tier 3 |
| Writer SP confirmed | ✅ | SP_Client_Balance_New matches OpsDB |
| Sample data reviewed | ✅ | 3 rows — CompensationType values, regulation diversity, amount formats consistent |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | TransferDirection semantics | Medium | Only TransferDirection = 1 rows are captured (via #CIDAgg filter). Confirm that direction 0 (outgoing) compensation is excluded intentionally. |
| 2 | CompensationReasonID mapping | Medium | Sample shows IDs 57 (Interest Payment), 20 (Special Promotion), 94 (Promotion - Leads). SP has commented-out exclusion filter for IDs 7,8,11,17,18,19,22,30-34,36-38,40-41,50-52. Confirm if these are still excluded elsewhere. |
| 3 | IsGlenEagleAccount | Low | Glen Eagle appears to be a white-label partner. Confirm current status — is Glen Eagle still active? |
| 4 | Mega-SP dependency | High | This table is written by SP_Client_Balance_New (~9500 lines), which also writes BI_DB_Client_Balance_CID_Level_New and BI_DB_Client_Balance_Aggregate_Level_New. All three tables share temp tables (#CIDAgg, #fca, etc.), meaning the compensation breakdown depends on the full SP completing. |

## Reviewer Corrections

*(Empty — awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 30 | All business columns |
| Tier 3 | 1 | UpdateDate |
