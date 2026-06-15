# Trade.PositionsHedgeServerChangeSummaryLog

> Parent log table that groups hedge-server rerouting operations. Each row represents one reroute batch with a start/end time window and optional comments for audit and monitoring.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered PK, 1 NC on StartTime) |

---

## 1. Business Meaning

Trade.PositionsHedgeServerChangeSummaryLog records the summary of each hedge-server rerouting operation. When positions are moved from one hedge server to another (e.g., for load balancing, failover, or reroute rules), the system first inserts a row here with StartTime and Comments, obtains the new ID, then processes the position changes. Child rows in Trade.PositionsHedgeServerChangeLog reference this ID via OperationSummaryID. When the operation completes, the same procedures update EndTime.

This table exists to group individual position changes into logical operations. Without it, there would be no way to know which position changes belonged to the same batch, how long a reroute took, or who/what triggered it. Operations staff and monitoring alerts (e.g., Monitor.AlertForDealingExecutionConfigurationManager) rely on this to detect anomalies such as more than 1000 positions routed in a single operation.

Data flows: Trade.PositionsHedgeServerChangeSummaryLogInsert creates new rows and returns the ID. Trade.MovePositionsHedgeServers and Trade.MovePositionsHedgeServersByRerouteService receive that ID as @OperationSummaryID, process positions, and UPDATE EndTime when done. The Monitor alert joins this table to Trade.PositionsHedgeServerChangeLog to count positions per operation and alert on large batches.

---

## 2. Business Logic

### 2.1 Operation Lifecycle (Start -> End)

**What**: Each summary row tracks the time window of a hedge-server rerouting operation.

**Columns/Parameters Involved**: `StartTime`, `EndTime`, `ID`

**Rules**:
- StartTime is set at INSERT (PositionsHedgeServerChangeSummaryLogInsert) via getutcdate() when the caller begins the operation
- EndTime is NULL until the move procedure commits; then UPDATE sets EndTime = getutcdate() for that ID
- The ID is returned to the caller and passed as @OperationSummaryID to MovePositionsHedgeServers or MovePositionsHedgeServersByRerouteService

**Diagram**:
```
Caller -> PositionsHedgeServerChangeSummaryLogInsert(@Comments)
              |
              v
         INSERT (StartTime=UTC, Comments)
         @SummaryID = scope_identity()
              |
              v
Caller -> MovePositionsHedgeServers(..., @OperationSummaryID)
              |
              v
         ... process positions ...
         UPDATE PositionsHedgeServerChangeSummaryLog
         SET EndTime = getutcdate() WHERE ID = @OperationSummaryID
         COMMIT
```

### 2.2 Comments for Audit and Alerts

**What**: Human-readable context for the operation, used in monitoring and troubleshooting.

**Columns/Parameters Involved**: `Comments`

**Rules**:
- Comments are optional (nullable) and supplied by the caller when inserting
- Typically includes operator name and brief reason (e.g., "yardenmo: for testing", "reroute service: load balancing")
- Monitor.AlertForDealingExecutionConfigurationManager surfaces Comments when alerting on large reroute batches (>1000 positions)

---

## 3. Data Overview

| ID | StartTime | EndTime | Comments | Meaning |
|---|---|---|---|---|
| 240 | 2025-08-20 12:33:28 | 2025-08-20 12:33:28 | yardenmo: t | Quick test run by operator yardenmo. Start and End differ by milliseconds - small batch. |
| 239 | 2025-08-20 12:26:48 | 2025-08-20 12:26:48 | yardenmo: test | Another test run. Sub-second duration indicates few positions moved. |
| 238 | 2025-08-20 12:16:57 | 2025-08-20 12:16:58 | yardenmo: for testing | ~1 second duration - moderate batch size. Manual reroute for validation. |
| 237 | 2025-08-20 12:16:55 | 2025-08-20 12:16:57 | yardenmo: for testing | ~2 second window. Multiple test runs in sequence to verify reroute logic. |
| 236 | 2025-08-20 12:16:53 | 2025-08-20 12:16:55 | yardenmo: for testing | Similar pattern - test operations clustered in time. |

