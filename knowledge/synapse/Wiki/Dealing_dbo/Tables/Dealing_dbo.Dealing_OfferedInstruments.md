# Dealing_dbo.Dealing_OfferedInstruments

## 1. Overview
Daily snapshot of all tradable instruments offered on the eToro platform, capturing pricing, exchange info, trading permissions, and identification codes (ISIN, CUSIP, Bloomberg ticker).

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | Clustered (Date ASC) |
| **Row Count** | ~8M |
| **Date Range** | 2022-03-30 → present |
| **Grain** | One row per Date × InstrumentID |
| **Refresh** | Daily, via SP_OfferedInstruments |

## 2. Business Context
This table serves as a daily audit of which instruments are available for trading, their mid-day pricing, and their trading permissions (buy/sell/pending orders). It captures the instrument configuration as a point-in-time snapshot, enabling historical analysis of instrument availability and pricing. The Bloomberg ticker was added in SR-218489 (2023-11-22).

**Author**: Jenia (created 2021-10-25).

## 3. Elements

| Column | Data Type | Nullable | Description | Tier | Source |
|--------|-----------|----------|-------------|------|--------|
| Date | date | Yes | Snapshot date | T2 | SP_OfferedInstruments: `@Date` |
| InstrumentID | int | Yes | eToro instrument identifier | T2 | SP_OfferedInstruments: `TI.InstrumentID` |
| InstrumentDisplayName | varchar(100) | Yes | Client-facing display name | T2 | SP_OfferedInstruments: `InstrumentDisplayName` |
| Symbol | varchar(50) | Yes | Trading symbol (e.g., AAPL) | T2 | SP_OfferedInstruments: `Symbol` |
| SymbolFull | varchar(50) | Yes | Full symbol with exchange suffix (e.g., AAPL.NQ) | T2 | SP_OfferedInstruments: `SymbolFull` |
| Occurred | datetime | Yes | Price timestamp from Fact_CurrencyPriceWithSplit | T2 | SP_OfferedInstruments: `HP.Occurred` |
| Bid | float | Yes | Spreaded bid price (client-visible). Formula: `BidSpreaded` | T2 | SP_OfferedInstruments: from Fact_CurrencyPriceWithSplit |
| Ask | float | Yes | Spreaded ask price (client-visible). Formula: `AskSpreaded` | T2 | SP_OfferedInstruments |
| LastPrice | float | Yes | Mid-price. Formula: `(BidSpreaded + AskSpreaded) / 2` | T2 | SP_OfferedInstruments |
| Exchange | varchar(50) | Yes | Exchange name (e.g., NASDAQ, NYSE) | T2 | SP_OfferedInstruments: `Exchange` |
| ISINCode | varchar(50) | Yes | International Securities Identification Number | T2 | SP_OfferedInstruments: `ISINCode` |
| CUSIP | varchar(50) | Yes | Committee on Uniform Securities Identification Procedures code | T2 | SP_OfferedInstruments: `CUSIP` |
| BuyCurrencyID | int | Yes | Currency of the buy side of the instrument | T2 | SP_OfferedInstruments: `TI.BuyCurrencyID` |
| SellCurrencyID | int | Yes | Currency of the sell side of the instrument | T2 | SP_OfferedInstruments: `TI.SellCurrencyID` |
| SellCurrency | varchar(20) | Yes | Sell-side currency abbreviation | T2 | SP_OfferedInstruments: `SellCurrency` |
| ExchangeID | int | Yes | Exchange identifier | T2 | SP_OfferedInstruments: `dei.ExchangeID` from Dim_ExchangeInfo |
| InstrumentTypeID | int | Yes | Instrument type code (5=Stocks, 6=ETF, 1=FX, etc.) | T2 | SP_OfferedInstruments: `InstrumentTypeID` |
| PipDifferenceThreshold | int | Yes | Maximum pip difference threshold for price matching | T2 | SP_OfferedInstruments: `PipDifferenceThreshold` |
| PRECISION | int | Yes | Decimal precision for the instrument | T2 | SP_OfferedInstruments: `TI.Precision` |
| AllowBuy | int | Yes | 1=buy orders allowed, 0=blocked | T2 | SP_OfferedInstruments: `TI.AllowBuy` |
| AllowSell | int | Yes | 1=sell orders allowed, 0=blocked | T2 | SP_OfferedInstruments: `TI.AllowSell` |
| AllowPendingOrders | int | Yes | 1=pending (limit) orders allowed | T2 | SP_OfferedInstruments: `AllowPendingOrders` |
| AllowExitOrder | int | Yes | 1=exit orders allowed | T2 | SP_OfferedInstruments: `AllowExitOrder` |
| AllowEntryOrders | int | Yes | 1=entry orders allowed | T2 | SP_OfferedInstruments: `AllowEntryOrders` |
| ISINCountryCode | varchar(20) | Yes | 2-letter country code from the ISIN | T2 | SP_OfferedInstruments: `ISINCountryCode` |
| VisibleInternallyOnly | int | Yes | 1=internal instrument (not shown to clients). Filter: only VisibleInternallyOnly=0 instruments are included | T2 | SP_OfferedInstruments |
| UpdateDate | datetime | Yes | Row write timestamp | T2 | SP_OfferedInstruments: `GETDATE()` |
| MaxPositionUnits | int | Yes | Maximum allowed position units | T2 | SP_OfferedInstruments: from `External_Etoro_Trade_ProviderToInstrument` |
| MinPositionAmount | int | Yes | Minimum required position amount | T2 | SP_OfferedInstruments |
| BloombergTicker | varchar(100) | Yes | Bloomberg terminal ticker. Source: `External_Etoro_Trade_LiquidityProviderContracts` where LiquidityProviderID=50 | T2 | SP_OfferedInstruments: added SR-218489 |

## 4. Relationships
| Related Object | Relationship | Join Condition |
|----------------|--------------|----------------|
| DWH_dbo.Fact_CurrencyPriceWithSplit | Pricing source | InstrumentID, OccurredDateID=@DateID |
| DWH_dbo.Dim_Instrument | Instrument metadata | InstrumentID |
| DWH_dbo.Dim_ExchangeInfo | Exchange lookup | ExchangeDescription=TI.Exchange |
| Dealing_staging.External_Etoro_Trade_ProviderToInstrument | Tradability + position limits | InstrumentID, Tradable=1 |
| Dealing_staging.External_Etoro_Trade_LiquidityProviderContracts | Bloomberg ticker | InstrumentID, LiquidityProviderID=50 |

## 5. ETL Details
| Property | Value |
|----------|-------|
| **Primary SP** | `Dealing_dbo.SP_OfferedInstruments` |
| **Parameters** | `@Date DATE` |
| **Load Pattern** | DELETE + INSERT for @Date |
| **Filters** | `Tradable=1 AND VisibleInternallyOnly=0` — only externally visible, tradable instruments |

## 6. Data Lifecycle
- **Retention**: No automated cleanup
- **Volume**: ~5500-6000 instruments per day

## 7. Known Gaps
- Bloomberg ticker is only populated for LiquidityProviderID=50 — other providers may use different tickers
- The Dim_ExchangeInfo join on ExchangeDescription (string) is fragile

## 8. Quality Score
**7.5/10** — Clean snapshot table with clear purpose. All columns directly mapped from known sources. Good instrument metadata coverage.
