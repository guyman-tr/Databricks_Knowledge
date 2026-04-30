# Trade.CloseOpenPositionWithStatus2

> Cleanup procedure that finalizes positions stuck in StatusID=2 (marked as closed but still in Trade.PositionTbl) by archiving them to History.Position_Active, creating change log entries, and deleting from Trade.PositionTbl.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | PositionID (stuck positions being cleaned up) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CloseOpenPositionWithStatus2 is a data remediation procedure that handles positions which reached StatusID=2 (closed) in Trade.PositionTbl but were never properly archived to History. In the normal close flow, when a position is closed, it transitions to StatusID=2, gets copied to History.Position_Active, gets a change log entry, and then is deleted from Trade.PositionTbl. If that flow is interrupted (crash, timeout, deadlock), positions can get stuck at StatusID=2 indefinitely.

Without this procedure, stuck StatusID=2 positions would occupy space in Trade.PositionTbl (a hot, heavily-indexed table), potentially appearing in queries for "closed but unarchived" positions and causing data inconsistencies between Trade and History schemas.

The procedure processes one position at a time in a WHILE loop with individual TRY/CATCH and transaction per position. This ensures that a failure on one position does not prevent others from being processed. It filters to positions with CloseOccurred more than 1 day ago and ActionType NOT IN (2, 7) to avoid interfering with active close operations.

---

## 2. Business Logic

### 2.1 Stuck Position Identification

**What**: Finds positions that are stuck at StatusID=2 in Trade.PositionTbl.

**Columns/Parameters Involved**: `StatusID`, `CloseOccurred`, `ActionType`

**Rules**:
- StatusID = 2 (closed)
- CloseOccurred < GETDATE()-1 (more than 1 day old - gives normal flow time to complete)
- ActionType NOT IN (2, 7) - excludes specific action types from cleanup (likely partial close and split actions that have their own flows)
- Must have matching PositionTreeInfo record (INNER JOIN validates tree integrity)

### 2.2 History Archive

**What**: Archives position data to History.Position_Active for positions not yet in History.

**Columns/Parameters Involved**: Full position record (75+ columns)

**Rules**:
- Only inserts if ExsitsInHistoryPosition = 0 (position not already in History.Position_Active)
- Joins Trade.PositionTbl with Trade.PositionTreeInfo for tree-level fields (LimitRate, StopRate, IsTslEnabled, IsDiscounted, CloseOnEndOfWeek)
- LEFT JOINs Trade.HedgeServer for EndHedgeQuery calculation (IsDummy flag)
- Uses partition elimination: abs(TreeID%50) = TPTI.PartitionCol AND PositionID%50 = PartitionCol
- After successful INSERT to History, DELETEs from Trade.PositionTbl

### 2.3 Change Log Entry

**What**: Creates a position change log entry (ChangeTypeID=6 = Close) for positions not yet logged.

**Columns/Parameters Involved**: Full position fields

**Rules**:
- Only executes if ExsitsInPositionChangeLog = 0 (no existing close change log with ChangeTypeID=6)
- Reads position data from History.PositionSlim (after archive)
- Calls History.PositionChangeLog_Insert with ChangeTypeID=6 (Close)

**Diagram**:
```
Trade.PositionTbl (StatusID=2, CloseOccurred < GETDATE()-1)
          |
     WHILE loop (one position at a time)
          |
     +----+----+
     |         |
  Not in     Not in
  History?   ChangeLog?
     |         |
  INSERT     EXEC History.
  History.   PositionChangeLog_Insert
  Position_  (ChangeTypeID=6)
  Active
     |
  DELETE
  Trade.PositionTbl
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | This procedure has no parameters. It processes all eligible stuck positions automatically. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | READ + DELETE | Source: reads stuck positions (StatusID=2), deletes after archiving |
| TreeID | Trade.PositionTreeInfo | READ (JOIN) | Provides tree-level fields: LimitRate, StopRate, IsTslEnabled, CloseOnEndOfWeek, IsDiscounted |
| HedgeServerID | Trade.HedgeServer | READ (LEFT JOIN) | Provides IsDummy flag for EndHedgeQuery calculation |
| PositionID | History.Position_Active | INSERT | Archive destination for position data |
| PositionID | History.PositionSlim | READ | Reads archived position data for change log creation |
| PositionID | History.PositionChangeLog_Active | READ (LEFT JOIN) | Checks if close change log already exists (ChangeTypeID=6) |
| - | History.PositionChangeLog_Insert | EXEC | Creates the close change log entry |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DBA/Operations | Manual/Scheduled | EXEC | Run manually or via scheduled job to clean up stuck positions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CloseOpenPositionWithStatus2 (procedure)
+-- Trade.PositionTbl (table)
+-- Trade.PositionTreeInfo (table)
+-- Trade.HedgeServer (table)
+-- History.Position_Active (table)
+-- History.PositionSlim (view/table)
+-- History.PositionChangeLog_Active (table)
+-- History.PositionChangeLog_Insert (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | READ (stuck positions) + DELETE (after archive) |
| Trade.PositionTreeInfo | Table | READ (JOIN - tree-level fields) |
| Trade.HedgeServer | Table | READ (LEFT JOIN - IsDummy flag) |
| History.Position_Active | Table | INSERT (archive destination) + READ (existence check) |
| History.PositionSlim | View/Table | READ (position data for change log) |
| History.PositionChangeLog_Active | Table | READ (existence check for ChangeTypeID=6) |
| History.PositionChangeLog_Insert | Procedure | EXEC (creates close change log with ChangeTypeID=6) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DBA/Operations | External | Manual or scheduled execution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Global ##temp table | Coupling | Uses ##positions for cross-statement data sharing |
| WHILE loop | Pattern | Processes one position per iteration with individual transaction |
| Per-position TRY/CATCH + TRAN | Resilience | Failure on one position (ROLLBACK) does not prevent others from processing |
| Partition elimination | Performance | Uses PositionID%50 and TreeID%50 for partition-aligned access |
| WITH (NOLOCK) | Isolation | Reads from multiple tables without locks |

---

## 8. Sample Queries

### 8.1 Check for positions stuck at StatusID=2

```sql
SELECT COUNT(*) AS StuckCount,
       MIN(CloseOccurred) AS OldestClose,
       MAX(CloseOccurred) AS NewestClose
FROM   Trade.PositionTbl WITH (NOLOCK)
WHERE  StatusID = 2
  AND  CloseOccurred < GETDATE() - 1
  AND  ActionType NOT IN (2, 7);
```

### 8.2 Preview which positions would be processed

```sql
SELECT PositionID, CID, TreeID, CloseOccurred, ActionType
FROM   Trade.PositionTbl WITH (NOLOCK)
WHERE  StatusID = 2
  AND  CloseOccurred < GETDATE() - 1
  AND  ActionType NOT IN (2, 7)
ORDER BY CloseOccurred;
```

### 8.3 Verify positions archived to History

```sql
SELECT TOP 10 PositionID, CID, EndDateTime, ActionType
FROM   History.Position_Active WITH (NOLOCK)
ORDER BY EndDateTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (History.PositionChangeLog_Insert) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CloseOpenPositionWithStatus2 | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CloseOpenPositionWithStatus2.sql*
