# BI_DB_dbo.External_Price_History_LastPriceBeforeClose_Range

> 54K-row rolling 7-day snapshot of the last market price before close for ~11,700 instruments, loaded daily from Bronze/Price/History/LastPriceBeforeClose/ Parquet via COPY INTO. Refreshed by SP_Create_External_Price_History_LastPriceBeforeClose_Range which drops and recreates the table each run. Covers bid/ask prices (raw and spreaded), USD conversion rates, and price metadata from the Price DB production pricing infrastructure.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Price.History.LastPriceBeforeClose (AZR-W-PRICEDB-2-Price) via Bronze lake Parquet |
| **Refresh** | Daily — DROP + COPY INTO for trailing 7 days (GETDATE()-7 to GETDATE()-1) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Row Count** | ~54,364 (7 days × ~11,726 instruments; varies with market calendar) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — not yet migrated to Unity Catalog |

---

## 1. Business Meaning

This table provides the **last recorded price before market close** for every tradeable instrument across a rolling 7-day window. It sources directly from the Price DB production infrastructure (`Price.History.LastPriceBeforeClose` on server AZR-W-PRICEDB-2-Price), which captures end-of-day pricing snapshots used by the Closing Price Updater service.

Each row represents one instrument's last price tick before market close on a given trade date. The table captures both raw bid/ask prices and spread-adjusted (spreaded) versions, along with USD conversion rates for non-USD instruments. Two price types exist: PriceType=1 (26.7% of rows, SourceID=NULL — likely forex/crypto with direct pricing) and PriceType=2 (73.3% — standard instrument close prices with SourceID populated).

The SP (`SP_Create_External_Price_History_LastPriceBeforeClose_Range`) uses a destructive DROP + COPY INTO pattern — the table is completely rebuilt each run from Parquet files in the Bronze data lake layer. It loads data day-by-day in a WHILE loop, using Managed Identity authentication against the `internal-sources` external data source. AUTO_CREATE_TABLE is enabled, meaning the table schema is inferred from the Parquet structure on each run.

**Data note**: The column name `InsretDate` is a typo preserved from the production Price DB DDL (should be "InsertDate"). This typo exists in both the production table and the Synapse copy.

---

## 2. Business Logic

### 2.1 Rolling 7-Day Window

**What**: The table always contains exactly 7 calendar days of price data.
**Columns Involved**: TradeDate, InsretDate
**Rules**:
- Window spans GETDATE()-7 to GETDATE()-1 (yesterday is the most recent day)
- The entire table is dropped and rebuilt on each SP execution
- No historical data is preserved — only the trailing week exists at any time

### 2.2 Price Type Classification

**What**: Two distinct pricing categories coexist in the table.
**Columns Involved**: PriceType, SourceID
**Rules**:
- PriceType=1: ~27% of rows, SourceID is NULL — forex/crypto instruments with direct market pricing
- PriceType=2: ~73% of rows, SourceID populated (4=primary, 6=secondary, 7=tertiary) — standard instrument close prices from external price providers

### 2.3 Spread-Adjusted Pricing

**What**: Each price tick carries both raw and spread-adjusted versions.
**Columns Involved**: Bid, Ask, BidSpreaded, AskSpreaded, USDConversionRate, USDConversionRateBidSpreaded, USDConversionRateAskSpreaded
**Rules**:
- Raw Bid/Ask represent the market mid-price before eToro spread markup
- BidSpreaded/AskSpreaded include eToro's spread (the difference visible to retail clients)
- USD conversion rates also have spread-adjusted variants for accurate P&L calculation in USD
- For USD-denominated instruments, USDConversionRate = 1.00000000

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP — no distribution key optimization possible. For analytical queries, filter on TradeDate first (only 7 distinct values). InstrumentID is the natural join key to Dim_Instrument.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest close price for an instrument | `WHERE InstrumentID = X AND TradeDate = (SELECT MAX(TradeDate) FROM BI_DB_dbo.External_Price_History_LastPriceBeforeClose_Range)` |
| All prices on a specific date | `WHERE TradeDate = '2026-04-11'` |
| Price spread analysis | Compare `Bid` vs `BidSpreaded` and `Ask` vs `AskSpreaded` |
| Cross-instrument close price comparison | Filter by TradeDate, JOIN to Dim_Instrument for instrument names |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Resolve instrument name, symbol, asset class |

### 3.4 Gotchas

