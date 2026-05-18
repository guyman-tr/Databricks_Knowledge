# Column Lineage: main.etoro_kpi_prep.v_trading_volume_and_amount

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_trading_volume_and_amount` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_trading_volume_and_amount.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_trading_volume_and_amount.json` (rows: 32, mismatches: 27) |
| **Primary upstream** | `main.dwh.dim_position` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.etoro_kpi_prep.v_copyfund_positions` | JOIN / referenced | ✗ `knowledge/UC_generated/etoro_kpi_prep/<Tables|Views>/v_copyfund_positions.md` |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Positions_Closed_To_IBAN.md` |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Positions_Opened_From_IBAN.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.dim_position` | Primary (FROM) | ✗ `(no wiki found)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\EXW_dbo\Tables\EXW_C2P_E2E.md` |
| `main.etoro_kpi_prep.v_dim_instrument_enriched` | JOIN / referenced | ✗ `knowledge/UC_generated/etoro_kpi_prep/<Tables|Views>/v_dim_instrument_enriched.md` |

## Lineage Chain

```
main.dwh.dim_position   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
  + main.etoro_kpi_prep.v_copyfund_positions   (JOIN)
  + main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban   (JOIN)
  + main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e   (JOIN)
  + main.etoro_kpi_prep.v_dim_instrument_enriched   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_trading_volume_and_amount   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `—` | `CID` | `join_enriched` | — | v.CID |
| 2 | `PositionID` | `—` | `PositionID` | `join_enriched` | — | v.PositionID |
| 3 | `InstrumentID` | `—` | `InstrumentID` | `join_enriched` | — | v.InstrumentID |
| 4 | `Amount` | `—` | `Amount` | `join_enriched` | — | v.Amount |
| 5 | `Leverage` | `—` | `Leverage` | `join_enriched` | — | v.Leverage |
| 6 | `DateID` | `—` | `DateID` | `join_enriched` | — | v.DateID |
| 7 | `VolumeOpen` | `—` | `VolumeOpen` | `join_enriched` | — | v.VolumeOpen |
| 8 | `VolumeClose` | `—` | `VolumeClose` | `join_enriched` | — | v.VolumeClose |
| 9 | `InvestedAmountOpen` | `—` | `InvestedAmountOpen` | `join_enriched` | — | v.InvestedAmountOpen |
| 10 | `InvestedAmountClosed` | `—` | `InvestedAmountClosed` | `join_enriched` | — | v.InvestedAmountClosed |
| 11 | `TotalVolume` | `—` | `TotalVolume` | `join_enriched` | — | v.TotalVolume |
| 12 | `NetInvestedAmount` | `—` | `NetInvestedAmount` | `join_enriched` | — | v.NetInvestedAmount |
| 13 | `CountOpenTransactions` | `—` | `CountOpenTransactions` | `join_enriched` | — | v.CountOpenTransactions |
| 14 | `CountCloseTransactions` | `—` | `CountCloseTransactions` | `join_enriched` | — | v.CountCloseTransactions |
| 15 | `CountTotalTransactions` | `—` | `CountTotalTransactions` | `join_enriched` | — | v.CountTotalTransactions |
| 16 | `IsSettled` | `—` | `IsSettled` | `join_enriched` | — | v.IsSettled |
| 17 | `IsAirDrop` | `—` | `IsAirDrop` | `join_enriched` | — | v.IsAirDrop |
| 18 | `IsBuy` | `—` | `IsBuy` | `join_enriched` | — | v.IsBuy |
| 19 | `SettlementTypeID` | `—` | `SettlementTypeID` | `join_enriched` | — | v.SettlementTypeID |
| 20 | `ComputedVolumeOpen` | `—` | `ComputedVolumeOpen` | `join_enriched` | — | v.ComputedVolumeOpen |
| 21 | `ComputedVolumeClose` | `—` | `ComputedVolumeClose` | `join_enriched` | — | v.ComputedVolumeClose |
| 22 | `IsCopy` | `—` | `—` | `case` | — | CASE WHEN v.MirrorID > 0 THEN 1 ELSE 0 END AS IsCopy |
| 23 | `IsMarginTrade` | `—` | `—` | `case` | — | CASE WHEN v.SettlementTypeID = 5 THEN 1 ELSE 0 END AS IsMarginTrade |
| 24 | `InstrumentTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentTypeID` | `join_enriched` | (Tier 1 — Trade.GetInstrument) | di.InstrumentTypeID |
| 25 | `IsFuture` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `IsFuture` | `join_enriched` | (Tier 2 — SP_Dim_Instrument) | di.IsFuture |
| 26 | `IsSQF` | `—` | `—` | `case` | — | CASE WHEN NOT sqf.InstrumentID IS NULL THEN 1 ELSE 0 END AS IsSQF |
| 27 | `IsC2P` | `—` | `—` | `case` | — | CASE WHEN NOT c2p.PositionID IS NULL THEN 1 ELSE 0 END AS IsC2P |
| 28 | `IsCopyFund` | `main.etoro_kpi_prep.v_copyfund_positions` | `—` | `case` | — | CASE WHEN NOT bdcfp.PositionID IS NULL THEN 1 ELSE 0 END AS IsCopyFund |
| 29 | `IsRecurring` | `—` | `—` | `unknown` | — | CAST(0 AS INT) AS IsRecurring |
| 30 | `IsOpenedFromIBAN` | `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban` | `—` | `case` | — | CASE WHEN NOT bdpofi.PositionID IS NULL THEN 1 ELSE 0 END AS IsOpenedFromIBAN |
| 31 | `IsClosedToIBAN` | `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban` | `—` | `case` | — | CASE WHEN NOT bdpcti.PositionID IS NULL THEN 1 ELSE 0 END AS IsClosedToIBAN |
| 32 | `IsValidCustomer` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `IsValidCustomer` | `join_enriched` | — | fsc.IsValidCustomer |

