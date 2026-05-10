---

## schema: BI_DB_dbo
database: Synapse DWH
total_deployable: 143
generated: 0
deployed: 100
failed: 2
stub_only: 45
last_generate_batch: 0
last_deploy_batch: 5
last_updated: "2026-05-07"

## Schema ALTER + Deployment Progress

| Metric                             | Value      |
| ---------------------------------- | ---------- |
| **Schema**                         | BI_DB_dbo  |
| **Total deployable**               | 75  |
| **Pending (no .alter.sql)**        | 0          |
| **Generated (awaiting UC deploy)** | 0        |
| **Deployed (UC)**                  | 100         |
| **Stub-only (no UC)**              | 47   |
| **Failed**                         | 2         |
| **Stale**                          | 0          |
| **Last generate batch**            | 0          |
| **Last deploy batch**              | 5          |
| **Last updated**                   | 2026-05-07       |

> **Rows**: `Pending` = no local `.alter.sql`. `Generated` = `.alter.sql` present with executable ALTER, UC not deployed in this index pass. `Deployed` = UC ALTERs executed. `Stub only` = comment-only `.alter.sql` (no UC target).

## Tables (92)

| Object                                                                                                                       | Deploy status                                                                                                                                      |
| ---------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| [BI_DB_dbo.BI_DB_ABook_Exposure_NOPHedged](Tables/BI_DB_ABook_Exposure_NOPHedged.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_AML_SAR_Report_FCA](Tables/BI_DB_AML_SAR_Report_FCA.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_AML_Singapore_Risk_Classification](Tables/BI_DB_AML_Singapore_Risk_Classification.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_AML_SubEntity_Categorization](Tables/BI_DB_AML_SubEntity_Categorization.md) | Deployed (Batch 10) — 2026-05-05|
| [BI_DB_dbo.BI_DB_AMLPeriodicReview](Tables/BI_DB_AMLPeriodicReview.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_AppFlyer_Reports](Tables/BI_DB_AppFlyer_Reports.md) | Deployed (Batch 11) — 2026-05-07|
| [BI_DB_dbo.BI_DB_ApproperiatenessTest_FTP_CID_Level](Tables/BI_DB_ApproperiatenessTest_FTP_CID_Level.md) | Deployed (Batch 10) — 2026-05-05|
| [BI_DB_dbo.BI_DB_ASIC_ClientBalanceFinance](Tables/BI_DB_ASIC_ClientBalanceFinance.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_CB_CycleGap_Categorization](Tables/BI_DB_CB_CycleGap_Categorization.md)                                     | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_CID_Daily_NWA](Tables/BI_DB_CID_Daily_NWA.md)                                                               | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_CID_DailyCluster](Tables/BI_DB_CID_DailyCluster.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_CID_DailyPanel_Club](Tables/BI_DB_CID_DailyPanel_Club.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_CID_DailyPanel_FullData](Tables/BI_DB_CID_DailyPanel_FullData.md) | Deployed (Batch 12) — 2026-05-07 — 364/366 stmts OK; wiki col `V3_CompleteDate` absent from UC (stripped)|
| [BI_DB_dbo.BI_DB_CID_LifeStageDefinition](Tables/BI_DB_CID_LifeStageDefinition.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData](Tables/BI_DB_CID_MonthlyPanel_FullData.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_CIDFirstDates](Tables/BI_DB_CIDFirstDates.md)                                                               | Deployed (Batch 10) — 2026-05-05|
| [BI_DB_dbo.BI_DB_CIDLevel_Settlement_Report](Tables/BI_DB_CIDLevel_Settlement_Report.md)                                     | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New](Tables/BI_DB_Client_Balance_Aggregate_Level_New.md)                     | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New](Tables/BI_DB_Client_Balance_CID_Level_New.md)                                 | Deployed (Batch 1) — 2026-03-30; hot-fix 2026-05-10 — RealizedEquity comment corrected (was: Confluence "Unrealized Equity" misattribution from Fact_SnapshotEquity wiki); 4 UC cols re-applied (`...client_balance_cid_level_new.realizedEquity`, `...ddr_fact_aum.RealizedEquityGlobal/TP`, `...v_fact_snapshotequity_fromdateid.RealizedEquity`)|
| [BI_DB_dbo.BI_DB_Client_New_CompensationBreakdown](Tables/BI_DB_Client_New_CompensationBreakdown.md)                         | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_ClubChangeLogProduct](Tables/BI_DB_ClubChangeLogProduct.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_Compliance_Illegal_Trades_Alerts](Tables/BI_DB_Compliance_Illegal_Trades_Alerts.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_Forbidden_Trading](Tables/BI_DB_Compliance_Restriction_Lists_Forbidden_Trading.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_CopyDailyData](Tables/BI_DB_CopyDailyData.md) | Deployed (Batch 11) — 2026-05-07|
| [BI_DB_dbo.BI_DB_CreditRiskMatrix](Tables/BI_DB_CreditRiskMatrix.md) | Deployed (Batch 5) — 2026-05-07|
| [BI_DB_dbo.BI_DB_Cross_Selling_Monthly](Tables/BI_DB_Cross_Selling_Monthly.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_Crypto_NOP](Tables/BI_DB_Crypto_NOP.md)                                                                     | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_Crypto_NOP_CID](Tables/BI_DB_Crypto_NOP_CID.md)                                                             | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_Daily_CreditLine](Tables/BI_DB_Daily_CreditLine.md)                                                         | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_Daily_Dividends](Tables/BI_DB_Daily_Dividends.md)                                                           | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_DailyCommisionReport](Tables/BI_DB_DailyCommisionReport.md) | Deployed (Batch 11) — 2026-05-07|
| [BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg](Tables/BI_DB_DailyCommisionReport_Instrument_Agg.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_DailyCopyRevenue](Tables/BI_DB_DailyCopyRevenue.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_DailyDividendsByPosition](Tables/BI_DB_DailyDividendsByPosition.md)                                         | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_DailyPanel_Copy](Tables/BI_DB_DailyPanel_Copy.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW](Tables/BI_DB_DailyZero_TreeSize_NEW.md)                                             | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks](Tables/BI_DB_DailyZeroPnL_Stocks.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_DCM_Dashboard](Tables/BI_DB_DCM_Dashboard.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_DDR_CID_Level](Tables/BI_DB_DDR_CID_Level.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status](Tables/BI_DB_DDR_Customer_Daily_Status.md)                                       | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status](Tables/BI_DB_DDR_Customer_Periodic_Status.md)                                 | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_DDR_Daily_Aggregated](Tables/BI_DB_DDR_Daily_Aggregated.md) | Deployed (Batch 13) — 2026-05-07|
| [BI_DB_dbo.BI_DB_DDR_Fact_AUM](Tables/BI_DB_DDR_Fact_AUM.md)                                                                 | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms](Tables/BI_DB_DDR_Fact_MIMO_AllPlatforms.md)                                     | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_DDR_Fact_PnL](Tables/BI_DB_DDR_Fact_PnL.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions](Tables/BI_DB_DDR_Fact_Revenue_Generating_Actions.md)                   | Deployed (re-apply 2026-04-12) — table was dropped+recreated; 56 stmts re-applied (1 TBLPROPERTIES + 1 SET TAGS + 27 COMMENT + 27 PII SET TAGS) |
| [BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts](Tables/BI_DB_DDR_Fact_Trading_Volumes_And_Amounts.md)                 | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_Demo_CID_Panel](Tables/BI_DB_Demo_CID_Panel.md) | Deployed (Batch 10) — 2026-05-05|
| [BI_DB_dbo.BI_DB_Deposit_Reversals_PIPs](Tables/BI_DB_Deposit_Reversals_PIPs.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints](Tables/BI_DB_DepositUsersFirstTouchPoints.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_DepositWithdrawFee](Tables/BI_DB_DepositWithdrawFee.md)                                                     | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals](Tables/BI_DB_DepositWithdrawFee_Reversals.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_Fact_Customer_Action_Position_Distribution](Tables/BI_DB_Fact_Customer_Action_Position_Distribution.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_Finance_Audit_Auxillary_Datapoints](Tables/BI_DB_Finance_Audit_Auxillary_Datapoints.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_Finance_eToro_vs_Positions](Tables/BI_DB_Finance_eToro_vs_Positions.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2025](Tables/BI_DB_Finance_Non_US_Settlement_New_2025.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_First5Actions](Tables/BI_DB_First5Actions.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_IFRS15_Daily_Balance](Tables/BI_DB_IFRS15_Daily_Balance.md) | Deployed (Batch 10) — 2026-05-05|
| [BI_DB_dbo.BI_DB_InterestDaily](Tables/BI_DB_InterestDaily.md)                                                               | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_InvestorsDetail](Tables/BI_DB_InvestorsDetail.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_KYC_Knowledge_Assessment](Tables/BI_DB_KYC_Knowledge_Assessment.md) | Deployed (Batch 10) — 2026-05-05|
| [BI_DB_dbo.BI_DB_KYC_Panel](Tables/BI_DB_KYC_Panel.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_LiveAcquisitionDashboard_Daily](Tables/BI_DB_LiveAcquisitionDashboard_Daily.md) | Deployed (Batch 10) — 2026-05-05|
| [BI_DB_dbo.BI_DB_LTV_BI_Actual](Tables/BI_DB_LTV_BI_Actual.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_MarketingCloudDaily](Tables/BI_DB_MarketingCloudDaily.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_MarketingDailyRawData](Tables/BI_DB_MarketingDailyRawData.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_Money_In_New_Management_Dashboard](Tables/BI_DB_Money_In_New_Management_Dashboard.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_Money_Out_New_Management_Dashboard](Tables/BI_DB_Money_Out_New_Management_Dashboard.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_Money_Out_STPAnalysis_OPS_Dashboard](Tables/BI_DB_Money_Out_STPAnalysis_OPS_Dashboard.md) | Deployed (Batch 10) — 2026-05-05|
| [BI_DB_dbo.BI_DB_MonthlyRiskScore](Tables/BI_DB_MonthlyRiskScore.md) | Deployed (Batch 5) — 2026-05-07|
| [BI_DB_dbo.BI_DB_NewBonusReport](Tables/BI_DB_NewBonusReport.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_Operations_Onboarding_Flow_UserKPIs](Tables/BI_DB_Operations_Onboarding_Flow_UserKPIs.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_OPS_Fraud_Alert_Analysis](Tables/BI_DB_OPS_Fraud_Alert_Analysis.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_OPS_KYC_Verification](Tables/BI_DB_OPS_KYC_Verification.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_OPS_VerificationPipeline_OverLevel2](Tables/BI_DB_OPS_VerificationPipeline_OverLevel2.md) | Deployed (Batch 10) — 2026-05-05|
| [BI_DB_dbo.BI_DB_PI_StatusPanel](Tables/BI_DB_PI_StatusPanel.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_PLTV](Tables/BI_DB_PLTV.md) | Deployed (Batch 10) — 2026-05-05|
| [BI_DB_dbo.BI_DB_PositionPnL](Tables/BI_DB_PositionPnL.md)                                                                   | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_PositionPnL_EU_Custody](Tables/BI_DB_PositionPnL_EU_Custody.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_PositionPnL_UK_Custody](Tables/BI_DB_PositionPnL_UK_Custody.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_PositionPnL_UK_Custody_Resolver](Tables/BI_DB_PositionPnL_UK_Custody_Resolver.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN](Tables/BI_DB_Positions_Closed_To_IBAN.md) | Deployed (Batch 10) — 2026-05-05|
| [BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN](Tables/BI_DB_Positions_Opened_From_IBAN.md) | Deployed (Batch 10) — 2026-05-05|
| [BI_DB_dbo.BI_DB_QMMF_Report](Tables/BI_DB_QMMF_Report.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_RollOverFee_Dividends](Tables/BI_DB_RollOverFee_Dividends.md)                                               | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market](Tables/BI_DB_Scored_Appropriateness_Negative_Market.md)             | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_Social_Activity](Tables/BI_DB_Social_Activity.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted](Tables/BI_DB_SpreadedPriceCandle60MinSplitted.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_Tax_Compliance_TIN](Tables/BI_DB_Tax_Compliance_TIN.md) | Deployed (Batch 10) — 2026-05-05|
| [BI_DB_dbo.BI_DB_Trading_Failures_Risk](Tables/BI_DB_Trading_Failures_Risk.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.BI_DB_Withdraw_Rollback_PIPs](Tables/BI_DB_Withdraw_Rollback_PIPs.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level](Tables/Client_Balance_Breakdown_Instrument_Level.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.Dim_Revenue_Metrics](Tables/Dim_Revenue_Metrics.md) | Deployed (Batch 13) — 2026-05-07|
| [BI_DB_dbo.DWH_CIDs7DaysDeviation](Tables/DWH_CIDs7DaysDeviation.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.DWH_CIDsDailyRisk](Tables/DWH_CIDsDailyRisk.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.DWH_GainDaily](Tables/DWH_GainDaily.md) | Deployed (Batch 9) — 2026-05-03|
| [BI_DB_dbo.External_Cmrdb_FxRate](Tables/External_Cmrdb_FxRate.md) | Deployed (Batch 13) — 2026-05-07|

