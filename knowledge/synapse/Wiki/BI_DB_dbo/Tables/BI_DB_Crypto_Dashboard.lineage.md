# BI_DB_dbo.BI_DB_Crypto_Dashboard — Column Lineage

**Generated**: 2026-04-21 | **Writer SP**: SP_CryptoDashboard | **Batch**: 20

## Summary

Daily DELETE+INSERT crypto trading dashboard aggregated at Date × Regulation × Country × BuyCurrency × Real/CFD × Manual/Copy grain.
Crypto = InstrumentTypeID=10. Population = Fact_SnapshotCustomer IsValidCustomer=1, IsDepositor=1, PlayerLevelID≠4 at @date.
Sources: DWH_dbo.Fact_SnapshotCustomer (population), DWH_dbo.Dim_Position (open positions), BI_DB_dbo.BI_DB_PositionPnL (PnL/AUA),
DWH_dbo.Fact_CustomerAction (commissions, first actions), DWH_dbo.Fact_FirstCustomerAction (FA),
DWH_dbo.Dim_Date (date calendar fields).

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | Date | @date parameter | — | Direct assignment of SP input parameter (the reporting date). | Tier 2 — SP_CryptoDashboard |
| 2 | DateID | @date parameter | — | CONVERT(CHAR(8),@date,112) — YYYYMMDD int. Clustering key. | Tier 2 — SP_CryptoDashboard |
| 3 | DayName | DWH_dbo.Dim_Date | DayName | dd.DayName via LEFT JOIN Dim_Date ON DateKey=@dateID. | Tier 3 — DWH_dbo.Dim_Date |
| 4 | SSWeekNumberOfMonth | DWH_dbo.Dim_Date | SSWeekNumberOfMonth | dd.SSWeekNumberOfMonth — eToro fiscal week-of-month numbering. | Tier 3 — DWH_dbo.Dim_Date |
| 5 | YearWeek | DWH_dbo.Dim_Date | SSWeekNumberOfYear | YEAR(@date)*100 + dd.SSWeekNumberOfYear — composite YYYYWW int. | Tier 2 — SP_CryptoDashboard |
| 6 | DayNumberOfWeek_Sun_Start | DWH_dbo.Dim_Date | DayNumberOfWeek_Sun_Start | dd.DayNumberOfWeek_Sun_Start — day number 1=Sun, 7=Sat. | Tier 3 — DWH_dbo.Dim_Date |
| 7 | WeekofMonth | DWH_dbo.Dim_Date | SSWeekNumberOfMonth | YEAR*10000 + MONTH*100 + SSWeekNumberOfMonth — composite int for week-of-month slicing. | Tier 2 — SP_CryptoDashboard |
| 8 | IsLastDayOfMonth | DWH_dbo.Dim_Date | IsLastDayOfMonth | dd.IsLastDayOfMonth — 'Y'/'N' flag. | Tier 3 — DWH_dbo.Dim_Date |
| 9 | Regulation | DWH_dbo.Dim_Regulation | Name | dr1.Name AS Regulation — regulatory entity name via Fact_SnapshotCustomer.RegulationID = Dim_Regulation.DWHRegulationID. | Tier 2 — SP_CryptoDashboard |
| 10 | Country | DWH_dbo.Dim_Country | Name | dc.Name AS Country — full country name via Fact_SnapshotCustomer.CountryID = Dim_Country.CountryID. | Tier 1 — Dictionary.Country |
| 11 | BuyCurrency | DWH_dbo.Dim_Instrument | BuyCurrency | di.BuyCurrency — crypto ticker symbol (BTC, ETH, ADA, XRP, SOL, DOGE, etc.) for InstrumentTypeID=10. | Tier 2 — SP_CryptoDashboard |
| 12 | Real/CFD | DWH_dbo.Dim_Position | IsSettled | CASE WHEN IsSettled=1 THEN 'Real' ELSE 'CFD' — real (settled/purchased) vs CFD crypto. Values: 'Real', 'CFD'. | Tier 2 — SP_CryptoDashboard |
| 13 | Manual/Copy | DWH_dbo.Dim_Position | MirrorID | CASE WHEN MirrorID=0 THEN 'Manual' ELSE 'Copy' — manual trading vs copy-trading position. Values: 'Manual', 'Copy'. | Tier 2 — SP_CryptoDashboard |
| 14 | AUA | BI_DB_dbo.BI_DB_PositionPnL | Amount + PositionPnL | SUM(ppnl.Amount + ppnl.PositionPnL) — Assets Under Administration: invested amount plus unrealized PnL for open crypto positions at @dateID. | Tier 2 — SP_CryptoDashboard |
| 15 | Amount in Units | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | SUM(ppnl.AmountInUnitsDecimal) — total crypto units held (e.g., 0.224609 BTC). Split-adjusted per BI_DB_PositionPnL logic. | Tier 2 — SP_CryptoDashboard |
| 16 | PnL | BI_DB_dbo.BI_DB_PositionPnL | PositionPnL | SUM(ppnl.PositionPnL) — aggregated unrealized P&L in USD for open crypto positions at @dateID. | Tier 2 — SP_CryptoDashboard |
| 17 | Revenue | DWH_dbo.Fact_CustomerAction | FullCommissionOnClose + FullCommission + RollOver | SUM(FullTotalCommission) + SUM(RollOver) — total trading revenue = open+close commissions (ActionTypeID IN 1,2,3,4,5,6,39,40) plus rollover fees (ActionTypeID=35, IsFeeDividend=1). | Tier 2 — SP_CryptoDashboard |
| 18 | # of FA Crypto | DWH_dbo.Fact_FirstCustomerAction | — | COUNT of customers whose very first crypto action (ActionTypeID=1, FirstEver=1) occurred on @dateID. New crypto investors metric. | Tier 2 — SP_CryptoDashboard |
| 19 | FA Amount Total | DWH_dbo.Fact_FirstCustomerAction | Amount | SUM(-ffca.Amount) — invested amount for first-ever crypto positions opened on @dateID. Negated from Fact_FirstCustomerAction.Amount. | Tier 2 — SP_CryptoDashboard |
| 20 | Opened Positions | DWH_dbo.Dim_Position | — | COUNT of new crypto positions opened on @dateID (OpenDateID=@dateID, ISNULL(IsPartialCloseChild,0)=0 to exclude partial closes). | Tier 2 — SP_CryptoDashboard |
| 21 | Open Positions | BI_DB_dbo.BI_DB_PositionPnL | — | COUNT of crypto positions with PnL data on @dateID (currently open end-of-day snapshot). | Tier 2 — SP_CryptoDashboard |
| 22 | Acvtive Hold by Inst | DWH_dbo.Dim_Position | CID | COUNT(DISTINCT CID) per dimension segment (Regulation/Country/BuyCurrency/Real-CFD/Manual-Copy) from #dimposition. "Acvtive" is a persisted typo from the SP code. | Tier 2 — SP_CryptoDashboard |
| 23 | UpdateDate | — | — | GETDATE() at ETL execution time. | Tier 2 — SP_CryptoDashboard |
| 24 | Acvtive Hold | BI_DB_dbo.BI_DB_PositionPnL | CID | COUNT(DISTINCT CID) from #positionpnl grouped by DateID only — total distinct crypto holders on @date, NOT segmented by dimensions. Same value repeated across all dimension rows for a given DateID. "Acvtive" typo persisted from SP. | Tier 2 — SP_CryptoDashboard |
| 25 | Active Hold Real | BI_DB_dbo.BI_DB_PositionPnL | CID | COUNT(DISTINCT CID WHERE IsSettled=1) from #positionpnl — distinct holders of real (settled) crypto on @date. Date-level, not dimension-segmented. | Tier 2 — SP_CryptoDashboard |
| 26 | Active Hold CFD | BI_DB_dbo.BI_DB_PositionPnL | CID | COUNT(DISTINCT CID WHERE IsSettled≠1) from #positionpnl — distinct holders of crypto CFD positions on @date. Date-level, not dimension-segmented. | Tier 2 — SP_CryptoDashboard |

