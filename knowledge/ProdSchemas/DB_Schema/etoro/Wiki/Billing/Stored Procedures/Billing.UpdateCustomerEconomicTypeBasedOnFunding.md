# Billing.UpdateCustomerEconomicTypeBasedOnFunding

> Automatically assigns a customer's Enhanced Due Diligence (EDD) flag based on the BIN country of their deposit's card, via the economic classification in the country dictionary.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer) + @FundingID (deposit) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a customer makes a credit card deposit, the card's BIN (Bank Identification Number) reveals the issuing country. In some countries, regulations require Enhanced Due Diligence (EDD) - heightened identity verification and transaction monitoring under KYC/AML compliance rules. `Billing.UpdateCustomerEconomicTypeBasedOnFunding` automates this classification: it extracts the BIN country from the funding record's XML data, looks up whether that country has a non-zero economic classification, and if so, flags the customer for EDD.

The procedure is the automated EDD assignment path. The manual path (compliance operators setting EDD directly) goes through `Billing.UpdateCustomerEDD` independently. Both paths converge on the same `BackOffice.Customer.IsEDD` flag.

The BIN country is stored as XML inside `Billing.Funding.FundingData`, extracted via XQuery: `Funding[1]/BinCountryIDAsInteger[1]`. The economic type is looked up from `Dictionary.Country.EconomicTypeID`. A non-zero `EconomicTypeID` indicates the country requires EDD treatment - any non-zero value passed to `Billing.UpdateCustomerEDD` as `@IsEDD` converts to `BIT=1` (EDD enabled). A zero value in either lookup causes a silent no-op (no EDD flag set).

Created by Geri Reshef, 05/07/2017, ticket 46690 (OPS0333 - EDD flag in Back Office).

---

## 2. Business Logic

### 2.1 BIN Country to EDD Classification Pipeline

**What**: A three-step compliance classification pipeline: BIN country extraction -> economic type lookup -> EDD flag assignment.

**Columns/Parameters Involved**: `@FundingID`, `Billing.Funding.FundingData` (XML), `Dictionary.Country.EconomicTypeID`, `@CID`

**Rules**:
- Step 1: Extract `BinCountryIDAsInteger` from `Billing.Funding.FundingData` XML for `@FundingID`. This is the country of the card's issuing bank, derived from the first 6 digits of the card number.
- Step 2: If `@BinCountryID <> 0` (valid country found in BIN): look up `EconomicTypeID` from `Dictionary.Country` for that country.
- Step 3: If `@EconomicTypeID <> 0` (country has a non-default economic classification): call `Billing.UpdateCustomerEDD @CID, @EconomicTypeID`. The non-zero integer passes as `@IsEDD` and converts to `BIT=1`, enabling EDD for the customer.
- Both zero-checks act as guards: a zero at either step means no EDD flag is set (silent no-op).
- No return value or error raised. If the funding record is missing or the XML is malformed, `@BinCountryID` will be NULL, and `NULL <> 0` evaluates as unknown (not true), so the no-op path is taken.

**Diagram**:
```
@FundingID
  --> SELECT BinCountryIDAsInteger FROM Billing.Funding.FundingData (XML)
      = @BinCountryID

  IF @BinCountryID <> 0:
    --> SELECT EconomicTypeID FROM Dictionary.Country WHERE CountryID = @BinCountryID
        = @EconomicTypeID

    IF @EconomicTypeID <> 0:
      --> EXEC Billing.UpdateCustomerEDD @CID, @EconomicTypeID
          --> UPDATE BackOffice.Customer SET IsEDD=1 WHERE CID=@CID
```

### 2.2 Implicit BIT Conversion for EDD Flag

**What**: `@EconomicTypeID` (INT) is passed directly as the `@IsEDD` (BIT) parameter to `UpdateCustomerEDD`, using SQL Server's implicit INT-to-BIT conversion.

**Columns/Parameters Involved**: `@EconomicTypeID`, `Billing.UpdateCustomerEDD.@IsEDD`

