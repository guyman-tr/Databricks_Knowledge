# `migration_tables` prune audit

- SP files scanned: **127** (C:\Users\guyman\Desktop\lakebridge_transplier_v3\Stored Procedures)
- Objects in `dwh_daily_process.migration_tables`: **359** (344 tables, 15 views)
- Distinct write targets across all SPs: **256**

## A. Prune candidates — in lake, NO SP writes to them

**133 objects.** Review each — anything recognizably test/backup/dated should be deleted.


### A.1 BACKUP_DATED (35)

| # | table_name | type | row_count | last_altered |
|---:|---|---|---:|---|
| 1 | `datasolutionsprocessesstatus_bkp_2023_10_29` | MANAGED | 0 | 2026-05-11T06:54:05.625000+00:00 |
| 2 | `dim_customer_backup_20260223` | MANAGED | 0 | 2026-05-11T07:04:40.249000+00:00 |
| 3 | `dim_customer_channel_20260322` | MANAGED | 0 | 2026-05-11T06:54:42.785000+00:00 |
| 4 | `dim_instrument_back20260325` | MANAGED | 0 | 2026-05-11T07:11:39.437000+00:00 |
| 5 | `dim_instrument_poc_bcp` | MANAGED | 0 | 2026-05-11T07:04:46.043000+00:00 |
| 6 | `dim_instrument_snapshot_12022025` | MANAGED | 0 | 2026-05-11T06:55:10.463000+00:00 |
| 7 | `dim_position_backup20240616` | MANAGED | 0 | 2026-05-11T07:04:51.915000+00:00 |
| 8 | `dim_position_backup_20250705` | MANAGED | 0 | 2026-05-11T07:09:00.131000+00:00 |
| 9 | `dim_position_backup_20250916` | MANAGED | 0 | 2026-05-11T07:04:53.394000+00:00 |
| 10 | `dim_position_switch_single_backup_20250916` | MANAGED | 0 | 2026-05-11T07:04:54.962000+00:00 |
| 11 | `dim_positionchangelog_bkp_2024_05_05` | MANAGED | 0 | 2026-05-11T07:04:57.534000+00:00 |
| 12 | `ext_dim_country_20240331` | MANAGED | 0 | 2026-05-11T06:56:01.020000+00:00 |
| 13 | `ext_dim_country_old_20240305` | MANAGED | 0 | 2026-05-11T06:56:03.705000+00:00 |
| 14 | `ext_dim_instrument_stockinfo_instrumentdata_back20250325` | MANAGED | 0 | 2026-05-11T06:56:31.051000+00:00 |
| 15 | `ext_dim_position_hbcexecutionlog_bkp_2023_10_17` | MANAGED | 0 | 2026-05-11T06:56:41.903000+00:00 |
| 16 | `ext_dim_position_real_20240430` | MANAGED | 0 | 2026-05-11T07:05:15.461000+00:00 |
| 17 | `ext_dim_position_real_backup_20250916` | MANAGED | 0 | 2026-05-11T07:05:16.982000+00:00 |
| 18 | `fact_billingwithdraw_20230531` | MANAGED | 0 | 2026-05-11T07:06:31.337000+00:00 |
| 19 | `fact_billingwithdraw_20230601` | MANAGED | 0 | 2026-05-11T07:06:32.905000+00:00 |
| 20 | `fact_cashout_state_backup_20250403` | MANAGED | 0 | 2026-05-11T06:57:39.768000+00:00 |
| 21 | `fact_customeraction_pnl_qa_environment` | MANAGED | 0 | 2026-05-11T07:06:36.046000+00:00 |
| 22 | `fact_deposit_state_backup_2025_07_22` | MANAGED | 0 | 2026-05-11T06:57:45.560000+00:00 |
| 23 | `fact_getspreadedpricecandle60minsplitted_for_check` | MANAGED | 0 | 2026-05-11T06:57:47.036000+00:00 |
| 24 | `fact_getspreadedpricecandle60minsplitted_for_check_daysbefore` | MANAGED | 0 | 2026-05-11T06:57:48.386000+00:00 |
| 25 | `fact_guru_copiers_backup_20241014` | MANAGED | 0 | 2026-05-11T07:06:42.747000+00:00 |
| 26 | `fact_guru_copiers_backup_20241014_ver2` | MANAGED | 0 | 2026-05-11T07:06:44.563000+00:00 |
| 27 | `fact_position_futures_snapshot_12022025` | MANAGED | 0 | 2026-05-11T07:06:47.524000+00:00 |
| 28 | `fact_position_futures_snapshot_backup` | MANAGED | 0 | 2026-05-11T07:06:48.946000+00:00 |
| 29 | `fact_snapshotcustomer_backup_20240408` | MANAGED | 0 | 2026-05-11T07:06:53.345000+00:00 |
| 30 | `fact_snapshotcustomer_backup_20240415` | MANAGED | 0 | 2026-05-11T07:06:54.772000+00:00 |
| 31 | `fact_snapshotcustomer_backup_20241014` | MANAGED | 0 | 2026-05-11T07:06:56.129000+00:00 |
| 32 | `fact_snapshotcustomer_backup_20241014_ver2` | MANAGED | 0 | 2026-05-11T07:06:57.652000+00:00 |
| 33 | `fact_snapshotcustomer_backup_20241016` | MANAGED | 0 | 2026-05-11T07:06:59.275000+00:00 |
| 34 | `fact_snapshotcustomer_backup_20250113` | MANAGED | 0 | 2026-05-11T07:07:00.635000+00:00 |
| 35 | `fact_snapshotcustomer_todelete` | MANAGED | 0 | 2026-05-11T07:07:02.080000+00:00 |

### A.2 TEST_PERSONAL (7)

| # | table_name | type | row_count | last_altered |
|---:|---|---|---:|---|
| 1 | `dim_affiliate_test_nitzan` | MANAGED | 0 | 2026-05-11T07:04:35.957000+00:00 |
| 2 | `dim_channel_test_nitzan` | MANAGED | 0 | 2026-05-11T06:54:24.806000+00:00 |
| 3 | `esmareporting_cysec_assaf` | MANAGED | 0 | 2026-05-11T06:55:48.162000+00:00 |
| 4 | `ext_fca_fact_customeraction_junk` | MANAGED | 0 | 2026-05-11T07:05:34.030000+00:00 |
| 5 | `fact_history_cost_junk_new` | MANAGED | 0 | 2026-05-11T07:09:10.739000+00:00 |
| 6 | `v_dim_instrument_correlation_test_full` | VIEW | (view) | 2026-05-11T07:12:13.707000+00:00 |
| 7 | `v_dim_mirror_ofir` | VIEW | (view) | 2026-05-11T07:12:14.826000+00:00 |

