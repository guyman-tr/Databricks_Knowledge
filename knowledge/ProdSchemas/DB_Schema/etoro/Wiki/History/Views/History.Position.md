# History.Position

> The central closed-positions unified view for eToro - UNION ALL over 62 quarterly dbo archive tables (2007Q3-2022Q4), History.Position_Active (primary 2021+ archive), Trade.PositionTbl WHERE StatusID=2 (recently closed live positions), and History.PositionClosePartial. Provides a single 124-column query interface spanning the entire eToro trading history from Q3 2007 to present.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | PositionID (bigint) |
| **Partition** | N/A (view - base table History.Position_Active is on HISTORY filegroup) |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

History.Position is THE closed-position query interface for all historical trading analysis at eToro. It unifies every closed position across the platform's entire history (2007 to present) into a single 124-column view. Without this view, analysts and procedures would need to query 65+ separate tables to get complete closed-position history.

**Source categorization**:

| Source Pool | Tables | Date Coverage | Column Richness |
|-------------|--------|---------------|-----------------|
| dbo quarterly archives | 62 tables (HistoryPosition_2007Q3 ... 2022Q4) | Q3 2007 - Q4 2022 | Older tables: many newer cols backfilled NULL/0; 2021Q2+ tables: more cols native |
| History.Position_Active | 1 table | Apr 2021 - present | All 124 cols native (primary source) |
| Trade.PositionTbl + PositionTreeInfo WHERE StatusID=2 | 2 tables (JOIN) | Most recent closed, pending async archival | Full 124 cols; some cols NULL (RequestedEndForexRate, RequestOpenOccurred, etc.) |
| History.PositionClosePartial | 1 table | Partial-close positions | Full 124 cols native |

The quarterly archive tables are in the `dbo` schema and are partitioned by time period. They represent the historical migration from the old HistoryPosition architecture. When eToro migrated to the new History.Position_Active table (April 2021), the quarterly archive strategy continued alongside until Q4 2022 when the last archive table was filled.

**Column evolution**: SQL Server requires all UNION ALL branches to have the same column count. Older quarterly tables (pre-2021Q2) lack many columns that were added over the years. These are backfilled in the SELECT list:
- `IsSettled`, `SettlementTypeID`: 0 for all pre-2021Q2 rows
- `RedeemStatus`, `RedeemID`: NULL for pre-2021Q2 rows
- `InitConversionRate`, `ExitOrderType`, `OpenActionType`, `OpenMarkup`, `CloseMarkup`, etc.: NULL/0/-1 for pre-2021Q1 rows
- `CloseTotalFees`, `OpenTotalFees`, `CloseTotalTaxes`, `OpenTotalTaxes`, `OpenMarkupByUnits`, `IsNoStopLoss`, `IsNoTakeProfit`, `OriginalOpenActionType`, `InitialLotCount`: 0/NULL for pre-2022Q4 rows; native in 2022Q4, Position_Active, and PositionClosePartial branches

This view is referenced by 50+ procedures across 7 schemas (BackOffice, Billing, CEP, Customer, dbo, History, Trade). It is the primary interface for account statements, P&L reports, compliance exports, and trading analytics.

---

## 2. Business Logic

### 2.1 Multi-Source UNION ALL Architecture

**What**: Each branch of the UNION ALL represents a different storage tier for closed positions.

**Rules**:
- **62 quarterly archive branches** (2007Q3-2022Q4): Read-only historical snapshots. Column backfilling with hardcoded NULL/0 for columns added after each table was created. No deduplication needed - each PositionID exists in exactly one quarterly table.
- **History.Position_Active branch**: The primary data source for 2021+ positions. 2,511,608+ rows. Full 124-column schema natively. Written by Trade.PostClosePositionActions asynchronously.
- **Trade.PositionTbl + PositionTreeInfo WHERE StatusID=2**: Recently closed positions not yet async-archived. INNER JOIN on TreeID for IsDiscounted and IsNoStopLoss/IsNoTakeProfit data. Some columns NULL (RequestedEndForexRate, RequestOpenOccurred, RequestCloseOccurred, EndHedgeQuery, EndForexRateUnAdjusted, EndMarketRateUnAdjusted).
- **History.PositionClosePartial**: Partial-close position records. Full 124-column schema natively.

