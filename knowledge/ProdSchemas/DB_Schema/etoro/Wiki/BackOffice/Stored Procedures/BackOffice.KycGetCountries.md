# BackOffice.KycGetCountries

> Returns all country names from Dictionary.Country for population of the KYC form country dropdowns.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; returns Name column from Dictionary.Country |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`KycGetCountries` is a simple lookup procedure that returns the list of all country names from `Dictionary.Country` to populate country selection dropdowns in the KYC (Know Your Customer) ILQ form. It is part of the KYC-ILQ suite of procedures (KycAddILQ, KycIlqGetByCid, KycIlqGetStates, KycGetCountries) used for US customer regulatory onboarding.

Fields like `@Citizenship`, `@ResidentialAddress` country selection, and other country-related inputs in the KYC form are populated from this lookup. The procedure returns only the Name column (not IDs), suggesting the UI stores and submits country names as strings rather than numeric IDs.

No SSDT callers found - called by the US KYC front-end form service.

---

## 2. Business Logic

### 2.1 Full Country List Lookup

**What**: Returns all country names from the Dictionary.Country table.

**Rules**:
- `SELECT Name FROM Dictionary.Country WITH (NOLOCK)`
- No filtering, no ordering - returns all countries in natural table order
- Only the Name column is returned (not ID or other metadata)
- WITH (NOLOCK): dirty read, acceptable for reference data

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Name | (from Dictionary.Country) | NO | - | CODE-BACKED | Country name string (e.g., "United States", "United Kingdom"). Used to populate citizenship and country dropdowns in the KYC ILQ form. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Name | Dictionary.Country | Lookup | SELECT Name for all countries |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.KycGetCountries (procedure)
└── Dictionary.Country (table) [SELECT Name]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Country | Table | SELECT Name for country dropdown population |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SSDT dependents found. | - | Called by US KYC form service for country dropdown |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| WITH (NOLOCK) | Query hint | Dirty read on reference data |
| No ORDER BY | Design | Countries returned in natural table order |

---

## 8. Sample Queries

### 8.1 Get all KYC country options

```sql
EXEC [BackOffice].[KycGetCountries];
-- Returns: Name column for all countries in Dictionary.Country
```

### 8.2 Equivalent direct query

```sql
SELECT Name FROM Dictionary.Country WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 7.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.KycGetCountries | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.KycGetCountries.sql*
