# Trade.DeleteClosedTrees

> Maintenance job that purges PositionTreeInfo rows for copy-trade trees whose head position closed before yesterday, processing partition-by-partition in batches of 1,000.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | TreeID (identifies copy-trade trees to delete) |
| **Partition** | Operates across 50 partitions (0-49) on PositionTreeInfo |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteClosedTrees is a nightly maintenance procedure that cleans up the Trade.PositionTreeInfo table by removing tree metadata for copy-trade hierarchies whose head (root) position has been closed. PositionTreeInfo stores the tree structure (limits, stop-loss, take-profit) for CopyTrader hierarchies. Once the head position closes and no child positions remain open, the tree info is no longer needed for real-time operations.

This procedure exists to keep the PositionTreeInfo table lean. Without periodic cleanup, closed tree entries accumulate indefinitely, degrading performance of copy-trading lookups. The procedure targets trees where the head position closed before yesterday (@MaxDate = GETDATE() - 1), providing a safety buffer to avoid deleting trees that are still in the close settlement pipeline.

Data flow: (1) Identify candidate trees by joining PositionTreeInfo to RealHistoryPosition on TreeID=PositionID where CloseOccurred < yesterday. (2) Exclude any TreeID that still has an open position in Trade.PositionTbl (EXCEPT clause). (3) On demo databases, also include negative TreeIDs from History.Position. (4) Process deletes partition-by-partition (50 partitions, 0-49) in batches of 1,000 to minimize lock escalation on the partitioned table.

---

## 2. Business Logic

### 2.1 Closed Tree Identification

**What**: A tree is eligible for deletion when its head position has closed AND no children remain in Trade.PositionTbl.

**Columns/Parameters Involved**: `TreeID`, `CloseOccurred`, `@MaxDate`

**Rules**:
- Head position identified via JOIN: PositionTreeInfo.TreeID = RealHistoryPosition.PositionID (the head position IS the tree ID)
- CloseOccurred < yesterday ensures the position is fully settled
- EXCEPT Trade.PositionTbl TreeIDs ensures no open child positions exist
- This two-step check prevents premature deletion of trees with partially-closed hierarchies

### 2.2 Demo Database Handling

**What**: Demo databases include negative TreeIDs from History.Position for additional cleanup.

**Columns/Parameters Involved**: `FeatureID`, `TreeID`

**Rules**:
- Checks Maintenance.Feature WHERE FeatureID = 22 AND Value = 0 to detect demo database
- On demo: also includes negative TreeIDs (demo copy positions) from History.Position
- Negative TreeIDs are a convention for demo/simulated copy-trade trees

### 2.3 Partition-Aware Batch Delete

**What**: Deletes are processed across 50 partitions in batches to avoid lock escalation.

**Columns/Parameters Involved**: `PartitionCol`, `Status`

**Rules**:
- Temp table #TREES_TO_DELETE has a computed PartitionCol = ABS(TreeID % 50) matching the real table's partitioning
- Outer loop iterates partitions 0-49; inner loop processes 1,000 trees per batch
- Status tracking: 0=pending, 1=marked for deletion, 2=deleted
- DELETE uses INNER JOIN matching both TreeID and PartitionCol for partition elimination

**Diagram**:
```
For each partition (0-49):
  Mark 1000 rows Status=1
  While rows remain:
    DELETE PositionTreeInfo INNER JOIN #trees WHERE Status=1
    Mark deleted rows Status=2
    Mark next 1000 Status=1
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | This procedure takes no parameters. It runs as a scheduled maintenance job. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (DELETE) | Trade.PositionTreeInfo | DELETER | Target table - removes tree metadata rows for closed trees |
| (JOIN) | RealHistoryPosition | READ | Synonym/view for historical position data; identifies closed head positions |
| (EXCEPT) | Trade.PositionTbl | READ | Checked to exclude trees with still-open child positions |
| (SELECT) | Maintenance.Feature | READ | Checked to detect demo database (FeatureID=22, Value=0) |
| (JOIN) | History.Position | READ | Used on demo databases to find negative TreeIDs for cleanup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteClosedTrees (procedure)
+-- Trade.PositionTreeInfo (table)
+-- RealHistoryPosition (synonym/view)
+-- Trade.PositionTbl (table)
+-- Maintenance.Feature (table, cross-schema)
+-- History.Position (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTreeInfo | Table | DELETE target for closed tree records |
| RealHistoryPosition | Synonym/View | JOIN to identify closed head positions by CloseOccurred |
| Trade.PositionTbl | Table | EXCEPT to exclude trees with open child positions |
| Maintenance.Feature | Table | Read to detect demo database environment |
| History.Position | Table | Used on demo databases for negative TreeID cleanup |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run the cleanup job

```sql
EXEC Trade.DeleteClosedTrees
```

### 8.2 Preview trees eligible for deletion

```sql
SELECT  pti.TreeID, hp.CloseOccurred
FROM    Trade.PositionTreeInfo pti WITH (NOLOCK)
        INNER JOIN RealHistoryPosition hp WITH (NOLOCK) ON pti.TreeID = hp.PositionID
WHERE   hp.CloseOccurred < CAST(GETDATE() - 1 AS DATE)
        AND pti.TreeID NOT IN (SELECT TreeID FROM Trade.PositionTbl WITH (NOLOCK))
```

### 8.3 Check remaining tree count after cleanup

```sql
SELECT  COUNT(*) AS RemainingTrees
FROM    Trade.PositionTreeInfo WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteClosedTrees | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteClosedTrees.sql*
