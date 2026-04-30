# Dictionary.UserGroupToPermission

> Junction table mapping BackOffice user groups to their allowed permissions per provider, forming the core RBAC (Role-Based Access Control) matrix that determines what operations each team can perform in the BackOffice system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | UserGroupID + PermissionID + ProviderID (composite PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 4 (1 clustered PK + 3 NC on individual columns) |

---

## 1. Business Meaning

Dictionary.UserGroupToPermission is the authorization matrix for the BackOffice system. Each row grants a specific permission to a specific user group for a specific provider (trading entity/label). This three-way mapping enables fine-grained access control where the Risk team might have "Approve Withdrawal" permission for provider 0 (global) but not for provider 2 (a specific regional entity).

Without this table, all BackOffice users would either have full access to everything or need individual permission assignments. The group-based model scales — when a new manager joins the Risk team, they inherit all permissions from the Risk group automatically. When a new permission is needed for Risk, one row per provider is added instead of one row per manager.

The table is consumed by Maintenance.ManagerAdd and Maintenance.ManagerEdit, which resolve a manager's effective permissions by reading this table for their assigned UserGroupID. The FK relationships to Dictionary.UserGroup and Dictionary.Permission ensure data integrity — only valid groups and permissions can be combined.

---

## 2. Business Logic

### 2.1 Three-Dimensional Permission Model

**What**: Permissions are granted at the intersection of group, permission, and provider — creating a 3D authorization cube.

**Columns/Parameters Involved**: `UserGroupID`, `PermissionID`, `ProviderID`

**Rules**:
- A group can have different permissions per provider (e.g., Risk can approve withdrawals for provider 0 but not provider 2)
- ProviderID 0 typically means "global" — the permission applies across all providers
- The composite PK (UserGroupID + PermissionID + ProviderID) ensures no duplicate grants
- 248 total permission grants across all groups and providers
- When a manager's group is changed (Maintenance.ManagerEdit), their effective permissions change immediately

**Diagram**:
```
Permission Resolution:
  Manager logs in
       │
       ▼
  Read Manager.UserGroupID
       │
       ▼
  Query UserGroupToPermission
  WHERE UserGroupID = @GroupID
       │
       ├─ PermissionID=1, ProviderID=0 ──► Can do Perm #1 for all providers
       ├─ PermissionID=1, ProviderID=1 ──► Can do Perm #1 for provider 1
       ├─ PermissionID=1, ProviderID=2 ──► Can do Perm #1 for provider 2
       ├─ PermissionID=2, ProviderID=0 ──► Can do Perm #2 for all providers
       └─ ...
```

### 2.2 Administrators Have Full Access

**What**: The Administrators group (UserGroupID=1) is granted every permission for every provider.

**Columns/Parameters Involved**: `UserGroupID`, `PermissionID`, `ProviderID`

**Rules**:
- The live data shows UserGroupID=1 has rows for PermissionID=1 with ProviderID 0, 1, and 2 — indicating admin access spans all providers
- This pattern repeats for every defined permission
- Non-admin groups receive a subset of permissions based on their operational role

---

## 3. Data Overview

| UserGroupID | PermissionID | ProviderID | Meaning |
|---|---|---|---|
| 1 | 1 | 0 | Administrators granted permission #1 globally (all providers) — full admin access pattern |
| 1 | 1 | 1 | Administrators granted permission #1 for provider 1 specifically — ensures access even with provider-specific checks |
| 1 | 1 | 2 | Administrators granted permission #1 for provider 2 — complete coverage across all provider entities |
| 1 | 2 | 0 | Administrators granted permission #2 globally — demonstrates that admins receive every permission systematically |
| 1 | 2 | 1 | Administrators granted permission #2 for provider 1 — each permission × provider combination gets its own row |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserGroupID | int | NO | - | CODE-BACKED | The user group receiving the permission. FK to Dictionary.UserGroup(UserGroupID) via FK_DGRP_DG2P. Values map to organizational teams: 1=Administrators, 2=Operations, 3=Risk, etc. See [Dictionary.UserGroup](Dictionary.UserGroup.md) for full hierarchy. |
| 2 | PermissionID | int | NO | - | CODE-BACKED | The permission being granted. FK to Dictionary.Permission(PermissionID) via FK_DPRM_DG2P. The 148 permissions cover actions like withdrawal approval, customer editing, trade operations, and reporting access. See [Dictionary.Permission](Dictionary.Permission.md) for full list. |
| 3 | ProviderID | int | NO | - | CODE-BACKED | The provider/trading entity scope for this permission. 0=global (applies to all providers), 1+=specific provider entity. Enables multi-entity isolation where some teams can operate on certain providers but not others. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UserGroupID | Dictionary.UserGroup | FK (FK_DGRP_DG2P) | Which organizational group receives this permission |
| PermissionID | Dictionary.Permission | FK (FK_DPRM_DG2P) | Which specific permission is being granted |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Maintenance.ManagerAdd | UserGroupID | Reader | Reads group permissions when creating a new manager to resolve their effective access |
| Maintenance.ManagerEdit | UserGroupID | Reader | Re-resolves permissions when a manager's group assignment changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.UserGroupToPermission (table)
├── Dictionary.UserGroup (table) [FK]
└── Dictionary.Permission (table) [FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.UserGroup | Table | FK — UserGroupID references the organizational group |
| Dictionary.Permission | Table | FK — PermissionID references the permission definition |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.ManagerAdd | Stored Procedure | Reads permissions for assigned group during manager creation |
| Maintenance.ManagerEdit | Stored Procedure | Reads permissions when changing a manager's group |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DG2P | CLUSTERED | UserGroupID, PermissionID, ProviderID | - | - | Active |
| DG2P_PERMISSION | NC | PermissionID ASC | - | - | Active |
| DG2P_PROVIDER | NC | ProviderID ASC | - | - | Active |
| DG2P_USERGROUP | NC | UserGroupID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_DGRP_DG2P | FK | UserGroupID → Dictionary.UserGroup(UserGroupID) — ensures group exists |
| FK_DPRM_DG2P | FK | PermissionID → Dictionary.Permission(PermissionID) — ensures permission exists |

---

## 8. Sample Queries

### 8.1 List all permissions for a specific group with readable names
```sql
SELECT  g.Name AS GroupName,
        p.Name AS PermissionName,
        gp.ProviderID
FROM    [Dictionary].[UserGroupToPermission] gp WITH (NOLOCK)
JOIN    [Dictionary].[UserGroup] g WITH (NOLOCK)
        ON g.UserGroupID = gp.UserGroupID
JOIN    [Dictionary].[Permission] p WITH (NOLOCK)
        ON p.PermissionID = gp.PermissionID
WHERE   gp.UserGroupID = 3 -- Risk team
ORDER BY p.Name, gp.ProviderID;
```

### 8.2 Count permissions per group
```sql
SELECT  g.Name AS GroupName,
        COUNT(DISTINCT gp.PermissionID) AS PermissionCount,
        COUNT(DISTINCT gp.ProviderID) AS ProviderCount
FROM    [Dictionary].[UserGroupToPermission] gp WITH (NOLOCK)
JOIN    [Dictionary].[UserGroup] g WITH (NOLOCK)
        ON g.UserGroupID = gp.UserGroupID
GROUP BY g.Name
ORDER BY PermissionCount DESC;
```

### 8.3 Find which groups have a specific permission
```sql
SELECT  g.Name AS GroupName,
        p.Name AS PermissionName,
        gp.ProviderID
FROM    [Dictionary].[UserGroupToPermission] gp WITH (NOLOCK)
JOIN    [Dictionary].[UserGroup] g WITH (NOLOCK)
        ON g.UserGroupID = gp.UserGroupID
JOIN    [Dictionary].[Permission] p WITH (NOLOCK)
        ON p.PermissionID = gp.PermissionID
WHERE   gp.PermissionID = 1 -- specific permission
ORDER BY g.Name, gp.ProviderID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.UserGroupToPermission | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.UserGroupToPermission.sql*
