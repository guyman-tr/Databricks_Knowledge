# Pre-Resolved Upstream Bundle for `Dealing_dbo.Dealing_Boundary_Cost`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `Dealing_dbo.Dealing_Boundary_Cost.sql`

```sql
CREATE TABLE [Dealing_dbo].[Dealing_Boundary_Cost]
(
	[Date] [date] NULL,
	[DateID] [int] NULL,
	[FromDate] [datetime] NULL,
	[ToDate] [datetime] NULL,
	[InstrumentID] [int] NULL,
	[InstrumentName] [varchar](100) NULL,
	[InstrumentType] [varchar](50) NULL,
	[StdSpreadPercent] [decimal](16, 6) NULL,
	[LastBid] [decimal](16, 6) NULL,
	[LastAsk] [decimal](16, 6) NULL,
	[Mid] [decimal](16, 6) NULL,
	[LastBidSpreaded] [decimal](16, 6) NULL,
	[LastAskSpreaded] [decimal](16, 6) NULL,
	[UnitsBuy] [decimal](16, 6) NULL,
	[UnitsSell] [decimal](16, 6) NULL,
	[WAVG_BuyPrice] [decimal](16, 6) NULL,
	[WAVG_SellPrice] [decimal](16, 6) NULL,
	[NOP] [decimal](20, 6) NULL,
	[UpdateDate] [datetime] NULL,
	[VolumeBuy] [decimal](16, 6) NULL,
	[VolumeSell] [decimal](16, 6) NULL,
	[VariableSpread] [decimal](16, 6) NULL,
	[LowerBoundary] [decimal](16, 4) NULL,
	[UpperBoundary] [decimal](16, 4) NULL,
	[HedgeRiskLimit] [decimal](16, 4) NULL,
	[FX_Bid] [decimal](16, 6) NULL,
	[InstrumentTypeID] [int] NULL,
	[HedgeServerID] [int] NULL,
	[IsSettled] [int] NULL,
	[PriceRatio] [decimal](16, 6) NULL,
	[HS_Moved_Units] [decimal](20, 6) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[DateID] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 9 upstream wiki(s). Read EACH one in full.


### Upstream `DWH_dbo.Dim_Instrument` — synapse
- **Resolved as**: `DWH_dbo.Dim_Instrument`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md`

# DWH_dbo.Dim_Instrument

> Comprehensive instrument dimension table covering all 15,700+ tradeable assets on the eToro platform -- combining core trade pair definitions (buy/sell currencies), display metadata, financial fundamentals, futures configuration, and platform classification into a single analytics-ready reference.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Trade.GetInstrument (view) + Trade.InstrumentMetaData + Trade.ProviderToInstrument + StockInfo + FuturesMetaData |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (InstrumentID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` |
| **UC Format** | delta |
| **UC Partitioned By** | None (15K rows; suggest Z-ORDER on InstrumentID) |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_Instrument` is the DWH's master reference for all tradeable instruments on the eToro platform. It extends the foundational trade pair definition from `Trade.Instrument` (which specifies the buy/sell currency pairing for each instrument) with rich analytics metadata: display names and company info from `Trade.InstrumentMetaData`, trading configuration from `Trade.ProviderToInstrument`, financial market data (market cap, ADV, shares outstanding) from the Rankings/StockInfo system, Bloomberg-style asset classification, and futures-specific parameters. The result is a 47-column analytics hub that serves as the primary instrument lookup for fact table enrichment across DWH analytics.

The production source is `etoro.Trade.GetInstrument` (a view on the production etoroDB-REAL server), which combines `Trade.Instrument` with multiple related tables. The Generic Pipeline exports this view daily to `Bronze/etoro/Trade/GetInstrument/` (UC: `trading.bronze_etoro_trade_getinstrument`). The DWH ETL SP (`SP_Dim_Instrument`) then joins this staging data with six additional staging tables to produce the full 47-column Dim_Instrument. Post-load UPDATE statements enrich price-server tracking, asset classification, and financial fundamentals. Source: upstream wiki available at `Trade/Tables/Trade.Instrument.md` (quality 9.1/10).

The ETL is a full TRUNCATE + INSERT + multiple UPDATEs, running daily with a `@dt` date parameter. `UpdateDate` and `InsertDate` are both set to `GETDATE()` at load time and do NOT reflect production modification times. The SP ends by calling `SP_Dim_Instrument_Snapshot @dt` to update the `Dim_Instrument_Snapshot` table (daily snapshot of futures configuration columns). As of 2026-03-19, the table contains 15,707 rows: 82% Stocks, 8% ETFs, 4% Crypto, 3% Commodities, 2% Indices, 1% Currencies.

---

## 2. Business Logic

### 2.1 Buy/Sell Currency Pairing

**What**: Every instrument is defined as a pair of assets from `Dictionary.Currency`/`Dim_Currency`. The pairing determines how prices are quoted, how positions are settled, and how P&L is converted to account currency.

**Columns Involved**: `BuyCurrencyID`, `SellCurrencyID`, `BuyCurrency`, `SellCurrency`

**Rules**:
- For **forex pairs**: BuyCurrencyID is the base currency, SellCurrencyID is the quote currency (e.g., InstrumentID=1: EUR/USD = BuyCurrencyID=2/EUR, SellCurrencyID=1/USD)
- For **stocks/ETFs/crypto**: BuyCurrencyID equals the asset's own InstrumentID in Dim_Currency, and SellCurrencyID is the denomination currency (USD for US stocks, EUR for European stocks, GBX for UK pence-quoted stocks)
- `BuyCurrency` and `SellCurrency` are DWH-added text abbreviations (denormalized from Dictionary.Currency via SP JOIN)
- InstrumentID=0: system/ETL null-sentinel record with all zero/NA values

**Diagram**:
```
Forex:  ID=1  -> Buy=EUR(2)  / Sell=USD(1)   = EUR/USD pair
Stock:  ID=1001 -> Buy=AAPL(1001) / Sell=USD(1) = Apple in USD
EuroSt: ID=1203 -> Buy=Bayer(1203) / Sell=EUR(2) = Bayer AG in EUR
Crypto: ID=XXXX -> Buy=BTC(?) / Sell=USD(1)     = Bitcoin in USD
```

### 2.2 InstrumentType and IsMajor Dual Representation

**What**: Two DWH-specific computed/reformatted columns encode enum values as human-readable text.

**Columns Involved**: `InstrumentTypeID`, `InstrumentType`, `IsMajorID`, `IsMajor`

**Rules**:
- `InstrumentType` is CASE-computed in the SP from `InstrumentTypeID`: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Note: type IDs 3, 7, 8, 9 are not defined (gap exists for historical reasons)
- `IsMajorID` = production `IsMajor` bit value (0 or 1). `IsMajor` = text version ('Yes' or 'No'). Analysts should use `IsMajorID` for filtering, `IsMajor` for display
- IsMajor=Yes: 6,963 instruments (major forex + popular stocks/ETFs). IsMajor=No: 8,743 instruments
- DWHInstrumentID always equals InstrumentID (redundant copy, same as the DWHXxxID pattern across all DWH Dim tables)
- StatusID is hardcoded to 1 for all real rows (ETL artifact; NULL only for ID=0 placeholder)

### 2.3 IsFuture Derivation and Futures Columns

**What**: Futures instruments are identified by membership in InstrumentGroups(GroupID=25), and carry additional configuration columns not present for non-futures instruments.

**Columns Involved**: `IsFuture`, `Multiplier`, `ProviderMarginPerLot`, `eToroMarginPerLot`, `SettlementTime`

**Rules**:
- `IsFuture = 1` when the instrument is a member of `DWH_staging.etoro_Trade_InstrumentGroups` with `GroupID=25`. Computed via CASE in SP_Dim_Instrument.
- `Multiplier`: contract size multiplier from `Trade.FuturesMetaData`. NULL for non-futures.
- `ProviderMarginPerLot`: initial margin requirement from the liquidity provider, from `Trade.FuturesInstrumentsInitialMarginByProviderMapping`. NULL for non-futures.
- `eToroMarginPerLot`: eToro's own margin per lot (in asset currency) from `Trade.ProviderToInstrument.InitialMarginInAssetCurrency`. NULL for non-futures.
- `SettlementTime`: daily/weekly settlement time from `Trade.ProviderToInstrument`, formatted as TIME(0) by the SP.

### 2.4 Financial Fundamentals (Post-Load Updates)

**What**: Market data columns are populated via post-load UPDATE statements joining to the Rankings/StockInfo data lake.

**Columns Involved**: `ADV_Last3Months`, `MKTcap`, `SharesOutStanding`, `AssetClass`, `IndustryGroup`, `PlatformSector`, `PlatformIndustry`

**Rules**:
- `ADV_Last3Months`: Average Daily Volume over last 3 months (MetadataID=8557). NULL for non-stock instruments or instruments without Rankings data.
- `MKTcap`: Market Capitalization in USD (MetadataID=8735 for stocks, fallback to MetadataID=9315 CryptoMarketCap for crypto). NULL if not covered by Rankings.
- `SharesOutStanding`: Total shares outstanding in units (MetadataID=8444). Stocks only.
- `AssetClass` / `IndustryGroup`: Bloomberg-style classification from `Ext_Dim_Instrument_Classification_Static`. More granular than InstrumentType.
- `PlatformSector` / `PlatformIndustry`: eToro platform taxonomy (MetadataID=8436/8280), may differ from Bloomberg AssetClass/IndustryGroup.
- `ReceivedOnPriceServer`: First date/time an instrument was seen on the price server. POST-LOAD from `Ext_Dim_Instrument_ReceivedOnPriceServerStatic`. NULL for instruments not yet priced.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed (all 15,707 rows available on every compute node) with a CLUSTERED INDEX on `InstrumentID`. Since virtually every fact table JOINs to `Dim_Instrument` on `InstrumentID`, replication eliminates shuffle overhead. The clustered index supports range scans and direct lookups efficiently.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export is pending write-objects configuration. At 15,707 rows, partitioning is not beneficial -- suggest Z-ORDER on `InstrumentID` for join performance, and `InstrumentTypeID` for type-filtered analytics.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get instrument name and type by ID | `JOIN Dim_Instrument ON InstrumentID; SELECT Name, InstrumentType` |
| Find all major instruments by asset class | `WHERE IsMajorID = 1 AND AssetClass = 'Technology'` |
| Find instruments eligible for long/short | `WHERE AllowBuy = 1 AND AllowSell = 1 AND Tradable = 1` |
| Get market cap for a position | `JOIN Dim_Instrument ON InstrumentID; SELECT MKTcap` |
| Find futures instruments with settlement | `WHERE IsFuture = 1 AND SettlementTime IS NOT NULL` |
| Find US stocks with ISIN | `WHERE InstrumentTypeID = 5 AND ISINCountryCode = 'US' AND ISINCode IS NOT NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Currency | `ON Dim_Currency.CurrencyID = Dim_Instrument.BuyCurrencyID` | Resolve buy-side currency/asset details |
| DWH_dbo.Dim_Currency | `ON Dim_Currency.CurrencyID = Dim_Instrument.SellCurrencyID` | Resolve sell-side denomination currency |
| DWH_dbo.Dim_HistorySplitRatio | `ON InstrumentID + date range` | Get split adjustment ratios for historical price normalization |
| DWH_dbo.Dim_Instrument_Snapshot | `ON InstrumentID + DateID` | Get point-in-time futures config for historical analysis |
| DWH_dbo.Fact_CurrencyPriceWithSplit | `ON InstrumentID` | Join to price history |

### 3.4 Gotchas

- **InstrumentID=0 is the null-sentinel placeholder**: All fields are 0/NA/NULL. Always filter `WHERE InstrumentID > 0` for analytics.
- **DWHInstrumentID always equals InstrumentID**: This is a redundant copy column -- do not use it as a distinct identifier.
- **StatusID is hardcoded 1**: This column conveys no information (all rows = 1 except the ID=0 placeholder). Do not filter on it.
- **UpdateDate and InsertDate are both ETL timestamps**: Neither reflects when the instrument was created or last modified in production. They reflect the last ETL run (daily, ~midnight).
- **InstrumentType gaps**: TypeIDs 3, 7, 8, 9 are not used. The CASE expression returns 'Other' for any unmapped typeID.
- **IsMajorID vs IsMajor**: Use `IsMajorID` (int 0/1) for WHERE/GROUP BY. Use `IsMajor` ('Yes'/'No') for display only.
- **NULL fundamentals**: ADV_Last3Months, MKTcap, SharesOutStanding are NULL for non-stock instruments and for instruments not covered by Rankings data. Always use LEFT JOIN or ISNULL() when using these for aggregations.
- **AllowBuy/AllowSell = 0 means trading disabled**: Instruments with AllowBuy=0 cannot be opened in the specified direction. This changes dynamically in production but is updated daily in DWH.
- **Dim_Instrument vs Dim_Currency**: Dim_Currency (from Dictionary.Currency) is the master asset registry with type and currency info. Dim_Instrument (from Trade.Instrument) is the trading pair definition with full analytics enrichment. For basic instrument lookups, Dim_Currency suffices. For trading parameters, fundamentals, or pair analysis, use Dim_Instrument.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 -- upstream wiki verbatim | `(Tier 1 -- upstream wiki, Trade.Instrument)` |
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Dim_Instrument)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |
| ★ | Tier 4 -- inferred [UNVERIFIED] | `[UNVERIFIED] (Tier 4 -- inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | int | NO | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 2 | InstrumentTypeID | int | NO | Instrument type category: 1=Currencies (forex), 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Note TypeIDs 3, 7, 8, 9 are unused gaps. Distribution: Stocks 82%, ETF 8%, Crypto 4%, Commodities 3%, Indices 2%, Currencies 1%. (Tier 2 -- SP_Dim_Instrument) |
| 3 | InstrumentType | varchar(50) | NO | Text label for InstrumentTypeID -- DWH-computed via CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Use InstrumentTypeID for filtering; InstrumentType for display. (Tier 2 -- SP_Dim_Instrument) |
| 4 | Name | varchar(50) | NO | Instrument name as defined in Trade.Instrument. For forex: pair notation (e.g., EUR/USD). For stocks: company name (e.g., Apple, Alphabet). For crypto: token name. This is the internal instrument name, not necessarily the display name shown to users (see InstrumentDisplayName). (Tier 3 -- live data, etoro.Trade.GetInstrument) |
| 5 | DWHInstrumentID | int | NO | Always equal to InstrumentID -- redundant copy following the DWH DWH{X}ID pattern. Use InstrumentID for all JOINs. (Tier 2 -- SP_Dim_Instrument) |
| 6 | StatusID | int | YES | Hardcoded to 1 for all real rows by SP_Dim_Instrument. NULL only for ID=0 placeholder. Conveys no business information. (Tier 2 -- SP_Dim_Instrument) |
| 7 | BuyCurrencyID | int | NO | The buy-side asset of the instrument pair. FK to DWH_dbo.Dim_Currency(CurrencyID). For forex: the base currency. For stocks/ETFs/crypto: the asset's own CurrencyID in Dim_Currency (BuyCurrencyID = InstrumentID for stocks). (Tier 1 -- upstream wiki, Trade.Instrument) |
| 8 | SellCurrencyID | int | NO | The sell-side (denomination) currency. FK to DWH_dbo.Dim_Currency(CurrencyID). For forex: the quote currency (e.g., USD in EUR/USD). For stocks: the trading denomination currency (USD, EUR, GBX). Only 67 distinct values since many assets share the same denomination. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 9 | BuyCurrency | varchar(50) | NO | Text abbreviation of BuyCurrencyID -- denormalized from Dictionary.Currency.Abbreviation via SP JOIN. Example: EUR, AAPL, BTC. DWH-added for query convenience. (Tier 2 -- SP_Dim_Instrument) |
| 10 | SellCurrency | varchar(50) | NO | Text abbreviation of SellCurrencyID -- denormalized from Dictionary.Currency.Abbreviation. Example: USD, EUR, GBX (GBP pence). DWH-added for query convenience. (Tier 2 -- SP_Dim_Instrument) |
| 11 | TradeRange | int | NO | Allowed trade range in pips for pending orders. Determines how far from market price a limit/stop order can be placed. Set during instrument creation. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 12 | DollarRatio | numeric(18,0) | NO | Price scaling factor for USD normalization. Most instruments = 1. JPY pairs = 100 (because JPY is quoted at 100x the numeric value of other currencies). Used in P&L and conversion rate calculations across the platform. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 13 | PipDifferenceThreshold | bigint | YES | Maximum allowed pip difference threshold for price validation. If a new price deviates more than this threshold from the previous price, it may be flagged as suspicious. NULL for some instruments. (Tier 1 -- upstream wiki, Trade.Instrument) |
| 14 | IsMajorID | int | NO | Integer representation of the production IsMajor flag (0 or 1). 1=major instrument (6,963 instruments -- all major forex pairs and many popular stocks). 0=non-major (8,743 instruments). Renamed from production IsMajor to distinguish from the text version. Use for filtering. (Tier 2 -- SP_Dim_Instrument) |
| 15 | IsMajor | varchar(3) | NO | Text version of IsMajorID -- DWH CASE computed: IsMajorID=1->'Yes', 0->'No'. Use for display. Affects spread calculations and regulatory leverage caps (ESMA allows higher leverage for major forex). (Tier 2 -- SP_Dim_Instrument) |
| 16 | UpdateDate | datetime | YES | ETL load timestamp -- set to GETDATE() by SP_Dim_Instrument on each daily reload. Does NOT reflect production modification date. NULL only for ID=0 placeholder. (Tier 2 -- SP_Dim_Instrument) |
| 17 | InsertDate | datetime | YES | ETL load timestamp -- set to GETDATE() by SP_Dim_Instrument, same as UpdateDate. Both reflect the daily load time. Does NOT reflect production insertion date. NULL only for ID=0 placeholder. (Tier 2 -- SP_Dim_Instrument) |
| 18 | InstrumentDisplayName | varchar(100) | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 19 | Industry | varchar(max) | YES | Industry classification string from Trade.InstrumentMetaData. Text description (e.g., 'Internet', 'Software'). Similar to but may differ from IndustryGroup (Bloomberg). NULL for non-stock instruments or instruments without metadata. (Tier 3 -- live data, etoro_Trade_InstrumentMetaData) |
| 20 | CompanyInfo | varchar(max) | YES | Free-text company description from Trade.InstrumentMetaData. May contain multi-sentence business descriptions of the company. NULL for non-company instruments (forex, commodities, indices). (Tier 3 -- live data, etoro_Trade_InstrumentMetaData) |
| 21 | Exchange | varchar(max) | YES | Stock exchange name from Trade.InstrumentMetaData (e.g., Nasdaq, NYSE, LSE). NULL for non-stock instruments. (Tier 3 -- live data, etoro_Trade_InstrumentMetaData) |
| 22 | ISINCode | varchar(30) | YES | International Securities Identification Number -- 12-character alphanumeric code standardized by ISO 6166 (e.g., US0378331005 for Apple). NULL for forex, commodities, and instruments without ISIN. Country prefix + national code + check digit. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 23 | ISINCountryCode | varchar(15) | YES | Country code prefix from the ISIN (first 2 characters). Indicates the country of registration (e.g., US, DE, GB). NULL when ISINCode is NULL. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 24 | Tradable | int | YES | Flag indicating if the instrument is currently tradable: 1=tradable, 0=not tradable. CAST from production bit. NULL for ID=0 placeholder. An instrument may exist but be non-tradable due to regulatory, market, or operational reasons. (Tier 2 -- SP_Dim_Instrument, etoro.Trade.GetInstrument) |
| 25 | Symbol | varchar(100) | YES | Ticker symbol for the instrument (e.g., AAPL, EURUSD, BTCUSD). Used for display, search, and price feed identification. NULL for ID=0 placeholder and some instruments without formal ticker. (Tier 3 -- live data, etoro.Trade.GetInstrument) |
| 26 | ReceivedOnPriceServer | datetime | YES | First timestamp when the instrument was observed on the price server (from Ext_Dim_Instrument_ReceivedOnPriceServerStatic). Set once and never updated (static history). NULL for instruments not yet priced or newly added instruments that have not yet appeared in price feeds. (Tier 2 -- SP_Dim_Instrument, post-load UPDATE) |
| 27 | BonusCreditUsePercent | int | YES | Percentage of bonus credit that can be applied to trading this instrument, from Trade.ProviderToInstrument. Lower values restrict bonus usage for high-risk/volatile instruments. NULL for instruments without ProviderToInstrument mapping. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 28 | SymbolFull | varchar(100) | YES | Full ticker symbol (may be longer than Symbol), from Trade.InstrumentMetaData. Used for data provider integrations that require fully qualified symbols. NULL for instruments without metadata. (Tier 3 -- live data, etoro_Trade_InstrumentMetaData) |
| 29 | CUSIP | varchar(500) | YES | Committee on Uniform Securities Identification Procedures number -- 9-character code for US/Canadian securities. Used for clearing, settlement, and regulatory reporting. NULL for non-US instruments and instruments without CUSIP. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentCusip) |
| 30 | Precision | int | YES | Decimal precision for price display and trading (number of decimal places), from Trade.ProviderToInstrument. Determines how many decimals are shown in the UI and used in calculations. NULL for instruments without ProviderToInstrument mapping. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 31 | AllowBuy | int | YES | Flag indicating if long (buy) positions can currently be opened: 1=allowed, 0=disabled. Cast from bit. NULL for ID=0 placeholder. Instruments may be buy-disabled due to regulatory restrictions, risk management, or market conditions. (Tier 2 -- SP_Dim_Instrument, etoro.Trade.GetInstrument) |
| 32 | AllowSell | int | YES | Flag indicating if short (sell) positions can currently be opened: 1=allowed, 0=disabled. Cast from bit. NULL for ID=0 placeholder. Many regulated markets prohibit short selling for retail clients. (Tier 2 -- SP_Dim_Instrument, etoro.Trade.GetInstrument) |
| 33 | AssetClass | nvarchar(400) | YES | Bloomberg-style asset class classification from Ext_Dim_Instrument_Classification_Static (e.g., Technology, Consumer Services, Finance). More granular than InstrumentType. NULL for non-stock instruments or instruments not in the classification static table. (Tier 2 -- SP_Dim_Instrument, post-load UPDATE) |
| 34 | IndustryGroup | nvarchar(400) | YES | Bloomberg-style industry group within AssetClass (e.g., Computers, Internet, Banks). Sub-classification of AssetClass. NULL for non-stock instruments or instruments not in the classification table. (Tier 2 -- SP_Dim_Instrument, post-load UPDATE) |
| 35 | ADV_Last3Months | numeric(20,4) | YES | Average Daily Trading Volume over the trailing 3 months (TTM), from Rankings StockInfo MetadataID=8557. In shares/units. NULL for non-stock instruments or instruments without Rankings coverage. Example: Apple ~48M shares/day. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 36 | MKTcap | numeric(20,4) | YES | Market capitalization in USD from Rankings StockInfo (MetadataID=8735 for equities; fallback MetadataID=9315 CryptoMarketCap for crypto). NULL for forex, commodities, and indices. Example: Apple ~3.8T USD. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 37 | SharesOutStanding | numeric(20,4) | YES | Total shares outstanding in units from Rankings StockInfo MetadataID=8444. Annual figure. NULL for non-equity instruments. Example: Apple ~14.7B shares. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 38 | VisibleInternallyOnly | int | YES | Flag (0/1) indicating if the instrument is visible only to internal eToro users (not shown to retail customers). Cast from bit. Used for instruments under development, testing, or institutional-only. NULL for ID=0 placeholder. (Tier 3 -- live data, etoro.Trade.GetInstrument) |
| 39 | PlatformSector | varchar(max) | YES | eToro platform sector classification from Rankings StockInfo MetadataID=8436. May differ from Bloomberg AssetClass. NULL for non-equity instruments or instruments without Rankings coverage. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 40 | PlatformIndustry | varchar(max) | YES | eToro platform industry classification from Rankings StockInfo MetadataID=8280. More granular than PlatformSector. NULL for non-equity instruments or instruments without Rankings coverage. (Tier 2 -- SP_Dim_Instrument, Rankings_StockInfo) |
| 41 | IsFuture | int | YES | Derived flag indicating if the instrument is a futures contract: 1=futures, 0=not futures. Computed in SP as CASE WHEN InstrumentID IN (SELECT InstrumentID FROM InstrumentGroups WHERE GroupID=25) THEN 1 ELSE 0. NULL for ID=0 placeholder. (Tier 2 -- SP_Dim_Instrument) |
| 42 | Multiplier | decimal(38,18) | YES | Futures contract size multiplier from Trade.FuturesMetaData. Determines how many units of the underlying asset one contract represents. NULL for non-futures instruments. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_FuturesMetaData) |
| 43 | ProviderID | int | YES | Liquidity provider identifier from Trade.ProviderToInstrument. Identifies which external market maker or broker provides pricing/liquidity for this instrument. NULL for instruments without a provider mapping. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 44 | ProviderMarginPerLot | decimal(38,18) | YES | Initial margin requirement per lot in the provider's terms, from Trade.FuturesInstrumentsInitialMarginByProviderMapping. Primarily relevant for futures instruments. NULL for non-futures or instruments without provider margin data. (Tier 3 -- live data, FuturesInstrumentsInitialMarginByProviderMapping) |
| 45 | eToroMarginPerLot | decimal(38,18) | YES | eToro's own margin requirement per lot in asset currency (InitialMarginInAssetCurrency from Trade.ProviderToInstrument). eToro's internal margin may differ from the provider's margin. NULL for instruments without ProviderToInstrument mapping. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 46 | SettlementTime | time(7) | YES | Daily or periodic settlement time for the instrument, from Trade.ProviderToInstrument, formatted as TIME via SP DATEPART conversion. Primarily relevant for futures and CFD instruments with defined settlement windows. NULL for instruments without settlement time defined. (Tier 3 -- live data, etoro_Trade_ProviderToInstrument) |
| 47 | OperationMode | int | YES | Trading operation mode: 0=Standard mode (default, ~15,600 instruments), 1=Alternate mode (~83 instruments, primarily European stock CFDs traded in non-USD denomination currencies). Controls how the trading engine processes orders. (Tier 1 -- upstream wiki, Trade.Instrument) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| InstrumentID | etoro.Trade.GetInstrument | InstrumentID | Passthrough |
| InstrumentTypeID | etoro.Trade.GetInstrument | InstrumentTypeID | Passthrough |
| InstrumentType | etoro.Trade.GetInstrument | InstrumentTypeID | CASE to text label |
| Name | etoro.Trade.GetInstrument | Name | Passthrough |
| DWHInstrumentID | etoro.Trade.GetInstrument | InstrumentID | rename (= InstrumentID) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |
| BuyCurrencyID | etoro.Trade.GetInstrument | BuyCurrencyID | Passthrough |
| SellCurrencyID | etoro.Trade.GetInstrument | SellCurrencyID | Passthrough |
| BuyCurrency | etoro.Dictionary.Currency | Abbreviation | join-enriched (via BuyCurrencyID) |
| SellCurrency | etoro.Dictionary.Currency | Abbreviation | join-enriched (via SellCurrencyID) |
| TradeRange | etoro.Trade.GetInstrument | TradeRange | Passthrough |
| DollarRatio | etoro.Trade.GetInstrument | DollarRatio | Passthrough |
| PipDifferenceThreshold | etoro.Trade.GetInstrument | PipDifferenceThreshold | Passthrough |
| IsMajorID | etoro.Trade.GetInstrument | IsMajor | rename (bit to int) |
| IsMajor | etoro.Trade.GetInstrument | IsMajor | CASE to 'Yes'/'No' text |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |
| InsertDate | -- | -- | ETL-computed: GETDATE() |
| InstrumentDisplayName | etoro.Trade.InstrumentMetaData | InstrumentDisplayName | join-enriched |
| Industry | etoro.Trade.InstrumentMetaData | Industry | join-enriched |
| CompanyInfo | etoro.Trade.InstrumentMetaData | CompanyInfo | join-enriched |
| Exchange | etoro.Trade.InstrumentMetaData | Exchange | join-enriched |
| ISINCode | etoro.Trade.InstrumentMetaData | ISINCode | join-enriched |
| ISINCountryCode | etoro.Trade.InstrumentMetaData | ISINCountryCode | join-enriched |
| Tradable | etoro.Trade.GetInstrument | Tradable | CAST to int |
| Symbol | etoro.Trade.GetInstrument | Symbol | Passthrough |
| ReceivedOnPriceServer | PriceLog (via PriceLog_History_CurrencyPrice_Active) | ReceivedOnPriceServer | join-enriched, post-load UPDATE |
| BonusCreditUsePercent | etoro.Trade.ProviderToInstrument | BonusCreditUsePercent | join-enriched |
| SymbolFull | etoro.Trade.InstrumentMetaData | SymbolFull | join-enriched |
| CUSIP | etoro.Trade.InstrumentCusip | CUSIP | join-enriched |
| Precision | etoro.Trade.ProviderToInstrument | Precision | join-enriched |
| AllowBuy | etoro.Trade.GetInstrument | AllowBuy | CAST to int |
| AllowSell | etoro.Trade.GetInstrument | AllowSell | CAST to int |
| AssetClass | External classification static | AssetClass | join-enriched, post-load UPDATE |
| IndustryGroup | External classification static | IndustryGroup | join-enriched, post-load UPDATE |
| ADV_Last3Months | Rankings.StockInfo (MetadataID=8557) | NumVal | join-enriched, post-load UPDATE |
| MKTcap | Rankings.StockInfo (MetadataID=8735/9315) | NumVal | join-enriched with fallback, post-load UPDATE |
| SharesOutStanding | Rankings.StockInfo (MetadataID=8444) | NumVal | join-enriched, post-load UPDATE |
| VisibleInternallyOnly | etoro.Trade.GetInstrument | VisibleInternallyOnly | CAST to int |
| PlatformSector | Rankings.StockInfo (MetadataID=8436) | StrVal | join-enriched, post-load UPDATE |
| PlatformIndustry | Rankings.StockInfo (MetadataID=8280) | StrVal | join-enriched, post-load UPDATE |
| IsFuture | etoro.Trade.InstrumentGroups (GroupID=25) | InstrumentID membership | CASE derived, post-load |
| Multiplier | etoro.Trade.FuturesMetaData | Multiplier | join-enriched |
| ProviderID | etoro.Trade.ProviderToInstrument | ProviderID | join-enriched |
| ProviderMarginPerLot | etoro.Trade.FuturesInstrumentsInitialMarginByProviderMapping | InitialMargin | join-enriched |
| eToroMarginPerLot | etoro.Trade.ProviderToInstrument | InitialMarginInAssetCurrency | join-enriched |
| SettlementTime | etoro.Trade.ProviderToInstrument | SettlementTime | cast/convert (TIME formatting) |
| OperationMode | etoro.Trade.Instrument | OperationMode | join-enriched (via etoro_Trade_Instrument) |

