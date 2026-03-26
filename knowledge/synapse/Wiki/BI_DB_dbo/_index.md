---
schema: BI_DB_dbo
database: Synapse DWH
total_objects: 1204
documented: 44
failed: 0
last_batch: 9
last_updated: "2026-03-26"
quality_avg: 8.8
---

## Schema Documentation Progress

| Metric | Value |
|--------|-------|
| **Schema** | BI_DB_dbo |
| **Total Objects** | ~1204 (1160 tables, 44 views -- full inventory not yet enumerated) |
| **Documented** | 44 |
| **Failed** | 0 |
| **Last Updated** | 2026-03-26 |
| **Quality Avg** | 8.8 |

---

## Batch 9 (COMPLETE) -- DDR redo with improved harness: 5 objects (PnL, MIMO AllPlatforms/eMoney, Revenue, Trading Volumes)

Planned: 2026-03-26 | Completed: 2026-03-26 | Note: Redo of Batch 7 items 4-8 with improved documentation pipeline

| # | Object | Type | Priority | Quality | Status |
|---|--------|------|----------|---------|--------|
| 1 | [BI_DB_dbo.BI_DB_DDR_Fact_PnL](Tables/BI_DB_DDR_Fact_PnL.md) | Table | 60 | 8.5 | Done |
| 2 | [BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms](Tables/BI_DB_DDR_Fact_MIMO_AllPlatforms.md) | Table | 60 | 8.5 | Done |
| 3 | [BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform](Tables/BI_DB_DDR_Fact_MIMO_eMoney_Platform.md) | Table | 60 | 8.5 | Done |
| 4 | [BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions](Tables/BI_DB_DDR_Fact_Revenue_Generating_Actions.md) | Table | 60 | 8.5 | Done |
| 5 | [BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts](Tables/BI_DB_DDR_Fact_Trading_Volumes_And_Amounts.md) | Table | 60 | 8.5 | Done |

## Batch 8 (COMPLETE) -- DDR remaining tables: 6 objects (AUM, MIMO Options/TP, Non-Revenue, Customer Daily/Periodic)

Planned: 2026-03-26 | Completed: 2026-03-26

| # | Object | Type | Priority | Quality | Status |
|---|--------|------|----------|---------|--------|
| 1 | [BI_DB_dbo.BI_DB_DDR_Fact_AUM](Tables/BI_DB_DDR_Fact_AUM.md) | Table | 60 | 8.5 | Done |
| 2 | [BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform](Tables/BI_DB_DDR_Fact_MIMO_Options_Platform.md) | Table | 0 | 8.0 | Done |
| 3 | [BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform](Tables/BI_DB_DDR_Fact_MIMO_Trading_Platform.md) | Table | 60 | 8.5 | Done |
| 4 | [BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions](Tables/BI_DB_DDR_Fact_Non_Revenue_Generating_Actions.md) | Table | 60 | 8.5 | Done |
| 5 | [BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status](Tables/BI_DB_DDR_Customer_Daily_Status.md) | Table | 99 | 8.5 | Done |
| 6 | [BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status](Tables/BI_DB_DDR_Customer_Periodic_Status.md) | Table | 100 | 8.0 | Done |

## Batch 7 (COMPLETE) -- Priority 60-90 targets: 8 objects (P90/P80/P70/P60 mix)

Planned: 2026-03-22 | Completed: 2026-03-22

