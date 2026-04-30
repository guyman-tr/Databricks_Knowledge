# History.ActionsLog

> Legacy audit log of completed async action executions (2014-2020), capturing action type, XML parameters, execution timing, retry count, and return value for the Internal.AsyncExecuter pipeline.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite PK: ExecutedActionID + ActionID (CLUSTERED, PAGE compressed) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK, PAGE compressed, FILLFACTOR 95) |

---

## 1. Business Meaning

History.ActionsLog is a legacy audit table for the `Internal.AsyncExecuter` async action pipeline. The pipeline processes queued business actions (position opens, position closes, customer registrations, login events, mirror detachments) by executing multi-step stored procedures defined in `Dictionary.Steps` and `Internal.ActionSteps`. When an action completed all its steps successfully, a record was inserted here with the full execution timeline.

**This table stopped receiving new data in January 2020.** The INSERT statement in `Internal.AsyncExecuter` was commented out in a January 2021 refactoring (visible as commented code at lines 116-119 of the procedure). The 1,226 existing records (from June 2014 to January 2020) are the historical archive of the pipeline's completed executions from that era. The table is preserved for historical audit purposes.

The async pipeline it logged worked as follows: `Internal.ActionsToExecute` held the queue; AsyncExecuter polled and executed each action's steps in sequence (with retry logic up to `MaxNumOfTries`); on success, a record was to be INSERTed here; on step failure after max retries, a record was written to `History.AsyncFailedSteps` and the item deleted from the queue. The INSERT to History.ActionsLog was the final step on full success.

---

## 2. Business Logic

### 2.1 Async Action Execution Pipeline

**What**: The async execution pipeline processes multi-step business workflows with retry logic, logging results here on complete success.

**Columns/Parameters Involved**: `ActionID`, `NumOfTries`, `RetVal`, `InsertedToQueue`, `StartedExecuting`, `FinishedExecuting`

**Rules**:
- Actions are picked from Internal.ActionsToExecute in ID order (lowest first)
- Each action has one or more steps from Dictionary.Steps, linked by Internal.ActionSteps (with success and failure chain)
- RetVal=0 = success for each step; non-zero = failure, triggers retry or failure path
- NumOfTries records how many attempts were made before success (typically 1)
- If max tries exceeded: row goes to History.AsyncFailedSteps instead of here
- On full success: INSERT here, DELETE from Internal.ActionsToExecute

**Diagram**:
```
Internal.ActionsToExecute (queue)
         |
         v
Internal.AsyncExecuter (WHILE loop, MIN ID first)
         |
         +-> Step 1: EXEC @ProcName ... @RetVal OUTPUT
         |        RetVal=0 -> next step
         |        RetVal!=0 -> retry OR History.AsyncFailedSteps
         +-> Step N: last step
         |        StepID=0 -> all steps done
         |
         +-> History.ActionsLog INSERT (commented out Jan 2021)
         +-> DELETE from Internal.ActionsToExecute
```

### 2.2 XML Parameter Payload

**What**: The Params column stores the full input context for the action as XML, with one child element per parameter.

**Columns/Parameters Involved**: `Params`

**Rules**:
- Format: `<Root><ParamName Value="value"/><ParamName2 Value="value2"/>...</Root>`
- For ActionID=8 (Customer.PostRegisterOperations): params include ExternalID, CreditTypeID, CIDReal, CIDDemo, Credit, RealProviderID, ChangePasswordDemo, ActionType, LoginID, GameType, SendEmail, AccountTypeID, ChangePassword, RegulationID, RiskStatusID, AffiliateStatusID, WasOrigCIDZero
- Params are passed as XML to each step procedure via `sp_executesql`
- NULL if the action had no parameters

---

## 3. Data Overview

1,226 records from June 2014 to January 2020. All records appear to be ActionID=8 (Customer.PostRegisterOperations) in the most recent data, though 5 distinct action types were used across the full history.

