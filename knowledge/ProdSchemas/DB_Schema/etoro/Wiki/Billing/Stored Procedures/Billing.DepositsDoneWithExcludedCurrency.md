# Billing.DepositsDoneWithExcludedCurrency

> Diagnostic query that returns deposits processed within the last @hourInterval hours where the deposit currency is in the excluded-currency list for the deposit's country/funding-type/regulation combination - an alerting tool for detecting currency exclusion rule violations.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @hourInterval (default 24h) - pure SELECT, no data modification |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositsDoneWithExcludedCurrency` (PAYUSOLA-7653) is a compliance/operations diagnostic tool that identifies deposits that violate the currency exclusion rules defined in `Billing.ExcludedCurrenciesByCountryAndRegulation`. These rules specify which currencies are not permitted for deposits from certain countries, funding types, or regulatory jurisdictions.

The SP is a pure SELECT - it does not modify any data. It is used to detect and investigate violations after the fact (within the configurable look-back window), allowing operations or compliance teams to take corrective action on any deposits that slipped through the exclusion checks.

The exclusion rule matching uses a "NULL means all" join pattern: if `ExcludedCurrenciesByCountryAndRegulation.CountryID` is NULL, the exclusion applies to all countries; similarly for FundingTypeID and RegulationID.

---

## 2. Business Logic

### 2.1 Excluded Currency Violation Detection

**What**: Finds deposits whose currency matches an excluded-currency rule for their country/funding-type/regulation.

**Columns/Parameters Involved**: `@hourInterval`, `Billing.ExcludedCurrenciesByCountryAndRegulation`, `Billing.Deposit.CurrencyID`

**Rules**:
- Time window: `PaymentDate > DATEADD(hour, -1 * @hourInterval, GETDATE())`.
- Joins `Billing.ExcludedCurrenciesByCountryAndRegulation` ON `Deposit.CurrencyID = e.CurrencyID` (currency must appear in the exclusion table).
- Additional ISNULL-based filters:
  - `c.CountryID = ISNULL(e.CountryID, c.CountryID)` - if e.CountryID is NULL, all countries match.
  - `ft.FundingTypeID = ISNULL(e.FundingTypeID, ft.FundingTypeID)` - if e.FundingTypeID is NULL, all funding types match.
  - `Deposit.ProcessRegulationID = ISNULL(e.RegulationID, Deposit.ProcessRegulationID)` - if e.RegulationID is NULL, all regulations match.
- `SELECT DISTINCT` - deduplicates in case multiple exclusion rules match the same deposit.
- Returns enriched rows with names resolved (FundingTypeName, RegulationName, Currency abbreviation, DepotName, MID, PaymentStatusName).

**Output columns**: DepositID, FundingTypeName, FundingTypeID, RegulationName, RegulationID, Amount, Currency (abbreviation), CurrencyID, DepotName, MID (merchant account), PaymentStatusName, PaymentDate, CountryID.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @hourInterval | INT | NO | 24 | CODE-BACKED | Look-back window in hours. Default 24 hours (last day). Deposits with PaymentDate > NOW - @hourInterval are scanned. Increase for wider historical searches. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID + CountryID + FundingTypeID + RegulationID | Billing.ExcludedCurrenciesByCountryAndRegulation | INNER JOIN | Core violation check - finds deposits whose currency is in the exclusion table for the deposit's country/type/regulation. |
| CID | Customer.Customer | INNER JOIN (cross-schema) | Provides CountryID for the depositor. |
| CID | BackOffice.Customer | INNER JOIN (cross-schema) | Required for the join chain (CID linkage). |
| CurrencyID | Dictionary.Currency | INNER JOIN | Resolves currency abbreviation. |
| MerchantAccountID | Dictionary.MerchantAccount | LEFT JOIN | Resolves MID (merchant account name). |
| ProcessRegulationID | Dictionary.Regulation | INNER JOIN | Resolves regulation name. |
| DepotID | Billing.Depot | INNER JOIN | Resolves depot name. |
| FundingID | Billing.Funding | INNER JOIN | Resolves FundingTypeID. |
| FundingTypeID | Dictionary.FundingType | INNER JOIN | Resolves funding type name. |
| PaymentStatusID | Dictionary.PaymentStatus | INNER JOIN | Resolves payment status name. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations / compliance monitoring | - | EXEC | Called to detect and investigate currency exclusion violations. PAYUSOLA-7653. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositsDoneWithExcludedCurrency (procedure)
+-- Billing.Deposit (table)
+-- Billing.ExcludedCurrenciesByCountryAndRegulation (table)
+-- Billing.Funding (table)
+-- Billing.Depot (table)
+-- Customer.Customer (table) [cross-schema]
+-- BackOffice.Customer (table) [cross-schema]
+-- Dictionary.Currency (table) [cross-schema]
+-- Dictionary.MerchantAccount (table) [cross-schema]
+-- Dictionary.Regulation (table) [cross-schema]
+-- Dictionary.FundingType (table) [cross-schema]
+-- Dictionary.PaymentStatus (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary data source. |
| Billing.ExcludedCurrenciesByCountryAndRegulation | Table | INNER JOIN - defines which currencies are excluded per country/type/regulation. |
| Billing.Funding | Table | INNER JOIN - FundingTypeID resolution. |
| Billing.Depot | Table | INNER JOIN - depot name resolution. |
| Customer.Customer | Table (cross-schema) | INNER JOIN - CountryID for depositor. |
| BackOffice.Customer | Table (cross-schema) | INNER JOIN - CID linkage. |
| Dictionary.Currency | Table (cross-schema) | INNER JOIN - currency abbreviation. |
| Dictionary.MerchantAccount | Table (cross-schema) | LEFT JOIN - MID name. |
| Dictionary.Regulation | Table (cross-schema) | INNER JOIN - regulation name. |
| Dictionary.FundingType | Table (cross-schema) | INNER JOIN - funding type name. |
| Dictionary.PaymentStatus | Table (cross-schema) | INNER JOIN - payment status name. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations/compliance monitoring tools | External | EXEC - violation detection. |

---

## 7. Technical Details

**Key join pattern**: `c.CountryID = ISNULL(e.CountryID, c.CountryID)` is a "NULL means wildcard" pattern: when the exclusion rule has NULL for a dimension, it matches all values of that dimension. This allows defining broad exclusions (e.g., "no USD deposits via CreditCard, globally") or narrow ones (e.g., "no EUR deposits via PayPal from Germany under FCA").

**No transaction / no modification**: Pure SELECT, safe to run anytime without side effects.

---

## 8. Sample Queries

### 8.1 Check last 24 hours for violations (default)

```sql
EXEC [Billing].[DepositsDoneWithExcludedCurrency];
```

### 8.2 Extend look-back to last 7 days

```sql
EXEC [Billing].[DepositsDoneWithExcludedCurrency] @hourInterval = 168;
```

### 8.3 View active exclusion rules

```sql
SELECT CurrencyID, CountryID, FundingTypeID, RegulationID, IsActive
FROM [Billing].[ExcludedCurrenciesByCountryAndRegulation] WITH (NOLOCK)
WHERE IsActive = 1
ORDER BY CurrencyID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositsDoneWithExcludedCurrency | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositsDoneWithExcludedCurrency.sql*
