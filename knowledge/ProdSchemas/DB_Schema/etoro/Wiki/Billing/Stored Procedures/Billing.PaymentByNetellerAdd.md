# Billing.PaymentByNetellerAdd

> Creates a legacy Neteller e-wallet payment record, registering or linking the Neteller account and connecting it to the payment in a single atomic transaction; part of the pre-2011 Billing.Payment infrastructure.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PaymentID (OUTPUT - new identity from Billing.Payment) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PaymentByNetellerAdd` is the Neteller e-wallet deposit creation procedure for the legacy `Billing.Payment` system. It is the Neteller counterpart to `Billing.PaymentByCreditCardAdd`. When a customer made a Neteller deposit in the pre-2011 era, this procedure atomically recorded the payment, registered or located the Neteller account, and linked account to payment.

Unlike `PaymentByCreditCardAdd`, the `@FundingTypeID` is a caller-supplied parameter rather than a hardcode (1 = credit card in the CC variant). This allowed the Neteller flow to specify the appropriate funding type at call time. The Neteller account upsert is simpler than the card upsert - no CVV, no billing address, just AccountID and SecureID.

As with all `Billing.Payment` procedures, this is legacy infrastructure frozen since January 2011. The active Neteller deposit path (if any) now uses the `Billing.Deposit`/`Billing.Funding` tables.

---

## 2. Business Logic

### 2.1 Four-Table Atomic Transaction (Neteller Variant)

**What**: Payment, Neteller account upsert, NetellerToPayment link, and History entry - all or nothing.

**Parameters Involved**: All parameters

**Rules**:
- Step 1: Generate UTC timestamp and unique per-CID TransactionID (Billing.GetTransactionID())
- Step 2: INSERT Billing.Payment with caller-supplied FundingTypeID (no hardcode unlike PaymentByCreditCardAdd)
- Step 3: Neteller account upsert via AccountID:
  - NOT EXISTS: INSERT Billing.Neteller (SecureID, AccountID) -> @NetellerID = SCOPE_IDENTITY()
  - EXISTS: SELECT @NetellerID from Billing.Neteller WHERE AccountID = @AccountID
- Step 4: INSERT Billing.NetellerToPayment (NetellerID, PaymentID)
- Step 5: INSERT History.Payment (status snapshot)
- Any error -> ROLLBACK + RAISERROR(60000) + RETURN 60000; success -> SELECT @TransactionID + COMMIT + RETURN 0

**Comparison with PaymentByCreditCardAdd**:

| Feature | PaymentByCreditCardAdd | PaymentByNetellerAdd |
|---------|----------------------|---------------------|
| FundingTypeID | Hardcoded to 1 | Caller-supplied |
| Account upsert | CreditCard by CardNumber, with CVV | Neteller by AccountID, no CVV |
| Cardholder billing data | Full address, name, email | None |
| Linking table | Billing.CreditCardToPayment | Billing.NetellerToPayment |
| PaymentDate | Overwrites to GETUTCDATE() | Internally set to GETUTCDATE() |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentID | INTEGER | NO | - | CODE-BACKED | OUTPUT. New Billing.Payment IDENTITY. Caller uses this to correlate payment actions and responses. |
| 2 | @FundingTypeID | INTEGER | NO | - | CODE-BACKED | Funding method type. Unlike PaymentByCreditCardAdd (hardcoded=1), this is caller-supplied. FK to Dictionary.FundingType. Stored in Billing.Payment.FundingTypeID. |
| 3 | @CurrencyID | INTEGER | NO | - | CODE-BACKED | Currency of the Neteller deposit. FK to Dictionary.Currency. |
| 4 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Stored in Billing.Payment.CID. Used in TransactionID uniqueness check. |
| 5 | @PaymentStatusID | INTEGER | NO | - | CODE-BACKED | Initial payment status. FK to Dictionary.PaymentStatus. Stored in both Billing.Payment and History.Payment. |
| 6 | @PaymentTypeID | INTEGER | NO | - | CODE-BACKED | Payment method subtype. FK to Dictionary.PaymentType. |
| 7 | @TerminalID | INTEGER | NO | - | CODE-BACKED | Gateway terminal configuration. FK to Billing.Terminal. |
| 8 | @Amount | INTEGER | NO | - | CODE-BACKED | Deposit amount in smallest currency unit (cents). Stored in Billing.Payment.Amount as INTEGER. |
| 9 | @ExchangeRate | dtPrice | NO | - | CODE-BACKED | Exchange rate at time of deposit. User-defined decimal type. |
| 10 | @SecureID | NUMERIC(6,0) | NO | - | CODE-BACKED | Neteller 6-digit security PIN. Stored in Billing.Neteller.SecureID on new account registration. Required to authenticate Neteller fund movements. |
| 11 | @AccountID | NUMERIC(12,0) | NO | - | CODE-BACKED | Customer's Neteller account number (up to 12 digits). Used to look up or create the Billing.Neteller row. UNIQUE in Billing.Neteller - one registration per Neteller account number. |
| 12 | @IPAddress | NUMERIC(18,0) | NO | - | CODE-BACKED | Customer IP address encoded as numeric. Stored in Billing.Payment.IPAddress for fraud/geolocation. |
| 13 | RETURN value | INTEGER | - | - | CODE-BACKED | 0 = success (COMMIT). 60000 = any step failed (ROLLBACK + RAISERROR). |
| 14 | Result set | CHAR(6) | - | - | CODE-BACKED | SELECT @TransactionID on success - 6-char unique TransactionID for the caller to use in payment action correlation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | [Billing.Payment](../Tables/Billing.Payment.md) | WRITER | Creates the legacy payment record |
| @AccountID upsert | [Billing.Neteller](../Tables/Billing.Neteller.md) | WRITER | Registers Neteller account if not already present |
| INSERT | Billing.NetellerToPayment | WRITER | Links Neteller account to the payment |
| INSERT | History.Payment | WRITER | Initial status snapshot |
| TransactionID | Billing.GetTransactionID() | Function call | Generates unique 6-char TransactionID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application billing service (external) | - | EXEC caller | Legacy Neteller deposit creation flow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PaymentByNetellerAdd (procedure)
├── Billing.Payment (table)
├── Billing.Neteller (table)
├── Billing.NetellerToPayment (table)
├── History.Payment (table)
└── Billing.GetTransactionID (function)
      └── Billing.GenTransactionID (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.Payment](../Tables/Billing.Payment.md) | Table | INSERT - main payment record |
| [Billing.Neteller](../Tables/Billing.Neteller.md) | Table | SELECT (lookup) + INSERT (new account registration) |
| Billing.NetellerToPayment | Table | INSERT - links Neteller account to payment |
| History.Payment | Table | INSERT - status log entry at payment creation |
| Billing.GetTransactionID | Function | Generates per-CID-unique 6-char TransactionID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application billing service (external) | Application | Legacy Neteller payment creation flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Transaction rolls back with RAISERROR(60000) on any error.

---

## 8. Sample Queries

### 8.1 Find legacy Neteller payments with account details

```sql
SELECT
    bp.PaymentID,
    bp.CID,
    bp.Amount,
    bp.PaymentDate,
    bp.TransactionID,
    n.AccountID,
    n.SecureID
