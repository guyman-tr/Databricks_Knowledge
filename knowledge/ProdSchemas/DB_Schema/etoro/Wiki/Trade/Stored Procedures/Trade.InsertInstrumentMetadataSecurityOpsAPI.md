# Trade.InsertInstrumentMetadataSecurityOpsAPI

> Atomically creates a new tradeable instrument across 5 tables (InstrumentMetaData, Dictionary.Currency, Trade.Instrument, History.SplitRatio, InstrumentImages) in a single transaction, called by the Security Operations API as Step 1 of the instrument onboarding workflow.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID - anchors all inserts across 5 tables |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertInstrumentMetadataSecurityOpsAPI is the primary instrument creation procedure used by the Security Operations (SecOps) internal API. It answers the operational question: "How do I add a brand new instrument to the eToro trading platform?" In a single atomic transaction, it bootstraps all the infrastructure a new instrument needs to be visible, tradeable, and priced - writing to InstrumentMetaData (display config), Dictionary.Currency (asset identity), Trade.Instrument (trading parameters), History.SplitRatio (price adjustment history placeholder), and Trade.InstrumentImages (CDN image registry).

This procedure exists because adding an instrument requires consistent, atomic registration across multiple subsystems. Without this procedure, partial instrument creation (e.g., metadata without trading parameters, or an instrument without a currency record) would leave the platform in an inconsistent state. The design deliberately uses InstrumentID as the shared key across ALL tables - including Dictionary.Currency (CurrencyID = InstrumentID) and Trade.Instrument (BuyCurrencyID = InstrumentID) - reflecting that on eToro, every tradeable asset is simultaneously a currency in the pricing model.

Data flow: This procedure is **Step 1 of 4** in the full instrument onboarding workflow (per Confluence: Instrument Insertion - Stored Procedures): (1) InsertInstrumentMetadataSecurityOpsAPI - base instrument creation; (2) InsertLiquidityProviderContractsBatchSecurityOpsAPI - LP contract setup; (3) Price.InsertPricingConfiguration - price throttling config; (4) InsertInstrumentClosingPriceSourceData - closing price source. The procedure is called exclusively by the Security Operations API (SMOpsAPI permission set). A Maintenance.Feature flag (FeatureID=22) gates whether LP contracts from the @Contracts TVP are inserted as part of this call or deferred to the dedicated LP batch procedure.

---

## 2. Business Logic

### 2.1 InstrumentID = CurrencyID = BuyCurrencyID Identity Pattern

**What**: On eToro, every instrument's numeric ID serves simultaneously as the instrument ID, its buy-side currency ID, and its Dictionary.Currency record ID. This shared keyspace is a fundamental platform design decision.

**Columns/Parameters Involved**: `@InstrumentID`, `@CurrencyID` (derived), `@BuyCurrencyID` (derived), `@CurrencyTypeID` (derived)

**Rules**:
- @CurrencyID = @InstrumentID: The instrument IS its own currency in Dictionary.Currency.
- @BuyCurrencyID = @InstrumentID: The buy side of the instrument pair uses the instrument's own ID.
- @CurrencyTypeID = @InstrumentTypeID: Currency type mirrors instrument type.
- @Abbreviation = @SymbolFull: The currency abbreviation in Dictionary.Currency equals the full symbol.
- @Name = @InstrumentDisplayName: Currency name equals instrument display name.

**Diagram**:
```
@InstrumentID (e.g., 1234)
       |
       +---> Trade.InstrumentMetaData.InstrumentID = 1234
       |
       +---> Dictionary.Currency.CurrencyID = 1234 (same key)
       |     Dictionary.Currency.Name = @InstrumentDisplayName
       |     Dictionary.Currency.Abbreviation = @SymbolFull
       |
       +---> Trade.Instrument.InstrumentID = 1234
       |     Trade.Instrument.BuyCurrencyID = 1234 (self-referencing)
       |     Trade.Instrument.SellCurrencyID = @SellCurrencyID (e.g., USD)
       |
       +---> History.SplitRatio.InstrumentID = 1234 (placeholder row)
       +---> Trade.InstrumentImages.InstrumentID = 1234 (4 image records)
```

### 2.2 Feature Flag Gated LP Contract Insertion

**What**: Whether liquidity provider contracts are inserted as part of this call is controlled by a Maintenance.Feature flag, not hardcoded. This allows the LP contract insertion to be moved to the separate InsertLiquidityProviderContractsBatchSecurityOpsAPI procedure without changing the caller.

