# AffiliateAdmin.GetAffiliateGroups

> Returns a dropdown list of affiliate groups, excluding the sentinel group (ID 1), for use in admin UI selectors.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns AffiliatesGroupsID + AffiliatesGroupsName rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.GetAffiliateGroups is a lookup procedure that provides the list of affiliate groups for dropdown selectors throughout the affiliate admin portal. It returns all groups except the sentinel row (AffiliatesGroupsID = 1), which is reserved as a system placeholder and should never appear in user-facing selections.

This procedure exists because multiple admin screens (affiliate creation, filtering, reporting) need a consistent group dropdown. By centralizing this query in a stored procedure, the application avoids duplicating the sentinel-exclusion logic across different pages.

Data flow: The procedure accepts @IsAdmin and @UserEmail parameters, though the permission-filtering logic based on these parameters is currently commented out in the code. In its current state, it performs a simple SELECT from AffiliateAdmin.AffiliatesGroups WHERE AffiliatesGroupsID > 1, returning all non-sentinel groups regardless of the caller's role.

---

## 2. Business Logic

### 2.1 Sentinel Group Exclusion

The WHERE clause filters out AffiliatesGroupsID = 1. This sentinel row exists in the AffiliatesGroups table as a system-level default or placeholder and is intentionally hidden from all user-facing group lists.

### 2.2 Commented-Out Permission Logic

The procedure contains commented-out logic that would filter groups based on @IsAdmin and @UserEmail. When this logic is active, non-admin users would only see groups they have permission to view. In the current deployed state, all callers see all groups.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IsAdmin | bit | NO | 0 | CODE-BACKED | Flag indicating whether the caller is an admin. Currently unused (permission logic is commented out). |
| 2 | @UserEmail | nvarchar(250) | YES | - | CODE-BACKED | Email of the calling user for permission filtering. Currently unused (permission logic is commented out). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | AffiliateAdmin.AffiliatesGroups | Read | Reads all non-sentinel groups for dropdown population |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.GetAffiliateGroups (procedure)
+-- AffiliateAdmin.AffiliatesGroups (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.AffiliatesGroups | Table | SELECT for group ID and name |

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

### 8.1 Get all affiliate groups for dropdown
```sql
EXEC AffiliateAdmin.GetAffiliateGroups @IsAdmin = 1, @UserEmail = 'admin@example.com';
-- Returns: AffiliatesGroupsID, AffiliatesGroupsName (all groups except sentinel)
```

### 8.2 Get groups as a non-admin user (currently returns same results)
```sql
EXEC AffiliateAdmin.GetAffiliateGroups @IsAdmin = 0, @UserEmail = 'user@example.com';
-- Returns: same result set (permission logic is commented out)
```

### 8.3 Verify sentinel exclusion manually
```sql
SELECT AffiliatesGroupsID, AffiliatesGroupsName
FROM AffiliateAdmin.AffiliatesGroups WITH (NOLOCK)
WHERE AffiliatesGroupsID > 1
ORDER BY AffiliatesGroupsName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. DDL references PART-5531, PART-4670, PART-3147.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 4.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAffiliateGroups | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAffiliateGroups.sql*
