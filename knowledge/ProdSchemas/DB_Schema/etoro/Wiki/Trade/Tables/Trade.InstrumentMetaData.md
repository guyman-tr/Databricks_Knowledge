# Trade.InstrumentMetaData

> Extended metadata for each tradeable instrument (display names, symbols, images, regulatory identifiers, fee config) - UI presentation and operational config layer that supplements Trade.Instrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (int, PK) |
| **Partition** | No |
| **Indexes** | 5 active (clustered PK, UNQ SymbolFull, IX_Cusip, IX_InstrumentTypeID) |

---

## 1. Business Meaning

Trade.InstrumentMetaData stores the extended configuration and presentation metadata for every tradeable instrument on the eToro platform. While Trade.Instrument defines the core buy/sell currency pairing and Dictionary.Currency holds asset definitions, InstrumentMetaData adds the layer that drives the UI and operational rules: display names, ticker symbols, CDN image URLs, exchange assignments, regulatory codes (ISIN, CUSIP, SEDOL), rollover fees, chart timeframe groups, and visibility/tradability flags.

This table exists because the trading engine needs more than just the instrument pair - it needs to know how to display the instrument in the app, which exchange to use for price feeds, which chart intervals to offer, whether the instrument is tradable or visible, and how to identify it for compliance (ISIN for stocks, CFI codes, etc.). Without InstrumentMetaData, the platform could not render instrument pickers, show correct symbols in position views, or route equity orders to the right exchange.

Data flows: Rows are created by Trade.InsertInstrumentMetaData, Trade.InsertInstrumentMetadataSecurityOpsAPI, Stocks.AddNewStock, and Internal.Newcurrency_3163 (legacy instrument setup). Procedures that update metadata include Trade.UpdateInstrumentsSymbolFull, Trade.UpdateInstrumentExchange, Trade.UpdateInstrumentType, Trade.UpdateCusip, Trade.UpdateInstrumentsMetaDataConfigurations, and Trade.UpdateFuturesMetadataSecurityOpsAPI. Trade.DisableInstrument and dbo.EnableInstrument toggle Tradable and InstrumentVisible. The table is system-versioned (temporal) to History.InstrumentMetaData; audit triggers log changes to History.AuditHistory. Read by 60+ views and procedures for positions, orders, dividends, fee calculation, and API responses.

---

## 2. Business Logic

### 2.1 Visibility and Tradability Control

**What**: Whether an instrument appears in the UI and can be traded. Two independent flags control display vs execution.

**Columns/Parameters Involved**: `InstrumentVisible`, `Tradable`

**Rules**:
- InstrumentVisible = 1: Instrument appears in discovery, search, and instrument lists. 0 = hidden from UI (e.g., delisted but positions still exist).
- Tradable = 1: Orders can be placed. 0 = trading disabled (e.g., during corporate actions, delisting).
- Trade.DisableInstrument sets both to 0. dbo.EnableInstrument sets both to 1.
- GetInstrumentsRates filters: (InstrumentVisible = 1 OR ProviderToInstrument.Enabled = 1) AND Tradable = 1 for price display.
- GetEnabledAndListedInstruments uses InstrumentMetaData to filter instruments visible and tradable per provider.

**Diagram**:
```
Instrument State:
InstrumentVisible=0, Tradable=0 -> Hidden and untradeable (delisted)
InstrumentVisible=1, Tradable=0 -> Visible but trading disabled
InstrumentVisible=1, Tradable=1 -> Active (normal state)
```

### 2.2 Candle Timeframe Group

**What**: Links the instrument to a group (Forex=1, Stocks=2) that defines which chart intervals are available via Trade.CandleGroupToIntervals.

**Columns/Parameters Involved**: `CandleTimeframeGroup`, Trade.CandleIntervalGroups.GroupID

**Rules**:
- 1 = Forex group (all 9 timeframes). 2 = Stocks group (same 9, different display rules). FK to Trade.CandleIntervalGroups.
- Trade.InsertInstrumentMetaData defaults to 2 (Stocks). Forex instruments use 1.
- Trade.GetInstrumentsTimeframeID joins InstrumentMetaData to CandleGroupToIntervals to return InstrumentID + TimeframeID for available chart intervals.

### 2.3 Instrument Type (Asset Class)

**What**: Asset class from Dictionary.CurrencyType - determines trading rules, min position size, price feed routing.

**Columns/Parameters Involved**: `InstrumentTypeID`, Dictionary.CurrencyType.CurrencyTypeID

