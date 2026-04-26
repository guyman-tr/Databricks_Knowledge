# Lineage: BI_DB_dbo.BI_DB_Capital_Guarantee

**Generated:** 2026-04-21 | **Writer SP:** SP_Capital_Guarantee | **Pattern:** DELETE WHERE Date=@date + INSERT

## ETL Pipeline

```
Fact_CustomerAction (ActionTypeID=15, DateID 20200201–20210201)
  JOIN Dim_Mirror ON MirrorID — ParentCID IN (4657429,4657433,4657444)
  |── #Mirror (MirrorIDs of excluded popular-investor cohort mirrors)
  |
DWH_dbo.Dim_Position (dp) — all open/closed positions
  JOIN BI_DB_dbo.BI_DB_CIDFirstDates (fd) ON CID — to get RegulationID
  JOIN DWH_dbo.Dim_Regulation (dr) ON RegulationID → Name
  JOIN DWH_dbo.Dim_Mirror (dm) ON MirrorID — ParentCID IN (4657429,4657433,4657444)
  LEFT JOIN BI_DB_dbo.BI_DB_PositionPnL (pp) ON PositionID AND DateID — current open P&L
  LEFT JOIN #Mirror (tt) ON MirrorID — used to EXCLUDE specific mirrors
  WHERE dm.ParentCID IN (4657429,4657433,4657444)
    AND (dm.CloseDateID=0 OR CloseDateID > @date)
    AND dm.OpenDateID >= 20200105
    AND dm.OpenDateID <= MIN(@date, 20200131)
    AND tt.MirrorID IS NULL [exclude #Mirror cohort]
  GROUP BY CID, Regulation, MirrorID, ParentUserName
  HAVING SUM(PnL) < 0 [loss-making mirrors only — actual guarantee exposure]
    |
    v
SP_Capital_Guarantee (@date)
    |
    v
BI_DB_dbo.BI_DB_Capital_Guarantee
(DELETE WHERE Date=@date + INSERT, ~135.7K rows; last written 2023-03-12)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform |
|---|--------|-------------|--------------|-----------|
| 1 | CID | Dim_Position | CID | Passthrough — customer ID of the mirror follower |
| 2 | Date | SP parameter | @date | Passthrough — ETL run date |
| 3 | Regulation | Dim_Regulation / BI_DB_CIDFirstDates | Name / RegulationID | Resolved via fd.RegulationID → dr.Name; CIDFirstDates used as RegulationID source |
| 4 | MirrorID | Dim_Position / Dim_Mirror | MirrorID | Passthrough — the specific copy/mirror relationship ID |
| 5 | ParentUserName | Dim_Mirror | ParentUserName | Passthrough — popular investor username (GainersQtr, ActiveTraders, SharpTraders) |
| 6 | PnL | Dim_Position / BI_DB_PositionPnL | NetProfit / PositionPnL | CASE: if position in BI_DB_PositionPnL (open, DateID=@date) → PositionPnL; else → Dim_Position.NetProfit (closed). SUM per mirror group. Always negative (HAVING SUM < 0). |
| 7 | UpdateDate | SP metadata | GETDATE() | ETL run timestamp |

## Source Objects

| Object | Schema | Role |
|--------|--------|------|
| Dim_Position | DWH_dbo | Primary position source — CID, MirrorID, NetProfit for all positions in guarantee cohort |
| BI_DB_CIDFirstDates | BI_DB_dbo | RegulationID source for customer; joined on CID |
| Dim_Regulation | DWH_dbo | Regulation name resolver (RegulationID → Name) |
| Dim_Mirror | DWH_dbo | Mirror metadata — ParentCID (popular investor), ParentUserName, OpenDateID, CloseDateID |
| BI_DB_PositionPnL | BI_DB_dbo | Current open-position P&L; LEFT JOIN to get live PnL for open positions |
| Fact_CustomerAction | DWH_dbo | Used to identify excluded mirror cohort (#Mirror): ActionTypeID=15, ParentCID in guarantee list, DateID 20200201–20210201 |

## Tier Assignment Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — (no upstream production wiki available) |
| Tier 2 | 7 | All columns — SP_Capital_Guarantee code analysis |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

## UC External Lineage

UC Target: `_Not_Migrated`
