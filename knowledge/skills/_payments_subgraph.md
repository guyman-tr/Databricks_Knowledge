# Payments Super-Domain — Subgraph Profile

_Selected by manual seed hubs: ['BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms', 'DWH_dbo.Fact_BillingDeposit', 'DWH_dbo.Fact_BillingWithdraw', 'Dealing_dbo.Dealing_IGReconEODHolding', 'EXW_Wallet.CryptoTypes', 'EXW_dbo.EXW_FinanceReportsBalancesNew', 'FiatDwhDB.Tribe', 'eMoney_dbo.eMoney_Dim_Account']_

## Scope
- Member clusters: 7
- Total nodes: 421
- Total internal edges: 1065
- Edge sources: {'wiki': 1905, 'tableau': 167, 'genie': 237, 'kpi': 11, 'kpi_prep': 70}

## Member clusters

| Cluster | Hub | Size | Seed hubs in cluster | Genie spaces |
|---|---|---|---|---|
| 7 | `DWH_dbo.Fact_BillingDeposit` | 115 | 2 |  |
| 45 | `EXW_Wallet.CryptoTypes` | 97 | 1 |  |
| 13 | `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms` | 74 | 1 | UK BA space [WIP](19), New Space (2)(3), New Space (1)(2) |
| 17 | `eMoney_dbo.eMoney_Dim_Account` | 61 | 1 |  |
| 47 | `EXW_dbo.EXW_FinanceReportsBalancesNew` | 30 | 1 | ido ezra space(10) |
| 28 | `Dealing_dbo.Dealing_IGReconEODHolding` | 24 | 1 |  |
| 49 | `FiatDwhDB.Tribe` | 20 | 1 |  |

## Top hubs across the Payments super-domain

- `EXW_Wallet.CryptoTypes` — 88.0
- `eMoney_dbo.eMoney_Dim_Account` — 83.5
- `DWH_dbo.Fact_BillingWithdraw` — 76.0
- `eMoney_dbo.eMoney_Dim_Transaction` — 62.5
- `BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals` — 58.0
- `DWH_dbo.Fact_BillingDeposit` — 57.0
- `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms` — 55.5
- `DWH_dbo.Fact_Cashout_State` — 52.0
- `DWH_dbo.Dim_FundingType` — 50.0
- `Billing.Withdraw` — 46.0
- `BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions` — 45.0
- `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` — 43.0
- `DWH_dbo.Dim_Currency` — 42.5
- `DWH_dbo.Dim_Affiliate` — 42.0
- `BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status` — 39.0
- `eMoney_dbo.eMoney_Panel_FirstDates` — 39.0
- `BI_DB_dbo.BI_DB_LTV_BI_Actual` — 38.0
- `FiatDwhDB.Tribe` — 38.0
- `BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData` — 37.0
- `Wallet.CryptoTypes` — 35.0
- `EXW_Wallet.SentTransactions` — 34.0
- `eMoney_dbo.eMoney_Fact_Transaction_Status` — 33.0
- `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform` — 32.0
- `BI_DB_dbo.BI_DB_AllDeposits` — 31.0
- `BI_DB_dbo.BI_DB_CID_DailyPanel_FullData` — 31.0
- `BI_DB_dbo.BI_DB_DailyCommisionReport` — 31.0
- `EXW_Wallet.CustomerWalletsView` — 31.0
- `eMoney_dbo.eMoneyClientBalance` — 30.0
- `DWH_dbo.Fact_Deposit_State` — 30.0
- `EXW_Wallet.ReceivedTransactions` — 30.0

## Genie spaces intersecting Payments (>=2 tables)

- `UK BA space [WIP]` — 19/30 tables
- `ido ezra space` — 10/10 tables
- `New Space (2)` — 3/3 tables
- `New Space (1)` — 2/2 tables
- `Product Analytics` — 2/12 tables
  > This space should be able to answer questions regarding main.dwh tables and Mixpanel Silver Data.
