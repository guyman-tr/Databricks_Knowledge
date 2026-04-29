# DWH_dbo.Fact_CurrencyPriceWithSplit

> Daily split-adjusted currency/instrument price fact table with ~1.77M rows in 2026 YTD, spanning from 2009-06-15 to present. Stores end-of-day ask/bid prices (raw and spreaded) for all tradeable instruments, with USD conversion rates computed post-load. Refreshed daily via SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse from DataLake staging views. Production source is the PriceLog candle data pipeline (upstream staging views, no resolved production wiki).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView via SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse |
| **Refresh** | Daily (1440 min), delete-insert by OccurredDateID with split re-processing |
| **Synapse Distribution** | HASH(InstrumentID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX + NCI on OccurredDateID |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Merge strategy from Synapse) |

---

## 1. Business Meaning

Fact_CurrencyPriceWithSplit is a daily instrument price snapshot table that records the end-of-day ask and bid prices for every tradeable instrument on the eToro platform. The table contains approximately 1.77M rows for 2026 YTD across 15,415 distinct instruments, with historical data going back to June 2009.

Each row represents a single instrument's price observation for a given date, including both the raw market prices (Ask, Bid) and the spreaded prices (AskSpreaded, BidSpreaded) that include the platform's spread markup. The table also stores a last-execution rate (RateLastEx) and USD conversion rates (ConvertRateIsBuy_1, ConvertRateIsBuy_0) that are computed post-load via a CASE-based currency pair resolution.

The key differentiator of this table (vs a plain price table) is **split adjustment**: when a stock split is detected for an instrument (via `DWH_staging.etoro_History_SplitRatio`), the SP deletes all historical prices for that instrument and re-inserts them from a split-adjusted staging view (`PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory`), ensuring the full price history reflects post-split values.

The table is loaded daily by `SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse`, which takes a `@dt` date parameter. Only ProviderID=1 is observed in recent data. The `isvalid` flag splits roughly 50/50 between valid (1) and invalid (0) prices.

---

## 2. Business Logic

### 2.1 Daily Price Load (Non-Split Path)

**What**: Standard daily price ingestion for instruments without pending splits.
**Columns Involved**: ProviderID, InstrumentID, Occurred, OccurredDate, OccurredDateID, isvalid, AskSpreaded, BidSpreaded, RateLastEx, Ask, Bid, UpdateDate
**Rules**:
- DELETE existing rows for the target OccurredDateID, then INSERT from staging view
- UpdateDate is set to `GETDATE()` at load time (not from source)
- ConvertRateIsBuy_1 and ConvertRateIsBuy_0 are NOT populated in this path (filled by post-insert UPDATE)

### 2.2 Split-Adjusted Re-Insertion

