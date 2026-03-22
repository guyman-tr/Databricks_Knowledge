# Dealing_Daily_Slippage_Positions_TriggerVSReceived

## 1. Business Meaning

Row-level daily position slippage using the **Trigger-vs-Received** (TVR) method. For every position that opened or closed on a given date, records the slippage between:

- **`RequestOccurred_CustomerChosenRate`** — the eToro market price at the exact moment the close/open request arrived at the system, adjusted for spread
- **`EndForexRate`** — the actual execution rate (from `DWH_dbo.Dim_Position`)

Added 2023-08-22 (SR-223256 / Nikos Kontos request) as a more accurate slippage measurement than the earlier "Request vs Received" metric which used a static customer-chosen rate.

**Why TVR is more accurate:** For a Stop Loss, `CustomerChosenRate` = the SL rate set days ago. But market may have gapped past it. `RequestOccurred_CustomerChosenRate` = the actual eToro market price at the instant the SL triggered and the request reached the system, which is the fair benchmark for measuring execution quality.

**Contains PII:** `CID` (customer ID). Handle under data classification policy.

**Scale:** 161M rows, 2023-08-23 to 2025-01-11 (~2.5 months stale as of 2026-03-21).

**ActionType values:** Manual Close, Stop Loss, Take Profit, Manual Open, Order, OpenOpen.

## 2. Business Logic

### 2.1 Position Sources

Three types of positions are included (from `#Main`):
1. **Closed positions** (`#Closed`): `CloseDateID = @DateID` — positions that closed on the date
2. **Opened positions** (`#Opened`): `OpenDateID = @DateID` — positions that opened on the date
3. **OpenOpen positions** (`#OpenOpen`): `IsOpenOpen=1, OpenDateID=@DateID` — positions that reopened

**Filters applied:** `IsValidCustomer=1`, `MirrorID=0`, `ParentPositionID=0`, `ReopenForPositionID IS NULL`. Excludes internal customers and mirror trades.

### 2.2 RequestOccurred_CustomerChosenRate Derivation

The TVR price is derived in `#PriceFromRequestOccurred`:
```sql
CROSS APPLY (
  SELECT TOP 1 * FROM #CurrencyPrice E
  WHERE E.InstrumentID = D.InstrumentID
    AND E.ReceivedOnPriceServer <= D.RequestCloseOccurred
  ORDER BY PriceOccurred DESC
) A
```
Then in `#TotalData`:
```sql
RequestOccurred_CustomerChosenRate =
  CASE WHEN ActionType IN ('Manual Close', 'Take Profit', 'Stop Loss') THEN
    CASE IsBuy WHEN 1 THEN Bid - Spread ELSE Ask + Spread END
  ELSE  -- Open
    CASE IsBuy WHEN 1 THEN Ask + Spread ELSE Bid - Spread END
  END
```
Where `Spread` is the CBH spread (from Dim_Position InitForexRate/AskSpreaded columns) or HBC commission-per-unit.

If `RequestOccurred_CustomerChosenRate IS NULL` (price lookup failed), the calculation falls back to `CustomerChosenRate`.

### 2.3 Slippage Formulas

```
RequestOccurred_SlippageInPips  = ABS(EndForexRate - RequestOccurred_CustomerChosenRate) × 10^Precision
RequestOccurred_SlippageInDollar = (IsBuy=1?+1:-1) × (RequestOccurred_CustomerChosenRate - EndForexRate) × AmountInUnitsDecimal × ConversionRate
RequestOccurred_slippage%        = ±ABS((RequestOccurred_CustomerChosenRate - EndForexRate) / RequestOccurred_CustomerChosenRate)
  (sign matches SlippageInDollar sign; NULL when RequestOccurred_CustomerChosenRate ≤ 0)
```

`ConversionRate` converts instrument currency to USD: 1 for USD instruments, 1/EndForexRate for BuyCurrencyID=1, UnitMargin/InitForexRate for cross.

### 2.4 OverThreshold

`OverThreshold = 1` when `|slippage%| > threshold` where threshold = **0.5%** for all asset classes (Forex, Commodities, Indices, Stocks, ETF, Crypto).

### 2.5 OpenSession

