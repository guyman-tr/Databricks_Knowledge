# Cluster 47 brief — `EXW_dbo.EXW_FinanceReportsBalancesNew`

_Size: 30, intra-cluster weight: 90.0_
_Schema mix: {'EXW_dbo': 2, 'Trade': 1, 'Wallet': 1, 'bi_db': 1, 'bi_output': 5, 'bi_output_stg': 3, 'etoro_kpi_prep': 12, 'etoro_kpi_prep_stg': 1, 'finance': 1, 'general': 3}_
_Edge sources: {'wiki': 15, 'genie': 45, 'kpi_prep': 30}_

## Top members (ranked by intra-cluster weight)

- `EXW_dbo.EXW_FinanceReportsBalancesNew` — w 24.0 [wiki](knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_FinanceReportsBalancesNew.md)
- `Wallet.FinanceReportRecords` — w 13.0 (no wiki)
- `bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban` — w 11.0 (no wiki)
- `bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban` — w 11.0 (no wiki)
- `finance.bronze_sodreconciliation_apex_ext869_cashactivity` — w 10.0 (no wiki)
- `bi_output.bi_output_finance_tables_ptp_tax` — w 9.0 (no wiki)
- `bi_output.bi_output_finance_tables_ptp_tax_backup` — w 9.0 (no wiki)
- `bi_output.bi_output_finance_tables_tax_ptp_monitoring` — w 9.0 (no wiki)
- `bi_output_stg.bi_output_finance_tables_ptp_tax` — w 9.0 (no wiki)
- `bi_output_stg.bi_output_finance_tables_ptp_tax_temp` — w 9.0 (no wiki)
- `bi_output_stg.bi_output_finance_tables_tax_ptp_monitoring` — w 9.0 (no wiki)
- `etoro_kpi_prep.v_fact_customeraction_w_metrics` — w 6.0 (no wiki)
- `etoro_kpi_prep_stg.v_fact_customeraction_w_metrics` — w 6.0 (no wiki)
- `general.bronze_usabroker_apex_options` — w 5.0 (no wiki)
- `etoro_kpi_prep.v_population_balance_only_accounts` — w 4.0 (no wiki)
- `etoro_kpi_prep.v_population_portfolio_only` — w 4.0 (no wiki)
- `etoro_kpi_prep.v_options_aum` — w 3.0 (no wiki)
- `etoro_kpi_prep.v_population_active_traders` — w 3.0 (no wiki)
- `etoro_kpi_prep.v_population_first_time_funded` — w 3.0 (no wiki)
- `etoro_kpi_prep.v_revenue_optionsplatform` — w 3.0 (no wiki)
- `general.bronze_sodreconciliation_apex_ext981_buypowersummary` — w 3.0 (no wiki)
- `EXW_dbo.EXW_30DayBalanceExtract` — w 2.0 [wiki](knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_30DayBalanceExtract.md)
- `Trade.Adminpositionlog` — w 2.0 (no wiki)
- `etoro_kpi_prep.v_dim_instrument_enriched` — w 2.0 (no wiki)
- `etoro_kpi_prep.v_fact_customeraction_enriched` — w 2.0 (no wiki)

## Wiki §3.3 Common JOINs (top members)

### `EXW_dbo.EXW_FinanceReportsBalancesNew`

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_DimUser | GCID = GCID | User demographic enrichment |
| EXW_AML_Users_Report | GCID = GCID | AML status and compliance flags |
| EXW_UserSettingsWalletAllowance | GCID = GCID | Wallet allowance decisions |

## KPI views in this cluster

### `etoro_kpi_prep.v_dim_instrument_enriched`  (2361 chars)

Refs:
- `trading.bronze_etoro_trade_instrumentmetadata_daily`
- `trading.bronze_etoro_trade_providertoinstrument`
- `rth_instruments`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
- `trading.bronze_etoro_trade_instrumentgroups`
- `instruments_245`

### `etoro_kpi_prep.v_fact_customeraction_enriched`  (5403 chars)

Refs:
- `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`
- `dwh.dim_position`
- `passive_actions_enriched`
- `active_actions`

### `etoro_kpi_prep.v_fact_customeraction_w_metrics`  (7517 chars)

