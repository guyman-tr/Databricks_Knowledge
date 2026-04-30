# Billing.CurrencyPerFundingTypeOverrides

> Per-country, per-funding-type override table that specifies which currencies are available (and in what rank order) for a payment method in a given country; overrides the default depot-based currency list when present.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (CountryID, FundingTypeID, CurrencyID) - composite PK CLUSTERED |
| **Partition** | N/A - PRIMARY filegroup |
| **Indexes** | 1 (composite PK) |
| **System-Versioned** | YES - History.BillingCurrencyPerFundingTypeOverrides |

---

## 1. Business Meaning

`Billing.CurrencyPerFundingTypeOverrides` defines which currencies are offered to customers when they select a specific payment method in a specific country. When a customer in CountryID=1 (USA) initiates a deposit via FundingTypeID=1, this table provides the ordered currency list for that combination.

The table holds 2,527 rows. Its purpose is to OVERRIDE the default currency set derived from the depot/currency mapping (Billing.DepotToCurrency). When overrides exist for a (CountryID, FundingTypeID) pair, the entire default currency list for that funding type is replaced by the overrides. When no overrides exist, the default depot currencies apply.

`GetFundingTypesWithOverrides` implements the override logic: using a CTE with EXCEPT + UNION ALL, it removes default currencies for any funding type that has overrides, then appends the override currencies with their explicit Rank and IsDefault settings.

The table is system-versioned - all changes are tracked in History.BillingCurrencyPerFundingTypeOverrides with ValidFrom/ValidTo timestamps.

---

## 2. Business Logic

### 2.1 Override Replacement Pattern (Not Supplement)

**What**: When CurrencyPerFundingTypeOverrides has any row for (CountryID, FundingTypeID), ALL default currencies for that funding type in that country are REPLACED by the override rows. This is a full substitution, not an additive override.

**Columns/Parameters Involved**: `CountryID`, `FundingTypeID`, `CurrencyID`, `IsDefault`, `Rank`

**Rules**:
```
GetFundingTypesWithOverrides logic:
  CurrencyOverrides CTE: overrides rows for @CountryID
  Currencies CTE: default depot-based currencies for @CountryID

  Result = (Currencies EXCEPT (Currencies for funding types that have any override))
           UNION ALL CurrencyOverrides

  -> If FundingTypeID has overrides: only override currencies shown (with Rank/IsDefault)
  -> If FundingTypeID has no overrides: default depot currencies shown (IsDefault=0, CurrencyRank=NULL)
```

**Diagram**:
```
Customer in Country=1 deposits via FundingType=1:
  GetFundingTypesWithOverrides(@CountryID=1)

  Override rows found for (1,1):
    CurrencyID=1, IsDefault=1, Rank=1  -> USD (default, first choice)
    CurrencyID=2, IsDefault=0, Rank=2  -> EUR (available, second choice)
    CurrencyID=3, IsDefault=0, Rank=3  -> GBP (available, third choice)

  Default depot currencies for FundingType=1 are SUPPRESSED.
  Customer sees: USD (default), EUR, GBP in that order.

  If no override rows for (1,99): default depot currencies shown as-is.
```

### 2.2 IsDefault and Rank Semantics

**What**: Each override row declares one currency as the pre-selected default and ranks all currencies for display order.

**Columns/Parameters Involved**: `IsDefault`, `Rank`

**Rules**:
- `IsDefault = 1`: This currency is the pre-selected/recommended currency for this (country, funding type) combination. Only one currency per (CountryID, FundingTypeID) should be IsDefault=1.
- `IsDefault = 0`: Currency is available but not pre-selected.
- `Rank`: Display order (ascending). Rank=1 is shown first. DEFAULT 1 means all rows are rank 1 unless explicitly set.
- `GetRanksByCountryAndFundingType` returns Rank+CurrencyID ordered by Rank - used for lightweight currency order lookups.

### 2.3 Trace Computed Column (Audit Trail)

