# Preflight report — UC ALTER deployment queue

- **Run date:** 2026-05-03
- **Mode:** APPLY (writes)
- **Files scanned:** 311
- **Files auto-fixed:** 64
- **Files BLOCKED:** 0

Blocks = encoding errors, prose-as-target, bogus `Tier N` as column,
unterminated COMMENT literal, or missing `;`. Auto-fixes = mojibake / unicode
punctuation normalization and backtick-wrapping of unsafe column tokens.

## Auto-fixed files

### `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Fact_Revenue_Generating_Actions.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_First5Actions.alter.sql`

- **Identifier backtick wrap**: 4 change(s)
    - line 58: `Traded_FX/Commodities/Indices -> `Traded_FX/Commodities/Indices``
    - line 59: `Traded_Stocks/ETFs -> `Traded_Stocks/ETFs``
    - line 146: `Traded_FX/Commodities/Indices -> `Traded_FX/Commodities/Indices``
    - line 147: `Traded_Stocks/ETFs -> `Traded_Stocks/ETFs``

### `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_MarketingDailyRawData.alter.sql`

- **Identifier backtick wrap**: 2 change(s)
    - line 34: `Organic/Paid -> `Organic/Paid``
    - line 86: `Organic/Paid -> `Organic/Paid``

### `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_OPS_Fraud_Alert_Analysis.alter.sql`

- **Identifier backtick wrap**: 2 change(s)
    - line 44: `2FA -> `2FA``
    - line 102: `2FA -> `2FA``

### `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_PLTV.alter.sql`

- **Identifier backtick wrap**: 2 change(s)
    - line 27: `MaxQ33/MaxQ35 -> `MaxQ33/MaxQ35``
    - line 37: `MaxQ33/MaxQ35 -> `MaxQ33/MaxQ35``

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/DateToDateID.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_AUM_OptionsPlatform.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_DDR_Aggregation_MoM.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_DDR_Aggregation_ThisMonth.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_DDR_Aggregation_ThisQuarter.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_DDR_Aggregation_ThisWeek.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_DDR_Aggregation_ThisYear.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_DDR_Aggregation_Yesterday.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_DDR_Aggregation_YoY.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Instrument_Conversion_Rates.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Instrument_Snapshot_Enriched.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_MIMO_First_Deposit_All_Platforms.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_MIMO_Options_Platform.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_PnL_Single_Day.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Population_Active_Traders.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Population_Balance_Only_Accounts.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Population_First_Time_Funded.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Population_First_Trading_Action.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Population_Funded.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Population_OTD_DateRange.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Population_Portfolio_Only.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_AdminFee.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_CashoutFee_ExcludeRedeem.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_CashoutFee_IncRedeem.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_Commissions.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_ConversionFee.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_ConversionFee_WithPositionData.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_CryptoToFiat_C2F.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_Dividend.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_DormantFee.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_FullCommissions.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_InterestFee.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_OptionsPlatform.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_RolloverFee.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_SDRT.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_Share_Lending.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_SpotAdjustFee.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_StakingFee.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_TicketFee.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_TicketFeeByPercent.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_Total.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_Trading_Fees_Breakdown.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_Trading_Instrument_Level.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Revenue_TransferCoinFee.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Search_Functions.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Trading_Volume.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_Trading_Volume_PositionLevel.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_ContactType.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_CountryIPAnonymousProxyType.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.alter.sql`

- **Identifier backtick wrap**: 4 change(s)
    - line 119: `2FA -> `2FA``
    - line 227: `2FA -> `2FA``
    - line 356: `2FA -> `2FA``
    - line 464: `2FA -> `2FA``

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument_Snapshot.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PositionHedgeServerChangeLog_Snapshot.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CustomerAction.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_Deposit_State.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotEquity.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/DWH_dbo/Views/V_Fact_SnapshotCustomer.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/DWH_dbo/Views/V_Fact_SnapshotCustomer_FromDateID.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/DWH_dbo/Views/V_Fact_SnapshotEquity_FromDateID.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

## Clean files: 247
