# Apex.State

> Core state machine table tracking the current workflow step for each customer's Apex account processing, including account creation, updates, closures, and identity investigations.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Apex.State is the central state machine record that tracks exactly where each customer stands in the Apex account processing workflow. Each customer has one row, containing the current ApexStateID (which of the 47 possible workflow states they are in) and an optional Comment with context about the current state (error messages, investigation details, etc.).

This table is the heart of the Apex integration engine. The state machine drives all account operations: creation flows (states 1-10), update flows (states 11-19), Sketch identity investigation flows (states 20-35), affiliated approval (states 36-37), restriction (states 38-39), and account closure (states 41-45). Without it, the system cannot determine what action to take next for any customer.

Data is written by Apex.SaveState, which atomically updates three tables in a transaction: State (this table), StateProcessingData (scheduling/retry metadata), and UserValidationErrors (current validation errors). The MERGE pattern creates or updates records. GetState retrieves the state with processing data via JOIN. GetWorkStates is the critical batch processor that fetches customers ready for the next state transition, using exponential backoff on error counts. System versioning (History.State) provides full state transition history.

---

## 2. Business Logic

### 2.1 Atomic Three-Table State Transition

**What**: Every state change atomically updates State, StateProcessingData, and UserValidationErrors in a single transaction.

**Columns/Parameters Involved**: `GCID`, `ApexStateID`, `Comment` (State) + StateProcessingData columns + ValidationErrors TVP

**Rules**:
- SaveState wraps all three MERGEs in BEGIN TRAN / COMMIT TRAN with XACT_ABORT ON
- State is updated only when ApexStateID or Comment actually changes (change detection in MERGE)
- StateProcessingData is updated only when scheduling/retry fields change
- UserValidationErrors are replaced entirely: DELETE all for GCID, then INSERT from @ValidationErrors TVP
- Comment is truncated to 4000 characters (substring(@Comment,0,4000))
- Failure in any of the three updates rolls back all three (XACT_ABORT)

### 2.2 State Machine Workflow Groups

**What**: The 47 states organize into distinct workflow groups, each handling a different account lifecycle operation.

**Columns/Parameters Involved**: `ApexStateID`

