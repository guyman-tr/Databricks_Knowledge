# BI_DB_dbo.BI_DB_STDSnapshots

**Schema**: BI_DB_dbo | **Type**: Table | **Batch**: 34 | **Generated**: 2026-04-22

| Property | Value |
|---|---|
| **Writer SP** | `BI_DB_dbo.SP_User_Segment_Snapshot` |
| **Frequency** | Daily (SB_Daily) |
| **Priority** | P20 |
| **Distribution** | HASH(CID) |
| **Clustered Index** | (CID ASC, DateKey ASC) |
| **Grain** | CID × DateKey — one row per customer per calendar day |
| **Date Range** | 20130101 – 20260412 |
| **Rows/Date (recent)** | ~2.7 M |
| **ETL Pattern** | DELETE WHERE DateKey=@Date + INSERT |

---

## 1. Business Meaning

Daily snapshot of each customer's open-position unrealized profit/loss and market price volatility (StandardDeviation) for all open positions held on that date. The table is sourced directly from `DWH_dbo.Fact_CustomerUnrealized_PnL` and functions as an **intermediate staging layer** within the customer segmentation pipeline.

Its sole consumer is `SP_User_Segment_Snapshot`, which joins STDSnapshots with `BI_DB_EquitySnapshots` to compute an equity-weighted average standard deviation (AvgSTD) per customer — a continuous volatility risk score that is then bucketed into a 10-tier **RiskIndex** written to `BI_DB_User_Segment_Snapshot`.

The table is not directly exposed to BI or reporting tools. It exists to decouple the DWH source read from the downstream segmentation logic and to provide a performant, daily-granular intermediate dataset distributed by customer hash.

---

## 2. Business Logic

### ETL Population

```sql
-- Daily pattern (SP_User_Segment_Snapshot, @Date parameter)
DELETE FROM BI_DB_dbo.BI_DB_STDSnapshots WHERE DateKey = @Date;

INSERT INTO BI_DB_dbo.BI_DB_STDSnapshots (CID, DateKey, PositionPnL, StandardDeviation, UpdateDate)
SELECT
    A.CID,
    A.DateModified,        -- renamed to DateKey
    A.PositionPnL,
    A.StandardDeviation,
    GETDATE()
FROM DWH_dbo.Fact_CustomerUnrealized_PnL A
WHERE StandardDeviation >= 0
  AND DateModified = @Date;
```

The `StandardDeviation >= 0` filter excludes invalid/negative volatility values from the source. Rows with StandardDeviation = 0 (zero-volatility positions) are retained.

### Downstream Risk Segmentation Chain

After population, SP_User_Segment_Snapshot uses STDSnapshots in a multi-step aggregation:

```sql
-- Step 1: join with BI_DB_EquitySnapshots on CID + DateKey → #pre2
SELECT s.CID, s.DateKey, e.RealizedEquity, s.StandardDeviation
INTO #pre2
FROM BI_DB_dbo.BI_DB_STDSnapshots s
JOIN BI_DB_dbo.BI_DB_EquitySnapshots e ON s.CID = e.CID AND s.DateKey = e.DateKey

-- Step 2: equity-weighted average standard deviation per CID → #ABCModel
SELECT CID, SUM(RealizedEquity * StandardDeviation) / SUM(RealizedEquity) AS AvgSTD
INTO #ABCModel FROM #pre2 GROUP BY CID

-- Step 3: map AvgSTD to RiskIndex 1-10 → #ABCModelCID
-- Thresholds: AvgSTD < 0.0011 → 1 (lowest) ... AvgSTD >= 0.0475 → 10 (highest)
```

The resulting RiskIndex is written to `BI_DB_User_Segment_Snapshot`.

---

## 3. Query Advisory

| Concern | Guidance |
|---|---|
| **Always filter by DateKey** | Table holds the full history (~4.75B rows total). Without a DateKey predicate, full scan required. |
| **CID predicates are efficient** | HASH(CID) distribution routes CID-filtered queries to a single node. |
| **Clustered index optimal pattern** | CID + DateKey range scans use the clustered index. Avoid ordering by non-clustered columns. |
| **Use COUNT_BIG(\*)** | Row count exceeds INT range (>2.1B). `COUNT(*)` raises arithmetic overflow. |
| **StandardDeviation is FLOAT NULL** | Use `IS NOT NULL` or `ISNULL(StandardDeviation, 0)` in aggregations to avoid NULL propagation. |
| **PositionPnL precision** | DECIMAL(16,2) — supports very large PnL values but truncates sub-cent precision. |

