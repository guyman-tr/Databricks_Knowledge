# Billing.RedeemPayoutProcess

> Execution record for the backoffice-managed crypto redemption payout pipeline, tracking each redemption's progress through position-close and crypto-units-transfer steps with correlation IDs for distributed tracing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | RedeemPayoutProcessID (INT, IDENTITY, CLUSTERED PK) |
| **Partition** | No ([MAIN] filegroup) |
| **Indexes** | 2 (PK + 1 NCI on RedeemID) |
| **Temporal** | No |

---

## 1. Business Meaning

Billing.RedeemPayoutProcess is the execution journal for the crypto redemption payout pipeline. Once a redemption request is approved (Redeem.RedeemStatusID=3 Approved), a backoffice operator or automated process initiates the actual payout by calling `RedeemPayoutProcess_CreateRecords`. This creates a row here and transitions the Redeem status to 4 (ReadyToRedeem).

Each row tracks two sequential execution steps required to complete a redemption:
1. **Close Position**: The customer's crypto trading position must be closed at the current market price
2. **Transfer Units**: The crypto units (or their cash equivalent) must be transferred to the customer's wallet/external address

Two boolean flags (InClosePositionProcess, InTransferUnitsProcess) and their associated timestamps track the state of each step. Multiple correlation IDs (BoCorrelationID, ClosePositionCorrelationID, TransferUnitsCorrelationID) provide distributed tracing links to the backoffice orchestration system, the position-close service, and the units-transfer service respectively.

**5,340 rows** (Jan 2023 - present): 57% automated (ManagerID=0), 43% operator-initiated. One row per redemption (one RedeemID maps to at most one payout process record at a time).

---

## 2. Business Logic

### 2.1 Payout Process Creation and Redeem Status Transition

**What**: `RedeemPayoutProcess_CreateRecords` creates the payout process record and atomically transitions the Redeem status from Approved(3) to ReadyToRedeem(4).

**Columns/Parameters Involved**: `RedeemID`, `ManagerID`, `BoCorrelationID`, `InClosePositionProcess`, `InTransferUnitsProcess`, `Occurred`

**Rules**:
- Input is a batch of RedeemIDs (BackOffice.IDs TVP) plus @ManagerID and @CorrelationID
- For each RedeemID with RedeemStatusID=3 (Approved):
  - If no existing payout process row: INSERT new row, then UPDATE Redeem.RedeemStatusID=4
  - If existing payout process row: UPDATE ManagerID+BoCorrelationID on existing row, then UPDATE Redeem.RedeemStatusID=4
- ManagerID=0 indicates automated system initiation; non-zero = specific backoffice user
- InClosePositionProcess and InTransferUnitsProcess default to 0 (false) on creation

**Diagram**:
```
BO approves batch of redemptions (RedeemStatusID=3)
        |
        v
RedeemPayoutProcess_CreateRecords(@Ids, @ManagerID, @CorrelationID)
        |
        +-- For each RedeemID:
            |
            +-- No existing row? -> INSERT RedeemPayoutProcess row
            |                    -> UPDATE Redeem.RedeemStatusID = 4 (ReadyToRedeem)
            |
            +-- Existing row?   -> UPDATE ManagerID, BoCorrelationID
                                -> UPDATE Redeem.RedeemStatusID = 4 (ReadyToRedeem)
        |
        v
Returns: ProcessID, RedeemID, PositionID, CID, Units, InstrumentID
         (data needed by BO to execute the actual payout)
```

### 2.2 Two-Step Execution Tracking

**What**: After the payout process row is created, the orchestration system drives two sequential steps: position close and units transfer.

**Columns/Parameters Involved**: `InClosePositionProcess`, `InClosePositionProcessDate`, `InTransferUnitsProcess`, `InTransferUnitsProcessDate`, `ClosePositionCorrelationID`, `TransferUnitsCorrelationID`

