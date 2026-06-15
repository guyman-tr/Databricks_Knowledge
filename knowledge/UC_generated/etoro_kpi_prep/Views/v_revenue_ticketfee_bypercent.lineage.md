# Column Lineage: main.etoro_kpi_prep.v_revenue_ticketfee_bypercent

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_ticketfee_bypercent` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_revenue_ticketfee_bypercent.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_revenue_ticketfee_bypercent.json` (rows: 6, mismatches: 6) |
| **Primary upstream** | `main.general.bronze_historycosts_history_costs` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Fact_Customer_Action_Position_Distribution.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Fact_Customer_Action_Position_Distribution.md` |
| `main.general.bronze_historycosts_history_costs` | Primary (FROM) | ✗ `knowledge/UC_generated/general/<Tables|Views>/bronze_historycosts_history_costs.md` |

## Lineage Chain

```
main.general.bronze_historycosts_history_costs   ←── primary upstream
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_revenue_ticketfee_bypercent   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `PositionID` | `main.general.bronze_historycosts_history_costs` | `PositionID` | `cast` | — | cast to BIGINT — CAST(fhc.PositionID AS BIGINT) AS PositionID |
| 2 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `RealCID` | `cast` | (Tier 1 — Customer.CustomerStatic) | cast to INT — CAST(fcapd.RealCID AS INT) AS RealCID |
| 3 | `Occurred` | `main.general.bronze_historycosts_history_costs` | `Occurred` | `passthrough` | — | fhc.Occurred |
| 4 | `DateID` | `main.general.bronze_historycosts_history_costs` | `—` | `unknown` | — | CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) AS DateID |
| 5 | `TicketFeeByPercent` | `main.general.bronze_historycosts_history_costs` | `—` | `unknown` | — | CAST(CASE WHEN CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) < 20250525 THEN 0 ELSE fhc.ValueInAccountCurrency END AS DECIMAL(38, 6)) A |
| 6 | `ActionType` | `—` | `—` | `literal` | — | literal `'Open'` — 'Open' AS ActionType |

## Cross-check vs system.access.column_lineage

- Total target columns: **6**
- OK: **0**, WARN: **3**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `PositionID` | `main.general.bronze_historycosts_history_costs.positionid` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution.positionid`, `main.general.bronze_historycosts_history_costs.positionid` | WARN |
| `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution.realcid` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution.realcid`, `main.general.bronze_historycosts_history_costs.cid` | WARN |
| `Occurred` | `main.general.bronze_historycosts_history_costs.occurred` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution.occurred`, `main.general.bronze_historycosts_history_costs.occurred` | WARN |
| `DateID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution.dateid`, `main.general.bronze_historycosts_history_costs.occurred` | ERROR |
| `TicketFeeByPercent` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution.amount`, `main.general.bronze_historycosts_history_costs.occurred`, `main.general.bronze_historycosts_history_costs.valueinaccountcurrency` | ERROR |
| `ActionType` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution.ticketfeeaction` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **1**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **2**

## Joins (detected)

- `INNER JOIN` — JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution AS fcapd ON CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) = fcapd.DateID AND fhc.PositionID = fcapd.PositionID AND fcapd.TicketFeeAction = '
- `INNER JOIN` — JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution AS fcapd ON CAST(DATE_FORMAT(fhc.Occurred, 'yyyyMMdd') AS INT) = fcapd.DateID AND fhc.PositionID = fcapd.PositionID AND fcapd.TicketFeeAction = '
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di ON fca.InstrumentID = di.InstrumentID