Upstream wiki: `C:\Users\guyman\Documents\github\DB_Schema\etoro\Wiki\Trade\Tables\Trade.Instrument.md` (quality 9.1/10)

### 5.2 ETL Pipeline

```
etoro.Trade.GetInstrument (view, etoroDB-REAL)
  -> Generic Pipeline (Override, 1440min, Bronze/etoro/Trade/GetInstrument/)
  -> trading.bronze_etoro_trade_getinstrument (UC Bronze)
  -> DWH_staging.etoro_Trade_GetInstrument
  +-> DWH_staging.etoro_Dictionary_Currency (buy/sell currency names)
  +-> DWH_staging.etoro_Trade_InstrumentMetaData (display name, ISIN, exchange, company)
  +-> DWH_staging.etoro_Trade_ProviderToInstrument (provider config, margins, precision)
  +-> DWH_staging.etoro_Trade_InstrumentCusip (CUSIP)
  +-> DWH_staging.etoro_Trade_FuturesMetaData (multiplier)
  +-> DWH_staging.etoro_Trade_FuturesInstrumentsInitialMarginByProviderMapping
  +-> DWH_staging.etoro_Trade_Instrument (OperationMode, AllowBuy/Sell, Tradable)
  -> SP_Dim_Instrument (TRUNCATE + JOIN INSERT + multiple post-load UPDATEs, daily)
  -> DWH_dbo.Dim_Instrument (15,707 rows)
  -- SP also call

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Dim_Position` — synapse
- **Resolved as**: `DWH_dbo.Dim_Position`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md`

# DWH_dbo.Dim_Position

> Core trading position table containing every opened and closed position on the eToro platform since 2007, with financial metrics (P&L, commissions, forex rates), lifecycle timestamps, social trading relationships (mirrors/copies/copy funds), regulatory context, and 20+ market price and spread columns added incrementally since 2022.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Trade.Position (open) + etoro.History.ClosePosition (closed) |
| **Refresh** | Daily (incremental via SP_Dim_Position_DL_To_Synapse @dt) |
| | |
| **Synapse Distribution** | HASH (PositionID) |
| **Synapse Index** | CLUSTERED INDEX (CloseDateID ASC, PositionID ASC) |
| **Synapse Partitions** | Monthly by CloseDateID, 2007-01-01 through 2026-02-28 (230+ partitions) |
| **Synapse Indexes** | IX_Dim_Position_CID, IX_Dim_Position_CloseDateID, IX_Dim_Position_CloseDateIDOpenDateID, IX_Dim_Position_CloseOccurred_OpenOccurred, IX_Dim_Position_Instrument |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position` |
| **UC Format** | Delta |
| **UC Partitioned By** | CloseDateID (monthly) |
| **UC Table Type** | Managed |

---

## 1. Business Meaning

Dim_Position is the central trading record table in DWH, containing every position (trade) ever opened on the eToro platform. Each row represents a single trading position lifecycle: opened by a customer (CID) on an instrument (InstrumentID), held for some duration, and either still open (CloseDateID=0) or closed with a final NetProfit. The data spans positions from 2007-08-27 to the most recent load date (2026-03-10 as of last ETL run 2026-03-11).

**Position types represented**:
- **Retail positions**: Opened by customers directly in the eToro web/mobile app
- **Mirror/CopyTrading positions**: Opened when a customer copies another trader (MirrorID links to Dim_Mirror); ParentPositionID links to the "master" position
- **Copy Fund positions**: IsCopyFundPosition=1 when the position's root (TreeID) belongs to a fund account (AccountTypeID=9)
- **AirDrop positions**: IsAirDrop=1 for positions created via airdrop events (crypto)
- **ReOpen positions**: IsReOpen=1 for positions reopened after a ReOpen event; ReopenForPositionID points to the original

**Open vs Closed state**:
- Open position: CloseDateID=0, CloseOccurred='1900-01-01 00:00:00'
- Closed position: CloseDateID=YYYYMMDD (e.g., 20260310), CloseOccurred = actual close timestamp