**Rules**:
- Any `EconomicTypeID <> 0` converts to `BIT=1` (EDD enabled) when passed to `UpdateCustomerEDD`.
- The actual value of `EconomicTypeID` is irrelevant - only its zero/non-zero status matters.
- The guard condition `IF @EconomicTypeID <> 0` ensures the conversion is always from a non-zero value, so EDD is always enabled (not disabled) by this automated path.
- To disable EDD via this path is not possible - only the manual `UpdateCustomerEDD @CID, 0` path clears the flag.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Passed to `Billing.UpdateCustomerEDD` to update `BackOffice.Customer.IsEDD` for this customer. |
| 2 | @FundingID | INT | NO | - | CODE-BACKED | FK to `Billing.Funding.FundingID`. The deposit whose card BIN country is used to determine EDD classification. The BIN country is extracted from `Billing.Funding.FundingData` XML. |

**Internal variables:**
| # | Element | Type | Notes |
|---|---------|------|-------|
| @BinCountryID | INT | Extracted from `Funding.FundingData` XML via XQuery. `0` or `NULL` means no valid BIN country - no EDD action taken. |
| @EconomicTypeID | INT | Looked up from `Dictionary.Country.EconomicTypeID` for `@BinCountryID`. `0` means the country has no special economic classification - no EDD action taken. Non-zero triggers EDD. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID | Billing.Funding | READ (XML) | Reads FundingData XML to extract BinCountryIDAsInteger |
| @BinCountryID | Dictionary.Country | Lookup | Looks up EconomicTypeID for the BIN country |
| @CID | BackOffice.Customer (via delegation) | UPDATE | EDD flag on BackOffice.Customer is updated via UpdateCustomerEDD |
| (delegated) | Billing.UpdateCustomerEDD | EXEC | Sets BackOffice.Customer.IsEDD=1 for the customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins permission grant | - | GRANT EXECUTE | BI admins role has execute permission |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateCustomerEconomicTypeBasedOnFunding (procedure)
├── Billing.Funding (table) [READ XML]
├── Dictionary.Country (table) [READ - EconomicTypeID lookup]
└── Billing.UpdateCustomerEDD (procedure)
      └── BackOffice.Customer (table) [UPDATE IsEDD]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | Reads FundingData XML to extract BIN country ID |
| Dictionary.Country | Table | Looks up EconomicTypeID for the card's issuing country |
| Billing.UpdateCustomerEDD | Stored Procedure | EXEC - sets the customer's EDD flag based on derived economic type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (billing service or deposit processors) | Application | Called during or after deposit processing to apply automated EDD classification |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BIN country guard | Conditional | `IF @BinCountryID <> 0` - skips EDD if no valid BIN country in XML |
| Economic type guard | Conditional | `IF @EconomicTypeID <> 0` - skips EDD if country has no special classification |
| NULL handling | Implicit | NULL BinCountryID from missing XML value: `NULL <> 0` is UNKNOWN, so IF block is skipped (no-op) |

---

## 8. Sample Queries

### 8.1 Check a customer's current EDD status and the BIN country that may have triggered it
```sql
SELECT
    f.FundingID,
    f.FundingData.value('Funding[1]/BinCountryIDAsInteger[1]', 'INT') AS BinCountryID,
    c.CountryID,
    c.EconomicTypeID,
    bo.IsEDD
FROM Billing.Funding f WITH (NOLOCK)
JOIN Dictionary.Country c WITH (NOLOCK)
    ON c.CountryID = f.FundingData.value('Funding[1]/BinCountryIDAsInteger[1]', 'INT')
JOIN BackOffice.Customer bo WITH (NOLOCK)
    ON bo.CID = f.CustomerID
WHERE f.FundingID = 12345;
```

### 8.2 Find countries that trigger EDD (non-zero EconomicTypeID)
```sql
SELECT
    CountryID,
    CountryName,
    EconomicTypeID
FROM Dictionary.Country WITH (NOLOCK)
WHERE EconomicTypeID <> 0
ORDER BY CountryName;
```

### 8.3 Execute automated EDD classification for a specific deposit
```sql
-- Triggered during deposit processing for compliance classification
EXEC Billing.UpdateCustomerEconomicTypeBasedOnFunding
    @CID      = 100001,
    @FundingID = 55001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (UpdateCustomerEDD) | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.UpdateCustomerEconomicTypeBasedOnFunding | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateCustomerEconomicTypeBasedOnFunding.sql*
