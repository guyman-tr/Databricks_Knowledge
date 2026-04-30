# Billing.CashoutReverse

> Cancels a legacy cashout request by setting it to status=4 (Cancelled), recording the reversal in history, and returning the reserved funds to the customer's balance via Customer.SetBalance (UpdateType=8 ReverseCashout).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 (success), RETURN 60015 (IB account), RETURN 60000 (not found / already cancelled / error) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CashoutReverse` cancels a pending cashout request and restores the reserved funds to the customer's balance. It is the counterpart to `Billing.CashoutRequestAdd`: where CashoutRequestAdd reserves funds (UpdateType=9), CashoutReverse releases them back (UpdateType=8 ReverseCashout).

This procedure handles the case where a withdrawal that was submitted but not yet processed needs to be cancelled - either by the customer's request, by operations review, or due to a compliance hold. After reversal the cashout record is in status=4 (Cancelled) and the customer's balance is restored to its pre-request state.

This is a legacy procedure operating on the ~2007-2011 `Billing.Cashout` table.

---

## 2. Business Logic

### 2.1 Cashout Reversal Flow

**What**: Atomically cancels a cashout and restores the customer's balance within a transaction.

**Rules**:
- **Guard 1 - IB account block**: If the customer is an Introducing Broker (Trade.Provider.IsIB=1), RAISERROR(60015) and RETURN.
- **Guard 2 - Not found**: If no row in Billing.Cashout matches @CashoutID, RAISERROR(60000) + RETURN 60000.
- **Guard 3 - Already cancelled**: If Billing.Cashout.CashoutStatusID = 4 for this @CashoutID, RAISERROR(60000) + RETURN 60000. Prevents double-reversal.
- **UPDATE Billing.Cashout**: Sets CashoutStatusID=4 (Cancelled). Outputs CID, old CashoutStatusID, Amount into @Info table variable.
- **INSERT History.Cashout**: Records the status transition (previous -> 4 Cancelled) with UpdateDate=GETDATE() and @Description as Remark.
- **EXEC Customer.SetBalance**: Called with UpdateType=8 (ReverseCashout), @Amount (positive - credit), @CID, @Description, @ManagerID, CashoutID=@CashoutID. This returns the reserved amount to the customer's available balance.

```
Cashout cancellation request
  -> EXEC Billing.CashoutReverse(@CashoutID, @ManagerID, @Description)
       Guard: IsIB? -> RETURN 60015
       Guard: not found? -> RETURN 60000
       Guard: already cancelled? -> RETURN 60000
       BEGIN TRANSACTION
         UPDATE Billing.Cashout SET CashoutStatusID=4
         INSERT History.Cashout (prev->4 Cancelled, remark=@Description)
         EXEC Customer.SetBalance(@CID, +@Amount, 8, ...) -- release funds
       COMMIT
       RETURN 0
```

### 2.2 Three-Way Cashout Lifecycle

| Step | Procedure | UpdateType | Balance Effect |
|------|-----------|------------|---------------|
| Request | CashoutRequestAdd | 9 (CashoutRequest) | -Amount (reserve) |
| Process | CashoutProcessTo* -> CashoutProcess | 2 (Cashout) | -Amount (confirm) |
| Cancel | CashoutReverse | 8 (ReverseCashout) | +Amount (release) |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CashoutID | INTEGER | NO | - | CODE-BACKED | The cashout request to cancel. Must exist in Billing.Cashout and must not already be in status=4 (Cancelled). The procedure reads CID and Amount from this record via the UPDATE OUTPUT clause. |
| 2 | @ManagerID | INTEGER | NO | - | CODE-BACKED | Operations manager or system authorizing the cancellation. Passed to Customer.SetBalance for audit. Stored in balance update history. |
| 3 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Reason or description for the cancellation. Stored as Remark in History.Cashout. Also passed to Customer.SetBalance for the balance restoration record. Max 255 characters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CashoutID | Billing.Cashout | MODIFIER | Updates CashoutStatusID to 4 (Cancelled); reads CID and Amount via OUTPUT |
| CID (from Billing.Cashout) | Customer.Customer | READ (JOIN guard) | Joins to verify customer is not an IB |
| - | Trade.Provider | READ (JOIN guard) | Joins to check IsIB=1 flag |
| @CashoutID | History.Cashout | WRITER | Inserts cancellation status record (NewStatus=4) |
| @CID | Customer.SetBalance | EXEC | Returns reserved funds to customer balance (UpdateType=8 ReverseCashout, positive amount) |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files. Called from back-office operations tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CashoutReverse (procedure)
+-- Billing.Cashout (table)           [MODIFIER - sets status=4; reads CID, Amount via OUTPUT]
+-- Customer.Customer (table)         [READ guard - IB check]
+-- Trade.Provider (table)            [READ guard - IsIB flag]
+-- History.Cashout (table)           [INSERT - cancellation status record]
+-- Customer.SetBalance (procedure)   [EXEC - releases reserved funds (UpdateType=8)]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Cashout | Table | MODIFIER - sets CashoutStatusID=4; OUTPUT reads CID and Amount |
| Customer.Customer | Table | READ - IB account check (cross-schema) |
| Trade.Provider | Table | READ - IsIB=1 check (cross-schema) |
| History.Cashout | Table | INSERT - cancellation audit record (NewStatus=4 Cancelled) |
| Customer.SetBalance | Stored Procedure | EXEC - restores reserved withdrawal amount to balance (UpdateType=8) |

### 6.2 Objects That Depend On This

No dependents found in Billing schema SP files.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **UpdateType=8 (ReverseCashout)**: Exactly reverses the UpdateType=9 (CashoutRequest) debit made by CashoutRequestAdd. The amount is passed positive (credit) to Customer.SetBalance.
- **No History.CashoutAction INSERT**: Unlike CashoutRequestAdd (which inserts a CashoutAction record) and CashoutProcess (which inserts CashoutAction status=2), CashoutReverse only writes to History.Cashout (not History.CashoutAction). This may be a legacy inconsistency.
- **Symmetric guard checks**: Same IB check (60015) as CashoutProcess and CashoutRequestAdd - ensures the same customer class restrictions apply to the full lifecycle.
- **Double-reversal protection**: The guard on CashoutStatusID=4 prevents a cancelled cashout from being reversed again, which would incorrectly credit the customer's balance twice.
- **Legacy system**: Operates on Billing.Cashout (~5,931 rows from 2007-2011), not the modern Billing.Withdraw system.

---

## 8. Sample Queries

### 8.1 Reverse a cashout request
```sql
DECLARE @Result INT;
EXEC @Result = Billing.CashoutReverse
    @CashoutID   = 5000,
    @ManagerID   = 12345,
    @Description = 'Customer requested cancellation';
SELECT @Result AS ReturnCode;
```

### 8.2 Check if a cashout is reversible
```sql
SELECT CashoutID, CID, Amount, CashoutStatusID, RequestDate
FROM Billing.Cashout WITH (NOLOCK)
WHERE CashoutID = 5000
  AND CashoutStatusID IN (1, 2);  -- Pending or InProcess (reversible states)
```

### 8.3 View the balance restoration in history
```sql
-- Verify the funds were returned (UpdateType=8 ReverseCashout)
SELECT TOP 5 *
FROM History.CustomerMoney WITH (NOLOCK)
WHERE CashoutID = 5000
ORDER BY UpdateDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CashoutReverse | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CashoutReverse.sql*
