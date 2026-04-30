# Trade.DeleteOrderForExecutionChangeLogJob

> Archives order execution change-log rows from Trade.OrderForExecutionChangeLog to History.OrderForExecutionChangeLog via MERGE, then deletes the originals for a given set of OrderIDs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderIDs (Trade.IdIntList TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **archival step for order execution change logs**. Trade.OrderForExecutionChangeLog is a memory-optimized audit table that stores before-images of order state whenever a WAITING_FOR_MARKET order is re-triggered with fresh parameters. Once the associated orders have been fully processed and archived, these change log entries are no longer needed in the active memory-optimized table.

The change log captures snapshots of OrderForOpen or OrderForClose rows before they are updated during order re-triggering. Each row records what the order looked like (StatusID, Amount, rates, etc.) before the update. This procedure moves these audit records to History.OrderForExecutionChangeLog and removes them from memory.

This procedure is called by `Trade.OrderForOpenJob` (and analogous close-order jobs) as part of the post-execution cleanup chain. It follows the same MERGE-then-DELETE pattern used by the other archival procedures in the order lifecycle: stage rows into a temp table, MERGE into History with 30-day partition elimination, then DELETE from the active table.

---

## 2. Business Logic

### 2.1 MERGE-Based Upsert to History

**What**: Uses MERGE to insert or update rows in History.OrderForExecutionChangeLog.

**Columns/Parameters Involved**: `ChangeLogID`, `OccurredAsDate` (partition key on History)

**Rules**:
- Match key: ChangeLogID (unique per change log entry)
- Partition elimination: `Target.OccurredAsDate BETWEEN CAST(GETUTCDATE()-30 AS DATE) AND CAST(GETUTCDATE() AS DATE)`
- WHEN NOT MATCHED: INSERT all 18 columns (ChangeLogID, ChangeOccurred, OrderID, OrderType, StatusID, Amount, AmountInUnits, UnitMargin, IsDiscounted, RequestGuid, RequestOccurred, PriceRateID, ClientViewRateID, ClientViewRate, OpenRate, ConversionRate, ConversionPriceRateID, FrozenAmount)
- WHEN MATCHED: UPDATE all columns

### 2.2 Conditional Delete from Active Table

**What**: Only deletes after confirming rows were archived.

**Columns/Parameters Involved**: `ChangeLogID`, `OrderID`

**Rules**:
- INSERT into #OrderForExecutionChangeLog joined on OrderID (from TVP)
- @@ROWCOUNT > 0 guard before MERGE
- @@ROWCOUNT > 0 guard before DELETE
- DELETE joins on ChangeLogID (the PK of the change log table)

**Diagram**:
```
@OrderIDs (TVP)
  |
  v
#OrderIDs (DISTINCT Id as OrderID)
  |
  v
Trade.OrderForExecutionChangeLog INNER JOIN #OrderIDs ON OrderID
  |
  v
#OrderForExecutionChangeLog (staged copy, 18 columns)
  |
  +-- @@ROWCOUNT = 0 --> Skip
  |
  +-- @@ROWCOUNT > 0
        |
        v
      MERGE into History.OrderForExecutionChangeLog (30-day window)
        |-- NOT MATCHED --> INSERT
        |-- MATCHED --> UPDATE
        |
        v
      @@ROWCOUNT > 0 --> DELETE from Trade.OrderForExecutionChangeLog
                          (JOIN on ChangeLogID)
```

### 2.3 Error Handling

**What**: Wraps entire operation in TRY/CATCH with RAISERROR.

**Rules**:
- On error, raises "Proc Trade.DeleteOrderForExecutionChangeLogJob Failed" + ERROR_MESSAGE() at severity 16

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderIDs | Trade.IdIntList (TVP) | READONLY | - | VERIFIED | Table-valued parameter containing OrderIDs whose change log entries should be archived. The Id column is joined to Trade.OrderForExecutionChangeLog.OrderID to find all change log rows for those orders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderIDs.Id | Trade.OrderForExecutionChangeLog.OrderID | JOIN | Identifies which change log entries to archive by their parent OrderID |
| (MERGE target) | History.OrderForExecutionChangeLog | Archive destination | Rows are upserted here before deletion from the memory-optimized table |
| @OrderIDs | Trade.IdIntList | UDT (TVP) | Table-valued parameter type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForOpenJob | EXEC call | Caller | Calls this procedure to archive change logs after open-order completion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteOrderForExecutionChangeLogJob (procedure)
+-- Trade.OrderForExecutionChangeLog (table)
+-- History.OrderForExecutionChangeLog (table)
+-- Trade.IdIntList (user defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForExecutionChangeLog | Table | SELECT + DELETE - reads change log rows and removes after archival |
| History.OrderForExecutionChangeLog | Table | MERGE target - archive for change log entries |
| Trade.IdIntList | User Defined Type | TVP parameter type for @OrderIDs input |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpenJob | Stored Procedure | Calls this procedure during open-order job cleanup |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

**Temp table indexes created within the procedure**:
- `IDX_ChangeLogID` on #OrderForExecutionChangeLog(ChangeLogID) - supports MERGE and DELETE joins

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check active change log entries for specific orders

```sql
SELECT  ChangeLogID, ChangeOccurred, OrderID, OrderType, StatusID,
        Amount, AmountInUnits, UnitMargin
FROM    Trade.OrderForExecutionChangeLog WITH (NOLOCK)
WHERE   OrderID IN (12345, 67890)
ORDER BY ChangeOccurred DESC;
```

### 8.2 View recently archived change logs in History

```sql
SELECT  TOP 100 ChangeLogID, ChangeOccurred, OrderID, OrderType, StatusID
FROM    History.OrderForExecutionChangeLog WITH (NOLOCK)
WHERE   OccurredAsDate >= CAST(GETUTCDATE() - 7 AS DATE)
ORDER BY ChangeOccurred DESC;
```

### 8.3 Count active vs archived change log entries

```sql
SELECT  'Active (memory)' AS Source, COUNT(*) AS EntryCount
FROM    Trade.OrderForExecutionChangeLog WITH (NOLOCK)
UNION ALL
SELECT  'History (30d)', COUNT(*)
FROM    History.OrderForExecutionChangeLog WITH (NOLOCK)
WHERE   OccurredAsDate >= CAST(GETUTCDATE() - 30 AS DATE);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteOrderForExecutionChangeLogJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteOrderForExecutionChangeLogJob.sql*
