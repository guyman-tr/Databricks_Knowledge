# Billing.PaymentByCreditCardAdd

> Creates a legacy credit card payment record, registering or updating the card in Billing.CreditCard and linking it to the payment in a single atomic transaction; part of the pre-2011 Billing.Payment infrastructure.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PaymentID (OUTPUT - new identity from Billing.Payment) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PaymentByCreditCardAdd` is the credit card deposit creation procedure for the legacy `Billing.Payment` system. When a customer made a credit card deposit in the pre-2011 era, this procedure recorded the full transaction atomically: the payment record itself, the card registration (with CVV), the link between card and payment including cardholder billing details, and an initial status history entry.

The procedure represents eToro's original credit card payment flow before the current `Billing.Deposit`/`Billing.Funding` architecture was introduced. `Billing.Payment` was frozen in January 2011 after all records were migrated to `Billing.Deposit`. This procedure now represents a closed chapter of the payment system - it is preserved for completeness but no longer part of active deposit processing.

The caller receives the new `@PaymentID` and the `TransactionID` (via result set) to link subsequent payment action records via `Billing.PaymentActionAdd`. If any step in the transaction fails, the entire operation is rolled back and error code 60000 is raised.

---

## 2. Business Logic

### 2.1 Four-Table Atomic Transaction

**What**: All four inserts (Payment, CreditCard upsert, CreditCardToPayment, History.Payment) succeed or fail together.

**Parameters Involved**: All parameters

**Rules**:
- Step 1: Generate unique TransactionID (per-CID uniqueness checked against Billing.Payment.TransactionID)
- Step 2: INSERT Billing.Payment with FundingTypeID=1 (hardcoded = credit card). @PaymentDate passed by caller is IGNORED - overwritten by GETUTCDATE() internally
- Step 3: CreditCard upsert - lookup by CardNumber:
  - Not found: INSERT new Billing.CreditCard (CardTypeID, CardNumber, CVV)
  - Found with NULL CVV or changed CVV: UPDATE Billing.CreditCard SET CVV = @CVV
  - Found with matching CVV: no card update
- Step 4: INSERT Billing.CreditCardToPayment with full cardholder billing details
- Step 5: INSERT History.Payment status log entry (PreviousStatus = CurrentStatus = @PaymentStatusID)
- Any error at any step -> ROLLBACK + RAISERROR(60000) + RETURN 60000

**Diagram**:
```
BEGIN TRANSACTION
  1. INSERT Billing.Payment  (FundingTypeID=1 hardcoded)
      -> @PaymentID = SCOPE_IDENTITY()
  2. SELECT @CardID from Billing.CreditCard WHERE CardNumber = @CardNumber
     2a. If @CardID IS NULL -> INSERT Billing.CreditCard
     2b. If found, CVV changed -> UPDATE Billing.CreditCard SET CVV
  3. INSERT Billing.CreditCardToPayment (links @CardID + @PaymentID + cardholder data)
  4. INSERT History.Payment (status snapshot)
  SELECT @TransactionID
