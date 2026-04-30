# Trade.InsertInstrumentMetaData

> Full instrument metadata provisioning SP: validates 8 required fields, resolves exchange name, then atomically inserts into Dictionary.Currency, Trade.InstrumentMetaData, and Trade.Instrument - creating a new tradeable asset record from scratch.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID INT, @Symbol VARCHAR(50) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertInstrumentMetaData is the **core instrument creation SP**. When a new financial instrument is onboarded to eToro, this SP creates its foundational records across three tables: a currency entry in `Dictionary.Currency` (instruments are represented as currency pairs), the display and classification metadata in `Trade.InstrumentMetaData`, and the core trading parameters in `Trade.Instrument`. Together these three records make the instrument visible to the trading system.

This SP exists because instrument onboarding requires consistent, validated setup across multiple tables. It enforces data quality through upfront validation (8 THROW checks before any insert), resolves the exchange name from `Price.Exchange`, and uses sensible defaults for attributes like tradability (starts as 0/invisible/non-tradeable until explicitly activated) and image URLs (CDN-based by instrument ID convention).

New instruments start as invisible (`InstrumentVisible=0`) and non-tradeable (`Tradable=0`), requiring a subsequent activation step. The ShardID default of 666 and OMEID default of -1 are placeholder values updated post-onboarding.

---

## 2. Business Logic

### 2.1 Input Validation (8 Guards)

**What**: Validates all critical parameters before any database write.

**Rules**:
- `@InstrumentID IS NULL OR <= 0` -> THROW 50000 'Invalid InstrumentID'
- `@currencyId IS NULL OR <= 0` -> THROW 50000 'Invalid currencyId'
- `@InstrumentTypeID IS NULL OR <= 0` -> THROW 50000 'Invalid InstrumentTypeID'
- `@InstrumentDisplayName IS NULL` -> THROW 50000
- `@Symbol IS NULL` -> THROW 50000
- `@SymbolFull IS NULL` -> THROW 50000
- `@ExchangeID IS NULL OR <= 0` -> THROW 50000 'Invalid ExchangeID'
- `@StocksIndustryID IS NULL OR <= 0` -> THROW 50000 'Invalid StocksIndustryID'
- `@PriceSourceID IS NULL` -> THROW 50000 'Invalid PriceSourceID'
- Exchange existence: `SELECT @Exchange = Name FROM Price.Exchange WHERE ExchangeID = @ExchangeID` -> if NULL: THROW 'Exchange not found...'

### 2.2 Dictionary.Currency Insert

