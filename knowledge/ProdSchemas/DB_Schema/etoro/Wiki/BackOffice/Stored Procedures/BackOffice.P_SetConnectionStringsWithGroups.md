# BackOffice.P_SetConnectionStringsWithGroups

> Updates the encrypted connection strings and/or metadata for an existing manager access group, using IIF-based partial update so only non-NULL parameters overwrite existing values.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE BackOffice.T_ManagerAccessGroupToConnectionStrings SET ... IIF(@param IS NULL, existingCol, EncryptByKey(...)) WHERE ManagerGroupID = @ManagerGroupID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.P_SetConnectionStringsWithGroups` modifies the database connection string configuration for an existing manager access group. It is the UPDATE counterpart to `P_InsertConnectionStringsWithGroups` (which inserts new groups) and `P_GetConnectionStringsWithGroups` (which reads them).

The IIF partial-update pattern allows callers to pass NULL for parameters they do not want to change, preserving existing values. Only non-NULL parameters trigger encryption and overwrite. This makes the procedure suitable for targeted updates - e.g., rotating only the live connection string without disturbing the replica string or DR configuration.

Part of the back-office segregation framework. The @DRManagerGroupID and @ManagerGroupType parameters were added in March 2019 (same as the corresponding INSERT procedure). The symmetric key used for encryption (`ConnectionStringsTableKey`) must be opened before the IIF-guarded `EncryptByKey` calls execute.

---

## 2. Business Logic

### 2.1 IIF Partial Update with Selective Encryption

**What**: Four-column UPDATE where each column is only overwritten if the corresponding parameter is non-NULL.

**Rules**:
- `replicaConnectionString = IIF(@replicaConnectionString IS NULL, replicaConnectionString, EncryptByKey(Key_GUID('ConnectionStringsTableKey'), @replicaConnectionString))`: if @replica is NULL, the existing encrypted value is self-assigned (no change). If non-NULL, the new plaintext is encrypted and stored.
- `liveConnectionString = IIF(@liveConnectionString IS NULL, liveConnectionString, EncryptByKey(Key_GUID('ConnectionStringsTableKey'), @liveConnectionString))`: same pattern for the live (read-write) string.
- `DRManagerGroupID = IIF(@DRManagerGroupID IS NULL, DRManagerGroupID, @DRManagerGroupID)`: plaintext int, no encryption. NULL means "do not change"; passing 0 would set it to 0 (no DR fallback).
- `ManagerGroupType = IIF(@ManagerGroupType IS NULL, ManagerGroupType, @ManagerGroupType)`: plaintext int, same partial-update semantics.
- `WHERE ManagerGroupID = @ManagerGroupID`: single row targeted. If ManagerGroupID does not exist, 0 rows affected (no error).
- The symmetric key must be opened first: `OPEN SYMMETRIC KEY ConnectionStringsTableKey DECRYPTION BY CERTIFICATE EncryptConnectionStrings`.
- All four IIF expressions execute even for unchanged columns - the self-assignment `replicaConnectionString = replicaConnectionString` is a no-op from SQL Server's perspective but does mark the row as updated.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ManagerGroupID | int | NO | - | CODE-BACKED | ID of the manager access group to update. FK to BackOffice.T_GroupsDictionary.ManagerGroupID. If no row exists with this ID, 0 rows are affected (silent no-op). |
| 2 | @replicaConnectionString | varchar(300) | YES | NULL | CODE-BACKED | New plaintext replica (read-only) connection string. If NULL, existing encrypted value is preserved unchanged. If provided, encrypted via EncryptByKey before storage. |
| 3 | @liveConnectionString | varchar(300) | YES | NULL | CODE-BACKED | New plaintext live (read-write) connection string. If NULL, existing encrypted value is preserved unchanged. If provided, encrypted via EncryptByKey before storage. |
| 4 | @DRManagerGroupID | int | YES | NULL | CODE-BACKED | New disaster recovery fallback group ID. If NULL, existing value preserved. Pass explicit value (e.g., 0) to clear the DR fallback. Added March 2019. |
| 5 | @ManagerGroupType | int | YES | NULL | CODE-BACKED | New integer environment tier classification. If NULL, existing value preserved. Added March 2019. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ManagerGroupID | BackOffice.T_ManagerAccessGroupToConnectionStrings | Writer | Updates connection string record for the specified group |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found. Called from BackOffice administration tools when rotating or updating connection strings for deployment environment groups.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.P_SetConnectionStringsWithGroups (procedure)
+-- BackOffice.T_ManagerAccessGroupToConnectionStrings (table) [UPDATE with IIF partial update]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.T_ManagerAccessGroupToConnectionStrings | Table | UPDATE (IIF partial + EncryptByKey) WHERE ManagerGroupID = @ManagerGroupID |

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
| IIF partial-update | Guard | NULL parameters self-assign existing column value - preserves data without requiring the caller to first fetch current values. |

---

## 8. Sample Queries

### 8.1 Rotate only the live connection string for a group

```sql
EXEC BackOffice.P_SetConnectionStringsWithGroups
    @ManagerGroupID = 10,
    @replicaConnectionString = NULL,          -- preserve existing
    @liveConnectionString = 'Server=new-live;Database=etoro;...',
    @DRManagerGroupID = NULL,                 -- preserve existing
    @ManagerGroupType = NULL;                 -- preserve existing
```

### 8.2 Update both connection strings and set DR group

```sql
EXEC BackOffice.P_SetConnectionStringsWithGroups
    @ManagerGroupID = 10,
    @replicaConnectionString = 'Server=new-replica;Database=etoro;...',
    @liveConnectionString = 'Server=new-live;Database=etoro;...',
    @DRManagerGroupID = 11,
    @ManagerGroupType = 1;
```

### 8.3 Verify update applied (read back via getter)

```sql
EXEC BackOffice.P_GetConnectionStringsWithGroups;
-- Check ManagerGroupID=10 row for updated values
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.P_SetConnectionStringsWithGroups | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.P_SetConnectionStringsWithGroups.sql*
