# Column Lineage: main.etoro_kpi_prep.v_revenue_dividend

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_dividend` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_revenue_dividend.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_revenue_dividend.json` (rows: 6, mismatches: 0) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction   ←── primary upstream
        │
        ▼
main.etoro_kpi_prep.v_revenue_dividend   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `PositionID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `PositionID` | `cast` | (Tier 1 — Trade.PositionTbl) | cast to BIGINT — CAST(PositionID AS BIGINT) AS PositionID |
| 2 | `RealCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `RealCID` | `cast` | (Tier 1 — Customer.CustomerStatic) | cast to INT — CAST(RealCID AS INT) AS RealCID |
| 3 | `Occurred` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `Occurred` | `passthrough` | (Tier 1 — source-dependent) | fca.Occurred |
| 4 | `DateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `DateID` | `cast` | (Tier 2 — SP_Fact_CustomerAction) | cast to INT — CAST(DateID AS INT) AS DateID |
| 5 | `etr_ymd` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `etr_ymd` | `passthrough` | — | etr_ymd |
| 6 | `Dividend` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `Amount` | `cast` | (Tier 1 — Trade.PositionTbl / History.Credit) | cast to DECIMAL(38, 6) — CAST(Amount AS DECIMAL(38, 6)) AS Dividend |

## Cross-check vs system.access.column_lineage

- Total target columns: **6**
- OK: **6**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