**What**: Every row carries an auto-computed JSON string recording who/what last touched it.

**Columns/Parameters Involved**: `Trace` (computed, non-persisted)

**Format**:
```json
{"HostName": "DBSERVER01","AppName": "Billing Service","SUserName": "billingapp","SPID": "52","DBName": "etoro","ObjectName": "BillingCurrencyPerFundingTypeOverridesUpsert"}
```

This is a diagnostic field - computed at query time from SQL Server system functions. Not stored, not indexed. Useful during debugging to see which application/procedure last wrote the row.

---

## 3. Data Overview

| CountryID | FundingTypeID | CurrencyID | IsDefault | Rank | Meaning |
|-----------|--------------|------------|-----------|------|---------|
| 1 | 1 | 1 | 1 | 1 | Country 1, FundingType 1: USD is the default currency (Rank 1 = first choice) |
| 1 | 1 | 2 | 0 | 2 | Country 1, FundingType 1: EUR available as second choice |
| 1 | 1 | 3 | 0 | 3 | Country 1, FundingType 1: GBP available as third choice |
| 1 | 1 | 5 | 0 | 4 | Country 1, FundingType 1: fourth currency option |
| (various) | (various) | (various) | (mixed) | (mixed) | 2,527 rows total covering country x funding type x currency combinations |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | int | NO | - | VERIFIED | Country for which this currency override applies. Part of composite PK. Implicit FK to Dictionary.Country(CountryID). Defines the geographic scope of the override. |
| 2 | FundingTypeID | int | NO | - | VERIFIED | Payment method type for which this currency override applies. Part of composite PK. Implicit FK to Dictionary.FundingType(FundingTypeID). Combined with CountryID, identifies which (country, payment method) pair is being overridden. |
| 3 | CurrencyID | int | NO | - | VERIFIED | The currency being included in this override set. Part of composite PK. Implicit FK to Dictionary.Currency(CurrencyID). One row per currency allowed in this (country, funding type) pair. Examples: 1=USD, 2=EUR, 3=GBP. |
| 4 | IsDefault | bit | NO | - | VERIFIED | Whether this currency is the pre-selected/recommended default for this (country, funding type) combination. 1=this currency is pre-selected when customer opens deposit for this funding type in this country. 0=available but not pre-selected. Typically one IsDefault=1 per (CountryID, FundingTypeID) group. |
| 5 | Rank | int | YES | 1 | VERIFIED | Display/priority order for this currency within the (country, funding type) combination. Lower rank = shown first. DEFAULT 1 means unranked rows all appear at equal priority. GetRanksByCountryAndFundingType returns CurrencyID ordered by Rank ASC. |
| 6 | Trace | computed | NO | - | VERIFIED | Non-persisted JSON audit string computed at query time. Records HostName, AppName, SUserName, SPID, DBName, ObjectName of the session that last accessed this row. Diagnostic only - useful for tracing which application/procedure is reading or writing the table. |
| 7 | ValidFrom | datetime2(7) | NO | - | VERIFIED | System-time start: timestamp when this row became the current version. Generated by SQL Server temporal system (GENERATED ALWAYS AS ROW START). Used to query the table as of a past point in time. |
| 8 | ValidTo | datetime2(7) | NO | - | VERIFIED | System-time end: timestamp when this row was superseded (9999-12-31 for current rows). Generated by SQL Server temporal system (GENERATED ALWAYS AS ROW END). Current rows have ValidTo = datetime2 MAX. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit | Country scoping for the override |
| FundingTypeID | Dictionary.FundingType | Implicit | Payment method being overridden |
| CurrencyID | Dictionary.Currency | Implicit | Currency included in the override set |
| (history) | History.BillingCurrencyPerFundingTypeOverrides | System-Versioning | Temporal history table storing all prior row versions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetFundingTypesWithOverrides | CountryID, FundingTypeID, CurrencyID | READER | Primary consumer - builds the override vs default currency resolution logic |
| Billing.GetRanksByCountryAndFundingType | CountryID, FundingTypeID | READER | Lightweight rank lookup - returns ordered CurrencyID list for a (country, funding type) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CurrencyPerFundingTypeOverrides (table)
  (no FK constraints in DDL - all relationships implicit)
