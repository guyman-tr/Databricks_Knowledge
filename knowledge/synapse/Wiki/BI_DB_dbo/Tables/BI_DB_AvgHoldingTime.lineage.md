# BI_DB_dbo.BI_DB_AvgHoldingTime — Column Lineage

> Generated: 2026-04-21 | Pipeline Phase: 10B | Writer SP: SP_AvgHoldingTime

## ETL Chain

```
DWH_dbo.Dim_Position (OpenOccurred, CloseOccurred, OpenDateID, CloseDateID, InstrumentID, Leverage, MirrorID, IsPartialCloseChild)
DWH_dbo.Dim_Instrument (InstrumentID, InstrumentType, InstrumentTypeID)
DWH_dbo.Dim_Customer (RealCID, IsValidCustomer, IsDepositor)
DWH_dbo.V_Liabilities (CID, Liabilities, ActualNWA, DateID — equity > $50 filter)
DWH_dbo.Dim_Mirror (CID, OpenOccurred, CloseOccurred, OpenDateID, CloseDateID, MirrorTypeID)
  |
  |-- SP_AvgHoldingTime(@date) — runs ONLY on day 2 of each month ---|
  |   #Days_open1/#Days_open: open direct positions (equity>$50) in 3-month window
  |   #Days_close: closed direct positions in trailing 3-month window
  |   #Days = UNION open + close (instrument positions)
  |   #CopyOpen/#CopyClose: mirror (copy) relationships
  |   #copy = UNION copy open + close
  |   #Groups: AVG(minutes→days) by InstrumentTypeID → Stocks/ETF,Indices/Crypto
  |   #Groups_copy: AVG(minutes→days) by MirrorTypeID → Copy Trading/Copy Portfolio
  |   DELETE for CloseDateID + INSERT
  v
BI_DB_dbo.BI_DB_AvgHoldingTime (300 rows, monthly, Apr 2021–Mar 2026)
  |
  |-- UC Target: _Not_Migrated (not in Generic Pipeline mapping)
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | CloseDateID | Computed | @EndDate (last day of previous month) | CAST(CONVERT(CHAR(8), @EndDate, 112) AS INT) → YYYYMMDD int | Tier 2 — SP_AvgHoldingTime |
| 2 | Groups | Computed | InstrumentTypeID / MirrorTypeID | CASE: 5=Stocks, 4/6=ETF,Indices, 10=Crypto, MirrorType 1/2=Copy Trading, 4=Copy Portfolio | Tier 2 — SP_AvgHoldingTime |
| 3 | AvgHoldingTime | DWH_dbo.Dim_Position + Dim_Mirror | OpenOccurred, CloseOccurred | AVG(DATEDIFF(minutes, Open, Close) / 60 / 24) → integer days | Tier 2 — SP_AvgHoldingTime |
| 4 | UpdateDate | ETL system | GETDATE() | ETL timestamp at INSERT | Tier 2 — SP_AvgHoldingTime |
| 5 | CloseDate | Computed | @EndDate | Last day of previous month (datetime) | Tier 2 — SP_AvgHoldingTime |

## Population Eligibility Filters

| Filter | Value |
|--------|-------|
| IsValidCustomer | = 1 |
| IsDepositor | = 1 |
| Equity (Liabilities + ActualNWA) | > $50 (open positions only) |
| Leverage | < 3 |
| MirrorID | = 0 (direct positions, not copy positions) |
| InstrumentTypeID | IN (4=ETF, 5=Stocks, 6=Indices, 10=Crypto) |
| IsPartialCloseChild | = 0 |
| MirrorTypeID | IN (1=Regular, 2=CopyMe, 4=Fund) for copy track |

## UC External Lineage

| UC Target | `_Not_Migrated` (not in Generic Pipeline mapping) |
|-----------|---|
