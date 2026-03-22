# Review Sidecar -- BI_DB_dbo.BI_DB_Outliers_New

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | OK | 30 columns in provided DDL (request text said 28; DDL count used) |
| All columns have tier suffix | OK | 29 Tier 2 + 1 Tier 3 (`UpdateDate`) |
| Writer SP confirmed | OK | `SP_Outliers_New` matches OpsDB (Priority 99, Daily, FinanceReportSPS) |
| Sample data reviewed | **PASSED** | Live MCP query confirmed: Date=2026-03-06/2026-03-04, Regulation='BVI', CreditReportValid=0, Transition='Valid To Invalid', most financial columns NULL/empty (sparse -- only populated for flipped customers), Unrealized Commission Change=0.00 (confirmed NULL-like), UpdateDate varchar format 'Mar 7 2026 2:58AM'. Data shape matches SP logic. |
| REPLICATE + HEAP | OK | Matches small outlier population pattern noted in task |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | Unrealized Commission Change | High | SP inserts **NULL** while `#CommissionOnOpen` is computed. Confirm intentional dead column or planned backfill. |
| 2 | Compensation exclusion list | Medium | Base `Compensation` excludes many `CompensationReasonID` values; confirm list still matches business rules. |
| 3 | Transition = NA | Medium | After DLT removal, `NA` is default when not valid/invalid flip. Confirm consumers handle NA. |
| 4 | Liabilities split | Medium | Chargeback loss vs other negative depends on `PlayerStatusID` sets (1,3,5,7). Validate against risk policy. |
| 5 | UpdateDate type | Low | Column is `varchar(50)` while source is `GETDATE()`; confirm implicit conversion is acceptable for downstream. |
| 6 | PlayerStatusID in #cid | Medium | `#cid` selects `PlayerStatusID` from the **prior-day** snapshot subquery (`b`). `V_Liabilities` split uses this value at `DateID=@ld_t2`. Confirm intended vs current-day status. |

## Reviewer Corrections

*(Empty -- awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 29 | All business columns including NULL placeholder column |
| Tier 3 | 1 | UpdateDate |
