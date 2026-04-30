# BackOffice.GetCustomerFundingCountries

> Returns the FundingID and derived CountryID for each of a customer's approved deposits, extracting the country from payment-method-specific XML fields per funding type.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - single customer; PaymentStatusID=2 filter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies the geographic origin of each payment method a customer has used for approved deposits. The "country" of a funding method is extracted differently for each payment type - a credit card's BIN country, a wire transfer's declared bank country, a PayPal account's registered country, or a Giropay/Trustly bank country.

Created May 2021 (MIMOOPS-3856 / "Get all customer funding countries") for AML/compliance use cases where the geographic source of funds needs to be documented and cross-checked against sanction lists or risk rules.

---

## 2. Business Logic

### 2.1 Per-FundingType Country Extraction Logic

**What**: CountryID is extracted from different XML paths depending on the payment method type.

**Columns/Parameters Involved**: `CountryID`, `Billing.Funding.FundingData`, `Billing.Deposit.PaymentData`

| FundingTypeID | Method | XML Source | XML Path |
|---------------|--------|------------|----------|
| 1 | Credit Card | Billing.Funding.FundingData | /Funding/BinCountryIDAsInteger |
| 2 | Wire Transfer | Billing.Funding.FundingData | /Funding/CountryIDAsInteger |
| 3 | PayPal | Billing.Deposit.PaymentData | /Deposit/CountryIDAsString |
| 11 | Giropay | Billing.Deposit.PaymentData | /Deposit/CountryIDAsString -> Dictionary.Country.Abbreviation lookup |
| 35 | Trustly | Billing.Deposit.PaymentData | /Deposit/BankCountryAsString -> Dictionary.Country.Name LIKE lookup |
| ELSE | Others | Billing.Funding.FundingData | /Funding/BinCountryIDAsInteger (default to credit card pattern) |

**Notes**:
- Giropay: CountryIDAsString returns a country abbreviation code (e.g., 'DE'), not an integer; resolved via `Dictionary.Country.Abbreviation LIKE` lookup
- Trustly: BankCountryAsString returns a country name string; resolved via case-insensitive `LOWER(Name) LIKE LOWER(...)` lookup
- PayPal: CountryIDAsString is cast directly to INT
- ELSE fallback uses BinCountryIDAsInteger - appropriate for e-wallets that store a BIN-like country field

### 2.2 Approved Deposits Only

**What**: Only approved/processed deposits are included.

**Rules**:
- `bd.PaymentStatusID = 2` - approved/successful deposits only
- Rejected, pending, or refunded deposits are excluded
- Combined with `bd.CID = @CID` in the JOIN and `bctf.CID = @CID` in the WHERE

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose funding countries to return. |
| **Output Columns** | | | | | | |
| 2 | FundingID | INT | NO | - | CODE-BACKED | Unique ID of the payment method. FK to Billing.Funding.FundingID. Deduplicated via DISTINCT. |
| 3 | CountryID | INT | YES | NULL | CODE-BACKED | Country ID derived from the payment method's XML data, extraction method varies by FundingTypeID. NULL if the XML field is empty or unparseable. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID / FundingID | Billing.CustomerToFunding | Primary JOIN | Customer's payment method associations |
| FundingID | Billing.Funding | Lookup / INNER JOIN | FundingData XML and FundingTypeID |
| FundingID / CID | Billing.Deposit | INNER JOIN | PaymentData XML; filtered to approved deposits |
| Abbreviation | Dictionary.Country | Subquery lookup | Resolves Giropay country abbreviation to CountryID |
| Name | Dictionary.Country | Subquery lookup | Resolves Trustly bank country string to CountryID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | AML/compliance country-of-funds tracking |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerFundingCountries (procedure)
|- Billing.CustomerToFunding (customer-funding links)
|- Billing.Funding (FundingData XML + FundingTypeID)
|- Billing.Deposit (PaymentData XML, PaymentStatusID filter)
+-- Dictionary.Country (Giropay + Trustly country resolution)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | Primary - links customer to their payment methods |
| Billing.Funding | Table | FundingData XML and FundingTypeID for country extraction |
| Billing.Deposit | Table | PaymentData XML for PayPal/Giropay/Trustly; PaymentStatusID=2 filter |
| Dictionary.Country | Table | Subquery lookups for Giropay (Abbreviation) and Trustly (Name) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Source of funds country for AML/compliance review |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `SET NOCOUNT ON`
- `SELECT DISTINCT`: deduplicates (FundingID, CountryID) pairs

---

## 8. Sample Queries

### 8.1 Get funding countries for a customer

```sql
EXEC BackOffice.GetCustomerFundingCountries @CID = 12345678;
```

### 8.2 Check credit card BIN country directly

```sql
SELECT DISTINCT bctf.FundingID,
    bf.FundingData.value('(/Funding/BinCountryIDAsInteger)[1]', 'INT') AS CountryID
FROM Billing.CustomerToFunding bctf
JOIN Billing.Funding bf ON bctf.FundingID = bf.FundingID
JOIN Billing.Deposit bd ON bctf.FundingID = bd.FundingID AND bd.CID = 12345678
WHERE bctf.CID = 12345678
    AND bf.FundingTypeID = 1
    AND bd.PaymentStatusID = 2;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOOPS-3856 | Jira | Created May 2021 to support "Get all customer funding countries" for AML source-of-funds tracking. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerFundingCountries | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerFundingCountries.sql*
