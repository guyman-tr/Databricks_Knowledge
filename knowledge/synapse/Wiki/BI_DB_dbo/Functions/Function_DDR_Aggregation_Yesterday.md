# Function_DDR_Aggregation_Yesterday

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | DDR (Daily Dashboard Report) |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 238 (T1: 1, T2: 237) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

DDR metrics for **the single calendar day `@edate` only** (not month-to-date). The periodic layer is built from `BI_DB_DDR_Customer_Daily_Status` where `Date = @edate` (daily flags without `_ThisMonth` / `_ThisWeek` suffixes). `BI_DB_V_DDR_MIMO`, `BI_DB_V_DDR_Revenue_Breakdown`, `BI_DB_V_DDR_Non_Revenue_Actions`, and `BI_DB_V_DDR_PnL` are all restricted to **`Date = @edate`**. `BI_DB_V_DDR_AUM` is also **`Date = @edate`**. First-time-deposit amounts (`*_FTDA`) are `SUM(CASE WHEN first-deposit flag THEN daily FTDA ELSE 0 END)` inside the PERIODIC CTE on that same day, then summed again in the outer grouped select.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @edate | DATE | As-of calendar date for periodic snapshot and period window |
| @OnlyValidCustomers | BIT | 0 = all customers, 1 = valid customers only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| BI_DB_DDR_Customer_Daily_Status | BI_DB_dbo |
| BI_DB_V_DDR_MIMO | BI_DB_dbo |
| BI_DB_V_DDR_Revenue_Breakdown | BI_DB_dbo |
| BI_DB_V_DDR_Non_Revenue_Actions | BI_DB_dbo |
| BI_DB_V_DDR_PnL | BI_DB_dbo |
| BI_DB_V_DDR_AUM | BI_DB_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | DateID | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.DateID | `@dateID` (`YYYYMMDD`) — partition / delete key for the narrow table. (Tier 2 — SP_DDR_Customer_Daily_Status) (via BI_DB_DDR_Customer_Daily_Status) | T1 |
| 2 | FirstActionType | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.FirstActionType | MAX(FirstActionType) in PERIODIC CTE; output GROUP BY dimension | T2 |
| 3 | RegulationID | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.RegulationID | MAX(RegulationID) in PERIODIC CTE; output GROUP BY dimension | T2 |
| 4 | IsCreditReportValidCB | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.IsCreditReportValidCB | MAX(IsCreditReportValidCB) in PERIODIC CTE; output GROUP BY dimension | T2 |
| 5 | IsValidCustomer | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.IsValidCustomer | MAX(IsValidCustomer) in PERIODIC CTE; output GROUP BY dimension | T2 |
| 6 | MifidCategorizationID | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.MifidCategorizationID | MAX(MifidCategorizationID) in PERIODIC CTE; output GROUP BY dimension | T2 |
| 7 | PlayerLevelID | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.PlayerLevelID | MAX(PlayerLevelID) in PERIODIC CTE; output GROUP BY dimension | T2 |
| 8 | CountryID | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.CountryID | MAX(CountryID) in PERIODIC CTE; output GROUP BY dimension | T2 |
| 9 | MarketingRegion | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.MarketingRegion | MAX(MarketingRegion) in PERIODIC CTE; output GROUP BY dimension | T2 |
| 10 | IsFunded | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.IsFunded | `MAX(IsFunded)` in PERIODIC where `Date = @edate`; outer `SUM(ps.IsFunded)` over output dimensions | T2 |
| 11 | FirstTimeFunded | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.FirstTimeFunded | `MAX(FirstTimeFunded)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 12 | ActiveTraded | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.ActiveTraded | `MAX(ActiveTraded)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 13 | Portfolio_Only | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.Portfolio_Only | `MAX(Portfolio_Only)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 14 | BalanceOnlyAccount | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.BalanceOnlyAccount | `MAX(BalanceOnlyAccount)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 15 | TPFirstDeposited | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.TPFirstDeposited | `MAX(TPFirstDeposited)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 16 | IBANFirstDeposited | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.IBANFirstDeposited | `MAX(IBANFirstDeposited)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 17 | TPExternalFirstDeposited | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.TPExternalFirstDeposited | `MAX(TPExternalFirstDeposited)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 18 | GlobalFirstDeposited | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.GlobalFirstDeposited | `MAX(GlobalFirstDeposited)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 19 | GlobalDeposited | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.GlobalDeposited | `MAX(GlobalDeposited)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 20 | GlobalRedeposited | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.GlobalRedeposited | `MAX(GlobalRedeposited)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 21 | GlobalCashedOut | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.GlobalCashedOut | `MAX(GlobalCashedOut)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 22 | Redeemed | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.Redeemed | `MAX(Redeemed)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 23 | DepositedTP | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.DepositedTP | `MAX(DepositedTP)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 24 | DepositedIBAN | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.DepositedIBAN | `MAX(DepositedIBAN)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 25 | ReDepositedTP | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.ReDepositedTP | `MAX(ReDepositedTP)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 26 | ReDepositedIBAN | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status.ReDepositedIBAN | `MAX(ReDepositedIBAN)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 27 | TP_FTDA | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status | `SUM(CASE WHEN TPFirstDeposited = 1 THEN TP_FTDA ELSE 0 END)` in PERIODIC (`Date = @edate`); outer `SUM(TP_FTDA)` | T2 |
| 28 | IBAN_FTDA | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status | `SUM(CASE WHEN IBANFirstDeposited = 1 THEN IBAN_FTDA ELSE 0 END)` in PERIODIC (`Date = @edate`); outer `SUM(IBAN_FTDA)` | T2 |
| 29 | TP_External_FTDA | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status | `SUM(CASE WHEN TPExternalFirstDeposited = 1 THEN TP_External_FTDA ELSE 0 END)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 30 | Global_FTDA | BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status | `SUM(CASE WHEN GlobalFirstDeposited = 1 THEN Global_FTDA ELSE 0 END)` in PERIODIC (`Date = @edate`); outer `SUM` | T2 |
| 31 | ExternalDepositsTPAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalDepositsTPAmount | `SUM(ExternalDepositsTPAmount)` over MIMO rows with **`Date = @edate` only**; outer `SUM` | T2 |
| 32 | ExternalWithdrawTPAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalWithdrawTPAmount | SUM(ExternalWithdrawTPAmount) | T2 |
| 33 | InternalDepositsTPAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.InternalDepositsTPAmount | SUM(InternalDepositsTPAmount) | T2 |
| 34 | InternalWithdrawTPAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.InternalWithdrawTPAmount | SUM(InternalWithdrawTPAmount) | T2 |
| 35 | TradeOpenFromIBANAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.TradeOpenFromIBANAmount | SUM(TradeOpenFromIBANAmount) | T2 |
| 36 | TradeCloseToIBANAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.TradeCloseToIBANAmount | SUM(TradeCloseToIBANAmount) | T2 |
| 37 | GlobalDepositsAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.GlobalDepositsAmount | SUM(GlobalDepositsAmount) | T2 |
| 38 | GlobalWithdrawsAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.GlobalWithdrawsAmount | SUM(GlobalWithdrawsAmount) | T2 |
| 39 | ExternalDepositToIBANAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalDepositToIBANAmount | SUM(ExternalDepositToIBANAmount) | T2 |
| 40 | ExternalWithdrawFromIBANAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalWithdrawFromIBANAmount | SUM(ExternalWithdrawFromIBANAmount) | T2 |
| 41 | ExternalDepositsTPCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalDepositsTPCount | SUM(ExternalDepositsTPCount) | T2 |
| 42 | ExternalWithdrawTPCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalWithdrawTPCount | SUM(ExternalWithdrawTPCount) | T2 |
| 43 | InternalDepositsTPCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.InternalDepositsTPCount | SUM(InternalDepositsTPCount) | T2 |
| 44 | InternalWithdrawTPCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.InternalWithdrawTPCount | SUM(InternalWithdrawTPCount) | T2 |
| 45 | TradeOpenFromIBANCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.TradeOpenFromIBANCount | SUM(TradeOpenFromIBANCount) | T2 |
| 46 | TradeCloseToIBANCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.TradeCloseToIBANCount | SUM(TradeCloseToIBANCount) | T2 |
| 47 | GlobalDepositsCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.GlobalDepositsCount | SUM(GlobalDepositsCount) | T2 |
| 48 | GlobalWithdrawsCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.GlobalWithdrawsCount | SUM(GlobalWithdrawsCount) | T2 |
| 49 | ExternalDepositToIBANCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalDepositToIBANCount | SUM(ExternalDepositToIBANCount) | T2 |
| 50 | ExternalWithdrawFromIBANCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalWithdrawFromIBANCount | SUM(ExternalWithdrawFromIBANCount) | T2 |
| 51 | ExternalReDepositsTPAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalReDepositsTPAmount | SUM(ExternalReDepositsTPAmount) | T2 |
| 52 | ExternalReDepositsTPCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalReDepositsTPCount | SUM(ExternalReDepositsTPCount) | T2 |
| 53 | InternalReDepositsTPAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.InternalReDepositsTPAmount | SUM(InternalReDepositsTPAmount) | T2 |
| 54 | InternalReDepositsTPCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.InternalReDepositsTPCount | SUM(InternalReDepositsTPCount) | T2 |
| 55 | ReDepositsGlobalAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ReDepositsGlobalAmount | SUM(ReDepositsGlobalAmount) | T2 |
| 56 | ReDepositsGlobalCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ReDepositsGlobalCount | SUM(ReDepositsGlobalCount) | T2 |
| 57 | ExternalFTDTPAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalFTDTPAmount | SUM(ExternalFTDTPAmount) | T2 |
| 58 | ExternalFTDTPCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalFTDTPCount | SUM(ExternalFTDTPCount) | T2 |
| 59 | InternalFTDTPAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.InternalFTDTPAmount | SUM(InternalFTDTPAmount) | T2 |
| 60 | InternalFTDTPCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.InternalFTDTPCount | SUM(InternalFTDTPCount) | T2 |
| 61 | ExternalFTDIBANAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalFTDIBANAmount | SUM(ExternalFTDIBANAmount) | T2 |
| 62 | ExternalFTDIBANCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalFTDIBANCount | SUM(ExternalFTDIBANCount) | T2 |
| 63 | InternalFTDIBANAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.InternalFTDIBANAmount | SUM(InternalFTDIBANAmount) | T2 |
| 64 | InternalFTDIBANCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.InternalFTDIBANCount | SUM(InternalFTDIBANCount) | T2 |
| 65 | TotalFTDGlobalAmount | BI_DB_dbo.BI_DB_V_DDR_MIMO.TotalFTDGlobalAmount | SUM(TotalFTDGlobalAmount) | T2 |
| 66 | TotalFTDGlobalCount | BI_DB_dbo.BI_DB_V_DDR_MIMO.TotalFTDGlobalCount | SUM(TotalFTDGlobalCount) | T2 |
| 67 | TransferCoins | BI_DB_dbo.BI_DB_V_DDR_MIMO.TransferCoins | SUM(TransferCoins) | T2 |
| 68 | CountRedeems | BI_DB_dbo.BI_DB_V_DDR_MIMO.CountRedeems | SUM(CountRedeems) | T2 |
| 69 | WithdrawTP_ExclRedeem | BI_DB_dbo.BI_DB_V_DDR_MIMO.WithdrawTP_ExclRedeem | SUM(WithdrawTP_ExclRedeem) | T2 |
| 70 | ExternalWithdrawTP_ExclRedeem | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalWithdrawTP_ExclRedeem | SUM(ExternalWithdrawTP_ExclRedeem) | T2 |
| 71 | GlobalWithdraw_ExclRedeem | BI_DB_dbo.BI_DB_V_DDR_MIMO.GlobalWithdraw_ExclRedeem | SUM(GlobalWithdraw_ExclRedeem) | T2 |
| 72 | CashoutAdjustment | BI_DB_dbo.BI_DB_V_DDR_MIMO.CashoutAdjustment | SUM(CashoutAdjustment) | T2 |
| 73 | ExternalCashedOutTP | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalCashedOutTP | Outer `SUM` of per-customer `MAX(ExternalCashedOutTP)` from MIMO CTE (**`Date = @edate`**) | T2 |
| 74 | InternalCashedOutTP | BI_DB_dbo.BI_DB_V_DDR_MIMO.InternalCashedOutTP | Outer `SUM` of per-customer `MAX(InternalCashedOutTP)` from MIMO CTE (**`Date = @edate`**) | T2 |
| 75 | ExternalCashedOutIBAN | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalCashedOutIBAN | Outer `SUM` of per-customer `MAX(ExternalCashedOutIBAN)` from MIMO CTE (**`Date = @edate`**) | T2 |
| 76 | InternalCashedOutIBAN | BI_DB_dbo.BI_DB_V_DDR_MIMO.InternalCashedOutIBAN | Outer `SUM` of per-customer `MAX(InternalCashedOutIBAN)` from MIMO CTE (**`Date = @edate`**) | T2 |
| 77 | TradersOpenedFromIBAN | BI_DB_dbo.BI_DB_V_DDR_MIMO | Outer `SUM` of per-customer `MAX(CASE WHEN TradeOpenFromIBANCount > 0 THEN 1 ELSE 0 END)` on **`Date = @edate`** | T2 |
| 78 | TradersClosedIBAN | BI_DB_dbo.BI_DB_V_DDR_MIMO | Outer `SUM` of per-customer `MAX(CASE WHEN TradeCloseToIBANAmount > 0 THEN 1 ELSE 0 END)` on **`Date = @edate`** | T2 |
| 79 | InternalDepositedTP | BI_DB_dbo.BI_DB_V_DDR_MIMO.InternalDepositedTP | Outer `SUM` of per-customer `MAX(InternalDepositedTP)` from MIMO CTE (**`Date = @edate`**) | T2 |
| 80 | ExternalDepositedTP | BI_DB_dbo.BI_DB_V_DDR_MIMO.ExternalDepositedTP | Outer `SUM` of per-customer `MAX(ExternalDepositedTP)` from MIMO CTE (**`Date = @edate`**) | T2 |
| 81 | CashedOutTP | BI_DB_dbo.BI_DB_V_DDR_MIMO.CashedOutTP | Outer `SUM` of per-customer `MAX(CashedOutTP)` from MIMO CTE (**`Date = @edate`**) | T2 |
| 82 | AdminFee | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.AdminFee | SUM(AdminFee) | T2 |
| 83 | CashoutFeeExclRedeem | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CashoutFeeExclRedeem | SUM(CashoutFeeExclRedeem) | T2 |
| 84 | Commission | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.Commission | SUM(Commission) | T2 |
| 85 | ConversionFee | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.ConversionFee | SUM(ConversionFee) | T2 |
| 86 | Dividends | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.Dividends | SUM(Dividends) | T2 |
| 87 | FullCommission | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.FullCommission | SUM(FullCommission) | T2 |
| 88 | RollOverFee | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.RollOverFee | SUM(RollOverFee) | T2 |
| 89 | SDRT | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.SDRT | SUM(SDRT) | T2 |
| 90 | SpotPriceAdjustment | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.SpotPriceAdjustment | SUM(SpotPriceAdjustment) | T2 |
| 91 | TransferCoinFee | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.TransferCoinFee | SUM(TransferCoinFee) | T2 |
| 92 | TicketFee | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.TicketFee | SUM(TicketFee) | T2 |
| 93 | TicketFeeByPercent | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.TicketFeeByPercent | SUM(TicketFeeByPercent) | T2 |
| 94 | DormantFee | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.DormantFee | SUM(DormantFee) | T2 |
| 95 | InterestFee | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.InterestFee | SUM(InterestFee) | T2 |
| 96 | CryptoToFiatFee | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CryptoToFiatFee | SUM(CryptoToFiatFee) | T2 |
| 97 | ShareLending | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.ShareLending | SUM(ShareLending) | T2 |
| 98 | StakingLagOneMonth | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.StakingLagOneMonth | SUM(StakingLagOneMonth) | T2 |
| 99 | TotalRevenue | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.TotalRevenue | SUM(TotalRevenue) | T2 |
| 100 | FullCommissionManual | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.FullCommissionManual | SUM(FullCommissionManual) | T2 |
| 101 | FullCommissionCopy | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.FullCommissionCopy | SUM(FullCommissionCopy) | T2 |
| 102 | FullCommissionStocks | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.FullCommissionStocks | SUM(FullCommissionStocks) | T2 |
| 103 | FullCommissionCrypto | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.FullCommissionCrypto | SUM(FullCommissionCrypto) | T2 |
| 104 | FullCommissionETF | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.FullCommissionETF | SUM(FullCommissionETF) | T2 |
| 105 | FullCommissionStocksReal | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.FullCommissionStocksReal | SUM(FullCommissionStocksReal) | T2 |
| 106 | FullCommissionCryptoReal | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.FullCommissionCryptoReal | SUM(FullCommissionCryptoReal) | T2 |
| 107 | FullCommissionETFReal | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.FullCommissionETFReal | SUM(FullCommissionETFReal) | T2 |
| 108 | FullCommissionStocksCFD | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.FullCommissionStocksCFD | SUM(FullCommissionStocksCFD) | T2 |
| 109 | FullCommissionCryptoCFD | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.FullCommissionCryptoCFD | SUM(FullCommissionCryptoCFD) | T2 |
| 110 | FullCommissionETFCFD | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.FullCommissionETFCFD | SUM(FullCommissionETFCFD) | T2 |
| 111 | FullCommissionCFD_FX_COM_IDX | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.FullCommissionCFD_FX_COM_IDX | SUM(FullCommissionCFD_FX_COM_IDX) | T2 |
| 112 | FullCommissionCurrencies | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.FullCommissionCurrencies | SUM(FullCommissionCurrencies) | T2 |
| 113 | FullCommissionCommodities | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.FullCommissionCommodities | SUM(FullCommissionCommodities) | T2 |
| 114 | FullCommissionIndices | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.FullCommissionIndices | SUM(FullCommissionIndices) | T2 |
| 115 | CommissionManual | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CommissionManual | SUM(CommissionManual) | T2 |
| 116 | CommissionCopy | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CommissionCopy | SUM(CommissionCopy) | T2 |
| 117 | CommissionStocks | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CommissionStocks | SUM(CommissionStocks) | T2 |
| 118 | CommissionCrypto | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CommissionCrypto | SUM(CommissionCrypto) | T2 |
| 119 | CommissionETF | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CommissionETF | SUM(CommissionETF) | T2 |
| 120 | CommissionStocksReal | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CommissionStocksReal | SUM(CommissionStocksReal) | T2 |
| 121 | CommissionCryptoReal | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CommissionCryptoReal | SUM(CommissionCryptoReal) | T2 |
| 122 | CommissionETFReal | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CommissionETFReal | SUM(CommissionETFReal) | T2 |
| 123 | CommissionStocksCFD | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CommissionStocksCFD | SUM(CommissionStocksCFD) | T2 |
| 124 | CommissionCryptoCFD | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CommissionCryptoCFD | SUM(CommissionCryptoCFD) | T2 |
| 125 | CommissionETFCFD | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CommissionETFCFD | SUM(CommissionETFCFD) | T2 |
| 126 | CommissionCFD_FX_COM_IDX | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CommissionCFD_FX_COM_IDX | SUM(CommissionCFD_FX_COM_IDX) | T2 |
| 127 | CommissionCurrencies | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CommissionCurrencies | SUM(CommissionCurrencies) | T2 |
| 128 | CommissionCommodities | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CommissionCommodities | SUM(CommissionCommodities) | T2 |
| 129 | CommissionIndices | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.CommissionIndices | SUM(CommissionIndices) | T2 |
| 130 | RollOverFeeStocks | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.RollOverFeeStocks | SUM(RollOverFeeStocks) | T2 |
| 131 | RollOverFeeETF | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.RollOverFeeETF | SUM(RollOverFeeETF) | T2 |
| 132 | RollOverFeeCrypto | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.RollOverFeeCrypto | SUM(RollOverFeeCrypto) | T2 |
| 133 | RollOverFee_FX_COM_IDX | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.RollOverFee_FX_COM_IDX | SUM(RollOverFee_FX_COM_IDX) | T2 |
| 134 | AdminFeeStocks | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.AdminFeeStocks | SUM(AdminFeeStocks) | T2 |
| 135 | AdminFeeETF | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.AdminFeeETF | SUM(AdminFeeETF) | T2 |
| 136 | AdminFeeCrypto | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.AdminFeeCrypto | SUM(AdminFeeCrypto) | T2 |
| 137 | AdminFeeFee_FX_COM_IDX | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.AdminFeeFee_FX_COM_IDX | SUM(AdminFeeFee_FX_COM_IDX) | T2 |
| 138 | SpotAdjustFeeStocks | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.SpotAdjustFeeStocks | SUM(SpotAdjustFeeStocks) | T2 |
| 139 | SpotAdjustFeeETF | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.SpotAdjustFeeETF | SUM(SpotAdjustFeeETF) | T2 |
| 140 | SpotAdjustFeeCrypto | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.SpotAdjustFeeCrypto | SUM(SpotAdjustFeeCrypto) | T2 |
| 141 | SpotAdjustFeeFee_FX_COM_IDX | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.SpotAdjustFeeFee_FX_COM_IDX | SUM(SpotAdjustFeeFee_FX_COM_IDX) | T2 |
| 142 | TicketFeeStocks | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.TicketFeeStocks | SUM(TicketFeeStocks) | T2 |
| 143 | TicketFeeETF | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.TicketFeeETF | SUM(TicketFeeETF) | T2 |
| 144 | TicketFeeCrypto | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.TicketFeeCrypto | SUM(TicketFeeCrypto) | T2 |
| 145 | TicketFee_FX_COM_IDX | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.TicketFee_FX_COM_IDX | SUM(TicketFee_FX_COM_IDX) | T2 |
| 146 | TicketFeeByPercentStocks | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.TicketFeeByPercentStocks | SUM(TicketFeeByPercentStocks) | T2 |
| 147 | TicketFeeByPercentETF | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.TicketFeeByPercentETF | SUM(TicketFeeByPercentETF) | T2 |
| 148 | TicketFeeByPercentCrypto | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.TicketFeeByPercentCrypto | SUM(TicketFeeByPercentCrypto) | T2 |
| 149 | TicketFeeByPercent_FX_COM_IDX | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.TicketFeeByPercent_FX_COM_IDX | SUM(TicketFeeByPercent_FX_COM_IDX) | T2 |
| 150 | RealizedEquityTP | BI_DB_dbo.BI_DB_V_DDR_AUM.RealizedEquityTP | SUM(RealizedEquityTP) where AUM is **`Date = @edate` only**; outer SUM across customers in group | T2 |
| 151 | TotalLiabilityTP | BI_DB_dbo.BI_DB_V_DDR_AUM.TotalLiabilityTP | SUM(TotalLiabilityTP) | T2 |
| 152 | InProcessCashout | BI_DB_dbo.BI_DB_V_DDR_AUM.InProcessCashout | SUM(InProcessCashout) | T2 |
| 153 | TotalPositionPNL | BI_DB_dbo.BI_DB_V_DDR_AUM.TotalPositionPNL | SUM(TotalPositionPNL) | T2 |
| 154 | TotalInvestedAmount | BI_DB_dbo.BI_DB_V_DDR_AUM.TotalInvestedAmount | SUM(TotalInvestedAmount) | T2 |
| 155 | TotalEquityTP | BI_DB_dbo.BI_DB_V_DDR_AUM.TotalEquityTP | SUM(TotalEquityTP) | T2 |
| 156 | EquityCopy | BI_DB_dbo.BI_DB_V_DDR_AUM.EquityCopy | SUM(EquityCopy) | T2 |
| 157 | InvestedAmountCopy | BI_DB_dbo.BI_DB_V_DDR_AUM.InvestedAmountCopy | SUM(InvestedAmountCopy) | T2 |
| 158 | EquityStocksManual | BI_DB_dbo.BI_DB_V_DDR_AUM.EquityStocksManual | SUM(EquityStocksManual) | T2 |
| 159 | InvestedAmountStocksManual | BI_DB_dbo.BI_DB_V_DDR_AUM.InvestedAmountStocksManual | SUM(InvestedAmountStocksManual) | T2 |
| 160 | InvestedAmountCryptoManual | BI_DB_dbo.BI_DB_V_DDR_AUM.InvestedAmountCryptoManual | SUM(InvestedAmountCryptoManual) | T2 |
| 161 | EquityCryptoManual | BI_DB_dbo.BI_DB_V_DDR_AUM.EquityCryptoManual | SUM(EquityCryptoManual) | T2 |
| 162 | CreditTP | BI_DB_dbo.BI_DB_V_DDR_AUM.CreditTP | SUM(CreditTP) | T2 |
| 163 | ActualNWA | BI_DB_dbo.BI_DB_V_DDR_AUM.ActualNWA | SUM(ActualNWA) | T2 |
| 164 | IBANBalance | BI_DB_dbo.BI_DB_V_DDR_AUM.IBANBalance | SUM(IBANBalance) | T2 |
| 165 | RealizedEquityGlobal | BI_DB_dbo.BI_DB_V_DDR_AUM.RealizedEquityGlobal | SUM(RealizedEquityGlobal) | T2 |
| 166 | TotalLiabilityGlobal | BI_DB_dbo.BI_DB_V_DDR_AUM.TotalLiabilityGlobal | SUM(TotalLiabilityGlobal) | T2 |
| 167 | EquityGlobal | BI_DB_dbo.BI_DB_V_DDR_AUM.EquityGlobal | SUM(EquityGlobal) | T2 |
| 168 | CreditGlobal | BI_DB_dbo.BI_DB_V_DDR_AUM.CreditGlobal | SUM(CreditGlobal) | T2 |
| 169 | Bonus | BI_DB_dbo.BI_DB_V_DDR_AUM.Bonus | SUM(Bonus) | T2 |
| 170 | DailyTotalPnL | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyTotalPnL | SUM(DailyTotalPnL) | T2 |
| 171 | DailyPnLManual | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyPnLManual | SUM(DailyPnLManual) | T2 |
| 172 | DailyPnLCopy | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyPnLCopy | SUM(DailyPnLCopy) | T2 |
| 173 | DailyPnLStocks | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyPnLStocks | SUM(DailyPnLStocks) | T2 |
| 174 | DailyPnLCrypto | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyPnLCrypto | SUM(DailyPnLCrypto) | T2 |
| 175 | DailyPnLETF | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyPnLETF | SUM(DailyPnLETF) | T2 |
| 176 | DailyPnLStocksReal | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyPnLStocksReal | SUM(DailyPnLStocksReal) | T2 |
| 177 | DailyPnLCryptoReal | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyPnLCryptoReal | SUM(DailyPnLCryptoReal) | T2 |
| 178 | DailyPnLETFReal | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyPnLETFReal | SUM(DailyPnLETFReal) | T2 |
| 179 | DailyPnLStocksCFD | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyPnLStocksCFD | SUM(DailyPnLStocksCFD) | T2 |
| 180 | DailyPnLCryptoCFD | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyPnLCryptoCFD | SUM(DailyPnLCryptoCFD) | T2 |
| 181 | DailyPnLETFCFD | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyPnLETFCFD | SUM(DailyPnLETFCFD) | T2 |
| 182 | DailyPnLCFD_FX_COM_IDX | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyPnLCFD_FX_COM_IDX | SUM(DailyPnLCFD_FX_COM_IDX) | T2 |
| 183 | DailyPnLCFDCurrencies | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyPnLCFDCurrencies | SUM(DailyPnLCFDCurrencies) | T2 |
| 184 | DailyPnLCFDCommodities | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyPnLCFDCommodities | SUM(DailyPnLCFDCommodities) | T2 |
| 185 | DailyPnLCFDIndices | BI_DB_dbo.BI_DB_V_DDR_PnL.DailyPnLCFDIndices | SUM(DailyPnLCFDIndices) | T2 |
| 186 | TradersWithProfit | BI_DB_dbo.BI_DB_V_DDR_PnL | count(DISTINCT CASE WHEN DailyTotalPnL > 0 THEN RealCID END) | T2 |
| 187 | TradersWithLoss | BI_DB_dbo.BI_DB_V_DDR_PnL | count(DISTINCT CASE WHEN DailyTotalPnL < 0 THEN RealCID END) | T2 |
| 188 | TradersWithProfitCopy | BI_DB_dbo.BI_DB_V_DDR_PnL | count(DISTINCT CASE WHEN DailyPnLCopy > 0 THEN RealCID END) | T2 |
| 189 | TradersWithLossCopy | BI_DB_dbo.BI_DB_V_DDR_PnL | count(DISTINCT CASE WHEN DailyPnLCopy < 0 THEN RealCID END) | T2 |
| 190 | TradersWithProfitStocks | BI_DB_dbo.BI_DB_V_DDR_PnL | count(DISTINCT CASE WHEN DailyPnLStocks > 0 THEN RealCID END) | T2 |
| 191 | TradersWithLossStocks | BI_DB_dbo.BI_DB_V_DDR_PnL | count(DISTINCT CASE WHEN DailyPnLStocks < 0 THEN RealCID END) | T2 |
| 192 | CompensationOtherAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationOtherAmount | SUM(CompensationOtherAmount) | T2 |
| 193 | CompensationPIWithCashoutAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationPIWithCashoutAmount | SUM(CompensationPIWithCashoutAmount) | T2 |
| 194 | CompensationRAFInvitedInvitingAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationRAFInvitedInvitingAmount | SUM(CompensationRAFInvitedInvitingAmount) | T2 |
| 195 | CompensationToAffiliateNoCashoutAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationToAffiliateNoCashoutAmount | SUM(CompensationToAffiliateNoCashoutAmount) | T2 |
| 196 | CompensationToAffiliateWithCashoutAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationToAffiliateWithCashoutAmount | SUM(CompensationToAffiliateWithCashoutAmount) | T2 |
| 197 | EditStoplossAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.EditStoplossAmount | SUM(EditStoplossAmount) | T2 |
| 198 | InvestmentAmountInNewTradesAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.InvestmentAmountInNewTradesAmount | SUM(InvestmentAmountInNewTradesAmount) | T2 |
| 199 | InvestmentAmountClosedTradesAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.InvestmentAmountClosedTradesAmount | SUM(InvestmentAmountClosedTradesAmount) | T2 |
| 200 | NewCopyAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.NewCopyAmount | SUM(NewCopyAmount) | T2 |
| 201 | StopCopyAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.StopCopyAmount | SUM(StopCopyAmount) | T2 |
| 202 | AddToCopyAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.AddToCopyAmount | SUM(AddToCopyAmount) | T2 |
| 203 | RemoveFromCopyAmount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.RemoveFromCopyAmount | SUM(RemoveFromCopyAmount) | T2 |
| 204 | CompensationOtherCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationOtherCount | SUM(CompensationOtherCount) | T2 |
| 205 | CompensationPIWithCashoutCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationPIWithCashoutCount | SUM(CompensationPIWithCashoutCount) | T2 |
| 206 | CompensationRAFInvitedInvitingCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationRAFInvitedInvitingCount | SUM(CompensationRAFInvitedInvitingCount) | T2 |
| 207 | CompensationToAffiliateNoCashoutCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationToAffiliateNoCashoutCount | SUM(CompensationToAffiliateNoCashoutCount) | T2 |
| 208 | CompensationToAffiliateWithCashoutCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.CompensationToAffiliateWithCashoutCount | SUM(CompensationToAffiliateWithCashoutCount) | T2 |
| 209 | EditStoplossCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.EditStoplossCount | SUM(EditStoplossCount) | T2 |
| 210 | NewTradesCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.NewTradesCount | SUM(NewTradesCount) | T2 |
| 211 | ClosedTradesCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.ClosedTradesCount | SUM(ClosedTradesCount) | T2 |
| 212 | NewCopyCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.NewCopyCount | SUM(NewCopyCount) | T2 |
| 213 | StopCopyCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.StopCopyCount | SUM(StopCopyCount) | T2 |
| 214 | AddToCopyCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.AddToCopyCount | SUM(AddToCopyCount) | T2 |
| 215 | RemoveFromCopyCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.RemoveFromCopyCount | SUM(RemoveFromCopyCount) | T2 |
| 216 | BonusComp | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.BonusComp | SUM(BonusComp) | T2 |
| 217 | PublishCommentCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions | count(DISTINCT CASE when PublishCommentCount > 0 THEN RealCID END) | T2 |
| 218 | PublishLikeCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions | count(DISTINCT CASE when PublishLikeCount > 0 THEN RealCID END) | T2 |
| 219 | PublishPostCount | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions | count(DISTINCT CASE when PublishPostCount > 0 THEN RealCID END) | T2 |
| 220 | PnLAdjustment | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions.PnLAdjustment | SUM(PnLAdjustment) | T2 |
| 221 | NewCopyUsers | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions | count(DISTINCT CASE WHEN NewCopyCount > 0 THEN RealCID END ) | T2 |
| 222 | DepositorsLoggedIn | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions | count(DISTINCT CASE WHEN DepositorsLoggedIn > 0 THEN RealCID END ) | T2 |
| 223 | RevenueGenerators | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown | Outer `SUM` of per-customer `MAX(CASE WHEN TotalRevenue <> 0 THEN 1 ELSE 0 END)` on **`Date = @edate`** | T2 |
| 224 | ActiveOpened | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown | Outer `SUM` of per-customer `MAX(CASE WHEN ActiveOpened = 1 THEN 1 ELSE 0 END)` on **`Date = @edate`** | T2 |
| 225 | ActiveOpenedRealStocks | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.ActiveOpenedRealStocks | Outer `SUM` of per-customer `MAX(CASE WHEN ActiveOpenedRealStocks = 1 THEN 1 ELSE 0 END)` on **`Date = @edate`** | T2 |
| 226 | ActiveOpenedCFDStocks | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.ActiveOpenedCFDStocks | Outer `SUM` of per-customer `MAX(CASE WHEN ActiveOpenedCFDStocks = 1 THEN 1 ELSE 0 END)` on **`Date = @edate`** | T2 |
| 227 | ActiveOpenedRealETF | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.ActiveOpenedRealETF | Outer `SUM` of per-customer `MAX(CASE WHEN ActiveOpenedRealETF = 1 THEN 1 ELSE 0 END)` on **`Date = @edate`** | T2 |
| 228 | ActiveOpenedCFDETF | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.ActiveOpenedCFDETF | Outer `SUM` of per-customer `MAX(CASE WHEN ActiveOpenedCFDETF = 1 THEN 1 ELSE 0 END)` on **`Date = @edate`** | T2 |
| 229 | ActiveOpenedRealCrypto | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.ActiveOpenedRealCrypto | Outer `SUM` of per-customer `MAX(CASE WHEN ActiveOpenedRealCrypto = 1 THEN 1 ELSE 0 END)` on **`Date = @edate`** | T2 |
| 230 | ActiveOpenedCFDCrypto | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.ActiveOpenedCFDCrypto | Outer `SUM` of per-customer `MAX(CASE WHEN ActiveOpenedCFDCrypto = 1 THEN 1 ELSE 0 END)` on **`Date = @edate`** | T2 |
| 231 | ActiveOpenedReal | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.ActiveOpenedReal | Outer `SUM` of per-customer `MAX(CASE WHEN ActiveOpenedReal = 1 THEN 1 ELSE 0 END)` on **`Date = @edate`** | T2 |
| 232 | ActiveOpenedCFD | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.ActiveOpenedCFD | Outer `SUM` of per-customer `MAX(CASE WHEN ActiveOpenedCFD = 1 THEN 1 ELSE 0 END)` on **`Date = @edate`** | T2 |
| 233 | ActiveOpenedCopy | BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown.ActiveOpenedCopy | Outer `SUM` of per-customer `MAX(CASE WHEN ActiveOpenedCopy = 1 THEN 1 ELSE 0 END)` on **`Date = @edate`** | T2 |
| 234 | PnLAdjusted | BI_DB_dbo.BI_DB_V_DDR_PnL, BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions | `SUM(ISNULL(dpnl.DailyTotalPnL,0) + ISNULL(dnrev.PnLAdjustment,0))` with PnL/non-rev rows **`Date = @edate`** | T2 |
| 235 | ZeroPnLAdjusted | BI_DB_dbo.BI_DB_V_DDR_PnL, BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions, BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown | `SUM(ISNULL(DailyTotalPnL,0) + ISNULL(PnLAdjustment,0) + ISNULL(Commission,0))` all on **`Date = @edate`** | T2 |
| 236 | ZeroPnLCopy | BI_DB_dbo.BI_DB_V_DDR_PnL, BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown | `SUM(ISNULL(DailyPnLCopy,0) + ISNULL(CommissionCopy,0))` on **`Date = @edate`** | T2 |
| 237 | ZeroPnLStocks | BI_DB_dbo.BI_DB_V_DDR_PnL, BI_DB_dbo.BI_DB_V_DDR_Revenue_Breakdown | `SUM(ISNULL(DailyPnLStocks,0) + ISNULL(CommissionStocks,0))` on **`Date = @edate`** | T2 |
| 238 | GlobalCashoutsAdjusted | BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Actions, BI_DB_dbo.BI_DB_V_DDR_MIMO | `SUM(ISNULL(GlobalWithdraw_ExclRedeem,0) - ISNULL(CompensationToAffiliateWithCashoutAmount,0) + ISNULL(CompensationPIWithCashoutAmount,0))` on **`Date = @edate`** | T2 |

## 5. Change History (only if found in SQL comments)


| Date | Author | Description |
|------|--------|-------------|
| 2024-12-03 | Guy M | added a couple of internal TP metrics on Gili's requeust |
| 2024-12-05 | Guy M | added externalTPdepositors TP metrics on Gili's requeust |
| 2024-12-09 | Guy M | added CashedOutTP TP metric |
| 2025-03-18 | Guy M | added new revenue metrics (staking, c2f, share lending) |
| 2025-05-06 | Guy M | added ticketfeebypercent |
| 2025-11-03 | Guy M | added bonus comp and some pnlmetrics |


---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