Refs:
- `general.bronze_recurringinvestment_recurringinvestment_planinstances`
- `dwh.dim_position`
- `etoro_kpi_prep.v_fact_customeraction_enriched`
- `etoro_kpi_prep.v_dim_instrument_enriched`
- `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee`
- `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_Reversals`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`
- `bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban`

### `etoro_kpi_prep.v_globalftdplatform`  (286 chars)

Refs:
- `bi_db.bronze_moneybusdb_dictionary_accounttypes`

### `etoro_kpi_prep.v_mimo_options_platform`  (5061 chars)

Refs:
- `finance.bronze_sodreconciliation_apex_ext869_cashactivity`
- `general.bronze_usabroker_apex_options`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- `MIMORecords`
- `DEPOSIT_UNIQUE_FOR_FTDJOIN`
- `FINRAONLY_ftd_date`
- `FINRAONLY_FTD_records`
- `FTDSingle`

### `etoro_kpi_prep.v_options_aum`  (1520 chars)

Refs:
- `general.bronze_sodreconciliation_apex_ext981_buypowersummary`
- `buypower_ranked`
- `latest_daily_buypower`
- `general.bronze_usabroker_apex_options`
- `first_funding`

### `etoro_kpi_prep.v_population_active_traders`  (3292 chars)

Refs:
- `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`
- `etoro_kpi_prep.v_revenue_optionsplatform`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- `actionsprep`

### `etoro_kpi_prep.v_population_balance_only_accounts`  (2905 chars)

Refs:
- `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`
- `snapshot_dates`
- `balanceprep_tp`
- `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance`
- `general.bronze_sodreconciliation_apex_ext981_buypowersummary`
- `general.bronze_usabroker_apex_options`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- `maxbalance_tp`

### `etoro_kpi_prep.v_population_first_time_funded`  (4120 chars)

Refs:
- `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- `etoro_kpi_prep.v_mimo_allplatforms`
- `etoro_kpi_prep.v_globalftdplatform`
- `REMOVE_BAD_FTDS`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`
- `dwh.dim_position`
- `etoro_kpi_prep.v_revenue_optionsplatform`

### `etoro_kpi_prep.v_population_funded`  (1084 chars)

Refs:
- `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`
- `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance`
- `etoro_kpi_prep.v_options_aum`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- `etoro_kpi_prep.v_population_first_time_funded`

### `etoro_kpi_prep.v_population_portfolio_only`  (5205 chars)

Refs:
- `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new`
- `snapshot_dates`
- `dwh.dim_position`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`
- `general.bronze_sodreconciliation_apex_ext981_buypowersummary`
- `general.bronze_usabroker_apex_options`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### `etoro_kpi_prep.v_revenue_optionsplatform`  (2400 chars)

Refs:
- `finance.bronze_sodreconciliation_apex_ext1047_revenuereports`
- `PREP`
- `FIRSTTRADE`
- `general.bronze_usabroker_apex_options`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### `etoro_kpi_prep_stg.v_fact_customeraction_w_metrics`  (8085 chars)

Refs:
- `general.bronze_recurringinvestment_recurringinvestment_planinstances`
- `dwh.dim_position`
- `etoro_kpi_prep.v_fact_customeraction_enriched`
- `etoro_kpi_prep.v_dim_instrument_enriched`
- `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee`
- `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_Reversals`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror`
- `bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban`

## Genie spaces overlapping this cluster

### `ido ezra space`  (9/10 tables, 0 join_specs)

Tables in cluster:
- `bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban`
- `bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban`
- `bi_output.bi_output_finance_tables_ptp_tax`
- `bi_output.bi_output_finance_tables_ptp_tax_backup`
- `bi_output.bi_output_finance_tables_tax_ptp_monitoring`
- `bi_output_stg.bi_output_finance_tables_ptp_tax`
- `bi_output_stg.bi_output_finance_tables_ptp_tax_temp`
- `bi_output_stg.bi_output_finance_tables_tax_ptp_monitoring`
- `finance.bronze_sodreconciliation_apex_ext869_cashactivity`

## Out-cluster neighbors (likely bridge candidates)

- `DWH_dbo.Dim_Customer` — outflow weight 7.0
- `DWH_dbo.Dim_Position` — outflow weight 5.0
- `DWH_dbo.Dim_Mirror` — outflow weight 4.0
- `EXW_dbo.EXW_CompensationClosingCountries` — outflow weight 3.0
- `EXW_dbo.EXW_DimUser` — outflow weight 3.0
- `DWH_dbo.Dim_Instrument` — outflow weight 3.0
- `DWH_dbo.Fact_CustomerAction` — outflow weight 3.0
- `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New` — outflow weight 3.0
- `EXW_dbo.EXW_DimUser_Enriched` — outflow weight 2.0
- `EXW_dbo.EXW_UserSettingsWalletAllowance` — outflow weight 2.0
- `EXW_Wallet.CryptoTypes` — outflow weight 2.0
- `etoro_kpi_prep.mv_revenue_trading` — outflow weight 2.0
- `etoro_kpi_prep.v_ddr_revenues` — outflow weight 2.0
- `BI_DB_dbo.BI_DB_DepositWithdrawFee` — outflow weight 2.0
- `BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals` — outflow weight 2.0
- `etoro_kpi_prep.v_mimo_optionsplatform` — outflow weight 2.0
- `etoro_kpi_prep_stg.v_ddr_mimo_options` — outflow weight 2.0
- `DWH_dbo.V_Fact_SnapshotCustomer_FromDateID` — outflow weight 2.0
- `eMoney_dbo.eMoneyClientBalance` — outflow weight 2.0
- `BI_DB_dbo.BI_DB_OPS_MultipleAccounts` — outflow weight 1.0