### A.3 DEPRECATED (5)

| # | table_name | type | row_count | last_altered |
|---:|---|---|---:|---|
| 1 | `ext_dim_customer_history_credit` | MANAGED | 0 | 2026-05-11T07:05:02.191000+00:00 |
| 2 | `ext_dim_customer_phoneverificationdetails` | MANAGED | 0 | 2026-05-11T07:05:03.591000+00:00 |
| 3 | `ext_dim_customer_worldcheck` | MANAGED | 0 | 2026-05-11T06:56:22.742000+00:00 |
| 4 | `ext_fsc_phoneverificationdetails` | MANAGED | 0 | 2026-05-11T07:06:02.661000+00:00 |
| 5 | `ext_fsc_phoneverificationdetailscloseyear` | MANAGED | 0 | 2026-05-11T07:06:04.565000+00:00 |

### A.4 INFRASTRUCTURE (15)

| # | table_name | type | row_count | last_altered |
|---:|---|---|---:|---|
| 1 | `datalaketablestatus` | MANAGED | 0 | 2026-05-11T06:53:57.337000+00:00 |
| 2 | `datalaketablestatus_id` | MANAGED | 0 | 2026-05-11T06:53:58.719000+00:00 |
| 3 | `datalaketablestatuslog` | MANAGED | 0 | 2026-05-11T06:53:59.982000+00:00 |
| 4 | `datasolutionsdwhdatabricks` | MANAGED | 0 | 2026-05-11T06:54:01.429000+00:00 |
| 5 | `datasolutionsmappingfreshservice` | MANAGED | 0 | 2026-05-11T06:54:02.662000+00:00 |
| 6 | `datasolutionstablesdate` | MANAGED | 0 | 2026-05-11T06:54:06.852000+00:00 |
| 7 | `datasolutionstablesrunind` | MANAGED | 0 | 2026-05-11T06:54:08.044000+00:00 |
| 8 | `dimpositiondatalakeexecutionlog` | MANAGED | 0 | 2026-05-11T06:55:45.537000+00:00 |
| 9 | `dwh_tables_name` | MANAGED | 0 | 2026-05-11T07:09:03.182000+00:00 |
| 10 | `log_replication` | MANAGED | 0 | 2026-05-11T06:57:57.121000+00:00 |
| 11 | `replcheck_dim_instrument_correlation` | MANAGED | 0 | 2026-05-11T06:57:58.589000+00:00 |
| 12 | `replcheck_dim_tables` | MANAGED | 0 | 2026-05-11T06:57:59.955000+00:00 |
| 13 | `replcheck_fact_customerunrealized_pnl` | MANAGED | 0 | 2026-05-11T06:58:01.355000+00:00 |
| 14 | `replcheck_fact_guru_copiers` | MANAGED | 0 | 2026-05-11T06:58:02.690000+00:00 |
| 15 | `replcheck_fact_snapshotequity` | MANAGED | 0 | 2026-05-11T06:58:04.060000+00:00 |

### A.5 VIEW (13)

| # | table_name | type | row_count | last_altered |
|---:|---|---|---:|---|
| 1 | `dim_instrument_correlation_unionedpartitions` | VIEW | (view) | 2026-05-11T07:12:11.378000+00:00 |
| 2 | `v_dim_date_for_dwhrep` | VIEW | (view) | 2026-05-11T07:12:12.769000+00:00 |
| 3 | `v_dim_mirror` | VIEW | (view) | 2026-05-11T07:12:14.323000+00:00 |
| 4 | `v_fact_customerunrealized_pnl_for_dwh_rep` | VIEW | (view) | 2026-05-11T07:12:15.939000+00:00 |
| 5 | `v_fact_regulationtransfer` | VIEW | (view) | 2026-05-11T07:12:16.438000+00:00 |
| 6 | `v_fact_snapshotcustomer` | VIEW | (view) | 2026-05-11T07:12:17.021000+00:00 |
| 7 | `v_fact_snapshotcustomer_fromdateid` | VIEW | (view) | 2026-05-11T07:12:17.562000+00:00 |
| 8 | `v_fact_snapshotequity` | VIEW | (view) | 2026-05-11T07:12:18.233000+00:00 |
| 9 | `v_fact_snapshotequity_fordwhrep` | VIEW | (view) | 2026-05-11T07:12:18.753000+00:00 |
| 10 | `v_fact_snapshotequity_fromdateid` | VIEW | (view) | 2026-05-11T07:12:19.248000+00:00 |
| 11 | `v_fca_numoflogins_mean_1q` | VIEW | (view) | 2026-05-11T07:12:19.902000+00:00 |
| 12 | `v_m2m_date_daterange` | VIEW | (view) | 2026-05-11T07:12:20.766000+00:00 |
| 13 | `vw_sts_user_operations_data_history` | VIEW | (view) | 2026-05-11T07:12:21.437000+00:00 |

### A.6 UNCLEAR (58)

