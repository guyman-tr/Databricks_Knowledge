# Dealing_Daily_Slippage_Totals_TriggerVSReceived

## 1. Business Meaning

Daily aggregated position slippage using the **Trigger-vs-Received (TVR)** method. Same structure as `Dealing_Daily_Slippage_Totals` but using `RequestOccurred_SlippageInDollar` instead of `SlippageInDollar` as the slippage metric.

**TVR difference:** Uses `RequestOccurred_CustomerChosenRate` — the eToro market price at the moment the close/open request was received by the system — as the reference point, rather than the static `CustomerChosenRate` (SL/TP rate or the rate shown in the UI when the customer placed the order). This provides a more accurate measure of execution slippage for Stop Loss and Take Profit orders where the order rate was set in advance.

Added 2023-08-22, so this table has data only from **2023-08-23 onward** (13M rows vs 45.6M for non-TVR).

**Missing columns vs non-TVR:** `WithinFirst5Minutes_MarketHours` and `IsSettled` — these were added only to `Dealing_Daily_Slippage_Totals` (SR-273115, SR-276862) and not yet backfilled here.

**Last updated:** 2025-01-11 (~2.5 months stale as of 2026-03-21).

## 2. Business Logic

### 2.1 TVR Slippage Formula

```sql
RequestOccurred_SlippageInDollar =
  (IsBuy=1?+1:-1) × (RequestOccurred_CustomerChosenRate - EndForexRate) × AmountInUnitsDecimal × ConversionRate
```

Aggregated as:
```sql
[Total Slippage $]               = SUM(RequestOccurred_SlippageInDollar)
[Total Profit $]                 = SUM(CASE WHEN RequestOccurred_SlippageInDollar > 0 THEN value ELSE 0 END)
[Total Loss $]                   = SUM(CASE WHEN RequestOccurred_SlippageInDollar < 0 THEN value ELSE 0 END)
[Total No of Trades]             = COUNT(1)
OverThreshold                    = based on ABS((RequestOccurred_CustomerChosenRate - EndForexRate) / RequestOccurred_CustomerChosenRate) > 0.5%
```

### 2.2 RequestOccurred_CustomerChosenRate

The TVR reference price is derived via `CROSS APPLY` on `CopyFromLake.PriceLog_History_CurrencyPrice`:
- Find the last eToro price where `ReceivedOnPriceServer ≤ RequestCloseOccurred`
- Apply split adjustments
- Add spread (CBH: actual spread from InitForex/EndForex columns; HBC: commission / units / convRate / 2)
- Result: the fair market price at the exact instant the request arrived

Falls back to `CustomerChosenRate` when `RequestOccurred_CustomerChosenRate IS NULL`.

### 2.3 Comparison to Non-TVR

| Aspect | `Dealing_Daily_Slippage_Totals` | `Dealing_Daily_Slippage_Totals_TriggerVSReceived` |
|--------|----------------------------------|---------------------------------------------------|
| Slippage reference | CustomerChosenRate (SL/TP rate or UI rate) | RequestOccurred_CustomerChosenRate (market price at request arrival) |
| SL slippage attribution | Measures gap between SL rate and execution | Measures market movement between request arrival and execution |
| History | 2017-01-02 onward | 2023-08-23 onward |
| Extra columns | WithinFirst5Minutes_MarketHours, IsSettled | — (not present) |
| Best use case | Historical trend; regulatory reporting | Execution quality analysis; LP performance |

## 3. Query Advisory

**Distribution:** ROUND_ROBIN, 13M rows. Always filter by Date.

**Spaced column names** (`[Total No of Trades]`, `[Total Slippage $]`, etc.) require square brackets.

**Row granularity:** One row per (InstrumentID, ActionType, HedgingMode, OverThreshold, OpenSession, Regulation) combination per day.

