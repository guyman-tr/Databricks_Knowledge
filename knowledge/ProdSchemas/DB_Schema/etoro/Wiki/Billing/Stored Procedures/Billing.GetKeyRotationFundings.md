# Billing.GetKeyRotationFundings

> Stages the next batch of credit card funding records for PCI DSS encryption key rotation; inserts unrotated Billing.Funding records into Billing.KeyRotation and returns the queued FundingIDs, or returns FundingID=0 if the backlog is too large.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @keyVersion - target encryption key version; returns staged FundingIDs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetKeyRotationFundings` is Phase 1 (Stage) of eToro's PCI DSS encryption key rotation process for stored credit card data. When eToro rotates its encryption key (required periodically for PCI DSS compliance), every credit card record in `Billing.Funding.FundingData` must be re-encrypted with the new key. This procedure batches that work safely.

The procedure copies up to `@topRecords` (default 1,000) credit card funding records that have not yet been encrypted with `@keyVersion` into `Billing.KeyRotation`, storing the current (pre-rotation) `FundingData` as a rollback backup. A downstream key rotation service then re-encrypts each record, updates `Billing.Funding`, and marks the `KeyRotation` row as processed. If rotation fails, `RollbackPCIRotation` can restore from the stored backup.

Rate limiting: if the unprocessed backlog in `Billing.KeyRotation` exceeds 3,000 records, the procedure returns a single row with `FundingID=0` instead of queuing more - signaling the caller to pause and let the service catch up.

EXECUTE is granted to `KeyRotationServiceUser` - confirming this is called by a dedicated key rotation service, not from interactive or other stored procedure code.

---

## 2. Business Logic

### 2.1 Staged Rotation with Backlog Rate Limiting

**What**: Before queuing more records, the procedure checks whether the current unprocessed backlog is within safe limits. This prevents overwhelming the rotation service.

**Columns/Parameters Involved**: `@topRecords`, `@keyVersion`, `@UnProcessedLimit=3000`, `@UnProcessed`

**Rules**:
- Hard-coded safety limit: `@UnProcessedLimit = 3000`
- If `COUNT(*) FROM KeyRotation WHERE IsProcessed=0 <= 3000`: proceed with INSERT
- If backlog > 3000: skip INSERT, return `FundingID=0` as sentinel (caller must pause)
- `FundingID=0` in results is NOT a real FundingID - it is a backpressure signal

**Diagram**:
```
@UnProcessed = COUNT(*) FROM KeyRotation WHERE IsProcessed=0

IF @UnProcessed <= 3000:
    INSERT TOP(@topRecords) into KeyRotation
        (source: Billing.Funding WHERE FundingTypeID=1
                                  AND (KeyVersion IS NULL OR KeyVersion != @keyVersion)
                                  AND FundingID NOT IN (unprocessed KeyRotation))
    Returns: [FundingID1, FundingID2, ..., FundingIDN]  (up to @topRecords rows)

ELSE (backlog too large):
    INSERT FundingID=0 into @InsertedFundingIDs
    Returns: [0]  <- sentinel, means "paused - too many unprocessed"
```

### 2.2 Credit Card Only (FundingTypeID=1)

**What**: Key rotation only applies to credit card records, which contain sensitive card data requiring PCI-regulated encryption.

**Columns/Parameters Involved**: `FundingTypeID=1`, `KeyVersion`, `FundingData`

**Rules**:
- Filter: `Billing.Funding WHERE FundingTypeID = 1` - only credit card funding records
- `KeyVersion IS NULL OR KeyVersion != @keyVersion` - targets records not yet on the new key
- Already-queued records excluded via: `FundingID NOT IN (SELECT FundingID FROM KeyRotation WHERE IsProcessed=0)`
- The stored `FundingData` (current, pre-rotation encrypted value) serves as the rollback backup in `Billing.KeyRotation.FundingData`
- `UsedKeyVersion` stored = current `Billing.Funding.KeyVersion` (the OLD key version being rotated away from)

### 2.3 Three-Phase Rotation Protocol

**What**: This procedure is Phase 1 of 3 in the rotation lifecycle.

**Columns/Parameters Involved**: `IsProcessed`, `FundingData`, `UsedKeyVersion`

**Rules**:
```
Phase 1 - Stage (this procedure):
  GetKeyRotationFundings(@topRecords, @keyVersion)
  -> Copies (FundingID, FundingData, UsedKeyVersion) to Billing.KeyRotation
  -> Returns FundingIDs to the rotation service

