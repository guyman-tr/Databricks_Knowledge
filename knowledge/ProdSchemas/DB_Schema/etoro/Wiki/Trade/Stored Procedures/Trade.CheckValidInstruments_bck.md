# Trade.CheckValidInstruments_bck

> Legacy backup copy of Trade.CheckValidInstruments that pre-dates futures contract support, expanded liquidity provider slots, and market range/volatility threshold enhancements. Unused in production - no callers found.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID (instrument being onboarded) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CheckValidInstruments_bck is a backup/legacy snapshot of the Trade.CheckValidInstruments procedure, preserved in the SSDT project with a `_bck` suffix. The header comment dates it to 2022-01-23 (Shany Sorokin: "Add tables to validation"). It performs the same core function as the active version - validating and staging instrument configuration data into global ##temp tables for new instrument onboarding - but lacks several features added since 2022.

This procedure exists as a safety net or historical reference. If the active Trade.CheckValidInstruments procedure experiences issues after a deployment, the team could temporarily revert to this backup version. However, no stored procedures or external processes currently call this backup.

Key differences from the active Trade.CheckValidInstruments:
- No futures contract support (@IsFuture, @Multiplier, @MinimalTick, @LastTradingDateTime, @ExpirationDateTime, @SettlementTime, @IndexPointValue, @CFICode, @SettlementMethod, @UnitOfMeasure are all absent)
- Only 4 liquidity provider slots (vs 10 in the active version)
- Uses @VolatiliyFeatureValue (typo) instead of the active version's @VolatilityThresholdTypeID, @VolatilityRatePercentage, @VolatilityRateInPips
- No market range validation parameters (@MarketRangeValidationType, @MarketRangePercentage, @MarketRange)
- No OMPD threshold parameters (@DifferenceThresholdType, @PercentageDifferenceThreshold)
- No @StopLossMarginInAssetCurrency, @InitialMarginInAssetCurrency
- 54 parameters (vs 97 in the active version)
- ~1,170 lines (vs ~1,560 in the active version)

---

## 2. Business Logic

### 2.1 Legacy Null String Normalization

**What**: Same pattern as the active version - converts 'null' strings to SQL NULL.

**Columns/Parameters Involved**: All 54 parameters

**Rules**:
- Identical CASE WHEN LOWER(@param) = 'null' THEN NULL pattern
- Some parameters additionally check for empty strings

### 2.2 InstrumentID Range Validation (Pre-Futures)

**What**: Same range validation as the active version but without futures-specific rules.

**Columns/Parameters Involved**: `@InstrumentID`, `@InstrumentTypeID`

**Rules**:
- InstrumentID 1000-9999: Only InstrumentTypeID NOT IN (5, 6)
- InstrumentID 100000-101000: Only InstrumentTypeID = 10
- InstrumentID 1-1000: Only InstrumentTypeID IN (5, 6, 10)
- No futures-specific exceptions (IsFuture does not exist in this version)

### 2.3 Copy-From-Instrument Logic (Simplified)

**What**: Same template-copying pattern but without futures special cases.

**Columns/Parameters Involved**: `@CopyMainpropertiesFromInstrument`

**Rules**:
- No futures-specific restriction (999/998 constraint absent)
- InstrumentTypeID match still enforced for non-currency types
- Copies to fewer configuration tables (no FuturesMetaData, no OMPD tables)

### 2.4 Global Temp Table Staging (Reduced Set)

**What**: Populates global ##temp tables but for fewer tables than the active version.