## ETL Pipeline

```
etoro.Trade.Instrument (InstrumentTypeID=10, crypto) → DWH_dbo.Dim_Instrument
etoro.Customer.Customer → DWH_dbo.Fact_SnapshotCustomer (population: IsValidCustomer=1, IsDepositor=1, PlayerLevelID≠4)
etoro.Trade.PositionTbl → DWH_dbo.Dim_Position (open crypto positions)
BI_DB_dbo.BI_DB_PositionPnL (daily position PnL snapshot, DateID=@dateID)
DWH_dbo.Fact_CustomerAction (ActionTypeID IN 1,2,3,4,5,6,35,39,40 — commissions+rollovers)
DWH_dbo.Fact_FirstCustomerAction (ActionTypeID=1, FirstEver=1 — first crypto opens)
DWH_dbo.Dim_Date (@dateID calendar fields)
  |-- SP_CryptoDashboard @date (DELETE WHERE DateID=@dateID + INSERT, daily, SB_Daily) ---|
  v
BI_DB_dbo.BI_DB_Crypto_Dashboard (69.3M rows, 2020-01-01 to 2026-04-12, 2,294 distinct dates)
  |-- UC Target: _Not_Migrated ---|
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 1 | Country |
| Tier 2 | 21 | Date, DateID, YearWeek, WeekofMonth, Regulation, BuyCurrency, Real/CFD, Manual/Copy, AUA, Amount in Units, PnL, Revenue, # of FA Crypto, FA Amount Total, Opened Positions, Open Positions, Acvtive Hold by Inst, UpdateDate, Acvtive Hold, Active Hold Real, Active Hold CFD |
| Tier 3 | 4 | DayName, SSWeekNumberOfMonth, DayNumberOfWeek_Sun_Start, IsLastDayOfMonth |
| Tier 4 | 0 | — |
