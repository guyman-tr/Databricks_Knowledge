# Trade.DeleteOrderForOpenJob

> Archives terminal-status open orders from Trade.OrderForOpen to History.OrderForOpen via MERGE, then deletes the originals and outputs deleted OrderIDs for downstream cleanup.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - processes all terminal open orders |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **archival and cleanup step** for position-open orders. Trade.OrderForOpen is a memory-optimized table holding orders while they are actively being processed through the execution engine. Once an order reaches a terminal status (FILLED, REJECTED, CANCELED, etc. as defined by Dictionary.OrderForExecutionStatus.IsTerminal=1), it no longer needs to remain in the hot execution path.

Without this procedure, Trade.OrderForOpen would accumulate completed orders indefinitely. As a memory-optimized table, every row consumes direct RAM. Stale terminal orders waste in-memory resources and increase scan times for active-order queries in the sub-millisecond execution path.

This procedure is called by `Trade.OrderForOpenJob` as part of the open-order processing lifecycle. Unlike DeleteOrderForCloseJob which takes a @rows parameter, this procedure processes ALL terminal orders in a single batch. It selects all orders where the status is terminal, MERGEs them into History.OrderForOpen with 30-day partition elimination (mapping Source.LastUpdate to Target.CloseOccurred), and deletes the originals. Deleted OrderIDs are OUTPUT into #OrderIDsBeenDeleted for the caller to use in subsequent cleanup of related tables (OpenExecutionPlan, OrderExecutionData, OrderForExecutionChangeLog).

---

## 2. Business Logic

### 2.1 Terminal Status Selection

**What**: Identifies open orders eligible for archival by joining to the status dictionary.

**Columns/Parameters Involved**: `StatusID`, `Dictionary.OrderForExecutionStatus.IsTerminal`

**Rules**:
- Joins Trade.OrderForOpen to Dictionary.OrderForExecutionStatus ON StatusID = ID
- Filters WHERE IsTerminal = 1
- No TOP limit - all terminal orders are processed in one pass (unlike DeleteOrderForCloseJob which uses @rows)

### 2.2 MERGE-Based Upsert to History

**What**: Uses MERGE to upsert all 46 columns into History.OrderForOpen.

**Columns/Parameters Involved**: `OrderID`, `OccurredAsDate` (partition key on History)

**Rules**:
- Match key: OrderID (unique per open order)
- Partition elimination: `Target.OccurredAsDate BETWEEN CAST(GETUTCDATE()-30 AS DATE) AND CAST(GETUTCDATE() AS DATE)`
- WHEN NOT MATCHED: INSERT all columns, mapping Source.LastUpdate to Target.CloseOccurred (the time the order reached terminal status)
- WHEN MATCHED: UPDATE all columns including Target.CloseOccurred = Source.LastUpdate
- The 46 columns cover the full order state: trade parameters (Amount, AmountInUnits, IsBuy, Leverage, StopRate, LimitRate), execution data (ExecutionID, PriceRateID, ClientViewRate, OpenRate, ConversionRate), copy-trade metadata (MirrorID, ParentPositionID, OpenActionType), settlement info (SettlementTypeID, OperationType), client-requested values (ClientRequestedAmount, ClientRequestedUnits, RequestedSettlementTypeID), and risk parameters (IsGuaranteedSL is not present; IsNoStopLoss, IsNoTakeProfit, AdditionalMargin are)

### 2.3 Delete with OUTPUT for Downstream Cleanup

**What**: Deletes archived orders and outputs OrderIDs for related table cleanup.

**Columns/Parameters Involved**: `OrderID`

**Rules**:
- DELETE joins Trade.OrderForOpen to #OrderForOpen on OrderID
- OUTPUT DELETED.OrderID INTO #OrderIDsBeenDeleted (created by the caller Trade.OrderForOpenJob)
- The caller uses #OrderIDsBeenDeleted to call Trade.DeleteOpenExecutionPlanJob, Trade.DeleteOpenOrderExecutionData, and Trade.DeleteOrderForExecutionChangeLogJob

