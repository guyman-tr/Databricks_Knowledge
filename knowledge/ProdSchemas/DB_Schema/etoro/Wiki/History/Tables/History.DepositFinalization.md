# History.DepositFinalization

> Step-level execution log for the deposit finalization process - each row records one step in the multi-step workflow that credits a customer's trading account after a payment is approved, capturing the step name, outcome, retry count, and any errors.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | FinalizationID (int IDENTITY, no PK constraint - heap table) |
| **Partition** | No |
| **Indexes** | 1 active (NONCLUSTERED on DepositID) |

---

## 1. Business Meaning

This table is the **deposit finalization step log**. When a deposit is approved by the payment provider (reaches `PaymentStatusID=2` in `Billing.Deposit`), the system runs a multi-step finalization workflow to apply the deposit to the customer's trading account - crediting balance, applying welcome bonuses, updating compliance records, etc. Each step in this workflow is logged here via `History.AddDepositFinalizationLog`.

The table was created on 2021-06-06 by developer "Elrom" for Jira ticket PAYIL-2688, indicating it was introduced to add observability to the deposit finalization pipeline. The table currently has **0 rows** - either the application layer that calls `History.AddDepositFinalizationLog` has not been deployed, the logging was later disabled, or this environment's data was cleared.

The table is a **heap** (no clustered index), which is appropriate for append-only log tables where insert speed is prioritized over range scan performance. The only index is NONCLUSTERED on `DepositID` to support lookup queries like "what finalization steps ran for this deposit?"

---

## 2. Business Logic

### 2.1 Deposit Finalization Step Logging

**What**: Each call to `History.AddDepositFinalizationLog` inserts one row recording the outcome of one named step in the finalization workflow.

**Columns/Parameters Involved**: `DepositID`, `Step`, `StepStatus`, `StepRetries`, `Error`, `FinalizationRequest`, `Created`

**Rules**:
- One `DepositID` will have multiple rows - one per step in the finalization workflow (e.g., "CreditBalance", "ApplyBonus", "NotifyCRM").
- `Step` is the name of the finalization step as defined by the calling application.
- `StepStatus` is a free-text status string (e.g., `"Success"`, `"Failed"`, `"Skipped"`) rather than an integer enum - the step status vocabulary is defined in the application, not in the database.
- `StepRetries` (default 0) tracks how many times the step was retried before achieving the recorded status. Non-zero values indicate transient failures that resolved on retry.
- `Error` captures exception/error details when a step fails. Combined with `StepRetries`, this enables diagnosis of what broke and how many attempts were needed.
- `FinalizationRequest` stores the full request payload (likely JSON) sent to the finalization service for this deposit. Useful for replaying or debugging failed finalizations.
- `Comment` provides a free-text field for additional context (can be empty string).
- `Created` defaults to GETUTCDATE() if NULL - represents when the step was executed.
- `@FinalizationID OUTPUT` is declared in the SP but never assigned - the return value of SCOPE_IDENTITY() is not captured (appears to be an oversight in the SP definition).

**Diagram**:
```
Deposit #12345 approved (PaymentStatusID -> 2):
  Finalization workflow starts:
    Step "ValidateCustomer"  -> StepStatus="Success", Retries=0 -> 1 row inserted
    Step "CreditBalance"     -> StepStatus="Success", Retries=0 -> 1 row inserted
    Step "ApplyBonus"        -> StepStatus="Failed",  Retries=2, Error="Timeout" -> 1 row inserted
    Step "NotifyCRM"         -> StepStatus="Success", Retries=1 -> 1 row inserted

History.DepositFinalization for DepositID=12345:
  Row 1: Step="ValidateCustomer",  StepStatus="Success", StepRetries=0
  Row 2: Step="CreditBalance",     StepStatus="Success", StepRetries=0
  Row 3: Step="ApplyBonus",        StepStatus="Failed",  StepRetries=2, Error="Timeout"
  Row 4: Step="NotifyCRM",         StepStatus="Success", StepRetries=1
```

---

## 3. Data Overview

The table currently contains **0 rows** in this environment. This may indicate:
- The application calling `History.AddDepositFinalizationLog` is not deployed or configured in this environment.
- The finalization logging was introduced (2021-06-06) but later disabled or rerouted to another system.
- Data was cleared/purged.

A representative set of rows for a finalized deposit would look like:

