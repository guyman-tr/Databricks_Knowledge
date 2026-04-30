# Trade.GetUsTerritoriesCountryIds

> Returns all country IDs belonging to US Territories (CountryGroupID=4), used to determine whether a customer's country is a US territory for regulatory and trading logic.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: CountryID (int) - all countries in CountryGroupID=4 (US_Territories) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetUsTerritoriesCountryIds is a **US territory country ID provider** stored procedure. It returns the full set of CountryIDs classified as US Territories by querying Dictionary.CountryToCountryGroup where CountryGroupID = 4. US territories include jurisdictions such as Puerto Rico, Guam, the US Virgin Islands, and similar US-administered territories where eToro applies US-specific trading regulations despite them not being US states.

This procedure exists alongside Trade.GetUsRegulationIds to form the two-axis US eligibility check: regulation-based (GetUsRegulationIds) and country-based (GetUsTerritoriesCountryIds). Many regulatory checks in the codebase require both conditions - a customer must be both under a US regulation AND reside in a US territory or US country. The comment `--US_Territories` in the DDL confirms CountryGroupID=4 maps to the US territories business concept.

The SP is used by two key services: TAPIUser (the trading API user that handles real-time trading operations) and PortfolioAlignmentService (which aligns portfolios for copy trading). Both services need to determine which customers fall under US territory rules for position eligibility, copy trade restrictions, and regulatory compliance decisions.

---

## 2. Business Logic

### 2.1 US Territory Classification by CountryGroupID

**What**: Returns country IDs where CountryGroupID = 4, the designated group for US Territories.

**Columns/Parameters Involved**: (no input parameters) - output: `CountryID`

**Rules**:
- Source: Dictionary.CountryToCountryGroup, filtered by CountryGroupID = 4
- CountryGroupID = 4 is hardcoded in the SP with the inline comment `--US_Territories`
- Result includes all countries mapped to the US territories group
- Used in combination with US regulation IDs for full US eligibility checks: both regulation and country must satisfy US criteria

**Diagram**:
```
Dictionary.CountryToCountryGroup
  WHERE CountryGroupID = 4  -- US_Territories
        |
        v
Trade.GetUsTerritoriesCountryIds (SP)
        |
        v
Callers (TAPIUser, PortfolioAlignmentService):
  WHERE CustomerCountryID IN (SELECT CountryID FROM Trade.GetUsTerritoriesCountryIds())
  AND RegulationID IN (SELECT ID FROM Trade.GetUsRegulationIds())
  --> Combined US eligibility check
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (no input parameters) | - | - | - | - | - | This procedure takes no parameters. |
| **Output column:** | | | | | | |
| 1 | CountryID | int | NO | - | CODE-BACKED | Country ID from Dictionary.CountryToCountryGroup where CountryGroupID=4 (US Territories). Used to identify whether a customer's country of residence is classified as a US territory. Consumers use this in IN/EXISTS subqueries alongside GetUsRegulationIds for full US regulatory eligibility checks. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID (output) | Dictionary.CountryToCountryGroup | SELECT from table | Directly queries the country-to-country-group mapping; filtered to CountryGroupID=4 (US_Territories) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TAPIUser (trading API service) | GRANT EXECUTE | Permission | Trading API service calls this SP to determine US territory membership for real-time trading decisions |
| PortfolioAlignmentService | GRANT EXECUTE | Permission | Portfolio alignment service calls this SP to apply US territory restrictions when aligning copy trade portfolios |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUsTerritoriesCountryIds (procedure)
+-- Dictionary.CountryToCountryGroup (table) [x-schema, leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CountryToCountryGroup | Table | SELECT FROM - source of all output rows; filtered by CountryGroupID=4 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TAPIUser (service) | Permission | GRANT EXECUTE - called by trading API service |
| PortfolioAlignmentService | Permission | GRANT EXECUTE - called by portfolio alignment service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute to get all US territory country IDs

```sql
EXEC Trade.GetUsTerritoriesCountryIds;
```

### 8.2 Filter customers in US territories

```sql
SELECT bc.CustomerID, bc.CountryID
FROM   BackOffice.Customer bc WITH (NOLOCK)
WHERE  bc.CountryID IN (SELECT CountryID FROM Trade.GetUsTerritoriesCountryIds());
```

### 8.3 Combined US eligibility check (territory + regulation)

```sql
SELECT bc.CustomerID
FROM   BackOffice.Customer bc WITH (NOLOCK)
WHERE  bc.CountryID IN (SELECT CountryID FROM Trade.GetUsTerritoriesCountryIds())
AND    ISNULL(bc.DesignatedRegulationID, bc.RegulationID)
           IN (SELECT ID FROM Trade.GetUsRegulationIds());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 11 - Phase 10: no results)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos (skipped - not found) | Corrections: 0 applied*
*Object: Trade.GetUsTerritoriesCountryIds | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUsTerritoriesCountryIds.sql*
