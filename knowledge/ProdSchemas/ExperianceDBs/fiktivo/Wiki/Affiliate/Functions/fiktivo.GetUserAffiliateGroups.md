# fiktivo.GetUserAffiliateGroups

> Scalar function that returns a comma-separated list of affiliate group IDs that a specific user belongs to, enabling display of a user's group memberships in a single field.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns varchar(max) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetUserAffiliateGroups is the inverse of GetAffiliateGroupUsers. Given a user ID, it returns all affiliate group IDs that the user is a member/viewer of, concatenated into a comma-separated string. This answers the question "which affiliate groups can this user see?" in a display-friendly format.

This function supports the affiliate management UI where administrators need to see at a glance which groups a user has access to. It enables filtering and display without requiring complex JOINs in the presentation layer.

The function reads from `dbo.tblaff_AffiliateGroups_Viewers`, the same cross-schema table used by its sibling function. It uses the same COALESCE-based string concatenation pattern to build the list.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The function implements a simple string aggregation pattern - the inverse lookup of GetAffiliateGroupUsers.

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserID | int (IN) | NO | - | CODE-BACKED | The user ID to look up group memberships for. References dbo.tblaff_AffiliateGroups_Viewers.UserID. |
| 2 | RETURN | varchar(max) | - | - | CODE-BACKED | Comma-separated list of AffiliatesGroupsIDs the user belongs to (e.g., '1,5,12'). Returns NULL if the user has no group memberships. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @UserID | dbo.tblaff_AffiliateGroups_Viewers | SELECT lookup | Queries group memberships for the given user |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.GetUserAffiliateGroups (function)
└── dbo.tblaff_AffiliateGroups_Viewers (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliateGroups_Viewers | Table (cross-schema) | SELECT AffiliatesGroupsID WHERE UserID = @param |

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

### 8.1 Get affiliate groups for a specific user
```sql
SELECT fiktivo.GetUserAffiliateGroups(101) AS UserGroups
```

### 8.2 List all users with their group memberships
```sql
SELECT DISTINCT UserID,
       fiktivo.GetUserAffiliateGroups(UserID) AS Groups
FROM dbo.tblaff_AffiliateGroups_Viewers WITH (NOLOCK)
```

### 8.3 Compare both sibling functions for a group
```sql
SELECT 1 AS GroupID,
       fiktivo.GetAffiliateGroupUsers(1) AS UsersInGroup,
       fiktivo.GetUserAffiliateGroups(101) AS GroupsForUser101
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.GetUserAffiliateGroups | Type: Scalar Function | Source: fiktivo/fiktivo/Functions/fiktivo.GetUserAffiliateGroups.sql*
