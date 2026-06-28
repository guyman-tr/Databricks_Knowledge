# Migration Autoloop Mission Status (2026-06-19)

## Selected bottom-up flows

1. `dim_mirror` (`sp_dim_mirror_dl_to_synapse`)
2. `fact_currencypricewithsplit` (`sp_fact_currencypricewithsplit_dl_to_synapse`)
3. `fact_deposit_state` (`sp_fact_deposit_state`)

Selection rationale:
- All three are in `DWH_Daily_Process_-_Entry_Point`.
- All are date-parameterized (default date-slice runnable).
- FCUPNL was explicitly excluded.
- These have direct procedure execution paths and no additional intra-flow dependencies in the extracted routine graph.

## Execution outcomes

- `dim_mirror`: **PASS** (migration vs gold parity on date slice)
- `fact_currencypricewithsplit`: **FAIL** (small business-sum drift vs gold)
- `fact_deposit_state`: **FAIL** (target slice present in migration, absent in gold/synapse slice)

## Drift triage notes

- `fact_currencypricewithsplit` interim checks:
  - `Ext_FCPWS_History_SplitRatio`: dbx/synapse rowcount aligned.
  - `Ext_FCPWS_Instrument`: dbx/synapse rowcount aligned.
  - Final drift is therefore downstream of interim staging.
- `fact_deposit_state`:
  - No `Ext_`/`stg_` references were parsed from the proc body for automatic interim triage.
  - Final table has date-slice rows in migration while gold/synapse return zero rows for the same date predicate.

## Next concrete actions

- `dim_mirror`: keep as baseline flow and add to nightly autoloop rotation.
- `fact_currencypricewithsplit`: diff final-table precision/rounding behavior between migration proc and gold writer; then rerun trust report.
- `fact_deposit_state`: confirm authoritative date column semantics for gold/synapse target (`FromDate` vs ETL insert date) and update date-slice predicate mapping before next rerun.