`OpenSession = 1` if the position's `Occurred` (execution time) falls within the first 5 minutes after the instrument's market open (`ExchangeOpenTimeUTC` from `Dealing_staging.External_CalendarDB_Market_MergedDailySchedules`). Higher slippage at open is expected.

### 2.6 Split Adjustments

All rates (CustomerChosenRate, StopRate, LimitRate, EndForexRate, Bid/Ask) are adjusted for stock splits using `DWH_dbo.Dim_HistorySplitRatio` where `Occurred` falls between `MinDate` and `MaxDate`.

## 3. Query Advisory

**Distribution:** ROUND_ROBIN, 161M rows. Always filter by Date. Consider filtering by InstrumentTypeID or HedgingMode to reduce scan.

**PII note:** `CID` is present. Do not expose in unfiltered exports without data classification approval.

**Slippage column to use:** `RequestOccurred_SlippageInDollar` is the primary TVR metric. `RequestOccurred_SlippageInPips` is unsigned (absolute distance); use `[RequestOccurred_slippage %]` for relative comparison.

**NULL CustomerChosenRate:** When `CustomerChosenRate ≤ 0`, `OverThreshold` and `[RequestOccurred_slippage %]` are NULL. Filter or COALESCE accordingly.

```sql
-- Daily TVR slippage P&L by action type
SELECT Date, ActionType, HedgingMode,
       SUM(RequestOccurred_SlippageInDollar) AS net_tvr_slippage_usd,
       COUNT(*) AS position_count,
       SUM(CASE WHEN OverThreshold=1 THEN 1 ELSE 0 END) AS over_threshold_count
FROM Dealing_dbo.Dealing_Daily_Slippage_Positions_TriggerVSReceived
WHERE Date = '2025-01-10'
GROUP BY Date, ActionType, HedgingMode
ORDER BY net_tvr_slippage_usd ASC

-- Stop Loss slippage deep-dive (find worst-executing instruments)
SELECT TOP 20 InstrumentName, InstrumentType,
    AVG(RequestOccurred_SlippageInDollar) AS avg_tvr_usd,
    SUM(CASE WHEN OverThreshold=1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS over_threshold_pct
FROM Dealing_dbo.Dealing_Daily_Slippage_Positions_TriggerVSReceived
WHERE Date BETWEEN '2024-12-01' AND '2025-01-11'
  AND ActionType = 'Stop Loss'
GROUP BY InstrumentName, InstrumentType
ORDER BY over_threshold_pct DESC
```

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date (UTC). Equals OpenDate (IsOpen=1) or CloseDate (IsOpen=0). Always filter by this column. (Tier 2 — SP_Slippage_Report) |
| PositionID | bigint | FK to `DWH_dbo.Dim_Position.PositionID`. Unique position identifier. (Tier 2 — SP_Slippage_Report) |
| CID | int | Customer ID. PII — FK to `DWH_dbo.Dim_Customer.RealCID`. (Tier 1 — upstream wiki, Customer.CustomerStatic) |
| InstrumentID | int | FK to `DWH_dbo.Dim_Instrument.InstrumentID`. (Tier 1 — upstream wiki, Trade.Instrument) |
| InstrumentName | varchar(45) | Instrument display name from Dim_Instrument. (Tier 2 — SP_Slippage_Report) |
| InstrumentTypeID | int | Numeric asset class ID from Dim_Instrument. Used for #ValuesPerAssetClass threshold lookup. (Tier 2 — SP_Slippage_Report) |
| InstrumentType | varchar(50) | Asset class text label. Values: Stocks, Currencies, Crypto Currencies, Indices, Commodities, ETF. (Tier 2 — SP_Slippage_Report) |
| HedgeServerID | int | Server ID handling the hedge. From Dim_Position. (Tier 2 — SP_Slippage_Report) |
| MirrorID | int | CopyTrader mirror chain ID. Always 0 in this table (mirror trades excluded). (Tier 2 — SP_Slippage_Report) |
| IsBuy | int | 1 = buy (long), 0 = sell (short). **Note:** For closed positions, IsBuy is **inverted** from the original (1→0, 0→1) to represent the closing direction. (Tier 2 — SP_Slippage_Report) |
| OrigIsBuy | int | Original position direction (not inverted). For opens: equals IsBuy. For closes: original open direction. (Tier 2 — SP_Slippage_Report) |
| ExecutionAmountInUnits | decimal(16,8) | Requested amount in units from `CopyFromLake.eToroLogs_Real_Hedge_EMSOrders.RequestedAmountInUnits`. May differ from AmountInUnitsDecimal for partial fills. (Tier 2 — SP_Slippage_Report) |
| AmountInUnitsDecimal | decimal(16,6) | Actual position size in instrument units from Dim_Position, split-adjusted. Used in slippage dollar calculation. (Tier 2 — SP_Slippage_Report) |
| Occurred | datetime | Execution timestamp: CloseOccurred for closes, OpenOccurred for opens. Used for OpenSession calculation. (Tier 2 — SP_Slippage_Report) |
| EndForexRate | decimal(16,8) | Actual LP execution rate from Dim_Position, split-adjusted. The "received" price in TVR. (Tier 2 — SP_Slippage_Report) |
| ConversionRate | decimal(16,8) | USD conversion factor. 1 for USD-denominated instruments (SellCurrencyID=1); 1/EndForexRate for BuyCurrencyID=1; UnitMargin/InitForexRate for cross-currency. (Tier 2 — SP_Slippage_Report) |
| ActionTypeID | int | Close reason code from Dim_ClosePositionReason. 0=Manual Close, 1=Stop Loss, 5=Take Profit, 14=ManualCloseMirror. NULL for opens. (Tier 2 — SP_Slippage_Report) |
| ActionType | varchar(50) | Close reason text. Values: Manual Close, Stop Loss, Take Profit, ManualCloseMirror, Manual Open, Order, OpenOpen. (Tier 2 — SP_Slippage_Report) |
| HedgingMode | varchar(10) | CBH = Clearing Broker Hedging (Apex/BNY); HBC = Hedge By Company. From EMSOrders.HedgeExecutionModeID (1=HBC, else CBH). (Tier 2 — SP_Slippage_Report) |
| Precision | int | Decimal precision for pip calculation. From Dim_Instrument. (Tier 2 — SP_Slippage_Report) |
| IsOpen | int | 1 = position opened on this date, 0 = position closed on this date. (Tier 2 — SP_Slippage_Report) |
| ExecutionID | int | EMS execution ID. InitExecutionID (opens) or EndExecutionID (closes). Used to match EMSOrders. (Tier 2 — SP_Slippage_Report) |
| StopRate | decimal(16,8) | Stop loss rate, split-adjusted. (Tier 2 — SP_Slippage_Report) |
| LimitRate | decimal(16,8) | Take profit rate, split-adjusted. (Tier 2 — SP_Slippage_Report) |
| RequestID | bigint | `CopyFromLake.eToroLogs_Real_Hedge_EMSOrders.ClientRequestID`. Links to the EMS order for ClientViewRate and RequestTime. (Tier 2 — SP_Slippage_Report) |
| ClientViewRate | numeric(16,8) | The rate shown in the eToro UI at the time of the request. From EMSOrders. Used as CustomerChosenRate for Manual Open/Close. (Tier 2 — SP_Slippage_Report) |
| CustomerChosenRate | decimal(16,8) | The rate the customer effectively chose: StopRate (SL), LimitRate (TP), or ClientViewRate (manual). Split-adjusted. Used in the non-TVR slippage calculation. (Tier 2 — SP_Slippage_Report) |
| RequestOccurred_SlippageInPips | money | Absolute slippage in pips between `RequestOccurred_CustomerChosenRate` and `EndForexRate`: `ABS(EndForexRate − RequestOccurred_CustomerChosenRate) × 10^Precision`. (Tier 2 — SP_Slippage_Report) |
| RequestOccurred_SlippageInDollar | money | USD TVR slippage: `(IsBuy=1?+1:-1) × (RequestOccurred_CustomerChosenRate − EndForexRate) × AmountInUnitsDecimal × ConversionRate`. Positive = eToro gains. (Tier 2 — SP_Slippage_Report) |
| [RequestOccurred_slippage %] | decimal(38,21) | Relative TVR slippage: `±ABS((RequestOccurred_CustomerChosenRate − EndForexRate) / RequestOccurred_CustomerChosenRate)`. Sign matches SlippageInDollar. NULL when rate ≤ 0. (Tier 2 — SP_Slippage_Report) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE()). Not a business date. (Tier 2 — SP_Slippage_Report) |
| RequestTime | datetime | Time when the EMS request was received, from EMSOrders. Used to find RequestOccurred price via CROSS APPLY on ReceivedOnPriceServer. (Tier 2 — SP_Slippage_Report) |
| OverThreshold | tinyint | 1 if `|slippage%| > 0.5%` (threshold uniform across all asset classes). NULL when CustomerChosenRate ≤ 0. (Tier 2 — SP_Slippage_Report) |
| OpenSession | int | 1 if execution (`Occurred`) falls within first 5 minutes of the instrument's market open. Higher slippage expected at open. (Tier 2 — SP_Slippage_Report) |
| Volume | int | Position volume (VolumeOnClose for closes, Volume for opens). From Dim_Position. (Tier 2 — SP_Slippage_Report) |
| Regulation | varchar(50) | Customer's regulatory jurisdiction. From `DWH_dbo.Dim_Regulation` via `DWH_dbo.Fact_SnapshotCustomer`. (Tier 2 — SP_Slippage_Report) |