| # | Object | Type | Priority | Quality | Status |
|---|--------|------|----------|---------|--------|
| 1 | [BI_DB_dbo.BI_DB_Futures_Finance_Prep_Data](Tables/BI_DB_Futures_Finance_Prep_Data.md) | Table | 90 | 8.5 | Done |
| 2 | [BI_DB_dbo.BI_DB_InterestDaily](Tables/BI_DB_InterestDaily.md) | Table | 80 | 8.0 | Done |
| 3 | [BI_DB_dbo.BI_DB_UsageTracking_SF](Tables/BI_DB_UsageTracking_SF.md) | Table | 70 | 7.5 | Done |
| 4 | BI_DB_dbo.BI_DB_DDR_Fact_PnL | Table | 60 | ~~8.0~~ | Superseded by Batch 9 |
| 5 | BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | Table | 60 | ~~8.0~~ | Superseded by Batch 9 |
| 6 | BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform | Table | 60 | ~~8.0~~ | Superseded by Batch 9 |
| 7 | BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions | Table | 60 | ~~8.0~~ | Superseded by Batch 9 |
| 8 | BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts | Table | 60 | ~~8.0~~ | Superseded by Batch 9 |

## Batch 6 (COMPLETE) -- Priority 99 targets: 1 object (173-column monster, dedicated batch)

Planned: 2026-03-20 | Completed: 2026-03-20

| # | Object | Type | Priority | Quality | Status |
|---|--------|------|----------|---------|--------|
| 1 | [BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New](Tables/BI_DB_Client_Balance_Aggregate_Level_New.md) | Table | 99 | 9.0 | Done |

## Batch 5 (COMPLETE) -- Priority 99 targets: 14 objects (large P99 batch, parallelized)

Planned: 2026-03-20 | Completed: 2026-03-20

| # | Object | Type | Priority | Quality | Status |
|---|--------|------|----------|---------|--------|
| 1 | [BI_DB_dbo.BI_DB_Crypto_NOP](Tables/BI_DB_Crypto_NOP.md) | Table | 99 | 9.0 | Done |
| 2 | [BI_DB_dbo.BI_DB_Crypto_NOP_CID](Tables/BI_DB_Crypto_NOP_CID.md) | Table | 99 | 9.0 | Done |
| 3 | [BI_DB_dbo.BI_DB_CycleGap](Tables/BI_DB_CycleGap.md) | Table | 99 | 9.0 | Done |
| 4 | [BI_DB_dbo.BI_DB_DailyDividendsByPosition](Tables/BI_DB_DailyDividendsByPosition.md) | Table | 99 | 9.0 | Done |
| 5 | [BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW](Tables/BI_DB_DailyZero_TreeSize_NEW.md) | Table | 99 | 9.0 | Done |
| 6 | [BI_DB_dbo.BI_DB_DepositWithdrawFee](Tables/BI_DB_DepositWithdrawFee.md) | Table | 99 | 9.0 | Done |
| 7 | [BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_Report](Tables/BI_DB_Finance_Non_US_Settlement_Report.md) | Table | 99 | 9.0 | Done |
| 8 | [BI_DB_dbo.BI_DB_Finance_Panel_Reports](Tables/BI_DB_Finance_Panel_Reports.md) | Table | 99 | 9.0 | Done |
| 9 | [BI_DB_dbo.BI_DB_GAML_Real_Positions_Report_Closed](Tables/BI_DB_GAML_Real_Positions_Report_Closed.md) | Table | 99 | 9.0 | Done |
| 10 | [BI_DB_dbo.BI_DB_GAML_Real_Positions_Report_Opened_2022](Tables/BI_DB_GAML_Real_Positions_Report_Opened_2022.md) | Table | 99 | 9.0 | Done |
| 11 | [BI_DB_dbo.BI_DB_Outliers_New](Tables/BI_DB_Outliers_New.md) | Table | 99 | 9.0 | Done |
| 12 | [BI_DB_dbo.BI_DB_PositionPnL](Tables/BI_DB_PositionPnL.md) | Table | 99 | 9.0 | Done |
| 13 | [BI_DB_dbo.BI_DB_RealCrypto_Lev2](Tables/BI_DB_RealCrypto_Lev2.md) | Table | 99 | 9.0 | Done |
| 14 | [BI_DB_dbo.BI_DB_RollOverFee_Dividends](Tables/BI_DB_RollOverFee_Dividends.md) | Table | 99 | 9.0 | Done |