| # | table_name | type | row_count | last_altered |
|---:|---|---|---:|---|
| 1 | `asyncfailedsteps` | MANAGED | 0 | 2026-05-11T06:53:53.191000+00:00 |
| 2 | `changeslog` | MANAGED | 0 | 2026-05-11T06:53:54.720000+00:00 |
| 3 | `customerstatic` | MANAGED | 0 | 2026-05-11T06:53:56.109000+00:00 |
| 4 | `dim_actiontype` | MANAGED | 0 | 2026-05-11T06:54:10.670000+00:00 |
| 5 | `dim_affiliatecosttype` | MANAGED | 0 | 2026-05-11T06:54:12.105000+00:00 |
| 6 | `dim_cardtype` | MANAGED | 0 | 2026-05-11T06:54:16.585000+00:00 |
| 7 | `dim_contacttype` | MANAGED | 0 | 2026-05-11T07:01:16.581000+00:00 |
| 8 | `dim_contracttype` | MANAGED | 0 | 2026-05-11T06:54:30.423000+00:00 |
| 9 | `dim_countryipanonymousproxytype` | MANAGED | 0 | 2026-05-11T06:54:40.028000+00:00 |
| 10 | `dim_customerchangetype` | MANAGED | 0 | 2026-05-11T06:54:44.092000+00:00 |
| 11 | `dim_desk` | MANAGED | 0 | 2026-05-11T06:54:46.708000+00:00 |
| 12 | `dim_ftdplatform` | MANAGED | 0 | 2026-05-11T06:54:55.836000+00:00 |
| 13 | `dim_instrument_correlation_archive` | MANAGED | 0 | 2026-05-11T07:08:25.157000+00:00 |
| 14 | `dim_instrument_correlation_half_records_1` | MANAGED | 0 | 2026-05-11T07:08:28.351000+00:00 |
| 15 | `dim_instrument_correlation_half_records_10` | MANAGED | 0 | 2026-05-11T07:08:29.702000+00:00 |
| 16 | `dim_instrument_correlation_half_records_11` | MANAGED | 0 | 2026-05-11T07:08:31.006000+00:00 |
| 17 | `dim_instrument_correlation_half_records_12` | MANAGED | 0 | 2026-05-11T07:08:32.563000+00:00 |
| 18 | `dim_instrument_correlation_half_records_13` | MANAGED | 0 | 2026-05-11T07:08:34.042000+00:00 |
| 19 | `dim_instrument_correlation_half_records_14` | MANAGED | 0 | 2026-05-11T07:08:35.443000+00:00 |
| 20 | `dim_instrument_correlation_half_records_15` | MANAGED | 0 | 2026-05-11T07:08:37.154000+00:00 |
| 21 | `dim_instrument_correlation_half_records_16` | MANAGED | 0 | 2026-05-11T07:08:38.604000+00:00 |
| 22 | `dim_instrument_correlation_half_records_17` | MANAGED | 0 | 2026-05-11T07:08:39.977000+00:00 |
| 23 | `dim_instrument_correlation_half_records_18` | MANAGED | 0 | 2026-05-11T07:08:41.300000+00:00 |
| 24 | `dim_instrument_correlation_half_records_19` | MANAGED | 0 | 2026-05-11T07:08:43.245000+00:00 |
| 25 | `dim_instrument_correlation_half_records_2` | MANAGED | 0 | 2026-05-11T07:08:44.865000+00:00 |
| 26 | `dim_instrument_correlation_half_records_20` | MANAGED | 0 | 2026-05-11T07:08:46.357000+00:00 |
| 27 | `dim_instrument_correlation_half_records_3` | MANAGED | 0 | 2026-05-11T07:08:47.814000+00:00 |
| 28 | `dim_instrument_correlation_half_records_4` | MANAGED | 0 | 2026-05-11T07:08:49.818000+00:00 |
| 29 | `dim_instrument_correlation_half_records_5` | MANAGED | 0 | 2026-05-11T07:08:51.316000+00:00 |
| 30 | `dim_instrument_correlation_half_records_6` | MANAGED | 0 | 2026-05-11T07:08:52.693000+00:00 |
| 31 | `dim_instrument_correlation_half_records_7` | MANAGED | 0 | 2026-05-11T07:08:54.078000+00:00 |
| 32 | `dim_instrument_correlation_half_records_8` | MANAGED | 0 | 2026-05-11T07:08:55.624000+00:00 |
| 33 | `dim_instrument_correlation_half_records_9` | MANAGED | 0 | 2026-05-11T07:08:56.990000+00:00 |
| 34 | `dim_movemoneyreason` | MANAGED | 0 | 2026-05-11T06:55:15.550000+00:00 |
| 35 | `dim_platformtype` | MANAGED | 0 | 2026-05-11T07:01:26.406000+00:00 |
| 36 | `dim_position_account_statement_amountinunitsdecimal` | MANAGED | 0 | 2026-05-11T07:04:49.167000+00:00 |
| 37 | `dim_position_account_statement_netprofit` | MANAGED | 0 | 2026-05-11T07:04:50.520000+00:00 |
| 38 | `dim_product` | MANAGED | 0 | 2026-05-11T06:55:28.726000+00:00 |
| 39 | `dim_socialnetwork` | MANAGED | 0 | 2026-05-11T06:55:38.210000+00:00 |
| 40 | `ext_dim_country` | MANAGED | 0 | 2026-05-11T06:55:59.397000+00:00 |
| 41 | `ext_dim_country_new` | MANAGED | 0 | 2026-05-11T06:56:02.431000+00:00 |
| 42 | `ext_dim_country_region_desk` | MANAGED | 0 | 2026-05-11T06:56:05.046000+00:00 |
| 43 | `ext_dim_country_test` | MANAGED | 0 | 2026-05-11T06:56:07.954000+00:00 |
| 44 | `ext_dim_instrument_classification_static` | MANAGED | 0 | 2026-05-11T06:56:25.609000+00:00 |
| 45 | `ext_dim_mirror_fundcids_staging` | MANAGED | 0 | 2026-05-11T07:01:39.340000+00:00 |
| 46 | `ext_dim_mirror_history_staging` | MANAGED | 0 | 2026-05-11T07:01:41.642000+00:00 |
| 47 | `ext_dim_mirror_real_staging` | MANAGED | 0 | 2026-05-11T07:01:43.337000+00:00 |
| 48 | `ext_dim_position_backoffice_customer` | MANAGED | 0 | 2026-05-11T07:01:44.770000+00:00 |
| 49 | `ext_dim_position_migration` | MANAGED | 0 | 2026-05-11T07:05:10.052000+00:00 |
| 50 | `ext_fca_sts_user_operations_data` | MANAGED | 0 | 2026-05-11T06:57:07.100000+00:00 |
| 51 | `ext_fsc_isdepositorcloseyear` | MANAGED | 0 | 2026-05-11T06:57:24.471000+00:00 |
| 52 | `ext_fse_positionchangelog_amount` | MANAGED | 0 | 2026-05-11T07:06:19.462000+00:00 |
| 53 | `fact_customeraction_switch_single` | MANAGED | 0 | 2026-05-11T07:06:39.121000+00:00 |
| 54 | `junk_dim_instrument_correlation_active` | MANAGED | 0 | 2026-05-11T07:11:42.526000+00:00 |
| 55 | `junk_dimpositionisbuy` | MANAGED | 0 | 2026-05-11T07:07:03.573000+00:00 |
| 56 | `sts_user_operations_data_history_test` | MANAGED | 0 | 2026-05-11T06:58:10.518000+00:00 |
| 57 | `val_match` | MANAGED | 0 | 2026-05-11T06:58:17.657000+00:00 |
| 58 | `val_target_fca` | MANAGED | 0 | 2026-05-11T07:07:09.474000+00:00 |

