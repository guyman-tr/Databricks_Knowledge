# Billing.GetCountryToCountryConflictGroupConfig

> Returns the complete country-to-regulatory-conflict-group mapping configuration as a dataset, enabling payment services to load all country classifications into memory.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input parameters; returns full Billing.CountryToCountryConflictGroup table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCountryToCountryConflictGroupConfig` is a configuration loader that exposes the entire `Billing.CountryToCountryConflictGroup` table to calling services. It returns every (CountryID, CountryConflictGroupID) pair from the junction table, giving the caller a complete in-memory map of which countries belong to which regulatory classification groups (EU, Non-EU, GCC, Tax Blacklist).

This procedure exists because the CountryToCountryConflictGroup data is used as static routing/compliance configuration - not for per-transaction row lookups. Services (credit card processing, payment routing, CFT checks) load it once at startup or on a refresh cycle. Having a dedicated stored procedure for this read provides a clean API boundary: the calling service doesn't need to know the table name, schema, or query structure - it simply calls this procedure.

Data flow: Called by a payment or compliance service at startup or on configuration refresh. The returned dataset is loaded into in-memory structures. Each country is tagged with its conflict group(s), and this mapping drives downstream decisions such as which payment methods are available, which CFT whitelist rules apply, and whether enhanced due diligence is required. A country not returned by this procedure (not in CountryToCountryConflictGroup) has no conflict group classification.

---

## 2. Business Logic

### 2.1 Full Configuration Load Pattern

**What**: Returns all 66 configuration rows with no filtering - designed for bulk in-memory load by payment services.

**Columns/Parameters Involved**: `CountryID`, `CountryConflictGroupID`

**Rules**:
- No WHERE clause - always returns the complete mapping (66 rows, 65 distinct countries, 4 groups).
- SET NOCOUNT ON suppresses row-count messages, consistent with a service-oriented read pattern.
- A country can appear in multiple groups (e.g., CountryID=155 appears in both Group 3 GCC and Group 4 Tax Blacklist), so the result set has more rows than distinct countries.
- The caller must handle multi-group membership by iterating all rows, not assuming one row per country.

**Diagram**:
```
Caller (Payment/Compliance Service)
    |
    | EXEC Billing.GetCountryToCountryConflictGroupConfig
    |
    v
Result set (66 rows):
  CountryID | CountryConflictGroupID
  ----------|-----------------------
  79        | 1  (Germany -> EU Countries)
  218       | 1  (UK -> EU Countries)
  9         | 2  (-> NON EU Countries)
  155       | 3  (-> GCC countries)
  155       | 4  (-> Tax Black Grouped)  <- same country in 2 groups
  ...
    |
    v
Service loads into memory: country -> [group1, group2, ...]
Used for: CFT checks, funding type restrictions, payment routing rules
```

### 2.2 Conflict Group Definitions

**What**: The four regulatory classification groups that drive different payment compliance rules.

**Columns/Parameters Involved**: `CountryConflictGroupID`

**Rules**:
- Group 1 (EU Countries, 31 entries): Standard EU regulatory treatment - SEPA payment rules, GDPR, standard AML thresholds.
- Group 2 (NON EU Countries, 20 entries): Non-EU customers - different funding availability, possible CFT whitelist requirements.
- Group 3 (GCC countries, 6 entries): Gulf Cooperation Council - regional payment rules and local banking restrictions.
- Group 4 (Tax Black Grouped Countries, 9 entries): Countries on tax authority blacklists or requiring enhanced due diligence. Some GCC countries (e.g., CountryID=155) are also in this group.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Returns** (SELECT output columns):

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CountryID | INT | NO | VERIFIED | Country identifier. Part of composite PK in source table. FK to Dictionary.Country. A country may appear multiple times (once per conflict group it belongs to). Inherited from Billing.CountryToCountryConflictGroup. |
| 2 | CountryConflictGroupID | INT | NO | VERIFIED | Regulatory conflict group for the country. Values: 1=EU Countries (31 entries), 2=NON EU Countries (20 entries), 3=GCC countries (6 entries), 4=Tax Black Grouped Countries (9 entries). Inherited from Billing.CountryToCountryConflictGroup. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID (output) | Billing.CountryToCountryConflictGroup | Direct read (SELECT) | Full table scan - returns all country-to-group mappings |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No stored procedures found calling this procedure in the SSDT repo. Called directly by application services via service account permissions.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCountryToCountryConflictGroupConfig (procedure)
└── Billing.CountryToCountryConflictGroup (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CountryToCountryConflictGroup | Table | Full SELECT - returns all (CountryID, CountryConflictGroupID) rows with no filtering |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | Called directly by application services; no stored procedures call this procedure. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure to get full conflict group config

```sql
-- Returns all 66 country-to-conflict-group mappings
EXEC [Billing].[GetCountryToCountryConflictGroupConfig]
```

### 8.2 Check a specific country's conflict groups

```sql
-- See which conflict groups a specific country belongs to
SELECT CountryID, CountryConflictGroupID
FROM [Billing].[CountryToCountryConflictGroup] WITH (NOLOCK)
WHERE CountryID = 155  -- example: GCC + Tax Blacklist country
```

### 8.3 Count countries per conflict group

```sql
-- Understand the distribution across regulatory groups
SELECT CountryConflictGroupID,
       COUNT(DISTINCT CountryID) AS CountryCount
FROM [Billing].[CountryToCountryConflictGroup] WITH (NOLOCK)
GROUP BY CountryConflictGroupID
ORDER BY CountryConflictGroupID
-- Expected: 1->31, 2->20, 3->6, 4->9
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped - no repos; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCountryToCountryConflictGroupConfig | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCountryToCountryConflictGroupConfig.sql*
