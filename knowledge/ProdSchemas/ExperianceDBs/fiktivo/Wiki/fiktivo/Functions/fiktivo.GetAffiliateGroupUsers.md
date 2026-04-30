# fiktivo.GetAffiliateGroupUsers

> Returns a comma-separated list of admin user IDs who have viewing permissions for a specific affiliate group.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns VARCHAR(MAX) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This function returns all admin users who are authorized to view and manage a specific affiliate group. Given an affiliate group ID, it queries the `dbo.tblaff_AffiliateGroups_Viewers` junction table and aggregates all matching UserIDs into a single comma-separated string (e.g., '12,45,67').

This supports the row-level security model of the affiliate management portal, where different admin users are granted visibility to different affiliate groups. The function provides a convenient way to retrieve the viewer list for a group without a JOIN - useful in reporting queries or UI logic that needs to display which admins manage a group.

The function is the inverse of `fiktivo.GetUserAffiliateGroups`, which returns the groups visible to a given user.

---

## 2. Business Logic

### 2.1 Comma-Separated User List Aggregation

**What**: Aggregates all UserIDs for a group into a single delimited string.

**Columns/Parameters Involved**: `@AffiliatesGroupsID` (input), `VARCHAR(MAX)` (return)

**Rules**:
- Uses the COALESCE + string concatenation pattern to build the CSV list
- Returns NULL if no viewers are assigned to the group
- Order of UserIDs in the result is non-deterministic (no ORDER BY in the query)
- Queries dbo.tblaff_AffiliateGroups_Viewers WHERE AffiliatesGroupsID = @AffiliatesGroupsID

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliatesGroupsID (parameter) | INT | NO | - | CODE-BACKED | Affiliate group ID to look up. References dbo.tblaff_AffiliatesGroups.AffiliatesGroupsID. Value 0 typically represents the "global/all groups" permission. |
| 2 | (return value) | VARCHAR(MAX) | YES | - | CODE-BACKED | Comma-separated list of UserIDs who can view this group (e.g., '12,45,67'). NULL if no viewers assigned. Each UserID references dbo.tblaff_User.UserID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | dbo.tblaff_AffiliateGroups_Viewers | Table access | Reads UserID values filtered by AffiliatesGroupsID. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.GetAffiliateGroupUsers (function)
    └── dbo.tblaff_AffiliateGroups_Viewers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliateGroups_Viewers | Table | SELECT UserID WHERE AffiliatesGroupsID = @param |

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function.

---

## 8. Sample Queries

### 8.1 Get all users who can view a specific group
```sql
SELECT fiktivo.GetAffiliateGroupUsers(11) AS UserList
-- Returns e.g.: '3,15,22,47'
```

### 8.2 Show group details with viewer list
```sql
SELECT g.AffiliatesGroupsID,
       g.GroupName,
       fiktivo.GetAffiliateGroupUsers(g.AffiliatesGroupsID) AS Viewers
FROM dbo.tblaff_AffiliatesGroups g WITH (NOLOCK)
WHERE g.AffiliatesGroupsID IN (1, 11, 159)
```

### 8.3 Find groups with no assigned viewers
```sql
SELECT g.AffiliatesGroupsID, g.GroupName
FROM dbo.tblaff_AffiliatesGroups g WITH (NOLOCK)
WHERE fiktivo.GetAffiliateGroupUsers(g.AffiliatesGroupsID) IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.GetAffiliateGroupUsers | Type: Scalar Function | Source: fiktivo/fiktivo/Functions/fiktivo.GetAffiliateGroupUsers.sql*
