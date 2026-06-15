# Column Lineage: main.etoro_kpi_prep.mv_revenue_trading

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.mv_revenue_trading` |
| **Object Type** | `MATERIALIZED_VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\mv_revenue_trading.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\mv_revenue_trading.json` (rows: 13, mismatches: 7) |
| **Primary upstream** | `main.dwh.dim_position` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_closed_to_iban.md` |
| `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban` | JOIN / referenced | ✗ `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_finance_tables_bi_db_positions_opened_from_iban.md` |
| `main.trading.bronze_etoro_trade_instrumentgroups` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.InstrumentGroups.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.dim_position` | Primary (FROM) | ✗ `(no wiki found)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |
| `main.etoro_kpi_prep.v_revenue_adminfee` | JOIN / referenced | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_adminfee.md` |
| `main.etoro_kpi_prep.v_revenue_commission` | JOIN / referenced | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_commission.md` |
| `main.etoro_kpi_prep.v_revenue_dividend` | JOIN / referenced | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_dividend.md` |
| `main.etoro_kpi_prep.v_revenue_fullcommission` | JOIN / referenced | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_fullcommission.md` |
| `main.etoro_kpi_prep.v_revenue_rollover` | JOIN / referenced | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_rollover.md` |
| `main.etoro_kpi_prep.v_revenue_spotadjustfee` | JOIN / referenced | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_spotadjustfee.md` |
| `main.etoro_kpi_prep.v_revenue_ticketfee_bypercent` | JOIN / referenced | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_ticketfee_bypercent.md` |
| `main.etoro_kpi_prep.v_revenue_ticketfee_fixed` | JOIN / referenced | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_revenue_ticketfee_fixed.md` |

## Lineage Chain

```
main.dwh.dim_position   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror   (JOIN)
  + main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban   (JOIN)
  + main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban   (JOIN)
  + main.trading.bronze_etoro_trade_instrumentgroups   (JOIN)
  + main.etoro_kpi_prep.v_revenue_spotadjustfee   (JOIN)
  + main.etoro_kpi_prep.v_revenue_adminfee   (JOIN)
  + main.etoro_kpi_prep.v_revenue_dividend   (JOIN)
  + main.etoro_kpi_prep.v_revenue_rollover   (JOIN)
  + main.etoro_kpi_prep.v_revenue_ticketfee_bypercent   (JOIN)
  + main.etoro_kpi_prep.v_revenue_ticketfee_fixed   (JOIN)
  + main.etoro_kpi_prep.v_revenue_fullcommission   (JOIN)
  + main.etoro_kpi_prep.v_revenue_commission   (JOIN)
        │
        ▼
main.etoro_kpi_prep.mv_revenue_trading   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `PositionID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 2 | `RealCID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 3 | `DateID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 4 | `Occurred` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 5 | `Amount` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 6 | `Metric` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 7 | `ActionType` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 8 | `IncludedInTotalRevenue` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 9 | `IsActiveTrade` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 10 | `IsSettled` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 11 | `MirrorID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 12 | `SettlementTypeID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 13 | `IsSettled_Final` | `—` | `—` | `coalesce` | — | COALESCE(fca.IsSettled, dp.IsSettled) AS IsSettled_Final |
| 14 | `MirrorID_Final` | `—` | `—` | `coalesce` | — | COALESCE(fca.MirrorID, dp.MirrorID) AS MirrorID_Final |
| 15 | `SettlementTypeID_Final` | `—` | `—` | `coalesce` | — | COALESCE(fca.SettlementTypeID, dp.SettlementTypeID) AS SettlementTypeID_Final |
| 16 | `IsOpenFromIBAN` | `—` | `—` | `case` | — | CASE WHEN NOT io.PositionID IS NULL THEN 1 ELSE 0 END AS IsOpenFromIBAN |
| 17 | `IsClosedToIBAN` | `—` | `—` | `case` | — | CASE WHEN NOT ic.PositionID IS NULL THEN 1 ELSE 0 END AS IsClosedToIBAN |
| 18 | `IsCopyFund` | `—` | `—` | `case` | — | CASE WHEN dm.MirrorTypeID = 4 THEN 1 ELSE 0 END AS IsCopyFund |
| 19 | `InstrumentID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentID` | `join_enriched` | (Tier 1 — Trade.GetInstrument) | di.InstrumentID |
| 20 | `InstrumentTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentTypeID` | `join_enriched` | (Tier 1 — Trade.GetInstrument) | di.InstrumentTypeID |
| 21 | `InstrumentType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentType` | `join_enriched` | (Tier 2 — SP_Dim_Instrument) | di.InstrumentType |
| 22 | `InstrumentName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `Name` | `join_enriched` | (Tier 1 — Trade.GetInstrument) | di.Name AS InstrumentName |
| 23 | `Symbol` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `Symbol` | `join_enriched` | (Tier 1 — Trade.InstrumentMetaData) | di.Symbol |
| 24 | `IsSQF` | `—` | `—` | `case` | — | CASE WHEN NOT sqf.InstrumentID IS NULL THEN 1 ELSE 0 END AS IsSQF |

## Cross-check vs system.access.column_lineage

- Total target columns: **13**
- OK: **6**, WARN: **0**, ERROR: **7**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `IsSettled_Final` | — | `main.dwh.dim_position.issettled`, `main.etoro_kpi_prep.v_revenue_adminfee.issettled`, `main.etoro_kpi_prep.v_revenue_commission.issettled`, `main.etoro_kpi_prep.v_revenue_fullcommission.issettled`, `main.etoro_kpi_prep.v_revenue_spotadjustfee.issettled` | ERROR |
| `MirrorID_Final` | — | `main.dwh.dim_position.mirrorid`, `main.etoro_kpi_prep.v_revenue_adminfee.mirrorid`, `main.etoro_kpi_prep.v_revenue_commission.mirrorid`, `main.etoro_kpi_prep.v_revenue_fullcommission.mirrorid`, `main.etoro_kpi_prep.v_revenue_spotadjustfee.mirrorid` | ERROR |
| `SettlementTypeID_Final` | — | `main.dwh.dim_position.settlementtypeid`, `main.etoro_kpi_prep.v_revenue_adminfee.settlementtypeid`, `main.etoro_kpi_prep.v_revenue_commission.settlementtypeid`, `main.etoro_kpi_prep.v_revenue_fullcommission.settlementtypeid`, `main.etoro_kpi_prep.v_revenue_spotadjustfee.settlementtypeid` | ERROR |
| `IsOpenFromIBAN` | — | `main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban.treeid` | ERROR |
| `IsClosedToIBAN` | — | `main.bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban.positionid` | ERROR |
| `IsCopyFund` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror.mirrortypeid` | ERROR |
| `IsSQF` | — | `main.trading.bronze_etoro_trade_instrumentgroups.instrumentid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **10**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN DIMPOS AS dp ON fca.PositionID = dp.PositionID
- `LEFT JOIN` — LEFT JOIN MIRRORS AS dm ON COALESCE(fca.MirrorID, dp.MirrorID) = dm.MirrorID
- `LEFT JOIN` — LEFT JOIN IBANOPEN AS io ON fca.PositionID = io.PositionID
- `LEFT JOIN` — LEFT JOIN IBANCLOSE AS ic ON fca.PositionID = ic.PositionID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di ON dp.InstrumentID = di.InstrumentID
- `LEFT JOIN` — LEFT JOIN SQF AS sqf ON di.InstrumentID = sqf.InstrumentID