## B. In lake AND written by an SP (KEEP — definitely in use)

**226 objects.** No action required.

| # | table_name | type | # SPs | sample SPs |
|---:|---|---|---:|---|
| 1 | `datasolutionsprocessesstatus` | MANAGED | 1 | DWH_dbo.SP_ProcessStatusLog |
| 2 | `dim_accounttype` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 3 | `dim_affiliate` | MANAGED | 1 | DWH_dbo.SP_Dim_Affiliate |
| 4 | `dim_billingdepot` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 5 | `dim_billingprotocolmidsettingsid` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 6 | `dim_bonustype` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 7 | `dim_calculationtype` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 8 | `dim_campaign` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 9 | `dim_cashoutfeegroup` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 10 | `dim_cashoutmode` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 11 | `dim_cashoutreason` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 12 | `dim_cashoutstatus` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 13 | `dim_channel` | MANAGED | 1 | DWH_dbo.SP_Dim_Channel |
| 14 | `dim_clientwithdrawreason` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 15 | `dim_closepositionreason` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 16 | `dim_compensationreason` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 17 | `dim_costconfigurationid` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 18 | `dim_costsubtype` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 19 | `dim_costtype` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 20 | `dim_country` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse |
| 21 | `dim_countrybin` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 22 | `dim_countryip` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 23 | `dim_countryipanonymous` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse |
| 24 | `dim_credittype` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 25 | `dim_currency` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 26 | `dim_customer` | MANAGED | 2 | DWH_dbo.SP_Dim_Customer, DWH_dbo.SP_Dim_Customer_20240104 |
| 27 | `dim_date` | MANAGED | 1 | DWH_dbo.SP_PopulateDimDate |
| 28 | `dim_documentstatus` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 29 | `dim_evmatchstatus` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 30 | `dim_exchangeinfo` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 31 | `dim_executionoperationtype` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 32 | `dim_extendeduserfield` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 33 | `dim_feeoperationtypes` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 34 | `dim_fund` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 35 | `dim_fundingtype` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 36 | `dim_fundtype` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 37 | `dim_funnel` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 38 | `dim_getspreadedpricecandle60minsplitted` | MANAGED | 1 | DWH_dbo.SP_Dim_GetSpreadedPriceCandle60MinSplitted |
| 39 | `dim_getspreadedpriceusdconversionrate` | MANAGED | 2 | DWH_dbo.SP_Dim_GetSpreadedPriceUSDConversionRate, DWH_dbo.SP_Dim_GetSpreadedPriceUSDConversionRate_InsertDataForHour |
| 40 | `dim_gurustatus` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 41 | `dim_historysplitratio` | MANAGED | 1 | DWH_dbo.SP_Dim_HistorySplitRatio_DL_To_Synapse |
| 42 | `dim_instrument` | MANAGED | 2 | DWH_dbo.SP_Dim_Instrument, DWH_dbo.SP_Dim_Instrument_bkp_2025_11_24 |
| 43 | `dim_instrument_correlation` | MANAGED | 1 | DWH_dbo.JUNK_SP_Dim_Instrument_Correlation |
| 44 | `dim_instrument_correlation_groupsinstruments` | MANAGED | 1 | DWH_dbo.SP_Dim_Instrument_Correlation_Build_GroupsInstruments |
| 45 | `dim_instrument_correlation_half_records` | MANAGED | 1 | DWH_dbo.SP_Dim_Instrument_Correlation_Half_Records |
| 46 | `dim_instrument_snapshot` | MANAGED | 1 | DWH_dbo.SP_Dim_Instrument_Snapshot |
| 47 | `dim_label` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 48 | `dim_language` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 49 | `dim_manager` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 50 | `dim_mifidcategorization` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 51 | `dim_mirror` | MANAGED | 1 | DWH_dbo.SP_Dim_Mirror_DL_To_Synapse |
| 52 | `dim_mirrortype` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 53 | `dim_paymentstatus` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 54 | `dim_pendingclosurestatus` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 55 | `dim_phoneverified` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 56 | `dim_platform` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 57 | `dim_playerlevel` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 58 | `dim_playerstatus` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 59 | `dim_playerstatusreasons` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 60 | `dim_playerstatussubreasons` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 61 | `dim_position` | MANAGED | 4 | DWH_dbo.SP_Dim_Position_DL_To_Synapse, DWH_dbo.SP_Dim_Position_DL_To_Synapse_bkp_2024_08_04, DWH_dbo.SP_Dim_Position_IsPartialCloseParent, … (+1) |
| 62 | `dim_position_switch_single` | MANAGED | 1 | DWH_dbo.SP_Dim_Position_DL_To_Synapse |
| 63 | `dim_positionchangelog` | MANAGED | 1 | DWH_dbo.SP_Dim_PositionChangeLog_DL_To_Synapse |
| 64 | `dim_positionhedgeserverchangelog_snapshot` | MANAGED | 2 | DWH_dbo.SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse, DWH_dbo.SP_Dim_Position_PositionHedgeServerChangeLog |
| 65 | `dim_range` | MANAGED | 3 | DWH_dbo.SP_Fact_SnapshotCustomer, DWH_dbo.SP_Fact_SnapshotCustomer_Eyal, DWH_dbo.SP_Fact_SnapshotEquity |
| 66 | `dim_redeemreason` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 67 | `dim_redeemstatus` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 68 | `dim_regulation` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 69 | `dim_riskclassification` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 70 | `dim_riskmanagementstatus` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 71 | `dim_riskstatus` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 72 | `dim_screeningstatus` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 73 | `dim_state_and_province` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 74 | `dim_threedsresponsetypes` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 75 | `dim_verificationlevel` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 76 | `dim_verificationstatus` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 77 | `dim_worldcheck` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 78 | `dwh_status` | MANAGED | 1 | DWH_dbo.SP_DWH_Status |
| 79 | `ext_customerfinancedb_customer_firsttimedeposits` | MANAGED | 1 | DWH_dbo.SP_Dim_Customer_DL_To_Synapse |
| 80 | `ext_dim_affiliate` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 81 | `ext_dim_affiliate_customer` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 82 | `ext_dim_affiliate_ftd` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 83 | `ext_dim_affiliate_ftde` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 84 | `ext_dim_affiliate_masteraffiliate` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 85 | `ext_dim_affiliate_registrations` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 86 | `ext_dim_channel` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 87 | `ext_dim_channel_affiliate_unifycode` | MANAGED | 1 | DWH_dbo.SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse |
| 88 | `ext_dim_country_regulation` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse |
| 89 | `ext_dim_customer_2fa` | MANAGED | 1 | DWH_dbo.SP_Dim_Customer_DL_To_Synapse |
| 90 | `ext_dim_customer_affiliate` | MANAGED | 1 | DWH_dbo.SP_Dim_Customer_DL_To_Synapse |
| 91 | `ext_dim_customer_avatars` | MANAGED | 1 | DWH_dbo.SP_Dim_Customer_DL_To_Synapse |
| 92 | `ext_dim_customer_bocustomer` | MANAGED | 1 | DWH_dbo.SP_Dim_Customer_DL_To_Synapse |
| 93 | `ext_dim_customer_customer` | MANAGED | 1 | DWH_dbo.SP_Dim_Customer_DL_To_Synapse |
| 94 | `ext_dim_customer_customeridentification` | MANAGED | 1 | DWH_dbo.SP_Dim_Customer_DL_To_Synapse |
| 95 | `ext_dim_customer_customeridentification_dlt` | MANAGED | 2 | DWH_dbo.SP_Fact_SnapshotCustomer, DWH_dbo.SP_Fact_SnapshotCustomer_Eyal |
| 96 | `ext_dim_customer_document` | MANAGED | 1 | DWH_dbo.SP_Dim_Customer_DL_To_Synapse |
| 97 | `ext_dim_customer_externalid_gcid` | MANAGED | 2 | DWH_dbo.SP_Dim_Customer, DWH_dbo.SP_Dim_Customer_20240104 |
| 98 | `ext_dim_customer_phonecustomer` | MANAGED | 1 | DWH_dbo.SP_Dim_Customer_DL_To_Synapse |
| 99 | `ext_dim_customer_screeningstatusid` | MANAGED | 1 | DWH_dbo.SP_Dim_Customer_DL_To_Synapse |
| 100 | `ext_dim_customer_sf_id` | MANAGED | 1 | DWH_dbo.SP_Dim_Customer_DL_To_Synapse |
| 101 | `ext_dim_customer_stockslending` | MANAGED | 1 | DWH_dbo.SP_Dim_Customer_DL_To_Synapse |
| 102 | `ext_dim_customerstatic` | MANAGED | 1 | DWH_dbo.SP_Dim_Customer_DL_To_Synapse |
| 103 | `ext_dim_instrument_receivedonpriceservercurrent` | MANAGED | 2 | DWH_dbo.SP_Dim_Instrument, DWH_dbo.SP_Dim_Instrument_bkp_2025_11_24 |
| 104 | `ext_dim_instrument_receivedonpriceserverstatic` | MANAGED | 2 | DWH_dbo.SP_Dim_Instrument, DWH_dbo.SP_Dim_Instrument_bkp_2025_11_24 |
| 105 | `ext_dim_instrument_stockinfo_instrumentdata` | MANAGED | 2 | DWH_dbo.SP_Dim_Instrument, DWH_dbo.SP_Dim_Instrument_bkp_2025_11_24 |
| 106 | `ext_dim_instrument_stockinfo_instrumentdata_platform` | MANAGED | 2 | DWH_dbo.SP_Dim_Instrument, DWH_dbo.SP_Dim_Instrument_bkp_2025_11_24 |
| 107 | `ext_dim_manager` | MANAGED | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 108 | `ext_dim_mirror_fundcids` | MANAGED | 1 | DWH_dbo.SP_Dim_Mirror_DL_To_Synapse |
| 109 | `ext_dim_mirror_history` | MANAGED | 1 | DWH_dbo.SP_Dim_Mirror_DL_To_Synapse |
| 110 | `ext_dim_mirror_real` | MANAGED | 1 | DWH_dbo.SP_Dim_Mirror_DL_To_Synapse |
| 111 | `ext_dim_mirror_sessionid` | MANAGED | 1 | DWH_dbo.SP_Dim_Mirror_DL_To_Synapse |
| 112 | `ext_dim_position_airdrop` | MANAGED | 2 | DWH_dbo.SP_Dim_Position_DL_To_Synapse, DWH_dbo.SP_Dim_Position_DL_To_Synapse_bkp_2024_08_04 |
| 113 | `ext_dim_position_currencyprice_active` | MANAGED | 2 | DWH_dbo.SP_Dim_Position_DL_To_Synapse, DWH_dbo.SP_Dim_Position_DL_To_Synapse_bkp_2024_08_04 |
| 114 | `ext_dim_position_first_open` | MANAGED | 2 | DWH_dbo.SP_Dim_Position_DL_To_Synapse, DWH_dbo.SP_Dim_Position_DL_To_Synapse_bkp_2024_08_04 |
| 115 | `ext_dim_position_fundcids` | MANAGED | 2 | DWH_dbo.SP_Dim_Position_DL_To_Synapse, DWH_dbo.SP_Dim_Position_DL_To_Synapse_bkp_2024_08_04 |
| 116 | `ext_dim_position_hbcexecutionlog` | MANAGED | 2 | DWH_dbo.SP_Dim_Position_DL_To_Synapse, DWH_dbo.SP_Dim_Position_DL_To_Synapse_bkp_2024_08_04 |
| 117 | `ext_dim_position_history_real` | MANAGED | 3 | DWH_dbo.SP_Dim_Position_DL_To_Synapse, DWH_dbo.SP_Dim_Position_DL_To_Synapse_bkp_2024_08_04, DWH_dbo.SP_Dim_Position_HedgeType_History |
| 118 | `ext_dim_position_positionchangelog` | MANAGED | 2 | DWH_dbo.SP_Dim_Position_DL_To_Synapse, DWH_dbo.SP_Dim_Position_DL_To_Synapse_bkp_2024_08_04 |
| 119 | `ext_dim_position_positionchangelogamount` | MANAGED | 2 | DWH_dbo.SP_Dim_Position_DL_To_Synapse, DWH_dbo.SP_Dim_Position_DL_To_Synapse_bkp_2024_08_04 |
| 120 | `ext_dim_position_positionchangelogamount_changetype12` | MANAGED | 2 | DWH_dbo.SP_Dim_Position_DL_To_Synapse, DWH_dbo.SP_Dim_Position_DL_To_Synapse_bkp_2024_08_04 |
| 121 | `ext_dim_position_positionhedgeserverchangelog` | MANAGED | 1 | DWH_dbo.SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse |
| 122 | `ext_dim_position_real` | MANAGED | 3 | DWH_dbo.SP_Dim_Position_DL_To_Synapse, DWH_dbo.SP_Dim_Position_DL_To_Synapse_bkp_2024_08_04, DWH_dbo.SP_Dim_Position_HedgeType_Real |
| 123 | `ext_dim_positionchangelog` | MANAGED | 1 | DWH_dbo.SP_Dim_PositionChangeLog_DL_To_Synapse |
| 124 | `ext_dim_subchannel_unifycode` | MANAGED | 1 | DWH_dbo.SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse |
| 125 | `ext_etoro_billing_vdeposit` | MANAGED | 1 | DWH_dbo.SP_Dim_Customer_DL_To_Synapse |
| 126 | `ext_fbd_fact_billingdeposit` | MANAGED | 1 | DWH_dbo.SP_Fact_BillingDeposit_DL_To_Synapse |
| 127 | `ext_fbr_fact_billingredeem` | MANAGED | 1 | DWH_dbo.SP_Fact_BillingRedeem_DL_To_Synapse |
| 128 | `ext_fbw_fact_billingwithdraw` | MANAGED | 1 | DWH_dbo.SP_Fact_BillingWithdraw_DL_To_Synapse |
| 129 | `ext_fca_actiontypeid_14` | MANAGED | 9 | DWH_dbo.SP_Fact_CustomerAction, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, … (+6) |
| 130 | `ext_fca_backoffice_customer` | MANAGED | 5 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+2) |
| 131 | `ext_fca_billing_deposit` | MANAGED | 5 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+2) |
| 132 | `ext_fca_billing_withdraw` | MANAGED | 5 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+2) |
| 133 | `ext_fca_countryip` | MANAGED | 5 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+2) |
| 134 | `ext_fca_customer` | MANAGED | 5 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+2) |
| 135 | `ext_fca_deposit_attempt` | MANAGED | 5 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+2) |
| 136 | `ext_fca_fact_customeraction` | MANAGED | 4 | DWH_dbo.SP_Fact_CustomerAction, DWH_dbo.SP_Fact_CustomerAction_bkp_2024_08_04, DWH_dbo.SP_Fact_CustomerAction_bkp_2024_08_20, … (+1) |
| 137 | `ext_fca_history_position` | MANAGED | 5 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+2) |
| 138 | `ext_fca_mirror_session` | MANAGED | 5 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+2) |
| 139 | `ext_fca_openbook_engagement` | MANAGED | 4 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_20, … (+1) |
| 140 | `ext_fca_position_airdrop` | MANAGED | 5 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+2) |
| 141 | `ext_fca_position_session` | MANAGED | 5 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+2) |
| 142 | `ext_fca_positionchangelog` | MANAGED | 5 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+2) |
| 143 | `ext_fca_positionsprocessedforindexdividnds` | MANAGED | 5 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+2) |
| 144 | `ext_fca_real_audit_loggin` | MANAGED | 5 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+2) |
| 145 | `ext_fca_real_cashier_cashouttofunding` | MANAGED | 5 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+2) |
| 146 | `ext_fca_real_cashier_loggin` | MANAGED | 5 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+2) |
| 147 | `ext_fca_real_customer_registration` | MANAGED | 9 | DWH_dbo.SP_Fact_CustomerAction, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, … (+6) |
| 148 | `ext_fca_real_history_credit_forfactaction` | MANAGED | 5 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+2) |
| 149 | `ext_fca_real_history_credit_forfactaction_all` | MANAGED | 4 | DWH_dbo.SP_Fact_CustomerAction, DWH_dbo.SP_Fact_CustomerAction_bkp_2024_08_04, DWH_dbo.SP_Fact_CustomerAction_bkp_2024_08_20, … (+1) |
| 150 | `ext_fca_real_position` | MANAGED | 4 | DWH_dbo.SP_Fact_CustomerAction, DWH_dbo.SP_Fact_CustomerAction_bkp_2024_08_04, DWH_dbo.SP_Fact_CustomerAction_bkp_2024_08_20, … (+1) |
| 151 | `ext_fca_real_trade_position` | MANAGED | 9 | DWH_dbo.SP_Fact_CustomerAction, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, … (+6) |
| 152 | `ext_fca_tran_billing_withdraw` | MANAGED | 5 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+2) |
| 153 | `ext_fcpws_history_splitratio` | MANAGED | 2 | DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse, DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse_OLD_VER |
| 154 | `ext_fcpws_instrument` | MANAGED | 2 | DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse, DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse_OLD_VER |
| 155 | `ext_fcupnl_backofficecustomer` | MANAGED | 1 | DWH_dbo.SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse |
| 156 | `ext_fcupnl_currencypricemaxdatewithsplit` | MANAGED | 1 | DWH_dbo.SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse |
| 157 | `ext_fcupnl_dictionary_instrument` | MANAGED | 1 | DWH_dbo.SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse |
| 158 | `ext_fcupnl_getspreadedpricecandle60minsplitted` | MANAGED | 1 | DWH_dbo.SP_Load_Ext_FCUPNL_GetSpreadedPriceCandle60MinSplitted |
| 159 | `ext_fcupnl_history_mirror` | MANAGED | 1 | DWH_dbo.SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse |
| 160 | `ext_fcupnl_history_position` | MANAGED | 3 | DWH_dbo.SP_Fact_CustomerUnrealized_PnL, DWH_dbo.SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerUnrealized_PnL_V0 |
| 161 | `ext_fcupnl_history_splitratio` | MANAGED | 1 | DWH_dbo.SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse |
| 162 | `ext_fcupnl_positionchangelog` | MANAGED | 1 | DWH_dbo.SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse |
| 163 | `ext_fcupnl_trade_position` | MANAGED | 3 | DWH_dbo.SP_Fact_CustomerUnrealized_PnL, DWH_dbo.SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerUnrealized_PnL_V0 |
| 164 | `ext_fgc_guru_copiers` | MANAGED | 1 | DWH_dbo.SP_Fact_Guru_Copiers_DL_To_Synapse |
| 165 | `ext_frt_backoffice_regulationchangelog` | MANAGED | 1 | DWH_dbo.SP_Fact_RegulationTransfer_DL_To_Synapse |
| 166 | `ext_frt_backoffice_regulationchangelog_all` | MANAGED | 1 | DWH_dbo.SP_Fact_RegulationTransfer_DL_To_Synapse |
| 167 | `ext_fsc_backoffice_customer` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotCustomer_DL_To_Synapse |
| 168 | `ext_fsc_backoffice_customercloseyear` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotCustomerCloseYear_DL_To_Synapse |
| 169 | `ext_fsc_backoffice_regulationchangelog` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotCustomer_DL_To_Synapse |
| 170 | `ext_fsc_backoffice_regulationchangelog_all` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotCustomer_DL_To_Synapse |
| 171 | `ext_fsc_customer_firsttimedeposits` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotCustomer_DL_To_Synapse |
| 172 | `ext_fsc_dimcustomercloseyear` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotCustomerCloseYear_DL_To_Synapse |
| 173 | `ext_fsc_phonecustomer` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotCustomer_DL_To_Synapse |
| 174 | `ext_fsc_phonecustomercloseyear` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotCustomerCloseYear_DL_To_Synapse |
| 175 | `ext_fsc_real_customer_customer` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotCustomer_DL_To_Synapse |
| 176 | `ext_fsc_real_customer_customercloseyear` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotCustomerCloseYear_DL_To_Synapse |
| 177 | `ext_fsc_real_history_credit` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotCustomer_DL_To_Synapse |
| 178 | `ext_fsc_stockslending` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotCustomer_DL_To_Synapse |
| 179 | `ext_fse_billing_withdraw` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotEquity_DL_To_Synapse |
| 180 | `ext_fse_billing_withdrawtofunding` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotEquity_DL_To_Synapse |
| 181 | `ext_fse_fact_snapshotequity` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotEquity |
| 182 | `ext_fse_history_credit` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotEquity_DL_To_Synapse |
| 183 | `ext_fse_history_position` | MANAGED | 2 | DWH_dbo.SP_Fact_SnapshotEquity_DL_To_Synapse, DWH_dbo.SP_Fact_SnapshotEquity_TotalPositionAmount |
| 184 | `ext_fse_history_withdrawaction` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotEquity_DL_To_Synapse |
| 185 | `ext_fse_history_withdrawtofundingaction` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotEquity_DL_To_Synapse |
| 186 | `ext_fse_inprocesscashouts` | MANAGED | 2 | DWH_dbo.SP_Fact_SnapshotEquity_DL_To_Synapse, DWH_dbo.SP_Fact_SnapshotEquity_InProcessCashouts |
| 187 | `ext_fse_positionchangelog` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotEquity_DL_To_Synapse |
| 188 | `ext_fse_real_history_credit` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotEquity_DL_To_Synapse |
| 189 | `ext_fse_totalcashchangeall` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotEquity_DL_To_Synapse |
| 190 | `ext_fse_totalpositionamount` | MANAGED | 1 | DWH_dbo.SP_Fact_SnapshotEquity_TotalPositionAmount |
| 191 | `ext_fse_trade_position` | MANAGED | 2 | DWH_dbo.SP_Fact_SnapshotEquity_DL_To_Synapse, DWH_dbo.SP_Fact_SnapshotEquity_TotalPositionAmount |
| 192 | `ext_history_cost` | MANAGED | 1 | DWH_dbo.SP_Fact_History_Cost_DL_To_Synapse |
| 193 | `fact_billingdeposit` | MANAGED | 2 | DWH_dbo.SP_Fact_BillingDeposit, DWH_dbo.SP_Fact_BillingDeposit_DL_To_Synapse |
| 194 | `fact_billingredeem` | MANAGED | 1 | DWH_dbo.SP_Fact_BillingRedeem_DL_To_Synapse |
| 195 | `fact_billingwithdraw` | MANAGED | 2 | DWH_dbo.SP_Fact_BillingWithdraw, DWH_dbo.SP_Fact_BillingWithdraw_DL_To_Synapse |
| 196 | `fact_cashout_rollback` | MANAGED | 1 | DWH_dbo.SP_Fact_Cashout_Rollback_DL_To_Synapse |
| 197 | `fact_cashout_state` | MANAGED | 1 | DWH_dbo.SP_Fact_Cashout_State |
| 198 | `fact_currencypricewithsplit` | MANAGED | 2 | DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse, DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse_OLD_VER |
| 199 | `fact_customeraction` | MANAGED | 6 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, … (+3) |
| 200 | `fact_customeraction_switch` | MANAGED | 1 | DWH_dbo.SP_Fact_CustomerAction_SWITCH |
| 201 | `fact_customerunrealized_pnl` | MANAGED | 2 | DWH_dbo.SP_Fact_CustomerUnrealized_PnL, DWH_dbo.SP_Fact_CustomerUnrealized_PnL_V0 |
| 202 | `fact_customerunrealized_pnl_userapi` | MANAGED | 2 | DWH_dbo.SP_Fact_CustomerUnrealized_PnL, DWH_dbo.SP_Fact_CustomerUnrealized_PnL_V0 |
| 203 | `fact_deposit_fees` | MANAGED | 1 | DWH_dbo.SP_Fact_Deposit_Fees_DL_To_Synapse |
| 204 | `fact_deposit_state` | MANAGED | 1 | DWH_dbo.SP_Fact_Deposit_State |
| 205 | `fact_firstcustomeraction` | MANAGED | 1 | DWH_dbo.SP_Fact_FirstCustomerAction |
| 206 | `fact_guru_copiers` | MANAGED | 2 | DWH_dbo.SP_Fact_Guru_Copiers, DWH_dbo.SP_Fact_Guru_Copiers_DL_To_Synapse |
| 207 | `fact_history_cost` | MANAGED | 1 | DWH_dbo.SP_Fact_History_Cost |
| 208 | `fact_position_futures_snapshot` | MANAGED | 1 | DWH_dbo.SP_Fact_Position_Futures_Snapshot |
| 209 | `fact_regulationtransfer` | MANAGED | 2 | DWH_dbo.SP_Fact_RegulationTransfer, DWH_dbo.SP_Fact_RegulationTransfer_DL_To_Synapse |
| 210 | `fact_reverse_deposits` | MANAGED | 1 | DWH_dbo.SP_Fact_Reverse_Deposits_DL_To_Synapse |
| 211 | `fact_settlement_prices` | MANAGED | 1 | DWH_dbo.SP_Fact_Settlement_Prices |
| 212 | `fact_snapshotcustomer` | MANAGED | 2 | DWH_dbo.SP_Fact_SnapshotCustomer, DWH_dbo.SP_Fact_SnapshotCustomerCloseYear |
| 213 | `fact_snapshotequity` | MANAGED | 2 | DWH_dbo.SP_Fact_SnapshotEquity, DWH_dbo.SP_Fact_SnapshotEquity_DL_To_Synapse |
| 214 | `fact_withdraw_fees` | MANAGED | 1 | DWH_dbo.SP_Fact_Withdraw_Fees_DL_To_Synapse |
| 215 | `log_main_full` | MANAGED | 1 | DWH_dbo.SP_Log_Full |
| 216 | `parquetmetadata` | MANAGED | 2 | DWH_dbo.DeleteFromParquetMetadata, DWH_dbo.InsertIntoParquetMetadata |
| 217 | `sts_user_operations_data_history` | MANAGED | 1 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_20240507 |
| 218 | `sts_user_operations_data_history_switch` | MANAGED | 1 | DWH_dbo.SP_STS_User_Operations_Data_History_SWITCH |
| 219 | `sts_user_operations_data_history_switch_single` | MANAGED | 4 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_20, … (+1) |
| 220 | `tablesupdatesprocessesstatus` | MANAGED | 1 | DWH_dbo.SP_Log_Table_Updates |
| 221 | `util_resultsliabilities_cycle` | MANAGED | 2 | DWH_dbo.SP_Test_Liabilities_Cycle, DWH_dbo.SP_Validation_Cycle_Gap_DL_To_Synapse |
| 222 | `util_resultssourcetotarget_actions` | MANAGED | 1 | DWH_dbo.SP_ResultsSourceToTarget_Actions |
| 223 | `val_fcv_closingbalance` | MANAGED | 1 | DWH_dbo.SP_Validation_Cycle_Gap_DL_To_Synapse |
| 224 | `val_fcv_comovements` | MANAGED | 1 | DWH_dbo.SP_Validation_Cycle_Gap_DL_To_Synapse |
| 225 | `val_fcv_movementsum` | MANAGED | 1 | DWH_dbo.SP_Validation_Cycle_Gap_DL_To_Synapse |
| 226 | `val_fcv_openingbalance` | MANAGED | 1 | DWH_dbo.SP_Validation_Cycle_Gap_DL_To_Synapse |

