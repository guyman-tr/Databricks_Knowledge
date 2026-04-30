# Billing.GetDepositsCountries

> Returns the distinct set of countries associated with a customer's approved deposits, extracting country information from payment instrument metadata using funding-type-specific logic (BIN code for cards, IBAN prefix for Giropay, XML fields for wire/PayPal/Trustly).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns DISTINCT CountryID rows for all approved deposits for @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetDepositsCountries` answers: "from which countries has this customer deposited?" It resolves the country of origin for each approved deposit using payment-method-specific extraction logic, then deduplicates to return a distinct set of CountryIDs.

Used in withdrawal/cashout workflows (granted to `WithdrawalServiceUser`) and deposit processing (`DepositUser`). In the context of AML/compliance workflows, knowing the countries associated with a customer's deposit instruments is critical for risk assessment (e.g., validating that withdrawal destination countries are consistent with deposit origins - the Wire AMOP country logic, per MIMOPSA-14349).

**Key history (MIMOPSA-14368, Nov 2024)**: Originally restricted to deposits within the last 12 months (`PaymentDate > DATEADD(year, -1, GETDATE())`). This filter was removed to return ALL-TIME approved deposit countries - needed for the Wire AMOP (Anti-Money-Laundering Operations Processing) country logic initiative that requires full historical deposit footprint.

---

## 2. Business Logic

### 2.1 Funding-Type-Specific Country Extraction

**What**: Country of origin for a deposit is not a direct column in `Billing.Deposit` - it is embedded in payment instrument XML metadata. This SP extracts it using 5 different methods based on FundingTypeID.

**Columns/Parameters Involved**: `Billing.Funding.FundingTypeID`, `Billing.Funding.FundingData`, `Billing.Deposit.PaymentData`, `CountryID (output)`

**Rules**:

| FundingTypeID | Payment Method | Country Extraction Method |
|--------------|----------------|--------------------------|
| 1 | CreditCard | BIN code lookup: `Dictionary.CountryBin WHERE BinCode = FundingData.value('/Funding/BinCodeAsString[1]', INT)` - the card's BIN prefix identifies the issuing country |
| 2 | WireTransfer | Direct XML field: `FundingData.value('/Funding/CountryIDAsInteger[1]', INT)` - wire transfer funding data contains CountryID directly |
| 3 | PayPal | Deposit XML: `PaymentData.value('/Deposit/CountryIDAsString[1]', INT)` - country from the PayPal payment response stored in Billing.Deposit.PaymentData |
| 11 | Giropay | IBAN-based: `SELECT TOP 1 CountryID FROM Dictionary.Country WHERE Abbreviation LIKE SUBSTRING(IBANCodeAsString, 1, 2)` - first 2 chars of IBAN are ISO country code (DE=Germany, AT=Austria, etc.) |
| 35 | Trustly | Name-based: `SELECT TOP 1 CountryID FROM Dictionary.Country WHERE LOWER(Name) LIKE LOWER(PaymentData.value('/Deposit/BankCountryAsString[1]', VARCHAR(8)))` - country name from Trustly payment response |
| All others | - | CASE returns NULL (no country extraction defined) |

**Diagram**:
```
@CID
  |
  -> Billing.Deposit (PaymentStatusID=2, all-time) INNER JOIN Billing.Funding
     |
     FundingTypeID=1  -> BIN code -> Dictionary.CountryBin -> CountryID
     FundingTypeID=2  -> Wire XML.CountryIDAsInteger     -> CountryID
     FundingTypeID=3  -> PayPal Deposit XML.CountryID   -> CountryID
     FundingTypeID=11 -> IBAN[0:2] -> Dictionary.Country.Abbreviation -> CountryID
     FundingTypeID=35 -> Trustly Deposit XML.BankCountry -> Dictionary.Country.Name -> CountryID
     All others       -> NULL
  |
  v
SELECT DISTINCT CountryID (excludes NULLs from unsupported types)
```

### 2.2 Full History Scope (Post-MIMOPSA-14368)

**What**: Returns countries from ALL approved deposits ever, not just the last 12 months.

**Rules**:
- Filter: `bd.PaymentStatusID = 2` (approved only) - no date restriction
- MIMOPSA-14368 (Nov 2024): Removed `AND bd.PaymentDate > DATEADD(year, -1, GETDATE())` to support Wire AMOP (Anti-Money-Laundering Operations Processing) country logic that needs the full deposit country history
- The commented-out line remains in the code as documentation of the change

### 2.3 Deduplication

