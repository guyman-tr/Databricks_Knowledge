# Column Lineage: BI_DB_dbo.BI_DB_Transactions_Per_Time_Unit

**Generated**: 2026-04-22
**Writer SP**: `BI_DB_dbo.SP_Transactions_Per_Time_Unit`
**ETL Pattern**: DELETE WHERE Date=@Date + INSERT (daily idempotent)
**Immediate Sources**: `DWH_dbo.Dim_Position` (opens + closes), `DWH_dbo.Dim_Customer` (customer base count)
**Root Sources**: `etoro_Trade_OpenPositionEndOfDay` (via Dim_Position), `etoro_Customer/BackOffice` (via Dim_Customer)

## ETL Pipeline

```
DWH_dbo.Dim_Position (dp) + DWH_dbo.Dim_Instrument (di)
  |-- #op: WHERE OpenDateID=@DateINT AND IsAirDrop=0 (all positions opened on @Date) --|
  |-- #cp: WHERE CloseDateID=@DateINT AND ClosePositionReasonID!=10 (all positions closed on @Date) --|
  (+ DWH_dbo.Fact_SnapshotCustomer + Dim_Range for SCD2 close-date resolution in #cp)
  |-- #unioned: UNION of #op + #cp (position-grain, opens + closes) --|
  v
  #daily: COUNT(PositionID), COUNT(DISTINCT CID) for the day
  #hourly: TOP 1 hour by COUNT(PositionID) DESC
  #minutely: TOP 1 hour+minute by COUNT(PositionID) DESC
  #secondly: TOP 1 hour+minute+second by COUNT(PositionID) DESC
  |-- JOIN all four temp tables + Dim_Customer subquery → #final --|
  v
BI_DB_dbo.BI_DB_Transactions_Per_Time_Unit
  (1 row/date — daily peak throughput summary)
  |-- (UC: Not Migrated) --|
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | Date | ETL runtime | @Date parameter | Reporting date passthrough | Tier 2 — SP_Transactions_Per_Time_Unit |
| 2 | Daily | Dim_Position | PositionID | COUNT(PositionID) across all opens+closes on @Date (UNION deduplication applied) | Tier 2 — SP_Transactions_Per_Time_Unit |
| 3 | Hour | Dim_Position | OpenOccurred / CloseOccurred | DATEPART(HOUR, ...) of the peak-volume hour (TOP 1 by transaction count DESC) | Tier 2 — SP_Transactions_Per_Time_Unit |
| 4 | Hourly | Dim_Position | PositionID | COUNT(PositionID) within peak hour | Tier 2 — SP_Transactions_Per_Time_Unit |
| 5 | Minute | Dim_Position | OpenOccurred / CloseOccurred | DATEPART(MINUTE, ...) of the peak-volume minute within peak hour (TOP 1) | Tier 2 — SP_Transactions_Per_Time_Unit |
| 6 | Minutely | Dim_Position | PositionID | COUNT(PositionID) within peak hour+minute | Tier 2 — SP_Transactions_Per_Time_Unit |
| 7 | Second | Dim_Position | OpenOccurred / CloseOccurred | DATEPART(SECOND, ...) of the peak-volume second within peak hour+minute (TOP 1) | Tier 2 — SP_Transactions_Per_Time_Unit |
| 8 | Secondly | Dim_Position | PositionID | COUNT(PositionID) within peak hour+minute+second | Tier 2 — SP_Transactions_Per_Time_Unit |
| 9 | CID_Daily | Dim_Position | CID | COUNT(DISTINCT CID) across all opens+closes on @Date | Tier 2 — SP_Transactions_Per_Time_Unit |
| 10 | CID_Hourly | Dim_Position | CID | COUNT(DISTINCT CID) within peak hour | Tier 2 — SP_Transactions_Per_Time_Unit |
| 11 | CID_Minutely | Dim_Position | CID | COUNT(DISTINCT CID) within peak hour+minute | Tier 2 — SP_Transactions_Per_Time_Unit |
| 12 | CID_Secondly | Dim_Position | CID | COUNT(DISTINCT CID) within peak hour+minute+second | Tier 2 — SP_Transactions_Per_Time_Unit |
| 13 | Customers_Cnt | Dim_Customer | RealCID | Subquery: COUNT(DISTINCT RealCID) WHERE IsValidCustomer=1 AND IsDepositor=1 AND VerificationLevelID=3; total fully-verified depositor base on ETL run day | Tier 2 — SP_Transactions_Per_Time_Unit |
| 14 | UpdateDate | ETL runtime | GETDATE() | ETL execution timestamp | Tier 2 — SP_Transactions_Per_Time_Unit |
