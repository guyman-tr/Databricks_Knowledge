# Synapse -> Databricks SP Migration: Stub Inventory

All 127 source stored procedures from `DWH_dbo` are deployed to `dwh_daily_process.migration_tables`. This document tracks which of them have **full transpiled bodies** vs. which were deployed as **no-op stubs** that need attention before production cutover.

## What is a stub?

A stub is a procedure deployed to Unity Catalog with its original name and parameter signature intact, but whose body is a no-op:

```sql
CREATE OR REPLACE PROCEDURE
  dwh_daily_process.migration_tables.<name>(<original sig>)
LANGUAGE SQL
AS BEGIN
  -- [stub] <name> -- helper SP not migrated; calls are no-ops.
  SELECT 1;
END;
```

Callers can `CALL` the stub without error -- it simply returns. This keeps the migration namespace complete (no `PROCEDURE_NOT_FOUND`) while we decide whether to fully implement, retire, or leave the SP as a no-op.

## Summary

| Class | Count | Action before cutover |
|---|---:|---|
| Full transpiled body (production-ready) | 91 | QA against Synapse output |
| Helper / no-op (Synapse-only concept) | 23 | Leave as no-op; document why |
| Backup / dated snapshot | 13 | Drop from UC at cutover |
| Orphan utility (no active callers) | 0 | Drop or re-author later |
| **TOTAL** | **127** | |

## Manually re-authored procedures (previously stubs)  (4)

These four SPs were originally stubbed because BladeBridge couldn't produce viable output. They were re-authored by hand from the Synapse source intent (and validated against the deployed schema in `dwh_daily_process.migration_tables`). The manual sources live in `tools/lakebridge/manual_rewrites/` and are deployed via `deploy_manual_rewrites.py`.

| # | Procedure | Reason for rewrite | Status |
|---:|---|---|---|
| 1 | `sp_dim_getspreadedpriceusdconversionrate_insertdataforhour` | Stray `;` between CTE and INSERT broke binding | Deployed, smoke-test passes |
| 2 | `sp_dim_instrument_correlation_build_groupsinstruments` | `DECLARE VARIABLE` + stray `;` + debug `SELECT` lines | Deployed, smoke-test passes |
| 3 | `sp_dim_positionhedgeserverchangelog_dl_to_synapse` | COALESCE/CAST mangled; MERGE USING corrupted; bad DATEDIFF | Deployed, smoke-test passes |
| 4 | `sp_fact_position_futures_snapshot` | `MERGE INTO <TEMP VIEW>` unsupported; redesigned as 16 chained TEMPORARY VIEWs + single INSERT | Deployed, smoke-test passes |

The futures-snapshot rewrite was the only true architectural change: the original mutated `#temp` tables via repeated `MERGE INTO` / `UPDATE`, which Databricks doesn't allow on TEMPORARY VIEWs. The new version bakes every "update" step into the next view as a `LEFT JOIN + COALESCE`, producing the final fact rows in a single `INSERT` off the view chain. The session-scoped views are dropped at the end so nothing leaks.

## Helper / no-op (intentional)  (23)

These represent Synapse / SQL DW concepts that have **no Databricks equivalent** (table partitions, columnstore indexes, workload groups, `sys.dm_pdw_*` monitoring, PolyBase `COPY INTO`, etc.) or one-time setup procs that have already been satisfied in Databricks by other means. **They are intentionally no-ops** -- callers invoke them to remain source-compatible, but no work is needed.

