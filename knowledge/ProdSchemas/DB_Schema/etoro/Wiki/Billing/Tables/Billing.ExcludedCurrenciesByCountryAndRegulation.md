# Billing.ExcludedCurrenciesByCountryAndRegulation

> Configuration table defining which account currencies are excluded from specific payment methods by country and regulatory jurisdiction - used to restrict deposit currency options for compliance and payment processor rules.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | None (no PK, no indexes) |
| **Partition** | No (DICTIONARY filegroup) |
| **Indexes** | 0 |

---

## 1. Business Meaning

`Billing.ExcludedCurrenciesByCountryAndRegulation` is a regulatory/business configuration table that defines which account currencies cannot be used when depositing via a specific payment method in a given country and regulation. When a customer initiates a deposit, the system calls `Billing.GetExcludedCurrenciesForCountryAndRegulation` to retrieve the list of (CurrencyID, FundingTypeID) pairs that are blocked for that customer's country+regulation, then removes them from available deposit currency options.

This enables compliance with regional rules - for example, the FSRA regulation (Abu Dhabi) may prohibit EUR or GBP credit card deposits from certain countries. The table contains 231 rows covering 14 regulatory jurisdictions (0=None through 13=MAS), 16 countries, 15 currencies, and 2 payment methods (CreditCard and WireTransfer).

The WHERE clause in the procedure uses `ISNULL(CountryID, @countryId) = @countryId` - a NULL country value in the table would match ALL countries (wildcard pattern). However, no NULL rows exist in current data. Similarly for RegulationID. The table is stored on the DICTIONARY filegroup, consistent with other reference/configuration tables.

---

## 2. Business Logic

### 2.1 Currency Exclusion Lookup

**What**: Returns the list of (CurrencyID, FundingTypeID) pairs excluded for a customer's country+regulation.

**Columns/Parameters Involved**: `CurrencyID`, `CountryID`, `RegulationID`, `FundingTypeID`

**Rules**:
- `GetExcludedCurrenciesForCountryAndRegulation(@countryId, @regulationId)` queries:
  ```sql
  SELECT CurrencyID, FundingTypeID
  FROM Billing.ExcludedCurrenciesByCountryAndRegulation
  WHERE ISNULL(CountryID, @countryId) = @countryId
  AND ISNULL(RegulationID, @regulationId) = @regulationId
  ```
- The ISNULL pattern allows wildcard rows: a row with NULL CountryID matches any country for that regulation. Currently all rows have explicit CountryID.
- A row in this table = "this CurrencyID is excluded when depositing via this FundingTypeID from this country under this regulation."
- FundingTypeID=2 (WireTransfer) has more exclusions (175 rows) than FundingTypeID=1 (CreditCard, 56 rows).
- Called by `Billing.GetCustomerDepositInfo` (indirectly, via deposit flow).

### 2.2 Audit Procedure

**What**: `Billing.DepositsDoneWithExcludedCurrency` identifies historical deposits that violated exclusion rules.

**Rules**:
- This procedure exists to audit compliance - finding deposits that were processed despite currency exclusion rules.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 231 |
| FundingTypeID=1 (CreditCard) | 56 rows |
| FundingTypeID=2 (WireTransfer) | 175 rows |
| Unique currencies excluded | 15 |
| Unique countries affected | 16 |
| Unique regulations | 14 (IDs: 0,1,2,3,4,5,6,7,8,9,10,11,12,13) |
| NULL country rows | 0 |
| NULL regulation rows | 0 |

