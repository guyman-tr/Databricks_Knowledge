# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation]
(
	[DateID] [int] NULL,
	[Date] [date] NULL,
	[Regulation] [varchar](50) NULL,
	[InstrumentID] [int] NULL,
	[InstrumentType] [varchar](50) NULL,
	[UnrealizedCommissionChange] [decimal](16, 6) NULL,
	[UnrealizedFullCommissionChange] [decimal](16, 6) NULL,
	[UnrealizedPnLChange] [decimal](16, 6) NULL,
	[UpdateDate] [datetime] NOT NULL
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

Found 5 upstream wiki(s). Read EACH one in full.


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

### Upstream `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New` — synapse
- **Resolved as**: `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Client_Balance_Aggregate_Level_New.md`

# BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New

> Daily client balance rollup -- same measures as `BI_DB_Client_Balance_CID_Level_New`, aggregated by regulation, geography, account attributes, and transfer flags (no CID). Built in the same ETL run as the CID table from temp table `#RegAgg` (`SUM` over `#CIDAgg` with a wide `GROUP BY`).


| Property                 | Value                                                                                         |
| ------------------------ | --------------------------------------------------------------------------------------------- |
| **Schema**               | BI_DB_dbo                                                                                     |
| **Object Type**          | Table (Fact -- BI reporting layer, aggregate grain)                                           |
| **Production Source**    | Derived -- rollup of `BI_DB_Client_Balance_CID_Level_New` in `SP_Client_Balance_New`          |
| **Refresh**              | Daily                                                                                         |
| **OpsDB**                | Priority 99, ProcessType 3 (same batch as CID Client Balance)                                   |
|                          |                                                                                               |
| **Synapse Distribution** | ROUND_ROBIN                                                                                   |
| **Synapse Index**        | CLUSTERED INDEX (DateID ASC)                                                                  |
|                          |                                                                                               |
| **UC Target**            | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_aggregate_level_new` (expected)    |
| **UC Format**            | Delta                                                                                         |
| **UC Copy Strategy**     | Append, 1440 min (daily)                                                                      |
| **Generic Pipeline ID**  | 943 (sibling of CID Client Balance pipeline)                                                  |


---

## 1. Business Meaning

`BI_DB_Client_Balance_Aggregate_Level_New` is the **aggregate (non-CID) sibling** of `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New`. Every numeric measure in the CID table is **summed** across customers that share the same combination of classification columns (for example `Regulation`, `Label`, `Country`, `TransferDirection`, `IsCreditReportValidCB`, DLT flags, `TanganyStatus`, `US_State`, and calendar attributes).

Use this table for **segment-level** dashboards, regulatory summaries by jurisdiction, and marketing or operations views where customer-level detail is not required. For **customer-level** balance, reconciliation, cycle-gap checks, and audit trails, use `BI_DB_Client_Balance_CID_Level_New` (and remember to `SUM` by `CID` when transfer rows exist).

### Grain and double counting

- **Grain**: One row per unique combination of all `GROUP BY` keys in `#RegAgg` for a given `DateID` (plus `TanganyStatus` and `US_State` where populated).
- **Transfer rows**: `TransferDirection` and credit-valid transfer flags behave as in the CID table. Aggregated rows still represent the split between current and prior regulation or CB-validity paths -- do not mix with CID-level counts without understanding transfer logic (see `BI_DB_Client_Balance_CID_Level_New`).

### Terminology (shared with CID wiki)

- **NWA** -- Non-Withdrawable Amount (bonus principal not cashable).
- **TRS** -- Total Return Swap (crypto settlement type).
- **DLT** -- Distributed Ledger Technology (Tangany wallet context).
- **SDRT** -- Stamp Duty Reserve Tax (UK).
- **C2P** -- Copy to Portfolio (copied trades as independent positions; column tracks related compensation flow per CID wiki).

---

## 2. Business Logic

### 2.1 ETL pattern -- DELETE + INSERT from `#RegAgg`

After `#CIDAgg` is populated (same logic as the CID insert), the SP builds `#RegAgg`:

- `SELECT` from `#CIDAgg` with `SUM(cast(... AS decimal(18,4)))` on all monetary and measure columns.
- `GROUP BY` all dimension keys: `TransferDirection`, `Regulation`, `IsCreditReportValidCB`, `DidRegulationTransfer`, `DidCBValidTransfer`, `DidDLTTransfer`, `IsDLTUser`, `IsEtoroTradingCID`, `eToroTradingGroupUser`, `IsGlenEagleAccount`, `Region`, `FromRegulation`, `ToRegulation`, `AccountType`, `Label`, `Country`, `MifidCategory`, `Club`, `PlayerStatus`, `DateID`, `IsGermanBaFin`, `IsValidCustomer`, `Date`, `YearMonth`, `YearQuarter`, `Year`, `TanganyStatus`, `US_State`.

Then `DELETE ... WHERE DateID = @dateID` and `INSERT INTO BI_DB_Client_Balance_Aggregate_Level_New` selecting from `#RegAgg` with `ISNULL(..., 0)` on most measures, `GETDATE()` for `UpdateDate`, and `NULL` literals for `DepositConversionFee` and `WithdrawConversionFee` (placeholders, same as CID table).

### 2.2 Balance cycle at aggregate level

The **CID-level** balance equation (Opening + flows = Closing) holds per customer path. **Summing** `OpeningBalance` or `ClosingBalance` across this aggregate grain **does not** generally reproduce a single platform-wide balance without careful filters -- many measures are additive at this grain, but interpret totals with finance for official reconciliation.

### 2.3 Internal transfer columns

`InternalTransferDeposits` is loaded from the rolled-up `DepositsInternalTransfer` column in `#RegAgg` (which sums the CID-level internal deposit transfer metric). `InternalTransferWithdraws` rolls up `CashoutsInternalTransfer` from `#CIDAgg` / `#RegAgg`.

---

## 3. Query Advisory

### 3.1 Distribution and indexing

- **ROUND_ROBIN**: No hash key; full scans are typical for broad reporting. Filter on `DateID` to use the clustered index.
- **Clustered index on `DateID`**: Prefer `WHERE DateID = @d` or bounded ranges.

### 3.2 Relationship to CID table

To validate or drill down: join or filter the CID table on the same dimensions, then compare `SUM` of measures to the aggregate row (allowing for floating-point / money rounding).

### 3.3 Data freshness

Loaded in the **same** `SP_Client_Balance_New` execution as `BI_DB_Client_Balance_CID_Level_New` (Priority 99, daily).

### 3.4 View

`V_BI_DB_Client_Balance_Aggregate_Level_New` -- `SELECT * WHERE DateID >= 20200101` (same pattern as CID view with a different cutoff).

---

## 4. Elements

### Confidence Tier Legend

| Stars   | Tiers  | Meaning                                                                      |
| ------- | ------ | ---------------------------------------------------------------------------- |
| 4 stars | Tier 1 | Upstream wiki verbatim (dim names via Dictionary)                            |
| 3 stars | Tier 2 | From Synapse SP code (`SP_Client_Balance_New`) and CID table lineage         |
| 2 stars | Tier 3 | Computed at insert only (`GETDATE()`, NULL placeholders)                     |
| 1 star  | Tier 4 | Inferred from column name -- `[UNVERIFIED]`                                  |


### Dimension and classification (GROUP BY keys)

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 1 | TransferDirection | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TransferDirection) |
| 2 | Regulation | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Regulation) |
| 3 | IsCreditReportValidCB | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.IsCreditReportValidCB) |
| 4 | DidRegulationTransfer | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.DidRegulationTransfer) |
| 5 | DidCBValidTransfer | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.DidCBValidTransfer) |
| 6 | IsEtoroTradingCID | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.IsEtoroTradingCID) |
| 7 | eToroTradingGroupUser | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.eToroTradingGroupUser) |
| 8 | IsGlenEagleAccount | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.IsGlenEagleAccount) |
| 9 | Region | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Region) |
| 10 | FromRegulation | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.FromRegulation) |
| 11 | ToRegulation | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ToRegulation) |
| 12 | AccountType | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.AccountType) |
| 13 | Label | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Label) |
| 14 | Country | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Country) |
| 15 | MifidCategory | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.MifidCategory) |
| 16 | Club | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Club) |
| 17 | PlayerStatus | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PlayerStatus) |

### Date

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 18 | DateID | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.DateID) |

### Balance components

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 19 | OpeningBalance | [money] | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.OpeningBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.OpeningBalance) |
| 20 | Deposits | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Deposits`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Deposits) |
| 21 | CompensationDeposit | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationDeposit`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationDeposit) |
| 22 | Bonus | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Bonus`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Bonus) |
| 23 | Compensation | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Compensation`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Compensation) |
| 24 | CompensationPI | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationPI`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationPI) |
| 25 | CompensationToAffiliate | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationToAffiliate`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationToAffiliate) |
| 26 | NWAAdjustment | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NWAAdjustment`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NWAAdjustment) |
| 27 | NegativeRefill | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NegativeRefill`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NegativeRefill) |
| 28 | Cashouts | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Cashouts`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Cashouts) |
| 29 | CashoutsIncludingRedeem | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CashoutsIncludingRedeem`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CashoutsIncludingRedeem) |
| 30 | CompensationCashouts | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationCashouts`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationCashouts) |
| 31 | CashoutFee | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CashoutFee`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CashoutFee) |
| 32 | Chargeback | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Chargeback`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Chargeback) |
| 33 | Refund | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Refund`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Refund) |
| 34 | OvernightFee | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.OvernightFee`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.OvernightFee) |
| 35 | LostDebt | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.LostDebt`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.LostDebt) |
| 36 | ChargebackLoss | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ChargebackLoss`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ChargebackLoss) |
| 37 | OtherNegatives | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.OtherNegatives`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.OtherNegatives) |
| 38 | Foreclosure | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Foreclosure`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Foreclosure) |
| 39 | CompensationPnLAdjustments | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationPnLAdjustments`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationPnLAdjustments) |
| 40 | CompensationDormantFee | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationDormantFee`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationDormantFee) |
| 41 | ClientBalanceRealizedPnL | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnL`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnL) |
| 42 | ClientBalanceRealizedPnLCFD | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLCFD`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLCFD) |
| 43 | ClientBalanceRealizedPnLRealStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLRealStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLRealStocks) |
| 44 | ClientBalanceRealizedPnLRealCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLRealCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLRealCrypto) |
| 45 | TransferCoins | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TransferCoins`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TransferCoins) |
| 46 | TransferCoinFees | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TransferCoinFees`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TransferCoinFees) |
| 47 | ClosingBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClosingBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClosingBalance) |
| 48 | realizedEquity | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.realizedEquity`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.realizedEquity) |
| 49 | RealCryptoOpenBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.RealCryptoOpenBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.RealCryptoOpenBalance) |