**What**: Creates a currency record for the instrument (instruments are modeled as currency pairs in eToro's system).

**Target**: `Dictionary.Currency`

**Mapped Values**:
- `CurrencyID` = @InstrumentID (instrument IS its own currency)
- `CurrencyTypeID` = @InstrumentTypeID
- `Name` = @InstrumentDisplayName
- `Abbreviation` = @SymbolFull
- `Mask` = 0, `EEAStockExchange` = 0 (defaults)
- `ISINCode` = @ISINCode

### 2.3 Trade.InstrumentMetaData Insert

**What**: Creates the display and classification metadata for the instrument.

**Target**: `Trade.InstrumentMetaData`

**Key defaults hardcoded**:
- `InstrumentVisible` = 0 (hidden until activated)
- `Tradable` = 0 (non-tradeable until activated)
- `CandleTimeframeGroup` = 2 (standard candle group)
- `InstrumentTypeImage` = NULL (set separately)
- `Ticker` = '/ticker' (placeholder)
- `ChartTicker` = NULL
- `DailyRolloverFee`, `WeekendRolloverFee`, `ContractRolloverFee` = NULL (set separately)
- `UnderlyingExchangeID`, `SEDOL` = NULL
- `SubCategory` = NULL
- Image URLs: CDN pattern `https://etoro-cdn.etorostatic.com/market-avatars/{InstrumentID}/{size}.png`

### 2.4 Trade.Instrument Insert

**What**: Creates the core trading parameters record.

**Target**: `Trade.Instrument`

**Key values**:
- `BuyCurrencyID` = @InstrumentID (instrument's own ID as buy currency)
- `SellCurrencyID` = @currencyId (the settlement currency, e.g., USD=1)
- `TradeRange` = 100 (default trade range)
- `DollarRatio` = 1.00
- `PipDifferenceThreshold` = 200
- `IsMajor` = 0
- `PriceServerID` = 666 (placeholder, updated post-onboarding)
- `ShardID` = @ShardID (default 666)
- `OMEID` = -1 (placeholder)
- `OperationMode` = @OperationMode (default 1)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The new instrument's ID. Used as PK in all three insert targets and as BuyCurrencyID in Trade.Instrument. Must be positive (validated). |
| 2 | @currencyId | INT | NO | - | CODE-BACKED | Settlement currency ID (e.g., 1=USD). Used as SellCurrencyID in Trade.Instrument. Must be positive (validated). |
| 3 | @InstrumentTypeID | INT | NO | - | CODE-BACKED | Instrument type (e.g., 1=Stocks, 4=Index, 6=ETF, 10=Crypto). Used as CurrencyTypeID in Dictionary.Currency and InstrumentTypeID in Trade.InstrumentMetaData. Must be positive (validated). |
| 4 | @InstrumentDisplayName | VARCHAR(255) | NO | - | CODE-BACKED | Human-readable display name (e.g., 'Apple Inc.'). Stored as Name in Dictionary.Currency and InstrumentDisplayName in Trade.InstrumentMetaData. NULL is rejected. |
| 5 | @Industry | VARCHAR(255) | YES | - | CODE-BACKED | Industry classification string (e.g., 'Technology', 'Financial Services'). Stored in Trade.InstrumentMetaData.Industry for display. |
| 6 | @CompanyInfo | VARCHAR(MAX) | YES | - | CODE-BACKED | Descriptive text about the company/asset for display on instrument pages. Stored in Trade.InstrumentMetaData.CompanyInfo. |
| 7 | @Symbol | VARCHAR(50) | NO | - | CODE-BACKED | Short ticker symbol (e.g., 'AAPL'). Stored in Trade.InstrumentMetaData.Symbol. NULL is rejected. |
| 8 | @SymbolFull | VARCHAR(100) | NO | - | CODE-BACKED | Full symbol or abbreviation (e.g., 'AAPL.US'). Stored as both Abbreviation in Dictionary.Currency and SymbolFull in Trade.InstrumentMetaData. NULL is rejected. |
| 9 | @ExchangeID | INT | NO | - | CODE-BACKED | Exchange ID from Price.Exchange. Exchange name is resolved from this table and stored in Trade.InstrumentMetaData.Exchange. Must exist in Price.Exchange (validated). |
| 10 | @StocksIndustryID | INT | NO | - | CODE-BACKED | Stocks industry classification ID. Stored in Trade.InstrumentMetaData.StocksIndustryID. Must be positive (validated). |
| 11 | @ISINCode | VARCHAR(50) | YES | - | CODE-BACKED | ISIN security identifier. Stored in both Dictionary.Currency.ISINCode and Trade.InstrumentMetaData.ISINCode. |
| 12 | @ISINCountryCode | VARCHAR(50) | YES | - | CODE-BACKED | ISIN country code component. Stored in Trade.InstrumentMetaData.ISINCountryCode. |
| 13 | @PriceSourceID | INT | NO | - | CODE-BACKED | Price data source identifier. Stored in Trade.InstrumentMetaData.PriceSourceID. NULL rejected (validated). |
| 14 | @Cusip | VARCHAR(50) | YES | - | CODE-BACKED | CUSIP security identifier (US market). Stored in Trade.InstrumentMetaData.Cusip. |
| 15 | @CFICode | VARCHAR(6) | YES | NULL | CODE-BACKED | CFI (Classification of Financial Instruments) code. Optional. Stored in Trade.InstrumentMetaData.CFICode. |
| 16 | @ShardID | INT | YES | 666 | CODE-BACKED | Database shard assignment. Default 666 (placeholder). Stored in Trade.Instrument.ShardID. Updated post-onboarding for proper shard routing. |
| 17 | @OperationMode | INT | YES | 1 | CODE-BACKED | Trading operation mode. Default 1. Stored in Trade.Instrument.OperationMode. Controls how the instrument processes orders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (validates against) | Price.Exchange | READER (cross-schema) | Resolves exchange name from ExchangeID |
| (inserts into) | Dictionary.Currency | WRITER (cross-schema) | Currency record for the new instrument |
| (inserts into) | Trade.InstrumentMetaData | WRITER | Display and classification metadata |
| (inserts into) | Trade.Instrument | WRITER | Core trading parameters |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Instrument onboarding tooling (external) | EXEC Trade.InsertInstrumentMetaData | Caller | Called during instrument onboarding to create the fundamental instrument record |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertInstrumentMetaData (procedure)
|- Price.Exchange (table - cross-schema, validation)
|- Dictionary.Currency (table - cross-schema, write)
|- Trade.InstrumentMetaData (table, write)
`-- Trade.Instrument (table, write)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.Exchange | Table (cross-schema) | Resolves Exchange Name from ExchangeID |
| Dictionary.Currency | Table (cross-schema) | Insert: currency record for instrument |
| Trade.InstrumentMetaData | Table | Insert: display/classification metadata |
| Trade.Instrument | Table | Insert: core trading parameters |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Instrument onboarding workflow | Process | Primary creation SP for new instruments |
| Trade.InsertInstrumentMarketData | Procedure | Sibling SP - provisions split ratio, LP contracts, images |
| Trade.InsertInstrumentTradingData | Procedure | Sibling SP (in batch) - trading data provisioning |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| 9 input guards | THROW 50000 | Rejects NULL/invalid values for all critical params before any write |
| Exchange existence | SELECT + THROW | Exchange must exist in Price.Exchange |
| Transaction | BEGIN TRAN / COMMIT / ROLLBACK | All three inserts atomic |
| Tradable=0, InstrumentVisible=0 | Hardcoded | New instruments start hidden and non-tradeable |
| ShardID/PriceServerID = 666 | Placeholder defaults | Must be updated post-onboarding |
| BuyCurrencyID = @InstrumentID | Convention | eToro models instruments as their own buy-side currency |

---

## 8. Sample Queries

### 8.1 Verify instrument creation

```sql
-- After EXEC Trade.InsertInstrumentMetaData:
SELECT i.InstrumentID, m.InstrumentDisplayName, m.Symbol, m.InstrumentTypeID, i.SellCurrencyID, i.OperationMode
FROM Trade.Instrument i WITH (NOLOCK)
JOIN Trade.InstrumentMetaData m WITH (NOLOCK) ON m.InstrumentID = i.InstrumentID
WHERE i.InstrumentID = @InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertInstrumentMetaData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertInstrumentMetaData.sql*
