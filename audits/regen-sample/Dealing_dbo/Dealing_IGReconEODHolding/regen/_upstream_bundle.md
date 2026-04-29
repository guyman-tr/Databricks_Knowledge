# Pre-Resolved Upstream Bundle for `Dealing_dbo.Dealing_IGReconEODHolding`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `Dealing_dbo.Dealing_IGReconEODHolding.sql`

```sql
CREATE TABLE [Dealing_dbo].[Dealing_IGReconEODHolding]
(
	[Date] [date] NULL,
	[HedgeServerID] [int] NULL,
	[Account_Number] [varchar](50) NULL,
	[InstrumentID] [int] NULL,
	[InstrumentDisplayName] [varchar](100) NULL,
	[Symbol] [varchar](250) NULL,
	[ISINCode] [varchar](30) NULL,
	[CurrencyPrimary] [varchar](50) NULL,
	[Exchange] [varchar](80) NULL,
	[IG_Units] [decimal](16, 6) NULL,
	[eToro_Units] [decimal](16, 6) NULL,
	[Clients_Units] [decimal](16, 6) NULL,
	[IG-eToro_Units] [decimal](16, 6) NULL,
	[IG-Clients_Units] [decimal](16, 6) NULL,
	[IG_LocalAmount] [money] NULL,
	[eToro_LocalAmount] [money] NULL,
	[IG-eToro_LocalAmount] [money] NULL,
	[IG_AmountUSD] [money] NULL,
	[eToro_AmountUSD] [money] NULL,
	[Clients_AmountUSD] [money] NULL,
	[IG-eToro_AmountUSD] [money] NULL,
	[IG-Clients_AmountUSD] [money] NULL,
	[IG_Rate] [decimal](16, 6) NULL,
	[eToro_Rate] [decimal](16, 6) NULL,
	[IG-eToro_Rate] [decimal](16, 6) NULL,
	[IG_FXRate] [decimal](16, 6) NULL,
	[eToro_FXRate] [decimal](16, 6) NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[Date] ASC
	)
)

GO

```

---

## Upstream Wikis Found

Found 4 upstream wiki(s). Read EACH one in full.


### Upstream `Dealing_dbo.Dealing_Duco_EODRecon` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_Duco_EODRecon`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Duco_EODRecon.md`

# Dealing_dbo.Dealing_Duco_EODRecon

## 1. Overview

**Daily end-of-day reconciliation** between eToro's LP (liquidity provider) hedge holdings and client NOP (net open position). Each row compares what eToro's hedge servers hold at EOD for a given liquidity account and instrument versus what the aggregated client position demands, expressed in units and USD amounts. The table is the **primary foundation for all LP broker reconciliation pipelines** — 11+ downstream recon tables (Apex, GS, IB, IG, JPM, SAXO, VISION, BNY VIRTU, CloseOnly) depend on it.

**Row grain**: `Date` + `LiquidityAccountID` + `InstrumentID` + `Buy/Sell` direction.

---

## 2. Business Context

`SP_DataForDuco` (Author: Jenia 2021-10-25, many updates through 2025-08-07) is the shared writer for both `Dealing_Duco_EODRecon` (EOD holdings) and `Dealing_Duco_ActivityRecon` (trade activity). The SP does not run on weekends.

**EOD reconciliation logic**: The SP performs a **FULL OUTER JOIN** between eToro's hedge netting (LP holdings from `Dealing_staging.etoro_Hedge_Netting` + `etoro_History_Netting_History`) and client NOP (from `BI_DB_dbo.BI_DB_PositionPnL`), resolving the latest netting row per (server, instrument) via ROW_NUMBER dedup. The result shows the EOD hedge position vs the client position for each instrument.

**LP side sourcing**: Uses the SCD2 netting history table (`etoro_History_Netting_History` with SysStartTime/SysEndTime) unioned with current state (`etoro_Hedge_Netting`) — the combined set is deduplicated to the latest row per (HedgeServerID, InstrumentID).

**Client side sourcing**: `BI_DB_PositionPnL` aggregates client NOP using the (2*IsBuy-1) sign convention, joined to `Fact_CurrencyPriceWithSplit` for USD conversion.

**Key business rules**:

- **Weekends excluded**: SP skips Sat/Sun — no data is generated for those dates.
- **HedgingPercent**: `eToro_Units / ClientUnits` — the ratio showing how much of the client position is hedged.
- **MKTcap**: Market capitalization from an external reference, used by downstream to size reconciliation thresholds.
- **CUSIP**: US security identifier from the LP file, used for broker-side matching.
- **Buy/Sell direction** is derived from the net units direction (positive = Buy, negative = Sell).
- **DELETE-INSERT by date**: Idempotent daily reload.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 27 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

Read-only checks executed **2026-03-21**.

| Check | Result |
|--------|--------|
| **Row count** | ~22,600,000 |
| **Date range** | Active and current (daily refresh confirmed, weekdays only) |
| **Recent sample** | Rows for 2026-03-20 with multiple LiquidityAccountID values |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Report date (EOD reconciliation date). (Tier 2 -- SP_DataForDuco, @Date) |
| 2 | LiquidityAccountID | int | YES | LP account identifier from etoro_Trade_LiquidityAccounts. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Trade_LiquidityAccounts.LiquidityAccountID) |
| 3 | LiquidityAccountName | varchar(max) | YES | LP account display name. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Trade_LiquidityAccounts.LiquidityAccountName) |
| 4 | HedgeServerID | int | YES | Hedge server identifier associated with the LP position. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Hedge_Netting.HedgeServerID) |
| 5 | InstrumentID | int | YES | eToro instrument identifier. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.InstrumentID) |
| 6 | ISINCode | varchar(max) | YES | ISIN code from LP netting or instrument master. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.ISINCode) |
| 7 | InstrumentDisplayName | varchar(max) | YES | Instrument display name. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.InstrumentDisplayName) |
| 8 | Buy/Sell | varchar(10) | YES | Direction of the position: 'Buy' or 'Sell', derived from net units sign. (Tier 2 -- SP_DataForDuco, computed from eToro_Units / ClientUnits sign) |
| 9 | eToro_Units | float | YES | Total LP hedge units held at EOD on the eToro side. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Hedge_Netting.Units) |
| 10 | ClientUnits | float | YES | Total client NOP units from BI_DB_PositionPnL for the instrument. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 11 | eToroLocalAmount | money | YES | LP hedge position value in the instrument's local currency. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Hedge_Netting.Amount) |
| 12 | eToroUSDAmount | money | YES | LP hedge position value converted to USD via FXratetoUSD. (Tier 2 -- SP_DataForDuco, computed: eToroLocalAmount × FXratetoUSD) |
| 13 | ClientAmount | money | YES | Client NOP position value in USD. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.NOP via FX conversion) |
| 14 | eToroRate | float | YES | Average rate of the eToro hedge holding (LP-side weighted average price). (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Hedge_Netting.Rate) |
| 15 | HedgingPercent | float | YES | eToro_Units / ClientUnits — hedge coverage ratio (1.0 = fully hedged). (Tier 2 -- SP_DataForDuco, computed: eToro_Units / NULLIF(ClientUnits, 0)) |
| 16 | UpdateDate | datetime | YES | Batch execution timestamp (GETDATE()). (Tier 3 -- SP_DataForDuco, GETDATE()) |
| 17 | Symbol | varchar(50) | YES | Instrument ticker symbol. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.Symbol) |
| 18 | SellCurrency | varchar(10) | YES | Trade currency of the instrument. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.SellCurrency) |
| 19 | Exchange | varchar(max) | YES | Exchange name for the instrument. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.Exchange) |
| 20 | MKTcap | decimal(24,6) | YES | Market capitalization of the instrument from external reference. (Tier 2 -- SP_DataForDuco, external reference table) |
| 21 | Clients_Units_Buy | float | YES | Client units on the buy side (long positions). (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL where IsBuy=1) |
| 22 | Clients_Units_Sell | float | YES | Client units on the sell side (short positions). (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL where IsBuy=0) |
| 23 | Clients_NOP_Buy | float | YES | Client NOP USD value for buy (long) positions. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL NOP buy-side) |
| 24 | Clients_NOP_Sell | float | YES | Client NOP USD value for sell (short) positions. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL NOP sell-side) |
| 25 | FXratetoUSD | float | YES | FX rate from instrument currency to USD for amount conversion. (Tier 2 -- SP_DataForDuco, DWH_dbo.Fact_CurrencyPriceWithSplit) |
| 26 | CUSIP | varchar(max) | YES | CUSIP identifier from the LP netting/external data source. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Hedge_Netting.CUSIP / external source) |

---

