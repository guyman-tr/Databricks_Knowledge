# Billing.KeyRotation

> PCI DSS encryption key rotation staging table; temporarily holds Billing.Funding credit card records being re-encrypted with a new key version, storing the pre-rotation FundingData as a rollback backup. Currently empty (no rotation in progress).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | FundingID - PK CLUSTERED |
| **Partition** | DICTIONARY filegroup (PAGE compression) |
| **Indexes** | 2 (PK + filtered nonclustered WHERE IsProcessed=0) |

---

## 1. Business Meaning

`Billing.KeyRotation` supports PCI DSS compliance by enabling safe rotation of the encryption key used to protect credit card data in `Billing.Funding.FundingData`. When eToro rotates its encryption key (for PCI DSS compliance or security policy), every credit card FundingData record must be re-encrypted with the new key.

The rotation is a 3-phase process:
1. **Stage** (GetKeyRotationFundings): Copy unrotated credit card records into this table, storing the OLD FundingData as a pre-rotation backup.
2. **Process** (application): Re-encrypt each record with the new key, update Billing.Funding, mark as IsProcessed=1.
3. **Rollback if needed** (RollbackPCIRotation - DBA only): Restore Billing.Funding.FundingData from the KeyRotation backup and reset to the old key version.

The table is currently empty (0 rows) - no rotation is in progress. The 6 supporting procedures cover the full lifecycle: stage, confirm, check status, truncate, and rollback.

---

## 2. Business Logic

### 2.1 Staged Rotation with Rate Limiting

**What**: GetKeyRotationFundings batches the rotation work and enforces a backlog limit to prevent overwhelming the system.

**Columns/Parameters Involved**: `FundingID`, `FundingData`, `UsedKeyVersion`, `IsProcessed`

**Rules**:
```
GetKeyRotationFundings(@topRecords=1000, @keyVersion):

  UnProcessedLimit = 3000 (hard-coded safety limit)
  UnProcessed = COUNT(*) FROM KeyRotation WHERE IsProcessed = 0

  IF (UnProcessed <= 3000):
    INSERT TOP(@topRecords) FundingIDs into KeyRotation:
      Source: Billing.Funding WHERE FundingTypeID = 1  -- credit cards only
                               AND (KeyVersion IS NULL OR KeyVersion != @keyVersion)
                               AND FundingID NOT IN (KeyRotation WHERE IsProcessed = 0)
      Stored: FundingData (CURRENT pre-rotation data), UsedKeyVersion (CURRENT key version)
    Returns: List of FundingIDs just staged

  IF (UnProcessed > 3000):
    Returns: FundingID=0 (signal to caller: backlog too large, pause rotation)
```

### 2.2 Rollback Safety Net (RollbackPCIRotation)

**What**: In case of rotation failure, the pre-rotation FundingData stored in this table can be used to restore Billing.Funding exactly as it was before.

**Columns/Parameters Involved**: `FundingID`, `FundingData`, `IsProcessed`

**Rules**:
```
RollbackPCIRotation (DBA-only emergency procedure):
  1. Get old KeyVersion from Billing.EncryptionKeyManagement WHERE KeyStatusID = 1
  2. WHILE (any rows with IsProcessed = 1 remain):
     - UPDATE Billing.Funding: SET FundingData = KeyRotation.FundingData (restore backup)
                                SET KeyVersion = old_KeyVersion
     - UPDATE KeyRotation: SET IsProcessed = 0 (mark as restored)
  Batch size: 1000 records per transaction (safe for rollback)
```

### 2.3 Processing State Tracking

**What**: IsProcessed tracks whether each record has been successfully re-encrypted by the application.

**Rules**:
```
IsProcessed = 0 (DEFAULT): Record staged, waiting for application to re-encrypt
IsProcessed = 1: Application successfully re-encrypted this FundingID with new key

KeyRotationUpdateIsProcessed(@FundingID, @IsProcessed=1):
  -> Called by application after each successful re-encryption

Filtered index Ix_KeyRotation_IsProcessed WHERE IsProcessed=0:
  -> Efficiently finds pending records without scanning processed ones
```

---

## 3. Data Overview

Table is currently empty (0 rows). No key rotation in progress.

