# Billing.PaymentByPayPalAdd

> Creates a legacy PayPal payment record, registering or linking the PayPal account by email address; part of the pre-2011 Billing.Payment infrastructure. Notable: unlike the Neteller and credit card variants, this procedure has no explicit transaction wrapper.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PaymentID (OUTPUT - new identity from Billing.Payment) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PaymentByPayPalAdd` is the PayPal deposit creation procedure for the legacy `Billing.Payment` system. It is the PayPal counterpart to `Billing.PaymentByNetellerAdd` and `Billing.PaymentByCreditCardAdd`. When a customer made a PayPal deposit in the pre-2011 era, this procedure recorded the payment and registered or linked the PayPal account by its email address.

The procedure has two notable differences from its sibling variants:
1. **FundingTypeID=3 is hardcoded** (PayPal, same pattern as FundingTypeID=1 for credit cards)
2. **No explicit BEGIN TRANSACTION / ROLLBACK** - the four inserts (Payment, PayPal upsert, PayPalToPayment, History.Payment) run without an explicit transaction wrapper. This contrasts with `PaymentByCreditCardAdd` and `PaymentByNetellerAdd` which both use atomic transactions with full ROLLBACK on error. The PayPal variant was likely written in an earlier style without this safety net.

As with all `Billing.Payment` procedures, this is legacy infrastructure frozen since January 2011.

---

## 2. Business Logic

### 2.1 Four-Insert Flow (No Transaction Wrapper)

**What**: Creates the payment, upserts the PayPal account, links them, and logs history - without explicit transaction protection.

**Parameters Involved**: All parameters

**Rules**:
- @PaymentDate passed by caller is overwritten by GETUTCDATE() inside (same pattern as PaymentByCreditCardAdd)
- FundingTypeID=3 hardcoded (PayPal)
- PayPal upsert: SELECT by @PayPalEmailAccount - if NULL: INSERT Billing.PayPal; if found: reuse existing @PayPalID
- INSERT Billing.PayPalToPayment (PayPalID, PaymentID)
- INSERT History.Payment (status snapshot)
- SELECT @TransactionID + RETURN 0 (always - no error code propagation)
- **NO BEGIN TRANSACTION**: if the PayPal INSERT or History.Payment INSERT fails, the Billing.Payment row may remain orphaned

### 2.2 Comparison with Sibling Payment Procedures

| Feature | PaymentByCreditCardAdd | PaymentByNetellerAdd | PaymentByPayPalAdd |
|---------|----------------------|---------------------|---------------------|
| FundingTypeID | Hardcoded: 1 | Caller-supplied | Hardcoded: 3 |
| Transaction | BEGIN/COMMIT/ROLLBACK | BEGIN/COMMIT/ROLLBACK | None |
| Error handling | ROLLBACK + error codes | ROLLBACK + error codes | None (RETURN 0 always) |
| Account identifier | CardNumber (hash) | AccountID (numeric) | PayPalEmailAccount (email) |
| Account data | CardTypeID + CVV | SecureID | Email only |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentID | INTEGER | NO | - | CODE-BACKED | OUTPUT. New Billing.Payment IDENTITY. |
| 2 | @CurrencyID | INTEGER | NO | - | CODE-BACKED | Currency of the PayPal deposit. FK to Dictionary.Currency. |
| 3 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Stored in Billing.Payment.CID. Used in TransactionID uniqueness check. |
| 4 | @PaymentStatusID | INTEGER | NO | - | CODE-BACKED | Initial payment status. FK to Dictionary.PaymentStatus. |
| 5 | @PaymentTypeID | INTEGER | NO | - | CODE-BACKED | Payment method subtype. FK to Dictionary.PaymentType. |
| 6 | @TerminalID | INTEGER | NO | - | CODE-BACKED | Gateway terminal. FK to Billing.Terminal. |
| 7 | @Amount | INTEGER | NO | - | CODE-BACKED | Deposit amount in smallest currency unit (cents). |
| 8 | @ExchangeRate | dtPrice | NO | - | CODE-BACKED | Exchange rate at deposit time. User-defined decimal type. |
| 9 | @PaymentDate | DATETIME | NO | - | CODE-BACKED | IGNORED - overwritten by GETUTCDATE() (SET @PaymentDate = GETUTCDATE() line 27). Parameter exists for API compatibility only. |
| 10 | @IPAddress | NUMERIC(18,0) | NO | - | CODE-BACKED | Customer IP address as numeric. Stored in Billing.Payment.IPAddress. |
| 11 | @PayPalEmailAccount | VARCHAR(250) | NO | - | CODE-BACKED | The customer's PayPal email address. Used to look up or create the Billing.PayPal row. Identifies the PayPal account uniquely. |
| 12 | RETURN value | INTEGER | - | 0 | CODE-BACKED | Always returns 0. No error propagation - procedure has no error handling (unlike CC and Neteller variants). |
| 13 | Result set | CHAR(6) | - | - | CODE-BACKED | SELECT @TransactionID - 6-char unique internal TransactionID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | [Billing.Payment](../Tables/Billing.Payment.md) | WRITER | Creates legacy payment record with FundingTypeID=3 (PayPal) |
| @PayPalEmailAccount upsert | Billing.PayPal | WRITER | Registers or reuses PayPal account by email |
| INSERT | Billing.PayPalToPayment | WRITER | Links PayPal account to payment |
| INSERT | History.Payment | WRITER | Status snapshot log |
| TransactionID | Billing.GetTransactionID() | Function call | Generates unique 6-char TransactionID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application billing service (external) | - | EXEC caller | Legacy PayPal deposit creation flow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PaymentByPayPalAdd (procedure)
├── Billing.Payment (table)
├── Billing.PayPal (table)
├── Billing.PayPalToPayment (table)
├── History.Payment (table)
└── Billing.GetTransactionID (function)
      └── Billing.GenTransactionID (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.Payment](../Tables/Billing.Payment.md) | Table | INSERT - main payment record |
| Billing.PayPal | Table | SELECT (lookup by email) + INSERT (new account) |
| Billing.PayPalToPayment | Table | INSERT - links PayPal to payment |
| History.Payment | Table | INSERT - status log |
| Billing.GetTransactionID | Function | Generates unique 6-char TransactionID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application billing service (external) | Application | Legacy PayPal payment creation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. **No explicit transaction**: partial failure leaves orphaned Payment rows. This is a known design gap compared to the CC and Neteller variants.

---

## 8. Sample Queries

### 8.1 Find legacy PayPal payments by email

```sql
SELECT
    bp.PaymentID,
    bp.CID,
    bp.Amount,
    bp.PaymentDate,
    bp.TransactionID,
    pp.PayPalEmailAccount
