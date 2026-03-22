---
object: Dealing_Manual_Exec_Trade_Summary
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_Manual_Exec_Trade_Summary — Review Notes

## Auto-Generated Flags

- **NOP sign convention**: NOP_Start/End = SUM(Units × (IsBuy=1 → -Bid else Ask)). This means a net long netting position yields a negative NOP value. Is this the intended convention for consumers, or do they negate it?
- **Etoro_Manual_Trades is decimal(22,8)**: This is a count column declared as decimal — unusual. Confirm this is intentional (COUNT(OrderID) stored as decimal).
- **Stocks Zero source change (Feb 2024)**: SP comment notes the Zero source was changed from BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW to Dealing_dbo.Dealing_DailyZeroPnL_Stocks for stocks on 2024-02-15. The UNION still includes both, so stocks may appear in both sources if not properly filtered.
- **HedgeServerID vs HedgeServer**: This table uses HedgeServerID while the trade-level table uses HedgeServer. Same field — inconsistent naming.

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
