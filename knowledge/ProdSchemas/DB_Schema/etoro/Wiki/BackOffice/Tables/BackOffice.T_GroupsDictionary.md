# BackOffice.T_GroupsDictionary

> Lookup table mapping manager group IDs to human-readable environment/deployment group names (Staging, Automation, Integration, Production environments).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | ManagerGroupID (CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

`BackOffice.T_GroupsDictionary` is the name lookup table for manager access groups. Each row maps a numeric `ManagerGroupID` to a descriptive `GroupDescription` that identifies the deployment environment and access type (Staging, Automation, Integration, Production) for which a group of back-office managers has credentials.

This table exists to give human-readable names to the group IDs used in `BackOffice.T_ManagerAccessGroupToConnectionStrings`, which stores the actual (encrypted) database connection strings. The `T_` prefix is a legacy naming convention indicating this is a reference/dictionary-style table. `P_GetManagerGroups` reads this table directly (`SELECT *`) to populate group dropdowns in the back-office UI. `LoadManagerByUsername` LEFT JOINs it to surface the group name when authenticating a manager session.

Live data (9 rows):

| ManagerGroupID | GroupDescription |
|---------------|-----------------|
| 1 | Staging Real |
| 2 | Staging Real Remote |
| 3 | Integration Real Remote |
| 4 | Staging Real Russia Limited |
| 5 | Automation Real |
| 6 | Automation Real Remote |
| 9 | Ukraine-ReadWrite |

(IDs 7, 8 appear absent from live data - may have been deleted or reserved.)

---

## 2. Business Logic

### 2.1 Group Name Resolution

**What**: ManagerGroupID -> GroupDescription lookup used when displaying or loading manager group information.

**Columns/Parameters Involved**: `ManagerGroupID`, `GroupDescription`

**Rules**:
- One row per group. ManagerGroupID is the PK - no duplicates possible.
- `P_GetManagerGroups` returns all rows (`SELECT *`) for admin UI population.
- `LoadManagerByUsername` LEFT JOINs on ManagerGroupID to retrieve the group name for the authenticated manager.
- This table is a static dictionary - group definitions rarely change.
- The groups represent deployment/environment tiers: Staging (test environments), Automation (CI/testing robots), Integration (integration test environments), Production-adjacent (Ukraine-ReadWrite).

---

## 3. Data Overview

| ManagerGroupID | GroupDescription | Meaning |
|---------------|-----------------|---------|
| 1 | Staging Real | Primary staging environment with real connection |
| 2 | Staging Real Remote | Staging environment with remote DB connection |
| 3 | Integration Real Remote | Integration test environment, remote DB |
| 4 | Staging Real Russia Limited | Staging environment with Russia-limited access |
| 5 | Automation Real | Automated testing environment, real DB |
| 6 | Automation Real Remote | Automated testing, remote DB connection |
| 9 | Ukraine-ReadWrite | Ukraine team with read-write access |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ManagerGroupID | int | NO | - | CODE-BACKED | Surrogate PK. Uniquely identifies a manager access group. Referenced by BackOffice.T_ManagerAccessGroupToConnectionStrings.ManagerGroupID to link groups to their DB connection strings. |
| 2 | GroupDescription | varchar(300) | NO | - | CODE-BACKED | Human-readable name for the manager group, describing the deployment environment and access type (e.g., "Staging Real Remote", "Automation Real"). Used in back-office UI dropdowns and manager session loading. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.T_ManagerAccessGroupToConnectionStrings | ManagerGroupID | FK (logical) | Links group names to their encrypted DB connection strings |
| BackOffice.P_GetManagerGroups | SELECT * | Reader | Returns all group definitions for admin UI |
| BackOffice.LoadManagerByUsername | LEFT JOIN | Reader | Resolves group name during manager authentication |
| BackOffice.LoadManagers | LEFT JOIN | Reader | Resolves group name when loading manager list |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf configuration table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.T_ManagerAccessGroupToConnectionStrings | Table | FK lookup - maps group IDs to connection strings |
| BackOffice.P_GetManagerGroups | Stored Procedure | Reads all group names for UI |
| BackOffice.LoadManagerByUsername | Stored Procedure | LEFT JOIN to resolve group name at login |
| BackOffice.LoadManagers | Stored Procedure | LEFT JOIN to resolve group name in manager list |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK on ManagerGroupID) | CLUSTERED PK | ManagerGroupID ASC | - | - | Active |

### 7.2 Constraints

No constraints beyond the PK.

---

## 8. Sample Queries

### 8.1 Get all manager groups

```sql
SELECT ManagerGroupID, GroupDescription
FROM BackOffice.T_GroupsDictionary WITH (NOLOCK)
ORDER BY ManagerGroupID;
```

### 8.2 Get group name for a specific ID

```sql
SELECT GroupDescription
FROM BackOffice.T_GroupsDictionary WITH (NOLOCK)
WHERE ManagerGroupID = 1;
-- Returns: 'Staging Real'
```

### 8.3 Get groups with their connection string configuration

```sql
SELECT
    g.ManagerGroupID,
    g.GroupDescription,
    cs.ManagerGroupType,
    cs.DRManagerGroupID
FROM BackOffice.T_GroupsDictionary g WITH (NOLOCK)
LEFT JOIN BackOffice.T_ManagerAccessGroupToConnectionStrings cs WITH (NOLOCK)
    ON cs.ManagerGroupID = g.ManagerGroupID
ORDER BY g.ManagerGroupID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Live Data, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.T_GroupsDictionary | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.T_GroupsDictionary.sql*
