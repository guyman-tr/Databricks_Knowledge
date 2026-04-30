# Billing.GetCurrencies

> Returns all currencies with a valid ISO 4217 code from Dictionary.Currency, providing the configuration service with the active currency reference list for payment processing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; returns full active-currency list from Dictionary.Currency |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCurrencies` is a configuration loader that exposes the active currency list to the `ConfigurationService`. It returns every currency from `Dictionary.Currency` that has a valid ISO 4217 code (ISOName IS NOT NULL), providing the two-column dataset (CurrencyID, ISOName) that services use to map internal integer currency IDs to standard currency codes like USD, EUR, GBP.

The `WHERE ISOName IS NOT NULL` filter is significant: `Dictionary.Currency` contains 10,669 rows in total, but only 145 have a non-NULL ISO code. The remaining 10,524 rows represent legacy, internal, or non-standard currency entries that are not used in payment processing. This procedure provides only the 145 payment-relevant currencies.

Data flow: The `ConfigurationService` calls this procedure at startup or on configuration refresh to build an in-memory CurrencyID-to-ISOName mapping. This mapping is used throughout the payment pipeline wherever an internal CurrencyID must be converted to a standard code for display, reporting, or external API calls to payment processors.

---

## 2. Business Logic

### 2.1 ISO Currency Filter

**What**: Only currencies with a valid ISO 4217 three-letter code are returned - filtering out 98.6% of the Dictionary.Currency rows that have no ISO code.

**Columns/Parameters Involved**: `ISOName`

**Rules**:
- `WHERE ISOName IS NOT NULL`: excludes 10,524 of 10,669 rows (98.6%) that represent legacy or non-standard entries.
- The 145 returned rows represent currencies actively used in eToro's payment system (USD, EUR, GBP, JPY, AUD, CHF, CAD, NZD, EGP, RUB, and others).
- CurrencyID=1 (USD) is the platform's base currency for all P&L calculations.
- No ORDER BY clause - the caller receives rows in table/index order. Services should not depend on ordering.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Returns** (SELECT output columns):

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CurrencyID | INT | NO | CODE-BACKED | Internal integer identifier for the currency. Used throughout the billing system as a FK to Dictionary.Currency. Key values: 1=USD, 2=EUR, 3=GBP, 4=JPY, 5=AUD, 6=CHF, 7=CAD, 8=NZD. |
| 2 | ISOName | NCHAR/VARCHAR | NO | CODE-BACKED | ISO 4217 three-letter currency code (e.g., USD, EUR, GBP). Always non-NULL in this result set (filtered by WHERE). Used by payment processors, reporting, and display logic to render the human-readable currency symbol. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID, ISOName | Dictionary.Currency | Direct read (SELECT) | Filtered to ISOName IS NOT NULL - returns only the 145 of 10,669 rows with a valid ISO code |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConfigurationServiceUser | EXECUTE grant | Permission | Configuration service loads currency list at startup for in-memory CurrencyID-to-ISO mapping |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCurrencies (procedure)
└── Dictionary.Currency (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | SELECT CurrencyID, ISOName WHERE ISOName IS NOT NULL - 145 rows returned from 10,669 total |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ConfigurationService | External service | Loads currency reference list at startup via ConfigurationServiceUser |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure to get all active currencies

```sql
-- Returns 145 currencies with valid ISO codes
EXEC [Billing].[GetCurrencies]
```

### 8.2 Verify the filter - check how many currencies have no ISO code

```sql
-- Shows the split: ~145 with ISO, ~10524 without
SELECT
    COUNT(CASE WHEN ISOName IS NOT NULL THEN 1 END) AS WithISO,
    COUNT(CASE WHEN ISOName IS NULL THEN 1 END) AS WithoutISO
FROM [Dictionary].[Currency] WITH (NOLOCK)
```

### 8.3 Look up a specific currency by ID or ISO code

```sql
-- Map between CurrencyID and ISO code
SELECT CurrencyID, ISOName
FROM [Dictionary].[Currency] WITH (NOLOCK)
WHERE ISOName IS NOT NULL
  AND ISOName IN ('USD', 'EUR', 'GBP')
ORDER BY CurrencyID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped - no repos; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Live data: 145 currencies confirmed | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCurrencies | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCurrencies.sql*
