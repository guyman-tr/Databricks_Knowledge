# History.AddDepositFinalizationLog

> Step-level log writer for the deposit finalization workflow, inserting one row into History.DepositFinalization per finalization step executed, with re-throw on failure.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FinalizationID OUTPUT (declared but never assigned - known bug) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.AddDepositFinalizationLog` is the sole writer for `History.DepositFinalization`. It is called during the deposit finalization workflow - the multi-step process that runs after a payment is approved to credit the customer's account, apply bonuses, notify CRM, etc. Each step in this workflow is logged here, with the step name, its outcome (Pass/Fail), retry count, and any error details.

This procedure was introduced on 2021-06-06 by developer Elrom for Jira ticket PAYIL-2688 to add observability to the finalization pipeline. Unlike `History.AddDepositStepLog` (which also updates `Billing.Deposit.DRStatusID` as a side effect), this procedure is a pure append-only logger with no side effects on other tables.

**Known bug**: The `@FinalizationID OUTPUT` parameter is declared but is never assigned inside the procedure (there is no `SELECT @FinalizationID = SCOPE_IDENTITY()` call). Any caller expecting the new row ID in the OUTPUT parameter will receive NULL. The table's FinalizationID IDENTITY value IS generated on INSERT, but it is not returned to the caller.

On failure, the procedure re-throws the exception (`THROW`), which propagates the original error to the caller (unlike some other log procedures that silently return -1 or swallow errors).

---

## 2. Business Logic

### 2.1 Deposit Finalization Step Tracking

**What**: Each procedure call appends one step record to the deposit finalization audit trail.

**Columns/Parameters Involved**: `@DepositID`, `@Step`, `@StepStatus`, `@StepRetries`, `@Error`

**Rules**:
- One DepositID will accumulate multiple rows - one per finalization step
- @StepStatus is free-text (e.g., "Success", "Failed", "Skipped") - no integer code constraints
- @StepRetries tracks how many retries occurred for this step (0 = first-try success, >0 = needed retries)
- @Error captures exception text on failure; empty/default when step succeeds
- @Created defaults to GETUTCDATE() if NULL
- @FinalizationRequest stores the full JSON/XML request payload for this deposit's finalization call

**Diagram**:
```
Deposit #12345 approved -> finalization workflow starts:
    Step 1: AddDepositFinalizationLog(@DepositID=12345, @Step="CreditBalance", @StepStatus="Success", @StepRetries=0)
    Step 2: AddDepositFinalizationLog(@DepositID=12345, @Step="ApplyBonus", @StepStatus="Failed", @StepRetries=2, @Error="Timeout")
    Step 3: AddDepositFinalizationLog(@DepositID=12345, @Step="NotifyCRM", @StepStatus="Success", @StepRetries=0)
```

### 2.2 OUTPUT Parameter Bug

**What**: @FinalizationID OUTPUT is declared but never populated.

**Columns/Parameters Involved**: `@FinalizationID` (OUTPUT)

**Rules**:
- The IDENTITY value IS generated in History.DepositFinalization on INSERT
- However, no `SELECT @FinalizationID = SCOPE_IDENTITY()` (or equivalent) is present in the procedure body
- Any caller reading @FinalizationID after execution will receive its pre-call value (typically NULL if uninitialized)
- This is a design bug introduced in the initial version (PAYIL-2688)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FinalizationID | int OUTPUT | YES | - | CODE-BACKED | OUTPUT parameter for the new row ID. Declared as OUTPUT but never assigned in procedure body (known bug - SCOPE_IDENTITY() not captured). Callers receiving NULL should not rely on this value until the bug is fixed. |
| 2 | @DepositID | int | NO | - | CODE-BACKED | ID of the deposit transaction being finalized. FK to Billing.Deposit.DepositID. All finalization steps for the same deposit share this ID; used to query the complete finalization history for a deposit. |
| 3 | @FinalizationRequest | nvarchar(max) | YES | N'' | CODE-BACKED | Full request payload (JSON/XML) sent to the finalization service for this deposit. Stored for replay/debugging. Defaults to empty string if not provided. |
| 4 | @Step | nvarchar(100) | NO | - | CODE-BACKED | Name of the finalization step being logged (e.g., "CreditBalance", "ApplyBonus", "NotifyCRM"). Free-text name defined by the calling application workflow. |
| 5 | @StepStatus | nvarchar(20) | NO | - | CODE-BACKED | Outcome of this finalization step. Free-text (e.g., "Success", "Failed", "Skipped"). Not an integer enum - the application layer defines the valid status vocabulary. |
| 6 | @StepRetries | int | NO | - | CODE-BACKED | Number of times this step was retried before the logged outcome. 0 = first attempt succeeded or failed; positive = transient failures were encountered before reaching this state. |
| 7 | @Error | nvarchar(max) | YES | N'' | CODE-BACKED | Error/exception details when @StepStatus indicates failure. Empty string (default) when step succeeds. Contains the exception message or stack trace from the finalization service. |
| 8 | @Created | datetime | YES | NULL | CODE-BACKED | Timestamp when this step executed. NULL defaults to GETUTCDATE() in the INSERT (ISNULL(@Created, GETUTCDATE())). Callers may pass an explicit datetime if the execution time differs from DB insert time. |
| 9 | @Comment | nvarchar(max) | YES | N'' | CODE-BACKED | Optional free-text notes about this step execution. Defaults to empty string. Used for supplementary context not captured by @Error or @Step. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | History.DepositFinalization | Write target | Inserts one step row per finalization step execution |
| @DepositID | Billing.Deposit | Implicit | @DepositID references the deposit being finalized |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit finalization service | (application call) | Application | Called for each step in the post-payment deposit finalization workflow. No SSDT procedures call this. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.AddDepositFinalizationLog (procedure)
└── History.DepositFinalization (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.DepositFinalization | Table | INSERT target - one row per finalization step |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Deposit finalization service | Application | Calls once per step in the finalization workflow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. On CATCH: `THROW` (re-throws original exception). RETURN(-1) after THROW is unreachable (THROW propagates, control never reaches RETURN). @FinalizationID OUTPUT is never assigned - known defect.

---

## 8. Sample Queries

### 8.1 Show finalization steps for a specific deposit

```sql
SELECT
    FinalizationID,
    DepositID,
    Step,
    StepStatus,
    StepRetries,
    Error,
    Created,
    Comment
FROM History.DepositFinalization WITH (NOLOCK)
WHERE DepositID = 12345
ORDER BY Created ASC
```

### 8.2 Find failed finalization steps requiring investigation

```sql
SELECT TOP 20
    FinalizationID,
    DepositID,
    Step,
    StepRetries,
    Error,
    Created
FROM History.DepositFinalization WITH (NOLOCK)
WHERE StepStatus <> 'Success'
ORDER BY Created DESC
```

### 8.3 Count finalization steps by status to monitor pipeline health

```sql
SELECT
    Step,
    StepStatus,
    COUNT(*) AS Count,
    AVG(CAST(StepRetries AS float)) AS AvgRetries
FROM History.DepositFinalization WITH (NOLOCK)
GROUP BY Step, StepStatus
ORDER BY Step, StepStatus
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 applicable (Phase 9B: no app code match)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.AddDepositFinalizationLog | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.AddDepositFinalizationLog.sql*
