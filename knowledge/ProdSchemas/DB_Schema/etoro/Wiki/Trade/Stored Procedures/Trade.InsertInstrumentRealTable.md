# Trade.InsertInstrumentRealTable

> Full instrument creation procedure that validates input via Trade.CheckValidInstruments, then atomically commits a new instrument across 20+ tables spanning Trade, Hedge, Price, History, and Dictionary schemas in a single transaction; the legacy comprehensive onboarding path preceding the SecurityOpsAPI workflow.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID + @isvalid OUTPUT - all inserts keyed on InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertInstrumentRealTable is the comprehensive legacy instrument creation procedure that commits all infrastructure for a new tradeable instrument in a single atomic transaction. Unlike InsertInstrumentMetadataSecurityOpsAPI (the newer SecurityOpsAPI path that writes to 5 tables), this procedure populates 20+ tables across 5 schemas: metadata, trading configuration, fee structures, hedge limits, price feeds, image registry, spread groups, leverage tables, lot counts, futures parameters, and audit history. The name "RealTable" distinguishes this from a dry-run/staging path: it writes to production tables.

This procedure exists as the definitive, all-or-nothing instrument onboarding operation for the legacy admin workflow. Without it, a new instrument would require 20+ separate INSERT statements with complex dependency ordering and no rollback guarantee. The procedure is called in sequence after its counterpart Trade.CheckValidInstruments (which both validates input and populates the ## global temp tables that this procedure reads from).

Data flow: The caller (external DBA tool or admin application) first calls Trade.CheckValidInstruments with all parameters, which populates ~20 global temp tables (##Dictionary_Currency, ##Trade_InstrumentMetaData, ##Trade_Instrument, etc.). If @isvalid=1, the caller then calls Trade.InsertInstrumentRealTable with the same parameters. This procedure re-calls Trade.CheckValidInstruments internally (verifying the temp tables still hold valid data), then begins the transaction, reading from each ## temp table and inserting into the corresponding production table. On success, it logs all parameters as XML to History.InstrumentInsertParameters. On failure, it logs the error to dbo.InsertInstrumentError with step 'Insert To Real' and re-throws.

---

## 2. Business Logic

### 2.1 Validate-Then-Insert Two-Phase Pattern

**What**: The procedure does NOT use its parameters as direct INSERT values. Instead, it delegates to Trade.CheckValidInstruments (passing all params) which populates global temp tables. Then it reads from those ## tables.

**Columns/Parameters Involved**: All input parameters, `@isvalid` OUTPUT

**Rules**:
- Phase 1: EXEC Trade.CheckValidInstruments (all params) -> sets @isvalid OUTPUT.
- If @isvalid=0 -> RAISERROR 'CheckValidInstruments Operation Failed' and RETURN -1.
- Phase 2 (only if @isvalid=1): Transaction reads from ## global temp tables, not from @parameters directly.
- This means: ALL 97 parameters serve as VALIDATION inputs. The actual INSERT column values are determined by Trade.CheckValidInstruments logic and stored in ## tables.
- Error in Phase 2 -> ROLLBACK, log to dbo.InsertInstrumentError with step 'Insert To Real'.

**Diagram**:
```
EXEC Trade.InsertInstrumentRealTable (97 params)
         |
         v
EXEC Trade.CheckValidInstruments (same 97 params)
         |
    @isvalid=0? -> RAISERROR, RETURN -1
         |
    @isvalid=1?
         |
         v
BEGIN TRAN
  INSERT Dictionary.Currency         FROM ##Dictionary_Currency
  INSERT Trade.InstrumentMetaData    FROM ##Trade_InstrumentMetaData
  INSERT Trade.Instrument            FROM ##Trade_Instrument
  INSERT Trade.FeatureThresholdValues FROM ##Trade_FeatureThresholdValues
  INSERT Trade.InstrumentImages       FROM ##Trade_InstrumentImages (IDENTITY_INSERT ON)
  INSERT Hedge.InstrumentConfiguration FROM ##Hedge_InstrumentConfiguration
  INSERT Price.InstrumentConfiguration FROM ##Price_InstrumentConfiguration (if @IsRealDB=1)
  INSERT Trade.InstrumentToFeeConfigV2 FROM ##Trade_InstrumentToFeeConfig
  INSERT Trade.TradonomiContracts      FROM ##Trade_TradonomiContracts
  INSERT Trade.ActiveFeatureThreshold  FROM ##Trade_ActiveFeatureThreshold
  INSERT Trade.InstrumentSpread        FROM ##Trade_InstrumentSpread
  INSERT Trade.ProviderToInstrument    FROM ##Trade_ProviderToInstrument
  INSERT Trade.Spread                  FROM ##Trade_Spread
  INSERT Trade.SpreadToGroup           FROM ##Trade_SpreadToGroup
  INSERT Hedge.HBCAccountConfiguration FROM ##Hedge_HBCAccountConfiguration
  INSERT Trade.LiquidityProviderContracts FROM ##Trade_LiquidityProviderContracts (IDENTITY_INSERT ON)
  INSERT Hedge.ProviderUnitConversionRatio FROM ##Hedge_ProviderUnitConversionRatio
  INSERT Trade.InstrumentConversion    FROM ##Trade_InstrumentConversion
  INSERT Hedge.InstrumentBoundaries    FROM ##Hedge_InstrumentBoundaries
  INSERT Price.InstrumentRateSources   FROM ##Price_InstrumentRateSources
  INSERT Price.LiquidityAccountToInstrument FROM ##Price_LiquidityAccountToInstrument
  INSERT Trade.ProviderInstrumentToLeverage FROM ##Trade_ProviderInstrumentToLeverage
  INSERT Trade.ProviderInstrumentToLotCount FROM ##Trade_ProviderInstrumentToLotCount
  INSERT Trade.InstrumentGroups        FROM ##Trade_InstrumentGroups
  INSERT History.SplitRatio            FROM ##History_SplitRatio (IDENTITY_INSERT ON)
  INSERT Trade.TradonomiToLiquidityProviderContracts (cross-join from ## tables)
  INSERT Trade.FuturesMetaData         FROM ##Trade_FuturesMetaData
  INSERT Price.OMPDThresholdValues     FROM ##Price_OMPDThresholdValues
  INSERT Price.OMPDActiveThreshold     FROM ##Price_OMPDActiveThreshold
  INSERT Price.PricingConfigurations   FROM ##Price_PricingConfigurations
  INSERT Trade.InstrumentVolatilityThresholdType (if @IsRealDB=1)
COMMIT
  INSERT History.InstrumentInsertParameters (XML audit of all 97 params)
```

### 2.2 Feature Flag (IsRealDB / FeatureID=22) Conditional Inserts

**What**: Two tables are only inserted into when Maintenance.Feature FeatureID=22 is enabled (Value=1). This flag determines if the environment is a "real" production DB vs. a staging/testing clone.

**Columns/Parameters Involved**: `@IsRealDB` (derived from FeatureID=22), `@VolatilityThresholdTypeID`

**Rules**:
- IF @IsRealDB=1: INSERT Price.InstrumentConfiguration AND INSERT Trade.InstrumentVolatilityThresholdType.
- IF @IsRealDB=0: Both tables are skipped.
- Same feature flag (FeatureID=22) used by InsertInstrumentMetadataSecurityOpsAPI for LP contract gating.

### 2.3 Liquidity Provider Array Parameters (Up to 10 Providers)

**What**: The procedure accepts up to 10 liquidity providers via numbered parameter sets (ID, Ticker, ExchangeID, RateID per slot). Slots 1-4 are required; slots 5-10 are nullable. These are passed to CheckValidInstruments and flow into the ## temp tables.

**Rules**:
- @LiquidityProviderID_1 through _4: Required. @LiquidityProviderID_5 through _10: NULL = no provider for that slot.
- Same structure for @ProviderTicker_1-10, @ProviderExchangeID_1-10, @ProviderRateID_1-10.
- CheckValidInstruments uses these to populate ##Trade_LiquidityProviderContracts.

### 2.4 Parameter Audit Trail

**What**: After a successful COMMIT, all 97 input parameters are serialized as an XML document and inserted into History.InstrumentInsertParameters.

**Rules**:
- XML is built using FOR XML PATH(''), ROOT('Root') with each parameter as a node with a @Value attribute.
- Enables full audit of what values were used to create each instrument.
- Inserted OUTSIDE the main transaction (post-COMMIT), so audit write failure doesn't rollback the creation.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Name | VARCHAR(50) | NO | - | CODE-BACKED | Internal name of the instrument. Passed to Trade.CheckValidInstruments for validation and populates ##Dictionary_Currency.Name. |
| 2 | @ISINCode | VARCHAR(30) | NO | - | CODE-BACKED | International Securities Identification Number. Used for regulatory identification. Flows to Dictionary.Currency.ISINCode and Trade.InstrumentMetaData.ISINCode. |
| 3 | @UnitMargin | INT | NO | - | CODE-BACKED | Required unit margin for the instrument (in eToro units). Used by CheckValidInstruments to validate position sizing rules. |
| 4 | @InstrumentID | INT | NO | - | CODE-BACKED | Unique identifier for the new instrument. Serves as the primary key shared across all 20+ target tables. Also used as the audit key in History.InstrumentInsertParameters. |
| 5 | @BuyCurrencyID | INT | NO | - | CODE-BACKED | Currency ID for the buy side of the instrument pair. Written to Trade.Instrument.BuyCurrencyID. Typically equals @InstrumentID (instrument is its own currency). |
| 6 | @SellCurrencyID | INT | NO | - | CODE-BACKED | Currency ID for the sell (quote) side of the pair, e.g., USD. Written to Trade.Instrument.SellCurrencyID. |
| 7 | @CopyMainpropertiesFromInstrument | INT | NO | - | CODE-BACKED | InstrumentID of an existing instrument to copy configuration from. Used by CheckValidInstruments to seed temp table values from an existing instrument's config. 0 = no copy template. |
| 8 | @SymbolFull | VARCHAR(50) | NO | - | CODE-BACKED | Full instrument symbol including exchange suffix (e.g., "AAPL.US"). Written to Trade.InstrumentMetaData.SymbolFull. |
| 9 | @Abbreviation | VARCHAR(20) | NO | - | CODE-BACKED | Short abbreviated form of the instrument symbol. Written to Dictionary.Currency.Abbreviation. |
| 10 | @DisplayName | VARCHAR(100) | NO | - | CODE-BACKED | Human-readable display name (e.g., "Apple Inc."). Written to Trade.InstrumentMetaData.InstrumentDisplayName. |
| 11 | @ExchangeID | INT | NO | - | CODE-BACKED | Exchange identifier. Written to Trade.InstrumentMetaData.ExchangeID. |
| 12 | @StocksIndustryID | INT | NO | - | CODE-BACKED | Stock industry classification ID. Written to Trade.InstrumentMetaData.StocksIndustryID. |
| 13 | @IsMajor | BIT | NO | - | CODE-BACKED | Whether the instrument is classified as a "major" (e.g., major currency pair). Written to Trade.Instrument.IsMajor. |
| 14 | @IsRealAsset | INT | NO | - | CODE-BACKED | Whether this is a real (physically-settled) asset as opposed to a CFD. Affects fee calculation and settlement logic. Written to Dictionary.Currency via CheckValidInstruments. |
| 15 | @CurrencyTypeID | INT | NO | - | CODE-BACKED | Currency type identifier. Written to Dictionary.Currency.CurrencyTypeID. Mirrors @InstrumentTypeID in most cases. |
| 16 | @PipDifferenceThreshold | BIGINT | NO | - | CODE-BACKED | Pip difference threshold for price protection. Written to Trade.Instrument.PipDifferenceThreshold. |
| 17 | @MaxPositionUnits | DECIMAL(18,4) | NO | - | CODE-BACKED | Maximum allowed position size in units. Written to Trade.ProviderToInstrument.MaxPositionUnits. |
| 18 | @Precision | TINYINT | NO | - | CODE-BACKED | Decimal precision for rate display. Written to Trade.ProviderToInstrument.Precision. |
| 19 | @InstrumentTypeSubCategoryID | INT | NO | - | CODE-BACKED | Sub-category within the instrument type hierarchy. Written to Trade.InstrumentMetaData.InstrumentTypeSubCategoryID. |
| 20 | @MinOrderSizeForExecutionInEToroUnits | DECIMAL(16,2) | NO | - | CODE-BACKED | Minimum order size (in eToro units) for hedge execution routing. Written to Hedge.InstrumentConfiguration. |
| 21 | @HBCDealSizeThresholdAlertInEToroUnits | INT | NO | - | CODE-BACKED | Hedge Block Check deal size threshold that triggers an alert. Written to Hedge.InstrumentConfiguration. |
| 22 | @HBCMaxDealSizeThresholdRejectInEToroUnits | INT | NO | - | CODE-BACKED | Hedge Block Check max deal size threshold that causes rejection. Written to Hedge.InstrumentConfiguration. |
| 23 | @ManualMaxDealSizeInEToroUnits | INT | NO | - | CODE-BACKED | Maximum deal size for manually-executed orders. Written to Hedge.InstrumentConfiguration. |
| 24 | @VolatilityThresholdTypeID | INT | NO | - | CODE-BACKED | Volatility threshold type for price protection rules. Written to Trade.InstrumentVolatilityThresholdType (only if @IsRealDB=1). |
| 25 | @InstrumentTypeID | INT | NO | - | CODE-BACKED | Instrument type (e.g., stock, crypto, currency, index). Written to Trade.InstrumentMetaData.InstrumentTypeID. Controls pricing, fees, and regulatory treatment. |
| 26 | @NonLeveragedSellEndOfWeekFee | DECIMAL(16,8) | NO | - | CODE-BACKED | End-of-week overnight fee for non-leveraged sell (short) positions. Written to Trade.InstrumentToFeeConfigV2. |
| 27 | @NonLeveragedBuyEndOfWeekFee | DECIMAL(16,8) | NO | - | CODE-BACKED | End-of-week overnight fee for non-leveraged buy (long) positions. Written to Trade.InstrumentToFeeConfigV2. |
| 28 | @NonLeveragedBuyOverNightFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Daily overnight fee for non-leveraged long positions. Written to Trade.InstrumentToFeeConfigV2. |
| 29 | @NonLeveragedSellOverNightFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Daily overnight fee for non-leveraged short positions. Written to Trade.InstrumentToFeeConfigV2. |
| 30 | @LeveragedSellEndOfWeekFee | DECIMAL(16,8) | NO | - | CODE-BACKED | End-of-week overnight fee for leveraged sell positions. Written to Trade.InstrumentToFeeConfigV2. |
| 31 | @LeveragedBuyEndOfWeekFee | DECIMAL(16,8) | NO | - | CODE-BACKED | End-of-week overnight fee for leveraged buy positions. Written to Trade.InstrumentToFeeConfigV2. |
| 32 | @LeveragedBuyOverNightFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Daily overnight fee for leveraged long positions. Written to Trade.InstrumentToFeeConfigV2. |
| 33 | @LeveragedSellOverNightFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Daily overnight fee for leveraged short positions. Written to Trade.InstrumentToFeeConfigV2. |
| 34 | @isvalid | BIT OUTPUT | NO | - | CODE-BACKED | OUTPUT parameter: set by Trade.CheckValidInstruments. 1 = validation passed, inserts proceed. 0 = validation failed, procedure returns -1 without inserting. |
| 35 | @PriceSourceID | INT | NO | - | CODE-BACKED | Price feed source identifier. Written to Trade.InstrumentMetaData.PriceSourceID. |
| 36 | @ShardID | INT | NO | - | CODE-BACKED | Database shard assignment for the instrument. Written to Trade.Instrument.ShardID. |
| 37 | @Cusip | VARCHAR(500) | NO | - | CODE-BACKED | CUSIP identifier for US equities. Written to Trade.InstrumentMetaData.Cusip. |
| 38 | @LiquidityProviderID_1 | INT | NO | - | CODE-BACKED | Liquidity provider ID for slot 1 (required). One of up to 10 LP slots. Passed to CheckValidInstruments; flows into ##Trade_LiquidityProviderContracts. |
| 39 | @LiquidityProviderID_2 | INT | NO | - | CODE-BACKED | Liquidity provider ID for slot 2 (required). |
| 40 | @LiquidityProviderID_3 | INT | NO | - | CODE-BACKED | Liquidity provider ID for slot 3 (required). |
| 41 | @LiquidityProviderID_4 | INT | NO | - | CODE-BACKED | Liquidity provider ID for slot 4 (required). |
| 42 | @LiquidityProviderID_5 | INT | YES | NULL | CODE-BACKED | Liquidity provider ID for slot 5 (optional). NULL = slot unused. |
| 43 | @LiquidityProviderID_6 | INT | YES | NULL | CODE-BACKED | Liquidity provider ID for slot 6 (optional). NULL = slot unused. |
| 44 | @LiquidityProviderID_7 | INT | YES | NULL | CODE-BACKED | Liquidity provider ID for slot 7 (optional). NULL = slot unused. |
| 45 | @LiquidityProviderID_8 | INT | YES | NULL | CODE-BACKED | Liquidity provider ID for slot 8 (optional). NULL = slot unused. |
| 46 | @LiquidityProviderID_9 | INT | YES | NULL | CODE-BACKED | Liquidity provider ID for slot 9 (optional). NULL = slot unused. |
| 47 | @LiquidityProviderID_10 | INT | YES | NULL | CODE-BACKED | Liquidity provider ID for slot 10 (optional). NULL = slot unused. |
| 48 | @ProviderTicker_1 | VARCHAR(100) | NO | - | CODE-BACKED | LP-specific ticker symbol for provider slot 1 (required). The ticker as used by this liquidity provider. |
| 49 | @ProviderTicker_2 | VARCHAR(100) | NO | - | CODE-BACKED | LP-specific ticker for slot 2 (required). |
| 50 | @ProviderTicker_3 | VARCHAR(100) | NO | - | CODE-BACKED | LP-specific ticker for slot 3 (required). |
| 51 | @ProviderTicker_4 | VARCHAR(100) | NO | - | CODE-BACKED | LP-specific ticker for slot 4 (required). |
| 52 | @ProviderTicker_5 | VARCHAR(100) | YES | NULL | CODE-BACKED | LP-specific ticker for slot 5 (optional). NULL if slot unused. |
| 53 | @ProviderTicker_6 | VARCHAR(100) | YES | NULL | CODE-BACKED | LP-specific ticker for slot 6 (optional). |
| 54 | @ProviderTicker_7 | VARCHAR(100) | YES | NULL | CODE-BACKED | LP-specific ticker for slot 7 (optional). |
| 55 | @ProviderTicker_8 | VARCHAR(100) | YES | NULL | CODE-BACKED | LP-specific ticker for slot 8 (optional). |
| 56 | @ProviderTicker_9 | VARCHAR(100) | YES | NULL | CODE-BACKED | LP-specific ticker for slot 9 (optional). |
| 57 | @ProviderTicker_10 | VARCHAR(100) | YES | NULL | CODE-BACKED | LP-specific ticker for slot 10 (optional). |
| 58 | @ProviderExchangeID_1 | INT | NO | - | CODE-BACKED | Exchange ID for LP slot 1 (required). Exchange where this LP routes orders for this instrument. |
| 59 | @ProviderExchangeID_2 | INT | NO | - | CODE-BACKED | Exchange ID for LP slot 2 (required). |
| 60 | @ProviderExchangeID_3 | INT | NO | - | CODE-BACKED | Exchange ID for LP slot 3 (required). |
| 61 | @ProviderExchangeID_4 | INT | NO | - | CODE-BACKED | Exchange ID for LP slot 4 (required). |
| 62 | @ProviderExchangeID_5 | INT | YES | NULL | CODE-BACKED | Exchange ID for LP slot 5 (optional). |
| 63 | @ProviderExchangeID_6 | INT | YES | NULL | CODE-BACKED | Exchange ID for LP slot 6 (optional). |
| 64 | @ProviderExchangeID_7 | INT | YES | NULL | CODE-BACKED | Exchange ID for LP slot 7 (optional). |
| 65 | @ProviderExchangeID_8 | INT | YES | NULL | CODE-BACKED | Exchange ID for LP slot 8 (optional). |
| 66 | @ProviderExchangeID_9 | INT | YES | NULL | CODE-BACKED | Exchange ID for LP slot 9 (optional). |
| 67 | @ProviderExchangeID_10 | INT | YES | NULL | CODE-BACKED | Exchange ID for LP slot 10 (optional). |
| 68 | @ProviderRateID_1 | INT | NO | - | CODE-BACKED | Rate conversion ID for LP slot 1 (required). Determines the rate conversion factor for this LP's pricing. |
| 69 | @ProviderRateID_2 | INT | NO | - | CODE-BACKED | Rate conversion ID for LP slot 2 (required). |
| 70 | @ProviderRateID_3 | INT | NO | - | CODE-BACKED | Rate conversion ID for LP slot 3 (required). |
| 71 | @ProviderRateID_4 | INT | NO | - | CODE-BACKED | Rate conversion ID for LP slot 4 (required). |
| 72 | @ProviderRateID_5 | INT | YES | NULL | CODE-BACKED | Rate conversion ID for LP slot 5 (optional). |
| 73 | @ProviderRateID_6 | INT | YES | NULL | CODE-BACKED | Rate conversion ID for LP slot 6 (optional). |
| 74 | @ProviderRateID_7 | INT | YES | NULL | CODE-BACKED | Rate conversion ID for LP slot 7 (optional). |
| 75 | @ProviderRateID_8 | INT | YES | NULL | CODE-BACKED | Rate conversion ID for LP slot 8 (optional). |
| 76 | @ProviderRateID_9 | INT | YES | NULL | CODE-BACKED | Rate conversion ID for LP slot 9 (optional). |
| 77 | @ProviderRateID_10 | INT | YES | NULL | CODE-BACKED | Rate conversion ID for LP slot 10 (optional). |
| 78 | @VisibleInternallyOnly | INT | NO | - | CODE-BACKED | Controls whether the instrument is visible to the public (0) or only to internal eToro users (1). Written to Trade.ProviderToInstrument.VisibleInternallyOnly. |
| 79 | @MarketRangeValidationType | TINYINT | NO | - | CODE-BACKED | Type of market range validation applied to orders: controls how slippage protection is enforced. Written to Trade.ProviderToInstrument.MarketRangeValidationType. |
| 80 | @MarketRangePercentage | DECIMAL(5,2) | YES | NULL | CODE-BACKED | Market range as a percentage (alternative to fixed pips). Written to Trade.ProviderToInstrument.MarketRangePercentage. |
| 81 | @MarketRange | INT | YES | NULL | CODE-BACKED | Fixed market range in pips for slippage protection. Written to Trade.ProviderToInstrument.MarketRange. |
| 82 | @VolatilityRatePercentage | INT | YES | NULL | CODE-BACKED | Volatility rate as percentage for the instrument's price protection threshold. |
| 83 | @VolatilityRateInPips | DECIMAL(5,2) | YES | NULL | CODE-BACKED | Volatility rate in pips for the instrument's price protection threshold. |
| 84 | @IsFuture | INT | YES | NULL | CODE-BACKED | Whether the instrument is a futures contract. 1 = futures, NULL/0 = non-futures. Controls whether ##Trade_FuturesMetaData is populated. |
| 85 | @Multiplier | DECIMAL(20,10) | YES | NULL | CODE-BACKED | Futures contract multiplier (point value multiplier). Written to Trade.FuturesMetaData.Multiplier for futures instruments. |
| 86 | @MinimalTick | DECIMAL(20,10) | YES | NULL | CODE-BACKED | Minimum price increment (tick size) for the instrument. Written to Trade.FuturesMetaData.MinimalTick. |
| 87 | @LastTradingDateTime | DATETIME | YES | NULL | CODE-BACKED | Last date/time the futures contract can be traded. Written to Trade.FuturesMetaData.LastTradingDateTime. |
| 88 | @ExpirationDateTime | DATETIME | YES | NULL | CODE-BACKED | Futures contract expiration date/time. Written to Trade.FuturesMetaData.ExpirationDateTime. |
| 89 | @SettlementTime | TIME(7) | YES | NULL | CODE-BACKED | Daily settlement time for the instrument. Written to Trade.FuturesMetaData.SettlementTime. |
| 90 | @IndexPointValue | DECIMAL(20,10) | YES | NULL | CODE-BACKED | Value of one index point in USD. Written to Trade.FuturesMetaData.IndexPointValue. Used in PnL calculation for index futures. |
| 91 | @StopLossMarginInAssetCurrency | DECIMAL(16,8) | YES | NULL | CODE-BACKED | Stop-loss margin requirement expressed in the asset's currency. Written to Trade.ProviderToInstrument.StopLossMarginInAssetCurrency. |
| 92 | @InitialMarginInAssetCurrency | DECIMAL(16,8) | YES | NULL | CODE-BACKED | Initial margin requirement expressed in the asset's currency. Written to Trade.ProviderToInstrument.InitialMarginInAssetCurrency. |
| 93 | @CFICode | VARCHAR(6) | NO | - | CODE-BACKED | Classification of Financial Instruments (CFI) code per ISO 10962 (e.g., "ESXXXX" for equity shares). Written to Trade.InstrumentMetaData.CFICode for regulatory classification. |
| 94 | @SettlementMethod | TINYINT | NO | - | CODE-BACKED | How the instrument settles at expiry/close: physical delivery vs. cash settlement. Written to Trade.FuturesMetaData.SettlementMethod. |
| 95 | @UnitOfMeasure | TINYINT | NO | - | CODE-BACKED | Unit of measure for the instrument (e.g., shares, contracts, barrels). Written to Trade.FuturesMetaData.UnitOfMeasure. |
| 96 | @DifferenceThresholdType | INT | NO | - | CODE-BACKED | Type identifier for the pip/price difference threshold logic. Passed to CheckValidInstruments for validation configuration. |
| 97 | @PercentageDifferenceThreshold | DECIMAL(20,2) | NO | - | CODE-BACKED | Price difference threshold expressed as a percentage. Used alongside @DifferenceThresholdType for order validation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | Trade.CheckValidInstruments | Procedure call (EXEC) | Validation delegate. Populates all ## global temp tables and sets @isvalid. |
| FeatureID=22 | Maintenance.Feature | Lookup (SELECT) | @IsRealDB flag - determines if Price.InstrumentConfiguration and Trade.InstrumentVolatilityThresholdType are populated. |
| ## tables (read) | Dictionary.Currency | Write (INSERT) | Creates currency record for the new instrument. |
| ## tables (read) | Trade.InstrumentMetaData | Write (INSERT) | Creates instrument metadata. |
| ## tables (read) | Trade.Instrument | Write (INSERT) | Creates core trading parameters. |
| ## tables (read) | Trade.FeatureThresholdValues | Write (INSERT) | Creates feature threshold values. |
| ## tables (read) | Trade.InstrumentImages | Write (INSERT, IDENTITY ON) | Creates image records. |
| ## tables (read) | Hedge.InstrumentConfiguration | Write (INSERT) | Creates hedge configuration. |
| ## tables (read) | Price.InstrumentConfiguration | Write (INSERT, conditional) | Creates price spread configuration (only if @IsRealDB=1). |
| ## tables (read) | Trade.InstrumentToFeeConfigV2 | Write (INSERT) | Creates fee structure records. |
| ## tables (read) | Trade.TradonomiContracts | Write (INSERT) | Creates Tradonomi contract records. |
| ## tables (read) | Trade.ActiveFeatureThreshold | Write (INSERT) | Creates active feature thresholds. |
| ## tables (read) | Trade.InstrumentSpread | Write (INSERT) | Creates spread configuration. |
| ## tables (read) | Trade.ProviderToInstrument | Write (INSERT) | Creates provider-instrument mapping with all trading parameters. |
| ## tables (read) | Trade.Spread | Write (INSERT) | Creates spread records. |
| ## tables (read) | Trade.SpreadToGroup | Write (INSERT) | Maps spreads to groups. |
| ## tables (read) | Hedge.HBCAccountConfiguration | Write (INSERT) | Creates HBC account configuration. |
| ## tables (read) | Trade.LiquidityProviderContracts | Write (INSERT, IDENTITY ON) | Creates LP contract records. |
| ## tables (read) | Hedge.ProviderUnitConversionRatio | Write (INSERT) | Creates unit conversion ratios. |
| ## tables (read) | Trade.InstrumentConversion | Write (INSERT) | Creates instrument conversion paths. |
| ## tables (read) | Hedge.InstrumentBoundaries | Write (INSERT) | Creates hedge exposure boundaries. |
| ## tables (read) | Price.InstrumentRateSources | Write (INSERT) | Creates price rate source priorities. |
| ## tables (read) | Price.LiquidityAccountToInstrument | Write (INSERT) | Maps liquidity accounts to instrument. |
| ## tables (read) | Trade.ProviderInstrumentToLeverage | Write (INSERT) | Creates leverage options. |
| ## tables (read) | Trade.ProviderInstrumentToLotCount | Write (INSERT) | Creates lot count groups. |
| ## tables (read) | Trade.InstrumentGroups | Write (INSERT) | Maps instrument to groups. |
| ## tables (read) | History.SplitRatio | Write (INSERT, IDENTITY ON) | Creates initial split ratio row. |
| Cross-join of ## | Trade.TradonomiToLiquidityProviderContracts | Write (INSERT) | Links Tradonomi contracts to LP contracts by InstrumentID. |
| ## tables (read) | Trade.FuturesMetaData | Write (INSERT) | Creates futures-specific metadata. |
| ## tables (read) | Price.OMPDThresholdValues | Write (INSERT) | Creates OMPD threshold values. |
| ## tables (read) | Price.OMPDActiveThreshold | Write (INSERT) | Creates active OMPD thresholds. |
| ## tables (read) | Price.PricingConfigurations | Write (INSERT) | Creates pricing throttling config. |
| @InstrumentID | Trade.InstrumentVolatilityThresholdType | Write (INSERT, conditional) | Creates volatility threshold record (only if @IsRealDB=1). |
| All params as XML | History.InstrumentInsertParameters | Write (INSERT, post-commit) | Audit log of all 97 input parameters. |
| On error | dbo.InsertInstrumentError | Write (INSERT) | Error log with step 'Insert To Real'. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ReturnInstruemtFirstConfiguration | (function) | Reference | References this SP (likely in documentation or string). |
| Trade.ReturnInstruemtFirstConfigurationNew | (function) | Reference | References this SP. |
| External DBA tools | (external) | External caller | Called by admin tooling as part of the legacy instrument creation workflow, after CheckValidInstruments populates ## tables. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertInstrumentRealTable (procedure)
├── Trade.CheckValidInstruments (procedure) - validation + ## temp table population
├── Maintenance.Feature (table) - @IsRealDB feature flag
├── Dictionary.Currency (table) - INSERT target
├── Trade.InstrumentMetaData (table) - INSERT target
├── Trade.Instrument (table) - INSERT target
├── Trade.FeatureThresholdValues (table) - INSERT target
├── Trade.InstrumentImages (table) - INSERT target
├── Hedge.InstrumentConfiguration (table) - INSERT target
├── Price.InstrumentConfiguration (table) - conditional INSERT target
├── Trade.InstrumentToFeeConfigV2 (table) - INSERT target
├── Trade.TradonomiContracts (table) - INSERT target
├── Trade.ActiveFeatureThreshold (table) - INSERT target
├── Trade.InstrumentSpread (table) - INSERT target
├── Trade.ProviderToInstrument (table) - INSERT target
├── Trade.Spread (table) - INSERT target
├── Trade.SpreadToGroup (table) - INSERT target
├── Hedge.HBCAccountConfiguration (table) - INSERT target
├── Trade.LiquidityProviderContracts (table) - INSERT target
├── Hedge.ProviderUnitConversionRatio (table) - INSERT target
├── Trade.InstrumentConversion (table) - INSERT target
├── Hedge.InstrumentBoundaries (table) - INSERT target
├── Price.InstrumentRateSources (table) - INSERT target
├── Price.LiquidityAccountToInstrument (table) - INSERT target
├── Trade.ProviderInstrumentToLeverage (table) - INSERT target
├── Trade.ProviderInstrumentToLotCount (table) - INSERT target
├── Trade.InstrumentGroups (table) - INSERT target
├── History.SplitRatio (table) - INSERT target
├── Trade.TradonomiToLiquidityProviderContracts (table) - INSERT target
├── Trade.FuturesMetaData (table) - INSERT target
├── Price.OMPDThresholdValues (table) - INSERT target
├── Price.OMPDActiveThreshold (table) - INSERT target
├── Price.PricingConfigurations (table) - INSERT target
├── Trade.InstrumentVolatilityThresholdType (table) - conditional INSERT target
├── History.InstrumentInsertParameters (table) - audit INSERT target
└── dbo.InsertInstrumentError (table) - error log INSERT target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CheckValidInstruments | Procedure | Called first with all 97 params; validates and populates ## global temp tables |
| Maintenance.Feature | Table | @IsRealDB flag (FeatureID=22) - gates two conditional INSERTs |
| 30+ target tables | Tables | All are INSERT targets reading from ## global temp tables |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ReturnInstruemtFirstConfiguration | Function | References this procedure |
| Trade.ReturnInstruemtFirstConfigurationNew | Function | References this procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET XACT_ABORT ON | Session setting | Any error in the transaction causes automatic ROLLBACK. Combined with explicit TRY/CATCH ensures atomicity. |
| SET NOCOUNT ON | Session setting | Suppresses row count messages. |
| Explicit transaction | Transaction | BEGIN TRAN ... COMMIT wraps all 30+ INSERTs. A failure in any single INSERT rolls back ALL insertions. |
| IDENTITY_INSERT ON/OFF | Session override | Applied for Trade.InstrumentImages, Trade.LiquidityProviderContracts, History.SplitRatio to allow caller-specified identity values. |
| Validation gate | Business rule | RAISERROR and RETURN -1 if @isvalid=0. All INSERT logic skipped if validation fails. |

---

## 8. Sample Queries

### 8.1 Check if an instrument was successfully created (verify all key tables)
```sql
DECLARE @InstrID INT = 9999;
SELECT 'InstrumentMetaData' AS [Table], InstrumentID FROM Trade.InstrumentMetaData WITH (NOLOCK) WHERE InstrumentID = @InstrID
UNION ALL SELECT 'Instrument', InstrumentID FROM Trade.Instrument WITH (NOLOCK) WHERE InstrumentID = @InstrID
UNION ALL SELECT 'Currency', CurrencyID FROM Dictionary.Currency WITH (NOLOCK) WHERE CurrencyID = @InstrID
UNION ALL SELECT 'SplitRatio', InstrumentID FROM History.SplitRatio WITH (NOLOCK) WHERE InstrumentID = @InstrID
UNION ALL SELECT 'ProviderToInstrument', InstrumentID FROM Trade.ProviderToInstrument WITH (NOLOCK) WHERE InstrumentID = @InstrID;
```

### 8.2 Retrieve the XML audit log of creation parameters
```sql
SELECT InstrumentID, ParametersValues
FROM   History.InstrumentInsertParameters WITH (NOLOCK)
WHERE  InstrumentID = 9999;
```

### 8.3 Check for creation errors logged during failed attempts
```sql
SELECT InstrumentID, ErrorOutput, Step_name, GETDATE() AS CheckTime
FROM   dbo.InsertInstrumentError WITH (NOLOCK)
WHERE  InstrumentID = 9999
ORDER BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 97 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Trade.CheckValidInstruments) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertInstrumentRealTable | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertInstrumentRealTable.sql*
