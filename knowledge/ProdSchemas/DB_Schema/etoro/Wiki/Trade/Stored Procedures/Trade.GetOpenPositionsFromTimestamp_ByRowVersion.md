# Trade.GetOpenPositionsFromTimestamp_ByRowVersion

> Returns a paginated bulk of open positions within a partition that have changed since a given row version - used for event-driven incremental synchronization of position data.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PartitionCol + @RowVersion |
| **Partition** | Trade.Position: PartitionCol = @PartitionCol (explicit) |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOpenPositionsFromTimestamp_ByRowVersion` is a variant of `GetOpenPositionsFromTimestamp` that uses a SQL Server `rowversion` (binary timestamp) instead of an InitDateTime threshold as the change-detection mechanism. It returns positions in a specific partition whose MAX row version (the greater of `RowVersionPosition` and `RowVersionTree`) is greater than the supplied `@RowVersion`.

**WHY:** Row-version-based synchronization is more reliable than timestamp-based sync because row versions are monotonically increasing system-generated values - no clock skew, no timezone issues, no missed updates due to the same-second writes. Services that need to detect every change to a position (including stop-loss/take-profit updates that change `RowVersionTree` but not `RowVersionPosition`) use this SP.

**HOW:** A `CROSS APPLY` computes `MAX(RowVersionPosition, RowVersionTree)` inline for each row. Rows where this computed max is greater than `@RowVersion` are returned, ordered ascending by `MaxRowVersion`. The caller saves the last returned `MaxRowVersion` as the next `@RowVersion` for the following call.

---

## 2. Business Logic

### 2.1 Dual RowVersion - Track Both Position and Tree Changes

**What:** A position can be modified in two ways: the position row itself (RowVersionPosition) or its tree metadata (RowVersionTree, which tracks stop-loss/take-profit changes). The SP considers both, returning rows where EITHER has changed since the last sync.

**Columns/Parameters Involved:** `@RowVersion`, `RowVersionPosition`, `RowVersionTree`, `MaxRowVersion`

**Rules:**
- `CROSS APPLY (SELECT MAX(MaxRowVersion) FROM (VALUES (RowVersionPosition),(RowVersionTree)) AS value(MaxRowVersion))` -> computes inline MAX of two rowversion columns
- `MaxRowVersion > @RowVersion` -> returns rows changed after the last seen version
- `ORDER BY MaxRowVersion ASC` -> deterministic order for incremental processing
- Caller updates `@RowVersion` to the last returned `MaxRowVersion` before the next call

### 2.2 Partition-Scoped Bulk

**What:** Same partition-scoping pattern as GetOpenPositionsFromTimestamp - processes one partition at a time.

**Rules:**
- `PartitionCol = @PartitionCol` -> single partition only
- `SELECT TOP (@BulkSize)` -> page size cap
- No PositionID cursor needed - ordering by MaxRowVersion provides implicit cursor via the RowVersion comparison

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BulkSize | int | NO | - | CODE-BACKED | Page size: maximum rows per call. If returned rows < BulkSize, end of changed records for this partition/version. |
| 2 | @RowVersion | RowVersion | NO | - | CODE-BACKED | Change-detection cursor. Returns only positions where MAX(RowVersionPosition, RowVersionTree) > this value. Caller saves and advances this cursor. |
| 3 | @PartitionCol | integer | NO | - | CODE-BACKED | Partition shard: must be 0-49. Scopes query to a single position partition. |

**Return Columns:**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| R1 | PositionID | bigint | NO | CODE-BACKED | Primary key of the position. |
| R2 | InstrumentID | int | NO | CODE-BACKED | Financial instrument. |
| R3 | CID | int | NO | CODE-BACKED | Customer owning the position. |
| R4 | HedgeServerID | int | YES | CODE-BACKED | Hedge server for this position. |
| R5 | Occurred | datetime | YES | CODE-BACKED | Creation timestamp. |
| R6 | InitDateTime | datetime | NO | CODE-BACKED | Position open timestamp. |
| R7 | Amount | money | NO | CODE-BACKED | Position amount in account currency. |
| R8 | AmountInUnitsDecimal | decimal | NO | CODE-BACKED | Position size in instrument units. |
| R9 | InitForexRate | money | NO | CODE-BACKED | Entry rate. |
| R10 | IsBuy | bit | NO | CODE-BACKED | Direction: 1=long, 0=short. |
| R11 | IsComputeForHedge | bit | NO | CODE-BACKED | Whether hedge engine tracks this position. |
| R12 | IsSettled | bit | YES | CODE-BACKED | Stock settlement flag. |
| R13 | Leverage | smallint | NO | CODE-BACKED | Leverage multiplier. |
| R14 | MirrorID | int | YES | CODE-BACKED | Copy relationship ID. |
| R15 | LimitRate | money | YES | CODE-BACKED | Take-profit rate. |
| R16 | StopRate | money | YES | CODE-BACKED | Stop-loss rate. |
| R17 | UnitMargin | money | NO | CODE-BACKED | Margin per unit. |
| R18 | SpreadedCommission | money | YES | CODE-BACKED | Spread-based commission. |
| R19 | Commission | money | YES | CODE-BACKED | Commission charged. |
| R20 | FullCommission | money | YES | CODE-BACKED | Total commission. |
| R21 | NetProfit | money | YES | CODE-BACKED | Running net profit. |
| R22 | PartitionCol | int | NO | CODE-BACKED | Partition shard value. |
| R23 | MaxRowVersion | rowversion/binary | NO | CODE-BACKED | MAX(RowVersionPosition, RowVersionTree). Use as next @RowVersion cursor. Ordered ascending. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PartitionCol + @RowVersion | Trade.Position | Direct query | Partition-scoped row-version filtered SELECT |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Incremental sync services | N/A | CALLER | Polls for position changes since last known row version |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOpenPositionsFromTimestamp_ByRowVersion (procedure)
└── Trade.Position (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT with PartitionCol filter and CROSS APPLY RowVersion max computation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Incremental data sync services | External | Change detection for open position state updates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Note:** `RowVersion` type in SQL Server is a monotonically increasing database-wide counter, guaranteed unique per modification. Comparing row versions works correctly across sessions and servers without clock synchronization concerns.

**Note:** `CROSS APPLY (SELECT MAX(...) FROM (VALUES (...),(...))`  is a SQL Server pattern for computing MAX across multiple columns of the same row.

---

## 8. Sample Queries

### 8.1 Get all changed positions in partition 0 since a rowversion
```sql
EXEC Trade.GetOpenPositionsFromTimestamp_ByRowVersion
    @BulkSize = 1000,
    @RowVersion = 0x00000000001F4A3B,
    @PartitionCol = 0
```

### 8.2 Initial load - get all positions in partition (RowVersion = 0)
```sql
EXEC Trade.GetOpenPositionsFromTimestamp_ByRowVersion
    @BulkSize = 1000,
    @RowVersion = 0x0000000000000000,
    @PartitionCol = 0
```

### 8.3 Manual equivalent - check changed positions
```sql
SELECT TOP 1000
       PositionID, MaxRowVersion
FROM   Trade.Position WITH (NOLOCK)
       CROSS APPLY (
           SELECT MAX(v) AS MaxRowVersion
           FROM   (VALUES (RowVersionPosition),(RowVersionTree)) AS t(v)
       ) AS rv
WHERE  PartitionCol = 0
AND    MaxRowVersion > 0x00000000001F4A3B
ORDER  BY MaxRowVersion ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOpenPositionsFromTimestamp_ByRowVersion | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOpenPositionsFromTimestamp_ByRowVersion.sql*