**Selection criteria for the 5 rows:**
- Rows 236-240 represent the most recent operations (ORDER BY ID DESC)
- All show completed operations (EndTime populated)
- Comments illustrate the typical format: operator: reason
- Duration varies from milliseconds to seconds depending on batch size

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key. Returned by scope_identity() from PositionsHedgeServerChangeSummaryLogInsert and passed as OperationSummaryID to MovePositionsHedgeServers/MovePositionsHedgeServersByRerouteService. Referenced by Trade.PositionsHedgeServerChangeLog.OperationSummaryID (FK). |
| 2 | StartTime | datetime | NO | - | CODE-BACKED | UTC timestamp when the reroute operation began. Set at INSERT via getutcdate() in PositionsHedgeServerChangeSummaryLogInsert. Marks the start of the batch. |
| 3 | EndTime | datetime | YES | - | CODE-BACKED | UTC timestamp when the reroute operation completed. Initially NULL; updated by MovePositionsHedgeServers and MovePositionsHedgeServersByRerouteService on successful COMMIT. Difference from StartTime indicates operation duration. |
| 4 | Comments | varchar(250) | YES | - | CODE-BACKED | Free-text description of the operation (e.g., operator name, reason). Supplied by caller to PositionsHedgeServerChangeSummaryLogInsert. Used by Monitor.AlertForDealingExecutionConfigurationManager when alerting on large batches (>1000 positions). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionsHedgeServerChangeLog | OperationSummaryID | FK | Each child change log row links to the parent summary via FK. Groups per-position changes into one logical reroute batch. |
| Trade.PositionsHedgeServerChangeSummaryLogInsert | @SummaryID OUTPUT | Lookup | Procedure inserts and returns ID for callers to pass to move procedures. |
| Trade.MovePositionsHedgeServers | @OperationSummaryID | Lookup | Updates EndTime for the given summary ID when batch completes. |
| Trade.MovePositionsHedgeServersByRerouteService | @OperationSummaryID | Lookup | Same as above for reroute-service path. |
| Monitor.AlertForDealingExecutionConfigurationManager | SummaryLog.ID | JOIN | Joins to count positions per operation and alert when >1000 positions routed in one batch. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionsHedgeServerChangeSummaryLog (table)
```

Tables have no code-level dependencies. This table is a leaf.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionsHedgeServerChangeLog | Table | FK from OperationSummaryID to this table's ID |
| Trade.PositionsHedgeServerChangeSummaryLogInsert | Procedure | INSERTs rows, returns ID |
| Trade.MovePositionsHedgeServers | Procedure | UPDATEs EndTime |
| Trade.MovePositionsHedgeServersByRerouteService | Procedure | UPDATEs EndTime |
| Monitor.AlertForDealingExecutionConfigurationManager | Procedure | JOINs to Surface Comments in alerts |
| Monitor.AlertForDealingExecutionConfigurationManager_Datadog | Procedure | Same JOIN pattern |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PositionsHedgeServerChangeSummaryLog | CLUSTERED | ID | - | - | Active |
| IX_IX_TradePositionHedgeServerChangeSummaryLog_StartTime | NC | StartTime | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PositionsHedgeServerChangeSummaryLog | PRIMARY KEY | Enforces unique ID; clustered on ID |
| ID NOT FOR REPLICATION | - | Identity column excluded from replication |

---

## 8. Sample Queries

### 8.1 Recent reroute operations with duration
```sql
SELECT   ID,
         StartTime,
         EndTime,
         DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
         Comments
FROM     Trade.PositionsHedgeServerChangeSummaryLog WITH (NOLOCK)
WHERE    EndTime IS NOT NULL
ORDER BY ID DESC;
```

### 8.2 Operations with position counts (join to change log)
```sql
SELECT   s.ID,
         s.StartTime,
         s.EndTime,
         s.Comments,
         COUNT(c.PositionID) AS PositionCount
FROM     Trade.PositionsHedgeServerChangeSummaryLog s WITH (NOLOCK)
         LEFT JOIN Trade.PositionsHedgeServerChangeLog c WITH (NOLOCK)
           ON c.OperationSummaryID = s.ID
GROUP BY s.ID,
         s.StartTime,
         s.EndTime,
         s.Comments
ORDER BY s.ID DESC;
```

### 8.3 Incomplete operations (no EndTime set)
```sql
SELECT   ID,
         StartTime,
         Comments
FROM     Trade.PositionsHedgeServerChangeSummaryLog WITH (NOLOCK)
WHERE    EndTime IS NULL
ORDER BY StartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionsHedgeServerChangeSummaryLog | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.PositionsHedgeServerChangeSummaryLog.sql*
