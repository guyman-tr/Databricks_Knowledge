# Billing.GetFundingTypesWithOverrides

> Returns the currency-level payment method availability for a country, applying country-specific currency overrides that replace the default depot-routing currencies when configured.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CountryID - primary filter; returns one row per (FundingType, Currency) combination |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetFundingTypesWithOverrides` is the currency-aware variant of the payment method availability query. While `GetFundingTypesByCountry` aggregates currencies into a comma-separated string, this procedure returns **one row per (FundingType, Currency) combination** and applies the `Billing.CurrencyPerFundingTypeOverrides` table to substitute country-specific currency sets in place of the default depot routing.

The procedure exists because some countries require non-standard currency offerings for certain payment methods. For example, a country may require PayPal to present only EUR (not the default USD+EUR+GBP set the depot routing would provide). The override table controls this substitution; this procedure implements it with a EXCEPT/UNION ALL pattern.

Data flows exclusively outward - read-only. Granted EXECUTE to `DepositSetupUser`, indicating it is called from the deposit configuration/setup service. The optional `@CID` is used only for iDEAL (FundingTypeID=34) bank pre-fill, identical to `GetFundingTypesByCountry`.

Code comment: "23/06/2021 Masksym S. Use FundingType rank rather than overrides PAYUA-2188" - the Rank column in the result comes from FundingTypeCountries.Rank (the funding type display rank) rather than a rank stored in the override table, following this change.

---

## 2. Business Logic

### 2.1 Override Replacement Pattern (Full Substitution, Not Additive)

**What**: When `Billing.CurrencyPerFundingTypeOverrides` has any row for (CountryID, FundingTypeID), ALL default depot-routing currencies for that funding type are replaced by the override set. It is a complete substitution.

**Columns/Parameters Involved**: `CurrencyOverrides` CTE, `Currencies` CTE, `IsDefault`, `CurrencyRank`

**Rules**:
- `CurrencyOverrides` CTE: overrides rows for `@CountryID` - joined through DepotToCurrency to verify the override currencies are still depot-routable (dtc.IsActive=1)
- `Currencies` CTE: standard depot-based currency set for `@CountryID` (all active depot-currency pairs for each funding type available in the country)
- Final query: `(Currencies EXCEPT Currencies-for-funding-types-with-any-override) UNION ALL CurrencyOverrides`
- Effect: if FundingTypeID X has ANY override row for @CountryID, ALL of X's standard currencies are removed and replaced with only the override currencies
- Override rows carry `IsDefault` (which currency is the default) and `CurrencyRank` (display order within the funding type); standard rows have `IsDefault=0` and `CurrencyRank=NULL`

**Diagram**:
```
@CountryID = 1 (USA), FundingType=1 (CreditCard):

  Currencies CTE (standard):
    (FT=1, CurrencyID=1)  IsDefault=0, CurrencyRank=NULL
    (FT=1, CurrencyID=2)  IsDefault=0, CurrencyRank=NULL
    (FT=1, CurrencyID=3)  IsDefault=0, CurrencyRank=NULL

  CurrencyOverrides CTE (override found for CountryID=1, FT=1):
    (FT=1, CurrencyID=1)  IsDefault=1, CurrencyRank=1  <- USD as default
    (FT=1, CurrencyID=2)  IsDefault=0, CurrencyRank=2

  Result:
    Standard (FT=1) rows REMOVED by EXCEPT
    Override (FT=1) rows ADDED by UNION ALL
    -> Customer sees: USD (default, rank 1), EUR (rank 2) only