### Sub-balance buckets

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 50 | RealCryptoClosingBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.RealCryptoClosingBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.RealCryptoClosingBalance) |
| 51 | ClientMoneyOpenBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientMoneyOpenBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientMoneyOpenBalance) |
| 52 | ClientMoneyClosingBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientMoneyClosingBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientMoneyClosingBalance) |
| 53 | RealStocksOpeningBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.RealStocksOpeningBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.RealStocksOpeningBalance) |
| 54 | RealStocksClosingBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.RealStocksClosingBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.RealStocksClosingBalance) |
| 55 | ClientBalanceFullCommission | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommission`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommission) |
| 56 | ClientBalanceCommission | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommission`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommission) |

### Commission breakdown

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 57 | ClientBalanceFullCommissionCFD | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionCFD`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionCFD) |
| 58 | ClientBalanceCommissionCFD | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionCFD`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionCFD) |
| 59 | ClientBalanceFullCommissionRealCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionRealCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionRealCrypto) |
| 60 | ClientBalanceCommissionRealCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionRealCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionRealCrypto) |
| 61 | ClientBalanceFullCommissionRealStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionRealStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionRealStocks) |
| 62 | ClientBalanceCommissionRealStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionRealStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionRealStocks) |
| 63 | DividendsPaid | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.DividendsPaid`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.DividendsPaid) |
| 64 | TotalLiability | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalLiability`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalLiability) |

### Liability and position metrics

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 65 | TotalNegativeLiability | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalNegativeLiability`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalNegativeLiability) |
| 66 | WithdrawableLiability | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.WithdrawableLiability`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.WithdrawableLiability) |
| 67 | NegativeWithdrawableLiability | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NegativeWithdrawableLiability`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NegativeWithdrawableLiability) |
| 68 | LiabilityInUsedMargin | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.LiabilityInUsedMargin`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.LiabilityInUsedMargin) |
| 69 | NegativeLiabilityInUsedMargin | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NegativeLiabilityInUsedMargin`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NegativeLiabilityInUsedMargin) |
| 70 | InProcessCashout | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.InProcessCashout`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.InProcessCashout) |
| 71 | NegativeInProcessCashout | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NegativeInProcessCashout`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NegativeInProcessCashout) |
| 72 | NOPCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOPCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOPCrypto) |
| 73 | NOPCryptoCFD | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOPCryptoCFD`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOPCryptoCFD) |
| 74 | NOPStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOPStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOPStocks) |
| 75 | NOPStocksCFD | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOPStocksCFD`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOPStocksCFD) |
| 76 | TotalRealCryptoLoan | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalRealCryptoLoan`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalRealCryptoLoan) |
| 77 | TotalRealCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalRealCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalRealCrypto) |
| 78 | TotalRealStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalRealStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalRealStocks) |
| 79 | PositionPNLCryptoReal | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.PositionPNLCryptoReal`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PositionPNLCryptoReal) |
| 80 | PositionPNLStocksReal | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.PositionPNLStocksReal`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PositionPNLStocksReal) |
| 81 | PositionPNL | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.PositionPNL`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PositionPNL) |
| 82 | AvailableCash | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.AvailableCash`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.AvailableCash) |
| 83 | CashInCopy | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CashInCopy`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CashInCopy) |
| 84 | NOP | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOP`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOP) |
| 85 | PositionAmount | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.PositionAmount`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PositionAmount) |
| 86 | StockOrders | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.StockOrders`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.StockOrders) |
| 87 | actualNWA | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.actualNWA`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.actualNWA) |
| 88 | UsedBonus | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UsedBonus`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UsedBonus) |

### Unrealized changes

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 89 | UnrealizedCommissionChange | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedCommissionChange`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedCommissionChange) |
| 90 | UnrealizedFullCommissionChange | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_L

*[Upstream wiki truncated to 30 KB. Open the file directly if you need more context.]*

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


### Upstream `DWH_dbo.Dim_Regulation` — synapse
- **Resolved as**: `DWH_dbo.Dim_Regulation`
- **Wiki path**: `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md`

# DWH_dbo.Dim_Regulation

> Lookup table defining the 15 regulatory jurisdictions under which eToro operates globally, with DWH-specific grouping (ClusterRegulationID) for analytics aggregation.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Regulation |
| **Refresh** | Daily via SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ID ASC) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_Regulation defines the 15 regulatory jurisdictions under which eToro operates globally. Each regulation represents a financial authority (CySEC, FCA, ASIC, FinCEN, etc.) and maps to an eToro legal entity holding the corresponding license. This classification drives multi-jurisdiction compliance - it determines which rules apply to each customer, what instruments they can trade, what leverage limits are enforced, and how their funds are segregated. (Tier 1 - upstream wiki, Dictionary.Regulation)

RegulationID is one of the most frequently joined columns in the DWH. It is assigned to users at registration (CustomerStatic.RegulationID) and propagated through every subsequent operation - deposits, trading, copy-trading, and compliance reporting. V_Dim_Customer joins Dim_Regulation to resolve the regulation name for every customer.

**DWH vs Production differences**: The DWH strips 6 columns from production (IsUSA, JurisdictionName, BankID, RegulationLongName, RegulationShortName, DefaultRegulationID) and adds 3 DWH-specific columns (DWHRegulationID = ID alias, StatusID = hardcoded 1, ClusterRegulationID = grouping logic). Analysts needing US/non-US split or jurisdiction names should reference the upstream wiki or query production via the Bronze layer.

Loaded daily by SP_Dictionaries_DL_To_Synapse via TRUNCATE+INSERT from DWH_staging.etoro_Dictionary_Regulation. All 15 rows have StatusID=1 (Active). No sentinel row.

---

## 2. Business Logic

### 2.1 ClusterRegulationID Grouping

**What**: The ETL groups certain regulations into a single cluster (ID=1) for analytics aggregation.

**Columns Involved**: `ClusterRegulationID`, `ID`

**Rules**:
- IDs 0 (None), 1 (CySEC), 5 (BVI) -> ClusterRegulationID=1 (grouped as "CySEC/BVI/None" cluster)
- All other IDs -> ClusterRegulationID = ID (each regulation is its own cluster)

**Rationale**: BVI (5) is the non-US fallback regulation for users in jurisdictions without a specific eToro entity. CySEC (1) is the primary EU regulation. None (0) is the sentinel for unassigned users. Grouping them under cluster 1 allows DWH analytics to treat these three as a single reporting unit.

```
ClusterRegulationID mapping:
  ID=0 (None)    -> Cluster 1
  ID=1 (CySEC)   -> Cluster 1
  ID=5 (BVI)     -> Cluster 1
  All others     -> Cluster = ID (FCA=2, NFA=3, ASIC=4, eToroUS=6, ...)
```

### 2.2 DWH Column Gaps vs Production

**What**: The DWH drops 6 production columns that are needed for full compliance analysis.

**Columns Dropped**:
- `IsUSA` - US/non-US jurisdiction flag (critical for instrument availability branching)
- `JurisdictionName` - eToro legal entity name (e.g., "eToro EU", "eToro UK")
- `BankID` - FK to Dictionary.Bank (custodian banking partner)
- `RegulationLongName` - Full formal name (e.g., "Cyprus Securities Exchange Commission")
- `RegulationShortName` - Abbreviated code for compact display
- `DefaultRegulationID` - Self-reference fallback (non-US->BVI, US->eToroUS)

**Impact**: DWH analytics that need US vs non-US split must either hardcode the IDs (6, 7, 8, 12, 14 are US) or join to the Bronze layer. See Section 3.4 Gotchas.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with CLUSTERED INDEX on ID. With 15 rows, REPLICATE is optimal. Join on ID directly.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` is Parquet. Read the entire table for any lookup.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve RegulationID to name in customer data | `LEFT JOIN DWH_dbo.Dim_Regulation r ON r.ID = cs.RegulationID` |
| Group analytics by regulation cluster | `GROUP BY r.ClusterRegulationID` |
| US vs non-US split (without IsUSA) | `WHERE r.ID IN (6, 7, 8, 12, 14)` for US; else non-US |
| Full customer record with regulation | Use `DWH_dbo.V_Dim_Customer` (pre-joins Dim_Regulation) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.CustomerStatic / V_Dim_Customer | ON r.ID = cs.RegulationID | Resolve regulation name per customer |
| DWH_dbo.V_Dim_Customer | Dim_Regulation already joined (INNER JOIN on RegulationID) | Use view instead of re-joining |

### 3.4 Gotchas

- **IsUSA not in DWH**: Production Dictionary.Regulation.IsUSA (US=1, non-US=0) is dropped by ETL. DWH analysts must hardcode: US regulations = IDs 6, 7, 8, 12, 14.
- **DWHRegulationID = ID**: These two columns always have the same value. DWHRegulationID is an ETL alias and appears redundant. Prefer ID for joins.
- **StatusID always 1**: Hardcoded Active for all rows. Not a meaningful filter.
- **Cluster 1 includes 3 regulations**: ClusterRegulationID=1 covers None (0), CySEC (1), and BVI (5). Aggregating by ClusterRegulationID will merge these three.
- **V_Dim_Customer uses INNER JOIN**: V_Dim_Customer has `INNER JOIN Dim_Regulation ON ID = RegulationID`. Customers with NULL RegulationID would be excluded.
- **Production has 6 more columns**: If you need IsUSA, JurisdictionName, or DefaultRegulationID, use the Bronze/staging layer or etoro.Dictionary.Regulation directly.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 - Upstream wiki verbatim | `(Tier 1 - upstream wiki, Dictionary.Regulation)` |
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP code)` |
| ★★☆☆☆ | Tier 3 - Live data | `(Tier 3 - live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | int | NO | Primary key identifying the regulatory authority. 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. Stored in CustomerStatic.RegulationID. (Tier 1 - upstream wiki, Dictionary.Regulation) |
| 2 | Name | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation) |
| 3 | DWHRegulationID | tinyint | YES | ETL-computed alias of ID - always equals ID. `[ID] as [DWHRegulationID]` in SP_Dictionaries_DL_To_Synapse. DWH-specific field not present in production. Use ID for joins. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | Hardcoded 1 (Active) for all rows by ETL (`1 as [StatusID]`). Not present in production Dictionary.Regulation. Not a meaningful filter. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | GETDATE() at SP_Dictionaries reload time. Not a business date. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | YES | GETDATE() at SP_Dictionaries reload time. Same value as UpdateDate since table is TRUNCATE+INSERTed daily. Not present in production. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 7 | ClusterRegulationID | tinyint | YES | ETL-computed grouping: `CASE WHEN ID IN (0,1,5) THEN 1 ELSE ID END`. Groups None (0), CySEC (1), and BVI (5) into cluster 1. All other regulations map to their own ID. Used for analytics aggregation where BVI/CySEC/None are treated as a single reporting unit. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ID | etoro.Dictionary.Regulation | ID | passthrough |
| Name | etoro.Dictionary.Regulation | Name | passthrough |
| DWHRegulationID | - | - | ETL-computed: [ID] aliased as DWHRegulationID |
| StatusID | - | - | ETL-computed: hardcoded 1 |
| UpdateDate | - | - | ETL-computed: GETDATE() |
| InsertDate | - | - | ETL-computed: GETDATE() |
| ClusterRegulationID | - | - | ETL-computed: CASE WHEN ID IN (0,1,5) THEN 1 ELSE ID END |