## 6. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| etoro_Hedge_Netting | Dealing_staging | Current LP netting state (EOD holdings) |
| etoro_History_Netting_History | Dealing_staging | Historical LP netting (SCD2, deduped to latest per server/instrument) |
| etoro_Trade_LiquidityAccounts | Dealing_staging | LP account name lookup |
| BI_DB_PositionPnL | BI_DB_dbo | Client NOP aggregation (AmountInUnitsDecimal, IsBuy) |
| Fact_CurrencyPriceWithSplit | DWH_dbo | FX rate for USD conversion |
| Dim_Instrument | DWH_dbo | Instrument metadata (ISIN, Symbol, Exchange, SellCurrency) |
| etoro_Hedge_GetHedgeServerAccountMapping | CopyFromLake | Hedge server → LP account mapping |

### Downstream Tables (partial — 11+ recon tables)

| Downstream | Schema | Notes |
|------------|--------|-------|
| Dealing_ApexRecon_TradeActivity | Dealing_dbo | Apex trade recon (via SP_Apex_Recon) |
| Dealing_ApexRecon_Holdings | Dealing_dbo | Apex holdings recon |
| Dealing_ApexRecon_Hedging | Dealing_dbo | Apex hedging recon |
| Dealing_CloseOnly_Recon | Dealing_dbo | Close-only instrument monitoring |
| Dealing_GSRecon* | Dealing_dbo | Goldman Sachs reconciliation |
| Dealing_IBRecon* | Dealing_dbo | Interactive Brokers reconciliation |
| Dealing_IGRecon* | Dealing_dbo | IG reconciliation |
| Dealing_SAXORecon* | Dealing_dbo | SAXO reconciliation |
| Dealing_VisionRecon* | Dealing_dbo | Vision reconciliation |
| Dealing_BNY_VIRTU_Recon* | Dealing_dbo | BNY VIRTU reconciliation |
| Dealing_JPMRecon* | Dealing_dbo | JPMorgan reconciliation |

---

## 7. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_DataForDuco (writes BOTH Dealing_Duco_EODRecon AND Dealing_Duco_ActivityRecon) |
| **Author** | Jenia (2021-10-25); many updates through 2025-08-07 |
| **ETL Pattern** | DELETE WHERE Date=@Date + INSERT |
| **Schedule** | Daily — SB_Daily (P0); skips weekends |
| **Parameter** | @Date (DATE) |
| **Delete Scope** | `DELETE WHERE Date = @Date` |

---

## 8. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Weekend gaps** | No data for Saturday/Sunday — expected behavior. |
| **HedgingPercent** | Values > 1.0 indicate over-hedging; < 1.0 indicates under-hedging. NULL when ClientUnits = 0. |
| **Buy/Sell direction** | Derived from net units sign; not always equivalent to instrument IsBuy flag. |
| **Downstream dependency** | 11+ recon tables use this as input — it runs before all LP-specific recon SPs. |
| **FULL OUTER JOIN artifact** | Rows may have NULL on either side if LP holds position but no client NOP exists, or vice versa. |

---

## 9. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Dealing / LP Reconciliation |
| **Sub-domain** | EOD hedge vs client NOP reconciliation |
| **Sensitivity** | Aggregated LP position data (no individual customer data) |
| **Quality Score** | 8.5 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*


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

### Upstream `Dealing_dbo.Dealing_Duco_ActivityRecon` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_Duco_ActivityRecon`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Duco_ActivityRecon.md`

# Dealing_dbo.Dealing_Duco_ActivityRecon

## 1. Overview

**Daily trade activity reconciliation** between eToro's LP (liquidity provider) hedge executions and client trade activity. Each row compares what was executed on the hedge server side (from the execution log) against what client positions were opened or closed that day, aggregated by liquidity account and instrument. Together with `Dealing_Duco_EODRecon` (holdings), this table forms the two-part Duco reconciliation suite that all LP-specific recon pipelines consume.

**Row grain**: `Date` + `LiquidityAccountID` + `InstrumentID` + `Buy/Sell` direction.

---

## 2. Business Context

`SP_DataForDuco` (Author: Jenia 2021-10-25, many updates through 2025-08-07) writes both this table and `Dealing_Duco_EODRecon` in a single run. The SP does not run on weekends.

**Activity reconciliation logic**: The SP performs a **FULL OUTER JOIN** between eToro's hedge execution log (`CopyFromLake.etoro_Hedge_ExecutionLog`) and client position changes from `BI_DB_dbo.BI_DB_PositionPnL` for the report date. The execution log captures LP trade fills; the client side aggregates open/close actions on positions.

**Rate comparison**: Unlike `EODRecon` which uses a single `eToroRate` (weighted average holding rate), `ActivityRecon` has separate `eToro_AvgRate` (LP execution weighted average) and `Client_AvgRate` (client execution weighted average) — enabling spread/markup analysis.

**Buy/Sell direction** is derived from the net units direction (positive = Buy, negative = Sell).

**Key business rules**:

- **Weekends excluded**: SP skips Sat/Sun — no data is generated for those dates.
- **eToro side**: `etoro_Hedge_ExecutionLog` filtered to `@Date` — captures intraday LP fills.
- **Client side**: `BI_DB_PositionPnL` open/close counts for `DateID = @DateID`.
- **No MKTcap/HedgingPercent/CUSIP**: Unlike EODRecon, this table focuses on trade matching rather than holdings comparison.
- **DELETE-INSERT by date**: Idempotent daily reload.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 25 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

Read-only checks executed **2026-03-21**.

| Check | Result |
|--------|--------|
| **Row count** | ~17,400,000 |
| **Date range** | Active and current (daily refresh confirmed, weekdays only) |
| **Recent sample** | Rows for 2026-03-20 with multiple LiquidityAccountID values |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Report date (trade activity reconciliation date). (Tier 2 -- SP_DataForDuco, @Date) |
| 2 | LiquidityAccountID | int | YES | LP account identifier. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Trade_LiquidityAccounts.LiquidityAccountID) |
| 3 | LiquidityAccountName | varchar(max) | YES | LP account display name. (Tier 2 -- SP_DataForDuco, Dealing_staging.etoro_Trade_LiquidityAccounts.LiquidityAccountName) |
| 4 | HedgeServerID | int | YES | Hedge server associated with the LP execution. (Tier 2 -- SP_DataForDuco, CopyFromLake.etoro_Hedge_ExecutionLog.HedgeServerID) |
| 5 | InstrumentID | int | YES | eToro instrument identifier. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.InstrumentID) |
| 6 | ISINCode | varchar(max) | YES | ISIN code from instrument master. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.ISINCode) |
| 7 | InstrumentDisplayName | varchar(max) | YES | Instrument display name. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.InstrumentDisplayName) |
| 8 | Buy/Sell | varchar(10) | YES | Direction: 'Buy' or 'Sell', derived from net units sign. (Tier 2 -- SP_DataForDuco, computed from sign of eToro_Units / ClientUnits) |
| 9 | eToro_Units | float | YES | Total LP units executed on the hedge server for the date. (Tier 2 -- SP_DataForDuco, CopyFromLake.etoro_Hedge_ExecutionLog.Units) |
| 10 | ClientUnits | float | YES | Total client position units opened/closed on the date. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.AmountInUnitsDecimal) |
| 11 | eToroLocalAmount | money | YES | LP execution value in local instrument currency. (Tier 2 -- SP_DataForDuco, CopyFromLake.etoro_Hedge_ExecutionLog.Amount) |
| 12 | eToroUSDAmount | money | YES | LP execution value converted to USD. (Tier 2 -- SP_DataForDuco, computed: eToroLocalAmount × FXratetoUSD) |
| 13 | ClientAmount | money | YES | Client activity value in USD. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL.NOP via FX conversion) |
| 14 | eToro_AvgRate | float | YES | Weighted average execution rate on the LP/hedge side. (Tier 2 -- SP_DataForDuco, CopyFromLake.etoro_Hedge_ExecutionLog.Rate weighted avg) |
| 15 | Client_AvgRate | float | YES | Weighted average execution rate on the client side. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL rate weighted avg) |
| 16 | UpdateDate | datetime | YES | Batch execution timestamp (GETDATE()). (Tier 3 -- SP_DataForDuco, GETDATE()) |
| 17 | Symbol | varchar(50) | YES | Instrument ticker symbol. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.Symbol) |
| 18 | SellCurrency | varchar(10) | YES | Trade currency of the instrument. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.SellCurrency) |
| 19 | Exchange | varchar(max) | YES | Exchange name for the instrument. (Tier 2 -- SP_DataForDuco, DWH_dbo.Dim_Instrument.Exchange) |
| 20 | Clients_Units_Buy | float | YES | Client trade units on the buy side. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL where IsBuy=1) |
| 21 | Clients_Units_Sell | float | YES | Client trade units on the sell side. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL where IsBuy=0) |
| 22 | Clients_NOP_Buy | float | YES | Client buy-side activity value in USD. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL NOP buy) |
| 23 | Clients_NOP_Sell | float | YES | Client sell-side activity value in USD. (Tier 2 -- SP_DataForDuco, BI_DB_dbo.BI_DB_PositionPnL NOP sell) |
| 24 | FXratetoUSD | float | YES | FX rate from instrument currency to USD. (Tier 2 -- SP_DataForDuco, DWH_dbo.Fact_CurrencyPriceWithSplit) |
| 25 | CUSIP | varchar(max) | YES | CUSIP identifier from LP execution log or external source. (Tier 2 -- SP_DataForDuco, external source / LP execution log) |

