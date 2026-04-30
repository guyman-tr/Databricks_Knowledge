# Trade.PositionsHedgeServerChangeLog

> Detail log table recording every individual position's hedge server change, capturing the from/to server IDs and the routing rule that triggered the move, linked to parent operation summaries.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | Composite PK (OperationSummaryID, PositionID) CLUSTERED |
| **Partition** | HISTORY filegroup |
| **Row Count** | 706,899 (MCP verified) |
| **Indexes** | 2 active (1 clustered PK, 1 NC on ADM_DATE) |
| **Compression** | PAGE (on both PK and NC index) |

---

## 1. Business Meaning

Trade.PositionsHedgeServerChangeLog records the individual position-level details of every hedge server rerouting operation. When the platform moves positions between hedge servers (for load balancing, failover, or automated routing rules), each affected position gets a row in this table capturing which server it was moved from, which it was moved to, and which routing rule triggered the change.

Without this table, operations staff would have no audit trail of position-level server movements. This is critical for investigating execution issues, verifying that positions were correctly redistributed during server migrations, and monitoring the impact of routing rule changes. The table also supports effective leverage calculations by providing the history of where positions were routed.

Data is written by Trade.MovePositionsHedgeServers and Trade.MovePositionsHedgeServersByRerouteService, which receive an OperationSummaryID from the parent Trade.PositionsHedgeServerChangeSummaryLog table. The parent-child relationship groups individual position changes into logical batch operations with start/end timestamps.

---

## 2. Business Logic

### 2.1 Position Server Movement Audit

**What**: Records the before/after state of each position's hedge server assignment during a rerouting operation.

**Columns/Parameters Involved**: `PositionID`, `FromHedgeServerID`, `ToHedgeServerID`, `FromRootHedgeServerID`, `ToRootHedgeServerID`, `RuleID`

**Rules**:
- Each row captures a single position's server change within a batch operation
- FromHedgeServerID/ToHedgeServerID track the direct hedge server assignment change
- FromRootHedgeServerID/ToRootHedgeServerID track changes to the root-level server in the hedge server hierarchy
- RuleID identifies the automated routing rule that triggered the change; -1 indicates a manual/ad-hoc move
- The procedure Trade.MovePositionsHedgeServers only logs positions where StatusID=1 (open) and the server actually changed
- Multiple positions can share the same OperationSummaryID (batch operation)

**Diagram**:
```
PositionsHedgeServerChangeSummaryLog (parent)
  ID=238, StartTime=2025-08-20 12:16:58
       |
       +-- PositionsHedgeServerChangeLog (children)
       |     PositionID=2151832467: Server 1 -> 5, Rule=-1 (manual)
       |     PositionID=2151832446: Server 1 -> 5, Rule=-1 (manual)
       |     PositionID=2151351456: Server 8 -> 1, Rule=88 (auto)
       |
  EndTime updated when operation completes
```

### 2.2 Routing Rule Tracking

**What**: Links each position change to the routing rule that caused it.

**Columns/Parameters Involved**: `RuleID`, `OperationSummaryID`

**Rules**:
- RuleID > 0: Automated routing rule from the reroute service configuration
- RuleID = -1: Manual move (not triggered by an automated rule)
- Rule 88 is the most common automated rule in recent data
- Combined with OperationSummaryID, enables analysis of which rules drive the most position movements

---

## 3. Data Overview

