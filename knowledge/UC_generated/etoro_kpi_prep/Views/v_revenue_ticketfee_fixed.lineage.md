# Column Lineage: main.etoro_kpi_prep.v_revenue_ticketfee_fixed

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_ticketfee_fixed` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_revenue_ticketfee_fixed.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_revenue_ticketfee_fixed.json` (rows: 0, mismatches: 0) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Fact_Customer_Action_Position_Distribution.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Fact_Customer_Action_Position_Distribution.md` |
| `main.general.bronze_historycosts_history_costs` | JOIN / referenced | ✗ `knowledge/UC_generated/general/<Tables|Views>/bronze_historycosts_history_costs.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution   ←── primary upstream
  + main.general.bronze_historycosts_history_costs   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_revenue_ticketfee_fixed   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `PositionID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 2 | `RealCID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 3 | `Occurred` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 4 | `DateID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 5 | `TicketFeeFixed` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 6 | `ActionType` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |

## Cross-check vs system.access.column_lineage

- Total target columns: **0**
- OK: **0**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**

## Joins (detected)

- `INNER JOIN` — JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution AS fcapd ON CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) = fcapd.DateID AND fhc.PositionID = fcapd.PositionID AND fcapd.TicketFeeAction = '
- `INNER JOIN` — JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution AS fcapd ON CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) = fcapd.DateID AND fhc.PositionID = fcapd.PositionID AND fcapd.TicketFeeAction = '
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di ON fca.InstrumentID = di.InstrumentID
