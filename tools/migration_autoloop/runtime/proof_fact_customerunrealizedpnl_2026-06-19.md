# Proof Run: Fact_CustomerUnrealizedPnL orchestration setup

## Goal
Pick one ADF-like flow that is still not orchestrated as a Databricks job, set it up, run it, and test toward QA parity.

## Selected flow
- Logical flow: `Fact_CustomerUnrealized_PnL` (from DWH daily process family)
- Existing migration objects were present:
  - procedure `sp_fact_customerunrealized_pnl_dl_to_synapse`
  - procedure `sp_fact_customerunrealized_pnl`
  - table `dwh_daily_process.migration_tables.fact_customerunrealized_pnl`

## Orchestration setup performed
1. Added SQL task files to workspace path:
   - `/Workspace/Users/guyman@etoro.com/dwh_daily_process_jobs/11_sp_fact_customerunrealized_pnl_dl_to_synapse.sql`
   - `/Workspace/Users/guyman@etoro.com/dwh_daily_process_jobs/12_sp_fact_customerunrealized_pnl.sql`
2. Created Databricks SQL Job:
   - `job_id = 18080659306023`
   - `name = DWH_Daily_Process__SP_Fact_CustomerUnrealized_PnL_AutoPOC`
   - task 1: `SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse`
   - task 2: `SP_Fact_CustomerUnrealized_PnL` (depends on task 1)

## Test execution results

### Run 1
- `run_id = 528991325110513`
- Failed before execution due SQL task file type mismatch (workspace NOTEBOOK vs required FILE).
- Fix applied: re-imported SQL artifacts as workspace FILE objects.

### Run 2
- `run_id = 393390618615952`
- Task `SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse` failed with missing snapshot dependency:
  - missing object: `dwh_daily_process.daily_snapshot.PriceLog_Candles_CurrencyPriceMaxDate`
- Safe compatibility shim applied:
  - created view `dwh_daily_process.daily_snapshot.pricelog_candles_currencypricemaxdate`
    from `...currencypricemaxdatewithsplitview`

### Run 3
- `run_id = 33501821831925`
- Task `SP_Fact_CustomerUnrealized_PnL_DL_To_Synapse` failed with transpiled SQL scripting limitation:
  - `LOCAL_VARIABLE_IN_TEMP_OBJECT_DEFINITION`
  - local variable `V_date` referenced inside temp-view definition

## Status
- **Orchestration setup:** DONE (job exists and is runnable)
- **Execution test:** DONE (job executed repeatedly; deterministic blockers surfaced)
- **QA parity:** BLOCKED (cannot reach parity until task 1 SQL is fixed)

## Concrete blockers to resolve before parity
1. Refactor `sp_fact_customerunrealized_pnl_dl_to_synapse` to avoid local variable in temp object definitions.
2. Validate all expected `daily_snapshot` objects required by this flow are present by canonical names.

