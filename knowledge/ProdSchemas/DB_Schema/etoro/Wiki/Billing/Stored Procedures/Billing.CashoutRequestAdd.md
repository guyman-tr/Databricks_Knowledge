# Billing.CashoutRequestAdd

> Creates a new legacy cashout request in Billing.Cashout, initializes history records, and reserves the amount from the customer's balance (UpdateType=9 CashoutRequest); called when a customer submits a withdrawal through the legacy cashout flow.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 (success), RETURN 60015 (IB account), RETURN 60000 (error), @CashoutID OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CashoutRequestAdd` is the entry point for creating a new legacy cashout (withdrawal) request. When a customer requests to withdraw funds from their eToro account, this procedure:
1. Inserts the request into `Billing.Cashout` (status=1 Pending) and captures the generated CashoutID via OUTPUT clause
2. Records the initial status in `History.Cashout`
3. Logs a "New" action in `History.CashoutAction` (status=1)
4. Reserves the withdrawal amount from the customer's balance via `Customer.SetBalance` with UpdateType=9 (CashoutRequest)

This is a legacy procedure for the ~2007-2011 `Billing.Cashout` table (5,931 rows). Modern withdrawals use the `Billing.Withdraw` system. The request remains in status=1 (Pending) until an operations manager processes it via one of the `CashoutProcessTo*` wrappers.

---

## 2. Business Logic

### 2.1 Cashout Request Creation Flow

**What**: Atomically creates a cashout request and reserves the customer's balance within a transaction.

**Rules**:
- **Guard 1 - IB account block**: If the customer (via CID) is an Introducing Broker (Trade.Provider.IsIB=1), RAISERROR(60015) and RETURN. IB accounts cannot use this cashout flow.
- **Guard 2 - Rejected status check**: If there is already a cashout for this CID with CashoutStatusID=4 (Cancelled/Rejected), the request may be blocked (legacy dedup logic).
- **INSERT Billing.Cashout**: Inserts with CashoutStatusID=1 (Pending), CurrencyID, Amount, FundingTypeID, RequestDate=GETDATE(). Uses OUTPUT clause to capture the auto-generated CashoutID into @CashoutID OUTPUT parameter.
- **INSERT History.Cashout**: Records the initial status with NewCashoutStatusID=1 (Pending), PreviousCashoutStatusID=NULL or 0, UpdateDate=GETDATE().
- **INSERT History.CashoutAction**: CashoutActionStatusID=1 (New), records the funding type and amount, ActionDate=GETDATE().
- **EXEC Customer.SetBalance**: Called with UpdateType=9 (CashoutRequest), @Amount negated (debit from balance), @CID, @Description, @ManagerID, CashoutID=@CashoutID. This reserves the withdrawal amount from the customer's available balance.

```
Customer submits withdrawal request
  -> EXEC Billing.CashoutRequestAdd(@CID, @Amount, @FundingTypeID, ...)
       Guard: IsIB? -> RETURN 60015
       BEGIN TRANSACTION
         INSERT Billing.Cashout (status=1 Pending) OUTPUT -> @CashoutID
         INSERT History.Cashout (NewStatus=1)
         INSERT History.CashoutAction (action=1 New)
         EXEC Customer.SetBalance(@CID, -@Amount, 9, ...) -- reserve funds
       COMMIT
  -> Returns @CashoutID OUTPUT to caller
  [Later] EXEC Billing.CashoutProcessTo*(@CashoutID, ...) -> status=3 Processed
```

### 2.2 Error Handling

