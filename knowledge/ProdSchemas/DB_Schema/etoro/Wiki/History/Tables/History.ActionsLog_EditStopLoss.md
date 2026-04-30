# History.ActionsLog_EditStopLoss

> Legacy audit log (2014-2017) of async actions processed through the dedicated EditStopLoss execution queue, capturing position-close attempts triggered by stop-loss and take-profit rate limits.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ExecutedActionID (PK, INT, CLUSTERED, PAGE compressed) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK, PAGE compressed) |

---

## 1. Business Meaning

History.ActionsLog_EditStopLoss is a legacy audit table for a specialized variant of the `Internal.AsyncExecuter` pipeline. The EditStopLoss queue (`Internal.ActionsToExecute_EditStopLoss`) processed actions routed to it when a position's stop-loss or take-profit limit was triggered, requiring a separate high-priority execution path. When an action completed, a record was to be inserted here — but like the main History.ActionsLog, the INSERT statement was commented out (visible at lines 103-106 of `Internal.AsyncExecuter_EditStopLoss`).

**This table stopped receiving new data in May 2017.** Despite being named "EditStopLoss", the 395 existing records (June 2014 to May 2017) are predominantly ActionID=5 (PositionFail) records — these are position-close attempts triggered by stop-rate or limit-rate hits that encountered a database error ("Position does not exist"). The table captures the position context at the moment of the failed close: the position's instrument, leverage, rates, CID, and the specific failure reason.

The relationship to `History.ActionsLog` (parent pattern): both share the same executor architecture and represent different execution queues of the same async pipeline. This table specialized in stop-loss-triggered actions. The `Internal.AsyncExecuter_EditStopLoss` procedure is a direct copy of `Internal.AsyncExecuter` but reads from `Internal.ActionsToExecute_EditStopLoss` instead.

---

## 2. Business Logic

### 2.1 Stop-Loss and Limit-Rate Close Failure Logging

**What**: Records capture position-close attempts triggered by stop-loss/take-profit rates that failed at the DB layer.

**Columns/Parameters Involved**: `ActionID`, `Params`

**Rules**:
- ActionID=5 (PositionFail): the close was attempted when StopRate or LimitRate was hit, but the DB returned an error
- Common FailReason in data: "Error closing position limit - DB failure! Details: Cannot close position XXXXX. Position does not exist."
- This failure means the position was already closed (or never existed) when the stop-loss trigger fired - a race condition in the trading engine
- ClosePositionActionTypeID in the XML identifies how the close was initiated: 1=System close (stop-loss/limit), 5=end-of-week close
- Retries were attempted up to MaxNumOfTries; if all failed, records went to History.AsyncFailedSteps instead

### 2.2 Position XML Payload Structure

**What**: The Params XML for PositionFail (ActionID=5) records contains the full position snapshot at close time.

**Columns/Parameters Involved**: `Params`

**Rules**:
- Full position context: PositionID, CID, InstrumentID, Leverage, Amount, AmountInUnitsDecimal, IsBuy
- Rate context: InitForexRate, EndForexRate, StopRate, LimitRate, LastOpPriceRate, ConversionRate (with corresponding PriceRateIDs)
- Financial context: NetProfit, Commission, CommissionOnClose, SpreadedCommission, UnitMargin
- Timing context: InitDateTime (open time), EndDateTime (requested close time), RequestOpenOccurred, RequestCloseOccurred
- FailReason: the specific error message from the failed close operation

---

## 3. Data Overview

395 records from June 2014 to May 2017. All recent records are ActionID=5 (PositionFail). The FailReason consistently indicates "Position does not exist" race conditions.

