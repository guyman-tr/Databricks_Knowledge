# Billing.PaymentByWesternUnionAdd

> Creates a legacy Western Union cash transfer payment record, storing the MTCN (Money Transfer Control Number) and sender location details in an atomic transaction.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PaymentID (OUTPUT - new identity from Billing.Payment) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PaymentByWesternUnionAdd` is the Western Union cash transfer deposit creation procedure for the legacy `Billing.Payment` system. When a customer sent funds via Western Union in the pre-2011 era, a customer service representative would record the payment using this procedure, storing the Western Union MTCN (Money Transfer Control Number) - the unique reference that identifies the physical cash transfer at the Western Union network - along with the country and city where the transfer was sent.

The MTCN is the essential Western Union identifier: it allows eToro operations to verify the transfer with Western Union's systems and confirm receipt of funds. Without the MTCN, a Western Union payment cannot be verified or reconciled.

This is the only payment variant that captures the physical location of the sender (CountryID + City) - required because Western Union operations use the sending location for fraud detection and compliance purposes.

Like all `Billing.Payment` procedures, this is legacy infrastructure frozen since January 2011.

---

## 2. Business Logic

### 2.1 Three-Table Atomic Transaction (Western Union Variant)

**What**: Creates payment, records MTCN and sending location, logs history - atomically.

**Parameters Involved**: All parameters

**Rules**:
- @PaymentDate overwritten by GETUTCDATE() (same pattern as other Payment variants)
- FundingTypeID=5 hardcoded (Western Union)
- INSERT Billing.Payment -> @PaymentID = SCOPE_IDENTITY()
- INSERT Billing.WesternUnionToPayment (PaymentID, CountryID, MTCN, City) - no intermediate error check
- INSERT History.Payment (status snapshot) - error checked here
- ROLLBACK on Payment INSERT error (returns raw @@ERROR, not fixed code 60000)
- Returns raw @@ERROR (SQL Server error number) vs. RAISERROR(60000) used in PaymentByCreditCardAdd
- SELECT @TransactionID + COMMIT + RETURN 0 on success

### 2.2 FundingType Map for Legacy Payment Variants

| FundingTypeID | Payment Method | Hardcoded In |
|---|---|---|
| 1 | Credit Card | PaymentByCreditCardAdd |
| 3 | PayPal | PaymentByPayPalAdd |
| 5 | Western Union | PaymentByWesternUnionAdd (this proc) |
| - | Neteller | PaymentByNetellerAdd (@FundingTypeID = caller-supplied) |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentID | INTEGER | NO | - | CODE-BACKED | OUTPUT. New Billing.Payment IDENTITY. |
| 2 | @CurrencyID | INTEGER | NO | - | CODE-BACKED | Currency of the Western Union transfer. FK to Dictionary.Currency. |
| 3 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Used in TransactionID uniqueness check and stored in Billing.Payment.CID. |
| 4 | @PaymentStatusID | INTEGER | NO | - | CODE-BACKED | Initial payment status. FK to Dictionary.PaymentStatus. |
| 5 | @PaymentTypeID | INTEGER | NO | - | CODE-BACKED | Payment method subtype. FK to Dictionary.PaymentType. |
| 6 | @TerminalID | INTEGER | NO | - | CODE-BACKED | Gateway terminal configuration. FK to Billing.Terminal. |
| 7 | @Amount | INTEGER | NO | - | CODE-BACKED | Transfer amount in smallest currency unit (cents). |
| 8 | @ExchangeRate | dtPrice | NO | - | CODE-BACKED | Exchange rate at deposit creation time. |
| 9 | @PaymentDate | DATETIME | NO | - | CODE-BACKED | IGNORED - overwritten by GETUTCDATE() at line 27. Parameter exists for API compatibility only. |
| 10 | @IPAddress | NUMERIC(18,0) | NO | - | CODE-BACKED | Customer IP address as numeric. Stored in Billing.Payment.IPAddress. |
| 11 | @MTCN | VARCHAR(15) | NO | - | CODE-BACKED | Money Transfer Control Number - Western Union's unique 10-digit transfer reference (up to 15 chars stored). Stored in Billing.WesternUnionToPayment.MTCN. Essential for verifying the cash transfer with Western Union's systems. |
| 12 | @CountryID | INTEGER | NO | - | CODE-BACKED | Country where the Western Union transfer was sent from. FK to Dictionary.Country. Stored in Billing.WesternUnionToPayment.CountryID. Used for fraud detection and compliance. |
| 13 | @City | VARCHAR(50) | NO | - | CODE-BACKED | City where the Western Union transfer was sent from. Stored in Billing.WesternUnionToPayment.City. Combined with CountryID to identify the sending Western Union agent location. |
| 14 | RETURN value | INTEGER | - | - | CODE-BACKED | 0 = success. Non-zero = raw SQL Server @@ERROR code (unlike CC variant which uses fixed code 60000). Payment INSERT errors and History.Payment INSERT errors return the raw error number. |
| 15 | Result set | CHAR(6) | - | - | CODE-BACKED | SELECT @TransactionID on success - 6-char unique internal TransactionID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | [Billing.Payment](../Tables/Billing.Payment.md) | WRITER | Creates legacy payment record with FundingTypeID=5 (Western Union) |
| @MTCN, @CountryID, @City | Billing.WesternUnionToPayment | WRITER | Stores transfer reference and sender location details |
| INSERT | History.Payment | WRITER | Status snapshot log |
| TransactionID | Billing.GetTransactionID() | Function call | Generates unique 6-char TransactionID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application billing service (external) | - | EXEC caller | Legacy Western Union deposit entry by customer service |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PaymentByWesternUnionAdd (procedure)
├── Billing.Payment (table)
├── Billing.WesternUnionToPayment (table)
├── History.Payment (table)
└── Billing.GetTransactionID (function)
      └── Billing.GenTransactionID (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.Payment](../Tables/Billing.Payment.md) | Table | INSERT - main payment record |
| Billing.WesternUnionToPayment | Table | INSERT - MTCN, CountryID, City |
| History.Payment | Table | INSERT - status log |
| Billing.GetTransactionID | Function | Generates unique 6-char TransactionID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application billing service (external) | Application | Legacy Western Union deposit creation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. ROLLBACK on Payment INSERT error; History.Payment INSERT error also triggers rollback. WesternUnionToPayment INSERT is not individually error-checked.

---

## 8. Sample Queries

### 8.1 Find a legacy Western Union payment by MTCN

```sql
SELECT
    bp.PaymentID,
    bp.CID,
    bp.Amount,
    bp.PaymentDate,
    bp.TransactionID,
    wup.MTCN,
    wup.City,
    c.Name AS Country
