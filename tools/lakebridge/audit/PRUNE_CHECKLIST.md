# `migration_tables` PRUNE CHECKLIST

Tick `[x]` = **DROP**, leave `[ ]` = **KEEP**.

When done, tell me "ready" and I'll read this file, extract the ticked entries,
and generate the `DROP TABLE` / `DROP VIEW` script.

**All 133 objects below are EMPTY (0 rows) — no data at risk if dropped.**

## A.1 BACKUP_DATED (35) — date-stamped backups, snapshots, version dupes

- [x] `datasolutionsprocessesstatus_bkp_2023_10_29`
- [x] `dim_customer_backup_20260223`
- [x] `dim_customer_channel_20260322`
- [x] `dim_instrument_back20260325`
- [ ] `dim_instrument_poc_bcp`
- [x] `dim_instrument_snapshot_12022025`
- [x] `dim_position_backup20240616`
- [x] `dim_position_backup_20250705`
- [x] `dim_position_backup_20250916`
- [x] `dim_position_switch_single_backup_20250916`
- [x] `dim_positionchangelog_bkp_2024_05_05`
- [x] `ext_dim_country_20240331`
- [x] `ext_dim_country_old_20240305`
- [x] `ext_dim_instrument_stockinfo_instrumentdata_back20250325`
- [x] `ext_dim_position_hbcexecutionlog_bkp_2023_10_17`
- [x] `ext_dim_position_real_20240430`
- [x] `ext_dim_position_real_backup_20250916`
- [x] `fact_billingwithdraw_20230531`
- [x] `fact_billingwithdraw_20230601`
- [x] `fact_cashout_state_backup_20250403`
- [x] `fact_customeraction_pnl_qa_environment`
- [x] `fact_deposit_state_backup_2025_07_22`
- [x] `fact_getspreadedpricecandle60minsplitted_for_check`
- [x] `fact_getspreadedpricecandle60minsplitted_for_check_daysbefore`
- [x] `fact_guru_copiers_backup_20241014`
- [x] `fact_guru_copiers_backup_20241014_ver2`
- [x] `fact_position_futures_snapshot_12022025`
- [x] `fact_position_futures_snapshot_backup`
- [x] `fact_snapshotcustomer_backup_20240408`
- [x] `fact_snapshotcustomer_backup_20240415`
- [x] `fact_snapshotcustomer_backup_20241014`
- [x] `fact_snapshotcustomer_backup_20241014_ver2`
- [x] `fact_snapshotcustomer_backup_20241016`
- [x] `fact_snapshotcustomer_backup_20250113`
- [x] `fact_snapshotcustomer_todelete`

## A.2 TEST_PERSONAL (7) — owner-named / junk

- [x] `dim_affiliate_test_nitzan`
- [x] `dim_channel_test_nitzan`
- [x] `esmareporting_cysec_assaf`
- [x] `ext_fca_fact_customeraction_junk`
- [x] `fact_history_cost_junk_new`
- [x] `v_dim_instrument_correlation_test_full` (VIEW)
- [x] `v_dim_mirror_ofir` (VIEW)

## A.3 DEPRECATED (5) — superseded per SP comments

- [x] `ext_dim_customer_history_credit`
- [x] `ext_dim_customer_phoneverificationdetails`
- [x] `ext_dim_customer_worldcheck`
- [x] `ext_fsc_phoneverificationdetails`
- [x] `ext_fsc_phoneverificationdetailscloseyear`

## A.4 INFRASTRUCTURE (15) — Synapse-only ops/monitoring tracking

- [x] `datalaketablestatus`
- [x] `datalaketablestatus_id`
- [x] `datalaketablestatuslog`
- [x] `datasolutionsdwhdatabricks`
- [x] `datasolutionsmappingfreshservice`
- [x] `datasolutionstablesdate`
- [x] `datasolutionstablesrunind`
- [x] `dimpositiondatalakeexecutionlog`
- [x] `dwh_tables_name`
- [x] `log_replication`
- [x] `replcheck_dim_instrument_correlation`
- [x] `replcheck_dim_tables`
- [x] `replcheck_fact_customerunrealized_pnl`
- [x] `replcheck_fact_guru_copiers`
- [x] `replcheck_fact_snapshotequity`