**Rules**:
- 1=Forex, 2=Commodity, 3=CFD (legacy), 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType (constraint name FK_InstrumentMetaData_InstrumentType).
- Used by fee config (GetRolloverFeeAlertThresholds), exposure (Stocks.GetExposure), and instrument setup. Must match Dictionary.Currency.CurrencyTypeID for the same InstrumentID.

---

## 3. Data Overview

| InstrumentID | InstrumentDisplayName | Symbol | SymbolFull | InstrumentTypeID | CandleTimeframeGroup | Meaning |
|---|---|---|---|---|---|---|
| 1 | EUR/USD | EURUSD | EURUSD | 1 | 1 | Major forex pair. CandleTimeframeGroup=1 (Forex). Visible and tradable. PriceSourceID=0 (eToro internal). |
| 1001 | Apple | AAPL | AAPL | 5 | 2 | US equity (Stocks). CandleTimeframeGroup=2 (Stocks). ISINCode=US0378331005. PriceSourceID=3 (Xignite). ExchangeID=4 (NASDAQ). |
| 1002 | Alphabet | GOOG | GOOG | 5 | 2 | US equity (Stocks). Different StocksIndustryID (8=Technology vs 3=Consumer Goods). PriceSourceID=3. |
| 100000 | Bitcoin | BTC | BTC | 10 | 2 | Cryptocurrency. CandleTimeframeGroup=2. ExchangeID=8 (BATS). PriceSourceID=0 (eToro). |
| 610 | ETORIAN610 | ETORIAN610 | ETORIAN610 | 5 | 2 | Synthetic/etorian instrument. StocksIndustryID=3. Illustrates non-standard symbol usage. |

