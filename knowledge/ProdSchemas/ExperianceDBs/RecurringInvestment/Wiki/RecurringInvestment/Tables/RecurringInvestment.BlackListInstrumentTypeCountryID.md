# RecurringInvestment.BlackListInstrumentTypeCountryID

> Blacklist table restricting entire instrument types (e.g., crypto, CFDs) for users in specific countries from recurring investment plans.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Table |
| **Key Identifier** | InstrumentTypeID + CountryID (NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK + IX_BlackListInstrumentTypeCountryID_InstrumentTypeID_CountryID) |

---

## 1. Business Meaning

This table maintains a blacklist of instrument type + country combinations. Unlike BlackListInstrumentIDCountryID (which blocks individual instruments), this table blocks entire categories of instruments (e.g., all crypto, all CFDs) for users in specific countries. This is the broadest instrument-level restriction mechanism.

Without this table, each instrument in a restricted category would need individual entries in BlackListInstrumentIDCountryID, which would be impractical for large categories and prone to missing newly added instruments.

System-versioned with history in History.RecurringInvestmentBlackListInstrumentTypeCountryID. Contains 10 entries covering instrument type + country combinations. Triggers PlanEventCode 901 (CountryAndInstrumentTypeNotCompatible).

---

## 2. Business Logic

### 2.1 Category-Level Instrument Restriction

**What**: Blocks entire instrument categories per country.

**Columns/Parameters Involved**: `InstrumentTypeID`, `CountryID`

**Rules**:
- InstrumentTypeID represents a category (e.g., 5=one type, 10=another)
- If the combination exists, ALL instruments of that type are blocked for users in that country
- This is the highest-priority instrument restriction - overrides individual instrument availability

---

## 3. Data Overview

| InstrumentTypeID | CountryID | UpdateDate | Meaning |
|------------------|-----------|------------|---------|
| 10 | 96 | 2026-01-21 | All instruments of type 10 are blocked for users in country 96. Most recently updated entry. |
| 10 | 63 | 2025-11-11 | Type 10 instruments blocked for country 63. Part of a batch update on 2025-11-11 affecting multiple countries. |
| 5 | 43 | 2025-11-11 | Instrument type 5 blocked for country 43. Different instrument type restriction. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentTypeID | int | NO | - | VERIFIED | ID of the instrument type/category. All instruments belonging to this type are blocked for the specified country. References external instrument classification system. |
| 2 | CountryID | int | NO | - | VERIFIED | Country ID of the user. Users from this country cannot create recurring investment plans for any instrument of the specified type. |
| 3 | UpdateDate | datetime | NO | GETUTCDATE() | VERIFIED | When this restriction was last added or modified. |
| 4 | Trace | computed | NO | - | CODE-BACKED | Computed audit column: JSON with connection details. |
| 5 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioned period start. |
| 6 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | System-versioned period end. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.BlacklistInstrumentTypesAndCountryIDGetAll | - | Reader | Reads all entries |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlacklistInstrumentTypesAndCountryIDGetAll | Stored Procedure | Reads all entries |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BlackListInstrumentTypeCountryID | NONCLUSTERED PK | InstrumentTypeID, CountryID | - | - | Active |
| IX_BlackListInstrumentTypeCountryID_InstrumentTypeID_CountryID | NONCLUSTERED | InstrumentTypeID, CountryID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_BlackListInstrumentTypeCountryID_UpdateDate | DEFAULT | GETUTCDATE() - auto-timestamps restriction creation |

### 7.3 Temporal

System-versioned with history table `History.RecurringInvestmentBlackListInstrumentTypeCountryID`.

---

## 8. Sample Queries

### 8.1 List all type+country restrictions
```sql
SELECT InstrumentTypeID, CountryID, UpdateDate FROM [RecurringInvestment].[BlackListInstrumentTypeCountryID] WITH (NOLOCK) ORDER BY InstrumentTypeID, CountryID
```

### 8.2 Find all restricted instrument types for a country
```sql
SELECT InstrumentTypeID FROM [RecurringInvestment].[BlackListInstrumentTypeCountryID] WITH (NOLOCK) WHERE CountryID = @CountryID ORDER BY InstrumentTypeID
```

### 8.3 Count countries per restricted instrument type
```sql
SELECT InstrumentTypeID, COUNT(*) AS RestrictedCountries FROM [RecurringInvestment].[BlackListInstrumentTypeCountryID] WITH (NOLOCK) GROUP BY InstrumentTypeID ORDER BY RestrictedCountries DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Blacklist of instrument types per country; PlanEventCode 901 = CountryAndInstrumentTypeNotCompatible |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.BlackListInstrumentTypeCountryID | Type: Table | Source: RecurringInvestment/RecurringInvestment/Tables/RecurringInvestment.BlackListInstrumentTypeCountryID.sql*
