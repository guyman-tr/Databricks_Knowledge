# Billing.AddEncryptionKey

> Registers a new encryption key in `Billing.EncryptionKeyManagement`, blocked when a PCI DSS key rotation is in progress (Billing.KeyRotation non-empty); idempotent if the key already exists.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @KeyID input (UNIQUEIDENTIFIER of the key to register) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.AddEncryptionKey` provisions a new encryption key into the PCI DSS key lifecycle registry (`Billing.EncryptionKeyManagement`). When eToro generates a new encryption key to replace the current active key for protecting credit card data in `Billing.Funding.FundingData`, this procedure registers it with the status "New" (KeyStatusID=2) as the staged candidate for the next rotation cycle.

The procedure exists to enforce two PCI DSS-related invariants: first, that a new key cannot be added while a rotation is already in progress (Billing.KeyRotation being non-empty means credit card records are currently being re-encrypted - adding a competing new key during this window would corrupt the rotation); second, that the same KeyID cannot be registered twice (idempotency check via EXISTS).

Data flows: a DBA or key management service calls this procedure to stage a new key before initiating the rotation cycle. The call to `Billing.RotateEncryptionKey` later atomically promotes the New-status key to Active. The `KeyID` parameter is a GUID reference to external cryptographic material (actual key bytes are not stored in the database).

---

## 2. Business Logic

### 2.1 Rotation-in-Progress Guard

**What**: The procedure refuses to register a new key if `Billing.KeyRotation` is non-empty, preventing key management changes during an active PCI DSS rotation cycle.

**Parameters/Columns Involved**: `Billing.KeyRotation`, `@KeyID`, `@KeyStatusID`

**Rules**:
- `IF NOT EXISTS (SELECT TOP(1) * FROM Billing.KeyRotation)` is the outer guard.
- If `KeyRotation` is non-empty: `RAISERROR('The table Billing.KeyRotation is not empty. In order to truncate the table run the SP Billing.TruncateKeyRotation', 16, 1)` - procedure aborts.
- If `KeyRotation` is empty (normal case): proceed to the inner idempotency check.
- `KeyRotation` is populated during active rotation (by `GetKeyRotationFundings`), emptied on rotation completion or rollback (by `TruncateKeyRotation`).

**Diagram**:
```
CALL AddEncryptionKey(@KeyID, @KeyStatusID)
         |
         v
  KeyRotation is empty?
  YES -> continue
  NO  -> RAISERROR: rotation in progress, run TruncateKeyRotation first
         |
         v
  KeyID already in EncryptionKeyManagement?
  NO  -> INSERT (KeyID, @KeyStatusID)  [default KeyStatusID=2 = New]
  YES -> PRINT 'The KeyID is already exists'  (no-op, idempotent)
```

### 2.2 Default Status is "New" (KeyStatusID=2)

**What**: The default value for `@KeyStatusID` is 2, which maps to "New" - the staging status for a key awaiting rotation.

**Parameters/Columns Involved**: `@KeyStatusID`, `EncryptionKeyManagement.KeyStatusID`

**Rules**:
- KeyStatusID=1 = Active (the key currently in use for encryption operations)
- KeyStatusID=2 = New (staged candidate for the next rotation - default for this procedure)
- KeyStatusID=3 = Inactive (retired keys kept for decryption of existing data)
- In practice this procedure is always called without overriding the default (all registered-via-proc entries should be New status).
- A non-2 `@KeyStatusID` could be passed but would bypass the normal rotation flow.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @KeyID | UNIQUEIDENTIFIER | NO | - | VERIFIED | GUID identifier of the new encryption key to register. This is a reference to external cryptographic material - no actual key bytes are stored in the database. Used in the EXISTS check and as the inserted value in EncryptionKeyManagement.KeyID. Must be unique (duplicate registration is a no-op with a PRINT warning). |
| 2 | @KeyStatusID | INT | NO | 2 | VERIFIED | Initial status for the registered key. Default 2=New (staged candidate for next rotation). Maps to EncryptionKeyManagement.KeyStatusID. Values: 1=Active (currently in use), 2=New (pending rotation), 3=Inactive (retired). Normal usage always uses the default (2=New). Overriding to 1=Active would bypass the standard RotateEncryptionKey promotion flow. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (guard check) | Billing.KeyRotation | READER | SELECT TOP(1) to check if rotation is in progress. Empty = safe to add key. |
| @KeyID | Billing.EncryptionKeyManagement | READER + WRITER | EXISTS check for idempotency, then INSERT if key is new. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called directly from application/DBA tooling during PCI DSS key provisioning.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.AddEncryptionKey (procedure)
|- Billing.KeyRotation (table)            [SELECT TOP(1) - rotation guard]
+- Billing.EncryptionKeyManagement (table) [EXISTS check + INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.KeyRotation | Table | SELECT TOP(1) to verify no rotation is in progress before allowing key registration |
| Billing.EncryptionKeyManagement | Table | EXISTS check for duplicate prevention; INSERT target for the new key record |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from DBA tooling or key management services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Register a new encryption key (default New status)
```sql
EXEC Billing.AddEncryptionKey
    @KeyID      = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
-- If KeyRotation is non-empty, this will RAISERROR.
-- If KeyID already exists, a PRINT warning is emitted (no INSERT).
```

### 8.2 Verify the key was registered
```sql
SELECT  KeyVersion,
        KeyID,
        KeyStatusID,
        ValidFrom,
        ValidTo
FROM    Billing.EncryptionKeyManagement WITH (NOLOCK)
WHERE   KeyID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

### 8.3 Check current key status before registering (pre-flight)
```sql
-- Verify no rotation in progress and see current key states
SELECT  'KeyRotation count' AS Check, COUNT(*) AS Value
FROM    Billing.KeyRotation WITH (NOLOCK)
UNION ALL
SELECT  'Active keys',  COUNT(*) FROM Billing.EncryptionKeyManagement WITH (NOLOCK) WHERE KeyStatusID = 1
UNION ALL
SELECT  'New keys',     COUNT(*) FROM Billing.EncryptionKeyManagement WITH (NOLOCK) WHERE KeyStatusID = 2
UNION ALL
SELECT  'Inactive keys',COUNT(*) FROM Billing.EncryptionKeyManagement WITH (NOLOCK) WHERE KeyStatusID = 3;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.AddEncryptionKey | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.AddEncryptionKey.sql*
