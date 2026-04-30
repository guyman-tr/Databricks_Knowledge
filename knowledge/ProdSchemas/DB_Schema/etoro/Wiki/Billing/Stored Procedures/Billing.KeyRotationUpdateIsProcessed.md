# Billing.KeyRotationUpdateIsProcessed

> Marks a credit card funding record as processed in the PCI key rotation staging table after its FundingData has been successfully re-encrypted with the new encryption key - called by the Key Rotation Funding Service listener after each successful migration.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Billing.KeyRotation.IsProcessed by FundingID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.KeyRotationUpdateIsProcessed` is the acknowledgment procedure for the PCI DSS encryption key rotation pipeline. It records that a specific credit card funding record (identified by FundingID) has been successfully re-encrypted with the new encryption key, transitioning its status in `Billing.KeyRotation` from pending (IsProcessed=0) to completed (IsProcessed=1).

The key rotation pipeline exists to meet PCI DSS compliance: when eToro rotates its encryption key (stored in Key Vault), every credit card's FundingData in `Billing.Funding` must be re-encrypted. The Billing.KeyRotation table is the staging/tracking table for this migration. The Funding Service (running as a PCI-instance listener on a service bus queue) processes one message per FundingID: it fetches the card, decrypts with the old key version, re-encrypts with the new key, updates `Billing.Funding`, and then calls this procedure to flag the migration as complete.

The `@IsProcessed` parameter defaults to 1 (mark as processed) but can be passed as 0 to reset a record back to pending - useful in rollback or re-processing scenarios.

Data flows: Key Rotation Service -> GetKeyRotationFunding (stages records) -> service bus message per FundingID -> Funding Service listener (re-encrypts) -> **KeyRotationUpdateIsProcessed** (marks complete) -> DD_CheckPCIRotationUnProcessedFundings (monitors backlog) -> TruncateKeyRotation (cleanup when done).

---

## 2. Business Logic

### 2.1 Processed Flag Update

**What**: A single-row UPDATE on Billing.KeyRotation, setting the IsProcessed flag for the specified FundingID.

**Columns/Parameters Involved**: `@FundingID`, `@IsProcessed`, `FundingID`, `IsProcessed`

**Rules**:
- `@IsProcessed` defaults to `1` (BIT) - the standard "mark as done" call; explicit 0 is used only for reset/rollback
- UPDATE is by PK (FundingID) so it touches exactly one row (or zero if the FundingID was never staged)
- IsProcessed=1 removes the record from the filtered index `WHERE IsProcessed=0` on Billing.KeyRotation (the index used for pending monitoring and batch selection)
- IsProcessed=0 = still pending; IsProcessed=1 = successfully re-encrypted with new key
- No return value; callers rely on @@ROWCOUNT or downstream monitoring to verify

**Diagram**:
```
Funding Service listener receives service bus message: {FundingID=X}
        |
        v
Fetch Billing.Funding WHERE FundingID=X
        |
        v
Decrypt FundingData with KeyVersion in Billing.Funding
Re-encrypt with new key
Update Billing.Funding (FundingData + KeyVersion)
        |
        v
EXEC KeyRotationUpdateIsProcessed @FundingID=X, @IsProcessed=1  (default)
        |
        v
UPDATE Billing.KeyRotation SET IsProcessed=1 WHERE FundingID=X
        |
        v
Record removed from filtered pending index
Monitoring counters update: Processed++ / Pending--
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INT | NO | - | CODE-BACKED | The Billing.Funding identity key of the credit card record that has been re-encrypted. Matches the PK of Billing.KeyRotation. Must already exist in KeyRotation (staged by GetKeyRotationFunding) for the UPDATE to affect any rows. |
| 2 | @IsProcessed | BIT | YES | 1 | CODE-BACKED | The processed flag value to set. Default=1 (mark as done after successful re-encryption). Pass 0 to reset a record back to pending - used in emergency rollback or re-processing scenarios. |

### Output

No result set returned. Row count affected is 0 (FundingID not in staging table) or 1 (updated successfully).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE target | Billing.KeyRotation | UPDATE | Sets IsProcessed flag by FundingID PK; transitions record from pending (0) to completed (1) in the rotation staging table |