**Rules**:
- Step 1 (Close Position): When initiated, InClosePositionProcess is set to 1 and ClosePositionCorrelationID is assigned. InClosePositionProcessDate records when this step was last changed.
- Step 2 (Transfer Units): When initiated, InTransferUnitsProcess is set to 1 and TransferUnitsCorrelationID is assigned. InTransferUnitsProcessDate records when this step was last changed.
- On step completion: the flag returns to 0 (false). The date field retains the last-changed timestamp.
- `RedeemPayoutProcess_Abort` can abort the current step when @RedeemProcessType is provided
- After abort or completion, `RedeemPayoutProcess_UpdateStatus` calls `RedeemStatusUpdate` to advance Billing.Redeem through the state machine

**Observed patterns** (live data):
- ~35% have InClosePositionProcess=true (position close in progress or step was set and not cleared)
- ~0.8% have InTransferUnitsProcess=true (units transfer in progress)
- ~27% have TransferUnitsCorrelationID populated (reached units transfer step)

### 2.3 Abort Flow

**What**: A payout process can be aborted mid-execution, rolling back the in-flight step.

**Rules**:
- `RedeemPayoutProcess_Abort` is called with @RedeemProcessType to indicate which step to abort
- `RedeemPayoutProcess_Update` -> `RedeemPayoutProcess_UpdateStatus` with @RedeemProcessType -> `RedeemPayoutProcess_Abort`
- After abort, `RedeemStatusUpdate` is called to set Redeem status to Terminated or another final state
- Abort requires @@ROWCOUNT > 0 validation to confirm the abort succeeded

---

## 3. Data Overview

| RedeemPayoutProcessID | RedeemID | ManagerID | InClosePositionProcess | InTransferUnitsProcess | Meaning |
|----------------------|----------|-----------|----------------------|----------------------|---------|
| 5340 | 40039 | 0 | true | false | Automated payout. Position close in progress. Units transfer step not yet reached (TransferUnitsCorrelationID present from a prior attempt). |
| 5339 | 38474 | 1050 | false | false | Manager-initiated payout. Both steps cleared (complete or aborted). ClosePositionCorrelationID present, no TransferUnitsCorrelationID - stopped after position close. |
| 5337 | 40038 | 0 | true | false | Automated payout in close position step. Has both CorrelationIDs - reached transfer units previously. |
| 5336 | 40037 | 969 | false | false | Manager-initiated. Both flags cleared. No TransferUnitsCorrelationID - never reached transfer units step. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RedeemPayoutProcessID | INT | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Surrogate primary key. NOT FOR REPLICATION flag indicates this table is part of a replicated setup. Each payout process execution has a unique ID. 5,340 current rows - one per redemption that reached the payout stage. |
| 2 | RedeemID | INT | NO | - | CODE-BACKED | FK to Billing.Redeem(RedeemID). Links this payout execution to the parent redemption request. Indexed via IX_RedeemPayoutProcess_RedeemID. One payout process per redeem (5,340 rows, 5,339 distinct RedeemIDs - one duplicate). |
| 3 | ManagerID | INT | YES | - | CODE-BACKED | BackOffice user who initiated or last updated this payout. 0 = automated system processing. Non-zero = specific BO operator CID. NULL indicates early records before this was consistently populated. 57% of rows have ManagerID=0 (automated), 43% have a specific manager. |
| 4 | InClosePositionProcess | BIT | NO | 0 | CODE-BACKED | Whether the position-close step is currently in progress. 0=not in progress (initial state or step cleared), 1=actively closing the position. Set by the BO orchestration system when it dispatches the position-close command. Cleared when position close is confirmed or aborted. 35% of rows currently have value=1. |
| 5 | InClosePositionProcessDate | DATETIME | YES | - | CODE-BACKED | UTC timestamp when InClosePositionProcess was last changed. Tracks when the close-position step was entered or exited. NULL means this step was never initiated for this payout. |
| 6 | InTransferUnitsProcess | BIT | NO | 0 | CODE-BACKED | Whether the crypto-units-transfer step is currently in progress. 0=not in progress, 1=actively transferring units. Set by BO orchestration when dispatching the unit transfer command. Cleared on transfer completion or abort. Only ~0.8% of rows currently active. |
| 7 | InTransferUnitsProcessDate | DATETIME | YES | - | CODE-BACKED | UTC timestamp when InTransferUnitsProcess was last changed. Tracks when the transfer-units step was last entered or exited. NULL means this step was never initiated. |
| 8 | BoCorrelationID | VARCHAR(36) | YES | - | CODE-BACKED | GUID correlation ID for the backoffice orchestration call that created or last updated this payout process. Always populated (36-char UUID string). Links the DB row to the specific BO system request for diagnostics. |
| 9 | ClosePositionCorrelationID | VARCHAR(36) | YES | - | CODE-BACKED | GUID correlation ID for the position-close service call. Set when InClosePositionProcess is activated. Used to correlate the DB row with the position-close service logs. Present on ~100% of rows (virtually all payouts require a position close). |
| 10 | TransferUnitsCorrelationID | VARCHAR(36) | YES | - | CODE-BACKED | GUID correlation ID for the crypto-units-transfer service call. Set when InTransferUnitsProcess is activated. NULL if the payout never reached or needed the units-transfer step. Present on ~27% of rows - only those that completed position close and proceeded to unit transfer. |
| 11 | Occurred | DATETIME | NO | getutcdate() | CODE-BACKED | UTC timestamp when this payout process row was first created (INSERT time). Defaults to getutcdate(). Not modified after INSERT. Represents when the redemption entered the payout execution pipeline. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RedeemID | Billing.Redeem | FK (FK_Billing_RedeemPayoutProcess_RedeemID) | Links each payout execution to its parent redemption request. `RedeemPayoutProcess_CreateRecords` also directly updates Billing.Redeem.RedeemStatusID as part of the same transaction. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.RedeemPayoutProcess_CreateRecords | RedeemID, ManagerID, BoCorrelationID | WRITER (INSERT/UPDATE) | Creates or updates the payout process row when BO initiates payout for approved redemptions |
| Billing.RedeemPayoutProcess_Update | RedeemPayoutProcessID | MODIFIER | Orchestrates UpdateStatus + payment status change |
| Billing.RedeemPayoutProcess_UpdateStatus | RedeemPayoutProcessID | MODIFIER | Updates process state; optionally calls Abort then calls RedeemStatusUpdate |
| Billing.RedeemPayoutProcess_Abort | RedeemPayoutProcessID | MODIFIER | Aborts an in-flight process step |
| Billing.RedeemPayoutProcess_GetNewRecords | InClosePositionProcess, RedeemID | READER | Returns records ready to begin processing (queued state) |
| Billing.RedeemPayoutProcess_GetClosedPosiotnsRecords | InClosePositionProcess, RedeemID | READER | Returns records where position close is complete |
| Billing.RedeemPayoutProcess_GetNegativeBalanceRecords | RedeemID | READER | Returns records where balance went negative during processing |
| Billing.GetRedeemDetailsByRedeemID | RedeemID | READER | Returns full payout process details for a given redeem |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RedeemPayoutProcess (table)
└-- Billing.Redeem (table) [FK: RedeemID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | FK constraint - RedeemID must exist in Billing.Redeem |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.RedeemPayoutProcess_CreateRecords | Stored Procedure | WRITER - creates payout process rows and transitions Redeem status |
| Billing.RedeemPayoutProcess_Update | Stored Procedure | MODIFIER - orchestrates payout step updates |
| Billing.RedeemPayoutProcess_UpdateStatus | Stored Procedure | MODIFIER - updates process step flags |
| Billing.RedeemPayoutProcess_Abort | Stored Procedure | MODIFIER - aborts an in-flight step |
| Billing.RedeemPayoutProcess_GetNewRecords | Stored Procedure | READER - queue polling |
| Billing.RedeemPayoutProcess_GetClosedPosiotnsRecords | Stored Procedure | READER - step completion polling |
| Billing.RedeemPayoutProcess_GetNegativeBalanceRecords | Stored Procedure | READER - error state detection |
| Billing.GetRedeemDetailsByRedeemID | Stored Procedure | READER - detail lookup |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingRedeemPayoutProcess | CLUSTERED PK | RedeemPayoutProcessID ASC | - | - | Active |
| IX_RedeemPayoutProcess_RedeemID | NONCLUSTERED | RedeemID ASC | - | - | Active |

Index options: FILLFACTOR=95. Both indexes reside on [MAIN] filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingRedeemPayoutProcess | PRIMARY KEY CLUSTERED | RedeemPayoutProcessID must be unique |
| FK_Billing_RedeemPayoutProcess_RedeemID | FOREIGN KEY | RedeemID must exist in Billing.Redeem(RedeemID) |
| Df_Billing_RedeemPayoutProcess_InClosePositionProcess | DEFAULT | InClosePositionProcess defaults to 0 (false) on INSERT |
| Df_Billing_RedeemPayoutProcess_InTransferUnitsProcess | DEFAULT | InTransferUnitsProcess defaults to 0 (false) on INSERT |
| Df_Billing_RedeemPayoutProcess_Occurred | DEFAULT | Occurred defaults to getutcdate() on INSERT |

Note: IDENTITY has `NOT FOR REPLICATION` flag - this table participates in SQL Server replication and the identity column is configured to allow subscriber-side inserts without consuming the identity sequence.

---

## 8. Sample Queries

### 8.1 Find redemptions currently in payout pipeline

```sql
SELECT
    rpp.RedeemPayoutProcessID,
    rpp.RedeemID,
    r.RedeemStatusID,
    rpp.ManagerID,
    rpp.InClosePositionProcess,
    rpp.InClosePositionProcessDate,
    rpp.InTransferUnitsProcess,
    rpp.InTransferUnitsProcessDate,
    rpp.BoCorrelationID,
    rpp.ClosePositionCorrelationID,
    rpp.TransferUnitsCorrelationID,
    rpp.Occurred
FROM [Billing].[RedeemPayoutProcess] rpp WITH (NOLOCK)
INNER JOIN [Billing].[Redeem] r WITH (NOLOCK) ON r.RedeemID = rpp.RedeemID
WHERE rpp.InClosePositionProcess = 1 OR rpp.InTransferUnitsProcess = 1
ORDER BY rpp.Occurred DESC
```

### 8.2 Payout process summary statistics

```sql
SELECT
    COUNT(*) AS TotalProcesses,
    SUM(CASE WHEN ManagerID = 0 THEN 1 ELSE 0 END) AS Automated,
    SUM(CASE WHEN ManagerID != 0 THEN 1 ELSE 0 END) AS OperatorInitiated,
    SUM(CASE WHEN InClosePositionProcess = 1 THEN 1 ELSE 0 END) AS InClosePositionNow,
    SUM(CASE WHEN InTransferUnitsProcess = 1 THEN 1 ELSE 0 END) AS InTransferUnitsNow,
    SUM(CASE WHEN TransferUnitsCorrelationID IS NOT NULL THEN 1 ELSE 0 END) AS ReachedTransferUnits,
    COUNT(*) - SUM(CASE WHEN TransferUnitsCorrelationID IS NOT NULL THEN 1 ELSE 0 END) AS StoppedAtClose
FROM [Billing].[RedeemPayoutProcess] WITH (NOLOCK)
```

### 8.3 Look up full payout details for a specific redemption

```sql
DECLARE @RedeemID INT = 40039

SELECT
    rpp.RedeemPayoutProcessID,
    r.RedeemID,
    r.CID,
    r.PositionID,
    r.RedeemStatusID,
    rpp.ManagerID,
    rpp.InClosePositionProcess,
    rpp.InClosePositionProcessDate,
    rpp.InTransferUnitsProcess,
    rpp.InTransferUnitsProcessDate,
    rpp.BoCorrelationID,
    rpp.ClosePositionCorrelationID,
    rpp.TransferUnitsCorrelationID,
    rpp.Occurred
FROM [Billing].[RedeemPayoutProcess] rpp WITH (NOLOCK)
INNER JOIN [Billing].[Redeem] r WITH (NOLOCK) ON r.RedeemID = rpp.RedeemID
WHERE rpp.RedeemID = @RedeemID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources directly referencing this table were found. The redemption payout pipeline is described in the context of Billing.Redeem documentation.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 6.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.RedeemPayoutProcess | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.RedeemPayoutProcess.sql*