**Selection criteria for the 5 rows:**
- Forex (1), Stocks (1001, 1002, 610), Crypto (100000) to show asset class variety.
- Major forex, major equity, etorian edge case.
- Include InstrumentTypeID, CandleTimeframeGroup, and symbol patterns representative of the table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Primary key. References Trade.Instrument.InstrumentID. Same value as Dictionary.Currency.CurrencyID for the instrument. |
| 2 | InstrumentDisplayName | varchar(100) | NO | - | CODE-BACKED | Human-readable name shown in UI (e.g., "Apple", "EUR/USD"). Used in position displays, order forms, and APIs. |
| 3 | InstrumentTypeImage | varchar(max) | YES | - | NAME-INFERRED | URL or path for instrument type icon. Nullable; CDN avatars often built from InstrumentID instead (InstrumentImageSmall/etc). |
| 4 | Ticker | varchar(max) | YES | - | CODE-BACKED | Ticker path for price/quote APIs. Trade.InsertInstrumentMetaData sets '/ticker' by default. Used for external ticker lookups. |
| 5 | ChartTicker | varchar(max) | YES | - | NAME-INFERRED | Alternate ticker for charting services. Null when same as Ticker. |
| 6 | InstrumentImageSmall | varchar(max) | YES | - | CODE-BACKED | CDN URL for small avatar. Trade.InsertInstrumentMetaData builds: etoro-cdn.etorostatic.com/market-avatars/{InstrumentID}/35x35.png. |
| 7 | InstrumentImageMedium | varchar(max) | YES | - | CODE-BACKED | CDN URL for medium avatar. Pattern: .../50x50.png. |
| 8 | InstrumentImageLarge | varchar(max) | YES | - | CODE-BACKED | CDN URL for large avatar. Pattern: .../150x150.png. |
| 9 | Exchange | varchar(max) | YES | - | CODE-BACKED | Exchange name string (e.g., "NASDAQ"). Populated from Price.Exchange via ExchangeID. May be denormalized. |
| 10 | Industry | varchar(max) | YES | - | CODE-BACKED | Industry sector label (e.g., "Technology", "Consumer Goods"). Used for stocks; NULL for forex/crypto. |
| 11 | CompanyInfo | varchar(max) | YES | - | NAME-INFERRED | Extended company/instrument description. Nullable. |
| 12 | DailyRolloverFee | decimal(18,4) | YES | - | CODE-BACKED | Overnight holding fee rate for weekdays, per lot/unit. NULL when not configured. |
| 13 | WeekendRolloverFee | decimal(18,4) | YES | - | CODE-BACKED | Overnight fee for weekend holds. NULL when not configured. |
| 14 | ContractRolloverFee | decimal(18,4) | YES | - | CODE-BACKED | Rollover fee for contract-based instruments (futures, etc.). NULL when N/A. |
| 15 | InstrumentVisible | int | YES | (1) | CODE-BACKED | Visibility: 1 = shown in UI, 0 = hidden. Default 1. dbo.EnableInstrument/Trade.DisableInstrument set this. Filtered by GetInstrumentsRates, GetEnabledAndListedInstruments. |
| 16 | Symbol | varchar(100) | YES | - | CODE-BACKED | Short ticker symbol (e.g., "AAPL", "EURUSD"). Used for display and lookup. Not necessarily unique. |
| 17 | CandleTimeframeGroup | int | YES | - | CODE-BACKED | FK to Trade.CandleIntervalGroups.GroupID. 1=Forex, 2=Stocks. Controls which chart intervals are available. See [Trade.CandleIntervalGroups](Trade.CandleIntervalGroups.md). |
| 18 | SymbolFull | varchar(100) | YES | - | CODE-BACKED | Full/canonical symbol, UNIQUE. Used for instrument lookup (e.g., Trade.GetOrdersForExecutionReportV2_JUNK: SELECT InstrumentID FROM InstrumentMetaData WHERE Symbol = @Symbol). Primary identifier in Security Ops API. |
| 19 | Tradable | bit | YES | - | CODE-BACKED | 1 = orders allowed, 0 = trading disabled. Set by EnableInstrument/DisableInstrument. Required for GetInstrumentsRates, GetEnabledAndListedInstruments. |
| 20 | ExchangeID | int | YES | - | CODE-BACKED | FK to Price.Exchange. Primary exchange for this instrument. Used for fee config (Trade.ExchangeInstrumentFeeDefinition), price feed routing. trg_update_Trade_InstrumentMetaData validates ExchangeID exists in ExchangeInstrumentFeeDefinition. |
| 21 | StocksIndustryID | int | YES | - | CODE-BACKED | Industry classification for stocks. Dictionary.StocksIndustry or similar. NULL for forex/crypto. Used in Trade.GetInstrumentMetaDataExtend as Industry (ISNULL to 0). |
| 22 | ISINCode | varchar(30) | YES | - | CODE-BACKED | International Securities Identification Number. Required for stocks (e.g., US0378331005 for Apple). NULL for forex/crypto. Used for compliance and dividend matching. |
| 23 | ISINCountryCode | varchar(15) | YES | - | CODE-BACKED | Country prefix of ISIN (e.g., "US"). Audit-tracked. |
| 24 | ContractExpire | bit | NO | (0) | CODE-BACKED | 1 = instrument has expiry (futures, options). 0 = no expiry (stocks, forex, crypto). Default 0. |
| 25 | InstrumentTypeSubCategoryID | int | YES | - | CODE-BACKED | Subclassification within asset class. References Dictionary or lookup. NULL for most instruments. Trade.GetAllInstrumentTypeSubCategoryForAPI exposes subcategories. |
| 26 | InstrumentTypeID | int | YES | - | CODE-BACKED | Asset class. FK to Dictionary.CurrencyType.CurrencyTypeID. 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. See [Dictionary.CurrencyType](../Dictionary/Tables/Dictionary.CurrencyType.md). |
| 27 | PriceSourceID | int | NO | (0) | CODE-BACKED | Price feed source. 0 = eToro internal. 3 = Xignite (stocks/ETF). Validated via Dictionary.PriceSourceName. Used for price routing and allocation. |
| 28 | Cusip | varchar(255) | YES | - | CODE-BACKED | CUSIP identifier (US/Canada securities). Trade.UpdateCusip, Trade.GetInstrumentCusip, Trade.CusipsToInstrumentIDs. Indexed (IX_Cusip). |
| 29 | CreateDate | datetime | YES | (getutcdate()) | CODE-BACKED | UTC timestamp when the instrument metadata row was created. |
| 30 | UnderlyingExchangeID | int | YES | - | NAME-INFERRED | Exchange for underlying when instrument is derivative. NULL for spot instruments. |
| 31 | DbLoginName | (computed) | - | - | CODE-BACKED | Computed: suser_name(). Current DB login for audit context. |
| 32 | AppLoginName | (computed) | - | - | CODE-BACKED | Computed: CONVERT(varchar(500), context_info()). Application context for audit. |
| 33 | SysStartTime | datetime2(7) | NO | (getutcdate()) | CODE-BACKED | System-versioning start. Generated always as row start. |
| 34 | SysEndTime | datetime2(7) | NO | ('9999-12-31 23:59:59.9999999') | CODE-BACKED | System-versioning end. Generated always as row end. History in History.InstrumentMetaData. |
| 35 | SEDOL | varchar(50) | YES | - | CODE-BACKED | SEDOL identifier (UK securities). Alternative to ISIN/CUSIP for some instruments. |
| 36 | SubCategory | varchar(255) | YES | - | NAME-INFERRED | Human-readable subcategory label. May duplicate InstrumentTypeSubCategoryID. |
| 37 | CFICode | varchar(6) | YES | - | CODE-BACKED | Classification of Financial Instruments code (ISO 10962). 6-character code for instrument classification. Trade.InsertInstrumentMetaData accepts @CFICode. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (implicit) | Same PK; InstrumentMetaData extends Instrument. |
| CandleTimeframeGroup | Trade.CandleIntervalGroups | FK | Chart timeframe group (Forex/Stocks). |
| InstrumentTypeID | Dictionary.CurrencyType | FK | Asset class (Forex, Stocks, Crypto, etc.). |
| ExchangeID | Price.Exchange | Lookup | Primary exchange for price/execution. |
| StocksIndustryID | Dictionary.StocksIndustry | Lookup | Industry for stocks. |
| UnderlyingExchangeID | Price.Exchange | Lookup | Underlying exchange for derivatives. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInstrument | IMD | JOIN | Instrument deal view joins InstrumentMetaData. |
| Trade.GetInstrumentMetaData | - | View | Direct view over this table. |
| Trade.GetInstrumentMetaDataExtend | - | View | Extended metadata view. |
| Trade.GetPositionsForDataApi | meta | JOIN | Position data includes metadata. |
| Trade.GetAggregatedPositionsForDataApi | meta | JOIN | Aggregated positions. |
| Trade.GetPositionsForFeeBulkGeneral | IMD | JOIN | Fee calculation by instrument. |
| Trade.GetDividendsByStatus | IMD | JOIN | Dividend data with instrument metadata. |
| Trade.GetInstrumentByIdSecurityOpsAPI | - | SELECT | Security Ops API by InstrumentID. |
| Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI | im | JOIN | Futures metadata. |
| Trade.GetInstrumentSymbolFull | imd | FROM | Symbol lookup. |
| Trade.GetEnabledAndListedInstruments | m | JOIN | Enabled/listed filter. |
| Trade.GetInstrumentsAndInstrumentsGroups | imd | JOIN | Instruments and groups. |
| Trade.CheckValidInstruments | - | SELECT/UPDATE | Validation and copy logic. |
| Trade.InsertInstrumentMetaData | - | INSERT | Primary insert procedure. |
| Trade.InsertInstrumentMetadataSecurityOpsAPI | - | INSERT | Security Ops API insert. |
| Trade.DisableInstrument | - | UPDATE | Sets Tradable=0, InstrumentVisible=0. |
| dbo.EnableInstrument | - | UPDATE | Sets Tradable=1, InstrumentVisible=1. |
| Trade.UpdateInstrumentsSymbolFullExtend | timd | UPDATE | Symbol full updates. |
| Trade.USAggregatePositionBySymbolForMonitor | - | JOIN | US aggregation. |
| Trade.GetAleErrorReport / V2 | tim | JOIN | ALE error report. |
| Trade.FailedDelayedCopyOrders | tim | JOIN | Delayed copy orders. |
| Trade.GetBacktraderCustomerData | IMD/TIMD | JOIN | Backtrader data. |
| Trade.GetCustomerManualOpenPositions | m | JOIN | Manual positions. |
| Trade.AlertForExitOrders_which_should_have_clsoed1 | imd | JOIN | Exit order alerts. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentMetaData (table)
```
This object has no code-level dependencies. Tables have no FROM/JOIN in CREATE TABLE. FK targets (Trade.CandleIntervalGroups, Dictionary.CurrencyType) are structural only.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CandleIntervalGroups | Table | FK: CandleTimeframeGroup -> GroupID |
| Dictionary.CurrencyType | Table | FK: InstrumentTypeID -> CurrencyTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentMetaData | View | Direct select |
| Trade.GetInstrumentMetaDataExtend | View | Extended metadata view |
| Trade.GetInstrument | View | JOIN for deal data |
| Trade.GetInstrumentDeal | View | Via GetInstrument |
| Trade.InsertInstrumentMetaData | Procedure | INSERT |
| Trade.InsertInstrumentMetadataSecurityOpsAPI | Procedure | INSERT |
| Trade.UpdateInstrumentsMetaDataConfigurations | Procedure | UPDATE |
| Trade.UpdateFuturesMetadataSecurityOpsAPI | Procedure | UPDATE |
| Trade.DisableInstrument | Procedure | UPDATE |
| Trade.GetInstrumentByIdSecurityOpsAPI | Procedure | SELECT |
| Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI | Procedure | SELECT |
| Trade.GetInstrumentsTimeframeID | Procedure | JOIN with CandleGroupToIntervals |
| Trade.GetPositionsForDataApi | Procedure | JOIN |
| Trade.GetAggregatedPositionsForDataApi | Procedure | JOIN |
| Trade.GetDividendsByStatus | Procedure | JOIN |
| Trade.GetInstrumentSymbolFull | Procedure | Symbol lookup |
| Trade.GetEnabledAndListedInstruments | Procedure | Filter |
| Trade.CheckValidInstruments | Procedure | Validation |
| Trade.USAggregatePositionBySymbolForMonitor | Procedure | JOIN |
| Stocks.AddNewStock | Procedure | INSERT (via Internal flow) |
| dbo.EnableInstrument | Procedure | UPDATE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_InstrumentMetaData | CLUSTERED | InstrumentID ASC | - | - | Active |
| UNQ_TradeInstrumentMetaData_SymbolFull | NC UNIQUE | SymbolFull ASC | - | - | Active |
| IX_Cusip | NC | Cusip ASC | - | - | Active |
| IX_InstrumentTypeID | NC | InstrumentTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_InstrumentMetaData | PRIMARY KEY | InstrumentID clustered |
| UNQ_TradeInstrumentMetaData_SymbolFull | UNIQUE | SymbolFull must be unique |
| DF_InstrumentMetaData_InstrumentVisible | DEFAULT | InstrumentVisible = 1 |
| (unnamed) | DEFAULT | ContractExpire = 0 |
| DF_InstrumentMetaDataPriceSourceID | DEFAULT | PriceSourceID = 0 |
| DF_InstrumentCreateDate | DEFAULT | CreateDate = getutcdate() |
| DF_InstrumentMetaData_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_InstrumentMetaData_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| FK_InstrumentMetaData_CandleIntervalGroups | FOREIGN KEY | CandleTimeframeGroup -> Trade.CandleIntervalGroups.GroupID |
| FK_InstrumentMetaData_InstrumentType | FOREIGN KEY | InstrumentTypeID -> Dictionary.CurrencyType.CurrencyTypeID |

---

## 8. Sample Queries

### 8.1 List visible tradable instruments by asset class
```sql
SELECT imd.InstrumentID, imd.InstrumentDisplayName, imd.SymbolFull, ct.Name AS AssetClass
FROM Trade.InstrumentMetaData imd WITH (NOLOCK)
JOIN Dictionary.CurrencyType ct WITH (NOLOCK) ON imd.InstrumentTypeID = ct.CurrencyTypeID
WHERE imd.InstrumentVisible = 1 AND imd.Tradable = 1
ORDER BY imd.InstrumentTypeID, imd.SymbolFull;
```

### 8.2 Get metadata for an instrument by SymbolFull
```sql
SELECT imd.*, cig.GroupName AS CandleGroup
FROM Trade.InstrumentMetaData imd WITH (NOLOCK)
LEFT JOIN Trade.CandleIntervalGroups cig WITH (NOLOCK) ON imd.CandleTimeframeGroup = cig.GroupID
WHERE imd.SymbolFull = 'AAPL';
```

### 8.3 Instruments with rollover fees configured
```sql
SELECT imd.InstrumentID, imd.InstrumentDisplayName, imd.SymbolFull,
       imd.DailyRolloverFee, imd.WeekendRolloverFee, imd.ContractRolloverFee
