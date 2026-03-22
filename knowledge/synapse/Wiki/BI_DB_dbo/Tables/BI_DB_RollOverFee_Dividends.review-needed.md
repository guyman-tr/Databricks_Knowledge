# Review Sidecar -- BI_DB_dbo.BI_DB_RollOverFee_Dividends

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | OK | 21 columns |
| All columns have tier suffix | OK | 20 Tier 2 + 1 Tier 3 (`UpdateDate`) |
| Writer SP confirmed | OK | `SP_RollOverFee_Dividends` matches OpsDB (Priority 99, Daily, FinanceReportSPS) |
| Sample data reviewed | **PASSED** | Live MCP query confirmed: DateID=20260310, PaymentType='RollOverFee', EventType='RollOverFee', IsSettled='CFD', InstrumentType='Stocks', Amount=0.01/0.03/0.25, IsComputeForHedge=True/False, PlayerLevel='Other'/'Internal', PaymentDate NULL for rollover fees. Data shape matches SP logic. |
| Distribution vs SP | OK | DDL `ROUND_ROBIN`, clustered `DateID` -- aligns with daily delete-insert |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | CountCIDs semantics | Medium | Stored as **AVG** of pre-aggregated distinct customer counts. Confirm this matches finance definitions (not a true COUNT DISTINCT at output grain). |
| 2 | Amount sign | Medium | `SUM(-Amount)` applied in both branches. Confirm reporting convention vs source FCA. |
| 3 | IsSettled override | Medium | `#IsSettled_pcl` uses `ChangeTypeID=13` rows with `OccurredDateID > @DateID`. Validate edge cases for same-day logs. |
| 4 | BVI hard-coded CIDs | Low | Four `RealCID` values forced to **BVI** player level. Confirm list is current. |
| 5 | Dividend EventType mapping | Medium | Large `CASE` on free-text `EventType`. Confirm uncategorized values still acceptable. |

## Reviewer Corrections

*(Empty -- awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 20 | All business columns |
| Tier 3 | 1 | UpdateDate |