---

## 6. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| etoro_Hedge_ExecutionLog | CopyFromLake | LP trade execution records for the report date |
| etoro_Trade_LiquidityAccounts | Dealing_staging | LP account name lookup |
| etoro_Hedge_GetHedgeServerAccountMapping | CopyFromLake | Hedge server → LP account mapping |
| BI_DB_PositionPnL | BI_DB_dbo | Client open/close activity (AmountInUnitsDecimal, IsBuy) |
| Fact_CurrencyPriceWithSplit | DWH_dbo | FX rate for USD conversion |
| Dim_Instrument | DWH_dbo | Instrument metadata (ISIN, Symbol, Exchange, SellCurrency) |

### Downstream Tables (partial — 10+ recon tables)

| Downstream | Schema | Notes |
|------------|--------|-------|
| Dealing_ApexRecon_TradeActivity | Dealing_dbo | Apex trade recon |
| Dealing_ApexRecon_Hedging | Dealing_dbo | Apex hedging recon |
| Dealing_GSReconTrades | Dealing_dbo | Goldman Sachs trade recon |
| Dealing_IBRecon_Trades | Dealing_dbo | Interactive Brokers trade recon |
| Dealing_IGReconTrades | Dealing_dbo | IG trade recon |
| Dealing_SAXORecon_Trades | Dealing_dbo | SAXO trade recon |
| Dealing_VisionRecon_Trades | Dealing_dbo | Vision trade recon |
| Dealing_BNY_VIRTU_ReconTrades | Dealing_dbo | BNY VIRTU trade recon |
| Dealing_JPMRecon* | Dealing_dbo | JPMorgan recon |

---

## 7. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_DataForDuco (writes BOTH Dealing_Duco_EODRecon AND Dealing_Duco_ActivityRecon) |
| **Author** | Jenia (2021-10-25); many updates through 2025-08-07 |
| **ETL Pattern** | DELETE WHERE Date=@Date + INSERT |
| **Schedule** | Daily — SB_Daily (P0); skips weekends |
| **Parameter** | @Date (DATE) |
| **Delete Scope** | `DELETE WHERE Date = @Date` |

---

## 8. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Weekend gaps** | No data for Saturday/Sunday — expected behavior. |
| **Rate comparison** | `eToro_AvgRate` vs `Client_AvgRate` reveals spread/markup captured by eToro on trade routing. |
| **FULL OUTER JOIN artifact** | NULL on either side means no match — LP traded but no client activity, or vice versa. |
| **vs EODRecon** | This captures daily activity (flows); `Dealing_Duco_EODRecon` captures end-of-day holdings (stocks). |
| **Downstream dependency** | Used by 10+ LP-specific recon SPs — runs first in each broker reconciliation pipeline. |

---

## 9. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Dealing / LP Reconciliation |
| **Sub-domain** | Daily trade activity reconciliation |
| **Sensitivity** | Aggregated LP execution data (no individual customer data) |
| **Quality Score** | 8.5 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*


### Upstream `Dealing_dbo.Dealing_IGReconTrades` — synapse
- **Resolved as**: `Dealing_dbo.Dealing_IGReconTrades`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_IGReconTrades.md`

# Dealing_dbo.Dealing_IGReconTrades

> Daily trade activity reconciliation comparing IG's executed order history against eToro's internal dealing records by instrument and direction, surfacing unit and value discrepancies.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | LP_IG_OH_OrderHistory (IG trade feed) + Dealing_Duco_ActivityRecon |
| **Refresh** | Daily (SB_Daily, Priority 0) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

Companion table to `Dealing_IGReconEODHolding`, covering the **trade activity** dimension of the IG reconciliation. Each row represents one instrument × direction (Buy/Sell) × IG account combination for a given date, comparing IG's reported executed order volume against eToro's internal trade records from `Dealing_Duco_ActivityRecon`.

Where `Dealing_IGReconEODHolding` shows end-of-day position snapshots, this table shows intraday trade flows. Non-zero `IG-eToro_*` values indicate trades that appear on IG's books but not eToro's (or vice versa), which can flag execution reporting failures, settlement mismatches, or LP-side rounding differences.

Same SP as EOD holdings (`SP_IGRecon`, Gili Goldbaum, 2023-12-28). IG trades sourced from `LP_IG_OH_OrderHistory` (order history parquet). eToro trades from `Dealing_Duco_ActivityRecon`. Same weekend logic applies (Saturday skip, Sunday → Friday). DELETE-INSERT by Date.

---

## 2. Business Logic

### 2.1 Trade Direction Encoding

**What**: Trades are broken down by Buy/Sell direction.

**Columns involved**: `Buy/Sell`, `IG_Units`, `eToro_Units`

**Rules**:
- `Buy/Sell` = 'Buy' or 'Sell' (from `CASE WHEN [Deal Size] < 0 THEN 'Sell' ELSE 'Buy'`)
- `IG_Units` = `SUM(ABS([Deal Size]) × [Lot Size] × (±1))` from `LP_IG_OH_OrderHistory`, filtered to `Result NOT LIKE '%Rejected:%'`
- Oil multiplier (×100) applied on IG side
- GBX normalisation (÷100) applied on eToro side

### 2.2 Reconciliation Diff Columns

**What**: `{LP}-{side}_*` columns show arithmetic difference between LP and eToro sides.

**Rules**:
- Formula: `ISNULL(IG_value, 0) − ISNULL(eToro_value, 0)`
- Non-zero = trade recon break

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN with CLUSTERED INDEX on `Date ASC`. Filter on Date first; add InstrumentID or direction filters to narrow results.

### 3.1b UC (Databricks) Storage & Partitioning

UC partitioning not yet resolved. Filter on `Date` for efficient scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Trade breaks for a date | `WHERE Date = @d AND [IG-eToro_Units] <> 0` |
| Buy vs Sell volume comparison | `GROUP BY Date, InstrumentID, [Buy/Sell]` |
| Reconcile against EOD holdings | JOIN to Dealing_IGReconEODHolding on Date + InstrumentID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID | Instrument metadata |
| Dealing_IGReconEODHolding | Date + InstrumentID | Pair trade recon with EOD holdings |
| Dealing_Duco_ActivityRecon | Date + HedgeServerID | Trace eToro-side source trades |

### 3.4 Gotchas

- **Rejected trades excluded**: IG side filters `Result NOT LIKE '%Rejected:%'` — rejected orders are not included
- **Oil multiplier and GBX normalization**: Same adjustments as EOD holdings table apply
- **FULL OUTER JOIN rows**: NULL HedgeServerID = IG-only trade; NULL Account_Number = eToro-only trade

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_IGRecon)` |
| ★★ | Tier 3 — live data / DDL | `(Tier 3 — DDL/live)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Trade date (same weekend adjustment as EOD: Saturday skip, Sunday→Friday). (Tier 2 — SP_IGRecon) |
| 2 | HedgeServerID | int | YES | eToro hedge server for the IG LP. From Fivetran mapping (`liquidity_provider='IG'`). NULL for IG-only trades. (Tier 2 — SP_IGRecon) |
| 3 | Account_Number | varchar(50) | YES | IG account number (`LP_IG_OH_OrderHistory.[Account ID]`). NULL for eToro-only trades. (Tier 2 — SP_IGRecon) |
| 4 | InstrumentID | int | YES | eToro instrument identifier. Resolved via #MarketNameToID or ISIN join. FK → DWH_dbo.Dim_Instrument. (Tier 2 — SP_IGRecon) |
| 5 | InstrumentDisplayName | varchar(100) | YES | Instrument display name. ISNULL(eToro_side, IG_side). (Tier 2 — SP_IGRecon) |
| 6 | Symbol | varchar(250) | YES | Ticker symbol. From eToro side. (Tier 2 — SP_IGRecon) |
| 7 | ISINCode | varchar(30) | YES | ISIN. ISNULL(eToro_side, IG_side). (Tier 2 — SP_IGRecon) |
| 8 | Buy/Sell | varchar(100) | YES | Trade direction: 'Buy' or 'Sell'. Derived from IG: `CASE WHEN [Deal Size] < 0 THEN 'Sell' ELSE 'Buy'`. From eToro: Dealing_Duco_ActivityRecon.[Buy/Sell]. (Tier 2 — SP_IGRecon) |
| 9 | CurrencyPrimary | varchar(50) | YES | Instrument local currency. GBX normalised to GBP. ISNULL(eToro, IG). (Tier 2 — SP_IGRecon) |
| 10 | IG_Units | decimal(16,6) | YES | IG's executed trade volume. `SUM(ABS([Deal Size])×[Lot Size]×(±1))` from `LP_IG_OH_OrderHistory` where Result not rejected. Oil ×100. (Tier 2 — SP_IGRecon) |
| 11 | eToro_Units | decimal(16,6) | YES | eToro's executed trade volume. `SUM(eToro_Units)` from `Dealing_Duco_ActivityRecon` for IG HS. (Tier 2 — SP_IGRecon) |
| 12 | Clients_Units | decimal(16,6) | YES | Aggregated client trade volume. `SUM(ClientUnits)` from `Dealing_Duco_ActivityRecon`. (Tier 2 — SP_IGRecon) |
| 13 | IG-eToro_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(IG_Units,0) − ISNULL(eToro_Units,0)`. (Tier 2 — SP_IGRecon) |
| 14 | IG-Clients_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(IG_Units,0) − ISNULL(Clients_Units,0)`. (Tier 2 — SP_IGRecon) |
| 15 | IG_Rate | decimal(16,6) | YES | IG's average execution price. `SUM(ABS([Deal Level]×[Deal Size])×Lot) / SUM(ABS([Deal Size]))` from `LP_IG_OH_OrderHistory`. (Tier 2 — SP_IGRecon) |
| 16 | eToro_Rate | decimal(16,6) | YES | eToro's average execution rate. `AVG(eToro_Rate)` from `Dealing_Duco_ActivityRecon`. GBX ÷100. (Tier 2 — SP_IGRecon) |
| 17 | IG-eToro_Rate | decimal(16,6) | YES | `ISNULL(IG_Rate,0) − ISNULL(eToro_Rate,0)`. Execution price discrepancy. (Tier 2 — SP_IGRecon) |
| 18 | IG_LocalAmount | money | YES | IG's notional trade value in local currency. Computed from `[Deal Level] × [Deal Size] × [Lot Size]` (sign adjusted). Oil ×100. (Tier 2 — SP_IGRecon) |
| 19 | eToro_LocalAmount | money | YES | eToro's local currency trade amount from `Dealing_Duco_ActivityRecon.eToroLocalAmount`. GBX ÷100. (Tier 2 — SP_IGRecon) |
| 20 | IG-eToro_LocalAmount | money | YES | `ISNULL(IG,0) − ISNULL(eToro,0)`. Local currency trade break. (Tier 2 — SP_IGRecon) |
| 21 | IG_AmountUSD | money | YES | IG's notional trade value in USD. `IG_LocalAmount × MAX(FX_Rate)`. (Tier 2 — SP_IGRecon) |
| 22 | eToro_AmountUSD | money | YES | eToro's USD trade amount from `Dealing_Duco_ActivityRecon.eToroUSDAmount`. (Tier 2 — SP_IGRecon) |
| 23 | Clients_AmountUSD | money | YES | Aggregated client trade amount in USD from `Dealing_Duco_ActivityRecon.ClientAmount`. (Tier 2 — SP_IGRecon) |
| 24 | IG-eToro_AmountUSD | money | YES | `ISNULL(IG,0) − ISNULL(eToro,0)`. USD trade break. (Tier 2 — SP_IGRecon) |
| 25 | IG-Clients_AmountUSD | money | YES | `ISNULL(IG,0) − ISNULL(Clients,0)`. USD break vs client NOP. (Tier 2 — SP_IGRecon) |
| 26 | IG_FXRate | decimal(16,6) | YES | IG's FX rate for currency conversion. `MAX(IG_FXRate)` from `#IG_FXRates` derived from `LP_IG_PS_EODPositions.[Conversion Rate]`. (Tier 2 — SP_IGRecon) |
| 27 | eToro_FXRate | decimal(16,6) | YES | eToro's FX rate. `AVG(eToro_FX_Rate)` from `Dealing_Duco_ActivityRecon.FXratetoUSD`. (Tier 2 — SP_IGRecon) |
| 28 | Exchange | varchar(80) | YES | Trading venue. From eToro side (`Dealing_Duco_ActivityRecon.Exchange`). ISNULL(eToro, 0). (Tier 2 — SP_IGRecon) |
| 29 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. GETDATE() on INSERT. (Tier 2 — SP_IGRecon) |

