# Trade.DeleteOpenExecutionPlanJob

> Archives completed open-execution-plan rows from Trade.OpenExecutionPlan to History.OpenExecutionPlan via MERGE, then deletes the originals for a given set of OrderIDs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderIDs (Trade.IdIntList TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **archival step** in the open-execution-plan lifecycle. After position-open orders have been fully executed (all copy-tree nodes opened), the corresponding rows in Trade.OpenExecutionPlan are no longer needed for active processing. This procedure moves them to History.OpenExecutionPlan and then removes them from the memory-optimized active table.

Trade.OpenExecutionPlan is a memory-optimized table that holds the tree-structured plan for opening positions across copy-trade hierarchies. Each row represents one node (CID/MirrorID/Level) in the copy tree. Once all nodes have been executed and confirmed, this procedure is called to archive the plan rows. Without this cleanup, the memory-optimized table would accumulate stale plan rows, consuming valuable in-memory storage and cluttering the active execution pipeline.

The procedure is called by `Trade.OrderForOpenJob` after it finishes processing an order's execution plan. It receives a TVP of OrderIDs, reads matching rows from Trade.OpenExecutionPlan into a temp table, MERGEs them into History.OpenExecutionPlan (inserting new or updating existing), and then deletes the originals from the active table. The MERGE uses partition elimination on History.OpenExecutionPlan (OccurredAsDate between GETUTCDATE()-30 and GETUTCDATE()) to target only recent partitions efficiently.

---

## 2. Business Logic

### 2.1 MERGE-Based Upsert to History

**What**: Uses MERGE to insert or update rows in History.OpenExecutionPlan, ensuring idempotent archival.

**Columns/Parameters Involved**: `OrderID`, `OpenCorrelationID`, `OccurredAsDate` (partition key on History)

**Rules**:
- Match key: OrderID + OpenCorrelationID (the composite PK of OpenExecutionPlan)
- Partition elimination clause: `Target.OccurredAsDate BETWEEN CAST(GETUTCDATE()-30 AS DATE) AND CAST(GETUTCDATE() AS DATE)` - scopes the MERGE to only the last 30 days of History partitions
- WHEN NOT MATCHED: INSERT all columns (OrderID, CID, MirrorID, Units, Level, SettlementTypeID, IsHedged, OpenActionType, OpenCorrelationID, ParentOpenCorrelationID, Amount)
- WHEN MATCHED: UPDATE all columns - handles the case where the plan was modified (e.g., units recalculated) before final archival

### 2.2 Conditional Delete from Active Table

**What**: Only deletes from Trade.OpenExecutionPlan after confirming rows were successfully archived.

**Columns/Parameters Involved**: `OrderID`

**Rules**:
- After the MERGE, checks @@ROWCOUNT > 0 before proceeding to DELETE
- DELETE joins Trade.OpenExecutionPlan to #OpenExecutionPlan on OrderID to remove only the orders that were just archived
- The INSERT into #OpenExecutionPlan also has a @@ROWCOUNT > 0 guard - if no matching rows exist, the MERGE and DELETE are skipped entirely

**Diagram**:
```
@OrderIDs (TVP)
  |
  v
#OrderIDs (DISTINCT Id as OrderID)
  |
  v
Trade.OpenExecutionPlan INNER JOIN #OrderIDs
  |
  v
#OpenExecutionPlan (staged copy)
  |
  +-- @@ROWCOUNT = 0 --> Skip (nothing to archive)
  |
  +-- @@ROWCOUNT > 0
        |
        v
      MERGE into History.OpenExecutionPlan
        |-- NOT MATCHED --> INSERT
        |-- MATCHED --> UPDATE
        |
        v
      @@ROWCOUNT > 0 --> DELETE from Trade.OpenExecutionPlan
```

### 2.3 Error Handling

**What**: Wraps the entire operation in TRY/CATCH with RAISERROR.

**Rules**:
- On any error, captures ERROR_MESSAGE() and raises with severity 16 (user-level error)
- Error message prefix: "Proc Trade.DeleteOpenExecutionPlanJob Failed"
- No explicit transaction - the MERGE and DELETE are separate statements (if MERGE succeeds but DELETE fails, rows exist in both tables; next call will UPDATE in History via MATCHED clause)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderIDs | Trade.IdIntList (TVP) | READONLY | - | VERIFIED | Table-valued parameter containing the set of OrderIDs whose execution plan rows should be archived. The Id column maps to Trade.OpenExecutionPlan.OrderID. Typically populated by Trade.OrderForOpenJob after completing order execution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderIDs.Id | Trade.OpenExecutionPlan.OrderID | JOIN | Identifies which execution plan rows to archive and delete |
| (MERGE target) | History.OpenExecutionPlan | Archive destination | Rows are upserted here before deletion from the active table |
| @OrderIDs | Trade.IdIntList | UDT (TVP) | Table-valued parameter type containing a single Id INT column |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForOpenJob | EXEC call | Caller | Calls this procedure after processing open-order execution to archive completed plan rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteOpenExecutionPlanJob (procedure)
+-- Trade.OpenExecutionPlan (table)
+-- History.OpenExecutionPlan (table)
+-- Trade.IdIntList (user defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OpenExecutionPlan | Table | SELECT + DELETE - reads plan rows and removes them after archival |
| History.OpenExecutionPlan | Table | MERGE target - archive destination for completed plan rows |
| Trade.IdIntList | User Defined Type | TVP parameter type for @OrderIDs input |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpenJob | Stored Procedure | Calls this procedure to archive execution plan after order completion |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

**Temp table indexes created within the procedure**:
- `IDX_OrderID` on #OrderIDs(OrderID) - supports JOIN to Trade.OpenExecutionPlan
- `IDX_OrderID` on #OpenExecutionPlan(OrderID) - supports MERGE source and DELETE JOIN

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check pending execution plan rows for specific orders

```sql
SELECT  oep.OrderID, oep.CID, oep.MirrorID, oep.Units,
        oep.Level, oep.SettlementTypeID, oep.OpenCorrelationID
FROM    Trade.OpenExecutionPlan oep WITH (NOLOCK)
WHERE   oep.OrderID IN (12345, 67890);
```

### 8.2 Verify archived rows in History for recent orders

```sql
SELECT  h.OrderID, h.CID, h.MirrorID, h.Units,
        h.Level, h.OpenCorrelationID, h.OccurredAsDate
FROM    History.OpenExecutionPlan h WITH (NOLOCK)
WHERE   h.OccurredAsDate >= CAST(GETUTCDATE() - 7 AS DATE)
ORDER BY h.OccurredAsDate DESC;
```

### 8.3 Compare active vs archived plan rows

```sql
SELECT  'Active' AS Source, COUNT(*) AS RowCount
FROM    Trade.OpenExecutionPlan WITH (NOLOCK)
UNION ALL
SELECT  'History (30d)', COUNT(*)
FROM    History.OpenExecutionPlan WITH (NOLOCK)
WHERE   OccurredAsDate >= CAST(GETUTCDATE() - 30 AS DATE);
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trade.OpenExecutionPlan](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13796081714) | Confluence | Confirms the archival lifecycle and MERGE pattern for execution plan rows |

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.6/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteOpenExecutionPlanJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteOpenExecutionPlanJob.sql*
