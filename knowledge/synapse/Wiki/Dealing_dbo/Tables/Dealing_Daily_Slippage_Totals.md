# Dealing_Daily_Slippage_Totals

## 1. Business Meaning

Daily aggregated position slippage using the **Request-vs-Received** method (not TVR). For each (InstrumentID × ActionType × HedgingMode × OverThreshold × OpenSession × Regulation × WithinFirst5Minutes_MarketHours × IsSettled) combination, aggregates count, volume, and USD slippage across all positions opened or closed on a given date.

This is the **longest-running slippage aggregate table** in the Dealing schema — data from 2017-01-02, covering every trading day before the TVR method was introduced (2023-08-23). 45.6M rows total.

**Slippage measurement:** Compares `CustomerChosenRate` (the rate the customer effectively chose — SL/TP rate or market rate they saw) against `EndForexRate` (actual LP execution rate). Positive = eToro gains on execution.

**Key difference from TriggerVSReceived tables:** This uses `CustomerChosenRate` (static, from order placement), while TVR tables use `RequestOccurred_CustomerChosenRate` (dynamic, from price at request arrival time). The TVR method is more accurate for SL/TP attribution.

**Last updated:** 2025-01-11 (~2.5 months stale as of 2026-03-21).

## 2. Business Logic

### 2.1 Slippage Formula

```sql
SlippageInDollar = (IsBuy=1?+1:-1) × (CustomerChosenRate - EndForexRate) × AmountInUnitsDecimal × ConversionRate
```

Aggregated as:
```sql
[Total Slippage $]               = SUM(SlippageInDollar)
[Total Profit $]                 = SUM(CASE WHEN SlippageInDollar > 0 THEN SlippageInDollar ELSE 0 END)
[Total Loss $]                   = SUM(CASE WHEN SlippageInDollar < 0 THEN SlippageInDollar ELSE 0 END)
[Total No of Trades]             = COUNT(1)
[Trades with Positive Slippage]  = SUM(CASE WHEN SlippageInDollar > 0 THEN 1 ELSE 0 END)
[Trades with Negative Slippage]  = SUM(CASE WHEN SlippageInDollar < 0 THEN 1 ELSE 0 END)
[Volume of Trades with Positive Slippage] = SUM(CASE WHEN SlippageInDollar > 0 THEN Volume ELSE 0 END)
[Volume of Trades with Negative Slippage] = SUM(CASE WHEN SlippageInDollar < 0 THEN Volume ELSE 0 END)
[Total Volume]                   = SUM(Volume)
```

### 2.2 CustomerChosenRate Logic

| ActionType | CustomerChosenRate |
|------------|-------------------|
| Stop Loss | `StopRate` (split-adjusted) |
| Take Profit | `LimitRate` (split-adjusted) |
| Manual Close | `ClientViewRate` from EMSOrders |
| ManualCloseMirror | `ClientViewRate` from EMSOrders |
| Manual Open | `ClientViewRate` from EMSOrders |
| Order | `ClientViewRate` from EMSOrders |
| OpenOpen | `ClientViewRate` from EMSOrders |

### 2.3 OverThreshold

Asset-class threshold is **0.5%** for all classes (Stocks, FX, Commodities, Indices, ETF, Crypto). `OverThreshold=1` when `ABS((CustomerChosenRate - EndForexRate) / CustomerChosenRate) > 0.005`. NULL when CustomerChosenRate ≤ 0.

### 2.4 WithinFirst5Minutes_MarketHours (added SR-273115, Sep 2024)

`WithinFirst5Minutes_MarketHours = 1` if `RequestCloseOccurred` falls within 5 minutes of the instrument's market open. Populated from `Dealing_staging.External_CalendarDB_Market_MergedDailySchedules`.

This flag identifies positions that close at market open — known high-slippage window.

### 2.5 IsSettled (added SR-276862, Oct 2024)

From `DWH_dbo.Dim_Position.IsSettled`. Indicates whether the position is settled (i.e., delivery has occurred). Relevant for stock and crypto positions.

### 2.6 Position Coverage

Includes Closed, Opened, and OpenOpen positions. Filters: `IsValidCustomer=1`, `MirrorID=0`, no partial-close children, no reopen positions. Split adjustments via `Dim_HistorySplitRatio`.