---

## 5. Lineage

### 5.1 Production Sources

| Column | Source | Transform |
|--------|--------|-----------|
| IG_Units | LP_IG_OH_OrderHistory.[Deal Size] | SUM×LotSize; rejected excluded; Oil ×100 |
| IG_Rate | LP_IG_OH_OrderHistory.[Deal Level] | Weighted avg price |
| IG_LocalAmount | LP_IG_OH_OrderHistory | Notional = DealLevel×DealSize×LotSize |
| IG_AmountUSD | LP_IG_OH_OrderHistory + FX | LocalAmount × FXRate |
| eToro_Units | Dealing_Duco_ActivityRecon.eToro_Units | SUM, IG HS filter |
| eToro_LocalAmount | Dealing_Duco_ActivityRecon.eToroLocalAmount | GBX ÷100 |
| eToro_AmountUSD | Dealing_Duco_ActivityRecon.eToroUSDAmount | Passthrough |
| Diff columns | Computed | ISNULL(LP,0)−ISNULL(eToro,0) |

### 5.2 ETL Pipeline

```
LP IG Files (Order History Parquet) → LP_IG_OH_OrderHistory
  +
Dealing_Duco_ActivityRecon (eToro activity, IG HS filter)
  → SP_IGRecon (FULL OUTER JOIN on InstrumentID + AccountID + Direction)
  → Dealing_IGReconTrades (DELETE-INSERT by Date)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata |
| HedgeServerID | Dealing_Duco_ActivityRecon | eToro trade source |

### 6.2 Referenced By

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_IGReconEODHolding | Same SP | EOD holdings companion — same writer |

---

## 7. Sample Queries

### 7.1 Trade breaks on latest date
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, [Buy/Sell],
  IG_Units, eToro_Units, [IG-eToro_Units], [IG-eToro_AmountUSD]
FROM Dealing_dbo.Dealing_IGReconTrades
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_IGReconTrades)
  AND ABS([IG-eToro_Units]) > 0
ORDER BY ABS([IG-eToro_AmountUSD]) DESC
```

### 7.2 Net daily traded volume by instrument (eToro side)
```sql
SELECT Date, InstrumentID, InstrumentDisplayName,
  SUM(CASE WHEN [Buy/Sell]='Buy' THEN eToro_Units ELSE -eToro_Units END) AS Net_eToro_Units
FROM Dealing_dbo.Dealing_IGReconTrades
WHERE Date >= DATEADD(DAY, -7, GETDATE())
GROUP BY Date, InstrumentID, InstrumentDisplayName
ORDER BY Date DESC
```

### 7.3 Rate discrepancy across instruments
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, [Buy/Sell],
  IG_Rate, eToro_Rate, [IG-eToro_Rate]
FROM Dealing_dbo.Dealing_IGReconTrades
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_IGReconTrades)
  AND ABS([IG-eToro_Rate]) > 0.01
ORDER BY ABS([IG-eToro_Rate]) DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object (Phase 10 not available in this session).

---

*Generated: 2026-03-21 | Quality: 7.8/10 (★★★☆☆) | Phases: P1 P2 P5 P8 P9 P13 P11*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `Dealing_dbo.SP_IGRecon`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_IGRecon.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [Dealing_dbo].[SP_IGRecon] @Date [DATE] AS  --Yesterday 
BEGIN


/******************************************************************************************************************************
Author: Gili Goldbaum
Date: 2023-12-28
Description: Daily IG - Executed trades and EOD holdings reconciliation
   
**************************  
** Change History  
**************************  
Date           Author        SR             Description   
----------    ----------    -----------    ----------------------------------------------------------------------------------  
2023-12-28     Gili			 SR-224121		Creating SP
2024-01-03     Gili			 SR-224121		Changed Data Types in #IG_EOD temp table
2024-01-11     Gili			 SR-224121		Updating the procedure - it will not run on Saturday + instead of Sunday it will run on Friday
2024-01-11     Gili			 SR-224121		Changed the Oil Multiplier in #IG_EOD Local Amount
2024-02-22     Gili			 SR-235175		Adding HS 24
2024-10-21	   Gili			 SR-276892		Changed the SP to take HS and LA from Fivetran
2024-11-18	   Gili			 SR-281249		Updated the WHERE clause of the #Fivetran temp table to use update_date <= @Date instead of update_date < @Date
2025-10-23	   Adar			 SR-338909		Fix IG table from Ariel's Code (Load [Dealing_staging].[LP_IG_PS_EODPositions] to daily table, to prevent issues of "-" from IG files)

*******************************************************************************************************************************/  
  
/************************************************Declare Parameters**********************************************************************/  
     
--exec  [Dealing_dbo].[SP_IGRecon] '20251015'  

--DECLARE @Date DATE='20251015'


DECLARE @TotalDate DATE= (SELECT CASE WHEN (select DayNumberOfWeek_Sun_Start from DWH_dbo.Dim_Date where FullDate = @Date) = 1 
									  THEN DATEADD(DAY, -2, @Date) 
									  ELSE @Date END)

DECLARE @TotalDateID INT=CAST(CONVERT(VARCHAR(8), @TotalDate, 112) AS INT)  

