# Billing.PayPalToPaymentEdit

> Updates the payer details, country, and transaction identifiers on a legacy PayPalToPayment record - used by back-office billing managers to correct or enrich PayPal payment metadata after a transaction is received.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PaymentID - the PayPalToPayment record to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayPalToPaymentEdit` is the update procedure for `Billing.PayPalToPayment`, a legacy table that recorded per-transaction PayPal payment metadata (payer name, country, PayPal token, and external transaction ID). The table currently has 0 rows in production, indicating this flow is either decommissioned or has been fully migrated to the newer PayPal architecture.

When a back-office billing manager (`BILLING_MANAGER` role) needed to correct or enrich the PayPal metadata for an existing payment record, they called this procedure. The CountryID is resolved from the provided country abbreviation via a lookup against `Dictionary.Country`, so callers pass the ISO abbreviation (e.g., 'US', 'GB') rather than the internal integer ID.

---

## 2. Business Logic

### 2.1 Country Resolution from Abbreviation

**What**: Resolves the CountryID integer from a two-letter country abbreviation.

**Columns Involved**: `Dictionary.Country.CountryID`, `Dictionary.Country.Abbreviation`

**Rules**:
- SELECT @CountryID = CountryID FROM Dictionary.Country WHERE Abbreviation = @CountryAbbreviation.
- If the abbreviation is not found, @CountryID remains NULL and NULL is written to PayPalToPayment.CountryID.
- This lookup enables callers to pass 'US', 'GB', etc. rather than needing to know internal CountryID values.

### 2.2 Payment Record Update

**What**: Updates all mutable PayPal payment fields on the record.

**Columns Involved**: `Billing.PayPalToPayment.Payer`, `Billing.PayPalToPayment.CountryID`, `Billing.PayPalToPayment.PayerFirstName`, `Billing.PayPalToPayment.PayerLastName`, `Billing.PayPalToPayment.Token`, `Billing.PayPalToPayment.TransactionID`

**Rules**:
- UPDATE Billing.PayPalToPayment SET Payer=@Payer, CountryID=@CountryID, PayerFirstName=@PayerFirstName, PayerLastName=@PayerLastName, Token=@Token, TransactionID=@TransactionID WHERE PaymentID=@PaymentID.
- All six fields are updated unconditionally (no ISNULL protection - passing NULL clears the field).
- Single-row update targeting PaymentID (PK).

**Diagram**:
```
@PaymentID + payer details + @CountryAbbreviation + @Token + @TransactionID
  |
  SELECT @CountryID FROM Dictionary.Country WHERE Abbreviation=@CountryAbbreviation
  |
  UPDATE Billing.PayPalToPayment SET
    Payer=@Payer,
    CountryID=@CountryID,   <- resolved from abbreviation
    PayerFirstName=@PayerFirstName,
    PayerLastName=@PayerLastName,
    Token=@Token,
    TransactionID=@TransactionID
  WHERE PaymentID=@PaymentID
```

---

## 3. Data Overview

N/A for stored procedure. Note: `Billing.PayPalToPayment` currently has 0 rows in production - this is a legacy procedure on a decommissioned or migrated flow.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentID | int | NO | - | CODE-BACKED | The PayPalToPayment record to update. Maps to `Billing.PayPalToPayment.PaymentID`. |
| 2 | @Payer | nvarchar(255) | YES | - | CODE-BACKED | PayPal payer identifier (email or account reference). Written to `Billing.PayPalToPayment.Payer`. |
| 3 | @CountryAbbreviation | nvarchar(10) | YES | - | CODE-BACKED | ISO country abbreviation (e.g., 'US', 'GB'). Resolved to CountryID via `Dictionary.Country.Abbreviation` lookup before being stored. |
| 4 | @PayerFirstName | nvarchar(100) | YES | - | CODE-BACKED | Payer's first name from PayPal. Written to `Billing.PayPalToPayment.PayerFirstName`. |
| 5 | @PayerLastName | nvarchar(100) | YES | - | CODE-BACKED | Payer's last name from PayPal. Written to `Billing.PayPalToPayment.PayerLastName`. |
| 6 | @Token | nvarchar(255) | YES | - | CODE-BACKED | PayPal payment token (checkout token or IPN token). Written to `Billing.PayPalToPayment.Token`. |
| 7 | @TransactionID | nvarchar(255) | YES | - | CODE-BACKED | PayPal's external transaction ID. Written to `Billing.PayPalToPayment.TransactionID`. Used for reconciliation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CountryAbbreviation | Dictionary.Country | Read (SELECT) | Resolves abbreviation to CountryID before the UPDATE. |
| @PaymentID | [Billing.PayPalToPayment](../Tables/Billing.PayPalToPayment.md) | Write (UPDATE) | Updates PayPal payment metadata on the legacy PayPalToPayment record. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BILLING_MANAGER (db role) | - | EXEC | Back-office billing manager tool for correcting PayPal payment records. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayPalToPaymentEdit (procedure)
├── Dictionary.Country (table) - SELECT for abbreviation lookup
└── Billing.PayPalToPayment (table) - UPDATE
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | SELECT to resolve Abbreviation -> CountryID. |
| [Billing.PayPalToPayment](../Tables/Billing.PayPalToPayment.md) | Table | UPDATE - writes payer details, CountryID, Token, TransactionID by PaymentID. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BILLING_MANAGER application role | Application | Back-office correction of legacy PayPal payment records. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

The UPDATE targets `WHERE PaymentID=@PaymentID` - this uses the PK of `Billing.PayPalToPayment` for a single-seek update. The Dictionary.Country lookup uses the Abbreviation column.

**Legacy status**: `Billing.PayPalToPayment` has 0 rows in production. This procedure exists for historical compatibility but is not actively used in current payment flows.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Update PayPal payment metadata (back-office correction)

```sql
EXEC Billing.PayPalToPaymentEdit
    @PaymentID          = 1001,
    @Payer              = 'payer@example.com',
    @CountryAbbreviation = 'US',
    @PayerFirstName     = 'John',
    @PayerLastName      = 'Smith',
    @Token              = 'EC-1A2B3C4D5E6F7890',
    @TransactionID      = '1A234567BC890123D';
```

### 8.2 Verify the country abbreviation lookup

```sql
SELECT CountryID, Abbreviation, Name
FROM Dictionary.Country WITH (NOLOCK)
WHERE Abbreviation = 'US';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PayPalToPaymentEdit | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayPalToPaymentEdit.sql*