Seems not to be working while Mixpanel Data is Included

## Cluster details (members)

### Cluster 7 — `DWH_dbo.Fact_BillingDeposit` (115 members)

**Top members:**
- `DWH_dbo.Fact_BillingDeposit` — 94.0
- `DWH_dbo.Fact_BillingWithdraw` — 89.0
- `DWH_dbo.Dim_Currency` — 83.5
- `BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals` — 76.0
- `DWH_dbo.Dim_FundingType` — 66.0
- `DWH_dbo.Fact_Cashout_State` — 55.0
- `Billing.Withdraw` — 52.0
- `BI_DB_dbo.BI_DB_AllDeposits` — 45.0
- `BI_DB_dbo.BI_DB_Withdraw_Rollback_PIPs` — 37.0
- `BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Affiliates` — 36.0
- `DWH_dbo.Fact_Cashout_Rollback` — 33.0
- `BI_DB_dbo.Synapse_Table_etoro_History_DepositAction` — 32.0
- `DWH_dbo.Fact_Deposit_State` — 32.0
- `BI_DB_dbo.BI_DB_DepositWithdrawFee` — 28.0
- `DWH_dbo.Dim_BillingDepot` — 28.0

**KPI views in this cluster:**
- `etoro_kpi_prep.v_mimo_allplatforms`
- `etoro_kpi_prep.v_mimo_emoneyplatform`
- `etoro_kpi_prep.v_mimo_first_deposit_all_platforms`
- `etoro_kpi_prep.v_mimo_optionsplatform`
- `etoro_kpi_prep.v_mimo_tradingplatform`
- `etoro_kpi_prep_stg.v_ddr_mimo_allplatforms`
- `etoro_kpi_prep_stg.v_ddr_mimo_emoney`
- `etoro_kpi_prep_stg.v_ddr_mimo_options`
- `etoro_kpi_prep_stg.v_ddr_mimo_tradingplatform`

### Cluster 45 — `EXW_Wallet.CryptoTypes` (97 members)

**Top members:**
- `EXW_Wallet.CryptoTypes` — 88.0
- `EXW_Wallet.CustomerWalletsView` — 37.0
- `Wallet.CryptoTypes` — 35.0
- `EXW_Wallet.SentTransactions` — 34.0
- `EXW_Wallet.ReceivedTransactions` — 30.0
- `EXW_dbo.EXW_WalletInventory` — 29.0
- `Wallet.Wallets` — 27.0
- `EXW_Wallet.EXW_Price` — 26.0
- `EXW_dbo.EXW_FactConversions` — 26.0
- `EXW_Wallet.Redemptions` — 25.0
- `EXW_dbo.EXW_FactRedeemTransactions` — 25.0
- `EXW_dbo.EXW_FactTransactions` — 25.0
- `EXW_Wallet.Wallets` — 24.0
- `Wallet.Redemptions` — 23.0
- `EXW_Wallet.Requests` — 21.0

### Cluster 13 — `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms` (74 members)

**Top members:**
- `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms` — 87.0
- `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` — 79.0
- `DWH_dbo.Dim_Affiliate` — 75.0
- `BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData` — 70.0
- `BI_DB_dbo.BI_DB_LTV_BI_Actual` — 68.0
- `BI_DB_dbo.BI_DB_CID_DailyPanel_FullData` — 66.0
- `BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions` — 65.0
- `BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status` — 56.0
- `BI_DB_dbo.BI_DB_DailyCommisionReport` — 55.0
- `BI_DB_dbo.BI_DB_First5Actions` — 53.0
- `DWH_dbo.Dim_ActionType` — 51.0
- `eMoney_dbo.eMoneyClientBalance` — 42.0
- `DWH_dbo.Dim_Channel` — 39.0
- `bi_db.bronze_sub_accounts_accounts` — 39.0
- `money_farm.silver_moneyfarm_etoro_mf_aum` — 38.0

**Genie spaces in this cluster:**
- `UK BA space [WIP]` (19/30)
- `New Space (2)` (3/3)
- `New Space (1)` (2/2)

