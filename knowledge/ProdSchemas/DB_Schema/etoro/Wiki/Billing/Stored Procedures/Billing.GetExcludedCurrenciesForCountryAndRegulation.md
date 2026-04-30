# Billing.GetExcludedCurrenciesForCountryAndRegulation

> Returns the list of currency + funding type combinations that are blocked for a given country and regulatory jurisdiction, used to filter out payment options that are not permitted for that customer segment.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @countryId + @regulationId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Different countries and regulatory jurisdictions have specific rules about which currencies and payment methods (funding types) are allowed. For example, a regulatory body may prohibit certain currencies for deposits in a specific region, or a country may restrict specific payment rails entirely.

This procedure queries Billing.ExcludedCurrenciesByCountryAndRegulation to retrieve all (CurrencyID, FundingTypeID) combinations that should be excluded for a given country and regulation. The calling service uses this list to filter out payment options before presenting them to the customer during the deposit or withdrawal flow.

The NULL-safe filter logic (`ISNULL(CountryID, @countryId) = @countryId AND ISNULL(RegulationID, @regulationId) = @regulationId`) means rows with NULL CountryID or NULL RegulationID act as wildcards - they match any country or any regulation respectively, allowing global exclusions to be expressed alongside country-specific ones.

---

## 2. Business Logic

### 2.1 NULL-Safe Country and Regulation Matching

**What**: Rows with NULL CountryID or NULL RegulationID act as wildcard exclusions.

**Columns/Parameters Involved**: `@countryId`, `@regulationId`

**Rules**:
- `ISNULL(CountryID, @countryId) = @countryId`: A row where CountryID IS NULL always satisfies this (because ISNULL makes it equal to @countryId). This means a NULL CountryID = "exclude for ALL countries"
- `ISNULL(RegulationID, @regulationId) = @regulationId`: Same logic - NULL RegulationID = "exclude for ALL regulations"
- A row with both NULL: excluded globally (any country, any regulation)
- A row with CountryID only set: excluded for that country regardless of regulation
- A row with RegulationID only set: excluded for that regulation regardless of country
- A row with both set: excluded only for that specific country + regulation combination

**Diagram**:
```
Exclusion applicability matrix:
CountryID | RegulationID | Applies When
----------|-------------|-------------
NULL      | NULL         | Always (global exclusion)
NULL      | 5            | Any country under regulation 5
103       | NULL         | Country 103 under any regulation
103       | 5            | Only country 103 under regulation 5
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @countryId | INT | NO | - | CODE-BACKED | Country identifier for the customer. Used with NULL-safe filter to match country-specific and global exclusions. Lookup: Dictionary.Country. |
| 2 | @regulationId | INT | NO | - | CODE-BACKED | Regulatory jurisdiction identifier for the customer's account. Used to match regulation-specific exclusions. Applied alongside @countryId for combined filtering. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | CurrencyID | INT | NO | - | CODE-BACKED | Currency that is excluded for the given country/regulation. Lookup: Dictionary.Currency. Callers remove this currency from the available funding options. |
| R2 | FundingTypeID | INT | NO | - | CODE-BACKED | Payment method that is excluded for this currency + country/regulation combination. Lookup: Dictionary.FundingType. The exclusion applies specifically to this funding type (not all funding types for the currency). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @countryId + @regulationId | Billing.ExcludedCurrenciesByCountryAndRegulation | Lookup | Source of all exclusion rules |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application payment services | @countryId + @regulationId | EXEC | Called during deposit/withdrawal flow to filter disallowed currencies |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetExcludedCurrenciesForCountryAndRegulation (procedure)
└── Billing.ExcludedCurrenciesByCountryAndRegulation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ExcludedCurrenciesByCountryAndRegulation | Table | SELECT CurrencyID, FundingTypeID with NULL-safe country/regulation filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from application payment layer. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all excluded currencies for a specific country and regulation

```sql
EXEC Billing.GetExcludedCurrenciesForCountryAndRegulation
    @countryId = 103,
    @regulationId = 2;
```

### 8.2 View all global exclusion rules (NULL country or regulation)

```sql
SELECT CurrencyID, FundingTypeID, CountryID, RegulationID
FROM Billing.ExcludedCurrenciesByCountryAndRegulation WITH (NOLOCK)
WHERE CountryID IS NULL OR RegulationID IS NULL;
```

### 8.3 Check if a specific currency is excluded for a country

```sql
SELECT CurrencyID, FundingTypeID
FROM Billing.ExcludedCurrenciesByCountryAndRegulation WITH (NOLOCK)
WHERE ISNULL(CountryID, 103) = 103
  AND ISNULL(RegulationID, 2) = 2
  AND CurrencyID = 2; -- EUR
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetExcludedCurrenciesForCountryAndRegulation | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetExcludedCurrenciesForCountryAndRegulation.sql*
