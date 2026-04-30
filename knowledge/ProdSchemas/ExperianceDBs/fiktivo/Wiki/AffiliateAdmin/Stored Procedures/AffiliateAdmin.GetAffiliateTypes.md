# AffiliateAdmin.GetAffiliateTypes

> Lists active top-level affiliate types with their affiliate counts, optionally filtered by a text search keyword.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns AffiliateTypeID, Description, affiliate count per type |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.GetAffiliateTypes is a list procedure that returns all active, top-level affiliate types along with the count of affiliates assigned to each type. It powers the affiliate types management grid in the admin portal, giving administrators a quick overview of how many affiliates belong to each type classification.

This procedure exists because the admin team needs to manage and monitor affiliate type configurations. The affiliate count per type provides operational insight into which types are most popular and helps identify types that may need attention (e.g., empty types that could be deprecated, or overcrowded types that might need subdivision).

Data flow: The procedure joins dbo.tblaff_AffiliateTypes with dbo.tblaff_Affiliates, groups by type, and counts affiliates per type. It filters to only active types (IsActive <> 0) and top-level types (FatherAffiliateTypeID IS NULL), excluding child/sub-types from the listing. The optional @TxtSearchWord parameter enables text-based filtering on the type description.

---

## 2. Business Logic

### 2.1 Active Types Only

The WHERE clause filters on IsActive <> 0, ensuring that deactivated affiliate types are not shown in the management grid. This prevents admins from accidentally working with deprecated types.

### 2.2 Top-Level Types Only

The FatherAffiliateTypeID IS NULL filter restricts results to root-level types in the type hierarchy. Sub-types (which have a non-NULL FatherAffiliateTypeID) are excluded, as they are managed through their parent type's detail screen.

### 2.3 Affiliate Count Aggregation

A LEFT JOIN to tblaff_Affiliates with GROUP BY provides the count of affiliates per type. This aggregation gives admins immediate visibility into type usage without requiring a separate query.

### 2.4 Optional Text Search

When @TxtSearchWord is provided (non-NULL), the procedure filters type descriptions using a LIKE pattern, allowing admins to quickly find types by name.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TxtSearchWord | varchar(200) | YES | NULL | CODE-BACKED | Optional text filter applied to type Description via LIKE. NULL returns all active top-level types. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.tblaff_AffiliateTypes | Read | Source for type details (AffiliateTypeID, Description, IsActive, FatherAffiliateTypeID) |
| JOIN | dbo.tblaff_Affiliates | Read | LEFT JOIN for counting affiliates per type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.GetAffiliateTypes (procedure)
+-- dbo.tblaff_AffiliateTypes (table)
+-- dbo.tblaff_Affiliates (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliateTypes | Table | SELECT for type definitions, filtered by IsActive and FatherAffiliateTypeID |
| dbo.tblaff_Affiliates | Table | LEFT JOIN for affiliate count aggregation per type |

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

### 8.1 Get all active top-level affiliate types with counts
```sql
EXEC AffiliateAdmin.GetAffiliateTypes;
-- Returns: AffiliateTypeID, Description, AffiliateCount for all active top-level types
```

### 8.2 Search for types containing 'CPA'
```sql
EXEC AffiliateAdmin.GetAffiliateTypes @TxtSearchWord = 'CPA';
-- Returns only types whose Description contains 'CPA'
```

### 8.3 Manually find types with zero affiliates
```sql
SELECT at.AffiliateTypeID, at.Description, COUNT(a.AffiliateID) AS AffiliateCount
FROM dbo.tblaff_AffiliateTypes at WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON a.AffiliateTypeID = at.AffiliateTypeID
WHERE at.IsActive <> 0 AND at.FatherAffiliateTypeID IS NULL
GROUP BY at.AffiliateTypeID, at.Description
HAVING COUNT(a.AffiliateID) = 0
ORDER BY at.Description;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. DDL references PART-4262, PART-2448.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 6.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAffiliateTypes | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAffiliateTypes.sql*