## 5. Lineage

| Source | Role |
|--------|------|
| `DWH_dbo.Dim_Position` | Position data (rates, dates, amounts, flags) |
| `CopyFromLake.eToroLogs_Real_Hedge_EMSOrders` | HedgingMode, ClientViewRate, RequestTime, RequestedAmountInUnits |
| `CopyFromLake.PriceLog_History_CurrencyPrice` | eToro prices for RequestOccurred calculation (CROSS APPLY on ReceivedOnPriceServer ≤ RequestCloseOccurred) |
| `Dealing_staging.External_CalendarDB_Market_MergedDailySchedules` | Market hours for OpenSession and WithinFirst5Minutes |
| `DWH_dbo.Dim_Instrument` | InstrumentType, Precision, currency fields, Exchange |
| `DWH_dbo.Dim_Customer` | IsValidCustomer filter |
| `DWH_dbo.Fact_SnapshotCustomer` + `Dim_Regulation` | Regulation lookup |
| `DWH_dbo.Dim_HistorySplitRatio` | Split adjustments for rates and amounts |
| `DWH_dbo.Dim_ClosePositionReason` | ActionType text |
| `CopyFromLake.etoro_DWH_HistoryOrderForClose/Open` | Order classification (manual vs order) |

**ETL:** `Dealing_dbo.SP_Slippage_Report` → `Dealing_dbo.Dealing_Daily_Slippage_Positions_TriggerVSReceived`

