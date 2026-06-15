# Migration Blacklist - Phase A0 (OpsDB-only) - 2026-05-31

Source: `dbo.ObjectsStatusHistory` aggregated by ProcedureName.
Universe: 1779 distinct procs in OpsDB. This file lists **235** procs that fail at least one Phase-A0 deprecation rule.

**Tick a checkbox = confirm DROP** (the migration runner will skip this proc).
Leave unchecked = REPRIEVE (we'll migrate it; please add a one-line `notes` reason in the CSV).

## Tally by verdict

| Verdict | Procs |
|---|---|
| A0_DISABLED | 12 |
| A4_DAILY_30D | 3 |
| A4_DAILY_365D | 133 |
| A4_DAILY_90D | 49 |
| A4_HOURLY | 6 |
| A4_MONTHLY | 4 |
| A4_NEVER_SUCCEEDED | 28 |

## Tally by proc kind

| Kind | Procs | Notes |
|---|---|---|
| synapse_sp | 191 | real Synapse stored procedure - primary blacklist target |
| databricks_job | 22 | BI_DataBricks-* - already-on-DBX job, no Synapse migration needed |
| other | 18 | unclassified - manual review |
| lake_path | 2 | Bronze/Silver/Gold/LP/etc lake-path identifier - generic-pipeline asset |
| multi_ref | 1 | comma-separated multi-proc identifier - manual review |
| dwh_meta | 1 | DWH-* metadata identifier - manual review |

---

## A0_DISABLED (12 procs)

Already marked ``IsActive=False`` in OpsDB. Auto-confirm-drop unless someone reactivates.

### kind: synapse_sp (12)

- [ ] `BI_DB_dbo.SP_AB_Test`  | freq=Daily | last_success=2023-01-25 05:32:26 | last_failure=2022-10-13 09:44:19 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Daily_PI_Performance`  | freq=Daily | last_success=2024-03-16 20:32:26 | last_failure=2024-03-03 21:02:02 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_DailyCommoditiesReport`  | freq=Daily | last_success=2024-04-10 07:30:44 | last_failure=2024-06-02 08:32:53 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_DailyZeroPnL_Stocks`  | freq=Daily | last_success=2024-02-10 08:44:38 | last_failure=2024-04-05 20:21:46 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_MergedDailySchedules`  | freq=Daily | last_success=2024-06-02 05:33:59 | last_failure=2024-03-10 06:30:07 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_MonthlyGain`  | freq=Monthly | last_success=2023-01-25 06:19:14 | last_failure=2022-09-13 07:23:21 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_MonthlyRiskScore`  | freq=Monthly | last_success=2023-01-25 06:01:01 | last_failure=2022-09-13 07:09:54 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_PI_Dashboard`  | freq=Daily | last_success=2024-03-16 20:24:13 | last_failure=2024-02-22 20:32:49 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_VolatilityEvents`  | freq=Daily | last_success=2023-01-25 06:32:10 | last_failure=2022-11-01 09:12:38 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_Boundary_Cost`  | freq=Daily | last_success=2023-03-16 08:37:06 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `DWH_pagetracking.Fact_MarketPageViews`  | freq=Daily | last_success=2024-06-01 10:44:32 | last_failure=2024-06-02 08:30:32 | succ_90d=0 | fail_90d=0
- [ ] `DWH_pagetracking.Fact_UserPageViews`  | freq= | last_success=2024-06-01 10:41:30 | last_failure=2024-06-02 08:30:31 | succ_90d=0 | fail_90d=0

---

## A4_DAILY_30D (3 procs)

Daily SP, last successful run 30-90 days ago. Likely silently failing.

### kind: databricks_job (1)

- [ ] `BI_DataBricks-etoro_customer_customer_deceased`  | freq=Daily | last_success=2026-03-22 04:08:39 | last_failure=2026-04-20 04:19:35 | succ_90d=20 | fail_90d=102

### kind: other (1)

- [ ] `DataBricks-export_table_to_file-SFMC_etoroDailyData`  | freq=Daily | last_success=2026-04-13 10:07:46 | last_failure= | succ_90d=3 | fail_90d=0

### kind: synapse_sp (1)

- [ ] `Dealing_dbo.SP_GSRecon`  | freq=Daily | last_success=2026-04-13 06:24:16 | last_failure=2024-10-31 06:32:04 | succ_90d=50 | fail_90d=0

---

## A4_DAILY_365D (133 procs)

Daily SP, last successful run > 365 days ago. Strongest drop candidate.

### kind: databricks_job (2)

- [ ] `BI_DataBricks-Dealing_Latency_Report`  | freq=Daily | last_success=2025-03-02 06:42:17 | last_failure=2025-01-13 12:56:59 | succ_90d=0 | fail_90d=0
- [ ] `BI_DataBricks-PTP_Automation`  | freq=Daily | last_success=2025-03-13 04:18:37 | last_failure=2025-03-20 04:33:39 | succ_90d=0 | fail_90d=0

### kind: other (3)

- [ ] `[Dealing_dbo].[SP_CopyPortfolio_Allocation]`  | freq=Daily | last_success=2023-03-11 04:20:13 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BigQueryGADataUploadData_Ltv`  | freq=Daily | last_success=2022-09-05 07:24:24 | last_failure=2022-09-18 07:14:17 | succ_90d=0 | fail_90d=0
- [ ] `DataBricks-Sedric_IsMajor`  | freq=Daily | last_success=2023-08-07 10:14:00 | last_failure=2023-07-26 10:11:08 | succ_90d=0 | fail_90d=0

### kind: synapse_sp (128)

- [ ] `BI_DB_dbo.[SP_EY_Audit_RollOverFee]`  | freq=Daily | last_success=2023-06-27 04:44:30 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.Client_Balance_Breakdown`  | freq=Daily | last_success=2023-05-15 10:26:03 | last_failure=2023-05-15 04:37:10 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_AffiliateFraudLoss`  | freq=Daily | last_success=2023-11-12 04:08:44 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_AML_Affiliate_Abuse`  | freq=Daily | last_success=2024-12-31 09:26:03 | last_failure=2024-06-28 07:09:22 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_AML_Multiple_Accounts`  | freq=Daily | last_success=2025-03-13 05:29:57 | last_failure=2025-03-06 04:58:48 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_AML_Terror_Monitor_Dashboard`  | freq=Daily | last_success=2024-12-28 04:47:25 | last_failure=2023-10-24 04:13:01 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_ASIC_ClientBalanceFinance`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_AssignmentToolBacklog`  | freq=Daily | last_success=2024-03-19 04:57:16 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_AssignmentToolSLAs`  | freq=Daily | last_success=2024-03-07 07:09:27 | last_failure=2024-03-07 06:56:00 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_AssignmentToolTasks`  | freq=Daily | last_success=2024-03-07 07:03:47 | last_failure=2024-03-07 06:56:14 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_AssignmentToolVolumes`  | freq=Daily | last_success=2024-03-07 05:28:24 | last_failure=2024-02-21 05:11:50 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_BI_DB_ASIC_Monitoring_CFD`  | freq=Daily | last_success=2023-11-05 04:20:15 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_BI_DB_ASIC_Monitoring_CFD_W_Sun`  | freq=Daily | last_success=2023-11-05 12:51:51 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_BI_DB_Compliance_BI_Clients_Dashboard`  | freq=Daily | last_success=2023-11-29 04:51:04 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_CB_Gap_Categorization`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_CID_Daily_NWA`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Client_Balance_New`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Copyfunds_Watched_Not_Invested`  | freq=Daily | last_success=2025-03-10 05:22:14 | last_failure=2025-03-12 05:46:38 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Crypto_NOP`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_CycleGap`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_D_Email_for_KYT`  | freq=Daily | last_success=2024-04-25 06:33:03 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Daily_CB_Gaps_All`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Daily_CreditLine`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Daily_Dividends`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Daily_PI_Performance_COPYDATA_RuningSideBySide`  | freq=Daily | last_success=2024-03-16 20:25:45 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_DailyDividendsByPosition`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure=2023-11-02 07:04:44 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_DailyZero_TreeSize_NEW`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_DepositWithdrawFee`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_DWH_GainDaily_COPYDATA_RuningSideBySide`  | freq=Daily | last_success=2024-05-07 04:59:55 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_ECB_ExchangeRateAPI_Update_Columns`  | freq=Daily | last_success=2025-01-19 00:15:08 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EndOfDayReport_Cashouts`  | freq=Daily | last_success=2024-03-11 08:46:57 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EndOfDayReport_Redeems`  | freq=Daily | last_success=2024-03-11 08:41:28 | last_failure=2023-04-20 00:29:53 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Auditor_Unrealized_Calculations`  | freq=Daily | last_success=2025-04-15 12:45:37 | last_failure=2024-06-18 12:06:36 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Opened_Positions`  | freq=Daily | last_success=2024-01-15 06:35:32 | last_failure=2023-06-27 08:19:45 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Position_LastOpPriceRate`  | freq=Daily | last_success=2024-01-20 05:11:20 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Finance_Non_US_Settlement_Report`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Finance_Panel_Reports`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_FirstTimeFunded`  | freq=Daily | last_success=2025-02-18 12:05:20 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_FirstTimeRev30`  | freq=Daily | last_success=2024-04-14 04:42:24 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Guru_Ratio_Populate`  | freq=Daily | last_success=2024-06-06 09:21:46 | last_failure=2024-06-03 08:50:37 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_GuruRatio`  | freq=Daily | last_success=2023-12-28 13:25:58 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Instrument_Details_During_Call`  | freq=Daily | last_success=2024-06-02 08:14:36 | last_failure=2024-06-26 12:05:40 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_KYC_Report`  | freq=Daily | last_success=2024-06-02 06:35:42 | last_failure=2024-04-05 20:21:45 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_MarketingCloudUserBehavior`  | freq=Daily | last_success=2024-06-02 10:01:44 | last_failure=2023-08-31 13:40:28 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_NOP_TradingActivity_Risk_Daily`  | freq=Daily | last_success=2024-01-17 04:09:48 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Outliers_New`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide`  | freq=Daily | last_success=2024-04-15 06:51:53 | last_failure=2024-02-10 07:17:52 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_PositionPnL`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_PositionPnL_UnrealizedPnL_Close_Adjustment`  | freq=Daily | last_success=2024-07-07 06:00:40 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Professional_List`  | freq=Daily | last_success=2024-06-02 04:52:57 | last_failure=2024-03-09 06:29:22 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Real_Crypto_Loans`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_RealCrypto_Lev2`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Risk_RiskStatusChange`  | freq=Daily | last_success=2024-01-03 05:11:55 | last_failure=2023-08-16 08:09:03 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_RiskClassification`  | freq=Daily | last_success=2024-06-02 04:59:18 | last_failure=2024-02-29 04:54:58 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_RollOverFee_Dividends`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_SCD_Staking_Position`  | freq=Daily | last_success=2024-06-02 08:18:26 | last_failure=2024-04-05 20:03:10 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_SF_Cases`  | freq=Daily | last_success=2024-05-30 06:03:33 | last_failure=2024-06-02 08:31:24 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_SF_Cases_Panel`  | freq=Daily | last_success=2023-01-25 03:30:44 | last_failure=2022-10-31 04:09:55 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Social_Activity_COPYDATA_RuningSideBySide`  | freq=Daily | last_success=2024-05-06 04:54:01 | last_failure=2024-03-24 04:37:35 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Social_Activity_Updates_COPYDATA_RuningSideBySide`  | freq=Daily | last_success=2024-04-15 07:51:07 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_SpreadedPriceCandle60MinSplitted`  | freq=Daily | last_success=2024-06-02 06:15:21 | last_failure=2024-03-04 08:43:25 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Staking_Daily_Email_for_labs`  | freq=Daily | last_success=2023-11-15 04:41:19 | last_failure=2023-11-20 04:46:16 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_TicketsForOPSNEW`  | freq=Daily | last_success=2024-04-23 05:52:47 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Users_Bio`  | freq=Daily | last_success=2023-11-08 04:11:30 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_VarCommission`  | freq=Daily | last_success=2025-01-21 04:01:33 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-CopyFromLake.Bronze_Fivetran_google_sheets_marex_mapping_table`  | freq=Daily | last_success=2024-02-14 11:34:53 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-CopyFromLake.DB_Logs_History_OrderForClose`  | freq=Daily | last_success=2024-08-08 09:49:05 | last_failure=2024-04-14 05:33:18 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-CopyFromLake.DB_Logs_History_OrderForOpen`  | freq=Daily | last_success=2024-08-01 04:53:03 | last_failure=2025-02-13 06:16:26 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-CopyFromLake.etoro_DWH_HistoryOrderForClose`  | freq=Daily | last_success=2025-01-12 06:30:00 | last_failure=2025-01-07 07:07:08 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-CopyFromLake.etoro_Hedge_HBCExecutionLog`  | freq=Daily | last_success=2024-01-15 06:13:16 | last_failure=2024-01-16 04:55:42 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-CopyFromLake.etoro_History_OrdersMarketFail`  | freq=Daily | last_success=2025-04-22 09:55:46 | last_failure=2025-02-13 06:17:41 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-CopyFromLake.etoro_Trade_OrdersEntryTbl`  | freq=Daily | last_success=2025-04-22 06:14:29 | last_failure=2024-01-19 04:34:22 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-CopyFromLake.eToroLogs_Real_Hedge_EMSOrders`  | freq=Daily | last_success=2025-01-26 04:59:02 | last_failure=2024-01-14 13:10:56 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-CopyFromLake.eToroLogs_Real_Hedge_RequestExecutionLog`  | freq=Daily | last_success=2024-01-15 05:53:31 | last_failure=2024-01-16 04:41:01 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-CopyFromLake.eToroLogs_Real_Hedge_RequestLimitExecutionLog`  | freq=Daily | last_success=2024-01-15 05:53:28 | last_failure=2024-01-16 04:46:47 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-CopyFromLake.WalletBalancesReportDB_Wallet_FinanceReportsBalances`  | freq=Daily | last_success=2025-03-24 06:39:21 | last_failure=2025-02-25 05:46:11 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-DE_dbo.FiatCurrencyBalancesStatuses`  | freq=Daily | last_success=2023-10-25 04:21:44 | last_failure=2023-09-28 16:34:49 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-general.KycAnalyzer_ClientRiskProfile`  | freq=Daily | last_success=2024-10-09 05:07:42 | last_failure=2024-03-27 04:29:44 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-general.SolarisBankIdentDb_SolarisBankIdent`  | freq=Daily | last_success=2024-10-09 05:07:15 | last_failure=2024-07-14 05:24:47 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-general.VideoIdentDb_VideoIdent`  | freq=Daily | last_success=2024-11-06 05:55:40 | last_failure=2024-10-07 06:09:37 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_DWH_CIDsDailyRisk`  | freq=Daily | last_success=2023-08-14 04:51:33 | last_failure=2023-08-15 05:19:17 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_SourcesFromDataLakeToSynapse`  | freq=Daily | last_success=2023-11-30 09:17:14 | last_failure=2024-01-04 05:27:32 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_UsageTracking_SF`  | freq=Daily | last_success=2024-05-27 04:07:48 | last_failure=2024-05-20 04:09:16 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_Apex_PnL`  | freq=Daily | last_success=2024-06-08 09:19:29 | last_failure=2023-10-29 14:10:49 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_Best_Execution`  | freq=Daily | last_success=2025-01-12 07:56:10 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_DailySpreadsAggregated`  | freq=Daily | last_success=2025-02-18 14:13:12 | last_failure=2024-06-19 06:02:17 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_DailySpreadsAggregatedFX`  | freq=Daily | last_success=2024-04-11 05:17:26 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_Execution_Slippage`  | freq=Daily | last_success=2025-01-12 05:15:59 | last_failure=2024-08-03 06:01:24 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_Failures`  | freq=Daily | last_success=2025-04-22 10:06:56 | last_failure=2025-02-11 19:32:59 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_Latency_Report`  | freq=Daily | last_success=2025-01-12 07:41:52 | last_failure=2024-02-21 06:23:36 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_Manual_Exec`  | freq=Daily | last_success=2024-06-09 05:32:52 | last_failure=2024-02-06 05:02:38 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_NewHedgeDash_Email_CSV_0230AM`  | freq=Daily | last_success=2025-05-12 06:36:02 | last_failure=2025-05-08 14:11:15 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_NewHedgeDash_Email_CSV_1130PM`  | freq=Daily | last_success=2025-05-12 06:41:23 | last_failure=2025-05-08 14:11:17 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_OccurredAtProvider_Latency`  | freq=Daily | last_success=2025-01-12 05:07:14 | last_failure=2024-10-27 05:06:53 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_Positions_OpenClose_Breakdown`  | freq=Daily | last_success=2024-09-01 06:03:23 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_Regime_Flags`  | freq=Daily | last_success=2025-01-20 05:19:55 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_SelfCopyingPI`  | freq=Daily | last_success=2023-09-04 11:46:02 | last_failure=2023-08-31 12:45:31 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_Slippage_Report`  | freq=Daily | last_success=2025-01-12 07:34:06 | last_failure=2024-07-28 06:15:28 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_USTradeReports`  | freq=Daily | last_success=2025-01-14 06:44:40 | last_failure=2024-09-19 07:55:00 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Copy_Etoro_Hedge_HBCExecutionLog`  | freq=Daily | last_success=2023-12-28 05:06:37 | last_failure=2024-01-04 05:40:59 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Copy_Etoro_Hedge_HBCOrderLog`  | freq=Daily | last_success=2023-12-28 04:06:35 | last_failure=2024-01-04 04:55:56 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Copy_eToroLogs_Real_Hedge_EMSOrders`  | freq=Daily | last_success=2025-01-26 04:12:04 | last_failure=2023-05-02 13:52:20 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Copy_eToroLogs_Real_Hedge_RequestExecutionLog`  | freq=Daily | last_success=2023-12-29 04:11:11 | last_failure=2024-01-04 05:03:34 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Copy_eToroLogs_Real_Hedge_RequestLimitExecutionLog`  | freq=Daily | last_success=2023-11-14 04:41:37 | last_failure=2024-01-04 05:03:30 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Copy_ExternalSources_LP_APEX_EXT869_3EU`  | freq=Daily | last_success=2023-10-29 13:55:31 | last_failure=2023-11-02 08:07:24 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Copy_ExternalSources_LP_APEX_EXT872_3EU_217314`  | freq=Daily | last_success=2023-10-29 14:00:55 | last_failure=2023-11-02 08:11:21 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Copy_ExternalSources_LP_APEX_EXT981_3EU`  | freq=Daily | last_success=2023-10-29 14:00:54 | last_failure=2023-11-02 08:08:41 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Copy_ExternalSources_LP_APEX_EXT982_3EU`  | freq=Daily | last_success=2023-10-29 14:00:50 | last_failure=2023-11-02 08:08:48 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Copy_PositionFailReal_History_PositionFail_DWH`  | freq=Daily | last_success=2024-03-28 06:07:52 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Copy_PriceLog_History_CurrencyPrice`  | freq=Daily | last_success=2024-06-09 04:14:26 | last_failure=2024-06-18 04:24:11 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Copy_PricesFromProvider_MarketCurrencyPrice`  | freq=Daily | last_success=2025-01-12 04:32:56 | last_failure=2024-01-28 05:13:01 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Create_External_DB_Logs_History_OrderForClose`  | freq=Daily | last_success=2024-01-07 05:16:10 | last_failure=2023-06-29 06:42:48 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Create_External_DB_Logs_History_OrderForOpen`  | freq=Daily | last_success=2024-01-07 05:25:46 | last_failure=2023-06-23 05:13:20 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Create_External_Etoro_History_CEPListCIDMappings`  | freq=Daily | last_success=2023-11-20 05:30:53 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Create_External_etoro_History_Mirror`  | freq=Daily | last_success=2024-01-16 04:32:53 | last_failure=2023-12-21 04:27:30 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Create_External_Etoro_History_OrdersEntryTbl`  | freq=Daily | last_success=2023-12-27 04:16:14 | last_failure=2024-01-04 05:16:44 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Create_External_Etoro_History_OrdersExitTbl`  | freq=Daily | last_success=2023-11-15 04:16:26 | last_failure=2023-12-19 04:25:52 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Create_External_Etoro_Trade_OrdersEntryTbl`  | freq=Daily | last_success=2025-04-22 04:46:15 | last_failure=2023-09-27 04:31:31 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Create_External_Etoro_Trade_OrdersExitTbl`  | freq=Daily | last_success=2025-04-22 04:46:00 | last_failure=2023-08-18 04:36:04 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Create_External_etoroGeneral_History_GuruCopiers`  | freq=Daily | last_success=2023-06-14 04:29:16 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Create_External_eToroLogs_Real_Hedge_ExecutionStrategyOrderLog`  | freq=Daily | last_success=2024-01-13 04:25:51 | last_failure=2024-01-16 04:56:01 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Create_External_eToroLogs_Real_Hedge_OrderLog`  | freq=Daily | last_success=2023-12-18 04:45:51 | last_failure=2023-09-27 04:37:48 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Create_External_Sodreconciliation_apex_EXT869_CashActivity`  | freq=Daily | last_success=2024-11-13 14:02:28 | last_failure=2024-11-14 05:12:15 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_staging.SP_Create_Rankings_StockInfo_DailyInstrumentInfo`  | freq=Daily | last_success=2024-01-31 04:11:19 | last_failure=2024-02-05 04:21:11 | succ_90d=0 | fail_90d=0
- [ ] `DWH_watchlists.Fact_Watchlists`  | freq=Daily | last_success=2024-06-01 09:33:42 | last_failure=2024-06-02 08:30:38 | succ_90d=0 | fail_90d=0
- [ ] `DWH_watchlists.Fact_WatchlistsItems`  | freq=Daily | last_success=2024-06-01 09:33:55 | last_failure=2024-06-02 08:30:42 | succ_90d=0 | fail_90d=0
- [ ] `eMoney_dbo.SP_eMoney_Yearly_Volume_Target_2023`  | freq=Daily | last_success=2024-01-01 05:16:27 | last_failure=2024-01-02 10:24:54 | succ_90d=0 | fail_90d=0
- [ ] `EXW_dbo.SP_EXW_EthFee_Blockchain`  | freq=Daily | last_success=2024-07-29 06:11:50 | last_failure=2024-08-11 05:15:50 | succ_90d=0 | fail_90d=0

---

## A4_DAILY_90D (49 procs)

Daily SP, last successful run 90-365 days ago. Strong drop candidate.

### kind: databricks_job (11)

- [ ] `BI_DataBricks-Compliance_MAS_Daily_Client_Metrics`  | freq=Daily | last_success=2025-07-16 05:55:07 | last_failure=2025-07-21 04:38:03 | succ_90d=0 | fail_90d=0
- [ ] `BI_DataBricks-Compliance_MAS_Population`  | freq=Daily | last_success=2025-07-08 05:58:14 | last_failure=2025-07-15 05:18:32 | succ_90d=0 | fail_90d=0
- [ ] `BI_DataBricks-operations_ops_mimo_data`  | freq=Daily | last_success=2025-06-30 10:09:01 | last_failure=2025-07-01 06:36:41 | succ_90d=0 | fail_90d=0
- [ ] `BI_DataBricks-SP_Customer_Customer_Support_AML_Handling_Days_Main`  | freq=Daily | last_success=2025-09-01 10:28:17 | last_failure=2025-09-09 04:51:34 | succ_90d=0 | fail_90d=0
- [ ] `BI_DataBricks-SP_Customer_Customer_Support_Case`  | freq=Daily | last_success=2025-08-20 04:12:08 | last_failure=2025-08-25 07:52:06 | succ_90d=0 | fail_90d=0
- [ ] `BI_DataBricks-SP_Customer_Customer_Support_Cases_Update_Main`  | freq=Daily | last_success=2025-08-26 14:08:19 | last_failure=2024-09-02 08:49:08 | succ_90d=0 | fail_90d=0
- [ ] `BI_DataBricks-SP_Customer_Customer_Support_CSAT_Main`  | freq=Daily | last_success=2025-08-20 04:12:29 | last_failure=2025-08-25 06:59:37 | succ_90d=0 | fail_90d=0
- [ ] `BI_DataBricks-SP_Customer_Customer_Support_Live_Chat_Transcript_Main`  | freq=Daily | last_success=2025-08-20 04:29:21 | last_failure=2025-09-09 05:34:44 | succ_90d=0 | fail_90d=0
- [ ] `BI_DataBricks-SP_Customer_Customer_Support_Salesforce_Reply_Main`  | freq=Daily | last_success=2025-08-20 05:00:02 | last_failure=2025-09-09 04:39:42 | succ_90d=0 | fail_90d=0
- [ ] `BI_DataBricks-SP_External_ISA`  | freq=Daily | last_success=2025-12-15 10:58:56 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DataBricks-SP_Marketing_Acquisition_Anomalies_Daily_Main`  | freq=Daily | last_success=2025-12-29 04:27:34 | last_failure=2025-12-30 04:39:25 | succ_90d=0 | fail_90d=0

### kind: other (1)

- [ ] `DataBricks-DLT_Recon`  | freq=Daily | last_success=2025-11-01 06:59:31 | last_failure=2025-07-14 07:21:00 | succ_90d=0 | fail_90d=0

### kind: synapse_sp (37)

- [ ] `BI_DB_dbo.SP_CashRiskMatrix`  | freq=Daily | last_success=2025-10-06 04:49:56 | last_failure=2025-10-08 05:19:19 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_CID_NPS_Panel`  | freq=Daily | last_success=2025-07-11 05:42:42 | last_failure=2025-07-28 16:30:54 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Deposit_Reversals_PIPs`  | freq=Daily | last_success=2025-09-11 04:59:29 | last_failure=2025-09-17 05:19:59 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_DepositWithdrawFee_2025`  | freq=Daily | last_success=2025-07-27 04:58:41 | last_failure=2025-07-28 05:07:14 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_DLT_Report`  | freq=Daily | last_success=2025-11-18 04:50:59 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Automation_CashoutReason`  | freq=Daily | last_success=2025-10-28 11:02:15 | last_failure=2023-06-27 04:48:31 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Automation_Configuration`  | freq=Daily | last_success=2025-10-28 11:05:36 | last_failure=2024-01-16 11:02:54 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Automation_LastOpRate_OnOpen_Daily`  | freq=Daily | last_success=2025-10-28 11:02:29 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Automation_Opened_Positions_Config_Daily`  | freq=Daily | last_success=2025-07-01 06:43:14 | last_failure=2025-05-08 05:56:28 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_BO_Deposits_With_PIPs`  | freq=Daily | last_success=2025-10-28 11:06:18 | last_failure=2025-05-13 11:11:00 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_CashoutFees`  | freq=Daily | last_success=2025-10-28 11:01:57 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_ChangeLog`  | freq=Daily | last_success=2025-10-28 11:04:59 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Client_Balance`  | freq=Daily | last_success=2025-10-28 11:04:55 | last_failure=2023-07-08 04:23:25 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Closed_Positions`  | freq=Daily | last_success=2025-10-28 11:05:28 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Compensation`  | freq=Daily | last_success=2025-10-28 11:02:05 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Conversions`  | freq=Daily | last_success=2025-07-27 11:01:10 | last_failure=2025-08-03 11:10:39 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Deposit_Cashouts`  | freq=Daily | last_success=2025-10-28 11:04:14 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_IBAN_Trades_MIMO`  | freq=Daily | last_success=2025-10-28 11:02:05 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_IFRS_Control`  | freq=Daily | last_success=2025-07-01 11:45:08 | last_failure=2025-06-30 12:09:17 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Negative_Refill`  | freq=Daily | last_success=2025-10-28 11:02:10 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Ran_Prices`  | freq=Daily | last_success=2025-10-28 11:06:13 | last_failure=2025-01-20 11:22:06 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Redeem`  | freq=Daily | last_success=2025-10-28 11:02:18 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Redeem_Per_CID`  | freq=Daily | last_success=2025-10-28 11:02:03 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_RedeemsFee`  | freq=Daily | last_success=2025-10-28 11:01:57 | last_failure=2025-06-29 11:15:28 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Reopen_Positions`  | freq=Daily | last_success=2025-10-28 11:02:03 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_RollOverFee`  | freq=Daily | last_success=2025-10-28 11:02:17 | last_failure=2023-09-30 11:12:09 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_EY_Audit_Withdraws_With_PIPs`  | freq=Daily | last_success=2025-10-28 11:03:39 | last_failure=2025-08-26 11:02:41 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_PIPs_Report_MID_Settings`  | freq=Daily | last_success=2025-09-11 04:59:09 | last_failure=2025-09-17 05:06:55 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Reg_UK_Compliance_SocialActivity`  | freq=Daily | last_success=2025-09-05 05:02:34 | last_failure=2023-07-13 18:26:03 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Reg_UK_Compliance_SocialActivityM`  | freq=Daily | last_success=2025-09-05 05:03:38 | last_failure=2023-06-12 10:42:06 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Social_Activity`  | freq=Daily | last_success=2025-09-05 04:56:56 | last_failure=2025-09-21 05:06:42 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Social_Activity_GDRP`  | freq=Daily | last_success=2025-09-21 09:40:46 | last_failure=2024-01-28 13:22:19 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Social_Activity_Updates`  | freq=Daily | last_success=2025-09-21 04:56:31 | last_failure=2024-03-08 07:00:37 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Withdraw_Rollback_PIPs`  | freq=Daily | last_success=2025-09-11 05:12:37 | last_failure=2025-09-17 05:23:21 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-CopyFromLake.customerfinancedb_customer_firsttimedeposits`  | freq=Daily | last_success=2025-09-09 07:32:35 | last_failure=2025-07-11 11:21:53 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_Market_Manipulation_Report_FCA`  | freq=Daily | last_success=2025-07-13 06:27:24 | last_failure=2025-07-16 06:51:54 | succ_90d=0 | fail_90d=0
- [ ] `eMoney_dbo.SP_eMoney_Calculated_Balance`  | freq=Daily | last_success=2025-06-11 04:47:30 | last_failure=2025-06-09 13:18:49 | succ_90d=0 | fail_90d=0

---

## A4_HOURLY (6 procs)

Hourly SP, last successful run > 2 days ago.

### kind: other (2)

- [ ] `BI_DataBricks_H_Dealing_Production_Diffusion_Analysis`  | freq=Hourly | last_success=2024-05-02 04:27:10 | last_failure=2024-04-15 04:19:29 | succ_90d=0 | fail_90d=0
- [ ] `DataBricks-export_table_to_file-SFMC_etoroAffiliateDailyData`  | freq=Hourly | last_success=2026-04-28 14:52:01 | last_failure=2026-04-12 10:52:38 | succ_90d=54 | fail_90d=6

### kind: synapse_sp (4)

- [ ] `BI_DB_dbo.SP_H_Deposits`  | freq=Hourly | last_success=2024-01-17 09:16:30 | last_failure=2024-01-09 04:03:05 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_H_Deposits_Wires_From_Googlesheet`  | freq=Hourly | last_success=2026-05-14 08:25:14 | last_failure=2026-04-26 20:14:49 | succ_90d=1282 | fail_90d=2
- [ ] `BI_DB_dbo.SP_H_PaymentSent_Results`  | freq=Hourly | last_success=2024-03-14 04:33:51 | last_failure=2024-05-08 08:18:15 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-CopyFromLake.Streams_dbo_Entries`  | freq=Hourly | last_success=2025-09-07 08:49:06 | last_failure=2025-06-29 04:10:46 | succ_90d=0 | fail_90d=0

---

## A4_MONTHLY (4 procs)

Monthly SP, last successful run > 45 days ago.

### kind: databricks_job (1)

- [ ] `BI_DataBricks-Dealing_volatility_bucket`  | freq=Monthly | last_success=2025-11-01 06:11:41 | last_failure=2025-09-30 09:06:58 | succ_90d=0 | fail_90d=0

### kind: synapse_sp (3)

- [ ] `BI_DB_dbo.SP_M_Crypto_RECON`  | freq=Monthly | last_success=2025-01-01 04:01:34 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_M_LTV_BI_Actual_Snapshot`  | freq=Monthly | last_success=2024-01-01 09:22:49 | last_failure= | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_M_CryptoRebateDiamond`  | freq=Monthly | last_success=2025-10-01 04:21:29 | last_failure= | succ_90d=0 | fail_90d=0

---

## A4_NEVER_SUCCEEDED (28 procs)

No successful run on record. Either always-failing or stub. Drop unless flagged for active dev.

### kind: databricks_job (7)

- [ ] `BI_DataBricks-DDR_Fact_Revenue_Generating_Actions`  | freq=Daily | last_success= | last_failure=2026-05-20 15:01:55 | succ_90d=0 | fail_90d=18
- [ ] `BI_DataBricks-Dealing_Bloomberg_holdings_pct_of_mktcap`  | freq=Daily | last_success= | last_failure=2025-12-07 10:20:24 | succ_90d=0 | fail_90d=0
- [ ] `BI_DataBricks-Dealing_premier_customer`  | freq=Monthly | last_success= | last_failure=2025-01-19 12:10:47 | succ_90d=0 | fail_90d=0
- [ ] `BI_DataBricks-Dealing-Premier_Clients_positions_monthly_report_M`  | freq=Monthly | last_success= | last_failure=2026-05-01 10:27:59 | succ_90d=0 | fail_90d=3
- [ ] `BI_DataBricks-SP_External_Club_Service_Balance_Main`  | freq=Daily | last_success= | last_failure=2025-09-09 05:38:41 | succ_90d=0 | fail_90d=0
- [ ] `BI_DataBricks-SP_PI_Diversification`  | freq=Daily | last_success= | last_failure=2025-07-23 12:12:34 | succ_90d=0 | fail_90d=0
- [ ] `BI_DataBricks-Voice-Of-The-Customer-Messages`  | freq=Daily | last_success= | last_failure=2026-02-26 09:36:30 | succ_90d=0 | fail_90d=0

### kind: dwh_meta (1)

- [ ] `DWH-DAYLY`  | freq=Daily | last_success= | last_failure=2026-01-14 10:50:59 | succ_90d=0 | fail_90d=0

### kind: lake_path (2)

- [ ] `Gold/sql_dp_prod_we/Dealing_dbo/Dealing_Staking_Summary`  | freq=Daily | last_success= | last_failure=2025-09-03 06:41:25 | succ_90d=0 | fail_90d=0
- [ ] `Gold/sql_dp_prod_we/Dealing_dbo/Dealing_Staking_Summary_US`  | freq=Daily | last_success= | last_failure=2025-09-03 06:41:25 | succ_90d=0 | fail_90d=0

### kind: multi_ref (1)

- [ ] `Share_Lending_Custody_Reconciliation_Main,BI_DataBricks-Share_Lending_Custody_Reconciliation`  | freq=Daily | last_success= | last_failure=2026-05-29 07:02:49 | succ_90d=0 | fail_90d=21

### kind: other (11)

- [ ] `BI_DataBrick-dealing_premier_clinet_report`  | freq=Daily | last_success= | last_failure=2025-01-30 09:20:37 | succ_90d=0 | fail_90d=0
- [ ] `BI_Dealing_JP_to_BNY_settlement`  | freq=Daily | last_success= | last_failure=2026-05-20 12:56:34 | succ_90d=0 | fail_90d=8
- [ ] `DataBricks-CorporateActions`  | freq=Daily | last_success= | last_failure=2026-05-19 09:31:31 | succ_90d=0 | fail_90d=5
- [ ] `DataBricks-Dealing_OMS_Daily`  | freq=Daily | last_success= | last_failure=2024-07-10 08:05:45 | succ_90d=0 | fail_90d=0
- [ ] `DataBricks-Dealing_Trading_LimitationsPIsClickSize`  | freq=Daily | last_success= | last_failure=2024-10-13 10:00:59 | succ_90d=0 | fail_90d=0
- [ ] `DataBricks-DealingRND_BestExecution`  | freq=Daily | last_success= | last_failure=2025-04-10 09:48:55 | succ_90d=0 | fail_90d=0
- [ ] `DataBricks-SP_Regime_Flags`  | freq=Daily | last_success= | last_failure=2025-01-05 14:01:05 | succ_90d=0 | fail_90d=0
- [ ] `Share_Lending_Collateral_Main`  | freq=Daily | last_success= | last_failure=2025-07-08 09:01:47 | succ_90d=0 | fail_90d=0
- [ ] `Share_Lending_Custody_Reconciliation_Main`  | freq=Daily | last_success= | last_failure=2025-07-08 06:36:25 | succ_90d=0 | fail_90d=0
- [ ] `SP_BI_DB_CO_Cluster_Daily`  | freq=Daily | last_success= | last_failure=2025-08-24 17:06:06 | succ_90d=0 | fail_90d=0
- [ ] `SP_dl_to_db_ADF_compliance`  | freq=Daily | last_success= | last_failure=2026-03-10 06:47:17 | succ_90d=0 | fail_90d=2

### kind: synapse_sp (6)

- [ ] `BI_DB_dbo.SP_AML_Email_for_KYT`  | freq=Daily | last_success= | last_failure=2024-07-23 07:20:56 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_BI_AMLPeriodicReview_PostReview`  | freq=Daily | last_success= | last_failure=2025-07-01 14:05:43 | succ_90d=0 | fail_90d=0
- [ ] `BI_DB_dbo.SP_Create_External_customerfinancedb_customer_globalftds`  | freq=Daily | last_success= | last_failure=2025-09-09 13:50:50 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-CopyFromLake.customerfinancedb_customer_firsttimedeposits`  | freq=Daily | last_success= | last_failure=2025-04-24 12:55:35 | succ_90d=0 | fail_90d=0
- [ ] `DE_dbo.SP_CopyLakeToSynapse-EXW_Wallet.FinanceReportsBalances`  | freq=Daily | last_success= | last_failure=2023-12-12 12:01:59 | succ_90d=0 | fail_90d=0
- [ ] `Dealing_dbo.SP_Test_4_Alerts_Dealing`  | freq=Daily | last_success= | last_failure=2023-03-16 09:50:18 | succ_90d=0 | fail_90d=0