**Columns/Parameters Involved**: `@Contracts` (TVP), Maintenance.Feature FeatureID=22

**Rules**:
- IF Maintenance.Feature FeatureID=22 AND Value=1 (enabled): @Contracts TVP is iterated and rows are inserted into Trade.LiquidityProviderContracts with FromDate=ToDate=GETDATE().
- IF feature is disabled: LP contracts are NOT inserted here. The separate procedure InsertLiquidityProviderContractsBatchSecurityOpsAPI must be called explicitly as Step 2.
- The @Contracts TVP is ALWAYS accepted by the procedure signature regardless of feature flag state.

### 2.3 Hardcoded Infrastructure Defaults

**What**: Many Trade.Instrument and Trade.InstrumentMetaData fields are hardcoded to system defaults, not exposed as parameters. This reflects that new instruments always start with the same infrastructure profile.

**Columns/Parameters Involved**: `PriceServerID`, `ShardID`, `IsMajor`, `OMEID`, `CandleTimeframeGroup`, `ContractExpire`, image URLs

**Rules**:
- PriceServerID = 100: All new instruments use price server 100 (hardcoded).
- ShardID = 8: New instruments route to shard 8 (hardcoded).
- IsMajor = 0: New instruments are never classified as "major" on creation.
- OMEID = NULL: No OME assignment at creation time.
- ContractExpire = 0: Instruments do not expire by default.
- CandleTimeframeGroup = 1: All new instruments use timeframe group 1 for charting.
- Image URLs: CDN defaults from etoro-cdn.etorostatic.com/market-avatars/defaults/ (35x35, 50x50, 150x150 px, plus SVG).
- Ticker (in InstrumentMetaData) = '/ticker': Default ticker pattern before exchange-specific ticker is assigned.

### 2.4 SplitRatio Placeholder Row

**What**: A placeholder History.SplitRatio row is inserted spanning 2000-2100 with all ratios = 1, ensuring the split ratio system always finds a valid baseline record for new instruments.