| ExecutedActionID | ActionID | InsertedToQueue | FinishedExecuting | NumOfTries | RetVal | Meaning |
|---|---|---|---|---|---|---|
| 2162 | 8 | 2020-01-05 13:17:59 | 2020-01-05 13:18:02 | 1 | 0 | Customer post-registration: CIDReal=3835265 paired with CIDDemo=3755149. Credit=10000000 (virtual demo credit). ~3 seconds to complete all registration steps. The last record ever inserted. |
| 2160 | 8 | 2020-01-05 06:28:31 | 2020-01-05 06:28:35 | 1 | 0 | Same action type with RegulationID=7 (different from the ID=1 standard). Indicates this customer had non-standard regulatory classification applied during registration. |
| 1163 | 8 | 2020-01-02 12:52:41 | 2020-01-02 12:52:42 | 1 | 0 | Earlier registration with RegulationID=0. Fast execution (~1 second). NumOfTries=1 confirms first-attempt success throughout this dataset. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExecutedActionID | int | NO | - | CODE-BACKED | The ID of the action from Internal.ActionsToExecute (the queue table's ID column) at the time of execution. Part of the composite PK. Maps to Internal.ActionsToExecute.ID before deletion. Uniquely identifies this specific execution instance. |
| 2 | ActionID | int | NO | - | VERIFIED | FK to Dictionary.Actions(ActionID). The type of action executed. Observed values: 1=PositionClose, 2=PositionOpen, 3=LogIn, 4=EditStopLoss, 5=PositionFail, 6=DetachMirrorPosition, 7=MIMO Operations, 8=Customer.PostRegisterOperations, 9=Customer.PostUpdateBasicUserInfo, 10=Customer.PostUpdateContactUserInfo, 11=AsyncOrdersChangeLog, 12=Customer.PostUpdateRiskUserInfo. All records in current data are ActionID=8. |
| 3 | Params | xml | YES | - | CODE-BACKED | XML payload passed to each step procedure. Format: `<Root><ParamName Value="value"/>...</Root>`. For ActionID=8 contains: ExternalID (correlation GUID), CIDReal, CIDDemo, Credit (demo virtual balance), CreditTypeID, RegulationID, RiskStatusID, AccountTypeID, SendEmail, and other registration context. NULL if the action has no parameters. |
| 4 | InsertedToQueue | datetime | NO | - | CODE-BACKED | When the action was added to Internal.ActionsToExecute. Sourced from Internal.ActionsToExecute.InsertedToQueue at archive time. Marks the start of the queue latency measurement. |
| 5 | StartedExecuting | datetime | NO | - | CODE-BACKED | When AsyncExecuter picked up this action and began processing (captured as @StartTime = GETUTCDATE() at the start of each loop iteration). StartedExecuting - InsertedToQueue = queue wait time. |
| 6 | FinishedExecuting | datetime | NO | getutcdate() | CODE-BACKED | When all steps completed and the INSERT was made. Set to GETUTCDATE() at completion by the INSERT statement. FinishedExecuting - StartedExecuting = total execution time. Default constraint provides fallback. |
| 7 | NumOfTries | tinyint | YES | - | CODE-BACKED | Number of attempts made before all steps succeeded. Sourced from @CurrentTry counter in AsyncExecuter. Typically 1 (all records in data have NumOfTries=1). Values > 1 indicate transient failures that required retry. Max = MaxNumOfTries from Dictionary.Steps; if exceeded the action goes to History.AsyncFailedSteps instead. |
| 8 | RetVal | int | YES | - | CODE-BACKED | Return value from the final step execution. 0 = complete success. Non-zero = partial state from the last step (rare in this table since non-zero outcomes typically prevent reaching this INSERT). Sourced from Internal.ActionsToExecute.RetVal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ActionID | Dictionary.Actions | FK (FK_HistoryActionsLog_DictionaryActions) | Classifies the type of async action that was executed. 12 action types defined. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.AsyncExecuter | - | Writer (LEGACY - commented out Jan 2021) | Used to INSERT completed actions here; INSERT statement now commented out. Multiple variant procedures (AsyncExecuter1-4, MIMO, Registration variants) had the same pattern. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ActionsLog (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Actions | Table | FK target - ActionID must exist |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.AsyncExecuter | Stored Procedure | Legacy writer (INSERT commented out Jan 2021) - still references table in commented code |
| Internal.AsyncExecuter1-4 | Stored Procedures | Legacy writer variants - same commented-out pattern |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryActionsLog | CLUSTERED PK (PAGE compressed) | ExecutedActionID ASC, ActionID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryActionsLog | PRIMARY KEY CLUSTERED | ExecutedActionID + ActionID - ensures uniqueness per queue item per action type |
| DF_HistoryActionsLog_FinishedExecuting | DEFAULT | FinishedExecuting = GETUTCDATE() at INSERT time |
| FK_HistoryActionsLog_DictionaryActions | FOREIGN KEY | ActionID -> Dictionary.Actions(ActionID) |

---

## 8. Sample Queries

### 8.1 Review execution history for a specific action type
```sql
SELECT
    ExecutedActionID,
    ActionID,
    a.ActionName,
    al.InsertedToQueue,
    al.StartedExecuting,
    al.FinishedExecuting,
    DATEDIFF(millisecond, al.StartedExecuting, al.FinishedExecuting) AS ExecMs,
    al.NumOfTries,
    al.RetVal
FROM History.ActionsLog al WITH (NOLOCK)
INNER JOIN Dictionary.Actions a WITH (NOLOCK)
    ON al.ActionID = a.ActionID
WHERE al.ActionID = 8
ORDER BY al.FinishedExecuting DESC;
```

### 8.2 Extract registration parameters from XML payload
```sql
SELECT
    ExecutedActionID,
    FinishedExecuting,
    Params.value('(/Root/CIDReal/@Value)[1]', 'INT')        AS CIDReal,
    Params.value('(/Root/CIDDemo/@Value)[1]', 'INT')        AS CIDDemo,
    Params.value('(/Root/Credit/@Value)[1]', 'BIGINT')      AS DemoCredit,
    Params.value('(/Root/RegulationID/@Value)[1]', 'INT')   AS RegulationID,
    Params.value('(/Root/AccountTypeID/@Value)[1]', 'INT')  AS AccountTypeID
FROM History.ActionsLog WITH (NOLOCK)
WHERE ActionID = 8
  AND FinishedExecuting >= '2019-01-01'
ORDER BY FinishedExecuting DESC;
```

### 8.3 Execution performance statistics by action type
```sql
SELECT
    a.ActionName,
    COUNT(*)                                                         AS TotalExecutions,
    AVG(DATEDIFF(ms, al.StartedExecuting, al.FinishedExecuting))    AS AvgExecMs,
    MAX(DATEDIFF(ms, al.StartedExecuting, al.FinishedExecuting))    AS MaxExecMs,
    AVG(CAST(al.NumOfTries AS FLOAT))                               AS AvgTries,
    MAX(al.NumOfTries)                                              AS MaxTries
FROM History.ActionsLog al WITH (NOLOCK)
INNER JOIN Dictionary.Actions a WITH (NOLOCK)
    ON al.ActionID = a.ActionID
GROUP BY a.ActionName
ORDER BY TotalExecutions DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ActionsLog | Type: Table | Source: etoro/etoro/History/Tables/History.ActionsLog.sql*
