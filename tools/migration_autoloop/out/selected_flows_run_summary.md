# Selected Flows Run Summary

- Target date: `2026-06-19`

## dim_mirror
- Return code: `0`
- QA pass (migration vs gold): `True`
- Databricks job state: `job_name_match:DWH_Daily_Process__SP_Dim_Mirror_AutoPOC`
- Report JSON: `tools/migration_autoloop/out/dim_mirror_trust_report_2026-06-19.json`
- Report MD: `tools/migration_autoloop/out/dim_mirror_trust_report_2026-06-19.md`

## fact_currencypricewithsplit
- Return code: `0`
- QA pass (migration vs gold): `True`
- Databricks job state: `job_name_match:DWH_Daily_Process__SP_Fact_CurrencyPriceWithSplit_AutoPOC`
- Report JSON: `tools/migration_autoloop/out/fact_currencypricewithsplit_trust_report_2026-06-19.json`
- Report MD: `tools/migration_autoloop/out/fact_currencypricewithsplit_trust_report_2026-06-19.md`

## fact_deposit_state
- Return code: `2`
- QA pass (migration vs gold): `False`
- Databricks job state: `job_name_match:DWH_Daily_Process__SP_Fact_Deposit_State_AutoPOC`
- Report JSON: `tools/migration_autoloop/out/fact_deposit_state_trust_report_2026-06-19.json`
- Report MD: `tools/migration_autoloop/out/fact_deposit_state_trust_report_2026-06-19.md`