FROM Billing.Payment bp WITH (NOLOCK)
INNER JOIN Billing.WesternUnionToPayment wup WITH (NOLOCK) ON wup.PaymentID = bp.PaymentID
INNER JOIN Dictionary.Country c WITH (NOLOCK) ON c.CountryID = wup.CountryID
WHERE wup.MTCN = '1234567890';
```

### 8.2 Find all Western Union payments for a customer

```sql
SELECT
    bp.PaymentID,
    bp.Amount,
    bp.PaymentDate,
    wup.MTCN,
    wup.City,
    dc.Name AS Country,
    ps.Name AS Status
FROM Billing.Payment bp WITH (NOLOCK)
INNER JOIN Billing.WesternUnionToPayment wup WITH (NOLOCK) ON wup.PaymentID = bp.PaymentID
INNER JOIN Dictionary.Country dc WITH (NOLOCK) ON dc.CountryID = wup.CountryID
INNER JOIN Dictionary.PaymentStatus ps WITH (NOLOCK) ON ps.PaymentStatusID = bp.PaymentStatusID
WHERE bp.CID = 123456
ORDER BY bp.PaymentDate DESC;
```

### 8.3 Top sending countries for legacy Western Union deposits

```sql
SELECT
    dc.Name AS Country,
    COUNT(*) AS TransferCount,
    SUM(bp.Amount) AS TotalAmount
FROM Billing.WesternUnionToPayment wup WITH (NOLOCK)
INNER JOIN Billing.Payment bp WITH (NOLOCK) ON bp.PaymentID = wup.PaymentID
INNER JOIN Dictionary.Country dc WITH (NOLOCK) ON dc.CountryID = wup.CountryID
GROUP BY dc.Name
ORDER BY TransferCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.9/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PaymentByWesternUnionAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PaymentByWesternUnionAdd.sql*