**Diagram**:
```
dbo.HistoryPosition_2007Q3 ... 2022Q4 (62 branches)
  SELECT all cols, NULL/0 for columns not present in older tables
  |
UNION ALL
  |
History.Position_Active (primary archive, 2021+)
  SELECT all cols natively
  |
UNION ALL
  |
Trade.PositionTbl JOIN Trade.PositionTreeInfo WHERE StatusID=2
  SELECT all cols; some NULL for inapplicable history fields
  |
UNION ALL
  |
History.PositionClosePartial
  SELECT all cols natively
  |
  v
History.Position (124 cols, full trading history 2007-present)
```

### 2.2 CommissionByUnits / FullCommissionByUnits Computation

**What**: The per-unit commission is computed as a ratio of closed units vs. original units.

**Columns/Parameters Involved**: `CommissionByUnits`, `FullCommissionByUnits`, `AmountInUnitsDecimal`, `InitialUnits`

**Rules**:
- Formula: `CAST(CASE WHEN ISNULL(InitialUnits, AmountInUnitsDecimal) <> 0 THEN (AmountInUnitsDecimal / ISNULL(InitialUnits, AmountInUnitsDecimal)) * Commission ELSE 0 END AS MONEY)`
- Uses CAST(... AS MONEY) in 2021Q2+ branches; early branches use `Commission as CommissionByUnits` (pre-partial-close)
- This enables correct commission calculation for partial-close positions where only a fraction of the original position was closed

### 2.3 SettlementTypeID Normalization

**What**: SettlementTypeID is computed from ISNULL(SettlementTypeID, cast(IsSettled as tinyint)) in the 2021Q1+ branches.

**Columns/Parameters Involved**: `SettlementTypeID`, `IsSettled`

