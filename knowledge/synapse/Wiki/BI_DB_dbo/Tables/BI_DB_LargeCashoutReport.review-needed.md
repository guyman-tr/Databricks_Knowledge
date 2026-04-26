# Review Needed: BI_DB_dbo.BI_DB_LargeCashoutReport

## Items Requiring Human Review

### 1. AffiliateCO: CashoutReasonID 14 and 15 Semantics
**What**: The wiki states AffiliateCO = 1 when CashoutReasonID IN (14, 15) but does not define what these IDs represent.
**Why**: The Billing.Withdraw upstream wiki lists CashoutReasonID as a FK to a dictionary table, but the exact labels for 14 and 15 were not confirmed in this pipeline pass.
**Action**: Query `etoro.Dictionary.CashoutReason WHERE CashoutReasonID IN (14, 15)` (or check the Billing.Withdraw upstream wiki) to confirm the business meaning of these reason codes. Update column 6 description accordingly.

### 2. Desk Mapping for USA Region
**What**: The #desk hardcoded table does not include a 'USA' row. The sample data confirmed no USA customers in the current 117-row queue, but USA is a valid region in Dim_Country.
**Why**: If a customer with Region='USA' submits a large cashout, the INNER JOIN on #desk will exclude them silently.
**Action**: Verify with the DWH Ops/Sales team whether USA is intentionally excluded from this report (e.g., handled by a separate US compliance pipeline) or if it should be added to the #desk mapping.

### 3. CashoutStatus 'Null' Branch Reachability
**What**: The SP CASE includes `ELSE 'Null'` for CashoutStatusID not 1 or 2, but the WHERE clause already filters to IN (1,2).
**Why**: If the WHERE clause is applied correctly, the ELSE branch should be dead code. However, if the external table or a future SP change alters the filter, 'Null' values could appear.
**Action**: Confirm whether any 'Null' CashoutStatus rows exist via `SELECT DISTINCT CashoutStatus FROM BI_DB_LargeCashoutReport`. Document as dead-code branch if never observed.

### 4. V_Liabilities View Definition
**What**: CurrentEquity = V_Liabilities.Liabilities + V_Liabilities.ActualNWA. The V_Liabilities view is referenced but its definition was not read during this pipeline pass.
**Why**: The exact definition of Liabilities vs. ActualNWA (net working assets?) and their relationship to the customer's equity position would add precision to the CurrentEquity description.
**Action**: Read `DWH_dbo.V_Liabilities` view definition from the SSDT repo to clarify what Liabilities and ActualNWA represent, and update column 12 description.

## Auto-Passed Items

| Check | Result |
|-------|--------|
| All 14 columns documented | PASS |
| T1 columns traced to Billing.Withdraw and Customer.CustomerStatic | PASS |
| UpdateDate uses Propagation tier | PASS |
| TRUNCATE+INSERT semantics (not historical) documented | PASS |
| $20K threshold documented | PASS |
| Business-day calculation formula documented | PASS |
| Desk hardcoded mapping fully enumerated | PASS |
| PII warning in executive summary and column descriptions | PASS |
| INNER JOIN on #desk (silent exclusion risk) noted in Gotchas | PASS |
| CustomerName/AccountManager LEFT JOIN NULL behavior documented | PASS |