## Batch 4 (COMPLETE) -- Priority 99 targets: 8 objects (small P99 batch)

Planned: 2026-03-20 | Completed: 2026-03-20

| # | Object | Type | Priority | Quality | Status |
|---|--------|------|----------|---------|--------|
| 1 | [BI_DB_dbo.BI_DB_Crypto_Net_Units_During_Month](Tables/BI_DB_Crypto_Net_Units_During_Month.md) | Table | 99 | 9.0 | Done |
| 2 | [BI_DB_dbo.BI_DB_Crypto_Net_Units_End_Of_Month](Tables/BI_DB_Crypto_Net_Units_End_Of_Month.md) | Table | 99 | 9.0 | Done |
| 3 | [BI_DB_dbo.BI_DB_Crypto_Zero](Tables/BI_DB_Crypto_Zero.md) | Table | 99 | 9.0 | Done |
| 4 | [BI_DB_dbo.BI_DB_Daily_CB_Gaps_All](Tables/BI_DB_Daily_CB_Gaps_All.md) | Table | 99 | 9.0 | Done |
| 5 | [BI_DB_dbo.BI_DB_Daily_CreditLine](Tables/BI_DB_Daily_CreditLine.md) | Table | 99 | 9.0 | Done |
| 6 | [BI_DB_dbo.BI_DB_Daily_Dividends](Tables/BI_DB_Daily_Dividends.md) | Table | 99 | 9.0 | Done |
| 7 | [BI_DB_dbo.BI_DB_Real_Crypto_Loan](Tables/BI_DB_Real_Crypto_Loan.md) | Table | 99 | 9.0 | Done |
| 8 | [BI_DB_dbo.BI_DB_VarCommission](Tables/BI_DB_VarCommission.md) | Table | 99 | 9.0 | Done |

## Batch 3 (COMPLETE) -- Priority 99 targets: 5 objects (first schema-scope batch)

Planned: 2026-03-20 | Completed: 2026-03-20

| # | Object | Type | Priority | Quality | Status |
|---|--------|------|----------|---------|--------|
| 1 | [BI_DB_dbo.BI_DB_ASIC_ClientBalanceFinance](Tables/BI_DB_ASIC_ClientBalanceFinance.md) | Table | 99 | 9.0 | Done |
| 2 | [BI_DB_dbo.BI_DB_CB_CycleGap_Categorization](Tables/BI_DB_CB_CycleGap_Categorization.md) | Table | 99 | 9.0 | Done |
| 3 | [BI_DB_dbo.BI_DB_CID_Daily_NWA](Tables/BI_DB_CID_Daily_NWA.md) | Table | 99 | 9.5 | Done |
| 4 | [BI_DB_dbo.BI_DB_CIDLevel_Settlement_Report](Tables/BI_DB_CIDLevel_Settlement_Report.md) | Table | 99 | 9.0 | Done |
| 5 | [BI_DB_dbo.BI_DB_Client_New_CompensationBreakdown](Tables/BI_DB_Client_New_CompensationBreakdown.md) | Table | 99 | 9.0 | Done |

## Batch 2 (COMPLETE) — Single-object mode: 1 object (rerun — Alias-Level Attribution)

Planned: 2026-03-20 | Completed: 2026-03-20

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [BI_DB_dbo.BI_DB_CIDFirstDates](Tables/BI_DB_CIDFirstDates.md) | Table | 9.5 | Done |

## Batch 1 (COMPLETE) — Single-object mode: 1 object (rerun v2 — Formula Pre-Pass)

Planned: 2026-03-20 | Completed: 2026-03-20

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New](Tables/BI_DB_Client_Balance_CID_Level_New.md) | Table | 9.5 | Done |

---

## Tables (documented: 44)