|- History.BillingCurrencyPerFundingTypeOverrides [temporal history]
```

### 6.1 Objects This Depends On

No FK constraints. Implicit dependencies on Dictionary.Country, Dictionary.FundingType, Dictionary.Currency.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetFundingTypesWithOverrides | Stored Procedure | READER - currency override resolution (CTE-based EXCEPT+UNION ALL pattern) |
| Billing.GetRanksByCountryAndFundingType | Stored Procedure | READER - ordered currency list by rank |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CurrencyPerFundingTypeOverrides | CLUSTERED PK | CountryID ASC, FundingTypeID ASC, CurrencyID ASC | - | - | Active (FILLFACTOR 95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK (composite) | PRIMARY KEY CLUSTERED | Unique (CountryID, FundingTypeID, CurrencyID) - one row per country-fundingtype-currency triplet |

### 7.3 Temporal History

| Property | Value |
|----------|-------|
| System-Versioning | ON |
| History Table | History.BillingCurrencyPerFundingTypeOverrides |
| History Retention | Full (no retention policy specified in DDL) |
| ValidFrom/ValidTo | datetime2(7) GENERATED ALWAYS AS ROW START/END |

---

## 8. Sample Queries

### 8.1 Get currency options for a country and funding type (ordered)
```sql
SELECT  CPFO.CurrencyID,
        DC.Name             AS CurrencyName,
        DC.Abbreviation     AS CurrencyCode,
        CPFO.IsDefault,
        CPFO.Rank
FROM    Billing.CurrencyPerFundingTypeOverrides CPFO WITH (NOLOCK)
INNER JOIN Dictionary.Currency DC WITH (NOLOCK)
        ON CPFO.CurrencyID = DC.CurrencyID
WHERE   CPFO.CountryID = 1
        AND CPFO.FundingTypeID = 1
ORDER BY CPFO.Rank;
```

### 8.2 Find funding types that have currency overrides for a country
```sql
SELECT  CPFO.FundingTypeID,
        COUNT(*)            AS CurrencyCount,
        SUM(CPFO.IsDefault) AS HasDefault
FROM    Billing.CurrencyPerFundingTypeOverrides CPFO WITH (NOLOCK)
WHERE   CPFO.CountryID = 1
GROUP BY CPFO.FundingTypeID
ORDER BY CPFO.FundingTypeID;
```

### 8.3 Query historical state (system-versioned)
```sql
-- What were the currency overrides for Country=1, FundingType=1 on a specific date?
SELECT  CountryID, FundingTypeID, CurrencyID, IsDefault, Rank, ValidFrom, ValidTo
FROM    Billing.CurrencyPerFundingTypeOverrides FOR SYSTEM_TIME AS OF '2025-01-01'
WHERE   CountryID = 1
        AND FundingTypeID = 1
ORDER BY Rank;
```

### 8.4 Find all countries/funding types where USD is the default currency
```sql
SELECT  CPFO.CountryID,
        DC_Country.Name     AS CountryName,
        CPFO.FundingTypeID
FROM    Billing.CurrencyPerFundingTypeOverrides CPFO WITH (NOLOCK)
INNER JOIN Dictionary.Country DC_Country WITH (NOLOCK)
        ON CPFO.CountryID = DC_Country.CountryID
WHERE   CPFO.CurrencyID = 1  -- USD
        AND CPFO.IsDefault = 1
ORDER BY DC_Country.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific table. For context on how currency overrides interact with funding type routing, see `Billing.GetFundingTypesWithOverrides` and `Billing.FundingTypeCountries`.

---

*Generated: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CurrencyPerFundingTypeOverrides | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.CurrencyPerFundingTypeOverrides.sql*
