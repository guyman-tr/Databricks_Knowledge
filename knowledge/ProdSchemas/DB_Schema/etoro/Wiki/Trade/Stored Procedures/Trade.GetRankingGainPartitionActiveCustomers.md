# Trade.GetRankingGainPartitionActiveCustomers

> Returns all customer IDs active within the last 24 hours for a specific hash partition, used by distributed ranking/gain calculation jobs to split customer processing across parallel workers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PartitionId INT, @TotalCustomerPartitionCount INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies "active" customers assigned to a specific processing partition for distributed batch jobs. eToro's ranking and gain calculation jobs must process potentially millions of customer records - rather than one monolithic job, the work is divided across N parallel workers by hashing each customer's CID. This procedure is called by each worker with its own partition ID to get only the customers it should process.

A customer is considered "active" if they appear in any of three sources: recently recorded in History.LastPostionOperationDateByCID (had any position operation), have an open position opened within the last 24 hours (Trade.PositionTbl, StatusID=1, Occurred > yesterday), or have a position opened or closed in the last 24 hours (History.PositionSlim). The UNION deduplicates across sources - a customer appearing in multiple sources is returned once.

Data flows: Called by a ranking service passing its partition index (0 to N-1). The returned CID list is then used to compute performance metrics (gain %, ranking). Corresponds to `Trade.GetPartitionDrawDownActiveCustomers` which uses the same partitioning pattern for a different metric.

---

## 2. Business Logic

### 2.1 Hash-Based Customer Partitioning

**What**: Distributes customer processing load across N parallel workers using modulo arithmetic on CID.

**Columns/Parameters Involved**: `@PartitionId`, `@TotalCustomerPartitionCount`, `CID`

**Rules**:
- Worker 0 processes: CID % @TotalCustomerPartitionCount = 0
- Worker 1 processes: CID % @TotalCustomerPartitionCount = 1
- ...Worker N-1 processes: CID % @TotalCustomerPartitionCount = N-1
- Every CID maps to exactly one partition (no overlap, complete coverage).
- @TotalCustomerPartitionCount must match across all worker invocations for a given batch run.

**Diagram**:
```
@TotalCustomerPartitionCount = 10 (example)

Worker 0: processes CID 10, 20, 30, 100, 110, ...
Worker 1: processes CID 1, 11, 21, 31, ...
...
Worker 9: processes CID 9, 19, 29, 39, ...

Together: all customers covered with no duplication
```

### 2.2 Active Customer Definition (3-Source UNION)

**What**: "Active" means the customer had position activity in the last 24 hours, drawn from three data stores covering different activity windows.

**Columns/Parameters Involved**: `CID`

**Rules**:
- Source 1 (History.LastPostionOperationDateByCID): Customers with a recorded last operation - broadest activity indicator.
- Source 2 (Trade.PositionTbl): Customers with a live open position opened in the last 24 hours (Occurred > GETDATE()-1 AND StatusID=1).
- Source 3 (History.PositionSlim): Customers with a position opened or closed in the last 24 hours (OpenOccurred > yesterday OR CloseOccurred > yesterday).
- UNION (not UNION ALL) deduplicates: each CID returned once even if active in multiple sources.

**Diagram**:
```
Active Customer Sources (UNION = deduplicated):
  History.LastPostionOperationDateByCID -> broad activity window
  Trade.PositionTbl (StatusID=1, Occurred > now-1d) -> recently opened open positions
  History.PositionSlim (Open or Close within 24h) -> recent position lifecycle events
           |
           v
  Distinct CID list for partition @PartitionId
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PartitionId | INT | NO | - | CODE-BACKED | The zero-based partition index this worker is responsible for. Must be in range [0, @TotalCustomerPartitionCount - 1]. Workers call this with sequential IDs (0, 1, 2, ..., N-1). |
| 2 | @TotalCustomerPartitionCount | INT | NO | - | CODE-BACKED | Total number of partitions (workers) in this batch run. Used as the modulus divisor: CID % @TotalCustomerPartitionCount = @PartitionId. Must be consistent across all workers in the same run. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | CID | INT | NO | - | CODE-BACKED | Customer ID assigned to this partition who had trading activity in the last 24 hours. Each CID returned once (UNION deduplicates). The caller uses this list to compute ranking/gain metrics for these customers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID (source 1) | History.LastPostionOperationDateByCID | Reader (cross-schema) | Broad activity tracking table - customers with any recent position operation |
| CID (source 2) | Trade.PositionTbl | Reader | Open positions opened in last 24 hours |
| CID (source 3) | History.PositionSlim | Reader (cross-schema) | Position events (open/close) from last 24 hours |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Ranking calculation service | @PartitionId | Application call | Called once per worker to get that worker's active customer subset for gain/ranking calculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetRankingGainPartitionActiveCustomers (procedure)
+-- History.LastPostionOperationDateByCID (table - cross-schema)
+-- Trade.PositionTbl (table)
+-- History.PositionSlim (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.LastPostionOperationDateByCID | Table (History schema) | Source 1 - customers with any recent position operation |
| Trade.PositionTbl | Table | Source 2 - open positions opened in last 24h |
| History.PositionSlim | Table (History schema) | Source 3 - positions opened or closed in last 24h |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Ranking calculation service | External application | Parallel batch job - each worker calls with its partition index |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK | Isolation hint | READ UNCOMMITTED on all three source tables |
| UNION | Deduplication | Ensures each CID returned once regardless of how many sources it appears in |
| CID % N = PartitionId | Hash filter | Hash-based partition assignment; not dependent on alphabetical or sequential order |

---

## 8. Sample Queries

### 8.1 Get active customers for partition 0 of 10

```sql
EXEC Trade.GetRankingGainPartitionActiveCustomers
    @PartitionId = 0,
    @TotalCustomerPartitionCount = 10;
```

### 8.2 Check how many active customers are in a given partition

```sql
-- Simulate the partition query inline to count customers
SELECT COUNT(DISTINCT CID) AS CustomerCount
FROM (
    SELECT CID FROM History.LastPostionOperationDateByCID WITH (NOLOCK)
    WHERE CID % 10 = 0
    UNION
    SELECT CID FROM Trade.PositionTbl WITH (NOLOCK)
    WHERE Occurred > GETDATE()-1 AND StatusID=1 AND CID % 10 = 0
    UNION
    SELECT CID FROM History.PositionSlim WITH (NOLOCK)
    WHERE (OpenOccurred > GETDATE()-1 OR CloseOccurred > GETDATE()-1)
    AND CID % 10 = 0
) AS UnionResult;
```

### 8.3 Verify partition coverage (all partitions combined return distinct customers)

```sql
-- Run for all partitions, count total - should equal distinct active customers
-- Example for 3 partitions
SELECT SUM(PartitionCount) AS TotalAcrossAllPartitions
FROM (
    SELECT 0 AS PartitionId, COUNT(*) AS PartitionCount
    FROM Trade.PositionTbl WITH (NOLOCK)
    WHERE Occurred > GETDATE()-1 AND StatusID=1 AND CID % 3 = 0
    UNION ALL
    SELECT 1, COUNT(*) FROM Trade.PositionTbl WITH (NOLOCK)
    WHERE Occurred > GETDATE()-1 AND StatusID=1 AND CID % 3 = 1
    UNION ALL
    SELECT 2, COUNT(*) FROM Trade.PositionTbl WITH (NOLOCK)
    WHERE Occurred > GETDATE()-1 AND StatusID=1 AND CID % 3 = 2
) AS PartitionCounts;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetRankingGainPartitionActiveCustomers | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetRankingGainPartitionActiveCustomers.sql*
