# BackOffice.KycIlqGetStates

> Returns all US state names from Dictionary.State (CountryID = 219) ordered alphabetically, for the KYC ILQ driver's license issuing state dropdown.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; returns Name from Dictionary.State WHERE CountryID = 219 (USA) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`KycIlqGetStates` returns the list of US states for the "Issuing State" dropdown in the KYC ILQ form, used when a customer selects which state issued their driver's license or state ID card. Created by Amir Moualem in 2012 as part of the US KYC ILQ system.

`CountryID = 219` is the USA in the `Dictionary.Country` table. The `Dictionary.State` table contains state/province/territory records keyed to a country - filtering by CountryID = 219 returns only the 50 US states (plus potentially DC and territories).

This is a companion lookup to `KycGetCountries` - while that returns countries for citizenship/nationality fields, `KycIlqGetStates` returns US states specifically for the US-required driver's license issuing state field.

---

## 2. Business Logic

### 2.1 US States Lookup

**What**: Selects all state names for CountryID = 219 (USA), sorted alphabetically.

**Rules**:
- `SELECT Name FROM Dictionary.State WITH (NOLOCK) WHERE CountryID = 219 ORDER BY Name ASC`
- CountryID = 219 = United States
- Returns only Name (not StateID or other metadata)
- Alphabetical order for UI display

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Name | (from Dictionary.State) | NO | - | CODE-BACKED | US state name (e.g., "Alabama", "Alaska", ..., "Wyoming"). Filtered to CountryID = 219 (USA) and sorted alphabetically. Used to populate the "Issuing State" dropdown for driver's license in the KYC ILQ form. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Name | Dictionary.State | Lookup | SELECT Name WHERE CountryID = 219 (USA) ORDER BY Name |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.KycIlqGetStates (procedure)
└── Dictionary.State (table) [SELECT Name WHERE CountryID = 219]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.State | Table | SELECT Name for US states (CountryID = 219) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SSDT dependents found. | - | Called by KYC form service for driver's license issuing state dropdown |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| WHERE CountryID = 219 | Filter | Restricts to US states only (USA = 219 in Dictionary.Country) |
| ORDER BY Name ASC | Sort | Alphabetical ordering for UI dropdown |
| WITH (NOLOCK) | Query hint | Dirty read on reference data |

---

## 8. Sample Queries

### 8.1 Get US states for KYC ILQ

```sql
EXEC [BackOffice].[KycIlqGetStates];
-- Returns: Name for all US states (CountryID = 219), alphabetically
```

### 8.2 Equivalent direct query

```sql
SELECT Name
FROM Dictionary.State WITH (NOLOCK)
WHERE CountryID = 219
ORDER BY Name ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 7.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.KycIlqGetStates | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.KycIlqGetStates.sql*
