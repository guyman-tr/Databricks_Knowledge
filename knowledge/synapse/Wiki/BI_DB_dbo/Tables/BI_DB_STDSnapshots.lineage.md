# Column Lineage: BI_DB_dbo.BI_DB_STDSnapshots

**Generated**: 2026-04-22
**Writer SP**: `BI_DB_dbo.SP_User_Segment_Snapshot`
**ETL Pattern**: DELETE WHERE DateKey=@Date + INSERT (daily full-replace per date)
**Filter Applied**: `WHERE StandardDeviation >= 0`
**Immediate Source**: `DWH_dbo.Fact_CustomerUnrealized_PnL`
**Root Sources**: `DWH_dbo.Fact_CustomerUnrealized_PnL` (unrealized open-position PnL + volatility)

## ETL Pipeline

```
DWH_dbo.Fact_CustomerUnrealized_PnL
  (alias A — open position unrealized PnL + StandardDeviation per CID per date)
  |-- SP_User_Segment_Snapshot: DELETE WHERE DateKey=@Date + INSERT WHERE StandardDeviation>=0 --|
  v
BI_DB_dbo.BI_DB_STDSnapshots
  (~2.7M rows/date — per-CID daily volatility + PnL snapshot)
  |-- SP_User_Segment_Snapshot: JOIN with BI_DB_EquitySnapshots → #pre2 → #ABCModel (AvgSTD) → #ABCModelCID (RiskIndex 1-10) --|
  v
BI_DB_dbo.BI_DB_User_Segment_Snapshot
  (final customer segmentation: RiskIndex + ActivitySegment)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | Fact_CustomerUnrealized_PnL | CID | Direct passthrough (A.CID) | Tier 2 — SP_User_Segment_Snapshot |
| 2 | DateKey | Fact_CustomerUnrealized_PnL | DateModified | Column rename: DateModified → DateKey; YYYYMMDD integer | Tier 2 — SP_User_Segment_Snapshot |
| 3 | PositionPnL | Fact_CustomerUnrealized_PnL | PositionPnL | Direct passthrough (A.PositionPnL) | Tier 2 — SP_User_Segment_Snapshot |
| 4 | StandardDeviation | Fact_CustomerUnrealized_PnL | StandardDeviation | Passthrough with filter: WHERE StandardDeviation >= 0 excludes invalid negative volatility | Tier 2 — SP_User_Segment_Snapshot |
| 5 | UpdateDate | ETL runtime | GETDATE() | ETL execution timestamp; not from source | Tier 2 — SP_User_Segment_Snapshot |

## Downstream Usage (within SP_User_Segment_Snapshot)

```sql
-- STDSnapshots feeds the risk segmentation chain:
SELECT s.CID, s.DateKey, e.RealizedEquity, s.StandardDeviation
INTO #pre2
FROM BI_DB_STDSnapshots s
JOIN BI_DB_EquitySnapshots e ON s.CID = e.CID AND s.DateKey = e.DateKey

-- #ABCModel: equity-weighted average standard deviation per CID
SELECT CID, SUM(RealizedEquity * StandardDeviation) / SUM(RealizedEquity) AS AvgSTD
INTO #ABCModel FROM #pre2 GROUP BY CID

-- #ABCModelCID: map AvgSTD to RiskIndex 1-10
-- Thresholds: <0.0011→1, ..., >=0.0475→10
```
