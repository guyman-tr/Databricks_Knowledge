# History.AddDepositStepLog

> Deposit processing step logger with recovery state management: inserts a step log entry into History.DepositStep (via synonym to DB_Logs) and, as a critical side effect, updates Billing.Deposit.DRStatusID to reflect deposit recovery status when steps fail or recover.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StepID OUTPUT (populated via OUTPUT clause from INSERT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.AddDepositStepLog` is the deposit workflow step logger for the payment processing pipeline. It is the primary writer for `History.DepositStep` (a synonym pointing to `DB_Logs.History.DepositStep`). But unlike a simple audit logger, this procedure has a critical **state management side effect**: it directly updates `Billing.Deposit.DRStatusID` based on step outcomes, making it part of the deposit recovery workflow rather than just a passive observer.

When a deposit processing step fails (`StepStatus='Fail'`), this procedure marks the deposit as "Pending" recovery (DRStatusID=1). When a failed step subsequently passes (`StepStatus='Pass'` after a prior 'Fail'), it marks the deposit as "Completed" recovery (DRStatusID=3). This means the deposit recovery status in `Billing.Deposit` is driven entirely by what this procedure records - it is both the logger and the state machine for deposit recovery.

The procedure was introduced on 2020-07-19 by developer Elrom for ticket PAYIL-2799, with subsequent enhancements to add CorrelationID (2021-08-05, PAYIL-2860) and per-step status updates (2021-10-31, PAIL-3244). The `TransactionID <> 0` guard prevents state updates for non-transactional log entries (dummy/test calls with TransactionID=0).

---

## 2. Business Logic

### 2.1 Deposit Recovery State Machine

**What**: The procedure drives Billing.Deposit.DRStatusID based on step pass/fail outcomes, implementing recovery state tracking.

**Columns/Parameters Involved**: `@StepStatus`, `@TransactionID`, `DRStatusID`

**Rules**:
- If @StepStatus = 'Fail' AND @TransactionID != 0:
  - UPDATE Billing.Deposit SET DRStatusID = 1 (Pending) WHERE DepositID = @TransactionID
  - Marks the deposit as needing recovery after this step failure
- If @StepStatus = 'Pass' AND @LastStatus = 'Fail' AND @TransactionID != 0:
  - UPDATE Billing.Deposit SET DRStatusID = 3 (Completed) WHERE DepositID = @TransactionID
  - Recovery is complete: the step that previously failed now passed
- If @StepStatus = 'Pass' AND @LastStatus != 'Fail': no DRStatusID update (normal success flow)
- @TransactionID = 0: no state updates made (guard against test/dummy calls)

**Diagram**:
```
Deposit #12345 processing flow:
    Step "PaymentGatewayRequest" -> Pass   -> no DRStatusID change
    Step "PaymentGatewayRequest" -> Fail   -> DRStatusID = 1 (Pending)
                                    (recovery mechanism kicks in)
    Step "PaymentGatewayRequest" -> Pass   -> DRStatusID = 3 (Completed)
                                    (recovery succeeded)
```

### 2.2 Last Status Lookup for Recovery Detection

**What**: Before deciding whether to mark recovery as complete, the procedure reads the most recent prior status for the same step.

**Columns/Parameters Involved**: `@StepStatus`, `@LastStatus`, `@TransactionID`, `@Step`

**Rules**:
- @LastStatus is populated ONLY when @StepStatus = 'Pass' AND @TransactionID != 0
- Query: SELECT TOP 1 StepStatus FROM History.DepositStep WHERE DepositID=@TransactionID AND Step=@Step ORDER BY Created DESC
- If @LastStatus = 'Fail' AND current status = 'Pass': recovery transition -> set DRStatusID=3
- This lookup happens BEFORE the INSERT, ensuring the "prior" status is the one before this call
- Performance note: this SELECT runs on History.DepositStep (in DB_Logs) every time @StepStatus='Pass' - requires a cross-DB query on the synonym

### 2.3 Transactional Safety

**What**: All operations are wrapped in an explicit transaction for atomicity.

**Rules**:
- BEGIN TRAN / COMMIT TRAN wrap the INSERT + DRStatusID UPDATE
- On CATCH: IF @@TRANCOUNT > 0 THROW; ROLLBACK TRAN
- RETURN 0 on success

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StepID | int OUTPUT | YES | - | CODE-BACKED | OUTPUT parameter populated with the new step row ID via `OUTPUT INSERTED.StepID INTO @Out`. Correctly implemented (unlike AddDepositFinalizationLog which has a similar pattern but never assigns the OUTPUT). |
| 2 | @TransactionID | int | NO | - | CODE-BACKED | Deposit transaction ID (Billing.Deposit.DepositID). The @TransactionID = 0 guard is checked before every Billing.Deposit DRStatusID update and before the LastStatus lookup - prevents state changes for dummy/test calls. |
| 3 | @InitiateRequest | nvarchar(max) | YES | N'' | CODE-BACKED | Full request payload for this processing step. Stored in History.DepositStep.InitiateRequest. Defaults to empty string. Used for replaying failed steps. |
| 4 | @Step | nvarchar(100) | NO | - | CODE-BACKED | Name of the deposit processing step (e.g., "finalize-send-email", "payment-gateway-authorize"). Used as part of the key for the LastStatus lookup (WHERE DepositID = @TransactionID AND Step = @Step). |
| 5 | @StepStatus | nvarchar(20) | NO | - | CODE-BACKED | Outcome of this step. Critical values: 'Pass' (success) and 'Fail' (failure). 'Pass' after prior 'Fail' triggers DRStatusID=3 recovery complete. 'Fail' triggers DRStatusID=1 (Pending). Other values (e.g., 'Skipped') produce no DRStatusID change. |
| 6 | @StepRetries | int | NO | - | CODE-BACKED | Number of retries for this step. Stored in History.DepositStep.StepRetries. 0 = first attempt; positive = transient failures occurred before this outcome. |
| 7 | @Error | nvarchar(max) | YES | N'' | CODE-BACKED | Error details when @StepStatus = 'Fail'. Empty string on success. Stored in History.DepositStep.Error. |
| 8 | @Created | datetime | YES | NULL | CODE-BACKED | Step execution timestamp. Defaults to GETDATE() (local time, not UTC) via COALESCE(@Created, GETDATE()) in the INSERT. Callers can pass an explicit datetime. |
| 9 | @Comment | nvarchar(max) | YES | N'' | CODE-BACKED | Optional free-text notes. Stored in History.DepositStep.Comment. |
| 10 | @CorrelationID | nvarchar(50) | YES | N'' | CODE-BACKED | Distributed tracing identifier for correlating this log entry with the originating service request. Added in PAYIL-2860 (2021-08-05). Stored in History.DepositStep.CorrelationID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TransactionID | History.DepositStep (via synonym) | Write + Read | INSERT step log row; SELECT prior status for recovery detection |
| @TransactionID | Billing.Deposit | Update (side effect) | Updates DRStatusID on step Fail (->1 Pending) or Pass-after-Fail (->3 Completed) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit processing service | (application call) | Application | Called for each step in the deposit payment processing workflow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.AddDepositStepLog (procedure)
├── History.DepositStep (synonym -> DB_Logs.History.DepositStep)
└── Billing.Deposit (table - side effect UPDATE)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.DepositStep | Synonym -> Table (DB_Logs) | INSERT step log row; SELECT prior step status |
| Billing.Deposit | Table | UPDATE DRStatusID based on step outcome (state management side effect) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Deposit processing service | Application | Primary caller for each deposit workflow step |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Transaction wrapped: BEGIN TRAN / COMMIT TRAN / ROLLBACK on CATCH. Uses OUTPUT clause to capture new StepID. The @StepStatus='Pass' path queries DB_Logs via the DepositStep synonym before inserting.

---

## 8. Sample Queries

### 8.1 Find deposit step log entries for a specific transaction

```sql
SELECT TOP 20
    StepID,
    DepositID,
    Step,
    StepStatus,
    StepRetries,
    Error,
    Created,
    CorrelationID
FROM History.DepositStep WITH (NOLOCK)
WHERE DepositID = 12345
ORDER BY Created ASC
```

### 8.2 Check current DRStatusID for deposits with recent step activity

```sql
SELECT
    d.DepositID,
    d.DRStatusID,
    d.PaymentStatusID,
    d.CustomerID
FROM Billing.Deposit d WITH (NOLOCK)
WHERE d.DepositID IN (
    SELECT DISTINCT DepositID
    FROM History.DepositStep WITH (NOLOCK)
    WHERE Created >= DATEADD(HOUR, -1, GETDATE())
)
```

### 8.3 Find steps that triggered recovery state changes (Fail followed by Pass)

```sql
SELECT
    DepositID,
    Step,
    StepStatus,
    StepRetries,
    Created,
    CorrelationID
FROM History.DepositStep WITH (NOLOCK)
WHERE DepositID IN (
    SELECT DepositID FROM History.DepositStep WITH (NOLOCK)
    WHERE StepStatus = 'Fail'
)
ORDER BY DepositID, Created ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 applicable (Phase 9B: no app code match)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.AddDepositStepLog | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.AddDepositStepLog.sql*
