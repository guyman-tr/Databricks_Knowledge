# Billing.RecurringDeposit

> Execution log for scheduled/recurring credit card deposit attempts, tracking each execution from initial registration through deposit creation and optional 3DS authentication retry.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | RecurringDepositID (INT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 3 (PK + 2 NCI) |

---

## 1. Business Meaning

Billing.RecurringDeposit tracks each individual execution of a recurring (scheduled) deposit. When a customer sets up automatic recurring payments, a scheduler service fires execution jobs at configured intervals. Each execution is registered in this table with a unique ExecutionID and ExecutionKey before the deposit is processed - the table acts as an idempotency guard and status tracker for the recurring deposit pipeline.

The table exists to link recurring execution jobs to their resulting deposits in Billing.Deposit. Without this table, the system would have no way to correlate which scheduled execution produced which deposit, making retry logic, failure diagnostics, and 3DS re-authentication impossible. It also tracks the Generation (attempt count) to distinguish initial attempts from retries.

Data lifecycle: A row is created by `RegisterRecurringExecution` (idempotent MERGE) when a scheduled job fires. Once the payment processor responds and a deposit record is created, `SetDepositIdToRecurringDeposit` updates the row with DepositID, 3DS data, and Generation. The row then serves as a permanent audit trail of that execution. The trigger `TR_RecurringDeposit_ModificationDate` ensures `ModificationDate` is always stamped on any change.

---

## 2. Business Logic

### 2.1 Idempotent Registration Pattern

**What**: Recurring executions are registered idempotently - the same execution can be safely submitted multiple times without creating duplicates.

**Columns/Parameters Involved**: `ExecutionID`, `ExecutionKey`, `RecurringDepositID`, `CreateDate`

**Rules**:
- `RegisterRecurringExecution` uses a MERGE statement: INSERT only when (ExecutionID, ExecutionKey) has no existing match
- The composite (ExecutionID, ExecutionKey) pair is the uniqueness key - indexed via IX_RecurringDeposit_1
- If the execution was already registered (e.g., retry call), the procedure returns the existing row without modification
- CreateDate is set once at INSERT time (GETUTCDATE()) and never changed

**Diagram**:
```
Scheduler fires execution job
        |
        v
RegisterRecurringExecution(@ExecutionId, @ExecutionKey)
        |
        v
MERGE INTO RecurringDeposit
  ON ExecutionID = @ExecutionId AND ExecutionKey = @ExecutionKey
  NOT MATCHED -> INSERT (creates new row)
  MATCHED     -> (no-op - already registered)
        |
        v
Returns existing/new RecurringDepositID for downstream use
```

### 2.2 Deposit Linkage and 3DS Generation Tracking

**What**: After a deposit is attempted, the recurring row is updated with the deposit result, 3DS authentication data, and generation (attempt count).

**Columns/Parameters Involved**: `DepositID`, `AuthId`, `3dsDate`, `Generation`

**Rules**:
- `SetDepositIdToRecurringDeposit` (PAYUS-2979, updated PAYIL-10393 Nov 2025) performs the UPDATE
- Generation=0 for the initial deposit attempt; Generation=1 for a 3DS retry (maximum observed in data = 1)
- AuthId is the 3DS authentication identifier - only populated when 3DS challenge was required (~2.7% of executions in current data)
- 3dsDate records when the 3DS authentication event occurred
- DepositID becomes non-NULL once the deposit is successfully created; ~97% of executions result in a deposit

**Diagram**:
```
Initial attempt:   Generation=0, AuthId=NULL, 3dsDate=NULL
                   -> DepositID set when deposit created

3DS required:      Generation=0 initially
                   -> 3DS challenge issued
                   -> AuthId + 3dsDate set when auth completes
                   -> Generation=1 on the retry execution
```

---

## 3. Data Overview

| RecurringDepositID | ExecutionID | ExecutionKey | DepositID | Generation | Meaning |
|--------------------|------------|--------------|-----------|------------|---------|
| 79193 | 2327131 | 093B734E-... | 10780832 | 0 | A recurring deposit executed at 17:37 on 2026-03-17, successfully linked to deposit 10780832. Standard execution with no 3DS. |
| 79192 | 2327121 | D23F2F05-... | 10780821 | 0 | Previous execution 1 minute earlier, linked to its deposit. Normal cadence shows one execution per minute in high-volume periods. |
| 79186 | 2444981 | 62364812-... | 10780444 | 0 | ExecutionID 2444981 is higher than the surrounding IDs, suggesting a different scheduler or execution series running in parallel. |
| 79185 | 2326931 | 96A096BD-... | 10780284 | 0 | Typical execution with ~12-minute gap from previous - recurring schedules are not all at the same interval. |
| (low ID) | - | - | NULL | - | Rows with NULL DepositID (~2,336 rows) represent executions where deposit creation failed or is still in progress. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RecurringDepositID | INT | NO | IDENTITY(79488,1) | CODE-BACKED | Surrogate primary key, auto-incremented. Starting IDENTITY seed 79488 is higher than current max row ID (79193), indicating historical rows were deleted. Used as the foreign reference key in `SetDepositIdToRecurringDeposit`. |
| 2 | ExecutionID | INT | NO | - | CODE-BACKED | Identifier of the recurring execution job from the scheduling system. Not an FK in DDL - references an external scheduler entity. Indexed (IX_RecurringDeposit_1) with ExecutionKey. Used as JOIN key in `GetDepositsForExecutions` to link executions to deposits. |
| 3 | ExecutionKey | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | GUID providing idempotency for execution registration. Combined with ExecutionID as the uniqueness guard in the MERGE statement of `RegisterRecurringExecution`. Prevents duplicate rows if the registration call is retried. |
| 4 | DepositID | INT | YES | - | CODE-BACKED | FK (no DDL constraint) to Billing.Deposit(DepositID). NULL until `SetDepositIdToRecurringDeposit` is called after the deposit is created. Indexed (IX_RecurringDeposit_DepositID). ~97% of rows are populated (successful deposit creation). Null rows = in-progress or failed executions. |
| 5 | CreateDate | DATETIME | NO | - | CODE-BACKED | UTC timestamp when the execution was registered (set to GETUTCDATE() on INSERT via `RegisterRecurringExecution`). Never modified after insert. |
| 6 | ModificationDate | DATETIME | YES | - | CODE-BACKED | UTC timestamp of the last modification. Automatically maintained by trigger `TR_RecurringDeposit_ModificationDate` (fires on INSERT and UPDATE). NULL only briefly after INSERT before trigger fires. Shows the time DepositID/AuthId/Generation were last set. |
| 7 | AuthId | INT | YES | - | CODE-BACKED | 3D Secure authentication identifier. Populated by `SetDepositIdToRecurringDeposit` via @AuthenticationID parameter. NULL for the ~97% of recurring deposits that do not require 3DS challenge. When non-NULL, identifies the specific 3DS auth event. |
| 8 | 3dsDate | DATETIME | YES | - | CODE-BACKED | UTC timestamp of the 3DS authentication event. Populated alongside AuthId. NULL when no 3DS was required. Only ~1.3% of rows have this populated (1,025 of 78,158). |
| 9 | Generation | INT | NO | 0 | CODE-BACKED | Attempt counter for the recurring execution cycle. 0 = initial deposit attempt, 1 = 3DS retry. Default = 0. Added via PAYIL-10393 (Nov 2025). In `GetDepositsForExecutions` this column is referenced as `RetryNumber` - the procedure appears to have a stale column reference that may need updating. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositID | Billing.Deposit | Implicit FK (no DDL constraint) | Links the recurring execution to its resulting deposit. Set by SetDepositIdToRecurringDeposit after deposit creation. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.RegisterRecurringExecution | ExecutionID, ExecutionKey | WRITER (MERGE INSERT) | Creates the initial row for each execution |
| Billing.SetDepositIdToRecurringDeposit | RecurringDepositID | MODIFIER (UPDATE) | Sets DepositID, AuthId, 3dsDate, Generation after deposit is created |
| Billing.GetRecurringThreeDsDateByDepositIds | DepositID | READER | Returns RecurringDepositID and 3dsDate for a batch of DepositIDs (CSV input) |
| Billing.GetDepositsForExecutions | ExecutionID | READER | JOINs by ExecutionID to link execution IDs to their deposits and statuses. NOTE: references `RetryNumber` column that does not exist in DDL - likely a stale reference to what is now `Generation`. |
| Billing.vDeposit | - | View dependency | Billing.vDeposit view references this table |
| Monitor.GetRecurringDepositsDashboard | - | READER | Monitoring/dashboard procedure for recurring deposit oversight |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RecurringDeposit (table)
└── (no code-level dependencies - leaf table)
```

### 6.1 Objects This Depends On

No dependencies. No FK constraints in DDL. DepositID references Billing.Deposit implicitly.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.RegisterRecurringExecution | Stored Procedure | WRITER - idempotent MERGE INSERT |
| Billing.SetDepositIdToRecurringDeposit | Stored Procedure | MODIFIER - links deposit and 3DS data |
| Billing.GetRecurringThreeDsDateByDepositIds | Stored Procedure | READER - 3DS date lookup by DepositID batch |
| Billing.GetDepositsForExecutions | Stored Procedure | READER - execution-to-deposit bridge |
| Billing.vDeposit | View | References table |
| Monitor.GetRecurringDepositsDashboard | Stored Procedure | READER - monitoring dashboard |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RecurringDeposit | CLUSTERED PK | RecurringDepositID ASC | - | - | Active |
| IX_RecurringDeposit_1 | NONCLUSTERED | ExecutionID ASC, ExecutionKey ASC | - | - | Active |
| IX_RecurringDeposit_DepositID | NONCLUSTERED | DepositID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RecurringDeposit | PRIMARY KEY CLUSTERED | RecurringDepositID unique |
| DF on Generation | DEFAULT | Generation defaults to 0 (initial attempt) |
| TR_RecurringDeposit_ModificationDate | TRIGGER (AFTER INSERT, UPDATE) | Automatically sets ModificationDate = GETUTCDATE() on every insert or update |

---

## 8. Sample Queries

### 8.1 Get all executions with their deposit outcomes for a date range

```sql
SELECT
    rd.RecurringDepositID,
    rd.ExecutionID,
    rd.ExecutionKey,
    rd.DepositID,
    rd.Generation,
    rd.AuthId,
    rd.[3dsDate],
    rd.CreateDate,
    rd.ModificationDate,
    CASE WHEN rd.DepositID IS NULL THEN 'Pending/Failed' ELSE 'Linked' END AS Status
FROM [Billing].[RecurringDeposit] rd WITH (NOLOCK)
WHERE rd.CreateDate >= DATEADD(day, -7, GETUTCDATE())
ORDER BY rd.CreateDate DESC
```

### 8.2 Find executions that required 3DS authentication

```sql
SELECT
    rd.RecurringDepositID,
    rd.ExecutionID,
    rd.DepositID,
    rd.AuthId,
    rd.[3dsDate],
    rd.Generation
FROM [Billing].[RecurringDeposit] rd WITH (NOLOCK)
WHERE rd.AuthId IS NOT NULL
ORDER BY rd.[3dsDate] DESC
```

### 8.3 Check execution success rate for current month

```sql
SELECT
    COUNT(*) AS TotalExecutions,
    COUNT(DepositID) AS LinkedToDeposit,
    COUNT(*) - COUNT(DepositID) AS PendingOrFailed,
    CAST(COUNT(DepositID) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS SuccessRate,
    COUNT(AuthId) AS RequiredThreeDs,
    MAX(Generation) AS MaxGeneration
FROM [Billing].[RecurringDeposit] WITH (NOLOCK)
WHERE CreateDate >= DATEADD(month, DATEDIFF(month, 0, GETUTCDATE()), 0)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PayPal - Recurring - Steps](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/4490396469) | Confluence | Describes PayPal billing agreement recurring deposit implementation context - confirms recurring deposits use a billing agreement ID pattern (MEDIUM confidence - PayPal-specific, general context) |

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.6/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.RecurringDeposit | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.RecurringDeposit.sql*