## Cross-check vs system.access.column_lineage

- Total target columns: **32**
- OK: **5**, WARN: **0**, ERROR: **27**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `CID` | — | `main.dwh.dim_position.cid` | ERROR |
| `PositionID` | — | `main.dwh.dim_position.positionid` | ERROR |
| `InstrumentID` | — | `main.dwh.dim_position.instrumentid` | ERROR |
| `Amount` | — | `main.dwh.dim_position.amount` | ERROR |
| `Leverage` | — | `main.dwh.dim_position.leverage` | ERROR |
| `DateID` | — | `main.dwh.dim_position.closedateid`, `main.dwh.dim_position.opendateid` | ERROR |
| `VolumeOpen` | — | `main.dwh.dim_position.volume` | ERROR |
| `VolumeClose` | — | `main.dwh.dim_position.volumeonclose` | ERROR |
| `InvestedAmountOpen` | — | `main.dwh.dim_position.initialamountcents`, `main.dwh.dim_position.ispartialclosechild` | ERROR |
| `InvestedAmountClosed` | — | `main.dwh.dim_position.amount`, `main.dwh.dim_position.netprofit` | ERROR |
| `TotalVolume` | — | `main.dwh.dim_position.volume`, `main.dwh.dim_position.volumeonclose` | ERROR |
| `NetInvestedAmount` | — | `main.dwh.dim_position.amount`, `main.dwh.dim_position.initialamountcents`, `main.dwh.dim_position.ispartialclosechild`, `main.dwh.dim_position.netprofit` | ERROR |
| `CountOpenTransactions` | — | `main.dwh.dim_position.ispartialclosechild` | ERROR |
| `CountTotalTransactions` | — | `main.dwh.dim_position.ispartialclosechild` | ERROR |
| `IsSettled` | — | `main.dwh.dim_position.issettled` | ERROR |
| `IsAirDrop` | — | `main.dwh.dim_position.isairdrop` | ERROR |
| `IsBuy` | — | `main.dwh.dim_position.isbuy` | ERROR |
| `SettlementTypeID` | — | `main.dwh.dim_position.settlementtypeid` | ERROR |
| `ComputedVolumeOpen` | — | `main.dwh.dim_position.initconversionrate`, `main.dwh.dim_position.initforex_usdconversionrate`, `main.dwh.dim_position.initforexrate`, `main.dwh.dim_position.initialunits`, `main.dwh.dim_position.ispartialclosechild`, `main.dwh.dim_position.lastopconversionrate` | ERROR |
| `ComputedVolumeClose` | — | `main.dwh.dim_position.amountinunitsdecimal`, `main.dwh.dim_position.endforexrate`, `main.dwh.dim_position.lastopconversionrate` | ERROR |
| `IsCopy` | — | `main.dwh.dim_position.mirrorid` | ERROR |
| `IsMarginTrade` | — | `main.dwh.dim_position.settlementtypeid` | ERROR |
| `IsSQF` | — | `main.etoro_kpi_prep.v_dim_instrument_enriched.instrumentid` | ERROR |
| `IsC2P` | — | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e.positionid` | ERROR |
| `IsCopyFund` | — | `main.etoro_kpi_prep.v_copyfund_positions.positionid` | ERROR |
| `IsOpenedFromIBAN` | — | `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban.positionid` | ERROR |
| `IsClosedToIBAN` | — | `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban.positionid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **31**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON v.CID = fsc.RealCID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS dr ON fsc.DateRangeID = dr.DateRangeID AND v.DateID BETWEEN dr.FromDateID AND dr.ToDateID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di ON v.InstrumentID = di.InstrumentID
- `LEFT JOIN` — LEFT JOIN sqf ON v.InstrumentID = sqf.InstrumentID
- `LEFT JOIN` — LEFT JOIN c2p ON v.PositionID = c2p.PositionID
- `LEFT JOIN` — LEFT JOIN main.etoro_kpi_prep.v_copyfund_positions AS bdcfp ON v.PositionID = bdcfp.PositionID
- `LEFT JOIN` — LEFT JOIN main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban AS bdpofi ON v.PositionID = bdpofi.PositionID
- `LEFT JOIN` — LEFT JOIN main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban AS bdpcti ON v.PositionID = bdpcti.PositionID
