# Lineage: DWH_dbo.Fact_Settlement_Prices

> Column-level lineage from end-of-day price feed to DWH Synapse table.

## Source Chain

```
Exchange/Clearing House EOD Feed
  -> DWH_staging.EndOfDay_EOD_SettlementPrices
  -> SP_Fact_Settlement_Prices(@dt)
  -> DWH_dbo.Fact_Settlement_Prices
```

## Generic Pipeline Mapping

Not found in _generic_pipeline_mapping.json.

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Notes |
|---|-----------|---------------|---------------|-----------|-------|
| 1 | InstrumentID | EndOfDay_EOD_SettlementPrices | InstrumentID | Passthrough | FK to Dim_Instrument |
| 2 | SettlementDateID | ETL-computed | Date | CONVERT(INT,CONVERT(VARCHAR,DATEADD(DAY,DATEDIFF(DAY,0,Date),0),112)) | YYYYMMDD int |
| 3 | SettlementDate | EndOfDay_EOD_SettlementPrices | Date | Renamed to SettlementDate | |
| 4 | SettlementPrice | EndOfDay_EOD_SettlementPrices | Price | Renamed to SettlementPrice | decimal(38,18) |
| 5 | UpdateDate | ETL-computed | N/A | GETDATE() | ETL load timestamp |

## ETL SP Details

**SP**: DWH_dbo.SP_Fact_Settlement_Prices
**Author**: Inbal BML (2024-10-31)
**Pattern**: Per-date incremental (DELETE for SettlementDate + INSERT)
