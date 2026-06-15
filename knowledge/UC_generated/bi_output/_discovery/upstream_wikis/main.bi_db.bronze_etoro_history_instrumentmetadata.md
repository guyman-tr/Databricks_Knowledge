# History.InstrumentMetaData

> SQL Server temporal history table storing prior row versions of Trade.InstrumentMetaData, capturing every change to instrument display names, tickers, fees, visibility, and classification for all tradable instruments.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.InstrumentMetaData is the SQL Server system-versioning history table for Trade.InstrumentMetaData, declared as `HISTORY_TABLE = [History].[InstrumentMetaData]` in the Trade.InstrumentMetaData DDL. It stores prior versions of the rich metadata for every instrument tradable on the eToro platform - forex pairs (EUR/USD, GBP/USD), stocks (AAPL, TSLA), indices, crypto, and ETFs.

Trade.InstrumentMetaData is the central reference table for instrument display and behavioral properties: how an instrument is displayed in the UI (name, ticker, image URLs), whether it is visible and tradable, its exchange, rollover fees, and financial classification codes (ISIN, CUSIP, SEDOL, CFI). The history table enables full point-in-time reconstruction: operators can determine exactly what the display name, tradability status, or fee structure was for any instrument at any historical moment.

This is one of the largest temporal history tables in the History schema with 1,480,296 rows. Trade.InstrumentMetaData has both a standard INSERT trigger (Tr_T_InstrumentMetaData_INSERT for temporal versioning via no-op UPDATE) and three ASM-generated audit triggers (Insert/Update/Delete) that write change logs to History.AuditHistory for specific columns (ContractExpire, ISINCode, ISINCountryCode, Industry, InstrumentDisplayName, InstrumentVisible, Symbol, SymbolFull, Tradable).

---

## 2. Business Logic

### 2.1 SQL Server Temporal Versioning Mechanics

**What**: SQL Server writes superseded row versions from Trade.InstrumentMetaData into this table on each UPDATE or DELETE.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `InstrumentID`

**Rules**:
- INSERT trigger Tr_T_InstrumentMetaData_INSERT fires on each new instrument and performs a no-op UPDATE, producing an immediate history record (SysStartTime = SysEndTime)
- Each subsequent metadata change (name update, fee change, visibility toggle) creates a new version row
- 1,480,296 rows reflects the high frequency of instrument metadata changes over the system's lifetime
- Both the temporal history and the ASM AuditHistory triggers capture changes in parallel for the audited columns

### 2.2 Dual Audit Mechanism

**What**: Trade.InstrumentMetaData has TWO independent audit mechanisms running in parallel for its most business-critical columns.

**Columns/Parameters Involved**: `ContractExpire`, `ISINCode`, `ISINCountryCode`, `Industry`, `InstrumentDisplayName`, `InstrumentVisible`, `Symbol`, `SymbolFull`, `Tradable`

**Rules**:
- Temporal versioning (via this history table): captures ALL column changes atomically - full row snapshot for any update
- ASM-generated audit triggers: write column-level OLD/NEW values to History.AuditHistory for the 9 key columns listed above. Provides human-readable "old value -> new value" audit trail separate from temporal versioning
- These mechanisms are complementary: temporal for time-travel queries, AuditHistory for column-level change logs

### 2.3 ExchangeID Validation on Update

**What**: When ExchangeID is changed on an instrument, trigger trg_update_Trade_InstrumentMetaData validates the new exchange has a fee definition and propagates the change to Trade.ExchangeInstrumentFeeDefinition.

**Columns/Parameters Involved**: `ExchangeID`

**Rules**:
- If the new ExchangeID does not exist in Trade.ExchangeInstrumentFeeDefinition, the update is ROLLED BACK with error "Exchange X Does Not Exist in Trade.ExchangeInstrumentFeeDefinition"
- If valid, Trade.ExchangeInstrumentFeeDefinition is updated to reflect the new exchange assignment for that instrument

### 2.4 Computed Columns Materialized in History

