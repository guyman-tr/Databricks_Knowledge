# Trade.GetRebalancePositions

> Retrieves position details (CID, InstrumentID, IsDiscounted, IsBuy) for a batch of PositionIDs, using partition-aligned JOIN on Trade.Position for efficient partition elimination.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionsTable dbo.BigIntTableInMem READONLY |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure performs a bulk position lookup for the rebalancing workflow. Given a set of PositionIDs (passed as a memory-optimized table variable), it returns the minimal position fields needed to process a rebalancing operation: the customer (CID), instrument (InstrumentID), discount flag (IsDiscounted), and direction (IsBuy). The name "Rebalance" refers to portfolio rebalancing - the process of adjusting a copied portfolio to align with the leader's current allocations.

The key technical feature is **partition-aligned JOIN**: Trade.Position is a partitioned view where each partition corresponds to PositionID%50. By pre-computing PartitionCol=Id%50 in a temp table and including it in the JOIN condition, SQL Server can perform partition elimination - it searches only the relevant partition(s) instead of scanning all 50. This makes the procedure efficient for bulk lookups across a large partitioned dataset.

The `dbo.BigIntTableInMem` input UDT is a memory-optimized table type (In-Memory OLTP) with a HASH index on Id, bucket count 256. Passing thousands of PositionIDs through an in-memory table variable avoids temp table spill-to-disk overhead.

---

## 2. Business Logic

### 2.1 Partition-Aligned Bulk Lookup

**What**: Computes the partition column (Id%50) for each input PositionID to enable SQL Server partition elimination on Trade.Position.

**Columns/Parameters Involved**: `@PositionsTable.Id`, `PartitionCol`, `Trade.Position.PositionID`, `Trade.Position.PartitionCol`

**Rules**:
- Trade.Position is partitioned by PartitionCol = PositionID % 50. Rows with PositionID=50 are in partition 0, PositionID=51 in partition 1, etc.
- The JOIN includes BOTH Id=PositionID AND PartitionCol=PartitionCol. The second condition tells SQL Server exactly which partition to look in.
- Without PartitionCol in the JOIN, SQL Server would perform a full scan across all 50 partitions.
- OPTION (RECOMPILE) forces a fresh execution plan per call, accommodating varying input set sizes.

**Diagram**:
```
Input: @PositionsTable (dbo.BigIntTableInMem, in-memory)
  Id=100  -> PartitionCol = 100%50 = 0  -> look in partition 0
  Id=151  -> PartitionCol = 151%50 = 1  -> look in partition 1
  Id=202  -> PartitionCol = 202%50 = 2  -> look in partition 2

JOIN Trade.Position ON PositionID=Id AND PartitionCol=PartitionCol
  -> SQL Server eliminates all partitions except matched ones
  -> Efficient even for millions of positions across 50 partitions
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionsTable | dbo.BigIntTableInMem READONLY | NO | - | CODE-BACKED | Memory-optimized table variable containing PositionIDs (as Id BIGINT) to look up. Uses In-Memory OLTP HASH index (bucket=256) for fast lookups. Caller populates with the batch of positions to rebalance. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | PositionID | BIGINT | NO | - | VERIFIED | Unique position identifier. Maps from input Id via partition-aligned JOIN to Trade.Position. |
| 3 | CID | INT | NO | - | VERIFIED | Customer ID who owns the position. Needed to route rebalance operations to the correct customer account. |
| 4 | InstrumentID | INT | NO | - | VERIFIED | The traded instrument. Used to determine what to buy/sell during rebalancing. FK to Trade.Instrument. |
| 5 | IsDiscounted | BIT | NO | - | CODE-BACKED | Fee discount flag for this position. 1=discounted fee rate applies. Needed for rebalance P&L calculations. |
| 6 | IsBuy | BIT | NO | - | VERIFIED | Trade direction: 1=Long/Buy, 0=Short/Sell. Needed to determine the rebalance direction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionsTable.Id / PositionID | Trade.Position | Reader | Partition-aligned JOIN to fetch position details for the input batch |
| @PositionsTable | dbo.BigIntTableInMem | UDT reference | Memory-optimized in-memory table type for input parameter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Rebalance service | @PositionsTable | Application call | Bulk position data fetch during portfolio rebalancing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetRebalancePositions (procedure)
+-- Trade.Position (view - partitioned)
|     +-- Trade.PositionTbl (table)
|     +-- Trade.PositionTreeInfo (table)
+-- dbo.BigIntTableInMem (UDT - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View (partitioned) | Partition-aligned INNER JOIN for bulk position data; 3-part name (etoro.Trade.Position) allows cross-database call |
| dbo.BigIntTableInMem | UDT (dbo schema) | Memory-optimized table type for input batch parameter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Rebalance/CopyTrader service | External application | Bulk position data fetch for portfolio rebalancing operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK | Isolation hint | READ UNCOMMITTED on Trade.Position for performance |
| OPTION (RECOMPILE) | Query hint | Forces fresh execution plan per call - accommodates variable input set sizes |
| Partition-aligned JOIN | Design | Id%50=PartitionCol in JOIN enables SQL Server partition elimination - critical for performance on partitioned Trade.Position |
| DROP TABLE IF EXISTS #a | Safety | Ensures clean temp table even if proc is called in same session |
| etoro.Trade.Position | 3-part name | Explicit database qualifier - allows this proc to be called from other databases |

---

## 8. Sample Queries

### 8.1 Fetch position data for a batch of positions

```sql
DECLARE @PositionBatch dbo.BigIntTableInMem;
INSERT INTO @PositionBatch (Id) VALUES (123456789), (234567890), (345678901);
EXEC Trade.GetRebalancePositions @PositionsTable = @PositionBatch;
```

### 8.2 Equivalent inline partition-aligned query

```sql
-- Shows the partition elimination technique
DECLARE @Ids TABLE (Id BIGINT, PartitionCol INT);
INSERT INTO @Ids VALUES (123456789, 123456789%50), (234567890, 234567890%50);

SELECT p.PositionID, p.CID, p.InstrumentID, p.IsDiscounted, p.IsBuy
FROM @Ids a
INNER JOIN Trade.Position p WITH (NOLOCK) ON a.Id = p.PositionID AND a.PartitionCol = p.PartitionCol
OPTION (RECOMPILE);
```

### 8.3 Check how many partitions a set of positions would touch

```sql
-- Shows partition distribution for a set of PositionIDs
SELECT Id % 50 AS PartitionCol, COUNT(*) AS PositionCount
FROM (VALUES (123456789), (234567890), (345678901), (100000000)) AS T(Id)
GROUP BY Id % 50
ORDER BY PartitionCol;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetRebalancePositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetRebalancePositions.sql*