**Lost from production** (dropped by ETL):

| Production Column | Type | Reason Dropped |
|-------------------|------|----------------|
| IsUSA | tinyint | Not carried to DWH; hardcode IDs 6,7,8,12,14 for US |
| JurisdictionName | varchar(30) | Not carried to DWH |
| BankID | int | Not carried to DWH |
| RegulationLongName | varchar(100) | Not carried to DWH |
| RegulationShortName | varchar(50) | Not carried to DWH |
| DefaultRegulationID | int | Not carried to DWH |

Full production documentation: see upstream wiki Dictionary/Tables/Dictionary.Regulation.md (quality 9.2, 15 rows documented)

### 5.2 ETL Pipeline

```
etoro.Dictionary.Regulation -> Generic Pipeline -> DWH_staging.etoro_Dictionary_Regulation -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_Regulation
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.Regulation | 15 current rows (IDs 0-14) |
| Staging | DWH_staging.etoro_Dictionary_Regulation | Raw import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Adds DWHRegulationID, StatusID, InsertDate, UpdateDate, ClusterRegulationID. Drops 6 production columns. |
| Target | DWH_dbo.Dim_Regulation | 15 rows |
| Export | Generic Pipeline (daily) | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A - production FKs (BankID, DefaultRegulationID) are dropped by ETL.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.V_Dim_Customer | ID (INNER JOIN on RegulationID) | Pre-joined customer view resolves regulation name |
| DWH_dbo.CustomerStatic | RegulationID | Every customer assigned a regulation at registration |

---

## 7. Sample Queries

### 7.1 List all regulations with cluster groupings
```sql
SELECT
    ID,
    Name,
    DWHRegulationID,
    ClusterRegulationID,
    StatusID
FROM [DWH_dbo].[Dim_Regulation]
ORDER BY ID
```

### 7.2 US vs non-US regulation breakdown
```sql
SELECT
    CASE WHEN ID IN (6, 7, 8, 12, 14) THEN 'US' ELSE 'Non-US' END AS Region,
    ID,
    Name
FROM [DWH_dbo].[Dim_Regulation]
WHERE ID > 0
ORDER BY Region, ID
```

### 7.3 Customer count by regulation cluster
```sql
SELECT
    r.ClusterRegulationID,
    r.Name AS PrimaryRegulationName,
    COUNT(DISTINCT cs.CustomerID) AS customer_count
FROM [DWH_dbo].[CustomerStatic] cs
LEFT JOIN [DWH_dbo].[Dim_Regulation] r ON r.ID = cs.RegulationID
GROUP BY r.ClusterRegulationID, r.Name
ORDER BY customer_count DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-19 | Quality: 8.0/10 (★★★★☆) | Phases: 7/14 (fast-path)*
*Tiers: 2 T1, 5 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 8/10, Relationships: 6/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Regulation | Type: Table | Production Source: etoro.Dictionary.Regulation*


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `BI_DB_dbo.SP_EY_Audit_Auditor_Unrealized_Calculations`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_EY_Audit_Auditor_Unrealized_Calculations.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [BI_DB_dbo].[SP_EY_Audit_Auditor_Unrealized_Calculations] @date [date] AS

     
/**************************************Start Main Comment History******************************************************     
Author:      Guy Manova       
Date:        2023-12-18      
Description: This is a Synapse version of the original Auditors Unrealiaed PnL which runs on AuditDB. that process is too cumbersome and requires too much data transport 
			 and AuditDB resources to run daily, so a series of optimizations on synapse creates the same logic, but only sends the FINAL RESULT to AuditDB.
      
**************************      
** Change History      
**************************      
Date			Author       Description       
   
2023-12-21		Guy M	 	 finalize small bug fixes and QA
2024-01-25		Guy M		 replaced the wrong metrics in the PnL with USD_CR (wrong conversion rates were used. USD_CR represents the EOD CR as computed in PositionPnL
2024-03-18		Guy M		 aligned the computation to the PnLFirst computation (wrapped with case for PnLVersion1 and changed the pnl copute). additional touchpoint will 
							be necessary in the underlying Opened_Positions proc to assign correct prices based on the centralized pnl (Issettled vs. IsDiscounted change) starting 
							from when the PositionPnL will start taking PnL from the central view rather than compute it.
2024-06-17		Guy M		added coercion of IsDiscounted = IsSettled where PnLVersion = 1. this is to keep the calculation simple, while accounting for the fact that
							in production IsDiscounted is no longer used and replaced by IsSettles. otherwise it would be a huge mess of nested case statements. 
2024-06-17		Guy M		using USD_CR for PNL version 1 is wrong. added some coalescing to get as detailed as possible initforex_usdconversionrate to do the correct computation.
2024-07-10		Guy M		added BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation as the regulators want a by-regulation breakdown of the computatations
							which can only be achieved with a daily keeping of the data :(

****************************************End Main Comment History****************************************************/      



BEGIN 

-- DECLARE @date DATE = '20240706'
DECLARE @sdate DATE = CAST(DATEADD(DAY,-1,@date) AS Date) 
DECLARE @sdateID int =CAST(CONVERT(VARCHAR(8), @sdate, 112) AS INT)
DECLARE @edate DATE = @date
DECLARE @edateID int =CAST(CONVERT(VARCHAR(8), @edate, 112) AS INT)
DECLARE @instrumentID INT = 1404
declare @sysstart datetime 
DECLARE @centralPnLStatrDate DATE = '20240331'
set @sysstart = SYSDATETIME()

-- EXEC [BI_DB_dbo].[SP_EY_Audit_Auditor_Unrealized_Calculations] '20240513'

-- if one of the dates needed for the computation is missing, this logic will run the Audit_Opened_Positions proc and build it for that date: 

IF OBJECT_ID('tempdb..#relevant') IS NOT NULL DROP TABLE #relevant -- select * from #relevant

CREATE TABLE #relevant

(
	DateID int NOT NULL
) 
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)

INSERT INTO #relevant VALUES (@sdateID)
INSERT INTO #relevant VALUES (@edateID)
--INSERT INTO #relevant VALUES (20230629)
--INSERT INTO #relevant VALUES (20230628)

IF OBJECT_ID('tempdb..#distinct') IS NOT NULL DROP TABLE #distinct -- select * from #distinct
CREATE TABLE #distinct  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS SELECT DISTINCT DateID 
FROM BI_DB_dbo.BI_DB_EY_Audit_Opened_Positions

---- select MAX( DateID), MIN(DateID) from BI_DB_dbo.BI_DB_EY_Audit_Opened_Positions 

IF OBJECT_ID('tempdb..#add') IS NOT NULL DROP TABLE #add -- select * from #add
CREATE TABLE #add  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT re.DateID, ROW_NUMBER() OVER (ORDER BY re.DateID) AS IndexColumn
FROM #relevant re
LEFT JOIN #distinct di
	ON re.DateID = di.DateID
WHERE di.DateID IS NULL