**Data Sources (merged in ETL)**:
- Open positions: `etoro_Trade_OpenPositionEndOfDay` (today's snapshot of all open positions)
- Closed positions: `etoro_History_ClosePositionEndOfDay` (positions that closed on @dt)

**134 columns** covering financial amounts, forex rates at open/close, market prices (spread data), execution IDs, order IDs, hedge types, and fee calculations added through 2025.

---

## 2. Business Logic

### 2.1 Open vs Closed Position States

**What**: The same position row transitions from "open" to "closed" as its lifecycle progresses.

**Columns Involved**: `CloseDateID`, `CloseOccurred`, `NetProfit`, `EndForexRate`, `ClosePositionReasonID`

**Rules**:
- **Open state**: CloseDateID=0, CloseOccurred='1900-01-01 00:00:00.000'. NetProfit holds unrealized P&L (updated daily). EndForexRate=NULL (position not yet closed).
- **Closed state**: CloseDateID=YYYYMMDD int (e.g., 20260310), CloseOccurred=actual datetime. NetProfit holds realized P&L. ClosePositionReasonID explains why it closed.
- **ETL daily cycle**: Each day, rows for positions that opened or closed that day are deleted/updated and re-inserted fresh from staging.
- **CloseDateID=19000101** is a transient internal state used during ETL processing (positions being "reset" before re-insertion); analysts should filter `WHERE CloseDateID NOT IN (0, 19000101)` for confirmed closed positions.
- **OpenDateID and CloseDateID**: Both are YYYYMMDD integers, NOT dates. Use `CAST(CAST(OpenDateID AS VARCHAR(8)) AS DATE)` to convert.

**Diagram**:
```
Position lifecycle in Dim_Position:
  Day 1 (open):  CloseDateID=0,        CloseOccurred='1900-01-01'  <-- still open
  Day N (close): CloseDateID=YYYYMMDD, CloseOccurred=actual time   <-- closed
  During ETL:    CloseDateID=19000101  <-- transient, skip in queries
```

### 2.2 Social Trading Relationships

**What**: How copy-trading and mirror relationships are encoded.

**Columns Involved**: `MirrorID`, `ParentPositionID`, `OrigParentPositionID`, `TreeID`, `IsCopyFundPosition`

**Rules**:
- **MirrorID**: FK to Dim_Mirror. When a customer copies another trader, all positions generated share the same MirrorID.
- **ParentPositionID**: The position ID of the "master" position being copied. NULL for original/manual positions.
- **OrigParentPositionID**: The original parent (before any reopen/rebalance operations).
- **TreeID**: FK back to Dim_Position.PositionID -- points to the root position of the copy tree. Used to identify CopyFund positions.
- **IsCopyFundPosition=1**: The position belongs to a copy-fund tree (TreeID's CID has AccountTypeID=9).

### 2.3 Financial Metrics and Commissions

**What**: How P&L and commission amounts flow through a position lifecycle.

**Columns Involved**: `Amount`, `NetProfit`, `Commission`, `CommissionOnClose`, `FullCommission`, `FullCommissionOnClose`, `EndOfWeekFee`, `PnLInDollars`

**Rules**:
- **Amount**: Position notional value in USD at open.
- **NetProfit**: Realized P&L for closed positions; unrealized daily P&L for open positions (updated daily from EndOfDayPnLInDollars).
- **Commission**: Opening commission charged.
- **CommissionOnClose**: Closing commission. Set to 0 for open positions; filled when position closes.
- **FullCommission / FullCommissionOnClose**: Total commissions including all components.
- **EndOfWeekFee**: Overnight fee charged on weekends for leveraged positions. CloseOnEndOfWeek=1 means position auto-closes at weekend.
- **PnLInDollars**: Unrealized daily P&L for open positions (from EndOfDayPnLInDollars staging column); realized at close.

### 2.4 Position Segmentation and Regulation

**What**: Regulatory context and platform categorization at time of open.

**Columns Involved**: `RegulationIDOnOpen`, `PlatformTypeID`, `PositionSegment`

**Rules**:
- **RegulationIDOnOpen**: The regulatory jurisdiction (entity) the customer belonged to at the time of opening. Derived from a JOIN with etoro_History_BackOfficeCustomer at ETL time. 1=UK/FCA, 2=Cyprus/CySEC, etc.
- **PlatformTypeID**: FK to Dim_PlatformType. 1=Web, 2=iOS, 3=Android, 0=Undefined.
- **PositionSegment**: Internal segment classification (smallint).

### 2.5 Volume and Unit Calculations

**What**: ETL-computed unit and volume metrics.

**Columns Involved**: `AmountInUnitsDecimal`, `LotCountDecimal`, `Volume`, `VolumeOnClose`, `UnitMargin`, `InitialUnits`

**Rules**:
- **AmountInUnitsDecimal**: Position size in instrument units (e.g., shares, crypto coins).
- **LotCountDecimal**: Position size in lots.
- **Volume**: ETL-computed = ROUND(AmountInUnitsDecimal * InitForexRate * USD conversion factor, 0) -- approximates USD equivalent at open.
- **VolumeOnClose**: Similar calculation using EndForexRate at close.
- **UnitMargin**: Margin per unit for leveraged positions.
- **InitialUnits**: Original units before any partial-close or partial-reopen adjustments.

### 2.6 Open/Close Rates and Market Prices

**What**: The forex rates, market prices, and spread data captured at open and close.

**Columns Involved**: `InitForexRate`, `EndForexRate`, `SpreadedPipBid`, `SpreadedPipAsk`, `InitForex_Ask/Bid/AskSpreaded/BidSpreaded/USDConversionRate`, `EndForex_*`, `OpenMarket_*`, `CloseMarket_*`

**Rules**:
- **InitForexRate / EndForexRate**: The execution rate at open and close respectively (in instrument's base currency per USD or USD per instrument).
- **InitForex_* columns**: Ask, Bid, spreaded variants, and USD conversion rate at the INIT price rate ID (raw price book). Populated from PriceLog_History_CurrencyPrice_Active.
- **EndForex_***: Same price book data at the END (close) rate.
- **OpenMarket_* / CloseMarket_***: Market prices at the time of market open/close events. Added 2023-03-07 (12 columns).
- **SpreadedPipBid / SpreadedPipAsk**: Bid/ask spread in pips at execution.

### 2.7 Fees and Taxes (Post-2025)

**What**: Tax and fee components added in 2025.

**Columns Involved**: `OpenTotalTaxes`, `CloseTotalTaxes`, `OpenTotalFees`, `CloseTotalFees`, `EstimateCloseFeeForCFD`, `EstimateCloseFeeOnOpenByUnits`, `EstimateCloseFeeOnOpen`, `Close_PnLInDollars`, `Close_CalculationRate`, `Close_ConversionRate`, `Close_PriceType`, `CurrentCalculationRate`, `CurrentConversionRate`

**Rules**:
- Added 2025-06-25 (Adi Ferber) and 2025-09-08 (Daniel Kaplan).
- These columns will be NULL for positions opened/closed before the ETL addition date.
- `EstimateCloseFeeForCFD/OnOpenByUnits/OnOpen`: Fee estimates for CFD instruments at open.
- `Close_PnLInDollars / Close_CalculationRate / Close_ConversionRate / Close_PriceType`: Close-side P&L metrics with explicit calculation chain.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Partitioning

**HASH (PositionID)**: Rows distributed by PositionID across nodes. Single-position lookups are efficient. JOINs between two HASH(PositionID) tables (e.g., Dim_Position JOIN Dim_PositionChangeLog by PositionID) are co-located and fast.

**Clustered Index (CloseDateID, PositionID)**: Clustered on close date -- date-range queries on closed positions are efficient. Open-position queries (CloseDateID=0) hit a single partition.

**Monthly partitioning**: Partitioned from 2007-01-01 to 2026-02-28 by CloseDateID. Always include a CloseDateID range filter in queries to enable partition elimination. Without it, all 230+ partitions are scanned.

**NOT ENFORCED PK**: The primary key on (PositionID, CloseDateID) is NOT ENFORCED. Synapse does not validate uniqueness. PositionID is logically unique per position, but be aware: duplicate PositionIDs can exist if ETL has a bug.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position`. Partitioned monthly by CloseDateID. Use `WHERE CloseDateID >= 20260101` style filters for partition pruning. Z-ORDER on PositionID within each partition is beneficial for position-lookup workloads.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get closed positions for a date range | WHERE CloseDateID BETWEEN 20260101 AND 20260310 |
| Get all open positions | WHERE CloseDateID = 0 |
| Get a customer's positions | WHERE CID = X AND CloseDateID BETWEEN ... (always include date range!) |
| P&L for closed positions | SUM(NetProfit) WHERE CloseDateID > 0 AND CloseDateID != 19000101 |
| CopyTrading positions only | WHERE MirrorID IS NOT NULL |
| Direct (non-copy) positions | WHERE MirrorID IS NULL AND ParentPositionID IS NULL |
| CopyFund positions only | WHERE IsCopyFundPosition = 1 |
| Long positions only | WHERE IsBuy = 1 |
| Short positions | WHERE IsBuy = 0 |
| By instrument | WHERE InstrumentID = X AND CloseDateID BETWEEN ... |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Resolve instrument name, asset class |
| DWH_dbo.Dim_Customer | ON CID | Customer info, tier, country |
| DWH_dbo.Dim_Currency | ON CurrencyID | Position base currency |
| DWH_dbo.Dim_Mirror | ON MirrorID | Copy-trading relationship details |
| DWH_dbo.Dim_ClosePositionReason | ON ClosePositionReasonID | Why position was closed |
| DWH_dbo.Dim_Platform | ON PlatformTypeID | Platform used to open |
| DWH_dbo.Dim_Date | ON OpenDateID / CloseDateID | Calendar dimensions |
| DWH_dbo.Dim_PositionChangeLog | ON PositionID | Position lifecycle changes (IsSettled, Amount changes) |

### 3.4 Gotchas

- **NEVER query without CloseDateID filter**: Without a date range filter, Synapse scans all 230+ monthly partitions. Always include `WHERE CloseDateID BETWEEN X AND Y` or `WHERE CloseDateID = 0`.
- **CloseDateID=0 for open, CloseDateID=19000101 during ETL**: Exclude 19000101 in most queries: `WHERE CloseDateID NOT IN (0, 19000101)` for confirmed-closed positions.
- **OpenDateID and CloseDateID are int, not date**: They are in YYYYMMDD format. Use `CAST(CAST(OpenDateID AS VARCHAR(8)) AS DATE)` to convert.
- **HASH distribution on PositionID**: Very efficient for single-position or position-list queries. Less efficient for large customer-level scans (CID is not the distribution key).
- **NOT ENFORCED PK**: PositionID uniqueness is not enforced by the database. Check for duplicates if needed.
- **134 columns -- many nullable**: Most columns beyond the core set are NULL for older positions predating their addition (2022-2025). Don't assume non-null.
- **Volume = ETL-computed approximation**: Volume (int) is rounded to nearest integer. VolumeOnClose uses EndForexRate which may differ. Not always perfectly accurate.
- **UpdateDate = GETDATE() or GETUTCDATE()**: Mixed -- open positions use GETDATE(), UPDATE path for closing positions uses GETUTCDATE(). Not a reliable "modified since" field.
- **IsPartialCloseParent / IsPartialCloseChild**: 1 if this position was split via partial close. Use OriginalPositionID to trace the original. Generally filter ISNULL(IsPartialCloseChild,0)=0 on OPEN metrics only — NEVER on CLOSE. Some open metrics (e.g., volume) are already pro-rated, so excluding children would be wrong. Apply the filter case-by-case.
- **RegulationIDOnOpen is 0 for unmatched**: If the ETL JOIN with BackOfficeCustomer history finds no regulation at that date, ISNULL defaults to 0.
- **AmountInUnitsDecimal may change**: Position amount can be adjusted (e.g., partial close). Dim_PositionChangeLog tracks historical amount values.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| ** | Tier 3 - MCP live data | (Tier 3 - MCP live data) |
| * | Tier 4 - Inferred from name | (Tier 4 - [UNVERIFIED]) |

Note: Upstream production wikis available for Trade.PositionTbl and Trade.OpenPositionEndOfDay. Columns with direct passthrough or view-computed staging get Tier 1. ETL-computed and PriceLog-enriched columns get Tier 2.

**Column Groups** (134 total):

#### Group A: Core Identity (5 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | bigint | NO | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. (Tier 1 — Trade.PositionTbl) |
| 2 | CID | int | YES | Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl) |
| 3 | InstrumentID | int | NO | FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl) |
| 4 | CurrencyID | int | NO | FK to Dictionary.Currency. Denomination currency for Amount, NetProfit. Must be > 0. (Tier 1 — Trade.PositionTbl) |
| 5 | ProviderID | int | NO | References Trade.Provider. Execution provider (default 1 = TRADONOMI in PositionOpen). (Tier 1 — Trade.PositionTbl) |

#### Group B: Lifecycle Timestamps and Date IDs (6 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 6 | OpenOccurred | datetime | NO | When position was persisted (mapped from Occurred in production). Default getutcdate(). (Tier 1 — Trade.PositionTbl) |
| 7 | CloseOccurred | datetime | NO | When close was persisted. (Tier 1 — Trade.PositionTbl) |
| 8 | OpenDateID | int | NO | ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 9 | CloseDateID | int | NO | ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. **Partition column.** Always include in WHERE clause. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 10 | RequestOpenOccurred | datetime2(7) | YES | When the open request arrived at Trading API. Distinct from OpenOccurred (DB insert time). (Tier 1 — Trade.PositionTbl) |
| 11 | RequestCloseOccurred | datetime2(7) | YES | When close request arrived at API. (Tier 1 — Trade.PositionTbl) |

#### Group C: Financial Metrics (13 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 12 | Amount | money | NO | Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents). (Tier 1 — Trade.PositionTbl) |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | Position size in units/shares. Fractional lots. (Tier 1 — Trade.PositionTbl) |
| 14 | InitialAmountCents | money | YES | Initial amount in cents. Used for ratio calculations. (Tier 1 — Trade.PositionTbl) |
| 15 | InitialUnits | decimal(16,6) | YES | Original unit count at open. Used for partial close ratio. (Tier 1 — Trade.PositionTbl) |
| 16 | NetProfit | money | NO | Realized PnL. 0 when open; set on close. In position currency. (Tier 1 — Trade.PositionTbl) |
| 17 | PnLInDollars | decimal(38,6) | YES | Max-rate PnL in dollars. From Trade.FnCalculatePnLWrapper using the max-date market rate. Represents unrealized profit/loss at the highest available price timestamp. (Tier 1 — Trade.OpenPositionEndOfDay) |
| 18 | Commission | money | NO | Open commission in dollars. PositionOpen stores @Commission/100 (cents to dollars). (Tier 1 — Trade.PositionTbl) |
| 19 | CommissionOnClose | money | NO | Commission charged on close. DWH note: adjusted by SP_Dim_Position when position is reopened; CommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 — Trade.PositionTbl) |
| 20 | FullCommission | money | YES | Full commission including spread. PositionOpen stores @FullCommission/100. (Tier 1 — Trade.PositionTbl) |
| 21 | FullCommissionOnClose | money | YES | Full commission on close. DWH note: adjusted by SP_Dim_Position when position is reopened; FullCommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 — Trade.PositionTbl) |
| 22 | CommissionByUnits | decimal(38,6) | YES | Prorated commission for partial close. Formula: (AmountInUnitsDecimal / InitialUnits) * Commission. Used for partial-close PnL. (Tier 1 — Trade.Position) |
| 23 | FullCommissionByUnits | decimal(38,6) | YES | Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission. (Tier 1 — Trade.Position) |
| 24 | EndOfWeekFee | money | NO | Overnight/weekend carry fee. (Tier 1 — Trade.PositionTbl) |

#### Group D: ETL-Computed Volumes and Units (4 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 25 | LotCountDecimal | decimal(16,6) | YES | Lot count from provider. Used for hedge aggregation and unit-based sizing. (Tier 1 — Trade.PositionTbl) |
| 26 | UnitMargin | decimal(15,8) | YES | Margin per unit. From Trade.ProviderToInstrument. (Tier 1 — Trade.PositionTbl) |
| 27 | Volume | int | YES | ETL-computed approximation of USD value: ROUND(AmountInUnitsDecimal * InitForexRate * USD conversion, 0). (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 28 | VolumeOnClose | int | YES | ETL-computed USD volume at close: ROUND(AmountInUnitsDecimal * EndForexRate * USD conversion, 0). 0 for open positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group E: Direction, Leverage, and Trade Settings (5 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 29 | IsBuy | bit | NO | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl) |
| 30 | Leverage | int | NO | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl) |
| 31 | CloseOnEndOfWeek | bit | NO | Weekend-close flag. 1 = position auto-closes at end of trading week. (Tier 1 — Trade.PositionTbl) |
| 32 | LimitRate | decimal(16,8) | YES | Take-profit rate set at open (or most recent update). (Tier 1 — Trade.PositionTbl) |
| 33 | StopRate | decimal(16,8) | YES | Stop-loss rate set at open (or most recent update). Can be updated via PositionChangeLog. (Tier 1 — Trade.PositionTbl) |

#### Group F: Forex Rates (6 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 34 | InitForexRate | decimal(16,8) | NO | Opening price rate at position open. Used for PnL calculation. (Tier 1 — Trade.PositionTbl) |
| 35 | EndForexRate | decimal(16,8) | YES | Closing rate at position close. NULL for open positions. (Tier 1 — Trade.PositionTbl) |
| 36 | LastOpConversionRate | decimal(16,8) | YES | Conversion rate for last operation. (Tier 1 — Trade.PositionTbl) |
| 37 | InitConversionRate | decimal(16,8) | YES | Currency conversion rate at open. (Tier 1 — Trade.PositionTbl) |
| 38 | SpreadedPipBid | decimal(16,8) | YES | Bid rate with spread at open. From Trade.CurrencyPrice/spread config. (Tier 1 — Trade.PositionTbl) |
| 39 | SpreadedPipAsk | decimal(16,8) | YES | Ask rate with spread at open. (Tier 1 — Trade.PositionTbl) |

#### Group G: Price Rate IDs and Execution IDs (7 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 40 | InitForexPriceRateID | bigint | YES | FK to price log table -- the specific price rate record at open. (Tier 1 — Trade.PositionTbl) |
| 41 | EndForexPriceRateID | bigint | YES | Price rate ID at close. (Tier 1 — Trade.PositionTbl) |
| 42 | LastOpPriceRateID | bigint | YES | Last operation price rate ID. (Tier 1 — Trade.PositionTbl) |
| 43 | LastOpPriceRate | decimal(16,8) | YES | Last operation price. Updated on partial close, dividend, etc. (Tier 1 — Trade.PositionTbl) |
| 44 | OpenMarketPriceRateID | bigint | YES | Market price rate ID at open. (Tier 1 — Trade.PositionTbl) |
| 45 | CloseMarketPriceRateID | bigint | YES | Market price rate ID at close. (Tier 1 — Trade.PositionTbl) |
| 46 | InitConversionRateID | bigint | YES | Conversion rate record ID at open. (Tier 1 — Trade.PositionTbl) |

#### Group H: Execution IDs (2 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 47 | InitExecutionID | bigint | YES | Execution record ID at open. (Tier 1 — Trade.PositionTbl) |
| 48 | EndExecutionID | bigint | YES | Execution record ID at close. NULL for open positions. (Tier 1 — Trade.PositionTbl) |

#### Group I: Market Price Data at Open (10 columns -- added 2023-03-07)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 49 | InitForex_Ask | numeric(16,8) | YES | Raw ask price at open from price book. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 50 | InitForex_Bid | numeric(16,8) | YES | Raw bid price at open from price book. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 51 | InitForex_AskSpreaded | numeric(16,8) | YES | Ask price including spread at open. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 52 | InitForex_BidSpreaded | numeric(16,8) | YES | Bid price including spread at open. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 53 | InitForex_USDConversionRate | numeric(16,8) | YES | USD conversion rate at open from price book. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 54 | EndForex_Ask | numeric(16,8) | YES | Raw ask at close. NULL for open positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 55 | EndForex_Bid | numeric(16,8) | YES | Raw bid at close. NULL for open positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 56 | EndForex_AskSpreaded | numeric(16,8) | YES | Spreaded ask at close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 57 | EndForex_BidSpreaded | numeric(16,8) | YES | Spreaded bid at close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 58 | EndForex_USDConversionRate | numeric(16,8) | YES | USD conversion rate at close from price book. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group J: Market Spread Data (8 columns -- added 2023-03-07)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 59 | OpenMarket_Ask | numeric(16,8) | YES | Market ask at time of open-side market event. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 60 | OpenMarket_Bid | numeric(16,8) | YES | Market bid at time of open-side market event. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 61 | OpenMarket_AskSpreaded | numeric(16,8) | YES | Spreaded market ask at open. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 62 | OpenMarket_BidSpreaded | numeric(16,8) | YES | Spreaded market bid at open. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 63 | OpenMarketCoversionRateBidSpreaded | numeric(16,8) | YES | USD conversion rate (bid-spreaded) at market open. Note: "Coversion" typo in original DDL. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 64 | OpenMarketCoversionRateAskSpreaded | numeric(16,8) | YES | USD conversion rate (ask-spreaded) at market open. Note: "Coversion" typo in original DDL. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 65 | CloseMarket_Ask | numeric(16,8) | YES | Market ask at close event. NULL for open positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 66 | CloseMarket_Bid | numeric(16,8) | YES | Market bid at close event. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group K: Close Market Spread (4 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 67 | CloseMarket_AskSpreaded | numeric(16,8) | YES | Spreaded market ask at close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 68 | CloseMarket_BidSpreaded | numeric(16,8) | YES | Spreaded market bid at close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 69 | CloseMarketCoversionRateBidSpreaded | numeric(16,8) | YES | USD conversion rate (bid-spreaded) at market close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 70 | CloseMarketCoversionRateAskSpreaded | numeric(16,8) | YES | USD conversion rate (ask-spreaded) at market close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group L: Markup and Spread Metrics (7 columns -- added 2024-01-15)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 71 | OpenMarketSpread | decimal(38,18) | YES | Spread at open. (Tier 1 — Trade.PositionTbl) |
| 72 | CloseMarketSpread | decimal(38,18) | YES | Spread at close. (Tier 1 — Trade.PositionTbl) |
| 73 | CloseMarkupOnOpen | decimal(38,18) | YES | Close markup projected at open. (Tier 1 — Trade.PositionTbl) |
| 74 | OpenMarkup | decimal(38,18) | YES | Markup at open. (Tier 1 — Trade.PositionTbl) |
| 75 | CloseMarkup | decimal(38,18) | YES | Markup at close. (Tier 1 — Trade.PositionTbl) |
| 76 | OpenMarkupByUnits | money | YES | Prorated open markup for partial close. Formula: OpenMarkup * AmountInUnitsDecimal / InitialUnits. (Tier 1 — Trade.Position) |
| 77 | SpreadedCommission | int | YES | Spread-related commission component. (Tier 1 — Trade.PositionTbl) |

#### Group M: Social Trading and Hierarchy (8 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 78 | MirrorID | int | YES | FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. (Tier 1 — Trade.PositionTbl) |
| 79 | HedgeID | int | YES | FK to Trade.Hedge. Broker executed hedge. NULL until hedge is opened. (Tier 1 — Trade.PositionTbl) |
| 80 | HedgeServerID | int | YES | FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl) |
| 81 | ParentPositionID | bigint | YES | Copy-trade parent. 0/1 = root. Positive = child of referenced position. (Tier 1 — Trade.PositionTbl) |
| 82 | OrigParentPositionID | bigint | YES | Original parent before any detachment. (Tier 1 — Trade.PositionTbl) |
| 83 | TreeID | bigint | YES | Links to Trade.PositionTreeInfo. Root: TreeID=PositionID. Children: root PositionID. Demo: negative. (Tier 1 — Trade.PositionTbl) |
| 84 | IsCopyFundPosition | int | YES | 1=position belongs to a copy fund tree (TreeID's CID has AccountTypeID=9). ETL-computed via JOIN chain. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 85 | IsOpenOpen | bit | YES | Open-on-open copy behavior. From Mirror. (Tier 1 — Trade.PositionTbl) |

#### Group N: Partial Close and ReOpen (7 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 86 | ReopenForPositionID | bigint | YES | When position was reopened: references the erroneously closed PositionID. (Tier 1 — Trade.PositionTbl) |
| 87 | IsReOpen | int | YES | 1=this position was reopened from ReopenForPositionID. ETL-computed: CASE WHEN ReopenForPositionID IS NOT NULL THEN 1. Default 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 88 | OriginalPositionID | bigint | YES | Original position ID for positions split by partial close. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 89 | IsPartialCloseParent | int | YES | 1=this position was partially closed (is the parent in a partial close event). (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 90 | IsPartialCloseChild | int | YES | 1=this position is the child (remainder) of a partial close event. Generally filter out child positions from most metrics on OPEN when aggregating, but not all (e.g., volume is already pro-rated so excluding these is wrong). NEVER filter these out on CLOSE. (Tier 5 — domain expert, SP_Dim_Position_DL_To_Synapse) |
| 91 | IsPartialCloseChildFromReOpen | int | YES | 1=partial close child that was created via a ReOpen flow. (Tier 4 - [UNVERIFIED]) |
| 92 | CommissionOnCloseOrig | money | YES | Original CommissionOnClose before reopen adjustments. ETL: CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group O: Settlement and Redemption (5 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 93 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 94 | IsSettledOnOpen | int | YES | 1 = real asset, 0 = CFD asset. Value at position open (snapshot); same 0/1 encoding as IsSettled. (Tier 5 — Expert Review) |
| 95 | RedeemStatus | tinyint | YES | Redemption state. Billing.Redeem integration. (Tier 1 — Trade.PositionTbl) |
| 96 | RedeemID | int | YES | Billing.Redeem reference when position closed via redeem. (Tier 1 — Trade.PositionTbl) |
| 97 | FullCommissionOnCloseOrig | money | YES | Original FullCommissionOnClose before reo

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Fact_CurrencyPriceWithSplit` — synapse
- **Resolved as**: `DWH_dbo.Fact_CurrencyPriceWithSplit`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md`

# DWH_dbo.Fact_CurrencyPriceWithSplit

> Daily price snapshot fact table capturing bid/ask prices per financial instrument per day, with spread-adjusted values, split-adjusted history for corporate-action dates, and pre-computed USD conversion rates.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView (Data Lake export) |
| **Refresh** | Daily (per-date incremental via @dt parameter) |
| | |
| **Synapse Distribution** | HASH(InstrumentID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE + NONCLUSTERED(OccurredDateID) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit |
| **UC Format** | Delta (Merge strategy, daily) |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

Fact_CurrencyPriceWithSplit is the DWH's authoritative daily price reference table. It stores one or more price rows per instrument per calendar day, including the raw bid/ask prices, spread-adjusted prices (AskSpreaded/BidSpreaded), and the last execution rate (RateLastEx). The `isvalid` flag marks whether a given price row was the active price at end-of-day. This table is the primary source for historical price look-ups used in P&L calculations across the warehouse.

Data originates from the PriceLog Candles pipeline in the Data Lake. The staging view `DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView` delivers daily candlestick prices for all instruments. On dates when a stock split occurs (identified via `DWH_staging.etoro_History_SplitRatio`), the ETL switches to `PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory`, which provides historically-adjusted prices for the affected instruments.

Loaded daily by `SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse(@dt)`. The SP deletes all rows for the given date, reloads from staging, then applies a split-branch if split events exist. A final UPDATE pass computes `ConvertRateIsBuy_1` and `ConvertRateIsBuy_0` using cross-currency logic to normalize instrument prices to USD. Data covers 2009-06-15 to the present with approximately 17.2M rows across 15,400+ distinct instruments.

---

## 2. Business Logic

### 2.1 Stock Split Price Adjustment

**What**: When a corporate action (stock split) occurs on a given date, prices for the affected instrument must be reloaded using split-adjusted history rather than the standard daily candle.

**Columns Involved**: `InstrumentID`, `OccurredDateID`, `AskSpreaded`, `BidSpreaded`, `Ask`, `Bid`, `RateLastEx`

**Rules**:
- On each daily run, the SP checks `DWH_staging.etoro_History_SplitRatio` for splits on `@dt`
- If split records exist (`@CountRowsSplit > 0`), all rows for the affected `InstrumentID` values are deleted from Fact_CurrencyPriceWithSplit
- Replacement rows are loaded from `PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory`, which contains the retroactively adjusted price series
- `ConvertRateIsBuy_1/0` from the pre-split date are preserved via a `#ConvertRateIsBuy` temp table join

**Diagram**:
```
Daily run:
  DELETE WHERE OccurredDateID = @DateID
  INSERT FROM PriceLog_Candles_CurrencyPriceMaxDateWithSplitView

Split check:
  IF etoro_History_SplitRatio has rows for @dt:
    DELETE affected instruments
    INSERT FROM PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory
    PRESERVE ConvertRates from pre-split data via #ConvertRateIsBuy temp table
```

### 2.2 USD Conversion Rate Computation

**What**: After loading prices, the SP computes two pre-calculated USD conversion rates per instrument per day, one for buy-side positions and one for sell-side. These rates allow downstream consumers to convert instrument P&L to USD without re-deriving the currency cross-rate.

**Columns Involved**: `ConvertRateIsBuy_1`, `ConvertRateIsBuy_0`, `Ask`, `Bid`, `InstrumentID`

**Rules**:
- Instrument currency pairs are loaded from `DWH_staging.etoro_Trade_GetInstrument` into `Ext_FCPWS_Instrument`
- If `SellCurrencyID = 1` (USD is the sell/quote currency): rate = 1.00 (already in USD)
- If `BuyCurrencyID = 1` (USD is the base currency): IsBuy_1 = 1/Bid, IsBuy_0 = 1/Ask
- If neither currency is USD: find a bridging instrument with USD as base/quote and apply cross-rate
- `ConvertRateIsBuy_1` is for buy-side positions (IsBuy=1); `ConvertRateIsBuy_0` for sell-side

**Diagram**:
```
For each instrument on @DateID:
  If SellCurrencyID = 1 (USD quote):   ConvertRate = 1.00
  If BuyCurrencyID = 1 (USD base):     ConvertRate = 1/Bid (buy) or 1/Ask (sell)
  If no direct USD pair:               ConvertRate via cross-rate through a USD-paired instrument
  Null if no cross-rate found:         COALESCE(..., 1.00) fallback
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH-distributed on `InstrumentID` with a CLUSTERED COLUMNSTORE index. Always include `InstrumentID` in JOIN conditions for co-location with Dim_Instrument. A secondary NONCLUSTERED index on `OccurredDateID` supports date-range lookups. For date-range queries, filter on `OccurredDateID` (integer YYYYMMDD) rather than `OccurredDate` to leverage the NCI.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the table is registered as `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit`, stored as Delta with a Merge copy strategy (daily refresh). Partition and Z-ORDER columns are resolved during the write-objects deployment phase.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get USD conversion rate for an instrument on a specific date | `WHERE InstrumentID = @id AND OccurredDateID = @dateID AND isvalid = 1` |
| Full price history for an instrument | `WHERE InstrumentID = @id ORDER BY OccurredDate` |
| End-of-day price for all instruments on a date | `WHERE OccurredDateID = @dateID AND isvalid = 1` |
| Instruments with split events on a date | JOIN to `Ext_FCPWS_History_SplitRatio` on InstrumentID and date range |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON f.InstrumentID = di.InstrumentID | Resolve instrument name, symbol, type |
| DWH_dbo.Dim_Date | ON f.OccurredDateID = dd.DateID | Resolve date to year/month/quarter |
| DWH_dbo.Ext_FCPWS_Instrument | ON f.InstrumentID = ei.InstrumentID | Get buy/sell currency pair for the instrument |

### 3.4 Gotchas

- `isvalid = 0` rows (~46% of all rows) represent non-active price records for the day. Most P&L queries should filter `isvalid = 1` to get the effective end-of-day price.
- `ConvertRateIsBuy_1` and `ConvertRateIsBuy_0` are NULL for ~1.3M rows (7.5% of the table) where no cross-rate could be computed. Use `ISNULL(..., 1.0)` in downstream calculations or investigate via `Ext_FCPWS_Instrument`.
- The table has 3 distinct `ProviderID` values. Typical analytical queries do not filter on ProviderID, but be aware that multiple providers may contribute prices for the same instrument on the same date.
- `OccurredDateID` is in YYYYMMDD integer format (e.g., 20240113), not a DATE. The NCI is on this column - prefer it for range filters over `OccurredDate`.
- The ETL is date-parameterized (`@dt`). It does NOT do a full reload - it deletes and reloads one date at a time. Gaps can appear if the SP was not run for a date.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Notes |
|-------|------|-----|-------|
| ★★★★★ | Tier 5 | `(Tier 5 - domain expert)` | Expert-confirmed |
| ★★★★☆ | Tier 1 | `(Tier 1 - upstream wiki, source)` | Upstream wiki verbatim |
| ★★★☆☆ | Tier 2 | `(Tier 2 - SP code / DDL)` | From SSDT SP or DDL analysis |
| ★★☆☆☆ | Tier 3 | `(Tier 3 - live data / DDL structure)` | From sampling or DDL |
| ★☆☆☆☆ | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Inferred, needs expert review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ProviderID | int | YES | Price provider identifier. 3 distinct values in production. Indicates which data provider sourced the price candle. Passed through from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 2 | InstrumentID | int | YES | Financial instrument identifier. Foreign key to DWH_dbo.Dim_Instrument. HASH distribution column - include in all JOINs for optimal Synapse performance. 15,416 distinct instruments in production. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 3 | Occurred | datetime | YES | Exact timestamp when the price was recorded. Sub-day precision. Use OccurredDate or OccurredDateID for date-level aggregations. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 4 | OccurredDate | date | YES | Calendar date of the price record. Date portion of Occurred. Use for date joins or display. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 5 | OccurredDateID | int | YES | Date as YYYYMMDD integer (e.g., 20240113). Secondary NCI index key. Use this column for date-range filters to leverage the NONCLUSTERED index. Corresponds to DWH_dbo.Dim_Date.DateID. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 6 | isvalid | int | YES | Row validity flag. 1 = active/valid end-of-day price for this instrument on this date. 0 = non-active record (e.g., intraday snapshot or superseded row). Filter isvalid = 1 for end-of-day analytical queries. ~54% of rows are valid. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 7 | AskSpreaded | numeric(36,12) | YES | Spread-adjusted ask (offer) price for the instrument. The ask price with the broker spread applied. Used in P&L calculations for buy-side opening cost. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 8 | BidSpreaded | numeric(36,12) | YES | Spread-adjusted bid price for the instrument. The bid price with the broker spread applied. Used in P&L calculations for sell-side closing proceeds. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 9 | RateLastEx | numeric(36,12) | YES | Last execution rate for the instrument on this date. The price at which the most recent trade was executed. Reference rate for settlement. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 10 | Ask | numeric(36,12) | YES | Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 11 | Bid | numeric(36,12) | YES | Raw bid price before spread adjustment. Mid-price reference. Compare to BidSpreaded to derive the spread. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 12 | UpdateDate | datetime | NO | DWH load timestamp. Set to GETDATE() at ETL execution time. Not the price timestamp - use Occurred for price time. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 13 | ConvertRateIsBuy_1 | numeric(18,4) | YES | Pre-computed USD conversion rate for buy-side positions (IsBuy=1). Multiply by instrument price to convert to USD. Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Bid; otherwise cross-rate. NULL where no cross-rate could be determined. Added 2023-02-26. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 14 | ConvertRateIsBuy_0 | numeric(18,4) | YES | Pre-computed USD conversion rate for sell-side positions (IsBuy=0). Multiply by instrument price to convert to USD. Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Ask; otherwise cross-rate. NULL where no cross-rate could be determined. Added 2023-02-26. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ProviderID | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | ProviderID | Passthrough |
| InstrumentID | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | InstrumentID | Passthrough; on split dates from SplitInstHistory variant |
| Occurred | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Occurred | Passthrough |
| OccurredDate | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | OccurredDate | Passthrough |
| OccurredDateID | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | OccurredDateID | Passthrough |
| isvalid | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | isvalid | Passthrough |
| AskSpreaded | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | AskSpreaded | Passthrough |
| BidSpreaded | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | BidSpreaded | Passthrough |
| RateLastEx | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | RateLastEx | Passthrough |
| Ask | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Ask | Passthrough |
| Bid | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Bid | Passthrough |
| UpdateDate | ETL-computed | N/A | GETDATE() at load time |
| ConvertRateIsBuy_1 | ETL-computed (UPDATE pass) | Bid/Ask cross-rate | CASE on BuyCurrencyID/SellCurrencyID via Ext_FCPWS_Instrument |
| ConvertRateIsBuy_0 | ETL-computed (UPDATE pass) | Bid/Ask cross-rate | CASE on BuyCurrencyID/SellCurrencyID via Ext_FCPWS_Instrument |

No upstream wiki available for DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView (Data Lake intermediate staging layer, not documented in DB_Schema wiki).

### 5.2 ETL Pipeline

```
Data Lake (PriceLog/Candles) -> DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView
  -> SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse(@dt)
    -> DWH_dbo.Fact_CurrencyPriceWithSplit [DELETE for @DateID + INSERT]

Split branch (when etoro_History_SplitRatio has rows for @dt):
  DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory
    -> re-INSERT split-affected instruments
  DWH_staging.etoro_Trade_GetInstrument -> Ext_FCPWS_Instrument
    -> UPDATE ConvertRateIsBuy_1/0 via cross-currency logic
```

| Step | Object | Description |
|------|--------|-------------|
| Source | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Daily price candles from Data Lake |
| Split source | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory | Split-adjusted historical prices |
| Split calendar | DWH_staging.etoro_History_SplitRatio | Identifies which instruments had splits on @dt |
| Instrument pairs | DWH_staging.etoro_Trade_GetInstrument | BuyCurrencyID/SellCurrencyID for ConvertRate |
| ETL | SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse | Per-date delete+insert + split branch + ConvertRate UPDATE |
| Target | DWH_dbo.Fact_CurrencyPriceWithSplit | Final DWH daily price table |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument name, symbol, type, asset class |
| OccurredDateID | DWH_dbo.Dim_Date (via Dim_Date.DateID) | Date dimension (year, month, quarter) |
| InstrumentID | DWH_dbo.Ext_FCPWS_Instrument | Currency pair lookup used during ConvertRate computation |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse | self-JOIN | ConvertRate computation reads same table for cross-rate |
| DWH_dbo.Fact_CustomerUnrealized_PnL (probable) | InstrumentID + OccurredDateID | Currency conversion for unrealized P&L (verify via SP_Fact_CustomerUnrealized_PnL_* analysis) |

---

## 7. Sample Queries

### 7.1 End-of-day prices for a set of instruments on a date

```sql
SELECT
    f.InstrumentID,
    di.InstrumentDisplayName,
    f.OccurredDate,
    f.Ask,
    f.Bid,
    f.AskSpreaded,
    f.BidSpreaded,
    f.RateLastEx,
    f.ConvertRateIsBuy_1,
    f.ConvertRateIsBuy_0
FROM [DWH_dbo].[Fact_CurrencyPriceWithSplit] f
JOIN [DWH_dbo].[Dim_Instrument] di ON f.InstrumentID = di.InstrumentID
WHERE f.OccurredDateID = 20240113
  AND f.isvalid = 1
ORDER BY di.InstrumentDisplayName;
```

### 7.2 Price history for a single instrument over a date range

```sql
SELECT
    f.OccurredDate,
    f.Ask,
    f.Bid,
    (f.Ask + f.Bid) / 2.0 AS MidPrice,
    f.ConvertRateIsBuy_1,
    f.isvalid
FROM [DWH_dbo].[Fact_CurrencyPriceWithSplit] f
WHERE f.InstrumentID = 1     -- replace with target InstrumentID
  AND f.OccurredDateID BETWEEN 20240101 AND 20240131
  AND f.isvalid = 1
ORDER BY f.OccurredDate;
```

### 7.3 Instruments with NULL ConvertRate (USD-conversion gap check)

```sql
SELECT
    f.InstrumentID,
    di.InstrumentDisplayName,
    COUNT(*) AS rows_with_null_rate
FROM [DWH_dbo].[Fact_CurrencyPriceWithSplit] f
JOIN [DWH_dbo].[Dim_Instrument] di ON f.InstrumentID = di.InstrumentID
WHERE f.ConvertRateIsBuy_1 IS NULL
  AND f.isvalid = 1
GROUP BY f.InstrumentID, di.InstrumentDisplayName
ORDER BY rows_with_null_rate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 7.7/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 14 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10*
*Object: DWH_dbo.Fact_CurrencyPriceWithSplit | Type: Table | Production Source: DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView*


### Upstream `DWH_dbo.Dim_HistorySplitRatio` — synapse
- **Resolved as**: `DWH_dbo.Dim_HistorySplitRatio`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_HistorySplitRatio.md`

# DWH_dbo.Dim_HistorySplitRatio

> Stock split and corporate action ratio table: maps each instrument's historical date ranges to the cumulative price and amount adjustment factors needed to normalize prices across split events.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | PriceLog.History.SplitRatio |
| **Refresh** | Daily (ETL) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (InstrumentID ASC, MinDate ASC, MaxDate ASC) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`DWH_dbo.Dim_HistorySplitRatio` stores the cumulative adjustment factors for every stock split and corporate action that has occurred on instruments traded on the eToro platform. Each row defines a contiguous date range (`MinDate` to `MaxDate`) during which a specific price ratio and amount ratio applied. When a new split occurs, the instrument gains a new row with a new date range, and all prior rows are updated to reflect the cumulative adjustment stack. The table is the canonical reference for converting historical prices to split-adjusted form for analytics.

Data originates from `PriceLog.History.SplitRatio` on the price server (AZR-W-PRICEDB-2-Price). The Generic Pipeline exports this table hourly to `Bronze/PriceLog/History/SplitRatio/` in the data lake (UC: `dealing.bronze_pricelog_history_splitratio`). The ETL SP (`SP_Dim_HistorySplitRatio_DL_To_Synapse`) then loads it into Synapse from `DWH_staging.etoro_History_SplitRatio` daily. Source: upstream `PriceLog.History.SplitRatio` (no upstream wiki in DB_Schema -- PriceLog is a standalone price server database).

The ETL uses a full TRUNCATE + INSERT pattern: the entire table is reloaded each run. The `UpdateDate` column is set to `GETDATE()` at load time (not from the source) and reflects the last ETL execution. As of 2026-03-11 the table holds 15,899 rows. The table is also exported downstream to Gold (`dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio`) daily. Note: consumer Fact SPs (`SP_Fact_CurrencyPriceWithSplit`, `SP_Fact_CustomerUnrealized_PnL`) read from the raw staging table or dedicated external tables (`Ext_FCPWS_History_SplitRatio`, `Ext_FCUPNL_History_SplitRatio`) for current-day split detection, not from this Dim_ table directly. The Dim_ form is the persisted reference copy for Gold export and analyst queries.

---

## 2. Business Logic

### 2.1 Date-Range Period Model

**What**: Each instrument has one or more consecutive non-overlapping date ranges. Within each range, the ratio values are constant. The ranges tile the full history from a start sentinel to an end sentinel.

**Columns Involved**: `InstrumentID`, `MinDate`, `MaxDate`

**Rules**:
- Each instrument has at least one row spanning `MinDate=2000-01-01` (beginning-of-history sentinel) to either a split date or `MaxDate=2100-01-01` (open-ended sentinel meaning "currently active").
- When a split occurs, the active row is split into two: the old range closes at the split event timestamp, and a new row opens from that timestamp with the new cumulative ratios.
- There are no gaps between consecutive ranges for a given instrument.
- The most recent (active) row always has `MaxDate=2100-01-01`.

**Diagram**:
```
Instrument with 2 splits (e.g., Apple):
  Row 1: MinDate=2000-01-01 | MaxDate=2014-06-08 | PriceRatio=0.0357 | AmountRatio=28.0
  Row 2: MinDate=2014-06-08 | MaxDate=2020-08-30 | PriceRatio=0.2500 | AmountRatio=4.0
  Row 3: MinDate=2020-08-30 | MaxDate=2100-01-01 | PriceRatio=1.0000 | AmountRatio=1.0
         (active, no further splits yet)
```

### 2.2 Cumulative Ratio Pair

**What**: `PriceRatio` and `AmountRatio` are reciprocal adjustment multipliers. `PriceRatioUnAdjusted` and `AmountRatioUnAdjusted` capture the incremental ratio of the most recent split only (not cumulative).

**Columns Involved**: `PriceRatio`, `AmountRatio`, `PriceRatioUnAdjusted`, `AmountRatioUnAdjusted`

**Rules**:
- `AdjustedPrice = HistoricalPrice * PriceRatio` (converts old price to post-split-equivalent)
- `AdjustedAmount = HistoricalAmount * AmountRatio` (converts old quantity to post-split-equivalent)
- For instruments with no splits: `PriceRatio=1.0`, `AmountRatio=1.0`, `PriceRatioUnAdjusted=1.0`, `AmountRatioUnAdjusted=1.0`
- `PriceRatio * AmountRatio` should approximately equal 1.0 (price and amount adjustments are inverse)
- `PriceRatioUnAdjusted` and `AmountRatioUnAdjusted` reflect only the most recent split increment, not the cumulative history

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `(InstrumentID ASC, MinDate ASC, MaxDate ASC)`. Because it is replicated, it is available on every distribution node without a shuffle -- ideal for JOINs against large fact tables. The clustered index on the three key columns optimizes range lookups: `WHERE InstrumentID = @id AND @price_date >= MinDate AND @price_date < MaxDate` resolves via a clustered index seek.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold table (`dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio`) is exported daily. No partition strategy is defined yet -- _pending write-objects resolution_. For best performance when querying split history in Databricks, filter by `InstrumentID` to leverage potential Z-ORDER.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Find the ratio for a specific instrument on a specific date | `WHERE InstrumentID = @id AND @dt >= MinDate AND @dt < MaxDate` -- exactly one row should match |
| Adjust historical prices to current split-adjusted form | Join on the date range condition above, multiply by `PriceRatio` |
| Find all instruments that had splits in a given year | `WHERE MinDate >= @year_start AND MinDate < @year_end AND PriceRatio != 1.0` |
| Get the active (current) ratio for all instruments | `WHERE MaxDate = '2100-01-01'` -- returns one row per instrument |
| Find instruments with the most split history | `GROUP BY InstrumentID HAVING COUNT(*) > 1 ORDER BY COUNT(*) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Currency | `ON Dim_Currency.CurrencyID = Dim_HistorySplitRatio.InstrumentID` | Resolve InstrumentID to instrument name, type, symbol |
| DWH_dbo.Dim_Instrument | `ON Dim_Instrument.InstrumentID = Dim_HistorySplitRatio.InstrumentID` | Resolve to instrument details once Dim_Instrument is documented |
| DWH_dbo.Fact_CurrencyPriceWithSplit | No direct FK -- used as ratio lookup in ETL | Provides split-adjusted price series |

### 3.4 Gotchas

- **Orphaned in analytics layer**: Consumer SPs (`SP_Fact_CurrencyPriceWithSplit`, `SP_Fact_CustomerUnrealized_PnL`) read split ratios from staging tables (`DWH_staging.etoro_History_SplitRatio`) and dedicated external tables, NOT from this Dim_ table. Use this table for analyst queries and Gold export only -- do not assume the ETL pipeline reads from it.
- **MaxDate=2100-01-01 means active**: This far-future sentinel indicates the currently applicable ratio. Filter `WHERE MaxDate = '2100-01-01'` to get current ratios per instrument.
- **MinDate=2000-01-01 means "since beginning"**: Any price data before the first recorded split uses the ratio in the row with this sentinel start date.
- **UpdateDate is ETL timestamp, not source timestamp**: The `UpdateDate` column is set to `GETDATE()` by the SP and reflects the last load time (2026-03-11 02:07), not a production-side modification date.
- **Most instruments have only 1 row** (no splits): `PriceRatio=1.0, AmountRatio=1.0` means no adjustment needed. Only instruments with stock splits have multiple rows.
- **Highly-split instruments**: Some instruments (e.g., InstrumentID 4459) have up to 15 split events in history.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 -- upstream wiki verbatim | `(Tier 1 -- upstream wiki, source)` |
| ★★★ | Tier 2 -- Synapse SP code | `(Tier 2 -- SP/DDL)` |
| ★★ | Tier 3 -- live data / DDL structure | `(Tier 3 -- live data)` |
| ★ | Tier 4 -- inferred [UNVERIFIED] | `[UNVERIFIED] (Tier 4 -- inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | int | NO | Sequential integer primary key for the split ratio record. Passed through from PriceLog.History.SplitRatio without transformation. (Tier 2 -- SP_Dim_HistorySplitRatio_DL_To_Synapse) |
| 2 | InstrumentID | int | NO | Instrument identifier (FK to DWH_dbo.Dim_Currency.CurrencyID and DWH_dbo.Dim_Instrument.InstrumentID). Groups all split ratio records for a single tradeable instrument. (Tier 2 -- SP_Dim_HistorySplitRatio_DL_To_Synapse) |
| 3 | MinDate | datetime | YES | Start of the date range (inclusive) for which the ratio applies. `2000-01-01` is the beginning-of-history sentinel for the earliest period before any splits. (Tier 3 -- live data, PriceLog.History.SplitRatio) |
| 4 | MaxDate | datetime | YES | End of the date range (exclusive) for which the ratio applies. `2100-01-01` is the open-ended sentinel indicating the currently active ratio (no further splits yet). (Tier 3 -- live data, PriceLog.History.SplitRatio) |
| 5 | PriceRatio | decimal(16,8) | NO | Cumulative price adjustment multiplier for this period. Multiply a historical price by this value to get its split-adjusted equivalent. 1.0 means no adjustment. Example: PriceRatio=0.25 means a 4:1 stock split occurred (1 old share = 4 new shares, price adjusted down to 25%). (Tier 3 -- live data, PriceLog.History.SplitRatio) |
| 6 | AmountRatio | decimal(16,8) | NO | Cumulative amount/quantity adjustment multiplier for this period. Multiply a historical position size by this value to get the split-adjusted share count. Inverse of PriceRatio: AmountRatio=4.0 corresponds to PriceRatio=0.25 (4:1 split). (Tier 3 -- live data, PriceLog.History.SplitRatio) |
| 7 | PriceRatioUnAdjusted | decimal(19,4) | NO | Incremental (non-cumulative) price ratio from the most recent split event only, before stacking with prior splits. Used to isolate the effect of a single split. 1.0 for the oldest period (before any splits). (Tier 3 -- live data, PriceLog.History.SplitRatio) |
| 8 | AmountRatioUnAdjusted | decimal(19,4) | NO | Incremental (non-cumulative) amount ratio from the most recent split event only. Inverse of PriceRatioUnAdjusted for the current split. 1.0 for the oldest period (before any splits). (Tier 3 -- live data, PriceLog.History.SplitRatio) |
| 9 | UpdateDate | datetime | NO | ETL load timestamp -- set to GETDATE() by SP_Dim_HistorySplitRatio_DL_To_Synapse at each reload. Not from the production source. Reflects when DWH was last refreshed, not when the split data changed. (Tier 2 -- SP_Dim_HistorySplitRatio_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ID | PriceLog.History.SplitRatio | ID | Passthrough |
| InstrumentID | PriceLog.History.SplitRatio | InstrumentID | Passthrough |
| MinDate | PriceLog.History.SplitRatio | MinDate | Passthrough |
| MaxDate | PriceLog.History.SplitRatio | MaxDate | Passthrough |
| PriceRatio | PriceLog.History.SplitRatio | PriceRatio | Passthrough |
| AmountRatio | PriceLog.History.SplitRatio | AmountRatio | Passthrough |
| PriceRatioUnAdjusted | PriceLog.History.SplitRatio | PriceRatioUnAdjusted | Passthrough |
| AmountRatioUnAdjusted | PriceLog.History.SplitRatio | AmountRatioUnAdjusted | Passthrough |
| UpdateDate | ETL-computed | -- | GETDATE() at load time |

No upstream wiki found for PriceLog.History.SplitRatio -- PriceLog is a standalone price server database (AZR-W-PRICEDB-2-Price) not covered in DB_Schema wiki.

### 5.2 ETL Pipeline

```
PriceLog.History.SplitRatio (AZR-W-PRICEDB-2-Price)
  -> Generic Pipeline (hourly, Override, Bronze/PriceLog/History/SplitRatio/)
  -> dealing.bronze_pricelog_history_splitratio (UC Bronze)
  -> DWH_staging.etoro_History_SplitRatio
  -> SP_Dim_HistorySplitRatio_DL_To_Synapse (TRUNCATE + INSERT, daily)
  -> DWH_dbo.Dim_HistorySplitRatio
  -> Gold/sql_dp_prod_we/DWH_dbo/Dim_HistorySplitRatio/ (daily export)
  -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio (UC Gold)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | PriceLog.History.SplitRatio | Price server split ratio table on AZR-W-PRICEDB-2-Price |
| Lake | Bronze/PriceLog/History/SplitRatio/ | Hourly Generic Pipeline export |
| Staging | DWH_staging.etoro_History_SplitRatio | Raw staging import |
| ETL | DWH_dbo.SP_Dim_HistorySplitRatio_DL_To_Synapse | TRUNCATE + full INSERT; UpdateDate = GETDATE() |
| Target | DWH_dbo.Dim_HistorySplitRatio | 15,899 rows, refreshed daily |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Currency | Universal instrument registry -- resolve InstrumentID to instrument name, symbol, type |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument dimension (to be documented in Batch 7) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_CurrencyPriceWithSplit | InstrumentID + date range | Uses Dim_HistorySplitRatio for split-adjusted price computation (via staging ext table path) |
| DWH_dbo.Fact_CustomerUnrealized_PnL | InstrumentID + date range | Uses split ratios for unrealized PnL calculation (via Ext_FCUPNL_History_SplitRatio) |
| dwh.gold_sql_dp_prod_we_dwh_dbo_dim_historysplitratio | -- | Gold UC export for downstream Databricks analytics |

---

## 7. Sample Queries

### 7.1 Get the active (current) split ratio for all instruments

```sql
SELECT
    InstrumentID,
    PriceRatio,
    AmountRatio,
    MinDate AS SplitActiveFrom
FROM [DWH_dbo].[Dim_HistorySplitRatio]
WHERE MaxDate = '2100-01-01'
ORDER BY InstrumentID;
```

### 7.2 Find the split ratio applicable on a specific date for an instrument

```sql
DECLARE @InstrumentID INT = 1001;
DECLARE @PriceDate DATE = '2015-01-01';

SELECT
    InstrumentID,
    MinDate,
    MaxDate,
    PriceRatio,
    AmountRatio,
    PriceRatioUnAdjusted,
    AmountRatioUnAdjusted
FROM [DWH_dbo].[Dim_HistorySplitRatio]
WHERE InstrumentID = @InstrumentID
  AND @PriceDate >= MinDate
  AND @PriceDate < MaxDate;
```

### 7.3 Find instruments with the most split events and resolve names

```sql
SELECT
    r.InstrumentID,
    c.[Name]            AS InstrumentName,
    COUNT(*)            AS SplitPeriods,
    MAX(r.MinDate)      AS MostRecentSplitDate
FROM [DWH_dbo].[Dim_HistorySplitRatio] r
JOIN [DWH_dbo].[Dim_Currency] c
    ON c.[CurrencyID] = r.[InstrumentID]
WHERE r.PriceRatio != 1.0   -- exclude no-split (identity) rows
GROUP BY r.InstrumentID, c.[Name]
ORDER BY SplitPeriods DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.2/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 3 T2, 6 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10*
*Object: DWH_dbo.Dim_HistorySplitRatio | Type: Table | Production Source: PriceLog.History.SplitRatio*


### Upstream `DWH_dbo.Dim_PositionChangeLog` — synapse
- **Resolved as**: `DWH_dbo.Dim_PositionChangeLog`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PositionChangeLog.md`

# DWH_dbo.Dim_PositionChangeLog

> Position lifecycle change audit log recording every event that modifies a position's amount, stop-loss rate, settlement status, or lot count -- enabling reconstruction of position state at any point in time.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.History.PositionChangeLog |
| **Refresh** | Daily (incremental via SP_Dim_PositionChangeLog_DL_To_Synapse @dt) |
| | |
| **Synapse Distribution** | HASH (PositionID) |
| **Synapse Index** | CLUSTERED INDEX (OccurredDateID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog` |
| **UC Format** | Delta |
| **UC Partitioned By** | OccurredDateID (daily or monthly range) |
| **UC Table Type** | Managed |

---

## 1. Business Meaning

Dim_PositionChangeLog is the audit trail for position state changes. Every time a position's amount, stop-loss rate, settlement flag, or lot count is modified after the initial open, a change log entry is created. This allows analysts to reconstruct the exact state of a position at any historical point in time.

Key use cases:
- **IsSettled tracking**: When a stock position transitions to "settled" status, the log records PreviousIsSettled vs IsSettled. The SP_Dim_Position_DL_To_Synapse ETL reads this table to backfill the correct IsSettled value on Dim_Position.
- **Amount corrections**: When a position's Amount or StopRate changes (e.g., partial close, margin call adjustment), the log records PreviousAmount and AmountChanged. The Dim_Position ETL uses ChangeTypeID=12 entries to apply cumulative amount corrections.
- **Initial open event**: ChangeTypeID=0 records the initial position open event -- used to detect the first appearance of a position in the changelog (primarily for hedge server tracking in SP_Dim_Position_DL_To_Synapse).

Data source is `etoro_History_PositionChangeLog` loaded daily via DELETE (yesterday+) then INSERT (from yesterday). As of 2025-01-05, ALL ChangeTypeIDs are loaded (previously restricted to IDs 1, 5, 11, 12, 13 only).

---

## 2. Business Logic

### 2.1 Change Types

**What**: Classification of what kind of position modification occurred.

**Columns Involved**: `ChangeTypeID`

**Rules**:
- ChangeTypeID=0: Initial open event (position first appears in changelog). Used to find OpenDateID for new positions entering the hedge server snapshot.
- ChangeTypeID=1: Rate/SL-TP change (StopRate or LimitRate modification).
- ChangeTypeID=2: Unspecified change -- seen in live data (requires domain expert clarification).
- ChangeTypeID=5: Added 2024-04-30 -- purpose requires clarification.
- ChangeTypeID=11: Partial close related event.
- ChangeTypeID=12: Amount adjustment -- summed cumulatively to correct Dim_Position.Amount for same-day modifications.
- ChangeTypeID=13: Purpose requires clarification.
- Before 2025-01-05: Only IDs 1, 5, 11, 12, 13 were loaded. ChangeTypeID=0, 2, and others were excluded. Historical rows for these types before 2025-01-05 may be absent.

**Note**: No upstream wiki exists enumerating the official ChangeTypeID names. Values above are inferred from SP code. All should be treated as Tier 4 [UNVERIFIED] until confirmed by domain expert.

### 2.2 State Tracking (Before/After Columns)

**What**: Each row captures the before and after state for the changed metric.

**Columns Involved**: `PreviousAmount`, `AmountChanged`, `NewAmount`, `PreviousStopRate`, `StopRate`, `PreviousIsSettled`, `IsSettled`, `PreviousAmountInUnits`, `AmountInUnits`, `PreviousLotCountDecimal`, `LotCountDecimal`

**Rules**:
- Each change captures the previous value, the delta (AmountChanged), and the new value.
- `AmountChanged` = NewAmount - PreviousAmount (can be negative for reductions).
- Multiple rows can exist per PositionID on the same day (same OccurredDateID) -- particularly for ChangeTypeID=12 (amount adjustments), which are summed via SUM(AmountChanged) GROUP BY PositionID in the Dim_Position ETL.
- `PreviousIsSettled` / `IsSettled` are cast to int (0/1) from bit in staging. NULL is possible if the event didn't involve a settlement change.
- The **most recent** changelog event for a PositionID at ChangeTypeID=0 (ROW_NUMBER by Occurred ASC, rn=1) is used in the Dim_Position ETL to correct IsSettled for open positions.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**HASH (PositionID)**: Co-located with Dim_Position for efficient JOINs on PositionID. Date-range queries should also include OccurredDateID.

**CLUSTERED INDEX (OccurredDateID)**: Efficient for date-range scans on when changes occurred. Always include an OccurredDateID range filter.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog`. Always filter on OccurredDateID for partition pruning.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All changes for a specific position | WHERE PositionID = X ORDER BY Occurred |
| Settlement changes on a date | WHERE OccurredDateID = YYYYMMDD AND PreviousIsSettled IS NOT NULL |
| Amount-adjusted positions | WHERE ChangeTypeID = 12 AND OccurredDateID = YYYYMMDD |
| Initial open events | WHERE ChangeTypeID = 0 AND OccurredDateID = YYYYMMDD |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Position | ON PositionID | Enrich position with change history |
| DWH_dbo.Dim_Customer | ON CID | Customer-level change analysis |

### 3.4 Gotchas

- **Multiple rows per position per day**: A position can have many changelog entries on the same day. Do NOT assume one row per (PositionID, OccurredDateID).
- **Historical completeness gap**: Before 2025-01-05, only ChangeTypeIDs 1, 5, 11, 12, 13 were loaded. Earlier history for ChangeTypeIDs 0, 2, etc. is missing.
- **ChangeTypeID values are undocumented**: No official lookup table for ChangeTypeID exists in DWH. The meanings above are inferred from SP code patterns.
- **AmountChanged may be 0**: Seen in live data -- a row with AmountChanged=0 may represent a rate-only change (StopRate update) with no amount modification.
- **PreviousIsSettled can be NULL**: If the change event didn't involve settlement status, both IsSettled and PreviousIsSettled may be NULL.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| * | Tier 4 - Inferred from name/code | (Tier 4 - [UNVERIFIED]) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | bigint | NO | FK to Dim_Position.PositionID. Distribution key -- co-located with Dim_Position for efficient JOINs. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 2 | CID | int | YES | Customer ID who owns the position. Nullable (some system positions may not have CID). (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 3 | Occurred | datetime | NO | Exact timestamp when the position change occurred. Passthrough from etoro_History_PositionChangeLog. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 4 | OccurredDateID | int | YES | ETL-computed YYYYMMDD int from Occurred. Clustered index key. Always filter on this for performance. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 5 | ChangeTypeID | tinyint | YES | Type of change event. Known codes: 0=Initial open, 1=Rate change, 2=Unknown, 5=Unknown (added 2024), 11=Partial close event, 12=Amount adjustment, 13=Unknown. No official lookup table in DWH. (Tier 4 - [UNVERIFIED]) |
| 6 | PreviousAmount | money | NO | Position amount (USD) before this change. NOT NULL -- always captured. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 7 | AmountChanged | money | NO | Change in amount (can be positive or negative). AmountChanged = NewAmount - PreviousAmount. NOT NULL. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 8 | NewAmount | numeric(16,8) | YES | Position amount after this change. Nullable -- may be absent for non-amount change types. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 9 | PreviousIsSettled | int | YES | Before the change: 1 = real asset, 0 = CFD asset. Cast from bit in staging. NULL if this event did not involve a settlement change. (Tier 5 — Expert Review) |
| 10 | IsSettled | int | YES | After the change: 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 11 | PreviousStopRate | numeric(16,8) | NO | Stop-loss rate before this change. NOT NULL. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 12 | StopRate | numeric(16,8) | NO | Stop-loss rate after this change. NOT NULL. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 13 | PreviousAmountInUnits | numeric(16,6) | YES | Unit count (shares/coins) before this change. Added for futures/unit-based positions. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 14 | AmountInUnits | numeric(16,6) | YES | Unit count after this change. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 15 | LotCountDecimal | decimal(38,18) | YES | New lot count after change. Added 2024-11-07 (Inbal BML) for futures project. NULL for older records. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 16 | PreviousLotCountDecimal | decimal(38,18) | YES | Lot count before this change. Added 2024-11-07. NULL for older records. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 17 | UpdateDate | datetime | NO | ETL load timestamp (GETDATE()). Not from production source. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Table | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| PositionID | etoro_History_PositionChangeLog | PositionID | passthrough |
| CID | etoro_History_PositionChangeLog | CID | passthrough |
| Occurred | etoro_History_PositionChangeLog | Occurred | passthrough |
| OccurredDateID | -- | Occurred | ETL-computed: CAST(CONVERT(VARCHAR(8), Occurred, 112) AS INT) |
| ChangeTypeID | etoro_History_PositionChangeLog | ChangeTypeID | passthrough |
| PreviousAmount | etoro_History_PositionChangeLog | PreviousAmount | passthrough |
| AmountChanged | etoro_History_PositionChangeLog | AmountChanged | passthrough |
| NewAmount | etoro_History_PositionChangeLog | NewAmount | passthrough |
| PreviousIsSettled | etoro_History_PositionChangeLog | PreviousIsSettled | ETL: CAST(PreviousIsSettled AS INT) |
| IsSettled | etoro_History_PositionChangeLog | IsSettled | ETL: CAST(IsSettled AS INT) |
| PreviousStopRate | etoro_History_PositionChangeLog | PreviousStopRate | passthrough |
| StopRate | etoro_History_PositionChangeLog | StopRate | passthrough |
| PreviousAmountInUnits | etoro_History_PositionChangeLog | PreviousAmountInUnits | passthrough |
| AmountInUnits | etoro_History_PositionChangeLog | AmountInUnits | passthrough |
| LotCountDecimal | etoro_History_PositionChangeLog | LotCountDecimal | passthrough |
| PreviousLotCountDecimal | etoro_History_PositionChangeLog | PreviousLotCountDecimal | passthrough |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.History.PositionChangeLog
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/History/PositionChangeLog/
  -> DWH_staging.etoro_History_PositionChangeLog
  -> SP_Dim_PositionChangeLog_DL_To_Synapse (DELETE yesterday+ then INSERT)
  -> DWH_dbo.Dim_PositionChangeLog
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.History.PositionChangeLog | Production position change audit (etoroDB-REAL) |
| Lake | Bronze/etoro/History/PositionChangeLog/ | Daily full-load via Generic Pipeline |
| Staging | DWH_staging.etoro_History_PositionChangeLog | Raw staging import |
| ETL Step 1 | SP_Dim_PositionChangeLog_DL_To_Synapse | DELETE FROM Dim_PositionChangeLog WHERE OccurredDateID >= @YesterdayID |
| ETL Step 2 | SP_Dim_PositionChangeLog_DL_To_Synapse | INSERT from staging WHERE Occurred >= @Yesterday (all ChangeTypeIDs as of 2025-01-05) |
| Target | DWH_dbo.Dim_PositionChangeLog | 17 cols, HASH(PositionID) + CCI on OccurredDateID |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Target Object | Join Column | Description |
|--------------|-------------|-------------|
| DWH_dbo.Dim_Position | PositionID | The position this log entry belongs to |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.SP_Dim_Position_DL_To_Synapse | PositionID | Reads IsSettled corrections and Amount adjustments to apply to Dim_Position |
| DWH_dbo.SP_Dim_Position_PositionHedgeServerChangeLog | PositionID | Reads initial open events (ChangeTypeID=0) for hedge server snapshot initialization |

---

## 7. Sample Queries

### 7.1 All changes for a specific position

```sql
SELECT  PositionID, Occurred, ChangeTypeID,
        PreviousAmount, AmountChanged, NewAmount,
        PreviousIsSettled, IsSettled,
        PreviousStopRate, StopRate
FROM    [DWH_dbo].[Dim_PositionChangeLog]
WHERE   PositionID = 3358743021
  AND   OccurredDateID BETWEEN 20260101 AND 20260310
ORDER BY Occurred;
```

### 7.2 Settlement status changes on a specific date

```sql
SELECT  PositionID, CID, Occurred, PreviousIsSettled, IsSettled
FROM    [DWH_dbo].[Dim_PositionChangeLog]
WHERE   OccurredDateID = 20260310
  AND   PreviousIsSettled IS NOT NULL
  AND   PreviousIsSettled <> IsSettled
ORDER BY Occurred;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.5/10 (***) | Phases: 14/14 (full pipeline)*
*Tiers: 0 T1, 16 T2, 0 T3, 1 T4 [UNVERIFIED] (ChangeTypeID mapping), 0 T5 | Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10*
*Object: DWH_dbo.Dim_PositionChangeLog | Type: Table | Production Source: etoro.History.PositionChangeLog*


### Upstream `DWH_dbo.Fact_SnapshotCustomer` — synapse
- **Resolved as**: `DWH_dbo.Fact_SnapshotCustomer`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_SnapshotCustomer.md`

# DWH_dbo.Fact_SnapshotCustomer

> Daily SCD Type 2 snapshot of every eToro customer's current state — the central customer-attribute table powering regulatory reporting, risk, and analytics.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source: Ext_FSC_Real_Customer_Customer (CC), Ext_FSC_BackOffice_Customer (BO), Ext_FSC_BackOffice_RegulationChangeLog, Ext_FSC_Customer_FirstTimeDeposits, Ext_FSC_PhoneCustomer, Ext_FSC_StocksLending, Ext_Dim_Customer_CustomerIdentification_DLT |
| **Refresh** | Daily via MERGE (SP_Fact_SnapshotCustomer), orchestrated by SP_Fact_SnapshotCustomer_DL_To_Synapse |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX + NCI(RealCID ASC) |
| | |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` (masked; matches `_generic_pipeline_mapping.json` generic_id=1115, `business_group` DWH). Unmasked PII export: `main.pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid`. |
| **UC Format** | delta |
| **UC Partitioned By** | N/A (view is unpartitioned) |
| **UC Table Type** | Two UC targets: `pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid` (unmasked) + `dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` (masked) |

---

## 1. Business Meaning

Fact_SnapshotCustomer is the central customer state table in the DWH. For every eToro customer (RealCID), it holds one row per distinct attribute state within a year, recording which attributes were active between FromDate and ToDate (encoded together in `DateRangeID`). The pattern is SCD Type 2 by year: each year's rows are closed as attribute changes occur, and a new open row is created with the updated state. At year-end, all open rows are closed and reopened with the new year's date range.

As of 2026-03-19: **406M+ total rows**, **46.4M distinct customers**, data from **2007-08-22 to present**. 302M rows are "currently open" (ToDate = year-end). 11.9% of current open rows represent depositors; 98.0% are valid customers (IsValidCustomer=1).

The SP loads data from 6 source systems via staging Ext_FSC tables pre-populated by SP_Fact_SnapshotCustomer_DL_To_Synapse. The core CC (Customer Core) source provides demographics and status; the BO (Back Office) source provides risk/compliance attributes. RegulationID is taken from RegulationChangeLog — **not** from Back Office — because regulation changes take effect end-of-day.

8 legacy columns (DemoCID, CustomerChangeTypeID, CurentValue, PreviousValue, DocsOK, Bankruptcy, PremiumAccount, Evangelist) are present in the DDL but NOT populated by the current SP. They carry DEFAULT (0) values.

---

## 2. Business Logic

### 2.1 SCD Type 2 Pattern — DateRangeID

**What**: Each customer-state row has a DateRangeID encoding both the open date (FromDate) and close date (ToDate) as a 12-digit bigint.

**Columns Involved**: `DateRangeID`, `RealCID`

**Rules**:
- DateRangeID = `YYYYMMDD` (open date, 8 chars) + `MMDDD` (year-end month+day, 4 chars) → e.g., `202603101231` = opened 2026-03-10, closes 2026-12-31
- When an attribute changes, the SP updates DateRangeID of the existing row to close it (right 4 chars become yesterday's MMDD), then inserts a new row with today's open date + year-end
- To get the **most current row** per customer: `RIGHT(CAST(DateRangeID AS VARCHAR(12)), 4) = '1231'`
- On January 1st: all prior year's open rows are closed (12-31) and re-opened for the new year
- The `Dim_Range` dimension table stores FromDateID + ToDateID for each DateRangeID

### 2.2 IsValidCustomer — Segment Flag

**What**: Computed flag indicating whether a customer is a "valid" retail customer for analytics (excludes demo, blocked countries, excluded labels).

**Columns Involved**: `IsValidCustomer`, `PlayerLevelID`, `LabelID`, `CountryID`

**Rules** (as of post-2020-03-14):
```
IsValidCustomer = 1 IF:
  PlayerLevelID <> 4 (not demo)
  AND LabelID NOT IN (30, 26) (not internal/excluded label)
  AND CountryID <> 250 (not blocked country)
ELSE 0
```
Pre-2020-03-14 rule additionally excluded AccountTypeID=9.

### 2.3 IsCreditReportValidCB — Credit Reporting Flag

**What**: Flag indicating whether a customer is eligible for credit report validation (CB = CreditBureau context).

**Columns Involved**: `IsCreditReportValidCB`, `PlayerLevelID`, `AccountTypeID`, `LabelID`, `CountryID`

**Rules** (as of post-2020-03-14):
```
IsCreditReportValidCB = 1 IF:
  NOT (PlayerLevelID = 4 AND AccountTypeID <> 2)  (not non-real demo)
  AND LabelID NOT IN (26, 30)
  AND NOT (CountryID = 250 AND CID NOT IN (3400616, 10526243))
ELSE 0
```

### 2.4 RegulationID — End-of-Day Rule

**What**: A customer's regulatory jurisdiction is taken from RegulationChangeLog (end-of-day change), NOT from the back-office system (immediate change), because regulation changes take effect at end of day for business/legal reasons.

**Columns Involved**: `RegulationID`, sourced from `Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID`

### 2.5 GDPR Erasure Masking

**What**: When a GDPR deletion request is processed, the UserName in Customer Core gets a `DelUserName` prefix. The SP detects this and masks Email, City, Address, Zip, and PhoneNumber in Fact_SnapshotCustomer.

**Columns Involved**: `Email`, `City`, `Address`, `Zip`, `PhoneNumber`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(RealCID) distribution + CCI makes per-customer aggregations and filters on RealCID highly efficient — queries that filter or join on RealCID benefit from colocation. The NCI on RealCID provides efficient point-lookup for single customers.

**Warning**: With 406M rows, full table scans are expensive. Always filter by DateRangeID or a specific year range when possible.

### 3.1b UC (Databricks) Storage

**In Databricks**, the data is accessed via `V_Fact_SnapshotCustomer_FromDateID` (generic_id=1115), not directly. Two UC targets:
- `pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid` — full PII (gated access)
- `dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` — Email/City/Address/Zip masked

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current state for all customers | `WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231'` |
| Current state for one customer | `WHERE RealCID = @cid AND RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231'` |
| Customer state on a specific date | `WHERE RealCID = @cid AND LEFT(CAST(DateRangeID AS VARCHAR(12)),8) <= @date AND RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) >= RIGHT(@date, 4)` |
| Count of depositors | `WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231' AND IsDepositor = 1` |
| Valid retail customers | `WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231' AND IsValidCustomer = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | ON f.CountryID = dc.CountryID | Country name/region |
| DWH_dbo.Dim_Label | ON f.LabelID = dl.LabelID | Brand/label name |
| DWH_dbo.Dim_Language | ON f.LanguageID = dl.LanguageID | Customer language |
| DWH_dbo.Dim_VerificationLevel | ON f.VerificationLevelID = dv.VerificationLevelID | KYC verification status |
| DWH_dbo.Dim_PlayerStatus | ON f.PlayerStatusID = dp.PlayerStatusID | Account lifecycle status |
| DWH_dbo.Dim_Regulation | ON f.RegulationID = dr.RegulationID | Regulatory jurisdiction |
| DWH_dbo.Dim_AccountStatus | ON f.AccountStatusID = das.AccountStatusID | Account enabled/disabled |
| DWH_dbo.Dim_Range | ON f.DateRangeID = dr.DateRangeID | Decode FromDateID + ToDateID |
| DWH_dbo.Fact_Guru_Copiers | ON f.RealCID = fg.RealCID | Copy-trading activity |

### 3.4 Gotchas

- **DateRangeID is NOT a date** — it is a 12-digit bigint encoding (FromDate)(ToDate MMDD). Always extract with LEFT(...,8) for FromDate and RIGHT(...,4) for ToDate MMDD.
- **Most-current-row filter**: `RIGHT(CAST(DateRangeID AS VARCHAR(12)),4) = '1231'` gets the currently open row, but after year-end closure this may temporarily return 0 rows. Use `MAX(DateRangeID)` per RealCID as a safer alternative.
- **Legacy columns with 0 defaults**: DemoCID, CustomerChangeTypeID, CurentValue, PreviousValue, DocsOK, Bankruptcy, PremiumAccount, Evangelist are all DEFAULT 0 and NOT populated by the current SP. Do not rely on them.
- **PII masking**: Email, City, Address, Zip are dynamically masked (`MASKED WITH (FUNCTION = 'default()')`). Users without `UNMASK` permission see NULL. PhoneNumber is NOT masked at DDL level but is GDPR-erased via the SP for deleted users.
- **WeekendFeePrecentage** (note: typo in column name — "Precentage" instead of "Percentage") — use as-is.
- **AccountStatusID distribution**: 1=93.2% (Active), 0=6.1% (unknown/default), 2=0.9% (Inactive). Only 3 distinct values observed.
- **Not exported directly to UC** — join via `V_Fact_SnapshotCustomer_FromDateID` in UC.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Notes |
|-------|------|-----|-------|
| ★★★★★ | Tier 5 | `(Tier 5 - domain expert)` | Expert-confirmed |
| ★★★★☆ | Tier 1 | `(Tier 1 - upstream wiki, source)` | Upstream wiki verbatim |
| ★★★☆☆ | Tier 2 | `(Tier 2 - SP code / DDL)` | From SSDT SP or DDL analysis |
| ★★☆☆☆ | Tier 3 | `(Tier 3 - live data / DDL structure)` | From sampling or DDL |
| ★☆☆☆☆ | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Inferred, needs expert review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | NO | Global Customer ID — the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 2 | RealCID | int | YES | Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 3 | DemoCID | int | YES | [UNVERIFIED] Demo account customer ID linked to this real customer. NOT populated by current SP_Fact_SnapshotCustomer — legacy column from original SCD2 design. Value is DEFAULT NULL/0 for all rows created post-schema-migration. (Tier 4 - inferred from DDL) |
| 4 | CustomerChangeTypeID | tinyint | YES | [UNVERIFIED] Legacy: type of change that created this snapshot row (e.g., 1=Insert, 2=Update). NOT populated by current SP — retained for backward compatibility. FK to Dim_CustomerChangeType. (Tier 4 - inferred from DDL) |
| 5 | CurentValue | int | YES | [UNVERIFIED] Legacy: the current value of the changed attribute (used with CustomerChangeTypeID). NOT populated by current SP. Column name has a typo ("Curent"). (Tier 4 - inferred from DDL) |
| 6 | PreviousValue | int | YES | [UNVERIFIED] Legacy: the previous value of the changed attribute. NOT populated by current SP. (Tier 4 - inferred from DDL) |
| 7 | CountryID | int | YES | Customer's registered country. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CountryID (CC). FK to Dim_Country. Key filter for valid customer segmentation (CountryID=250 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 8 | LabelID | int | YES | Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LabelID (CC). FK to Dim_Label. Labels 26 and 30 excluded from valid customer segment. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 9 | LanguageID | int | YES | Customer's preferred interface language. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.LanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 10 | VerificationLevelID | int | YES | KYC (Know Your Customer) verification level. DEFAULT -1. Source: Ext_FSC_BackOffice_Customer.VerificationLevelID (BO). FK to Dim_VerificationLevel. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 11 | DocsOK | smallint | YES | [UNVERIFIED] Legacy: documents verified flag (1=OK). NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 12 | PlayerStatusID | int | YES | Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusID (CC). FK to Dim_PlayerStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 13 | Bankruptcy | smallint | YES | [UNVERIFIED] Legacy: bankruptcy flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 14 | RiskStatusID | int | YES | Customer risk assessment status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskStatusID (BO). FK to Dim_RiskStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 15 | RiskClassificationID | int | YES | Risk classification tier for compliance. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.RiskClassificationID (BO). FK to Dim_RiskClassification. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 16 | CommunicationLanguageID | int | YES | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 17 | PremiumAccount | smallint | YES | [UNVERIFIED] Legacy: premium account flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 18 | Evangelist | smallint | YES | [UNVERIFIED] Legacy: evangelist/ambassador status flag. NOT populated by current SP. DEFAULT 0. (Tier 4 - inferred from DDL) |
| 19 | GuruStatusID | smallint | YES | Popular Investor (Guru) program status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.GuruStatusID (BO). FK to Dim_GuruStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 20 | UpdateDate | datetime | YES | DWH load timestamp. Set to GETDATE() at ETL execution. Not the customer event date. DEFAULT 0 (DDL default is 0 but SP sets GETDATE()). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 21 | RegulationID | tinyint | YES | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 22 | AccountStatusID | int | YES | Account enabled/suspended status. DEFAULT 0. Distribution: 1=93.2% (Active), 0=6.1%, 2=0.9% (Inactive). Source: Ext_FSC_Real_Customer_Customer.AccountStatusID (CC). FK to Dim_AccountStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 23 | AccountManagerID | int | YES | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 24 | PlayerLevelID | int | YES | Account tier: 4=demo, other values=real tiers. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerLevelID (CC). FK to Dim_PlayerLevel. Critical for IsValidCustomer (PlayerLevelID=4 excluded). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 25 | AccountTypeID | int | YES | Account type (e.g., 7=Employee, 9=excluded type, 2=real account). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountTypeID (BO). FK to Dim_AccountType. Used in IsCreditReportValidCB logic. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 26 | DateRangeID | bigint | YES | SCD2 range key: 12-digit bigint = YYYYMMDD (row open date) + MMDDD (year-end MMDD, typically 1231). E.g., 202603101231 = open 2026-03-10, closes 2026-12-31. Join to Dim_Range for FromDateID + ToDateID. See §2.1. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 27 | IsDepositor | bit | YES | 1 if the customer has made at least one real-money deposit (FTD detected). Set when CID appears in Ext_FSC_Customer_FirstTimeDeposits. Never reverted to 0 once set. DEFAULT 0. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 28 | PendingClosureStatusID | tinyint | YES | Status of a pending account closure request. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PendingClosureStatusID (CC). FK to Dim_PendingClosureStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 29 | DocumentStatusID | int | YES | KYC document review status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DocumentStatusID (BO). FK to Dim_DocumentStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 30 | SuitabilityTestStatusID | int | YES | MiFID suitability test completion status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.SuitabilityTestStatusID (BO). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 31 | MifidCategorizationID | int | YES | MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 32 | IsEmailVerified | int | YES | 1 if the customer has verified their email address. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.IsEmailVerified (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 33 | IsValidCustomer | int | YES | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. See §2.2. Approx 98% of current rows = 1. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 34 | DesignatedRegulationID | int | YES | Secondary/designated regulatory jurisdiction (separate from primary RegulationID). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.DesignatedRegulationID (BO). FK to Dim_Regulation. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 35 | EvMatchStatus | int | YES | eVerify (identity verification) match status. DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.EvMatchStatus (BO). FK to Dim_EvMatchStatus. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 36 | RegionID | int | YES | Customer's geographic region (sub-country grouping). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.RegionID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 37 | PlayerStatusReasonID | int | YES | Reason code for the current PlayerStatusID (e.g., why account was blocked). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusReasonID (CC). FK to Dim_PlayerStatusReasons. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 38 | IsCreditReportValidCB | int | YES | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed. See §2.3. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 39 | AffiliateID | int | YES | Affiliate/partner who referred this customer. DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.AffiliateID (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 40 | Email | nvarchar(50) | YES | Customer email address. PII: dynamically masked at DDL level (MASKED WITH default()). GDPR: set to masked value when UserName='DelUserName*'. Source: Ext_FSC_Real_Customer_Customer.Email (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 41 | City | nvarchar(50) | YES | Customer city. PII: dynamically masked at DDL level. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.City (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 42 | Address | nvarchar(100) | YES | Customer street address. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Address (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 43 | Zip | nvarchar(50) | YES | Customer postal code. PII: dynamically masked. GDPR erasure supported. Source: Ext_FSC_Real_Customer_Customer.Zip (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 44 | PhoneNumber | varchar(30) | YES | Customer phone number. PII: not DDL-masked but GDPR-erased to 'DelPhoneNumber_XXXXXXX' for deleted users. Source: Ext_FSC_PhoneCustomer.PhoneNumber. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 45 | IsPhoneVerified | bit | YES | 1 if the customer's phone number has been verified (PhoneVerifiedID IN (1,2) in source). Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 46 | PhoneVerificationDateID | varchar(8) | YES | Date the phone was verified, as YYYYMMDD string. Rows where PhoneVerificationDateID='19000101' are excluded from source. Source: Ext_FSC_PhoneCustomer. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 47 | PlayerStatusSubReasonID | int | YES | Sub-reason code for PlayerStatus (more granular than PlayerStatusReasonID). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.PlayerStatusSubReasonID (CC). FK to Dim_PlayerStatusSubReasons. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 48 | WeekendFeePrecentage | int | YES | Weekend overnight fee percentage applied to this customer. Note: column name typo ("Precentage"). Source: Ext_FSC_Real_Customer_Customer.WeekendFeePrecentage (CC). (Tier 2 - SP_Fact_SnapshotCustomer) |
| 49 | DltStatusID | int | YES | DLT (Digital Ledger/Tangany) wallet status ID. DEFAULT 0. Source: UserApiDB_Customer_CustomerIdentification via Ext_Dim_Customer_CustomerIdentification_DLT. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 50 | DltID | nvarchar(100) | YES | DLT wallet identifier (Tangany ID). NULL if no DLT wallet. Source: UserApiDB_Customer_CustomerIdentification via Ext_Dim_Customer_CustomerIdentification_DLT. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 51 | EquiLendID | varchar(4000) | YES | EquiLend securities lending platform identifier. NULL if not enrolled in stocks lending. Source: ComplianceStateDB_Compliance_StocksLending via Ext_FSC_StocksLending. (Tier 2 - SP_Fact_SnapshotCustomer) |
| 52 | StocksLendingStatusID | int | YES | Status of the customer's stocks lending enrollment. NULL if not enrolled. Source: ComplianceStateDB_Compliance_StocksLending via Ext_FSC_StocksLending. (Tier 2 - SP_Fact_SnapshotCustomer) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source System | Source Object | Source Column | Transform |
|---------------|--------------|---------------|---------------|-----------|
| RealCID | Customer Core (CC) | Ext_FSC_Real_Customer_Customer | CID | Passthrough |
| GCID | CC / DLT | Ext_FSC_Real_Customer_Customer / Ext_Dim_Customer_CustomerIdentification_DLT | GCID | COALESCE(CC.GCID, FSC.GCID, DLT.GCID, 0) |
| CountryID | CC | Ext_FSC_Real_Customer_Customer | CountryID | COALESCE(CC, FSC, 0) |
| LabelID | CC | Ext_FSC_Real_Customer_Customer | LabelID | COALESCE(CC, FSC, 0) |
| LanguageID | CC | Ext_FSC_Real_Customer_Customer | LanguageID | COALESCE(CC, FSC, 0) |
| PlayerStatusID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusID | COALESCE(CC, FSC, 0) |
| CommunicationLanguageID | CC | Ext_FSC_Real_Customer_Customer | CommunicationLanguageID | COALESCE(CC, FSC, 0) |
| AccountStatusID | CC | Ext_FSC_Real_Customer_Customer | AccountStatusID | COALESCE(CC, FSC, 0) |
| PlayerLevelID | CC | Ext_FSC_Real_Customer_Customer | PlayerLevelID | COALESCE(CC, FSC, 0) |
| IsEmailVerified | CC | Ext_FSC_Real_Customer_Customer | IsEmailVerified | COALESCE(CC, FSC, 0) |
| PendingClosureStatusID | CC | Ext_FSC_Real_Customer_Customer | PendingClosureStatusID | COALESCE(CC, FSC, 0) |
| RegionID | CC | Ext_FSC_Real_Customer_Customer | RegionID | COALESCE(CC, FSC, 0) |
| PlayerStatusReasonID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusReasonID | COALESCE(CC, FSC, 0) |
| PlayerStatusSubReasonID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusSubReasonID | COALESCE(CC, FSC, 0) |
| WeekendFeePrecentage | CC | Ext_FSC_Real_Customer_Customer | WeekendFeePrecentage | COALESCE(CC, FSC) |
| AffiliateID | CC | Ext_FSC_Real_Customer_Customer | AffiliateID | COALESCE(CC, FSC, 0) |
| Email | CC | Ext_FSC_Real_Customer_Customer | Email | COALESCE(CC, FSC, '') + GDPR masking |
| City | CC | Ext_FSC_Real_Customer_Customer | City | COALESCE(CC, FSC, '') + GDPR masking |
| Address | CC | Ext_FSC_Real_Customer_Customer | Address | COALESCE(CC, FSC, '') + GDPR masking |
| Zip | CC | Ext_FSC_Real_Customer_Customer | Zip | COALESCE(CC, FSC, '') + GDPR masking |
| VerificationLevelID | Back Office (BO) | Ext_FSC_BackOffice_Customer | VerificationLevelID | COALESCE(BO, FSC, 0) |
| RiskStatusID | BO | Ext_FSC_BackOffice_Customer | RiskStatusID | COALESCE(BO, FSC, 0) |
| RiskClassificationID | BO | Ext_FSC_BackOffice_Customer | RiskClassificationID | COALESCE(BO, FSC, 0) |
| GuruStatusID | BO | Ext_FSC_BackOffice_Customer | GuruStatusID | COALESCE(BO, FSC, 0) |
| AccountTypeID | BO | Ext_FSC_BackOffice_Customer | AccountTypeID | COALESCE(BO, FSC, 0) |
| AccountManagerID | BO | Ext_FSC_BackOffice_Customer | AccountManagerID | COALESCE(BO, FSC, 0) |
| DocumentStatusID | BO | Ext_FSC_BackOffice_Customer | DocumentStatusID | COALESCE(BO, FSC, 0) |
| SuitabilityTestStatusID | BO | Ext_FSC_BackOffice_Customer | SuitabilityTestStatusID | COALESCE(BO, FSC, 0) |
| MifidCategorizationID | BO | Ext_FSC_BackOffice_Customer | MifidCategorizationID | COALESCE(BO, FSC, 0) |
| DesignatedRegulationID | BO | Ext_FSC_BackOffice_Customer | DesignatedRegulationID | COALESCE(BO, FSC, 0) |
| EvMatchStatus | BO | Ext_FSC_BackOffice_Customer | EvMatchStatus | COALESCE(BO, FSC, 0) |
| RegulationID | Regulation | Ext_FSC_BackOffice_RegulationChangeLog | ToRegulationID | COALESCE(RegChange, FSC.RegulationID, BO.RegulationID, 0) — end-of-day |
| IsDepositor | FTD | Ext_FSC_Customer_FirstTimeDeposits | CID | 1 if CID exists in FTD table |
| PhoneNumber | Phone | Ext_FSC_PhoneCustomer | PhoneNumber | COALESCE(Phone, FSC, '') |
| IsPhoneVerified | Phone | Ext_FSC_PhoneCustomer | PhoneVerifiedID | CASE WHEN PhoneVerifiedID IN (1,2) THEN 1 ELSE 0 |
| PhoneVerificationDateID | Phone | Ext_FSC_PhoneCustomer | PhoneVerificationDateID | COALESCE(Phone, FSC, ''); exclude 19000101 |
| DltStatusID | DLT/Tangany | UserApiDB_Customer_CustomerIdentification | DltStatusID | via Ext_Dim_Customer_CustomerIdentification_DLT |
| DltID | DLT/Tangany | UserApiDB_Customer_CustomerIdentification | DltID | via Ext_Dim_Customer_CustomerIdentification_DLT |
| EquiLendID | StocksLending | ComplianceStateDB_Compliance_StocksLending | EquiLendID | via Ext_FSC_StocksLending |
| StocksLendingStatusID | StocksLending | ComplianceStateDB_Compliance_StocksLending | StocksLendingStatusID | via Ext_FSC_StocksLending |
| DateRangeID | ETL-computed | N/A | @date + year-end | convert(bigint, convert(varchar,@date,112) + right(convert(varchar,@largedate,112),4)) |
| IsValidCustomer | ETL-computed | N/A | N/A | CASE on PlayerLevelID, LabelID, CountryID |
| IsCreditReportValidCB | ETL-computed | N/A | N/A | CASE on PlayerLevelID, AccountTypeID, LabelID, CountryID |
| UpdateDate | ETL-computed | N/A | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
Customer Core (CC) → etoro_History_Customer_Customer (CDC)
  → Ext_FSC_Real_Customer_Customer

Back Office (BO) → etoro_History_BackOfficeCustomer (CDC)
  → Ext_FSC_BackOffice_Customer
  → Ext_FSC_BackOffice_RegulationChangeLog

FTD System → CustomerFinanceDB_Customer_FirstTimeDeposits
  → Ext_FSC_Customer_FirstTimeDeposits

Phone Verification → ContactVerification_Phone_Customer
  → Ext_FSC_PhoneCustomer

DLT/Tangany → UserApiDB_Customer_CustomerIdentification
  → Ext_Dim_Customer_CustomerIdentification_DLT

Stocks Lending → ComplianceStateDB_Compliance_StocksLending
  → Ext_FSC_StocksLending

[All above via SP_Fact_SnapshotCustomer_DL_To_Synapse]
  → SP_Fact_SnapshotCustomer(@dt) [MERGE + DateRange update]
  → DWH_dbo.Fact_SnapshotCustomer
```

| Step | Object | Description |
|------|--------|-------------|
| Source Load | SP_Fact_SnapshotCustomer_DL_To_Synapse | Loads 6 Ext_FSC staging tables from DL, then calls inner SP |
| ETL | SP_Fact_SnapshotCustomer (Author: Boris Slutski, 2018-03-11) | MERGE: close existing rows + INSERT new rows + Dim_Range update |
| Target | DWH_dbo.Fact_SnapshotCustomer | DWH customer snapshot table |
| UC Export | V_Fact_SnapshotCustomer_FromDateID (generic_id=1115) | Daily Merge to UC (two targets: PII + masked) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | Country name/region |
| LabelID | DWH_dbo.Dim_Label | Brand/label name |
| LanguageID | DWH_dbo.Dim_Language | Language name |
| VerificationLevelID | DWH_dbo.Dim_VerificationLevel | KYC tier |
| PlayerStatusID | DWH_dbo.Dim_PlayerStatus | Account lifecycle status |
| PlayerLevelID | DWH_dbo.Dim_PlayerLevel | Real vs demo tier |
| RiskStatusID | DWH_dbo.Dim_RiskStatus | Risk status |
| RiskClassificationID | DWH_dbo.Dim_RiskClassification | Risk classification |
| GuruStatusID | DWH_dbo.Dim_GuruStatus | Popular Investor status |
| RegulationID / DesignatedRegulationID | DWH_dbo.Dim_Regulation | Regulatory jurisdiction |
| AccountStatusID | DWH_dbo.Dim_AccountStatus | Account enabled/disabled |
| AccountTypeID | DWH_dbo.Dim_AccountType | Account type |
| DocumentStatusID | DWH_dbo.Dim_DocumentStatus | KYC document status |
| MifidCategorizationID | DWH_dbo.Dim_MifidCategorization | MiFID II client category |
| PlayerStatusReasonID | DWH_dbo.Dim_PlayerStatusReasons | Status reason code |
| PlayerStatusSubReasonID | DWH_dbo.Dim_PlayerStatusSubReasons | Status sub-reason |
| EvMatchStatus | DWH_dbo.Dim_EvMatchStatus | eVerify match status |
| PendingClosureStatusID | DWH_dbo.Dim_PendingClosureStatus | Closure status |
| DateRangeID | DWH_dbo.Dim_Range | SCD2 date range decode |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_Guru_Copiers | RealCID | SP_Fact_Guru_Copiers joins FSC for guru/copier state |
| DWH_dbo.V_Fact_SnapshotCustomer_FromDateID | All columns | Databricks export view (generic_id=1115) |
| DWH_dbo.V_Fact_SnapshotCustomer | All columns | Alternative view (not in generic mapping) |
| DWH_dbo.Dim_Range | DateRangeID | SP inserts new DateRangeIDs into Dim_Range |

---

## 7. Sample Queries

### 7.1 Current customer state for a single customer

```sql
SELECT
    f.RealCID,
    f.GCID,
    f.AccountStatusID,
    f.PlayerStatusID,
    f.CountryID,
    f.RegulationID,
    f.IsDepositor,
    f.IsValidCustomer,
    f.DateRangeID,
    LEFT(CAST(f.DateRangeID AS VARCHAR(12)), 8) AS FromDateYYYYMMDD
FROM [DWH_dbo].[Fact_SnapshotCustomer] f
WHERE f.RealCID = 12345678
  AND RIGHT(CAST(f.DateRangeID AS VARCHAR(12)), 4) = '1231';
```

### 7.2 Count of valid retail depositors by country (current snapshot)

```sql
SELECT
    dc.CountryName,
    COUNT(DISTINCT f.RealCID) AS depositor_count
FROM [DWH_dbo].[Fact_SnapshotCustomer] f
JOIN [DWH_dbo].[Dim_Country] dc ON f.CountryID = dc.CountryID
WHERE RIGHT(CAST(f.DateRangeID AS VARCHAR(12)), 4) = '1231'
  AND f.IsDepositor = 1
  AND f.IsValidCustomer = 1
GROUP BY dc.CountryName
ORDER BY depositor_count DESC;
```

### 7.3 Customers who changed regulation during 2025 (history)

```sql
SELECT
    f.RealCID,
    f.Regula

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

### Upstream `DWH_dbo.Dim_Range` — synapse
- **Resolved as**: `DWH_dbo.Dim_Range`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md`

# DWH_dbo.Dim_Range

> DWH-internal date range helper table mapping (FromDate, ToDate) pairs as composite keys, used by Snapshot analytics to efficiently join year-to-date and multi-period equity/customer snapshots.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | DWH-internal (generated by SP_Fact_SnapshotEquity and SP_Fact_SnapshotCustomer) |
| **Refresh** | Daily - INSERT-only accumulation by Snapshot SPs |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (DateRangeID, FromDateID, ToDateID) + 3 NCI indexes |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_Range is a DWH-internal helper lookup that pre-computes all possible (FromDate, ToDate) date range pairs needed by the Snapshot analytics pipelines. Each row represents a unique start-to-end date interval, identified by a composite BigInt key (DateRangeID). The table enables efficient range-based JOINs in SnapshotEquity and SnapshotCustomer views without requiring date arithmetic at query time.

This table has no external production source. It is generated entirely within the DWH by SP_Fact_SnapshotEquity and SP_Fact_SnapshotCustomer, which INSERT new DateRangeID combinations as they encounter new date pairs during snapshot processing. The pattern is append-only - new rows are added daily but existing rows are never updated or deleted.

As of 2026-03-10, the table contains approximately 1.3 million date range pairs spanning from 2007-01-01 to 2026-03-10 on the FromDate side, and 2007-08-26 to 2026-12-31 on the ToDate side.

---

## 2. Business Logic

### 2.1 DateRangeID Encoding

**What**: DateRangeID is a deterministic composite key encoding both FromDate and MMDD(ToDate) into a single 12-digit BigInt.

**Columns Involved**: `DateRangeID`, `FromDateID`, `ToDateID`

**Rules**:
- Formula: `DateRangeID = CONCAT(YYYYMMDD(FromDate), MMDD(ToDate))`
- Example: FromDateID=20070101, ToDateID=20071231 -> DateRangeID=200701011231
- Decoding FromDateID: `CONVERT(INT, LEFT(CAST(DateRangeID AS VARCHAR(12)), 8))`
- Decoding ToDateID: `CONVERT(INT, LEFT(CAST(DateRangeID AS VARCHAR(12)), 4) + RIGHT(CAST(DateRangeID AS VARCHAR(12)), 4))`
- The YEAR component of ToDateID is always the SAME as the YEAR of FromDateID (only MMDD of ToDate is stored in the last 4 digits)

**Diagram**:
```
DateRangeID (12-digit BigInt):
  [ YYYY | MM | DD | MM | DD ]
  [  From Year  | From MMDD  | To MMDD ]
   |___________|             |________|
   Chars 1-8 = FromDateID    Chars 9-12 = MMDD(ToDate)

  ToDateID = YYYY(FromDate) + MMDD(ToDate)
  -> Year-end range example:
     FromDate=2020-03-15, ToDate=2020-12-31
     DateRangeID = 202003151231
     ToDateID    = 20201231
```

### 2.2 Snapshot Range Pattern

**What**: Dim_Range is the bridge between individual customer dates and fiscal/calendar year-end periods in Snapshot reports.

**Columns Involved**: `DateRangeID`, `FromDateID`, `ToDateID`

**Rules**:
- The primary use case is "from customer registration/event date to year-end": FromDate = customer's start date, ToDate = December 31 of that year
- The SPs also generate non-year-end ranges when snapshots require partial-period measurements
- The table grows daily as new snapshot dates are processed
- No deduplication needed - DateRangeID uniqueness is enforced by the NOT EXISTS check in both SPs

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a composite CLUSTERED INDEX on (DateRangeID, FromDateID, ToDateID) and three Non-Clustered Indexes: IX_Dim_Range_FromDateID, IX_Dim_Range_ToDateID, and IX_Dim_Range_FromDateID_ToDateID. The NCI indexes are unusual for Synapse (which typically uses only CCI) and suggest heavy range-based lookups by the Snapshot SPs. Always filter on FromDateID or ToDateID directly to leverage these indexes.

Note: PRIMARY KEY (DateRangeID) is declared NOT ENFORCED - Synapse does not validate uniqueness but the ETL SPs maintain it via NOT EXISTS guards.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` is Parquet. With 1.3M rows, consider filtering on FromDateID for performance.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Find the DateRangeID for a specific (from, to) pair | `SELECT DateRangeID FROM DWH_dbo.Dim_Range WHERE FromDateID = @from AND ToDateID = @to` |
| Find all ranges starting from a given date | `WHERE FromDateID = @date` (uses IX_Dim_Range_FromDateID) |
| Look up range details from a DateRangeID | `SELECT FromDateID, ToDateID FROM DWH_dbo.Dim_Range WHERE DateRangeID = @id` |
| Check how many ranges exist for a year | `WHERE FromDateID BETWEEN @year*10000+101 AND @year*10000+1231` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_SnapshotEquity | DateRangeID | Resolve snapshot equity date ranges |
| DWH_dbo.Fact_SnapshotCustomer | DateRangeID | Resolve snapshot customer date ranges |
| DWH_dbo.V_Fact_SnapshotEquity | DateRangeID | View-level access to snapshot equity with resolved ranges |
| DWH_dbo.V_M2M_Date_DateRange | DateRangeID | Month-to-month date range bridging |

### 3.4 Gotchas

- **ToDate YEAR = FromDate YEAR**: The DateRangeID encoding only stores MMDD of ToDate. The year of ToDate is derived from FromDate's year. This means all ranges in this table are within-year ranges - cross-year ranges cannot be represented.
- **INSERT-only, no TRUNCATE**: Both writer SPs use NOT EXISTS guards, making the table append-only. Rows are never deleted. If a DateRangeID is erroneously created, it persists forever.
- **Primary key NOT ENFORCED**: Synapse does not verify uniqueness of DateRangeID. Trust the ETL logic, not the constraint.
- **DateRangeID is a STRING-derived number**: Always treat DateRangeID as a derived key, not a business ID. Decode using LEFT/RIGHT string operations if needed.
- **1.3M rows for a dim table**: Larger than typical dimensions. REPLICATE is appropriate given daily Snapshot SP joins from all distributions.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP code)` |
| ★★☆☆☆ | Tier 3b - DDL structure | `(Tier 3b - DDL)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateRangeID | bigint | NO | Primary key (NOT ENFORCED). 12-digit composite key encoding FromDate and MMDD(ToDate). Formula: CONCAT(YYYYMMDD(From), MMDD(To)). Example: 200701011231 = From:20070101, To:20071231. (Tier 2 - SP code: SP_Fact_SnapshotEquity) |
| 2 | FromDateID | int | NO | Start date of the range in YYYYMMDD integer format. Derived from DateRangeID: LEFT(DateRangeID, 8). Range: 20070101 to 20260310. (Tier 2 - SP code: SP_Fact_SnapshotEquity) |
| 3 | ToDateID | int | NO | End date of the range in YYYYMMDD integer format. Derived from DateRangeID: YYYY(From) + MMDD(last 4 chars of DateRangeID). The year of ToDate always equals the year of FromDate. Range: 20070826 to 20261231. (Tier 2 - SP code: SP_Fact_SnapshotEquity) |
| 4 | UpdateDate | datetime | YES | ETL timestamp set to GETDATE() when the row was inserted. NULL for oldest rows (pre-UpdateDate tracking). Not a business date. (Tier 3b - DDL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| DateRangeID | DWH-internal (computed) | - | ETL-computed: CONCAT(YYYYMMDD(@date), MMDD(@largedate)) |
| FromDateID | DWH-internal (computed) | - | ETL-computed: LEFT(DateRangeID, 8) |
| ToDateID | DWH-internal (computed) | - | ETL-computed: LEFT(DateRangeID, 4) + RIGHT(DateRangeID, 4) |
| UpdateDate | - | - | ETL-computed: GETDATE() at insert time |

### 5.2 ETL Pipeline

```
SP_Fact_SnapshotEquity (daily) ---+
                                  +--> INSERT new DateRangeIDs --> DWH_dbo.Dim_Range
SP_Fact_SnapshotCustomer (daily) -+
```

| Step | Object | Description |
|------|--------|-------------|
| Writer 1 | SP_Fact_SnapshotEquity | INSERTs new (FromDate, ToDate) pairs from #outputdata temp table (Action='UPDATE') |
| Writer 2 | SP_Fact_SnapshotCustomer | INSERTs new (FromDate, ToDate) pairs from #outputdata and #UpdatedRanges temp tables |
| Guard | NOT EXISTS check | Both SPs use NOT EXISTS to prevent duplicate DateRangeIDs |
| Target | DWH_dbo.Dim_Range | Append-only. 1.3M rows as of 2026-03-10 |
| Export | Generic Pipeline (daily) | Exports to dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A - DateRangeID, FromDateID, and ToDateID are DWH-internal keys with no external FK targets.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.V_Fact_SnapshotEquity | DateRangeID | Snapshot equity view with date range context |
| DWH_dbo.V_Fact_SnapshotEquity_FromDateID | DateRangeID / FromDateID | Snapshot equity filtered by customer registration date |
| DWH_dbo.V_Fact_SnapshotCustomer | DateRangeID | Snapshot customer view with date range context |
| DWH_dbo.V_Fact_SnapshotCustomer_FromDateID | DateRangeID / FromDateID | Snapshot customer filtered by registration date |
| DWH_dbo.V_M2M_Date_DateRange | DateRangeID | Month-to-month date range bridge view |

---

## 7. Sample Queries

### 7.1 Decode a DateRangeID back to its components
```sql
SELECT
    DateRangeID,
    FromDateID,
    ToDateID,
    -- Verify encoding formula
    CONVERT(BIGINT,
        LEFT(CONVERT(VARCHAR(12), DateRangeID), 4)
        + RIGHT(CONVERT(VARCHAR(12), DateRangeID), 4)
    ) AS ToDateID_decoded
FROM [DWH_dbo].[Dim_Range]
WHERE DateRangeID = 200701011231
```

### 7.2 Find all year-end ranges (FromDate to Dec 31 of same year)
```sql
SELECT DateRangeID, FromDateID, ToDateID
FROM [DWH_dbo].[Dim_Range]
WHERE RIGHT(CAST(DateRangeID AS VARCHAR(12)), 4) = '1231'
ORDER BY FromDateID DESC
```

### 7.3 Count ranges per year
```sql
SELECT
    LEFT(CAST(FromDateID AS VARCHAR(8)), 4) AS FromYear,
    COUNT(*) AS range_count
FROM [DWH_dbo].[Dim_Range]
GROUP BY LEFT(CAST(FromDateID AS VARCHAR(8)), 4)
ORDER BY FromYear DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-19 | Quality: 8.3/10 (★★★★☆) | Phases: 10/14*
*Tiers: 0 T1, 3 T2, 1 T3b, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10*
*Object: DWH_dbo.Dim_Range | Type: Table | Production Source: DWH-internal (SP_Fact_SnapshotEquity + SP_Fact_SnapshotCustomer)*


### Upstream `DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot` — synapse
- **Resolved as**: `DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PositionHedgeServerChangeLog_Snapshot.md`

# DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot

> SCD Type 2 snapshot table tracking the history of hedge server assignments per position -- each row represents a date range during which a position was assigned to a specific HedgeServerID, with ToDate=20991231 indicating the current active assignment.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Trade.PositionsHedgeServerChangeLog |
| **Refresh** | Daily (incremental via SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse @dt) |
| | |
| **Synapse Distribution** | HASH (PositionID) |
| **Synapse Index** | CLUSTERED INDEX (PositionID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot` |
| **UC Format** | Delta |
| **UC Partitioned By** | None (sparse) |
| **UC Table Type** | Managed |

---

## 1. Business Meaning

Dim_PositionHedgeServerChangeLog_Snapshot tracks which hedge server (HedgeServerID) was responsible for executing and managing each position during any given date range. A hedge server is the execution venue or broker-side system where a position is "hedged" (i.e., covered with a liquidity provider). Positions can move between hedge servers during their lifetime.

This table uses an SCD Type 2 pattern:
- **FromDate**: The YYYYMMDD date from which HedgeServerID was active for this position.
- **ToDate**: The YYYYMMDD date to which HedgeServerID was active. ToDate=20991231 indicates the current/active assignment.
- A position moving from HedgeServer A to HedgeServer B generates two rows: (PositionID, ServerA, FromDate=OpenDate, ToDate=yesterday) and (PositionID, ServerB, FromDate=today, ToDate=20991231).

**Predecessor table**: The original `Dim_PositionHedgeServerChangeLog` table was replaced by this snapshot variant. The `_Snapshot` suffix indicates the SCD2 approach vs. the original raw-log approach. `Dim_PositionHedgeServerChangeLog` no longer exists in Synapse.

This table is used by SP_Dim_Position_DL_To_Synapse when populating `InitHedgeType` and `EndHedgeType` on Dim_Position (via SP_Dim_Position_HedgeType_Real and SP_Dim_Position_HedgeType_History).

---

## 2. Business Logic

### 2.1 SCD Type 2 Active-Record Pattern

**What**: Each position has one or more rows representing consecutive HedgeServerID assignments.

**Columns Involved**: `PositionID`, `HedgeServerID`, `FromDate`, `ToDate`

**Rules**:
- **Current assignment**: `WHERE ToDate = 20991231` -- gives the active hedge server for each position.
- **Historical assignment on a date**: `WHERE FromDate <= @dateID AND ToDate >= @dateID` -- point-in-time hedge server lookup.
- **Single initial assignment**: Most positions have a single row (never changed hedge server): FromDate=OpenDateID, ToDate=20991231.
- **After hedge server change**: The old row gets ToDate=dateBeforeChange. A new row is inserted with FromDate=changeDate, ToDate=20991231.
- **New positions**: On first appearance in PositionsHedgeServerChangeLog, two rows may be inserted: one for the pre-change period (OpenDateID -> OccurredDateID-1, using FromHedgeServerID) and one for the post-change period (OccurredDateID -> 20991231, using ToHedgeServerID).
- Both FromDate and ToDate are YYYYMMDD ints (e.g., 20260226). Use `CAST(CAST(FromDate AS VARCHAR(8)) AS DATE)` to convert.

### 2.2 ETL Pattern

**What**: Daily incremental update to maintain the SCD2 records.

**Rules**:
1. DELETE rows with FromDate >= yesterday (re-process yesterday's data).
2. Set ToDate=20991231 on the most recent row per PositionID (repair any open-ended records).
3. Load yesterday's hedge server changes from etoro_Trade_PositionsHedgeServerChangeLog (via Ext_Dim_Position_PositionHedgeServerChangeLog).
4. Deduplicate: Remove duplicates keeping only the most recent per PositionID (ROW_NUMBER by OccurredDate DESC).
5. For positions already in Snapshot: Close old row (ToDate=yesterday), insert new active row (FromDate=today, ToDate=20991231).
6. For new positions: Insert initial row (FromDate=OpenDateID, ToDate=OccurredDateID-1) + active row (FromDate=OccurredDateID, ToDate=20991231).

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**HASH (PositionID)**: Co-located with Dim_Position for efficient JOINs. A JOIN between Dim_PositionHedgeServerChangeLog_Snapshot and Dim_Position on PositionID benefits from co-location.

**CLUSTERED INDEX (PositionID)**: Efficient for lookups by PositionID. When querying current active records (`WHERE ToDate=20991231`), this is efficient.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot`. No partitioning needed unless the table grows very large. Z-ORDER on PositionID is beneficial.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current hedge server for a position | WHERE PositionID = X AND ToDate = 20991231 |
| Hedge server for a position on a date | WHERE PositionID = X AND FromDate <= YYYYMMDD AND ToDate >= YYYYMMDD |
| All positions on a specific hedge server today | WHERE HedgeServerID = 84 AND ToDate = 20991231 |
| Positions that changed hedge servers | Positions with more than 1 row |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Position | ON PositionID AND CloseDateID BETWEEN FromDate AND ToDate | Match position to its hedge server at close date |
| DWH_dbo.Dim_Position | ON PositionID AND ToDate = 20991231 | Get current hedge server |

### 3.4 Gotchas

- **ToDate=20991231 = active row**: This sentinel value (year 2099) means "no end date known yet" -- the current active assignment. NOT a real date.
- **FromDate/ToDate are int YYYYMMDD**: Cannot use standard date comparisons directly. Use `BETWEEN` with int values.
- **UpdateDate is 2026-02-27**: The table is 20+ days stale as of 2026-03-19. This is more stale than other DWH tables (which are stale to 2026-03-11). Check whether the SP runs independently from the main ETL.
- **Dim_PositionHedgeServerChangeLog does NOT exist**: The original table without `_Snapshot` suffix was dropped. Do not reference the old name.
- **Not all positions appear**: Only positions that have had a hedge server change event appear here. Positions that were assigned to one server from open to close and never changed may have only one row, or no rows if no change event was ever logged.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - Upstream wiki | (Tier 1 — Trade.PositionsHedgeServerChangeLog) |
| *** | Tier 2 - Synapse SP code | (Tier 2 — SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse) |
| ** | Tier 3 - MCP live data | (Tier 3 — MCP live data) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | bigint | NO | The position that was moved between hedge servers. References Trade.PositionTbl.PositionID (implicit - no declared FK). Part of composite PK with OperationSummaryID. A position can appear multiple times if moved across different operations. (Tier 1 — Trade.PositionsHedgeServerChangeLog) |
| 2 | HedgeServerID | int | NO | The hedge server ID the position was moved to. After this operation, Trade.PositionTbl.HedgeServerID equals this value for the affected position. (Tier 1 — Trade.PositionsHedgeServerChangeLog) |
| 3 | FromDate | int | YES | Start date of this hedge server assignment (YYYYMMDD int). For initial position open: equals OpenDateID. For subsequent changes: equals the date the change took effect. (Tier 2 — SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse) |
| 4 | ToDate | int | YES | End date of this hedge server assignment (YYYYMMDD int). 20991231=currently active. For closed/changed records: the last day this assignment was valid (inclusive). (Tier 2 — SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp (GETDATE()). All rows share same timestamp per daily ETL run. Last seen: 2026-02-27. (Tier 2 — SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Table | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| PositionID | etoro_Trade_PositionsHedgeServerChangeLog | PositionID | passthrough |
| HedgeServerID | etoro_Trade_PositionsHedgeServerChangeLog | FromHedgeServerID / ToHedgeServerID | ETL-computed: FromHedgeServerID for pre-change rows, ToHedgeServerID for post-change rows |
| FromDate | Dim_Position | OpenDateID | ETL-computed: OpenDateID for pre-change rows; OccurredDateID for post-change rows |
| ToDate | -- | -- | ETL-computed: OccurredDateID-1 for pre-change rows; 20991231 for active rows |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Trade.PositionsHedgeServerChangeLog
  -> Generic Pipeline (daily)
  -> DWH_staging.etoro_Trade_PositionsHedgeServerChangeLog
  -> DWH_dbo.Ext_Dim_Position_PositionHedgeServerChangeLog (staging buffer)
  -> SP_Dim_Position_PositionHedgeServerChangeLog (via SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse)
  -> DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot (SCD2 upsert)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Trade.PositionsHedgeServerChangeLog | Production hedge server change events |
| Staging | DWH_staging.etoro_Trade_PositionsHedgeServerChangeLog | Raw staging |
| Ext | DWH_dbo.Ext_Dim_Position_PositionHedgeServerChangeLog | Loaded from staging: PositionID, OccurredDate, FromHedgeServerID, ToHedgeServerID |
| ETL | SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse | DELETE-then-rebuild for yesterday; update ToDate on open records; call SP_Dim_Position_PositionHedgeServerChangeLog |
| ETL (inner SP) | SP_Dim_Position_PositionHedgeServerChangeLog | Deduplicates ext table; closes old active rows; inserts new rows for changed/new positions |
| Target | DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot | 5 cols, SCD2 pattern |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Target Object | Join Column | Description |
|--------------|-------------|-------------|
| DWH_dbo.Dim_Position | PositionID | Position being tracked |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.SP_Dim_Position_PositionHedgeServerChangeLog | PositionID | Reads active rows to update ToDate when server changes |
| DWH_dbo.SP_Dim_Position_HedgeType_Real | PositionID | Derives InitHedgeType for open positions |
| DWH_dbo.SP_Dim_Position_HedgeType_History | PositionID | Derives EndHedgeType for closed positions |

---

## 7. Sample Queries

### 7.1 Current hedge server for a specific position

```sql
SELECT PositionID, HedgeServerID, FromDate, ToDate
FROM   [DWH_dbo].[Dim_PositionHedgeServerChangeLog_Snapshot]
WHERE  PositionID = 3268434767
  AND  ToDate = 20991231;
```

### 7.2 Point-in-time hedge server for a position

```sql
SELECT PositionID, HedgeServerID, FromDate, ToDate
FROM   [DWH_dbo].[Dim_PositionHedgeServerChangeLog_Snapshot]
WHERE  PositionID = 3268434767
  AND  FromDate <= 20260310
  AND  ToDate   >= 20260310;
```

### 7.3 All positions currently on a specific hedge server

```sql
SELECT PositionID, FromDate
FROM   [DWH_dbo].[Dim_PositionHedgeServerChangeLog_Snapshot]
WHERE  HedgeServerID = 84
  AND  ToDate = 20991231
ORDER BY FromDate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.5/10 (***) | Phases: 14/14 (full pipeline)*
*Tiers: 2 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10*
*Object: DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot | Type: Table | Production Source: etoro.Trade.PositionsHedgeServerChangeLog*


### Upstream `BI_DB_dbo.BI_DB_PositionPnL` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_PositionPnL`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_PositionPnL.md`

# BI_DB_dbo.BI_DB_PositionPnL

## 1. Overview

Daily end-of-day snapshot of **open trading positions** with unrealized P&L, rates, commissions, NOP, and close-price metrics. Grain is **one row per position per calendar day** (`DateID` + `PositionID`); only positions open as of end of `@dt` appear for that `DateID`.

## 2. Business Context

- **Rules**: Positions are sourced from `DWH_dbo.Dim_Position` with `OpenDateID < @ReportDateID` and still open on `@dt` (`CloseDateID >= @ReportDateID` or `CloseDateID = 0`). `Dim_PositionChangeLog` rewinds `Amount`, `StopRate`, `AmountInUnitsDecimal`, and `IsSettled` when changes occur after `@dt`; rows with partial-close child (`ChangeTypeID = 11`) after `@dt` are removed. Stock splits adjust `InitForexRate`, units, and EOD rates via `Dim_HistorySplitRatio` and `#Prices`. **PositionPnL** is `PnLInDollars` from Dim_Position (authoritative PnL engine) since 2024-03-24; **Price** and **NOP** still use SP formulas from EOD rates and `Dim_Instrument` FX chains. **DailyPnL** is updated after load as today `PositionPnL` minus prior day `PositionPnL` per `PositionID`.
- **Consumers**: Finance and CMR reporting; downstream BI_DB procedures and views (e.g. crypto zero / loan / NOP stacks, IFRS, compliance, dashboards) read this table as the canonical daily position P&L snapshot.

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object type** | Table |
| **Column count** | 39 |
| **Distribution** | `HASH (PositionID)` |
| **Clustered index** | `(DateID ASC, Date ASC, CID ASC, PositionID ASC)` |
| **Partitioning** | `PARTITION (DateID RANGE LEFT FOR VALUES (...))` -- daily boundaries aligned with main table (typically 2015 through current horizon) |
| **Nonclustered index** | `IX_BI_DB_PositionPnL_CID` on `(DateID, CID)` on main table (per deployment; switch staging builds CID NCIs on switch tables) |

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | int | YES | Customer identifier for the position. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.CID) |
| 2 | PositionID | bigint | NO | Unique position key; Synapse distribution key. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.PositionID) |
| 3 | InstrumentID | int | NO | Traded instrument. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.InstrumentID) |
| 4 | MirrorID | int | YES | Copy-trading mirror link when applicable. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.MirrorID) |
| 5 | Commission | money | NO | Opening commission in dollars. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Commission) |
| 6 | InitForexRate | numeric(16,8) | NO | Open rate; split-adjusted in SP when position spans a split. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.InitForexRate / split logic) |
| 7 | SpreadedPipBid | numeric(16,8) | YES | Bid with spread at open. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.SpreadedPipBid) |
| 8 | SpreadedPipAsk | numeric(16,8) | YES | Ask with spread at open. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.SpreadedPipAsk) |
| 9 | PositionPnL | decimal(16,4) | YES | Unrealized P&L in USD; from `PnLInDollars` (replaces legacy formula). (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.PnLInDollars) |
| 10 | Price | numeric(38,6) | YES | Per-unit price-move expression × USD conversion factor from `#Pre_UnrealizedPnL` (bid/ask vs InitForexRate and instrument FX chain). (Tier 2 -- SP_PositionPnL, computed from #OpenPositions + Dim_Instrument + #Prices) |
| 11 | HedgeServerID | int | YES | Hedge server for the position. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.HedgeServerID) |
| 12 | Amount | money | NO | Position amount in USD; rewound via `Dim_PositionChangeLog` when SL/partial-close edits after `@dt`. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Amount / PositionChangeLog.PreviousAmount) |
| 13 | AmountInUnitsDecimal | numeric(16,6) | YES | Size in instrument units; split-adjusted and rewound from partial-close log when applicable. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.AmountInUnitsDecimal / split + PositionChangeLog) |
| 14 | LimitRate | numeric(16,8) | NO | Take-profit rate. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.LimitRate) |
| 15 | StopRate | numeric(16,8) | NO | Stop-loss rate; rewound to `PreviousStopRate` when edited after `@dt`. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.StopRate / PositionChangeLog) |
| 16 | IsBuy | bit | NO | Long (1) vs short (0). (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.IsBuy) |
| 17 | Occurred | datetime | NO | Position open timestamp (`OpenOccurred`). (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.OpenOccurred) |
| 18 | Date | date | YES | Snapshot calendar date `@dt`. (Tier 3 -- SP_PositionPnL, parameter @dt) |
| 19 | DateID | int | NO | Snapshot date as YYYYMMDD; partition key. (Tier 3 -- SP_PositionPnL, CAST(CONVERT(CHAR(8),@dt,112) AS INT)) |
| 20 | UpdateDate | datetime | YES | Row load timestamp at insert (`GETDATE()`). (Tier 3 -- SP_PositionPnL, GETDATE()) |
| 21 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. Rewound via PositionChangeLog (`ChangeTypeID = 13`) when applicable. (Tier 5 — Expert Review) |
| 22 | NOP | money | YES | Net open position in USD from units × pair rate × direction × conversion (see `#Pre_UnrealizedPnL`). (Tier 2 -- SP_PositionPnL, computed) |
| 23 | DailyPnL | decimal(16,4) | YES | Day-over-day change: `PositionPnL - prior day PositionPnL` (NULL until post-switch UPDATE). (Tier 3 -- SP_PositionPnL, UPDATE vs prior DateID) |
| 24 | Leverage | int | YES | Position leverage. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Leverage) |
| 25 | RateBid | numeric(36,12) | YES | EOD bid from latest `Fact_CurrencyPriceWithSplit` row before `@ReportDate`, split-adjusted; uses `BidLastWithoutSpread` when discounted. (Tier 2 -- SP_PositionPnL, DWH_dbo.Fact_CurrencyPriceWithSplit + split) |
| 26 | RateAsk | numeric(36,12) | YES | EOD ask from same price row, split-adjusted. (Tier 2 -- SP_PositionPnL, DWH_dbo.Fact_CurrencyPriceWithSplit + split) |
| 27 | USD_CR | money | YES | End-of-day conversion rate used with PnL context; from Dim_Position `CurrentConversionRate`. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.CurrentConversionRate) |
| 28 | SettlementTypeID | int | YES | Modern settlement type from Dim_Position. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.SettlementTypeID) |
| 29 | EstimateCloseFeeForCFD | numeric(19,8) | YES | Estimated close fee for CFD from production PnL inputs. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.EstimateCloseFeeForCFD) |
| 30 | EstimateCloseFeeOnOpenByUnits | numeric(19,8) | YES | Estimated close fee per units-at-open path. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.EstimateCloseFeeOnOpenByUnits) |
| 31 | EstimateCloseFeeOnOpen | numeric(19,8) | YES | Estimated close fee from open parameters. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.EstimateCloseFeeOnOpen) |
| 32 | Close_PnLInDollars | decimal(19,4) | YES | Official close-price P&L in dollars from Dim_Position. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Close_PnLInDollars) |
| 33 | Close_CalculationRate | decimal(18,8) | YES | Rate used for close P&L. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Close_CalculationRate) |
| 34 | Close_ConversionRate | decimal(18,8) | YES | FX conversion at close for regulated P&L. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Close_ConversionRate) |
| 35 | Close_PriceType | int | YES | Close price type indicator from upstream PnL. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.Close_PriceType) |
| 36 | CurrentCalculationRate | numeric(18,8) | YES | Max-date calculation rate for last-bid style P&L. (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.CurrentCalculationRate) |
| 37 | CurrentConversionRate | numeric(18,8) | YES | Conversion rate paired with current calculation rate (same source family as USD_CR). (Tier 2 -- SP_PositionPnL, DWH_dbo.Dim_Position.CurrentConversionRate) |
| 38 | Close_NOP | numeric(18,8) | YES | NOP using close rates: `AmountInUnitsDecimal * Close_CalculationRate * Close_ConversionRate`. (Tier 2 -- SP_PositionPnL, computed in #Pre_UnrealizedPnL) |
| 39 | Current_NOP | numeric(18,8) | YES | NOP using current rates: `AmountInUnitsDecimal * CurrentCalculationRate * CurrentConversionRate`. (Tier 2 -- SP_PositionPnL, computed in #Pre_UnrealizedPnL) |

## 5. Relationships

**Source tables (ETL read path)**

| Source | Role |
|--------|------|
| DWH_dbo.Dim_Position | Open positions, PnL dollars, fees, close/current rates, core attributes |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Latest bid/ask before `@ReportDate` per instrument |
| DWH_dbo.Dim_HistorySplitRatio | Split boundaries and ratios for rate/unit adjustment |
| DWH_dbo.Dim_PositionChangeLog | Rewind deletes/updates for post-`@dt` changes |
| DWH_dbo.Dim_Instrument (+ self-joins / #Prices) | Instrument currency pair and USD cross for Price and NOP |

**Consumers (representative)**

Includes finance and CMR pipelines and many BI_DB dependents such as **`BI_DB_Crypto_Zero`**, **`BI_DB_Real_Crypto_Loan`**, **`BI_DB_DailyZero_TreeSize_NEW`** (and related daily zero / NOP procedures), plus roll-over and dividend logic (**`SP_RollOverFee_Dividends`** reads prior-day `AmountInUnitsDecimal`), IFRS, compliance, and diagnostics. Confirm additional references with a repo search on `BI_DB_PositionPnL`.

## 6. ETL & Lifecycle

| Aspect | Detail |
|--------|--------|
| **Writer** | `BI_DB_dbo.SP_PositionPnL` @dt |
| **OpsDB** | Priority **99**, ProcessType **4** (FinanceReportSPS), frequency **Daily** |
| **Pattern** | Build `#UnrealizedPnL` -- create `BI_DB_PositionPnL_SWITCH_SINGLE` with same distribution/index/partition scheme as main table -- `INSERT ... SELECT` from `#UnrealizedPnL` -- `SP_BI_DB_PositionPnL_SWITCH` partition swap -- `UPDATE` **DailyPnL** vs previous `DateID` |
| **Grain** | One row per open `PositionID` per `DateID` |
| **Delete scope** | Daily partition replaced via switch for the target `DateID` (not a full-table DELETE) |

## 7. Query Advisory

- **Partition elimination**: Always filter **`WHERE DateID = ...` or a tight `DateID` range**; scanning all daily partitions is prohibitively expensive.
- **Distribution**: **`PositionID`** is the hash key -- joins and GROUP BY on `PositionID` minimize movement; filtering large sets by `CID` alone may benefit from **`IX_BI_DB_PositionPnL_CID (DateID, CID)`** when present.
- **Semantics**: Table holds **open** positions only for each snapshot date; closed-position economics live in `Dim_Position` / fact tables.
- **DailyPnL**: Populated in a second step; for intraday copies of switch tables, expect NULL until the main-table UPDATE runs.

## 8. Classification & Status

| Field | Value |
|-------|--------|
| **Domain** | Finance / trading P&L and exposure |
| **Sensitivity** | Customer and position-level financial data -- internal use only |
| **Quality score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `Dealing_dbo.SP_Boundary_Cost`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_Boundary_Cost.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [Dealing_dbo].[SP_Boundary_Cost] @Date [DATE] AS
BEGIN

    ----=============================================================================================
    --DECLARE @Date DATE = '2023-02-08';
    DECLARE @DateID INT = CONVERT(NVARCHAR, @Date, 112);
    DECLARE @PreviousDay DATE = DATEADD(DAY, -1, @Date);
    DECLARE @PreviousDayID INT = CONVERT(NVARCHAR, @PreviousDay, 112);
    DECLARE @NextDay DATE = DATEADD(DAY, 1, @Date);
    DECLARE @ThreeMonthsBefore DATE = DATEADD(MONTH, -2, DATEADD(MONTH, DATEDIFF(MONTH, 0, @Date), 0)); -- 2 months before first day of the month
    DECLARE @ThreeMonthsBeforeID INT = CONVERT(NVARCHAR, @ThreeMonthsBefore, 112);

    ----=============================================================================================
    IF OBJECT_ID('tempdb..#Ins') IS NOT NULL
        DROP TABLE #Ins;

    CREATE TABLE #Ins
    WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS
    ----open positions
    SELECT InstrumentID,
           InstrumentDisplayName AS InstrumentName,
           InstrumentType,
           InstrumentTypeID,
           BuyCurrencyID,
           SellCurrencyID
    FROM [DWH_dbo].[Dim_Instrument]
    WHERE Tradable = 1
          AND VisibleInternallyOnly = 0
          AND
          (
              InstrumentTypeID IN ( 2, 4, 5, 6 )
              OR
              (
                  InstrumentTypeID = 10
                  AND SellCurrencyID = 1
              )
          );

PRINT('#Ins')

    ----=============================================================================================
    IF OBJECT_ID('tempdb..#CID') IS NOT NULL
        DROP TABLE #CID;
 
    CREATE TABLE #CID
    WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS
    ----open positions
    SELECT d.DateKey,
           SC.RealCID
    FROM [DWH_dbo].[Fact_SnapshotCustomer] SC WITH (NOLOCK)
        JOIN [DWH_dbo].Dim_Range R WITH (NOLOCK)
            ON SC.DateRangeID = R.DateRangeID
        JOIN [DWH_dbo].Dim_Date d
            ON d.DateKey
               BETWEEN FromDateID AND ToDateID
    WHERE d.DateKey IN ( @DateID, @PreviousDayID )
          AND IsValidCustomer = 1;

		  PRINT('#CID')

		  --SELECT  * FROM #CID c
    ----=============================================================================================
    IF OBJECT_ID('tempdb..#Position_Pre') IS NOT NULL
        DROP TABLE #Position_Pre;

    CREATE TABLE #Position_Pre
    WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS
    ----open positions
    SELECT dp.PositionID
		,dp.OpenOccurred
		,dp.OpenDateID
		,dp.CloseOccurred
		,dp.CloseDateID
		,dp.InstrumentID
		,dp.HedgeServerID
		,dp.IsSettled
		,dp.CID
		,dp.IsBuy
		,dp.AmountInUnitsDecimal
		,dp.Volume
		,dp.VolumeOnClose
		,dp.InitForex_Ask
		,dp.InitForex_Bid
		,dp.InitForexRate
		,dp.InitForex_USDConversionRate
		,dp.EndForex_Ask
		,dp.EndForex_Bid
		,dp.EndForexRate
		,dp.LastOpConversionRate
    FROM [DWH_dbo].Dim_Position dp WITH (NOLOCK)
    WHERE dp.OpenDateID
          BETWEEN @ThreeMonthsBeforeID AND @DateID
          OR dp.CloseDateID
          BETWEEN @ThreeMonthsBeforeID AND @DateID;
PRINT('#Position_Pre')
    ----=============================================================================================

    IF OBJECT_ID('tempdb..#PreviousDayPerPos_Pre') IS NOT NULL
        DROP TABLE #PreviousDayPerPos_Pre;

    CREATE TABLE #PreviousDayPerPos_Pre
    WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS
    ----open positions
    SELECT PositionID
		,dp.InstrumentID
		,dp.HedgeServerID
		,dp.IsSettled
		,dp.IsBuy
		,dp.AmountInUnitsDecimal
FROM DWH_dbo.Dim_Position dp WITH (NOLOCK)
JOIN #CID fsc
ON dp.CID=fsc.RealCID
JOIN #Ins i
ON i.InstrumentID = dp.InstrumentID
WHERE fsc.DateKey = @PreviousDayID
		AND (dp.CloseDateID >= @DateID OR dp.CloseDateID = 0)
		AND dp.OpenDateID < @DateID;
PRINT('#PreviousDayPerPos_Pre')
----=============================================================================================

--Take the history of the HS Position

IF OBJECT_ID('tempdb..#HSPositions') IS NOT NULL
        DROP TABLE #HSPositions;

 CREATE TABLE #HSPositions
    WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS
SELECT dphscls.PositionID
		,dphscls.HedgeServerID
		,dphscls.FromDate
		,dphscls.ToDate
FROM DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot dphscls WITH (NOLOCK)
WHERE (CASE WHEN dphscls.FromDate = dphscls.ToDate THEN dphscls.FromDate END = @DateID)
			OR @DateID BETWEEN dphscls.FromDate AND dphscls.ToDate ;

--SELECT * FROM #HSPositions WHERE PositionID = 389710093
PRINT('#HSPositions')
----=============================================================================================

IF OBJECT_ID('tempdb..#HSDistinct') IS NOT NULL
        DROP TABLE #HSDistinct;

 CREATE TABLE #HSDistinct
    WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS
SELECT *
FROM (
SELECT *, ROW_NUMBER() OVER(PARTITION BY h.PositionID ORDER BY h.FromDate) AS RN
FROM #HSPositions h) a
WHERE RN = 1;
PRINT('#HSDistinct')
----=============================================================================================

IF OBJECT_ID('tempdb..#PreviousDayPerPos') IS NOT NULL
        DROP TABLE #PreviousDayPerPos;

 CREATE TABLE #PreviousDayPerPos
    WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS
SELECT p.PositionID
	  ,p.InstrumentID
	  ,ISNULL(hpd.HedgeServerID,p.HedgeServerID) AS HedgeServerID
	  ,p.IsSettled
	  ,p.IsBuy
	  ,p.AmountInUnitsDecimal
FROM #PreviousDayPerPos_Pre p
LEFT JOIN #HSDistinct hpd
ON p.PositionID = hpd.PositionID;

--SELECT TOP 1000 * FROM #HSDistinct h WHERE h.HedgeServerID = 112 AND h.FromDate = 20220511
PRINT('#PreviousDayPerPos')
----=============================================================================================

IF OBJECT_ID('tempdb..#Position') IS NOT NULL
        DROP TABLE #Position;

 CREATE TABLE #Position
    WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS
SELECT pp.PositionID
	  ,pp.OpenOccurred
	  ,pp.OpenDateID
	  ,pp.CloseOccurred
	  ,pp.CloseDateID
	  ,pp.InstrumentID
	  ,ISNULL(h.HedgeServerID, pp.HedgeServerID) AS HedgeServerID
	  ,pp.IsSettled
	  ,pp.CID
	  ,pp.IsBuy
	  ,pp.AmountInUnitsDecimal
	  ,pp.Volume
	  ,pp.VolumeOnClose
	  ,pp.InitForex_Ask
	  ,pp.InitForex_Bid
	  ,pp.InitForexRate
	  ,pp.InitForex_USDConversionRate
	  ,pp.EndForex_Ask
	  ,pp.EndForex_Bid
	  ,pp.EndForexRate
	  ,pp.LastOpConversionRate 
FROM #Position_Pre pp
LEFT JOIN #HSDistinct h
ON pp.PositionID = h.PositionID;
PRINT('#Position')
----=============================================================================================

IF OBJECT_ID('tempdb..#PreviousDayNOP') IS NOT NULL
        DROP TABLE #PreviousDayNOP;

 CREATE TABLE #PreviousDayNOP
    WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS
SELECT pdu.InstrumentID
		,pdu.HedgeServerID
		,pdu.IsSettled
		,SUM(CASE WHEN IsBuy=1 THEN AmountInUnitsDecimal ELSE -AmountInUnitsDecimal end) Units 
FROM BI_DB_dbo.BI_DB_PositionPnL pdu--#PreviousDayPerPos pdu
WHERE DateID = @PreviousDayID
GROUP BY pdu.InstrumentID
		,pdu.HedgeServerID
		,pdu.IsSettled;

PRINT('#PreviousDayNOP')
--SELECT distinct HedgeServerID FROM #PreviousDayNOP WHERE InstrumentID = 100000
--SELECT * FROM #PreviousDayNOP WHERE InstrumentID = 6212 AND HedgeServerID = 112
--SELECT TOP 10 * FROM BI_DB_dbo.BI_DB_PositionPnL bdppl
    ----=============================================================================================

    IF OBJECT_ID('tempdb..#RawSpread') IS NOT NULL
        DROP TABLE #RawSpread;

    CREATE TABLE #RawSpread
    WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS
    ----open positions
    -- Spread- Standard Deviation calculation (quarterly average)
    SELECT CAST(OpenOccurred AS DATE) Date,
           dp.InstrumentID,
           dp.InitForex_Bid Bid,
           dp.InitForex_Ask Ask,
           (dp.InitForex_Bid + dp.InitForex_Ask) / 2 Mid,
           dp.InitForex_Ask - dp.InitForex_Bid Spread
    FROM #Position dp
        JOIN #Ins i
            ON dp.InstrumentID = i.InstrumentID
    WHERE dp.OpenDateID
          BETWEEN @ThreeMonthsBeforeID AND @DateID
          AND dp.InitForex_Bid IS NOT NULL
    UNION ALL
    SELECT CAST(CloseOccurred AS DATE) Date,
           dp.InstrumentID,
           dp.EndForex_Bid,
           dp.EndForex_Ask,
           (dp.EndForex_Bid + dp.EndForex_Ask) / 2 Mid,
           dp.EndForex_Ask - dp.EndForex_Bid Spread
    FROM #Position dp
        JOIN #Ins i
            ON dp.InstrumentID = i.InstrumentID
    WHERE dp.CloseDateID
          BETWEEN @ThreeMonthsBeforeID AND @DateID
          AND dp.EndForex_Bid IS NOT NULL;
PRINT('#RawSpread')
    ----=============================================================================================
    IF OBJECT_ID('tempdb..#StdSpread') IS NOT NULL
        DROP TABLE #StdSpread;

    CREATE TABLE #StdSpread
    WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS SELECT rs.InstrumentID,
                                                    DATEPART(MONTH, Date) AS Month,
                                                    YEAR(Date) Year,
                                                    STDEV(rs.Spread / Mid) StdSpreadPercent
                                             FROM #RawSpread rs
                                             GROUP BY rs.InstrumentID,
                                                      DATEPART(MONTH, Date),
                                                      YEAR(Date);
PRINT('#StdSpread')
    ----=============================================================================================
    IF OBJECT_ID('tempdb..#StdSpreadAvg') IS NOT NULL
        DROP TABLE #StdSpreadAvg;

    CREATE TABLE #StdSpreadAvg
    WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS SELECT InstrumentID,
                                                    AVG(StdSpreadPercent) StdSpreadPercent
                                             FROM #StdSpread
                                             GROUP BY InstrumentID;
PRINT('#StdSpreadAvg')
    ----=============================================================================================
	--DECLARE @Date DATE = '2023-02-13'
	-- DECLARE @NextDay DATE = DATEADD(DAY, 1, @Date);
    DECLARE @TOP INT;
    IF OBJECT_ID('tempdb..#Minutes') IS NOT NULL
        DROP TABLE #Minutes;
    CREATE TABLE #Minutes
    (
        FromDate DATETIME,
        ToDate DATETIME,
        Units DECIMAL(16, 6)
    )
    WITH (HEAP, DISTRIBUTION=ROUND_ROBIN);


    SELECT @TOP = DATEDIFF(MINUTE, @Date, @NextDay);

    INSERT INTO #Minutes
    SELECT DATEADD(MINUTE, (ROW_NUMBER() OVER (ORDER BY DateKey)) - 1, CAST(@Date AS DATETIME)) FromDate,
           DATEADD(MINUTE, (ROW_NUMBER() OVER (ORDER BY DateKey)), CAST(@Date AS DATETIME)) ToDate,
           0.0 Units
    FROM
    (SELECT TOP (@TOP) d1.* FROM DWH_dbo.Dim_Date d1, DWH_dbo.Dim_Date d2) t;

    --SELECT * FROM #Minutes ORDER BY 1
	PRINT('#Minutes')
    ----=============================================================================================
	--SELECT COUNT(*) FROM #Position
	--DECLARE @Date DATE = '2023-02-13';
    ---DECLARE @DateID INT = CONVERT(NVARCHAR, @Date, 112);
    IF OBJECT_ID('tempdb..#VolumeByMinute') IS NOT NULL
        DROP TABLE #VolumeByMinute;

    CREATE TABLE #VolumeByMinute
    WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS SELECT DATEADD(mi, DATEDIFF(mi, 0, OpenOccurred), 0) DateFrom,
                                                    DATEADD(MINUTE, 1, DATEADD(mi, DATEDIFF(mi, 0, OpenOccurred), 0)) DateTo,
                                                    dp.InstrumentID,
                                                    dp.HedgeServerID,
                                                    dp.IsSettled,
                                                    SUM(   CASE
                                                               WHEN dp.IsBuy = 1 THEN
                                                                   dp.AmountInUnitsDecimal
                                                               ELSE
                                                                   0
                                                           END
                                                       ) UnitsBuy,
                                                    SUM(   CASE
                                                               WHEN dp.IsBuy = 0 THEN
                                                                   dp.AmountInUnitsDecimal
                                                               ELSE
                                                                   0
                                                           END
                                                       ) UnitsSell,
                                                    SUM(   CASE
                                                               WHEN dp.IsBuy = 1 THEN
                                                                   dp.AmountInUnitsDecimal * dp.InitForexRate
                                                               ELSE
                                                                   0
                                                           END
                                                       ) "UnitsBuy*Price",
                                                    SUM(   CASE
                                                               WHEN dp.IsBuy = 0 THEN
                                                                   dp.AmountInUnitsDecimal * dp.InitForexRate
                                                               ELSE
                                                                   0
                                                           END
                                                       ) "UnitsSell*Price",
                                                    SUM(   CASE
                                                               WHEN dp.IsBuy = 1 THEN
                                                                   dp.Volume
                                                               ELSE
                                                                   0
                                                           END
                                                       ) VolumeBuy,
                                                    SUM(   CASE
                                                               WHEN dp.IsBuy = 0 THEN
                                                                   dp.Volume
                                                               ELSE
                                                                   0
                                                           END
                                                       ) VolumeSell,
                                                    SUM(dp.AmountInUnitsDecimal * (dp.InitForex_Ask - dp.InitForex_Bid)
                                                        * dp.InitForex_USDConversionRate
                                                       ) VariableSpread
                                             FROM #Position dp
                                                 JOIN #CID fsc
                                                     ON dp.CID = fsc.RealCID
                                                 JOIN #Ins i
                                                     ON i.InstrumentID = dp.InstrumentID
                                             WHERE fsc.DateKey = @DateID
                                                   AND dp.OpenDateID = @DateID
                                             GROUP BY DATEADD(mi, DATEDIFF(mi, 0, OpenOccurred), 0),
                                                      DATEADD(MINUTE, 1, DATEADD(mi, DATEDIFF(mi, 0, OpenOccurred), 0)),
                                                      dp.InstrumentID,
                                                      dp.HedgeServerID,
                                                      dp.IsSettled
                                             UNION ALL
                                             SELECT DATEADD(mi, DATEDIFF(mi, 0, CloseOccurred), 0) DateFrom,
                                                    DATEADD(MINUTE, 1, DATEADD(mi, DATEDIFF(mi, 0, CloseOccurred), 0)) DateTo,
                                                    dp.InstrumentID,
                                                    dp.HedgeServerID,
                                                    dp.IsSettled,
                                                    SUM(   CASE
                                                               WHEN dp.IsBuy = 0 THEN
                                                                   dp.AmountInUnitsDecimal
                                                               ELSE
                                                                   0
                                                           END
                                                       ) UnitsBuy,
                                                    SUM(   CASE
                                                               WHEN dp.IsBuy = 1 THEN
                                                                   dp.AmountInUnitsDecimal
                                                               ELSE
                                                                   0
                                                           END
                                                       ) UnitsSell,
                                                    SUM(   CASE
                                                               WHEN dp.IsBuy = 0 THEN
                                                                   dp.AmountInUnitsDecimal * dp.EndForexRate
                                                               ELSE
                                                                   0
                                                           END
                                                       ) "UnitsBuy*Price",
                                                    SUM(   CASE
                                                               WHEN dp.IsBuy = 1 THEN
                                                                   dp.AmountInUnitsDecimal * dp.EndForexRate
                                                               ELSE
                                                                   0
                                                           END
                                                       ) "UnitsSell*Price",
                                                    SUM(   CASE
                                                               WHEN dp.IsBuy = 0 THEN
                                                                   dp.VolumeOnClose
                                                               ELSE
                                                                   0
                                                           END
                                                       ) VolumeBuy,
                                                    SUM(   CASE
                                                               WHEN dp.IsBuy = 1 THEN
                                                                   dp.VolumeOnClose
                                                               ELSE
                                                                   0
                                                           END
                                                       ) VolumeSell,
                                                    SUM(dp.AmountInUnitsDecimal * (dp.EndForex_Ask - dp.EndForex_Bid)
                                                        * dp.LastOpConversionRate
                                                       ) VariableSpread
                                             FROM #Position dp
                                                 JOIN #CID fsc
                                                     ON dp.CID = fsc.RealCID
                                                 JOIN #Ins i
                                                     ON i.InstrumentID = dp.InstrumentID
                                             WHERE fsc.DateKey = @DateID
                                                   AND dp.CloseDateID = @DateID
                                             GROUP BY DATEADD(mi, DATEDIFF(mi, 0, CloseOccurred), 0),
                                                      DATEADD(MINUTE, 1, DATEADD(mi, DATEDIFF(mi, 0, CloseOccurred), 0)),
                                                      dp.InstrumentID,
                                                      dp.HedgeServerID,
                                                      dp.IsSettled;

PRINT('#VolumeByMinute')
    ----=============================================================================================

    IF OBJECT_ID('tempdb..#Sum') IS NOT NULL
        DROP TABLE #Sum;

    CREATE TABLE #Sum
    WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS SELECT DateTo,
                                                    InstrumentID,
                                                    HedgeServerID,
                                                    IsSettled,
                                                    SUM(UnitsBuy) UnitsBuy,
                                                    SUM(UnitsSell) UnitsSell,
                                                    SUM(bm.VolumeBuy) VolumeBuy,
                                                    SUM(bm.VolumeSell) VolumeSell,
                                                    CASE
                                                        WHEN SUM(UnitsBuy) > 0 THEN
                                                            SUM(bm.[UnitsBuy*Price]) / SUM(bm.UnitsBuy)
                                                        ELSE
                                                            0
                                                    END WAVG_BuyPrice,
                                                    CASE
                                                        WHEN SUM(UnitsSell) > 0 THEN
                                                            SUM(bm.[UnitsSell*Price]) / SUM(bm.UnitsSell)
                                                        ELSE
                                                            0
                                                    END WAVG_SellPrice,
                                                    SUM(bm.VariableSpread) VariableSpread
                                             INTO #Sum
                                             FROM #VolumeByMinute bm
                                             GROUP BY bm.DateTo,
                                                      InstrumentID,
                                                      bm.HedgeServerID,
                                                      bm.IsSettled;

													  PRINT('#Sum')
    ----=============================================================================================

    --IF OBJECT_ID('tempdb..#SumWithoutNulls_Temp') IS NOT NULL
    --    DROP TABLE #SumWithoutNulls_Temp;
    IF OBJECT_ID('tempdb..#SumWithoutNulls') IS NOT NULL
        DROP TABLE #SumWithoutNulls;

-----------------------------------------------------------------------------------------------------------
--Loop over to join each minute

--DROP TABLE IF EXISTS #SumWithoutNulls
CREATE TABLE #SumWithoutNulls([FromDate] DATETIME, ToDate DATETIME, InstrumentID INT, HedgeServerID INT, 
		IsSettled INT, UnitsBuy FLOAT, UnitsSell FLOAT, VolumeBuy INT, VolumeSell INT, WAVG_BuyPrice FLOAT, 
		WAVG_SellPrice FLOAT, VariableSpread FLOAT)
		  WITH (HEAP, DISTRIBUTION=ROUND_ROBIN)

--1 - Declare the Variables
DECLARE @HSID INT 
DECLARE @RealCFD INT 
DECLARE @InstrumentID INT
DECLARE @i INT=1
DECLARE @Max INT


	
IF OBJECT_ID('tempdb..#loop') IS NOT NULL
DROP TABLE #loop;

		  CREATE TABLE #loop
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS
SELECT ROW_NUMBER() OVER( ORDER BY  HedgeServerID) Rn , *
FROM 
	(SELECT DISTINCT HedgeServerID, IsSettled, InstrumentID FROM #Sum 
	UNION
	SELECT DISTINCT HedgeServerID, IsSettled, InstrumentID FROM #PreviousDayNOP pdn) t 


	
IF OBJECT_ID('tempdb..#Crossloop') IS NOT NULL
DROP TABLE #Crossloop;
	
CREATE TABLE #Crossloop
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS
SELECT * FROM 
#Minutes CROSS JOIN #loop

CREATE CLUSTERED INDEX CIX ON #Crossloop(ToDate,HedgeServerID,IsSettled,InstrumentID)

CREATE CLUSTERED INDEX CIX ON #Sum (DateTo,HedgeServerID,IsSettled,InstrumentID)

IF OBJECT_ID('tempdb..#SumWithoutNulls') IS NOT NULL
DROP TABLE #SumWithoutNulls;

CREATE TABLE #SumWithoutNulls
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

    SELECT
	    m.FromDate
		,m.ToDate
		,ISNULL(s.InstrumentID, m.InstrumentID) InstrumentID
		,ISNULL(s.HedgeServerID, m.HedgeServerID) AS HedgeServerID
		,ISNULL(s.IsSettled,m.IsSettled) AS IsSettled
		,ISNULL(UnitsBuy,0) UnitsBuy
		,ISNULL(UnitsSell,0) UnitsSell
		,ISNULL(s.VolumeBuy,0) VolumeBuy
		,ISNULL(s.VolumeSell,0) VolumeSell
		,ISNULL(WAVG_BuyPrice,0) WAVG_BuyPrice
		,ISNULL(WAVG_SellPrice,0) WAVG_SellPrice
		,ISNULL(s.VariableSpread,0) VariableSpread
	FROM #Crossloop m
	LEFT JOIN #Sum s ON m.ToDate=s.DateTo AND s.HedgeServerID = m.HedgeServerID 
	AND s.IsSettled = m.IsSettled AND s.InstrumentID = m.InstrumentID

/*
SELECT @Max = MAX(Rn) FROM #loop


WHILE @i<=@Max
BEGIN 

	SELECT 
		@HSID=HedgeServerID, 
		@RealCFD= IsSettled, 
		@InstrumentID = InstrumentID 
	FROM #loop WHERE Rn = @i 

	INSERT INTO #SumWithoutNulls 
	    SELECT m.FromDate
		,m.ToDate
		,ISNULL(s.InstrumentID, @InstrumentID) InstrumentID
		,ISNULL(s.HedgeServerID, @HSID) AS HedgeServerID
		,ISNULL(s.IsSettled,@RealCFD) AS IsSettled
		,ISNULL(UnitsBuy,0) UnitsBuy
		,ISNULL(UnitsSell,0) UnitsSell
		,ISNULL(s.VolumeBuy,0) VolumeBuy
		,ISNULL(s.VolumeSell,0) VolumeSell
		,ISNULL(WAVG_BuyPrice,0) WAVG_BuyPrice
		,ISNULL(WAVG_SellPrice,0) WAVG_SellPrice
		,ISNULL(s.VariableSpread,0) VariableSpread
	FROM #Minutes m
	LEFT JOIN #Sum s
	ON m.ToDate=s.DateTo AND s.HedgeServerID = @HSID AND s.IsSettled = @RealCFD AND s.InstrumentID = @InstrumentID

	SET @i = @i+1

END 
*/


/*

--
-- 2 - Declare Cursor

DECLARE db_cursor CURSOR FOR 
-- Populate the cursor with your logic
-- * UPDATE WITH YOUR SPECIFIC CODE HERE *

SELECT DISTINCT HedgeServerID, IsSettled, InstrumentID FROM #Sum 
UNION
SELECT DISTINCT HedgeServerID, IsSettled, InstrumentID FROM #PreviousDayNOP pdn
ORDER BY 1

-- Open the Cursor
OPEN db_cursor

-- 3 - Fetch the next record from the cursor
FETCH NEXT FROM db_cursor INTO @HSID, @RealCFD, @InstrumentID   
--PRINT @ID
-- Set the status for the cursor
WHILE @@FETCH_STATUS = 0  
 
BEGIN  
	
	-- 4 - Begin the custom business logic
	INSERT INTO #SumWithoutNulls 
	SELECT m.FromDate
		,m.ToDate
		,ISNULL(s.InstrumentID, @InstrumentID) InstrumentID
		,ISNULL(s.HedgeServerID, @HSID) AS HedgeServerID
		,ISNULL(s.IsSettled,@RealCFD) AS IsSettled
		,ISNULL(UnitsBuy,0) UnitsBuy
		,ISNULL(UnitsSell,0) UnitsSell
		,ISNULL(s.VolumeBuy,0) VolumeBuy
		,ISNULL(s.VolumeSell,0) VolumeSell
		,ISNULL(WAVG_BuyPrice,0) WAVG_BuyPrice
		,ISNULL(WAVG_SellPrice,0) WAVG_SellPrice
		,ISNULL(s.VariableSpread,0) VariableSpread
	FROM #Minutes m
	LEFT JOIN #Sum s
	ON m.ToDate=s.DateTo AND s.HedgeServerID = @HSID AND s.IsSettled = @RealCFD AND s.InstrumentID = @InstrumentID


	-- 5 - Fetch the next record from the cursor
 	FETCH NEXT FROM db_cursor INTO @HSID, @RealCFD, @InstrumentID 

END

-- 6 - Close the cursor
CLOSE db_cursor  

-- 7 - Deallocate the cursor
DEALLOCATE db_cursor
*/
--SELECT * FROM #SumWithoutNulls ORDER BY 1, 4
--SELECT * FROM #SumWithoutNulls ORDER BY 1, 4
-----------------------------------

    --CREATE TABLE #SumWithoutNulls
    --(
    --    [FromDate] DATETIME,
    --    ToDate DATETIME,
    --    InstrumentID INT,
    --    HedgeServerID INT,
    --    IsSettled INT,
    --    UnitsBuy FLOAT,
    --    UnitsSell FLOAT,
    --    VolumeBuy INT,
    --    VolumeSell INT,
    --    WAVG_BuyPrice FLOAT,
    --    WAVG_SellPrice FLOAT,
    --    VariableSpread FLOAT
    --);

    --WITH Hedge_List
    --AS (SELECT DISTINCT
    --           HedgeServerID,
    --           IsSettled,
    --           InstrumentID
    --    FROM #Sum
    --    UNION
    --    SELECT DISTINCT
    --           HedgeServerID,
    --           IsSettled,
    --           InstrumentID
    --    FROM #PreviousDayNOP pdn)
    --SELECT *
    --INTO #SumWithoutNulls_Temp
    --FROM Hedge_List,
    --     #Minutes;


    --INSERT INTO #SumWithoutNulls
    --SELECT m.FromDate,
    --       m.ToDate,
    --       ISNULL(s.InstrumentID, m.InstrumentID) InstrumentID,
    --       ISNULL(s.HedgeServerID, m.HedgeServerID) AS HedgeServerID,
    --       ISNULL(s.IsSettled, 0) AS IsSettled,
    --       ISNULL(UnitsBuy, 0) UnitsBuy,
    --       ISNULL(UnitsSell, 0) UnitsSell,
    --       ISNULL(s.VolumeBuy, 0) VolumeBuy,
    --       ISNULL(s.VolumeSell, 0) VolumeSell,
    --       ISNULL(WAVG_BuyPrice, 0) WAVG_BuyPrice,
    --       ISNULL(WAVG_SellPrice, 0) WAVG_SellPrice,
    --       ISNULL(s.VariableSpread, 0) VariableSpread
    --FROM #SumWithoutNulls_Temp m
    --    LEFT JOIN #Sum s
    --        ON m.ToDate = s.DateTo
    --           AND m.InstrumentID = s.InstrumentID
    --           AND m.HedgeServerID = s.HedgeServerID;
    --WHERE m.InstrumentID=17 AND ToDate='2021-11-01 00:02:00.000'

	PRINT('#SumWithoutNulls')
    ----=============================================================================================
	   --DECLARE @Date DATE = '2023-02-13';
    --DECLARE @DateID INT = CONVERT(NVARCHAR, @Date, 112);
    --DECLARE @PreviousDay DATE = DATEADD(DAY, -1, @Date);
    --DECLARE @PreviousDayID INT = CONVERT(NVARCHAR, @PreviousDay, 112);
    --DECLARE @NextDay DATE = DATEADD(DAY, 1, @Date);
    IF OBJECT_ID('tempdb..#RawPrices') IS NOT NULL
        DROP TABLE #RawPrices;

    CREATE TABLE #RawPrices
    (
        [InstrumentID] [INT] NULL,
        [Occurred] [DATETIME] NULL,
        [LastBid] [NUMERIC](16, 8) NULL,
        [LastAsk] [NUMERIC](16, 8) NULL,
        [LastBidSpreaded] [NUMERIC](16, 8) NULL,
        [LastAskSpreaded] [NUMERIC](16, 8) NULL,
        FromDate [DATETIME] NULL,
        ToDate [DATETIME] NULL,
        rn INT
    );

	DECLARE 
	@fromdate date=@Date,
	@todate date=@Date,
	@idate date ,
	@location varchar(500),
	@path varchar(1000)='/internal-sources/Bronze/PriceLog/History/CurrencyPrice/',

	@dest_table varchar(500)='BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp',
	@fullpath varchar(max) = '',
	@copysql varchar(max),
	@dropsql varchar(max)

	SELECT @location=
	SUBSTRING(location,CHARINDEX('@',location)+1,LEN(location))
	FROM sys.external_data_sources
	WHERE name = 'internal-sources'

	SELECT @idate=@fromdate

	IF OBJECT_ID(@dest_table) IS NOT NULL 
	BEGIN
	SELECT  @dropsql = CONCAT('DROP TABLE ',@dest_table,';')
	EXEC (@dropsql)
	END 

	WHILE @idate<=@todate
	BEGIN 

    SELECT @fullpath = @fullpath +
     ','''+CONCAT('https://',@location,@path,'etr_y=',year(@idate),'/etr_ym=',
       LEFT(CAST(@idate as varchar(10)),7),'/etr_ymd=',@idate)+''''

    SET @idate= dateadd(day,1,@idate)
 
	END 
	SET @fullpath =STUFF(@fullpath, 1, 1, '');

	SELECT @copysql 
		= CONCAT('COPY INTO ',@dest_table,' FROM ',@fullpath,
		' WITH (
			FILE_TYPE = ''PARQUET''
			,CREDENTIAL = (IDENTITY = ''Managed Identity'')
			,AUTO_CREATE_TABLE = ''ON''
		)')

--print @copysql
EXEC (@copysql)

    INSERT INTO #RawPrices
    (
        [InstrumentID],
        [Occurred],
        [LastBid],
        [LastAsk],
        [LastBidSpreaded],
        [LastAskSpreaded],
        FromDate,
        ToDate,
        rn
    )
	Select *
	from (
    SELECT InstrumentID,
           Occurred,
           Bid LastBid,
           Ask LastAsk,
           BidSpreaded LastBidSpreaded,
           AskSpreaded LastAskSpreaded,
           DATEADD(mi, DATEDIFF(mi, 0, Occurred), 0) FromDate,
           DATEADD(MINUTE, 1, DATEADD(mi, DATEDIFF(mi, 0, Occurred), 0)) ToDate,
           ROW_NUMBER() OVER (PARTITION BY DATEADD(mi, DATEDIFF(mi, 0, Occurred), 0),
                                           InstrumentID
                              ORDER BY Occurred DESC
                             ) rn
    FROM BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp
		  ) a
		  where rn=1;

		  PRINT('#RawPrices')
    ----=============================================================================================
    IF OBJECT_ID('tempdb..#FinalPrices') IS NOT NULL
        DROP TABLE #FinalPrices;

    SELECT m.FromDate,
           m.ToDate,
           rp.InstrumentID,
           i.InstrumentName,
           i.InstrumentType,
           i.InstrumentTypeID,
           --	  ,i.BuyCurrencyID
           --	  ,i.SellCurrencyID
           rp.LastBid,
           rp.LastAsk,
           (rp.LastAsk + rp.LastBid) / 2 AS Mid,
           rp.LastBidSpreaded,
           rp.LastAskSpreaded
    INTO #FinalPrices
    FROM #Minutes m
        LEFT JOIN #RawPrices rp
            ON m.ToDate = rp.ToDate
        JOIN #Ins i
            ON rp.InstrumentID = i.InstrumentID;

PRINT('#FinalPrices')
    ----=============================================================================================
    IF OBJECT_ID('tempdb..#Rates') IS NOT NULL
        DROP TABLE #Rates;

    SELECT fcpws.OccurredDateID,
           di.InstrumentID,
           di.BuyCurrencyID,
           di.SellCurrencyID,
           fcpws.Bid,
           fcpws.Ask
    INTO #Rates
    FROM [DWH_dbo].[Fact_CurrencyPriceWithSplit] fcpws
        JOIN [DWH_dbo].[Dim_Instrument] di
            ON fcpws.InstrumentID = di.InstrumentID
    WHERE fcpws.OccurredDateID = @DateID;
PRINT('#Rates')
    ----=============================================================================================
    IF OBJECT_ID('tempdb..#FX_Rates') IS NOT NULL
        DROP TABLE #FX_Rates;

    SELECT di.InstrumentID,
           di.InstrumentName,
           di.SellCurrencyID,
           CASE
               WHEN di.SellCurrencyID = 1 THEN
                   1
               WHEN di.BuyCurrencyID = 1 THEN
                   1 / r.Bid
               WHEN di.SellCurrencyID <> 1
                    AND di.BuyCurrencyID <> 1 THEN
                   COALESCE(1 / r1.Bid, r2.Bid, 1)
           END FX_Bid
    INTO #FX_Rates
    FROM #Ins di
        LEFT JOIN #Rates r
            ON di.SellCurrencyID = r.SellCurrencyID
               AND di.BuyCurrencyID = r.BuyCurrencyID
        LEFT JOIN #Rates r1
            ON di.SellCurrencyID = r1.SellCurrencyID
               AND r1.BuyCurrencyID = 1
               AND di.BuyCurrencyID <> 1
        LEFT JOIN #Rates r2
            ON di.SellCurrencyID = r2.BuyCurrencyID
               AND r2.SellCurrencyID = 1
               AND di.SellCurrencyID <> 1;

PRINT('#FX_Rates')
----=============================================================================================


  IF OBJECT_ID('tempdb..#Boundaries') IS NOT NULL
        DROP TABLE #Boundaries;
		
CREATE TABLE #Boundaries
	(InstrumentID INT
	,HedgeServerID INT
	,LowerBoundary DECIMAL(16,4)
	,UpperBoundary DECIMAL(16,4)
	,HedgeRiskLimit DECIMAL(16,4))

INSERT INTO tempdb..#Boundaries
SELECT ib.InstrumentID
		,ib.HedgeServerID
		,(-1)*(CloseThresholdPercentage*OpenThresholdUSD)/100 AS LowerBoundary
		,OpenThresholdUSD AS UpperBoundary
		,HedgeRiskLimitUSD AS HedgeRiskLimit
FROM [dbo].[etoro_Hedge_InstrumentBoundaries] ib
JOIN #Ins i
ON ib.InstrumentID = i.InstrumentID;

PRINT('#Boundaries')
----=============================================================================================

----------------------
-- Check if positions have been moved from HS to HS
----------------------

-- Determine the actual amount of units at the time the position was moved to a different HS (in case of partial closes)

 IF OBJECT_ID('tempdb..#Position_ChangeLog_Units') IS NOT NULL
        DROP TABLE #Position_ChangeLog_Units;

SELECT pcl.PositionID
		,p.OpenOccurred
		,pcl.Occurred Change_Occurred
		,p.CloseOccurred
		,pcl.PreviousAmountInUnits
		,pcl.AmountInUnits
		,ROW_NUMBER() OVER (PARTITION BY pcl.PositionID ORDER BY pcl.Occurred ASC) rn_FirstChange
		,ROW_NUMBER() OVER (PARTITION BY pcl.PositionID ORDER BY pcl.Occurred DESC) rn_LastChange
		,CASE WHEN p.OpenDateID = @DateID AND p.CloseDateID <> @DateID THEN 'Open'
				WHEN p.OpenDateID <> @DateID AND p.CloseDateID = @DateID THEN 'Close'
				WHEN p.OpenDateID = @DateID AND p.CloseDateID = @DateID THEN 'Open/Close' END OpenClose
INTO #Position_ChangeLog_Units
FROM DWH_dbo.Dim_PositionChangeLog pcl WITH (NOLOCK)
JOIN #Position p
ON p.PositionID = pcl.PositionID AND (p.OpenDateID = @DateID OR p.CloseDateID = @DateID)
WHERE ChangeTypeID = 12;


 IF OBJECT_ID('tempdb..#Position_ChangeLog_Units_1') IS NOT NULL
        DROP TABLE #Position_ChangeLog_Units_1;

SELECT pclu.PositionID
	  ,pclu.OpenOccurred
	  ,pclu.Change_Occurred
	  ,pclu.CloseOccurred
	  ,pclu.PreviousAmountInUnits
	  ,pclu.AmountInUnits
	  ,pclu1.Change_Occurred AS FirstChange
	  ,pclu2.Change_Occurred AS LastChange
	  ,pclu1.PreviousAmountInUnits AS InitialUnits
	  ,pclu2.AmountInUnits AS LatestUnits
	  ,pclu.OpenClose
INTO #Position_ChangeLog_Units_1
FROM #Position_ChangeLog_Units pclu
INNER JOIN #Position_ChangeLog_Units pclu1
ON pclu.PositionID = pclu1.PositionID AND pclu1.rn_FirstChange = 1
INNER JOIN #Position_ChangeLog_Units pclu2
ON pclu.PositionID = pclu2.PositionID AND pclu2.rn_LastChange = 1
--WHERE pclu.PositionID = 2204050442
;

--SELECT * FROM #Position_ChangeLog_Units_1 pclu
--SELECT * FROM [AZR-W-REAL-DB-2-BIDBUser].etoro.Trade.Change
PRINT('#Position_ChangeLog_Units')
--==================================================================================


 IF OBJECT_ID('tempdb..#Historical_Units') IS NOT NULL
        DROP TABLE #Historical_Units;

SELECT cl.PositionID
		,OpenOccurred AS FromDate
		,@NextDay AS ToDate
		,cl.InitialUnits AS Units
INTO #Historical_Units
FROM #Position_ChangeLog_Units_1 cl
WHERE cl.OpenClose = 'Open' AND FirstChange > @NextDay

UNION

SELECT pclu.PositionID
		,pclu.OpenOccurred AS FromDate
		,pclu.FirstChange ToDate
		,pclu.PreviousAmountInUnits AS Units
FROM #Position_ChangeLog_Units_1 pclu
WHERE pclu.OpenClose = 'Open' AND FirstChange <= @NextDay AND pclu.FirstChange = pclu.Change_Occurred

UNION 

SELECT pclu.PositionID
		,pclu.Change_Occurred FromDate
		,ISNULL(LEAD(pclu.Change_Occurred) OVER (PARTITION BY pclu.PositionID ORDER BY pclu.Change_Occurred ASC),@NextDay) ToDate
		,pclu.AmountInUnits Units
FROM #Position_ChangeLog_Units_1 pclu
WHERE pclu.OpenClose = 'Open' AND FirstChange <= @NextDay

UNION 

SELECT pclu.PositionID
		,@Date FromDate
		,pclu.FirstChange ToDate
		,pclu.PreviousAmountInUnits Units
FROM #Position_ChangeLog_Units_1 pclu
WHERE pclu.OpenClose = 'Close' AND FirstChange >= @Date AND pclu.Change_Occurred = pclu.FirstChange

UNION

SELECT pclu.PositionID
		,pclu.Change_Occurred FromDate
		,ISNULL(LEAD(pclu.Change_Occurred) OVER (PARTITION BY pclu.PositionID ORDER BY pclu.Change_Occurred ASC),@NextDay) ToDate
		,pclu.AmountInUnits Units
FROM #Position_ChangeLog_Units_1 pclu
WHERE pclu.OpenClose = 'Close' AND FirstChange >= @Date

UNION 

SELECT pclu.PositionID
		,@Date FromDate
		,pclu.Change_Occurred ToDate
		,ISNULL(pclu.PreviousAmountInUnits,pclu.LatestUnits) Units
FROM #Position_ChangeLog_Units_1 pclu
WHERE pclu.OpenClose = 'Close' AND FirstChange < @Date 
	AND pclu.Change_Occurred = ISNULL((SELECT MIN(Change_Occurred) FROM #Position_ChangeLog_Units_1 pclu1 WHERE pclu1.PositionID = pclu.PositionID AND pclu1.Change_Occurred>=@Date),@NextDay)

UNION

SELECT pclu.PositionID
		,pclu.Change_Occurred FromDate
		,ISNULL(LEAD(pclu.Change_Occurred) OVER (PARTITION BY pclu.PositionID ORDER BY pclu.Change_Occurred ASC),pclu.CloseOccurred) ToDate
		,pclu.AmountInUnits Units
FROM #Position_ChangeLog_Units_1 pclu
WHERE pclu.OpenClose = 'Open/Close' 

UNION

SELECT pclu.PositionID
		,pclu.OpenOccurred AS FromDate
		,pclu.FirstChange AS ToDate
		,pclu.PreviousAmountInUnits AS Units
FROM #Position_ChangeLog_Units_1 pclu
WHERE pclu.OpenClose = 'Open/Close' AND pclu.Change_Occurred = pclu.FirstChange

UNION

SELECT pclu.PositionID
		,@Date AS FromDate
		,pclu.CloseOccurred AS ToDate
		,pclu.LatestUnits AS Units
FROM #Position_ChangeLog_Units_1 pclu
WHERE pclu.OpenClose = 'Close' AND pclu.FirstChange < @Date;


--SELECT * FROM #Historical_Units hu
PRINT('#Historical_Units')
--============================================================================

-- Determine which positions were moved to a different HS on @Date

 IF OBJECT_ID('tempdb..#PositionHS_ChangeLog') IS NOT NULL
        DROP TABLE #PositionHS_ChangeLog;

SELECT cl.PositionID
		,ISNULL(p.InstrumentID,pdpp.InstrumentID) InstrumentID
		,ISNULL(p.IsSettled,pdpp.IsSettled) IsSettled
		,(2*ISNULL(p.IsBuy,pdpp.IsBuy)-1)*COALESCE(hu.Units,p.AmountInUnitsDecimal,pdpp.AmountInUnitsDecimal) AS NetUnits
		,DATEADD(mi,datediff(mi,0,ADM_DATE),0) FromDate
		,DATEADD(MINUTE,1,DATEADD(mi,DATEDIFF(mi,0,ADM_DATE),0)) ToDate
		,FromHedgeServerID
		,ToHedgeServerID
INTO #PositionHS_ChangeLog
FROM DWH_dbo.etoro_Trade_PositionsHedgeServerChangeLog cl
LEFT JOIN #Position p
ON cl.PositionID = p.PositionID
LEFT JOIN #PreviousDayPerPos pdpp
ON cl.PositionID = pdpp.PositionID
LEFT JOIN #Historical_Units hu
ON cl.PositionID = hu.PositionID AND cl.ADM_DATE BETWEEN hu.FromDate AND ToDate
WHERE ADM_DATE >= CAST(@Date AS DATETIME) AND ADM_DATE <DATEADD(DAY,1,CAST(@Date AS DATETIME));

--SELECT * FROM #PositionHS_ChangeLog phcl where InstrumentID is null

--SELECT TOP 10* FROM DWH_dbo.etoro_Trade_PositionsHedgeServerChangeLog WHERE PositionID = 850628056
--SELECT TOP 10* FROM DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot WHERE PositionID = 850628056 ORDER BY 3
PRINT('#PositionHS_ChangeLog')
--=====================================================================

 IF OBJECT_ID('tempdb..#HS_Change_List') IS NOT NULL
        DROP TABLE #HS_Change_List;

SELECT DISTINCT phcl.FromHedgeServerID HedgeServerID -- List of HS in which occurred a transfer of positions
INTO #HS_Change_List
FROM #PositionHS_ChangeLog phcl

UNION

SELECT DISTINCT phcl.ToHedgeServerID
FROM #PositionHS_ChangeLog phcl;

--SELECT * FROM #HS_Change_List hcl order by 1
PRINT('#HS_Change_List')
--=====================================================================

 IF OBJECT_ID('tempdb..#HS_Moved_Units') IS NOT NULL
        DROP TABLE #HS_Moved_Units;

SELECT cl.InstrumentID
		,cl.FromDate
		,cl.ToDate
		,hs.HedgeServerID
		,cl.IsSettled
		,SUM(CASE WHEN hs.HedgeServerID = cl.FromHedgeServerID THEN -cl.NetUnits ELSE cl.NetUnits END) UnitsMoved -- the number of units added to/removed from this HS during this minute
INTO #HS_Moved_Units
FROM #HS_Change_List hs
LEFT JOIN #PositionHS_ChangeLog cl
ON cl.FromHedgeServerID = hs.HedgeServerID or cl.ToHedgeServerID = hs.HedgeServerID
GROUP BY cl.FromDate
		,cl.ToDate
		,hs.HedgeServerID
		,cl.InstrumentID
		,cl.IsSettled;

--SELECT * FROM #HS_Moved_Units hmu order by InstrumentID
PRINT('#HS_Moved_Units')
--=============================================================================

 IF OBJECT_ID('tempdb..#First_Occurrence') IS NOT NULL
        DROP TABLE #First_Occurrence;

SELECT a.FromDate -- Units moved during the night / before the first trade
	  ,a.ToDate
	  ,a.InstrumentID
	  ,a.HedgeServerID
	  ,a.IsSettled
	  ,SUM(CASE WHEN hmu.FromDate <= a.FromDate THEN hmu.UnitsMoved ELSE 0 END) UnitsMoved_BeforeStart
INTO #First_Occurrence
FROM (SELECT swn.FromDate
			,swn.ToDate
			,swn.InstrumentID
			,swn.HedgeServerID
			,swn.IsSettled
			,ROW_NUMBER() OVER (PARTITION BY swn.InstrumentID, swn.HedgeServerID, swn.IsSettled ORDER BY swn.FromDate ASC) rn
		FROM #SumWithoutNulls swn
		WHERE swn.UnitsBuy <> 0 OR swn.UnitsSell <> 0) a
LEFT JOIN #HS_Moved_Units hmu
ON a.InstrumentID = hmu.InstrumentID AND a.HedgeServerID = hmu.HedgeServerID AND a.IsSettled = hmu.IsSettled
WHERE rn = 1
GROUP BY a.FromDate
	  ,a.ToDate
	  ,a.InstrumentID
	  ,a.HedgeServerID
	  ,a.IsSettled;

--SELECT * FROM #First_Occurrence fo where InstrumentID = 5990
PRINT('#First_Occurrence')
--=========================================================================

IF OBJECT_ID('tempdb..#HS_Moved_Units_Final') IS NOT NULL
        DROP TABLE #HS_Moved_Units_Final;

SELECT fo.FromDate
	  ,fo.ToDate
	  ,fo.InstrumentID
	  ,fo.HedgeServerID
	  ,fo.IsSettled
	  ,ISNULL(fo.UnitsMoved_BeforeStart,0) AS UnitsMoved
INTO #HS_Moved_Units_Final
FROM #First_Occurrence fo

UNION ALL

SELECT mu.FromDate
	  ,mu.ToDate
	  ,mu.InstrumentID
	  ,mu.HedgeServerID
	  ,mu.IsSettled
	  ,mu.UnitsMoved
FROM #HS_Moved_Units mu
LEFT JOIN #First_Occurrence fo
ON mu.FromDate = fo.FromDate AND mu.InstrumentID = fo.InstrumentID AND mu.HedgeServerID = fo.HedgeServerID AND mu.IsSettled = fo.IsSettled
WHERE COALESCE(fo.FromDate,fo.InstrumentID,fo.HedgeServerID,fo.IsSettled) IS NULL -- don't pull the first occurrence
AND fo.FromDate <= mu.FromDate;

--SELECT * FROM #HS_Moved_Units_Final hmuf where InstrumentID = 5990
PRINT('#HS_Moved_Units_Final')

--=========================================================================


IF OBJECT_ID('tempdb..#HS_Moved_Units_NoTrades') IS NOT NULL
        DROP TABLE #HS_Moved_Units_NoTrades;
 -- case when all remaining units were moved out of a HS and no trades happened on this day for this HS/instrument/IsSettled
SELECT hmu.* 
INTO #HS_Moved_Units_NoTrades
FROM #HS_Moved_Units hmu
LEFT JOIN #SumWithoutNulls swn
ON hmu.InstrumentID = swn.InstrumentID AND hmu.HedgeServerID = swn.HedgeServerID AND hmu.IsSettled = swn.IsSettled
WHERE swn.FromDate IS NULL AND hmu.InstrumentID IS NOT NULL

UNION

SELECT mu.*
FROM #HS_Moved_Units mu
WHERE (SELECT SUM(swn.UnitsBuy) FROM #SumWithoutNulls swn WHERE swn.InstrumentID = mu.InstrumentID AND swn.HedgeServerID = mu.HedgeServerID AND  swn.IsSettled = mu.IsSettled) = 0
AND (SELECT SUM(swn.UnitsSell) FROM #SumWithoutNulls swn WHERE swn.InstrumentID = mu.InstrumentID AND swn.HedgeServerID = mu.HedgeServerID AND  swn.IsSettled = mu.IsSettled) = 0;

--SELECT * FROM #SumWithoutNulls hmunt WHERE InstrumentID = 6212 AND HedgeServerID = 112 AND IsSettled = 1

PRINT('#HS_Moved_Units_NoTrades')
----=============================================================================================

DELETE FROM [Dealing_dbo].[Dealing_Boundary_Cost] WHERE Date = @Date

INSERT INTO [Dealing_dbo].[Dealing_Boundary_Cost] 
		(Date
		,DateID
		,FromDate
		,ToDate
		,InstrumentID
		,InstrumentName
		,InstrumentType
		,StdSpreadPercent
		,LastBid
		,LastAsk
		,Mid
		,LastBidSpreaded
		,LastAskSpreaded
		,UnitsBuy
		,UnitsSell
		,WAVG_BuyPrice
		,WAVG_SellPrice
		,NOP
		,UpdateDate
		,VolumeBuy
		,VolumeSell
		,VariableSpread
		,LowerBoundary
		,UpperBoundary
		,HedgeRiskLimit
		,FX_Bid
		,InstrumentTypeID
		,HedgeServerID
		,IsSettled
		,PriceRatio
		,HS_Moved_Units
)


SELECT  @Date
		,@DateID
		,fp.FromDate
		,fp.ToDate
	  	,fp.InstrumentID
		,fp.InstrumentName
		,fp.InstrumentType
		,StdSpreadPercent
	  ,fp.LastBid
	  ,fp.LastAsk
	  ,fp.Mid
	  ,fp.LastBidSpreaded
	  ,fp.LastAskSpreaded
	  ,ISNULL(rs.UnitsBuy,0) UnitsBuy
	  ,ISNULL(rs.UnitsSell,0) UnitsSell
	  ,ISNULL(rs.WAVG_BuyPrice,0) WAVG_BuyPrice
	  ,ISNULL(rs.WAVG_SellPrice,0) WAVG_SellPrice
      ,ISNULL(nop.Units,0) + SUM(ISNULL(rs.UnitsBuy,0) - ISNULL(rs.UnitsSell,0)) OVER (PARTITION BY rs.InstrumentID, rs.HedgeServerID, rs.IsSettled ORDER BY rs.ToDate) AS NOP
	  ,GETDATE() AS UpdateDate
	  ,ISNULL(rs.VolumeBuy,0) VolumeBuy
	  ,ISNULL(rs.VolumeSell,0) VolumeSell
	  ,ISNULL(rs.VariableSpread,0) VariableSpread
	  ,CASE WHEN fp.InstrumentTypeID IN (5,6) then ISNULL(b.LowerBoundary,-50000.0000) ELSE b.LowerBoundary END LowerBoundary -- default value when there is no boundary
	  ,CASE WHEN fp.InstrumentTypeID IN (5,6) then ISNULL(b.UpperBoundary, 500000.0000) ELSE b.UpperBoundary END UpperBoundary
	  ,CASE WHEN fp.InstrumentTypeID IN (5,6) then ISNULL(b.HedgeRiskLimit,250000.0000) ELSE b.HedgeRiskLimit END HedgeRiskLimit
	  ,fr.FX_Bid
	  ,fp.InstrumentTypeID
	  ,ISNULL(rs.HedgeServerID,nop.HedgeServerID) AS HedgeServerID
	  ,ISNULL(rs.IsSettled,nop.IsSettled) AS IsSettled
		,CASE WHEN ROW_NUMBER() OVER (PARTITION BY fp.InstrumentID,ISNULL(rs.HedgeServerID,nop.HedgeServerID),ISNULL(rs.IsSettled,nop.IsSettled) ORDER BY fp.FromDate ASC) = 1 THEN ISNULL(sr.PriceRatio,1) ELSE 1 END PriceRatio
		,ISNULL(mu.UnitsMoved,0) as HS_Moved_Units
FROM #FinalPrices fp 
LEFT JOIN #SumWithoutNulls rs
ON rs.ToDate = fp.ToDate AND rs.InstrumentID = fp.InstrumentID
LEFT JOIN #PreviousDayNOP nop
ON fp.InstrumentID = nop.InstrumentID AND rs.HedgeServerID = nop.HedgeServerID AND rs.IsSettled = nop.IsSettled
LEFT JOIN #StdSpreadAvg s
ON fp.InstrumentID = s.InstrumentID
LEFT JOIN #Boundaries b
ON fp.InstrumentID = b.InstrumentID AND b.HedgeServerID = ISNULL(rs.HedgeServerID,nop.HedgeServerID)
LEFT JOIN #FX_Rates fr
ON fp.InstrumentID = fr.InstrumentID -- and fp.ToDate = fr.ToDate 
LEFT JOIN DWH_dbo.Dim_HistorySplitRatio sr WITH (NOLOCK)
ON fp.InstrumentID = sr.InstrumentID AND CONVERT(NVARCHAR, sr.MaxDate, 112) = @DateID
LEFT JOIN #HS_Moved_Units_Final mu
ON fp.InstrumentID = mu.InstrumentID AND fp.FromDate = mu.FromDate AND ISNULL(rs.HedgeServerID,nop.HedgeServerID) = mu.HedgeServerID AND ISNULL(rs.IsSettled,nop.IsSettled) = mu.IsSettled

UNION ALL -- Additional rows in the case when all units were moved out of a HS and no trades happened on this day for this HS/Instrument/IsSettled

SELECT @Date
		,@DateID
		,mu.FromDate
		,mu.ToDate
		,mu.InstrumentID
		,ISNULL(fp.InstrumentName,fp1.InstrumentName) InstrumentName
		,ISNULL(fp.InstrumentType, fp1.InstrumentType) InstrumentType
		,NULL
		,ISNULL(fp.LastBid,fp1.LastBid) LastBid
		,ISNULL(fp.LastAsk,fp1.LastAsk) LastAsk
		,ISNULL(fp.Mid,fp1.Mid) LastBid
		,ISNULL(fp.LastBidSpreaded,fp1.LastBidSpreaded) LastBidSpreaded
		,ISNULL(fp.LastAskSpreaded,fp1.LastAskSpreaded) LastAskSpreaded
		,0
		,0
		,NULL
		,NULL
		,0 AS NOP
		,GETDATE()
		,0
		,0
		,NULL
		,NULL 
		,NULL
		,NULL
		,fr.FX_Bid
		,ISNULL(fp.InstrumentTypeID,fp1.InstrumentTypeID) InstrumentTypeID
		,mu.HedgeServerID
		,mu.IsSettled
		,ISNULL(sr.PriceRatio,1) PriceRatio
		,mu.UnitsMoved
FROM #HS_Moved_Units_NoTrades mu
LEFT JOIN #FinalPrices fp
ON mu.InstrumentID = fp.InstrumentID AND fp.FromDate = mu.FromDate AND fp.FromDate IS NOT NULL
LEFT JOIN #FinalPrices fp1
ON mu.InstrumentID = fp1.InstrumentID AND fp1.FromDate = (SELECT MIN(fp2.FromDate) FROM #FinalPrices fp2 WHERE fp2.InstrumentID = mu.InstrumentID)
LEFT JOIN #FX_Rates fr
ON mu.InstrumentID = fr.InstrumentID
LEFT JOIN DWH_dbo.Dim_HistorySplitRatio sr WITH (NOLOCK)
ON fp.InstrumentID = sr.InstrumentID AND CONVERT(NVARCHAR, sr.MaxDate, 112) = @DateID

----=============================================================================================

--SELECT TOP 3 * FROM #Ins
--SELECT TOP 3 * FROM #CID
--SELECT TOP 3 * FROM #Position
--SELECT TOP 3 * FROM #PreviousDayNOP
--SELECT TOP 3 * FROM #RawSpread
--SELECT TOP 3 * FROM #StdSpread
--SELECT TOP 3 * FROM #StdSpreadAvg
--SELECT TOP 3 * FROM #Minutes
--SELECT TOP 3 * FROM #VolumeByMinute
--SELECT * FROM #SumWithoutNulls 
-- WHERE InstrumentID=
--17 AND ToDate='2021-11-01 00:02:00.000'


-- [Dealing_dbo].[SP_Boundary_Cost]

END;

GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `Dealing_dbo.SP_Boundary_Cost` | synapse_sp | Dealing_dbo | SP_Boundary_Cost | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_Boundary_Cost.sql` |
| `DWH_dbo.Dim_Instrument` | synapse | DWH_dbo | Dim_Instrument | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `DWH_dbo.Dim_Position` | synapse | DWH_dbo | Dim_Position | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md` |
| `BI_DB_staging.PriceLog_History_CurrencyPrice_Active_tmp` | unresolved | BI_DB_staging | PriceLog_History_CurrencyPrice_Active_tmp | `—` |
| `dbo.etoro_Hedge_InstrumentBoundaries` | unresolved | dbo | etoro_Hedge_InstrumentBoundaries | `—` |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | synapse | DWH_dbo | Fact_CurrencyPriceWithSplit | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md` |
| `DWH_dbo.Dim_HistorySplitRatio` | synapse | DWH_dbo | Dim_HistorySplitRatio | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_HistorySplitRatio.md` |
| `DWH_dbo.Dim_PositionChangeLog` | synapse | DWH_dbo | Dim_PositionChangeLog | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PositionChangeLog.md` |
| `DWH_dbo.Fact_SnapshotCustomer` | synapse | DWH_dbo | Fact_SnapshotCustomer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_SnapshotCustomer.md` |
| `DWH_dbo.Dim_Range` | synapse | DWH_dbo | Dim_Range | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `DWH_dbo.Dim_Date` | unresolved | DWH_dbo | Dim_Date | `—` |
| `DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot` | synapse | DWH_dbo | Dim_PositionHedgeServerChangeLog_Snapshot | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PositionHedgeServerChangeLog_Snapshot.md` |
| `BI_DB_dbo.BI_DB_PositionPnL` | synapse | BI_DB_dbo | BI_DB_PositionPnL | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_PositionPnL.md` |
| `sys.external_data_sources` | unresolved | sys | external_data_sources | `—` |
| `DWH_dbo.etoro_Trade_PositionsHedgeServerChangeLog` | unresolved | DWH_dbo | etoro_Trade_PositionsHedgeServerChangeLog | `—` |
