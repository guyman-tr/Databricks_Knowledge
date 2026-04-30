# Billing.RedeemPayoutProcess_Abort

> Releases a processing lock on Redeem payout process records when a close-position or transfer-units step fails or is aborted, allowing the records to be retried.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Ids + @CorrelationID + @RedeemProcessType identify the lock to release |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

During redeem payout processing, records are "claimed" by a worker by setting an in-process flag (InClosePositionProcess or InTransferUnitsProcess) and a correlation ID. This prevents concurrent workers from double-processing the same record. `Billing.RedeemPayoutProcess_Abort` is the rollback/release mechanism - it clears that flag when the processing step fails, was aborted, or needs to be retried.

Without this procedure, failed processing steps would permanently lock records in a "claimed but not completed" state, halting the payout queue.

Called by `Billing.RedeemPayoutProcess_UpdateStatus` as part of an atomic transaction when a status update needs to release the processing lock first.

---

## 2. Business Logic

### 2.1 Two-Phase Lock Release

**What**: Releases one of two distinct processing locks based on which phase failed.

**Columns/Parameters Involved**: `@RedeemProcessType`, `InClosePositionProcess`, `InTransferUnitsProcess`, `ClosePositionCorrelationID`, `TransferUnitsCorrelationID`

**Rules**:
- `@RedeemProcessType = 1`: Close-position phase aborted. Sets `InClosePositionProcess = 0` WHERE `ClosePositionCorrelationID = @CorrelationID`. This allows the close-position worker to re-claim these records.
- `@RedeemProcessType = 2`: Transfer-units phase aborted. Sets `InTransferUnitsProcess = 0` WHERE `TransferUnitsCorrelationID = @CorrelationID`. This allows the transfer-units worker to re-claim.
- The CorrelationID acts as an idempotency key - only the worker that set the correlation ID can release it, preventing accidental releases by other workers.

**Diagram**:
```
@RedeemProcessType
  = 1 (ClosePosition phase abort)
    --> UPDATE RedeemPayoutProcess
        SET InClosePositionProcess = 0
        WHERE ID IN @Ids AND ClosePositionCorrelationID = @CorrelationID
  = 2 (TransferUnits phase abort)
    --> UPDATE RedeemPayoutProcess
        SET InTransferUnitsProcess = 0
        WHERE ID IN @Ids AND TransferUnitsCorrelationID = @CorrelationID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Ids | BackOffice.IDs (table type) | NO | - | CODE-BACKED | Table-valued parameter of process record IDs to abort. Contains the RedeemPayoutProcessIDs that need their lock released. |
| 2 | @CorrelationID | VARCHAR(36) | NO | - | CODE-BACKED | Correlation ID of the processing session to abort. Only records whose current CorrelationID matches this value will have their lock released, preventing accidental aborts of records claimed by other workers. |
| 3 | @RedeemProcessType | INT | NO | - | CODE-BACKED | Which processing phase to abort: 1 = ClosePosition phase (releases InClosePositionProcess lock), 2 = TransferUnits phase (releases InTransferUnitsProcess lock). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Ids | Billing.RedeemPayoutProcess | Direct write (UPDATE) | Clears processing flags for matched records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.RedeemPayoutProcess_UpdateStatus | @ProcessID, @CorrelationID, @RedeemProcessType | EXEC callee | Called to release lock before status update |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RedeemPayoutProcess_Abort (procedure)
└── Billing.RedeemPayoutProcess (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.RedeemPayoutProcess | Table | UPDATE to clear InClosePositionProcess or InTransferUnitsProcess |
| BackOffice.IDs | User Defined Type | Input parameter type for the list of process IDs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.RedeemPayoutProcess_UpdateStatus | Procedure | Calls this to release lock before updating status |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CorrelationID match | Business safety | Only releases locks where the stored CorrelationID matches @CorrelationID, preventing cross-session lock releases. |

---

## 8. Sample Queries

### 8.1 Abort a failed close-position processing step

```sql
DECLARE @Ids BackOffice.IDs
INSERT INTO @Ids (ID) VALUES (1001), (1002)
EXEC Billing.RedeemPayoutProcess_Abort
    @Ids = @Ids,
    @CorrelationID = 'a1b2c3d4-1234-5678-abcd-ef0123456789',
    @RedeemProcessType = 1  -- ClosePosition phase
```

### 8.2 Abort a failed transfer-units processing step

```sql
DECLARE @Ids BackOffice.IDs
INSERT INTO @Ids (ID) VALUES (1001)
EXEC Billing.RedeemPayoutProcess_Abort
    @Ids = @Ids,
    @CorrelationID = 'a1b2c3d4-1234-5678-abcd-ef0123456789',
    @RedeemProcessType = 2  -- TransferUnits phase
```

### 8.3 Check for stuck in-process records that may need manual abort

```sql
SELECT rpp.RedeemPayoutProcessID, rpp.RedeemID, rpp.InClosePositionProcess,
       rpp.InTransferUnitsProcess, rpp.ClosePositionCorrelationID,
       rpp.InClosePositionProcessDate
FROM Billing.RedeemPayoutProcess rpp WITH (NOLOCK)
WHERE (rpp.InClosePositionProcess = 1 AND rpp.InClosePositionProcessDate < DATEADD(HOUR, -1, GETUTCDATE()))
   OR (rpp.InTransferUnitsProcess = 1 AND rpp.InTransferUnitsProcessDate < DATEADD(HOUR, -1, GETUTCDATE()))
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller analyzed (RedeemPayoutProcess_UpdateStatus) | App Code: skipped | Corrections: 0 applied*
*Object: Billing.RedeemPayoutProcess_Abort | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.RedeemPayoutProcess_Abort.sql*
