# Trade.GetOpenPositionsFromTimestamp

> Returns a paginated bulk of open positions within a specific partition, opened before a timestamp threshold - used for bulk data extraction and synchronization pipelines.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PartitionCol + @InitialPositionID + @MaximumTimestampThreshold |
| **Partition** | Trade.Position: PartitionCol = @PartitionCol (explicit) |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOpenPositionsFromTimestamp` extracts a bulk page of open positions from a single partition of `Trade.Position`, filtered by a minimum PositionID (continuation cursor) and a maximum InitDateTime (timestamp threshold). It returns at most `@BulkSize` rows ordered ascending by PositionID.

**WHY:** Used by synchronization services and data pipelines that need to load or replicate open position data partition-by-partition. The `@PartitionCol` forces the query to a single shard, the `@InitialPositionID` enables cursor-based pagination (pick up where the last batch left off), and `@MaximumTimestampThreshold` limits the scan to positions opened before a certain time.

**HOW:** The caller iterates over all 50 partitions (0-49), using the last PositionID returned from the previous batch as the new `@InitialPositionID`. Repeats until fewer than `@BulkSize` rows are returned (indicating end of that partition). Returns `RowVersionPosition` aliased as `MaxRowVersion` to allow downstream change-tracking.

---

## 2. Business Logic

### 2.1 Partition-Scoped Cursor Pagination

**What:** The query is strictly scoped to one partition column value and pages forward using PositionID as the cursor.

**Columns/Parameters Involved:** `@PartitionCol`, `@InitialPositionID`, `@BulkSize`

**Rules:**
- `PartitionCol = @PartitionCol` -> single partition only (no cross-shard scan)
- `PositionID > @InitialPositionID` -> continuation cursor (start after last seen ID)
- `ORDER BY PositionID ASC` -> deterministic pagination order
- `SELECT TOP (@BulkSize)` -> page size cap

### 2.2 Timestamp Filter

**What:** Only positions opened before `@MaximumTimestampThreshold` are returned. This is a ceiling, not a floor - used to process positions up to a specific point in time.

**Columns/Parameters Involved:** `@MaximumTimestampThreshold`, `InitDateTime`

**Rules:**
- `InitDateTime < @MaximumTimestampThreshold` -> strict less-than (excludes positions opened exactly at the threshold)

### 2.3 Optional Instrument Filter

**What:** `@InstrumentID` is optional. When provided, restricts the bulk to a single instrument within the partition.

**Columns/Parameters Involved:** `@InstrumentID`, `InstrumentID`

**Rules:**
- `InstrumentID = ISNULL(@InstrumentID, InstrumentID)` -> NULL = all instruments, value = filter to that instrument

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BulkSize | int | NO | - | CODE-BACKED | Page size: maximum number of rows to return per call. Caller uses this to detect end-of-partition (returned rows < BulkSize). |
| 2 | @PartitionCol | integer | NO | - | CODE-BACKED | Partition shard: must be 0-49. Forces query to a single PositionTbl partition. Caller iterates all 50 partitions. |
| 3 | @InitialPositionID | bigint | NO | - | CODE-BACKED | Cursor: only positions with PositionID > this value are returned. Start at 0 for the first page. |
| 4 | @MaximumTimestampThreshold | datetime | NO | - | CODE-BACKED | Timestamp ceiling: only positions with InitDateTime < this value are returned. |
| 5 | @InstrumentID | integer | YES | NULL | CODE-BACKED | Optional instrument filter. NULL = all instruments. |

**Return Columns:**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| R1 | PositionID | bigint | NO | CODE-BACKED | Primary key. Use as next @InitialPositionID for pagination. |
| R2 | InstrumentID | int | NO | CODE-BACKED | Financial instrument being traded. |
| R3 | CID | int | NO | CODE-BACKED | Customer who owns the position. |
| R4 | HedgeServerID | int | YES | CODE-BACKED | Hedge server responsible for this position. |
| R5 | Occurred | datetime | YES | CODE-BACKED | Timestamp when the position record was created/occurred. |
| R6 | InitDateTime | datetime | NO | CODE-BACKED | Timestamp when the position was opened (used in timestamp filter). |
| R7 | Amount | money | NO | CODE-BACKED | Position amount in account currency. |
| R8 | AmountInUnitsDecimal | decimal | NO | CODE-BACKED | Position size in instrument units. |
| R9 | InitForexRate | money | NO | CODE-BACKED | Entry rate of the position. |
| R10 | IsBuy | bit | NO | CODE-BACKED | Direction: 1=long, 0=short. |
| R11 | IsComputeForHedge | bit | NO | CODE-BACKED | Whether this position is tracked by the hedge engine. |
| R12 | IsSettled | bit | YES | CODE-BACKED | Whether this is a settled (stock) position. |
| R13 | Leverage | smallint | NO | CODE-BACKED | Leverage multiplier applied at open. |
| R14 | MirrorID | int | YES | CODE-BACKED | Copy relationship ID (0 if not copied). |
| R15 | LimitRate | money | YES | CODE-BACKED | Take-profit rate. |
| R16 | StopRate | money | YES | CODE-BACKED | Stop-loss rate. |
| R17 | UnitMargin | money | NO | CODE-BACKED | Margin required per unit. |
| R18 | SpreadedCommission | money | YES | CODE-BACKED | Spread-based commission component. |
| R19 | Commission | money | YES | CODE-BACKED | Commission charged on the position. |
| R20 | FullCommission | money | YES | CODE-BACKED | Total commission including all components. |
| R21 | NetProfit | money | YES | CODE-BACKED | Running net profit (populated on Position view from PositionTbl + tree data). |
| R22 | PartitionCol | int | NO | CODE-BACKED | Partition shard value (= PositionID % 50). Returned for downstream partition-aware processing. |
| R23 | MaxRowVersion | rowversion/binary | YES | CODE-BACKED | RowVersionPosition aliased as MaxRowVersion. Used for change-detection in sync pipelines. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PartitionCol + @InitialPositionID | Trade.Position | Direct query | Partition-scoped paginated SELECT |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Data synchronization pipelines | N/A | CALLER | Iterates partitions to extract open position bulk data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOpenPositionsFromTimestamp (procedure)
└── Trade.Position (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT with PartitionCol, PositionID cursor, timestamp filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Data synchronization services | External | Bulk extraction of open positions by partition |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Hint:** Uses `NOLOCK` for maximum read throughput. Suitable for sync/replication use cases where eventual consistency is acceptable.

---

## 8. Sample Queries

### 8.1 First page of partition 0
```sql
EXEC Trade.GetOpenPositionsFromTimestamp
    @BulkSize = 1000,
    @PartitionCol = 0,
    @InitialPositionID = 0,
    @MaximumTimestampThreshold = '2026-01-01 00:00:00'
```

### 8.2 Iterate all partitions to get all open positions
```sql
-- Pseudocode pattern for caller:
-- FOR @p = 0 TO 49:
--   @cursor = 0
--   WHILE TRUE:
--     rows = EXEC GetOpenPositionsFromTimestamp @BulkSize=1000, @PartitionCol=@p, @InitialPositionID=@cursor, @MaximumTimestampThreshold=@threshold
--     process(rows)
--     IF rows.count < 1000: BREAK
--     @cursor = rows.last.PositionID
```

### 8.3 Get positions for a specific instrument on partition 5
```sql
EXEC Trade.GetOpenPositionsFromTimestamp
    @BulkSize = 500,
    @PartitionCol = 5,
    @InitialPositionID = 0,
    @MaximumTimestampThreshold = '2026-03-01 00:00:00',
    @InstrumentID = 1234
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOpenPositionsFromTimestamp | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOpenPositionsFromTimestamp.sql*
