# Trade.DeleteOrderForCloseJob

> Archives terminal-status close orders from Trade.OrderForClose to History.OrderForClose via MERGE, then deletes the originals in configurable batch sizes.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @rows (batch size) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **archival and cleanup step** for position-close orders. Trade.OrderForClose is a memory-optimized table holding orders while they are actively being processed. Once an order reaches a terminal status (FILLED, REJECTED, CANCELED, etc.), it no longer needs to be in the hot execution path. This procedure moves those terminal orders to the disk-based History.OrderForClose table and deletes them from memory.

Without this procedure, Trade.OrderForClose would accumulate completed orders indefinitely. As a memory-optimized table, every row consumes RAM directly, so stale terminal orders waste valuable in-memory resources and increase scan times for active-order queries.

This procedure is called by `Trade.OrderForCloseJob` as part of the close-order processing lifecycle. It selects up to @rows orders that have reached terminal status (determined by joining to Dictionary.OrderForExecutionStatus WHERE IsTerminal=1), MERGEs them into History.OrderForClose with 30-day partition elimination, and deletes the originals. Deleted OrderIDs are OUTPUT into #OrderIDsBeenDeleted for downstream use by the caller.

---

## 2. Business Logic

### 2.1 Terminal Status Selection

**What**: Identifies close orders eligible for archival by joining to the status dictionary.

**Columns/Parameters Involved**: `StatusID`, `Dictionary.OrderForExecutionStatus.IsTerminal`

**Rules**:
- Joins Trade.OrderForClose to Dictionary.OrderForExecutionStatus ON StatusID = ID
- Filters WHERE IsTerminal = 1 (terminal statuses include FILLED, REJECTED, CANCELED, etc.)
- Only terminal orders are archived - orders still in PLACED (2) or WAITING_FOR_MARKET (11) are left untouched
- Respects TOP(@rows) to limit batch size per call

### 2.2 MERGE-Based Upsert to History

**What**: Uses MERGE to upsert into History.OrderForClose with partition elimination.

**Columns/Parameters Involved**: `OrderID`, `PositionID`, `OccurredAsDate` (partition key on History)

**Rules**:
- Match key: OrderID + PositionID (composite - a position can have multiple close attempts)
- Partition elimination: `Target.OccurredAsDate BETWEEN CAST(GETUTCDATE()-30 AS DATE) AND CAST(GETUTCDATE() AS DATE)`
- WHEN NOT MATCHED: INSERT all 33 columns, mapping Source.LastUpdate to Target.CloseOccurred
- WHEN MATCHED: UPDATE all columns, also mapping Source.LastUpdate to Target.CloseOccurred
- All 33 columns from the temp table are transferred, including trade execution details (ExecutionID, CloseRate, ClientViewRate), copy-trade metadata (MirrorCloseActionType, RequiresHierarchicalOperation), and settlement info (SettlementTypeID, OperationType)

### 2.3 Delete with OUTPUT

**What**: Deletes archived orders from the active table and outputs deleted OrderIDs.

**Columns/Parameters Involved**: `OrderID`

**Rules**:
- DELETE joins Trade.OrderForClose to #OrderForClose on OrderID
- Uses OUTPUT DELETED.OrderID INTO #OrderIDsBeenDeleted - the caller (Trade.OrderForCloseJob) uses this list for subsequent cleanup steps
- Only runs if the MERGE affected rows (@@ROWCOUNT > 0)

**Diagram**:
```
Trade.OrderForClose (memory-optimized)
  |
  v
JOIN Dictionary.OrderForExecutionStatus WHERE IsTerminal = 1
  |
  v
TOP(@rows) --> #OrderForClose (staged copy, 33 columns)
  |
  +-- @@ROWCOUNT = 0 --> Skip
  |
  +-- @@ROWCOUNT > 0
        |
        v
      MERGE into History.OrderForClose (30-day partition window)
        |-- NOT MATCHED --> INSERT (LastUpdate -> CloseOccurred)
        |-- MATCHED --> UPDATE
        |
        v
      @@ROWCOUNT > 0 --> DELETE from Trade.OrderForClose
                          OUTPUT OrderID INTO #OrderIDsBeenDeleted
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @rows | INT | NO | 1000 | CODE-BACKED | Maximum number of terminal close orders to archive per call. Controls batch size to avoid long-running transactions on the memory-optimized table. Default 1000. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| StatusID | Dictionary.OrderForExecutionStatus | JOIN/Lookup | Joins on StatusID = ID, filters WHERE IsTerminal = 1 to find archival-eligible orders |
| (source) | Trade.OrderForClose | DELETE target | Reads and deletes terminal close orders from the memory-optimized active table |
| (MERGE target) | History.OrderForClose | Archive destination | Upserts archived order data with partition elimination on OccurredAsDate |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForCloseJob | EXEC call | Caller | Calls this procedure during close-order job processing to archive completed orders |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteOrderForCloseJob (procedure)
+-- Trade.OrderForClose (table)
+-- Dictionary.OrderForExecutionStatus (table)
+-- History.OrderForClose (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForClose | Table | SELECT + DELETE - reads terminal orders and removes after archival |
| Dictionary.OrderForExecutionStatus | Table | JOIN - determines which StatusID values are terminal (IsTerminal = 1) |
| History.OrderForClose | Table | MERGE target - disk-based archive for completed close orders |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForCloseJob | Stored Procedure | Calls this procedure as part of the close-order processing lifecycle |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

**Temp table indexes created within the procedure**:
- `IDX_OrderID` on #OrderForClose(OrderID) - supports MERGE and DELETE joins
- PK on #OrderForClose(OrderID) - declared in temp table definition

### 7.2 Constraints

None.

**Note**: The procedure relies on a temp table #OrderIDsBeenDeleted that must be pre-created by the caller (Trade.OrderForCloseJob) before invoking this procedure. The DELETE OUTPUT feeds into it.

---

## 8. Sample Queries

### 8.1 Preview terminal close orders eligible for archival

```sql
SELECT  ofc.OrderID, ofc.CID, ofc.StatusID, ofc.PositionID,
        dofe.StatusName, ofc.LastUpdate
FROM    Trade.OrderForClose ofc WITH (NOLOCK)
        INNER JOIN Dictionary.OrderForExecutionStatus dofe WITH (NOLOCK)
            ON ofc.StatusID = dofe.ID
WHERE   dofe.IsTerminal = 1;
```

### 8.2 Check recent archived close orders in History

```sql
SELECT  TOP 100 OrderID, CID, StatusID, PositionID,
        CloseOccurred, InstrumentID, CloseRate
FROM    History.OrderForClose WITH (NOLOCK)
WHERE   OccurredAsDate >= CAST(GETUTCDATE() - 7 AS DATE)
ORDER BY CloseOccurred DESC;
```

### 8.3 Count active vs archived close orders

```sql
SELECT  'Active (memory)' AS Source, COUNT(*) AS OrderCount
FROM    Trade.OrderForClose WITH (NOLOCK)
UNION ALL
SELECT  'History (30d)', COUNT(*)
FROM    History.OrderForClose WITH (NOLOCK)
WHERE   OccurredAsDate >= CAST(GETUTCDATE() - 30 AS DATE);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.7/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteOrderForCloseJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteOrderForCloseJob.sql*
