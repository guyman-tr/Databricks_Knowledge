# Billing.PaymentByPayPalProcess

> Processes a confirmed PayPal deposit by marking it Approved and crediting the customer's account balance; orchestrates DepositUpdate and AmountAdd in a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID (the PayPal deposit being settled) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PaymentByPayPalProcess` is the PayPal settlement procedure. When PayPal sends a payment confirmation callback (IPN - Instant Payment Notification), this procedure is called to finalize the deposit: it marks the deposit as Approved, records the PayPal postback action, and credits the customer's USD account with the deposit amount (converted using the current exchange rate).

The procedure represents the completion of a two-phase PayPal deposit flow: the deposit is first created in "Pending" status (PaymentStatusID=13) via the legacy `PaymentByPayPalAdd` or current Deposit creation flow, then this procedure confirms it when PayPal's callback arrives.

Unlike the other PaymentBy* procedures (which target the legacy `Billing.Payment` table), this procedure works on the current `Billing.Deposit` system - it accepts a `@DepositID` (not a `@PaymentID`). It validates that the deposit is truly a PayPal deposit in Pending status before proceeding, preventing accidental processing of non-PayPal or already-processed deposits.

---

## 2. Business Logic

### 2.1 PayPal Settlement Flow

**What**: Two-phase PayPal completion: validate -> update deposit status -> credit customer account.

**Parameters Involved**: `@DepositID`, `@ManagerID`, `@ExchangeRate`

**Pre-condition**: Deposit must be:
- `Billing.Funding.FundingTypeID = 3` (PayPal)
- `Billing.Deposit.PaymentStatusID = 13` (Pending)

**If pre-condition fails**: RAISERROR(60025, "Invalid Deposit") + RETURN 60025

**Steps (within one transaction)**:
1. Read `PaymentData` XML from Billing.Deposit and `ProtocolID` from Billing.Depot for FundingTypeID=3
2. EXEC `Billing.DepositUpdate` with:
   - PaymentStatusID=2 (Approved)
   - PaymentActionStatusID=3 (Closed)
   - PaymentActionTypeID=6 (Postback - the PayPal IPN callback)
3. Calculate amount: `ROUND(Amount * @ExchangeRate, 0)` - converts deposit currency to USD
4. EXEC `Billing.AmountAdd` with:
   - CurrencyID=1 (USD)
   - AccountTypeID=1 (Deposit)
   - Description='Pay Pal payment cleared'
5. COMMIT on both success / ROLLBACK if either fails

**Diagram**:
```
PayPal IPN callback received
           |
           v
Billing.PaymentByPayPalProcess(@DepositID, @ManagerID, @ExchangeRate)
           |
  Validate: FundingTypeID=3 AND PaymentStatusID=13 (Pending)?
           |
   YES -> BEGIN TRANSACTION
           |
    Billing.DepositUpdate(Approved, Closed, Postback, @ProtocolID)
           |
    Amount = ROUND(Deposit.Amount * @ExchangeRate, 0) -> USD
           |
    Billing.AmountAdd(CID, USD, Deposit, Amount, 'Pay Pal payment cleared')
           |
   COMMIT TRANSACTION -> RETURN 0
```

### 2.2 Exchange Rate Conversion

**What**: Deposit amount is converted from deposit currency to USD before crediting.

**Parameters Involved**: `@ExchangeRate`, Billing.Deposit.Amount

