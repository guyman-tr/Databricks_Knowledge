# Dealing_dbo ALTER Generation Report

**Generated**: 2026-03-22
**Engine**: `_batch_generate_lib.py` v1.0
**UC Bulk Query**: `system.information_schema.tables WHERE table_name LIKE 'gold_sql_dp_prod_we_dealing_dbo_%'`

## Summary

| Metric | Count |
|--------|-------|
| Total wiki objects scanned | 219 |
| ALTER scripts generated | **29** |
| Resolved this run | 25 |
| Already had UC targets | 4 |
| No UC table exists | 189 |
| Parse failures | 1 |
| Views (skipped) | 0 |
| PII Masked tables | 0 |

## UC Schema Distribution

Unlike DWH_dbo (which maps exclusively to `main.dwh`), Dealing_dbo tables are distributed across **5 UC schemas**:

| UC Schema | Count | Tables |
|-----------|-------|--------|
| `main.dealing` | 16 | Core dealing tables (reconciliation, risk, hedging) |
| `main.bi_db` | 5 | Dashboard/reporting tables |
| `main.general` | 4 | Intra-hour monitoring tables |
| `main.finance` | 3 | Staking finance tables |
| `main.trading` | 1 | Employees report |

## Generated ALTER Scripts (29)

### Standard (in `main.dealing`) — 16

1. Dealing_ApexRecon_Holdings (21 cols)
2. Dealing_ApexRecon_TradeActivity (15 cols)
3. Dealing_BNY_VIRTU_ReconEODHolding (28 cols)
4. Dealing_Boundary_Cost (35 cols)
5. Dealing_Clicks_OpenClose_Breakdown (45 cols)
6. Dealing_Duco_ActivityRecon (25 cols)
7. Dealing_ESMANetLoss (20 cols)
8. Dealing_Islamic_Daily_Administrative_Fee (30 cols)
9. Dealing_Islamic_Daily_Spot_Price_Adjustment (30 cols)
10. Dealing_ManipulationReport_RealStocks (16 cols)
11. Dealing_ManipulationReport_RealStocks_CID (20 cols)
12. Dealing_Marex_Recon_EODHoldings_Futures (38 cols)
13. Dealing_RiskMatrix_V2 (17 cols)
14. Dealing_SAXORecon_EODHoldings (33 cols)
15. Dealing_Staking_Summary (31 cols)
16. V_Dealing_Duco_EODRecon — **parse failure** (no column section)

### Non-standard UC schema — 13

| Object | UC Target | Schema | Cols |
|--------|-----------|--------|------|
| Dealing_DealingDashboard_Clients | `main.bi_db` | bi_db | 45 |
| Dealing_Duco_EODRecon | `main.bi_db` | bi_db | 26 |
| Dealing_NOP_Report | `main.bi_db` | bi_db | 14 |
| Dealing_NumberofPositionsOpened_Agg | `main.bi_db` | bi_db | 6 |
| Dealing_Staking_Results | `main.bi_db` | bi_db | 24 |
| Dealing_CommoditiesIntraHour_Clients | `main.general` | general | 16 |
| Dealing_CommoditiesIntraHour_Etoro | `main.general` | general | 14 |
| Dealing_IndiciesIntraHour_Clients | `main.general` | general | 17 |
| Dealing_IndiciesIntraHour_Etoro | `main.general` | general | 15 |
| Dealing_Staking_DailyPool | `main.finance` | finance | 6 |
| Dealing_Staking_OptedOut | `main.finance` | finance | 18 |
| Dealing_Staking_Parameters | `main.finance` | finance | 8 |
| Dealing_Employees_Report | `main.trading` | trading | 69 |

## Parse Failures (1)

| Object | Issue |
|--------|-------|
| V_Dealing_Duco_EODRecon | View wiki uses `Key Column Enhancement` section — no standard column table |

## No UC Table Exists (189)

These Dealing_dbo objects have wiki documentation but no corresponding UC table in Unity Catalog. They are either:
- Synapse-only tables not exported via the Generic Pipeline
- Historical/deprecated tables
- Tables with non-standard naming that the pipeline doesn't pick up

<details>
<summary>Full list (189 objects)</summary>

