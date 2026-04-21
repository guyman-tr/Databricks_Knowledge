# Propagation Scope Report: gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer

**Generated**: 2026-04-12 14:35 | Deep lineage discovery

## Source Table

| Property | Value |
|----------|-------|
| UC Name | `main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer` |
| Columns with descriptions | 44 |
| Discovery methods | name_pattern |
| Discovered at | 2026-04-12T14:35:49.714276+00:00 |

## Downstream Objects

**Total**: 3 objects

| Object | Type | Hop | Via | Identical | Renamed | Total |
|--------|------|-----|-----|-----------|---------|-------|
| `main.bi_output.vg_fact_snapshotcustomer_for_emoney_genie` | VIEW | 1 | name_pattern | 1 | 0 | 1 |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | TABLE | 1 | name_pattern | 42 | 0 | 42 |
| `main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid` | TABLE | 1 | name_pattern | 42 | 0 | 42 |

## Blacklisted Columns (Excluded)

11 columns excluded from per-table propagation: `__meets_drop_expectations`, `_fivetran_synced`, `_row`, `created`, `createddate`, `etr_y`, `etr_ym`, `etr_ymd`, `filename`, `insertdate`, `updatedate`

*These are handled separately by `_broadcast_propagate.py`.*

## Execution Plan

| Metric | Value |
|--------|-------|
| Total ALTER statements | 85 |
| Identical column matches | 85 |
| Rename matches | 0 |
| Batch size | 30 objects |
| Number of batches | 1 |

- **Batch 1**: 3 objects, 85 statements — `vg_fact_snapshotcustomer_for_emoney_genie`, `gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid`
