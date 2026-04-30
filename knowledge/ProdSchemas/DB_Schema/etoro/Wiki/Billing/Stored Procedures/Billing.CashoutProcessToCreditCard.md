# Billing.CashoutProcessToCreditCard

> Credit card wrapper for Billing.CashoutProcess: processes a legacy cashout request as a credit card payment (FundingTypeID=1) and records the card and bank details in Billing.CreditCardToCashout.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 (success), RETURN @Answer (from CashoutProcess), RETURN @LocalError (SQL error) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CashoutProcessToCreditCard` is one of five payment-method-specific wrappers that call the core `Billing.CashoutProcess` procedure. It handles the case where the customer's cashout is being returned to a credit card.

The procedure adds to `Billing.CashoutProcess` (which handles the generic cashout work: status update, history, balance deduction) the credit-card-specific record: an entry in `Billing.CreditCardToCashout` linking the cashout to the specific CardID and the processing BankID.

This is a legacy procedure operating on the `Billing.Cashout` table (~2007-2011 era).

---

## 2. Business Logic

### 2.1 Wrapper Pattern

**What**: Calls CashoutProcess with FundingTypeID=1 (CreditCard), then inserts the card details.

**Rules**:
- All work is within `BEGIN TRANSACTION ... COMMIT/ROLLBACK`.
- `EXECUTE @Answer = Billing.CashoutProcess(@CashoutID, @ManagerID, @ProcessCurrencyID, @CashoutActionStatusID, 1, @ExchangeRate, @Description)` - FundingTypeID=1 hardcoded (Credit Card).
- If @Answer != 0 (CashoutProcess failed): RETURN @Answer immediately (no explicit rollback here - CashoutProcess rollbacks internally, but the outer transaction is still open).
- INSERT INTO Billing.CreditCardToCashout (CardID, CashoutID, BankID).
- On INSERT error: ROLLBACK TRANSACTION + RAISERROR(60000) + RETURN @LocalError.
- On success: COMMIT TRANSACTION + RETURN 0.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CashoutID | INTEGER | NO | - | CODE-BACKED | The cashout request to process. Passed to Billing.CashoutProcess and written to Billing.CreditCardToCashout.CashoutID. Must exist in Billing.Cashout. |
| 2 | @ManagerID | INTEGER | NO | - | CODE-BACKED | Operations manager authorizing the processing. Passed to Billing.CashoutProcess. |
| 3 | @ProcessCurrencyID | INTEGER | NO | - | CODE-BACKED | Currency in which the credit card payment was issued. Passed to Billing.CashoutProcess -> Billing.Cashout.ProcessCurrencyID. |
| 4 | @CashoutActionStatusID | INTEGER | NO | - | CODE-BACKED | Action status for history. Passed to CashoutProcess but not actually used (CashoutProcess hardcodes 2). Legacy parameter. |
| 5 | @CardID | INTEGER | NO | - | CODE-BACKED | The specific credit card (Billing.CreditCard.CardID) to which the cashout is being returned. Written to Billing.CreditCardToCashout.CardID. |
| 6 | @BankID | INTEGER | NO | - | CODE-BACKED | Bank processing the credit card payment. Written to Billing.CreditCardToCashout.BankID. References a bank/depot record. |
| 7 | @ExchangeRate | dbo.dtPrice | NO | - | CODE-BACKED | Exchange rate for currency conversion. Passed to Billing.CashoutProcess -> Billing.Cashout.ExchangeRate. |
| 8 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Description of the cashout processing action. Passed to CashoutProcess -> History.Cashout.Remark and Customer.SetBalance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CashoutID | Billing.CashoutProcess | EXEC (callee) | Core cashout processing (status update, history, balance debit) with FundingTypeID=1 |
| @CardID + @CashoutID | Billing.CreditCardToCashout | WRITER | Links the credit card to this cashout payment |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in Billing schema SP files. Called from operations back-office tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CashoutProcessToCreditCard (procedure)
+-- Billing.CashoutProcess (procedure)      [EXEC - core processing]
|   +-- Billing.Cashout (table)
|   +-- Customer.Customer, Trade.Provider   [IB guard]
|   +-- History.Cashout, History.CashoutAction
|   +-- Customer.SetBalance (procedure)
+-- Billing.CreditCardToCashout (table)     [INSERT - card-to-cashout mapping]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CashoutProcess | Stored Procedure | EXEC - handles all common cashout processing; called with FundingTypeID=1 |
| Billing.CreditCardToCashout | Table | INSERT - records which card processed this cashout |

### 6.2 Objects That Depend On This

No dependents found in Billing schema SP files.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **FundingTypeID=1 hardcoded**: This wrapper always sets CreditCard (1) as the funding type. The five wrappers each hardcode their specific type.
- **Nested transaction**: This procedure opens `BEGIN TRANSACTION` around the entire call including `EXEC Billing.CashoutProcess`, which itself uses `BEGIN TRANSACTION`. Nested transactions are supported in SQL Server (@@TRANCOUNT increments).
- **Part of a five-wrapper family**: See also CashoutProcessToNeteller (6), CashoutProcessToPayPal (3), CashoutProcessToWesternUnion (5), CashoutProcessToWireTransfer (2).

---

## 8. Sample Queries

### 8.1 Process a cashout via credit card
```sql
DECLARE @Answer INT;
EXEC @Answer = Billing.CashoutProcessToCreditCard
    @CashoutID             = 5000,
    @ManagerID             = 12345,
    @ProcessCurrencyID     = 1,
    @CashoutActionStatusID = 2,
    @CardID                = 9876,
    @BankID                = 42,
    @ExchangeRate          = 1.0,
    @Description           = 'Credit card refund approved';
SELECT @Answer AS ReturnCode;
```

### 8.2 Verify card-to-cashout link was created
```sql
SELECT c.CashoutID, c.CardID, c.BankID
FROM Billing.CreditCardToCashout c WITH (NOLOCK)
WHERE c.CashoutID = 5000;
```

### 8.3 View cashout processing history
```sql
SELECT hc.CashoutID, hc.PreviousCashoutStatusID, hc.NewCashoutStatusID, hc.UpdateDate, hc.Remark
FROM History.Cashout hc WITH (NOLOCK)
WHERE hc.CashoutID = 5000
ORDER BY hc.UpdateDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CashoutProcessToCreditCard | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CashoutProcessToCreditCard.sql*
