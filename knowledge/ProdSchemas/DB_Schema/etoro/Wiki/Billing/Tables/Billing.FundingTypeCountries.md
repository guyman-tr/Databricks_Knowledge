# Billing.FundingTypeCountries

> Master availability table defining which payment methods (funding types) are available in which countries, with a display rank; the core routing matrix used to determine what deposit/cashout options a customer in a specific country can use.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (FundingTypeID, CountryID) - composite PK CLUSTERED |
| **Partition** | N/A - PRIMARY filegroup |
| **Indexes** | 1 (composite PK) |
| **System-Versioned** | YES - History.BillingFundingTypeCountries |

---

## 1. Business Meaning

`Billing.FundingTypeCountries` is the master availability configuration for the payment routing system. It defines the set of funding types (payment methods) that are enabled in each country, along with the display rank for ordering them in the customer UI.

The table holds 1,276 rows covering 18 distinct FundingTypeIDs across up to 251 countries each. A (FundingTypeID, CountryID) entry means: "this payment method is available in this country." The absence of an entry means the payment method is not offered in that country.

`GetFundingTypesByCountry` is the primary consumer - it queries this table to return the ordered list of payment methods for a given country, along with the supported currency IDs for each. `GetFundingTypesWithOverrides` (documented in CurrencyPerFundingTypeOverrides) uses this table as the base for currency override resolution.

The table is system-versioned - all changes to payment method availability are tracked in History.BillingFundingTypeCountries.

---

## 2. Business Logic

### 2.1 Payment Method Availability by Country

**What**: Each row authorizes one payment method in one country. The Rank determines display ordering.

**Columns/Parameters Involved**: `FundingTypeID`, `CountryID`, `Rank`

**Rules**:
```
A customer in CountryID=X can use FundingTypeID=Y IF:
  EXISTS (SELECT 1 FROM Billing.FundingTypeCountries
          WHERE FundingTypeID = Y AND CountryID = X)

GetFundingTypesByCountry(@CountryID):
  -> Returns all FundingTypeIDs for the country, ordered by Rank ASC
  -> Joins with Depot/DepotToCurrency to get supported CurrencyIDs per method
  -> Rank determines UI display order (lowest = first shown)
```

### 2.2 Rank Semantics

**What**: Rank is a display priority - lower rank = shown first in the UI payment method selector.

**Current data**:
```
FundingTypeID=1:  244 countries, Rank 0-5   (likely credit card - widest availability)
FundingTypeID=2:  251 countries, Rank 2-20  (second most available)
FundingTypeID=3:  191 countries, Rank 1-102
FundingTypeID=33: 250 countries, Rank 1-5
FundingTypeID=28: 9 countries,  Rank 0-1   (top-ranked in some countries)
Other types:      1-11 countries each (regional payment methods)
```

FundingTypeIDs 9, 10, 32, 43: Only 1 country each (highly regional or legacy methods).
FundingTypeID=34: 2 countries (iDEAL - Netherlands-specific, special ExtraData handling).

### 2.3 iDEAL Special Case (FundingTypeID=34)

**What**: FundingTypeID=34 (iDEAL, Dutch payment method) requires extra data from `Billing.GetFundingExtraData`. Both GetFundingTypesByCountry and GetFundingTypesWithOverrides check `IIF(ft.FundingTypeID = 34, GetFundingExtraData(@CID, 34), NULL)`.

---

## 3. Data Overview