**Rules**:
- `@Amount = ROUND(Billing.Deposit.Amount * @ExchangeRate, 0)` - multiplied and rounded to integer cents
- The @ExchangeRate is passed by the caller (not looked up from Billing.Deposit.ExchangeRate) - caller provides the rate at time of processing (may differ from rate at deposit creation)
- Result is in USD (CurrencyID=1) regardless of deposit currency

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INTEGER | NO | - | VERIFIED | The Billing.Deposit record to process. Must be a PayPal deposit (FundingTypeID=3) in Pending status (PaymentStatusID=13). Error 60025 if not found or wrong status. |
| 2 | @ManagerID | INTEGER | NO | - | CODE-BACKED | ID of the operator/manager processing this PayPal callback. Passed to Billing.DepositUpdate and Billing.AmountAdd for audit trail attribution. |
| 3 | @ExchangeRate | dtPrice | NO | - | CODE-BACKED | Exchange rate used to convert the deposit amount to USD. Applied as: ROUND(Deposit.Amount * @ExchangeRate, 0). Provided by the caller at processing time - may differ from the rate stored in Billing.Deposit at creation. |
| 4 | RETURN value | INTEGER | - | - | VERIFIED | 0 = success (COMMIT). 60025 = deposit not found or not in valid state (PayPal + Pending). Non-zero = error propagated from DepositUpdate or AmountAdd. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID validate + read | Billing.Deposit | READ | Validates PayPal/Pending status; reads Amount and PaymentData |
| @DepositID via FundingID | Billing.Funding | JOIN | Validates FundingTypeID=3 (PayPal) |
| FundingTypeID=3 | Billing.Depot | READ | Retrieves ProtocolID for PayPal processing |
| Settlement | Billing.DepositUpdate | EXEC | Marks deposit Approved (status=2), records Postback (ActionType=6) |
| Credit | Billing.AmountAdd | EXEC | Credits customer USD account with converted deposit amount |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application billing service (external) | - | EXEC caller | Called when PayPal IPN (Instant Payment Notification) is received |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PaymentByPayPalProcess (procedure)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Billing.Depot (table)
├── Billing.DepositUpdate (procedure)
└── Billing.AmountAdd (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | READ - validates status, reads Amount and PaymentData XML |
| Billing.Funding | Table | JOIN - validates FundingTypeID=3 (PayPal) |
| Billing.Depot | Table | READ - retrieves ProtocolID for FundingTypeID=3 |
| Billing.DepositUpdate | Procedure | Called to mark deposit Approved and record Postback action |
| Billing.AmountAdd | Procedure | Called to credit customer USD account with settled amount |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application billing service (external) | Application | Called on PayPal IPN confirmation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Validation guard: deposit must be PayPal + Pending before transaction starts. Both EXEC calls propagate errors - if either fails the transaction is rolled back.

---

## 8. Sample Queries

### 8.1 Find pending PayPal deposits awaiting processing

```sql
SELECT
    bd.DepositID,
    bd.CID,
    bd.Amount,
    bd.PaymentDate,
    bd.PaymentStatusID,
    ps.Name AS Status
FROM Billing.Deposit bd WITH (NOLOCK)
INNER JOIN Billing.Funding bf WITH (NOLOCK) ON bf.FundingID = bd.FundingID
INNER JOIN Dictionary.PaymentStatus ps WITH (NOLOCK) ON ps.PaymentStatusID = bd.PaymentStatusID
WHERE bf.FundingTypeID = 3   -- PayPal
  AND bd.PaymentStatusID = 13 -- Pending
ORDER BY bd.PaymentDate;
```

### 8.2 Verify a PayPal deposit was processed (Approved)

```sql
SELECT
    bd.DepositID,
    bd.CID,
    bd.Amount,
    bd.PaymentDate,
    ps.Name AS Status,
    bd.ExchangeRate
FROM Billing.Deposit bd WITH (NOLOCK)
INNER JOIN Billing.Funding bf WITH (NOLOCK) ON bf.FundingID = bd.FundingID
INNER JOIN Dictionary.PaymentStatus ps WITH (NOLOCK) ON ps.PaymentStatusID = bd.PaymentStatusID
WHERE bd.DepositID = 12345
  AND bf.FundingTypeID = 3;
```

### 8.3 List all PayPal deposits with their processing outcome

```sql
SELECT
    bd.DepositID,
    bd.CID,
    bd.Amount,
    bd.PaymentDate,
    ps.Name AS Status,
    bd.ExchangeRate
FROM Billing.Deposit bd WITH (NOLOCK)
INNER JOIN Billing.Funding bf WITH (NOLOCK) ON bf.FundingID = bd.FundingID
INNER JOIN Dictionary.PaymentStatus ps WITH (NOLOCK) ON ps.PaymentStatusID = bd.PaymentStatusID
WHERE bf.FundingTypeID = 3
ORDER BY bd.PaymentDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PaymentByPayPalProcess | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PaymentByPayPalProcess.sql*