**Rules**:
- MinDate = '2000-01-01', MaxDate = '2100-01-01': Full historical coverage.
- PriceRatio = 1, AmountRatio = 1, PriceRatioUnAdjusted = 1.0, AmountRatioUnAdjusted = 1.0: No adjustments at creation (1:1 ratio = no split).
- All IsCompleted* flags = 0: Processing jobs have not yet run.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Contracts | Trade.LiquidityProviderContractTableType READONLY | NO | - | CODE-BACKED | Table-valued parameter containing liquidity provider contract data (LiquidityProviderID, InstrumentID, Ticker, ExchangeID, RateConversionFactor). Inserted into Trade.LiquidityProviderContracts only if Maintenance.Feature FeatureID=22 is enabled. May be passed empty if LP contracts are handled by the separate batch procedure. |
| 2 | @InstrumentID | INT | NO | - | VERIFIED | Unique instrument identifier. Serves as the shared key across ALL 5 target tables - also used as CurrencyID (Dictionary.Currency) and BuyCurrencyID (Trade.Instrument). See Section 2.1 for the InstrumentID = CurrencyID identity pattern. |
| 3 | @InstrumentDisplayName | VARCHAR(50) | NO | - | VERIFIED | Human-readable display name for the instrument (e.g., "Apple Inc."). Written to Trade.InstrumentMetaData.InstrumentDisplayName AND Dictionary.Currency.Name. Both tables receive the same value via @Name = @InstrumentDisplayName. |
| 4 | @Industry | VARCHAR(50) | YES | NULL | CODE-BACKED | Industry classification for the instrument (e.g., "Technology", "Healthcare"). Written to Trade.InstrumentMetaData.Industry. Optional - NULL if the instrument has no industry classification. |
| 5 | @CompanyInfo | VARCHAR(50) | YES | NULL | CODE-BACKED | Additional company description or info text. Written to Trade.InstrumentMetaData.CompanyInfo. Optional - NULL for non-equity instruments. |
| 6 | @InstrumentVisible | INT | NO | - | CODE-BACKED | Visibility flag controlling whether the instrument appears in the UI instrument picker and platform surfaces. Written to Trade.InstrumentMetaData.InstrumentVisible. Typically 0 (hidden) on initial creation until the instrument is ready for users; Trade.DisableInstrument / dbo.EnableInstrument toggle this post-creation. |
| 7 | @Symbol | VARCHAR(50) | NO | - | CODE-BACKED | Short trading symbol for the instrument (e.g., "AAPL"). Written to Trade.InstrumentMetaData.Symbol. Used in platform displays and API responses. |
| 8 | @SymbolFull | VARCHAR(50) | NO | - | VERIFIED | Full symbol name (e.g., "AAPL.US"). Written to Trade.InstrumentMetaData.SymbolFull AND used as @Abbreviation for Dictionary.Currency.Abbreviation. The currency abbreviation for this instrument equals its full symbol. |
| 9 | @Tradable | INT | NO | - | CODE-BACKED | Tradability flag controlling whether users can open new positions. Written to Trade.InstrumentMetaData.Tradable. Typically 0 (not tradable) on creation until the instrument passes QA; toggled by Trade.DisableInstrument / dbo.EnableInstrument. |
| 10 | @ExchangeID | INT | NO | - | CODE-BACKED | Exchange identifier for the instrument. Written to Trade.InstrumentMetaData.ExchangeID. Also used to look up ExchangeDescription from Dictionary.ExchangeInfo, which is written to Trade.InstrumentMetaData.Exchange (the text name). |
| 11 | @StocksIndustryID | INT | YES | NULL | CODE-BACKED | Stock industry classification ID. Written to Trade.InstrumentMetaData.StocksIndustryID. Optional - NULL for non-stock instruments (crypto, currencies, indices). |
| 12 | @ISINCode | VARCHAR(50) | YES | NULL | CODE-BACKED | International Securities Identification Number (ISIN). Written to BOTH Trade.InstrumentMetaData.ISINCode AND Dictionary.Currency.ISINCode. Used for regulatory identification of equity instruments. Optional for non-equity assets. |
| 13 | @ISINCountryCode | VARCHAR(50) | YES | NULL | CODE-BACKED | Two-letter country code component of the ISIN (e.g., "US", "GB"). Written to Trade.InstrumentMetaData.ISINCountryCode. Optional. |
| 14 | @InstrumentTypeSubCategoryID | INT | YES | NULL | CODE-BACKED | Sub-category classification within the instrument type hierarchy. Written to Trade.InstrumentMetaData.InstrumentTypeSubCategoryID. Optional - used to distinguish subtypes within a major InstrumentTypeID. |
| 15 | @InstrumentTypeID | INT | NO | - | VERIFIED | Instrument type identifier (e.g., stock, crypto, currency, index). Written to Trade.InstrumentMetaData.InstrumentTypeID AND used as @CurrencyTypeID for Dictionary.Currency.CurrencyTypeID. Controls which pricing formulas, features, and regulations apply. |
| 16 | @PriceSourceID | INT | NO | - | CODE-BACKED | Price source identifier linking the instrument to its pricing feed provider. Written to Trade.InstrumentMetaData.PriceSourceID. Determines which price server delivers real-time quotes. |
| 17 | @Cusip | VARCHAR(50) | YES | NULL | CODE-BACKED | CUSIP (Committee on Uniform Securities Identification Procedures) identifier, primarily for US equities. Written to Trade.InstrumentMetaData.Cusip. Optional. |
| 18 | @SellCurrencyID | INT | NO | - | CODE-BACKED | Currency ID of the instrument's sell (quote) side, typically USD (CurrencyID=7 or similar). Written to Trade.Instrument.SellCurrencyID. Together with BuyCurrencyID (= @InstrumentID), forms the instrument's currency pair in Trade.Instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ExchangeID | Dictionary.ExchangeInfo | Lookup (SELECT) | Reads ExchangeDescription to populate Trade.InstrumentMetaData.Exchange text column before INSERT. |
| @InstrumentID (inserts) | Trade.InstrumentMetaData | Write (INSERT) | Creates the core instrument metadata record. |
| @InstrumentID (inserts) | Dictionary.Currency | Write (INSERT) | Registers the instrument as a currency - CurrencyID = InstrumentID. |
| @InstrumentID (inserts) | Trade.Instrument | Write (INSERT) | Creates the trading parameters record with hardcoded defaults. |
| @InstrumentID (inserts) | History.SplitRatio | Write (INSERT) | Creates placeholder split ratio row spanning 2000-2100 with ratios = 1. |
| @InstrumentID (inserts) | Trade.InstrumentImages | Write (INSERT) | Creates 4 default CDN image records (35px, 50px, 150px, SVG). |
| @Contracts (conditional) | Trade.LiquidityProviderContracts | Write (INSERT, feature-gated) | Inserts LP contracts from TVP only when Maintenance.Feature FeatureID=22 is enabled. |
| FeatureID=22 | Maintenance.Feature | Lookup (SELECT) | Feature flag check controls LP contract insertion path. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Security Operations API | SMOpsAPI permission set | External caller | The only caller in the DB repo. Invoked as Step 1 of the instrument onboarding workflow. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertInstrumentMetadataSecurityOpsAPI (procedure)
├── Dictionary.ExchangeInfo (table) - lookup
├── Trade.InstrumentMetaData (table) - INSERT target
├── Dictionary.Currency (table) - INSERT target
├── Trade.Instrument (table) - INSERT target
├── History.SplitRatio (table) - INSERT target
├── Trade.InstrumentImages (table) - INSERT target
├── Trade.LiquidityProviderContracts (table) - conditional INSERT target
└── Maintenance.Feature (table) - feature flag check
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ExchangeInfo | Table | SELECT ExchangeDescription WHERE ExchangeID = @ExchangeID to populate Exchange text field |
| Trade.InstrumentMetaData | Table | Primary INSERT target - main instrument metadata |
| Dictionary.Currency | Table | INSERT target - instrument registered as currency (CurrencyID = InstrumentID) |
| Trade.Instrument | Table | INSERT target - trading parameters with hardcoded defaults |
| History.SplitRatio | Table | INSERT target - placeholder split ratio row |
| Trade.InstrumentImages | Table | INSERT target - 4 default CDN image records |
| Trade.LiquidityProviderContracts | Table | Conditional INSERT target (requires FeatureID=22 enabled) |
| Maintenance.Feature | Table | Feature flag lookup (FeatureID=22, Value=1 enables LP contract insertion) |
| Trade.LiquidityProviderContractTableType | UDT | TVP type used by @Contracts parameter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Security Operations API (external) | External client | Step 1 in the 4-step instrument onboarding workflow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Explicit transaction | Transaction | BEGIN TRY / BEGIN TRANSACTION ... COMMIT / ROLLBACK on CATCH. All 5-6 table inserts are atomic - either all succeed or all roll back. |
| SET NOCOUNT ON | Session setting | Suppresses row-count messages for performance. |