**What**: Returns DISTINCT CountryIDs - if a customer has 10 approved credit card deposits all from Germany, they get one CountryID=81 row.

**Rules**:
- `SELECT DISTINCT` - NULLs (from unsupported funding types) are also deduplicated; if all deposits are unsupported types, returns a single NULL row or no rows
- Subqueries for Giropay and Trustly use `SELECT TOP 1` to handle any edge cases with multiple country matches

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters to this customer's deposit history. |
| 2 | CountryID (output) | INT | YES | - | CODE-BACKED | Distinct country IDs associated with the customer's approved deposits. Extracted via funding-type-specific logic from FundingData/PaymentData XML. NULL for deposits with unsupported FundingTypeIDs (not 1, 2, 3, 11, or 35). FK to Dictionary.Country.CountryID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.Deposit.CID | Lookup | Filters to customer's deposit history |
| bd.FundingID | Billing.Funding.FundingID | INNER JOIN | Retrieves payment instrument type and XML metadata |
| BinCodeAsString (XML) | Dictionary.CountryBin.BinCode | Subquery Lookup | Resolves CreditCard BIN code to CountryID |
| IBANCodeAsString (XML) | Dictionary.Country.Abbreviation | Subquery Lookup | Resolves Giropay IBAN prefix to CountryID |
| BankCountryAsString (XML) | Dictionary.Country.Name | Subquery Lookup | Resolves Trustly bank country name to CountryID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositUser | GRANT EXECUTE | Permission | Deposit service uses for deposit country queries |
| WithdrawalServiceUser | GRANT EXECUTE | Permission | Withdrawal service uses to validate withdrawal destination against deposit countries (AML/compliance) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetDepositsCountries (procedure)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Dictionary.CountryBin (table) [CreditCard BIN lookup]
└── Dictionary.Country (table) [Giropay IBAN + Trustly name lookup]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | No NOLOCK hint - primary source; filtered by CID and PaymentStatusID=2 |
| Billing.Funding | Table | No NOLOCK hint - INNER JOIN for FundingTypeID and FundingData XML |
| Dictionary.CountryBin | Table | Subquery - maps CreditCard BIN codes to CountryID |
| Dictionary.Country | Table | Subquery - maps Giropay IBAN abbreviation and Trustly country name to CountryID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositUser (deposit service) | DB User | Calls for deposit country queries |
| WithdrawalServiceUser (withdrawal service) | DB User | Calls for AML/compliance country validation in Wire AMOP workflow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No WITH (NOLOCK) | Design | Unlike most Billing read SPs, this one does not use NOLOCK - reads committed data only; important for AML/compliance use where stale reads are unacceptable |
| MIMOPSA-14368 (Nov 2024) | History | Removed 1-year date filter; commented-out line preserved in code. Full history now returned for Wire AMOP country logic. |
| NULL for unsupported types | Design | FundingTypeIDs other than 1, 2, 3, 11, 35 return NULL; DISTINCT includes NULLs as a single row |
| Giropay IBAN subquery | Performance | `SELECT TOP 1 CountryID FROM Dictionary.Country WHERE Abbreviation LIKE SUBSTRING(...)` - scans Dictionary.Country per Giropay deposit; acceptable given low volume |
| Trustly LIKE match | Performance | `WHERE LOWER(Name) LIKE LOWER(...)` on country name - case-insensitive but prevents index use on Name column |

---

## 8. Sample Queries

### 8.1 Get all deposit countries for a customer

```sql
EXEC Billing.GetDepositsCountries @CID = 12345;
```

### 8.2 Manual inline equivalent (CreditCard only)

```sql
SELECT DISTINCT
    cb.CountryID
FROM Billing.Deposit bd
INNER JOIN Billing.Funding bf ON bf.FundingID = bd.FundingID
INNER JOIN Dictionary.CountryBin cb ON cb.BinCode = bf.FundingData.value('(/Funding/BinCodeAsString)[1]', 'INT')
WHERE bd.CID = 12345
  AND bd.PaymentStatusID = 2
  AND bf.FundingTypeID = 1;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPSA-14368 (Nov 2024) | Jira | Removed 1-year date filter from this SP. Part of "Cash Activities - Wire AMOP (Country Logic)" initiative (parent: MIMOPSA-14349) requiring full historical deposit country data for AML compliance workflows. Assigned: Itay Hay. |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 8/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 1 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 1 Jira (MIMOPSA-14368) | Procedures: 0 SQL callers (DepositUser, WithdrawalServiceUser) | App Code: 0 | Corrections: 0 applied*
*Object: Billing.GetDepositsCountries | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetDepositsCountries.sql*
