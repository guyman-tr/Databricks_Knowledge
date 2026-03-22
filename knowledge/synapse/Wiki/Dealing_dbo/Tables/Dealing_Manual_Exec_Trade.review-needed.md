---
object: Dealing_Manual_Exec_Trade
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_Manual_Exec_Trade — Review Notes

## Auto-Generated Flags

- **Duplicate OrderIDs**: The same OrderID can appear in both the Manual log and Execution log. Does this cause duplicate rows in this table, or does the LEFT JOIN prevent it?
- **RequestTypeID=3**: Included regardless of success. What does type 3 represent? Is this a SAXO/EMSX order type?
- **Signed Units**: Units are multiplied by (IsBuy=1 → 1, else -1). This means sell orders have negative units. Confirm downstream consumers handle this correctly.
- **HedgeServer vs HedgeServerID**: This table has column `HedgeServer` (int) while Manual_Exec_Trade_Summary has `HedgeServerID`. Same concept, different naming — watch for join issues.

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