## 3. Query Advisory

**Distribution:** ROUND_ROBIN, 45.6M rows. Always filter by Date.

**Spaced column names:** All metric columns (`[Total No of Trades]`, `[Total Slippage $]`, etc.) require square bracket quoting in SQL.

**Row granularity:** One row per unique (InstrumentID, ActionType, HedgingMode, OverThreshold, OpenSession, Regulation, WithinFirst5Minutes_MarketHours, IsSettled) combination per day. Multiple rows per instrument per day are normal.

**Prefer TVR table for post-Aug-2023 analysis:** `Dealing_Daily_Slippage_Totals_TriggerVSReceived` uses a more accurate slippage baseline for SL/TP analysis.

```sql
-- Daily net slippage by action type
SELECT Date, ActionType, HedgingMode,
    SUM([Total Slippage $]) AS net_slippage_usd,
    SUM([Total No of Trades]) AS trades,
    SUM([Total Volume]) AS total_volume
FROM Dealing_dbo.Dealing_Daily_Slippage_Totals
WHERE Date BETWEEN '2025-01-01' AND '2025-01-11'
GROUP BY Date, ActionType, HedgingMode
ORDER BY Date DESC, net_slippage_usd ASC

-- OpenSession slippage analysis (first 5 min of market)
SELECT InstrumentType,
    SUM(CASE WHEN OpenSession=1 THEN [Total Slippage $] ELSE 0 END) AS open_session_usd,
    SUM(CASE WHEN OpenSession=0 THEN [Total Slippage $] ELSE 0 END) AS non_open_usd
FROM Dealing_dbo.Dealing_Daily_Slippage_Totals
WHERE Date >= '2024-01-01'
GROUP BY InstrumentType
```

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date (UTC). Always filter by this. (Tier 2 — SP_Slippage_Report) |
| InstrumentID | int | FK to `DWH_dbo.Dim_Instrument.InstrumentID`. (Tier 1 — upstream wiki, Trade.Instrument) |
| InstrumentName | varchar(45) | Instrument display name from Dim_Instrument. (Tier 2 — SP_Slippage_Report) |
| InstrumentType | varchar(50) | Asset class label. Values: Stocks, Currencies, Crypto Currencies, Indices, Commodities, ETF. (Tier 2 — SP_Slippage_Report) |
| ActionType | varchar(50) | Close/open reason: Manual Close, Stop Loss, Take Profit, ManualCloseMirror, Manual Open, Order, OpenOpen. (Tier 2 — SP_Slippage_Report) |
| [Total No of Trades] | int | Count of positions in this group. (Tier 2 — SP_Slippage_Report) |
| [Trades with Positive Slippage] | int | Count of positions where `SlippageInDollar > 0` (eToro gained). (Tier 2 — SP_Slippage_Report) |
| [Trades with Negative Slippage] | int | Count of positions where `SlippageInDollar < 0` (eToro cost). (Tier 2 — SP_Slippage_Report) |
| [Total Slippage $] | money | Net USD slippage = `[Total Profit $] + [Total Loss $]`. Positive = eToro net gain. (Tier 2 — SP_Slippage_Report) |
| [Total Profit $] | money | Sum of positive SlippageInDollar. Amount eToro gained on favorable executions. (Tier 2 — SP_Slippage_Report) |
| [Total Loss $] | money | Sum of negative SlippageInDollar (always ≤ 0). Amount eToro lost on unfavorable executions. (Tier 2 — SP_Slippage_Report) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE()). Not a business date. (Tier 2 — SP_Slippage_Report) |
| OverThreshold | tinyint | 1 if `\|slippage%\| > 0.5%`. NULL when CustomerChosenRate ≤ 0. Used to flag abnormal slippage events. (Tier 2 — SP_Slippage_Report) |
| OpenSession | int | 1 if execution occurred within first 5 minutes of market open. Higher slippage expected at open. (Tier 2 — SP_Slippage_Report) |
| HedgingMode | varchar(10) | CBH = Clearing Broker Hedging (Apex/BNY); HBC = Hedge By Company. (Tier 2 — SP_Slippage_Report) |
| [Volume of Trades with Positive Slippage] | bigint | Sum of Volume for positions with positive slippage. (Tier 2 — SP_Slippage_Report) |
| [Volume of Trades with Negative Slippage] | bigint | Sum of Volume for positions with negative slippage. (Tier 2 — SP_Slippage_Report) |
| [Total Volume] | bigint | Sum of Volume for all positions in this group. (Tier 2 — SP_Slippage_Report) |
| Regulation | varchar(50) | Customer's regulatory jurisdiction at time of trade. From Dim_Regulation via Fact_SnapshotCustomer. (Tier 2 — SP_Slippage_Report) |
| WithinFirst5Minutes_MarketHours | bit | 1 if `RequestCloseOccurred` is within 5 minutes of market open. Added Sep 2024 (SR-273115). NULL for pre-Sep-2024 data. (Tier 2 — SP_Slippage_Report) |
| IsSettled | tinyint | From Dim_Position.IsSettled. 1 = position delivery has settled. Relevant for stocks/crypto. Added Oct 2024 (SR-276862). NULL for pre-Oct-2024 data. (Tier 2 — SP_Slippage_Report) |

