# Propagation Scope Report: gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked

**Generated**: 2026-04-12 14:36 | Deep lineage discovery

## Source Table

| Property | Value |
|----------|-------|
| UC Name | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` |
| Columns with descriptions | 54 |
| Discovery methods | name_pattern |
| Discovered at | 2026-04-12T14:36:05.473365+00:00 |

## Downstream Objects

**Total**: 1 objects

| Object | Type | Hop | Via | Identical | Renamed | Total |
|--------|------|-----|-----|-----------|---------|-------|
| `main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid` | TABLE | 1 | name_pattern | 53 | 0 | 53 |

## Blacklisted Columns (Excluded)

11 columns excluded from per-table propagation: `__meets_drop_expectations`, `_fivetran_synced`, `_row`, `created`, `createddate`, `etr_y`, `etr_ym`, `etr_ymd`, `filename`, `insertdate`, `updatedate`

*These are handled separately by `_broadcast_propagate.py`.*

## Execution Plan

| Metric | Value |
|--------|-------|
| Total ALTER statements | 53 |
| Identical column matches | 53 |
| Rename matches | 0 |
| Batch size | 30 objects |
| Number of batches | 1 |

- **Batch 1**: 1 objects, 53 statements — `gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid`