```

### 2.2 Per-Currency Row Output (vs. Aggregated CSV in GetFundingTypesByCountry)

**What**: Unlike `GetFundingTypesByCountry` which returns one row per funding type with currencies as a CSV string, this procedure returns one row per (FundingType, Currency) pair, enabling richer per-currency metadata.

**Columns/Parameters Involved**: `FundingTypeID`, `CurrencyID`, `IsDefault`, `CurrencyRank`

**Rules**:
- Use this procedure when the consumer needs to know: which currency is the default, what rank order currencies should appear in, and whether a funding type has overrides (override rows have non-NULL CountryID and CurrencyRank)
- Use `GetFundingTypesByCountry` when only a flat CSV of currencies per funding type is needed
- The `dtc.IsActive = 1` filter in both CTEs ensures only active depot-currency pairs are considered

### 2.3 iDEAL Special Case (FundingTypeID=34)

**What**: Identical to `GetFundingTypesByCountry` - iDEAL rows get ExtraData with the customer's last-used bank details.

**Columns/Parameters Involved**: `@CID`, `ExtraData`, `FundingTypeID=34`

**Rules**:
- `IIF(ft.FundingTypeID = 34, Billing.GetFundingExtraData(@CID, 34), NULL)` applied in both CTEs
- All non-iDEAL rows return NULL for ExtraData
- @CID only matters when FundingTypeID=34 rows are in the result set

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CountryID | INT | NO | - | CODE-BACKED | Country to look up payment method currencies for. Filters both CTEs to this country. FK to Dictionary.Country. |
| 2 | @CID | INT | YES | NULL | CODE-BACKED | Customer ID. Optional - only consumed by Billing.GetFundingExtraData when FundingTypeID=34 (iDEAL) is in the result. Pass NULL when iDEAL pre-fill is not needed. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method ID. Identifies the payment method (e.g., 1=CreditCard, 7=PayPal, 34=iDEAL). From Billing.FundingTypeCountries and Billing.CurrencyPerFundingTypeOverrides. |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Currency ID from Dictionary.Currency that this payment method supports in the given country. One row per (FundingTypeID, CurrencyID) combination. |
| 5 | IsDefault | bit | NO | - | CODE-BACKED | Whether this currency is the default selection for this funding type. 1=default pre-selected currency; 0=available but not default. Populated from CurrencyPerFundingTypeOverrides.IsDefault for override rows; always 0 for standard rows. |
| 6 | CountryID | int | YES | NULL | CODE-BACKED | NULL for standard depot-routing rows; equals @CountryID for override rows. Distinguishes override rows from standard rows - a non-NULL value indicates this (FundingType, Currency) combination comes from the overrides table. |
| 7 | Rank | int | NO | - | CODE-BACKED | Display rank of the funding type for this country (from Billing.FundingTypeCountries.Rank). Controls the order in which funding types appear in the payment method UI. Per PAYUA-2188 (2021), this is the FundingType-level rank, not the currency-level rank. |
| 8 | ExtraData | nvarchar(MAX) | YES | NULL | CODE-BACKED | JSON bank pre-fill data for iDEAL (FundingTypeID=34) only: `{"LastUsedBank":{"Bic":"...","BankName":"..."}}` from Billing.GetFundingExtraData. NULL for all other payment methods. |
| 9 | CurrencyRank | int | YES | NULL | CODE-BACKED | Display rank of this currency within the funding type. Populated from CurrencyPerFundingTypeOverrides.Rank for override rows; NULL for standard rows. Controls the order currencies are presented within a payment method selector. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| overrides (CurrencyOverrides CTE) | Billing.CurrencyPerFundingTypeOverrides | Direct Read | Source of country-specific currency override rows with IsDefault and CurrencyRank |
| ft (both CTEs) | Billing.FundingTypeCountries | Direct Read | Country-funding availability matrix and funding type display rank |
| dtc (both CTEs) | Billing.DepotToCurrency | Direct Read | Active depot-currency routing - filters to dtc.IsActive=1 |
| depot (both CTEs) | Billing.Depot | Direct Read | Payment gateway registry - joins DepotToCurrency to FundingType |
| GetFundingExtraData | Billing.GetFundingExtraData | Function Call | Conditional (FundingTypeID=34 only) - retrieves iDEAL last-used bank details |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositSetupUser (permissions) | EXECUTE grant | Permission | Deposit configuration/setup service role that calls this procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingTypesWithOverrides (procedure)
├── Billing.CurrencyPerFundingTypeOverrides (table)
├── Billing.FundingTypeCountries (table)
├── Billing.DepotToCurrency (table)
├── Billing.Depot (table)
└── Billing.GetFundingExtraData (scalar function)
      ├── Billing.Funding (table)
      └── Billing.Deposit (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CurrencyPerFundingTypeOverrides | Table | CurrencyOverrides CTE - provides country-specific currency override sets with IsDefault and CurrencyRank |
| Billing.FundingTypeCountries | Table | Both CTEs - provides country-funding availability and display rank |
| Billing.DepotToCurrency | Table | Both CTEs - validates depot-currency pairings (filtered to IsActive=1); WITH(NOLOCK) applied per 2024 change |
| Billing.Depot | Table | Both CTEs - joins DepotToCurrency to FundingType |
| Billing.GetFundingExtraData | Scalar Function | Called conditionally for FundingTypeID=34 only |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositSetupUser | DB Role/User | EXECUTE permission granted - deposit setup service is the primary consumer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute to get all payment method currencies for a country

```sql
EXEC Billing.GetFundingTypesWithOverrides @CountryID = 1  -- USA
```

### 8.2 Execute with customer ID for iDEAL countries

```sql
EXEC Billing.GetFundingTypesWithOverrides @CountryID = 161, @CID = 12345678
-- Netherlands - iDEAL rows get ExtraData with last-used bank
```

### 8.3 Identify which funding types have currency overrides vs standard routing for a country

```sql
-- Rows with CountryID IS NOT NULL = from override table
-- Rows with CountryID IS NULL = from standard depot routing
EXEC Billing.GetFundingTypesWithOverrides @CountryID = 1
-- Compare CountryID column to distinguish override vs standard rows
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Billing Service Database Readonly Separation | Confluence | Page found but no page ID available to fetch content |
| Deposit Setup - Trading Eligible Payment Method Types | Confluence | Page likely contains deposit setup flow context for this procedure |
| Deposit Info Current Structure and Data | Confluence | Page found but no page ID available to fetch content |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingTypesWithOverrides | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetFundingTypesWithOverrides.sql*
