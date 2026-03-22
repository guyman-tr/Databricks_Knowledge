# Column Lineage: Dealing_dbo.Dealing_NOP_LPandClients

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_NOP_LPandClients` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Sources** | `BI_DB_dbo.BI_DB_PositionPnL` (Clients), `Dealing_staging.etoro_History_Netting_History` / `etoro_Hedge_Netting` (LP) |
| **ETL SP** | `Dealing_dbo.SP_NOP_LPandClients` |
| **Secondary Sources** | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Position`, `DWH_dbo.Dim_Customer`, `BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
LP path:
  etoro_History_Netting_History ──┐
  etoro_Hedge_Netting ────────────┤──► #hedge ──► #hedge1 (dedup) ──► #LP (NOP calc) ──┐
  BI_DB_SpreadedPriceCandle60MinSplitted ──► #Prices (latest EOD prices)                ├──► #Final ──► Dealing_NOP_LPandClients
  Dim_Instrument ──────────────────────────────────────────────────────────────────────┤
                                                                                       │
Client path:                                                                           │
  BI_DB_PositionPnL ──────┐                                                            │
  Dim_Instrument ─────────┤──► #Clients (agg by instrument+direction+TranType) ────────┘
  Dim_Position ───────────┤
  Dim_Customer ───────────┘
```

## Column Lineage

| DWH Column | Source (LP path) | Source (Client path) | Transform | Computation Formula |
|-----------|-----------------|---------------------|-----------|---------------------|
| HedgeServerID | etoro netting → HedgeServerID | BI_DB_PositionPnL.HedgeServerID | passthrough | Direct from source |
| InstrumentType | Dim_Instrument.InstrumentType | Dim_Instrument.InstrumentType | join-enriched | Via InstrumentID JOIN |
| InstrumentID | etoro netting → InstrumentID | BI_DB_PositionPnL.InstrumentID | passthrough | Direct from source |
| Instrument | Dim_Instrument.Name | Dim_Instrument.Name | join-enriched | Instrument display name |
| IsBuy | etoro netting → IsBuy | BI_DB_PositionPnL.IsBuy | passthrough | Direction flag |
| TranType | — | — | ETL-computed | LP: hardcoded `'LP'`. Clients: `CASE WHEN IsComputeForHedge=0 THEN 'IsComputeForHedge=0' WHEN LabelID=30 THEN 'LabelID=30' ELSE 'Clients' END` |
| NOP_Units | etoro netting | BI_DB_PositionPnL | ETL-computed | LP: `Units*(2*IsBuy-1)`. Clients: `SUM(AmountInUnitsDecimal*(2*IsBuy-1))` |
| NOP | etoro netting + Prices | BI_DB_PositionPnL | ETL-computed | LP: `Units*Price*(2*IsBuy-1)*FX_rate` (multi-step USD conversion). Clients: `SUM(NOP)` |
| DateID | — | — | ETL-computed | `Dealing_dbo.DateToDateID(@Date)` |
| Date | — | — | ETL-computed | `@Date` SP parameter |
| UpdateDate | — | — | ETL-computed | `GETDATE()` |
| LiquidityAccountID | etoro netting | — | passthrough/NULL | LP: from netting. Clients: NULL |

## Summary

| Category | Count |
|----------|-------|
| **ETL-computed** | 5 |
| **Join-enriched** | 2 |
| **Passthrough** | 4 |
| **NULL for Clients** | 1 |
| **Total** | 12 |
