# fiktivo.GetAffiliateGroupUsers

> Scalar function that returns a comma-separated list of UserIDs belonging to a specific affiliate group, enabling display of group membership in a single field.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns varchar(max) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetAffiliateGroupUsers retrieves all user IDs that are viewers/members of a specific affiliate group and concatenates them into a single comma-separated string. Affiliate groups allow organizing affiliates into logical groupings, and this function answers the question "which users can see this group?" in a format suitable for display in reports or UI grids.

Without this function, querying group membership would require a JOIN or subquery against the viewers table. This function provides a denormalized, display-friendly representation of group membership that can be used inline in SELECT statements.

The function reads from `dbo.tblaff_AffiliateGroups_Viewers`, a cross-schema table in the dbo schema that maps affiliate group IDs to user IDs. It uses the classic SQL Server string concatenation pattern with COALESCE to build the comma-separated list.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The function implements a simple string aggregation pattern.

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliatesGroupsID | int (IN) | NO | - | CODE-BACKED | The affiliate group ID to look up. References dbo.tblaff_AffiliateGroups_Viewers.AffiliatesGroupsID. |
| 2 | RETURN | varchar(max) | - | - | CODE-BACKED | Comma-separated list of UserIDs belonging to the specified group (e.g., '101,205,308'). Returns NULL if the group has no members. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AffiliatesGroupsID | dbo.tblaff_AffiliateGroups_Viewers | SELECT lookup | Queries viewer membership for the given group |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.GetAffiliateGroupUsers (function)
└── dbo.tblaff_AffiliateGroups_Viewers (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliateGroups_Viewers | Table (cross-schema) | SELECT UserID WHERE AffiliatesGroupsID = @param |

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

N/A for function.

---

## 8. Sample Queries

### 8.1 Get users for a specific affiliate group
```sql
SELECT fiktivo.GetAffiliateGroupUsers(1) AS GroupMembers
```

### 8.2 List all groups with their member lists
```sql
SELECT DISTINCT AffiliatesGroupsID,
       fiktivo.GetAffiliateGroupUsers(AffiliatesGroupsID) AS Members
FROM dbo.tblaff_AffiliateGroups_Viewers WITH (NOLOCK)
```

### 8.3 Find groups with a specific user
```sql
SELECT DISTINCT AffiliatesGroupsID,
       fiktivo.GetAffiliateGroupUsers(AffiliatesGroupsID) AS AllMembers
FROM dbo.tblaff_AffiliateGroups_Viewers WITH (NOLOCK)
WHERE AffiliatesGroupsID IN (
    SELECT AffiliatesGroupsID
    FROM dbo.tblaff_AffiliateGroups_Viewers WITH (NOLOCK)
    WHERE UserID = 101
)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.GetAffiliateGroupUsers | Type: Scalar Function | Source: fiktivo/fiktivo/Functions/fiktivo.GetAffiliateGroupUsers.sql*
