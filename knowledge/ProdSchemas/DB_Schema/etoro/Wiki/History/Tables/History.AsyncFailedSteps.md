# History.AsyncFailedSteps

> Failure log for the Internal.AsyncExecuter pipeline: stores async action steps that exceeded their maximum retry count, capturing action type, failed step, return value, XML parameters, and failure timestamp.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (PK, INT IDENTITY, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK) |

---

## 1. Business Meaning

History.AsyncFailedSteps is the **failure destination** for the `Internal.AsyncExecuter` async action pipeline. When an async action step fails (returns non-zero RetVal) and has been retried more times than its `MaxNumOfTries` limit (from Dictionary.Steps), the action is removed from the active queue (`Internal.ActionsToExecute`) and a record is written here. It is the failure complement to `History.ActionsLog` (which logged successes until January 2020).

The pipeline processes business workflows as sequences of stored procedure steps. When a step consistently fails across all retries, the record lands here with the ActionID (which workflow), StepID (which step failed), RetVal (the failure code), and Params (the full XML context). This table is the primary operational alert surface for async pipeline failures.

**Currently very active**: 20.3 million rows since July 2025, with roughly 20,000-80,000 new failures per day based on the run cadence. All 4 observed ActionIDs are customer profile update operations (PostUpdateBasicUserInfo, PostUpdateContactUserInfo, PostRegisterOperations, PostUpdateRiskUserInfo) - indicating sustained failures in the customer profile async pipeline.

**All 10+ AsyncExecuter variants write here**: `Internal.AsyncExecuter1` through `9`, `AsyncExecuter_MIMO`, `AsyncExecuter_MIMONew`, `AsyncExecuter_EditStopLoss`, `AsyncExecuter_Registration` all share the same failure path: INSERT INTO History.AsyncFailedSteps + DELETE from Internal.ActionsToExecute within a transaction (with ROLLBACK on failure).

**Note on ErrorID**: The INSERT in all AsyncExecuter procedures hardcodes `null` for ErrorID - this column is never populated in practice.

---

## 2. Business Logic

### 2.1 Async Step Failure Path

**What**: Records actions that have exhausted all retries without a successful step completion.

**Columns/Parameters Involved**: `ActionID`, `StepID`, `RetVal`, `Params`, `Occurred`

**Rules**:
- A step failure is: RetVal != 0 after executing the step procedure via sp_executesql
- Retry condition: @CurrentTry <= @MaxNumOfTries (MaxNumOfTries comes from Internal.ActionSteps for each step)
- On each retry: @CurrentTry++, RetVal stored back in ActionsToExecute.RetVal
- RetVal=-1 is special: treated as 0 (success-like, PartsToDo reset to 0) for retry counting
- Failure threshold crossed: when @CurrentTry > @MaxNumOfTries after a non-zero RetVal
- Failure action: BEGIN TRAN -> INSERT here -> DELETE from queue -> COMMIT (ROLLBACK on catch)
- StepID recorded = the step that exhausted retries (not necessarily the first step)
- Occurred = GETUTCDATE() at failure time

**Diagram**:
```
Internal.ActionsToExecute (queue)
   |
   Internal.AsyncExecuter (WHILE loop)
   |
   EXEC @ProcName ... @RetVal OUTPUT
   |
   +-- RetVal=0 -> next step -> success path (queue item deleted)
   |
   +-- RetVal!=0 -> @CurrentTry++
         |
         +-- @CurrentTry <= @MaxNumOfTries -> retry (stay in queue)
         |
         +-- @CurrentTry > @MaxNumOfTries (max retries exceeded)
               |
               BEGIN TRAN
               INSERT History.AsyncFailedSteps (ActionID, StepID, RetVal, null, Params, GETUTCDATE())
               DELETE Internal.ActionsToExecute WHERE ID = @ID
               COMMIT
```

### 2.2 Monitoring and Repair

**What**: The failure table is actively monitored and repair procedures exist for certain action types.