## C. Missing from lake — an SP writes but table is NOT deployed

**11 tables.** These would cause runtime errors when the SP is called. Separate issue from pruning.
(Filtered out 19 parser false positives: CTE / temp-view names like `t`, `cte`, `temp_table_*`.)

| # | table_name | written by SP(s) |
|---:|---|---|
| 1 | `columnstorerebuildlog` | DWH_dbo.DWH_ColumnstoreTablesMaintenance |
| 2 | `dim_accountstatus` | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 3 | `dim_instrument_correlation_active` | DWH_dbo.SP_Dim_Instrument_Correlation |
| 4 | `dim_instrument_correlation_half_records_` | DWH_dbo.SP_Dim_Instrument_Correlation_FilterByInstrumentID |
| 5 | `dim_positionhedgeserverchangelog` | DWH_dbo.SP_Dim_Position_PositionHedgeServerChangeLog_backup_20210621 |
| 6 | `ext_marketpageviews` | DWH_dbo.SP_Daily_MarketPageViews_DL_To_Synapse |
| 7 | `fact_marketpageviews_switch_single` | DWH_dbo.SP_Daily_MarketPageViews_DL_To_Synapse |
| 8 | `fact_snapshotcustomer_eyal` | DWH_dbo.SP_Fact_SnapshotCustomer_Eyal |
| 9 | `job_logtable` | DWH_dbo.SP_KillTableauSessions |
| 10 | `ltv_conversions_multipliers_table` | BI_DB_dbo |
| 11 | `timeoutterminator` | DWH_dbo.SP_KillTableauSessions |

