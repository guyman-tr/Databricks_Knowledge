# Trade.UpdateCustomerMoneyCashoutRollback

> Reverses a cashout by adding the rollback amount to a customer's Credit, RealizedEquity, and TotalCash balances atomically; returns the updated balance values via OUTPUT clause.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - identifies the customer whose balance is restored |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateCustomerMoneyCashoutRollback restores a customer's balance after a cashout (withdrawal) is reversed. When a customer's cashout is rejected, cancelled, or rolled back by operations (e.g., failed wire transfer, chargeback, or manual correction via the CashoutTool), the withdrawn funds must be returned to their account. This procedure performs that credit restore by incrementing three balance fields simultaneously and returning the resulting values for confirmation.

Without this procedure, cashout reversals would require direct table updates, risking inconsistency between Credit, RealizedEquity, and TotalCash. The three fields must all increase by the same amount because a cashout reduces all three when it is processed - reverting it requires increasing all three by the same delta.

The procedure is called by `Billing.AddCashoutRollback` (the billing orchestrator for cashout rollback workflow), and is also invocable via the CashoutTool (a BackOffice admin utility). Created by KateM on 21/02/2022.

---

## 2. Business Logic

### 2.1 Three-Field Parallel Credit Restore

**What**: A cashout reversal must restore Credit, RealizedEquity, AND TotalCash by the same amount, because the original cashout decremented all three simultaneously.

**Columns/Parameters Involved**: `@Amount`, `Customer.CustomerMoney.Credit`, `Customer.CustomerMoney.RealizedEquity`, `Customer.CustomerMoney.TotalCash`

**Rules**:
- All three fields receive the same increment: `+= @Amount`
- ISNULL wraps both sides: `ISNULL(field, 0) + ISNULL(@Amount, 0)` - protects against NULL balances (e.g., uninitialized accounts) and NULL amount input
- Credit: the customer's available trading balance. Cashout decrements it; rollback restores it
- RealizedEquity: cumulative real funds. Cashout decrements it (real withdrawal); rollback restores it
- TotalCash: maintained by the TotalCash reconciliation job. Cashout decrements; rollback increments
- OUTPUT clause returns `Inserted.Credit, Inserted.TotalCash, Inserted.RealizedEquity` - the post-update values so the caller can log and verify the result
- Wrapped in TRY/CATCH with THROW - errors propagate cleanly to the caller

**Diagram**:
```
Cashout Rollback Flow:
  Original cashout: Credit -= X, RealizedEquity -= X, TotalCash -= X
  Rollback restore: Credit += X, RealizedEquity += X, TotalCash += X
  Net effect after cashout + rollback: all three fields back to original values
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the account whose balance is being restored. Matches Customer.CustomerMoney.CID (the primary key of the balance table). The UPDATE targets exactly one row for this CID. |
| 2 | @Amount | MONEY | NO | - | CODE-BACKED | The dollar amount to restore to the customer's balance. This is the cashout amount being reversed - all three balance fields (Credit, RealizedEquity, TotalCash) are incremented by this value. ISNULL-protected on both sides to handle null input gracefully. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE + OUTPUT | Customer.CustomerMoney | Modifier | Increments Credit, RealizedEquity, TotalCash by @Amount for @CID; returns updated values via OUTPUT clause |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.AddCashoutRollback | EXEC call | Caller | The Billing schema cashout rollback orchestrator calls this to restore the customer's trading balance |
| CashoutTool (UsersPermissions) | EXEC call | Caller | BackOffice admin tool for manual cashout reversals |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateCustomerMoneyCashoutRollback (procedure)
+-- Customer.CustomerMoney (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | UPDATE target - increments Credit, RealizedEquity, TotalCash for @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.AddCashoutRollback | Stored Procedure | Calls this as part of the cashout rollback workflow to restore customer balance |
| CashoutTool | Script/Utility | Admin tool for manual cashout reversals |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. The procedure uses `SET NOCOUNT ON` and is wrapped in TRY/CATCH with THROW.

---

## 8. Sample Queries

### 8.1 Execute a cashout rollback for a customer
```sql
EXEC Trade.UpdateCustomerMoneyCashoutRollback
    @CID    = 12345,
    @Amount = 500.00;
-- Returns: Credit, TotalCash, RealizedEquity after update
```

### 8.2 Verify customer balance before and after rollback
```sql
SELECT CID, Credit, RealizedEquity, TotalCash
FROM   Customer.CustomerMoney WITH (NOLOCK)
WHERE  CID = 12345;
```

### 8.3 Check balance history for a customer after rollback
```sql
SELECT TOP 10 *
FROM   History.CustomerMoney WITH (NOLOCK)
WHERE  CID = 12345
ORDER  BY ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateCustomerMoneyCashoutRollback | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateCustomerMoneyCashoutRollback.sql*
