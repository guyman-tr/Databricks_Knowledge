# Billing.CashoutProcess

> Core legacy cashout processing procedure that sets a cashout request to Processed (status=3), records the exchange rate and payment method, writes status history, and calls Customer.SetBalance to execute the actual balance deduction - called by all CashoutProcessTo* wrappers.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 (success), RETURN 60015 (IB account), RETURN 60000 (invalid/error), RETURN @Answer (SetBalance error) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CashoutProcess` is the central procedure for processing a legacy cashout request (from `Billing.Cashout`, eToro's original ~2007-2011 withdrawal system). When an operations manager decides to process a pending cashout, this procedure is called to:
1. Update the cashout record to status 3 (Processed)
2. Record the processing currency and exchange rate
3. Log the transition in History.Cashout and History.CashoutAction
4. Debit the customer's balance via `Customer.SetBalance` (UpdateType=2, Cashout)

This procedure is never called directly by external callers; it is always wrapped by one of five payment-method-specific procedures: `CashoutProcessToCreditCard`, `CashoutProcessToNeteller`, `CashoutProcessToPayPal`, `CashoutProcessToWesternUnion`, `CashoutProcessToWireTransfer`. Each wrapper calls this procedure to do the common work and then adds the payment-method-specific record.

Note: This operates on the legacy `Billing.Cashout` table (5,931 rows), not the modern `Billing.Withdraw` table.

---

## 2. Business Logic

### 2.1 Cashout Processing Flow

**What**: Atomically processes a cashout request within a transaction, deducting the customer's balance.

**Columns/Parameters Involved**: `@CashoutID`, `@CashoutActionStatusID`, `@ProcessCurrencyID`, `@FundingTypeID`, `@ExchangeRate`

**Rules**:
- **Guard 1 - IB account block**: If the customer is an Introducing Broker (Trade.Provider.IsIB=1), RAISERROR(60015) and RETURN. IB accounts cannot be cashed out through this flow.
- **Guard 2 - Already processed**: If `Billing.Cashout.CashoutStatusID = 3` for this @CashoutID, RAISERROR(60000) and RETURN 60000. Prevents double-processing.
- **UPDATE Billing.Cashout**: Sets CashoutStatusID=3 (comment: "proccessed"), ProcessCurrencyID, FundingTypeID, ExchangeRate. Outputs CID, old CashoutStatusID, Amount to @Info table variable.
- **INSERT History.Cashout**: Records previous->new status transition (3) with UpdateDate=GETDATE() and @Description as Remark.
- **INSERT History.CashoutAction**: CashoutActionStatusID=2 (comment: "processed"), FundingTypeID, Amount, ActionDate=GETDATE().
- **EXEC Customer.SetBalance**: Called with @CID, @Amount, UpdateType=2 (Cashout), @Description, @ManagerID, PositionID=NULL, UpdateID=NULL, @CashoutID. This deducts the amount from the customer's balance.

```
CashoutProcessToXxx(@CashoutID, ..., FundingTypeID=N, ...)
  -> EXEC Billing.CashoutProcess(@CashoutID, FundingTypeID=N, ...)
       Guard: IsIB? -> RETURN 60015
       Guard: already processed? -> RETURN 60000
       BEGIN TRANSACTION
         UPDATE Billing.Cashout SET CashoutStatusID=3, ProcessCurrencyID, FundingTypeID, ExchangeRate
         INSERT History.Cashout (prev->3, remark=@Description)
         INSERT History.CashoutAction (status=2 "processed")
         EXEC Customer.SetBalance(@CID, @Amount, 2, ...)
       COMMIT
  -> INSERT Billing.{Method}ToCashout (payment method specific record)
```

### 2.2 Error Handling

**What**: Transactional rollback on any step failure.

**Rules**:
- Each INSERT/UPDATE checks @@ERROR; on non-zero: ROLLBACK TRANSACTION + RAISERROR(60000) + RETURN.
- If UPDATE affects 0 rows (CashoutID not found): treated as error 60000.
- If Customer.SetBalance returns non-zero: RETURN @Answer (propagates balance error without explicit rollback here - the outer wrapper handles the transaction).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CashoutID | INTEGER | NO | - | CODE-BACKED | The cashout request to process. Must exist in Billing.Cashout and must not already be in status 3 (processed). References Billing.Cashout.CashoutID. |
| 2 | @ManagerID | INTEGER | NO | - | CODE-BACKED | ID of the operations manager processing this cashout. Passed to Customer.SetBalance as the authorizing manager. Not stored directly on Billing.Cashout by this procedure. |
| 3 | @ProcessCurrencyID | INTEGER | NO | - | CODE-BACKED | Currency in which the payment was actually issued to the customer. May differ from Billing.Cashout.CurrencyID if the payment provider uses a different currency. Written to Billing.Cashout.ProcessCurrencyID. References Dictionary.Currency. |
| 4 | @CashoutActionStatusID | INTEGER | NO | - | CODE-BACKED | Status code for the History.CashoutAction entry. The procedure hardcodes 2 ("processed") in the INSERT - this parameter is declared but NOT actually used in the logic. Likely legacy parameter retained for API compatibility. |
| 5 | @FundingTypeID | INTEGER | NO | - | CODE-BACKED | Payment method used for the cashout (1=CreditCard, 2=WireTransfer, 3=PayPal, 5=WesternUnion, 6=Neteller). Set by the calling CashoutProcessTo* wrapper. Written to Billing.Cashout.FundingTypeID and History.CashoutAction.FundingTypeID. |
| 6 | @ExchangeRate | dbo.dtPrice | NO | - | CODE-BACKED | Exchange rate applied when converting between the customer's currency and the processing currency. Uses the dbo.dtPrice user-defined type (decimal precision for price data). Written to Billing.Cashout.ExchangeRate. NULL if no conversion needed (dtPrice is nullable in the table). |
| 7 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Free-text description of the processing action. Stored as the Remark in History.Cashout. Also passed to Customer.SetBalance as the balance update description for audit trail. Max 255 characters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CashoutID | Billing.Cashout | READER + MODIFIER | Reads for guard checks; updates CashoutStatusID, ProcessCurrencyID, FundingTypeID, ExchangeRate |
| CID (from Billing.Cashout) | Customer.Customer | READ (JOIN guard) | Joins to verify customer is not an IB |
| - | Trade.Provider | READ (JOIN guard) | Joins to Customer.Customer to check IsIB flag |
| @CashoutID | History.Cashout | WRITER | Inserts status transition record |
| @CashoutID | History.CashoutAction | WRITER | Inserts action record (status=2 processed) |
| @CID | Customer.SetBalance | EXEC | Deducts cashout amount from customer balance (UpdateType=2) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CashoutProcessToCreditCard | EXEC | Caller | Wraps this with FundingTypeID=1, adds CreditCardToCashout record |
| Billing.CashoutProcessToNeteller | EXEC | Caller | Wraps with FundingTypeID=6, adds NetellerToCashout record |
| Billing.CashoutProcessToPayPal | EXEC | Caller | Wraps with FundingTypeID=3, adds PayPalToCashout record |
| Billing.CashoutProcessToWesternUnion | EXEC | Caller | Wraps with FundingTypeID=5, adds WesternUnionToCashout record |
| Billing.CashoutProcessToWireTransfer | EXEC | Caller | Wraps with FundingTypeID=2, adds WireTransferToCashout record |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CashoutProcess (procedure)
+-- Billing.Cashout (table)           [READ guard + UPDATE - core cashout record]
+-- Customer.Customer (table)         [READ guard - IB check]
+-- Trade.Provider (table)            [READ guard - IsIB flag]
+-- History.Cashout (table)           [INSERT - status transition log]
+-- History.CashoutAction (table)     [INSERT - action log]
+-- Customer.SetBalance (procedure)   [EXEC - balance deduction, UpdateType=2]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Cashout | Table | READ guard + UPDATE (status, ProcessCurrencyID, FundingTypeID, ExchangeRate) |
| Customer.Customer | Table | READ - IB account check (cross-schema) |
| Trade.Provider | Table | READ - IsIB=1 check (cross-schema) |
| History.Cashout | Table | INSERT - status transition audit record |
| History.CashoutAction | Table | INSERT - action audit record (status=2 processed) |
| Customer.SetBalance | Stored Procedure | EXEC - performs the actual balance deduction (cross-schema) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CashoutProcessToCreditCard | Stored Procedure | Caller - credit card cashout wrapper |
| Billing.CashoutProcessToNeteller | Stored Procedure | Caller - Neteller cashout wrapper |
| Billing.CashoutProcessToPayPal | Stored Procedure | Caller - PayPal cashout wrapper |
| Billing.CashoutProcessToWesternUnion | Stored Procedure | Caller - Western Union cashout wrapper |
| Billing.CashoutProcessToWireTransfer | Stored Procedure | Caller - wire transfer cashout wrapper |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **@CashoutActionStatusID is unused**: The parameter is declared but the INSERT to History.CashoutAction hardcodes `2` (processed). This is a legacy API artifact.
- **CashoutStatusID=3 hardcoded**: The processed status is hardcoded as `3` in both the guard check and the UPDATE.
- **Customer.SetBalance UpdateType=2**: Documented in Billing.Cashout as "Cashout" balance update type.
- **Nested transaction context**: Called inside `BEGIN TRANSACTION` from the wrappers. The rollback logic here handles errors before SetBalance; after SetBalance, the outer wrapper rolls back if @Answer != 0.
- **Legacy system**: Operates on Billing.Cashout (~5,931 rows from 2007-2011), not the modern Billing.Withdraw.

---

## 8. Sample Queries

### 8.1 Process a cashout via credit card wrapper (typical usage)
```sql
-- Use the wrapper, not this procedure directly
DECLARE @Answer INT;
EXEC @Answer = Billing.CashoutProcessToCreditCard
    @CashoutID            = 5000,
    @ManagerID            = 12345,
    @ProcessCurrencyID    = 1,       -- USD
    @CashoutActionStatusID = 2,
    @CardID               = 9876,
    @BankID               = 42,
    @ExchangeRate         = 1.0,
    @Description          = 'Approved by ops manager';
SELECT @Answer AS ReturnCode;
```

### 8.2 Check current status of a cashout before processing
```sql
SELECT c.CashoutID, c.CID, c.CashoutStatusID, c.Amount, c.FundingTypeID,
       c.RequestDate, c.ProcessCurrencyID, c.ExchangeRate,
       cs.Name AS StatusName
FROM Billing.Cashout c WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON cs.CashoutStatusID = c.CashoutStatusID
WHERE c.CashoutStatusID IN (1, 2)  -- Pending or InProcess only
ORDER BY c.RequestDate;
```

### 8.3 View processing history for a cashout
```sql
SELECT hc.CashoutID, hc.PreviousCashoutStatusID, hc.NewCashoutStatusID,
       hc.UpdateDate, hc.Remark
FROM History.Cashout hc WITH (NOLOCK)
WHERE hc.CashoutID = 5000
ORDER BY hc.UpdateDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CashoutProcess | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CashoutProcess.sql*