FROM Billing.Payment bp WITH (NOLOCK)
INNER JOIN Billing.PayPalToPayment pptp WITH (NOLOCK) ON pptp.PaymentID = bp.PaymentID
INNER JOIN Billing.PayPal pp WITH (NOLOCK) ON pp.PayPalID = pptp.PayPalID
WHERE pp.PayPalEmailAccount = 'customer@example.com'
ORDER BY bp.PaymentDate DESC;
```

### 8.2 List all legacy PayPal accounts with payment counts

```sql
SELECT
    pp.PayPalID,
    pp.PayPalEmailAccount,
    COUNT(pptp.PaymentID) AS PaymentCount,
    SUM(bp.Amount) AS TotalAmount
FROM Billing.PayPal pp WITH (NOLOCK)
INNER JOIN Billing.PayPalToPayment pptp WITH (NOLOCK) ON pptp.PayPalID = pp.PayPalID
INNER JOIN Billing.Payment bp WITH (NOLOCK) ON bp.PaymentID = pptp.PaymentID
GROUP BY pp.PayPalID, pp.PayPalEmailAccount
ORDER BY PaymentCount DESC;
```

### 8.3 Find legacy PayPal payments missing their linking record (orphan detection)

```sql
SELECT bp.PaymentID, bp.CID, bp.FundingTypeID, bp.PaymentDate
FROM Billing.Payment bp WITH (NOLOCK)
WHERE bp.FundingTypeID = 3  -- PayPal
  AND NOT EXISTS (
      SELECT 1 FROM Billing.PayPalToPayment pptp WITH (NOLOCK)
      WHERE pptp.PaymentID = bp.PaymentID
  )
ORDER BY bp.PaymentDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.9/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PaymentByPayPalAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PaymentByPayPalAdd.sql*
