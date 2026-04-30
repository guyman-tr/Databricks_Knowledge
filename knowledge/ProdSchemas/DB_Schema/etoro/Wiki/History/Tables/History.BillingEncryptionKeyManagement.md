# History.BillingEncryptionKeyManagement

> SQL Server temporal history table for Billing.EncryptionKeyManagement: records all past lifecycle status transitions of billing encryption keys (identified by GUID), including status changes during key rotation. 95 history rows, 4 distinct keys, 3 status values, July 2023 to December 2024.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | KeyVersion (INT IDENTITY - no PK on history table) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.BillingEncryptionKeyManagement is the SQL Server temporal system-versioning history table for `Billing.EncryptionKeyManagement`. It automatically captures every INSERT, UPDATE, and DELETE applied to the billing encryption key registry, preserving the complete lifecycle history of each encryption key.

`Billing.EncryptionKeyManagement` manages the lifecycle of encryption keys used in billing operations. Each row represents one encryption key identified by a GUID (`KeyID`) with a monotonically increasing version number (`KeyVersion`, IDENTITY). The `KeyStatusID` tracks the key's current lifecycle state - keys cycle through states during rotation operations (likely: active, pending/rotating, retired).

**Key rotation pattern**: The uniform distribution across 3 status values (approx. 32 rows each) for 4 keys suggests each key transitions through all three status values multiple times during its lifetime. This is consistent with a periodic key rotation protocol where keys are systematically activated and deactivated.

**Current state (live table, 5 rows)**:
- KeyVersion=0: GUID=00000000 (null/placeholder), StatusID=3 (retired)
- KeyVersion=1: StatusID=3 (retired)
- KeyVersion=2: StatusID=3 (retired)
- KeyVersion=3: StatusID=1 (active) - the currently active key
- KeyVersion=4: StatusID=3 (retired)

**Security note**: KeyIDs are GUIDs stored in plaintext in this table. The actual cryptographic key material is NOT stored here - this table only manages metadata (lifecycle status) for keys stored elsewhere (e.g., in a key management service or encrypted column in another store).

**Scale**: 95 history rows, 4 distinct active keys (plus a placeholder zero-GUID). Active July 2023 to December 2024.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: SQL Server automatically writes rows to this history table on any status change (UPDATE) or key deregistration (DELETE) applied to Billing.EncryptionKeyManagement.

**Rules**:
- INSERT into source: new key registered, no immediate history row
- UPDATE (status change): old state moved to history with ValidTo=NOW; new state active with ValidFrom=NOW
- DELETE: deleted row moved to history with ValidTo=NOW
- ValidFrom/ValidTo use UTC (datetime2(7))
- KeyVersion is IDENTITY in source (auto-incrementing) - new keys get higher versions

### 2.2 Key Status Lifecycle

**What**: Keys transition through 3 known status states.

**Rules**:
- Status distribution in history: StatusID=1 (32 rows), StatusID=2 (31 rows), StatusID=3 (32 rows)
- Live active key has StatusID=1 - consistent with StatusID=1 meaning "Active"
- Retired/decommissioned keys have StatusID=3 - consistent with StatusID=3 meaning "Retired" or "Inactive"
- StatusID=2 (31 rows, seen first ~7 minutes after StatusID=1 transitions in 2023) likely means "Pending rotation" or "Inactive/Deactivated"
- Typical lifecycle: 1 (Active) -> 2 (Rotating/Pending) -> 3 (Retired) -> potentially reactivated

### 2.3 Key Version Tracking

**What**: Each unique key is assigned a sequential KeyVersion on creation.

**Rules**:
- KeyVersion=0: placeholder zero-GUID used during initialization or as a sentinel
- Active key versions: 1, 2, 3, 4 (4 real keys + 1 placeholder = 5 live rows)
- To reconstruct key history: filter history by KeyID (GUID) and order by ValidFrom
- `Trace` JSON captures who performed each status transition

---

## 3. Data Overview

95 history rows (July 2023 to December 2024). 5 live rows. 4 real key GUIDs plus 1 zero placeholder. 3 status values distributed ~equally (32/31/32 rows).