**KPI views in this cluster:**
- `etoro_kpi.v_spaceship_aum`
- `etoro_kpi.v_spaceship_fees`
- `etoro_kpi.vg_ddr_revenue`
- `etoro_kpi_prep.v_dim_dataplatform_uuid`
- `etoro_kpi_prep.v_spaceship_mimo`

<details><summary>All members</summary>

- `BI_DB_CID_MonthlyPanel_FullData.ClusterDetail`
- `BI_DB_dbo.BI_DB_CID_DailyPanel_FullData`
- `BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH`
- `BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData`
- `BI_DB_dbo.BI_DB_ClubUsersDataRemarketingGoogle`
- `BI_DB_dbo.BI_DB_CorpDevDashboard`
- `BI_DB_dbo.BI_DB_Crypto_Top_1000_List`
- `BI_DB_dbo.BI_DB_DCM_Dashboard`
- `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status`
- `BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status`
- `BI_DB_dbo.BI_DB_DDR_Fact_AUM`
- `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms`
- `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform`
- `BI_DB_dbo.BI_DB_DDR_Fact_PnL`
- `BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions`
- `BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts`
- `BI_DB_dbo.BI_DB_DailyCommisionReport`
- `BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg`
- `BI_DB_dbo.BI_DB_DailyCommisionReport_Last2weeks`
- `BI_DB_dbo.BI_DB_DailyCommisionReport_LastYear`
- `BI_DB_dbo.BI_DB_DailyCommisionReport_MonthlyData`
- `BI_DB_dbo.BI_DB_DailyCommisionReport_ThisMonth`
- `BI_DB_dbo.BI_DB_DailyCommisionReport_Yesterday`
- `BI_DB_dbo.BI_DB_Diversification`
- `BI_DB_dbo.BI_DB_First5Actions`
- `BI_DB_dbo.BI_DB_LTV_BI_Actual`
- `BI_DB_dbo.BI_DB_LTV_By_FTD_MOP`
- `BI_DB_dbo.BI_DB_LTV_Predictions`
- `BI_DB_dbo.BI_DB_LTV_Revenue_Multipliers`
- `BI_DB_dbo.BI_DB_V_DDR_*`
- `BI_DB_dbo.BI_DB_V_DDR_AUM`
- `BI_DB_dbo.Bi_Db_Ddr_Daily_Aggregated`
- `BI_DB_dbo.Dim_Revenue_Metrics`
- `BI_DB_dbo.Function_DDR_Aggregation_*`
- `BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms`
- `BI_DB_dbo.Function_PnL_Single_Day`
- `BI_DB_dbo.Function_Population_First_Time_Funded`
- `BI_DB_dbo.Group_LTV_Table`
- `BI_DB_dbo.LTV_Conversions_Multipliers_Table`
- `BI_DB_dbo.LTV_FromDB_ToBigQuery`
- `BI_DB_dbo.SP_DDR_Customer_Daily_Status`
- `BI_DB_dbo.SP_LTV_Multiplier_Model`
- `DWH_dbo.Dim_ActionType`
- `DWH_dbo.Dim_Affiliate`
- `DWH_dbo.Dim_Channel`
- `DWH_dbo.Dim_ContractType`
- `DWH_dbo.Dim_FTDPlatform`
- `DWH_dbo.Dim_InstrumentType`
- `DWH_dbo.Fact_AffiliateCommission`
- `Dealing_dbo.Dealing_DealingDashboard_Clients`
- `Dictionary.AccountTypes`
- `Dim_Country.MarketingRegionManualName`
- `Dim_Country.Region`
- `EXW_dbo.EXW_C2F_E2E`
- `bi_db.bronze_sub_accounts_accounts`
- `bi_output.bi_output_moneyfarm_fact_portfolio_snapshot`
- `bi_output.bi_output_moneyfarm_fact_transactions`
- `compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts`
- `eMoneyClientBalance.BalanceDateID`
- `eMoney_dbo.SP_eMoney_ClientBalance`
- `eMoney_dbo.eMoneyClientBalance`
- `eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap`
- `eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance`
- `etoro_kpi.v_spaceship_aum`
- `etoro_kpi.v_spaceship_fees`
- `etoro_kpi.vg_ddr_revenue`
- `etoro_kpi_prep.v_dim_dataplatform_uuid`
- `etoro_kpi_prep.v_spaceship_mimo`
- `money_farm.silver_moneyfarm_etoro_mf_aum`
- `spaceship.bronze_spaceship_metabase_contact`
- `spaceship.bronze_spaceship_metabase_nova_transactions`
- `spaceship.bronze_spaceship_metabase_super_transactions`
- `spaceship.bronze_spaceship_metabase_user_beta`
- `spaceship.spaceship_metabase_voyager_user_balances`