**Rules**:
- States 1-10: Account CREATION (collect data -> send to Apex -> poll result -> handle rejection/appeal)
- States 11-19: Account UPDATE (collect changes -> send update -> poll result -> handle rejection)
- States 20-35: Sketch CIP INVESTIGATION (check identity -> handle indeterminate/reject -> appeal)
- States 36-37: AFFILIATED approval (broker-dealer affiliated persons)
- States 38-39: Account RESTRICTION
- States 40: Post-update notification
- States 41-45: Account CLOSURE
- States 46-47: Special approvals (visa, manual appeal)
- See [State (Apex State)](_glossary.md#state-apex-state) for full value definitions

---

## 3. Data Overview

| GCID | ApexStateID | Comment | Meaning |
|------|------------|---------|---------|
| 20708 | 5 (WaitForFailingUserDataUpdate...) | Error = RequestValidation; Code = ERR002... | Customer stuck in error state after failed create request. Comment contains the API error details for debugging. |
| 60520 | 10 (InitiateAutoAppeal) | Reasons: Investigation Status: Indeterminate... | Customer's account creation was rejected, system is attempting auto-appeal. Comment records the investigation findings. |
| 75188 | 7 (NotifyTradingCompleted) | NULL | Happy path - account creation completed, trading platform being notified. No comment needed for success states. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | VERIFIED | Global Customer ID. Primary key - one state record per customer. Referenced by StateProcessingData and UserValidationErrors via FK. The core identifier linking all Apex workflow tables. |
| 2 | ApexStateID | int | NO | - | VERIFIED | The current state machine step for this customer's Apex account processing. FK to Dictionary.State. 47 possible values spanning creation (1-10), update (11-19), investigation (20-35), restriction (38-39), closure (41-45), and special approval (46-47) workflows. See [State (Apex State)](_glossary.md#state-apex-state) for full definitions. (Dictionary.State) |
| 3 | Comment | nvarchar(4000) | YES | - | CODE-BACKED | Context text for the current state. Typically contains error messages, investigation details, or processing notes. Truncated to 4000 chars by SaveState before storage. NULL for normal progression states. Contains structured data like "Error = {type}; Code = {code}; Description = {msg}" or investigation reasons. |
| 4 | BeginTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System versioning row start time. Records when this state was entered. Essential for tracking state transition timing and detecting stuck states. Part of SYSTEM_TIME period for temporal table History.State. |
| 5 | EndTime | datetime2(7) | NO | '9999-12-31 23:59:59.9999999' | CODE-BACKED | System versioning row end time. '9999-12-31' indicates the current active state. Part of SYSTEM_TIME period. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ApexStateID | Dictionary.State | FK | Current workflow state from the 47-state machine |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.StateProcessingData | GCID | FK | Processing metadata (scheduling, retries, errors) for this state |
| Apex.UserValidationErrors | GCID | FK | Current validation errors for this customer's state |
| Apex.SaveState | @GCID | Writer | Atomically updates State + StateProcessingData + UserValidationErrors |
| Apex.GetState | @GCID | Reader | Retrieves state JOINed with StateProcessingData |
| Apex.GetWorkStates | - | Reader | Batch processor fetching customers ready for next transition |
| Apex.GetApexDataAndState | @GCID | Reader | Combined account data + state retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.State (table)
└── Dictionary.State (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.State | Table | FK for ApexStateID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.StateProcessingData | Table | FK on GCID - processing metadata |
| Apex.UserValidationErrors | Table | FK on GCID - validation errors |
| Apex.SaveState | Stored Procedure | Writer - atomic three-table update |
| Apex.GetState | Stored Procedure | Reader - JOINs with StateProcessingData |
| Apex.GetWorkStates | Stored Procedure | Reader - batch processor |
| Apex.GetApexDataAndState | Stored Procedure | Reader - combined retrieval |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_State | CLUSTERED PK | GCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_State | PRIMARY KEY | Clustered on GCID - one state per customer |
| FK_State_State | FOREIGN KEY | ApexStateID -> Dictionary.State(ApexStateID) |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.State |

---

## 8. Sample Queries

### 8.1 Get a customer's current state with state name

```sql
SELECT s.GCID, s.ApexStateID, ds.Name AS StateName, s.Comment, s.BeginTime
FROM Apex.State s WITH (NOLOCK)
INNER JOIN Dictionary.State ds WITH (NOLOCK) ON ds.ApexStateID = s.ApexStateID
WHERE s.GCID = 20708;
```

### 8.2 View state transition history for a customer

```sql
SELECT GCID, ApexStateID, Comment, BeginTime, EndTime
FROM Apex.State WITH (NOLOCK) WHERE GCID = 20708
UNION ALL
SELECT GCID, ApexStateID, Comment, BeginTime, EndTime
FROM History.State WITH (NOLOCK) WHERE GCID = 20708
ORDER BY BeginTime;
```

### 8.3 Find customers stuck in error/investigation states

```sql
SELECT s.GCID, s.ApexStateID, ds.Name AS StateName,
       DATEDIFF(HOUR, s.BeginTime, GETUTCDATE()) AS HoursInState,
       LEFT(s.Comment, 200) AS CommentStart
FROM Apex.State s WITH (NOLOCK)
INNER JOIN Dictionary.State ds WITH (NOLOCK) ON ds.ApexStateID = s.ApexStateID
WHERE s.ApexStateID IN (5, 9, 10, 21, 26, 34, 35, 47)
  AND DATEDIFF(HOUR, s.BeginTime, GETUTCDATE()) > 24
ORDER BY s.BeginTime ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.State | Type: Table | Source: USABroker/Apex/Tables/Apex.State.sql*
