# Review Needed: BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdraw

## Critical Issues

### 1. Column Swap Bug in SP_AML_Multiple_Accounts Step 12

**Severity**: HIGH — data integrity issue in production

The INSERT statement in Step 12 of `SP_AML_Multiple_Accounts` has `IsBlocked` and `Total_Users` in swapped positions relative to the SELECT clause:

```sql
-- INSERT column order:    FundingID, IsBlocked,   Total_Users, ...
-- SELECT value order:     FundingID, Total_Users, IsBlocked,   ...
```

**Evidence from live data**:
- `IsBlocked` column contains values 2-151 (these are user counts, not block flags)
- `Total_Users` column contains values 0-1 (these are block flags, not user counts)

**Impact**: Any dashboard or downstream query reading `IsBlocked` as a block indicator is actually reading user counts, and vice versa. The deposit counterpart (`BI_DB_AML_Multiple_Accounts_Dep`, Step 11) does NOT have this bug.

**Recommended fix**: Swap positions 2 and 3 in the SELECT clause of Step 12 to match the INSERT column list.

### 2. Data Staleness

UpdateDate is 2025-03-13 — over a year stale as of 2026-04-28. The SP may not be in the current execution schedule.

### 3. Type Precision Loss

`Total_Approved_Withdraw` is stored as `int` but the source (`Fact_BillingWithdraw.Amount_WithdrawToFunding`) is `money` type. Decimal amounts are truncated on insert.

## Tier 3 Columns

| Column | Reason | Suggested Action |
|--------|--------|-----------------|
| IsBlocked | Source is `External_etoro_Billing_Funding.IsBlocked` — no upstream wiki exists for this external table | Document once External_etoro_Billing_Funding is wikified |

## Open Questions

1. Is the column swap bug known to the AML dashboard team? Do downstream Power BI reports compensate for it?
2. Why was the SP execution stopped (last run 2025-03-13)?
3. Should the `Group_Type` CASE expression include a '2-4' bucket? The HAVING clause allows FundingIDs with 2+ users, but the lowest bucket label is '5-20'.

---
*Generated: 2026-04-28*