DECLARE @Is_Saturday INT = CASE WHEN (select DayNumberOfWeek_Sun_Start from DWH_dbo.Dim_Date where FullDate = @Date) = 7 THEN 1 ELSE 0 END 


-------Ariel Code
-------Load [Dealing_staging].[LP_IG_PS_EODPositions] to daily table, to prevent issues of "-" from IG files

-- === set the ETR date you want ===
DECLARE @etr_date date = @TotalDate;

-- Build partition strings: etr_y, etr_ym, etr_ymd
DECLARE @etr_y   char(4)  = CONVERT(char(4), DATEPART(year, @etr_date));
DECLARE @etr_ym  char(7)  = CONVERT(char(10), @etr_date, 23); -- 'yyyy-mm-dd' then take first 7 chars: 'yyyy-mm'
SET @etr_ym = LEFT(@etr_ym, 7);
DECLARE @etr_ymd char(10) = CONVERT(char(10), @etr_date, 23); -- 'yyyy-mm-dd'

-- Build the dynamic path
DECLARE @path nvarchar(4000) =
N'https://dldataplatformprodwe.dfs.core.windows.net/external-sources/LP/Silver/IG/PS_EODPositions'
  + N'/etr_y='  + @etr_y
  + N'/etr_ym=' + @etr_ym
  + N'/etr_ymd='+ @etr_ymd
  + N'/*.parquet';

-- Build the dynamic SQL for COPY INTO
DECLARE @sql nvarchar(max) = N'
IF OBJECT_ID(''Dealing_staging.LP_IG_PS_EODPositions_daily'', ''U'') IS NOT NULL
    DROP TABLE Dealing_staging.LP_IG_PS_EODPositions_daily;

COPY INTO Dealing_staging.LP_IG_PS_EODPositions_daily
FROM ''' + @path + N'''
WITH (
    FILE_TYPE = ''PARQUET'',
    CREDENTIAL = (IDENTITY = ''Managed Identity''),
    AUTO_CREATE_TABLE = ''ON''
);'
-- print (@sql)

EXEC sp_executesql @sql;

--Insert the data to the main table of IG, to make sure all the dates appears there
DELETE FROM [Dealing_staging].[LP_IG_PS_EODPositions] WHERE ReportDateID = @TotalDateID

INSERT INTO [Dealing_staging].[LP_IG_PS_EODPositions]
SELECT 
[Account ID],
[Account Name],
[Market Name],
[Period],
[Bloomberg Code],
[ISIN],
[Created],
[Deal ID],
[Direction],
[Position],
[Opening],
[Stop Level],
[Type],
[Limit Level],
case when len(trim(cast(Latest as varchar)))=1 then convert(float ,replace(Latest,char(45),'0.0')) else  Latest end [Latest],
case when len(trim(cast([Current Value] as varchar)))=1 then convert(float , replace([Current Value],char(45),'0.0')) else  [Current Value] end [Current Value],
case when len(trim(cast([Profit/Loss] as varchar)))=1 then convert(float ,replace([Profit/Loss],char(45),'0.0')) else  [Profit/Loss] end [Profit/Loss],
[Ccy],
[Base currency],
case when len(trim(cast([Consideration (Base Ccy)] as varchar)))=1 then convert(float , replace([Consideration (Base Ccy)],char(45),'0.0')) else  [Consideration (Base Ccy)] end [Consideration (Base Ccy)],
case when len(trim(cast([Conversion Rate] as varchar)))=1 then convert(float ,replace( [Conversion Rate],char(45),'0.0')) else  [Conversion Rate] end [Conversion Rate],
[Product],
[FileName],
[ReportDateID]
FROM Dealing_staging.LP_IG_PS_EODPositions_daily
WHERE ReportDateID = @TotalDateID


IF OBJECT_ID('tempdb..#MarketNameToID') IS NOT NULL 
DROP TABLE #MarketNameToID;
    CREATE TABLE #MarketNameToID        
    (        
       MarketName VARCHAR(100),        
       InstrumentID INT,    
	   Multiplier INT
    ) WITH (HEAP, DISTRIBUTION=HASH (InstrumentID)) ;        

INSERT INTO #MarketNameToID
SELECT 'Wall Street Cash ($1)',29,1 UNION ALL
SELECT 'Germany 30 Cash (€1)',32,1 UNION ALL
SELECT 'Germany 40 Cash (E1)',32,1 UNION ALL
SELECT 'Hong Kong HS50 Cash (HK1)',38,1 UNION ALL
SELECT 'UK100 Cash (£1)',30,1 UNION ALL
SELECT 'UK100 Cash (1£)',30,1 UNION ALL
SELECT 'Australia 200 Cash (A$1)',33,1 UNION ALL
SELECT 'Australia 200 Cash (1A$           )',33,1 UNION ALL
SELECT 'US Tech 100 Cash ($1)',28,1 UNION ALL
SELECT 'US Tech 100 Cash (1$)',28,1 UNION ALL
SELECT 'US 500 Cash ($1)',27,1 UNION ALL
SELECT 'US 500 Cash (1$)',27,1 UNION ALL
SELECT 'Natural Gas ($1)',22,1 UNION ALL
SELECT 'Natural Gas (1$)',22,1 UNION ALL
SELECT 'France 40 Cash (€1)',31,1 UNION ALL
SELECT 'France 40 Cash (1€)',31,1 UNION ALL
SELECT 'Oil - US Crude ($1)',17,100 UNION ALL
SELECT 'Oil - US Crude (1$)',17,100 UNION ALL
SELECT 'Japan 225 Cash (¥100)',36,1 UNION ALL
SELECT 'Japan 225 Cash (100¥)',36,1 UNION ALL
SELECT 'Spain 35 Cash (€1)',34,1 UNION ALL
SELECT 'Spain 35 Cash (1€)',34,1 UNION ALL
SELECT 'Esken Ltd Open Offer',2641,1 UNION ALL
SELECT 'Ether (USD) - B2C2',100001,1 UNION ALL
SELECT 'Kier Group PLC Open Offer',2792,1 UNION ALL
SELECT 'Norwegian Air Shuttle AS Rights Issue',2220,1 UNION ALL
SELECT 'ProShares UltraShort Bloomberg Crude Oil',4464,1 UNION ALL
SELECT 'Renewi PLC',2836,1 UNION ALL
SELECT 'iPath S&P 500 VIX Short-Term Futures ETN',3163,1 UNION ALL
SELECT 'DNB ASA',2213,1 UNION ALL
SELECT 'Distribuidora Internacional de Alimentacion SA Rights Issue',1321,1 UNION ALL
SELECT 'Atlas Copco AB - B',2244,1 UNION ALL
SELECT 'AUD/USD',7,100000 UNION ALL
SELECT 'EUR/USD',1,100000 UNION ALL
SELECT 'GBP/USD',2,100000 UNION ALL
SELECT 'NZD/USD',3,100000 UNION ALL
SELECT 'Spot Gold ($1 Contract)',18,100 UNION ALL
SELECT 'Spot Gold',18,1 UNION ALL
SELECT 'Spot Silver ($1 Contract)',19,100 UNION ALL
SELECT 'USD/CAD',4,100000 UNION ALL
SELECT 'USD/CHF',6,100000 UNION ALL
SELECT 'USD/CNH',45,100000 UNION ALL
SELECT 'USD/JPY',5,100000 UNION ALL
SELECT 'USD/PLN',73,100000 UNION ALL
SELECT 'USD/RUB',44,100000 UNION ALL
SELECT 'USD/SGD',64,100000 UNION ALL
SELECT 'USD/TRY',62,100000 UNION ALL
SELECT 'China A50 Cash ($1)',26,1 UNION ALL
SELECT 'USD/MXN',63,1

IF OBJECT_ID('tempdb..#Fivetran') IS NOT NULL DROP TABLE #Fivetran;
CREATE TABLE #Fivetran
WITH (HEAP, DISTRIBUTION=ROUND_ROBIN) AS

SELECT _row
	  ,lp_accounts
	  ,hs_dealing_desk
	  ,liquidity_account_name
	  ,instruments_
	  ,activity
	  ,strategy
	  ,strategy_details
	  ,liquidity_account_id
	  ,liquidity_provider
	  ,_fivetran_synced
	  ,is_active
	  ,update_date
FROM
(
SELECT *,
DENSE_RANK() over (ORDER BY update_date DESC) AS rn
FROM Dealing_staging.External_Fivetran_dealing_active_hs_mappings
WHERE 
liquidity_provider = 'IG' AND
update_date <= @Date
) a
WHERE rn = 1

--SELECT * FROM #Fivetran 

IF OBJECT_ID('tempdb..#Ins') IS NOT NULL 
DROP TABLE #Ins
    CREATE TABLE #Ins
     WITH (HEAP, DISTRIBUTION=HASH (InstrumentID))

AS

SELECT DISTINCT lp.[Market Name] AS [MarketName]
		,ISNULL(di1.InstrumentID,m.InstrumentID) InstrumentID
		,ISNULL(di1.InstrumentDisplayName,di2.InstrumentDisplayName) AS InstrumentDisplayName
