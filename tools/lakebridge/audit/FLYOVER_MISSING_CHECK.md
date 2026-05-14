# Fly-over check on 'missing twin' list

Checked 40 non-Ext missing tables against every object under `main.*` using exact-pattern + permissive substring matching (token must be word-boundary delimited).

- Twin **found** after deeper search: **3**
- Still truly missing: **37**

## Twins discovered in deeper search

| migration_tables.<table> | main.<schema>.<twin> | type |
|---|---|---|
| `datasolutionsprocessesstatus` | `main.regtech.gold_regreportdb_prod_dbo_datasolutionsprocessesstatus` | EXTERNAL |
| `fact_snapshotcustomer` | `main.bi_output.vg_fact_snapshotcustomer_for_emoney_genie` | VIEW |
| `fact_snapshotcustomer` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | EXTERNAL |
| `fact_snapshotcustomer` | `main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer` | EXTERNAL |
| `fact_snapshotcustomer` | `main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid` | EXTERNAL |
| `fact_snapshotequity` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid` | EXTERNAL |

## Still truly missing

- `dim_billingprotocolmidsettingsid`
- `dim_calculationtype`
- `dim_costconfigurationid`
- `dim_costsubtype`
- `dim_costtype`
- `dim_countryipanonymous`
- `dim_executionoperationtype`
- `dim_feeoperationtypes`
- `dim_getspreadedpricecandle60minsplitted`
- `dim_getspreadedpriceusdconversionrate`
- `dim_instrument_correlation_groupsinstruments`
- `dim_instrument_correlation_half_records`
- `dim_instrument_snapshot`
- `dim_position_switch_single`
- `dim_positionhedgeserverchangelog_snapshot`
- `dwh_status`
- `fact_cashout_rollback`
- `fact_cashout_state`
- `fact_customeraction_switch`
- `fact_customerunrealized_pnl_userapi`
- `fact_deposit_fees`
- `fact_deposit_state`
- `fact_position_futures_snapshot`
- `fact_reverse_deposits`
- `fact_settlement_prices`
- `fact_withdraw_fees`
- `log_main_full`
- `parquetmetadata`
- `sts_user_operations_data_history_switch`
- `sts_user_operations_data_history_switch_single`
- `tablesupdatesprocessesstatus`
- `util_resultsliabilities_cycle`
- `util_resultssourcetotarget_actions`
- `val_fcv_closingbalance`
- `val_fcv_comovements`
- `val_fcv_movementsum`
- `val_fcv_openingbalance`