| # | Procedure | Active callers (in deployed set) |
|---:|---|---|
| 1 | `addpartitionstotable` | `DWH_dbo.AddPartitionsToDWH` |
| 2 | `checkifpartitionexists` | _none_ |
| 3 | `copyintotable` | _none_ |
| 4 | `copyintotable_bydate` | _none_ |
| 5 | `createparquetcopytable` | _none_ |
| 6 | `createparquetcopytablefromjson` | _none_ |
| 7 | `createparquetcopytablefromjson_new` | _none_ |
| 8 | `dba_createpartitioninfrabydateint` | _none_ |
| 9 | `dba_openfuturepartitions` | _none_ |
| 10 | `dwh_columnstoretablesmaintenance` | _none_ |
| 11 | `junk_sp_dim_instrument_correlation` | _none_ |
| 12 | `sp_alterworkloadgroup` | _none_ |
| 13 | `sp_check_dim_instrument_correlation_differences` | _none_ |
| 14 | `sp_check_pnlindollars_in_dwh_staging_etoro_trade_openpositionendofday` | `DWH_dbo.SP_Dim_Position_DL_To_Synapse`, `DWH_dbo.SP_Dim_Position_DL_To_Synapse_bkp_2024_08_04` |
| 15 | `sp_currencypriceexists_for_check` | _none_ |
| 16 | `sp_dwh_status` | _none_ |
| 17 | `sp_fact_customeraction_create_switch_single` | _none_ |
| 18 | `sp_fact_customerunrealized_pnl_userapi_for_check` | _none_ |
| 19 | `sp_fact_getspreadedpricecandle60minsplitted_for_check` | _none_ |
| 20 | `sp_log_full` | _none_ |
| 21 | `sp_populatedimdate` | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| 22 | `sp_processstatuslog` | _none_ |
| 23 | `sp_remove_ci_from_tables` | _none_ |

## Backup / dated snapshot  (13)

Older versions of a production SP, kept in source for historical reference (suffixes like `_bkp_2024_08_04`, `_20240507`, `_v0`, `_eyal`). Stubbed so the namespace matches the source repo verbatim. **Drop these from UC at cutover** -- the live SP supersedes them.

| # | Procedure | Active callers (in deployed set) |
|---:|---|---|
| 1 | `sp_dim_customer_20240104` | _none_ |
| 2 | `sp_dim_instrument_bkp_2025_11_24` | _none_ |
| 3 | `sp_dim_position_dl_to_synapse_bkp_2024_08_04` | _none_ |
| 4 | `sp_dim_position_positionhedgeserverchangelog_backup_20210621` | _none_ |
| 5 | `sp_fact_customeraction_bkp_2024_08_04` | _none_ |
| 6 | `sp_fact_customeraction_bkp_2024_08_20` | _none_ |
| 7 | `sp_fact_customeraction_bkp_2024_09_25` | _none_ |
| 8 | `sp_fact_customeraction_dl_to_synapse_20240507` | _none_ |
| 9 | `sp_fact_customeraction_dl_to_synapse_bkp_2024_08_04` | _none_ |
| 10 | `sp_fact_customeraction_dl_to_synapse_bkp_2024_08_20` | _none_ |
| 11 | `sp_fact_customeraction_dl_to_synapse_bkp_2024_09_25` | _none_ |
| 12 | `sp_fact_customerunrealized_pnl_v0` | _none_ |
| 13 | `sp_fact_snapshotcustomer_eyal` | _none_ |

## Orphan utility  (0)

Transpilation broke but no other deployed SP actively calls them. Stubbed so `SHOW PROCEDURES` is complete. Re-author only if a downstream team needs them.

| # | Procedure | Active callers (in deployed set) |
|---:|---|---|

## Full transpiled bodies (production-ready candidates)

91 procedures (87 auto-transpiled + 4 manually re-authored) are deployed with their full original logic. Each still needs end-to-end QA against the equivalent Synapse SP output before being promoted to the production pipeline.

<details>
<summary>Click to expand the list of 91 procedures</summary>

