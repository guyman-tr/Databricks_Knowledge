# Column Lineage: main.etoro_kpi_prep.v_revenue_sdrt

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_sdrt` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_revenue_sdrt.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_revenue_sdrt.json` (rows: 14, mismatches: 3) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Fact_Customer_Action_Position_Distribution.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_revenue_sdrt   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `RealCID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | fca.RealCID |
| 2 | `GCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `GCID` | `passthrough` | (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) | fca.GCID |
| 3 | `DateID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `DateID` | `passthrough` | (Tier 1 — DWH_dbo.Fact_CustomerAction) | fca.DateID |
| 4 | `Occurred` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `Occurred` | `passthrough` | (Tier 1 — source-dependent) | fca.Occurred |
| 5 | `SDRT` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `—` | `arithmetic` | — | -1 * fca.Amount AS SDRT |
| 6 | `InstrumentID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `InstrumentID` | `passthrough` | (Tier 1 — Trade.Instrument) | fca.InstrumentID |
| 7 | `PositionID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `PositionID` | `passthrough` | (Tier 1 — Trade.PositionTbl) | fca.PositionID |
| 8 | `IsBuy` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `IsBuy` | `passthrough` | (Tier 1 — Trade.PositionTbl) | fca.IsBuy |
| 9 | `IsSettled` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `IsSettled` | `passthrough` | (Tier 5 — Expert Review) | fca.IsSettled |
| 10 | `SettlementTypeID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `SettlementTypeID` | `passthrough` | (Tier 1 — Trade.PositionTbl) | fca.SettlementTypeID |
| 11 | `IsMarginTrade` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `—` | `case` | — | CASE WHEN fca.SettlementTypeID = 5 THEN 1 ELSE 0 END AS IsMarginTrade |
| 12 | `IsCopy` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `—` | `case` | — | CASE WHEN fca.MirrorID <> 0 THEN 1 ELSE 0 END AS IsCopy |
| 13 | `InstrumentTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentTypeID` | `join_enriched` | (Tier 1 — Trade.GetInstrument) | di.InstrumentTypeID |
| 14 | `IsValidCustomer` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution` | `IsValidCustomer` | `passthrough` | (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) | fca.IsValidCustomer |

## Cross-check vs system.access.column_lineage

- Total target columns: **14**
- OK: **11**, WARN: **0**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `SDRT` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution.amount` | ERROR |
| `IsMarginTrade` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution.settlementtypeid` | ERROR |
| `IsCopy` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_fact_customer_action_position_distribution.mirrorid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **4**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di ON fca.InstrumentID = di.InstrumentID
