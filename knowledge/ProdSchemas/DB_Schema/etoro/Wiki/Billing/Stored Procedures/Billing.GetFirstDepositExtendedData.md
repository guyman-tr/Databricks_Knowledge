# Billing.GetFirstDepositExtendedData

> Retrieves extended data for a specific deposit record including refundability status, the card issuer bank name, and the payment country name - data needed for refund eligibility and reporting.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When processing a refund, chargeback, or withdrawal for a customer deposit, the system needs to know whether the original deposit's payment method supports refunds (IsRefundable), who issued the card (IssuingBank for credit cards), and which country the payment was made in (MopCountry). This information is not directly on the Deposit table and requires joining across the funding, funding type, and country BIN tables.

This procedure provides a single, efficient lookup of all three pieces of extended data for a given deposit. It is typically called during refund workflow processing or when displaying deposit details to back-office users.

Country resolution follows the same pattern as GetFirstApprovedWidthrowToFundingMessageParameters: for credit card deposits (FundingTypeID=3) where the deposit PaymentData XML contains a valid CountryIDAsString, that country is used; otherwise, the country is resolved from the card BIN's CountryID.

---

## 2. Business Logic

### 2.1 Country Resolution for Deposits

**What**: Payment country for the deposit is derived from the deposit XML or card BIN data.

**Columns/Parameters Involved**: `MopCountry`

**Rules**:
- For FundingTypeID=3 (credit card) AND PaymentData.CountryIDAsString > 0: use the country from the deposit payment data XML
- Otherwise (not credit card, or no country in payment data): use CountryBin.CountryID (card issuer country from BIN lookup)
- JOIN condition: `DC.CountryID > 0` ensures invalid/null countries are excluded from the result
- Result: Dictionary.Country.Name aliased as MopCountry

### 2.2 Refundability Check

**What**: IsRefundable flag on FundingType determines whether a refund is allowed for this payment method.

**Rules**:
- Dictionary.FundingType.IsRefundable comes from the type definition, not the individual transaction
- When IsRefundable=0, the payment method (e.g., certain e-wallets) cannot be used as a refund target
- This flag drives the application's decision to offer/block the refund option

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | Primary key of Billing.Deposit. Identifies the specific deposit for which extended data is requested. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | DepositID | INT | NO | - | CODE-BACKED | Echoes back the input @DepositID. Confirms which deposit the extended data belongs to. |
| R2 | IsRefundable | BIT | YES | NULL | CODE-BACKED | Dictionary.FundingType.IsRefundable. 1 = this payment method type supports refunds (credit card, bank transfer). 0 = method does not support refunds (e.g., certain e-wallets). Drives refund eligibility decision in the application. |
| R3 | MopCountry | NVARCHAR | YES | NULL | CODE-BACKED | Human-readable country name. For credit card (FundingTypeID=3) deposits with a country in PaymentData XML: that deposit country. Otherwise: card BIN country (CountryBin.CountryID -> Dictionary.Country.Name). NULL if country cannot be resolved. |
| R4 | IssuingBank | VARCHAR | YES | NULL | CODE-BACKED | Name of the card-issuing bank from Dictionary.CountryBin. Only populated for credit card payments where the card BIN is known. NULL for non-card payment methods or unknown BINs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit | JOIN | Main deposit record (DepositID, FundingID, PaymentData XML) |
| FundingID | Billing.Funding | JOIN | FundingData XML (BinCodeAsString) |
| FundingTypeID | Dictionary.FundingType | JOIN | IsRefundable flag |
| BinCodeAsString | Dictionary.CountryBin | LEFT JOIN | Card BIN -> IssuingBank + CountryID |
| Resolved CountryID | Dictionary.Country | LEFT JOIN | MopCountry (country name) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application refund/chargeback service | @DepositID | EXEC | Called during refund processing to check eligibility and get payment details |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFirstDepositExtendedData (procedure)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Dictionary.FundingType (table)
├── Dictionary.CountryBin (table)
└── Dictionary.Country (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Main lookup by DepositID; PaymentData XML for country |
| Billing.Funding | Table | JOIN on FundingID; FundingData XML (BinCode) + FundingTypeID |
| Dictionary.FundingType | Table | JOIN on FundingTypeID; IsRefundable |
| Dictionary.CountryBin | Table | LEFT JOIN on BinCode -> IssuingBank + CountryID |
| Dictionary.Country | Table | LEFT JOIN on resolved CountryID -> Name (MopCountry) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from refund/chargeback processing service. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get extended data for a deposit

```sql
EXEC Billing.GetFirstDepositExtendedData @DepositID = 12345678;
```

### 8.2 Check deposit refundability for a set of deposits

```sql
SELECT d.DepositID, ft.IsRefundable, ft.Name AS FundingType
FROM Billing.Deposit d WITH (NOLOCK)
INNER JOIN Billing.Funding f WITH (NOLOCK) ON d.FundingID = f.FundingID
INNER JOIN Dictionary.FundingType ft WITH (NOLOCK) ON f.FundingTypeID = ft.FundingTypeID
WHERE d.CID = 1234567
ORDER BY d.DepositID DESC;
```

### 8.3 Find deposits where country is resolved from PaymentData vs CountryBin

```sql
-- Deposits where country comes from XML (FundingTypeID=3 with valid country)
SELECT d.DepositID,
    d.PaymentData.value('Deposit[1]/CountryIDAsString[1]', 'VarChar(Max)') AS XmlCountry,
    cb.CountryID AS BinCountry
FROM Billing.Deposit d WITH (NOLOCK)
INNER JOIN Billing.Funding f WITH (NOLOCK) ON d.FundingID = f.FundingID
LEFT JOIN Dictionary.CountryBin cb WITH (NOLOCK)
    ON f.FundingData.value('Funding[1]/BinCodeAsString[1]', 'VarChar(Max)') = cb.BinCode
WHERE f.FundingTypeID = 3
ORDER BY d.DepositID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFirstDepositExtendedData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFirstDepositExtendedData.sql*