IF EXISTS (SELECT 1 FROM #add)
BEGIN
    -- build data: run the audit open positions and the rest of the flow

    DECLARE @index INT = 1

    WHILE @index <= (SELECT MAX(a.IndexColumn) FROM #add a)
    BEGIN
        DECLARE @date1 DATE = (SELECT CONVERT(DATE, CONVERT(VARCHAR(8), a.DateID), 112) FROM #add a WHERE a.IndexColumn = @index)
        
        EXEC [BI_DB_dbo].[SP_EY_Audit_Opened_Positions] @date1

        SET @index = @index + 1
    END
END



IF OBJECT_ID('tempdb..#lastOp') IS NOT NULL DROP TABLE #lastOp
CREATE TABLE #lastOp  
    WITH (CLUSTERED COLUMNSTORE INDEX, DISTRIBUTION=HASH(PositionID))
AS
SELECT *
FROM BI_DB_dbo.EY_Audit_Automation_LastOpRate eaalor
WHERE eaalor.LastOpPriceRate IS NOT NULL

-- insert into  BI_DB_dbo.Guy_Test_Runtimes select GETDATE(), datediff(SECOND,@sysstart, GETDATE()) , count(*), ' to to populate  #lastOp' FROM #lastOp


--DECLARE @date DATE = '20230701'
--DECLARE @sdate DATE = CAST(DATEADD(DAY,-1,@date) AS Date) 
--DECLARE @sdateID int =CAST(CONVERT(VARCHAR(8), @sdate, 112) AS INT)
--DECLARE @edate DATE = '20230630'
--DECLARE @edateID int =CAST(CONVERT(VARCHAR(8), @edate, 112) AS INT)
--DECLARE @instrumentID INT = 22

-- SELECT TOP 10 * from #lastOp

IF OBJECT_ID('tempdb..#end2022_ref') IS NOT NULL DROP TABLE #end2022_ref
CREATE TABLE #end2022_ref  
WITH (CLUSTERED INDEX (InstrumentID, OpenDateID), DISTRIBUTION=HASH(PositionID))
AS
--DROP TABLE IF EXISTS #end2022_ref
SELECT *, 'OpenEnd2022' AS PositionTiming
--INTO #end2022_ref
FROM BI_DB_dbo.EY_Audit_Automation_Opened_Positions_End_2022_Baseline eaaop
--WHERE eaaop.InstrumentID IN (@instrumentID) --(40,5005,100020,29,1246,100086,17, 1001,22)



-- insert into  BI_DB_dbo.Guy_Test_Runtimes select GETDATE(), datediff(SECOND,@sysstart, GETDATE()) , count(*), ' to to populate  #end2022_ref' FROM #end2022_ref

-- SELECT top 1000 * from #end2022_ref


--DECLARE @date DATE = '20230701'
--DECLARE @sdate DATE = CAST(DATEADD(DAY,-1,@date) AS Date) 
--DECLARE @sdateID int =CAST(CONVERT(VARCHAR(8), @sdate, 112) AS INT)
--DECLARE @edate DATE = '20230630'
--DECLARE @edateID int =CAST(CONVERT(VARCHAR(8), @edate, 112) AS INT)
--DECLARE @instrumentID INT = 22

IF OBJECT_ID('tempdb..#StartDateOpenPositions') IS NOT NULL DROP TABLE #StartDateOpenPositions -- SELECT * FROM #StartDateOpenPositions
CREATE TABLE #StartDateOpenPositions  
    WITH (CLUSTERED INDEX (InstrumentID, OpenOccurred),DISTRIBUTION=HASH(PositionID))
AS
--DROP TABLE IF EXISTS #StartDateOpenPositions
SELECT eaaop.*, 'OpenEndT1' AS PositionTiming, o.LastOpPriceRate
--INTO #StartDateOpenPositions
FROM BI_DB_dbo.BI_DB_EY_Audit_Opened_Positions eaaop
	LEFT JOIN #lastOp o
		ON eaaop.InstrumentID = o.InstrumentID AND eaaop.OpenDateID = o.OpenDateID AND eaaop.PositionID = o.PositionID
WHERE DateID = @sdateID
 --AND eaaop.InstrumentID IN (@instrumentID) --40,5005,100020,29,1246,100086,17, 1001,22)


-- insert into  BI_DB_dbo.Guy_Test_Runtimes select GETDATE(), datediff(SECOND,@sysstart, GETDATE()) , count(*), ' to to populate  #StartDateOpenPositions' FROM #StartDateOpenPositions




--DECLARE @date DATE = '20230701'
--DECLARE @sdate DATE = CAST(DATEADD(DAY,-1,@date) AS Date) 
--DECLARE @sdateID int =CAST(CONVERT(VARCHAR(8), @sdate, 112) AS INT)
--DECLARE @edate DATE = '20230630'
--DECLARE @edateID int =CAST(CONVERT(VARCHAR(8), @edate, 112) AS INT)
--DECLARE @instrumentID INT = 22


IF OBJECT_ID('tempdb..#StartDateReady') IS NOT NULL DROP TABLE #StartDateReady -- select top 10 * from #StartDateReady
CREATE TABLE #StartDateReady  
    WITH (CLUSTERED INDEX (InstrumentID),DISTRIBUTION=HASH(PositionID))
AS
SELECT er.*, oc.Precision, oc.SpreadTypeID, oc.Bid, oc.Ask, oc.ReferenceBid, oc.ReferenceAsk
FROM #StartDateOpenPositions er
JOIN BI_DB_dbo.EY_Audit_Automation_Position_Open_Configs oc
	ON er.PositionID = oc.PositionID



-- insert into  BI_DB_dbo.Guy_Test_Runtimes select GETDATE(), datediff(SECOND,@sysstart, GETDATE()) , count(*), ' to to populate  #StartDateReady' FROM #StartDateReady

--- in the new centralized PnL, since date XXX, the PnL discount is based on IsSettled, not IsDiscounted. 
---	IN ORDER TO simplify, this just aligns the IsDiscounted to the IsSettled if date > xxx

/*
IF @sdate >= @centralPnLStatrDate
BEGIN

UPDATE #StartDateReady
SET IsDiscounted = IsSettled

END


ELSE
BEGIN
    PRINT '@sdate is not greater than @centralPnLStatrDate. Continuing the stored procedure.';
END;
*/

--DECLARE @date DATE = '20230701'
--DECLARE @sdate DATE = CAST(DATEADD(DAY,-1,@date) AS Date) 
--DECLARE @sdateID int =CAST(CONVERT(VARCHAR(8), @sdate, 112) AS INT)
--DECLARE @edate DATE = '20230630'
--DECLARE @edateID int =CAST(CONVERT(VARCHAR(8), @edate, 112) AS INT)
--DECLARE @instrumentID INT = 22



IF OBJECT_ID('tempdb..#EndDateOpenPositions') IS NOT NULL DROP TABLE #EndDateOpenPositions
CREATE TABLE #EndDateOpenPositions  
    WITH (HEAP,DISTRIBUTION=HASH(PositionID))
AS
SELECT eaaop.*, 'OpenEndT2' AS PositionTiming, o.LastOpPriceRate
FROM BI_DB_dbo.BI_DB_EY_Audit_Opened_Positions eaaop
	LEFT JOIN #lastOp o
		ON eaaop.InstrumentID = o.InstrumentID AND eaaop.OpenDateID = o.OpenDateID AND eaaop.PositionID = o.PositionID
WHERE DateID = @edateID
 --AND eaaop.InstrumentID IN (@instrumentID) --  (40,5005,100020,29,1246,100086,17, 1001,22)

-- insert into  BI_DB_dbo.Guy_Test_Runtimes select GETDATE(), datediff(SECOND,@sysstart, GETDATE()) , count(*), ' to to populate  #EndDateOpenPositions' FROM #EndDateOpenPositions

-- DECLARE @date DATE = '20230701'
--DECLARE @sdate DATE = CAST(DATEADD(DAY,-1,@date) AS Date) 
--DECLARE @sdateID int =CAST(CONVERT(VARCHAR(8), @sdate, 112) AS INT)
--DECLARE @edate DATE = '20230630'
--DECLARE @edateID int =CAST(CONVERT(VARCHAR(8), @edate, 112) AS INT)
--DECLARE @instrumentID INT = 22

IF OBJECT_ID('tempdb..#EndDateReady') IS NOT NULL DROP TABLE #EndDateReady -- select * from #EndDateReady
CREATE TABLE #EndDateReady  
    WITH (CLUSTERED INDEX (InstrumentID),DISTRIBUTION=HASH(PositionID))
AS
SELECT er.*, oc.Precision, oc.SpreadTypeID, oc.Bid, oc.Ask, oc.ReferenceBid, oc.ReferenceAsk
FROM #EndDateOpenPositions er
JOIN BI_DB_dbo.EY_Audit_Automation_Position_Open_Configs oc
	ON er.PositionID = oc.PositionID


-- insert into  BI_DB_dbo.Guy_Test_Runtimes select GETDATE(), datediff(SECOND,@sysstart, GETDATE()) , count(*), ' to to populate  #EndDateReady' FROM #EndDateReady

--- in the new centralized PnL, since date XXX, the PnL discount is based on IsSettled, not IsDiscounted. 
---	IN ORDER TO simplify, this just aligns the IsDiscounted to the IsSettled if date > xxx

/*
IF @edate >= @centralPnLStatrDate
BEGIN

UPDATE #EndDateReady
SET IsDiscounted = IsSettled

END


ELSE
BEGIN
    PRINT '@edate is not greater than @centralPnLStatrDate. Continuing the stored procedure.';
END;
*/

SELECT TOP 1000 sdr.InitConversionRate, sdr.InitForex_USDConversionRate, sdr.OpenMarketUSDConversionRateBidSpreaded 
FROM #StartDateReady sdr 
WHERE sdr.InitConversionRate <> 1 
AND ( sdr.InitConversionRate IS NULL OR sdr.InitConversionRate = 0 )

-- update both tables for old position final prices

 UPDATE  t1
 SET 
 t1.OpenAskFinal = t2.OpenAskFinal
,t1.OpenBidFinal   = t2.OpenBidFinal 
,t1.OpenAskSpreadedFinal = t2.OpenAskSpreadedFinal 
,t1.OpenBidSpreadedFinal  = t2.OpenBidSpreadedFinal 
,t1.OpenMarketUSDConversionRateBidSpreaded_Final  = t2.OpenMarketUSDConversionRateBidSpreaded_Final 
, t1.InitForex_USDConversionRate = COALESCE(t1.InitConversionRate, t1.InitForex_USDConversionRate, t2.OpenMarketUSDConversionRateBidSpreaded_Final, t1.USD_CR)
,t1.IsPriceFound = t2.IsPriceFound
 FROM #StartDateReady t1
 INNER JOIN #end2022_ref  t2
	 ON t1.InstrumentID = t2.InstrumentID
	 AND t1.OpenDateID = t2.OpenDateID
	 AND t1.PositionID = t2.PositionID
 WHERE t1.OpenDateID <= 20221231

  UPDATE  t1
 SET 
 t1.OpenAskFinal = t2.OpenAskFinal
,t1.OpenBidFinal   = t2.OpenBidFinal 
,t1.OpenAskSpreadedFinal = t2.OpenAskSpreadedFinal 
,t1.OpenBidSpreadedFinal  = t2.OpenBidSpreadedFinal 
,t1.OpenMarketUSDConversionRateBidSpreaded_Final  = t2.OpenMarketUSDConversionRateBidSpreaded_Final 
,t1.InitForex_USDConversionRate = COALESCE(t1.InitConversionRate, t1.InitForex_USDConversionRate, t2.OpenMarketUSDConversionRateBidSpreaded_Final, t1.USD_CR)
,t1.IsPriceFound = t2.IsPriceFound
 FROM #EndDateReady t1
 INNER JOIN #end2022_ref  t2
	 ON t1.InstrumentID = t2.InstrumentID
	 AND t1.OpenDateID = t2.OpenDateID
	 AND t1.PositionID = t2.PositionID
 WHERE t1.OpenDateID <= 20221231


UPDATE #StartDateReady
SET OpenAskFinal = InitForex_Ask
	, OpenBidFinal = InitForex_Bid
	, OpenAskSpreadedFinal = InitForex_AskSpreaded
	, OpenBidSpreadedFinal = InitForex_BidSpreaded
	, OpenMarketUSDConversionRateBidSpreaded_Final = COALESCE(OpenMarketUSDConversionRateBidSpreaded, USD_CR)
	, IsPriceFound = 1
WHERE InitForexPriceRateID = OpenMarketPriceRateID AND OpenDateID = @sdateID


UPDATE #EndDateReady
SET OpenAskFinal = InitForex_Ask
	, OpenBidFinal = InitForex_Bid
	, OpenAskSpreadedFinal = InitForex_AskSpreaded
	, OpenBidSpreadedFinal = InitForex_BidSpreaded
	, OpenMarketUSDConversionRateBidSpreaded_Final = COALESCE(OpenMarketUSDConversionRateBidSpreaded, USD_CR)
	, IsPriceFound = 1
WHERE InitForexPriceRateID = OpenMarketPriceRateID AND OpenDateID >= @sdateID


UPDATE #EndDateReady
SET OpenAskFinal = OpenMarketAsk
	, OpenBidFinal = OpenMarketBid
	, OpenAskSpreadedFinal = OpenMarketAskSpreaded
	, OpenBidSpreadedFinal = OpenMarketBidSpreaded
	, OpenMarketUSDConversionRateBidSpreaded_Final = OpenMarketUSDConversionRateBidSpreaded
WHERE InitForexPriceRateID != OpenMarketPriceRateID AND OpenDateID >= @sdateID 


UPDATE #EndDateReady
SET IsPriceFound = 1
WHERE InitForexPriceRateID != OpenMarketPriceRateID AND OpenDateID >= @sdateID  AND OpenMarketAsk IS NOT NULL

UPDATE  t1
 SET 
 t1.InitForex_USDConversionRate = COALESCE(t1.InitConversionRate, t1.InitForex_USDConversionRate, t1.USD_CR)
 FROM #StartDateReady t1
 WHERE t1.OpenDateID > 20221231

  UPDATE  t1
 SET 
 t1.InitForex_USDConversionRate = COALESCE(t1.InitConversionRate, t1.InitForex_USDConversionRate, t1.USD_CR)
 FROM #EndDateReady t1
 WHERE t1.OpenDateID > 20221231

-- insert into  BI_DB_dbo.Guy_Test_Runtimes select GETDATE(), datediff(SECOND,@sysstart, GETDATE()) , count(*), ' to to update #EndDateReady-StartDateReady' FROM #EndDateReady



-- DECLARE @date DATE = '20230701'
--DECLARE @sdate DATE = CAST(DATEADD(DAY,-1,@date) AS Date) 
--DECLARE @sdateID int =CAST(CONVERT(VARCHAR(8), @sdate, 112) AS INT)
--DECLARE @edate DATE = '20230630'
--DECLARE @edateID int =CAST(CONVERT(VARCHAR(8), @edate, 112) AS INT)
--DECLARE @instrumentID INT = 22

IF OBJECT_ID('tempdb..#closedcommissions') IS NOT NULL DROP TABLE #closedcommissions
CREATE TABLE #closedcommissions  
    WITH (HEAP,DISTRIBUTION=HASH(PositionID))
AS
--DROP TABLE IF EXISTS #closedcommissions
SELECT CloseDateID, PositionID, InstrumentID, CommissionOnClose, FullCommissionOnClose  
--INTO #closedcommissions
FROM DWH_dbo.Dim_Position dp
WHERE CloseDateID IN (@sdateID, @edateID)
 --AND InstrumentID IN (@instrumentID)-- (40,5005,100020,29,1246,100086,17, 1001,22)

-- insert into  BI_DB_dbo.Guy_Test_Runtimes select GETDATE(), datediff(SECOND,@sysstart, GETDATE()) , count(*), ' to to populate #closedcommissions' FROM #closedcommissions

CREATE CLUSTERED INDEX #clus1 ON #closedcommissions (InstrumentID, CloseDateID)

-- select top 10 * from #closedcommissions

UPDATE #StartDateReady
SET IsDiscounted = IsSettled 
WHERE PnLVersion = 1
AND OpenDateID > 20240301

UPDATE #EndDateReady
SET IsDiscounted = IsSettled 
WHERE PnLVersion = 1
AND OpenDateID > 20240301


--UPDATE #EndDateReady
--SET InitForex_USDConversionRate = OpenMarketUSDConversionRateBidSpreaded_Final
--WHERE PnLVersion = 1

--UPDATE #StartDateReady
--SET InitForex_USDConversionRate = OpenMarketUSDConversionRateBidSpreaded_Final
--WHERE PnLVersion = 1


IF OBJECT_ID('tempdb..#Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date') IS NOT NULL DROP TABLE #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date
CREATE TABLE #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date  
    WITH (HEAP,DISTRIBUTION=HASH(PositionID))
AS
--DROP TABLE IF EXISTS #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date
SELECT er.*
-- , BI_DB_dbo.sc_fn_EY_PnL_Calculation (PnLVersion,IsBuy ,SellCurrencyID ,BuyCurrencyID ,RateBid ,RateAsk ,InitForexRate ,Units ,EndForex_USDConversionRate ,InitForex_USDConversionRate ,USD_CR) AS EY_PnL_Calculation_New
, CASE WHEN er.PnLVersion = 1 
	THEN 
	CASE 
		WHEN er.[IsBuy] = 1
			AND [SellCurrencyID] = 1 -- (Rate Bid - Initial Forex Rate)*1*Units
			THEN round((([RateBid] - er.[InitForexRate]) * 1 * er.[Units]), 4)
		WHEN er.[IsBuy] = 1
			AND [SellCurrencyID] != 1
			AND [BuyCurrencyID] = 1 -- (Rate Bid - Initial Forex Rate)*1 / Rate Bid*Units
			THEN round((([RateBid] * COALESCE(er.EndForex_USDConversionRate, er.USD_CR) - er.[InitForexRate] * COALESCE(er.InitForex_USDConversionRate, er.USD_CR)) * er.[Units]), 4)
----------------------------------------------
		WHEN er.[IsBuy] = 1 
			AND [SellCurrencyID] != 1
			AND [BuyCurrencyID] != 1 -- (Rate Bid - Initial Forex Rate)*USD_cr_Long*Units
			THEN round((([RateBid] * COALESCE(er.EndForex_USDConversionRate, er.USD_CR) - er.[InitForexRate] * COALESCE(er.InitForex_USDConversionRate, er.USD_CR)) * er.[Units]), 4)
-----------------------------------------------
		WHEN er.[IsBuy] != 1
			AND [SellCurrencyID] = 1 -- (Initial Forex Rate - Rate Ask)*1*Units
			THEN round(((er.[InitForexRate] * COALESCE(er.InitForex_USDConversionRate, er.USD_CR) - [RateAsk] * COALESCE(er.EndForex_USDConversionRate, er.USD_CR))  * er.[Units]), 4)
		WHEN er.[IsBuy] != 1
			AND [SellCurrencyID] != 1
			AND [BuyCurrencyID] = 1 -- (Initial Forex Rate - Rate Ask)*1 / Rate Ask*Units
			THEN round(((er.[InitForexRate] * COALESCE(er.InitForex_USDConversionRate, er.USD_CR) - [RateAsk] * COALESCE(er.EndForex_USDConversionRate, er.USD_CR)) * er.[Units]), 4)
		WHEN er.[IsBuy] != 1
			AND [SellCurrencyID] != 1
			AND [BuyCurrencyID] != 1 -- (Initial Forex Rate - Rate Ask)*USD_cr_Short*Units
			THEN round(((er.[InitForexRate] * COALESCE(er.InitForex_USDConversionRate, er.USD_CR) - [RateAsk] * COALESCE(er.EndForex_USDConversionRate, er.USD_CR)) * er.[Units]), 4)
		END 
	  ELSE 
		CASE 
			WHEN er.[IsBuy] = 1
				AND [SellCurrencyID] = 1 -- (Rate Bid - Initial Forex Rate)*1*Units
				THEN round((([RateBid] - er.[InitForexRate]) * 1 * er.[Units]), 4)
			WHEN er.[IsBuy] = 1
				AND [SellCurrencyID] != 1
				AND [BuyCurrencyID] = 1 -- (Rate Bid - Initial Forex Rate)*1 / Rate Bid*Units
				THEN round((([RateBid] - er.[InitForexRate]) *  er.USD_CR * er.[Units]), 4)
			WHEN er.[IsBuy] = 1
				AND [SellCurrencyID] != 1
				AND [BuyCurrencyID] != 1 -- (Rate Bid - Initial Forex Rate)*USD_cr_Long*Units
				THEN round((([RateBid] - er.[InitForexRate]) *  er.USD_CR * er.[Units]), 4)
			WHEN er.[IsBuy] != 1
				AND [SellCurrencyID] = 1 -- (Initial Forex Rate - Rate Ask)*1*Units
				THEN round(((er.[InitForexRate] - [RateAsk]) * 1 * er.[Units]), 4)
			WHEN er.[IsBuy] != 1
				AND [SellCurrencyID] != 1
				AND [BuyCurrencyID] = 1 -- (Initial Forex Rate - Rate Ask)*1 / Rate Ask*Units
				THEN round(((er.[InitForexRate] - [RateAsk]) *  er.USD_CR * er.[Units]), 4)
			WHEN er.[IsBuy] != 1
				AND [SellCurrencyID] != 1
				AND [BuyCurrencyID] != 1 -- (Initial Forex Rate - Rate Ask)*USD_cr_Short*Units
				THEN round(((er.[InitForexRate] - [RateAsk]) *  er.USD_CR * er.[Units]), 4)
		END 
	END 
	AS EY_PnL_Calculation
	, Ask AS ConfigAsk
	, Bid AS ConfigBid
	, ReferenceAsk AS ConfigReferenceAsk
	, ReferenceBid AS ConfigReferenceBid
	, Precision AS ConfigPrecision
	, SpreadTypeID AS ConfigSpreadTypeID
	, er.Commission AS Etoro_Commission -- the commission as appears in DimPosition
	, er.CommissionByUnits AS UnrealizedCommission -- the commission by units as *computed by the synapse audit stored procedure to show the outstanding unrealized at the date
	, CASE WHEN er.CloseDateID = @edateID THEN cp.CommissionOnClose ELSE 0 END AS RealizedCommission -- commission on close may appear if the synapse run time is not on @edate, this compensates for this timing issue
	, er.FullCommission AS Etoro_FullCommission -- the commission as appears in DimPosition
	, er.FullCommissionByUnits AS UnrealizedFullCommission -- the commission by units as *computed by the synapse audit stored procedure to show the outstanding unrealized at the date
	, CASE WHEN er.CloseDateID = @edateID THEN cp.FullCommissionOnClose ELSE 0 END AS RealizedFullCommission -- commission on close may appear if the synapse run time is not on @edate, this compensates for this timing issue
	, er.Units/er.InitialUnits AS OutstandingUnitsRatio -- this is the ratio used to recompute the ByUnits commissions at the BALANNCE DATE rather than the RUN DATE (shown in DimPositions)
	, CASE WHEN er.IsDiscounted = 1 THEN 0
			WHEN ISNULL(er.IsReOpen,0) = 1 THEN 0
			WHEN SpreadTypeID = 1 THEN ROUND((Ask - Bid) / POWER(10, nullif([Precision],1)) * er.InitialUnits * ROUND(er.OpenMarketUSDConversionRateBidSpreaded_Final,4),2)
			WHEN SpreadTypeID = 2 THEN ROUND(((Ask - Bid)/100) * er.InitialUnits * er.OpenMarketUSDConversionRateBidSpreaded_Final * er.OpenBidFinal,2)
		ELSE NULL 
	  END AS EY_CommissionOpen_Calc
	, CASE WHEN er.IsDiscounted = 1 THEN 0
			WHEN ISNULL(er.IsReOpen,0) = 1 THEN 0
			WHEN SpreadTypeID = 1 THEN ROUND((ReferenceAsk - ReferenceBid) / POWER(10, nullif([Precision],1)) * er.InitialUnits * ROUND(er.OpenMarketUSDConversionRateBidSpreaded_Final,4),2)
			WHEN SpreadTypeID = 2 THEN ROUND(((ReferenceAsk - ReferenceBid)/100) * er.InitialUnits * er.OpenMarketUSDConversionRateBidSpreaded_Final * er.OpenBidFinal,2)
		ELSE NULL 
	  END AS EY_CommissionOpen_Calc_RefAskBid
	, CASE WHEN er.IsDiscounted = 1 THEN 0
			WHEN ISNULL(er.IsReOpen,0) = 1 THEN 0
			WHEN SpreadTypeID = 1 THEN ROUND((ReferenceAsk - ReferenceBid) / POWER(10, nullif([Precision],1)) * er.InitialUnits * ROUND(er.OpenMarketUSDConversionRateBidSpreaded_Final,4),2)
			WHEN SpreadTypeID = 2 THEN ROUND(((ReferenceAsk - ReferenceBid)/100) * er.InitialUnits * er.OpenMarketUSDConversionRateBidSpreaded_Final * ISNULL(LastOpPriceRate,1),2)
		ELSE NULL 
	  END AS EY_CommissionOpen_Calc_LastOpRate
	, CASE WHEN er.IsDiscounted = 1 THEN ROUND((ABS(ROUND([OpenBidSpreadedFinal],0) - ROUND([OpenAskSpreadedFinal],4)) -  ABS(ROUND(er.OpenBidFinal,4) - ROUND(er.OpenAskFinal,4))) * er.InitialUnits * er.OpenMarketUSDConversionRateBidSpreaded_Final,2)
			WHEN er.IsReOpen = 1 THEN 0
		ELSE ROUND(ABS(ROUND([OpenBidSpreadedFinal],4) - ROUND([OpenAskSpreadedFinal],4)) * er.InitialUnits * er.OpenMarketUSDConversionRateBidSpreaded_Final,4)
	  END AS EY_FullCommissionOpen_Calc
	, 0 AS UseReferenceAskBid
	, 0 AS UseLastOpPriceRate
	, cast(NULL as float) AS EY_Commission_Calc_Final
	, cast(NULL as float) AS EY_UnrealizedCommission
	, cast(NULL as float) AS EY_UnrealizedFullCommission
--INTO #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date
FROM #StartDateReady er 
	LEFT JOIN #closedcommissions cp 
		ON er.PositionID = cp.PositionID AND cp.CloseDateID = @sdateID


CREATE CLUSTERED INDEX #clus1 ON #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date (InstrumentID, PositionTiming)

-- insert into  BI_DB_dbo.Guy_Test_Runtimes select GETDATE(), datediff(SECOND,@sysstart, GETDATE()) , count(*), ' to to populate #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date' FROM #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date


--DROP TABLE #StartDateOpenPositions


-- select * from #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date

IF OBJECT_ID('tempdb..#Auditors_OpenPosition_FullComm_PnL_Recal_End_Date') IS NOT NULL DROP TABLE #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date
CREATE TABLE #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date  
    WITH (HEAP,DISTRIBUTION=HASH(PositionID))
AS
-- DROP TABLE IF EXISTS #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date
SELECT er.*
--, BI_DB_dbo.sc_fn_EY_PnL_Calculation (PnLVersion,IsBuy ,SellCurrencyID ,BuyCurrencyID ,RateBid ,RateAsk ,InitForexRate ,Units ,EndForex_USDConversionRate ,InitForex_USDConversionRate ,USD_CR) AS EY_PnL_Calculation_New
, CASE WHEN er.PnLVersion = 1 
	THEN 
	CASE 
		WHEN er.[IsBuy] = 1
			AND [SellCurrencyID] = 1 -- (Rate Bid - Initial Forex Rate)*1*Units
			THEN round((([RateBid] - er.[InitForexRate]) * 1 * er.[Units]), 4)
		WHEN er.[IsBuy] = 1
			AND [SellCurrencyID] != 1
			AND [BuyCurrencyID] = 1 -- (Rate Bid - Initial Forex Rate)*1 / Rate Bid*Units
			THEN round((([RateBid] * COALESCE(er.EndForex_USDConversionRate, er.USD_CR) - er.[InitForexRate] * COALESCE(er.InitForex_USDConversionRate, er.USD_CR)) * er.[Units]), 4)
		WHEN er.[IsBuy] = 1
			AND [SellCurrencyID] != 1
			AND [BuyCurrencyID] != 1 -- (Rate Bid - Initial Forex Rate)*USD_cr_Long*Units
			THEN round((([RateBid] * COALESCE(er.EndForex_USDConversionRate, er.USD_CR) - er.[InitForexRate] * COALESCE(er.InitForex_USDConversionRate, er.USD_CR)) * er.[Units]), 4)
		WHEN er.[IsBuy] != 1
			AND [SellCurrencyID] = 1 -- (Initial Forex Rate - Rate Ask)*1*Units
			THEN round(((er.[InitForexRate] * COALESCE(er.InitForex_USDConversionRate, er.USD_CR) - [RateAsk] * COALESCE(er.EndForex_USDConversionRate, er.USD_CR))  * er.[Units]), 4)
		WHEN er.[IsBuy] != 1
			AND [SellCurrencyID] != 1
			AND [BuyCurrencyID] = 1 -- (Initial Forex Rate - Rate Ask)*1 / Rate Ask*Units
			THEN round(((er.[InitForexRate] * COALESCE(er.InitForex_USDConversionRate, er.USD_CR) - [RateAsk] * COALESCE(er.EndForex_USDConversionRate, er.USD_CR)) * er.[Units]), 4)
		WHEN er.[IsBuy] != 1
			AND [SellCurrencyID] != 1
			AND [BuyCurrencyID] != 1 -- (Initial Forex Rate - Rate Ask)*USD_cr_Short*Units
			THEN round(((er.[InitForexRate] * COALESCE(er.InitForex_USDConversionRate, er.USD_CR) - [RateAsk] * COALESCE(er.EndForex_USDConversionRate, er.USD_CR)) * er.[Units]), 4)
		END 
	  ELSE 
		CASE 
			WHEN er.[IsBuy] = 1
				AND [SellCurrencyID] = 1 -- (Rate Bid - Initial Forex Rate)*1*Units
				THEN round((([RateBid] - er.[InitForexRate]) * 1 * er.[Units]), 4)
			WHEN er.[IsBuy] = 1
				AND [SellCurrencyID] != 1
				AND [BuyCurrencyID] = 1 -- (Rate Bid - Initial Forex Rate)*1 / Rate Bid*Units
				THEN round((([RateBid] - er.[InitForexRate]) *  er.USD_CR * er.[Units]), 4)
			WHEN er.[IsBuy] = 1
				AND [SellCurrencyID] != 1
				AND [BuyCurrencyID] != 1 -- (Rate Bid - Initial Forex Rate)*USD_cr_Long*Units
				THEN round((([RateBid] - er.[InitForexRate]) *  er.USD_CR * er.[Units]), 4)
			WHEN er.[IsBuy] != 1
				AND [SellCurrencyID] = 1 -- (Initial Forex Rate - Rate Ask)*1*Units
				THEN round(((er.[InitForexRate] - [RateAsk]) * 1 * er.[Units]), 4)
			WHEN er.[IsBuy] != 1
				AND [SellCurrencyID] != 1
				AND [BuyCurrencyID] = 1 -- (Initial Forex Rate - Rate Ask)*1 / Rate Ask*Units
				THEN round(((er.[InitForexRate] - [RateAsk]) *  er.USD_CR * er.[Units]), 4)
			WHEN er.[IsBuy] != 1
				AND [SellCurrencyID] != 1
				AND [BuyCurrencyID] != 1 -- (Initial Forex Rate - Rate Ask)*USD_cr_Short*Units
				THEN round(((er.[InitForexRate] - [RateAsk]) *  er.USD_CR * er.[Units]), 4)
		END 
	END 
	AS EY_PnL_Calculation
	, Ask AS ConfigAsk
	, Bid AS ConfigBid
	, ReferenceAsk AS ConfigReferenceAsk
	, ReferenceBid AS ConfigReferenceBid
	, Precision AS ConfigPrecision
	, SpreadTypeID AS ConfigSpreadTypeID
	, er.Commission AS Etoro_Commission -- the commission as appears in DimPosition
	, er.CommissionByUnits AS UnrealizedCommission -- the commission by units as *computed by the synapse audit stored procedure to show the outstanding unrealized at the date
	, CASE WHEN er.CloseDateID = @edateID THEN cp.CommissionOnClose ELSE 0 END AS RealizedCommission -- commission on close may appear if the synapse run time is not on @edate, this compensates for this timing issue
	, er.FullCommission AS Etoro_FullCommission -- the commission as appears in DimPosition
	, er.FullCommissionByUnits AS UnrealizedFullCommission -- the commission by units as *computed by the synapse audit stored procedure to show the outstanding unrealized at the date
	, CASE WHEN er.CloseDateID = @edateID THEN cp.FullCommissionOnClose ELSE 0 END AS RealizedFullCommission -- commission on close may appear if the synapse run time is not on @edate, this compensates for this timing issue
	, er.Units/er.InitialUnits AS OutstandingUnitsRatio -- this is the ratio used to recompute the ByUnits commissions at the BALANNCE DATE rather than the RUN DATE (shown in DimPositions)
	, CASE WHEN er.IsDiscounted = 1 THEN 0
			WHEN ISNULL(er.IsReOpen,0) = 1 THEN 0
			WHEN SpreadTypeID = 1 THEN ROUND((Ask - Bid) / POWER(10, nullif([Precision],1)) * er.InitialUnits * ROUND(er.OpenMarketUSDConversionRateBidSpreaded_Final,4),2)
			WHEN SpreadTypeID = 2 THEN ROUND(((Ask - Bid)/100) * er.InitialUnits * er.OpenMarketUSDConversionRateBidSpreaded_Final * er.OpenBidFinal,2)
		ELSE NULL 
	  END AS EY_CommissionOpen_Calc
	, CASE WHEN er.IsDiscounted = 1 THEN 0
			WHEN ISNULL(er.IsReOpen,0) = 1 THEN 0
			WHEN SpreadTypeID = 1 THEN ROUND((ReferenceAsk - ReferenceBid) / POWER(10, nullif([Precision],1)) * er.InitialUnits * ROUND(er.OpenMarketUSDConversionRateBidSpreaded_Final,4),2)
			WHEN SpreadTypeID = 2 THEN ROUND(((ReferenceAsk - ReferenceBid)/100) * er.InitialUnits * er.OpenMarketUSDConversionRateBidSpreaded_Final * er.OpenBidFinal,2)
		ELSE NULL 
	  END AS EY_CommissionOpen_Calc_RefAskBid
	, CASE WHEN er.IsDiscounted = 1 THEN 0
			WHEN ISNULL(er.IsReOpen,0) = 1 THEN 0
			WHEN SpreadTypeID = 1 THEN ROUND((ReferenceAsk - ReferenceBid) / POWER(10, nullif([Precision],1)) * er.InitialUnits * ROUND(er.OpenMarketUSDConversionRateBidSpreaded_Final,4),2)
			WHEN SpreadTypeID = 2 THEN ROUND(((ReferenceAsk - ReferenceBid)/100) * er.InitialUnits * er.OpenMarketUSDConversionRateBidSpreaded_Final * ISNULL(LastOpPriceRate,1),2)
		ELSE NULL 
	  END AS EY_CommissionOpen_Calc_LastOpRate
	, CASE WHEN er.IsDiscounted = 1 THEN ROUND((ABS(ROUND([OpenBidSpreadedFinal],0) - ROUND([OpenAskSpreadedFinal],4)) -  ABS(ROUND(er.OpenBidFinal,4) - ROUND(er.OpenAskFinal,4))) * er.InitialUnits * er.OpenMarketUSDConversionRateBidSpreaded_Final,2)
			WHEN er.IsReOpen = 1 THEN 0
		ELSE ROUND(ABS(ROUND([OpenBidSpreadedFinal],4) - ROUND([OpenAskSpreadedFinal],4)) * er.InitialUnits * er.OpenMarketUSDConversionRateBidSpreaded_Final,2)
	  END AS EY_FullCommissionOpen_Calc
	, 0 AS UseReferenceAskBid
	, 0 AS UseLastOpPriceRate
	, cast(NULL as float) AS EY_Commission_Calc_Final
	, cast(NULL as float) AS EY_UnrealizedCommission
	, cast(NULL as float) AS EY_UnrealizedFullCommission
--INTO #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date
FROM #EndDateReady er
	LEFT JOIN #closedcommissions cp
		ON er.PositionID = cp.PositionID AND cp.CloseDateID = @edateID

CREATE CLUSTERED INDEX #clus1 ON #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date (InstrumentID, PositionTiming)



-- insert into  BI_DB_dbo.Guy_Test_Runtimes select GETDATE(), datediff(SECOND,@sysstart, GETDATE()) , count(*), ' to to populate #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date' FROM #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date

-- select top 10 * from #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date


--DECLARE @date DATE = '20230315'
--DECLARE @sdate DATE = CAST(DATEADD(DAY,-1,@date) AS Date) 
--DECLARE @sdateID int =CAST(CONVERT(VARCHAR(8), @sdate, 112) AS INT)
--DECLARE @edate DATE = @date
--DECLARE @edateID int =CAST(CONVERT(VARCHAR(8), @edate, 112) AS INT)
--DECLARE @instrumentID INT = 8000
--declare @sysstart datetime 

UPDATE  #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date
SET UseReferenceAskBid = 1 
WHERE abs(EY_CommissionOpen_Calc - Commission) > abs(EY_CommissionOpen_Calc_RefAskBid - Commission)

UPDATE  #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date
SET UseReferenceAskBid = 1 
WHERE abs(EY_CommissionOpen_Calc - Commission) > abs(EY_CommissionOpen_Calc_RefAskBid - Commission)

UPDATE  #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date
SET UseLastOpPriceRate = 1 
WHERE abs(EY_CommissionOpen_Calc - Commission) > abs(EY_CommissionOpen_Calc_LastOpRate - Commission)

UPDATE  #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date
SET UseLastOpPriceRate = 1 
WHERE abs(EY_CommissionOpen_Calc - Commission) > abs(EY_CommissionOpen_Calc_LastOpRate - Commission)


-- update the final commission based on the previous conditions

UPDATE #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date
SET EY_Commission_Calc_Final = EY_CommissionOpen_Calc

UPDATE #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date
SET EY_Commission_Calc_Final = EY_CommissionOpen_Calc

UPDATE #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date
SET EY_Commission_Calc_Final = EY_CommissionOpen_Calc_RefAskBid
WHERE UseReferenceAskBid = 1

UPDATE #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date
SET EY_Commission_Calc_Final = EY_CommissionOpen_Calc_LastOpRate
WHERE UseLastOpPriceRate = 1

UPDATE #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date
SET EY_Commission_Calc_Final = EY_CommissionOpen_Calc_RefAskBid
WHERE UseReferenceAskBid = 1

UPDATE #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date
SET EY_Commission_Calc_Final = EY_CommissionOpen_Calc_LastOpRate
WHERE UseLastOpPriceRate = 1

UPDATE #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date
SET EY_UnrealizedCommission = EY_Commission_Calc_Final * OutstandingUnitsRatio
	, EY_UnrealizedFullCommission = EY_FullCommissionOpen_Calc * OutstandingUnitsRatio 

UPDATE #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date
SET EY_UnrealizedCommission = EY_Commission_Calc_Final * OutstandingUnitsRatio
	, EY_UnrealizedFullCommission = EY_FullCommissionOpen_Calc * OutstandingUnitsRatio 


--- on the rare occassion that FullCommission < Commission, we update then fullcommission to be euqal to commission

UPDATE #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date 
SET FullCommission = Commission 
	, EY_FullCommissionOpen_Calc = EY_CommissionOpen_Calc
WHERE Commission > FullCommission

UPDATE #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date 
SET FullCommission = Commission 
	, EY_FullCommissionOpen_Calc = EY_CommissionOpen_Calc
WHERE Commission > FullCommission

UPDATE #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date 
SET EY_UnrealizedCommission = COALESCE(UnrealizedCommission, CommissionByUnits)
	, EY_UnrealizedFullCommission = COALESCE(UnrealizedFullCommission, CommissionByUnits)

UPDATE #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date 
SET EY_UnrealizedCommission = COALESCE(UnrealizedCommission, CommissionByUnits)
	, EY_UnrealizedFullCommission = COALESCE(UnrealizedFullCommission, CommissionByUnits)

-- insert into  BI_DB_dbo.Guy_Test_Runtimes select GETDATE(), datediff(SECOND,@sysstart, GETDATE()) , count(*), ' to to update #Auditors' FROM #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date

-- select top 1000 * from #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date
-- select top 1000 * from #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date

--- computing the unrealized change from sdate to edate

-- DECLARE @date DATE = '20230701'
--DECLARE @sdate DATE = CAST(DATEADD(DAY,-1,@date) AS Date) 
--DECLARE @sdateID int =CAST(CONVERT(VARCHAR(8), @sdate, 112) AS INT)
--DECLARE @edate DATE = @date
--DECLARE @edateID int =CAST(CONVERT(VARCHAR(8), @edate, 112) AS INT)
--DECLARE @instrumentID INT = 22

IF OBJECT_ID('tempdb..#testresults') IS NOT NULL DROP TABLE #testresults
CREATE TABLE #testresults  
    WITH (CLUSTERED INDEX (InstrumentID),DISTRIBUTION=HASH(PositionID))
AS
SELECT @edateID as DateID
	 , COALESCE( ed.CID										, sd.CID								) as CID								
	 , COALESCE( ed.PositionID								, sd.PositionID							) as PositionID							
	 , COALESCE( ed.OpenDateID								, sd.OpenDateID							) as OpenDateID							
	 , COALESCE( ed.CloseDateID								, sd.CloseDateID						) as CloseDateID						
	 , COALESCE( ed.InstrumentType							, sd.InstrumentType						) as InstrumentType						
	 , COALESCE( ed.InstrumentID							, sd.InstrumentID						) as InstrumentID						
	 , COALESCE( ed.InitialUnits							, sd.InitialUnits						) as InitialUnits						
	 , COALESCE( ed.Units									, sd.Units								) as Units								
	 , COALESCE( ed.IsDiscounted							, sd.IsDiscounted						) as IsDiscounted						
	 , COALESCE( ed.PositionPnL								, sd.PositionPnL						) as PositionPnL						
	 , COALESCE( ed.PositionPnL_Calc						, sd.PositionPnL_Calc					) as PositionPnL_Calc					
	 , COALESCE( ed.Commission								, sd.Commission							) as Commission							
	 , COALESCE( ed.CommissionOnClose						, sd.CommissionOnClose					) as CommissionOnClose					
	 , COALESCE( ed.FullCommission							, sd.FullCommission						) as FullCommission						
	 , COALESCE( ed.CommissionByUnits						, sd.CommissionByUnits					) as CommissionByUnits					
	 , COALESCE( ed.FullCommissionByUnits					, sd.FullCommissionByUnits				) as FullCommissionByUnits				
	 , COALESCE( ed.IsPriceFound							, sd.IsPriceFound						) as IsPriceFound						
	 , COALESCE( ed.EY_PnL_Calculation						, sd.EY_PnL_Calculation					) as EY_PnL_Calculation					
	 , COALESCE( ed.UnrealizedCommission					, sd.UnrealizedCommission				) as UnrealizedCommission				
	 , COALESCE( ed.RealizedCommission						, sd.RealizedCommission					) as RealizedCommission					
	 , COALESCE( ed.Etoro_FullCommission					, sd.Etoro_FullCommission				) as Etoro_FullCommission				
	 , COALESCE( ed.UnrealizedFullCommission				, sd.UnrealizedFullCommission			) as UnrealizedFullCommission			
	 , COALESCE( ed.RealizedFullCommission					, sd.RealizedFullCommission				) as RealizedFullCommission				
	 , COALESCE( ed.OutstandingUnitsRatio					, sd.OutstandingUnitsRatio				) as OutstandingUnitsRatio				
	 , COALESCE( ed.EY_CommissionOpen_Calc					, sd.EY_CommissionOpen_Calc				) as EY_CommissionOpen_Calc				
	 , COALESCE( ed.EY_CommissionOpen_Calc_RefAskBid		, sd.EY_CommissionOpen_Calc_RefAskBid	) as EY_CommissionOpen_Calc_RefAskBid	
	 , COALESCE( ed.EY_CommissionOpen_Calc_LastOpRate		, sd.EY_CommissionOpen_Calc_LastOpRate	) as EY_CommissionOpen_Calc_LastOpRate	
	 , COALESCE( ed.EY_FullCommissionOpen_Calc				, sd.EY_FullCommissionOpen_Calc			) as EY_FullCommissionOpen_Calc			
	 , COALESCE( ed.UseReferenceAskBid						, sd.UseReferenceAskBid					) as UseReferenceAskBid					
	 , COALESCE( ed.UseLastOpPriceRate						, sd.UseLastOpPriceRate					) as UseLastOpPriceRate					
	 , COALESCE( ed.EY_Commission_Calc_Final				, sd.EY_Commission_Calc_Final			) as EY_Commission_Calc_Final			
	 , ISNULL(ed.EY_UnrealizedCommission,0) - ISNULL(sd.EY_UnrealizedCommission,0) AS UnrealizedCommissionChange
	 , ISNULL(ed.EY_UnrealizedFullCommission,0) - ISNULL(sd.EY_UnrealizedFullCommission,0) AS UnrealizedFullCommissionChange
	 , ISNULL(ed.EY_PnL_Calculation,0) - ISNULL(sd.EY_PnL_Calculation,0) AS UnrealizedPnLChange
FROM #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date ed
FULL outer JOIN #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date sd
	ON ed.InstrumentID = sd.InstrumentID AND ed.PositionID = sd.PositionID

-- insert into  BI_DB_dbo.Guy_Test_Runtimes select GETDATE(), datediff(SECOND,@sysstart, GETDATE()) , count(*), ' to to update #testresults' FROM #testresults


/*

select InstrumentID, sum( UnrealizedPnLChange) UnrealizedPnLChangeAudit 
from #testresults
--where InstrumentID = 1404
group by InstrumentID
order by 1

SELECT InstrumentID, sum(cbbil.UnrealizedPnLChange) UnrealizedPnLChangeCB
FROM BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level cbbil
WHERE cbbil.DateID = 20240513
--and InstrumentID = 1404
group by InstrumentID
order by 1

select  sum( UnrealizedPnLChange) UnrealizedPnLChangeAudit 
from #testresults
--where InstrumentID = 1404
order by 1

SELECT  sum(cbbil.UnrealizedPnLChange) UnrealizedPnLChangeCB
FROM BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level cbbil
WHERE cbbil.DateID = 20240404
--and InstrumentID = 1404
order by 1

*/




--- final result inserts

--DECLARE @date DATE = '20240513'
--DECLARE @sdate DATE = CAST(DATEADD(DAY,-1,@date) AS Date) 
--DECLARE @sdateID int =CAST(CONVERT(VARCHAR(8), @sdate, 112) AS INT)
--DECLARE @edate DATE = @date
--DECLARE @edateID int =CAST(CONVERT(VARCHAR(8), @edate, 112) AS INT)
--DECLARE @instrumentID INT = 8000

-- select * FROM BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results WHERE [Date] = '20240513'

DELETE FROM BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results WHERE [Date] = @edate

INSERT INTO BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results
SELECT
	CONVERT(DATE, CONVERT(VARCHAR(8), ma.DateID), 112) AS [Date]
  , 'SP_EY_Audit_Auditor_Unrealized_Calculations_On_Synapse' AS Stored_Proc
  , ma.Metric_a
  , ma.Metric_a_Value
  , mb.Metric_b
  , mb.Metric_b_Value
  , Metric_a_Value - Metric_b_Value AS [Diff$]
  , ABS((Metric_a_Value - Metric_b_Value)/Metric_b_Value * 100) AS [Diff%]
  , NULL AS IsPriceFound
  , GETDATE() AS UpdateDate
FROM 
	(
	SELECT DateID, 'EY_UnrealizedCommissionChange_Calc' AS Metric_a, ABS(sum(UnrealizedCommissionChange)) AS Metric_a_Value
	FROM #testresults
	GROUP BY DateID
	) ma
	JOIN 
	(
	SELECT DateID, 'CB_UnrealizedCommissionChange' AS Metric_b, ABS(sum(UnrealizedCommissionChange)) AS Metric_b_Value
FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New bdcbaln
WHERE DateID = @edateID
GROUP BY DateID
	) mb
ON ma.DateID = mb.DateID

UNION all 

SELECT
	CONVERT(DATE, CONVERT(VARCHAR(8), ma.DateID), 112) AS [Date]
  , 'SP_EY_Audit_Auditor_Unrealized_Calculations_On_Synapse' AS Stored_Proc
  , ma.Metric_a
  , ma.Metric_a_Value
  , mb.Metric_b
  , mb.Metric_b_Value
  , Metric_a_Value - Metric_b_Value AS [Diff$] 
  , ABS((Metric_a_Value - Metric_b_Value)/Metric_b_Value * 100) AS [Diff%]
  , NULL AS IsPriceFound
  , GETDATE() AS UpdateDate
FROM 
	(
	SELECT DateID, 'EY_UnrealizedFullCommissionChange_Calc' AS Metric_a, ABS(sum(UnrealizedFullCommissionChange)) AS Metric_a_Value
	FROM #testresults
	GROUP BY DateID
	) ma
	JOIN 
	(
	SELECT DateID, 'CB_UnrealizedFullCommissionChange' AS Metric_b, ABS(sum(UnrealizedFullCommissionChange)) AS Metric_b_Value
FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New bdcbaln
WHERE DateID = @edateID
GROUP BY DateID
	) mb
ON ma.DateID = mb.DateID

UNION ALL 

SELECT
	CONVERT(DATE, CONVERT(VARCHAR(8), ma.DateID), 112) AS [Date]
  , 'SP_EY_Audit_Auditor_Unrealized_Calculations_On_Synapse' AS Stored_Proc
  , ma.Metric_a
  , ma.Metric_a_Value
  , mb.Metric_b
  , mb.Metric_b_Value
  , Metric_a_Value - Metric_b_Value AS [Diff$] 
  , ABS((Metric_a_Value - Metric_b_Value)/Metric_b_Value * 100) AS [Diff%]
  , NULL AS IsPriceFound
  , GETDATE() AS UpdateDate
FROM 
	(
	SELECT DateID, 'EY_UnrealizedPnLChange_Calc' AS Metric_a, ABS(sum(UnrealizedPnLChange)) AS Metric_a_Value
	FROM #testresults
	GROUP BY DateID
	) ma
	JOIN 
	(
	SELECT DateID, 'CB_UnrealizedPnLChange' AS Metric_b, ABS(sum(bdcbaln.UnrealizedPnLChange)) AS Metric_b_Value
FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New bdcbaln
WHERE DateID = @edateID
GROUP BY DateID
	) mb
ON ma.DateID = mb.DateID


IF OBJECT_ID('tempdb..#regPrep') IS NOT NULL DROP TABLE #regPrep
CREATE TABLE #regPrep
    WITH (HEAP,DISTRIBUTION = HASH(CID))
as

SELECT
	t.DateID
  , t.CID
  , t.InstrumentID
  , t.InstrumentType
  , sum(t.UnrealizedCommissionChange		) as UnrealizedCommissionChange
  , sum(t.UnrealizedFullCommissionChange	) as UnrealizedFullCommissionChange
  , sum(t.UnrealizedPnLChange				) as UnrealizedPnLChange
FROM #testresults t
GROUP BY 
	t.DateID
  , t.CID
  , t.InstrumentID
  , t.InstrumentType

IF OBJECT_ID('tempdb..#byRegulation') IS NOT NULL DROP TABLE #byRegulation
CREATE TABLE #byRegulation
    WITH (HEAP,DISTRIBUTION = ROUND_ROBIN)
as
SELECT
	dr1.Name AS Regulation
  , p.InstrumentID
  , p.InstrumentType
  , sum(p.UnrealizedCommissionChange		) as UnrealizedCommissionChange
  , sum(p.UnrealizedFullCommissionChange	) as UnrealizedFullCommissionChange
  , sum(p.UnrealizedPnLChange				) as UnrealizedPnLChange
FROM #regPrep p
	JOIN DWH_dbo.Fact_SnapshotCustomer fsc
		ON p.CID = fsc.RealCID
	JOIN DWH_dbo.Dim_Range dr
		ON fsc.DateRangeID = dr.DateRangeID AND p.DateID BETWEEN dr.FromDateID AND dr.ToDateID
	JOIN DWH_dbo.Dim_Regulation dr1
		ON fsc.RegulationID = dr1.DWHRegulationID
GROUP BY 
	dr1.Name
  , p.InstrumentID
  , p.InstrumentType


DELETE FROM BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation WHERE DateID = @edateID -- select * from BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation

INSERT INTO BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation (
	   DateID
	 , [Date]
	 , r.Regulation
	 , r.InstrumentID
	 , r.InstrumentType
	 , r.UnrealizedCommissionChange
	 , r.UnrealizedFullCommissionChange
	 , r.UnrealizedPnLChange
	 , UpdateDate
)
SELECT @edateID AS DateID
	 , @edate AS [Date]
	 , r.Regulation
	 , r.InstrumentID
	 , r.InstrumentType
	 , r.UnrealizedCommissionChange
	 , r.UnrealizedFullCommissionChange
	 , r.UnrealizedPnLChange
	 , GETDATE() AS UpdateDate
FROM #byRegulation r -- select top 10 * from #byRegulation

-- we dont want to keep unnecessary data, so this logic deletes existing dates which exist but are no longer needed: 


IF OBJECT_ID('tempdb..#delete') IS NOT NULL DROP TABLE #delete -- select * from #delete
CREATE TABLE #delete  
    WITH (HEAP,DISTRIBUTION=ROUND_ROBIN)
AS
SELECT d.DateID
FROM #distinct d
LEFT JOIN #relevant r
	ON d.DateID = r.DateID
WHERE r.DateID IS NULL

-- select * from #delete

-- Check if #delete has rows

IF EXISTS (SELECT 1 FROM #delete)
BEGIN
    -- Delete rows from BI_DB_dbo.BI_DB_EY_Audit_Opened_Positions where DateID is in #delete
    DELETE FROM BI_DB_dbo.BI_DB_EY_Audit_Opened_Positions
    WHERE DateID IN (SELECT DateID FROM #delete);
END;


-- SELECT TOP 10 * FROM #testresults 
-- select * from BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results order by Date

/**********************************************************************************
in order not to keep huge data, delete from Opened Positions where dateid is not 
one of the two participating date ids. on a daily basis, this will insure that when 
running on "yesterday" and "day beofre" those 2 will always be there. when doing 
reruns, first a bunch of other procs need to run and 

**********************************************************************************/
/*
SELECT DateID, SUM(PositionPnL),sum(PositionPnL_Calc), sum(EY_PnL_Calculation)
FROM #Auditors_OpenPosition_FullComm_PnL_Recal_Start_Date aopfcplrsd
GROUP BY aopfcplrsd.DateID

SELECT DateID, SUM(PositionPnL),sum(PositionPnL_Calc), sum(EY_PnL_Calculation)
FROM #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date aopfcplrsd
GROUP BY aopfcplrsd.DateID

SELECT DateID, SUM(aopfcplrsd.EY_UnrealizedCommission)
FROM #Auditors_OpenPosition_FullComm_PnL_Recal_End_Date aopfcplrsd
GROUP BY aopfcplrsd.DateID

SELECT *
FROM BI_DB_dbo.BI_DB_EY_Audit_Opened_Positions bdeaop
WHERE bdeaop.DateID = 20230701
AND bdeaop.InstrumentID = 1
*/

/*

DECLARE @instrumentID INT = 8000

SELECT InstrumentID, sum(UnrealizedCommissionChange), sum( UnrealizedPnLChange)
FROM #testresults
GROUP BY InstrumentID
ORDER BY 1

SELECT InstrumentID, sum(cbbil.UnrealizedCommissionChange), sum(cbbil.UnrealizedPnLChange)
FROM BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level cbbil
WHERE cbbil.DateID = 20240513
--and InstrumentID = @instrumentID
group by InstrumentID
order by 1


SELECT sum(bdeaop.CommissionByUnits) FROM BI_DB_dbo.BI_DB_EY_Audit_Opened_Positions bdeaop WHERE bdeaop.DateID = 20230930 AND bdeaop.InstrumentID = 5005
*/

 END


GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `BI_DB_dbo.SP_EY_Audit_Auditor_Unrealized_Calculations` | synapse_sp | BI_DB_dbo | SP_EY_Audit_Auditor_Unrealized_Calculations | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\BI_DB_dbo\Stored Procedures\BI_DB_dbo.SP_EY_Audit_Auditor_Unrealized_Calculations.sql` |
| `BI_DB_dbo.BI_DB_EY_Audit_Opened_Positions` | unresolved | BI_DB_dbo | BI_DB_EY_Audit_Opened_Positions | `—` |
| `BI_DB_dbo.EY_Audit_Automation_LastOpRate` | unresolved | BI_DB_dbo | EY_Audit_Automation_LastOpRate | `—` |
| `BI_DB_dbo.EY_Audit_Automation_Opened_Positions_End_2022_Baseline` | unresolved | BI_DB_dbo | EY_Audit_Automation_Opened_Positions_End_2022_Baseline | `—` |
| `BI_DB_dbo.EY_Audit_Automation_Position_Open_Configs` | unresolved | BI_DB_dbo | EY_Audit_Automation_Position_Open_Configs | `—` |
| `DWH_dbo.Dim_Position` | synapse | DWH_dbo | Dim_Position | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Position.md` |
| `BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results` | unresolved | BI_DB_dbo | BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results | `—` |
| `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New` | synapse | BI_DB_dbo | BI_DB_Client_Balance_Aggregate_Level_New | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Client_Balance_Aggregate_Level_New.md` |
| `DWH_dbo.Fact_SnapshotCustomer` | synapse | DWH_dbo | Fact_SnapshotCustomer | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_SnapshotCustomer.md` |
| `DWH_dbo.Dim_Range` | synapse | DWH_dbo | Dim_Range | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `DWH_dbo.Dim_Regulation` | synapse | DWH_dbo | Dim_Regulation | `C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