| OperationSummaryID | PositionID | ADM_DATE | FromHedgeServerID | ToHedgeServerID | RuleID | Meaning |
|---|---|---|---|---|---|---|
| 240 | 2152074700 | 2025-08-20 12:33 | 101 | 1 | 88 | Position moved from hedge server 101 to server 1 by automated rule 88, root server stayed at 1 |
| 239 | 2152074700 | 2025-08-20 12:26 | 101 | 1 | 88 | Same position moved again 7 minutes earlier (different batch), root changed from 82 to 1 |
| 238 | 2151832467 | 2025-08-20 12:16 | 1 | 5 | -1 | Manual move from server 1 to server 5 (RuleID=-1 = no automated rule), root unchanged at 1 |
| 238 | 2151832446 | 2025-08-20 12:16 | 1 | 5 | -1 | Another position in the same manual batch moved to server 5 |
| 238 | 2151351456 | 2025-08-20 12:16 | 8 | 1 | 88 | Mixed batch: this position moved by rule 88 in the same operation as the manual moves above |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OperationSummaryID | int | NO | - | VERIFIED | FK to Trade.PositionsHedgeServerChangeSummaryLog(ID). Groups this position change into a logical batch operation with start/end timestamps and comments. Part of composite PK. Multiple positions share the same OperationSummaryID when moved in the same batch. |
| 2 | PositionID | bigint | NO | - | VERIFIED | The position that was moved between hedge servers. References Trade.PositionTbl.PositionID (implicit - no declared FK). Part of composite PK with OperationSummaryID. A position can appear multiple times if moved across different operations. |
| 3 | ADM_DATE | datetime | NO | getutcdate() | CODE-BACKED | Timestamp of when this position change was recorded. Default is UTC time at insert. Indexed (IDX_TPHSCL_ADM_DATE_BIGINT) for time-range queries. Used by monitoring and reporting to analyze rerouting activity over time. |
| 4 | FromHedgeServerID | int | NO | - | CODE-BACKED | The hedge server ID the position was on before this operation. Captured from Trade.PositionTbl.HedgeServerID at the time of the move. References Trade.HedgeServer (implicit). |
| 5 | ToHedgeServerID | int | NO | - | CODE-BACKED | The hedge server ID the position was moved to. After this operation, Trade.PositionTbl.HedgeServerID equals this value for the affected position. |
| 6 | FromRootHedgeServerID | int | YES | - | CODE-BACKED | The root-level hedge server ID before the move. Nullable because older records or certain scenarios may not track root server changes. From Trade.PositionTbl.RootHedgeServerID. |
| 7 | ToRootHedgeServerID | int | YES | - | CODE-BACKED | The root-level hedge server ID after the move. Nullable for same reasons as FromRootHedgeServerID. Tracks hierarchical server assignment changes. |
| 8 | RuleID | int | YES | - | CODE-BACKED | Identifies the automated routing rule that triggered this position move. Positive values correspond to reroute service rules. -1 = manual/ad-hoc move (not triggered by a rule). NULL if not applicable. Rule 88 is the most common in recent data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OperationSummaryID | Trade.PositionsHedgeServerChangeSummaryLog | Explicit FK (FK_PosHedgeChange_Summary_ID_BIGINT) | Links each position change to its parent batch operation with timestamps and comments |
| PositionID | Trade.PositionTbl | Implicit | References the position that was moved |
| FromHedgeServerID / ToHedgeServerID | Trade.HedgeServer | Implicit | References the hedge servers involved in the move |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionsHedgeServerChangeLog_DP | - | View | Likely a data platform view over this table |
| Trade.EffectiveLeveragePositions | - | Reader | Uses change history for effective leverage calculations |
| Trade.EffectiveLeveragePositions_Job | - | Reader | Job variant of effective leverage calculation |
| Trade.GetOrderForOpenPositionsOvt | - | Reader | Retrieves order data including hedge server change context |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionsHedgeServerChangeLog (table)
└── Trade.PositionsHedgeServerChangeSummaryLog (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionsHedgeServerChangeSummaryLog | Table | FK target - OperationSummaryID references ID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionsHedgeServerChangeLog_DP | View | Reads change log data |
| Trade.MovePositionsHedgeServers | Stored Procedure | Writer - inserts position change records |
| Trade.MovePositionsHedgeServersByRerouteService | Stored Procedure | Writer - inserts position change records |
| Trade.EffectiveLeveragePositions | Stored Procedure | Reader - uses for leverage calculations |
| Trade.EffectiveLeveragePositions_Job | Stored Procedure | Reader - job-based leverage calculations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradePositionsHedgeServerChangeLog_BIGINT | CLUSTERED PK | OperationSummaryID ASC, PositionID ASC | - | - | Active (PAGE compression) |
| IDX_TPHSCL_ADM_DATE_BIGINT | NONCLUSTERED | ADM_DATE ASC | - | - | Active (PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TradePositionsHedgeServerChangeLog_BIGINT | PRIMARY KEY | Composite (OperationSummaryID, PositionID) - a position can only appear once per operation |
| FK_PosHedgeChange_Summary_ID_BIGINT | FOREIGN KEY | OperationSummaryID -> Trade.PositionsHedgeServerChangeSummaryLog(ID). WITH CHECK |
| DF_TradePositionsHedgeServerChangeLog_ADMDate_BIGINT | DEFAULT | ADM_DATE defaults to getutcdate() |

---

## 8. Sample Queries

### 8.1 Show recent hedge server changes with operation details
```sql
SELECT  TOP 20
        scl.OperationSummaryID,
        scl.PositionID,
        scl.ADM_DATE,
        scl.FromHedgeServerID,
        scl.ToHedgeServerID,
        scl.RuleID,
        sl.Comments       AS OperationComments
FROM    Trade.PositionsHedgeServerChangeLog scl WITH (NOLOCK)
JOIN    Trade.PositionsHedgeServerChangeSummaryLog sl WITH (NOLOCK)
        ON scl.OperationSummaryID = sl.ID
ORDER BY scl.ADM_DATE DESC;
```

### 8.2 Count positions moved per operation
```sql
SELECT  scl.OperationSummaryID,
        MIN(scl.ADM_DATE)    AS OperationDate,
        COUNT(*)             AS PositionsMoved,
        COUNT(DISTINCT scl.FromHedgeServerID) AS SourceServers,
        COUNT(DISTINCT scl.ToHedgeServerID)   AS TargetServers
FROM    Trade.PositionsHedgeServerChangeLog scl WITH (NOLOCK)
GROUP BY scl.OperationSummaryID
ORDER BY PositionsMoved DESC;
```

### 8.3 Trace movement history for a specific position
```sql
SELECT  scl.OperationSummaryID,
        scl.ADM_DATE,
        scl.FromHedgeServerID,
        scl.ToHedgeServerID,
        scl.FromRootHedgeServerID,
        scl.ToRootHedgeServerID,
        scl.RuleID
FROM    Trade.PositionsHedgeServerChangeLog scl WITH (NOLOCK)
WHERE   scl.PositionID = 2152074700
ORDER BY scl.ADM_DATE;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from DDL analysis, live data sampling, parent table documentation (Trade.PositionsHedgeServerChangeSummaryLog), and procedure logic analysis (Trade.MovePositionsHedgeServers).

---

*Generated: 2026-03-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionsHedgeServerChangeLog | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.PositionsHedgeServerChangeLog.sql*
