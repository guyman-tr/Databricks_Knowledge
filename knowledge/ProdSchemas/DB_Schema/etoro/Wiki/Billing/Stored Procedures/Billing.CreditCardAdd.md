# Billing.CreditCardAdd

> Inserts a hashed credit card (PAN hash) with its card type into `Billing.CreditCard` and returns the new `CardID`; the PCI-compliant entry point for card registration.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CardID OUTPUT (new Billing.CreditCard.CardID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CreditCardAdd` is the sole writer of `Billing.CreditCard`. It registers a new credit card in eToro's payment system by inserting a pre-computed hash of the card number (PAN) rather than the actual card number. This PCI DSS-compliant design means the database never stores sensitive cardholder data - the application layer hashes the card before calling this procedure.

The returned `@CardID` becomes the stable reference used throughout the billing system to link deposits (`Billing.CreditCardToPayment`) and legacy cashouts (`Billing.CreditCardToCashout`) to a specific card. The UNIQUE constraint on `CardNumber` in `Billing.CreditCard` ensures that the same physical card (same hash) can only be registered once.

Cards added via this procedure are then linked to a `Billing.Funding` record (the customer's payment instrument) through a separate step in the card registration flow.

---

## 2. Business Logic

### 2.1 PCI-Compliant Card Registration

**What**: Inserts a card hash (not the actual PAN) alongside the card type into `Billing.CreditCard`, returns the new ID.

**Parameters Involved**: `@CardHash`, `@CardTypeID`, `@CardID`

**Rules**:
- The card hash (`@CardHash`) is computed by the application layer before this call - the database only sees the hash
- `SCOPE_IDENTITY()` captures the IDENTITY value from the INSERT and assigns it to `@CardID OUTPUT`
- If the same hash already exists (same physical card), the INSERT fails with a UNIQUE constraint violation on `Billing.CreditCard.CardNumber`
- Error handling: `@@ERROR` is captured and returned as `RETURN @LocalError`; 0=success, non-zero=SQL error code
- Dynamic Data Masking on `CardNumber` column (set in the table DDL) means non-privileged DB queries see `xxxx` instead of the hash

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CardID | INTEGER OUTPUT | NO | - | VERIFIED | Returns the newly assigned `Billing.CreditCard.CardID` (IDENTITY value from SCOPE_IDENTITY()). The caller uses this ID to link the card to a Billing.Funding record. |
| 2 | @CardTypeID | INTEGER | NO | - | CODE-BACKED | Card network type. FK to `Dictionary.CardType` in the target table. Values: 1=Visa, 2=Mastercard, 3=Amex. Written directly to `Billing.CreditCard.CardTypeID`. |
| 3 | @CardHash | VARCHAR(50) | NO | - | VERIFIED | One-way hash of the card's PAN (Primary Account Number), computed by the application before this call. Stored as `Billing.CreditCard.CardNumber`. Max 50 characters. If the same hash already exists, INSERT fails with UNIQUE constraint violation (same physical card may not be registered twice). |

**Return value**: `RETURN @LocalError` - 0 on success, `@@ERROR` value on failure.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CardTypeID | Billing.CreditCard.CardTypeID | Write | Inserts card type into CreditCard registry |
| @CardHash | Billing.CreditCard.CardNumber | Write | Inserts PCI-compliant card hash |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Card registration service | @CardHash, @CardTypeID | Caller | Called when a customer adds a new credit card; caller captures @CardID for subsequent Billing.Funding linkage |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CreditCardAdd (procedure)
+-- Billing.CreditCard (table) [INSERT target]
      +-- Dictionary.CardType (table) [FK on CardTypeID]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CreditCard | Table | INSERT target for the new card registration |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Card registration workflows | External | Call this SP to register new cards; use @CardID in subsequent Billing.Funding creation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**No transaction wrapper**: This procedure does NOT use `BEGIN TRANSACTION`. If the INSERT fails, no rollback is needed (single-statement operation). Callers that need transactional semantics must wrap the EXEC in their own transaction.

---

## 8. Sample Queries

### 8.1 Register a new card (caller pattern)

```sql
DECLARE @NewCardID INTEGER
EXEC @LocalError = Billing.CreditCardAdd
    @CardID = @NewCardID OUTPUT,
    @CardTypeID = 1,           -- Visa
    @CardHash = 'abc123def456...'  -- Pre-computed hash from app layer

IF @LocalError = 0
    SELECT @NewCardID AS NewCardID
ELSE
    SELECT @LocalError AS ErrorCode
```

### 8.2 Verify the card was registered

```sql
SELECT
    cc.CardID,
    cc.CardTypeID,
    ct.Name AS CardTypeName,
    cc.CardNumber  -- Will show hash (or 'xxxx' for non-privileged users)
FROM Billing.CreditCard cc WITH (NOLOCK)
JOIN Dictionary.CardType ct WITH (NOLOCK) ON ct.CardTypeID = cc.CardTypeID
WHERE cc.CardID = @NewCardID
```

### 8.3 Check for duplicate card before registration

```sql
-- Detect if the same card hash already exists before calling CreditCardAdd
SELECT CardID, CardTypeID
FROM Billing.CreditCard WITH (NOLOCK)
WHERE CardNumber = @CardHash
-- If a row is returned, the card is already registered; use that CardID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CreditCardAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CreditCardAdd.sql*
