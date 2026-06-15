# Column Lineage: main.etoro_kpi_prep.v_population_funded

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_population_funded` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_population_funded.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_population_funded.json` (rows: 3, mismatches: 3) |
| **Primary upstream** | `main.etoro_kpi_prep.v_options_aum` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Client_Balance_CID_Level_New.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.etoro_kpi_prep.v_options_aum` | Primary (FROM) | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_options_aum.md` |
| `main.etoro_kpi_prep.v_population_first_time_funded` | JOIN / referenced | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_population_first_time_funded.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoneyClientBalance.md` |

## Lineage Chain

```
main.etoro_kpi_prep.v_options_aum   ←── primary upstream
  + main.etoro_kpi_prep.v_population_first_time_funded   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_population_funded   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `—` | `DateID` | `join_enriched` | — | a.DateID |
| 2 | `RealCID` | `—` | `RealCID` | `join_enriched` | — | a.RealCID |
| 3 | `Equity` | `—` | `—` | `aggregate` | — | SUM(a.Equity) AS Equity |

## Cross-check vs system.access.column_lineage

- Total target columns: **3**
- OK: **0**, WARN: **0**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `DateID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new.dateid`, `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance.balancedateid`, `main.etoro_kpi_prep.v_options_aum.dateid` | ERROR |
| `RealCID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new.cid`, `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance.cid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.realcid` | ERROR |
| `Equity` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new.actualnwa`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new.totalliability`, `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance.closingbalancebo`, `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance.usdapproxrate`, `main.etoro_kpi_prep.v_options_aum.optionstotalequity` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **3**

## Joins (detected)

- `INNER JOIN` — JOIN main.etoro_kpi_prep.v_population_first_time_funded AS fpftf ON a.RealCID = fpftf.RealCID AND fpftf.FirstFundedDateID <= a.DateID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc ON faop.GCID = dc.GCID