FROM Trade.InstrumentMetaData imd WITH (NOLOCK)
WHERE imd.DailyRolloverFee IS NOT NULL
   OR imd.WeekendRolloverFee IS NOT NULL
   OR imd.ContractRolloverFee IS NOT NULL
ORDER BY imd.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Important DBs and DB Main](https://etoro.atlassian.net/wiki/spaces/CM/pages/2106130488) | Confluence | Database context for Trade schema |
| [Security Master Ops API - Duplicate Symbol Full](https://etoro.atlassian.net/wiki/spaces/CM/pages/14016348165) | Confluence | SymbolFull uniqueness and Security Ops API |
| [Asset Universe - Fields in use in each API and Service](https://etoro.atlassian.net/wiki/spaces/CM/pages/13224083616) | Confluence | Instrument metadata usage across APIs |
| [HLD - Visibility Update](https://etoro.atlassian.net/wiki/spaces/CM/pages/13210976290) | Confluence | InstrumentVisible / Tradable visibility logic |
| [Instrument On Paper testing](https://etoro.atlassian.net/wiki/spaces/CM/pages/12929433601) | Confluence | Instrument testing flows |

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 32 CODE-BACKED, 0 ATLASSIAN-ONLY, 5 NAME-INFERRED | Phases: 1,4,5,7,8,10,11*
*Sources: Atlassian: 5 Confluence + 0 Jira | Procedures: 15+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentMetaData | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.InstrumentMetaData.sql*
