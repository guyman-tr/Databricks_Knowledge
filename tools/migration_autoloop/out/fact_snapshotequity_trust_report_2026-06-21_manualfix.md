# Autoloop Trust Report — fact_snapshotequity

- Pipeline: `DWH_Daily_Process_-_Entry_Point`
- Target date: `2026-06-21`
- Procedure: `sp_fact_snapshotequity_dl_to_synapse_autopoc`
- Migration table: `dwh_daily_process.migration_tables.fact_snapshotequity`
- Gold table: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotequity_fromdateid`
- Synapse table: `DWH_dbo.v_Fact_SnapshotEquity_FromDateID`
- Databricks task state: `unknown`
- QA pass (migration vs gold): `False`

## Core metrics
- Pre rows: `13159`
- Post rows: `13159`
- Gold rows: `48844`
- Delta rows (post-gold): `-35685.0`

## Interim triage
- `Ext_FSE_Billing_Withdraw`: dbx_rows=21391289, syn_rows=5577, delta=21385712.0
- `Ext_FSE_Billing_WithdrawToFunding`: dbx_rows=23227213, syn_rows=23227213, delta=0.0
- `Ext_FSE_History_Credit`: dbx_rows=457, syn_rows=457, delta=0.0
- `Ext_FSE_History_Position`: dbx_rows=92075, syn_rows=92075, delta=0.0
- `Ext_FSE_History_WithdrawAction`: dbx_rows=106858140, syn_rows=26455, delta=106831685.0
- `Ext_FSE_History_WithdrawToFundingAction`: dbx_rows=149506088, syn_rows=26679, delta=149479409.0