<details><summary>Parser false positives (ignore)</summary>

| name | seen in |
|---|---|
| `c` | DWH_dbo.SP_Dim_Position_DL_To_Synapse, DWH_dbo.SP_Dim_Position_DL_To_Synapse_bkp_2024_08_04 |
| `cte` | DWH_dbo.SP_Dim_GetSpreadedPriceUSDConversionRate, DWH_dbo.SP_Dim_Position_PositionHedgeServerChangeLog |
| `fact` | DWH_dbo.SP_Fact_CustomerUnrealized_PnL, DWH_dbo.SP_Fact_CustomerUnrealized_PnL_V0 |
| `t` | DWH_dbo.SP_Dim_Position_DL_To_Synapse |
| `t1` | DWH_dbo.SP_Fact_Position_Futures_Snapshot |
| `temp_table_actiontypeid14sessionid` | DWH_dbo.SP_Fact_CustomerAction, DWH_dbo.SP_Fact_CustomerAction_bkp_2024_08_04, DWH_dbo.SP_Fact_CustomerAction_bkp_2024_08_20 … |
| `temp_table_closedinsettlement` | DWH_dbo.SP_Fact_Position_Futures_Snapshot |
| `temp_table_dailycustomersnapshot` | DWH_dbo.SP_Fact_SnapshotCustomer, DWH_dbo.SP_Fact_SnapshotCustomer_Eyal |
| `temp_table_errors` | DWH_dbo.AddPartitionsToTable |
| `temp_table_ext_fse_positionchangelog_cid` | DWH_dbo.SP_Fact_SnapshotEquity |
| `temp_table_firstactions` | DWH_dbo.SP_Fact_FirstCustomerAction |
| `temp_table_holidaytable` | DWH_dbo.SP_PopulateDimDate |
| `temp_table_openatsettlement` | DWH_dbo.SP_Fact_Position_Futures_Snapshot |
| `temp_table_outputdata` | DWH_dbo.SP_Fact_SnapshotCustomer, DWH_dbo.SP_Fact_SnapshotCustomer_Eyal, DWH_dbo.SP_Fact_SnapshotEquity |
| `temp_table_positionorigin` | DWH_dbo.SP_Fact_CustomerAction, DWH_dbo.SP_Fact_CustomerAction_bkp_2024_08_04, DWH_dbo.SP_Fact_CustomerAction_bkp_2024_08_20 … |
| `temp_table_prepclosed` | DWH_dbo.SP_Fact_Position_Futures_Snapshot |
| `temp_table_prepopens` | DWH_dbo.SP_Fact_Position_Futures_Snapshot |
| `temp_table_reopenforposition` | DWH_dbo.SP_Dim_Position_ReOpen |
| `temp_table_tbl` | DWH_dbo.AddPartitionsToTable |

</details>
