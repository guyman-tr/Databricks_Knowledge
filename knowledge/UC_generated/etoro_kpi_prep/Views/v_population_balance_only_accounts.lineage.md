# Column Lineage: main.etoro_kpi_prep.v_population_balance_only_accounts

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_population_balance_only_accounts` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_population_balance_only_accounts.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_population_balance_only_accounts.json` (rows: 3, mismatches: 3) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary` | JOIN / referenced | ✓ `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT981_BuyPowerSummary.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Client_Balance_CID_Level_New.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Client_Balance_CID_Level_New.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoneyClientBalance.md` |
| `main.general.bronze_usabroker_apex_options` | JOIN / referenced | ✓ `knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/apex/Tables/apex.Options.md` |
| `main.etoro_kpi_prep.v_population_active_traders` | JOIN / referenced | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_population_active_traders.md` |
| `main.etoro_kpi_prep.v_population_portfolio_only` | JOIN / referenced | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_population_portfolio_only.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new   ←── primary upstream
  + main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance   (JOIN)
  + main.general.bronze_sodreconciliation_apex_ext981_buypowersummary   (JOIN)
  + main.general.bronze_usabroker_apex_options   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.etoro_kpi_prep.v_population_active_traders   (JOIN)
  + main.etoro_kpi_prep.v_population_portfolio_only   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_population_balance_only_accounts   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `—` | `DateID` | `join_enriched` | — | bu.DateID |
| 2 | `RealCID` | `—` | `RealCID` | `join_enriched` | — | bu.RealCID |
| 3 | `MaxAnyEquity` | `—` | `MaxAnyEquity` | `join_enriched` | — | bu.MaxAnyEquity |

## Cross-check vs system.access.column_lineage

- Total target columns: **3**
- OK: **0**, WARN: **0**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `DateID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new.dateid`, `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary.processdate` | ERROR |
| `RealCID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new.cid`, `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance.cid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.realcid` | ERROR |
| `MaxAnyEquity` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new.actualnwa`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new.totalliability`, `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance.closingbalancebo`, `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance.usdapproxrate`, `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary.totalequity` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **3**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new AS cb ON cb.DateID = bs.DateID
- `INNER INNER` — INNER JOIN main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance AS mcb ON mcb.BalanceDateID = bs.DateID AND mcb.ClosingBalanceCalc > 0
- `INNER INNER` — INNER JOIN main.general.bronze_usabroker_apex_options AS op ON bps.AccountNumber = op.OptionsApexID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc ON op.GCID = dc.GCID
- `LEFT JOIN` — LEFT JOIN maxbalance_tp AS tp ON tp.DateID = c.DateID AND tp.RealCID = c.RealCID
- `LEFT JOIN` — LEFT JOIN max_iban AS ib ON ib.DateID = c.DateID AND ib.RealCID = c.RealCID
- `LEFT JOIN` — LEFT JOIN max_options AS mo ON mo.DateID = c.DateID AND mo.RealCID = c.RealCID