**What**: DbLoginName and AppLoginName are computed in Trade.InstrumentMetaData. This history table stores their snapshot values at version close time.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`

**Rules**:
- DbLoginName: suser_name() - identifies who made the change (e.g., "DevTradingSTG" for automated service)
- AppLoginName: context_info() - typically NULL

---

## 3. Data Overview

1,480,296 rows. Very active - changes occurring daily.

| InstrumentID | InstrumentDisplayName | Symbol | InstrumentTypeID | Tradable | DbLoginName | SysStartTime | SysEndTime | Meaning |
|-------------|----------------------|--------|-----------------|---------|------------|-------------|-----------|---------|
| 1 | EUR/USD | EURUSD | 1 (FX) | true | DevTradingSTG | 2026-03-18 18:25:18 | 2026-03-18 19:37:18 | EUR/USD metadata version active for ~72 minutes before being updated by an automated service. The automated update likely changed fee rates or spread configuration. |
| 2 | GBP/USD | GBPUSD | 1 (FX) | true | DevTradingSTG | 2026-03-18 18:25:18 | 2026-03-18 19:37:18 | GBP/USD updated at the same time as EUR/USD - suggesting a batch fee/configuration update ran across multiple FX instruments simultaneously. |
| 100263 | GOLDBTC | GOLDBTC | 10 (custom) | true | DevTradingSTG | 2026-03-17 21:33:13 | 2026-03-18 19:37:18 | Synthetic instrument (Gold/Bitcoin ratio) that was updated the prior day and then overwritten the next day by the same batch process. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | The instrument this history version belongs to. PK in Trade.InstrumentMetaData (one live row per instrument). Multiple history rows here for the same InstrumentID capture its metadata evolution. |
| 2 | InstrumentDisplayName | varchar(100) | NO | - | VERIFIED | Human-readable display name shown in the eToro UI for this instrument (e.g., "EUR/USD", "Apple", "Bitcoin"). Audited by AuditInsert/Update/Delete triggers -> History.AuditHistory. |
| 3 | InstrumentTypeImage | varchar(max) | YES | - | CODE-BACKED | URL or path to the image representing the instrument type category (not the instrument itself). |
| 4 | Ticker | varchar(max) | YES | - | CODE-BACKED | Ticker symbol used for price feed lookup. Observed value: "/ticker" - may be overridden per instrument. |
| 5 | ChartTicker | varchar(max) | YES | - | CODE-BACKED | Ticker symbol used specifically for charting data source lookups. May differ from Ticker for some instruments. |
| 6 | InstrumentImageSmall | varchar(max) | YES | - | CODE-BACKED | URL to the small (thumbnail) icon image for this instrument, displayed in instrument lists. |
| 7 | InstrumentImageMedium | varchar(max) | YES | - | CODE-BACKED | URL to the medium-size image for this instrument. |
| 8 | InstrumentImageLarge | varchar(max) | YES | - | CODE-BACKED | URL to the large image for this instrument, used in instrument detail pages. |
| 9 | Exchange | varchar(max) | YES | - | CODE-BACKED | Exchange name as a free-text string (e.g., "NASDAQ", "NYSE"). Supplemented by ExchangeID (the structured FK). This column may be a legacy display field. |
| 10 | Industry | varchar(max) | YES | - | VERIFIED | Industry classification for stock instruments (e.g., "Technology", "Healthcare"). Audited by ASM triggers -> History.AuditHistory. NULL for non-stock instruments. |
| 11 | CompanyInfo | varchar(max) | YES | - | CODE-BACKED | Free-text company description displayed on the instrument detail page. Rich text describing the company's business and background. |
| 12 | DailyRolloverFee | decimal(18,4) | YES | - | CODE-BACKED | Daily overnight/rollover fee rate applied to leveraged CFD positions in this instrument. Expressed as a percentage or absolute value per day. NULL = fee not configured. |
| 13 | WeekendRolloverFee | decimal(18,4) | YES | - | CODE-BACKED | Weekend-specific rollover fee charged for positions held over the weekend (Friday close to Monday open, typically 3x daily). NULL = not configured. |
| 14 | ContractRolloverFee | decimal(18,4) | YES | - | CODE-BACKED | Rollover fee applied when a futures contract rolls to the next expiry period. Audited by ASM triggers. NULL for non-futures instruments. |
| 15 | InstrumentVisible | int | YES | 1 | VERIFIED | Visibility flag: 1=visible to customers (default), 0=hidden. Controls whether the instrument appears in search and trading interfaces. Audited by ASM triggers -> History.AuditHistory. |
| 16 | Symbol | varchar(100) | YES | - | VERIFIED | Short trading symbol for the instrument (e.g., "EURUSD", "AAPL"). Used in price feeds and internal references. Audited by ASM triggers. |
| 17 | CandleTimeframeGroup | int | YES | - | CODE-BACKED | FK to Trade.CandleIntervalGroups (FK_InstrumentMetaData_CandleIntervalGroups). Determines which candle timeframe intervals are available for this instrument's charts. |
| 18 | SymbolFull | varchar(100) | YES | - | VERIFIED | Fully-qualified unique symbol string for the instrument (e.g., "Drm.797" for dormant instruments). UNIQUE constraint on Trade.InstrumentMetaData (UNQ_TradeInstrumentMetaData_SymbolFull). Audited by ASM triggers. |
| 19 | Tradable | bit | YES | - | VERIFIED | Whether customers can currently trade this instrument: 1=tradable, 0=not tradable (suspended, delisted, or not yet launched). Audited by ASM triggers -> History.AuditHistory. |
| 20 | ExchangeID | int | YES | - | VERIFIED | FK to Trade.Exchange (structural). Identifies the exchange where this instrument is traded. Validated on UPDATE by trigger trg_update_Trade_InstrumentMetaData - prevents assignment to an exchange without a fee definition in Trade.ExchangeInstrumentFeeDefinition. |
| 21 | StocksIndustryID | int | YES | - | CODE-BACKED | Numeric ID of the stock's industry sector. FK to a stocks industry lookup table. NULL for non-stock instruments. Supplements the free-text Industry column with a structured classification. |
| 22 | ISINCode | varchar(30) | YES | - | VERIFIED | International Securities Identification Number for the instrument. Audited by ASM triggers -> History.AuditHistory. NULL for instruments not mapped to a global security identifier. |
| 23 | ISINCountryCode | varchar(15) | YES | - | VERIFIED | Country code component of the ISIN (first 2 characters of ISIN, e.g., "US", "GB"). Audited by ASM triggers. |
| 24 | ContractExpire | bit | NO | 0 | VERIFIED | Whether this futures/CFD instrument has a contract expiry date: 0=perpetual (no expiry), 1=expires. DEFAULT 0. Audited by ASM triggers -> History.AuditHistory. Triggers futures rollover processing when 1. |
| 25 | InstrumentTypeSubCategoryID | int | YES | - | CODE-BACKED | Sub-category classification within the instrument's type. Provides finer granularity than InstrumentTypeID (e.g., distinguishing ETFs from indices within the same type group). |
| 26 | InstrumentTypeID | int | YES | - | VERIFIED | Instrument type classification. FK to Dictionary.CurrencyType (FK_InstrumentMetaData_InstrumentType). Observed: 1=FX pair, 4=Index/ETF, 10=custom/synthetic. Determines trading rules, fee schedules, and hedging behavior. |
| 27 | PriceSourceID | int | NO | 0 | CODE-BACKED | ID of the price data source for this instrument. DEFAULT 0 = default/unspecified source. Used by the Price engine to route price feed subscriptions. |
| 28 | Cusip | varchar(255) | YES | - | CODE-BACKED | CUSIP identifier (Committee on Uniform Securities Identification Procedures). US-centric securities identifier. Indexed in Trade.InstrumentMetaData (IX_Cusip). NULL for non-US or non-CUSIP instruments. |
| 29 | CreateDate | datetime | YES | getutcdate() | CODE-BACKED | UTC timestamp when the instrument metadata row was first created. DEFAULT getutcdate() set at row insertion. |
| 30 | UnderlyingExchangeID | int | YES | - | CODE-BACKED | For derivative instruments (futures, CFDs), the exchange of the underlying asset. May differ from ExchangeID when eToro lists a derivative on one exchange tracking an asset traded on another. |
| 31 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | Materialized snapshot of suser_name() at version close time. Identifies who changed the metadata. Observed: "DevTradingSTG" for automated batch updates. |
| 32 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Materialized snapshot of context_info() at version close time. Typically NULL. |
| 33 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Start of validity for this metadata version. Set by SQL Server temporal engine. Rows with SysStartTime=SysEndTime are insert artifacts from Tr_T_InstrumentMetaData_INSERT. |
| 34 | SysEndTime | datetime2(7) | NO | - | VERIFIED | End of validity for this metadata version. CLUSTERED INDEX ordered (SysEndTime, SysStartTime) for temporal scan performance. |
| 35 | SEDOL | varchar(50) | YES | - | CODE-BACKED | Stock Exchange Daily Official List identifier. UK-centric securities identifier (7-character alphanumeric). NULL for non-SEDOL instruments. |
| 36 | SubCategory | varchar(255) | YES | - | CODE-BACKED | Freeform sub-category label providing additional classification context beyond InstrumentTypeSubCategoryID. |
| 37 | CFICode | varchar(6) | YES | - | CODE-BACKED | Classification of Financial Instruments code (ISO 10962). 6-character standardized code describing the instrument type at the international regulatory level (e.g., "ESVUFR" for common equity). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit (from source FK) | The instrument whose metadata is captured. |
| ExchangeID | Trade.Exchange | Implicit (from source) | The exchange where the instrument trades. Validated by trigger on source table. |
| CandleTimeframeGroup | Trade.CandleIntervalGroups | Implicit (from source FK) | Chart timeframe group. Source has FK_InstrumentMetaData_CandleIntervalGroups. |
| InstrumentTypeID | Dictionary.CurrencyType | Implicit (from source FK) | Instrument type classification. Source has FK_InstrumentMetaData_InstrumentType. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InstrumentMetaData | (SYSTEM_VERSIONING) | Temporal - HISTORY_TABLE | All closed row versions from Trade.InstrumentMetaData flow here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.InstrumentMetaData (table)
  - leaf node: no code-level dependencies (auto-managed by SQL Server temporal engine)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | Declares this as its HISTORY_TABLE via SYSTEM_VERSIONING. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_InstrumentMetaData | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage option | Page-level compression on all data and LOB pages. |
| TEXTIMAGE_ON [PRIMARY] | Storage option | LOB (varchar(max)) columns stored on PRIMARY filegroup. |

---

## 8. Sample Queries

### 8.1 Retrieve all versions of an instrument's display name over time
```sql
SELECT InstrumentID, InstrumentDisplayName, Symbol, Tradable, InstrumentTypeID,
       SysStartTime, SysEndTime, DbLoginName
