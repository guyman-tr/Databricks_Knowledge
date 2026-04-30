# AffiliateAdmin.GetAffiliateTypesByGroup

> Returns affiliate types that have at least one affiliate belonging to any of the specified affiliate groups.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns distinct AffiliateTypeID + Description for types with affiliates in specified groups |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.GetAffiliateTypesByGroup is a filtered lookup procedure that returns only those affiliate types that have at least one affiliate member in one or more specified affiliate groups. It is used to populate dependent dropdowns or filter panels in the admin portal, where the available type options should be scoped to types that are actually represented within selected groups.

This procedure exists because the admin portal's filtering workflow often requires cascading filters: an admin first selects one or more affiliate groups, and then the type filter should only show types that are relevant to those groups. This avoids presenting empty or irrelevant type options that would return zero results when applied.

Data flow: The procedure accepts a table-valued parameter @AffiliateGroupsID of type dbo.IDTableType (a table of integer IDs). It joins dbo.tblaff_AffiliateTypes with dbo.tblaff_Affiliates and the @AffiliateGroupsID TVP, filtering to top-level types only (FatherAffiliateTypeID IS NULL). The DISTINCT or GROUP BY ensures each type appears only once regardless of how many affiliates match.

---

## 2. Business Logic

### 2.1 Table-Valued Parameter Filtering

The @AffiliateGroupsID parameter is a dbo.IDTableType (user-defined table type containing integer IDs). The procedure joins this TVP against the affiliate table's group assignment to scope results to affiliates in the specified groups.

### 2.2 Existence-Based Type Filtering

Only types that have at least one affiliate in the specified groups are returned. Types with no affiliates in those groups are excluded, ensuring the result set is contextually relevant to the selected group filter.

### 2.3 Top-Level Types Only

The FatherAffiliateTypeID IS NULL filter restricts results to root-level types, consistent with other type-listing procedures in the AffiliateAdmin schema.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateGroupsID | dbo.IDTableType READONLY | NO | - | CODE-BACKED | Table-valued parameter containing a list of AffiliatesGroupsID values to filter by. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.tblaff_AffiliateTypes | Read | Source for type details (AffiliateTypeID, Description) |
| JOIN | dbo.tblaff_Affiliates | Read | Joins to determine which types have affiliates in specified groups |
| JOIN | @AffiliateGroupsID (TVP) | Filter | Table-valued parameter providing the list of group IDs to filter by |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.GetAffiliateTypesByGroup (procedure)
+-- dbo.tblaff_AffiliateTypes (table)
+-- dbo.tblaff_Affiliates (table)
+-- dbo.IDTableType (user-defined table type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliateTypes | Table | SELECT for type ID and description |
| dbo.tblaff_Affiliates | Table | JOIN to find affiliates in specified groups |
| dbo.IDTableType | User-Defined Table Type | Parameter type for @AffiliateGroupsID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get types for specific groups using TVP
```sql
DECLARE @Groups dbo.IDTableType;
INSERT INTO @Groups (ID) VALUES (2), (5), (8);

EXEC AffiliateAdmin.GetAffiliateTypesByGroup @AffiliateGroupsID = @Groups;
-- Returns: AffiliateTypeID, Description for types with affiliates in groups 2, 5, or 8
```

### 8.2 Get types for a single group
```sql
DECLARE @Groups dbo.IDTableType;
INSERT INTO @Groups (ID) VALUES (3);

EXEC AffiliateAdmin.GetAffiliateTypesByGroup @AffiliateGroupsID = @Groups;
```

### 8.3 Manually find types with affiliate counts per group
```sql
DECLARE @Groups dbo.IDTableType;
INSERT INTO @Groups (ID) VALUES (2), (5);

SELECT at.AffiliateTypeID, at.Description, COUNT(DISTINCT a.AffiliateID) AS AffiliateCount
FROM dbo.tblaff_AffiliateTypes at WITH (NOLOCK)
JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON a.AffiliateTypeID = at.AffiliateTypeID
JOIN @Groups g ON g.ID = a.AffiliatesGroupsID
WHERE at.FatherAffiliateTypeID IS NULL
GROUP BY at.AffiliateTypeID, at.Description
ORDER BY at.Description;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. DDL references PART-2714.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 6.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAffiliateTypesByGroup | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAffiliateTypesByGroup.sql*
