# `main.<schema>` mirror-gap audit

For every of the 226 tables in `dwh_daily_process.migration_tables` that an SP writes to, we searched `main.<any_schema>.*` for a twin mirror using these naming conventions:

- `gold_sql_dp_prod_we_dwh_dbo_<table>` (with or without `_masked` suffix)
- `bronze_<sourcedb>_<schema>_<table>`
- bare `<table>`

## Result

- **Has twin** in `main.*`: **72**
- **NO twin in `main.*`**: **154** _but only the non-Ext_ ones are real gaps DE must fix; Ext_ tables are internal staging built by `*_DL_To_Synapse` SPs and don't need a main.* mirror._

---

## Part 1 — Real gaps (DE must add): 40

These tables are consumer-facing outputs (Dim_, Fact_, util/val, logging, process-status) that have no `main.*` mirror. When Databricks SPs become the production writer, downstream consumers (reports, dashboards, other SPs that read from `main.*`) will fail unless these are added to the generic replication pipeline.

### Dim_* (15)

| # | table | # SPs | sample SPs |
|---:|---|---:|---|
| 1 | `dim_billingprotocolmidsettingsid` | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 2 | `dim_calculationtype` | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 3 | `dim_costconfigurationid` | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 4 | `dim_costsubtype` | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 5 | `dim_costtype` | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 6 | `dim_countryipanonymous` | 1 | DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse |
| 7 | `dim_executionoperationtype` | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 8 | `dim_feeoperationtypes` | 1 | DWH_dbo.SP_Dictionaries_DL_To_Synapse |
| 9 | `dim_getspreadedpricecandle60minsplitted` | 1 | DWH_dbo.SP_Dim_GetSpreadedPriceCandle60MinSplitted |
| 10 | `dim_getspreadedpriceusdconversionrate` | 2 | DWH_dbo.SP_Dim_GetSpreadedPriceUSDConversionRate, DWH_dbo.SP_Dim_GetSpreadedPriceUSDConversionRate_InsertDataForHour |
| 11 | `dim_instrument_correlation_groupsinstruments` | 1 | DWH_dbo.SP_Dim_Instrument_Correlation_Build_GroupsInstruments |
| 12 | `dim_instrument_correlation_half_records` | 1 | DWH_dbo.SP_Dim_Instrument_Correlation_Half_Records |
| 13 | `dim_instrument_snapshot` | 1 | DWH_dbo.SP_Dim_Instrument_Snapshot |
| 14 | `dim_position_switch_single` | 1 | DWH_dbo.SP_Dim_Position_DL_To_Synapse |
| 15 | `dim_positionhedgeserverchangelog_snapshot` | 2 | DWH_dbo.SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse, DWH_dbo.SP_Dim_Position_PositionHedgeServerChangeLog |

### Fact_* (12)

| # | table | # SPs | sample SPs |
|---:|---|---:|---|
| 1 | `fact_cashout_rollback` | 1 | DWH_dbo.SP_Fact_Cashout_Rollback_DL_To_Synapse |
| 2 | `fact_cashout_state` | 1 | DWH_dbo.SP_Fact_Cashout_State |
| 3 | `fact_customeraction_switch` | 1 | DWH_dbo.SP_Fact_CustomerAction_SWITCH |
| 4 | `fact_customerunrealized_pnl_userapi` | 2 | DWH_dbo.SP_Fact_CustomerUnrealized_PnL, DWH_dbo.SP_Fact_CustomerUnrealized_PnL_V0 |
| 5 | `fact_deposit_fees` | 1 | DWH_dbo.SP_Fact_Deposit_Fees_DL_To_Synapse |
| 6 | `fact_deposit_state` | 1 | DWH_dbo.SP_Fact_Deposit_State |
| 7 | `fact_position_futures_snapshot` | 1 | DWH_dbo.SP_Fact_Position_Futures_Snapshot |
| 8 | `fact_reverse_deposits` | 1 | DWH_dbo.SP_Fact_Reverse_Deposits_DL_To_Synapse |
| 9 | `fact_settlement_prices` | 1 | DWH_dbo.SP_Fact_Settlement_Prices |
| 10 | `fact_snapshotcustomer` | 2 | DWH_dbo.SP_Fact_SnapshotCustomer, DWH_dbo.SP_Fact_SnapshotCustomerCloseYear |
| 11 | `fact_snapshotequity` | 2 | DWH_dbo.SP_Fact_SnapshotEquity, DWH_dbo.SP_Fact_SnapshotEquity_DL_To_Synapse |
| 12 | `fact_withdraw_fees` | 1 | DWH_dbo.SP_Fact_Withdraw_Fees_DL_To_Synapse |