Sample: CurrencyID=2 (EUR) and CurrencyID=3 (GBP) are excluded for CreditCard (FundingTypeID=1) deposits under RegulationID=11 (FSRA) for 5 specific countries.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyID | int | YES | - | CODE-BACKED | Account currency that is excluded for deposits. Implicit FK to Dictionary.Currency. 15 distinct values observed. NULL would mean "all currencies excluded" but no NULL rows exist. Used in WHERE ISNULL(CountryID,...) pattern. |
| 2 | CountryID | int | YES | - | CODE-BACKED | Customer's country for this exclusion rule. Implicit FK to Dictionary.Country. 16 distinct countries affected. NULL allowed (wildcard - would match any country) but no NULL rows in current data. |
| 3 | RegulationID | int | YES | - | CODE-BACKED | Regulatory jurisdiction for this exclusion rule. Implicit FK to Dictionary.Regulation. Values: 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC & GAML, 11=FSRA, 12=FINRAONLY, 13=MAS. NULL allowed (wildcard) but no NULL rows in current data. |
| 4 | FundingTypeID | int | YES | - | CODE-BACKED | Payment method for which the currency is excluded. Implicit FK to Dictionary.FundingType. Values: 1=CreditCard (56 rows), 2=WireTransfer (175 rows). NULL allowed but no NULL rows. Returned alongside CurrencyID to tell the caller which payment method is restricted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | Implicit FK | Currency excluded from the payment method. |
| CountryID | Dictionary.Country | Implicit FK | Country for which the exclusion applies. |
| RegulationID | Dictionary.Regulation | Implicit FK | Regulatory jurisdiction for the exclusion. |
| FundingTypeID | Dictionary.FundingType | Implicit FK | Payment method restricted for this currency+country+regulation. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetExcludedCurrenciesForCountryAndRegulation | CountryID, RegulationID | READER | Returns excluded (CurrencyID, FundingTypeID) pairs for a customer's country and regulation. Primary read path. |
| Billing.DepositsDoneWithExcludedCurrency | (all columns) | READER | Audit procedure that identifies deposits processed in violation of exclusion rules. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies (no FK constraints, all nullable columns).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetExcludedCurrenciesForCountryAndRegulation | Stored Procedure | READER - returns applicable exclusions for deposit flow |
| Billing.DepositsDoneWithExcludedCurrency | Stored Procedure | READER - compliance audit for deposits in excluded currencies |

---

## 7. Technical Details

### 7.1 Indexes

None. No PK, no clustered index, no nonclustered indexes. Full scan for each lookup (acceptable given 231 rows).

### 7.2 Constraints

None. All columns are nullable. No PK, UNIQUE, DEFAULT, or CHECK constraints.

### 7.3 Notes

- DICTIONARY filegroup - consistent with other reference/configuration tables.
- No version tracking (non-temporal) - configuration changes are not audited by the table itself.

---

## 8. Sample Queries

### 8.1 Get excluded currencies for a customer's country and regulation

```sql
EXEC [Billing].[GetExcludedCurrenciesForCountryAndRegulation] @countryId = 15, @regulationId = 11;
```

### 8.2 View all exclusions with readable names

```sql
SELECT e.CurrencyID, c.Abbreviation AS Currency, e.CountryID, co.Name AS Country,
    e.RegulationID, r.Name AS Regulation, e.FundingTypeID, ft.Name AS FundingType
FROM [Billing].[ExcludedCurrenciesByCountryAndRegulation] e WITH (NOLOCK)
LEFT JOIN [Dictionary].[Currency] c WITH (NOLOCK) ON e.CurrencyID = c.CurrencyID
LEFT JOIN [Dictionary].[Country] co WITH (NOLOCK) ON e.CountryID = co.CountryID
LEFT JOIN [Dictionary].[Regulation] r WITH (NOLOCK) ON e.RegulationID = r.ID
LEFT JOIN [Dictionary].[FundingType] ft WITH (NOLOCK) ON e.FundingTypeID = ft.FundingTypeID
ORDER BY e.RegulationID, e.CountryID, e.FundingTypeID, e.CurrencyID;
```

### 8.3 Summary of exclusions by regulation and payment method

```sql
SELECT r.Name AS Regulation, ft.Name AS FundingType,
    COUNT(*) AS ExclusionRules, COUNT(DISTINCT e.CurrencyID) AS UniqueCurrencies
FROM [Billing].[ExcludedCurrenciesByCountryAndRegulation] e WITH (NOLOCK)
LEFT JOIN [Dictionary].[Regulation] r WITH (NOLOCK) ON e.RegulationID = r.ID
LEFT JOIN [Dictionary].[FundingType] ft WITH (NOLOCK) ON e.FundingTypeID = ft.FundingTypeID
GROUP BY r.Name, ft.Name
ORDER BY ExclusionRules DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ExcludedCurrenciesByCountryAndRegulation | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ExcludedCurrenciesByCountryAndRegulation.sql*
