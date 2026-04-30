# Billing.CreditCard

> Registry of customer credit cards stored as hashed card numbers for PCI compliance; each row represents one unique card (Visa/Mastercard/Amex) with Dynamic Data Masking applied to the hash column for non-privileged users.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | CardID (PRIMARY KEY NONCLUSTERED, IDENTITY) |
| **Row Count** | ~55,320 rows |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 - PK NONCLUSTERED on CardID; 1 - UNIQUE NC on CardNumber; 1 - NC on CardTypeID |

---

## 1. Business Meaning

`Billing.CreditCard` is the registry of credit cards that customers have registered on the eToro platform. For PCI DSS compliance, the actual card number (PAN) is NOT stored - instead `CardNumber` stores a hash of the card (passed as `@CardHash` by `Billing.CreditCardAdd`), allowing deduplication without retaining sensitive card data.

An additional Dynamic Data Masking (DDM) rule (`MASKED WITH (FUNCTION = 'default()')`) is applied to `CardNumber`, ensuring that non-privileged database users see `xxxx` instead of even the hash value.

The UNIQUE index on `CardNumber` ensures that the same physical card (same hash) cannot be registered twice, preventing duplicate payment method entries.

Cards are distributed across 3 types in live data: Visa (66%, ~36,588), Mastercard (33%, ~18,527), Amex (<1%, ~205).

The table links to:
- `Billing.CreditCardToPayment`: deposit payments made with a registered card
- `Billing.CreditCardToCashout`: legacy cashout records associated with a card
- `Billing.FormatFundingPaymentDetailsForWithdraw`: function that reads `Billing.Funding.FundingData` XML to extract card details for formatting

---

## 2. Business Logic

### 2.1 Card Registration (PCI-Compliant)

**What**: Stores a one-way hash of a customer's credit card to enable card-level deduplication and linking without retaining the actual PAN.

**Columns Involved**: `CardNumber`, `CardTypeID`, `CardID`

**Rules**:
- `Billing.CreditCardAdd @CardTypeID, @CardHash -> @CardID OUTPUT`: inserts the card type and pre-computed hash as `CardNumber`
- The hash is computed by the application layer before calling the SP - the database never receives the actual card number in this flow
- UNIQUE constraint on `CardNumber` prevents the same card from being registered twice
- DDM `default()` masking on `CardNumber` returns `xxxx` for non-privileged queries (privileged users see the actual hash)
- No application logic depends on decoding `CardNumber` - it's used only for equality checks (deduplication)

### 2.2 CVV Column

- `CVV` varchar(4) NULL: present in schema but NOT populated by `Billing.CreditCardAdd`
- Likely legacy from an earlier (pre-PCI) system or used by a separate, more restricted flow
- NULL in most records; storing actual CVV would violate PCI DSS - likely stores a CVV indicator or is unused

### 2.3 Card Type Classification

- `CardTypeID` FK to `Dictionary.CardType`: identifies card network
- Observed in live data: 1=Visa (66%), 2=Mastercard (33%), 3=Amex (<1%)
- Used for routing decisions (some depots only accept specific card types) and for display in the customer portal

---

## 3. Data Overview

| CardTypeID | Card Type | Count | Percentage |
|-----------|-----------|-------|------------|
| 1 | Visa | 36,588 | 66.1% |
| 2 | Mastercard | 18,527 | 33.5% |
| 3 | Amex (American Express) | 205 | 0.4% |
| **Total** | | **55,320** | |

