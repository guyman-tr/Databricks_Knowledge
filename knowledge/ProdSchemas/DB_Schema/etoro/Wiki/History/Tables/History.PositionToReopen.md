# History.PositionToReopen

> Execution log of position reopen operations, recording each position reopened within a batch reopen job with its outcome (success/failure) and the resulting new position ID.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - clustered on (CID, ReopenOperationID) |
| **Partition** | No (ON [HISTORY] filegroup) |
| **Indexes** | 2 (1 clustered + 1 nonclustered on ClosedPositionID) |

---

## 1. Business Meaning

`History.PositionToReopen` is the execution audit log for position reopen operations. When a back-office operation is approved to reopen a set of closed positions (typically CopyTrader positions or positions closed due to an incident), the system processes each position individually via `Trade.PositionReopen`. The result of each individual reopen attempt is recorded here: which position was reopened, for which customer, in which batch (`ReopenOperationID`), what hierarchy level it was at, what new position ID was created, and whether it succeeded or failed.

This table exists to provide full traceability of reopen operations. Reopening positions has significant financial implications - it reverses a close and creates a new open position. The execution log enables post-operation review (the results are emailed to operations teams via `Trade.ReopenOperationSendResult`), investigation of failures, and audit of which positions were affected by each batch.

Data flows in when `Trade.PositionReopen` executes for each position in a reopen batch. The batch is processed by `Trade.PositionsReopen` which iterates positions `ORDER BY LevelID ASC` - root positions first (Level 0), then Level 1 copies, then Level 2 copies - ensuring the CopyTrader hierarchy is rebuilt in the correct order. The companion table `Trade.PositionToReopen` holds the pending queue; this History table holds the completed results.

---

## 2. Business Logic

### 2.1 Hierarchy-Ordered Reopen Processing

**What**: Positions in a reopen batch are processed in CopyTrader hierarchy order - root positions before copies.

**Columns/Parameters Involved**: `LevelID`, `ReopenOperationID`, `ClosedPositionID`, `ReopenPositionID`

**Rules**:
- `Trade.PositionsReopen` processes positions `ORDER BY LevelID ASC, ClosedPositionID ASC`
- LevelID 0 = root/leader position (reopened first)
- LevelID 1 = direct copier positions (depend on Level 0 being reopened first)
- LevelID 2 = copies-of-copies (depend on Level 1 being reopened first)
- ReopenPositionID is populated with the new PositionID created for the reopened position
- After all positions are processed, results are emailed to operations via Trade.ReopenOperationSendResult

**Diagram**:
```
Trade.PositionsReopen (@ReopenOperationID)
    |
    +-> CURSOR over Trade.PositionToReopen ORDER BY LevelID ASC
        |
        +-> For each position:
            +-> EXEC Trade.PositionReopen(@ClosedPositionID, @CID)
            +-> INSERT History.PositionToReopen: (THIS TABLE)
                  ReopenOperationID, CID, ClosedPositionID,
                  LevelID, ReopenPositionID, Result, FailReason

Hierarchy order example:
  Level 0: Leader position (reopened first -> gets new PositionID)
  Level 1: Copier positions (reopened with ParentPositionID = new Level 0 ID)
  Level 2: Copies of copies (reopened with ParentPositionID = new Level 1 ID)
```

### 2.2 Result Tracking

**What**: Each reopen attempt is recorded as success or failure with diagnostic detail.

**Columns/Parameters Involved**: `Result`, `FailReason`

**Rules**:
- Result: 0=Failed, 1=Success (from live data distribution)
- When Result=0: FailReason contains the error message from Trade.PositionReopen
- When Result=1: FailReason is NULL, ReopenPositionID contains the new position ID
- ReopenPositionID is NULL on failure (no new position was created)

---

## 3. Data Overview

67 rows covering 68 reopen operations (ReopenOperationIDs up to 68). All visible recent operations succeeded (Result=1).

| ReopenOperationID | CID | ClosedPositionID | LevelID | ReopenPositionID | Result | RequestReopenOccurred | ExecutionOccurred |
|---|---|---|---|---|---|---|---|
| 68 | 3739182 | 2151342031 | 2 | 2151342054 | 1 | 2025-03-06 12:02:07 | 2025-03-06 12:02:10 |
| 67 | 3739182 | 2151342016 | 1 | 2151342017 | 1 | 2025-03-06 11:43:45 | 2025-03-06 11:43:48 |
| 66 | 3739182 | 2151341937 | 1 | 2151341938 | 1 | 2025-03-06 10:09:01 | 2025-03-06 10:09:06 |