COMMIT TRANSACTION
RETURN 0
```

### 2.2 CVV Storage - Legacy Path

**What**: Unlike the modern `Billing.CreditCardAdd` (which stores a hash), this procedure stores CVV in `Billing.CreditCard`.

**Columns Involved**: `@CVV`, `@CardNumber`, Billing.CreditCard.CVV

**Rules**:
- CVV is stored if the card is new (INSERT), or updated if the stored CVV is NULL or has changed
- Code comment: "we add CVV functionality later, check value, if NOT NULL, otherwise write it to the table" - reflects incremental CVV rollout in 2007-2011
- This is part of the legacy system; the modern Billing.Funding flow does NOT store CVV

### 2.3 PaymentDate Overwrite

**What**: The @PaymentDate INPUT parameter is silently overwritten inside the procedure.

**Rules**:
- Line 54: `SET @PaymentDate = GETUTCDATE()` - the passed value is discarded
- All inserts use the overwritten value (or ISNULL fallback which also resolves to GETUTCDATE())
- The parameter exists for API compatibility but has no effect on the stored timestamp

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentID | INTEGER | NO | - | CODE-BACKED | OUTPUT. New Billing.Payment IDENTITY returned after INSERT. Used by caller to create payment action records (Billing.PaymentActionAdd) and to link the deposit in the application. |
| 2 | @CurrencyID | INTEGER | NO | - | CODE-BACKED | Currency of the deposit. FK to Dictionary.Currency. Stored in Billing.Payment.CurrencyID. |
| 3 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Stored in Billing.Payment.CID. Also used in TransactionID uniqueness check. |
| 4 | @PaymentStatusID | INTEGER | NO | - | CODE-BACKED | Initial payment status. Stored in Billing.Payment and History.Payment (as both Previous and ChangedTo on creation). FK to Dictionary.PaymentStatus. |
| 5 | @PaymentTypeID | INTEGER | NO | - | CODE-BACKED | Payment method type (credit card protocol subtype). FK to Dictionary.PaymentType. Stored in Billing.Payment.PaymentTypeID. |
| 6 | @TerminalID | INTEGER | NO | - | CODE-BACKED | Payment terminal/gateway configuration. FK to Billing.Terminal. Stored in Billing.Payment.TerminalID. |
| 7 | @BankID | INTEGER | NO | - | CODE-BACKED | Issuing bank identifier. Stored in Billing.CreditCardToPayment.BankID for chargeback routing. |
| 8 | @Amount | INTEGER | NO | - | CODE-BACKED | Deposit amount in smallest currency unit (cents). Stored in Billing.Payment.Amount as INTEGER. |
| 9 | @ExchangeRate | dtPrice | NO | - | CODE-BACKED | Exchange rate at time of deposit. dtPrice is a user-defined decimal type. Stored in Billing.Payment.ExchangeRate. |
| 10 | @PaymentDate | DATETIME | NO | - | CODE-BACKED | IGNORED - overwritten by GETUTCDATE() inside the procedure. Parameter exists for interface compatibility only. All inserts use the internal UTC timestamp. |
| 11 | @IPAddress | NUMERIC(18,0) | NO | - | CODE-BACKED | Customer IP address encoded as a numeric (integer representation of dotted-quad). Stored in Billing.Payment.IPAddress for fraud/geolocation lookup. |
| 12 | @CountryID | INTEGER | NO | - | CODE-BACKED | Cardholder billing country. FK to Dictionary.Country. Stored in Billing.CreditCardToPayment.CountryID. |
| 13 | @StateID | INTEGER | NO | - | CODE-BACKED | Cardholder billing state/province. FK to Dictionary.State. Stored in Billing.CreditCardToPayment.StateID. |
| 14 | @ExpirationDate | CHAR(10) | NO | - | CODE-BACKED | Card expiry date (e.g., "12/2025"). Stored in Billing.CreditCardToPayment.ExpirationDate. |
| 15 | @CardHolderAddress | VARCHAR(250) | NO | - | CODE-BACKED | Cardholder billing street address for AVS (Address Verification Service). Stored in Billing.CreditCardToPayment. |
| 16 | @CardHolderFirstName | VARCHAR(100) | NO | - | CODE-BACKED | Cardholder first name for name-match verification and DepositNameConflict risk checks. Stored in Billing.CreditCardToPayment. |
| 17 | @CardHolderLastName | VARCHAR(100) | NO | - | CODE-BACKED | Cardholder last name. Combined with FirstName for identity matching against customer profile. Stored in Billing.CreditCardToPayment. |
| 18 | @CardHolderEmail | VARCHAR(50) | NO | - | CODE-BACKED | Cardholder email address. Stored in Billing.CreditCardToPayment for fraud detection. |
| 19 | @CardHolderPhoneNumber | VARCHAR(50) | NO | - | CODE-BACKED | Cardholder phone number. Stored in Billing.CreditCardToPayment. |
| 20 | @City | VARCHAR(50) | NO | - | CODE-BACKED | Cardholder billing city. Stored in Billing.CreditCardToPayment.City. |
| 21 | @ZipCode | VARCHAR(50) | NO | - | CODE-BACKED | Cardholder billing postal code for AVS. Stored in Billing.CreditCardToPayment.ZipCode. |
| 22 | @CardTypeID | INTEGER | NO | - | CODE-BACKED | Card network: Visa/Mastercard/Amex. FK to Dictionary.CardType. Stored in Billing.CreditCard.CardTypeID on new card registration. |
| 23 | @CardNumber | VARCHAR(50) | NO | - | CODE-BACKED | Card number or hash used for deduplication. Looked up in Billing.CreditCard (UNIQUE on CardNumber). If not found, a new card row is inserted. Used for card identity - not stored as plaintext PAN in the modern system. |
| 24 | @CVV | VARCHAR(4) | YES | - | CODE-BACKED | Card CVV security code. Stored in Billing.CreditCard.CVV for new cards or if existing CVV is NULL or changed. Legacy CVV storage - the modern payment system does not store CVV in DB. |
| 25 | @ProcessingTerminal | INTEGER | NO | - | CODE-BACKED | Secondary terminal reference for the credit card processor. Stored in Billing.CreditCardToPayment.ProcessingTerminal (distinct from @TerminalID which is the main gateway terminal). |
| 26 | RETURN value | INTEGER | - | - | CODE-BACKED | 0 = success (COMMIT). 60000 = transaction failure at any step (ROLLBACK + RAISERROR). Caller must check before using @PaymentID. |
| 27 | Result set | CHAR(6) | - | - | CODE-BACKED | SELECT @TransactionID - returns the 6-char unique TransactionID on success. Caller uses this to correlate gateway responses via Billing.PaymentActionAdd. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | [Billing.Payment](../Tables/Billing.Payment.md) | WRITER | Creates the main legacy payment record (FundingTypeID=1 hardcoded) |
| @CardNumber upsert | [Billing.CreditCard](../Tables/Billing.CreditCard.md) | WRITER | Registers card or updates CVV |
| INSERT | Billing.CreditCardToPayment | WRITER | Links card to payment with full cardholder billing details |
| INSERT | History.Payment | WRITER | Initial status snapshot log entry |
| TransactionID | Billing.GetTransactionID() | Function call | Generates unique 6-char TransactionID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application billing service (external) | - | EXEC caller | Legacy credit card deposit creation flow (pre-2011) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PaymentByCreditCardAdd (procedure)
├── Billing.Payment (table)
├── Billing.CreditCard (table)
├── Billing.CreditCardToPayment (table)
├── History.Payment (table)
└── Billing.GetTransactionID (function)
      └── Billing.GenTransactionID (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.Payment](../Tables/Billing.Payment.md) | Table | INSERT - main payment record |
| [Billing.CreditCard](../Tables/Billing.CreditCard.md) | Table | SELECT (lookup by CardNumber) + INSERT (new card) + UPDATE (CVV update) |
| Billing.CreditCardToPayment | Table | INSERT - links card to payment with cardholder billing details |
| History.Payment | Table | INSERT - status log entry at payment creation |
| Billing.GetTransactionID | Function | Generates the per-CID-unique 6-char TransactionID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application billing service (external) | Application | Legacy payment creation flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Transaction rolls back with RAISERROR(60000) on any INSERT/UPDATE error. Billing.Payment FK constraints enforce valid CurrencyID, CID, PaymentStatusID, PaymentTypeID, TerminalID.

---

## 8. Sample Queries

### 8.1 Look up a legacy credit card payment with its card and cardholder details

```sql
SELECT
    bp.PaymentID,
    bp.CID,
    bp.Amount,
    bp.PaymentDate,
    bp.TransactionID,
    cc.CardTypeID,
    cctp.CardHolderFirstName,
    cctp.CardHolderLastName,
    cctp.ExpirationDate
FROM Billing.Payment bp WITH (NOLOCK)
INNER JOIN Billing.CreditCardToPayment cctp WITH (NOLOCK) ON cctp.PaymentID = bp.PaymentID
INNER JOIN Billing.CreditCard cc WITH (NOLOCK) ON cc.CardID = cctp.CardID
WHERE bp.CID = 123456
ORDER BY bp.PaymentDate DESC;
```

### 8.2 Find cards registered via this legacy flow with their CVV status

```sql
SELECT
    cc.CardID,
    cc.CardTypeID,
    CASE WHEN cc.CVV IS NULL THEN 'No CVV' ELSE 'CVV Present' END AS CVVStatus
FROM Billing.CreditCard cc WITH (NOLOCK)
WHERE cc.CVV IS NOT NULL
ORDER BY cc.CardID DESC;
```

### 8.3 Review legacy payment status history

```sql
SELECT
    hp.PaymentID,
    hp.PreviousPaymentStatusID,
    hp.ChangedToPaymentStatusID,
    hp.ModificationDate
FROM History.Payment hp WITH (NOLOCK)
WHERE hp.PaymentID = 9876
ORDER BY hp.ModificationDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 27 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PaymentByCreditCardAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PaymentByCreditCardAdd.sql*
