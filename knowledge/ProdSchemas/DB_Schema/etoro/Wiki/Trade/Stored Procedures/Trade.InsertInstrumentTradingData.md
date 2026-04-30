# Trade.InsertInstrumentTradingData

> Bootstraps trading configuration for a new instrument by inserting default records into Trade.InstrumentToFeeConfigV2, Trade.ProviderToInstrument, Trade.ProviderInstrumentToLeverage, and Trade.ProviderInstrumentToLotCount under Provider 1, with business-rule-driven defaults and exchange-based W-8BEN flag logic.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID - anchors all 4 inserts |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertInstrumentTradingData creates the minimal trading configuration required for a new instrument to be accessible under Provider 1 (eToro's primary provider). It writes default fee structures (all zero), provider-instrument trading parameters (with sensible platform defaults for leverage, order types, and market range), a starting leverage option (LeverageID=1, default), and a lot count group assignment. The procedure is designed for newly onboarded instruments where initial configuration is "safe defaults" - all trades disabled by default (Enabled=0, VisibleInternallyOnly=1) until explicitly activated.

This procedure exists as the lighter counterpart to Trade.InsertInstrumentRealTable. While InsertInstrumentRealTable is the comprehensive legacy DBA workflow, InsertInstrumentTradingData targets the SecurityOpsAPI-era flow where each configuration table is populated separately. It was specifically designed for instruments onboarded via the modern API where fee config, leverage, and lot count data are populated in discrete steps.

Data flow: Called after InsertInstrumentMetadataSecurityOpsAPI (which creates InstrumentMetaData, Currency, Instrument, InstrumentImages, SplitRatio). InsertInstrumentTradingData adds the provider layer (ProviderToInstrument + fees + leverage + lot count). The inserted ProviderToInstrument row uses ProviderID=1 and starts with Enabled=0 and VisibleInternallyOnly=1 - the instrument is hidden and untradeable until operations explicitly enables it.

---

## 2. Business Logic

### 2.1 InstrumentOperationMode vs Slippage Validation

**What**: The @Slippage parameter is required when the instrument uses unmanaged order execution (InstrumentOperationMode=1) and must be NULL when managed (InstrumentOperationMode=0).

**Columns/Parameters Involved**: `@Slippage`, `@InstrumentOperationMode`

**Rules**:
- IF @Slippage IS NULL AND @InstrumentOperationMode=1: RAISERROR - unmanaged mode requires a slippage value.
- IF @Slippage IS NOT NULL AND @InstrumentOperationMode=0: RAISERROR - managed/STP mode must not have slippage set.
- InstrumentOperationMode=1 = "un mung" (unmanaged): direct market, slippage applies.
- InstrumentOperationMode=0 = "mng" (managed/STP): no slippage parameter needed.

### 2.2 RequiresW8Ben - Exchange-Driven US Tax Form Requirement

**What**: The W-8BEN tax form requirement for non-US persons holding US securities is automatically set based on the instrument's exchange.

**Columns/Parameters Involved**: `@ExchangeID`, `RequiresW8Ben` (written to ProviderToInstrument)

**Rules**:
- RequiresW8Ben = 1 when ExchangeID IN (4, 5, 20): These are US exchanges (e.g., NYSE, NASDAQ, AMEX). Users must submit W-8BEN for non-US tax treatment.
- RequiresW8Ben = 0 for all other exchanges.

### 2.3 New Instrument Defaults - Safe-Start Profile

**What**: All inserted records use a conservative "safe start" profile: fees = 0, trading disabled, visible internally only. Must be explicitly enabled.

**Rules**:
- InstrumentToFeeConfigV2: ALL fees set to 0 (all 8 fee types).
- ProviderToInstrument.Enabled = 0: Not tradeable until enabled.
- ProviderToInstrument.VisibleInternallyOnly = 1: Hidden from public until enabled.
- ProviderToInstrument.AllowBuy = 1 / AllowSell = 0: Buy-only by default.
- ProviderToInstrument.MaxPositionUnits = 2147483646.9999 (near INT max): Effectively unlimited units.
- ProviderInstrumentToLeverage: LeverageID=1, IsDefault=1, Percentage=0, LeverageType=1.
- ProviderInstrumentToLotCount: LotCountGroupID=0, LotCountID=1, IsDefault=1, Percentage=0.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | YES | NULL | CODE-BACKED | Instrument identifier. Required (RAISERROR if NULL). Serves as the FK key across all 4 target tables. |
| 2 | @SymbolFull | NVARCHAR(50) | YES | NULL | CODE-BACKED | Full symbol (e.g., "AAPL.US"). Required. Used to construct PresentationCode = @SymbolFull + '=' in Trade.ProviderToInstrument. |
| 3 | @ExchangeID | INT | YES | NULL | CODE-BACKED | Exchange identifier. Required. Drives RequiresW8Ben logic: ExchangeID IN (4, 5, 20) = US exchange = W-8BEN required. Written to Trade.ProviderToInstrument.ExchangeID is not directly written - used only for W-8BEN calculation. |
| 4 | @Precision | TINYINT | YES | NULL | CODE-BACKED | Decimal precision for rate display. Required. Written directly to Trade.ProviderToInstrument.Precision. |
| 5 | @AboveDollarPrecision | TINYINT | YES | NULL | CODE-BACKED | Precision used for rates above $1.00. Required. Written to Trade.ProviderToInstrument.AboveDollarPrecision. |
| 6 | @Unit | INT | YES | NULL | CODE-BACKED | Contract unit size. Written to Trade.ProviderToInstrument.Unit via ISNULL(@Unit, 1) - defaults to 1 if not provided. |
| 7 | @MarketRange | INT | YES | NULL | CODE-BACKED | Fixed market range in pips for slippage protection. Written to ProviderToInstrument.MarketRange via ISNULL(@MarketRange, 0). |
| 8 | @MaxStopLossPercentage | DECIMAL(5,2) | YES | NULL | CODE-BACKED | Maximum stop-loss as percentage of position. Written via ISNULL(@MaxStopLossPercentage, 100) - defaults to 100% (no restriction). |
| 9 | @AllowedRateDiffPercentage | DECIMAL(5,2) | YES | NULL | CODE-BACKED | Allowed rate difference percentage for order execution. Written via ISNULL(@AllowedRateDiffPercentage, -1) - -1 means no restriction. |
| 10 | @MarketRangeValidationType | TINYINT | YES | NULL | CODE-BACKED | Type of market range validation for order slippage protection. Written via ISNULL(@MarketRangeValidationType, 2). |
| 11 | @MarketRangePercentage | DECIMAL(5,2) | YES | NULL | CODE-BACKED | Market range as a percentage (alternative to fixed pips). Written via ISNULL(@MarketRangePercentage, 1) - defaults to 1%. |
| 12 | @AllowedOpenOrderType | TINYINT | YES | NULL | CODE-BACKED | Allowed order types for opening positions. Written via ISNULL(@AllowedOpenOrderType, 1). |
| 13 | @UnitsQuantityType | TINYINT | YES | NULL | CODE-BACKED | How units quantity is expressed for this instrument. Written via ISNULL(@UnitsQuantityType, 1). |
| 14 | @TradeUnitType | TINYINT | YES | NULL | CODE-BACKED | Unit type for trading (lots, units, etc.). Written via ISNULL(@TradeUnitType, 0). |
| 15 | @StopLossMarginInAssetCurrency | DECIMAL(16,8) | YES | NULL | CODE-BACKED | Stop-loss margin in the asset's currency. Written via ISNULL(@StopLossMarginInAssetCurrency, 1). |
| 16 | @InitialMarginInAssetCurrency | DECIMAL(16,8) | YES | NULL | CODE-BACKED | Initial margin in the asset's currency. Written via ISNULL(@InitialMarginInAssetCurrency, 1). |
| 17 | @OrderFillBehaviorType | TINYINT | YES | NULL | CODE-BACKED | Order fill behavior: how partial fills are handled. Written via ISNULL(@OrderFillBehaviorType, 0). |
| 18 | @AmountFormula | TINYINT | YES | NULL | CODE-BACKED | Formula type for position amount calculations. Written via ISNULL(@AmountFormula, 0). |
| 19 | @Slippage | DECIMAL(10,4) | YES | NULL | CODE-BACKED | Slippage tolerance for unmanaged (direct market) instruments. Required when @InstrumentOperationMode=1; must be NULL when @InstrumentOperationMode=0. Written directly to ProviderToInstrument.Slippage. |
| 20 | @InstrumentOperationMode | INT | YES | NULL | CODE-BACKED | Execution mode: 0=managed/STP (no slippage), 1=unmanaged/direct market (slippage applies). Gates @Slippage validation. Not directly written to any table - used only for validation. |
| 21 | @UnitMargin | INT | YES | NULL | CODE-BACKED | Margin requirement per unit. Parameter accepted but NOT used in current INSERT logic (ProviderToInstrument.UnitMargin is hardcoded to 0). |
| 22 | @InstrumentTypeID | INT | YES | NULL | CODE-BACKED | Instrument type identifier. Parameter accepted but NOT directly written in current INSERT logic. |
| 23 | @Price | dbo.dtPrice | YES | NULL | CODE-BACKED | Price UDT parameter. Accepted but not used in the current INSERT logic. Reserved for future use or legacy compatibility. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.InstrumentToFeeConfigV2 | Write (INSERT) | Creates zero-fee record for the instrument (all 8 fee types = 0). |
| @InstrumentID | Trade.ProviderToInstrument | Write (INSERT) | Creates provider-instrument mapping with trading defaults under ProviderID=1. |
| @InstrumentID | Trade.ProviderInstrumentToLeverage | Write (INSERT) | Creates default leverage option (LeverageID=1, IsDefault=1) under ProviderID=1. |
| @InstrumentID | Trade.ProviderInstrumentToLotCount | Write (INSERT) | Creates default lot count group mapping under ProviderID=1. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by SecurityOpsAPI-era instrument onboarding workflow after InsertInstrumentMetadataSecurityOpsAPI.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertInstrumentTradingData (procedure)
├── Trade.InstrumentToFeeConfigV2 (table) - INSERT target
├── Trade.ProviderToInstrument (table) - INSERT target
├── Trade.ProviderInstrumentToLeverage (table) - INSERT target
└── Trade.ProviderInstrumentToLotCount (table) - INSERT target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentToFeeConfigV2 | Table | INSERT with all fees = 0 |
| Trade.ProviderToInstrument | Table | INSERT with defaults; RequiresW8Ben derived from @ExchangeID |
| Trade.ProviderInstrumentToLeverage | Table | INSERT LeverageID=1, IsDefault=1 |
| Trade.ProviderInstrumentToLotCount | Table | INSERT LotCountGroupID=0, LotCountID=1, IsDefault=1 |

### 6.2 Objects That Depend On This

No dependents found in stored procedures. Called externally by instrument onboarding API.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Required params check | Validation | RAISERROR if @InstrumentID, @SymbolFull, @ExchangeID, @Precision, or @AboveDollarPrecision IS NULL |
| Slippage/mode consistency | Validation | RAISERROR if @Slippage NULL with InstrumentOperationMode=1, or @Slippage NOT NULL with InstrumentOperationMode=0 |
| Explicit transaction | Transaction | BEGIN TRAN ... COMMIT with ROLLBACK on CATCH |

---

## 8. Sample Queries

### 8.1 Execute the procedure for a US equity
```sql
EXEC Trade.InsertInstrumentTradingData
    @InstrumentID = 9999,
    @SymbolFull = 'EXMP.US',
    @ExchangeID = 4,         -- US exchange: RequiresW8Ben = 1
    @Precision = 2,
    @AboveDollarPrecision = 2,
    @Unit = 1,
    @InstrumentOperationMode = 0,  -- managed/STP
    @Slippage = NULL;
```

### 8.2 Verify the 4 tables were populated
```sql
SELECT 'FeeConfig' AS [Table], InstrumentID FROM Trade.InstrumentToFeeConfigV2 WITH (NOLOCK) WHERE InstrumentID = 9999
UNION ALL SELECT 'ProviderToInstrument', InstrumentID FROM Trade.ProviderToInstrument WITH (NOLOCK) WHERE InstrumentID = 9999
UNION ALL SELECT 'Leverage', InstrumentID FROM Trade.ProviderInstrumentToLeverage WITH (NOLOCK) WHERE InstrumentID = 9999
UNION ALL SELECT 'LotCount', InstrumentID FROM Trade.ProviderInstrumentToLotCount WITH (NOLOCK) WHERE InstrumentID = 9999;
```

### 8.3 Check W-8BEN flag assignment for US exchanges
```sql
SELECT p.InstrumentID, m.SymbolFull, m.ExchangeID, p.RequiresW8Ben
FROM   Trade.ProviderToInstrument p WITH (NOLOCK)
       JOIN Trade.InstrumentMetaData m WITH (NOLOCK) ON p.InstrumentID = m.InstrumentID
WHERE  p.RequiresW8Ben = 1
ORDER  BY m.ExchangeID, m.SymbolFull;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertInstrumentTradingData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertInstrumentTradingData.sql*
