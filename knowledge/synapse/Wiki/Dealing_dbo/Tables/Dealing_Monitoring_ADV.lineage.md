---
object: Dealing_Monitoring_ADV
lineage_type: DWH Multi-source Aggregation
production_source: DWH_dbo.Dim_Position + CopyFromLake.etoro_Hedge_ExecutionLog + BI_DB_PositionPnL
---

# Dealing_Monitoring_ADV — Lineage Map

## Data Flow

```
CopyFromLake.etoro_Hedge_ExecutionLog (IF NOT present → SP_Copy_Temporary_Data)
  │ → LP execution volume per instrument (TotalVolumeUnitsLP)
  │
DWH_dbo.Dim_Position (InstrumentTypeID IN 5,6, IsValidCustomer=1, OpenDateID=@DateID)
  │ → Client volume + NOP (TotalVolumeEtoro, Top5CIDs/PIs)
  │
BI_DB_dbo.BI_DB_PositionPnL (DateID=@DateID)
  │ → Client NOP in units (TotalNOPEtoro, Top5CIDs/PIs NOP)
  │
Market data source (ADV, MKTcap, SharesOutStanding) [source TBD]
  │
DWH_dbo.Dim_Instrument (Symbol, Exchange, InstrumentTypeID filter)
  │
  ▼
Dealing_Monitoring_ADV + Dealing_Monitoring_ADV_MoreThanPercent
(both written by SP_Monitoring_ADV)
```

## Refresh Schedule
Daily — SP_Monitoring_ADV, OpsDB Priority 0, ProcessType 1 (SQL). Active.
