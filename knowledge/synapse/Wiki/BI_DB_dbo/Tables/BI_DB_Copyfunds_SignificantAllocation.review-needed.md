# BI_DB_Copyfunds_SignificantAllocation — Review Needed

**Generated**: 2026-04-23  
**Reviewer**: BI / Account Management / Data Engineering  

---

## Issues Requiring Human Review

### 1. `NetMoneyOut` column stores net money IN — naming error
**Severity**: High  
The column `NetMoneyOut` contains the value computed as `NetMoneyIn` in the SP (`-1 * SUM(all ActionTypeID 15-18 amounts)`). Positive values mean the customer added more to CopyFunds than they withdrew. Any report reading `NetMoneyOut` as a withdrawal amount would produce inverted results. The name cannot be changed without a DDL ALTER, which requires pipeline and downstream coordination.  
**Recommended action**: Rename the column to `NetMoneyIn` in the DDL, or add a column alias in all downstream report queries. Flag existing reports that use this column for sign-correction.

### 2. `AddMoneyOut` is negative in practice — counter-intuitive sign
**Severity**: Medium  
The SP computes `AddMoneyOut = -1 * SUM(Amount)` for ActionTypeID 16 and 18. In Fact_CustomerAction, these amounts are stored as positive (representing money leaving the account). Applying `-1` makes them negative in this table. The column name implies a positive dollar amount of withdrawals, but the actual stored value is negative. Observed: Africa row shows AddMoneyOut = -51,662.54.  
**Recommended action**: Verify with the Data Engineering team whether this sign is intentional. Consider changing to `AddMoneyOut = SUM(Amount)` (without negation) to store as positive, matching the column's implied semantics.

### 3. Silent INNER JOIN on `#Contact` excludes customers with no Salesforce history
**Severity**: Medium  
The SP has `JOIN #Contact ct ON ct.CID = dc.RealCID` (INNER JOIN, not LEFT JOIN). Customers in `#NetMoneyIn` who have never received a Salesforce contact (phone call or email from an account manager) are silently excluded from the output, even if their allocation change far exceeds the threshold. This means the table may miss high-value clients who are newly assigned or have never been actively managed.  
**Recommended action**: Change to LEFT JOIN with `ContactedLastMonth = 'Never Contacted'` for NULL cases, or confirm with business that uncontacted customers are intentionally excluded.

### 4. `Balance` column stores V_Liabilities.Credit (cash), not total balance
**Severity**: Low (naming ambiguity)  
The `Balance` column name implies total account balance, but the SP sources it from `V_Liabilities.Credit` (cash balance available for withdrawal). The customer's total wealth is in `RealizedEquity`. Downstream reports treating `Balance` as total account value would understate client wealth significantly for heavy investors (where most equity is in open positions, not cash).  
**Recommended action**: Rename to `CashBalance` or add a column comment clarifying Credit = cash only.

### 5. No @Date parameter — cannot reprocess historical dates
**Severity**: Low (operational limitation)  
The SP uses `@Date = DATEADD(day, -1, GETDATE())` — hardcoded to yesterday. If the SP fails and needs to be rerun the next day, it will process the new "yesterday" (two days after the original target). There is no mechanism to reprocess a specific historical date.  
**Recommended action**: Parameterize @Date and add the standard `@Date Date = DATEADD(day,-1,GETDATE())` defaulting pattern used by other BI_DB_dbo SPs (e.g., SP_CopyMilestone).