FROM Billing.Payment bp WITH (NOLOCK)
INNER JOIN Billing.NetellerToPayment ntp WITH (NOLOCK) ON ntp.PaymentID = bp.PaymentID
INNER JOIN Billing.Neteller n WITH (NOLOCK) ON n.NetellerID = ntp.NetellerID
WHERE bp.CID = 123456
ORDER BY bp.PaymentDate DESC;
```

### 8.2 Count legacy Neteller payments by status

```sql
SELECT
    ps.Name AS PaymentStatus,
    COUNT(*) AS PaymentCount,
    SUM(bp.Amount) AS TotalAmount
FROM Billing.Payment bp WITH (NOLOCK)
INNER JOIN Billing.NetellerToPayment ntp WITH (NOLOCK) ON ntp.PaymentID = bp.PaymentID
INNER JOIN Dictionary.PaymentStatus ps WITH (NOLOCK) ON ps.PaymentStatusID = bp.PaymentStatusID
GROUP BY ps.Name
ORDER BY PaymentCount DESC;
```

### 8.3 Find Neteller accounts used in legacy payments

```sql
SELECT
    n.NetellerID,
    n.AccountID,
    COUNT(ntp.PaymentID) AS LegacyPaymentCount
FROM Billing.Neteller n WITH (NOLOCK)
INNER JOIN Billing.NetellerToPayment ntp WITH (NOLOCK) ON ntp.NetellerID = n.NetellerID
GROUP BY n.NetellerID, n.AccountID
ORDER BY LegacyPaymentCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PaymentByNetellerAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PaymentByNetellerAdd.sql*
