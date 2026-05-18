# Column Lineage: main.etoro_kpi_prep.v_dim_dataplatform_uuid

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_dim_dataplatform_uuid` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_dim_dataplatform_uuid.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_dim_dataplatform_uuid.json` (rows: 6, mismatches: 6) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.bronze_sub_accounts_accounts` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.etoro_kpi.v_spaceship_aum` | JOIN / referenced | ✓ `knowledge/uc_domains/spaceship/schemas/etoro_kpi/Views/v_spaceship_aum.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   ←── primary upstream
  + main.bi_db.bronze_sub_accounts_accounts   (JOIN)
  + main.etoro_kpi.v_spaceship_aum   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_dim_dataplatform_uuid   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `dp_uuid` | `—` | `GCID` | `cast` | — | cast to STRING — CAST(e.GCID AS STRING) AS dp_uuid |
| 2 | `source_platform` | `—` | `—` | `case` | — | CASE WHEN NOT sc.sps_user_id IS NULL THEN 'both_gcid' ELSE 'etoro_gcid' END AS source_platform |
| 3 | `gcid` | `—` | `GCID` | `join_enriched` | — | e.GCID AS gcid |
| 4 | `cid` | `—` | `primary_cid` | `join_enriched` | — | e.primary_cid AS cid |
| 5 | `etoro_cid_count` | `—` | `cid_count` | `join_enriched` | — | e.cid_count AS etoro_cid_count |
| 6 | `sps_user_id` | `—` | `sps_user_id` | `join_enriched` | — | sc.sps_user_id |

## Cross-check vs system.access.column_lineage

- Total target columns: **6**
- OK: **0**, WARN: **0**, ERROR: **6**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `dp_uuid` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.gcid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.realcid`, `main.etoro_kpi.v_spaceship_aum.user_id`, `main.etoro_kpi_prep.v_spaceship_aum.gcid`, `main.etoro_kpi_prep.v_spaceship_aum.user_id` | ERROR |
| `source_platform` | — | `main.bi_db.bronze_sub_accounts_accounts.accountid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.gcid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.realcid`, `main.etoro_kpi_prep.v_spaceship_aum.user_id` | ERROR |
| `gcid` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.gcid`, `main.etoro_kpi_prep.v_spaceship_aum.gcid` | ERROR |
| `cid` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.realcid` | ERROR |
| `etoro_cid_count` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.realcid` | ERROR |
| `sps_user_id` | — | `main.bi_db.bronze_sub_accounts_accounts.accountid`, `main.etoro_kpi.v_spaceship_aum.user_id`, `main.etoro_kpi_prep.v_spaceship_aum.user_id` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **5**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN sps_cross AS sc ON e.GCID = sc.gcid