### Validation / util (6)

| # | table | # SPs | sample SPs |
|---:|---|---:|---|
| 1 | `util_resultsliabilities_cycle` | 2 | DWH_dbo.SP_Test_Liabilities_Cycle, DWH_dbo.SP_Validation_Cycle_Gap_DL_To_Synapse |
| 2 | `util_resultssourcetotarget_actions` | 1 | DWH_dbo.SP_ResultsSourceToTarget_Actions |
| 3 | `val_fcv_closingbalance` | 1 | DWH_dbo.SP_Validation_Cycle_Gap_DL_To_Synapse |
| 4 | `val_fcv_comovements` | 1 | DWH_dbo.SP_Validation_Cycle_Gap_DL_To_Synapse |
| 5 | `val_fcv_movementsum` | 1 | DWH_dbo.SP_Validation_Cycle_Gap_DL_To_Synapse |
| 6 | `val_fcv_openingbalance` | 1 | DWH_dbo.SP_Validation_Cycle_Gap_DL_To_Synapse |

### Other (7)

| # | table | # SPs | sample SPs |
|---:|---|---:|---|
| 1 | `datasolutionsprocessesstatus` | 1 | DWH_dbo.SP_ProcessStatusLog |
| 2 | `dwh_status` | 1 | DWH_dbo.SP_DWH_Status |
| 3 | `log_main_full` | 1 | DWH_dbo.SP_Log_Full |
| 4 | `parquetmetadata` | 2 | DWH_dbo.DeleteFromParquetMetadata, DWH_dbo.InsertIntoParquetMetadata |
| 5 | `sts_user_operations_data_history_switch` | 1 | DWH_dbo.SP_STS_User_Operations_Data_History_SWITCH |
| 6 | `sts_user_operations_data_history_switch_single` | 4 | DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_04, DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse_bkp_2024_08_20 +1 |
| 7 | `tablesupdatesprocessesstatus` | 1 | DWH_dbo.SP_Log_Table_Updates |


#### Copy-paste list for DE ticket

```
DWH_dbo.dim_billingprotocolmidsettingsid
DWH_dbo.dim_calculationtype
DWH_dbo.dim_costconfigurationid
DWH_dbo.dim_costsubtype
DWH_dbo.dim_costtype
DWH_dbo.dim_countryipanonymous
DWH_dbo.dim_executionoperationtype
DWH_dbo.dim_feeoperationtypes
DWH_dbo.dim_getspreadedpricecandle60minsplitted
DWH_dbo.dim_getspreadedpriceusdconversionrate
DWH_dbo.dim_instrument_correlation_groupsinstruments
DWH_dbo.dim_instrument_correlation_half_records
DWH_dbo.dim_instrument_snapshot
DWH_dbo.dim_position_switch_single
DWH_dbo.dim_positionhedgeserverchangelog_snapshot
DWH_dbo.fact_cashout_rollback
DWH_dbo.fact_cashout_state
DWH_dbo.fact_customeraction_switch
DWH_dbo.fact_customerunrealized_pnl_userapi
DWH_dbo.fact_deposit_fees
DWH_dbo.fact_deposit_state
DWH_dbo.fact_position_futures_snapshot
DWH_dbo.fact_reverse_deposits
DWH_dbo.fact_settlement_prices
DWH_dbo.fact_snapshotcustomer
DWH_dbo.fact_snapshotequity
DWH_dbo.fact_withdraw_fees
DWH_dbo.datasolutionsprocessesstatus
DWH_dbo.dwh_status
DWH_dbo.log_main_full
DWH_dbo.parquetmetadata
DWH_dbo.sts_user_operations_data_history_switch
DWH_dbo.sts_user_operations_data_history_switch_single
DWH_dbo.tablesupdatesprocessesstatus
DWH_dbo.util_resultsliabilities_cycle
DWH_dbo.util_resultssourcetotarget_actions
DWH_dbo.val_fcv_closingbalance
DWH_dbo.val_fcv_comovements
DWH_dbo.val_fcv_movementsum
DWH_dbo.val_fcv_openingbalance
```

