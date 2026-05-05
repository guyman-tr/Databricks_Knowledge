---
schema: eMoney_dbo
database: Synapse DWH
total_deployable: 46
generated: 0
deployed: 15
failed: 22
stub_only: 9
last_generate_batch: 0
last_deploy_batch: 10
last_updated: "2026-05-05"
---

## Schema ALTER + Deployment Progress

| Metric                             | Value      |
| ---------------------------------- | ---------- |
| **Schema**                         | eMoney_dbo   |
| **Total deployable**               | 45  |
| **Pending (no .alter.sql)**        | 0          |
| **Generated (awaiting UC deploy)** | 0        |
| **Deployed (UC)**                  | 15         |
| **Stub-only (no UC)**              | 9   |
| **Failed**                         | 22         |
| **Stale**                          | 0          |
| **Last generate batch**            | 0          |
| **Last deploy batch**              | 10          |
| **Last updated**                   | 2026-05-03       |

> **Rows**: `Pending` = no local `.alter.sql`. `Generated` = `.alter.sql` present with executable ALTER, UC not deployed. `Deployed` = UC ALTERs executed. `Stub only` = comment-only `.alter.sql` (no UC target).

## Tables (44)

| Object | Deploy status |
|--------|---------------|
| [eMoney_dbo.eMoney_Account_Mappings](Tables/eMoney_Account_Mappings.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`bi_db`.`gold_sql_dp_prod_we_emoney_dbo_emoney_account_mapp|
| [eMoney_dbo.eMoney_Aggregated_Tribe_Balance](Tables/eMoney_Aggregated_Tribe_Balance.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`bi_db`.`gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_t|
| [eMoney_dbo.eMoney_AM_Target](Tables/eMoney_AM_Target.md) | Stub only |
| [eMoney_dbo.eMoney_BankPaymentsUK](Tables/eMoney_BankPaymentsUK.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`gold_sql_dp_prod_we_emoney_dbo_emoney_bankpayment|
| [eMoney_dbo.eMoney_Card_Instance_Summary](Tables/eMoney_Card_Instance_Summary.md) | Deployed (Batch 1) — 2026-05-03|
| [eMoney_dbo.eMoney_Card_Monthly_Snapshot](Tables/eMoney_Card_Monthly_Snapshot.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthl|
| [eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap](Tables/eMoney_Client_Balance_Check_Exceptions_Gap.md) | Stub only |
| [eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance](Tables/eMoney_Client_Balance_Check_Opening_Balance.md) | Stub only |
| [eMoney_dbo.eMoney_Country_Codes_Mapping_ISO](Tables/eMoney_Country_Codes_Mapping_ISO.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`gold_sql_dp_prod_we_emoney_dbo_emoney_country_cod|
| [eMoney_dbo.eMoney_Currency_Mapping_ISO](Tables/eMoney_Currency_Mapping_ISO.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`gold_sql_dp_prod_we_emoney_dbo_emoney_currency_ma|
| [eMoney_dbo.eMoney_Customer_Risk_Assessment](Tables/eMoney_Customer_Risk_Assessment.md) | Deployed (Batch 1) — 2026-05-03|
| [eMoney_dbo.eMoney_Customer_Risk_Assessment_History](Tables/eMoney_Customer_Risk_Assessment_History.md) | Deployed (Batch 1) — 2026-05-03|
| [eMoney_dbo.eMoney_Daily_MIMO_New_Reports_Action](Tables/eMoney_Daily_MIMO_New_Reports_Action.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`bi_db`.`gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_n|
| [eMoney_dbo.eMoney_Dictionary_AccountProgram](Tables/eMoney_Dictionary_AccountProgram.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_|
| [eMoney_dbo.eMoney_Dictionary_AccountStatus](Tables/eMoney_Dictionary_AccountStatus.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_|
| [eMoney_dbo.eMoney_Dictionary_AccountSubProgram](Tables/eMoney_Dictionary_AccountSubProgram.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_|
| [eMoney_dbo.eMoney_Dictionary_AuthorizationType](Tables/eMoney_Dictionary_AuthorizationType.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_|
| [eMoney_dbo.eMoney_Dictionary_CardStatus](Tables/eMoney_Dictionary_CardStatus.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_|
| [eMoney_dbo.eMoney_Dictionary_CurrencyBalanceStatus](Tables/eMoney_Dictionary_CurrencyBalanceStatus.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_|
| [eMoney_dbo.eMoney_Dictionary_PaymentSchemaType](Tables/eMoney_Dictionary_PaymentSchemaType.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_|
| [eMoney_dbo.eMoney_Dictionary_PaymentSpecificationType](Tables/eMoney_Dictionary_PaymentSpecificationType.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_|
| [eMoney_dbo.eMoney_Dictionary_Provider](Tables/eMoney_Dictionary_Provider.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_|
| [eMoney_dbo.eMoney_Dictionary_TransactionCategory](Tables/eMoney_Dictionary_TransactionCategory.md) | Stub only |
| [eMoney_dbo.eMoney_Dictionary_TransactionStatus](Tables/eMoney_Dictionary_TransactionStatus.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_|
| [eMoney_dbo.eMoney_Dictionary_TransactionType](Tables/eMoney_Dictionary_TransactionType.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_|
| [eMoney_dbo.eMoney_Dictionary_TribeScriptStatus](Tables/eMoney_Dictionary_TribeScriptStatus.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_|
| [eMoney_dbo.eMoney_Dim_Account](Tables/eMoney_Dim_Account.md) | Deployed (Batch 1) — 2026-05-03|
| [eMoney_dbo.eMoney_Dim_Country_Rollout](Tables/eMoney_Dim_Country_Rollout.md) | Deployed (Batch 10) — 2026-05-05|
| [eMoney_dbo.eMoney_Dim_Transaction](Tables/eMoney_Dim_Transaction.md) | Deployed (Batch 10) — 2026-05-05|
| [eMoney_dbo.eMoney_Fact_Transaction_Status](Tables/eMoney_Fact_Transaction_Status.md) | Deployed (Batch 10) — 2026-05-05|
| [eMoney_dbo.eMoney_Marketing_EmailTracking](Tables/eMoney_Marketing_EmailTracking.md) | Stub only |
| [eMoney_dbo.eMoney_Panel_FirstDates](Tables/eMoney_Panel_FirstDates.md) | Deployed (Batch 1) — 2026-05-03|
| [eMoney_dbo.eMoney_Panel_Retention_Daily](Tables/eMoney_Panel_Retention_Daily.md) | Stub only |
| [eMoney_dbo.eMoney_Panel_Retention_Monthly](Tables/eMoney_Panel_Retention_Monthly.md) | Deployed (Batch 10) — 2026-05-05|
| [eMoney_dbo.eMoney_Reports_AcquisitionFunnel](Tables/eMoney_Reports_AcquisitionFunnel.md) | Deployed (Batch 10) — 2026-05-05|
| [eMoney_dbo.eMoney_Reports_AcquisitionFunnelAggregated](Tables/eMoney_Reports_AcquisitionFunnelAggregated.md) | Deployed (Batch 10) — 2026-05-05|
| [eMoney_dbo.eMoney_Reports_ClubUpgrade](Tables/eMoney_Reports_ClubUpgrade.md) | Deployed (Batch 10) — 2026-05-05|
| [eMoney_dbo.eMoney_Reports_MIMO_Actions](Tables/eMoney_Reports_MIMO_Actions.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`bi_db`.`gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo|
| [eMoney_dbo.eMoney_Risk_Portfolio](Tables/eMoney_Risk_Portfolio.md) | Stub only |
| [eMoney_dbo.eMoney_Snapshot_Settled_Balance](Tables/eMoney_Snapshot_Settled_Balance.md) | Failed (deploy Batch 1) — DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`emoney`.`gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_se|
| [eMoney_dbo.eMoney_UserData_Marketing](Tables/eMoney_UserData_Marketing.md) | Deployed (Batch 1) — 2026-05-03|
| [eMoney_dbo.eMoneyClientBalance](Tables/eMoneyClientBalance.md) | Failed (deploy Batch 1) — [COLUMN_NOT_FOUND_IN_TABLE] Column 'Column' not found in table 'main'.'bi_db'.'gold_sql_dp_prod_we_emoney_dbo_emoneyclie|
| [eMoney_dbo.eMoneyProcessStatusLog](Tables/eMoneyProcessStatusLog.md) | Stub only |
| [eMoney_dbo.v_eMoney_Card_Instance_Summary](Tables/v_eMoney_Card_Instance_Summary.md) | Deployed (Batch 10) — 2026-05-05|

## Views (2)

| Object | Deploy status |
|--------|---------------|
| [eMoney_dbo.v_eMoney_Dim_Account](Views/v_eMoney_Dim_Account.md) | Stub only |

## Views (1)

| Object | Deploy status |
|--------|---------------|
| [eMoney_dbo.v_eMoney_Card_Instance_Summary](Views/v_eMoney_Card_Instance_Summary.md) | Deployed (Batch 9) — 2026-05-03|
