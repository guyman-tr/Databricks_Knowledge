# BI_DB_dbo.BI_DB_Mirror_Assets_Allocation — Column Lineage

## Lineage Metadata

| Property | Value |
|----------|-------|
| **Writer SP** | BI_DB_dbo.SP_rsk_AgregatedRisk |
| **Load Pattern** | Daily TRUNCATE + INSERT (full refresh) |
| **Refresh** | Daily (SB_Daily, Priority 0) |
| **UC Target** | _Not_Migrated |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|--------------|-----------|------|
| 1 | Date | BI_DB_dbo.BI_DB_PositionPnL | Date | Direct — yesterday's date | T2 |
| 2 | InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Direct via InstrumentID join | T2 |
| 3 | total_equity_copy | BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Instrument | Amount + PositionPnL | SUM(Amount+PositionPnL) for CopyTrade mirrors (AccountTypeID<>9) on yesterday | T2 |
| 4 | total_equity_copy_LW | BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Instrument | Amount + PositionPnL | Same SUM but for last week start date | T2 |
| 5 | total_equity_copy_LM | BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Instrument | Amount + PositionPnL | Same SUM but for last month start date | T2 |
| 6 | total_equity_copy_YTD | BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Instrument | Amount + PositionPnL | Same SUM but for Jan 1st of current year | T2 |
| 7 | UpdateDate | ETL | GETDATE() | Set on INSERT | T5 |
