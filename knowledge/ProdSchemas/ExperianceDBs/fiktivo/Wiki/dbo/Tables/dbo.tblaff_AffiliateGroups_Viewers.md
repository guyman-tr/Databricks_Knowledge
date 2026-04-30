# dbo.tblaff_AffiliateGroups_Viewers

> Junction table that grants admin users visibility permissions to specific affiliate groups, implementing row-level security for the affiliate management portal.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | AffiliatesGroupsID + UserID (composite PK, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

This table controls which admin users can see and manage which affiliate groups in the admin portal. It implements a many-to-many permission model: each admin user can be granted access to multiple affiliate groups, and each group can have multiple authorized viewers.

This is a critical security table. Without it, all admin users would see all affiliate groups, which is undesirable in organizations where different teams manage different affiliate segments. For example, a regional manager should only see the affiliate groups assigned to their region.

The table currently has 872 permission assignments, linking admin users (from dbo.tblaff_User) to affiliate groups (from dbo.tblaff_AffiliatesGroups). AffiliatesGroupsID=0 appears frequently, which likely represents a "global" or "all groups" special permission.

---

## 2. Business Logic

### 2.1 Group Visibility Permissions

**What**: Row-level security controlling which admin users can view/manage which affiliate groups.

**Columns/Parameters Involved**: `AffiliatesGroupsID`, `UserID`

**Rules**:
- A user can see all affiliates within a group if they have a row in this table for that group
- AffiliatesGroupsID=0 appears to be a special "global" group granting broad visibility
- Removing a row revokes the user's access to that group immediately
- New admin users typically need explicit grants added here before they can see any affiliate data

---

## 3. Data Overview

| AffiliatesGroupsID | UserID | Meaning |
|---|---|---|
| 0 | 18 | User 18 has access to the global/default group (GroupID 0) - likely has broad visibility |
| 0 | 19 | User 19 also has global group access |
| 0 | 22 | User 22 also has global group access |
| 0 | 23 | User 23 also has global group access |
| 0 | 63 | User 63 also has global group access |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliatesGroupsID | int | NO | - | VERIFIED | The affiliate group being granted visibility. References dbo.tblaff_AffiliatesGroups.AffiliatesGroupsID. Value 0 represents the global/default group. Part of composite PK. |
| 2 | UserID | int | NO | - | VERIFIED | The admin user being granted access. References dbo.tblaff_User.UserID. Part of composite PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliatesGroupsID | dbo.tblaff_AffiliatesGroups | Implicit FK | The affiliate group being made visible to the user |
| UserID | dbo.tblaff_User | Implicit FK | The admin user receiving visibility permission |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MCHP | CLUSTERED PK | AffiliatesGroupsID, UserID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find all groups a user can see
```sql
SELECT v.AffiliatesGroupsID, g.GroupName
FROM dbo.tblaff_AffiliateGroups_Viewers v WITH (NOLOCK)
JOIN dbo.tblaff_AffiliatesGroups g WITH (NOLOCK) ON v.AffiliatesGroupsID = g.AffiliatesGroupsID
WHERE v.UserID = 18
```

### 8.2 Find all users who can see a specific group
```sql
SELECT v.UserID, u.EmailAddress
FROM dbo.tblaff_AffiliateGroups_Viewers v WITH (NOLOCK)
JOIN dbo.tblaff_User u WITH (NOLOCK) ON v.UserID = u.UserID
WHERE v.AffiliatesGroupsID = 0
```

### 8.3 Count permissions per user
```sql
SELECT v.UserID, u.EmailAddress, COUNT(*) AS GroupCount
FROM dbo.tblaff_AffiliateGroups_Viewers v WITH (NOLOCK)
JOIN dbo.tblaff_User u WITH (NOLOCK) ON v.UserID = u.UserID
GROUP BY v.UserID, u.EmailAddress
ORDER BY GroupCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_AffiliateGroups_Viewers | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_AffiliateGroups_Viewers.sql*