### 5.2 Referenced By (other objects point to this)

Called exclusively by the **Funding Service PCI listener** (application layer, not from any stored procedure in the Billing schema). The listener runs on PCI-compliant instances only and processes service bus messages published by the Key Rotation Service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.KeyRotationUpdateIsProcessed (procedure)
└── Billing.KeyRotation (table - UPDATE target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.KeyRotation | Table | UPDATE target; sets IsProcessed by FundingID PK |

### 6.2 Objects That Depend On This

No stored procedure dependents within the Billing schema. Part of the broader key rotation lifecycle:

| Object | Type | Role in Pipeline |
|--------|------|-----------------|
| Billing.GetKeyRotationFundings | Stored Procedure | STAGE phase: populates KeyRotation staging table; called before this procedure |
| Billing.DD_CheckPCIRotationUnProcessedFundings | Stored Procedure | MONITOR phase: counts WHERE IsProcessed=0; checks backlog health |
| Billing.TruncateKeyRotation | Stored Procedure | CLEANUP phase: truncates KeyRotation after all records are IsProcessed=1 |
| Billing.RollbackPCIRotation | Stored Procedure | ROLLBACK phase: restores Billing.Funding from KeyRotation backup (DBA only) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- `SET NOCOUNT ON` suppresses row-count messages
- No error handling - callers are responsible for detecting zero-row updates
- Simple single-column UPDATE by PK; extremely low overhead
- The `@IsProcessed BIT = 1` default means the procedure can be called with only `@FundingID` for the standard completion case
- Billing.KeyRotation has a filtered nonclustered index `WHERE IsProcessed=0`; setting IsProcessed=1 removes the row from this index, making it invisible to pending-backlog queries and the 3000-limit guard in GetKeyRotationFunding
- PCI DSS safety: this procedure only affects the staging table (Billing.KeyRotation), not Billing.Funding itself; the actual FundingData update is done by the Funding Service before calling this procedure

---

## 8. Sample Queries

### 8.1 Mark a FundingID as processed (standard call)
```sql
EXEC Billing.KeyRotationUpdateIsProcessed @FundingID = 12345678
-- @IsProcessed defaults to 1; marks as re-encrypted
```

### 8.2 Reset a FundingID back to pending (rollback/reprocess)
```sql
EXEC Billing.KeyRotationUpdateIsProcessed
    @FundingID   = 12345678,
    @IsProcessed = 0
-- Resets to pending; record re-appears in filtered pending index
```

### 8.3 Monitor rotation progress (from Key Rotation Design doc)
```sql
DECLARE @ActiveVersion INT = 0
DECLARE @NewVersion    INT = 1

SELECT COUNT(*) AS Remaining
FROM Billing.Funding WITH (NOLOCK)
WHERE FundingTypeID = 1 AND KeyVersion = @ActiveVersion

SELECT COUNT(*) AS Converted
FROM Billing.Funding WITH (NOLOCK)
WHERE FundingTypeID = 1 AND KeyVersion = @NewVersion

SELECT COUNT(*) AS Processed
FROM Billing.KeyRotation WITH (NOLOCK)
WHERE IsProcessed = 1

SELECT COUNT(*) AS Pending
FROM Billing.KeyRotation WITH (NOLOCK)
WHERE IsProcessed = 0
```

---

## 9. Atlassian Knowledge Sources

**Confluence - Key Rotation Design** (page 12030935477, MG space): Describes the full PCI encryption key rotation architecture. Explicitly lists `Billing.KeyRotationUpdateIsProcessed` as: "Update for every funding that got new encryption that it had been processed in table Billing.KeyRotation." Documents the Funding Service listener flow (decrypt old -> encrypt new -> update Billing.Funding -> call this procedure), the 3000-row backlog limit, monitoring queries, and emergency stop procedures via CCM configuration.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 4 lifecycle siblings analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.KeyRotationUpdateIsProcessed | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.KeyRotationUpdateIsProcessed.sql*