```sql
-- TVR net slippage by instrument type for a period
SELECT InstrumentType,
    SUM([Total Slippage $]) AS tvr_net_usd,
    SUM([Total No of Trades]) AS trades,
    SUM([Total Profit $]) AS gross_gain,
    SUM([Total Loss $]) AS gross_loss
FROM Dealing_dbo.Dealing_Daily_Slippage_Totals_TriggerVSReceived
WHERE Date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY InstrumentType
ORDER BY tvr_net_usd ASC

-- Compare TVR vs non-TVR for the same period
SELECT a.Date, a.InstrumentType, a.ActionType,
    a.[Total Slippage $] AS non_tvr_usd,
    b.[Total Slippage $] AS tvr_usd,
    b.[Total Slippage $] - a.[Total Slippage $] AS tvr_vs_nontvr_diff
FROM Dealing_dbo.Dealing_Daily_Slippage_Totals a
JOIN Dealing_dbo.Dealing_Daily_Slippage_Totals_TriggerVSReceived b
  ON a.Date=b.Date AND a.InstrumentID=b.InstrumentID AND a.ActionType=b.ActionType
     AND a.HedgingMode=b.HedgingMode AND a.Regulation=b.Regulation
WHERE a.Date = '2025-01-10'
```

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date (UTC). Always filter by this. Coverage starts 2023-08-23. (Tier 2 — SP_Slippage_Report) |
| InstrumentID | int | FK to `DWH_dbo.Dim_Instrument.InstrumentID`. (Tier 1 — upstream wiki, Trade.Instrument) |
| InstrumentName | varchar(45) | Instrument display name from Dim_Instrument. (Tier 2 — SP_Slippage_Report) |
| InstrumentType | varchar(50) | Asset class label. Values: Stocks, Currencies, Crypto Currencies, Indices, Commodities, ETF. (Tier 2 — SP_Slippage_Report) |
| ActionType | varchar(50) | Close/open reason: Manual Close, Stop Loss, Take Profit, ManualCloseMirror, Manual Open, Order, OpenOpen. (Tier 2 — SP_Slippage_Report) |
| [Total No of Trades] | int | Count of positions in this group. (Tier 2 — SP_Slippage_Report) |
| [Trades with Positive Slippage] | int | Count where `RequestOccurred_SlippageInDollar > 0` (eToro gained). (Tier 2 — SP_Slippage_Report) |
| [Trades with Negative Slippage] | int | Count where `RequestOccurred_SlippageInDollar < 0` (eToro cost). (Tier 2 — SP_Slippage_Report) |
| [Total Slippage $] | money | Net USD TVR slippage = `SUM(RequestOccurred_SlippageInDollar)`. Positive = eToro net gain. (Tier 2 — SP_Slippage_Report) |
| [Total Profit $] | money | Sum of positive `RequestOccurred_SlippageInDollar`. (Tier 2 — SP_Slippage_Report) |
| [Total Loss $] | money | Sum of negative `RequestOccurred_SlippageInDollar` (always ≤ 0). (Tier 2 — SP_Slippage_Report) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE()). Not a business date. (Tier 2 — SP_Slippage_Report) |
| OverThreshold | tinyint | 1 if `\|tvr_slippage%\| > 0.5%` based on `RequestOccurred_CustomerChosenRate`. NULL when that rate ≤ 0. (Tier 2 — SP_Slippage_Report) |
| OpenSession | int | 1 if execution occurred within first 5 minutes of market open. (Tier 2 — SP_Slippage_Report) |
| HedgingMode | varchar(10) | CBH = Clearing Broker Hedging (Apex/BNY); HBC = Hedge By Company. (Tier 2 — SP_Slippage_Report) |
| [Volume of Trades with Positive Slippage] | bigint | Sum of Volume for positions with positive TVR slippage. (Tier 2 — SP_Slippage_Report) |
| [Volume of Trades with Negative Slippage] | bigint | Sum of Volume for positions with negative TVR slippage. (Tier 2 — SP_Slippage_Report) |
| [Total Volume] | bigint | Sum of Volume for all positions in this group. (Tier 2 — SP_Slippage_Report) |
| Regulation | varchar(50) | Customer's regulatory jurisdiction. From Dim_Regulation via Fact_SnapshotCustomer. (Tier 2 — SP_Slippage_Report) |

## 5. Lineage

Same sources as `Dealing_Daily_Slippage_Totals`. The TVR tables read from the same `#NEW` temp table but use `RequestOccurred_SlippageInDollar` instead of `SlippageInDollar`.

| Source | Role |
|--------|------|
| `DWH_dbo.Dim_Position` | Position data |
| `CopyFromLake.eToroLogs_Real_Hedge_EMSOrders` | HedgingMode, RequestTime, ClientViewRate |
| `CopyFromLake.PriceLog_History_CurrencyPrice` | eToro prices for RequestOccurred calculation |
| `Dealing_staging.External_CalendarDB_Market_MergedDailySchedules` | Market hours for OpenSession |
| `DWH_dbo.Dim_Instrument` | InstrumentName, InstrumentType, etc. |
| `DWH_dbo.Fact_SnapshotCustomer` + `Dim_Regulation` | Regulation |
| `DWH_dbo.Dim_HistorySplitRatio` | Split adjustments |

**ETL:** `Dealing_dbo.SP_Slippage_Report` → `Dealing_dbo.Dealing_Daily_Slippage_Totals_TriggerVSReceived`

**Coverage:** 2023-08-23 to 2025-01-11.

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Daily_Slippage_Totals` | Non-TVR counterpart; older history (2017+); has extra columns (WithinFirst5Minutes_MarketHours, IsSettled) |
| `Dealing_dbo.Dealing_Daily_Slippage_Positions_TriggerVSReceived` | Row-level source; this is its aggregation |

## 7. Sample Queries

```sql
-- Stop Loss TVR slippage by HedgingMode — regulatory view
SELECT Regulation, HedgingMode,
    SUM([Total Slippage $]) AS tvr_net_usd,
    SUM([Trades with Positive Slippage]) * 100.0 / NULLIF(SUM([Total No of Trades]),0) AS positive_rate_pct
FROM Dealing_dbo.Dealing_Daily_Slippage_Totals_TriggerVSReceived
WHERE ActionType = 'Stop Loss'
  AND Date BETWEEN '2024-06-01' AND '2024-12-31'
GROUP BY Regulation, HedgingMode
ORDER BY tvr_net_usd ASC

-- Daily over-threshold rate
SELECT Date,
    SUM(CASE WHEN OverThreshold=1 THEN [Total No of Trades] ELSE 0 END) * 100.0
        / NULLIF(SUM([Total No of Trades]),0) AS over_threshold_pct
FROM Dealing_dbo.Dealing_Daily_Slippage_Totals_TriggerVSReceived
WHERE Date >= '2024-01-01'
GROUP BY Date
ORDER BY Date DESC
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.
