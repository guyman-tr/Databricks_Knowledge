# Billing.RollbackPCIRotation

> DBA-only emergency rollback for a failed PCI encryption key rotation: restores original encrypted FundingData from Billing.KeyRotation backup and resets IsProcessed flags, processing in 1000-row batches.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; processes all IsProcessed=1 rows in Billing.KeyRotation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

PCI DSS compliance requires periodic rotation of encryption keys used to protect cardholder data (SecuredCardData in `Billing.Funding.FundingData`). When a key rotation fails or is aborted mid-way, the `Billing.KeyRotation` table contains the original encrypted data for records that were already re-encrypted with the new key. `Billing.RollbackPCIRotation` undoes the rotation by restoring the old encrypted FundingData values and resetting the IsProcessed flag.

**This procedure is DBA-only.** The code comment explicitly states "Can be executed ONLY BY DBA!!!!!!!!!!!!!!" and the procedure uses `XACT_ABORT ON` to ensure any error aborts the transaction immediately. A botched rollback could permanently corrupt cardholder data.

The procedure also identifies the "old" (currently Active, KeyStatusID=1) key version to restore, and processes records in batches of 1,000 with individual BEGIN/COMMIT TRAN per batch to limit lock duration.

---

## 2. Business Logic

### 2.1 Batched PCI Key Rollback

**What**: Restores original FundingData and resets IsProcessed on KeyRotation records in 1000-row batches.

**Columns/Parameters Involved**: `KeyVersion`, `FundingData`, `IsProcessed`, `KeyStatusID`

**Rules**:
- `@Old_KeyVersion` = the ACTIVE key's version (KeyStatusID=1 in EncryptionKeyManagement). This is the key to revert TO.
- WHILE loop: while #FundingIDs is non-empty (records with IsProcessed=1):
  - Selects TOP 1000 FundingIDs from KeyRotation WHERE IsProcessed=1.
  - BEGIN TRAN:
    - UPDATE Billing.Funding: FundingData = KeyRotation.FundingData (the BACKUP), KeyVersion = @Old_KeyVersion.
    - UPDATE Billing.KeyRotation: IsProcessed = 0 (marks as un-rotated).
    - TRUNCATE and refill #FundingIDs for next batch.
  - COMMIT TRAN.
  - CATCH: ROLLBACK all transactions, RAISERROR.
- Uses XACT_ABORT ON: any error immediately rolls back the current transaction.

**Diagram**:
```
@Old_KeyVersion = KeyVersion WHERE KeyStatusID = 1 (Active key)
#FundingIDs = TOP 1000 from KeyRotation WHERE IsProcessed=1
WHILE @rows_left > 0:
  BEGIN TRAN
    UPDATE Billing.Funding SET FundingData = KeyRotation.FundingData, KeyVersion = @Old_KeyVersion
    UPDATE Billing.KeyRotation SET IsProcessed = 0
    TRUNCATE #FundingIDs
    Refill #FundingIDs (next batch)
  COMMIT TRAN
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | - | No input parameters. Automatically determines old key version and processes all KeyRotation.IsProcessed=1 rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Key version lookup | Billing.EncryptionKeyManagement | READ | Finds the active key version (KeyStatusID=1) to restore |
| FundingData restore | Billing.Funding | UPDATE | Restores original encrypted FundingData and KeyVersion |
| Rollback tracking | Billing.KeyRotation | READ + UPDATE | Source of backup FundingData; IsProcessed reset to 0 |

### 5.2 Referenced By (other objects point to this)

No SQL callers. DBA manual execution only.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RollbackPCIRotation (procedure)
├── Billing.EncryptionKeyManagement (table)
├── Billing.Funding (table)
└── Billing.KeyRotation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.EncryptionKeyManagement | Table | SELECT to get active key version (KeyStatusID=1) |
| Billing.Funding | Table | UPDATE to restore FundingData and KeyVersion |
| Billing.KeyRotation | Table | Source of backup FundingData values; IsProcessed flag updated |

### 6.2 Objects That Depend On This

No SQL dependents. DBA-only.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| XACT_ABORT ON | Safety | Any error immediately aborts and rolls back the current transaction - prevents partial updates. |
| Batch size 1000 | Performance | Limits each transaction to 1000 rows to reduce lock contention on Billing.Funding. |
| DBA-only | Policy | Code comment explicitly restricts execution to DBAs. Not exposed to application layer. |

---

## 8. Sample Queries

### 8.1 Check KeyRotation status before rollback (DBA)

```sql
SELECT
    SUM(CASE WHEN kr.IsProcessed = 1 THEN 1 ELSE 0 END) AS ProcessedRows,
    SUM(CASE WHEN kr.IsProcessed = 0 THEN 1 ELSE 0 END) AS UnprocessedRows,
    COUNT(*) AS Total
FROM Billing.KeyRotation kr WITH (NOLOCK)
```

### 8.2 Check current key versions

```sql
SELECT KeyVersion, KeyStatusID, ModificationDate
FROM Billing.EncryptionKeyManagement WITH (NOLOCK)
ORDER BY KeyStatusID
```

### 8.3 Execute the rollback (DBA only - use with extreme caution)

```sql
-- WARNING: DBA use ONLY. Verify KeyRotation state before executing.
EXEC Billing.RollbackPCIRotation
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 7/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: skipped | Corrections: 0 applied*
*Object: Billing.RollbackPCIRotation | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.RollbackPCIRotation.sql*