</details>

### Cluster 17 — `eMoney_dbo.eMoney_Dim_Account` (61 members)

**Top members:**
- `eMoney_dbo.eMoney_Dim_Account` — 108.0
- `eMoney_dbo.eMoney_Dim_Transaction` — 79.5
- `Dim_Customer.RealCID` — 52.0
- `eMoney_dbo.eMoney_Panel_FirstDates` — 43.0
- `eMoney_dbo.eMoney_Card_Monthly_Snapshot` — 36.0
- `eMoney_dbo.eMoney_Fact_Transaction_Status` — 36.0
- `eMoney_dbo.eMoney_Reports_AcquisitionFunnel` — 34.0
- `eMoney_dbo.eMoney_Card_Instance_Summary` — 26.0
- `eMoney_dbo.eMoney_Marketing_EmailTracking` — 20.0
- `eMoney_dbo.eMoney_Snapshot_Settled_Balance` — 19.0
- `eMoney_dbo.eMoney_UserData_Marketing` — 19.0
- `eMoney_dbo.eMoney_Account_Mappings` — 16.0
- `eMoney_dbo.eMoney_Dictionary_AccountSubProgram` — 13.0
- `eMoney_dbo.eMoney_Dictionary_AccountProgram` — 12.0
- `Dim_Country.CountryID` — 10.0

<details><summary>All members</summary>

