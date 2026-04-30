# BackOffice.P_InsertConnectionStringsWithGroups

> Inserts a new manager group connection string record with encrypted connection strings, using a WHERE NOT EXISTS guard to prevent duplicate group entries.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT INTO BackOffice.T_ManagerAccessGroupToConnectionStrings (WHERE NOT EXISTS guard) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.P_InsertConnectionStringsWithGroups` adds a new database connection string configuration for a manager access group. The connection strings (live and replica) are provided as plaintext by the caller and are encrypted before storage using the `ConnectionStringsTableKey` symmetric key. A `WHERE NOT EXISTS` guard prevents inserting a duplicate entry if the group already has connection strings.

Part of the back-office segregation framework (ticket 36750, June 2016 - "Segregation - connection string encryption"). Added @DRManagerGroupID and @ManagerGroupType parameters in March 2019. A code comment notes a bug fix in the same period: an earlier developer wrote the INSERT without column names, which broke silently when new columns were added to the table.

---

## 2. Business Logic

### 2.1 Conditional Insert with Encryption

**What**: Only inserts if the ManagerGroupID does not already exist. Encrypts both connection strings before storing.

**Rules**:
- `WHERE NOT EXISTS (SELECT * FROM T_ManagerAccessGroupToConnectionStrings WHERE ManagerGroupID = @ManagerGroupID)`: idempotent guard - safe to call multiple times without error.
- `EncryptByKey(Key_GUID('ConnectionStringsTableKey'), @replicaConnectionString)`: encrypts the plaintext connection string using the open symmetric key.
- The symmetric key must be opened first: `OPEN SYMMETRIC KEY ConnectionStringsTableKey DECRYPTION BY CERTIFICATE EncryptConnectionStrings`.
- Result: 0 rows affected if group already exists, 1 row inserted if new.
- No error raised for duplicate groups - silent no-op.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ManagerGroupID | int | NO | - | CODE-BACKED | ID of the manager access group to configure. FK to BackOffice.T_GroupsDictionary.ManagerGroupID. If this group already has a row in T_ManagerAccessGroupToConnectionStrings, the INSERT is skipped (WHERE NOT EXISTS). |
| 2 | @replicaConnectionString | varchar(300) | NO | - | CODE-BACKED | Plaintext replica (read-only) DB connection string. Encrypted by EncryptByKey before storage. Max 300 characters. |
| 3 | @liveConnectionString | varchar(300) | NO | - | CODE-BACKED | Plaintext live (read-write) DB connection string. Encrypted by EncryptByKey before storage. Max 300 characters. |
| 4 | @DRManagerGroupID | int | YES | NULL | CODE-BACKED | Disaster recovery fallback group ID. NULL = no DR fallback. Added March 2019 (bug fix release). Stored plaintext (not encrypted). |
| 5 | @ManagerGroupType | int | YES | NULL | CODE-BACKED | Integer type classification of the environment tier. NULL = unspecified. Added March 2019. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ManagerGroupID | BackOffice.T_ManagerAccessGroupToConnectionStrings | Writer | Inserts new connection string record for the group (if not exists) |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found. Called from BackOffice administration tools when adding new deployment environment groups.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.P_InsertConnectionStringsWithGroups (procedure)
+-- BackOffice.T_ManagerAccessGroupToConnectionStrings (table) [INSERT + EXISTS check]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.T_ManagerAccessGroupToConnectionStrings | Table | INSERT (encrypted) + WHERE NOT EXISTS guard |

### 6.2 Objects That Depend On This

No SQL-layer dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ConnectionStringsTableKey | Symmetric Key | Must be opened before EncryptByKey calls. Protected by EncryptConnectionStrings certificate. |
| WHERE NOT EXISTS | Guard | Prevents duplicate ManagerGroupID entries. Silent no-op if group exists. |

---

## 8. Sample Queries

### 8.1 Insert a new group connection string (new group only)

```sql
EXEC BackOffice.P_InsertConnectionStringsWithGroups
    @ManagerGroupID = 10,
    @replicaConnectionString = 'Server=replica-db;Database=etoro;...',
    @liveConnectionString = 'Server=live-db;Database=etoro;...',
    @DRManagerGroupID = NULL,
    @ManagerGroupType = 1;
```

### 8.2 Verify the record was inserted

```sql
EXEC BackOffice.P_GetConnectionStringsWithGroups;
-- Check for ManagerGroupID = 10 in results
```

### 8.3 Check if a group already has connection strings

```sql
SELECT ManagerGroupID, ManagerGroupType, DRManagerGroupID
FROM BackOffice.T_ManagerAccessGroupToConnectionStrings WITH (NOLOCK)
WHERE ManagerGroupID = 10;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.P_InsertConnectionStringsWithGroups | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.P_InsertConnectionStringsWithGroups.sql*