| ExecutedActionID | ActionID | FinishedExecuting | PositionID (from XML) | FailReason (from XML) | Meaning |
|---|---|---|---|---|---|
| 121077943 | 5 | 2017-05-21 12:09:13 | 119771068 | Position does not exist | Stop-rate hit on a short gold position (InstrumentID=1001, IsBuy=0). By the time the async close ran, the position was already gone - likely closed by another path simultaneously. Classic race condition. |
| 121077942 | 5 | 2017-05-21 12:09:12 | 119771068 | Position does not exist | Same position, attempted twice within 1 second - both failed. Two close requests were queued for the same PositionID. |
| 121077941 | 5 | 2017-05-21 12:09:12 | 119771706 | Position does not exist | Different position (InstrumentID=33), same batch time. All three were part of the same stop-rate sweep at 12:09 - a market event triggered multiple simultaneous close attempts. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExecutedActionID | int | NO | - | CODE-BACKED | The ID from Internal.ActionsToExecute_EditStopLoss at execution time. Single-column PK (unlike History.ActionsLog which has a composite PK). Uniquely identifies each queue item execution. |
| 2 | ActionID | int | NO | - | VERIFIED | FK to Dictionary.Actions(ActionID). Despite the table name suggesting ActionID=4 (EditStopLoss), the data contains ActionID=5 (PositionFail) - position-close failures triggered by stop-loss/limit-rate hits. Presumably also could hold ActionID=4 (EditStopLoss) records from earlier in the history. |
| 3 | Params | xml | YES | - | CODE-BACKED | XML payload with full position context at close time. For ActionID=5 (PositionFail): includes PositionID, CID, InstrumentID, Leverage, Amount, rates (Init/End/Stop/Limit/LastOp), NetProfit, Commission, FailReason, ClosePositionActionTypeID. Same `<Root><ParamName Value="value"/>` format as History.ActionsLog. |
| 4 | InsertedToQueue | datetime | NO | - | CODE-BACKED | When the action was added to Internal.ActionsToExecute_EditStopLoss - the moment the stop-loss or limit trigger was detected and queued for async processing. |
| 5 | StartedExecuting | datetime | NO | - | CODE-BACKED | When Internal.AsyncExecuter_EditStopLoss picked this action from the queue (captured as @StartTime). Execution was nearly immediate in observed data (< 1 second lag from InsertedToQueue). |
| 6 | FinishedExecuting | datetime | NO | getutcdate() | CODE-BACKED | When all steps completed. Set to GETUTCDATE() at INSERT time. Note: the INSERT is commented out in the current procedure - this field exists for completeness but was populated only during 2014-2017 when the INSERT was active. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ActionID | Dictionary.Actions | FK (FK_HistoryActionsLog_EditStopLoss_DictionaryActions) | Classifies the async action type. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Internal.AsyncExecuter_EditStopLoss | - | Writer (LEGACY - commented out) | Specialized executor for the EditStopLoss queue. INSERT commented out, last populated May 2017. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ActionsLog_EditStopLoss (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Actions | Table | FK target - ActionID must exist |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Internal.AsyncExecuter_EditStopLoss | Stored Procedure | Legacy writer (INSERT commented out) - processes Internal.ActionsToExecute_EditStopLoss queue |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryActionsLog_EditStopLoss | CLUSTERED PK (PAGE compressed) | ExecutedActionID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryActionsLog_EditStopLoss | PRIMARY KEY | ExecutedActionID - single-column PK (unlike ActionsLog's composite PK) |
| DF_HistoryActionsLog_EditStopLoss_FinishedExecuting | DEFAULT | FinishedExecuting = GETUTCDATE() |
| FK_HistoryActionsLog_EditStopLoss_DictionaryActions | FOREIGN KEY | ActionID -> Dictionary.Actions(ActionID) |

---

## 8. Sample Queries

### 8.1 Extract failed position close details from XML params
```sql
SELECT
    ExecutedActionID,
    FinishedExecuting,
    Params.value('(/Root/PositionID/@Value)[1]',   'BIGINT')    AS PositionID,
    Params.value('(/Root/CID/@Value)[1]',           'INT')       AS CID,
    Params.value('(/Root/InstrumentID/@Value)[1]',  'INT')       AS InstrumentID,
    Params.value('(/Root/StopRate/@Value)[1]',      'FLOAT')     AS StopRate,
    Params.value('(/Root/EndForexRate/@Value)[1]',  'FLOAT')     AS TriggerRate,
    Params.value('(/Root/FailReason/@Value)[1]',    'VARCHAR(500)') AS FailReason,
    Params.value('(/Root/NetProfit/@Value)[1]',     'DECIMAL(14,4)') AS NetProfit
FROM History.ActionsLog_EditStopLoss WITH (NOLOCK)
WHERE ActionID = 5
ORDER BY FinishedExecuting DESC;
```

### 8.2 Count of failed stop-loss closes by instrument
```sql
SELECT
    Params.value('(/Root/InstrumentID/@Value)[1]', 'INT') AS InstrumentID,
    COUNT(*) AS FailCount
FROM History.ActionsLog_EditStopLoss WITH (NOLOCK)
WHERE ActionID = 5
  AND Params IS NOT NULL
GROUP BY Params.value('(/Root/InstrumentID/@Value)[1]', 'INT')
ORDER BY FailCount DESC;
```

### 8.3 Look up all queue items for a specific position
```sql
SELECT
    al.ExecutedActionID,
    a.ActionName,
    al.InsertedToQueue,
    al.StartedExecuting,
    al.FinishedExecuting,
    al.Params.value('(/Root/FailReason/@Value)[1]', 'VARCHAR(500)') AS FailReason
FROM History.ActionsLog_EditStopLoss al WITH (NOLOCK)
INNER JOIN Dictionary.Actions a WITH (NOLOCK)
    ON al.ActionID = a.ActionID
WHERE al.Params.value('(/Root/PositionID/@Value)[1]', 'BIGINT') = 119771068
ORDER BY al.InsertedToQueue;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ActionsLog_EditStopLoss | Type: Table | Source: etoro/etoro/History/Tables/History.ActionsLog_EditStopLoss.sql*