- `BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_CIDs`
- `BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_Countries`
- `BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_Forbidden_Trading`
- `BI_DB_dbo.BI_DB_Deposits_WiresFromGooglesheets`
- `BI_DB_dbo.BI_DB_Document_Vendors`
- `BI_DB_dbo.BI_DB_SFMC_Report`
- `Dictionary.AccountPrograms`
- `Dictionary.AccountStatuses`
- `Dictionary.CardStatuses`
- `Dictionary.CurrencyBalanceStatuses`
- `Dictionary.TransactionCategories`
- `Dictionary.TransactionStatuses`
- `Dictionary.TransactionTypes`
- `Dim_Country.CountryID`
- `Dim_Customer.RealCID`
- `Dim_PlayerLevel.PlayerLevelID`
- `Dim_PlayerStatus.PlayerStatusID`
- `Dim_Regulation.DWHRegulationID`
- `SubPrograms.Id`
- `dbo.FiatAccount`
- `dbo.FiatBankAccount`
- `dbo.FiatCardInstances`
- `dbo.FiatCardStatuses`
- `dbo.FiatCards`
- `dbo.FiatCurrencyBalances`
- `dbo.FiatTransactions`
- `dbo.SubPrograms`
- `eMoney_Dictionary_AccountProgram.AccountProgramID`
- `eMoney_Dim_Account.AccountID`
- `eMoney_Dim_Account.CardID`
- `eMoney_Dim_Account.CurrencyBalanceID`
- `eMoney_dbo.eMoney_Account_Mappings`
- `eMoney_dbo.eMoney_Aggregated_Tribe_Balance`
- `eMoney_dbo.eMoney_BankPaymentsUK`
- `eMoney_dbo.eMoney_Calculated_Balance`
- `eMoney_dbo.eMoney_Card_Instance_Summary`
- `eMoney_dbo.eMoney_Card_Monthly_Snapshot`
- `eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static`
- `eMoney_dbo.eMoney_Customer_Risk_Assessment`
- `eMoney_dbo.eMoney_Dictionary_AccountProgram`
- `eMoney_dbo.eMoney_Dictionary_AccountStatus`
- `eMoney_dbo.eMoney_Dictionary_AccountSubProgram`
- `eMoney_dbo.eMoney_Dictionary_CardStatus`
- `eMoney_dbo.eMoney_Dictionary_CurrencyBalanceStatus`
- `eMoney_dbo.eMoney_Dictionary_TransactionCategory`
- `eMoney_dbo.eMoney_Dictionary_TransactionStatus`
- `eMoney_dbo.eMoney_Dictionary_TransactionType`
- `eMoney_dbo.eMoney_Dim_Account`
- `eMoney_dbo.eMoney_Dim_Transaction`
- `eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic`
- `eMoney_dbo.eMoney_Fact_Transaction_Status`
- `eMoney_dbo.eMoney_Marketing_EmailTracking`
- `eMoney_dbo.eMoney_Panel_FirstDates`
- `eMoney_dbo.eMoney_Reports_AcquisitionFunnel`
- `eMoney_dbo.eMoney_Reports_AcquisitionFunnelAggregated`
- `eMoney_dbo.eMoney_Reports_ClubUpgrade`
- `eMoney_dbo.eMoney_Risk_Portfolio`
- `eMoney_dbo.eMoney_Snapshot_Settled_Balance`
- `eMoney_dbo.eMoney_UserData_Marketing`
- `eMoney_dbo.v_eMoney_Card_Instance_Summary`
- `eMoney_dbo.v_eMoney_Dim_Account`

</details>

### Cluster 47 — `EXW_dbo.EXW_FinanceReportsBalancesNew` (30 members)

**Top members:**
- `EXW_dbo.EXW_FinanceReportsBalancesNew` — 42.0
- `Wallet.FinanceReportRecords` — 13.0
- `bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban` — 12.0
- `bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban` — 12.0
- `finance.bronze_sodreconciliation_apex_ext869_cashactivity` — 12.0
- `etoro_kpi_prep.v_fact_customeraction_w_metrics` — 11.0
- `etoro_kpi_prep_stg.v_fact_customeraction_w_metrics` — 10.0
- `bi_output.bi_output_finance_tables_ptp_tax` — 9.0
- `bi_output.bi_output_finance_tables_ptp_tax_backup` — 9.0
- `bi_output.bi_output_finance_tables_tax_ptp_monitoring` — 9.0
- `bi_output_stg.bi_output_finance_tables_ptp_tax` — 9.0
- `bi_output_stg.bi_output_finance_tables_ptp_tax_temp` — 9.0
- `bi_output_stg.bi_output_finance_tables_tax_ptp_monitoring` — 9.0
- `etoro_kpi_prep.v_population_active_traders` — 9.0
- `etoro_kpi_prep.v_population_portfolio_only` — 9.0

**Genie spaces in this cluster:**
- `ido ezra space` (10/10)

**KPI views in this cluster:**
- `etoro_kpi_prep.v_dim_instrument_enriched`
- `etoro_kpi_prep.v_fact_customeraction_enriched`
- `etoro_kpi_prep.v_fact_customeraction_w_metrics`
- `etoro_kpi_prep.v_globalftdplatform`
- `etoro_kpi_prep.v_mimo_options_platform`
- `etoro_kpi_prep.v_options_aum`
- `etoro_kpi_prep.v_population_active_traders`
- `etoro_kpi_prep.v_population_balance_only_accounts`
- `etoro_kpi_prep.v_population_first_time_funded`
- `etoro_kpi_prep.v_population_funded`

<details><summary>All members</summary>

