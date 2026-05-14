# Prune execution result

- Targets ticked: **116**
- Dropped: **22**
- Failed: **0**
- Skipped (missing): 94

## Dropped (22)

| # | table | type | elapsed_ms |
|---:|---|---|---:|
| 1 | `ext_dim_country` | MANAGED | 460 |
| 2 | `ext_dim_country_new` | MANAGED | 533 |
| 3 | `ext_dim_country_region_desk` | MANAGED | 375 |
| 4 | `ext_dim_country_test` | MANAGED | 503 |
| 5 | `ext_dim_mirror_fundcids_staging` | MANAGED | 444 |
| 6 | `ext_dim_mirror_history_staging` | MANAGED | 455 |
| 7 | `ext_dim_mirror_real_staging` | MANAGED | 350 |
| 8 | `asyncfailedsteps` | MANAGED | 413 |
| 9 | `changeslog` | MANAGED | 410 |
| 10 | `customerstatic` | MANAGED | 439 |
| 11 | `dim_instrument_correlation_archive` | MANAGED | 415 |
| 12 | `ext_dim_position_backoffice_customer` | MANAGED | 348 |
| 13 | `ext_dim_position_migration` | MANAGED | 45467 |
| 14 | `ext_fca_sts_user_operations_data` | MANAGED | 369 |
| 15 | `ext_fsc_isdepositorcloseyear` | MANAGED | 359 |
| 16 | `ext_fse_positionchangelog_amount` | MANAGED | 443 |
| 17 | `fact_customeraction_switch_single` | MANAGED | 441 |
| 18 | `junk_dim_instrument_correlation_active` | MANAGED | 388 |
| 19 | `junk_dimpositionisbuy` | MANAGED | 410 |
| 20 | `sts_user_operations_data_history_test` | MANAGED | 451 |
| 21 | `val_match` | MANAGED | 390 |
| 22 | `val_target_fca` | MANAGED | 368 |
## Skipped (missing in lake) (94)

- `datasolutionsprocessesstatus_bkp_2023_10_29`
- `dim_customer_backup_20260223`
- `dim_customer_channel_20260322`
- `dim_instrument_back20260325`
- `dim_instrument_snapshot_12022025`
- `dim_position_backup20240616`
- `dim_position_backup_20250705`
- `dim_position_backup_20250916`
- `dim_position_switch_single_backup_20250916`
- `dim_positionchangelog_bkp_2024_05_05`
- `ext_dim_country_20240331`
- `ext_dim_country_old_20240305`
- `ext_dim_instrument_stockinfo_instrumentdata_back20250325`
- `ext_dim_position_hbcexecutionlog_bkp_2023_10_17`
- `ext_dim_position_real_20240430`
- `ext_dim_position_real_backup_20250916`
- `fact_billingwithdraw_20230531`
- `fact_billingwithdraw_20230601`
- `fact_cashout_state_backup_20250403`
- `fact_customeraction_pnl_qa_environment`
- `fact_deposit_state_backup_2025_07_22`
- `fact_getspreadedpricecandle60minsplitted_for_check`
- `fact_getspreadedpricecandle60minsplitted_for_check_daysbefore`
- `fact_guru_copiers_backup_20241014`
- `fact_guru_copiers_backup_20241014_ver2`
- `fact_position_futures_snapshot_12022025`
- `fact_position_futures_snapshot_backup`
- `fact_snapshotcustomer_backup_20240408`
- `fact_snapshotcustomer_backup_20240415`
- `fact_snapshotcustomer_backup_20241014`
- `fact_snapshotcustomer_backup_20241014_ver2`
- `fact_snapshotcustomer_backup_20241016`
- `fact_snapshotcustomer_backup_20250113`
- `fact_snapshotcustomer_todelete`
- `dim_affiliate_test_nitzan`
- `dim_channel_test_nitzan`
- `esmareporting_cysec_assaf`
- `ext_fca_fact_customeraction_junk`
- `fact_history_cost_junk_new`
- `v_dim_instrument_correlation_test_full`
- `v_dim_mirror_ofir`
- `ext_dim_customer_history_credit`
- `ext_dim_customer_phoneverificationdetails`
- `ext_dim_customer_worldcheck`
- `ext_fsc_phoneverificationdetails`
- `ext_fsc_phoneverificationdetailscloseyear`
- `datalaketablestatus`
- `datalaketablestatus_id`
- `datalaketablestatuslog`
- `datasolutionsdwhdatabricks`
- `datasolutionsmappingfreshservice`
- `datasolutionstablesdate`
- `datasolutionstablesrunind`
- `dimpositiondatalakeexecutionlog`
- `dwh_tables_name`
- `log_replication`
- `replcheck_dim_instrument_correlation`
- `replcheck_dim_tables`
- `replcheck_fact_customerunrealized_pnl`
- `replcheck_fact_guru_copiers`
- `replcheck_fact_snapshotequity`
- `dim_instrument_correlation_unionedpartitions`
- `v_dim_date_for_dwhrep`
- `v_dim_mirror`
- `v_fact_customerunrealized_pnl_for_dwh_rep`
- `v_fact_regulationtransfer`
- `v_fact_snapshotcustomer`
- `v_fact_snapshotcustomer_fromdateid`
- `v_fact_snapshotequity`
- `v_fact_snapshotequity_fordwhrep`
- `v_fact_snapshotequity_fromdateid`
- `v_fca_numoflogins_mean_1q`
- `v_m2m_date_daterange`
- `vw_sts_user_operations_data_history`
- `dim_instrument_correlation_half_records_1`
- `dim_instrument_correlation_half_records_2`
- `dim_instrument_correlation_half_records_3`
- `dim_instrument_correlation_half_records_4`
- `dim_instrument_correlation_half_records_5`
- `dim_instrument_correlation_half_records_6`
- `dim_instrument_correlation_half_records_7`
- `dim_instrument_correlation_half_records_8`
- `dim_instrument_correlation_half_records_9`
- `dim_instrument_correlation_half_records_10`
- `dim_instrument_correlation_half_records_11`
- `dim_instrument_correlation_half_records_12`
- `dim_instrument_correlation_half_records_13`
- `dim_instrument_correlation_half_records_14`
- `dim_instrument_correlation_half_records_15`
- `dim_instrument_correlation_half_records_16`
- `dim_instrument_correlation_half_records_17`
- `dim_instrument_correlation_half_records_18`
- `dim_instrument_correlation_half_records_19`
- `dim_instrument_correlation_half_records_20`
