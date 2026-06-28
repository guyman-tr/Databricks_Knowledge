# Column Lineage: main.bi_output.bi_output_vg_daily_commission

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_daily_commission` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_vg_daily_commission.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_vg_daily_commission.json` (rows: 37, mismatches: 37) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DailyCommisionReport.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.trading.bronze_etoro_trade_instrumentgroups` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentGroups.md` |
| `main.trading.bronze_etoro_trade_instrumentmetadata` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentMetaData.md` |
| `main.trading.bronze_etoro_trade_providertoinstrument` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.ProviderToInstrument.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
  + main.trading.bronze_etoro_trade_instrumentgroups   (JOIN)
  + main.trading.bronze_etoro_trade_instrumentmetadata   (JOIN)
  + main.trading.bronze_etoro_trade_providertoinstrument   (JOIN)
        │
        ▼
main.bi_output.bi_output_vg_daily_commission   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `—` | `RealCID` | `join_enriched` | — | dc.RealCID |
| 2 | `InstrumentID` | `—` | `InstrumentID` | `join_enriched` | — | dc.InstrumentID |
| 3 | `Instrument` | `—` | `Instrument` | `join_enriched` | — | dc.Instrument |
| 4 | `InstrumentTypeID` | `—` | `InstrumentTypeID` | `join_enriched` | — | dc.InstrumentTypeID |
| 5 | `InstrumentType` | `—` | `InstrumentType` | `join_enriched` | — | dc.InstrumentType |
| 6 | `FullDate` | `—` | `FullDate` | `join_enriched` | — | dc.FullDate |
| 7 | `DateID` | `—` | `DateID` | `join_enriched` | — | dc.DateID |
| 8 | `Commissions` | `—` | `Commissions` | `join_enriched` | — | dc.Commissions |
| 9 | `FullCommissions` | `—` | `FullCommissions` | `join_enriched` | — | dc.FullCommissions |
| 10 | `VolumeOnOpen` | `—` | `VolumeOnOpen` | `join_enriched` | — | dc.VolumeOnOpen |
| 11 | `VolumeOnClose` | `—` | `VolumeOnClose` | `join_enriched` | — | dc.VolumeOnClose |
| 12 | `RollOverFee` | `—` | `RollOverFee` | `join_enriched` | — | dc.RollOverFee |
| 13 | `IsSettled` | `—` | `IsSettled` | `join_enriched` | — | dc.IsSettled |
| 14 | `IsMirror` | `—` | `IsMirror` | `join_enriched` | — | dc.IsMirror |
| 15 | `CommissionOnOpen` | `—` | `CommissionOnOpen` | `join_enriched` | — | dc.CommissionOnOpen |
| 16 | `CommissionOnCloseAdjustment` | `—` | `CommissionOnCloseAdjustment` | `join_enriched` | — | dc.CommissionOnCloseAdjustment |
| 17 | `FullCommissionOnOpen` | `—` | `FullCommissionOnOpen` | `join_enriched` | — | dc.FullCommissionOnOpen |
| 18 | `FullCommissionOnCloseAdjustment` | `—` | `FullCommissionOnCloseAdjustment` | `join_enriched` | — | dc.FullCommissionOnCloseAdjustment |
| 19 | `CommissionOnClose` | `—` | `CommissionOnClose` | `join_enriched` | — | dc.CommissionOnClose |
| 20 | `FullCommissionOnClose` | `—` | `FullCommissionOnClose` | `join_enriched` | — | dc.FullCommissionOnClose |
| 21 | `IsBuy` | `—` | `IsBuy` | `join_enriched` | — | dc.IsBuy |
| 22 | `IsLeverage` | `—` | `IsLeverage` | `join_enriched` | — | dc.IsLeverage |
| 23 | `IsAirDrop` | `—` | `IsAirDrop` | `join_enriched` | — | dc.IsAirDrop |
| 24 | `SettlementTypeID` | `—` | `SettlementTypeID` | `join_enriched` | — | dc.SettlementTypeID |
| 25 | `TicketFee` | `—` | `TicketFee` | `join_enriched` | — | dc.TicketFee |
| 26 | `TicketFeeByPercent` | `—` | `TicketFeeByPercent` | `join_enriched` | — | dc.TicketFeeByPercent |
| 27 | `AdminFee` | `—` | `AdminFee` | `join_enriched` | — | dc.AdminFee |
| 28 | `SpotAdjustFee` | `—` | `SpotAdjustFee` | `join_enriched` | — | dc.SpotAdjustFee |
| 29 | `InvestedAmountOpen` | `—` | `InvestedAmountOpen` | `join_enriched` | — | dc.InvestedAmountOpen |
| 30 | `CountUU` | `—` | `CountUU` | `join_enriched` | — | dc.CountUU |
| 31 | `IsMarginTrade` | `—` | `IsMarginTrade` | `join_enriched` | — | dc.IsMarginTrade |
| 32 | `instrumentdisplayname` | `—` | `instrumentdisplayname` | `join_enriched` | — | fu.instrumentdisplayname |
| 33 | `symbol` | `—` | `symbol` | `join_enriched` | — | fu.symbol |
| 34 | `IsFuture` | `—` | `—` | `case` | — | CASE WHEN fu.isfuture = 1 THEN 1 ELSE 0 END AS IsFuture |
| 35 | `IsSQF` | `—` | `—` | `case` | — | CASE WHEN NOT si.InstrumentID IS NULL THEN 1 ELSE 0 END AS IsSQF |
| 36 | `Is_245` | `—` | `—` | `case` | — | CASE WHEN NOT tff.InstrumentID IS NULL THEN 1 ELSE 0 END AS Is_245 |
| 37 | `IsUSStock` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport` | `—` | `case` | — | CASE WHEN exchange IN ('Nasdaq', 'NYSE', 'Regular Trading Hours - RTH') THEN 1 ELSE 0 END AS IsUSStock |

