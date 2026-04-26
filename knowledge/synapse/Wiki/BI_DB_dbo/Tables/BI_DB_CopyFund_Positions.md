# BI_DB_dbo.BI_DB_CopyFund_Positions

| Property | Value |
|----------|-------|
| Schema | BI_DB_dbo |
| Object | BI_DB_CopyFund_Positions |
| Type | Table |
| Rows | ~325.9M (append-mode historical, all Copy Fund positions since 2020) |
| Distribution | HASH(PositionID) |
| Index | CLUSTERED COLUMNSTORE INDEX |
| Production Source | DWH_dbo.Dim_Position + DWH_dbo.Dim_Mirror (MirrorTypeID=4) |
| Writer SP | BI_DB_dbo.SP_CopyFund_Positions |
| Refresh Cadence | Daily DELETE(OpenDateID=@dateID OR (CloseDateID=@dateID AND IsPartialCloseChild=1)) + INSERT |
| UC Target | _Not_Migrated |
| Author | Guy Manova (2025-03-07) |
| Batch | 74 |
| Documented | 2026-04-23 |

---

## 1. Business Meaning

Pre-joined denormalization of **Copy Fund positions** — positions held within Copy Portfolio mirrors (MirrorTypeID=4). The table exists to eliminate the runtime cost of joining `DWH_dbo.Dim_Position` to `DWH_dbo.Dim_Mirror` in analytical queries that need both position data and the fund leader's identity (ParentCID, ParentUserName).

**Scope**: Copy Fund positions only — `DWH_dbo.Dim_Mirror.MirrorTypeID=4`. Regular PI copy mirrors (Type 1), CopyMe (Type 2), and Social Index (Type 3) are excluded.

**Scale**: ~325.9M rows, backed by a CLUSTERED COLUMNSTORE INDEX optimized for analytical aggregation. Partitioning by position open/close date drives the daily incremental load.

**Known issue**: Rare duplicate PositionIDs can appear due to unexplained upstream behavior. A post-load dedupe step detects and resolves these by keeping `MAX(CloseDateID)` and `MAX(UpdateDate)` for the winning row.

Authored by Guy Manova (2025-03-07); bugfix for partial close children (2025-05-05); schema change for rerun-safety (2025-07-06); dedupe code added (2025-09-08).

---

## 2. Business Logic & Derivation Rules

