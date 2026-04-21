# Propagation Scope Report: gold_sql_dp_prod_we_dwh_dbo_v_dim_mirror

**Generated**: 2026-04-12 14:36 | Deep lineage discovery

## Source Table

| Property | Value |
|----------|-------|
| UC Name | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_dim_mirror` |
| Columns with descriptions | 27 |
| Discovery methods |  |
| Discovered at | 2026-04-12T14:36:49.378431+00:00 |

## Downstream Objects

**Total**: 0 objects

| Object | Type | Hop | Via | Identical | Renamed | Total |
|--------|------|-----|-----|-----------|---------|-------|

## Blacklisted Columns (Excluded)

11 columns excluded from per-table propagation: `__meets_drop_expectations`, `_fivetran_synced`, `_row`, `created`, `createddate`, `etr_y`, `etr_ym`, `etr_ymd`, `filename`, `insertdate`, `updatedate`

*These are handled separately by `_broadcast_propagate.py`.*

## Execution Plan

| Metric | Value |
|--------|-------|
| Total ALTER statements | 0 |
| Identical column matches | 0 |
| Rename matches | 0 |
| Batch size | 30 objects |
| Number of batches | 1 |

- **Batch 1**: 0 objects, 0 statements — 