| FundingTypeID | CountryCount | RankRange | Meaning |
|--------------|-------------|-----------|---------|
| 1 | 244 | 0-5 | Widest coverage - likely credit/debit cards |
| 2 | 251 | 2-20 | Widest absolute coverage (251 countries) |
| 33 | 250 | 1-5 | Near-universal coverage |
| 3 | 191 | 1-102 | Major regional method |
| 8 | 160 | 2-15 | Broad coverage |
| 6 | 142 | 2-103 | Broad coverage |
| 34 | 2 | 2-10 | iDEAL (NL + 1 other) - special ExtraData |
| 43 | 1 | 0 | Single-country, top-ranked |
| Total | 1,276 rows | - | 18 distinct funding types |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID | int | NO | - | VERIFIED | Payment method type. Part of composite PK. Implicit FK to Dictionary.FundingType(FundingTypeID). 18 distinct values in data. Identifies which payment method (credit card, wire, e-wallet, etc.) this availability record covers. |
| 2 | CountryID | int | NO | - | VERIFIED | Country where this payment method is available. Part of composite PK. FK to Dictionary.Country(CountryID) via FK_FundingTypeCountries_Country. |
| 3 | Rank | tinyint | NO | - | VERIFIED | Display priority for this payment method in this country. Lower = shown first in the UI payment method selector. Values range from 0 (top priority) to 103 across all rows. GetFundingTypesByCountry orders results by Rank ASC. |
| 4 | Trace | computed | NO | - | VERIFIED | Non-persisted JSON audit string (HostName, AppName, SUserName, SPID, DBName, ObjectName). Computed at query time. Same pattern as CurrencyPerFundingTypeOverrides. |
| 5 | ValidFrom | datetime2(7) | NO | - | VERIFIED | System-time start: timestamp when this availability row became current. GENERATED ALWAYS AS ROW START. |
| 6 | ValidTo | datetime2(7) | NO | - | VERIFIED | System-time end: timestamp when this availability row was superseded. GENERATED ALWAYS AS ROW END. Current rows have ValidTo = datetime2 MAX (9999-12-31). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID | Dictionary.FundingType | Implicit | Payment method definition |
| CountryID | Dictionary.Country | FK (explicit: FK_FundingTypeCountries_Country) | Country where payment method is available |
| (history) | History.BillingFundingTypeCountries | System-Versioning | Temporal history for availability changes |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetFundingTypesByCountry | CountryID, FundingTypeID, Rank | READER | Primary consumer - returns ordered payment methods for a country |
| Billing.GetFundingTypesWithOverrides | CountryID, FundingTypeID, Rank | READER | Currency override resolution - joins FundingTypeCountries with CurrencyPerFundingTypeOverrides |
| Billing.CurrencyPerFundingTypeOverrides | FundingTypeID | RELATED | Currency overrides for (country, funding type) - consumed by GetFundingTypesWithOverrides together with this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingTypeCountries (table)
|- Dictionary.Country (table)              [FK: CountryID]
|- History.BillingFundingTypeCountries     [temporal history]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | FK target - valid country set |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetFundingTypesByCountry | Stored Procedure | READER - primary consumer for payment method availability |
| Billing.GetFundingTypesWithOverrides | Stored Procedure | READER - used in currency override resolution |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FundingTypeCountries | CLUSTERED PK | FundingTypeID ASC, CountryID ASC | - | - | Active (FILLFACTOR 90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FundingTypeCountries | PRIMARY KEY CLUSTERED | (FundingTypeID, CountryID) - one entry per payment method per country |
| FK_FundingTypeCountries_Country | FOREIGN KEY | CountryID must exist in Dictionary.Country |

### 7.3 Temporal History

| Property | Value |
|----------|-------|
| System-Versioning | ON |
| History Table | History.BillingFundingTypeCountries |
| ValidFrom/ValidTo | datetime2(7) GENERATED ALWAYS AS ROW START/END |

---

## 8. Sample Queries

### 8.1 Get all payment methods available in a country (ordered)
```sql
SELECT  FTC.FundingTypeID,
        FTC.CountryID,
        FTC.Rank
FROM    Billing.FundingTypeCountries FTC WITH (NOLOCK)
WHERE   FTC.CountryID = 79  -- Germany
ORDER BY FTC.Rank;
```

### 8.2 Find countries where a specific payment method is available
```sql
SELECT  FTC.CountryID,
        DC.Name         AS CountryName,
        FTC.Rank
FROM    Billing.FundingTypeCountries FTC WITH (NOLOCK)
INNER JOIN Dictionary.Country DC WITH (NOLOCK)
        ON FTC.CountryID = DC.CountryID
WHERE   FTC.FundingTypeID = 35  -- Trustly
ORDER BY FTC.Rank, DC.Name;
```

### 8.3 Payment method coverage summary
```sql
SELECT  FTC.FundingTypeID,
        COUNT(DISTINCT FTC.CountryID)   AS CountryCount,
        MIN(FTC.Rank)                   AS MinRank,
        MAX(FTC.Rank)                   AS MaxRank
FROM    Billing.FundingTypeCountries FTC WITH (NOLOCK)
GROUP BY FTC.FundingTypeID
ORDER BY CountryCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific table.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingTypeCountries | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.FundingTypeCountries.sql*