**Rules**:
- Missing: ##Trade_FuturesMetaData, ##Price_OMPDThresholdValues, ##Price_OMPDActiveThreshold, ##Price_PricingConfigurations
- Missing: ##Trade_InstrumentGroups
- Only 4 liquidity provider contract rows (vs up to 10)
- Calls Trade.CheckValidInstrumentsConstrients at the end (same as active version)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Name | VARCHAR(50) | NO | - | CODE-BACKED | Instrument display name. Same as active version. |
| 2 | @ISINCode | VARCHAR(30) | NO | - | CODE-BACKED | International Securities Identification Number. Same as active version. |
| 3 | @UnitMargin | INT | NO | - | CODE-BACKED | Price of 1 unit in USD for margin calculations. Same as active version. |
| 4 | @InstrumentID | INT | NO | - | CODE-BACKED | Unique identifier for the new instrument. Same validation rules minus futures checks. |
| 5 | @BuyCurrencyID | INT | NO | - | CODE-BACKED | Buy-side currency. Same validation as active version. |
| 6 | @SellCurrencyID | INT | NO | - | CODE-BACKED | Sell-side currency. Same validation as active version. |
| 7 | @CopyMainpropertiesFromInstrument | INT | NO | - | CODE-BACKED | Template instrument to copy from. No futures restriction (999/998). |
| 8 | @SymbolFull | VARCHAR(50) | NO | - | CODE-BACKED | Full trading symbol. Same as active version. |
| 9 | @Abbreviation | VARCHAR(20) | NO | - | CODE-BACKED | Short abbreviation. Same as active version. |
| 10 | @DisplayName | VARCHAR(100) | NO | - | CODE-BACKED | User-facing display name. Same as active version. |
| 11 | @ExchangeID | INT | NO | - | CODE-BACKED | Exchange identifier. Validated against Dictionary.ExchangeInfo. Same as active version. |
| 12 | @StocksIndustryID | INT | NO | - | CODE-BACKED | Industry classification. Same validation as active version. |
| 13 | @IsMajor | BIT | NO | - | CODE-BACKED | Major instrument flag. Same as active version. |
| 14 | @IsRealAsset | INT | NO | - | CODE-BACKED | Real asset ownership flag. Same validation as active version (no IsFuture exception). |
| 15 | @CurrencyTypeID | INT | NO | - | CODE-BACKED | Currency type. Validated against Dictionary.CurrencyType. Same as active version. |
| 16 | @PipDifferenceThreshold | BIGINT | NO | - | CODE-BACKED | Pip difference alerting threshold. Same as active version. |
| 17 | @MaxPositionUnits | DECIMAL(18,4) | NO | - | CODE-BACKED | Maximum position size in units. Same as active version. |
| 18 | @Precision | TINYINT | NO | - | CODE-BACKED | Rate display precision (1-6). Same as active version. |
| 19 | @InstrumentTypeSubCategoryID | INT | NO | - | CODE-BACKED | Sub-category within instrument type. Same as active version. |
| 20 | @MinOrderSizeForExecutionInEToroUnits | DECIMAL(16,2) | NO | - | CODE-BACKED | Minimum order size for execution. Same as active version. |
| 21 | @HBCDealSizeThresholdAlertInEToroUnits | INT | NO | - | CODE-BACKED | HBC deal size alert threshold. Same as active version. |
| 22 | @HBCMaxDealSizeThresholdRejectInEToroUnits | INT | NO | - | CODE-BACKED | HBC maximum deal size rejection threshold. Same as active version. |
| 23 | @ManualMaxDealSizeInEToroUnits | INT | NO | - | CODE-BACKED | Manual max deal size. Same as active version. |
| 24 | @VolatiliyFeatureValue | INT | NO | - | CODE-BACKED | Legacy volatility feature value (note typo: "Volatiliy"). Replaced in the active version by @VolatilityThresholdTypeID, @VolatilityRatePercentage, and @VolatilityRateInPips. |
| 25 | @InstrumentTypeID | INT | NO | - | CODE-BACKED | Instrument type classification. Same range rules as active version. |
| 26 | @NonLeveragedSellEndOfWeekFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Weekend fee for non-leveraged sell. Same as active version. |
| 27 | @NonLeveragedBuyEndOfWeekFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Weekend fee for non-leveraged buy. Same as active version. |
| 28 | @NonLeveragedBuyOverNightFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Overnight fee for non-leveraged buy. Same as active version. |
| 29 | @NonLeveragedSellOverNightFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Overnight fee for non-leveraged sell. Same as active version. |
| 30 | @LeveragedSellEndOfWeekFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Weekend fee for leveraged sell. Same as active version. |
| 31 | @LeveragedBuyEndOfWeekFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Weekend fee for leveraged buy. Same as active version. |
| 32 | @LeveragedBuyOverNightFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Overnight fee for leveraged buy. Same as active version. |
| 33 | @LeveragedSellOverNightFee | DECIMAL(16,8) | NO | - | CODE-BACKED | Overnight fee for leveraged sell. Same as active version. |
| 34 | @isvalid | BIT (OUTPUT) | NO | - | CODE-BACKED | Output flag: 1=passed, 0=failed. Same as active version. |
| 35 | @PriceSourceID | INT | NO | - | CODE-BACKED | Price source. Validated against Dictionary.PriceSourceName. Same as active version. |
| 36 | @ShardID | INT | NO | - | CODE-BACKED | Shard assignment. Value 8 forbidden. Same as active version. |
| 37 | @Cusip | VARCHAR(500) | NO | - | CODE-BACKED | CUSIP identifier. Same as active version. |
| 38 | @LiquidityProviderID_1 | INT | NO | - | CODE-BACKED | Primary liquidity provider ID. Validated against Trade.LiquidityProviders. |
| 39 | @LiquidityProviderID_2 | INT | NO | - | CODE-BACKED | Liquidity provider 2. |
| 40 | @LiquidityProviderID_3 | INT | NO | - | CODE-BACKED | Liquidity provider 3. |
| 41 | @LiquidityProviderID_4 | INT | NO | - | CODE-BACKED | Liquidity provider 4 (max in this version - active version supports 10). |
| 42 | @ProviderTicker_1 | VARCHAR(100) | NO | - | CODE-BACKED | Ticker symbol for liquidity provider 1. |
| 43 | @ProviderTicker_2 | VARCHAR(100) | NO | - | CODE-BACKED | Ticker symbol for liquidity provider 2. |
| 44 | @ProviderTicker_3 | VARCHAR(100) | NO | - | CODE-BACKED | Ticker symbol for liquidity provider 3. |
| 45 | @ProviderTicker_4 | VARCHAR(100) | NO | - | CODE-BACKED | Ticker symbol for liquidity provider 4. |
| 46 | @ProviderExchangeID_1 | INT | NO | - | CODE-BACKED | Exchange ID for liquidity provider 1. |
| 47 | @ProviderExchangeID_2 | INT | NO | - | CODE-BACKED | Exchange ID for liquidity provider 2. |
| 48 | @ProviderExchangeID_3 | INT | NO | - | CODE-BACKED | Exchange ID for liquidity provider 3. |
| 49 | @ProviderExchangeID_4 | INT | NO | - | CODE-BACKED | Exchange ID for liquidity provider 4. |
| 50 | @ProviderRateID_1 | INT | NO | - | CODE-BACKED | Rate conversion factor for liquidity provider 1. |
| 51 | @ProviderRateID_2 | INT | NO | - | CODE-BACKED | Rate conversion factor for liquidity provider 2. |
| 52 | @ProviderRateID_3 | INT | NO | - | CODE-BACKED | Rate conversion factor for liquidity provider 3. |
| 53 | @ProviderRateID_4 | INT | NO | - | CODE-BACKED | Rate conversion factor for liquidity provider 4. |
| 54 | @VisibleInternallyOnly | INT | NO | - | CODE-BACKED | Internal-only visibility flag. Same as active version. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StocksIndustryID | Dictionary.StocksIndustry | Lookup | Validates industry ID |
| @CurrencyTypeID | Dictionary.CurrencyType | Lookup | Validates currency type |
| @ExchangeID | Dictionary.ExchangeInfo | Lookup | Validates exchange and gets description |
| @PriceSourceID | Dictionary.PriceSourceName | Lookup | Validates price source |
| @BuyCurrencyID | Dictionary.Currency | Lookup | Checks currency existence |
| @LiquidityProviderID_* | Trade.LiquidityProviders | Lookup | Validates provider IDs |
| @InstrumentID, @isvalid | Trade.CheckValidInstrumentsConstrients | EXEC | FK/index constraint validation |
| @InstrumentID | dbo.InsertInstrumentError | INSERT | Logs validation errors |
| @InstrumentID | 20+ instrument configuration tables | SELECT (existence) | Checks instrument uniqueness across tables |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none) | - | - | No callers found - this is an unused backup procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CheckValidInstruments_bck (procedure) [UNUSED BACKUP]
+-- Trade.CheckValidInstrumentsConstrients (procedure)
|     +-- dbo.InsertInstrumentError (table)
+-- dbo.InsertInstrumentError (table)
+-- Dictionary lookup tables (Dictionary.StocksIndustry, CurrencyType, ExchangeInfo, PriceSourceName, Currency)
+-- 20+ instrument configuration tables (Trade, Hedge, Price schemas)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CheckValidInstrumentsConstrients | Procedure | EXEC - FK/index validation |
| dbo.InsertInstrumentError | Table | INSERT - error logging |
| Dictionary.StocksIndustry | Table | SELECT - validates industry |
| Dictionary.CurrencyType | Table | SELECT - validates currency type |
| Dictionary.ExchangeInfo | Table | SELECT - validates exchange |
| Dictionary.PriceSourceName | Table | SELECT - validates price source |
| Dictionary.Currency | Table | SELECT - checks currency existence |
| Trade.LiquidityProviders | Table | SELECT - validates LP IDs |
| Trade.Instrument | Table | SELECT - existence checks |
| Trade.InstrumentMetaData | Table | SELECT - existence checks |
| 15+ additional instrument config tables | Tables | SELECT - existence checks and copy-from logic |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none) | - | No dependents - unused backup |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Global temp tables (##) | Coupling | Same ##temp table pattern as active version |
| No explicit transaction | Atomicity | Error logging not transactional |
| TRY/CATCH with THROW | Error handling | Same pattern as active version |
| CREATE keyword | DDL | Uses `CREATE PROC` vs active version's `CREATE OR ALTER` |

---

## 8. Sample Queries

### 8.1 Compare parameter counts between active and backup versions

```sql
SELECT 'Active' AS Version, COUNT(*) AS ParamCount
FROM   sys.parameters WITH (NOLOCK)
WHERE  object_id = OBJECT_ID('Trade.CheckValidInstruments')
UNION ALL
SELECT 'Backup', COUNT(*)
FROM   sys.parameters WITH (NOLOCK)
WHERE  object_id = OBJECT_ID('Trade.CheckValidInstruments_bck');
```

### 8.2 Check if backup procedure exists in target database

```sql
SELECT name, create_date, modify_date
FROM   sys.procedures WITH (NOLOCK)
WHERE  schema_id = SCHEMA_ID('Trade')
  AND  name LIKE 'CheckValidInstruments%'
ORDER BY name;
```

### 8.3 View recent instrument onboarding errors

```sql
SELECT TOP 20 InstrumentID, ErrorOutput, ObjectType, Step_name
FROM   dbo.InsertInstrumentError WITH (NOLOCK)
ORDER BY InstrumentID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 54 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (CheckValidInstrumentsConstrients) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CheckValidInstruments_bck | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CheckValidInstruments_bck.sql*