| KeyID | KeyVersion | KeyStatusID | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|
| 5B548225-... | 3 | 1 | 2024-12-26 | 9999 (live) | Currently active key. StatusID=1=Active. |
| 0802474B-... | 1 | 3 | 2024-12-24 | 9999 (live) | Retired key. StatusID=3=Retired. |
| (history) | 3 | 2 | 2023-07-30 | 2023-07-31 | Key 3 was in StatusID=2 for ~7 minutes before transitioning to StatusID=3. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | KeyID | uniqueidentifier | NO | - | CODE-BACKED | GUID identifying the encryption key. Unique key identifier. The zero-GUID (00000000-...) is a special placeholder/sentinel. 4 real GUIDs in history (KeyVersions 1-4). The actual cryptographic material is stored externally - this is only the key identifier. |
| 2 | KeyVersion | int | NO | - | CODE-BACKED | Sequential version number from IDENTITY(1,1) in source. Monotonically increasing across all key registrations. Not a PK on history table. KeyVersion=0 is the zero-placeholder. Current active key is KeyVersion=3. |
| 3 | KeyStatusID | int | NO | - | CODE-BACKED | Lifecycle status of the key at this point in time. 3 known values with roughly equal history frequency. StatusID=1=Active (current key has this), StatusID=3=Retired (most live keys), StatusID=2=likely Pending/Rotating (intermediate state). No FK to a status lookup table in DDL. |
| 4 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON connection context captured via computed column at time of status change. Format: {"HostName": "...", "AppName": "...", "SUserName": "...", "SPID": "...", "DBName": "...", "ObjectName": "..."}. Provides full audit trail of who triggered each key status change. |
| 5 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this key status became active. Managed by SQL Server temporal. |
| 6 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this key status was superseded by the next status transition. Managed by SQL Server temporal. Clustered index leading key. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints on history table. No FK from source table to a KeyStatus lookup (status values 1, 2, 3 are used without referential enforcement).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server SYSTEM_VERSIONING | Automatic | Writer | Temporal versioning engine writes all historical states here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BillingEncryptionKeyManagement (temporal history table)
  - automatically maintained by: Billing.EncryptionKeyManagement (source table)
```

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Server temporal engine | System | Writes historical rows from Billing.EncryptionKeyManagement status changes automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_BillingEncryptionKeyManagement | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

Standard temporal clustering on (ValidTo, ValidFrom). PAGE compression. On PRIMARY filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none - no PK) | - | Temporal history tables have no PK constraint. |

---

## 8. Sample Queries

### 8.1 Full lifecycle history for a specific key
```sql
SELECT
    h.KeyID,
    h.KeyVersion,
    h.KeyStatusID,
    h.ValidFrom,
    h.ValidTo,
    DATEDIFF(MINUTE, h.ValidFrom, h.ValidTo) AS ActiveMinutes,
    JSON_VALUE(h.Trace, '$.SUserName') AS ChangedBy
FROM History.BillingEncryptionKeyManagement h WITH (NOLOCK)
WHERE h.KeyID = @KeyGUID
ORDER BY h.ValidFrom ASC;
```

### 8.2 All key status transitions ordered chronologically
```sql
SELECT
    h.KeyVersion,
    h.KeyID,
    h.KeyStatusID,
    h.ValidFrom AS StatusBegin,
    h.ValidTo AS StatusEnd,
    JSON_VALUE(h.Trace, '$.SUserName') AS ChangedBy
FROM History.BillingEncryptionKeyManagement h WITH (NOLOCK)
ORDER BY h.ValidFrom ASC;
```

### 8.3 Current key state vs history (via temporal syntax)
```sql
-- What was the key status on a specific date?
SELECT *
FROM Billing.EncryptionKeyManagement
FOR SYSTEM_TIME AS OF '2024-06-01T00:00:00';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BillingEncryptionKeyManagement | Type: Table | Source: etoro/etoro/History/Tables/History.BillingEncryptionKeyManagement.sql*