1. `addpartitionstodwh`
2. `deletefromparquetmetadata`
3. `insertintoparquetmetadata`
4. `kys_tableswithsmallcompressedrowgroups`
5. `sp_bi_db_ltv_conversions_multipliers_table`
6. `sp_count_currencypricemaxdatewithsplit`
7. `sp_daily_marketpageviews_dl_to_synapse`
8. `sp_dictionaries_country_dl_to_synapse`
9. `sp_dictionaries_dl_to_synapse`
10. `sp_dim_affiliate`
11. `sp_dim_channel`
12. `sp_dim_channel_affiliate_unifycode_dl_to_synapse`
13. `sp_dim_customer`
14. `sp_dim_customer_dl_to_synapse`
15. `sp_dim_getspreadedpricecandle60minsplitted`
16. `sp_dim_getspreadedpriceusdconversionrate`
17. `sp_dim_getspreadedpriceusdconversionrate_deletebydaterange`
18. `sp_dim_getspreadedpriceusdconversionrate_insertdataforhour`
19. `sp_dim_historysplitratio_dl_to_synapse`
20. `sp_dim_instrument`
21. `sp_dim_instrument_correlation`
22. `sp_dim_instrument_correlation_build_groupsinstruments`
23. `sp_dim_instrument_correlation_bygrouprange`
24. `sp_dim_instrument_correlation_filterbyinstrumentid`
25. `sp_dim_instrument_correlation_half_records`
26. `sp_dim_instrument_snapshot`
27. `sp_dim_mirror_dl_to_synapse`
28. `sp_dim_position_checkexistpartition`
29. `sp_dim_position_dl_to_synapse`
30. `sp_dim_position_hedgetype_history`
31. `sp_dim_position_hedgetype_real`
32. `sp_dim_position_ispartialcloseparent`
33. `sp_dim_position_positionhedgeserverchangelog`
34. `sp_dim_position_reopen`
35. `sp_dim_positionchangelog_dl_to_synapse`
36. `sp_dim_positionhedgeserverchangelog_dl_to_synapse`
37. `sp_dropstagingtables`
38. `sp_droptable`
39. `sp_fact_billingdeposit`
40. `sp_fact_billingdeposit_dl_to_synapse`
41. `sp_fact_billingredeem_dl_to_synapse`
42. `sp_fact_billingwithdraw`
43. `sp_fact_billingwithdraw_dl_to_synapse`
44. `sp_fact_cashout_rollback_dl_to_synapse`
45. `sp_fact_cashout_state`
46. `sp_fact_currencypricewithsplit_dl_to_synapse`
47. `sp_fact_currencypricewithsplit_dl_to_synapse_old_ver`
48. `sp_fact_customeraction`
49. `sp_fact_customeraction_checkexistpartition`
50. `sp_fact_customeraction_dl_to_synapse`
51. `sp_fact_customeraction_isparitalcloseparent`
52. `sp_fact_customeraction_switch`
53. `sp_fact_customerunrealized_pnl`
54. `sp_fact_customerunrealized_pnl_dl_to_synapse`
55. `sp_fact_deposit_fees_dl_to_synapse`
56. `sp_fact_deposit_state`
57. `sp_fact_firstcustomeraction`
58. `sp_fact_firstcustomeraction_dl_to_synapse`
59. `sp_fact_guru_copiers`
60. `sp_fact_guru_copiers_dl_to_synapse`
61. `sp_fact_history_cost`
62. `sp_fact_history_cost_dl_to_synapse`
63. `sp_fact_position_futures_snapshot`
64. `sp_fact_regulationtransfer`
65. `sp_fact_regulationtransfer_dl_to_synapse`
66. `sp_fact_reverse_deposits_dl_to_synapse`
67. `sp_fact_settlement_prices`
68. `sp_fact_snapshotcustomer`
69. `sp_fact_snapshotcustomer_dl_to_synapse`
70. `sp_fact_snapshotcustomercloseyear`
71. `sp_fact_snapshotcustomercloseyear_dl_to_synapse`
72. `sp_fact_snapshotequity`
73. `sp_fact_snapshotequity_dl_to_synapse`
74. `sp_fact_snapshotequity_inprocesscashouts`
75. `sp_fact_snapshotequity_totalpositionamount`
76. `sp_fact_withdraw_fees_dl_to_synapse`
77. `sp_killtableausessions`
78. `sp_load_ext_fcupnl_getspreadedpricecandle60minsplitted`
79. `sp_log_table_updates`
80. `sp_noc_liabilitieschange`
81. `sp_report_asic_getcustomerdata`
82. `sp_report_asic_getcustomerdata_traction`
83. `sp_resultssourcetotarget_actions`
84. `sp_sts_user_operations_data_history_create_switch_single`
85. `sp_sts_user_operations_data_history_switch`
86. `sp_test_externaltointernal`
87. `sp_test_liabilities_cycle`
88. `sp_truncatestagingtables`
89. `sp_truncatetables`
90. `sp_validation_cycle_gap_dl_to_synapse`
91. `waitforseconds`

</details>

---

_Generated by `tools/lakebridge/_gen_stub_inventory.py`._