FROM [Dealing_staging].[LP_IG_OH_OrderHistory] lp  with (NOLOCK)
LEFT JOIN [DWH_dbo].[Dim_Instrument] di1
ON di1.ISINCode = lp.ISIN
LEFT JOIN #MarketNameToID m
ON lp.[Market Name] = m.[MarketName]
LEFT JOIN [DWH_dbo].[Dim_Instrument] di2
ON m.InstrumentID = di2.InstrumentID

UNION

SELECT DISTINCT lp.[Market Name]  AS [MarketName]
		,ISNULL(di1.InstrumentID,m.InstrumentID) InstrumentID
		,ISNULL(di1.InstrumentDisplayName,di2.InstrumentDisplayName) AS InstrumentDisplayName
FROM [Dealing_staging].[LP_IG_PS_EODPositions] lp  with (NOLOCK)
LEFT JOIN [DWH_dbo].[Dim_Instrument] di1
ON di1.ISINCode = lp.ISIN
LEFT JOIN #MarketNameToID m
ON lp.[Market Name] = m.[MarketName]
LEFT JOIN [DWH_dbo].[Dim_Instrument] di2
ON m.InstrumentID = di2.InstrumentID


--EOD 
--eToro Side holdings
IF OBJECT_ID('tempdb..#eToroSide_EOD') IS NOT NULL 
DROP TABLE #eToroSide_EOD 
CREATE TABLE #eToroSide_EOD   
    WITH (HEAP, DISTRIBUTION=HASH (InstrumentID, HedgeServerID))
AS

SELECT 
dde.Date,
dde.HedgeServerID,
dde.InstrumentID,
dde.InstrumentDisplayName,
dde.Symbol,
dde.ISINCode,
dde.[Buy/Sell],
CASE WHEN dde.SellCurrency = 'GBX' THEN 'GBP' ELSE dde.SellCurrency END AS CurrencyPrimary,
dde.Exchange,
dde.eToro_Units,
dde.ClientUnits, 
CASE WHEN dde.SellCurrency='GBX' THEN dde.eToroLocalAmount/100 ELSE eToroLocalAmount END AS eToroLocalAmount, --Adjust to GBX
dde.eToroUSDAmount AS eToroAmountUSD,
dde.ClientAmount AS ClientAmountUSD,
CASE WHEN dde.SellCurrency= 'GBX' THEN dde.eToroRate/100 ELSE dde.eToroRate END AS eToroRate,
dde.FXratetoUSD,
f.lp_accounts AS AccountID 
FROM [Dealing_dbo].[Dealing_Duco_EODRecon] dde WITH (NOLOCK)
JOIN #Fivetran f ON dde.HedgeServerID = f.hs_dealing_desk AND dde.LiquidityAccountID = f.liquidity_account_id
WHERE dde.Date=@TotalDate


IF OBJECT_ID('tempdb..#eToroSide_EOD_Final') IS NOT NULL 
DROP TABLE #eToroSide_EOD_Final 
CREATE TABLE #eToroSide_EOD_Final   
    WITH (HEAP, DISTRIBUTION=HASH (InstrumentID, HedgeServerID))
AS

SELECT	 Date,
		 HedgeServerID,
		 InstrumentID,
		 InstrumentDisplayName,
		 Symbol,
		 ISINCode,
		 CurrencyPrimary,
		 Exchange,
		 AccountID,
		 SUM(eToro_Units) AS eToro_Units,
		 SUM(ClientUnits) AS ClientUnits,
		 SUM(eToroLocalAmount) AS eToroLocalAmount,
		 SUM(eToroAmountUSD) AS eToroAmountUSD,
		 SUM(ClientAmountUSD) AS ClientAmountUSD,
		 MAX(eToroRate) AS eToroRate,
		 MAX(FXratetoUSD) AS FXratetoUSD
FROM #eToroSide_EOD
GROUP BY Date,
		 HedgeServerID,
		 InstrumentID,
		 InstrumentDisplayName,
		 Symbol,
		 ISINCode,
		 CurrencyPrimary,
		 Exchange,
		 AccountID

--IG holdings
IF OBJECT_ID('tempdb..#IG_EOD') IS NOT NULL 
DROP TABLE #IG_EOD 
CREATE TABLE #IG_EOD   
    WITH (HEAP, DISTRIBUTION=HASH (InstrumentID))
AS

SELECT   m.[Account ID] AS Account_Number
		,m.[Market Name] AS [MarketName]
		,i.InstrumentID
		,i.InstrumentDisplayName
		,ISIN AS ISINCode --?
		,Ccy AS CurrencyPrimary
		,CASE WHEN m.[Market Name] = 'Oil - US Crude ($1)' THEN ABS(CAST(m.Position AS DECIMAL(16,6)))*100 ELSE ABS(CAST(m.Position AS DECIMAL(16,6))) END AS IG_Units
		,CASE WHEN m.[Market Name] = 'Oil - US Crude ($1)' 
		 THEN (CASE WHEN TRY_CONVERT(DECIMAL(16,6), m.[Current Value]) IS NULL THEN TRY_CONVERT(FLOAT, m.[Current Value]) ELSE CAST(m.[Current Value] AS DECIMAL(16,6)) END)*100
		 ELSE (CASE WHEN TRY_CONVERT(DECIMAL(16,6), m.[Current Value]) IS NULL THEN TRY_CONVERT(FLOAT, m.[Current Value]) ELSE CAST(m.[Current Value] AS DECIMAL(16,6)) END) END AS IG_LocalAmount
		,CASE WHEN TRY_CONVERT(DECIMAL(16,6), m.[Consideration (Base Ccy)]) IS NULL THEN TRY_CONVERT(FLOAT, m.[Consideration (Base Ccy)]) ELSE CAST(m.[Consideration (Base Ccy)] AS DECIMAL(16,6)) END AS IG_AmountUSD
		,TRY_CONVERT(DECIMAL(16,6), m.Latest) AS IG_Rate
		,CASE WHEN Ccy = 'USD' THEN 1 ELSE TRY_CONVERT(DECIMAL(16,6), LEFT(m.[Conversion Rate], LEN(m.[Conversion Rate])-1)) END AS IG_FXRate
  		,CASE WHEN CAST(Position AS DECIMAL(16,6)) < 0 THEN 0 ELSE 1 end IsBuy
FROM [Dealing_staging].[LP_IG_PS_EODPositions] m with (NOLOCK)
LEFT JOIN #Ins i
ON i.[MarketName] = m.[Market Name] AND i.InstrumentID IS NOT NULL
WHERE m.ReportDateID = @TotalDateID


IF OBJECT_ID('tempdb..#IG_EOD_Final') IS NOT NULL 
DROP TABLE #IG_EOD_Final
CREATE TABLE #IG_EOD_Final
    WITH (HEAP, DISTRIBUTION=HASH (InstrumentID))
AS
 
SELECT
	Account_Number,
	MarketName,
	InstrumentID,
	InstrumentDisplayName,
	ISINCode,
	CurrencyPrimary,
	SUM((2*IsBuy-1)*IG_Units) AS IG_Units,
	SUM(IG_LocalAmount) AS IG_LocalAmount,
	MAX(IG_Rate) AS IG_Rate,
	MAX(IG_FXRate) AS IG_FXRate,
	SUM((2*IsBuy-1)*IG_AmountUSD) AS IG_AmountUSD
FROM #IG_EOD
GROUP BY
	Account_Number,
	MarketName,
	InstrumentID,
	InstrumentDisplayName,
	ISINCode,
	CurrencyPrimary


--EOD Final Data 
IF OBJECT_ID('tempdb..#EOD_Final') IS NOT NULL 
DROP TABLE #EOD_Final
CREATE TABLE #EOD_Final
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
 
SELECT @TotalDate AS Date,
	   tse.HedgeServerID,
	   ig.Account_Number,
	   tse.InstrumentID,
	   ISNULL(tse.InstrumentDisplayName, ig.InstrumentDisplayName) AS InstrumentDisplayName,
	   tse.Symbol,
	   ISNULL(tse.ISINCode, ig.ISINCode) AS ISINCode,
	   ISNULL(tse.CurrencyPrimary, ig.CurrencyPrimary) AS CurrencyPrimary,
	   ISNULL(tse.Exchange, 0) AS Exchange,
	   ISNULL(ig.IG_Units, 0) AS IG_Units,
	   ISNULL(tse.eToro_Units, 0) AS eToro_Units,
	   ISNULL(tse.ClientUnits, 0) AS Clients_Units,
	   ISNULL(ig.IG_Units, 0)- ISNULL(tse.eToro_Units, 0) AS [IG-eToro_Units],
	   ISNULL(ig.IG_Units, 0)- ISNULL(tse.ClientUnits, 0) AS [IG-Clients_Units],
	   ISNULL(ig.IG_LocalAmount, 0) AS IG_LocalAmount,
	   ISNULL(tse.eToroLocalAmount, 0) AS eToro_LocalAmount,
	   ISNULL(ig.IG_LocalAmount, 0)- ISNULL(tse.eToroLocalAmount, 0) AS [IG-eToro_LocalAmount],
	   ISNULL(ig.IG_AmountUSD, 0) AS IG_AmountUSD,
	   ISNULL(tse.eToroAmountUSD, 0) AS eToro_AmountUSD,
	   ISNULL(tse.ClientAmountUSD, 0) AS Clients_AmountUSD,
	   ISNULL(ig.IG_AmountUSD, 0)- ISNULL(tse.eToroAmountUSD, 0) AS [IG-eToro_AmountUSD],
	   ISNULL(ig.IG_AmountUSD, 0)- ISNULL(tse.ClientAmountUSD, 0) AS [IG-Clients_AmountUSD],
	   ISNULL(ig.IG_Rate, 0) AS IG_Rate,
	   ISNULL(tse.eToroRate, 0) AS eToro_Rate,
	   ISNULL(ig.IG_Rate, 0)- ISNULL(tse.eToroRate, 0) AS [IG-eToro_Rate],
	   ISNULL(tse.FXratetoUSD,0) AS eToro_FXRate,
	   ISNULL(ig.IG_FXRate,0) AS IG_FXRate
FROM #IG_EOD_Final ig
FULL OUTER JOIN #eToroSide_EOD_Final tse
ON tse.InstrumentID= ig.InstrumentID AND ig.Account_Number = tse.AccountID

--SELECT * FROM #EOD_Final

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Trades Activity
--eToro Side Trades
IF OBJECT_ID('tempdb..#eToroSide_Trades') IS NOT NULL 
DROP TABLE #eToroSide_Trades
CREATE TABLE #eToroSide_Trades
    WITH (HEAP, DISTRIBUTION=HASH (InstrumentID, HedgeServerID))
AS

SELECT 
ddar.Date,
ddar.InstrumentID, 
ddar.InstrumentDisplayName, 
ddar.ISINCode, 
CASE WHEN ddar.SellCurrency = 'GBX' THEN 'GBP' ELSE ddar.SellCurrency END AS CurrencyPrimary,
ddar.Exchange, 
ddar.Symbol,
ddar.[Buy/Sell],
ddar.eToro_Units, 
ddar.ClientUnits, 
CASE WHEN ddar.SellCurrency= 'GBX' THEN ddar.eToro_AvgRate/100 ELSE ddar.eToro_AvgRate END AS eToro_Rate,
CASE WHEN ddar.SellCurrency= 'GBX' THEN ddar.eToroLocalAmount/100 ELSE ddar.eToroLocalAmount END AS eToroLocalAmount,
ddar.eToroUSDAmount AS eToroAmountUSD, 
ddar.ClientAmount AS ClientAmountUSD, 
ddar.FXratetoUSD AS eToro_FX_Rate,
ddar.HedgeServerID,
f.lp_accounts AS AccountID 
FROM [Dealing_dbo].[Dealing_Duco_ActivityRecon] ddar
JOIN #Fivetran f ON ddar.HedgeServerID = f.hs_dealing_desk AND ddar.LiquidityAccountID = f.liquidity_account_id
WHERE ddar.Date=@TotalDate


IF OBJECT_ID('tempdb..#eToroSide_Trades_Final') IS NOT NULL 
DROP TABLE #eToroSide_Trades_Final
CREATE TABLE #eToroSide_Trades_Final
    WITH (HEAP, DISTRIBUTION=HASH (InstrumentID, HedgeServerID))
AS

SELECT	 Date,
		 HedgeServerID,
		 InstrumentID,
		 InstrumentDisplayName,
		 Symbol,
		 [Buy/Sell],
		 ISINCode,
		 CurrencyPrimary,
		 Exchange,
		 AccountID,
		 SUM(eToro_Units) AS eToro_Units,
		 SUM(ClientUnits) AS ClientUnits,
		 SUM(eToroLocalAmount) AS eToroLocalAmount,
		 SUM(eToroAmountUSD) AS eToroAmountUSD,
		 SUM(ClientAmountUSD) AS ClientAmountUSD,
		 AVG(eToro_Rate) AS eToroRate,
		 AVG(eToro_FX_Rate) AS FXratetoUSD
FROM #eToroSide_Trades
GROUP BY Date,
		 HedgeServerID,
		 InstrumentID,
		 InstrumentDisplayName,
		 Symbol,
		 [Buy/Sell],
		 ISINCode,
		 CurrencyPrimary,
		 Exchange,
		 AccountID

--IG Trades
IF OBJECT_ID('tempdb..#IG_FXRates') IS NOT NULL 
DROP TABLE #IG_FXRates
CREATE TABLE #IG_FXRates
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT DISTINCT m.Ccy AS CurrencyPrimary,
CASE WHEN m.Ccy = 'USD' THEN 1 ELSE CAST(LEFT(m.[Conversion Rate], LEN(m.[Conversion Rate])-1) AS FLOAT) END AS IG_FXRate
FROM [Dealing_staging].[LP_IG_PS_EODPositions] m with (NOLOCK)
WHERE m.ReportDateID = @TotalDateID


IF OBJECT_ID('tempdb..#IG_Trades_Final') IS NOT NULL 
DROP TABLE #IG_Trades_Final
CREATE TABLE #IG_Trades_Final
    WITH (HEAP, DISTRIBUTION=HASH (InstrumentID))
AS

SELECT   lp.[Account ID] AS Account_Number
		,lp.[Market Name] AS [MarketName]
		,i.InstrumentID
		,i.InstrumentDisplayName
		,lp.ISIN AS ISINCode --?
		,Ccy AS CurrencyPrimary
		,CASE WHEN CAST([Deal Size] AS DECIMAL(16,6)) < 0 THEN 'Sell' ELSE 'Buy' END AS [Buy/Sell]
		,SUM(ABS(CAST(lp.[Deal Size] AS DECIMAL(16,6)))*
			(CASE WHEN [Market Name] = 'Oil - US Crude ($1)' THEN 100 ELSE CAST([Lot Size] AS DECIMAL(16,6)) END)*
			(CASE WHEN CAST([Deal Size] AS DECIMAL(16,6)) < 0 THEN -1 ELSE 1 END)) AS IG_Units
		,SUM(ABS(CAST(lp.[Deal Size] AS DECIMAL(16,6)))*
			CAST(lp.[Deal Level] AS DECIMAL(16,6)))
			/NULLIF(SUM(ABS(CAST(lp.[Deal Size] AS DECIMAL(16,6)))),0) AS IG_Rate
		,SUM(ABS(CAST(lp.[Deal Level] AS DECIMAL(16,6))*
			CAST(lp.[Deal Size] AS DECIMAL(16,6)))*
			(CASE WHEN [Market Name] = 'Oil - US Crude ($1)' THEN 100 ELSE CAST([Lot Size] AS DECIMAL(16,6)) END)*
			(CASE WHEN CAST([Deal Size] AS DECIMAL(16,6)) < 0 THEN 1 ELSE -1 END)) AS IG_LocalAmount
		,MAX(f.IG_FXRate)*
		 SUM(ABS(CAST(lp.[Deal Level] AS DECIMAL(16,6))*
			CAST(lp.[Deal Size] AS DECIMAL(16,6)))*
			(CASE WHEN [Market Name] = 'Oil - US Crude ($1)' THEN 100 ELSE CAST([Lot Size] AS DECIMAL(16,6)) END)*
			(CASE WHEN CAST([Deal Size] AS DECIMAL(16,6)) < 0 THEN 1 ELSE -1 END)) AS IG_AmountUSD
		,MAX(f.IG_FXRate) AS IG_FXRate
FROM [Dealing_staging].[LP_IG_OH_OrderHistory] lp  with (NOLOCK) 
LEFT JOIN #Ins i
ON i.MarketName = lp.[Market Name] AND i.InstrumentID IS NOT NULL
LEFT JOIN #IG_FXRates f
ON lp.Ccy = f.CurrencyPrimary
WHERE ReportDateID = @TotalDateID AND lp.Result NOT LIKE '%Rejected:%'
GROUP BY ReportDateID
		,lp.[Market Name]
		,lp.[Account ID]
		,i.InstrumentID
		,i.InstrumentDisplayName
		,lp.ISIN --?
		,lp.Ccy
		,CASE WHEN CAST([Deal Size] AS DECIMAL(16,6)) < 0 THEN 'Sell' ELSE 'Buy' END


IF OBJECT_ID('tempdb..#Trades_Final') IS NOT NULL 
DROP TABLE #Trades_Final
CREATE TABLE #Trades_Final
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS

