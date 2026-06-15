# Column Lineage: main.etoro_kpi.v_ddr_non_revenue_actions

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.v_ddr_non_revenue_actions` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\v_ddr_non_revenue_actions.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\v_ddr_non_revenue_actions.json` (rows: 6, mismatches: 4) |
| **Primary upstream** | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` | Primary (FROM) | ✗ `knowledge/UC_generated/de_output/<Tables|Views>/de_output_etoro_kpi_fact_customeraction_w_metrics.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |

## Lineage Chain

```
main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
        │
        ▼
main.etoro_kpi.v_ddr_non_revenue_actions   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` | `DateID` | `passthrough` | — | DateID |
| 2 | `RealCID` | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` | `RealCID` | `passthrough` | — | RealCID |
| 3 | `ActionType` | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` | `ActionType` | `passthrough` | — | ActionType |
| 4 | `Amount` | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` | `—` | `aggregate` | — | SUM(Amount) AS Amount |
| 5 | `CountActions` | `—` | `—` | `aggregate` | — | COUNT(*) AS CountActions |
| 6 | `IsCopyFund` | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` | `IsCopyFund` | `passthrough` | — | IsCopyFund |

## Cross-check vs system.access.column_lineage

- Total target columns: **6**
- OK: **2**, WARN: **3**, ERROR: **1**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `DateID` | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics.dateid` | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics.dateid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.dateid` | WARN |
| `RealCID` | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics.realcid` | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics.realcid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.realcid` | WARN |
| `ActionType` | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics.actiontype` | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics.actiontypeid`, `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics.compensationreasonid`, `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics.dateid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked.realcid`, `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd.tp_ftd_dateid` | WARN |
| `Amount` | — | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics.actiontypeid`, `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics.amount` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **2**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON fca.RealCID = fsc.RealCID AND fca.DateID BETWEEN fsc.FromDateID AND fsc.ToDateID AND fsc.IsDepositor = 1