| FinalizationID | DepositID | Step | StepStatus | StepRetries | Error | Created |
|---|---|---|---|---|---|---|
| 1 | 10793579 | ValidateCustomer | Success | 0 | null | 2024-01-15 09:00:01 |
| 2 | 10793579 | CreditBalance | Success | 0 | null | 2024-01-15 09:00:02 |
| 3 | 10793579 | ApplyBonus | Failed | 2 | Service timeout | 2024-01-15 09:00:05 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FinalizationID | int | NO | IDENTITY | CODE-BACKED | Auto-incremented surrogate key. No PK constraint defined in DDL - the table is a heap with only an NONCLUSTERED index on DepositID. Note: `History.AddDepositFinalizationLog` declares `@FinalizationID OUTPUT` but does not assign SCOPE_IDENTITY() to it - the OUTPUT parameter is unused. |
| 2 | DepositID | int | NO | - | CODE-BACKED | The deposit being finalized. FK to Billing.Deposit (implicit). The NONCLUSTERED index on DepositID supports lookup queries: "what finalization steps ran for this deposit?" Multiple rows per DepositID (one per step). |
| 3 | FinalizationRequest | nvarchar(max) | YES | - | CODE-BACKED | The full finalization request payload, likely JSON, sent to the finalization service for this deposit. Enables replay and debugging of failed finalizations. Stored on [HISTORY] filegroup TEXTIMAGE_ON for large-value columns. |
| 4 | Step | nvarchar(100) | YES | - | CODE-BACKED | The name of the finalization step being logged (e.g., "ValidateCustomer", "CreditBalance", "ApplyBonus"). Defined by the calling application - not an enum from a dictionary table. Identifies which part of the workflow this row represents. |
| 5 | StepStatus | nvarchar(20) | YES | - | CODE-BACKED | Free-text outcome status for this step (e.g., "Success", "Failed", "Skipped"). Not an integer FK - the vocabulary is application-defined. Used to filter for failed steps during investigation. |
| 6 | StepRetries | int | YES | 0 | CODE-BACKED | Number of retries before this outcome was reached. Default=0 (succeeded or failed on first attempt). Non-zero values indicate transient failures: a step with Retries=3 and Status="Success" resolved after 3 retries; Retries=3 and Status="Failed" means 4 total attempts all failed. |
| 7 | Error | nvarchar(max) | YES | - | CODE-BACKED | Error message or exception detail captured when a step fails. NULL for successful steps. Used for root-cause analysis of finalization failures. Stored on [HISTORY] filegroup TEXTIMAGE_ON. |
| 8 | Created | datetime | YES | - | CODE-BACKED | UTC datetime when this step was executed, set to GETUTCDATE() by the SP if not provided by the caller. The `@Created` parameter allows override for testing or reprocessing scenarios. |
| 9 | Comment | nvarchar(max) | YES | - | CODE-BACKED | Additional free-text context provided by the caller. Defaults to empty string in the SP. Stored on [HISTORY] filegroup TEXTIMAGE_ON. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositID | Billing.Deposit | Implicit | The deposit being finalized |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.AddDepositFinalizationLog | History.DepositFinalization | Writer | Sole writer - inserts one row per finalization step event |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.DepositFinalization (table)
- Leaf node - no code-level dependencies
- Written by History.AddDepositFinalizationLog (procedure)
- Related to Billing.Deposit (implicit via DepositID)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.AddDepositFinalizationLog | Stored Procedure | Writer - inserts finalization step log rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Fill Factor | Status |
|-----------|------|-------------|-----------------|--------|------------|--------|
| IX_DepositFinalization_DepositID | NONCLUSTERED | DepositID ASC | - | - | 95% | Active |

**Structure**: Heap table - no clustered index. Appropriate for append-only log workloads where insert speed is prioritized.
**Filegroup**: [HISTORY] for both table and large-value storage (TEXTIMAGE_ON [HISTORY]).
**No compression**: Unlike most History schema tables, DATA_COMPRESSION is not specified - default (no compression).
**Jira ticket**: PAYIL-2688 (noted in SP comment, created 2021-06-06 by Elrom).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none) | - | No PK, FK, UNIQUE, CHECK, or DEFAULT constraints other than StepRetries DEFAULT 0 |
| DF StepRetries | DEFAULT | StepRetries = 0 if not provided |

---

## 8. Sample Queries

### 8.1 All finalization steps for a specific deposit
```sql
SELECT FinalizationID, Step, StepStatus, StepRetries, Error, Created, Comment
FROM [History].[DepositFinalization] WITH (NOLOCK)
WHERE DepositID = 10793579
ORDER BY FinalizationID
```

### 8.2 Failed finalization steps (for investigation)
```sql
SELECT DepositID, Step, StepStatus, StepRetries, Error, Created
FROM [History].[DepositFinalization] WITH (NOLOCK)
WHERE StepStatus = 'Failed'
  AND Created >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY Created DESC
```

### 8.3 Steps with high retry counts (intermittent failures)
```sql
SELECT DepositID, Step, StepStatus, StepRetries, Error, Created
FROM [History].[DepositFinalization] WITH (NOLOCK)
WHERE StepRetries > 1
ORDER BY StepRetries DESC, Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.3/10 (Elements: 8.5/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Note: Table has 0 rows - business logic inferred from SP code and column semantics only*
*Object: History.DepositFinalization | Type: Table | Source: etoro/etoro/History/Tables/History.DepositFinalization.sql*