## 5. Lineage

| Source | Role |
|--------|------|
| `DWH_dbo.Dim_Position` | Position data (rates, dates, volumes, IsSettled) |
| `CopyFromLake.eToroLogs_Real_Hedge_EMSOrders` | HedgingMode, ClientViewRate (for CustomerChosenRate of manual actions) |
| `CopyFromLake.PriceLog_History_CurrencyPrice` | Prices used in RequestOccurred calculation (not directly in this table's slippage, but part of pipeline) |
| `Dealing_staging.External_CalendarDB_Market_MergedDailySchedules` | Market hours for OpenSession and WithinFirst5Minutes_MarketHours |
| `DWH_dbo.Dim_Instrument` | InstrumentName, InstrumentType, InstrumentTypeID, currency fields |
| `DWH_dbo.Dim_Customer` | IsValidCustomer filter |
| `DWH_dbo.Fact_SnapshotCustomer` + `Dim_Regulation` | Regulation lookup |
| `DWH_dbo.Dim_HistorySplitRatio` | Split adjustments for rates and amounts |
| `DWH_dbo.Dim_ClosePositionReason` | ActionType text |

**ETL:** `Dealing_dbo.SP_Slippage_Report` → `Dealing_dbo.Dealing_Daily_Slippage_Totals`

**Coverage:** 2017-01-02 to 2025-01-11 (45.6M rows).

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Daily_Slippage_Totals_TriggerVSReceived` | TVR variant; uses `RequestOccurred_CustomerChosenRate`; covers 2023-08-23 onward |
| `Dealing_dbo.Dealing_Daily_Slippage_Positions` | Row-level source (not in this batch); this table is its aggregation |
| `DWH_dbo.Dim_Instrument` | JOIN on InstrumentID |

## 7. Sample Queries

```sql
-- Historical trend: monthly net slippage by instrument type
SELECT YEAR(Date) AS yr, MONTH(Date) AS mo, InstrumentType,
    SUM([Total Slippage $]) AS net_slippage_usd,
    SUM([Total No of Trades]) AS trades
FROM Dealing_dbo.Dealing_Daily_Slippage_Totals
WHERE Date >= '2023-01-01'
GROUP BY YEAR(Date), MONTH(Date), InstrumentType
ORDER BY yr DESC, mo DESC, net_slippage_usd ASC

-- CBH vs HBC net comparison for Stop Loss positions
SELECT HedgingMode, Regulation,
    SUM([Total Slippage $]) AS net_usd,
    SUM([Total No of Trades]) AS trades,
    CAST(SUM([Trades with Positive Slippage]) AS FLOAT) / NULLIF(SUM([Total No of Trades]),0) AS positive_rate
FROM Dealing_dbo.Dealing_Daily_Slippage_Totals
WHERE Date BETWEEN '2024-01-01' AND '2024-12-31'
  AND ActionType = 'Stop Loss'
GROUP BY HedgingMode, Regulation
ORDER BY net_usd ASC
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.