When active during rotation, a row represents: "FundingID=9876543 had FundingData={...} (encrypted with KeyVersion=3) when we started rotating to KeyVersion=4. IsProcessed=0 means it hasn't been re-encrypted yet."

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingID | int | NO | - | VERIFIED | FK to Billing.Funding(FundingID). The credit card funding record being rotated. Part of PK - one row per funding record per rotation cycle (table is truncated between rotations). |
| 2 | FundingData | xml | NO | - | VERIFIED | The PRE-ROTATION FundingData XML from Billing.Funding. Stored as a backup at the time of staging. If rotation fails, RollbackPCIRotation uses this to restore Billing.Funding exactly. Contains the credit card data encrypted with UsedKeyVersion. PAGE compressed storage. |
| 3 | UsedKeyVersion | smallint | YES | 0 | VERIFIED | The encryption key version active in Billing.Funding at the time this record was staged. Captured to identify which key needs re-encryption. 0 = no key version set (NULL coerced to default). |
| 4 | IsProcessed | bit | NO | 0 | VERIFIED | Processing state: 0=staged but not yet re-encrypted by application (DEFAULT), 1=application successfully re-encrypted this record with the new key. Filtered index covers only IsProcessed=0 rows for efficient pending-work queries. |
| 5 | Created | datetime | YES | GETUTCDATE() | VERIFIED | UTC timestamp when this row was inserted into KeyRotation. Auto-populated at stage time. Useful for monitoring rotation duration and identifying stalled records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingID | Billing.Funding | Implicit | Credit card funding record being re-encrypted |
| (via RollbackPCIRotation) | Billing.EncryptionKeyManagement | Implicit | Queries old KeyVersion for rollback target |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetKeyRotationFundings | FundingID, FundingData, UsedKeyVersion | WRITER+READER | Stages records for rotation; enforces 3000-row backlog limit |
| Billing.KeyRotationUpdateIsProcessed | FundingID, IsProcessed | WRITER | Marks records as processed after re-encryption |
| Billing.RollbackPCIRotation | FundingID, FundingData, IsProcessed | READER+WRITER | DBA-only rollback: restores Billing.Funding from backup |
| Billing.TruncateKeyRotation | (all) | TRUNCATE | Clears table after successful rotation or for reset |
| Billing.DD_CheckPCIRotationUnProcessedFundings | IsProcessed | READER | Monitoring: count of unprocessed records |
| Billing.DD_CheckPCIRotationOldFundings | UsedKeyVersion | READER | Monitoring: records with old key versions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.KeyRotation (table)
  (no FK constraints in DDL - all relationships implicit)

Indirectly depends on:
Billing.Funding (table) - source of records to rotate
Billing.EncryptionKeyManagement (table) - key version management
```

### 6.1 Objects This Depends On

No FK constraints. Implicit dependency on Billing.Funding and Billing.EncryptionKeyManagement.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetKeyRotationFundings | Stored Procedure | WRITER+READER - stages rotation batches |
| Billing.KeyRotationUpdateIsProcessed | Stored Procedure | WRITER - marks records as processed |
| Billing.RollbackPCIRotation | Stored Procedure | READER+WRITER - emergency rollback (DBA only) |
| Billing.TruncateKeyRotation | Stored Procedure | TRUNCATE - cleanup after rotation |
| Billing.DD_CheckPCIRotationUnProcessedFundings | Stored Procedure | READER - monitoring |
| Billing.DD_CheckPCIRotationOldFundings | Stored Procedure | READER - monitoring |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Filter | Status |
|-----------|------|-------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | FundingID ASC | - | Active (PAGE compression) on DICTIONARY |
| Ix_KeyRotation_IsProcessed | NONCLUSTERED | IsProcessed ASC | WHERE IsProcessed = 0 | Active (PAGE compression) - only indexes unprocessed rows |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK (unnamed) | PRIMARY KEY CLUSTERED | FundingID - one staging row per credit card per rotation cycle |
| DF_KeyRotation_UsedKeyVersion | DEFAULT | UsedKeyVersion = 0 |
| DF_KeyRotation_IsProcessed | DEFAULT | IsProcessed = 0 (pending by default) |
| (unnamed) | DEFAULT | Created = GETUTCDATE() |

### 7.3 PCI Context

This table is central to PCI DSS compliance. The FundingData XML contains encrypted payment card data. The rotation ensures that when an encryption key is retired, all stored card data is re-encrypted with the current active key. The rollback capability (RollbackPCIRotation) is a safety mechanism explicitly restricted to DBAs.

---

## 8. Sample Queries

### 8.1 Check rotation progress (during active rotation)
```sql
SELECT  IsProcessed,
        COUNT(*)            AS RecordCount,
        MIN(UsedKeyVersion) AS OldestKeyVersion
FROM    Billing.KeyRotation WITH (NOLOCK)
GROUP BY IsProcessed;
-- IsProcessed=0: pending re-encryption; IsProcessed=1: complete
```

### 8.2 Find records not yet processed (using filtered index)
```sql
SELECT  TOP 10 FundingID, UsedKeyVersion, Created
FROM    Billing.KeyRotation WITH (NOLOCK)
WHERE   IsProcessed = 0  -- uses Ix_KeyRotation_IsProcessed filtered index
ORDER BY Created;
```

### 8.3 Check if rotation is needed (from Billing.Funding perspective)
```sql
DECLARE @CurrentKeyVersion SMALLINT = (
    SELECT KeyVersion FROM Billing.EncryptionKeyManagement WITH (NOLOCK)
    WHERE KeyStatusID = 2  -- active key
);

SELECT COUNT(*) AS FundingsNeedingRotation
FROM   Billing.Funding WITH (NOLOCK)
WHERE  FundingTypeID = 1
       AND (KeyVersion IS NULL OR KeyVersion != @CurrentKeyVersion);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific table. See `Billing.EncryptionKeyManagement` for the encryption key lifecycle management table that works alongside KeyRotation.

---

*Generated: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.KeyRotation | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.KeyRotation.sql*
