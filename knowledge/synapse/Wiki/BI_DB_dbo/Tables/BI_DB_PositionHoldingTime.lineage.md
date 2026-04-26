# Lineage: BI_DB_dbo.BI_DB_PositionHoldingTime

## Source Chain

| Level | Object | Type | Role |
|-------|--------|------|------|
| L0 | Trade.PositionTbl (production) | Production DB | Regular trading position events |
| L0 | Trade.Mirror (production) | Production DB | Copy trade relationship events |
| L1 | DWH_dbo.Dim_Position | DWH Dimension | Regular closed positions (MirrorID=0, CloseDateID=@DateID) |
| L1 | DWH_dbo.Dim_Instrument | DWH Dimension | InstrumentType and InstrumentID for regular positions |
| L1 | DWH_dbo.Dim_Mirror | DWH Dimension | Copy trade/portfolio closed positions (CloseDateID=@DateID) |
| L2 | BI_DB_dbo.BI_DB_PositionHoldingTime | **THIS TABLE** | Daily closed-position holding time log |

## ETL Pipeline

```
DWH_dbo.Dim_Position (MirrorID=0, CloseDateID=@DateID — direct/non-mirror positions only)
DWH_dbo.Dim_Instrument (JOIN ON InstrumentID — type and ID)
  UNION ALL
DWH_dbo.Dim_Mirror (CloseDateID=@DateID — copy trade and copy portfolio relationships)
  |-- SP_PositionHoldingTime @Date (daily, one date parameter) ---|
  |   DELETE WHERE CloseDate = @Date (upsert by day)              |
  |   INSERT via UNION ALL (regular + copy positions)             |
  v
BI_DB_dbo.BI_DB_PositionHoldingTime (368M rows, accumulating since 2022-01-01)
  |-- UC: Not Migrated ---|
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CloseDate | DWH_dbo.Dim_Position / Dim_Mirror | CloseOccurred | `CAST(CloseOccurred AS DATE)` — calendar date of position/mirror close | Tier 2 |
| 2 | CID | DWH_dbo.Dim_Position / Dim_Mirror | CID | Direct — customer who owns the position or copy relationship | Tier 1 |
| 3 | PositionID | DWH_dbo.Dim_Position (regular) / Dim_Mirror (copy) | PositionID / MirrorID | Regular positions: Dim_Position.PositionID. Copy positions: Dim_Mirror.MirrorID (not a trade position ID) | Tier 2 |
| 4 | InstrumentType | DWH_dbo.Dim_Instrument (regular) / SP literal (copy) | di.InstrumentType / MirrorTypeID | Regular: Dim_Instrument InstrumentType string. Copy: CASE WHEN MirrorTypeID=4 THEN 'Copy Portfolio' ELSE 'Copy Trade' | Tier 2 |
| 5 | InstrumentID | DWH_dbo.Dim_Instrument (regular) / Dim_Mirror (copy) | di.InstrumentID / dm.ParentCID | Regular: actual InstrumentID (FK to Dim_Instrument). Copy: ParentCID (the CID being copied) — NOT an instrument ID | Tier 2 |
| 6 | OpenDateID | DWH_dbo.Dim_Position / Dim_Mirror | OpenDateID | Direct passthrough — YYYYMMDD int of open date | Tier 2 |
| 7 | OpenOccurred | DWH_dbo.Dim_Position / Dim_Mirror | OpenOccurred | Direct passthrough — open datetime with milliseconds | Tier 1 |
| 8 | CloseDateID | DWH_dbo.Dim_Position / Dim_Mirror | CloseDateID | Direct passthrough — YYYYMMDD int of close date; 0=open, 19000101=ETL transient | Tier 2 |
| 9 | CloseOccurred | DWH_dbo.Dim_Position / Dim_Mirror | CloseOccurred | Direct passthrough — close datetime with milliseconds | Tier 1 |
| 10 | Leverage | DWH_dbo.Dim_Position / SP literal (copy) | Leverage / 0 | Regular: Dim_Position.Leverage (1–400). Copy: hardcoded 0 (copy relationships have no instrument leverage) | Tier 1 |
| 11 | Amount | DWH_dbo.Dim_Position / Dim_Mirror | Amount | Direct passthrough — position notional in USD for regular; mirror allocation amount for copy | Tier 1 |
| 12 | HoldingTime | DWH_dbo.Dim_Position / Dim_Mirror | OpenOccurred, CloseOccurred | `DATEDIFF(mi, CAST(OpenOccurred AS DATE), CAST(CloseOccurred AS DATE))` — whole-calendar-day holding in minutes (always a multiple of 1440 or 0) | Tier 2 |
| 13 | UpdateDate | SP-computed | GETDATE() | ETL run timestamp; one value per daily batch | Tier 2 |

## UC External Lineage

UC Target: Not Migrated
