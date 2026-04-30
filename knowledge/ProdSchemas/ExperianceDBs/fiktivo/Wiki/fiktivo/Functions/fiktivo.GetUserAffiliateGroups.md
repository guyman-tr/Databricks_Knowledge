# fiktivo.GetUserAffiliateGroups

> Returns a comma-separated list of affiliate group IDs that a specific admin user has viewing permissions for.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns VARCHAR(MAX) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This function returns all affiliate groups that a specific admin user is authorized to view and manage. Given a user ID, it queries the `dbo.tblaff_AffiliateGroups_Viewers` junction table and aggregates all matching AffiliatesGroupsIDs into a single comma-separated string (e.g., '11,159,200').

This supports the row-level security model of the affiliate management portal. When an admin user logs into the portal, this function can quickly determine which affiliate groups they should see, enabling filtered views across the UI. It is the inverse of `fiktivo.GetAffiliateGroupUsers`, which returns the users assigned to a given group.

---

## 2. Business Logic

### 2.1 Comma-Separated Group List Aggregation

**What**: Aggregates all AffiliatesGroupsIDs for a user into a single delimited string.

**Columns/Parameters Involved**: `@UserID` (input), `VARCHAR(MAX)` (return)

**Rules**:
- Uses the COALESCE + string concatenation pattern to build the CSV list
- Returns NULL if the user has no group assignments (no portal access)
- Order of group IDs in the result is non-deterministic (no ORDER BY)
- Queries dbo.tblaff_AffiliateGroups_Viewers WHERE UserID = @UserID

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserID (parameter) | INT | NO | - | CODE-BACKED | Admin user ID to look up. References dbo.tblaff_User.UserID. |
| 2 | (return value) | VARCHAR(MAX) | YES | - | CODE-BACKED | Comma-separated list of AffiliatesGroupsIDs this user can view (e.g., '11,159,200'). NULL if user has no group assignments. Each ID references dbo.tblaff_AffiliatesGroups.AffiliatesGroupsID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | dbo.tblaff_AffiliateGroups_Viewers | Table access | Reads AffiliatesGroupsID values filtered by UserID. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.GetUserAffiliateGroups (function)
    └── dbo.tblaff_AffiliateGroups_Viewers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliateGroups_Viewers | Table | SELECT AffiliatesGroupsID WHERE UserID = @param |

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

### 8.1 Get all groups visible to a user
```sql
SELECT fiktivo.GetUserAffiliateGroups(15) AS GroupList
-- Returns e.g.: '11,159,200'
```

### 8.2 Show user details with their accessible groups
```sql
SELECT u.UserID,
       u.Username,
       fiktivo.GetUserAffiliateGroups(u.UserID) AS AccessibleGroups
FROM dbo.tblaff_User u WITH (NOLOCK)
WHERE u.UserID IN (3, 15, 47)
```

### 8.3 Find users with no group assignments
```sql
SELECT u.UserID, u.Username
FROM dbo.tblaff_User u WITH (NOLOCK)
WHERE fiktivo.GetUserAffiliateGroups(u.UserID) IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.GetUserAffiliateGroups | Type: Scalar Function | Source: fiktivo/fiktivo/Functions/fiktivo.GetUserAffiliateGroups.sql*
