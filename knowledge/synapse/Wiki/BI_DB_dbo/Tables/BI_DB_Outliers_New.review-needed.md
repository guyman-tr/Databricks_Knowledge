# Review Sidecar — BI_DB_dbo.BI_DB_Outliers_New
<!-- Refreshed 2026-04-23 batch 61 -->

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | ✅ | 30 columns in DDL, 30 in wiki |
| All columns have tier suffix | ✅ | All 30 descriptions end with (Tier N — source) |
| Writer SP confirmed | ✅ | SP_Outliers_New, P99 FinanceReportSPS |
| Sample data reviewed | ✅ | 5 rows sampled; NULL amounts for new-invalid rows confirmed; UpdateDate varchar format "Apr  8 2026  2:53AM" |
| Distribution query | ✅ | Transition: Valid To Invalid 4,766 / Invalid to Valid 1,786; 14 regulations (BVI dominant) |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | `[Unrealized Commission Change]` | High | Always NULL — SP hardcodes NULL for this column. `Fact_CustomerUnrealized_PnL.CommissionOnOpen` is computed but discarded. Confirm this is intentional or an unfinished implementation. SP waste: `#CommissionOnOpen` temp table is created every run but never used. |
| 2 | `UpdateDate` varchar(50) | High | DDL type is varchar(50) not datetime. SP inserts `GETDATE()` which implicitly converts. Confirm if intentional or DDL bug. All temporal filtering must use `[Date]` column instead. |
| 3 | `CreditReportValid` varchar(50) | Medium | Stores '0' or '1' as varchar despite being a bit flag. Confirm all downstream consumers filter with string comparison. |
| 4 | NULL vs 0 semantics | Medium | Financial columns are NULL (not 0) when a customer has no lifetime activity for that action type. SUM ignores NULLs — confirm this is acceptable for financial reporting. |
| 5 | Cumulative amounts | Medium | All financial columns are cumulative lifetime totals to the day before transition — not daily delta amounts. Confirm report consumers understand this. |
| 6 | `[Negative Refill Compensation]` DDL position | Low | In DDL this column is at position 29 (after `[Lost Debt]`), but SP INSERT maps it to logical position 9 (after `[Compensation]`). No functional issue (named INSERT), but DDL column ordering is inconsistent with SP logic. |
| 7 | 'NA' Transition branch | Low | CASE ELSE 'NA' is unreachable after DLT removal (SR-281275) — CurrStat≠PrevStat can only produce 0→1 or 1→0. Confirm no rows with Transition='NA' exist in production. |
| 8 | PlayerStatusID in #cid | Medium | `PlayerStatusID` comes from the **prior-day** snapshot subquery. `V_Liabilities` Chargeback Loss / Other Negative split uses prior-day PlayerStatusID. Confirm this is the intended behavior (should it use current-day status?). |

## Reviewer Corrections

*(Empty — awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 2 | RealCID, Regulation |
| Tier 2 | 27 | CreditReportValid, Transition, [Deposit Amounts], [Compensation Deposit], GivenBonus, [Compensation], [Negative Refill Compensation], [Compensation PI], [Compensation To Affiliates], [Cashout Amounts], [Compensation Cashouts], [Cashout Fee], [Chargeback], [Refund], [ClientBalanceCommission], [Over The Weekend Fee], [Chargeback Loss], [Other Negative], [Compensation PnL Adjustment], [Compensation DormantFee], [ClientBalance Realized PnL], [Unrealized Commission Change], [Cycle Calculation], [Foreclosure], [Lost Debt], [Date], [DateID] |
| Propagation | 1 | UpdateDate |