---

## 4. Elements

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 1 | CID | INT | NOT NULL | T2 | Customer identifier. Hash distribution key; links to DWH customer dimension. Sourced from `Fact_CustomerUnrealized_PnL.CID`. |
| 2 | DateKey | INT | NOT NULL | T2 | Calendar date in YYYYMMDD integer format. Corresponds to `Fact_CustomerUnrealized_PnL.DateModified`. Used as the partition/delete key in the daily ETL cycle. |
| 3 | PositionPnL | DECIMAL(16,2) | NOT NULL | T2 | Aggregate unrealized profit/loss across all open positions for this customer on this date. Can be positive (profit) or negative (loss). Sourced directly from `Fact_CustomerUnrealized_PnL.PositionPnL`. |
| 4 | StandardDeviation | FLOAT | NULL | T2 | Market price volatility measure for the customer's open positions on this date. Used as the primary risk signal: after equity-weighting against `BI_DB_EquitySnapshots`, produces `AvgSTD` which maps to RiskIndex 1–10. Only non-negative values are loaded (WHERE StandardDeviation >= 0). |
| 5 | UpdateDate | DATETIME | NULL | T2 | ETL execution timestamp (GETDATE() at time of INSERT). Not sourced from upstream data. |

---

## 5. Lineage

**Writer SP**: `BI_DB_dbo.SP_User_Segment_Snapshot`
**Root Source**: `DWH_dbo.Fact_CustomerUnrealized_PnL`

```
DWH_dbo.Fact_CustomerUnrealized_PnL
  (CID, DateModified, PositionPnL, StandardDeviation)
  |-- SP_User_Segment_Snapshot: filter StandardDeviation >= 0 --|
  v
BI_DB_dbo.BI_DB_STDSnapshots
  (CID, DateKey, PositionPnL, StandardDeviation, UpdateDate)
  |-- JOIN with BI_DB_EquitySnapshots → equity-weighted AvgSTD → RiskIndex 1-10 --|
  v
BI_DB_dbo.BI_DB_User_Segment_Snapshot
```

See `BI_DB_STDSnapshots.lineage.md` for full column-level lineage table.

---

## 6. Relationships

| Relationship | Object | Join / Notes |
|---|---|---|
| **Source** | `DWH_dbo.Fact_CustomerUnrealized_PnL` | CID + DateModified; daily snapshot of unrealized PnL and volatility |
| **Sibling (same writer)** | `BI_DB_dbo.BI_DB_EquitySnapshots` | Both written by SP_User_Segment_Snapshot; joined on CID + DateKey in downstream logic |
| **Sibling (same writer)** | `BI_DB_dbo.BI_DB_DepositSnapshots` | Written in same SP execution; not joined with STDSnapshots |
| **Downstream consumer** | `BI_DB_dbo.BI_DB_User_Segment_Snapshot` | STDSnapshots feeds RiskIndex via AvgSTD computation; indirect via temp tables |

---

## 7. Sample Queries

```sql
-- Latest snapshot for a specific customer
SELECT CID, DateKey, PositionPnL, StandardDeviation
FROM BI_DB_dbo.BI_DB_STDSnapshots
WHERE CID = 12345
  AND DateKey = 20260412;

-- Equity-weighted average volatility per customer (mirrors SP logic)
SELECT s.CID,
       SUM(e.RealizedEquity * s.StandardDeviation) / NULLIF(SUM(e.RealizedEquity), 0) AS AvgSTD
FROM BI_DB_dbo.BI_DB_STDSnapshots s
JOIN BI_DB_dbo.BI_DB_EquitySnapshots e ON s.CID = e.CID AND s.DateKey = e.DateKey
WHERE s.DateKey = 20260412
  AND s.StandardDeviation IS NOT NULL
GROUP BY s.CID;

-- Row count for a specific date (use COUNT_BIG to avoid INT overflow)
SELECT COUNT_BIG(*) AS row_count
FROM BI_DB_dbo.BI_DB_STDSnapshots
WHERE DateKey = 20260412;
```

---

## 8. Atlassian

No Confluence page found for this table. It is an internal staging table within the customer segmentation pipeline and is unlikely to have dedicated business documentation. See the Confluence page for `BI_DB_User_Segment_Snapshot` (the final output table) for business context on customer risk and activity segmentation.
