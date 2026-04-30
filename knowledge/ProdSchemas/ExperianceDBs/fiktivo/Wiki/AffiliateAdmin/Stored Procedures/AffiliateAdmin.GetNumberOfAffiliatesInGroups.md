# AffiliateAdmin.GetNumberOfAffiliatesInGroups

> Counts the number of affiliates in each specified affiliate group using a table-valued parameter for group ID input.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | AffiliatesGroupsID, cnt (affiliate count per group) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetNumberOfAffiliatesInGroups calculates the number of affiliates assigned to each of the specified affiliate groups. It accepts a table-valued parameter containing a list of group IDs and returns the count of affiliates per group.

**WHY:** When managing affiliate groups, administrators need to understand the size of each group before performing operations such as merging, deleting, or reassigning groups. This procedure provides the membership counts needed for informed decision-making. For example, before deleting a group, the admin can verify how many affiliates would be affected. The procedure is also used in group listing screens to display member counts alongside group names.

**HOW:** The procedure accepts a `dbo.IDTableType` table-valued parameter containing the list of group IDs to query. It then performs a GROUP BY query on `tblaff_Affiliates` filtering by AffiliatesGroupsID values present in the input table, returning AffiliatesGroupsID and COUNT(*) as cnt for each matching group.

---

## 2. Business Logic

### 2.1 Table-Valued Parameter Input
The @AffiliateGroupIDs parameter uses the `dbo.IDTableType` user-defined table type, which provides a list of integer IDs. This allows the caller to request counts for multiple groups in a single call, avoiding the N+1 query problem.

### 2.2 Group-Level Aggregation
The procedure uses GROUP BY AffiliatesGroupsID with COUNT(*) to produce one row per group. Groups that exist in the input list but have no affiliates assigned will NOT appear in the results (since the filter uses IN on the affiliates table). The application should interpret missing group IDs as having zero members.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateGroupIDs | dbo.IDTableType READONLY | No | - | CODE-BACKED | Table-valued parameter containing the list of affiliate group IDs to count members for |

**Result Set:** AffiliatesGroupsID (INT), cnt (INT) - count of affiliates per group (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Affiliates` | Table | COUNT(*) grouped by AffiliatesGroupsID |
| `dbo.IDTableType` | User-Defined Table Type | Input parameter type for group ID list |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Affiliate group listing | Application | Displays member counts per group |
| Group management operations | Application | Validates group size before merge/delete |

---

## 6. Dependencies

### 6.0 Chain
`GetNumberOfAffiliatesInGroups` -> `tblaff_Affiliates`

### 6.1 Depends On
- `dbo.tblaff_Affiliates` - Source table for affiliate group membership
- `dbo.IDTableType` - User-defined table type for ID list input

### 6.2 Depend On This
No known database dependencies. Called from application layer.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Get affiliate counts for specific groups
DECLARE @GroupIDs dbo.IDTableType;
INSERT INTO @GroupIDs (ID) VALUES (1), (2), (5), (10);
EXEC AffiliateAdmin.GetNumberOfAffiliatesInGroups @AffiliateGroupIDs = @GroupIDs;
```

```sql
-- 2. Check if a single group has members before deletion
DECLARE @GroupIDs dbo.IDTableType;
INSERT INTO @GroupIDs (ID) VALUES (7);
EXEC AffiliateAdmin.GetNumberOfAffiliatesInGroups @AffiliateGroupIDs = @GroupIDs;
-- If no rows returned, the group has zero members
```

```sql
-- 3. Get counts for all groups in a range
DECLARE @GroupIDs dbo.IDTableType;
INSERT INTO @GroupIDs (ID)
SELECT AffiliatesGroupsID FROM AffiliateAdmin.AffiliatesGroups;
EXEC AffiliateAdmin.GetNumberOfAffiliatesInGroups @AffiliateGroupIDs = @GroupIDs;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4500.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetNumberOfAffiliatesInGroups | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetNumberOfAffiliatesInGroups.sql*
