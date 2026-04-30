# BackOffice.T_ManagerAccessGroupToConnectionStrings

> Stores encrypted database connection strings (live and replica) for each back-office manager access group, enabling environment-specific DB routing for manager sessions.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | ManagerGroupID (CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

`BackOffice.T_ManagerAccessGroupToConnectionStrings` is the encrypted credential store for back-office database connection strings, organized by manager access group. Each row corresponds to one manager group (defined in `T_GroupsDictionary`) and holds two encrypted connection strings - one pointing to the live database server and one pointing to the replica - along with metadata about the group type and disaster recovery configuration.

This table exists to enable environment-based DB routing: when a back-office manager logs in, the system determines their group (e.g., "Staging Real Remote", "Automation Real") and reads the appropriate connection strings from this table to route subsequent queries to the correct database environment. The connection strings are stored as `varbinary(300)` - they are encrypted at rest, and only the application layer knows the decryption key.

The `DICTIONARY` filegroup placement and `PAGE` compression indicate this is a relatively small, infrequently-updated configuration table treated as core infrastructure. Live data: 8 rows covering all active manager groups. Only group 1 (Staging Real) has a `DRManagerGroupID=5` (Automation Real), suggesting only one group has a defined disaster recovery fallback.

SPs: `P_GetConnectionStringsWithGroups` reads this table; `P_InsertConnectionStringsWithGroups` and `P_SetConnectionStringsWithGroups` write to it; `LoadManagerByUsername` and `LoadManagers` JOIN it during manager authentication.

---

## 2. Business Logic

### 2.1 Environment-Based Connection String Routing

**What**: Maps manager groups to their DB connection strings for environment-specific routing.

**Columns/Parameters Involved**: `ManagerGroupID`, `replicaConnectionString`, `liveConnectionString`, `ManagerGroupType`

**Rules**:
- Each manager group gets exactly one row (PK on ManagerGroupID).
- `liveConnectionString`: Points to the primary (read-write) database server for this group's environment.
- `replicaConnectionString`: Points to a read-only replica server, used for read-heavy queries.
- Both strings are encrypted (`varbinary(300)`) - application decrypts at runtime.
- `ManagerGroupType` classifies the environment tier (values not decoded from DDL - stored as int).
- At authentication (`LoadManagerByUsername`), the manager's group is resolved and the matching row is read to establish the connection context.

### 2.2 Disaster Recovery Fallback

**What**: Groups can specify a fallback group to use during DR scenarios.

**Columns/Parameters Involved**: `DRManagerGroupID`

**Rules**:
- `DRManagerGroupID` references another ManagerGroupID to use as the DR fallback.
- Only group 1 (Staging Real) has `DRManagerGroupID=5` (Automation Real) in live data.
- Most groups have NULL for `DRManagerGroupID`, indicating no DR fallback is configured.
- In a DR scenario, the application would read the DR group's connection strings instead.

---

## 3. Data Overview

| ManagerGroupID | ManagerGroupType | DRManagerGroupID | Notes |
|---------------|-----------------|-----------------|-------|
| 1 (Staging Real) | (int) | 5 (Automation Real) | Only group with DR fallback configured |
| 2-9 (other groups) | (int) | NULL | No DR fallback configured |

8 total rows. Connection strings are encrypted varbinary - not representable in plain text.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ManagerGroupID | int | NO | - | CODE-BACKED | PK. References BackOffice.T_GroupsDictionary.ManagerGroupID. Identifies which manager access group these connection strings belong to. One row per group. |
| 2 | replicaConnectionString | varbinary(300) | YES | - | CODE-BACKED | Encrypted database connection string pointing to the read-only replica server for this group's environment. Decrypted by application at runtime. Used for read queries to reduce load on the live server. |
| 3 | liveConnectionString | varbinary(300) | YES | - | CODE-BACKED | Encrypted database connection string pointing to the primary (read-write) server for this group's environment. Used for write operations and real-time reads. |
| 4 | DRManagerGroupID | int | YES | - | CODE-BACKED | Disaster recovery fallback group ID. If this group's environment is unavailable, use the connection strings from the group with this ManagerGroupID. NULL = no DR fallback defined. References T_GroupsDictionary.ManagerGroupID. |
| 5 | ManagerGroupType | int | YES | - | NAME-INFERRED | Integer classification of the group's environment type (e.g., Staging, Automation, Integration, Production). Exact values not decoded from DDL. Used to categorize groups in the admin interface. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ManagerGroupID | BackOffice.T_GroupsDictionary.ManagerGroupID | Logical FK | The group whose connection strings are stored |
| DRManagerGroupID | BackOffice.T_GroupsDictionary.ManagerGroupID | Logical FK (self-ref) | DR fallback group |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.P_GetConnectionStringsWithGroups | SELECT | Reader | Retrieves connection strings for runtime routing |
| BackOffice.P_InsertConnectionStringsWithGroups | INSERT | Writer | Adds new group connection string records |
| BackOffice.P_SetConnectionStringsWithGroups | UPDATE | Writer | Updates existing connection strings |
| BackOffice.LoadManagerByUsername | JOIN | Reader | Loads connection strings on manager login |
| BackOffice.LoadManagers | JOIN | Reader | Loads connection strings when listing managers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.T_ManagerAccessGroupToConnectionStrings
+-- BackOffice.T_GroupsDictionary (logical FK on ManagerGroupID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.T_GroupsDictionary | Table | Logical FK - ManagerGroupID must be a valid group |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.P_GetConnectionStringsWithGroups | Stored Procedure | Reads connection strings for runtime use |
| BackOffice.P_InsertConnectionStringsWithGroups | Stored Procedure | Inserts new connection string records |
| BackOffice.P_SetConnectionStringsWithGroups | Stored Procedure | Updates existing connection strings |
| BackOffice.LoadManagerByUsername | Stored Procedure | JOIN to get connection strings at login |
| BackOffice.LoadManagers | Stored Procedure | JOIN to get connection strings in manager list |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK on ManagerGroupID) | CLUSTERED PK | ManagerGroupID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PAGE compression | Storage | Table stored with PAGE compression on DICTIONARY filegroup |
| DICTIONARY filegroup | Storage | Stored on dedicated dictionary/configuration filegroup, not primary data filegroup |

---

## 8. Sample Queries

### 8.1 Get all groups with their type and DR configuration

```sql
SELECT
    cs.ManagerGroupID,
    g.GroupDescription,
    cs.ManagerGroupType,
    cs.DRManagerGroupID,
    dr.GroupDescription AS DRGroupDescription
FROM BackOffice.T_ManagerAccessGroupToConnectionStrings cs WITH (NOLOCK)
JOIN BackOffice.T_GroupsDictionary g WITH (NOLOCK)
    ON g.ManagerGroupID = cs.ManagerGroupID
LEFT JOIN BackOffice.T_GroupsDictionary dr WITH (NOLOCK)
    ON dr.ManagerGroupID = cs.DRManagerGroupID
ORDER BY cs.ManagerGroupID;
```

### 8.2 Get connection strings for a specific group (via SP)

```sql
EXEC BackOffice.P_GetConnectionStringsWithGroups @ManagerGroupID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 3/11 (DDL, Live Data, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.T_ManagerAccessGroupToConnectionStrings | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.T_ManagerAccessGroupToConnectionStrings.sql*