**What**: When stock splits are detected, the SP deletes ALL historical data for the affected instruments and re-inserts from a split-adjusted staging view.
**Columns Involved**: All 14 columns
**Rules**:
- Split detection: check `DWH_staging.etoro_History_SplitRatio` for splits with MinDate on the load date
- If splits found (CountRowsSplit > 0): delete all rows for those InstrumentIDs, re-insert from `PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory`
- ConvertRateIsBuy_1/0 are carried forward from the pre-split data via a temp table join (#ConvertRateIsBuy) using ROW_NUMBER to pick the latest non-null value per date
- Split ratios are also stored in `Ext_FCPWS_History_SplitRatio` helper table

### 2.3 USD Conversion Rate Computation

**What**: Post-insert UPDATE computes USD-equivalent conversion rates for each instrument based on its currency pair composition.
**Columns Involved**: ConvertRateIsBuy_1, ConvertRateIsBuy_0
**Rules**:
- JOIN to `Ext_FCPWS_Instrument` (populated from `DWH_staging.etoro_Trade_GetInstrument`) to get BuyCurrencyID and SellCurrencyID
- **SellCurrencyID = 1 (USD)**: rate = 1.00 (already USD-denominated)
- **BuyCurrencyID = 1 (USD)**: rate = 1.00 / Bid (for IsBuy=1) or 1.00 / Ask (for IsBuy=0)
- **Cross-currency (neither side is USD)**: COALESCE(1.00 / I2Price.Bid, I3Price.Bid, 1.00) for buy; COALESCE(1.00 / I2Price.Ask, I3Price.Ask, 1.00) for sell — finds a USD intermediary pair
- Only applies to rows where OccurredDateID = @DateID (the current load date)

### 2.4 Validity Flag

**What**: The `isvalid` flag distinguishes valid market prices from invalid/stale ones.
**Columns Involved**: isvalid
**Rules**:
- Values: 0 (invalid/stale) and 1 (valid)
- Approximately 50/50 distribution in recent data
- Sourced directly from the staging view; not computed by the SP

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

The table is HASH-distributed on `InstrumentID` and has a clustered columnstore index for optimal compression of the large historical dataset. A non-clustered index on `OccurredDateID` supports efficient date-range filtering. Always include `OccurredDateID` in WHERE clauses for large scans to leverage the NCI.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest price for an instrument | `WHERE InstrumentID = @id AND OccurredDateID = (SELECT MAX(OccurredDateID) FROM ... WHERE InstrumentID = @id AND isvalid = 1)` |
| Price history for date range | `WHERE InstrumentID = @id AND OccurredDateID BETWEEN @start AND @end` |
| All instrument prices for a date | `WHERE OccurredDateID = @dateId` |
| USD-converted price | `SELECT Bid * ConvertRateIsBuy_1 AS BidUSD FROM ... WHERE ConvertRateIsBuy_1 IS NOT NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Resolve instrument name, symbol, type |
| DWH_dbo.Dim_Position | InstrumentID = InstrumentID AND OccurredDateID = OpenDateID | Get opening price for a position |
| DWH_dbo.Dim_HistorySplitRatio | InstrumentID = InstrumentID | Understand split events affecting prices |

### 3.4 Gotchas

- **isvalid = 0 rows**: Nearly half the rows are marked invalid. Always filter `WHERE isvalid = 1` unless you specifically need stale/invalid prices.
- **ConvertRateIsBuy_1/0 NULLs**: 594 NULLs observed in April 2026 data. These occur when no USD conversion path can be resolved for the instrument's currency pair. Do not assume these columns are always populated.
- **Ask vs AskSpreaded divergence**: ~14% of rows have different Ask and AskSpreaded values. AskSpreaded includes the platform spread; Ask is the raw market price. Use the appropriate one based on your analysis goal.
- **Split re-insertion**: After a stock split, ALL historical prices for the instrument are replaced with split-adjusted values. Historical queries run before and after a split event will return different prices for the same instrument/date combination.
- **ProviderID**: Currently always 1 in recent data. Do not hard-code this assumption for historical queries.
- **OccurredDateID format**: Integer YYYYMMDD (e.g., 20260401). Not a date type.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Grounded in DDL + SP code, no upstream wiki available |
| Tier 4 | Inferred from name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ProviderID | int | YES | Price data provider identifier. Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. Currently observed as a single value (1) in all recent data. (Tier 3 — DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView) |
| 2 | InstrumentID | int | YES | Unique identifier for the financial instrument (currency pair, stock, crypto, etc.). Distribution key for the table. Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. FK to Dim_Instrument. 15,415 distinct values in April 2026. (Tier 3 — DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView) |
| 3 | Occurred | datetime | YES | Exact timestamp of the price observation. Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. Represents the last market tick time for this instrument on the given date. (Tier 3 — DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView) |
| 4 | OccurredDate | date | YES | Date portion of the price observation (Occurred truncated to date). Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. (Tier 3 — DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView) |
| 5 | OccurredDateID | int | YES | Integer date key in YYYYMMDD format (e.g., 20260401). Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. Used as the partition/delete key for daily loads and as the NCI column for efficient date-range queries. Range: 20090615 to 20260426. (Tier 3 — DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView) |
| 6 | isvalid | int | YES | Validity flag for the price observation. 0 = invalid/stale price, 1 = valid market price. Approximately 50/50 distribution in recent data. Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView; not computed by the SP. (Tier 3 — DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView) |
| 7 | AskSpreaded | numeric(36,12) | YES | Ask price including the platform's spread markup. This is the price a buyer would pay on the platform. May differ from the raw Ask price (~14% of rows show divergence). Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. (Tier 3 — DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView) |
| 8 | BidSpreaded | numeric(36,12) | YES | Bid price including the platform's spread markup. This is the price a seller would receive on the platform. May differ from the raw Bid price. Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. (Tier 3 — DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView) |
| 9 | RateLastEx | numeric(36,12) | YES | Last execution rate for the instrument on this date. Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. Represents the most recent trade execution price. (Tier 3 — DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView) |
| 10 | Ask | numeric(36,12) | YES | Raw market ask (offer) price without platform spread. This is the underlying market price before eToro's spread is applied. Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. (Tier 3 — DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView) |
| 11 | Bid | numeric(36,12) | YES | Raw market bid price without platform spread. This is the underlying market price before eToro's spread is applied. Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. (Tier 3 — DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView) |
| 12 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() at the time the SP inserts the row. NOT NULL. Does not originate from the source data; reflects when the data was loaded into Synapse. (Tier 2 — SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 13 | ConvertRateIsBuy_1 | numeric(18,4) | YES | USD conversion rate for buy-side transactions. Computed post-insert by the SP via CASE logic: 1.00 if SellCurrencyID = 1 (USD); 1.00 / Bid if BuyCurrencyID = 1; COALESCE(1.00 / I2Price.Bid, I3Price.Bid, 1.00) for cross-currency pairs. NULL when no USD conversion path can be resolved. Added 2023-02-26 by MeravHu. (Tier 2 — SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 14 | ConvertRateIsBuy_0 | numeric(18,4) | YES | USD conversion rate for sell-side transactions. Computed post-insert by the SP via CASE logic: 1.00 if SellCurrencyID = 1 (USD); 1.00 / Ask if BuyCurrencyID = 1; COALESCE(1.00 / I2Price.Ask, I3Price.Ask, 1.00) for cross-currency pairs. NULL when no USD conversion path can be resolved. Added 2023-02-26 by MeravHu. (Tier 2 — SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|--------------|-----------|
| ProviderID | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | ProviderID | Passthrough |
| InstrumentID | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | InstrumentID | Passthrough |
| Occurred | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Occurred | Passthrough |
| OccurredDate | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | OccurredDate | Passthrough |
| OccurredDateID | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | OccurredDateID | Passthrough |
| isvalid | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | isvalid | Passthrough |
| AskSpreaded | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | AskSpreaded | Passthrough |
| BidSpreaded | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | BidSpreaded | Passthrough |
| RateLastEx | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | RateLastEx | Passthrough |
| Ask | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Ask | Passthrough |
| Bid | DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView | Bid | Passthrough |
| UpdateDate | SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse | GETDATE() | ETL timestamp |
| ConvertRateIsBuy_1 | SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse | CASE expression | Computed from Bid prices + currency pair lookup |
| ConvertRateIsBuy_0 | SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse | CASE expression | Computed from Ask prices + currency pair lookup |

### 5.2 ETL Pipeline

```
PriceLog (production candle data — unknown upstream DB)
  |-- Generic Pipeline (Bronze/DataLake export) ---|
  v
DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView (non-split instruments)
DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView_SplitInstHistory (split-adjusted)
DWH_staging.etoro_History_SplitRatio (split event detection)
DWH_staging.etoro_Trade_GetInstrument (currency pair mapping)
  |-- SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse @dt ---|
  |   Step 1: DELETE + INSERT prices for @dt
  |   Step 2: If splits detected, re-insert split-adjusted history
  |   Step 3: UPDATE ConvertRateIsBuy_1/0 via currency pair CASE logic
  v
DWH_dbo.Fact_CurrencyPriceWithSplit (~1.77M rows 2026 YTD)
  |-- Generic Pipeline (Merge, delta, daily) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit (Unity Catalog)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | FK to instrument dimension for name, symbol, type resolution |
| InstrumentID | DWH_dbo.Ext_FCPWS_Instrument | Used by SP for currency pair resolution (BuyCurrencyID, SellCurrencyID) |
| InstrumentID | DWH_dbo.Ext_FCPWS_History_SplitRatio | Split ratio events that trigger historical re-insertion |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID, OccurredDateID | DWH_dbo.SP_CurrencyPriceExists_For_CHECK | Monitoring SP that checks if prices exist for instruments with open positions |
| InstrumentID, Bid, Ask | DWH_dbo.SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse | Self-join for cross-currency USD conversion rate computation |

---

## 7. Sample Queries

### 7.1 Get Latest Valid Price for a Specific Instrument

```sql
SELECT TOP 1
    InstrumentID, OccurredDate, Ask, Bid, AskSpreaded, BidSpreaded,
    ConvertRateIsBuy_1, ConvertRateIsBuy_0
FROM DWH_dbo.Fact_CurrencyPriceWithSplit
WHERE InstrumentID = 9059
  AND isvalid = 1
ORDER BY OccurredDateID DESC
```

### 7.2 Price History with USD Conversion for Date Range

```sql
SELECT
    f.InstrumentID,
    i.Name AS InstrumentName,
    f.OccurredDate,
    f.Bid,
    f.Ask,
    f.Bid * f.ConvertRateIsBuy_1 AS BidUSD,
    f.Ask * f.ConvertRateIsBuy_0 AS AskUSD
FROM DWH_dbo.Fact_CurrencyPriceWithSplit f
JOIN DWH_dbo.Dim_Instrument i ON f.InstrumentID = i.InstrumentID
WHERE f.OccurredDateID BETWEEN 20260401 AND 20260426
  AND f.isvalid = 1
  AND f.ConvertRateIsBuy_1 IS NOT NULL
ORDER BY f.OccurredDate
```

### 7.3 Instruments Missing Prices for Yesterday (Monitoring)

```sql
DECLARE @dateID INT = CAST(CONVERT(VARCHAR(8), DATEADD(DAY, -1, GETDATE()), 112) AS INT)

SELECT p.InstrumentID, i.Name, COUNT(*) AS OpenPositions
FROM DWH_dbo.Dim_Position p
LEFT JOIN DWH_dbo.Fact_CurrencyPriceWithSplit f
    ON p.InstrumentID = f.InstrumentID AND f.OccurredDateID = @dateID
JOIN DWH_dbo.Dim_Instrument i ON p.InstrumentID = i.InstrumentID
WHERE p.OpenDateID = @dateID
  AND f.InstrumentID IS NULL
GROUP BY p.InstrumentID, i.Name
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources searched (regen harness mode).

---

*Generated: 2026-04-28 | Quality: 7/10 | Phases: 13/14*
*Tiers: 0 T1, 3 T2, 11 T3, 0 T4, 0 T5 | Elements: 14/14, Logic: 7/10, Lineage: 8/10*
*Object: DWH_dbo.Fact_CurrencyPriceWithSplit | Type: Table | Production Source: Unknown (dormant — no upstream wiki resolvable; staging views are intermediaries with no documented production origin)*