*Execution latency ~3-5 seconds per position. LevelID 2 positions reopen after Level 1 in the same operation.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReopenOperationID | int | NO | - | VERIFIED | ID of the batch reopen operation. Links to Trade.ReopenOperation (which tracks the overall operation metadata and approval status). All positions being reopened together share the same ReopenOperationID. Part of the clustered key (CID, ReopenOperationID). |
| 2 | CID | int | NO | - | VERIFIED | Customer account ID of the position owner. Part of the clustered key - all positions for a customer in a given operation can be retrieved by clustered seek on (CID, ReopenOperationID). |
| 3 | ClosedPositionID | bigint | NO | - | VERIFIED | ID of the closed position that was reopened (or attempted to be reopened). References History.Position. Indexed independently (IDX_HistoryReopenPosition_ClosedPositionID) for reverse lookup. |
| 4 | LevelID | int | NO | - | VERIFIED | CopyTrader hierarchy level of this position within the reopen batch: 0=root/leader position, 1=direct copy, 2=copy of copy. Processing order is `ORDER BY LevelID ASC` to ensure parent positions exist before child positions are reopened. |
| 5 | ReopenPositionID | bigint | YES | - | VERIFIED | ID of the new open position created by the reopen operation. NULL when Result=0 (failed). The new position has the same instrument/amount/direction as the original closed position but with a new PositionID and current market rates. |
| 6 | RequestReopenOccurred | datetime | NO | - | CODE-BACKED | UTC timestamp when the reopen request was received/queued. Copied from Trade.PositionToReopen.RequestOccurred. Enables measurement of queue-to-execution latency. |
| 7 | ExecutionOccurred | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when the reopen execution completed (success or failure). DEFAULT getutcdate() applied at INSERT time. Typically 3-5 seconds after RequestReopenOccurred based on live data. |
| 8 | Result | tinyint | NO | - | VERIFIED | Outcome of this individual reopen attempt: 0=Failed, 1=Success. From live data both values exist. All recent operations (2025) show Result=1. |
| 9 | FailReason | varchar(max) | YES | - | VERIFIED | Error message when Result=0. NULL when Result=1. Sourced from the CATCH block in Trade.PositionReopen or Trade.PositionsReopen. Enables diagnosis of which positions failed and why. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ReopenOperationID | Trade.ReopenOperation | Implicit | The batch reopen operation this execution belongs to |
| ClosedPositionID | History.Position | Implicit | The closed position that was reopened |
| ReopenPositionID | Trade.PositionTbl | Implicit | The newly created open position resulting from the reopen |
| CID | Customer table | Implicit | The customer whose position was reopened |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionReopen | INSERT | WRITER | Inserts one row per position reopen attempt |
| Trade.ReopenOperationSendResult | SELECT | READER | Queries results to send execution summary email to operations |
| Trade.ReopenOperationValidation | SELECT | READER | May validate prior results before executing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionToReopen (table)
(leaf - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionReopen | Stored Procedure | WRITER - inserts execution result for each reopened position |
| Trade.PositionsReopen | Stored Procedure | Orchestrator - iterates positions and calls Trade.PositionReopen |
| Trade.ReopenOperationSendResult | Stored Procedure | READER - sends email report of results |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CLU_IDX_HistoryReopenPosition | CLUSTERED | CID ASC, ReopenOperationID ASC | - | - | Active |
| IDX_HistoryReopenPosition_ClosedPositionID | NONCLUSTERED | ClosedPositionID ASC | - | - | Active |

*FILLFACTOR=90. NCI on ClosedPositionID uses DATA_COMPRESSION=PAGE.*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_PositionToReopen_Occurred | DEFAULT | `getutcdate()` on ExecutionOccurred |

---

## 8. Sample Queries

### 8.1 Full results for a reopen operation

```sql
SELECT
    ptr.CID,
    ptr.ClosedPositionID,
    ptr.LevelID,
    ptr.ReopenPositionID,
    ptr.Result,
    ptr.FailReason,
    ptr.RequestReopenOccurred,
    ptr.ExecutionOccurred,
    DATEDIFF(SECOND, ptr.RequestReopenOccurred, ptr.ExecutionOccurred) AS LatencySeconds
FROM History.PositionToReopen ptr WITH (NOLOCK)
WHERE ptr.ReopenOperationID = @ReopenOperationID
ORDER BY ptr.LevelID ASC, ptr.ClosedPositionID ASC
```

### 8.2 Find reopen history for a specific closed position

```sql
SELECT
    ptr.ReopenOperationID,
    ptr.CID,
    ptr.ReopenPositionID,
    ptr.Result,
    ptr.FailReason,
    ptr.ExecutionOccurred
FROM History.PositionToReopen ptr WITH (NOLOCK)
WHERE ptr.ClosedPositionID = @ClosedPositionID
ORDER BY ptr.ExecutionOccurred DESC
```

### 8.3 Success/failure summary per operation

```sql
SELECT
    ReopenOperationID,
    COUNT(*) AS TotalPositions,
    SUM(CASE WHEN Result = 1 THEN 1 ELSE 0 END) AS Succeeded,
    SUM(CASE WHEN Result = 0 THEN 1 ELSE 0 END) AS Failed,
    MIN(ExecutionOccurred) AS StartedAt,
    MAX(ExecutionOccurred) AS CompletedAt
FROM History.PositionToReopen WITH (NOLOCK)
GROUP BY ReopenOperationID
ORDER BY ReopenOperationID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Trade.PositionsReopen, Trade.ReopenOperationSendResult) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionToReopen | Type: Table | Source: etoro/etoro/History/Tables/History.PositionToReopen.sql*