**Rules**:
- Each INSERT/UPDATE checks @@ERROR; on non-zero: ROLLBACK + RAISERROR(60000) + RETURN.
- If Customer.SetBalance returns non-zero: RETURN @Answer (propagates error).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID making the cashout request. Used for the IB guard check, written to Billing.Cashout.CID, and passed to Customer.SetBalance. |
| 2 | @Amount | MONEY | NO | - | CODE-BACKED | Withdrawal amount in the customer's account currency. Written to Billing.Cashout.Amount. Passed negated to Customer.SetBalance (debit). |
| 3 | @FundingTypeID | INTEGER | NO | - | CODE-BACKED | Payment method the customer selected for the withdrawal (1=CreditCard, 2=WireTransfer, 3=PayPal, 5=WesternUnion, 6=Neteller). Written to Billing.Cashout.FundingTypeID and History.CashoutAction.FundingTypeID. |
| 4 | @CurrencyID | INTEGER | NO | - | CODE-BACKED | Currency of the cashout request. Written to Billing.Cashout.CurrencyID. References Dictionary.Currency. |
| 5 | @ManagerID | INTEGER | NO | - | CODE-BACKED | Manager or system ID authorizing the reservation. Passed to Customer.SetBalance for audit. May be a system account ID when triggered from application code. |
| 6 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Description of the cashout request. Passed to Customer.SetBalance as the balance update description for audit trail and stored in History.Cashout.Remark. |
| 7 | @CashoutID | INTEGER | YES | - | CODE-BACKED | OUTPUT parameter. Returns the auto-generated CashoutID from Billing.Cashout after successful INSERT. The caller uses this to reference the cashout in subsequent operations (e.g., passing to CashoutProcessTo* wrappers). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Cashout | WRITER | Inserts new cashout record (status=1 Pending); OUTPUT returns CashoutID |
| @CID | Customer.Customer | READ (JOIN guard) | Joins to verify customer is not an IB |
| - | Trade.Provider | READ (JOIN guard) | Joins to check IsIB=1 flag |
| @CashoutID | History.Cashout | WRITER | Inserts initial status record (NewStatus=1) |
| @CashoutID | History.CashoutAction | WRITER | Inserts action record (status=1 New) |
| @CID | Customer.SetBalance | EXEC | Reserves withdrawal amount from balance (UpdateType=9 CashoutRequest, negative amount) |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files. Called from application code when customers submit withdrawal requests.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CashoutRequestAdd (procedure)
+-- Billing.Cashout (table)           [INSERT - new cashout record; OUTPUT CashoutID]
+-- Customer.Customer (table)         [READ guard - IB check]
+-- Trade.Provider (table)            [READ guard - IsIB flag]
+-- History.Cashout (table)           [INSERT - initial status record]
+-- History.CashoutAction (table)     [INSERT - action=1 New record]
+-- Customer.SetBalance (procedure)   [EXEC - balance reservation (UpdateType=9)]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Cashout | Table | INSERT - creates pending cashout record; OUTPUT captures new CashoutID |
| Customer.Customer | Table | READ - IB account check (cross-schema) |
| Trade.Provider | Table | READ - IsIB=1 check (cross-schema) |
| History.Cashout | Table | INSERT - status transition record (initial, NewStatus=1) |
| History.CashoutAction | Table | INSERT - action record (action=1 New) |
| Customer.SetBalance | Stored Procedure | EXEC - reserves withdrawal amount from balance (UpdateType=9) |

### 6.2 Objects That Depend On This

No dependents found in Billing schema SP files. Called from application layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **OUTPUT clause for CashoutID**: Uses `INSERT ... OUTPUT INSERTED.CashoutID INTO @TempTable` pattern to capture the identity value generated for the new row. Returns it via @CashoutID OUTPUT parameter.
- **UpdateType=9 vs UpdateType=2**: CashoutRequestAdd uses UpdateType=9 (CashoutRequest - funds reserved but not yet paid). When the cashout is later processed via CashoutProcessTo*, Customer.SetBalance is called again with UpdateType=2 (Cashout - actual deduction). This two-step accounting matches the pending->processed lifecycle.
- **Lifecycle pairing**: This procedure is the "open" half; `Billing.CashoutReverse` (UpdateType=8, RETURN funds) and `Billing.CashoutProcess` (UpdateType=2, confirm deduction) are the "close" operations.
- **Legacy system**: Operates on Billing.Cashout (~5,931 rows from 2007-2011), not the modern Billing.Withdraw system.
- **IB guard consistency**: Same IB check (60015) as CashoutProcess - IB accounts are blocked from both creating and processing cashouts in this legacy flow.

---

## 8. Sample Queries

### 8.1 Add a cashout request (typical flow)
```sql
DECLARE @NewCashoutID INT;
EXEC Billing.CashoutRequestAdd
    @CID           = 100001,
    @Amount        = 500.00,
    @FundingTypeID = 1,        -- CreditCard
    @CurrencyID    = 1,        -- USD
    @ManagerID     = 99999,    -- system or ops manager
    @Description   = 'Customer withdrawal request',
    @CashoutID     = @NewCashoutID OUTPUT;
SELECT @NewCashoutID AS NewCashoutID;
```

### 8.2 Check pending cashout requests
```sql
SELECT c.CashoutID, c.CID, c.Amount, c.CurrencyID, c.FundingTypeID, c.RequestDate
FROM Billing.Cashout c WITH (NOLOCK)
WHERE c.CashoutStatusID = 1  -- Pending
ORDER BY c.RequestDate;
```

### 8.3 View the balance reservation in history
```sql
-- Check Customer.SetBalance created UpdateType=9 record
SELECT TOP 5 *
FROM History.CustomerMoney WITH (NOLOCK)
WHERE CID = 100001 AND UpdateType = 9
ORDER BY UpdateDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CashoutRequestAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CashoutRequestAdd.sql*