DSC_HedgeOnIndices, DSC_HedgeOnIndices_H, Daily_Slippage_Positions_HOLD, Dealing_015Min_AllTrades, Dealing_AbuseAPI, Dealing_AbusersCIDs, Dealing_ApexRecon_Hedging, Dealing_Apex_PnL, Dealing_Apex_PnL_Daily, Dealing_Apex_PnL_EE, Dealing_Apex_PnL_EE_Daily, Dealing_BNY_Citadel_ReconTrades, Dealing_BNY_Detailed, Dealing_BNY_VIRTU_ReconTrades, Dealing_Best_Execution_Compensation_CBH, Dealing_Best_Execution_Compensation_CBH_HOLD, Dealing_Best_Execution_Compensation_HBC, Dealing_Best_Execution_Compensation_HBC_HOLD, Dealing_Boundary_Cost_H_Indices, Dealing_CEPDailyAudit_CP, Dealing_CEPDailyAudit_CPToRule, Dealing_CEPDailyAudit_ConditionToCP, Dealing_CEPDailyAudit_Conditions, Dealing_CEPDailyAudit_ListCIDMapping, Dealing_CEPDailyAudit_NameLists, Dealing_CEPDailyAudit_Rules, Dealing_CEPWeeklyAudit_CP, Dealing_CEPWeeklyAudit_CPToRule, Dealing_CEPWeeklyAudit_ConditionToCP, Dealing_CEPWeeklyAudit_Conditions, Dealing_CEPWeeklyAudit_ListCIDMapping, Dealing_CEPWeeklyAudit_NameLists, Dealing_CEPWeeklyAudit_Rules, Dealing_CEP_ExecutionMonitoring, Dealing_CFDs_Stocks_Credit_Risk, Dealing_CIDs_CommissionsAndFails, Dealing_CIDs_CommissionsAndFails_PIs, Dealing_CME_Reporting, Dealing_CapitalGuarantee, Dealing_ClientCountry, Dealing_ClientCountry_Reg, Dealing_ClientDataFinal, Dealing_ClientDataRecurring, Dealing_ClientDataTop50, Dealing_ClientsCapitalAdequacy, Dealing_ClientsDataChange_3Months, Dealing_ClientsDataChange_6Months, Dealing_CloseOnly_Recon, Dealing_Commission_Assurance, Dealing_Commission_Assurance_By_Position, Dealing_CopierAnalysis, Dealing_CopyPortfolio_Allocation, Dealing_CryptoVolume, Dealing_CryptoVolume_ByDirection, Dealing_DailyAvgSpread, Dealing_DailySpread_ModeFrequency, Dealing_DailySpreadsAggregated, Dealing_DailySpreadsAggregatedFX, Dealing_DailyVariableSpread, Dealing_DailyZeroPnL_Stocks, Dealing_Daily_Latency, Dealing_Daily_Latency_AllPositions, Dealing_Daily_Latency_AllPositions_StatusUpdateTime, Dealing_Daily_Latency_ClientOrder_WithDelay, Dealing_Daily_Latency_ClientOrder_WithDelay_StatusUpdateTime, Dealing_Daily_Latency_Compensation, Dealing_Daily_Latency_Compensation_StatusUpdateTime, Dealing_Daily_Latency_StatusUpdateTime, Dealing_Daily_Slippage_Positions, Dealing_Daily_Slippage_Positions_TriggerVSReceived, Dealing_Daily_Slippage_Totals, Dealing_Daily_Slippage_Totals_TriggerVSReceived, Dealing_Employee_Zero_StocksETFs, Dealing_EquityFees, Dealing_Execution_Slippage, Dealing_Execution_Slippage_AssetType, Dealing_Execution_Slippage_AssetType_RequestTime, Dealing_Execution_Slippage_RequestTime, Dealing_Extented_Hours_NewCID, Dealing_Extented_Hours_Volume, Dealing_FactSet_Daily, Dealing_FactSet_Management, Dealing_FactSet_Management_Export, Dealing_FactSet_NewPIs_History, Dealing_FailReasons, Dealing_FailReasons_PIs, Dealing_Fails_PI, Dealing_Fails_PI_ErrorCodes, Dealing_Failures, Dealing_Failures_Rate, Dealing_GSReconEODHolding, Dealing_GSReconTrades, Dealing_HedgeCost, Dealing_Holdings_RealStocks, Dealing_IBRecon_EODHoldings, Dealing_IBRecon_EODHoldings_CFD, Dealing_IBRecon_Trades, Dealing_IBRecon_Trades_CFD, Dealing_IGReconEODHolding, Dealing_IGReconTrades, Dealing_Islamic_Admin_Fee_Per_Group, Dealing_Islamic_Instruments_Groups, Dealing_Islamic_Units_Per_Contract, Dealing_JPMReconEODHolding, Dealing_JPMReconTrades, Dealing_LP_StocksNOP, Dealing_Latency_SuspiciousCIDs, Dealing_MAXLeverageByNOP, Dealing_MCS_Model_Report, Dealing_ManualPositionClose, Dealing_Manual_Exec, Dealing_Manual_Exec_Trade, Dealing_Manual_Exec_Trade_Summary, Dealing_Marex_Recon_EODHoldings, Dealing_Marex_Recon_Trades, Dealing_Marex_Recon_Trades_Futures, Dealing_MarketMakerAllTrade, Dealing_MarketMakerAllTradeEtoroX, Dealing_MarketMakerBoundaries_CFD, Dealing_MarketMakerBoundaries_Real, Dealing_Market_Manipulation_OutstandingsharesHigherthan005, Dealing_Market_Manipulation_Report, Dealing_Market_Manipulation_Report_FCA, Dealing_MaxNOPLimitSettings, Dealing_MaxPositionUnits, Dealing_Monitoring_ADV, Dealing_Monitoring_ADV_MoreThanPercent, Dealing_NOP_LPandClients, Dealing_OccurredAtProvider_Latency_Instrument, Dealing_OccurredAtProvider_Latency_LiquidityAccountID, Dealing_OccurredAtProvider_Latency_PCSID, Dealing_PDT, Dealing_PlayerLevel_Data, Dealing_PlayerLevel_Data_PIs, Dealing_PlayerLevel_Fails, Dealing_PlayerLevel_Fails_PIs, Dealing_PreviouslyIdentifiedAbusers, Dealing_PriceLocks, Dealing_Regime_Flags, Dealing_SAXORecon_Hedging, Dealing_SAXORecon_Trades, Dealing_SaxoRecon_FXnCommed_EODHoldings, Dealing_SaxoRecon_FXnCommed_Trades, Dealing_SelfCopyingPI, Dealing_SpreadsMST, Dealing_Staking_Club, Dealing_Staking_Club_US, Dealing_Staking_Compensation, Dealing_Staking_Compensation_US, Dealing_Staking_DailyPool_US, Dealing_Staking_Emails, Dealing_Staking_Emails_New, Dealing_Staking_Emails_US, Dealing_Staking_OptedOut_PerCID, Dealing_Staking_OptedOut_PerCID_US, Dealing_Staking_OptedOut_US, Dealing_Staking_Parameters_US, Dealing_Staking_Position, Dealing_Staking_Position_US, Dealing_Staking_Results_US, Dealing_Staking_Summary_US, Dealing_Staking_WelcomeEmail_Temp, Dealing_Supposed_LPFees, Dealing_SuspiciousActivityTrading_24H, Dealing_US_DailyTradeBlotter, Dealing_US_DailyTradeBlotter_DailyCSV, Dealing_US_OriginalEntryTradeTicket, Dealing_US_Stocks_SmartPortfolio, Dealing_Unrealized_Open_CryptoRebate, Dealing_VisionRecon_EODHoldings, Dealing_VisionRecon_Trades, Dealing_WeeklyCMT_Fees, Dealing_dbo.Dealing_GS_Credit_Risk, Dealing_dbo.Dealing_JP_Credit_Risk, Dealing_dbo.Dealing_MIMO_Zero, Dealing_dbo.Dealing_Max_NOP, Dealing_dbo.Dealing_NOPDistribution, Dealing_dbo.Dealing_OfferedInstruments, Dealing_dbo.Dealing_RolloverCommissionSplit, Dealing_etoro_history_interestrate, Dealing_overnight_fees, External_Fivetran_dealing_overnight_fees, External_Gold_Dealing_Marex_Trader_OrderID, StocksOverrideRateLog, V_Dealing_CEPDailyAudit_CP_Last180Days, V_Dealing_CEPDailyAudit_Conditions_Last180Days, V_Dealing_CEPDailyAudit_Rules_Last180Days, V_Dealing_DealingDashboard_Clients, V_RequestViewForBestExecution

</details>

## Parser Fixes Applied

The batch lib parser was enhanced during this run to handle Dealing_dbo wiki format variations:

1. **Flexible section numbering**: Matches columns in `## 4. Elements`, `## 5. Elements`, or even `## Elements` (no number)
2. **Multiple section names**: `Column Details`, `Elements`, `Column Descriptions`, `Key Columns & Elements`, `Key Column Enhancement`
3. **Dynamic column detection**: Auto-detects header row to find the column-name and description positions
4. **3-column format**: Handles `| Column | Type | Description |` (Dealing_dbo) alongside `| # | Element | Type | Nullable | Description |` (DWH_dbo)
5. **Schema prefix stripping**: Handles files named `Dealing_dbo.Dealing_X.md` by stripping the schema prefix for lookup