### Load Strategy — Incremental by Position Lifecycle
Each daily run processes positions active on `@date`:
1. **Delete scope**: `OpenDateID = @dateID OR (CloseDateID = @dateID AND IsPartialCloseChild = 1)`
2. **Insert scope**: Same filter on `Dim_Position` — new positions opened on @date + partial close children closed on @date
3. Positions closed on @date that are NOT partial close children are NOT reloaded (their `CloseDateID` was written during a prior day's load)

### MirrorTypeID Filter
`WHERE MirrorTypeID = 4` in the SP — all rows in this table have `MirrorTypeID = 4` (Fund). The column is stored for query convenience but filtering on it is redundant within this table.

### Partial Close Children (`IsPartialCloseChild`)
When a position is partially closed, a "child" position is created to represent the remainder. The SP includes these children by also deleting/inserting on `CloseDateID = @dateID AND IsPartialCloseChild = 1`. This ensures the child's close event is captured correctly without reprocessing all open positions.

**Filtering guidance** (from DWH_dbo.Dim_Position wiki): Exclude `IsPartialCloseChild=1` when aggregating OPEN position metrics. Do NOT exclude on CLOSE — volume is already pro-rated in the source and excluding would cause undercounting.

### Dedupe Step
Post-INSERT, the SP checks for duplicate PositionIDs:
```
GROUP BY PositionID (HAVING COUNT > 1) → #dupes
For each duplicate: keep MAX(CloseDateID), MAX(UpdateDate)
DELETE duplicates, INSERT deduplicated version
```

### UpdateDate
`GETDATE()` at load time. In dedupe resolutions, `MAX(UpdateDate)` of the duplicate group is preserved.

---

## 3. Query Advisory

- **Always filter by OpenDateID or CloseDateID** — 325.9M rows, full scans are expensive even with COLUMNSTORE.
- **HASH(PositionID)** — equality filters on PositionID are efficient (single distribution hit).
- **MirrorTypeID is always 4** — no need to filter. Adding `WHERE MirrorTypeID = 4` is harmless but redundant.
- **CloseDateID = 0** means the position is still open. `CloseDateID = 19000101` is a Dim_Position ETL transient state (rare). Always check both values when filtering for open positions.
- **IsPartialCloseChild** is stored as `int` (0 or 1) not `bit`. Use `WHERE IsPartialCloseChild = 0` to exclude child positions.
- **COLUMNSTORE** — aggregations (SUM, COUNT, AVG) are highly optimized. Row-level lookups by PositionID are slower than on a row store.
- **Duplicate handling**: Rare duplicates are cleaned by the SP post-load. If you observe duplicates, the SP may have run partially; check UpdateDate freshness.

---

## 4. Elements

| Column | Nullable | Type | Description |
|--------|----------|------|-------------|
| PositionID | NULL | bigint | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. (Tier 1 — DWH_dbo.Dim_Position via Trade.PositionTbl) |
| CID | NULL | int | Customer ID. References Customer.Customer. (Copier's customer ID — the customer copying the Fund PI.) (Tier 1 — DWH_dbo.Dim_Position via Trade.PositionTbl) |
| MirrorID | NULL | int | FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. (All rows in this table have MirrorID > 0, MirrorTypeID = 4.) (Tier 1 — DWH_dbo.Dim_Position via Trade.PositionTbl) |
| OpenDateID | NULL | int | ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default. (Tier 1 — DWH_dbo.Dim_Position via SP_Dim_Position_DL_To_Synapse) |
| CloseDateID | NULL | int | ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. Partition column. Always include in WHERE clause. Dedupe step keeps MAX(CloseDateID) for duplicate rows. (Tier 1 — DWH_dbo.Dim_Position via SP_Dim_Position_DL_To_Synapse) |
| ParentCID | NULL | int | Leader customer ID. The user whose trades are copied (the Copy Fund PI). Trade.GetActiveCopiersForParents filters by ParentCID. (Tier 1 — DWH_dbo.Dim_Mirror via Trade.Mirror) |
| ParentUserName | NULL | varchar(500) | Leader username at mirror creation. Denormalized for display; Trade.RegisterMirror passes from caller. (Tier 1 — DWH_dbo.Dim_Mirror via Trade.Mirror) |
| MirrorTypeID | NULL | int | 1=Regular, 2=CopyMe, 3=Social Index, 4=Fund (Dictionary.MirrorType). Always 4 in this table — the SP filters WHERE MirrorTypeID=4. (Tier 1 — DWH_dbo.Dim_Mirror via Trade.Mirror) |
| UpdateDate | NULL | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Propagation) |
| IsPartialCloseChild | NULL | int | 1=this position is the child (remainder) of a partial close event. Generally filter out child positions from most metrics on OPEN when aggregating, but not all (e.g., volume is already pro-rated so excluding these is wrong). NEVER filter these out on CLOSE. (Tier 1 — DWH_dbo.Dim_Position via Trade.PositionTbl) |

---

## 5. Lineage

### 5.1 Source Objects

| Source | Usage |
|--------|-------|
| DWH_dbo.Dim_Position | Primary: PositionID, CID, MirrorID, OpenDateID, CloseDateID, IsPartialCloseChild |
| DWH_dbo.Dim_Mirror | Join target: ParentCID, ParentUserName, MirrorTypeID; filter WHERE MirrorTypeID=4 |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (positions where OpenDateID=@dateID OR (CloseDateID=@dateID AND IsPartialCloseChild=1))
  |
  JOIN DWH_dbo.Dim_Mirror (WHERE MirrorTypeID=4 — Copy Fund mirrors only)
  |
  v
SP_CopyFund_Positions — DELETE(OpenDateID=@dateID OR matching partial close) + INSERT
  |
  +--> Post-load dedupe: detect duplicates → keep MAX(CloseDateID, UpdateDate)
  |
  v
BI_DB_dbo.BI_DB_CopyFund_Positions (~325.9M rows, HASH(PositionID), COLUMNSTORE)
  |
  v
UC Target: _Not_Migrated (not in Generic Pipeline)
```

---

## 6. Relationships & Cross-References

| Related Object | Relationship |
|----------------|-------------|
| DWH_dbo.Dim_Position | Primary source. This table is a filtered (MirrorTypeID=4) pre-joined projection of Dim_Position. |
| DWH_dbo.Dim_Mirror | Secondary source for ParentCID, ParentUserName, MirrorTypeID. |
| BI_DB_dbo.BI_DB_CopyDailyData | Sibling table in the Copy domain. CopyDailyData aggregates copier metrics per PI per day; this table is the position-level detail backing those aggregates. |

---

## 7. Sample Queries

```sql
-- Open Copy Fund positions for a specific fund PI
SELECT PositionID, CID, MirrorID, OpenDateID
FROM [BI_DB_dbo].[BI_DB_CopyFund_Positions]
WHERE ParentCID = 12345
  AND CloseDateID = 0          -- open positions only
  AND IsPartialCloseChild = 0  -- exclude partial close children
ORDER BY OpenDateID DESC;

-- Positions opened on a specific date (efficient: uses HASH(PositionID) indirectly via OpenDateID scan)
SELECT COUNT(*) AS NewPositions, COUNT(DISTINCT CID) AS UniqueCopiers
FROM [BI_DB_dbo].[BI_DB_CopyFund_Positions]
WHERE OpenDateID = 20260401;

-- Positions closed on a specific date (include partial close children)
SELECT PositionID, CID, ParentCID, ParentUserName, OpenDateID, CloseDateID, IsPartialCloseChild
FROM [BI_DB_dbo].[BI_DB_CopyFund_Positions]
WHERE CloseDateID = 20260401
ORDER BY IsPartialCloseChild, PositionID;

-- Check for unexpected duplicates (should return 0 rows post-load)
SELECT PositionID, COUNT(*) AS cnt
FROM [BI_DB_dbo].[BI_DB_CopyFund_Positions]
GROUP BY PositionID
HAVING COUNT(*) > 1;
```

---

## 8. Atlassian Sources

No Confluence pages identified for this object. Contact Guy Manova (original author) or the Data Platform team for Copy Fund infrastructure documentation.
