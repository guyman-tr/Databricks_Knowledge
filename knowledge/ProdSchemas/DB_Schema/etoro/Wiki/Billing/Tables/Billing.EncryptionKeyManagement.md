# Billing.EncryptionKeyManagement

> PCI DSS encryption key registry - tracks the lifecycle status of encryption keys used in the Billing domain, supporting key rotation operations. Stores key identifiers (GUIDs) and status; actual cryptographic key material is external.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | KeyVersion (IDENTITY PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 (PK clustered) |
| **Temporal** | Yes - SYSTEM_VERSIONING (history in History.BillingEncryptionKeyManagement) |

---

## 1. Business Meaning

`Billing.EncryptionKeyManagement` is the key lifecycle registry for the Billing domain's PCI DSS encryption infrastructure. It maintains a small set of records (5 total, 1 currently active) that track each encryption key by its GUID identifier (`KeyID`) and current status (Active, New, Inactive). The table does NOT store cryptographic key material - the `KeyID` GUID is a reference identifier used to look up keys in an external key management system or vault.

PCI DSS requires periodic key rotation (typically annual). The key rotation lifecycle uses three statuses: a new key is provisioned as `New` (status 2), then rotated to `Active` (status 1), displacing the previous active key to `Inactive` (status 3). The `Billing.RotateEncryptionKey` procedure enforces the invariant: exactly one Active + one New key must exist before rotation is allowed.

System versioning (temporal table) provides a complete audit trail of every key status change, satisfying PCI DSS requirements for cryptographic key lifecycle documentation. The `Trace` computed column captures the session context of each write operation for forensic audit.

---

## 2. Business Logic

### 2.1 Key Status Lifecycle

**What**: Keys progress through New -> Active -> Inactive as rotations occur.

**Columns/Parameters Involved**: `KeyID`, `KeyVersion`, `KeyStatusID`

**Rules**:
| KeyStatusID | Name | Meaning |
|------------|------|---------|
| 1 | Active | Currently active key used for new encryption operations. Exactly 1 should exist at any time. |
| 2 | New | Newly provisioned key, staged for rotation. Exactly 1 should exist when rotation is pending. |
| 3 | Inactive | Previous keys that have been rotated out. No longer used for encryption but retained for decryption of old data. |

Current state: KeyVersion=3 is Active (1), versions 0-2 and 4 are Inactive (3). No New key exists currently - no rotation pending.

### 2.2 Key Rotation Procedure

**What**: `RotateEncryptionKey` atomically transitions the pending New key to Active.

**Columns/Parameters Involved**: `KeyStatusID`

**Rules**:
- PRECONDITION: exactly 1 row with KeyStatusID=1 (Active) AND exactly 1 row with KeyStatusID=2 (New). Otherwise RAISERROR.
- Step 1: UPDATE Active key (KeyStatusID=1) -> Inactive (KeyStatusID=3).
- Step 2: UPDATE New key (KeyStatusID=2) -> Active (KeyStatusID=1).
- Both updates are in a single transaction (BEGIN TRAN / COMMIT TRAN).
- After rotation: new key becomes active, old key is preserved as inactive (for decryption of data encrypted with it).

**Diagram**:
```
Before rotation:
  KeyVersion N   -> KeyStatusID = 1 (Active)
  KeyVersion N+1 -> KeyStatusID = 2 (New)

After RotateEncryptionKey:
  KeyVersion N   -> KeyStatusID = 3 (Inactive)
  KeyVersion N+1 -> KeyStatusID = 1 (Active)
```

### 2.3 Key Addition Gate

**What**: `AddEncryptionKey` prevents key insertion while a rotation operation is in progress.

**Rules**:
- `Billing.AddEncryptionKey(@KeyID, @KeyStatusID=2)` checks `Billing.KeyRotation` first.
- If KeyRotation is NOT empty: rotation in progress, new key insertion blocked (RAISERROR).
- If KeyRotation IS empty AND KeyID not already present: INSERT into EncryptionKeyManagement with status 2 (New).
- Idempotent: silently ignores duplicate KeyIDs.

---

## 3. Data Overview

| KeyVersion | KeyStatusID | Status |
|-----------|------------|--------|
| 0 | 3 | Inactive (first-ever key, now retired) |
| 1 | 3 | Inactive |
| 2 | 3 | Inactive |
| 3 | 1 | **Active** (current encryption key) |
| 4 | 3 | Inactive (was active before version 3) |

KeyIDs are UUIDs - not shown here as they are security-sensitive identifiers.

5 total rows | 1 Active | 4 Inactive | 0 New (no pending rotation)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | KeyID | uniqueidentifier | NO | - | CODE-BACKED | GUID identifier for the encryption key. Used to look up the actual cryptographic key material in an external key management system. NOT the key material itself. Enforced as unique by AddEncryptionKey (prevents duplicate GUID insertion). |
| 2 | KeyVersion | int | NO | IDENTITY(1,1) | CODE-BACKED | Sequential version number and surrogate PK. Auto-incremented. Used by consuming code to reference which version of the key was used to encrypt data (enables correct key lookup during decryption). The value 0 in current data indicates the IDENTITY was seeded at 0. |
| 3 | KeyStatusID | int | NO | - | CODE-BACKED | Current lifecycle status of the key. Values: 1=Active (currently used for encryption, exactly 1 at a time), 2=New (staged for upcoming rotation, exactly 1 when rotation pending), 3=Inactive (rotated out, retained for decryption of old data). Updated by RotateEncryptionKey and UpdateEncryptionKey procedures. |
| 4 | Trace | computed | YES | - | CODE-BACKED | Session context JSON at write time: `{"HostName": "...","AppName": "...","SUserName": "...","SPID": "...","DBName": "...","ObjectName": "..."}`. Not persisted. Provides forensic audit capability for each key status change - identifies which application and user modified the key state. Same pattern as Billing.AftRouting and Billing.DepositTypeConversionFeeOverride. |
| 5 | ValidFrom | datetime2(7) | NO | GENERATED ALWAYS AS ROW START | CODE-BACKED | System-time period start for temporal versioning. Marks when this key version/status combination became effective. Maintained automatically by SQL Server. |
| 6 | ValidTo | datetime2(7) | NO | GENERATED ALWAYS AS ROW END | CODE-BACKED | System-time period end for temporal versioning. Set to 9999-12-31 for current rows. Historical rows in History.BillingEncryptionKeyManagement carry actual end timestamps, providing a complete audit trail of every key status transition for PCI DSS compliance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

None. The table has no FK constraints and no implicit FK dependencies.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetEncryptionKeys | KeyID, KeyVersion, KeyStatusID | READER | Returns all key records (used by encryption layer to determine active key). |
| Billing.AddEncryptionKey | KeyID, KeyStatusID | WRITER | Inserts new key in New status (if no rotation in progress). |
| Billing.RotateEncryptionKey | KeyStatusID | UPDATER | Atomically transitions New -> Active and Active -> Inactive. |
| Billing.UpdateEncryptionKey | KeyStatusID | UPDATER | Updates key status directly (administrative use). |
| Billing.RollbackPCIRotation | KeyStatusID | UPDATER | Reverses a failed rotation (emergency rollback). |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (leaf table).

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetEncryptionKeys | Stored Procedure | READER - retrieves all key versions and statuses |
| Billing.AddEncryptionKey | Stored Procedure | WRITER - inserts new key entries |
| Billing.RotateEncryptionKey | Stored Procedure | UPDATER - performs atomic key rotation |
| Billing.UpdateEncryptionKey | Stored Procedure | UPDATER - direct status update |
| Billing.RollbackPCIRotation | Stored Procedure | UPDATER - emergency rotation rollback |
| History.BillingEncryptionKeyManagement | Table (history) | SYSTEM VERSIONING - receives all row version changes |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EncryptionKeyManagement | CLUSTERED PK | KeyVersion ASC | - | - | Active |

Small table (5 rows) - full scan is negligible. GetEncryptionKeys retrieves all rows.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EncryptionKeyManagement | PRIMARY KEY | KeyVersion - unique version identifier |
| PERIOD FOR SYSTEM_TIME | Temporal | ValidFrom/ValidTo - maintained by SQL Server |
| SYSTEM_VERSIONING = ON | Temporal | History table: History.BillingEncryptionKeyManagement |

Note: No UNIQUE constraint on KeyID - uniqueness enforced in application logic via AddEncryptionKey's SELECT check.

---

## 8. Sample Queries

### 8.1 Get the currently active encryption key

```sql
SELECT KeyID, KeyVersion, KeyStatusID
FROM [Billing].[EncryptionKeyManagement] WITH (NOLOCK)
WHERE KeyStatusID = 1;  -- Active
```

### 8.2 Check rotation readiness (should have exactly 1 Active and 1 New)

```sql
SELECT KeyStatusID,
    CASE KeyStatusID WHEN 1 THEN 'Active' WHEN 2 THEN 'New' WHEN 3 THEN 'Inactive' END AS Status,
    COUNT(*) AS KeyCount
FROM [Billing].[EncryptionKeyManagement] WITH (NOLOCK)
GROUP BY KeyStatusID
ORDER BY KeyStatusID;
```

### 8.3 View full key lifecycle history (temporal)

```sql
SELECT KeyVersion, KeyStatusID,
    CASE KeyStatusID WHEN 1 THEN 'Active' WHEN 2 THEN 'New' WHEN 3 THEN 'Inactive' END AS Status,
    ValidFrom, ValidTo
FROM [Billing].[EncryptionKeyManagement]
FOR SYSTEM_TIME ALL
ORDER BY KeyVersion, ValidFrom;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.EncryptionKeyManagement | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.EncryptionKeyManagement.sql*
