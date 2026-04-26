# BI_DB_dbo.BI_DB_DailyNOP_ByInstrument — Column Lineage

## Lineage Metadata

| Property | Value |
|----------|-------|
| **Target Table** | BI_DB_dbo.BI_DB_DailyNOP_ByInstrument |
| **Writer SP** | BI_DB_dbo.SP_DailyNOP_ByInstrument |
| **Primary Sources** | BI_DB_dbo.BI_DB_PositionPnL (NOP), BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted (price) |
| **Enrichment JOINs** | DWH_dbo.Dim_Instrument (type, name), DWH_dbo.Dim_Customer (valid filter) |
| **Load Pattern** | Daily DELETE for @date + INSERT |
| **Generated** | 2026-04-26 |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | Date | SP parameter | @date | Direct assignment | Tier 2 |
| 2 | DateID | SP parameter | @dateINT | CAST(CONVERT(CHAR(8), @date, 112) AS INT) | Tier 2 |
| 3 | InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | JOIN on InstrumentID | Tier 1 |
| 4 | InstrumentID | BI_DB_dbo.BI_DB_PositionPnL + BI_DB_SpreadedPriceCandle60MinSplitted | InstrumentID | ISNULL(NOP.InstrumentID, Price.InstrumentID) via FULL OUTER JOIN | Tier 1 |
| 5 | Instrument | DWH_dbo.Dim_Instrument | InstrumentDisplayName | JOIN on InstrumentID, renamed to Instrument | Tier 1 |
| 6 | HedgeServer | BI_DB_dbo.BI_DB_PositionPnL | HedgeServerID | ISNULL(HedgeServerID, 0), renamed to HedgeServer | Tier 2 |
| 7 | NOP | BI_DB_dbo.BI_DB_PositionPnL | NOP | SUM(pp.NOP) GROUP BY InstrumentID, HedgeServerID, filtered to IsValidCustomer=1, ISNULL(NOP,0) | Tier 2 |
| 8 | LastPrice | BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted | BidLast | Latest BidLast per InstrumentID (ROW_NUMBER DESC by DateFrom), ISNULL(LastPrice,0) | Tier 2 |
| 9 | UpdateDate | SP computation | GETDATE() | ETL timestamp | Tier 5 |

## Source Objects

| Source Object | Type | Purpose |
|--------------|------|---------|
| BI_DB_dbo.BI_DB_PositionPnL | Table | NOP values per CID/InstrumentID/HedgeServerID |
| BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted | Table | Latest BidLast price per InstrumentID |
| DWH_dbo.Dim_Customer | Dimension Table | IsValidCustomer=1 filter |
| DWH_dbo.Dim_Instrument | Dimension Table | InstrumentType, InstrumentDisplayName |

## Downstream Consumers

| Consumer | Type | Usage |
|----------|------|-------|
| (none found in SSDT) | — | Risk monitoring dashboards (inferred from NOP reporting) |
