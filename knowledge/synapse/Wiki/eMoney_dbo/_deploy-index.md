---
schema: eMoney_dbo
total_objects: 49
with_uc_target: 36
knowledge_only_stubs: 9
no_uc_table: 4
last_updated: 2026-04-21
status: Generated (not yet deployed)
---

# eMoney_dbo Deploy Index

## Summary

| Metric | Value |
|--------|-------|
| **Schema** | eMoney_dbo |
| **Total Documented** | 49 |
| **With UC Target (ALTER generated)** | 36 |
| **Knowledge-only Stubs** | 9 |
| **No UC Table Exists** | 4 |
| **Last Updated** | 2026-04-21 |
| **Deploy Status** | Generated — not yet deployed to UC |

---

## Objects With UC Targets (36)

| Object | UC Target | Classification | Cols |
|--------|-----------|----------------|------|
| eMoney_Dim_Account | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account | Non-standard | 89 |
| eMoney_Dim_Transaction | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction | Non-standard | 77 |
| eMoney_Fact_Transaction_Status | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status | Non-standard | 77 |
| eMoney_Panel_FirstDates | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_firstdates | Non-standard | 65 |
| eMoney_Panel_Retention_Monthly | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly | Non-standard | 86 |
| eMoney_Reports_AcquisitionFunnel | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel | Non-standard | 15 |
| eMoney_Reports_AcquisitionFunnelAggregated | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnelaggregated | Non-standard | 5 |
| eMoney_Reports_ClubUpgrade | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_clubupgrade | Non-standard | 13 |
| eMoney_Dim_Country_Rollout | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout | Non-standard | 7 |
| eMoney_Account_Mappings | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings | Non-standard | 24 |
| eMoney_Card_Instance_Summary | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary | Non-standard | 18 |
| eMoney_Card_Monthly_Snapshot | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot | Non-standard | 23 |
| eMoney_Snapshot_Settled_Balance | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_snapshot_settled_balance | Non-standard | 27 |
| eMoney_BankPaymentsUK | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk | Non-standard | 18 |
| eMoney_Aggregated_Tribe_Balance | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_aggregated_tribe_balance | Non-standard | 28 |
| eMoney_Daily_MIMO_New_Reports_Action | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action | Non-standard | 20 |
| eMoney_Reports_MIMO_Actions | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions | Non-standard | 20 |
| eMoney_UserData_Marketing | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing | Non-standard | 13 |
| eMoneyClientBalance | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance | Non-standard | 79 |
| eMoney_Customer_Risk_Assessment | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_customer_risk_assessment | Non-standard | 120 |
| eMoney_Customer_Risk_Assessment_History | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_customer_risk_assessment_history | Non-standard | 120 |
| eMoney_Country_Codes_Mapping_ISO | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_country_codes_mapping_iso | Non-standard | 6 |
| eMoney_Currency_Mapping_ISO | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_currency_mapping_iso | Non-standard | 4 |
| eMoney_Dictionary_AccountProgram | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountprogram | Non-standard | 3 |
| eMoney_Dictionary_AccountStatus | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountstatus | Non-standard | 3 |
| eMoney_Dictionary_AccountSubProgram | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_accountsubprogram | Non-standard | 5 |
| eMoney_Dictionary_AuthorizationType | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_authorizationtype | Non-standard | 3 |
| eMoney_Dictionary_CardStatus | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_cardstatus | Non-standard | 3 |
| eMoney_Dictionary_CurrencyBalanceStatus | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_currencybalancestatus | Non-standard | 3 |
| eMoney_Dictionary_PaymentSchemaType | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentschematype | Non-standard | 3 |
| eMoney_Dictionary_PaymentSpecificationType | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_paymentspecificationtype | Non-standard | 3 |
| eMoney_Dictionary_Provider | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_provider | Non-standard | 3 |
| eMoney_Dictionary_TransactionStatus | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactionstatus | Non-standard | 3 |
| eMoney_Dictionary_TransactionType | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactiontype | Non-standard | 3 |
| eMoney_Dictionary_TribeScriptStatus | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_tribescriptstatus | Non-standard | 3 |
| v_eMoney_Card_Instance_Summary | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_v_emoney_card_instance_summary | Non-standard | 17 |

## Knowledge-Only Stubs (9)

| Object | Reason |
|--------|--------|
| eMoney_AM_Target | No UC table exists |
| eMoney_Client_Balance_Check_Exceptions_Gap | No UC table exists |
| eMoney_Client_Balance_Check_Opening_Balance | No UC table exists |
| eMoney_Dictionary_TransactionCategory | No UC table exists |
| eMoney_Marketing_EmailTracking | No UC table exists |
| eMoney_Panel_Retention_Daily | No UC table exists |
| eMoney_Risk_Portfolio | No UC table exists |
| eMoneyProcessStatusLog | No UC table exists |
| v_eMoney_Dim_Account | No UC table exists (view) |

## No UC Table (4 — no ALTER file generated)

| Object | Reason |
|--------|--------|
| eMoney_Calculated_Balance | Not exported to UC via Generic Pipeline |
| eMoney_Currency_Instrument_Mapping_Static | Not exported to UC via Generic Pipeline |
| eMoney_Daily_Shortfall_CID_Level | Not exported to UC via Generic Pipeline |
| eMoney_EntityByCurrencyISO_MappingStatic | Not exported to UC via Generic Pipeline |