**Introduced:** 2023-08-22 (SR-223256). TVR tables cover 2023-08-23 onward only.

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Daily_Slippage_Totals_TriggerVSReceived` | Aggregation of this table by InstrumentID × ActionType × HedgingMode etc. |
| `Dealing_dbo.Dealing_Daily_Slippage_Positions` | Non-TVR counterpart; uses CustomerChosenRate instead of RequestOccurred_CustomerChosenRate; covers 2017 onward |
| `DWH_dbo.Dim_Position` | Source data; JOIN on PositionID |
| `DWH_dbo.Dim_Customer` | JOIN on CID for customer details |

## 7. Sample Queries

```sql
-- Compare TVR vs traditional slippage for SL positions on a date
SELECT t.PositionID, t.InstrumentName, t.ActionType,
    t.CustomerChosenRate,
    t.RequestOccurred_SlippageInDollar AS tvr_slippage_usd,
    t.RequestOccurred_SlippageInPips AS tvr_pips
FROM Dealing_dbo.Dealing_Daily_Slippage_Positions_TriggerVSReceived t
WHERE Date = '2025-01-10'
  AND ActionType = 'Stop Loss'
  AND OverThreshold = 1
ORDER BY RequestOccurred_SlippageInDollar ASC

-- OpenSession slippage impact
SELECT OpenSession,
    COUNT(*) AS position_count,
    AVG(RequestOccurred_SlippageInDollar) AS avg_tvr_usd,
    SUM(RequestOccurred_SlippageInDollar) AS total_tvr_usd
FROM Dealing_dbo.Dealing_Daily_Slippage_Positions_TriggerVSReceived
WHERE Date BETWEEN '2025-01-01' AND '2025-01-11'
GROUP BY OpenSession
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.
