# Dictionary.Groups

> Lookup table defining internal user groups for BackOffice permission management — organizing dealing team members, CM tool users, and system operators into role-based access groups.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | GroupID (INT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.Groups defines the internal user groups used for role-based access control in eToro's BackOffice and trading management systems. Each group represents a team or permission level — dealing teams, senior dealers, configuration manager users, and system operations staff. Group membership determines which BackOffice features and operations a user can access.

This table exists because eToro's internal tools require granular access control. The dealing team needs different permissions than the trading core team, and configuration management operations (like reloading cache) should be restricted to authorized system operators. Groups are linked to users through Internal.GroupsAndRoles, and permission checks are performed by Internal.CheckSinglePermission.

The group system supports eToro's operational hierarchy: All-Dealers (broadest), Dealing-Managers and Dealing-Seniors (elevated privileges), specialized tool groups (Dealing-CM-Tool, CEP-Users), and system-level operations (Trading-CM-SystemOperations).

---

## 2. Business Logic

### 2.1 Group Hierarchy and Access Levels

**What**: Groups are organized by functional area and privilege level.

**Columns/Parameters Involved**: `GroupID`, `GroupName`, `GroupDesc`

**Rules**:
- **Dealing groups** (1, 2, 5, 14): Tiered dealing team access — All-Dealers (broadest), Dealing-Managers, Dealing-Seniors, Dealers-Seniors
- **Tool-specific groups** (7, 8, 13): Access to specific tools — Configuration Manager (CM), special permissions, CEP (Complex Event Processing) users
- **System operations** (9): Trading-CM-SystemOperations — can execute system-wide technical operations like cache reload
- **Team groups** (6, 12, 15, 16): Team-specific access — Reopen-Positions-Operation, Trading-Core, USOPS-CM, foglight-stg
- Permission checks use Internal.CheckSinglePermission which resolves group membership via Internal.GroupsAndRoles

**Diagram**:
```
Access Level Hierarchy:
Trading-CM-SystemOperations (9) ─── Highest (system-wide operations)
    │
Dealing-Managers (2) / Dealing-Seniors (5) ─── Elevated dealing access
    │
All-Dealers (1) ─── Base dealing team access
    │
Tool-specific: CM-Tool (7), CEP-Users (13), Special-Perms (8)
    │
Team-specific: Trading-Core (12), USOPS-CM (15), Reopen-Positions (6)
```

---

## 3. Data Overview

| GroupID | GroupName | GroupDesc | Meaning |
|---|---|---|---|
| 1 | All-Dealers | All Dealers | Broadest dealing team group — all members of the dealing team belong to this group. Provides base-level access to dealing tools, instrument configuration, and trading operations. |
| 2 | Dealing-Managers | Dealing Managers | Elevated access for dealing team managers. Grants permissions for senior operations like overriding trading parameters, approving configuration changes, and managing dealer assignments. |
| 9 | Trading-CM-SystemOperations | Users that can execute system-wide technical operations (like Reload Cache) | Highest-privilege group for system-level operations. Members can reload server caches, trigger system-wide configuration refreshes, and perform maintenance operations that affect all trading servers. |
| 13 | CEP-Users | CEP-Allowed-Users | Access to the Complex Event Processing (CEP) system. Members can create and manage CEP rules for real-time event detection (e.g., price alerts, volatility triggers, trading pattern monitoring). |
| 7 | Dealing-CM-Tool | Dealing configuration manager allowed users | Access to the Configuration Manager tool for modifying instrument trading parameters (spreads, thresholds, features). A sensitive tool that directly affects live trading behavior. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GroupID | int | NO | - | VERIFIED | Primary key identifying the user group. Values: 1=All-Dealers, 2=Dealing-Managers, 5=Dealing-Seniors, 6=Reopen-Positions-Operation, 7=Dealing-CM-Tool, 8=Dealing-Special-Permissions, 9=Trading-CM-SystemOperations, 12=Trading-Core, 13=CEP-Users, 14=Dealers-Seniors, 15=USOPS-CM, 16=foglight-stg. Referenced by Internal.GroupsAndRoles for user-to-group assignment. |
| 2 | GroupName | varchar(50) | NO | - | VERIFIED | Machine-readable group identifier using hyphenated naming convention (e.g., "All-Dealers", "Trading-CM-SystemOperations"). Used in Internal.CheckSinglePermission for programmatic permission checks. |
| 3 | GroupDesc | varchar(500) | YES | - | VERIFIED | Human-readable description of the group's purpose and access level. Displayed in BackOffice user management UI. Explains what operations group members are authorized to perform. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.GroupsAndRoles | GroupID | Implicit Lookup | Maps users to groups for permission assignment |
| Internal.CheckSinglePermission | GroupID | Read | Checks if a user belongs to a specific group |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.GroupsAndRoles | Table | References GroupID for user-to-group membership |
| Internal.CheckSinglePermission | Stored Procedure | Reads groups to verify user permissions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_Groups | CLUSTERED PK | GroupID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_Groups | PRIMARY KEY | Unique group identifier |

---

## 8. Sample Queries

### 8.1 List all groups with descriptions
```sql
SELECT  GroupID,
        GroupName,
        GroupDesc
FROM    [Dictionary].[Groups] WITH (NOLOCK)
ORDER BY GroupID;
```

### 8.2 Find users in a specific group
```sql
SELECT  gr.UserID,
        g.GroupName,
        g.GroupDesc
FROM    [Internal].[GroupsAndRoles] gr WITH (NOLOCK)
JOIN    [Dictionary].[Groups] g WITH (NOLOCK)
        ON gr.GroupID = g.GroupID
WHERE   g.GroupName = @GroupName;
```

### 8.3 List all dealing-related groups
```sql
SELECT  GroupID,
        GroupName,
        GroupDesc
FROM    [Dictionary].[Groups] WITH (NOLOCK)
WHERE   GroupName LIKE '%Deal%'
ORDER BY GroupID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Groups | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Groups.sql*