Phase 2 - Process (rotation service):
  For each returned FundingID:
    Re-encrypt FundingData with new key
    UPDATE Billing.Funding SET FundingData=<new_encrypted>, KeyVersion=@keyVersion
    UPDATE Billing.KeyRotation SET IsProcessed=1

Phase 3 - Rollback if needed (DBA/RollbackPCIRotation):
  RESTORE Billing.Funding.FundingData from KeyRotation.FundingData
  RESET Billing.Funding.KeyVersion to KeyRotation.UsedKeyVersion
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @topRecords | INT | YES | 1000 | CODE-BACKED | Maximum number of funding records to stage per call. Default 1,000 keeps batch sizes manageable for the rotation service. |
| 2 | @keyVersion | SMALLINT | NO | - | CODE-BACKED | The target encryption key version to rotate TO. Records already on this key version (Billing.Funding.KeyVersion = @keyVersion) are excluded from staging. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | FundingID | INT | NO | - | CODE-BACKED | FundingID of each credit card record staged into Billing.KeyRotation. Special value FundingID=0 means the unprocessed backlog exceeded 3,000 records - the rotation service should pause and not call again until the backlog is cleared. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Billing.Funding | Direct Read + Write (via INSERT) | Reads FundingID, FundingData, KeyVersion for credit cards (FundingTypeID=1) not yet on target key version |
| INSERT target | Billing.KeyRotation | Direct Write | Stages (FundingID, FundingData, UsedKeyVersion) for re-encryption; also reads IsProcessed for backlog check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KeyRotationServiceUser (permissions) | EXECUTE grant | Permission | Dedicated PCI key rotation service that calls this procedure in batch rotation loops |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetKeyRotationFundings (procedure)
├── Billing.KeyRotation (table)
└── Billing.Funding (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.KeyRotation | Table | Read (IsProcessed=0 backlog check) + INSERT (staging records for rotation) |
| Billing.Funding | Table | Read - selects credit card records (FundingTypeID=1) not yet on target key version |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KeyRotationServiceUser | DB Role/User | EXECUTE permission granted - PCI key rotation service calls this to stage batches |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Stage a batch for key version 3

```sql
EXEC Billing.GetKeyRotationFundings
    @topRecords = 1000,
    @keyVersion = 3
-- Returns FundingIDs staged, or FundingID=0 if backlog > 3000
```

### 8.2 Check current rotation backlog before calling

```sql
SELECT
    COUNT(*) AS UnprocessedInBacklog,
    CASE WHEN COUNT(*) > 3000 THEN 'PAUSED - too many unprocessed'
         ELSE 'OK - can stage more'
    END AS Status
FROM Billing.KeyRotation WITH (NOLOCK)
WHERE IsProcessed = 0
```

### 8.3 Check how many credit card fundings still need rotation to a given key version

```sql
SELECT COUNT(*) AS RemainingToRotate
FROM Billing.Funding WITH (NOLOCK)
WHERE FundingTypeID = 1
  AND (KeyVersion IS NULL OR KeyVersion != 3)  -- replace 3 with target version
  AND FundingID NOT IN (
      SELECT FundingID FROM Billing.KeyRotation WITH (NOLOCK) WHERE IsProcessed = 0
  )
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetKeyRotationFundings | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetKeyRotationFundings.sql*