---

## 8. Sample Queries

### 8.1 Execute the procedure to create a new stock instrument
```sql
DECLARE @Contracts Trade.LiquidityProviderContractTableType;

EXEC Trade.InsertInstrumentMetadataSecurityOpsAPI
    @Contracts = @Contracts,
    @InstrumentID = 9999,
    @InstrumentDisplayName = 'Example Corp',
    @InstrumentVisible = 0,
    @Symbol = 'EXMP',
    @SymbolFull = 'EXMP.US',
    @Tradable = 0,
    @ExchangeID = 1,
    @InstrumentTypeID = 5,
    @PriceSourceID = 1,
    @SellCurrencyID = 7;
```

### 8.2 Verify all 5 tables were populated after creation
```sql
SELECT 'InstrumentMetaData' AS TableName, InstrumentID, InstrumentDisplayName
FROM   Trade.InstrumentMetaData WITH (NOLOCK) WHERE InstrumentID = 9999
UNION ALL
SELECT 'Currency', CurrencyID, Name FROM Dictionary.Currency WITH (NOLOCK) WHERE CurrencyID = 9999
UNION ALL
SELECT 'Instrument', InstrumentID, CAST(SellCurrencyID AS VARCHAR) FROM Trade.Instrument WITH (NOLOCK) WHERE InstrumentID = 9999;
```

### 8.3 Check feature flag controlling LP contract insertion
```sql
SELECT FeatureID, FeatureName, Value,
       CASE WHEN CAST(Value AS INT) = 1 THEN 'LP contracts inserted in InsertInstrumentMetadataSecurityOpsAPI'
            ELSE 'LP contracts handled by separate InsertLiquidityProviderContractsBatchSecurityOpsAPI' END AS Behavior
FROM   Maintenance.Feature WITH (NOLOCK)
WHERE  FeatureID = 22;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Instrument Insertion - Stored Procedures](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13273465990) | Confluence | Full workflow sequence (Steps 1-4), InstrumentID=CurrencyID identity pattern, parameter purpose documentation, feature flag LP contract gating context |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1, 8, 9, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertInstrumentMetadataSecurityOpsAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertInstrumentMetadataSecurityOpsAPI.sql*