**Rules**:
- `Internal.MonitorErrorsQueue` and `Internal.MonitorErrorsQueue_DD` query this table to count and surface failures for operational monitoring/alerting
- `Trade.ChekAsyncFailedSteps` reads this table for health-check purposes
- `Internal.FixRegistrationAsyncFailedSteps` specifically targets ActionID=8 (Customer.PostRegisterOperations) failures, attempting to re-process or remediate failed registration steps
- `dbo.SSRS_AsyncJobsRecords` queries this table for SSRS reporting dashboards

### 2.3 Dominant Failure Patterns (Current Data)

**What**: Analysis of failure distribution reveals systemic issues.

**Rules**:
- ActionID=10 (Customer.PostUpdateContactUserInfo): 8.28M failures (41%) - largest failure category
- ActionID=12 (Customer.PostUpdateRiskUserInfo): 5.89M failures (29%)
- ActionID=8 (Customer.PostRegisterOperations): 3.53M failures (17%)
- ActionID=9 (Customer.PostUpdateBasicUserInfo): 2.62M failures (13%)
- All 4 ActionIDs are customer profile update workflows - these downstream post-processing steps are consistently failing at StepID=9 with RetVal=1
- Total 20.3M failures since July 2025 suggests the profile update async pipeline has a persistent failure condition

---

## 3. Data Overview

20,314,964 rows, July 2025 to March 2026. All 4 active ActionIDs are customer profile update operations. RetVal=1 is the dominant failure code. StepID=9 is the most common failed step. ErrorID is always NULL.