---

## Part 2 — Ext_* internal staging (114)

Listed for completeness only. These are NOT a DE ask — they are populated by `*_DL_To_Synapse` migration SPs from sources in `daily_snapshot` views and consumed only by other migration SPs inside `migration_tables`. No `main.*` mirror is required.

<details><summary>Expand to see the 114 Ext_* tables</summary>

| # | table | # SPs |
|---:|---|---:|
| 1 | `ext_customerfinancedb_customer_firsttimedeposits` | 1 |
| 2 | `ext_dim_affiliate` | 1 |
| 3 | `ext_dim_affiliate_customer` | 1 |
| 4 | `ext_dim_affiliate_ftd` | 1 |
| 5 | `ext_dim_affiliate_ftde` | 1 |
| 6 | `ext_dim_affiliate_masteraffiliate` | 1 |
| 7 | `ext_dim_affiliate_registrations` | 1 |
| 8 | `ext_dim_channel` | 1 |
| 9 | `ext_dim_channel_affiliate_unifycode` | 1 |
| 10 | `ext_dim_country_regulation` | 1 |
| 11 | `ext_dim_customer_2fa` | 1 |
| 12 | `ext_dim_customer_affiliate` | 1 |
| 13 | `ext_dim_customer_avatars` | 1 |
| 14 | `ext_dim_customer_bocustomer` | 1 |
| 15 | `ext_dim_customer_customer` | 1 |
| 16 | `ext_dim_customer_customeridentification` | 1 |
| 17 | `ext_dim_customer_customeridentification_dlt` | 2 |
| 18 | `ext_dim_customer_document` | 1 |
| 19 | `ext_dim_customer_externalid_gcid` | 2 |
| 20 | `ext_dim_customer_phonecustomer` | 1 |
| 21 | `ext_dim_customer_screeningstatusid` | 1 |
| 22 | `ext_dim_customer_sf_id` | 1 |
| 23 | `ext_dim_customer_stockslending` | 1 |
| 24 | `ext_dim_customerstatic` | 1 |
| 25 | `ext_dim_instrument_receivedonpriceservercurrent` | 2 |
| 26 | `ext_dim_instrument_receivedonpriceserverstatic` | 2 |
| 27 | `ext_dim_instrument_stockinfo_instrumentdata` | 2 |
| 28 | `ext_dim_instrument_stockinfo_instrumentdata_platform` | 2 |
| 29 | `ext_dim_manager` | 1 |
| 30 | `ext_dim_mirror_fundcids` | 1 |
| 31 | `ext_dim_mirror_history` | 1 |
| 32 | `ext_dim_mirror_real` | 1 |
| 33 | `ext_dim_mirror_sessionid` | 1 |
| 34 | `ext_dim_position_airdrop` | 2 |
| 35 | `ext_dim_position_currencyprice_active` | 2 |
| 36 | `ext_dim_position_first_open` | 2 |
| 37 | `ext_dim_position_fundcids` | 2 |
| 38 | `ext_dim_position_hbcexecutionlog` | 2 |
| 39 | `ext_dim_position_history_real` | 3 |
| 40 | `ext_dim_position_positionchangelog` | 2 |
| 41 | `ext_dim_position_positionchangelogamount` | 2 |
| 42 | `ext_dim_position_positionchangelogamount_changetype12` | 2 |
| 43 | `ext_dim_position_positionhedgeserverchangelog` | 1 |
| 44 | `ext_dim_position_real` | 3 |
| 45 | `ext_dim_positionchangelog` | 1 |
| 46 | `ext_dim_subchannel_unifycode` | 1 |
| 47 | `ext_etoro_billing_vdeposit` | 1 |
| 48 | `ext_fbd_fact_billingdeposit` | 1 |
| 49 | `ext_fbr_fact_billingredeem` | 1 |
| 50 | `ext_fbw_fact_billingwithdraw` | 1 |
| 51 | `ext_fca_actiontypeid_14` | 9 |
| 52 | `ext_fca_backoffice_customer` | 5 |
| 53 | `ext_fca_billing_deposit` | 5 |
| 54 | `ext_fca_billing_withdraw` | 5 |
| 55 | `ext_fca_countryip` | 5 |
| 56 | `ext_fca_customer` | 5 |
| 57 | `ext_fca_deposit_attempt` | 5 |
| 58 | `ext_fca_fact_customeraction` | 4 |
| 59 | `ext_fca_history_position` | 5 |
| 60 | `ext_fca_mirror_session` | 5 |
| 61 | `ext_fca_openbook_engagement` | 4 |
| 62 | `ext_fca_position_airdrop` | 5 |
| 63 | `ext_fca_position_session` | 5 |
| 64 | `ext_fca_positionchangelog` | 5 |
| 65 | `ext_fca_positionsprocessedforindexdividnds` | 5 |
| 66 | `ext_fca_real_audit_loggin` | 5 |
| 67 | `ext_fca_real_cashier_cashouttofunding` | 5 |
| 68 | `ext_fca_real_cashier_loggin` | 5 |
| 69 | `ext_fca_real_customer_registration` | 9 |
| 70 | `ext_fca_real_history_credit_forfactaction` | 5 |
| 71 | `ext_fca_real_history_credit_forfactaction_all` | 4 |
| 72 | `ext_fca_real_position` | 4 |
| 73 | `ext_fca_real_trade_position` | 9 |
| 74 | `ext_fca_tran_billing_withdraw` | 5 |
| 75 | `ext_fcpws_history_splitratio` | 2 |
| 76 | `ext_fcpws_instrument` | 2 |
| 77 | `ext_fcupnl_backofficecustomer` | 1 |
| 78 | `ext_fcupnl_currencypricemaxdatewithsplit` | 1 |
| 79 | `ext_fcupnl_dictionary_instrument` | 1 |
| 80 | `ext_fcupnl_getspreadedpricecandle60minsplitted` | 1 |
| 81 | `ext_fcupnl_history_mirror` | 1 |
| 82 | `ext_fcupnl_history_position` | 3 |
| 83 | `ext_fcupnl_history_splitratio` | 1 |
| 84 | `ext_fcupnl_positionchangelog` | 1 |
| 85 | `ext_fcupnl_trade_position` | 3 |
| 86 | `ext_fgc_guru_copiers` | 1 |
| 87 | `ext_frt_backoffice_regulationchangelog` | 1 |
| 88 | `ext_frt_backoffice_regulationchangelog_all` | 1 |
| 89 | `ext_fsc_backoffice_customer` | 1 |
| 90 | `ext_fsc_backoffice_customercloseyear` | 1 |
| 91 | `ext_fsc_backoffice_regulationchangelog` | 1 |
| 92 | `ext_fsc_backoffice_regulationchangelog_all` | 1 |
| 93 | `ext_fsc_customer_firsttimedeposits` | 1 |
| 94 | `ext_fsc_dimcustomercloseyear` | 1 |
| 95 | `ext_fsc_phonecustomer` | 1 |
| 96 | `ext_fsc_phonecustomercloseyear` | 1 |
| 97 | `ext_fsc_real_customer_customer` | 1 |
| 98 | `ext_fsc_real_customer_customercloseyear` | 1 |
| 99 | `ext_fsc_real_history_credit` | 1 |
| 100 | `ext_fsc_stockslending` | 1 |
| 101 | `ext_fse_billing_withdraw` | 1 |
| 102 | `ext_fse_billing_withdrawtofunding` | 1 |
| 103 | `ext_fse_fact_snapshotequity` | 1 |
| 104 | `ext_fse_history_credit` | 1 |
| 105 | `ext_fse_history_position` | 2 |
| 106 | `ext_fse_history_withdrawaction` | 1 |
| 107 | `ext_fse_history_withdrawtofundingaction` | 1 |
| 108 | `ext_fse_inprocesscashouts` | 2 |
| 109 | `ext_fse_positionchangelog` | 1 |
| 110 | `ext_fse_real_history_credit` | 1 |
| 111 | `ext_fse_totalcashchangeall` | 1 |
| 112 | `ext_fse_totalpositionamount` | 1 |
| 113 | `ext_fse_trade_position` | 2 |
| 114 | `ext_history_cost` | 1 |

</details>

---

## Has twin (KEEP — already mirrored) — 72 tables

_See `main_mirror_gaps.csv` for the full table→twin mapping._
