# Trade.SI_GetSpreadGroup

> System Integration query that returns all spread groups from the Trade.GetSpreadGroup view, ordered by SpreadGroupID descending.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (no parameters - returns all records) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a System Integration (SI_) endpoint that returns all spread group definitions. Spread groups organize trading spreads (bid/ask prices) into named collections that can be assigned to customers or instruments. Integration systems use this to load the current spread group catalog for configuration, display, or assignment logic.

The procedure reads from `Trade.GetSpreadGroup` view with no filter, returning all rows ordered by SpreadGroupID DESC so the most recently added groups appear first. The SELECT * pattern means it returns all columns the view exposes.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (no parameters) | - | - | - | - | - | This procedure has no input parameters. Returns all rows from Trade.GetSpreadGroup. |
| Output: SpreadGroupID | int | - | - | CODE-BACKED | Unique identifier of the spread group. |
| Output: Name | varchar | - | - | CODE-BACKED | Display name of the spread group (managed via Trade.SpreadGroupAdd/Edit/Delete procedures). |
| (additional columns) | - | - | - | NAME-INFERRED | Additional columns as defined by the Trade.GetSpreadGroup view. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | Trade.GetSpreadGroup | Reader | SELECT * with NOLOCK ordered by SpreadGroupID DESC |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SI_GetSpreadGroup (procedure)
└── Trade.GetSpreadGroup (view) [SELECT * ORDER BY SpreadGroupID DESC]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetSpreadGroup | View | Read with NOLOCK for all rows; provides spread group configuration |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No callers found in Trade SP folder | - | Called by external integration systems (SI_ prefix convention) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all spread groups

```sql
EXEC Trade.SI_GetSpreadGroup;
```

### 8.2 Direct equivalent query

```sql
SELECT *
FROM Trade.GetSpreadGroup WITH (NOLOCK)
ORDER BY SpreadGroupID DESC;
```

### 8.3 Find spread groups by name pattern

```sql
SELECT SpreadGroupID, Name
FROM Trade.SpreadGroup WITH (NOLOCK)
WHERE Name LIKE '%default%'
ORDER BY SpreadGroupID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SI_GetSpreadGroup | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SI_GetSpreadGroup.sql*
