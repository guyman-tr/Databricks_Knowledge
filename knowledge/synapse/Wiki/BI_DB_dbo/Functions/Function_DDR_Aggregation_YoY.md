# Function_DDR_Aggregation_YoY

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | DDR (Daily Dashboard Report) |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 129 (T1: 1, T2: 128) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Year-level DDR aggregates per customer with **`Period` = calendar year (YYYY)** between `@StartYear` and `@EndYear`.

**Time logic:** `BI_DB_DDR_Customer_Periodic_Status` is filtered to **one row per year per customer**: `DateID` must equal `MAX(DateID)` grouped by `LEFT(DateID, 4)` within the year range (the latest available snapshot day in that year). The PERIODIC CTE then groups by `RealCID` and `LEFT(DateID,4)` with `MAX` on dimensions and `SUM` on `*_ThisYear` counters. `BI_DB_V_DDR_MIMO`, revenue, PnL, and non-revenue views aggregate **per `RealCID` and calendar year** (`GROUP BY LEFT(DateID,4)`), summing **all days in each year** in range. AUM aligns to the same year-end `DateID` rows as periodic status. `*_FTDA` outputs are literal **0**. Column coverage matches the reduced MoM-style shape (many detailed fields omitted in SQL).

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @StartYear | INT | Start calendar year (YYYY) |
| @EndYear | INT | End calendar year (YYYY) |
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| BI_DB_DDR_Customer_Periodic_Status | BI_DB_dbo |
| BI_DB_V_DDR_MIMO | BI_DB_dbo |
| BI_DB_V_DDR_Revenue_Breakdown | BI_DB_dbo |
| BI_DB_V_DDR_Non_Revenue_Actions | BI_DB_dbo |
| BI_DB_V_DDR_PnL | BI_DB_dbo |
| BI_DB_V_DDR_AUM | BI_DB_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | PeriodName | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status | Literal `'Year'` in PERIODIC / MIMO / revenue CTEs | T2 |
| 2 | Period | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.DateID | `LEFT(DateID, 4)` → calendar year (YYYY) | T2 |
| 3 | RealCID | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.RealCID | Direct from PERIODIC CTE | T1 |
| 4 | FirstActionType | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.FirstActionType_ThisYear | MAX(FirstActionType_ThisYear) in PERIODIC CTE; output GROUP BY dimension | T2 |
| 5 | RegulationID | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.RegulationID_ThisYear | MAX(RegulationID_ThisYear) in PERIODIC CTE; output GROUP BY dimension | T2 |
| 6 | IsCreditReportValidCB | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.IsCreditReportValidCB_ThisYear | MAX(IsCreditReportValidCB_ThisYear) in PERIODIC CTE; output GROUP BY dimension | T2 |
| 7 | IsValidCustomer | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.IsValidCustomer_ThisYear | MAX(IsValidCustomer_ThisYear) in PERIODIC CTE; output GROUP BY dimension | T2 |
| 8 | MifidCategorizationID | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.MifidCategorizationID_ThisYear | MAX(MifidCategorizationID_ThisYear) in PERIODIC CTE; output GROUP BY dimension | T2 |
| 9 | PlayerLevelID | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.PlayerLevelID_ThisYear | MAX(PlayerLevelID_ThisYear) in PERIODIC CTE; output GROUP BY dimension | T2 |
| 10 | CountryID | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.CountryID_ThisYear | MAX(CountryID_ThisYear) in PERIODIC CTE; output GROUP BY dimension | T2 |
| 11 | MarketingRegion | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.MarketingRegion_ThisYear | MAX(MarketingRegion_ThisYear) in PERIODIC CTE; output GROUP BY dimension | T2 |
| 12 | IsFunded | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.IsFunded_ThisYear | `SUM(IsFunded_ThisYear)` in PERIODIC grouped by `RealCID`, `LEFT(DateID,4)` on **year-end snapshot rows only** in range | T2 |
| 13 | FirstTimeFunded | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.FirstTimeFunded_ThisYear | `SUM(FirstTimeFunded_ThisYear)` same PERIODIC grain | T2 |
| 14 | ActiveTraded | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.ActiveTraded_ThisYear | `SUM(ActiveTraded_ThisYear)` same PERIODIC grain | T2 |
| 15 | Portfolio_Only | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.Portfolio_Only_ThisYear | `SUM(Portfolio_Only_ThisYear)` same PERIODIC grain | T2 |
| 16 | BalanceOnlyAccount | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.BalanceOnlyAccount_ThisYear | `SUM(BalanceOnlyAccount_ThisYear)` same PERIODIC grain | T2 |
| 17 | TPFirstDeposited | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.TPFirstDeposited_ThisYear | `SUM(TPFirstDeposited_ThisYear)` same PERIODIC grain | T2 |
| 18 | IBANFirstDeposited | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.IBANFirstDeposited_ThisYear | `SUM(IBANFirstDeposited_ThisYear)` same PERIODIC grain | T2 |
| 19 | GlobalFirstDeposited | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.GlobalFirstDeposited_ThisYear | `SUM(GlobalFirstDeposited_ThisYear)` same PERIODIC grain | T2 |
| 20 | GlobalDeposited | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.GlobalDeposited_ThisYear | `SUM(GlobalDeposited_ThisYear)` same PERIODIC grain | T2 |
| 21 | GlobalRedeposited | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.GlobalRedeposited_ThisYear | `SUM(GlobalRedeposited_ThisYear)` same PERIODIC grain | T2 |
| 22 | GlobalCashedOut | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.GlobalCashedOut_ThisYear | `SUM(GlobalCashedOut_ThisYear)` same PERIODIC grain | T2 |
| 23 | Redeemed | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.Redeemed_ThisYear | `SUM(Redeemed_ThisYear)` same PERIODIC grain | T2 |
| 24 | DepositedTP | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.DepositedTP_ThisYear | `SUM(DepositedTP_ThisYear)` same PERIODIC grain | T2 |
| 25 | DepositedIBAN | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.DepositedIBAN_ThisYear | `SUM(DepositedIBAN_ThisYear)` same PERIODIC grain | T2 |
| 26 | ReDepositedTP | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.ReDepositedTP_ThisYear | `SUM(ReDepositedTP_ThisYear)` same PERIODIC grain | T2 |
| 27 | ReDepositedIBAN | BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status.ReDepositedIBAN_ThisYear | `SUM(ReDepositedIBAN_ThisYear)` same PERIODIC grain | T2 |
| 28 | TP_FTDA | — | Literal 0 (not populated in YoY variant) | T2 |
| 29 | IBAN_FTDA | — | Literal 0 (not populated in YoY variant) | T2 |
| 30 | TP_External_FTDA | — | Literal 0 (not populated in YoY variant) | T2 |
| 31 | Global_FTDA | — | Literal 0 (not populated in YoY variant) | T2 |
| 32 | GlobalDepositAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.GlobalDepositsAmount | `SUM(GlobalDepositsAmount)` in MIMO CTE grouped by `RealCID`, `LEFT(DateID,4)` — **all daily rows in that calendar year** in `@StartYear`–`@EndYear` | T2 |
| 33 | GlobalWithdrawsAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.GlobalWithdrawsAmount | `SUM(GlobalWithdrawsAmount)` same MIMO year grain | T2 |
| 34 | TradeOpenFromIBANCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.TradeOpenFromIBANCount | `SUM(TradeOpenFromIBANCount)` same MIMO year grain | T2 |
| 35 | TradeCloseToIBANCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.TradeCloseToIBANCount | `SUM(TradeCloseToIBANCount)` same MIMO year grain | T2 |
| 36 | GlobalDepositsCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.GlobalDepositsCount | SUM(GlobalDepositsCount) | T2 |
| 37 | GlobalWithdrawsCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.GlobalWithdrawsCount | SUM(GlobalWithdrawsCount) | T2 |
| 38 | ReDepositsGlobalAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ReDepositsGlobalAmount | SUM(ReDepositsGlobalAmount) | T2 |
| 39 | ReDepositsGlobalCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ReDepositsGlobalCount | SUM(ReDepositsGlobalCount) | T2 |
| 40 | TotalFTDGlobalAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.TotalFTDGlobalAmount | SUM(TotalFTDGlobalAmount) | T2 |
| 41 | TotalFTDGlobalCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.TotalFTDGlobalCount | SUM(TotalFTDGlobalCount) | T2 |
| 42 | TransferCoins | BI_DB_dbo.BI_DB_V_DDR_MIMO.TransferCoins | SUM(TransferCoins) | T2 |
| 43 | CountRedeems | BI_DB_dbo.BI_DB_V_DDR_MIMO.CountRedeems | SUM(CountRedeems) | T2 |
| 44 | GlobalWithdraw_ExclRedeem | BI_DB_dbo.BI_DB_V_DDR_MIMO.GlobalWithdraw_ExclRedeem | SUM(GlobalWithdraw_ExclRedeem) | T2 |
| 45 | CashoutAdjustment | BI_DB_dbo.BI_DB_V_DDR_MIMO.CashoutAdjustment | SUM(CashoutAdjustment) | T2 |
| 46 | TradersOpenedFromIBAN | BI_DB_dbo.BI_DB_V_DDR_MIMO | `MAX(CASE WHEN TradeOpenFromIBANCount > 0 THEN 1 ELSE 0 END)` per `RealCID` + year in MIMO CTE; outer query may `SUM` those customer-year flags | T2 |
| 47 | TradersClosedIBAN | BI_DB_dbo.BI_DB_V_DDR_MIMO | `MAX(CASE WHEN TradeCloseToIBANAmount > 0 THEN 1 ELSE 0 END)` per `RealCID` + year in MIMO CTE | T2 |
| 48 | AdminFee | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.AdminFee | SUM(AdminFee) | T2 |
| 49 | CashoutFeeExclRedeem | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CashoutFeeExclRedeem | SUM(CashoutFeeExclRedeem) | T2 |
| 50 | Commission | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.Commission | SUM(Commission) | T2 |
| 51 | ConversionFee | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.ConversionFee | SUM(ConversionFee) | T2 |
| 52 | Dividends | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.Dividends | SUM(Dividends) | T2 |
| 53 | FullCommission | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.FullCommission | SUM(FullCommission) | T2 |
| 54 | RollOverFee | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.RollOverFee | SUM(RollOverFee) | T2 |
| 55 | SDRT | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.SDRT | SUM(SDRT) | T2 |
| 56 | SpotPriceAdjustment | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.SpotPriceAdjustment | SUM(SpotPriceAdjustment) | T2 |
| 57 | TransferCoinFee | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.TransferCoinFee | SUM(TransferCoinFee) | T2 |
| 58 | TicketFee | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.TicketFee | SUM(TicketFee) | T2 |
| 59 | TicketFeeByPercent | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.TicketFeeByPercent | SUM(TicketFeeByPercent) | T2 |
| 60 | DormantFee | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.DormantFee | SUM(DormantFee) | T2 |
| 61 | InterestFee | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.InterestFee | SUM(InterestFee) | T2 |
| 62 | CryptoToFiatFee | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CryptoToFiatFee | SUM(CryptoToFiatFee) | T2 |
| 63 | ShareLending | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.ShareLending | SUM(ShareLending) | T2 |
| 64 | StakingLagOneMonth | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.StakingLagOneMonth | SUM(StakingLagOneMonth) | T2 |
| 65 | TotalRevenue | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.TotalRevenue | SUM(TotalRevenue) | T2 |
| 66 | DailyTotalPnL | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyTotalPnL | SUM(DailyTotalPnL) | T2 |
| 67 | DailyPnLCopy | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyPnLCopy | SUM(DailyPnLCopy) | T2 |
| 68 | DailyPnLStocks | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyPnLStocks | SUM(DailyPnLStocks) | T2 |
| 69 | TradersWithProfit | BI_DB_dbo.BI_DB_V_DDR_PnL | COUNT(DISTINCT CASE WHEN DailyTotalPnL > 0 THEN RealCID END) | T2 |
| 70 | TradersWithLoss | BI_DB_dbo.BI_DB_V_DDR_PnL | COUNT(DISTINCT CASE WHEN DailyTotalPnL < 0 THEN RealCID END) | T2 |
| 71 | TradersWithProfitCopy | BI_DB_dbo.BI_DB_V_DDR_PnL | COUNT(DISTINCT CASE WHEN DailyPnLCopy > 0 THEN RealCID END) | T2 |
| 72 | TradersWithLossCopy | BI_DB_dbo.BI_DB_V_DDR_PnL | COUNT(DISTINCT CASE WHEN DailyPnLCopy < 0 THEN RealCID END) | T2 |
| 73 | TradersWithProfitStocks | BI_DB_dbo.BI_DB_V_DDR_PnL | COUNT(DISTINCT CASE WHEN DailyPnLStocks > 0 THEN RealCID END) | T2 |
| 74 | TradersWithLossStocks | BI_DB_dbo.BI_DB_V_DDR_PnL | COUNT(DISTINCT CASE WHEN DailyPnLStocks < 0 THEN RealCID END) | T2 |
| 75 | CompensationOtherAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationOtherAmount | SUM(CompensationOtherAmount) | T2 |
| 76 | CompensationPIWithCashoutAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationPIWithCashoutAmount | SUM(CompensationPIWithCashoutAmount) | T2 |
| 77 | CompensationRAFInvitedInvitingAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationRAFInvitedInvitingAmount | SUM(CompensationRAFInvitedInvitingAmount) | T2 |
| 78 | CompensationToAffiliateNoCashoutAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationToAffiliateNoCashoutAmount | SUM(CompensationToAffiliateNoCashoutAmount) | T2 |
| 79 | CompensationToAffiliateWithCashoutAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationToAffiliateWithCashoutAmount | SUM(CompensationToAffiliateWithCashoutAmount) | T2 |
| 80 | EditStoplossAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.EditStoplossAmount | SUM(EditStoplossAmount) | T2 |
| 81 | InvestmentAmountInNewTradesAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.InvestmentAmountInNewTradesAmount | SUM(InvestmentAmountInNewTradesAmount) | T2 |
| 82 | InvestmentAmountClosedTradesAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.InvestmentAmountClosedTradesAmount | SUM(InvestmentAmountClosedTradesAmount) | T2 |
| 83 | NewCopyAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.NewCopyAmount | SUM(NewCopyAmount) | T2 |
| 84 | StopCopyAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.StopCopyAmount | SUM(StopCopyAmount) | T2 |
| 85 | AddToCopyAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.AddToCopyAmount | SUM(AddToCopyAmount) | T2 |
| 86 | RemoveFromCopyAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.RemoveFromCopyAmount | SUM(RemoveFromCopyAmount) | T2 |
| 87 | CompensationOtherCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationOtherCount | SUM(CompensationOtherCount) | T2 |
| 88 | CompensationPIWithCashoutCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationPIWithCashoutCount | SUM(CompensationPIWithCashoutCount) | T2 |
| 89 | CompensationRAFInvitedInvitingCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationRAFInvitedInvitingCount | SUM(CompensationRAFInvitedInvitingCount) | T2 |
| 90 | CompensationToAffiliateNoCashoutCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationToAffiliateNoCashoutCount | SUM(CompensationToAffiliateNoCashoutCount) | T2 |
| 91 | CompensationToAffiliateWithCashoutCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationToAffiliateWithCashoutCount | SUM(CompensationToAffiliateWithCashoutCount) | T2 |
| 92 | EditStoplossCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.EditStoplossCount | SUM(EditStoplossCount) | T2 |
| 93 | NewTradesCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.NewTradesCount | SUM(NewTradesCount) | T2 |
| 94 | ClosedTradesCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.ClosedTradesCount | SUM(ClosedTradesCount) | T2 |
| 95 | NewCopyCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.NewCopyCount | SUM(NewCopyCount) | T2 |
| 96 | StopCopyCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.StopCopyCount | SUM(StopCopyCount) | T2 |
| 97 | AddToCopyCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.AddToCopyCount | SUM(AddToCopyCount) | T2 |
| 98 | RemoveFromCopyCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.RemoveFromCopyCount | SUM(RemoveFromCopyCount) | T2 |
| 99 | PnLAdjustment | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.PnLAdjustment | SUM(PnLAdjustment) | T2 |
| 100 | BonusComp | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.BonusComp | SUM(BonusComp) | T2 |
| 101 | NewCopyUsers | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions | COUNT(DISTINCT CASE WHEN NewCopyCount > 0 THEN RealCID END) | T2 |
| 102 | RevenueGenerators | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.RevenueGenerators | SUM(RevenueGenerators) | T2 |
| 103 | ActiveOpened | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.ActiveOpened | SUM(ActiveOpened) | T2 |
| 104 | RealizedEquityTP | BI_DB_dbo.BI_DB_V_DDR_AUM.RealizedEquityTP | SUM(RealizedEquityTP) | T2 |
| 105 | TotalLiabilityTP | BI_DB_dbo.BI_DB_V_DDR_AUM.TotalLiabilityTP | SUM(TotalLiabilityTP) | T2 |
| 106 | InProcessCashout | BI_DB_dbo.BI_DB_V_DDR_AUM.InProcessCashout | SUM(InProcessCashout) | T2 |
| 107 | TotalPositionPNL | BI_DB_dbo.BI_DB_V_DDR_AUM.TotalPositionPNL | SUM(TotalPositionPNL) | T2 |
| 108 | TotalInvestedAmount | BI_DB_dbo.BI_DB_V_DDR_AUM.TotalInvestedAmount | SUM(TotalInvestedAmount) | T2 |
| 109 | TotalEquityTP | BI_DB_dbo.BI_DB_V_DDR_AUM.TotalEquityTP | SUM(TotalEquityTP) | T2 |
| 110 | EquityCopy | BI_DB_dbo.BI_DB_V_DDR_AUM.EquityCopy | SUM(EquityCopy) | T2 |
| 111 | InvestedAmountCopy | BI_DB_dbo.BI_DB_V_DDR_AUM.InvestedAmountCopy | SUM(InvestedAmountCopy) | T2 |
| 112 | EquityStocksManual | BI_DB_dbo.BI_DB_V_DDR_AUM.EquityStocksManual | SUM(EquityStocksManual) | T2 |
| 113 | InvestedAmountStocksManual | BI_DB_dbo.BI_DB_V_DDR_AUM.InvestedAmountStocksManual | SUM(InvestedAmountStocksManual) | T2 |
| 114 | InvestedAmountCryptoManual | BI_DB_dbo.BI_DB_V_DDR_AUM.InvestedAmountCryptoManual | SUM(InvestedAmountCryptoManual) | T2 |
| 115 | EquityCryptoManual | BI_DB_dbo.BI_DB_V_DDR_AUM.EquityCryptoManual | SUM(EquityCryptoManual) | T2 |
| 116 | CreditTP | BI_DB_dbo.BI_DB_V_DDR_AUM.CreditTP | SUM(CreditTP) | T2 |
| 117 | ActualNWA | BI_DB_dbo.BI_DB_V_DDR_AUM.ActualNWA | SUM(ActualNWA) | T2 |
| 118 | IBANBalance | BI_DB_dbo.BI_DB_V_DDR_AUM.IBANBalance | SUM(IBANBalance) | T2 |
| 119 | RealizedEquityGlobal | BI_DB_dbo.BI_DB_V_DDR_AUM.RealizedEquityGlobal | SUM(RealizedEquityGlobal) | T2 |
| 120 | TotalLiabilityGlobal | BI_DB_dbo.BI_DB_V_DDR_AUM.TotalLiabilityGlobal | SUM(TotalLiabilityGlobal) | T2 |
| 121 | EquityGlobal | BI_DB_dbo.BI_DB_V_DDR_AUM.EquityGlobal | SUM(EquityGlobal) | T2 |
| 122 | CreditGlobal | BI_DB_dbo.BI_DB_V_DDR_AUM.CreditGlobal | SUM(CreditGlobal) | T2 |
| 123 | Bonus | BI_DB_dbo.BI_DB_V_DDR_AUM.Bonus | SUM(Bonus) | T2 |
| 124 | OptionsTotalEquity | BI_DB_dbo.BI_DB_V_DDR_AUM.OptionsTotalEquity | SUM(OptionsTotalEquity) | T2 |
| 125 | PnLAdjusted | BI_DB_dbo.BI_DB_V_DDR_PnL, BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions | SUM(ISNULL(DailyTotalPnL, 0) + ISNULL(PnLAdjustment, 0)) | T2 |
| 126 | ZeroPnLAdjusted | BI_DB_dbo.BI_DB_V_DDR_PnL, BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions, BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown | SUM(ISNULL(DailyTotalPnL, 0) + ISNULL(PnLAdjustment, 0) + ISNULL(Commission, 0)) | T2 |
| 127 | ZeroPnLCopy | BI_DB_dbo.BI_DB_V_DDR_PnL, BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown | SUM(ISNULL(DailyPnLCopy, 0) + ISNULL(CommissionCopy, 0)) | T2 |
| 128 | ZeroPnLStocks | BI_DB_dbo.BI_DB_V_DDR_PnL, BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown | SUM(ISNULL(DailyPnLStocks, 0) + ISNULL(CommissionStocks, 0)) | T2 |
| 129 | GlobalCashoutsAdjusted | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions, BI_DB_dbo.BI_DB_V_DDR_MIMO | SUM(ISNULL(GlobalWithdraw_ExclRedeem, 0) - ISNULL(CompensationToAffiliateWithCashoutAmount, 0) + ISNULL(CompensationPIWithCashoutAmount, 0)) | T2 |

## 5. Change History (only if found in SQL comments)


| Date | Author | Description |
|------|--------|-------------|
| 2025-10-20 | Guy M | Initial creation - adapted from Function_DDR_Aggregation_ThisYear |


---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
