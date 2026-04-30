# Trade.CheckValidInstruments

> Validates and stages all configuration data for a new financial instrument across 30+ tables, enforcing business rules for instrument types, ranges, currency pairs, futures metadata, and liquidity providers before delegating constraint checking to Trade.CheckValidInstrumentsConstrients.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID (instrument being onboarded) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CheckValidInstruments is the core validation and data preparation procedure for the eToro instrument onboarding pipeline. When a new trading instrument (stock, ETF, commodity, currency pair, index, or futures contract) is added to the platform, this procedure receives all of its metadata, fee schedules, liquidity provider mappings, and configuration parameters. It validates every input against business rules and lookup tables, then stages the data into global temporary tables (##Schema_Table) for downstream insertion.

Without this procedure, invalid instruments could be inserted into the system - for example, a futures contract missing its expiration date, a currency pair where buy and sell currencies are the same, or an instrument with an InstrumentID that already exists across any of 30+ configuration tables. Such errors would break trading, pricing, hedging, and fee calculations across the platform.

The data flow is: the caller (Trade.InsertInstrumentRealTable) invokes this procedure with all instrument parameters. CheckValidInstruments first converts 'null' strings to actual NULLs (the data comes from file loading via dbo.LoadInstrumentFile). It then runs ~25 validation checks. If all pass, it populates 25+ global ##temp tables with the instrument's configuration (either from the parameters directly or by copying from an existing template instrument via @CopyMainpropertiesFromInstrument). Finally, it calls Trade.CheckValidInstrumentsConstrients for foreign key and unique index validation before returning @isvalid=1.

---

## 2. Business Logic

### 2.1 Null String Normalization

**What**: Converts string 'null' values and empty strings to SQL NULL for all input parameters.

**Columns/Parameters Involved**: All 97 parameters

**Rules**:
- Parameters passed from file-loading (dbo.LoadInstrumentFile) may contain the literal string 'null' instead of SQL NULL
- Each parameter is normalized via `CASE WHEN LOWER(@param) = 'null' THEN NULL ELSE @param END`
- Some parameters additionally check for empty/whitespace strings via `REPLACE(@param, ' ', '') = ''`

### 2.2 Futures Instrument Validation

**What**: Enforces that futures contracts have all required metadata fields populated.

**Columns/Parameters Involved**: `@IsFuture`, `@Multiplier`, `@MinimalTick`, `@LastTradingDateTime`, `@ExpirationDateTime`, `@SettlementTime`, `@IndexPointValue`, `@SettlementMethod`, `@UnitOfMeasure`, `@CFICode`

**Rules**:
- @IsFuture cannot be NULL (THROW 51000)
- When @IsFuture=1, ALL futures fields must be non-NULL: Multiplier, MinimalTick, LastTradingDateTime, ExpirationDateTime, SettlementTime, IndexPointValue, SettlementMethod, UnitOfMeasure
- A cross-check (@CheckIsFuture) verifies all 8 futures fields are present when @IsFuture=1
- Futures dates must be in the future (LastTradingDateTime > GETDATE(), ExpirationDateTime > GETDATE())
- Multiplier, MinimalTick, IndexPointValue must be > 0
- CFICode must be exactly 6 uppercase alphabetic characters
- SettlementMethod must exist in Dictionary.SettlementMethodValues
- UnitOfMeasure must exist in Dictionary.UnitOfMeasure
- Futures can only copy from instrument 999 or 998
- Futures copy instrument must have LeverageID=1

**Diagram**:
```
@IsFuture = 1?
  |-- YES --> Validate all 8 futures fields present
  |           Validate CFICode (6 alpha chars)
  |           Validate SettlementMethod (Dictionary lookup)
  |           Validate UnitOfMeasure (Dictionary lookup)
  |           Validate dates in future
  |           Validate positive Multiplier/MinimalTick/IndexPointValue
  |           Validate InitialMargin + StopLossMargin > 0
  |           @SettlementTypeID = 4
  |-- NO  --> @SettlementTypeID = 0, skip futures validations
```

### 2.3 InstrumentID Range Validation

**What**: Enforces that InstrumentID falls in the correct numeric range for its instrument type.

**Columns/Parameters Involved**: `@InstrumentID`, `@InstrumentTypeID`

**Rules**:
- InstrumentID 1000-9999: Only InstrumentTypeID NOT IN (5, 6) - i.e., NOT Fiat/Crypto currencies
- InstrumentID 100000-101000: Only InstrumentTypeID = 10
- InstrumentID 1-1000: Only InstrumentTypeID IN (5, 6, 10) - currencies and type-10 instruments
- InstrumentID cannot be negative
- InstrumentID must not already exist in ANY of 30+ tables (cross-table uniqueness check)

### 2.4 Currency Pair Validation

**What**: Ensures currency pair consistency for the instrument.

**Columns/Parameters Involved**: `@BuyCurrencyID`, `@SellCurrencyID`, `@InstrumentID`, `@InstrumentTypeID`

**Rules**:
- BuyCurrencyID cannot equal SellCurrencyID (same-currency pair forbidden)
- The Buy/Sell combination must not already exist in Trade.Instrument (neither direct nor reversed)
- For InstrumentTypeID IN (5, 6) - currency instruments: BuyCurrencyID must equal InstrumentID

### 2.5 Copy-From-Instrument Logic

**What**: Allows a new instrument to inherit configurations from an existing template instrument.

**Columns/Parameters Involved**: `@CopyMainpropertiesFromInstrument`

**Rules**:
- The copy-from instrument must exist in Trade.InstrumentMetaData
- For non-futures (@IsFuture=0): the copy-from instrument must have the same InstrumentTypeID
- For futures (@IsFuture=1): copy-from must be instrument 999 or 998
- Multiple configuration tables can independently copy from the template: leverage, lot counts, spreads, HBC configurations, instrument boundaries, etc.
- When copy source is -1 or doesn't exist for a specific table, default values are used instead

### 2.6 Market Range and Volatility Validation

**What**: Validates market range and volatility threshold configurations.

**Columns/Parameters Involved**: `@MarketRangeValidationType`, `@MarketRangePercentage`, `@MarketRange`, `@VolatilityThresholdTypeID`, `@VolatilityRatePercentage`, `@VolatilityRateInPips`

**Rules**:
- MarketRangeValidationType=1 (pips): @MarketRange must not be NULL
- MarketRangeValidationType=2 (percentage): @MarketRangePercentage must not be NULL, must be 0-100
- Cannot have both MarketRange and MarketRangePercentage set simultaneously
- Cannot have both empty simultaneously
- VolatilityThresholdTypeID=1 (pips): @VolatilityRateInPips must be non-zero
- VolatilityThresholdTypeID=2 (percentage): @VolatilityRatePercentage must be non-zero and 0-100
- Cannot have both volatility rate types set simultaneously

### 2.7 Global Temp Table Staging

**What**: Populates 25+ global ##temp tables with the new instrument's configuration data for downstream insertion.

**Columns/Parameters Involved**: All parameters

**Rules**:
- Each config table gets a ##temp counterpart (e.g., ##Trade_Instrument, ##Trade_InstrumentMetaData)
- Checks if the instrument already exists in each production table before staging (IF NOT EXISTS pattern)
- For each table, either uses provided parameter values or copies from the template instrument
- Liquidity provider contracts are created from up to 10 provider parameter slots, validated against Trade.LiquidityProviders
- Spread data supports two paths: default simple spread or copy from template with group mapping
- After staging, calls Trade.CheckValidInstrumentsConstrients for FK/index validation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Name | VARCHAR(50) | NO | - | CODE-BACKED | Display name of the instrument (e.g., "Apple Inc."). Used for InstrumentMetaData.CompanyInfo and DisplayName. Converted from 'null' string if needed. |
| 2 | @ISINCode | VARCHAR(30) | NO | - | CODE-BACKED | International Securities Identification Number. First 2 characters extracted as ISINCountryCode. Stored in Trade.InstrumentMetaData. |
| 3 | @UnitMargin | INT | NO | - | CODE-BACKED | Price of 1 unit in the market in USD. Used in Trade.ProviderToInstrument for margin calculations. |
| 4 | @InstrumentID | INT | NO | - | CODE-BACKED | Unique identifier for the new instrument. Validated for uniqueness across 30+ tables, range correctness per InstrumentTypeID, and non-negative value. |
| 5 | @BuyCurrencyID | INT | NO | - | CODE-BACKED | The buy-side currency for the instrument pair. Must differ from @SellCurrencyID. For currency instruments (type 5,6), must equal @InstrumentID. Validated against Dictionary.Currency. |
| 6 | @SellCurrencyID | INT | NO | - | CODE-BACKED | The sell-side currency for the instrument pair. Must differ from @BuyCurrencyID. Buy/Sell combination must be unique in Trade.Instrument. |
| 7 | @CopyMainpropertiesFromInstrument | INT | NO | - | CODE-BACKED | InstrumentID of the template instrument to copy configurations from. Must exist in Trade.InstrumentMetaData. For futures: must be 999 or 998. For non-futures: must match InstrumentTypeID. |
| 8 | @SymbolFull | VARCHAR(50) | NO | - | CODE-BACKED | Full trading symbol (e.g., "AAPL"). Stored in Trade.InstrumentMetaData.SymbolFull and used as PresentationCode suffix in ProviderToInstrument. |
| 9 | @Abbreviation | VARCHAR(20) | NO | - | CODE-BACKED | Short abbreviation for the instrument/currency. Used in Dictionary.Currency when creating a new currency record. |
| 10 | @DisplayName | VARCHAR(100) | NO | - | CODE-BACKED | User-facing display name. Stored in InstrumentMetaData.InstrumentDisplayName. |
| 11 | @ExchangeID | INT | NO | - | CODE-BACKED | Exchange where the instrument trades. Cannot be NULL. Validated against Dictionary.ExchangeInfo. Used to resolve exchange description for InstrumentMetaData. |
| 12 | @StocksIndustryID | INT | NO | - | CODE-BACKED | Industry classification. Required (non-NULL) for InstrumentTypeID=5 (stocks). Must be NULL for non-stock types. Validated against Dictionary.StocksIndustry.IndustryID. |
| 13 | @IsMajor | BIT | NO | - | CODE-BACKED | Whether this is a major/high-profile instrument. Stored in Trade.Instrument.IsMajor. |
| 14 | @IsRealAsset | INT | NO | - | CODE-BACKED | Whether the instrument represents real asset ownership (not CFD). Must be 0 or 1. When 1: InstrumentTypeID must be 5, 6, or 10 (or IsFuture=1). Determines SettledBuyMaxLeverage in ProviderToInstrument. |
| 15 | @CurrencyTypeID | INT | NO | - | CODE-BACKED | Type of currency. Validated against Dictionary.CurrencyType. Used when creating new Dictionary.Currency record. |
| 16 | @PipDifferenceThreshold | BIGINT | NO | - | CODE-BACKED | Threshold for pip difference alerting in price monitoring. Stored in Trade.Instrument and Price OMPD threshold tables. |
| 17 | @MaxPositionUnits | DECIMAL(18,4) | NO | - | CODE-BACKED | Maximum position size in units. Stored in Trade.ProviderToInstrument.MaxPositionUnits. |
| 18 | @Precision | TINYINT | NO | - | CODE-BACKED | Decimal precision for rate display (1-6). Validated to be in range. Used in ProviderToInstrument.Precision and AboveDollarPrecision. |
| 19 | @InstrumentTypeSubCategoryID | INT | NO | - | CODE-BACKED | Sub-category within the instrument type. Stored in Trade.InstrumentMetaData.InstrumentTypeSubCategoryID. |
| 20 | @MinOrderSizeForExecutionInEToroUnits | DECIMAL(16,2) | NO | - | CODE-BACKED | Minimum order size for execution in eToro units. Stored in Hedge.InstrumentConfiguration. |
| 21 | @HBCDealSizeThresholdAlertInEToroUnits | INT | NO | - | CODE-BACKED | HBC (Hedging/Broker Connection) deal size alert threshold in eToro units. Triggers alert when exceeded. Stored in Hedge.InstrumentConfiguration. |
| 22 | @HBCMaxDealSizeThresholdRejectInEToroUnits | INT | NO | - | CODE-BACKED | HBC maximum deal size rejection threshold. Orders exceeding this are rejected. Stored in Hedge.InstrumentConfiguration and Hedge.HBCAccountConfiguration.MaxOrderSizeInEToroUnits. |
| 23 | @ManualMaxDealSizeInEToroUnits | INT | NO | - | CODE-BACKED | Maximum deal size for manual (non-automated) orders in eToro units. Stored in Hedge.InstrumentConfiguration. |
| 24 | @InstrumentTypeID | INT | NO | - | CODE-BACKED | The instrument type classification. Key values: 1=Forex (Unit=1000), 5=Fiat Currency (InstrumentID 1-1000, BuyCurrencyID must equal InstrumentID), 6=Crypto Currency (same range rules as 5), 10=Special (InstrumentID 100000-101000). Determines range validation, fee defaults, and trade behavior. |
| 25 | @NonLeveragedSellEndOfWeekFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Weekend holding fee for non-leveraged sell positions. Stored in Trade.InstrumentToFeeConfigV2. |
| 26 | @NonLeveragedBuyEndOfWeekFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Weekend holding fee for non-leveraged buy positions. Stored in Trade.InstrumentToFeeConfigV2. |
| 27 | @NonLeveragedBuyOverNightFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Overnight holding fee for non-leveraged buy positions. Stored in Trade.InstrumentToFeeConfigV2. |
| 28 | @NonLeveragedSellOverNightFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Overnight holding fee for non-leveraged sell positions. Stored in Trade.InstrumentToFeeConfigV2. |
| 29 | @LeveragedSellEndOfWeekFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Weekend holding fee for leveraged sell positions. Stored in Trade.InstrumentToFeeConfigV2. |
| 30 | @LeveragedBuyEndOfWeekFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Weekend holding fee for leveraged buy positions. Stored in Trade.InstrumentToFeeConfigV2. |
| 31 | @LeveragedBuyOverNightFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Overnight holding fee for leveraged buy positions. Stored in Trade.InstrumentToFeeConfigV2. |
| 32 | @LeveragedSellOverNightFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Overnight holding fee for leveraged sell positions. Stored in Trade.InstrumentToFeeConfigV2. |
| 33 | @isvalid | BIT (OUTPUT) | NO | - | CODE-BACKED | Output flag: 1=all validations passed and data staged successfully, 0=validation failed. Checked by caller (InsertInstrumentRealTable) to decide whether to proceed with production inserts. |
| 34 | @PriceSourceID | INT | NO | - | CODE-BACKED | Price source for the instrument. Validated against Dictionary.PriceSourceName. Overridden by the copy-from instrument's PriceSourceID if copying. |
| 35 | @ShardID | INT | NO | - | CODE-BACKED | Database shard assignment. Value 8 is explicitly forbidden (THROW 51000). Stored in Trade.Instrument. |
| 36 | @Cusip | VARCHAR(500) | NO | - | CODE-BACKED | Committee on Uniform Securities Identification Procedures number. Stored in Trade.InstrumentMetaData.Cusip. |
| 37 | @LiquidityProviderID_1 | INT | NO | - | CODE-BACKED | Primary liquidity provider ID (slot 1). Validated against Trade.LiquidityProviders. Creates a contract in Trade.LiquidityProviderContracts. |
| 38 | @LiquidityProviderID_2 | INT | NO | - | CODE-BACKED | Liquidity provider ID slot 2. Same validation as slot 1. |
| 39 | @LiquidityProviderID_3 | INT | NO | - | CODE-BACKED | Liquidity provider ID slot 3. Same validation as slot 1. |
| 40 | @LiquidityProviderID_4 | INT | NO | - | CODE-BACKED | Liquidity provider ID slot 4. Same validation as slot 1. |
| 41 | @LiquidityProviderID_5 | INT | YES | NULL | CODE-BACKED | Liquidity provider ID slot 5. Optional. |
| 42 | @LiquidityProviderID_6 | INT | YES | NULL | CODE-BACKED | Liquidity provider ID slot 6. Optional. |
| 43 | @LiquidityProviderID_7 | INT | YES | NULL | CODE-BACKED | Liquidity provider ID slot 7. Optional. |
| 44 | @LiquidityProviderID_8 | INT | YES | NULL | CODE-BACKED | Liquidity provider ID slot 8. Optional. |
| 45 | @LiquidityProviderID_9 | INT | YES | NULL | CODE-BACKED | Liquidity provider ID slot 9. Optional. |
| 46 | @LiquidityProviderID_10 | INT | YES | NULL | CODE-BACKED | Liquidity provider ID slot 10. Optional. |
| 47 | @ProviderTicker_1 | VARCHAR(100) | NO | - | CODE-BACKED | Ticker symbol used by liquidity provider 1 for this instrument. Stored in Trade.LiquidityProviderContracts.Ticker. |
| 48 | @ProviderTicker_2 | VARCHAR(100) | NO | - | CODE-BACKED | Ticker symbol for liquidity provider 2. |
| 49 | @ProviderTicker_3 | VARCHAR(100) | NO | - | CODE-BACKED | Ticker symbol for liquidity provider 3. |
| 50 | @ProviderTicker_4 | VARCHAR(100) | NO | - | CODE-BACKED | Ticker symbol for liquidity provider 4. |
| 51 | @ProviderTicker_5 | VARCHAR(100) | YES | NULL | CODE-BACKED | Ticker symbol for liquidity provider 5. Optional. |
| 52 | @ProviderTicker_6 | VARCHAR(100) | YES | NULL | CODE-BACKED | Ticker symbol for liquidity provider 6. Optional. |
| 53 | @ProviderTicker_7 | VARCHAR(100) | YES | NULL | CODE-BACKED | Ticker symbol for liquidity provider 7. Optional. |
| 54 | @ProviderTicker_8 | VARCHAR(100) | YES | NULL | CODE-BACKED | Ticker symbol for liquidity provider 8. Optional. |
| 55 | @ProviderTicker_9 | VARCHAR(100) | YES | NULL | CODE-BACKED | Ticker symbol for liquidity provider 9. Optional. |
| 56 | @ProviderTicker_10 | VARCHAR(100) | YES | NULL | CODE-BACKED | Ticker symbol for liquidity provider 10. Optional. |
| 57 | @ProviderExchangeID_1 | INT | NO | - | CODE-BACKED | Exchange ID used by liquidity provider 1. Stored in Trade.LiquidityProviderContracts.ExchangeID. |
| 58 | @ProviderExchangeID_2 | INT | NO | - | CODE-BACKED | Exchange ID for liquidity provider 2. |
| 59 | @ProviderExchangeID_3 | INT | NO | - | CODE-BACKED | Exchange ID for liquidity provider 3. |
| 60 | @ProviderExchangeID_4 | INT | NO | - | CODE-BACKED | Exchange ID for liquidity provider 4. |
| 61 | @ProviderExchangeID_5 | INT | YES | NULL | CODE-BACKED | Exchange ID for liquidity provider 5. Optional. |
| 62 | @ProviderExchangeID_6 | INT | YES | NULL | CODE-BACKED | Exchange ID for liquidity provider 6. Optional. |
| 63 | @ProviderExchangeID_7 | INT | YES | NULL | CODE-BACKED | Exchange ID for liquidity provider 7. Optional. |
| 64 | @ProviderExchangeID_8 | INT | YES | NULL | CODE-BACKED | Exchange ID for liquidity provider 8. Optional. |
| 65 | @ProviderExchangeID_9 | INT | YES | NULL | CODE-BACKED | Exchange ID for liquidity provider 9. Optional. |
| 66 | @ProviderExchangeID_10 | INT | YES | NULL | CODE-BACKED | Exchange ID for liquidity provider 10. Optional. |
| 67 | @ProviderRateID_1 | INT | NO | - | CODE-BACKED | Rate conversion factor ID for liquidity provider 1. Stored in Trade.LiquidityProviderContracts.RateConversionFactor. |
| 68 | @ProviderRateID_2 | INT | NO | - | CODE-BACKED | Rate conversion factor ID for liquidity provider 2. |
| 69 | @ProviderRateID_3 | INT | NO | - | CODE-BACKED | Rate conversion factor ID for liquidity provider 3. |
| 70 | @ProviderRateID_4 | INT | NO | - | CODE-BACKED | Rate conversion factor ID for liquidity provider 4. |
| 71 | @ProviderRateID_5 | INT | YES | NULL | CODE-BACKED | Rate conversion factor ID for liquidity provider 5. Optional. |
| 72 | @ProviderRateID_6 | INT | YES | NULL | CODE-BACKED | Rate conversion factor ID for liquidity provider 6. Optional. |
| 73 | @ProviderRateID_7 | INT | YES | NULL | CODE-BACKED | Rate conversion factor ID for liquidity provider 7. Optional. |
| 74 | @ProviderRateID_8 | INT | YES | NULL | CODE-BACKED | Rate conversion factor ID for liquidity provider 8. Optional. |
| 75 | @ProviderRateID_9 | INT | YES | NULL | CODE-BACKED | Rate conversion factor ID for liquidity provider 9. Optional. |
| 76 | @ProviderRateID_10 | INT | YES | NULL | CODE-BACKED | Rate conversion factor ID for liquidity provider 10. Optional. |
| 77 | @VisibleInternallyOnly | INT | NO | - | CODE-BACKED | Whether the instrument is visible only to internal eToro users and not to retail clients. Stored in Trade.ProviderToInstrument.VisibleInternallyOnly. |
| 78 | @MarketRangeValidationType | TINYINT | NO | - | CODE-BACKED | How market range is measured: 1=Pips (requires @MarketRange), 2=Percentage (requires @MarketRangePercentage). Stored in Trade.ProviderToInstrument. |
| 79 | @MarketRangePercentage | DECIMAL(5,2) | YES | NULL | CODE-BACKED | Market range as a percentage (0-100). Required when @MarketRangeValidationType=2. Cannot coexist with @MarketRange. Stored in Trade.ProviderToInstrument. |
| 80 | @MarketRange | INT | YES | NULL | CODE-BACKED | Market range in pips. Required when @MarketRangeValidationType=1. Cannot coexist with @MarketRangePercentage. Stored in Trade.ProviderToInstrument. |
| 81 | @VolatilityThresholdTypeID | INT | NO | - | CODE-BACKED | How volatility threshold is measured: 1=Pips (requires @VolatilityRateInPips), 2=Percentage (requires @VolatilityRatePercentage). Controls Trade.InstrumentVolatilityThresholdType and FeatureThresholdValues. |
| 82 | @VolatilityRatePercentage | INT | YES | NULL | CODE-BACKED | Volatility rate as percentage (0-100). Required when @VolatilityThresholdTypeID=2. Cannot coexist with @VolatilityRateInPips. |
| 83 | @VolatilityRateInPips | DECIMAL(5,2) | YES | NULL | CODE-BACKED | Volatility rate in pips. Required when @VolatilityThresholdTypeID=1. Cannot coexist with @VolatilityRatePercentage. |
| 84 | @IsFuture | INT | NO | - | CODE-BACKED | Whether this is a futures contract: 1=Futures, 0=Non-futures. Cannot be NULL. Triggers extensive futures-specific validations. Sets @SettlementTypeID=4 for futures, 0 for non-futures. |
| 85 | @Multiplier | DECIMAL(20,10) | YES | NULL | CODE-BACKED | Contract multiplier for futures instruments. Must be > 0 when @IsFuture=1. Stored in Trade.FuturesMetaData. |
| 86 | @MinimalTick | DECIMAL(20,10) | YES | NULL | CODE-BACKED | Minimum price movement for futures instruments. Must be > 0 when @IsFuture=1. Stored in Trade.FuturesMetaData. |
| 87 | @LastTradingDateTime | DATETIME | YES | NULL | CODE-BACKED | Last trading date/time for futures contracts. Must be in the future when @IsFuture=1. Stored in Trade.FuturesMetaData. |
| 88 | @ExpirationDateTime | DATETIME | YES | NULL | CODE-BACKED | Contract expiration date/time for futures. Must be in the future when @IsFuture=1. Stored in Trade.FuturesMetaData. |
| 89 | @SettlementTime | TIME(7) | YES | NULL | CODE-BACKED | Daily settlement time for futures contracts. Required when @IsFuture=1. Stored in Trade.FuturesMetaData. |
| 90 | @IndexPointValue | DECIMAL(20,10) | YES | NULL | CODE-BACKED | Value of one index point for futures. Must be > 0 when @IsFuture=1. Zero values are converted to NULL. Stored in Trade.FuturesMetaData. |
| 91 | @StopLossMarginInAssetCurrency | DECIMAL(16,8) | YES | NULL | CODE-BACKED | Stop-loss margin requirement in the asset's currency for futures. Must be > 0 when @IsFuture=1. Stored in Trade.ProviderToInstrument. |
| 92 | @InitialMarginInAssetCurrency | DECIMAL(16,8) | YES | NULL | CODE-BACKED | Initial margin requirement in the asset's currency for futures. Must be > 0 when @IsFuture=1. Stored in Trade.ProviderToInstrument. |
| 93 | @CFICode | VARCHAR(6) | NO | - | CODE-BACKED | Classification of Financial Instruments code (ISO 10962). Must be exactly 6 uppercase alphabetic characters when @IsFuture=1. Stored in Trade.InstrumentMetaData. |
| 94 | @SettlementMethod | TINYINT | NO | - | CODE-BACKED | Physical or cash settlement method for futures. Validated against Dictionary.SettlementMethodValues when @IsFuture=1. Stored in Trade.FuturesMetaData. |
| 95 | @UnitOfMeasure | TINYINT | NO | - | CODE-BACKED | Unit of measure for the underlying commodity in futures. Validated against Dictionary.UnitOfMeasure when @IsFuture=1. Stored in Trade.FuturesMetaData. |
| 96 | @DifferenceThresholdType | INT | NO | - | CODE-BACKED | Type of price difference threshold for OMPD (Outlier Mid-Price Detection): determines which threshold (pips or percentage) is active. Stored in Price.OMPDActiveThreshold. |
| 97 | @PercentageDifferenceThreshold | DECIMAL(20,2) | NO | - | CODE-BACKED | Percentage-based price difference threshold for OMPD monitoring. Stored in Price.OMPDThresholdValues. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.FeatureThresholdValues | SELECT (existence) | Checks if instrument already has feature thresholds |
| @InstrumentID | Hedge.InstrumentConfiguration | SELECT (existence) | Checks if instrument already has hedge config |
| @InstrumentID | Price.InstrumentConfiguration | SELECT (existence) | Checks if instrument already has price config |
| @InstrumentID | Price.Instrument | SELECT (existence) | Checks if instrument exists in Price schema |
| @InstrumentID | Trade.InstrumentVolatilityThresholdType | SELECT (existence) | Checks volatility threshold config |
| @InstrumentID | Trade.Instrument | SELECT (existence + data) | Checks instrument existence, reads PriceServerID from copy source |
| @InstrumentID | Trade.InstrumentToFeeConfigV2 | SELECT (existence) | Checks fee config existence |
| @InstrumentID | Trade.TradonomiContracts | SELECT (existence + MAX) | Checks contracts and gets next ContractID |
| @InstrumentID | Trade.InstrumentImages | SELECT (existence + MAX) | Checks images and gets next ImageID |
| @InstrumentID | Trade.ActiveFeatureThreshold | SELECT (existence) | Checks feature threshold config |
| @InstrumentID | Trade.InstrumentSpread | SELECT (existence + data) | Checks spread existence and copies spread data |
| @InstrumentID | Trade.Spread | SELECT (existence + data) | Checks spread existence and copies spread data |
| @InstrumentID | Trade.ProviderToInstrument | SELECT (existence) | Checks provider config |
| @InstrumentID | Hedge.HBCAccountConfiguration | SELECT (existence + data) | Checks HBC config and copies from template |
| @InstrumentID | Trade.LiquidityProviderContracts | SELECT (existence + MAX) | Checks contracts and gets next ContractID |
| @InstrumentID | Hedge.ProviderUnitConversionRatio | SELECT (existence + data) | Checks unit conversion and copies from template |
| @InstrumentID | Hedge.InstrumentBoundaries | SELECT (existence + data) | Checks boundaries and copies from template |
| @InstrumentID | Trade.ProviderInstrumentToLeverage | SELECT (existence + data) | Checks leverage config and copies from template |
| @InstrumentID | Trade.ProviderInstrumentToLotCount | SELECT (existence + data) | Checks lot count config and copies from template |
| @InstrumentID | Trade.InstrumentMetaData | SELECT (existence + data) | Checks metadata, reads PriceSourceID and ContractExpire from copy source |
| @InstrumentID | Trade.UsAllowedInstruments | SELECT (existence) | Checks US-allowed instruments |
| @InstrumentID | Trade.InstrumentCusip | SELECT (existence) | Checks CUSIP existence |
| @InstrumentID | History.SplitRatio | SELECT (existence + MAX) | Checks split ratio and gets next ID |
| @InstrumentID | Trade.FuturesMetaData | SELECT (existence) | Checks futures metadata |
| @StocksIndustryID | Dictionary.StocksIndustry | SELECT (validation) | Validates industry ID exists |
| @CurrencyTypeID | Dictionary.CurrencyType | SELECT (validation) | Validates currency type exists |
| @ExchangeID | Dictionary.ExchangeInfo | SELECT (validation + data) | Validates exchange and gets description |
| @PriceSourceID | Dictionary.PriceSourceName | SELECT (validation) | Validates price source exists |
| @BuyCurrencyID | Dictionary.Currency | SELECT (existence) | Checks if currency needs to be created |
| @SettlementMethod | Dictionary.SettlementMethodValues | SELECT (validation) | Validates settlement method for futures |
| @UnitOfMeasure | Dictionary.UnitOfMeasure | SELECT (validation) | Validates unit of measure for futures |
| @LiquidityProviderID_* | Trade.LiquidityProviders | SELECT (validation) | Validates each liquidity provider ID |
| (staging) | Trade.SpreadGroup | JOIN | Validates spread group assignments |
| (error logging) | dbo.InsertInstrumentError | INSERT | Logs all validation errors |
| (split ratio) | dbo.PriceSplitRatio | INSERT via ##temp | Creates price split ratio record |
| @InstrumentID, @isvalid | Trade.CheckValidInstrumentsConstrients | EXEC | Delegates FK/index constraint validation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertInstrumentRealTable | EXEC | EXEC | Primary caller - the instrument onboarding pipeline procedure that passes all parameters and checks @isvalid after completion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CheckValidInstruments (procedure)
+-- Trade.CheckValidInstrumentsConstrients (procedure)
|     +-- dbo.InsertInstrumentError (table)
|     +-- sys catalog views (system)
+-- dbo.InsertInstrumentError (table)
+-- Dictionary.StocksIndustry (table)
+-- Dictionary.CurrencyType (table)
+-- Dictionary.ExchangeInfo (table)
+-- Dictionary.PriceSourceName (table)
+-- Dictionary.SettlementMethodValues (table)
+-- Dictionary.UnitOfMeasure (table)
+-- Dictionary.Currency (table)
+-- Trade.LiquidityProviders (table)
+-- Trade.SpreadGroup (table)
+-- 25+ instrument configuration tables (tables)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CheckValidInstrumentsConstrients | Procedure | Called at end for FK/unique index validation |
| dbo.InsertInstrumentError | Table | INSERT - logs all validation errors |
| Dictionary.StocksIndustry | Table | SELECT - validates @StocksIndustryID |
| Dictionary.CurrencyType | Table | SELECT - validates @CurrencyTypeID |
| Dictionary.ExchangeInfo | Table | SELECT - validates @ExchangeID, reads ExchangeDescription |
| Dictionary.PriceSourceName | Table | SELECT - validates @PriceSourceID |
| Dictionary.SettlementMethodValues | Table | SELECT - validates @SettlementMethod |
| Dictionary.UnitOfMeasure | Table | SELECT - validates @UnitOfMeasure |
| Dictionary.Currency | Table | SELECT - checks if currency exists |
| Trade.LiquidityProviders | Table | SELECT - validates liquidity provider IDs |
| Trade.SpreadGroup | Table | JOIN - validates spread group assignments |
| Trade.Instrument | Table | SELECT - existence checks, reads PriceServerID/OMEID |
| Trade.InstrumentMetaData | Table | SELECT - existence checks, reads PriceSourceID/ContractExpire |
| Trade.InstrumentToFeeConfigV2 | Table | SELECT - existence checks, copies fee config |
| Trade.FeatureThresholdValues | Table | SELECT - existence checks, copies thresholds |
| Trade.Spread | Table | SELECT - existence checks, copies spread data |
| Trade.SpreadToGroup | Table | SELECT - copies spread group mapping |
| Trade.InstrumentSpread | Table | SELECT - copies instrument spread |
| Trade.ProviderToInstrument | Table | SELECT - existence check |
| Trade.ProviderInstrumentToLeverage | Table | SELECT - copies leverage config |
| Trade.ProviderInstrumentToLotCount | Table | SELECT - copies lot count config |
| Trade.ActiveFeatureThreshold | Table | SELECT - copies active thresholds |
| Trade.TradonomiContracts | Table | SELECT - existence check, next ContractID |
| Trade.InstrumentImages | Table | SELECT - existence check, next ImageID |
| Trade.LiquidityProviderContracts | Table | SELECT - existence check, next ContractID |
| Trade.InstrumentConversion | Table | SELECT - existence check |
| Trade.UsAllowedInstruments | Table | SELECT - existence check |
| Trade.InstrumentCusip | Table | SELECT - existence check |
| Trade.FuturesMetaData | Table | SELECT - existence check |
| Trade.InstrumentVolatilityThresholdType | Table | SELECT - existence check |
| Hedge.InstrumentConfiguration | Table | SELECT - existence check, copies config |
| Hedge.HBCAccountConfiguration | Table | SELECT - existence check, copies config |
| Hedge.InstrumentBoundaries | Table | SELECT - existence check, copies boundaries |
| Hedge.ProviderUnitConversionRatio | Table | SELECT - existence check, copies ratios |
| Price.InstrumentConfiguration | Table | SELECT - existence check |
| Price.Instrument | Table | SELECT - existence check |
| Price.InstrumentRateSources | Table | SELECT - commented-out copy logic |
| Price.LiquidityAccountToInstrument | Table | SELECT - commented-out copy logic |
| History.SplitRatio | Table | SELECT - existence check, next ID |
| dbo.PriceSplitRatio | Table | SELECT - existence check, next ID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertInstrumentRealTable | Procedure | EXEC - calls this procedure as validation step |
| Trade.CheckValidInstruments_bck | Procedure | Backup copy of this procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Global temp tables (##) | Coupling | Uses 25+ global ##temp tables shared with caller and callee - session-level coupling |
| No explicit transaction | Atomicity | Error logging to dbo.InsertInstrumentError is not wrapped in a transaction |
| TRY/CATCH with THROW | Error handling | Captures errors, logs to dbo.InsertInstrumentError, re-throws to caller |
| sys.objects dependency | Portability | Uses `SELECT TOP 6 ... FROM sys.objects` as a row generator for CFICode validation |

---

## 8. Sample Queries

### 8.1 Check recent instrument onboarding errors

```sql
SELECT TOP 20 InstrumentID, ErrorOutput, ObjectType, Step_name
FROM   dbo.InsertInstrumentError WITH (NOLOCK)
ORDER BY InstrumentID DESC;
```

### 8.2 Verify instrument exists across all configuration tables

```sql
DECLARE @InstrumentID INT = 1234;
SELECT 'Trade.Instrument' AS TableName, COUNT(*) AS Cnt FROM Trade.Instrument WITH (NOLOCK) WHERE InstrumentID = @InstrumentID
UNION ALL SELECT 'Trade.InstrumentMetaData', COUNT(*) FROM Trade.InstrumentMetaData WITH (NOLOCK) WHERE InstrumentID = @InstrumentID
UNION ALL SELECT 'Trade.ProviderToInstrument', COUNT(*) FROM Trade.ProviderToInstrument WITH (NOLOCK) WHERE InstrumentID = @InstrumentID
UNION ALL SELECT 'Trade.InstrumentToFeeConfigV2', COUNT(*) FROM Trade.InstrumentToFeeConfigV2 WITH (NOLOCK) WHERE InstrumentID = @InstrumentID
UNION ALL SELECT 'Hedge.InstrumentConfiguration', COUNT(*) FROM Hedge.InstrumentConfiguration WITH (NOLOCK) WHERE InstrumentID = @InstrumentID;
```

### 8.3 Check instrument type distribution and ranges

```sql
SELECT   im.InstrumentTypeID,
         MIN(im.InstrumentID) AS MinID,
         MAX(im.InstrumentID) AS MaxID,
         COUNT(*)             AS InstrumentCount
FROM     Trade.InstrumentMetaData im WITH (NOLOCK)
GROUP BY im.InstrumentTypeID
ORDER BY im.InstrumentTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 97 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (CheckValidInstrumentsConstrients) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CheckValidInstruments | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CheckValidInstruments.sql*