| Object | Quality | Status |
|--------|---------|--------|
| [BI_DB_dbo.BI_DB_ASIC_ClientBalanceFinance](Tables/BI_DB_ASIC_ClientBalanceFinance.md) | 9.0 | Done (Batch 3 #1) |
| [BI_DB_dbo.BI_DB_CB_CycleGap_Categorization](Tables/BI_DB_CB_CycleGap_Categorization.md) | 9.0 | Done (Batch 3 #2) |
| [BI_DB_dbo.BI_DB_CID_Daily_NWA](Tables/BI_DB_CID_Daily_NWA.md) | 9.5 | Done (Batch 3 #3) |
| [BI_DB_dbo.BI_DB_CIDFirstDates](Tables/BI_DB_CIDFirstDates.md) | 9.5 | Done (Batch 2) |
| [BI_DB_dbo.BI_DB_CIDLevel_Settlement_Report](Tables/BI_DB_CIDLevel_Settlement_Report.md) | 9.0 | Done (Batch 3 #4) |
| [BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New](Tables/BI_DB_Client_Balance_Aggregate_Level_New.md) | 9.0 | Done (Batch 6 #1) |
| [BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New](Tables/BI_DB_Client_Balance_CID_Level_New.md) | 9.5 | Done (Batch 1) |
| [BI_DB_dbo.BI_DB_Client_New_CompensationBreakdown](Tables/BI_DB_Client_New_CompensationBreakdown.md) | 9.0 | Done (Batch 3 #5) |
| [BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status](Tables/BI_DB_DDR_Customer_Daily_Status.md) | 8.5 | Done (Batch 8 #5) |
| [BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status](Tables/BI_DB_DDR_Customer_Periodic_Status.md) | 8.0 | Done (Batch 8 #6) |
| [BI_DB_dbo.BI_DB_DDR_Fact_AUM](Tables/BI_DB_DDR_Fact_AUM.md) | 8.5 | Done (Batch 8 #1) |
| [BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms](Tables/BI_DB_DDR_Fact_MIMO_AllPlatforms.md) | 8.0 | Done (Batch 7 #5) |
| [BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform](Tables/BI_DB_DDR_Fact_MIMO_Options_Platform.md) | 8.0 | Done (Batch 8 #2) |
| [BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform](Tables/BI_DB_DDR_Fact_MIMO_Trading_Platform.md) | 8.5 | Done (Batch 8 #3) |
| [BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform](Tables/BI_DB_DDR_Fact_MIMO_eMoney_Platform.md) | 8.0 | Done (Batch 7 #6) |
| [BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions](Tables/BI_DB_DDR_Fact_Non_Revenue_Generating_Actions.md) | 8.5 | Done (Batch 8 #4) |
| [BI_DB_dbo.BI_DB_DDR_Fact_PnL](Tables/BI_DB_DDR_Fact_PnL.md) | 8.0 | Done (Batch 7 #4) |
| [BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions](Tables/BI_DB_DDR_Fact_Revenue_Generating_Actions.md) | 8.0 | Done (Batch 7 #7) |
| [BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts](Tables/BI_DB_DDR_Fact_Trading_Volumes_And_Amounts.md) | 8.0 | Done (Batch 7 #8) |
| [BI_DB_dbo.BI_DB_Crypto_Net_Units_During_Month](Tables/BI_DB_Crypto_Net_Units_During_Month.md) | 9.0 | Done (Batch 4 #1) |
| [BI_DB_dbo.BI_DB_Crypto_Net_Units_End_Of_Month](Tables/BI_DB_Crypto_Net_Units_End_Of_Month.md) | 9.0 | Done (Batch 4 #2) |
| [BI_DB_dbo.BI_DB_Crypto_NOP](Tables/BI_DB_Crypto_NOP.md) | 9.0 | Done (Batch 5 #1) |
| [BI_DB_dbo.BI_DB_Crypto_NOP_CID](Tables/BI_DB_Crypto_NOP_CID.md) | 9.0 | Done (Batch 5 #2) |
| [BI_DB_dbo.BI_DB_Crypto_Zero](Tables/BI_DB_Crypto_Zero.md) | 9.0 | Done (Batch 4 #3) |
| [BI_DB_dbo.BI_DB_CycleGap](Tables/BI_DB_CycleGap.md) | 9.0 | Done (Batch 5 #3) |
| [BI_DB_dbo.BI_DB_Daily_CB_Gaps_All](Tables/BI_DB_Daily_CB_Gaps_All.md) | 9.0 | Done (Batch 4 #4) |
| [BI_DB_dbo.BI_DB_Daily_CreditLine](Tables/BI_DB_Daily_CreditLine.md) | 9.0 | Done (Batch 4 #5) |
| [BI_DB_dbo.BI_DB_Daily_Dividends](Tables/BI_DB_Daily_Dividends.md) | 9.0 | Done (Batch 4 #6) |
| [BI_DB_dbo.BI_DB_DailyDividendsByPosition](Tables/BI_DB_DailyDividendsByPosition.md) | 9.0 | Done (Batch 5 #4) |
| [BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW](Tables/BI_DB_DailyZero_TreeSize_NEW.md) | 9.0 | Done (Batch 5 #5) |
| [BI_DB_dbo.BI_DB_DepositWithdrawFee](Tables/BI_DB_DepositWithdrawFee.md) | 9.0 | Done (Batch 5 #6) |
| [BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_Report](Tables/BI_DB_Finance_Non_US_Settlement_Report.md) | 9.0 | Done (Batch 5 #7) |
| [BI_DB_dbo.BI_DB_Finance_Panel_Reports](Tables/BI_DB_Finance_Panel_Reports.md) | 9.0 | Done (Batch 5 #8) |
| [BI_DB_dbo.BI_DB_Futures_Finance_Prep_Data](Tables/BI_DB_Futures_Finance_Prep_Data.md) | 8.5 | Done (Batch 7 #1) |
| [BI_DB_dbo.BI_DB_GAML_Real_Positions_Report_Closed](Tables/BI_DB_GAML_Real_Positions_Report_Closed.md) | 9.0 | Done (Batch 5 #9) |
| [BI_DB_dbo.BI_DB_GAML_Real_Positions_Report_Opened_2022](Tables/BI_DB_GAML_Real_Positions_Report_Opened_2022.md) | 9.0 | Done (Batch 5 #10) |
| [BI_DB_dbo.BI_DB_InterestDaily](Tables/BI_DB_InterestDaily.md) | 8.0 | Done (Batch 7 #2) |
| [BI_DB_dbo.BI_DB_Outliers_New](Tables/BI_DB_Outliers_New.md) | 9.0 | Done (Batch 5 #11) |
| [BI_DB_dbo.BI_DB_PositionPnL](Tables/BI_DB_PositionPnL.md) | 9.0 | Done (Batch 5 #12) |
| [BI_DB_dbo.BI_DB_Real_Crypto_Loan](Tables/BI_DB_Real_Crypto_Loan.md) | 9.0 | Done (Batch 4 #7) |
| [BI_DB_dbo.BI_DB_RealCrypto_Lev2](Tables/BI_DB_RealCrypto_Lev2.md) | 9.0 | Done (Batch 5 #13) |
| [BI_DB_dbo.BI_DB_RollOverFee_Dividends](Tables/BI_DB_RollOverFee_Dividends.md) | 9.0 | Done (Batch 5 #14) |
| [BI_DB_dbo.BI_DB_UsageTracking_SF](Tables/BI_DB_UsageTracking_SF.md) | 7.5 | Done (Batch 7 #3) |
| [BI_DB_dbo.BI_DB_VarCommission](Tables/BI_DB_VarCommission.md) | 9.0 | Done (Batch 4 #8) |

*Full table inventory not yet enumerated. Run schema-scope batch to populate all objects.*

## Views (documented: 0)

*Full view inventory not yet enumerated. Run schema-scope batch to populate all objects.*
