# BackOffice.P_GetConnectionStringsWithGroups

> Decrypts and returns all manager group database connection strings (live and replica) from the encrypted connection string store, executing with elevated owner permissions.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT from BackOffice.T_ManagerAccessGroupToConnectionStrings with symmetric key decryption |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.P_GetConnectionStringsWithGroups` is the secure retrieval procedure for back-office database connection strings. Connection strings are stored encrypted in `BackOffice.T_ManagerAccessGroupToConnectionStrings` using SQL Server symmetric key encryption. This procedure opens the symmetric key, decrypts both connection strings (live and replica) for all manager access groups, and returns them as plaintext along with the group metadata.

The procedure exists to prevent plaintext credentials from being stored anywhere in the database while still making them accessible at runtime. The symmetric key (`ConnectionStringsTableKey`) is protected by a certificate (`EncryptConnectionStrings`), so only the SQL Server instance with the correct certificate can decrypt the data. The `WITH EXECUTE AS OWNER` clause means this procedure runs as the schema owner, not the calling user, ensuring the caller does not need direct access to the symmetric key or the encrypted columns.

Called at application startup or manager login to load connection routing configuration. The `P_` prefix is a legacy naming convention for procedures in this segregation group (introduced ticket 36240, May 2016).

---

## 2. Business Logic

### 2.1 Symmetric Key Decryption Pattern

**What**: Opens a symmetric key before SELECT, decrypts varbinary columns to varchar, then the key is auto-closed at end of batch.

**Columns/Parameters Involved**: `replicaConnectionString`, `liveConnectionString` (both varbinary(300) in table; returned as varchar(300))

**Rules**:
- `OPEN SYMMETRIC KEY ConnectionStringsTableKey DECRYPTION BY CERTIFICATE EncryptConnectionStrings`: opens the key for the session.
- `CAST(DecryptByKey(replicaConnectionString) AS Varchar(300))`: decrypts the binary blob to a plaintext connection string.
- The key remains open for the duration of the batch; SQL Server auto-closes it when the connection ends or on `CLOSE SYMMETRIC KEY`.
- `WITH EXECUTE AS OWNER`: procedure runs with the schema owner's security context, not the caller's. This prevents privilege escalation while allowing decryption.
- Result columns: ManagerGroupID, replicaConnectionString (plaintext), liveConnectionString (plaintext), DRManagerGroupID, ManagerGroupType.

### 2.2 Group Routing Context

**What**: Each returned row provides routing configuration for one manager access group.

**Rules**:
- ManagerGroupID identifies the group (1=Staging Real, 2=Staging Real Remote, etc.) - see BackOffice.T_GroupsDictionary for descriptions.
- replicaConnectionString: used for read queries to reduce primary DB load.
- liveConnectionString: used for write operations and real-time reads.
- DRManagerGroupID: when non-NULL, specifies the fallback group for disaster recovery.
- ManagerGroupType: integer classification of the environment tier.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|

This procedure has no input parameters. It returns a result set with the following columns:

| # | Output Column | Type | Confidence | Description |
|---|--------------|------|------------|-------------|
| 1 | ManagerGroupID | int | CODE-BACKED | Group identifier. FK to BackOffice.T_GroupsDictionary. Identifies the deployment environment group (1=Staging Real, 2=Staging Real Remote, etc.). |
| 2 | replicaConnectionString | varchar(300) | CODE-BACKED | Decrypted read-only replica DB connection string for this group's environment. Used for read queries to reduce primary DB load. Stored encrypted as varbinary(300) in table. |
| 3 | liveConnectionString | varchar(300) | CODE-BACKED | Decrypted primary (read-write) DB connection string for this group's environment. Used for write operations. Stored encrypted as varbinary(300) in table. |
| 4 | DRManagerGroupID | int | CODE-BACKED | Disaster recovery fallback group ID. NULL = no DR configured. When non-NULL, use connection strings from that group's row instead during DR scenarios. |
| 5 | ManagerGroupType | int | NAME-INFERRED | Integer type classification of the group's environment tier. Exact values not defined in DDL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | BackOffice.T_ManagerAccessGroupToConnectionStrings | Reader | Reads and decrypts all group connection string records |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found. Called from BackOffice application at startup/login for connection routing configuration.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.P_GetConnectionStringsWithGroups (procedure)
+-- BackOffice.T_ManagerAccessGroupToConnectionStrings (table)
      +-- BackOffice.T_GroupsDictionary (logical FK)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.T_ManagerAccessGroupToConnectionStrings | Table | SELECT (with decryption) - source of all connection string data |

### 6.2 Objects That Depend On This

No SQL-layer dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EXECUTE AS OWNER | Security | Runs as schema owner, not caller. Required to access symmetric key decryption without granting callers direct key access. |
| ConnectionStringsTableKey | Symmetric Key | SQL Server symmetric key used to encrypt/decrypt connection string columns. Protected by EncryptConnectionStrings certificate. |

---

## 8. Sample Queries

### 8.1 Get all decrypted connection strings

```sql
EXEC BackOffice.P_GetConnectionStringsWithGroups;
```

### 8.2 Get connection string for a specific group (filter after retrieval)

```sql
-- Connection strings must be retrieved via SP (encryption prevents direct SELECT)
-- Store results in a temp table and filter:
CREATE TABLE #ConnStrings (
    ManagerGroupID INT,
    replicaConnectionString VARCHAR(300),
    liveConnectionString VARCHAR(300),
    DRManagerGroupID INT,
    ManagerGroupType INT
);
INSERT INTO #ConnStrings
EXEC BackOffice.P_GetConnectionStringsWithGroups;

SELECT * FROM #ConnStrings WITH (NOLOCK) WHERE ManagerGroupID = 1;
DROP TABLE #ConnStrings;
```

### 8.3 Join with group descriptions

```sql
-- After inserting into temp table as above:
SELECT cs.ManagerGroupID, g.GroupDescription, cs.ManagerGroupType, cs.DRManagerGroupID
FROM #ConnStrings cs
JOIN BackOffice.T_GroupsDictionary g WITH (NOLOCK) ON g.ManagerGroupID = cs.ManagerGroupID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.P_GetConnectionStringsWithGroups | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.P_GetConnectionStringsWithGroups.sql*