**Rules**:
- In older branches (pre-2021Q1): hardcoded 0 AS SettlementTypeID
- In 2021Q1 branch: `cast(IsSettled as tinyint) AS SettlementTypeID` (SettlementTypeID column didn't exist yet)
- In 2021Q2+ branches: `ISNULL(SettlementTypeID, cast(IsSettled as tinyint))` - uses native SettlementTypeID if available, falls back to IsSettled cast

### 2.4 ActionType - Close Reason

**What**: Identifies why each position was closed. Distribution is well-understood from History.Position_Active (the primary source).

**Columns/Parameters Involved**: `ActionType`

**Rules** (from History.Position_Active - represents all modern closes):

| ActionType | Count | Pct | Description |
|-----------|-------|-----|-------------|
| 1 | 1,700,808 | 67.7% | Client close - user manually closed the position |
| 0 | 311,534 | 12.4% | Unknown / settlement auto-close |
| 10 | 272,110 | 10.8% | Settlement or system close |
| 24 | 40,962 | 1.6% | Mirror/copy trading close |
| 13 | 36,359 | 1.4% | Stop-loss triggered |
| Other | 150,000+ | 6.0% | End-of-week (5), take-profit (9), system (23), etc. |

---

## 3. Data Overview

Live data query from History.Position fails for the quarterly archive branches (McpUserRO lacks access to EtoroArchive database). Data from History.Position_Active branch (most recent rows):

| PositionID | CID | InstrumentID | IsBuy | Amount | Leverage | NetProfit | ActionType | CloseOccurred | IsSettled |
|-----------|-----|-------------|-------|--------|----------|-----------|-----------|--------------|-----------|
| 2152976743 | 14952810 | 100000 (BTC) | Buy | $99.97 | 1 | 0 | 0 | 2026-03-21 11:11 | true (1) | Settlement position: 1-hour BTC cycling, NetProfit=0, SettlementTypeID=1. Leverage=1 = fully funded stock/crypto. |
| 2152976741 | 14952810 | 100000 (BTC) | Buy | $99.97 | 1 | 0 | 0 | 2026-03-21 10:09 | true (1) | Same customer, same pattern: 1-hour intervals, BTC settlement flow. |
| 2152976740 | 14952810 | 100000 (BTC) | Buy | $99.97 | 1 | 0 | 0 | 2026-03-21 09:16 | true (1) | All 3 rows from the same test customer CID=14952810 running repeated BTC settlement cycles. InitConversionRate=1 (USD instrument, no conversion). |

Note: Older data (pre-2021 from quarterly archives) is not accessible via MCP but forms the majority of the historical record.

---

## 4. Elements

All 124 columns are pass-through from the underlying tables with computation only on CommissionByUnits and SettlementTypeID (see Section 2). Full descriptions are in History.Position_Active documentation. Below is the complete column list with notes on backfilling behavior across branches.

| # | Element | Type | Nullable | Confidence | Branch Availability |
|---|---------|------|----------|------------|---------------------|
| 1 | PositionID | bigint | NO | CODE-BACKED | All branches - native |
| 2 | CID | int | YES | CODE-BACKED | All branches - native |
| 3 | ForexResultID | bigint | NO | CODE-BACKED | All branches - native (-1 for modern) |
| 4 | CurrencyID | int | NO | CODE-BACKED | All branches - native |
| 5 | ProviderID | int | NO | CODE-BACKED | All branches - native |
| 6 | GameServerID | int | NO | CODE-BACKED | All branches - native |
| 7 | InstrumentID | int | NO | CODE-BACKED | All branches - native |
| 8 | HedgeID | int | YES | CODE-BACKED | All branches - native |
| 9 | HedgeServerID | int | YES | CODE-BACKED | All branches - native |
| 10 | OrderID | int | YES | CODE-BACKED | All branches - native |
| 11 | Leverage | int | NO | CODE-BACKED | All branches - native |
| 12 | Amount | money | NO | CODE-BACKED | All branches - native |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | CODE-BACKED | All branches - native |
| 14 | UnitMargin | decimal(16,8) | NO | CODE-BACKED | All branches - native |
| 15 | LotCountDecimal | decimal(16,6) | YES | CODE-BACKED | All branches - native |
| 16 | InitForexRate | dbo.dtPrice | NO | CODE-BACKED | All branches - native. Rate at position open. |
| 17 | InitDateTime | datetime | NO | CODE-BACKED | All branches - native |
| 18 | NetProfit | money | NO | CODE-BACKED | All branches - native. P&L in account currency. |
| 19 | LimitRate | dbo.dtPrice | NO | CODE-BACKED | All branches - native. Take-profit rate. |
| 20 | StopRate | dbo.dtPrice | NO | CODE-BACKED | All branches - native. Stop-loss rate. |
| 21 | SpreadedPipBid | dbo.dtPrice | YES | CODE-BACKED | All branches - native |
| 22 | SpreadedPipAsk | dbo.dtPrice | YES | CODE-BACKED | All branches - native |
| 23 | IsBuy | bit | NO | CODE-BACKED | All branches. 1=Buy/Long, 0=Sell/Short. |
| 24 | CloseOnEndOfWeek | bit | NO | CODE-BACKED | All branches - native |
| 25 | EndOfWeekFee | money | NO | CODE-BACKED | All branches - native |
| 26 | Commission | money | NO | CODE-BACKED | All branches - native. Commission at open. |
| 27 | CommissionOnClose | money | NO | CODE-BACKED | All branches - native |
| 28 | SpreadedCommission | int | NO | CODE-BACKED | All branches - native |
| 29 | EndForexRate | dbo.dtPrice | NO | CODE-BACKED | All branches - native. Rate at close. |
| 30 | RequestedEndForexRate | dbo.dtPrice | YES | CODE-BACKED | All branches; NULL in Trade branch (not available for closed live positions). |
| 31 | EndDateTime | datetime | NO | CODE-BACKED | All branches - native |
| 32 | ActionType | int | NO | CODE-BACKED | All branches. Close reason. 1=ClientClose (68%), 0=auto (12%), 10=settlement (11%). See Section 2.4. |
| 33 | AdditionalParam | sql_variant | YES | CODE-BACKED | All branches - native |
| 34 | RequestOpenOccurred | datetime | YES | CODE-BACKED | All branches; NULL in Trade branch. |
| 35 | RequestCloseOccurred | datetime | YES | CODE-BACKED | All branches; NULL in Trade branch. |
| 36 | OpenOccurred | datetime | NO | CODE-BACKED | All branches. When position was opened. In Trade branch: Occurred column. |
| 37 | CloseOccurred | datetime | NO | CODE-BACKED | All branches. When position was closed. |
| 38 | SpreadGroupID | int | YES | NAME-INFERRED | All branches - native |
| 39 | LotCountGroupID | int | YES | NAME-INFERRED | All branches - native |
| 40 | TradeRange | int | YES | CODE-BACKED | All branches - native |
| 41 | InitForexPriceRateID | bigint | NO | CODE-BACKED | All branches - native |
| 42 | OrderPriceRateID | bigint | NO | CODE-BACKED | All branches - native |
| 43 | EndForexPriceRateID | bigint | NO | CODE-BACKED | All branches - native |
| 44 | OrderPriceRate | dbo.dtPrice | NO | CODE-BACKED | All branches - native |
| 45 | MarketPriceRate | dbo.dtPrice | NO | CODE-BACKED | All branches - native |
| 46 | MarketPriceRateID | bigint | NO | CODE-BACKED | All branches - native |
| 47 | EntryHedgeQuery | int | NO | NAME-INFERRED | All branches - native |
| 48 | EndHedgeQuery | int | YES | NAME-INFERRED | All branches; NULL in Trade branch. |
| 49 | ParentPositionID | bigint | YES | CODE-BACKED | All branches - native. Copy-trading parent position. |
| 50 | OrigParentPositionID | bigint | YES | CODE-BACKED | All branches - native |
| 51 | LastOpPriceRate | dbo.dtPrice | YES | CODE-BACKED | All branches - native |
| 52 | LastOpPriceRateID | bigint | YES | CODE-BACKED | All branches - native |
| 53 | LastOpConversionRate | dbo.dtPrice | YES | CODE-BACKED | All branches - native |
| 54 | LastOpConversionRateID | bigint | YES | CODE-BACKED | All branches - native |
| 55 | MirrorID | int | YES | CODE-BACKED | All branches - native. Copy relationship ID. 0=not a copy trade. |
| 56 | EndMarketRate | dbo.dtPrice | YES | CODE-BACKED | All branches - native |
| 57 | EndMarketPriceRateID | bigint | YES | CODE-BACKED | All branches - native |
| 58 | PositionRatio | decimal(7,6) | YES | CODE-BACKED | All branches - native |
| 59 | DirectAggLotCount | decimal(16,6) | YES | NAME-INFERRED | All branches - native |
| 60 | StocksOrderID | int | YES | CODE-BACKED | All branches - native |
| 61 | InitialAmountCents | money | NO | CODE-BACKED | All branches - native. Opening amount in cents. |
| 62 | IsOpenOpen | bit | YES | CODE-BACKED | All branches - native. Copy-trading open-open flag. |
| 63 | OpenExposureID | int | YES | CODE-BACKED | All branches - native |
| 64 | CloseExposureID | int | YES | CODE-BACKED | All branches - native |
| 65 | OpenMarketPriceRateID | bigint | YES | CODE-BACKED | All branches - native |
| 66 | CloseMarketPriceRateID | bigint | YES | CODE-BACKED | All branches - native |
| 67 | AmountInUnitsDecimalUnAdjusted | decimal(16,6) | YES | CODE-BACKED | All branches - native |
| 68 | LotCountDecimalUnAdjusted | decimal(16,6) | YES | CODE-BACKED | All branches - native |
| 69 | InitForexRateUnAdjusted | dbo.dtPrice | YES | CODE-BACKED | All branches - native |
| 70 | LimitRateUnAdjusted | dbo.dtPrice | YES | CODE-BACKED | All branches - native |
| 71 | StopRateUnAdjusted | dbo.dtPrice | YES | CODE-BACKED | All branches - native |
| 72 | EndForexRateUnAdjusted | dbo.dtPrice | YES | CODE-BACKED | All branches; NULL in Trade branch. |
| 73 | OrderPriceRateUnAdjusted | dbo.dtPrice | YES | CODE-BACKED | All branches - native |
| 74 | MarketPriceRateUnAdjusted | dbo.dtPrice | YES | CODE-BACKED | All branches - native |
| 75 | LastOpPriceRateUnAdjusted | dbo.dtPrice | YES | CODE-BACKED | All branches - native |
| 76 | EndMarketRateUnAdjusted | dbo.dtPrice | YES | CODE-BACKED | All branches; NULL in Trade branch. |
| 77 | InitExecutionID | bigint | YES | CODE-BACKED | All branches - native |
| 78 | EndExecutionID | bigint | YES | CODE-BACKED | All branches - native |
| 79 | RootHedgeServerID | int | YES | CODE-BACKED | All branches - native |
| 80 | TreeID | bigint | NO | CODE-BACKED | All branches - native. Hierarchical position group ID. |
| 81 | ExitOrderID | int | YES | CODE-BACKED | All branches - native |
| 82 | OrderType | int | YES | NAME-INFERRED | All branches - native |
| 83 | IsTslEnabled | tinyint | NO | CODE-BACKED | All branches - native |
| 84 | IsComputeForHedge | smallint | YES | NAME-INFERRED | All branches - native |
| 85 | FullCommission | money | YES | CODE-BACKED | All branches - native |
| 86 | FullCommissionOnClose | money | YES | CODE-BACKED | All branches - native |
| 87 | IsSettled | bit | NO | CODE-BACKED | Older branches: 0 (hardcoded). 2021Q1+ branches: native. 91.6% of Position_Active rows are settled. |
| 88 | SettlementTypeID | tinyint | YES | CODE-BACKED | Older: 0. 2021Q1 branch: cast(IsSettled as tinyint). 2021Q2+: ISNULL(SettlementTypeID, cast(IsSettled as tinyint)). |
| 89 | RedeemStatus | tinyint | YES | CODE-BACKED | Older branches: NULL. 2021+ branches: native. NULL=no redeem, 20=redeemed. |
| 90 | RedeemID | int | YES | CODE-BACKED | Older branches: NULL. 2021+ branches: native. |
| 91 | OriginalPositionID | bigint | YES | CODE-BACKED | Older branches: PositionID (self-reference alias). 2021+ branches: ISNULL(OriginalPositionID, PositionID). For partial-close clones: the parent PositionID. |
| 92 | InitialUnits | decimal(16,6) | YES | CODE-BACKED | Older branches: AmountInUnitsDecimal alias. 2021+ branches: native. Original unit count before partial close. |
| 93 | SubCloseTypeID | decimal(16,6) | YES | NAME-INFERRED | Older branches: NULL. 2021+ branches: native. |
| 94 | PartialCloseRatio | decimal(16,15) | YES | CODE-BACKED | Older branches: 1 (no partial close). 2021+ branches: ISNULL(PartialCloseRatio, 1). NULL = full close. |
| 95 | ReopenForPositionID | bigint | YES | CODE-BACKED | Older branches: NULL. 2021+ branches: native. |
| 96 | UnitsBaseValueCents | int | YES | CODE-BACKED | All branches: ISNULL(UnitsBaseValueCents, CONVERT(INT, InitialAmountCents)). Position value in cents. |
| 97 | IsDiscounted | bit | YES | CODE-BACKED | Older branches: 0. 2021+ branches: native. Discounted spread flag (Free Stocks). In Trade branch: from Trade.PositionTreeInfo. |
| 98 | CommissionByUnits | money | NO | CODE-BACKED | Computed: (AmountInUnitsDecimal / InitialUnits) * Commission. For proportional commission in partial-close scenarios. |
| 99 | FullCommissionByUnits | money | NO | CODE-BACKED | Computed: (AmountInUnitsDecimal / InitialUnits) * FullCommission. Same pattern as CommissionByUnits. |
| 100 | InitConversionRate | decimal(16,8) | YES | CODE-BACKED | Older branches: NULL. 2021Q2+ branches: native. USD conversion rate at open. |
| 101 | InitConversionRateID | bigint | YES | CODE-BACKED | Older branches: NULL. 2021Q2+ branches: native. |
| 102 | ExitOrderType | int | YES | CODE-BACKED | Older branches: NULL. 2021Q2+ branches: native. Type of exit order that triggered close. |
| 103 | MarketRangeValidationType | tinyint | YES | CODE-BACKED | Older branches: NULL. 2021Q2+ branches: native. |
| 104 | MarketRangePercentage | decimal(5,2) | YES | CODE-BACKED | Older branches: NULL. 2021Q2+ branches: native. |
| 105 | OpenActionType | int | NO | CODE-BACKED | Older branches: -1 (sentinel). 2021Q2+ branches: native. How the position was opened. |
| 106 | OpenMarketSpread | dbo.dtPrice | YES | CODE-BACKED | Older branches: NULL. 2021Q2+ branches: native. Market bid-ask spread at open. |
| 107 | CloseMarketSpread | dbo.dtPrice | YES | CODE-BACKED | Older branches: NULL. 2021Q2+ branches: native. |
| 108 | PnLVersion | tinyint | YES | CODE-BACKED | Older branches: 0. 2021Q2+ branches: native. P&L calculation algorithm version. |
| 109 | CloseMarkupOnOpen | money | YES | CODE-BACKED | Older branches: NULL. 2021Q2+ branches: native. |
| 110 | OpenMarkup | money | YES | CODE-BACKED | Older branches: NULL. 2021Q2+ branches: native. eToro revenue markup at open. |
| 111 | CloseMarkup | money | YES | CODE-BACKED | Older branches: NULL. 2021Q2+ branches: native. eToro revenue markup at close. |
| 112 | OpenEtoroPrice | dbo.dtPrice | YES | CODE-BACKED | Older branches: NULL. 2021Q2+ branches: native. eToro-quoted price at open (market + markup). |
| 113 | CloseEtoroPrice | dbo.dtPrice | YES | CODE-BACKED | Older branches: NULL. 2021Q2+ branches: native. eToro-quoted price at close. |
| 114 | EstimatedConversionMarkupRatio | decimal(20,4) | YES | CODE-BACKED | Older branches: NULL. 2021Q2+ branches: native. |
| 115 | EstimatedMarkupRatio | decimal(20,4) | YES | CODE-BACKED | Older branches: NULL. 2021Q2+ branches: native. |
| 116 | CloseTotalFees | money | YES | CODE-BACKED | Pre-2022Q4 branches: 0 (hardcoded). 2022Q4, Position_Active, PositionClosePartial: native. Total fees at close. |
| 117 | CloseTotalTaxes | money | YES | CODE-BACKED | Pre-2022Q4: 0. 2022Q4+ branches: native. Total taxes at close. |
| 118 | OpenTotalFees | money | YES | CODE-BACKED | Pre-2022Q4: 0. 2022Q4+ branches: native. Total fees at open. |
| 119 | OpenTotalTaxes | money | YES | CODE-BACKED | Pre-2022Q4: 0. 2022Q4+ branches: native. Total taxes at open. |
| 120 | OpenMarkupByUnits | money | YES | CODE-BACKED | Pre-2022Q4: NULL. 2022Q4+ branches: Cast((OpenMarkup * AmountInUnitsDecimal / ISNULL(InitialUnits, AmountInUnitsDecimal)) AS Money). Per-unit open markup. |
| 121 | IsNoStopLoss | bit | YES | CODE-BACKED | Pre-2022Q4: NULL. 2022Q4, Position_Active, PositionClosePartial: native. In Trade branch: from PositionTreeInfo. |
| 122 | IsNoTakeProfit | bit | YES | CODE-BACKED | Pre-2022Q4: NULL. 2022Q4+ branches: native. In Trade branch: from PositionTreeInfo. |
| 123 | OriginalOpenActionType | int | YES | CODE-BACKED | Pre-2022Q4: NULL. 2022Q4+ branches: native. Original OpenActionType before modifications. |
| 124 | InitialLotCount | decimal(16,6) | YES | CODE-BACKED | Pre-2022Q4: NULL. 2022Q4+ branches: native. Original lot count before partial close. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (62 quarterly branches) | dbo.HistoryPosition_2007Q3 ... dbo.HistoryPosition_2022Q4 | View (UNION branches) | Historical quarterly archives in dbo schema |
| (Position_Active branch) | History.Position_Active | View (UNION branch) | Primary archive 2021+; 2.5M+ rows |
| (Trade branch) | Trade.PositionTbl + Trade.PositionTreeInfo | View (UNION branch, JOIN, WHERE StatusID=2) | Recently closed live positions pending archival |
| (PartialClose branch) | History.PositionClosePartial | View (UNION branch) | Partial-close position records |
| InstrumentID | Trade.Instrument | Implicit FK | Trading instrument |
| CurrencyID | Dictionary.Currency | Implicit FK | Account currency |
| MirrorID | Trade.Mirror | Implicit FK | Copy-trading relationship |

### 5.2 Referenced By (other objects point to this)

| Source Object | Schema | Relationship Type | Description |
|--------------|--------|-------------------|-------------|
| History.GetAggClosePosition | History | View (depends on this) | Aggregated closed position metrics |
| History.GetClosedPositions | History | View (depends on this) | Filtered closed positions with instrument info |
| History.GetPosition | History | View (depends on this) | Enriched position with hedge data |
| History.GetPositionForXML | History | View (depends on this) | XML-format position data |
| History.GetPositionInfo | History | View (depends on this) | Position info with customer context |
| History.GetPositionWithPrimaryCurrency | History | View (depends on this) | Position with forex game data |
| History.ClosePositionEndOfDay | History | View (depends on this) | End-of-day close analysis |
| History.ClosePositionEndOfDay_Try | History | View (depends on this) | End-of-day close (try variant) |
| dbo.AccountStatement_* | dbo | SP (Read) | Account statement generation (8+ procedures) |
| BackOffice.GetCustomerClosedPositions | BackOffice | SP (Read) | Back-office closed position lookup |
| BackOffice.GetCustomerClosedOrders | BackOffice | SP (Read) | Back-office order lookup |
| BackOffice.JUNK_* | BackOffice | Functions (Read) | Legacy analytics functions |
| Billing.WithdrawService_GetRedeemCashouts | Billing | SP (Read) | Redeem cashout processing |
| Customer.SetBalanceClosePosition | Customer | SP (Read) | Balance update on close |
| History.GetNetProfit | History | Function (Read) | Net profit calculation |
| Trade.PostClosePositionActions | Trade | SP (Read for verification) | Archive writer that checks this view |
| History.SplitClosePositions | History | SP (UPDATE) | Retroactively adjusts rate and unit columns for stock split events (2000-row batches via OUTPUT -> History.PositionSplit) |
| (50+ total consumers) | Multiple | Various | This is the most referenced view in the History schema |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Position (view)
|- dbo.HistoryPosition_2007Q3 ... dbo.HistoryPosition_2022Q4 (62 tables - quarterly archives, dbo schema)
|- History.Position_Active (table - primary archive, Apr 2021+)
|    Written by: Trade.PostClosePositionActions (async archive-on-close)
|    Written by: History.MovePartialClosePositionToPosition_Active (partial close)
|- Trade.PositionTbl + Trade.PositionTreeInfo (tables - live closed positions WHERE StatusID=2)
+- History.PositionClosePartial (table - partial close records)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.HistoryPosition_2007Q3 ... 2022Q4 | Tables (62) | UNION ALL branches - quarterly historical archive |
| History.Position_Active | Table | UNION ALL branch - primary 2021+ archive |
| Trade.PositionTbl | Table | UNION ALL branch (JOIN WITH Trade.PositionTreeInfo WHERE StatusID=2) |
| Trade.PositionTreeInfo | Table | INNER JOIN with Trade.PositionTbl for IsDiscounted, IsNoStopLoss, IsNoTakeProfit |
| History.PositionClosePartial | Table | UNION ALL branch - partial close records |

### 6.2 Objects That Depend On This

50+ stored procedures and 6+ views across History, BackOffice, Billing, CEP, Customer, dbo, and Trade schemas. See Section 5.2 for key consumers.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Key indexes on source tables:
- `History.Position_Active`: CLUSTERED (CID, CloseOccurred), NC PK (PositionID), NC (MirrorID, PositionID), NC (HedgeServerID, CloseOccurred)
- `Trade.PositionTbl`: Multiple indexes; StatusID filter uses appropriate index
- Quarterly archive tables: Individual PK indexes per table

Querying this view without date or CID filters will touch all 65+ tables. Always filter by CloseOccurred or CID when possible.

### 7.2 Constraints

N/A for View. Key constraint: History.Position_Active has CHECK (CloseOccurred >= '2021-04-01').

---

## 8. Sample Queries

### 8.1 Get closed positions for a specific customer (recent history)
```sql
SELECT
    p.PositionID,
    p.InstrumentID,
    p.IsBuy,
    p.Amount,
    p.Leverage,
    p.NetProfit,
    p.ActionType,
    p.OpenOccurred,
    p.CloseOccurred,
    p.IsSettled,
    p.MirrorID,
    p.CommissionByUnits
FROM History.Position p WITH (NOLOCK)
WHERE p.CID = 14952810
  AND p.CloseOccurred >= '2026-01-01'
ORDER BY p.CloseOccurred DESC;
```

### 8.2 Copy-trading positions for a mirror relationship
```sql
SELECT
    p.PositionID,
    p.CID,
    p.InstrumentID,
    p.Amount,
    p.NetProfit,
    p.ActionType,
    p.PartialCloseRatio,
    p.OpenOccurred,
    p.CloseOccurred
FROM History.Position p WITH (NOLOCK)
WHERE p.MirrorID = 1839451
ORDER BY p.CloseOccurred DESC;
```

### 8.3 P&L by instrument for a customer (modern data only - use Position_Active for performance)
```sql
SELECT
    p.InstrumentID,
    COUNT(*) AS PositionCount,
    SUM(p.NetProfit) AS TotalProfit,
    AVG(p.Amount) AS AvgAmount
FROM History.Position_Active p WITH (NOLOCK)  -- query base table directly for speed
WHERE p.CID = 14952810
GROUP BY p.InstrumentID
ORDER BY TotalProfit DESC;
-- Note: For all-history queries use History.Position, but expect longer runtime
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.Position. Business context inherited from History.Position_Active documentation (Confluence: "Position partial-close: short summary").

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 8.8/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 122 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 50+ consumers identified | App Code: 0 repos | Corrections: 0 applied*
*Object: History.Position | Type: View | Source: etoro/etoro/History/Views/History.Position.sql*