FROM History.InstrumentMetaData WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY SysStartTime;
```

### 8.2 Check what metadata was in effect at a specific point in time
```sql
SELECT InstrumentID, InstrumentDisplayName, Symbol, InstrumentTypeID,
       DailyRolloverFee, WeekendRolloverFee, Tradable, ExchangeID,
       SysStartTime, SysEndTime
FROM Trade.InstrumentMetaData WITH (NOLOCK)
FOR SYSTEM_TIME AS OF '2024-01-01 00:00:00'
WHERE InstrumentID = 1;
```

### 8.3 Find instruments whose display name changed on a given date
```sql
SELECT h.InstrumentID, h.InstrumentDisplayName AS OldName,
       t.InstrumentDisplayName AS CurrentName,
       h.SysEndTime AS ChangedAt, h.DbLoginName
FROM History.InstrumentMetaData h WITH (NOLOCK)
JOIN Trade.InstrumentMetaData t WITH (NOLOCK) ON t.InstrumentID = h.InstrumentID
WHERE CAST(h.SysEndTime AS date) = '2026-03-18'
  AND h.SysStartTime != h.SysEndTime
  AND h.InstrumentDisplayName != t.InstrumentDisplayName
ORDER BY h.SysEndTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 29 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 triggers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.InstrumentMetaData | Type: Table | Source: etoro/etoro/History/Tables/History.InstrumentMetaData.sql*
