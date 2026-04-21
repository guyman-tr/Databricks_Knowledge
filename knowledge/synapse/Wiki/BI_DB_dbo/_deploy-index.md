---

## schema: BI_DB_dbo
database: Synapse DWH
total_deployable: 71
generated: 0
deployed: 24
failed: 0
stub_only: 47
last_generate_batch: 0
last_deploy_batch: 1
last_updated: "2026-04-12"

## Schema ALTER + Deployment Progress

| Metric                             | Value      |
| ---------------------------------- | ---------- |
| **Schema**                         | BI_DB_dbo  |
| **Total deployable**               | 71  |
| **Pending (no .alter.sql)**        | 0          |
| **Generated (awaiting UC deploy)** | 0        |
| **Deployed (UC)**                  | 24         |
| **Stub-only (no UC)**              | 47   |
| **Failed**                         | 0         |
| **Stale**                          | 0          |
| **Last generate batch**            | 0          |
| **Last deploy batch**              | 1          |
| **Last updated**                   | 2026-04-12       |

> **Rows**: `Pending` = no local `.alter.sql`. `Generated` = `.alter.sql` present with executable ALTER, UC not deployed in this index pass. `Deployed` = UC ALTERs executed. `Stub only` = comment-only `.alter.sql` (no UC target).

## Tables (24)

| Object                                                                                                                       | Deploy status                                                                                                                                      |
| ---------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| [BI_DB_dbo.BI_DB_CB_CycleGap_Categorization](Tables/BI_DB_CB_CycleGap_Categorization.md)                                     | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_CID_Daily_NWA](Tables/BI_DB_CID_Daily_NWA.md)                                                               | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_CIDFirstDates](Tables/BI_DB_CIDFirstDates.md)                                                               | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_CIDLevel_Settlement_Report](Tables/BI_DB_CIDLevel_Settlement_Report.md)                                     | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New](Tables/BI_DB_Client_Balance_Aggregate_Level_New.md)                     | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New](Tables/BI_DB_Client_Balance_CID_Level_New.md)                                 | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_Client_New_CompensationBreakdown](Tables/BI_DB_Client_New_CompensationBreakdown.md)                         | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_Crypto_NOP](Tables/BI_DB_Crypto_NOP.md)                                                                     | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_Crypto_NOP_CID](Tables/BI_DB_Crypto_NOP_CID.md)                                                             | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_Daily_CreditLine](Tables/BI_DB_Daily_CreditLine.md)                                                         | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_Daily_Dividends](Tables/BI_DB_Daily_Dividends.md)                                                           | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_DailyDividendsByPosition](Tables/BI_DB_DailyDividendsByPosition.md)                                         | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW](Tables/BI_DB_DailyZero_TreeSize_NEW.md)                                             | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status](Tables/BI_DB_DDR_Customer_Daily_Status.md)                                       | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status](Tables/BI_DB_DDR_Customer_Periodic_Status.md)                                 | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_DDR_Fact_AUM](Tables/BI_DB_DDR_Fact_AUM.md)                                                                 | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms](Tables/BI_DB_DDR_Fact_MIMO_AllPlatforms.md)                                     | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions](Tables/BI_DB_DDR_Fact_Revenue_Generating_Actions.md)                   | Deployed (re-apply 2026-04-12) — table was dropped+recreated; 56 stmts re-applied (1 TBLPROPERTIES + 1 SET TAGS + 27 COMMENT + 27 PII SET TAGS) |
| [BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts](Tables/BI_DB_DDR_Fact_Trading_Volumes_And_Amounts.md)                 | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_DepositWithdrawFee](Tables/BI_DB_DepositWithdrawFee.md)                                                     | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_InterestDaily](Tables/BI_DB_InterestDaily.md)                                                               | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_PositionPnL](Tables/BI_DB_PositionPnL.md)                                                                   | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_RollOverFee_Dividends](Tables/BI_DB_RollOverFee_Dividends.md)                                               | Deployed (Batch 1) — 2026-03-30|
| [BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market](Tables/BI_DB_Scored_Appropriateness_Negative_Market.md)             | Deployed (Batch 1) — 2026-03-30|

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
| [BI_DB_dbo.Function_PnL_Single_Day](Functions/Function_PnL_Single_Day.md)                                                    | Stub only |
| [BI_DB_dbo.Function_Population_Active_Traders](Functions/Function_Population_Active_Traders.md)                              | Stub only |
| [BI_DB_dbo.Function_Population_Balance_Only_Accounts](Functions/Function_Population_Balance_Only_Accounts.md)                | Stub only |
| [BI_DB_dbo.Function_Population_First_Time_Funded](Functions/Function_Population_First_Time_Funded.md)                        | Stub only |
| [BI_DB_dbo.Function_Population_First_Trading_Action](Functions/Function_Population_First_Trading_Action.md)                  | Stub only |
| [BI_DB_dbo.Function_Population_Funded](Functions/Function_Population_Funded.md)                                              | Stub only |
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
