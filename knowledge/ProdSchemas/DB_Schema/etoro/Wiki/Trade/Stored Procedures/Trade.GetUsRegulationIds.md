# Trade.GetUsRegulationIds

> Returns the set of US regulation IDs (excluding eToroUS) dynamically from Dictionary.Regulation, replacing hardcoded ID lists in US-regulatory logic.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: ID (int) - regulation IDs where IsUSA=1 and ID<>6 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetUsRegulationIds is a **US regulation ID provider** stored procedure. It returns all regulation IDs from Dictionary.Regulation where IsUSA = 1, explicitly excluding ID = 6 (eToroUS), by delegating to the view Trade.vGetUsRegulationIds. The result is a small set of integer IDs representing US-regulated jurisdictions such as eToro US (non-eToroUS entities), US territories, and state-specific regulations like New York.

This procedure exists to replace fragile hardcoded lists of US regulation IDs (previously `IN (6, 7, 8)`) scattered across procedures and functions throughout the database. Before this SP was created, adding a new US regulation (e.g., RegulationID = 14 for New York users) required manually locating and updating every hardcoded list - a process prone to missed updates and bugs. This SP provides a single, authoritative dynamic source that automatically includes any new US regulation added to Dictionary.Regulation with IsUSA = 1.

Data flows through this procedure as a lookup: callers execute it or use it in subqueries to get the current set of US regulation IDs. Because it reads from Dictionary.Regulation via the view, adding a new US regulation row automatically propagates to all consumers of this SP without code changes. The SP is the recommended standard for all future US-regulation filtering in this schema.

---

## 2. Business Logic

### 2.1 Dynamic US Regulation Filter (Excluding eToroUS)

**What**: Returns all regulation IDs flagged as US regulations, except eToroUS (ID=6).

**Columns/Parameters Involved**: (no input parameters) - output: `ID`

**Rules**:
- Source: Dictionary.Regulation via Trade.vGetUsRegulationIds
- Filter: IsUSA = 1 AND ID <> 6
- eToroUS (ID=6) is excluded because it represents a separate US entity handled independently in most regulatory logic
- Result is a dynamic list - new US regulations are automatically included when added to Dictionary.Regulation with IsUSA=1

**Diagram**:
```
Dictionary.Regulation
  WHERE IsUSA = 1
  AND ID <> 6 (eToroUS excluded)
        |
        v
Trade.vGetUsRegulationIds (view)
        |
        v
Trade.GetUsRegulationIds (SP - this object)
        |
        v
Callers: use IN (SELECT ID FROM Trade.GetUsRegulationIds)
         to filter for US-regulated customers/positions
```

### 2.2 Replacement for Hardcoded ID Lists

**What**: This SP was created as the canonical replacement for inline `IN (6, 7, 8)` or `= 8` checks for US regulations.

**Columns/Parameters Involved**: `ID` (output)

**Rules**:
- Legacy code uses hardcoded: `RegulationID IN (6, 7, 8)` or `RegulationID = 8`
- Hardcoded lists do NOT automatically include new US regulations (e.g., adding NY Regulation 14 required manual updates to 9+ objects)
- This SP and its underlying view solve the problem dynamically
- Recommended usage: `WHERE RegulationID IN (SELECT ID FROM Trade.GetUsRegulationIds())`

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (no input parameters) | - | - | - | - | - | This procedure takes no parameters. |
| **Output column:** | | | | | | |
| 1 | ID | int | NO | - | CODE-BACKED | Regulation ID from Dictionary.Regulation. Represents a US-regulated jurisdiction (IsUSA=1) other than eToroUS (ID<>6). Examples include eToro IBLLC (RegulationID=7), eToro US LLC (RegulationID=8), and NY Regulation (RegulationID=14). Use in WHERE IN clauses to filter for US-regulated customers or positions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ID (output) | Trade.vGetUsRegulationIds | SELECT from view | Delegates to the view which filters Dictionary.Regulation by IsUSA=1 and excludes eToroUS (ID=6) |
| ID (output) | Dictionary.Regulation | Indirect (via view) | Ultimate source of regulation IDs; IsUSA flag determines inclusion |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| trading-xavier-user | GRANT EXECUTE | Permission | The xavier database user has EXECUTE permission on this SP, indicating it is called by a scheduled job or service running under that identity (orphaned position close flow) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUsRegulationIds (procedure)
+-- Trade.vGetUsRegulationIds (view)
      +-- Dictionary.Regulation (table) [x-schema, leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.vGetUsRegulationIds | View | SELECT FROM - source of all output rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| trading-xavier-user (job/service) | Permission | GRANT EXECUTE - called by the xavier scheduled job context |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute to get current US regulation IDs

```sql
EXEC Trade.GetUsRegulationIds;
```

### 8.2 Use as a subquery filter for US-regulated customers

```sql
SELECT bc.CustomerID, bc.RegulationID
FROM   BackOffice.Customer bc WITH (NOLOCK)
WHERE  ISNULL(bc.DesignatedRegulationID, bc.RegulationID)
       IN (SELECT ID FROM Trade.GetUsRegulationIds());
```

### 8.3 Check if a specific regulation is a US regulation (excluding eToroUS)

```sql
SELECT CASE
           WHEN EXISTS (SELECT 1 FROM Trade.GetUsRegulationIds() WHERE ID = @RegulationID)
           THEN 'US-regulated (non-eToroUS)'
           ELSE 'Not US-regulated or eToroUS'
       END AS RegulationClassification;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [TFB-803: Database Impact Analysis - New NY Regulation 14](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13799620624) | Confluence | SP was created as part of NY Regulation 14 (RegulationID=14) onboarding to replace hardcoded US regulation ID lists (6,7,8); documented as the canonical solution in Section 7; automatically includes regulation 14 because IsUSA=1; recommended for adoption across all impacted objects |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos (skipped - not found) | Corrections: 0 applied*
*Object: Trade.GetUsRegulationIds | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUsRegulationIds.sql*
