# BI_DB_dbo.BI_DB_Instruments_BidAndAsk

> 460-row daily snapshot of instrument-level bid/ask prices combined with instrument attributes (type, exchange, ISIN, CUSIP, currencies, tradability). One row per instrument that had price candle data yesterday. Sourced from DWH_dbo.Dim_Instrument for attributes and DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted for the latest hourly bid/ask. Daily TRUNCATE + INSERT via SP_Instruments_BidAndAsk. Dominated by Crypto Currencies (80%), Currencies, Commodities, Indices, and a small number of Stocks.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Instrument Reference + Price Snapshot) |
| **Production Source** | Derived — Dim_Instrument attributes + Dim_GetSpreadedPriceCandle60MinSplitted bid/ask by SP_Instruments_BidAndAsk |
| **Refresh** | Daily TRUNCATE + INSERT (SB_Daily) |
| **Synapse Distribution** | HASH(InstrumentID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **OpsDB Priority** | 0 |
| **OpsDB Process** | SB_Daily, ProcessType 1 (SQL) |

---

## 1. Business Meaning

`BI_DB_Instruments_BidAndAsk` is a **daily reference snapshot** that combines instrument master data with the latest bid and ask prices. Each row represents one instrument that had at least one price candle on the previous trading day.

The table holds 460 instruments as of the last refresh (2026-04-13), primarily Crypto Currencies (370, 80%), Currencies/forex (49, 11%), Commodities (22, 5%), Indices (17, 4%), and a small number of Stocks (2). The low stock count is because the price candle source (`Dim_GetSpreadedPriceCandle60MinSplitted`) may not carry all stock instruments — stocks with no recent trading or market-maker quoting would not have candle data.

### Load Pattern

- **Daily TRUNCATE + INSERT**: The entire table is rebuilt each day
- The SP takes yesterday's date (`GETDATE()-1`) and finds the most recent 60-minute candle per instrument from that day
- Uses `ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY AskLastOccurred DESC)` to pick the latest candle (RN=1)
- No historical data retained — always a single-day snapshot

### ISINCountryCode Derivation

The SP derives `ISINCountryCode` from the first 2-3 characters of the ISIN:
- If ISIN length is 0 or 1: returns '-'
- If the 3rd character is numeric: takes first 2 characters (standard country prefix, e.g., 'US', 'GB')
- If the 3rd character is non-numeric: takes first 3 characters (some ISIN formats)

---

## 2. Business Logic

### 2.1 Latest Price Selection

**What**: For each instrument, the most recent hourly candle from yesterday is selected.
**Columns Involved**: Ask, Bid, InstrumentID
**Rules**:
- Source: Dim_GetSpreadedPriceCandle60MinSplitted
- Filter: AskLastOccurred >= yesterday AND < today
- ROW_NUMBER partitioned by InstrumentID, ordered by AskLastOccurred DESC
- Only RN = 1 is kept (latest candle of the day)

### 2.2 Instrument Attribute Enrichment

**What**: Instrument reference data from Dim_Instrument provides static attributes.
**Columns Involved**: All attribute columns (InstrumentID through AllowSell)
**Rules**:
- InstrumentID <> 0 (excludes placeholder)
- ISINCode and CUSIP default to '0' when NULL (ISNULL coercion)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(InstrumentID) distribution. Small table (460 rows) — full scan is instant.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current bid/ask for an instrument | `WHERE Symbol = 'EURUSD'` |
| All crypto instruments with prices | `WHERE InstrumentTypeName = 'Crypto Currencies'` |
| Instruments by exchange | `GROUP BY Exchange` |
| Spread calculation | `SELECT Symbol, Ask - Bid AS spread` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID | Additional attributes not in this snapshot |
| DWH_dbo.Dim_Currency | BuyCurrencyID or SellCurrencyID | Currency details |

### 3.4 Gotchas

- **Single-day snapshot only**: No history retained. For historical bid/ask, query Dim_GetSpreadedPriceCandle60MinSplitted directly
- **Not all instruments**: Only instruments with candle data from yesterday appear. Many stocks may be missing
- **ISINCode/CUSIP = '0'**: NULL values are coerced to '0' string — filter with `ISINCode <> '0'` not `IS NOT NULL`
- **Crypto-dominated**: 80% of rows are crypto — aggregate statistics are heavily weighted toward crypto unless filtered

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki with documented production source |
| Tier 2 | Derived from SP code analysis with high confidence |
| Tier 3 | Inferred from data patterns and naming conventions |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | int | YES | Unique instrument identifier. FK to DWH_dbo.Dim_Instrument. Filtered to exclude placeholder (InstrumentID <> 0). (Tier 1 — DWH_dbo.Dim_Instrument wiki, originally Trade.Instrument) |
| 2 | InstrumentDisplayName | varchar(100) | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 3 | InstrumentTypeID | int | YES | Instrument type category: 1=Currencies (forex), 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Note TypeIDs 3, 7, 8, 9 are unused gaps. (Tier 1 — DWH_dbo.Dim_Instrument wiki, originally Trade.Instrument) |
| 4 | InstrumentTypeName | varchar(50) | YES | Text label for InstrumentTypeID — DWH-computed via CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Renamed from Dim_Instrument.InstrumentType. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 5 | Symbol | varchar(50) | YES | Ticker symbol for the instrument (e.g., AAPL, EURUSD, BTCUSD). Used for display, search, and price feed identification. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 6 | SymbolFull | varchar(50) | YES | Full ticker symbol including exchange suffix or extended identifier. From Dim_Instrument. (Tier 2 — SP_Instruments_BidAndAsk, from Dim_Instrument) |
| 7 | Exchange | varchar(50) | YES | Stock exchange name from Trade.InstrumentMetaData (e.g., Nasdaq, NYSE, LSE, FX). NULL for non-stock instruments. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 8 | ISINCode | varchar(30) | YES | International Securities Identification Number — 12-character alphanumeric code (e.g., US0378331005). Defaulted to '0' when NULL in source. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 9 | ISINCountryCode | varchar(15) | YES | Country code extracted from the first 2-3 characters of ISINCode. '-' if ISIN is missing or too short. Standard: 2-char country prefix (US, GB, DE). (Tier 2 — SP_Instruments_BidAndAsk) |
| 10 | CUSIP | varchar(30) | YES | Committee on Uniform Securities Identification Procedures number — 9-character code for US/Canadian securities. Defaulted to '0' when NULL in source. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 11 | BuyCurrencyID | int | YES | The buy-side asset of the instrument pair. FK to DWH_dbo.Dim_Currency(CurrencyID). For forex: the base currency. For stocks: the asset's own CurrencyID. (Tier 1 — DWH_dbo.Dim_Instrument wiki, Trade.Instrument) |
| 12 | BuyCurrencyName | varchar(30) | YES | Text abbreviation of BuyCurrencyID — denormalized from Dictionary.Currency.Abbreviation. Example: EUR, AAPL, BTC. Renamed from Dim_Instrument.BuyCurrency. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 13 | SellCurrencyID | int | YES | The sell-side (denomination) currency. FK to DWH_dbo.Dim_Currency(CurrencyID). For forex: the quote currency. For stocks: trading denomination (USD, EUR, GBX). (Tier 1 — DWH_dbo.Dim_Instrument wiki, Trade.Instrument) |
| 14 | SellCurrencyName | varchar(30) | YES | Text abbreviation of SellCurrencyID — denormalized from Dictionary.Currency.Abbreviation. Example: USD, EUR, GBX. Renamed from Dim_Instrument.SellCurrency. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 15 | PipDifferenceThreshold | int | YES | Pip difference threshold for the instrument. From Dim_Instrument. Used for spread monitoring and alerting. (Tier 2 — SP_Instruments_BidAndAsk, from Dim_Instrument) |
| 16 | Precision | int | YES | Decimal precision for price display (number of decimal places). From Dim_Instrument. (Tier 2 — SP_Instruments_BidAndAsk, from Dim_Instrument) |
| 17 | Tradable | int | YES | Flag indicating if the instrument is currently tradable: 1=tradable, 0=not tradable. (Tier 1 — DWH_dbo.Dim_Instrument wiki) |
| 18 | AllowBuy | bit | YES | Whether buy (long) orders are allowed for this instrument. From Dim_Instrument. (Tier 2 — SP_Instruments_BidAndAsk, from Dim_Instrument) |
| 19 | AllowSell | bit | YES | Whether sell (short) orders are allowed for this instrument. From Dim_Instrument. (Tier 2 — SP_Instruments_BidAndAsk, from Dim_Instrument) |
| 20 | Ask | decimal(36,6) | YES | Latest ask (offer) price from the most recent hourly candle yesterday. The price at which sellers are willing to sell. From Dim_GetSpreadedPriceCandle60MinSplitted.AskLast. (Tier 2 — SP_Instruments_BidAndAsk, from Dim_GetSpreadedPriceCandle60MinSplitted) |
| 21 | Bid | decimal(36,6) | YES | Latest bid price from the most recent hourly candle yesterday. The price at which buyers are willing to buy. From Dim_GetSpreadedPriceCandle60MinSplitted.BidLast. (Tier 2 — SP_Instruments_BidAndAsk, from Dim_GetSpreadedPriceCandle60MinSplitted) |
| 22 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_Instruments_BidAndAsk. Set to GETDATE(). (Tier 5 — SP_Instruments_BidAndAsk) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| InstrumentID through AllowSell (cols 1-19) | DWH_dbo.Dim_Instrument (Trade.Instrument, Trade.InstrumentMetaData) | Various | Passthrough/rename |
| ISINCountryCode | DWH_dbo.Dim_Instrument | ISINCode | Derived: SUBSTRING of ISIN prefix |
| Ask, Bid | DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted | AskLast, BidLast | Latest candle from yesterday (ROW_NUMBER RN=1) |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Instrument (instrument master, InstrumentID<>0)
  + DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted (hourly candles, yesterday)
    |-- SP_Instruments_BidAndAsk (daily TRUNCATE + INSERT) --|
    |   JOIN on InstrumentID                                  |
    |   ROW_NUMBER per instrument by AskLastOccurred DESC     |
    |   Take RN=1 (latest candle of yesterday)                |
    v
BI_DB_dbo.BI_DB_Instruments_BidAndAsk (460 rows, daily snapshot)
  (Not in Generic Pipeline — _Not_Migrated to UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument master |
| BuyCurrencyID, SellCurrencyID | DWH_dbo.Dim_Currency | Currency lookups |
| Ask, Bid | DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted | Price source |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Bid-Ask Spread for All Forex Pairs

```sql
SELECT Symbol, Bid, Ask, Ask - Bid AS spread,
       CAST((Ask - Bid) / NULLIF(Ask, 0) * 10000 AS decimal(10,2)) AS spread_pips
FROM [BI_DB_dbo].[BI_DB_Instruments_BidAndAsk]
WHERE InstrumentTypeName = 'Currencies'
ORDER BY spread_pips DESC
```

### 7.2 Crypto Instruments by Exchange

```sql
SELECT Exchange, COUNT(*) AS instruments,
       AVG(Ask) AS avg_ask
FROM [BI_DB_dbo].[BI_DB_Instruments_BidAndAsk]
WHERE InstrumentTypeName = 'Crypto Currencies'
GROUP BY Exchange
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search permission denied).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 13 T1, 8 T2, 0 T3, 0 T4, 1 T5 | Elements: 22/22, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_Instruments_BidAndAsk | Type: Table | Production Source: Derived — Dim_Instrument + Dim_GetSpreadedPriceCandle60MinSplitted*