- **Table may be empty during SP execution**: The DROP + COPY INTO pattern means the table briefly does not exist mid-refresh. Queries during this window will fail.
- **InsretDate is a typo**: The column name is "InsretDate" (missing 'e'), not "InsertDate". This matches the production DDL.
- **SourceID is NULL for PriceType=1**: Do not assume SourceID is always populated.
- **No historical data**: Only 7 days exist at any time. For historical pricing, use the Bronze UC table (`dealing.bronze_price_history_lastpricebeforeclose`).
- **AUTO_CREATE_TABLE**: The table schema is inferred from Parquet on each run. If the Parquet schema changes, column types may silently shift.
- **PriceRateID = 0 for PriceType=2**: Most PriceType=2 rows have PriceRateID=0, while PriceType=1 rows have actual PriceRateID values.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available — limited confidence |
| Tier 5 | ETL infrastructure / canonical |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CurrencyPriceID | bigint | YES | Unique identifier for the price tick record in the production Price DB. Production PK component (with InstrumentID + Occurred). (Tier 4 — Price.History.LastPriceBeforeClose) |
| 2 | InstrumentID | int | YES | Unique identifier for the tradeable financial instrument. FK to Dim_Instrument. Production PK component. (Tier 4 — Price.History.LastPriceBeforeClose) |
| 3 | Bid | numeric(16,8) | YES | Raw bid price (highest price a buyer will pay) before eToro spread markup, at the last tick before market close. (Tier 4 — Price.History.LastPriceBeforeClose) |
| 4 | Ask | numeric(16,8) | YES | Raw ask price (lowest price a seller will accept) before eToro spread markup, at the last tick before market close. (Tier 4 — Price.History.LastPriceBeforeClose) |
| 5 | Occurred | datetime2(7) | YES | Timestamp of the last price tick before market close. Sub-second precision. Production PK component (with InstrumentID). (Tier 4 — Price.History.LastPriceBeforeClose) |
| 6 | PriceRateID | bigint | YES | Internal price rate identifier from the pricing engine. 0 for PriceType=2 rows; populated for PriceType=1 (forex/crypto). (Tier 4 — Price.History.LastPriceBeforeClose) |
| 7 | USDConversionRate | numeric(16,8) | YES | USD conversion rate at the time of the price tick. 1.0 for USD-denominated instruments; non-1.0 for instruments priced in other currencies. Used for P&L normalization. (Tier 4 — Price.History.LastPriceBeforeClose) |
| 8 | MarketPriceRateID | bigint | YES | Internal identifier for the market-level price rate, linking to the broader pricing infrastructure. (Tier 4 — Price.History.LastPriceBeforeClose) |
| 9 | BidSpreaded | numeric(16,8) | YES | Spread-adjusted bid price visible to retail clients after eToro markup. For many instruments, equals raw Bid (spread may be zero at close). (Tier 4 — Price.History.LastPriceBeforeClose) |
| 10 | AskSpreaded | numeric(16,8) | YES | Spread-adjusted ask price visible to retail clients after eToro markup. For many instruments, equals raw Ask (spread may be zero at close). (Tier 4 — Price.History.LastPriceBeforeClose) |
| 11 | USDConversionRateBidSpreaded | numeric(16,8) | YES | USD conversion rate with bid-side spread applied. Used to convert non-USD instrument values to USD accounting for spread on the conversion rate itself. (Tier 4 — Price.History.LastPriceBeforeClose) |
| 12 | USDConversionRateAskSpreaded | numeric(16,8) | YES | USD conversion rate with ask-side spread applied. Counterpart to USDConversionRateBidSpreaded for the ask side. (Tier 4 — Price.History.LastPriceBeforeClose) |
| 13 | USDConversionPriceRateID | bigint | YES | Internal price rate identifier for the USD conversion rate tick. Links to the pricing engine record used for the FX conversion. (Tier 4 — Price.History.LastPriceBeforeClose) |
| 14 | PriceType | int | YES | Price classification type. 1=forex/crypto direct pricing (27%, SourceID NULL), 2=standard instrument close price from external providers (73%). (Tier 3 — inferred from data distribution) |
| 15 | InsretDate | date | YES | Date the price record was inserted into the production Price DB. Typo preserved from production DDL (should be "InsertDate"). Default: GETDATE() in production. (Tier 4 — Price.History.LastPriceBeforeClose) |
| 16 | TradeDate | date | YES | The trading date for which this close price applies. Used as the primary date filter. Range: rolling 7 days (GETDATE()-7 to GETDATE()-1). (Tier 4 — Price.History.LastPriceBeforeClose) |
| 17 | SourceID | int | YES | Identifier for the price data provider/source. 4=primary provider (68%), 6=secondary (5%), 7=tertiary (0.5%), NULL for PriceType=1 forex/crypto (27%). (Tier 3 — inferred from data distribution) |
| 18 | etr_y | varchar(max) | YES | ETL partition column: year (YYYY format). (Tier 5 — Generic Pipeline) |
| 19 | etr_ym | varchar(max) | YES | ETL partition column: year-month (YYYY-MM format). (Tier 5 — Generic Pipeline) |
| 20 | etr_ymd | varchar(max) | YES | ETL partition column: year-month-day (YYYY-MM-DD format). (Tier 5 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| CurrencyPriceID | Price.History.LastPriceBeforeClose | CurrencyPriceID | Passthrough |
| InstrumentID | Price.History.LastPriceBeforeClose | InstrumentID | Passthrough |
| Bid | Price.History.LastPriceBeforeClose | Bid | Passthrough |
| Ask | Price.History.LastPriceBeforeClose | Ask | Passthrough |
| Occurred | Price.History.LastPriceBeforeClose | Occurred | Passthrough (datetime → datetime2) |
| PriceRateID | Price.History.LastPriceBeforeClose | PriceRateID | Passthrough |
| USDConversionRate | Price.History.LastPriceBeforeClose | USDConversionRate | Passthrough |
| MarketPriceRateID | Price.History.LastPriceBeforeClose | MarketPriceRateID | Passthrough |
| BidSpreaded | Price.History.LastPriceBeforeClose | BidSpreaded | Passthrough |
| AskSpreaded | Price.History.LastPriceBeforeClose | AskSpreaded | Passthrough |
| USDConversionRateBidSpreaded | Price.History.LastPriceBeforeClose | USDConversionRateBidSpreaded | Passthrough |
| USDConversionRateAskSpreaded | Price.History.LastPriceBeforeClose | USDConversionRateAskSpreaded | Passthrough |
| USDConversionPriceRateID | Price.History.LastPriceBeforeClose | USDConversionPriceRateID | Passthrough |
| PriceType | Price.History.LastPriceBeforeClose | PriceType | Passthrough |
| InsretDate | Price.History.LastPriceBeforeClose | InsretDate | Passthrough |
| TradeDate | Price.History.LastPriceBeforeClose | TradeDate | Passthrough |
| SourceID | Price.History.LastPriceBeforeClose | SourceID | Passthrough |
| etr_y | Generic Pipeline | Partition column | ETL infrastructure |
| etr_ym | Generic Pipeline | Partition column | ETL infrastructure |
| etr_ymd | Generic Pipeline | Partition column | ETL infrastructure |

### 5.2 ETL Pipeline

```
Price.History.LastPriceBeforeClose (AZR-W-PRICEDB-2-Price)
  |-- Generic Pipeline (Append, daily, delta) ---|
  v
Bronze/Price/History/LastPriceBeforeClose/ (Parquet, partitioned by etr_ymd)
  |-- SP_Create_External_Price_History_LastPriceBeforeClose_Range ---|
  |   DROP table + COPY INTO (7-day rolling window, Managed Identity)
  v
BI_DB_dbo.External_Price_History_LastPriceBeforeClose_Range (~54K rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | FK to instrument dimension — resolves symbol, name, asset class |

### 6.2 Referenced By (other objects point to this)

No known consumers in the SSDT repo reference this table.

---

## 7. Sample Queries

### 7.1 Get Latest Close Price for a Specific Instrument

```sql
SELECT InstrumentID, Bid, Ask, BidSpreaded, AskSpreaded, Occurred, TradeDate
FROM [BI_DB_dbo].[External_Price_History_LastPriceBeforeClose_Range]
WHERE InstrumentID = 1261
  AND TradeDate = (SELECT MAX(TradeDate) FROM [BI_DB_dbo].[External_Price_History_LastPriceBeforeClose_Range])
```

### 7.2 Compare Raw vs Spreaded Prices Across All Instruments

```sql
SELECT TOP 100
  r.InstrumentID,
  di.SymbolFull,
  r.TradeDate,
  r.Bid,
  r.BidSpreaded,
  r.Bid - r.BidSpreaded AS BidSpreadDiff,
  r.Ask,
  r.AskSpreaded,
  r.AskSpreaded - r.Ask AS AskSpreadDiff
FROM [BI_DB_dbo].[External_Price_History_LastPriceBeforeClose_Range] r
JOIN [DWH_dbo].[Dim_Instrument] di ON r.InstrumentID = di.InstrumentID
WHERE r.TradeDate = '2026-04-11'
  AND r.PriceType = 2
ORDER BY AskSpreadDiff DESC
```

### 7.3 Daily Instrument Coverage Check

```sql
SELECT TradeDate, COUNT(*) AS instruments, COUNT(DISTINCT PriceType) AS price_types
FROM [BI_DB_dbo].[External_Price_History_LastPriceBeforeClose_Range]
GROUP BY TradeDate
ORDER BY TradeDate
```

---

## 8. Atlassian Knowledge Sources

- [Guidelines Create External tables](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11680317482) — General guidance on external table patterns in Synapse
- [Closing Price Service - Get All Universe](https://etoro-jira.atlassian.net/wiki/spaces/MDT/pages/13649412099) — Architecture of the closing price domain service
- [DB (Closing Price Updater)](https://etoro-jira.atlassian.net/wiki/spaces/MDT/pages/11786813565) — Price DB infrastructure and server details

---

*Generated: 2026-04-27 | Quality: 7.5/10 | Phases: 14/14*
*Tiers: 0 T1, 0 T2, 2 T3, 15 T4, 3 T5 | Elements: 20/20, Logic: 7/10, Lineage: 9/10*
*Object: BI_DB_dbo.External_Price_History_LastPriceBeforeClose_Range | Type: Table | Production Source: Price.History.LastPriceBeforeClose*