**Diagram**:
```
Trade.OrderForOpen (memory-optimized)
  |
  v
JOIN Dictionary.OrderForExecutionStatus WHERE IsTerminal = 1
  |
  v
ALL terminal orders --> #OrderForOpen (46 columns)
  |
  +-- @@ROWCOUNT = 0 --> Skip
  |
  +-- @@ROWCOUNT > 0
        |
        v
      MERGE into History.OrderForOpen (30-day partition window)
        |-- NOT MATCHED --> INSERT (LastUpdate -> CloseOccurred)
        |-- MATCHED --> UPDATE
        |
        v
      @@ROWCOUNT > 0 --> DELETE from Trade.OrderForOpen
                          OUTPUT OrderID INTO #OrderIDsBeenDeleted
                          |
                          v
                        Caller uses #OrderIDsBeenDeleted for:
                        - DeleteOpenExecutionPlanJob
                        - DeleteOpenOrderExecutionData
                        - DeleteOrderForExecutionChangeLogJob
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no parameters. It operates directly on all terminal orders in Trade.OrderForOpen.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| StatusID | Dictionary.OrderForExecutionStatus | JOIN/Lookup | Joins on StatusID = ID, filters WHERE IsTerminal = 1 to find archival-eligible orders |
| (source) | Trade.OrderForOpen | DELETE target | Reads and deletes terminal open orders from the memory-optimized active table |
| (MERGE target) | History.OrderForOpen | Archive destination | Upserts archived order data with partition elimination on OccurredAsDate |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForOpenJob | EXEC call | Caller | Calls this procedure during open-order job processing to archive completed orders |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteOrderForOpenJob (procedure)
+-- Trade.OrderForOpen (table)
+-- Dictionary.OrderForExecutionStatus (table)
+-- History.OrderForOpen (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpen | Table | SELECT + DELETE - reads terminal orders and removes after archival |
| Dictionary.OrderForExecutionStatus | Table | JOIN - determines which StatusID values are terminal (IsTerminal = 1) |
| History.OrderForOpen | Table | MERGE target - disk-based archive for completed open orders |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpenJob | Stored Procedure | Calls this procedure as part of the open-order processing lifecycle |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

**Temp table indexes created within the procedure**:
- `IDX_OrderID` on #OrderForOpen(OrderID) - supports MERGE and DELETE joins
- PK on #OrderForOpen(OrderID) - declared in temp table definition

### 7.2 Constraints

None.

**Note**: The procedure relies on a temp table #OrderIDsBeenDeleted that must be pre-created by the caller (Trade.OrderForOpenJob) before invoking this procedure. The DELETE OUTPUT feeds into it. The comment in the source code confirms: "Temp table that declare in Trade.OrderForOpenJob procedure (same code scope)".

---

## 8. Sample Queries

### 8.1 Preview terminal open orders eligible for archival

```sql
SELECT  ofo.OrderID, ofo.CID, ofo.StatusID, ofo.InstrumentID,
        dofe.StatusName, ofo.LastUpdate, ofo.OrderType
FROM    Trade.OrderForOpen ofo WITH (NOLOCK)
        INNER JOIN Dictionary.OrderForExecutionStatus dofe WITH (NOLOCK)
            ON ofo.StatusID = dofe.ID
WHERE   dofe.IsTerminal = 1;
```

### 8.2 Check recent archived open orders in History

```sql
SELECT  TOP 100 OrderID, CID, StatusID, InstrumentID,
        CloseOccurred, IsBuy, Leverage, Amount
FROM    History.OrderForOpen WITH (NOLOCK)
WHERE   OccurredAsDate >= CAST(GETUTCDATE() - 7 AS DATE)
ORDER BY CloseOccurred DESC;
```

### 8.3 Count active vs archived open orders

```sql
SELECT  'Active (memory)' AS Source, COUNT(*) AS OrderCount
FROM    Trade.OrderForOpen WITH (NOLOCK)
UNION ALL
SELECT  'History (30d)', COUNT(*)
FROM    History.OrderForOpen WITH (NOLOCK)
WHERE   OccurredAsDate >= CAST(GETUTCDATE() - 30 AS DATE);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.7/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteOrderForOpenJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteOrderForOpenJob.sql*