- `EXW_dbo.EXW_30DayBalanceExtract`
- `EXW_dbo.EXW_FinanceReportsBalancesNew`
- `Trade.Adminpositionlog`
- `Wallet.FinanceReportRecords`
- `bi_db.bronze_moneybusdb_dictionary_accounttypes`
- `bi_output.bi_output_finance_tables_bi_db_positions_closed_to_iban`
- `bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban`
- `bi_output.bi_output_finance_tables_ptp_tax`
- `bi_output.bi_output_finance_tables_ptp_tax_backup`
- `bi_output.bi_output_finance_tables_tax_ptp_monitoring`
- `bi_output_stg.bi_output_finance_tables_ptp_tax`
- `bi_output_stg.bi_output_finance_tables_ptp_tax_temp`
- `bi_output_stg.bi_output_finance_tables_tax_ptp_monitoring`
- `etoro_kpi_prep.v_dim_instrument_enriched`
- `etoro_kpi_prep.v_fact_customeraction_enriched`
- `etoro_kpi_prep.v_fact_customeraction_w_metrics`
- `etoro_kpi_prep.v_globalftdplatform`
- `etoro_kpi_prep.v_mimo_options_platform`
- `etoro_kpi_prep.v_options_aum`
- `etoro_kpi_prep.v_population_active_traders`
- `etoro_kpi_prep.v_population_balance_only_accounts`
- `etoro_kpi_prep.v_population_first_time_funded`
- `etoro_kpi_prep.v_population_funded`
- `etoro_kpi_prep.v_population_portfolio_only`
- `etoro_kpi_prep.v_revenue_optionsplatform`
- `etoro_kpi_prep_stg.v_fact_customeraction_w_metrics`
- `finance.bronze_sodreconciliation_apex_ext869_cashactivity`
- `general.bronze_recurringinvestment_recurringinvestment_planinstances`
- `general.bronze_sodreconciliation_apex_ext981_buypowersummary`
- `general.bronze_usabroker_apex_options`

</details>

### Cluster 28 — `Dealing_dbo.Dealing_IGReconEODHolding` (24 members)

**Top members:**
- `Dealing_dbo.Dealing_IGReconEODHolding` — 25.0
- `Dealing_dbo.Dealing_Duco_EODRecon` — 22.0
- `Dealing_dbo.Dealing_JPMReconEODHolding` — 16.0
- `Dealing_dbo.Dealing_Marex_Recon_Trades` — 15.0
- `Dealing_dbo.Dealing_IGReconTrades` — 13.0
- `Dealing_dbo.Dealing_VisionRecon_EODHoldings` — 12.0
- `Dealing_dbo.Dealing_VisionRecon_Trades` — 12.0
- `Dealing_dbo.Dealing_Duco_ActivityRecon` — 11.0
- `Dealing_dbo.Dealing_JPMReconTrades` — 11.0
- `Dealing_dbo.Dealing_Marex_Recon_Trades_Futures` — 11.0
- `Dealing_dbo.Dealing_Marex_Recon_EODHoldings` — 9.0
- `Dealing_dbo.Dealing_Marex_Recon_EODHoldings_Futures` — 8.0
- `CopyFromLake.etoro_Hedge_ExecutionLog` — 6.0
- `Dealing_Duco_ActivityRecon.eToroUSDAmount` — 4.0
- `Dealing_Duco_ActivityRecon.eToro_Units` — 4.0

<details><summary>All members</summary>