## Cross-check vs system.access.column_lineage

- Total target columns: **37**
- OK: **0**, WARN: **0**, ERROR: **37**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `RealCID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.realcid` | ERROR |
| `InstrumentID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.instrumentid` | ERROR |
| `Instrument` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.instrument` | ERROR |
| `InstrumentTypeID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.instrumenttypeid` | ERROR |
| `InstrumentType` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.instrumenttype` | ERROR |
| `FullDate` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.fulldate` | ERROR |
| `DateID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.dateid` | ERROR |
| `Commissions` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.commissions` | ERROR |
| `FullCommissions` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.fullcommissions` | ERROR |
| `VolumeOnOpen` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.volumeonopen` | ERROR |
| `VolumeOnClose` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.volumeonclose` | ERROR |
| `RollOverFee` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.rolloverfee` | ERROR |
| `IsSettled` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.issettled` | ERROR |
| `IsMirror` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.ismirror` | ERROR |
| `CommissionOnOpen` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.commissiononopen` | ERROR |
| `CommissionOnCloseAdjustment` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.commissiononcloseadjustment` | ERROR |
| `FullCommissionOnOpen` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.fullcommissiononopen` | ERROR |
| `FullCommissionOnCloseAdjustment` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.fullcommissiononcloseadjustment` | ERROR |
| `CommissionOnClose` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.commissiononclose` | ERROR |
| `FullCommissionOnClose` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.fullcommissiononclose` | ERROR |
| `IsBuy` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.isbuy` | ERROR |
| `IsLeverage` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.isleverage` | ERROR |
| `IsAirDrop` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.isairdrop` | ERROR |
| `SettlementTypeID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.settlementtypeid` | ERROR |
| `TicketFee` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.ticketfee` | ERROR |
| `TicketFeeByPercent` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.ticketfeebypercent` | ERROR |
| `AdminFee` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.adminfee` | ERROR |
| `SpotAdjustFee` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.spotadjustfee` | ERROR |
| `InvestedAmountOpen` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.investedamountopen` | ERROR |
| `CountUU` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.countuu` | ERROR |
| `IsMarginTrade` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport.ismargintrade` | ERROR |
| `instrumentdisplayname` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumentdisplayname` | ERROR |
| `symbol` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.symbol` | ERROR |
| `IsFuture` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.isfuture` | ERROR |
| `IsSQF` | — | `main.trading.bronze_etoro_trade_instrumentgroups.instrumentid` | ERROR |
| `Is_245` | — | `main.trading.bronze_etoro_trade_instrumentmetadata.instrumentid` | ERROR |
| `IsUSStock` | — | `main.trading.bronze_etoro_trade_instrumentmetadata.exchange` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **37**

## Joins (detected)

- `INNER JOIN` — JOIN instrument_metadata AS fu ON dc.InstrumentID = fu.InstrumentID
- `LEFT JOIN` — LEFT JOIN sqf_instruments AS si ON dc.InstrumentID = si.InstrumentID
- `LEFT JOIN` — LEFT JOIN 245_instruments AS tff ON dc.InstrumentID = tff.InstrumentID
- `INNER JOIN` — JOIN main.trading.bronze_etoro_trade_providertoinstrument AS pti ON imd.InstrumentID = pti.InstrumentID
- `INNER JOIN` — JOIN main.trading.bronze_etoro_trade_providertoinstrument AS pti ON imd.InstrumentID = pti.InstrumentID
- `INNER JOIN` — JOIN 245_instruments_prep AS rth ON rth.isincode = imd.ISINCode
