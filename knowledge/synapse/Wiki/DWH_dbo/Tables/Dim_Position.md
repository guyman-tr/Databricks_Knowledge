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
| 97 | FullCommissionOnCloseOrig | money | YES | Original FullCommissionOnClose before reopen. ETL default 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group P: Close Reason, Order, and Position Classification (7 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 98 | ClosePositionReasonID | int | YES | Close reason mapped from ActionType. 0=Customer, 1=Stop Loss, 5=Take Profit, 9=Hierarchical Close. (Tier 1 — Trade.PositionTbl) |
| 99 | OpenPositionReasonID | int | YES | Open reason mapped from OpenActionType. 0=Customer, 1=Hierarchical Open, 2=Reopen, 3=Open Open, 13=ACATS_IN. (Tier 1 — Trade.PositionTbl) |
| 100 | OrderID | int | YES | FK to Trade.Orders. Originating order. NULL for corporate action/dividend positions. (Tier 1 — Trade.PositionTbl) |
| 101 | ExitOrderID | int | YES | Order that closed the position (exit order). (Tier 1 — Trade.PositionTbl) |
| 102 | OrderType | int | YES | Dictionary.OrderType at open. 1=OpenTrade, 13=EntryOrder, 16=EntryOrderByUnits, etc. (Tier 1 — Trade.PositionTbl) |
| 103 | ExitOrderType | int | YES | Order type of the exit order. Dictionary.OrderType. (Tier 1 — Trade.PositionTbl) |
| 104 | PositionSegment | smallint | YES | Internal segment classification. (Tier 4 - [UNVERIFIED]) |

#### Group Q: Regulatory Context (1 column)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 105 | RegulationIDOnOpen | int | NO | Regulatory jurisdiction ID at time of position open. ETL-computed via JOIN to etoro_History_BackOfficeCustomer (customer's regulation history). ISNULL(..., 0) when no regulation match found. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group R: Platform and AirDrop (3 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 106 | PlatformTypeID | tinyint | YES | FK to Dim_PlatformType. Platform used to open: 1=Web, 2=iOS, 3=Web, 0=. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 107 | IsAirDrop | int | YES | 1=position was created via an airdrop event (crypto). ETL-computed: JOIN to etoro_Trade_PositionAirdropLog. NULL=not an airdrop. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 108 | IsDiscounted | int | YES | 1=position received a discounted rate. DWH note: CAST from bit to int. (Tier 1 — Trade.PositionTbl) |

#### Group S: Hedge Type (2 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 109 | InitHedgeType | nvarchar(5) | YES | Hedge type at position open: 'HBC' or 'CBH'. Populated by SP_Dim_Position_HedgeType_Real. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 110 | EndHedgeType | nvarchar(5) | YES | Hedge type at position close. Populated by SP_Dim_Position_HedgeType_History. NULL for open positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group T: DLT (Direct Liquidity Trading) (2 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 111 | DLTOpen | smallint | YES | DLT flag at open. Added 2024-06-02 (Ofir A). (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 112 | DLTClose | smallint | YES | DLT flag at close. Added 2024-06-02. NULL for open positions and older positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |

#### Group U: Commission Versioning and P&L Version (2 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 113 | CommissionVersion | int | YES | Version of commission calculation algorithm used. Added 2024-08-22. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 114 | PnLVersion | int | YES | PnL calculation version. (Tier 1 — Trade.PositionTbl) |

#### Group V: Settlement Type (1 column)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 115 | SettlementTypeID | int | YES | Modern settlement classification. Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled. (Tier 1 — Trade.PositionTbl) |

#### Group W: IsComputeForHedge (1 column)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 116 | IsComputeForHedge | smallint | YES | 1 = include in hedge exposure calculation, 0 = exclude. (Tier 1 — Trade.PositionTbl) |

#### Group X: Taxes and Fees (8 columns -- added 2025)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 117 | OpenTotalTaxes | decimal(38,18) | YES | Taxes at open. (Tier 1 — Trade.PositionTbl) |
| 118 | CloseTotalTaxes | decimal(38,18) | YES | Taxes at close. (Tier 1 — Trade.PositionTbl) |
| 119 | OpenTotalFees | decimal(38,18) | YES | Fees at open. (Tier 1 — Trade.PositionTbl) |
| 120 | CloseTotalFees | decimal(38,18) | YES | Fees at close. (Tier 1 — Trade.PositionTbl) |
| 121 | EstimateCloseFeeForCFD | numeric(38,6) | YES | Estimated close fee for CFD positions at end-of-day rates. From Trade.FnGetCloseFee using max-rate closing rate and conversion rate. (Tier 1 — Trade.OpenPositionEndOfDay) |
| 122 | EstimateCloseFeeOnOpenByUnits | numeric(38,6) | YES | Estimated close fee per unit, calculated from open parameters. From Trade.FnGetCloseFeeOnOpen. Alternative fee calculation method based on unit count. (Tier 1 — Trade.OpenPositionEndOfDay) |
| 123 | EstimateCloseFeeOnOpen | numeric(38,8) | YES | Estimated close fee calculated based on position open parameters. From Trade.FnGetCloseFeeOnOpen using OpenTotalFees, InitialLotCount, IsBuy, OpenMarketSpread, units. (Tier 1 — Trade.OpenPositionEndOfDay) |
| 124 | Close_PnLInDollars | decimal(38,6) | YES | Official closing-rate PnL in dollars. From Trade.FnCalculatePnLWrapper using the Close_* prices. The regulated end-of-day position value. (Tier 1 — Trade.OpenPositionEndOfDay) |

#### Group Y: Close-Side Calculation Chain (5 columns -- added 2025-09-08)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 125 | Close_CalculationRate | decimal(16,8) | YES | Official closing rate used for close PnL. Selected from Close_Bid/Ask/Spreaded based on direction and settlement. (Tier 1 — Trade.OpenPositionEndOfDay) |
| 126 | Close_ConversionRate | decimal(26,17) | YES | Conversion rate at official close. Same calculation as CurrentConversionRate but at the closing price point. (Tier 1 — Trade.OpenPositionEndOfDay) |
| 127 | Close_PriceType | int | YES | Price type indicator for the closing price. From History.CurrencyPriceMaxDateClosingPriceWithSplitView.PriceType. (Tier 1 — Trade.OpenPositionEndOfDay) |
| 128 | CurrentCalculationRate | decimal(16,8) | YES | The max-date closing rate used for PnL calculation. From Trade.FnCalculatePnLWrapper. The bid or ask price selected based on IsBuy and IsRealPosition. (Tier 1 — Trade.OpenPositionEndOfDay) |
| 129 | CurrentConversionRate | decimal(26,17) | YES | Currency conversion rate at end-of-day for the max-rate PnL. Computed from end-of-day prices using the conversion instrument pair, direction, and settlement type. (Tier 1 — Trade.OpenPositionEndOfDay) |

#### Group Z: Stop/Limit at Open and Metadata (6 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 130 | StopRateOnOpen | numeric(16,8) | YES | Stop-loss rate as set at the time of open (immutable snapshot). (Tier 4 - [UNVERIFIED]) |
| 131 | LimitRateOnOpen | numeric(16,8) | YES | Take-profit rate as set at the time of open (immutable snapshot). (Tier 4 - [UNVERIFIED]) |
| 132 | IsAirDrop | int | YES | (Duplicate reference -- see Group R #107) (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 133 | UpdateDate | datetime | NO | ETL load timestamp. GETDATE() for new inserts; GETUTCDATE() for updates of existing rows. Not a reliable "data freshness" indicator. (Tier 2 - SP_Dim_Position_DL_To_Synapse) |
| 134 | IsCopyFundPosition | int | YES | (Duplicate reference -- see Group M #84) (Tier 2 — SP_Dim_Position_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| DWH Column Group | Source Table | Source Column | Transform |
|-----------------|--------------|---------------|-----------|
| Core identity, amounts, flags | etoro_Trade_OpenPositionEndOfDay | Various | passthrough (open positions) |
| Core identity, amounts, flags | etoro_History_ClosePositionEndOfDay | Various | passthrough (closed positions) |
| ClosePositionReasonID | etoro_History_ClosePositionEndOfDay | ActionType | rename |
| OpenPositionReasonID | etoro_Trade_OpenPositionEndOfDay | OpenActionType | rename |
| OpenDateID | -- | OpenOccurred | ETL-computed: CONVERT(int, YYYYMMDD) |
| CloseDateID | -- | CloseOccurred | ETL-computed: CONVERT(int, YYYYMMDD) |
| RegulationIDOnOpen | etoro_History_BackOfficeCustomer | RegulationID | ETL-computed: JOIN on CID + date range |
| Volume, VolumeOnClose | -- | AmountInUnitsDecimal + forex rates | ETL-computed: ROUND(units * rate * conversion) |
| IsSettled | -- | IsSettled + InstrumentTypeID | ETL-computed: CASE logic |
| IsReOpen | -- | ReopenForPositionID | ETL-computed: CASE WHEN IS NOT NULL |
| IsCopyFundPosition | -- | TreeID + Ext_Dim_Position_FundCIDs | ETL-computed: JOIN chain to fund accounts |
| IsAirDrop | etoro_Trade_PositionAirdropLog | PositionID | ETL-computed: EXISTS JOIN |
| InitHedgeType / EndHedgeType | -- | InitExecutionID/EndExecutionID | ETL-computed: SP_Dim_Position_HedgeType_* |
| InitForex_*/EndForex_* | PriceLog_History_CurrencyPrice_Active | Ask/Bid/etc. | ETL-computed: JOIN on PriceRateID |
| IsSettled corrections | etoro_History_PositionChangeLog | PreviousIsSettled | ETL-computed: UPDATE via Ext_Dim_Position_PositionChangeLog |
| Amount corrections | etoro_History_PositionChangeLog | PreviousAmount | ETL-computed: UPDATE via Ext_Dim_Position_PositionChangeLogAmount |

### 5.2 ETL Pipeline

```
Daily call: EXEC SP_Dim_Position_DL_To_Synapse @dt='YYYYMMDD'

Step 1: DELETE from Dim_Position WHERE OpenDateID = @Yesterday
        OR (CloseDateID = @Yesterday AND PositionID <> OriginalPositionID) -- partial closes
Step 2: UPDATE Dim_Position -- reset closing positions back to "open" state
        SET CloseOccurred='1900-01-01', CloseDateID=19000101 WHERE CloseDateID = @Yesterday

Step 3: Build staging temp tables
  - etoro_History_BackOfficeCustomer -> #etoro_History_BackOfficeCustomer (deduplicated)
  - etoro_History_PositionChangeLog -> Ext_Dim_Position_PositionChangeLog (IsSettled changes)
  - etoro_History_PositionChangeLog -> Ext_Dim_Position_First_Open
  - etoro_History_PositionChangeLog -> Ext_Dim_Position_PositionChangeLogAmount
  - etoro_BackOffice_Customer -> Ext_Dim_Position_FundCIDs (AccountTypeID=9)
  - etoro_Trade_PositionAirdropLog -> Ext_Dim_Position_AirDrop
  - PriceLog_History_CurrencyPrice_Active -> Ext_Dim_Position_CurrencyPrice_Active

Step 4: Load Ext_Dim_Position_Real (open positions)
  INSERT FROM etoro_Trade_OpenPositionEndOfDay
  LEFT JOIN etoro_Trade_GetInstrument (for IsSettled computation)
  LEFT JOIN #etoro_History_BackOfficeCustomer (for RegulationID)
  WHERE Occurred < @CurrentDate

Step 5: Load Ext_Dim_Position_History_Real (closed positions)
  INSERT FROM etoro_History_ClosePositionEndOfDay
  LEFT JOIN etoro_Trade_GetInstrument
  LEFT JOIN #etoro_History_BackOfficeCustomer
  WHERE CloseOccurred or OpenOccurred in @Yesterday window

Step 6: Apply corrections to Ext tables
  - Update IsSettled from PositionChangeLog
  - Update Amount/StopRate from PositionChangeLogAmount
  - Update IsCopyFundPosition (JOIN to TreeID -> FundCIDs)
  - Update IsAirDrop (JOIN to AirDrop log)
  - Update InitForex_*/EndForex_* from CurrencyPrice_Active
  - Update InitHedgeType/EndHedgeType via SP_Dim_Position_HedgeType_*

Step 7: UPDATE existing Dim_Position rows from Ext_Dim_Position_History_Real
  (for positions that transitioned from open to closed)

Step 8: INSERT new rows from Ext_Dim_Position_History_Real
  (for newly-closed positions not yet in Dim_Position)

Step 9: INSERT new rows from Ext_Dim_Position_Real
  (for today's open positions)

Step 10: Additional SPs:
  - SP_Dim_Position_IsPartialCloseParent
  - SP_Dim_Position_ReOpen
  - SP_Dim_Position_PositionHedgeServerChangeLog
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Target Object | Join Column(s) | Description |
|--------------|----------------|-------------|
| DWH_dbo.Dim_Instrument | InstrumentID | Trading instrument |
| DWH_dbo.Dim_Customer | CID | Customer who opened the position |
| DWH_dbo.Dim_Currency | CurrencyID | Account currency |
| DWH_dbo.Dim_Mirror | MirrorID | Copy-trading relationship |
| DWH_dbo.Dim_ClosePositionReason | ClosePositionReasonID | Why position was closed |
| DWH_dbo.Dim_PlatformType | PlatformTypeID | Platform used |
| DWH_dbo.Dim_Position | TreeID (self-join) | Root copy-tree position |
| DWH_dbo.Dim_Position | ParentPositionID (self-join) | Master position being copied |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_PositionChangeLog | PositionID | Position lifecycle changes |
| DWH_dbo.Dim_PositionHedgeServerChangeLog | PositionID | Hedge server changes per position |
| DWH_dbo.Fact_Position_Futures_Snapshot | PositionID | Futures position snapshot |

---

## 7. Sample Queries

### 7.1 Get recent closed positions for a customer

```sql
SELECT  dp.PositionID,
        dp.CID,
        dp.InstrumentID,
        dp.IsBuy,
        dp.Amount,
        dp.NetProfit,
        dp.OpenOccurred,
        dp.CloseOccurred
FROM    [DWH_dbo].[Dim_Position] dp
WHERE   dp.CID = 10696215
  AND   dp.CloseDateID BETWEEN 20260201 AND 20260310   -- always filter by CloseDateID
  AND   dp.CloseDateID NOT IN (0, 19000101)            -- exclude open and transient
ORDER BY dp.CloseOccurred DESC;
```

### 7.2 Daily P&L summary by instrument (closed positions)

```sql
SELECT  dp.InstrumentID,
        dp.CloseDateID,
        SUM(dp.NetProfit)   AS TotalNetProfit,
        SUM(dp.Commission)  AS TotalCommission,
        COUNT(*)            AS PositionCount
FROM    [DWH_dbo].[Dim_Position] dp
WHERE   dp.CloseDateID = 20260310
  AND   dp.CloseDateID NOT IN (0, 19000101)
GROUP BY dp.InstrumentID, dp.CloseDateID
ORDER BY TotalNetProfit DESC;
```

### 7.3 All currently open positions

```sql
SELECT  dp.PositionID,
        dp.CID,
        dp.InstrumentID,
        dp.Amount,
        dp.NetProfit  AS UnrealizedPnL,
        dp.OpenOccurred
FROM    [DWH_dbo].[Dim_Position] dp
WHERE   dp.CloseDateID = 0
ORDER BY dp.OpenOccurred DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 8.0/10 (***) | Phases: 14/14 (full pipeline)*
*Tiers: 85 T1, 45 T2, 0 T3, 6 T4, 0 T5 | Phases: 1,2,3,5,7,8,9,9B,10,10.5,13,11*
*Object: DWH_dbo.Dim_Position | Type: Table | Production Sources: etoro.Trade.Position + etoro.History.ClosePosition (via ETL staging)*
