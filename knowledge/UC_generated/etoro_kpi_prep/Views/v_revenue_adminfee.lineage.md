# Column Lineage: main.etoro_kpi_prep.v_revenue_adminfee

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_adminfee` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_revenue_adminfee.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_revenue_adminfee.json` (rows: 8, mismatches: 1) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Fact_Customer_Action_Position_Distribution.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution   ←── primary upstream
        │
        ▼
main.etoro_kpi_prep.v_revenue_adminfee   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `PositionID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `PositionID` | `cast` | (Tier 1 — Trade.PositionTbl) | cast to BIGINT — CAST(fca.PositionID AS BIGINT) AS PositionID |
| 2 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `RealCID` | `cast` | (Tier 1 — Customer.CustomerStatic) | cast to INT — CAST(fca.RealCID AS INT) AS RealCID |
| 3 | `DateID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `DateID` | `cast` | (Tier 1 — DWH_dbo.Fact_CustomerAction) | cast to INT — CAST(fca.DateID AS INT) AS DateID |
| 4 | `Occurred` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `Occurred` | `passthrough` | (Tier 1 — source-dependent) | fca.Occurred |
| 5 | `AdminFee` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `—` | `unknown` | — | CAST(-1 * fca.Amount AS DECIMAL(38, 6)) AS AdminFee |
| 6 | `IsSettled` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `IsSettled` | `cast` | (Tier 5 — Expert Review) | cast to INT — CAST(fca.IsSettled AS INT) AS IsSettled |
| 7 | `MirrorID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `MirrorID` | `cast` | (Tier 1 — Trade.PositionTbl) | cast to INT — CAST(fca.MirrorID AS INT) AS MirrorID |
| 8 | `SettlementTypeID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `SettlementTypeID` | `cast` | (Tier 1 — Trade.PositionTbl) | cast to INT — CAST(fca.SettlementTypeID AS INT) AS SettlementTypeID |

## Cross-check vs system.access.column_lineage

- Total target columns: **8**
- OK: **7**, WARN: **0**, ERROR: **1**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `AdminFee` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution.amount` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **0**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**
