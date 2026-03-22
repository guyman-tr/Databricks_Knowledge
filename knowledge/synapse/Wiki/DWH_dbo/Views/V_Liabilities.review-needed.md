# V_Liabilities — Review Sidecar

## Unverified Claims

### 1. Dead Join to Fact_Guru_Copiers
**Claim**: The LEFT JOIN to Fact_Guru_Copiers (alias `gc`) exists but no columns from `gc` are selected in the view. This is a dead join.
**Evidence**: The view SQL shows `LEFT JOIN DWH_dbo.Fact_Guru_Copiers gc ON(a.CID=gc.CID AND b.DateKey=gc.DateID)` with the comment `--- 2021.01.11 - Boris Slutski`. However, no column in the SELECT clause references `gc.*`.
**Risk**: Medium — the dead join adds unnecessary I/O. It may have been used in a prior version and left behind, or it may serve an implicit filtering purpose (unlikely given LEFT JOIN).
**Suggested verification**: Ask Boris Slutski whether gc columns were intentionally removed or if the JOIN should be cleaned up. Check if removing the JOIN changes row counts (it shouldn't with LEFT JOIN and no gc.* references).

### 2. TotalStockOrders in NetEquity Formula
**Claim**: The NetEquity formula includes TotalStockOrders: `TotalPositionsAmount + TotalCash + TotalStockOrders + PositionPnL`. However, TotalStockOrders is a legacy column hardcoded to 0 since 2019 (confirmed in Fact_SnapshotEquity wiki). The Confluence "Summary of V-Liabilities" shows Balance = `TotalPositionsAmount + PositionPnL + TotalCash + InProcessCashouts` (without TotalStockOrders).
**Evidence**: Both the view SQL and the upstream FSE wiki confirm TotalStockOrders = 0 always. The formula inconsistency is cosmetic, not computational.
**Risk**: Low — no data impact since value is always 0. Could be cleaned up for clarity.
**Suggested verification**: None needed — confirmed via FSE wiki that it's always 0.

### 3. Liabilities Decomposition — BonusCredit Edge Cases
**Claim**: When NetEquity is exactly 0, ActualNWA = 0 and Liabilities = InProcessCashouts. When NetEquity equals BonusCredit exactly, ActualNWA = BonusCredit and Liabilities = InProcessCashouts.
**Evidence**: The CASE expression handles `> BonusCredit` (ActualNWA = BonusCredit) and `< 0` (ActualNWA = 0), with the ELSE covering `0 ≤ NetEquity ≤ BonusCredit` (ActualNWA = NetEquity).
**Risk**: Low — the math is consistent, but edge cases at exactly 0 or exactly BonusCredit should be validated with sample data.
**Suggested verification**: Run: `SELECT CID, DateID, ActualNWA, Liabilities, BonusCredit FROM V_Liabilities WHERE BonusCredit > 0 AND DateID = 20260318 ORDER BY Liabilities` to verify edge cases.

### 4. WA_Liabilities Naming
**Claim**: WA_Liabilities = "credit-capped liabilities" — the portion of liabilities that can be covered by the client's credit balance. "WA" likely stands for "Withdrawal Available" or "Withholding Amount".
**Evidence**: The formula MIN(Liabilities_excl_cashouts, Credit) clearly caps at Credit. The prefix "WA" is not documented in any Confluence page.
**Risk**: Low — the formula is clear even if the naming etymology is uncertain.
**Suggested verification**: Ask BI team what "WA" stands for in WA_Liabilities.

### 5. CopyFundAUM Source Table
**Claim**: CopyFundAUM is sourced from Fact_SnapshotEquity. The column appears unqualified in the view SQL (no `a.` or `c.` prefix).
**Evidence**: The column is listed on line 60 of the view SQL without a table alias. It is not documented in the Fact_SnapshotEquity wiki (32 columns) nor in the Fact_CustomerUnrealized_PnL wiki (57 columns).
**Risk**: Low — the column exists in one of the source tables; SQL Server resolves it unambiguously at compile time.
**Suggested verification**: Run `SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Fact_SnapshotEquity' AND COLUMN_NAME = 'CopyFundAUM'` to confirm the source table.

## Reviewer Corrections

*(None yet — awaiting domain expert review)*