- `CopyFromLake.etoro_Hedge_ExecutionLog`
- `Dealing_Duco_ActivityRecon.ClientAmount`
- `Dealing_Duco_ActivityRecon.ClientUnits`
- `Dealing_Duco_ActivityRecon.eToroLocalAmount`
- `Dealing_Duco_ActivityRecon.eToroUSDAmount`
- `Dealing_Duco_ActivityRecon.eToro_Units`
- `Dealing_Duco_EODRecon.ClientAmount`
- `Dealing_Duco_EODRecon.ClientUnits`
- `Dealing_Duco_EODRecon.eToroUSDAmount`
- `Dealing_Duco_EODRecon.eToro_Units`
- `Dealing_dbo.Dealing_Duco_ActivityRecon`
- `Dealing_dbo.Dealing_Duco_EODRecon`
- `Dealing_dbo.Dealing_IGReconEODHolding`
- `Dealing_dbo.Dealing_IGReconTrades`
- `Dealing_dbo.Dealing_JPMReconEODHolding`
- `Dealing_dbo.Dealing_JPMReconTrades`
- `Dealing_dbo.Dealing_Marex_Recon_EODHoldings`
- `Dealing_dbo.Dealing_Marex_Recon_EODHoldings_Futures`
- `Dealing_dbo.Dealing_Marex_Recon_Trades`
- `Dealing_dbo.Dealing_Marex_Recon_Trades_Futures`
- `Dealing_dbo.Dealing_VisionRecon_EODHoldings`
- `Dealing_dbo.Dealing_VisionRecon_Trades`
- `LP_IG_OH_OrderHistory.Deal`
- `LP_JPM_EOD_eToro_Report_ComponentUnderlyings.Market`

</details>

### Cluster 49 — `FiatDwhDB.Tribe` (20 members)

**Top members:**
- `FiatDwhDB.Tribe` — 38.0
- `eMoney_Tribe.AccountsSnapshots_BankAccount-393561` — 29.0
- `Tribe.AccountsSnapshots_BankAccount-393561` — 23.0
- `eMoney_Tribe.AccountsSnapshots_AccountSnapshot-956050` — 23.0
- `eMoney_Tribe.SettlementsTransactions_SecurityChecks-426253` — 21.0
- `eMoney_Tribe.SettlementsTransactions_RiskActions-236807` — 15.0
- `eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239` — 13.0
- `eMoney_Tribe.CardsSnapshots_Account-513255` — 12.0
- `eMoney_Tribe.CardsSnapshots_Accounts-350640` — 12.0
- `eMoney_Tribe.CardsSnapshots_CardSnapshot-140457` — 11.0
- `Tribe.SettlementsTransactions_RiskActions-236807` — 10.0
- `eMoney_Tribe.AccountsSnapshots_BankAccounts-795870` — 9.0
- `eMoney_Tribe.CardsSnapshots-890718` — 7.0
- `eMoney_Tribe.AccountsSnapshots-509416` — 6.0
- `eMoney_Tribe.CardsSnapshots_BankAccounts-83854` — 4.0

<details><summary>All members</summary>

- `FiatDwhDB.Tribe`
- `Tribe.AccountsSnapshots_BankAccount-393561`
- `Tribe.CardsSnapshots_Account-513255`
- `Tribe.CardsSnapshots_BankAccounts-83854`
- `Tribe.SettlementsTransactions_RiskActions-236807`
- `eMoney_Tribe.AccountsSnapshots-509416`
- `eMoney_Tribe.AccountsSnapshots_AccountSnapshot-956050`
- `eMoney_Tribe.AccountsSnapshots_BankAccount-393561`
- `eMoney_Tribe.AccountsSnapshots_BankAccounts-795870`
- `eMoney_Tribe.CardsSnapshots-890718`
- `eMoney_Tribe.CardsSnapshots_Account-513255`
- `eMoney_Tribe.CardsSnapshots_Accounts-350640`
- `eMoney_Tribe.CardsSnapshots_BankAccounts-83854`
- `eMoney_Tribe.CardsSnapshots_CardSnapshot-140457`
- `eMoney_Tribe.SettlementsTransactions-333243`
- `eMoney_Tribe.SettlementsTransactions_RiskActions-236807`
- `eMoney_Tribe.SettlementsTransactions_SecurityChecks-426253`
- `eMoney_Tribe.SettlementsTransactions_SettlementTransaction-637239`
- `eMoney_dbo.ETL_AccountSnapshot`
- `eMoney_dbo.ETL_SettlementsTransactions`

</details>