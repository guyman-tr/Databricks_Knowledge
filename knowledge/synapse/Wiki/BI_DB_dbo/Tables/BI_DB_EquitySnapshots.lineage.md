# Lineage: BI_DB_dbo.BI_DB_EquitySnapshots

## Object Metadata

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Name** | BI_DB_EquitySnapshots |
| **Object Type** | Table |
| **Writer SP** | BI_DB_dbo.SP_User_Segment_Snapshot (first INSERT block) |
| **Production Source** | DWH_dbo.Fact_SnapshotEquity (via Dim_Range date filter) |
| **ETL Pattern** | Daily — DELETE WHERE Date=@Date + INSERT from Fact_SnapshotEquity JOIN Dim_Range WHERE DR.FromDateID<=@Date AND DR.ToDateID>=@Date |
| **UC Target** | _Not_Migrated |

## ETL Pipeline

```
DWH_dbo.Fact_SnapshotEquity (SE)
  |-- INNER JOIN DWH_dbo.Dim_Range (DR) ON SE.DateRangeID=DR.DateRangeID
  |   Filter: DR.ToDateID >= @Date AND DR.FromDateID <= @Date
  |   (selects the active SCD row for each CID on the given date)
  |-- SP_User_Segment_Snapshot @Yesterday
  |   Date = CONVERT(VARCHAR,@Yesterday,112) as INT
  |-- DELETE WHERE Date=@Date
  |-- INSERT (Date, CID, RealizedEquity, GETDATE())
  v
BI_DB_dbo.BI_DB_EquitySnapshots
  (13.37B rows | Jan 2013 – Apr 2026 | HASH(CID), CLUSTERED(Date,CID))

Then used as intermediate in same SP:
  BI_DB_EquitySnapshots (R)
  INNER JOIN BI_DB_STDSnapshots (C) ON R.Date=C.DateKey AND R.CID=C.CID
  WHERE RealizedEquity+PositionPnL >= 50
  → #pre2 → #ABCModel → risk model → BI_DB_User_Segment_Snapshot
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|---------------|-----------|------|
| 1 | Date | SP parameter | @Yesterday (converted to INT) | CONVERT(VARCHAR,@Yesterday,112) cast to INT | Tier 2 |
| 2 | CID | DWH_dbo.Fact_SnapshotEquity | CID | Direct passthrough; HASH distribution key | Tier 1 |
| 3 | RealizedEquity | DWH_dbo.Fact_SnapshotEquity | RealizedEquity | Direct passthrough from active SCD snapshot row | Tier 1 |
| 4 | UpdateDate | ETL | GETDATE() | SET at INSERT time | Tier 2 |

## Source Objects

| Source Object | Type | Role |
|--------------|------|------|
| DWH_dbo.Fact_SnapshotEquity | Table | Primary source — realized equity snapshots per CID |
| DWH_dbo.Dim_Range | Table | SCD date range filter — selects the active row for given date |

## UC External Lineage

UC Target: _Not_Migrated — no Unity Catalog lineage applicable.
