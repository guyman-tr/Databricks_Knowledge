# V_Liabilities — Review Sidecar

## Unverified Claims

### 1. Dead Join to Fact_Guru_Copiers
**Claim**: The LEFT JOIN to Fact_Guru_Copiers (alias `gc`) exists but no columns from `gc` are selected in the view. This is a dead join.
**Evidence**: The view SQL shows `LEFT JOIN DWH_dbo.Fact_Guru_Copiers gc ON(a.CID=gc.CID AND b.DateKey=gc.DateID)` with the comment `--- 2021.01.11 - Boris Slutski`. However, no column in the SELECT clause references `gc.*`.
**Risk**: Medium — the dead join adds unnecessary I/O. It may have been used in a prior version and left behind, or it may serve an implicit filtering purpose (unlikely given LEFT JOIN).
**Suggested verification**: Ask Boris Slutski whether gc columns were intentionally removed or if the JOIN should be cleaned up. Check if removing the JOIN changes row counts (it shouldn't with LEFT JOIN and no gc.* references).

### 2. TotalStockOrders in NetEquity Formula
**Claim**: The NetEquity formula used in ActualNWA and Liabilities includes TotalStockOrders: `TotalPositionsAmount + TotalCash + TotalStockOrders + PositionPnL`. However, the Confluence "Summary of V-Liabilities" shows Balance = `TotalPositionsAmount + PositionPnL + TotalCash + InProcessCashouts` (without TotalStockOrders).
**Evidence**: The actual view SQL uses TotalStockOrders in the CASE expressions. The Confluence page uses a different formula in its example query.
**Risk**: High — the view's actual formula and the Confluence documentation are inconsistent. This could cause confusion for analysts.
**Suggested verification**: Confirm with BI team which formula is correct, and whether TotalStockOrders should be part of the net equity calculation or not.

### 3. Liabilities Decomposition — BonusCredit Edge Cases
**Claim**: When NetEquity is exactly 0, ActualNWA = 0 and Liabilities = InProcessCashouts + 0. When NetEquity equals BonusCredit exactly, ActualNWA = BonusCredit and Liabilities = InProcessCashouts + 0.
**Evidence**: The CASE expression handles `> BonusCredit` (ActualNWA = BonusCredit) and `< 0` (ActualNWA = 0), with the ELSE covering `0 ≤ NetEquity ≤ BonusCredit` (ActualNWA = NetEquity).
**Risk**: Low — the math is consistent, but edge cases at exactly 0 or exactly BonusCredit should be validated with sample data.
**Suggested verification**: Run: `SELECT CID, DateID, ActualNWA, Liabilities, BonusCredit FROM V_Liabilities WHERE BonusCredit > 0 AND DateID = 20260318 ORDER BY Liabilities` to verify edge cases.

### 4. WA_Liabilities Meaning
**Claim**: WA_Liabilities = "credit-capped liabilities" — the portion of liabilities that can be covered by the client's credit balance. "WA" likely stands for "Withdrawal Available" or "Withholding Amount".
**Evidence**: The formula MIN(Liabilities_excl_cashouts, Credit) clearly caps at Credit. The prefix "WA" is not documented in any Confluence page.
**Risk**: Low — the formula is clear even if the naming etymology is uncertain.
**Suggested verification**: Ask BI team what "WA" stands for in WA_Liabilities.

### 5. View Excludes Today
**Claim**: The WHERE clause `DateKey < CAST(CONVERT(VARCHAR(MAX),GETDATE(),112) AS INT)` excludes the current day's data.
**Evidence**: Direct from view SQL. This means the view always shows data through yesterday at most.
**Risk**: Low — this is intentional as EOD snapshots need both FSE and FCUPNL to be loaded, which happens after market close.
**Suggested verification**: None needed — this is by design.

## Reviewer Corrections

*(None yet — awaiting domain expert review)*