SELECT @TotalDate AS Date,
	   tse.HedgeServerID,
	   ig.Account_Number,
	   tse.InstrumentID,
	   ISNULL(tse.InstrumentDisplayName, ig.InstrumentDisplayName) AS InstrumentDisplayName,
	   tse.Symbol,
	   ISNULL(tse.ISINCode, ig.ISINCode) AS ISINCode,
	   ISNULL(tse.[Buy/Sell], ig.[Buy/Sell]) AS [Buy/Sell],
	   ISNULL(tse.CurrencyPrimary, ig.CurrencyPrimary) AS CurrencyPrimary,
	   ISNULL(tse.Exchange, 0) AS Exchange,
	   ISNULL(ig.IG_Units, 0) AS IG_Units,
	   ISNULL(tse.eToro_Units, 0) AS eToro_Units,
	   ISNULL(tse.ClientUnits, 0) AS Clients_Units,
	   ISNULL(ig.IG_Units, 0)- ISNULL(tse.eToro_Units, 0) AS [IG-eToro_Units],
	   ISNULL(ig.IG_Units, 0)- ISNULL(tse.ClientUnits, 0) AS [IG-Clients_Units],
	   ISNULL(ig.IG_LocalAmount, 0) AS IG_LocalAmount,
	   ISNULL(tse.eToroLocalAmount, 0) AS eToro_LocalAmount,
	   ISNULL(ig.IG_LocalAmount, 0)- ISNULL(tse.eToroLocalAmount, 0) AS [IG-eToro_LocalAmount],
	   ISNULL(ig.IG_AmountUSD, 0) AS IG_AmountUSD,
	   ISNULL(tse.eToroAmountUSD, 0) AS eToro_AmountUSD,
	   ISNULL(tse.ClientAmountUSD, 0) AS Clients_AmountUSD,
	   ISNULL(ig.IG_AmountUSD, 0)- ISNULL(tse.eToroAmountUSD, 0) AS [IG-eToro_AmountUSD],
	   ISNULL(ig.IG_AmountUSD, 0)- ISNULL(tse.ClientAmountUSD, 0) AS [IG-Clients_AmountUSD],
	   ISNULL(ig.IG_Rate, 0) AS IG_Rate,
	   ISNULL(tse.eToroRate, 0) AS eToro_Rate,
	   ISNULL(ig.IG_Rate, 0)- ISNULL(tse.eToroRate, 0) AS [IG-eToro_Rate], 
	   ISNULL(tse.FXratetoUSD,0) AS eToro_FXRate,
	   ISNULL(ig.IG_FXRate,0) AS IG_FXRate
FROM #IG_Trades_Final ig
FULL OUTER JOIN #eToroSide_Trades_Final tse
ON tse.InstrumentID = ig.InstrumentID AND tse.[Buy/Sell] = ig.[Buy/Sell] AND ig.Account_Number = tse.AccountID

--select * from #Trades_Final

--------------------------
--Final Tables

DELETE FROM [Dealing_dbo].[Dealing_IGReconEODHolding] WHERE Date = @TotalDate

INSERT INTO [Dealing_dbo].[Dealing_IGReconEODHolding]
	 (Date,
	  HedgeServerID,
	  Account_Number,
	  InstrumentID,
	  InstrumentDisplayName,
	  Symbol,
	  ISINCode,
	  CurrencyPrimary,
	  Exchange,
	  IG_Units,
	  eToro_Units,
	  Clients_Units,
	  [IG-eToro_Units],
	  [IG-Clients_Units],
	  IG_LocalAmount,
	  eToro_LocalAmount,
	  [IG-eToro_LocalAmount],
	  IG_AmountUSD,
	  eToro_AmountUSD,
	  Clients_AmountUSD,
	  [IG-eToro_AmountUSD],
	  [IG-Clients_AmountUSD], 
	  IG_Rate,
	  eToro_Rate,
	  [IG-eToro_Rate], 
	  IG_FXRate,
	  eToro_FXRate,
	  [UpdateDate])
SELECT	
Date,
HedgeServerID,
Account_Number,
InstrumentID,
InstrumentDisplayName,
Symbol,
ISINCode,
CurrencyPrimary,
Exchange,
IG_Units,
eToro_Units,
Clients_Units,
[IG-eToro_Units],
[IG-Clients_Units],
IG_LocalAmount,
eToro_LocalAmount,
[IG-eToro_LocalAmount],
IG_AmountUSD,
eToro_AmountUSD,
Clients_AmountUSD,
[IG-eToro_AmountUSD],
[IG-Clients_AmountUSD], 
IG_Rate,
eToro_Rate,
[IG-eToro_Rate], 
IG_FXRate,
eToro_FXRate,
GETDATE()
FROM #EOD_Final  
WHERE @Is_Saturday = 0

DELETE FROM [Dealing_dbo].[Dealing_IGReconTrades] WHERE Date = @TotalDate

INSERT INTO [Dealing_dbo].[Dealing_IGReconTrades]
	 (Date,
	  HedgeServerID,
	  Account_Number,
	  InstrumentID,
	  InstrumentDisplayName,
	  Symbol,
	  ISINCode,
	  [Buy/Sell],
	  CurrencyPrimary,
	  IG_Units,
	  eToro_Units,
	  Clients_Units,
	  [IG-eToro_Units],
	  [IG-Clients_Units],
	  IG_Rate,
	  eToro_Rate,
	  [IG-eToro_Rate], 
	  IG_LocalAmount,
	  eToro_LocalAmount,
	  [IG-eToro_LocalAmount],
	  IG_AmountUSD,
	  eToro_AmountUSD,
	  Clients_AmountUSD,
	  [IG-eToro_AmountUSD],
	  [IG-Clients_AmountUSD], 
	  IG_FXRate,
	  eToro_FXRate,
	  Exchange,
	  [UpdateDate])
SELECT
Date,
HedgeServerID,
Account_Number,
InstrumentID,
InstrumentDisplayName,
Symbol,
ISINCode,
[Buy/Sell],
CurrencyPrimary,
IG_Units,
eToro_Units,
Clients_Units,
[IG-eToro_Units],
[IG-Clients_Units],
IG_Rate,
eToro_Rate,
[IG-eToro_Rate], 
IG_LocalAmount,
eToro_LocalAmount,
[IG-eToro_LocalAmount],
IG_AmountUSD,
eToro_AmountUSD,
Clients_AmountUSD,
[IG-eToro_AmountUSD],
[IG-Clients_AmountUSD], 
IG_FXRate,
eToro_FXRate,
Exchange,
GETDATE()
FROM #Trades_Final
WHERE @Is_Saturday = 0

END
GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `Dealing_staging.LP_IG_PS_EODPositions` | unresolved | Dealing_staging | LP_IG_PS_EODPositions | `—` |
| `Dealing_dbo.Dealing_Duco_EODRecon` | synapse | Dealing_dbo | Dealing_Duco_EODRecon | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Duco_EODRecon.md` |
| `Dealing_staging.External_Fivetran_dealing_active_hs_mappings` | unresolved | Dealing_staging | External_Fivetran_dealing_active_hs_mappings | `—` |
| `DWH_dbo.Dim_Instrument` | synapse | DWH_dbo | Dim_Instrument | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `LP_IG_PS_EODPositions.Position` | unresolved | LP_IG_PS_EODPositions | Position | `—` |
| `Dealing_Duco_EODRecon.eToro_Units` | unresolved | Dealing_Duco_EODRecon | eToro_Units | `—` |
| `Dealing_Duco_EODRecon.ClientUnits` | unresolved | Dealing_Duco_EODRecon | ClientUnits | `—` |
| `Dealing_Duco_EODRecon.eToroLocalAmount` | unresolved | Dealing_Duco_EODRecon | eToroLocalAmount | `—` |
| `Dealing_Duco_EODRecon.eToroUSDAmount` | unresolved | Dealing_Duco_EODRecon | eToroUSDAmount | `—` |
| `Dealing_Duco_EODRecon.ClientAmount` | unresolved | Dealing_Duco_EODRecon | ClientAmount | `—` |
| `LP_IG_PS_EODPositions.Latest` | unresolved | LP_IG_PS_EODPositions | Latest | `—` |
| `Dealing_Duco_EODRecon.eToroRate` | unresolved | Dealing_Duco_EODRecon | eToroRate | `—` |
| `Dealing_Duco_EODRecon.FXratetoUSD` | unresolved | Dealing_Duco_EODRecon | FXratetoUSD | `—` |
| `Dealing_dbo.SP_IGRecon` | synapse_sp | Dealing_dbo | SP_IGRecon | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\Dealing_dbo\Stored Procedures\Dealing_dbo.SP_IGRecon.sql` |
| `DWH_dbo.Dim_Date` | unresolved | DWH_dbo | Dim_Date | `—` |
| `Dealing_staging.LP_IG_PS_EODPositions_daily` | unresolved | Dealing_staging | LP_IG_PS_EODPositions_daily | `—` |
| `Dealing_staging.LP_IG_OH_OrderHistory` | unresolved | Dealing_staging | LP_IG_OH_OrderHistory | `—` |
| `Dealing_dbo.Dealing_Duco_ActivityRecon` | synapse | Dealing_dbo | Dealing_Duco_ActivityRecon | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Duco_ActivityRecon.md` |
| `Dealing_dbo.Dealing_IGReconTrades` | synapse | Dealing_dbo | Dealing_IGReconTrades | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_IGReconTrades.md` |