## A.5 VIEW (13) — reporting views, no SP populates them

- [x] `dim_instrument_correlation_unionedpartitions`
- [x] `v_dim_date_for_dwhrep`
- [x] `v_dim_mirror`
- [x] `v_fact_customerunrealized_pnl_for_dwh_rep`
- [x] `v_fact_regulationtransfer`
- [x] `v_fact_snapshotcustomer`
- [x] `v_fact_snapshotcustomer_fromdateid`
- [x] `v_fact_snapshotequity`
- [x] `v_fact_snapshotequity_fordwhrep`
- [x] `v_fact_snapshotequity_fromdateid`
- [x] `v_fca_numoflogins_mean_1q`
- [x] `v_m2m_date_daterange`
- [x] `vw_sts_user_operations_data_history`

## A.6 UNCLEAR (58) — manual review

Grouped by sub-pattern for easier scanning.

### A.6.a Sharded `dim_instrument_correlation_half_records_*` (20)

- [x] `dim_instrument_correlation_half_records_1`
- [x] `dim_instrument_correlation_half_records_2`
- [x] `dim_instrument_correlation_half_records_3`
- [x] `dim_instrument_correlation_half_records_4`
- [x] `dim_instrument_correlation_half_records_5`
- [x] `dim_instrument_correlation_half_records_6`
- [x] `dim_instrument_correlation_half_records_7`
- [x] `dim_instrument_correlation_half_records_8`
- [x] `dim_instrument_correlation_half_records_9`
- [x] `dim_instrument_correlation_half_records_10`
- [x] `dim_instrument_correlation_half_records_11`
- [x] `dim_instrument_correlation_half_records_12`
- [x] `dim_instrument_correlation_half_records_13`
- [x] `dim_instrument_correlation_half_records_14`
- [x] `dim_instrument_correlation_half_records_15`
- [x] `dim_instrument_correlation_half_records_16`
- [x] `dim_instrument_correlation_half_records_17`
- [x] `dim_instrument_correlation_half_records_18`
- [x] `dim_instrument_correlation_half_records_19`
- [x] `dim_instrument_correlation_half_records_20`

### A.6.b Lookup/dictionary tables not touched by any transpiled SP (16)

Schema-only on Databricks today. In Synapse these might be loaded by a
process we didn't pick up (or might just be dead schema). Decide per table.

- [ ] `dim_actiontype`
- [ ] `dim_affiliatecosttype`
- [ ] `dim_cardtype`
- [ ] `dim_contacttype`
- [ ] `dim_contracttype`
- [ ] `dim_countryipanonymousproxytype`
- [ ] `dim_customerchangetype`
- [ ] `dim_desk`
- [ ] `dim_ftdplatform`
- [ ] `dim_movemoneyreason`
- [ ] `dim_platformtype`
- [ ] `dim_position_account_statement_amountinunitsdecimal`
- [ ] `dim_position_account_statement_netprofit`
- [ ] `dim_product`
- [ ] `dim_socialnetwork`
- [ ] `ext_dim_instrument_classification_static`

### A.6.c Country / mirror staging variants (7)

- [x] `ext_dim_country`
- [x] `ext_dim_country_new`
- [x] `ext_dim_country_region_desk`
- [x] `ext_dim_country_test`
- [x] `ext_dim_mirror_fundcids_staging`
- [x] `ext_dim_mirror_history_staging`
- [x] `ext_dim_mirror_real_staging`

### A.6.d Assorted (15) — review case-by-case

- [x] `asyncfailedsteps`
- [x] `changeslog`
- [x] `customerstatic`
- [x] `dim_instrument_correlation_archive`
- [x] `ext_dim_position_backoffice_customer`
- [x] `ext_dim_position_migration`
- [x] `ext_fca_sts_user_operations_data`
- [x] `ext_fsc_isdepositorcloseyear`
- [x] `ext_fse_positionchangelog_amount`
- [x] `fact_customeraction_switch_single`
- [x] `junk_dim_instrument_correlation_active`
- [x] `junk_dimpositionisbuy`
- [x] `sts_user_operations_data_history_test`
- [x] `val_match`
- [x] `val_target_fca`
