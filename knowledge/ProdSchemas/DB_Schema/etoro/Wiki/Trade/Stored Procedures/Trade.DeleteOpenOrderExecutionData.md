# Trade.DeleteOpenOrderExecutionData

> Archives open-order execution rate data from Trade.OrderExecutionData to History.OrderExecutionData via MERGE, then deletes the originals for a given set of OrderIDs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderIDs (Trade.IdIntList TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **archival step for open-order execution data**. After open-order processing is complete and execution rates have been consumed by reporting procedures, this procedure moves the transient execution rate records from the memory-optimized Trade.OrderExecutionData table to the disk-based History.OrderExecutionData table, then deletes them from the active table.

Trade.OrderExecutionData is a memory-optimized table holding execution price/rate information (ExecutionRate, ExecutionRateDiscounted, ExecutionRateSpreaded) generated when orders are filled. Each row is created during Trade.PositionOpen and consumed by Trade.OrderForOpenUpdate to return execution rates to clients. Once the order-for-open lifecycle is complete, this procedure archives the rate data.

This procedure is called by `Trade.OrderForOpenJob` as part of the post-execution cleanup. It receives a TVP of OrderIDs, reads matching rows from Trade.OrderExecutionData, MERGEs them into History.OrderExecutionData (with 30-day partition elimination), and deletes the originals. The pattern is identical to Trade.DeleteOpenExecutionPlanJob but targets execution rate data instead of execution plan data.

---

## 2. Business Logic

### 2.1 MERGE-Based Upsert to History

**What**: Uses MERGE to insert or update rows in History.OrderExecutionData with 30-day partition elimination.

**Columns/Parameters Involved**: `OrderID`, `OccurredAsDate` (partition key on History)

**Rules**:
- Match key: OrderID (each order has one execution data row)
- Partition elimination: `Target.OccurredAsDate BETWEEN CAST(GETUTCDATE()-30 AS DATE) AND CAST(GETUTCDATE() AS DATE)` - limits MERGE scan to recent History partitions
- WHEN NOT MATCHED: INSERT all 9 columns (OrderID, ExecutionID, OrderExecutionTime, OrderType, Occurred, ExecutionRateDiscounted, ExecutionRateSpreaded, ExecutionRateID, ExecutionRate)
- WHEN MATCHED: UPDATE all columns - handles re-execution or plan modification scenarios

### 2.2 Conditional Delete from Active Table

**What**: Only deletes from Trade.OrderExecutionData after confirming rows were successfully archived.

**Columns/Parameters Involved**: `OrderID`

**Rules**:
- INSERT into #OpenOrderExecutionData checks @@ROWCOUNT > 0 before proceeding to MERGE
- After MERGE, checks @@ROWCOUNT > 0 before DELETE
- DELETE joins Trade.OrderExecutionData to #OpenOrderExecutionData on OrderID

**Diagram**:
```
@OrderIDs (TVP)
  |
  v
#OrderIDs (DISTINCT Id as OrderID)
  |
  v
Trade.OrderExecutionData INNER JOIN #OrderIDs
  |
  v
#OpenOrderExecutionData (staged copy)
  |
  +-- @@ROWCOUNT = 0 --> Skip
  |
  +-- @@ROWCOUNT > 0
        |
        v
      MERGE into History.OrderExecutionData (30-day partition window)
        |-- NOT MATCHED --> INSERT
        |-- MATCHED --> UPDATE
        |
        v
      @@ROWCOUNT > 0 --> DELETE from Trade.OrderExecutionData
```

### 2.3 Error Handling

**What**: Wraps entire operation in TRY/CATCH with RAISERROR.

**Rules**:
- On error, raises "Proc Trade.DeleteOpenOrderExecutionData Failed" + ERROR_MESSAGE() at severity 16
- No explicit transaction - MERGE and DELETE are separate statements

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderIDs | Trade.IdIntList (TVP) | READONLY | - | VERIFIED | Table-valued parameter containing OrderIDs whose execution rate data should be archived. The Id column maps to Trade.OrderExecutionData.OrderID. Populated by Trade.OrderForOpenJob after open-order processing completes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderIDs.Id | Trade.OrderExecutionData.OrderID | JOIN | Identifies which execution rate rows to archive and delete |
| (MERGE target) | History.OrderExecutionData | Archive destination | Rows are upserted here before deletion from the memory-optimized active table |
| @OrderIDs | Trade.IdIntList | UDT (TVP) | Table-valued parameter type containing a single Id INT column |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForOpenJob | EXEC call | Caller | Calls this procedure after open-order execution to archive execution rate data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteOpenOrderExecutionData (procedure)
+-- Trade.OrderExecutionData (table)
+-- History.OrderExecutionData (table)
+-- Trade.IdIntList (user defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderExecutionData | Table | SELECT + DELETE - reads execution rate data and removes after archival |
| History.OrderExecutionData | Table | MERGE target - disk-based archive for execution rate data |
| Trade.IdIntList | User Defined Type | TVP parameter type for @OrderIDs input |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpenJob | Stored Procedure | Calls this procedure to archive execution rate data after order-for-open completion |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

**Temp table indexes created within the procedure**:
- `IDX_OrderID` on #OpenOrderExecutionData(OrderID) - supports MERGE and DELETE joins

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check active execution data for specific orders

```sql
SELECT  OrderID, ExecutionID, OrderType, ExecutionRate,
        ExecutionRateDiscounted, ExecutionRateSpreaded, OrderExecutionTime
FROM    Trade.OrderExecutionData WITH (NOLOCK)
WHERE   OrderID IN (12345, 67890);
```

### 8.2 Verify recent archived execution data in History

```sql
SELECT  OrderID, ExecutionID, OrderType, ExecutionRate, Occurred
FROM    History.OrderExecutionData WITH (NOLOCK)
WHERE   OccurredAsDate >= CAST(GETUTCDATE() - 7 AS DATE)
ORDER BY Occurred DESC;
```

### 8.3 Compare active vs archived execution data counts

```sql
SELECT  'Active' AS Source, COUNT(*) AS RowCount
FROM    Trade.OrderExecutionData WITH (NOLOCK)
UNION ALL
SELECT  'History (30d)', COUNT(*)
FROM    History.OrderExecutionData WITH (NOLOCK)
WHERE   OccurredAsDate >= CAST(GETUTCDATE() - 30 AS DATE);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteOpenOrderExecutionData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteOpenOrderExecutionData.sql*
