# Customer.SetBalanceCashoutRollback

> Reverses a previously processed cashout by adding the rollback amount back to a customer's Credit, RealizedEquity, and TotalCash, logging the credit event, and linking the credit record back to the originating Billing.CashoutRollbackTracking entry.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT, @Amount MONEY, @CreditTypeID INT, @RollbackID BIGINT; raises on error via THROW |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

A cashout rollback occurs when a previously approved withdrawal is reversed - for example, if a chargeback is received after the withdrawal was processed, if a payment processor rejects the withdrawal after initial approval, or if a compliance hold requires the funds to be returned to the customer's account. `SetBalanceCashoutRollback` is the database entry point for this reversal.

The procedure atomically adds the @Amount back to three balance fields (Credit, RealizedEquity, TotalCash), logs a credit record with the appropriate CreditTypeID (typically 33=Cashout Rollback), and updates the `Billing.CashoutRollbackTracking` table to link the rollback tracking record back to the newly created CreditID. This bidirectional linkage allows the billing system to trace exactly which credit event corresponds to each rollback entry.

Unlike `SetBalanceCashOut` (which only decrements RealizedEquity), this rollback procedure restores all three balance components, making the customer whole as if the original cashout had not occurred.

---

## 2. Business Logic

### 2.1 Three-Field Balance Restoration

**What**: Adds the rollback amount to Credit, RealizedEquity, and TotalCash simultaneously.

**Columns/Parameters Involved**: `Credit`, `RealizedEquity`, `TotalCash`

**Rules**:
- `Credit += @Amount`
- `RealizedEquity += @Amount`
- `TotalCash += @Amount`
- Uses ISNULL wrappers to handle NULL columns.
- Uses OUTPUT clause to capture new values (NewCredit, OldCredit, NewRealizedEquity, TotalCash) for the credit record.

### 2.2 Rollback Tracking Linkage

**What**: After inserting the credit record, the Billing tracking table is updated with the new CreditID.

**Columns/Parameters Involved**: `@RollbackID`, `@CreditID`

**Rules**:
- `UPDATE Billing.CashoutRollbackTracking SET CreditID = @CreditID WHERE RollbackID = @RollbackID`
- Links the Billing-layer rollback entry to the Customer-layer credit event.
- Both the credit insert and the tracking update are within the same transaction.
- @RollbackID is nullable (NULL = no tracking update needed for legacy/direct calls).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the account being credited with the rollback amount. |
| 2 | @Amount | MONEY | NO | - | CODE-BACKED | Amount to restore in dollars. Added to Credit, RealizedEquity, and TotalCash. |
| 3 | @CreditTypeID | INT | NO | - | VERIFIED | Type of credit event. Typically 33=Cashout Rollback (Dictionary.CreditType). The caller supplies this to allow flexibility for related rollback scenarios. |
| 4 | @WithdrawID | INT | NO | - | CODE-BACKED | Withdrawal request ID being reversed. Links the rollback credit record to the original withdrawal. |
| 5 | @ManagerID | INT | NO | - | CODE-BACKED | Admin/manager who authorized the rollback. Stored in the credit record. |
| 6 | @Description | VARCHAR(250) | NO | - | CODE-BACKED | Human-readable description of the rollback reason, stored in the credit history. |
| 7 | @WithdrawProcessingID | INT | NO | - | CODE-BACKED | Processing batch ID for the rollback. Passed through to SetBalanceInsertCredit_Native. |
| 8 | @RollbackID | BIGINT | YES | NULL | CODE-BACKED | Billing.CashoutRollbackTracking primary key. When provided, the tracking entry is updated with the new CreditID. NULL if no tracking linkage needed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerMoney | MODIFIER | Adds @Amount to Credit, RealizedEquity, TotalCash |
| @CID | Customer.SetBalanceInsertCredit_Native | Caller (EXEC) | Logs the rollback as a credit record |
| @RollbackID | Billing.CashoutRollbackTracking | MODIFIER | Updates CreditID to link the tracking record to the new credit |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalance | EXEC | Caller | Routes CreditTypeID=33 (Cashout Rollback) events here |
| Billing cashout rollback pipeline | External | Caller | Called when a withdrawal reversal is initiated |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetBalanceCashoutRollback (procedure)
+-- Customer.CustomerMoney (table) [UPDATE Credit, RealizedEquity, TotalCash]
+-- Customer.SetBalanceInsertCredit_Native (procedure) [INSERT credit record]
|     +-- History.ActiveCreditRecentMemoryBucket (table)
+-- Billing.CashoutRollbackTracking (table) [UPDATE CreditID linkage]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | UPDATE - restores Credit, RealizedEquity, TotalCash |
| Customer.SetBalanceInsertCredit_Native | Procedure | EXEC - inserts rollback credit record |
| Billing.CashoutRollbackTracking | Table | UPDATE - links rollback tracking entry to credit ID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Procedure | Calls this for CreditTypeID=33 (Cashout Rollback) events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BEGIN TRAN / COMMIT | Transaction | Balance update + credit insert + tracking update are atomic |
| Nested transaction handling | Error handling | ROLLBACK if this is the last transaction; COMMIT if nested. Ensures parent transaction is not stranded. |

---

## 8. Sample Queries

### 8.1 Find cashout rollbacks for a customer

```sql
SELECT
    acb.CreditID,
    acb.CreditTypeID,
    ct.Name AS CreditTypeName,
    acb.Payment AS RollbackAmount,
    acb.WithdrawID,
    acb.Description,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
JOIN Dictionary.CreditType ct WITH (NOLOCK) ON ct.CreditTypeID = acb.CreditTypeID
WHERE acb.CID = 12345
    AND acb.CreditTypeID = 33
ORDER BY acb.Occurred DESC
```

### 8.2 Check Billing.CashoutRollbackTracking linkage

```sql
SELECT
    rt.RollbackID,
    rt.CreditID,
    rt.WithdrawID,
    acb.Payment AS RollbackAmount,
    acb.Occurred AS RollbackDate
FROM Billing.CashoutRollbackTracking rt WITH (NOLOCK)
LEFT JOIN History.ActiveCreditBucket_VW acb WITH (NOLOCK) ON acb.CreditID = rt.CreditID
WHERE rt.RollbackID = 999888
```

### 8.3 Compare original cashout vs rollback for a withdrawal

```sql
DECLARE @WithdrawID INT = 77777;

SELECT
    acb.CreditTypeID,
    ct.Name AS EventType,
    acb.Payment AS Amount,
    acb.RealizedEquity AS RealizedEquityAfterEvent,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
JOIN Dictionary.CreditType ct WITH (NOLOCK) ON ct.CreditTypeID = acb.CreditTypeID
WHERE acb.WithdrawID = @WithdrawID
    AND acb.CreditTypeID IN (2, 9, 15, 33)
ORDER BY acb.Occurred
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetBalanceCashoutRollback | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetBalanceCashoutRollback.sql*