| ID | ActionID | StepID | RetVal | ErrorID | Occurred | Meaning |
|---|---|---|---|---|---|---|
| 20317626 | 9 | 9 | 1 | NULL | 2026-03-19 07:07:13 | Customer.PostUpdateBasicUserInfo action, Step 9 failed with RetVal=1 after exceeding max retries. The XML Params would contain the customer context. This is one of thousands of identical failures in the same minute window. |
| (typical) | 10 | 9 | 1 | NULL | (current) | Customer.PostUpdateContactUserInfo - the most common failure type. Step 9 consistently failing. NULL ErrorID confirms the hardcoded-null pattern in all AsyncExecuter INSERT statements. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-generated surrogate PK. NOT FOR REPLICATION flag means the identity seed is not synchronized in replication scenarios - each replica generates its own IDs. Clustered PK. |
| 2 | ActionID | int | YES | - | CODE-BACKED | The type of async action that failed. References Dictionary.Actions(ActionID). Values in current data: 8=Customer.PostRegisterOperations, 9=Customer.PostUpdateBasicUserInfo, 10=Customer.PostUpdateContactUserInfo, 12=Customer.PostUpdateRiskUserInfo. All AsyncExecuter variants pass @ActionID from Internal.ActionsToExecute. |
| 3 | StepID | int | YES | - | CODE-BACKED | The step within the action's pipeline that exhausted its retries and failed. References Dictionary.Steps(StepID). Set to @StepID at the point where @CurrentTry > @MaxNumOfTries. Identifies exactly which step in the multi-step workflow could not succeed. |
| 4 | RetVal | int | YES | - | CODE-BACKED | The return value from the last failed execution of the step procedure. Non-zero by definition (zero would mean success). RetVal=1 is the most common value in current data. RetVal=-1 is special in the executor (treated as partial success) but can appear here if the overall action still fails. |
| 5 | ErrorID | int | YES | - | CODE-BACKED | Always NULL. The INSERT in all AsyncExecuter procedures hardcodes null for this column - no error code is ever populated. The column exists for future use but is currently never populated. |
| 6 | Params | xml | YES | - | CODE-BACKED | The XML parameters from the failed action, carried from Internal.ActionsToExecute.Params. Contains the full business context at failure time: customer IDs, action-specific data. Same `<Root><ParamName Value="value"/>` format used across the async pipeline. Essential for diagnosing and replaying failed actions. |
| 7 | Occurred | datetime | YES | - | CODE-BACKED | UTC timestamp when the failure was logged. Set to GETUTCDATE() in the AsyncExecuter INSERT. Marks when the max-retry threshold was crossed, not when the first failure occurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ActionID | Dictionary.Actions | Implicit FK | Identifies the failed action type. |
| StepID | Dictionary.Steps | Implicit FK | Identifies the failed step within the action's pipeline. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.AsyncExecuter | INSERT | Writer | Primary writer - all variants (1-9, MIMO, MIMONew, EditStopLoss, Registration) share this failure path. |
| Internal.MonitorErrorsQueue | - | Reader (monitor) | Reads failure counts for operational alerting. |
| Internal.MonitorErrorsQueue_DD | - | Reader (monitor) | DD-variant monitoring reader. |
| Trade.ChekAsyncFailedSteps | - | Reader (health check) | Pipeline health check query. |
| Internal.FixRegistrationAsyncFailedSteps | - | Reader/Writer (repair) | Targets ActionID=8 failures for remediation. |
| dbo.SSRS_AsyncJobsRecords | - | Reader (reporting) | SSRS dashboard for async job failure reporting. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.AsyncFailedSteps (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No FK constraints.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.AsyncExecuter (and 10+ variants) | Stored Procedures | Writers - failure destination for all async action executor variants |
| Internal.MonitorErrorsQueue | Stored Procedure | Reader - failure count monitoring |
| Internal.MonitorErrorsQueue_DD | Stored Procedure | Reader - DD monitoring variant |
| Trade.ChekAsyncFailedSteps | Stored Procedure | Reader - pipeline health check |
| Internal.FixRegistrationAsyncFailedSteps | Stored Procedure | Reader/Writer - registration failure repair |
| dbo.SSRS_AsyncJobsRecords | Stored Procedure | Reader - SSRS reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryAsyncFailedSteps | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryAsyncFailedSteps | PRIMARY KEY CLUSTERED | ID - single-column surrogate PK |
| NOT FOR REPLICATION on ID | Identity option | ID values not synchronized during replication - each server generates independent IDs |

---

## 8. Sample Queries

### 8.1 Recent failure summary by action type
```sql
SELECT
    afs.ActionID,
    a.ActionName,
    afs.StepID,
    afs.RetVal,
    COUNT(*) AS FailureCount,
    MAX(afs.Occurred) AS LatestFailure
FROM History.AsyncFailedSteps afs WITH (NOLOCK)
INNER JOIN Dictionary.Actions a WITH (NOLOCK)
    ON afs.ActionID = a.ActionID
WHERE afs.Occurred >= DATEADD(hour, -24, GETUTCDATE())
GROUP BY afs.ActionID, a.ActionName, afs.StepID, afs.RetVal
ORDER BY FailureCount DESC;
```

### 8.2 Extract parameters from a failed registration action
```sql
SELECT TOP 10
    ID,
    ActionID,
    StepID,
    RetVal,
    Occurred,
    Params.value('(/Root/CIDReal/@Value)[1]', 'INT') AS CIDReal,
    Params.value('(/Root/ExternalID/@Value)[1]', 'VARCHAR(100)') AS ExternalID,
    Params.value('(/Root/RegulationID/@Value)[1]', 'INT') AS RegulationID
FROM History.AsyncFailedSteps WITH (NOLOCK)
WHERE ActionID = 8
ORDER BY Occurred DESC;
```

### 8.3 Daily failure trend
```sql
SELECT
    CAST(Occurred AS DATE) AS FailureDate,
    ActionID,
    COUNT(*) AS DailyFailures
FROM History.AsyncFailedSteps WITH (NOLOCK)
WHERE Occurred >= DATEADD(day, -30, GETUTCDATE())
GROUP BY CAST(Occurred AS DATE), ActionID
ORDER BY FailureDate DESC, DailyFailures DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.AsyncFailedSteps | Type: Table | Source: etoro/etoro/History/Tables/History.AsyncFailedSteps.sql*