| Metric | Value |
|--------|-------|
| ID range | 18 to 55,340 |
| Card types present | 3 of 31 defined |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CardID | int | NO | IDENTITY(1,1) | CODE-BACKED | Internal eToro primary key for this card registration. Auto-generated. Referenced by `Billing.CreditCardToPayment` and `Billing.CreditCardToCashout` to link transactions to a specific card. NOT FOR REPLICATION. |
| 2 | CardTypeID | int | NO | - | CODE-BACKED | Card network type. FK to `Dictionary.CardType` (FK_DCDT_BCCD). Observed values: 1=Visa (66%), 2=Mastercard (34%), 3=Amex (<1%). Indexed (BCRC_CARDTYPE) for card-type filtering queries. |
| 3 | CardNumber | varchar(50) | NO | - | CODE-BACKED | Hash of the card's PAN (Primary Account Number), computed by the application before insertion (passed as `@CardHash` by `Billing.CreditCardAdd`). PCI-compliant: actual card number is never stored. UNIQUE enforced by BCRC_CARDNUMBER index - prevents duplicate card registrations. MASKED WITH (FUNCTION = 'default()') - non-privileged DB users see `xxxx`. |
| 4 | CVV | varchar(4) | YES | NULL | NAME-INFERRED | Card Verification Value field. NOT populated by the standard `Billing.CreditCardAdd` flow. Likely legacy from a pre-PCI era or a restricted supplementary flow. NULL in most records. varchar(4) accommodates both 3-digit (Visa/MC) and 4-digit (Amex) CVV formats. Storing actual CVV would violate PCI DSS; this field is not used in active flows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CardTypeID | Dictionary.CardType | FK (FK_DCDT_BCCD) | Card network/type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CreditCardToPayment | CardID | FK (implicit) | Links deposit payments to this card |
| Billing.CreditCardToCashout | CardID | FK (implicit) | Links legacy cashout records to this card |
| Billing.CreditCardAdd | CardID (OUTPUT) | Write | Registers a new card (inserts hash as CardNumber) |
| Billing.LoadCreditCards | - | Read | Loads full registry into application cache |
| Billing.LoadCreditCardToPayment | - | Read | Loads card-to-payment associations |
| Billing.PaymentByCreditCardAdd | CardID | Write | Associates a payment with this card |
| Billing.GetPaymentData | CardID | Read | Retrieves payment details including card type |
| Billing.GetPaymentDetails | CardID | Read | Detailed payment + card data retrieval |
| Billing.GetDepositsCustomerCardPCIVersion | CardID | Read | PCI-compliant card data retrieval |
| Billing.FormatFundingPaymentDetailsForWithdraw | CardID | Related | Formats card details for withdrawal payment data |
| Billing.CheckFundingTypeLimitByCCNumber | CardNumber | Read | Checks if a card hash has reached its funding type limit |
| Billing.CustomerRemove | CardID | Delete | Removes card registrations on customer deletion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CreditCard
  -> Dictionary.CardType (card network type)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CardType | Table | FK on CardTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CreditCardToPayment | Table | FK on CardID - links deposits to cards |
| Billing.CreditCardToCashout | Table | FK on CardID - links legacy cashouts to cards |
| Billing.CreditCardAdd | Stored Procedure | Inserts new card hash registration |
| Billing.LoadCreditCards | Stored Procedure | Full table scan for cache |
| Billing.CheckFundingTypeLimitByCCNumber | Stored Procedure | Limit check by card hash |
| Billing.CustomerRemove | Stored Procedure | Deletes records on customer removal |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Notes |
|-----------|------|-------------|-----------------|--------|-------|
| PK_BCRC | NONCLUSTERED PK | CardID ASC | - | - | Active; FILLFACTOR=90; heap table |
| BCRC_CARDNUMBER | UNIQUE NC | CardNumber ASC | - | - | Active; FILLFACTOR=90; SET ANSI_PADDING ON; prevents duplicate card hash |
| BCRC_CARDTYPE | NC | CardTypeID ASC | - | - | Active; no FILLFACTOR specified |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BCRC | PRIMARY KEY NONCLUSTERED (CardID) | One row per card registration |
| FK_DCDT_BCCD | FOREIGN KEY CardTypeID -> Dictionary.CardType | Card type must be valid |
| BCRC_CARDNUMBER (index) | UNIQUE | Each card hash may only be registered once |
| MASKED WITH (FUNCTION = 'default()') | DDM | CardNumber shows as 'xxxx' for non-privileged users |

---

## 8. Sample Queries

### 8.1 Card type distribution

```sql
SELECT
    ct.Name AS CardType,
    COUNT(*) AS Count,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Pct
FROM Billing.CreditCard cc WITH (NOLOCK)
JOIN Dictionary.CardType ct WITH (NOLOCK) ON ct.CardTypeID = cc.CardTypeID
GROUP BY ct.Name
ORDER BY Count DESC
```

### 8.2 Find cards with deposit history

```sql
SELECT TOP 20
    cc.CardID,
    cc.CardTypeID,
    COUNT(ctp.PaymentID) AS PaymentCount
FROM Billing.CreditCard cc WITH (NOLOCK)
JOIN Billing.CreditCardToPayment ctp WITH (NOLOCK) ON ctp.CardID = cc.CardID
GROUP BY cc.CardID, cc.CardTypeID
ORDER BY PaymentCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 1,2,3,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CreditCard | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.CreditCard.sql*