## Views (2)

| Object | Deploy status |
| ------ | ------------- |
| [BI_DB_dbo.V_BI_DB_AllDeposits](Views/V_BI_DB_AllDeposits.md) | Deployed (Batch 13) — 2026-05-07|
| [BI_DB_dbo.V_BI_DB_BO_Generated_Compensations](Views/V_BI_DB_BO_Generated_Compensations.md) | Deployed (Batch 5) — 2026-05-07|
| [BI_DB_dbo.V_BI_DB_KYC_Score_CID_Level](Views/V_BI_DB_KYC_Score_CID_Level.md) | Deployed (Batch 13) — 2026-05-07|

## Functions (47)

| Object                                                                                                                       | Deploy status                                                                                                                                      |
| ---------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| [BI_DB_dbo.DateToDateID](Functions/DateToDateID.md)                                                                          | Stub only |
| [BI_DB_dbo.Function_AUM_OptionsPlatform](Functions/Function_AUM_OptionsPlatform.md)                                          | Stub only |
| [BI_DB_dbo.Function_DDR_Aggregation_MoM](Functions/Function_DDR_Aggregation_MoM.md)                                          | Stub only |
| [BI_DB_dbo.Function_DDR_Aggregation_ThisMonth](Functions/Function_DDR_Aggregation_ThisMonth.md)                              | Stub only |
| [BI_DB_dbo.Function_DDR_Aggregation_ThisQuarter](Functions/Function_DDR_Aggregation_ThisQuarter.md)                          | Stub only |
| [BI_DB_dbo.Function_DDR_Aggregation_ThisWeek](Functions/Function_DDR_Aggregation_ThisWeek.md)                                | Stub only |
| [BI_DB_dbo.Function_DDR_Aggregation_ThisYear](Functions/Function_DDR_Aggregation_ThisYear.md)                                | Stub only |
| [BI_DB_dbo.Function_DDR_Aggregation_Yesterday](Functions/Function_DDR_Aggregation_Yesterday.md)                              | Stub only |
| [BI_DB_dbo.Function_DDR_Aggregation_YoY](Functions/Function_DDR_Aggregation_YoY.md)                                          | Stub only |
| [BI_DB_dbo.Function_Instrument_Conversion_Rates](Functions/Function_Instrument_Conversion_Rates.md)                          | Stub only |
| [BI_DB_dbo.Function_Instrument_Snapshot_Enriched](Functions/Function_Instrument_Snapshot_Enriched.md)                        | Stub only |
| [BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms](Functions/Function_MIMO_First_Deposit_All_Platforms.md)                | Stub only |
| [BI_DB_dbo.Function_MIMO_Options_Platform](Functions/Function_MIMO_Options_Platform.md)                                      | Stub only |
| [BI_DB_dbo.Function_PnL_Single_Day](Functions/Function_PnL_Single_Day.md) | Failed (deploy Batch 9) — no executable ALTER|
| [BI_DB_dbo.Function_Population_Active_Traders](Functions/Function_Population_Active_Traders.md)                              | Stub only |
| [BI_DB_dbo.Function_Population_Balance_Only_Accounts](Functions/Function_Population_Balance_Only_Accounts.md)                | Stub only |
| [BI_DB_dbo.Function_Population_First_Time_Funded](Functions/Function_Population_First_Time_Funded.md)                        | Stub only |
| [BI_DB_dbo.Function_Population_First_Trading_Action](Functions/Function_Population_First_Trading_Action.md)                  | Stub only |
| [BI_DB_dbo.Function_Population_Funded](Functions/Function_Population_Funded.md) | Failed (deploy Batch 9) — no executable ALTER|
| [BI_DB_dbo.Function_Population_OTD_DateRange](Functions/Function_Population_OTD_DateRange.md)                                | Stub only |
| [BI_DB_dbo.Function_Population_Portfolio_Only](Functions/Function_Population_Portfolio_Only.md)                              | Stub only |
| [BI_DB_dbo.Function_Revenue_AdminFee](Functions/Function_Revenue_AdminFee.md)                                                | Stub only |
| [BI_DB_dbo.Function_Revenue_CashoutFee_ExcludeRedeem](Functions/Function_Revenue_CashoutFee_ExcludeRedeem.md)                | Stub only |
| [BI_DB_dbo.Function_Revenue_CashoutFee_IncRedeem](Functions/Function_Revenue_CashoutFee_IncRedeem.md)                        | Stub only |
| [BI_DB_dbo.Function_Revenue_Commissions](Functions/Function_Revenue_Commissions.md)                                          | Stub only |
| [BI_DB_dbo.Function_Revenue_ConversionFee](Functions/Function_Revenue_ConversionFee.md)                                      | Stub only |
| [BI_DB_dbo.Function_Revenue_ConversionFee_WithPositionData](Functions/Function_Revenue_ConversionFee_WithPositionData.md)    | Stub only |
| [BI_DB_dbo.Function_Revenue_CryptoToFiat_C2F](Functions/Function_Revenue_CryptoToFiat_C2F.md)                                | Stub only |
| [BI_DB_dbo.Function_Revenue_Dividend](Functions/Function_Revenue_Dividend.md)                                                | Stub only |
| [BI_DB_dbo.Function_Revenue_DormantFee](Functions/Function_Revenue_DormantFee.md)                                            | Stub only |
| [BI_DB_dbo.Function_Revenue_FullCommissions](Functions/Function_Revenue_FullCommissions.md)                                  | Stub only |
| [BI_DB_dbo.Function_Revenue_InterestFee](Functions/Function_Revenue_InterestFee.md)                                          | Stub only |
| [BI_DB_dbo.Function_Revenue_OptionsPlatform](Functions/Function_Revenue_OptionsPlatform.md)                                  | Stub only |
| [BI_DB_dbo.Function_Revenue_RolloverFee](Functions/Function_Revenue_RolloverFee.md)                                          | Stub only |
| [BI_DB_dbo.Function_Revenue_SDRT](Functions/Function_Revenue_SDRT.md)                                                        | Stub only |
| [BI_DB_dbo.Function_Revenue_Share_Lending](Functions/Function_Revenue_Share_Lending.md)                                      | Stub only |
| [BI_DB_dbo.Function_Revenue_SpotAdjustFee](Functions/Function_Revenue_SpotAdjustFee.md)                                      | Stub only |
| [BI_DB_dbo.Function_Revenue_StakingFee](Functions/Function_Revenue_StakingFee.md)                                            | Stub only |
| [BI_DB_dbo.Function_Revenue_TicketFee](Functions/Function_Revenue_TicketFee.md)                                              | Stub only |
| [BI_DB_dbo.Function_Revenue_TicketFeeByPercent](Functions/Function_Revenue_TicketFeeByPercent.md)                            | Stub only |
| [BI_DB_dbo.Function_Revenue_Total](Functions/Function_Revenue_Total.md)                                                      | Stub only |
| [BI_DB_dbo.Function_Revenue_Trading_Fees_Breakdown](Functions/Function_Revenue_Trading_Fees_Breakdown.md)                    | Stub only |
| [BI_DB_dbo.Function_Revenue_Trading_Instrument_Level](Functions/Function_Revenue_Trading_Instrument_Level.md)                | Stub only |
| [BI_DB_dbo.Function_Revenue_TransferCoinFee](Functions/Function_Revenue_TransferCoinFee.md)                                  | Stub only |
| [BI_DB_dbo.Function_Search_Functions](Functions/Function_Search_Functions.md)                                                | Stub only |
| [BI_DB_dbo.Function_Trading_Volume](Functions/Function_Trading_Volume.md)                                                    | Stub only |
| [BI_DB_dbo.Function_Trading_Volume_PositionLevel](Functions/Function_Trading_Volume_PositionLevel.md)                        | Stub only |