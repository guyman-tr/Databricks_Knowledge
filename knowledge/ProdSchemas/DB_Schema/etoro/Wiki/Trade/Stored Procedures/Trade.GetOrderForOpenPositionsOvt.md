# Trade.GetOrderForOpenPositionsOvt

> Returns comprehensive open-order and position data for a time window from both live Trade and History tables - an OVT reporting SP used for position open reconciliation and execution analysis.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @start DATETIME + @end DATETIME |
| **Partition** | OccurredAsDate date partitions on History.OpenExecutionPlan; #CombinedPositionData clustered index on (OpenOccurred) |
| **Indexes** | Creates clustered indexes on 3 temp tables: #PositionsHedgeServerChangeLog(ADM_DATE, PositionID), #CombinedPositionData(OpenOccurred), #OpenExecutionPlan(OrderID) |

---

## 1. Business Meaning

**WHAT:** `GetOrderForOpenPositionsOvt` is the open-position counterpart to `GetOrderForClosePositionsOvt`. It returns all positions that were opened within a date range, joining execution plan data (History.OpenExecutionPlan), actual executions (History.ExecutedOpenOrders), position details (from both live Trade.PositionTbl and archived History.Position_Active), and stock split data. It produces a comprehensive row per execution plan entry showing what position was created, how it was executed, and the position's full opening attributes.

**WHY:** Operations and risk teams use this for open-order execution analysis: what positions were opened in a period, which orders triggered them, how were units allocated, and whether hedge server routing changed during the window. The procedure is granted to the TradingOvt permission role, indicating it feeds an operational view tool (OVT) used for reconciliation and execution quality monitoring.

**HOW:**
1. Load `Trade.PositionsHedgeServerChangeLog` into `#PositionsHedgeServerChangeLog` (10-minute lookback from @start) with clustered index for join performance - captures hedge server rerouting events.
2. Load `History.PositionSplit` into `#HistoryPositionSplit` (splits since @start) - for stock-split-affected positions.
3. Build `#CombinedPositionData` via CTE UNION ALL: live positions from `Trade.PositionTbl` (StatusID=1, opened in window) + archived from `History.Position_Active` (opened in window), both joined with `History.PositionChangeLog_Active` (ChangeTypeID=0, open event) and `Trade.PositionTreeInfo`. Apply hedge server override from #PositionsHedgeServerChangeLog if present.
4. Load `History.OpenExecutionPlan` into `#OpenExecutionPlan` (by date range) with clustered index on OrderID.
5. Final SELECT: `#OpenExecutionPlan` LEFT JOIN `History.ExecutedOpenOrders` LEFT JOIN `#CombinedPositionData` LEFT JOIN `#HistoryPositionSplit`, ordered by OrderID.

---

## 2. Business Logic

### 2.1 Dual Position Source - Live Trade + History

**What:** Positions opened in the window may still be live (Trade.PositionTbl, StatusID=1) or already archived (History.Position_Active). The UNION ALL captures both without omission.

**Columns/Parameters Involved:** `StatusID` (Trade.PositionTbl filter), `Occurred`/`OpenOccurred`

**Rules:**
- `Trade.PositionTbl WHERE StatusID = 1 AND Occurred BETWEEN @start AND @end` -> open positions currently live
- `History.Position_Active WHERE OpenOccurred BETWEEN @start AND @end` -> positions that opened in window but were since closed and archived
- Both branches additionally filter on `History.PositionChangeLog_Active.Occurred BETWEEN @start AND @end AND ChangeTypeID = 0` (the open event log entry)
- UNION ALL normalizes both with identical column list (52 columns in #CombinedPositionData)
- `IsDiscounted` column: from Trade.PositionTreeInfo for live positions; from History.Position_Active directly for archived

### 2.2 Hedge Server Routing Correction

**What:** If a position's hedge server changed during the reconciliation window (a rerouting event), apply the pre-routing server ID rather than the current one, for accurate historical attribution.

**Columns/Parameters Involved:** `PositionHedgeServerID` (aliased as HedgeServerID), `RootHedgeServerID`

**Rules:**
- `ISNULL(hs.FromHedgeServerID, TPOS.HedgeServerID) AS PositionHedgeServerID` -> use pre-routing server if a change log entry exists
- `ISNULL(hs.FromRootHedgeServerID, TPOS.RootHedgeServerID) AS RootHedgeServerID` -> same for root hedge server
- Joined via `LEFT JOIN #PositionsHedgeServerChangeLog hs ON hs.PositionID = TPOS.PositionID AND hs.ADM_DATE >= @start`
- The `#PositionsHedgeServerChangeLog` temp table uses a 10-minute lookback (`DATEADD(MINUTE, -10, @start)`) to capture changes that started just before the reporting window

### 2.3 Settlement Type Fallback

**What:** Same pattern used across all OVT procedures: `ISNULL(SettlementTypeID, cast(IsSettled as tinyint))` normalizes the settlement type for both old and new positions.

**Columns/Parameters Involved:** `SettlementTypeID`, `IsSettled`

**Rules:**
- `ISNULL(TPOS.SettlementTypeID, CAST(TPOS.IsSettled AS tinyint)) AS SettlementTypeID` - for new positions, SettlementTypeID is set; for older positions it may be NULL so IsSettled (1=Real, 0=CFD) is cast to the same numeric code
- See Trade.PositionTbl documentation for full SettlementTypeID value map

### 2.4 PositionChangeLog as Open-Event Filter

**What:** The join with `History.PositionChangeLog_Active` (ChangeTypeID=0) serves as a filter ensuring only positions whose open event occurred in the window are returned - not all open positions that happened to exist in the window.

**Columns/Parameters Involved:** `ChangeTypeID`, `Occurred` (from pcl)

**Rules:**
- `ChangeTypeID = 0` = open event record in the position change log
- `pcl.Occurred BETWEEN @start AND @end` ensures the open event timestamp falls in the reporting window
- `pcl.LimitRate`, `pcl.StopRate`, `pcl.AmountInUnits`, `pcl.MirrorID`, etc. come from the open event log, not the current position state (making the data point-in-time accurate for the open event)

### 2.5 Stock Split Integration

**What:** For positions affected by a stock split since @start, `SplitPositionID` is included in the output to link the position to its split record.

**Columns/Parameters Involved:** `SplitPositionID`

**Rules:**
- `LEFT JOIN #HistoryPositionSplit ps ON cpd.PositionID = ps.PositionID`
- NULL if no split occurred; non-NULL if the position was affected by a stock split

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @start | DATETIME | NO | - | CODE-BACKED | Start of the reporting window (inclusive). Filters History.OpenExecutionPlan by OccurredAsDate and position open Occurred. Also used as lower bound for PositionsHedgeServerChangeLog (with 10-minute lookback: DATEADD(MINUTE,-10,@start)). |
| 2 | @end | DATETIME | NO | - | CODE-BACKED | End of the reporting window (inclusive). Filters History.OpenExecutionPlan by OccurredAsDate and position open Occurred. Typically set to current time for live reconciliation reports. |

**Output columns (from final SELECT):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OccurredAsDate | DATE | YES | - | CODE-BACKED | Date portion of the open execution event from History.OpenExecutionPlan. Used as partition key on the source table. |
| 2 | OrderID | INT | YES | - | CODE-BACKED | Order ID from History.OpenExecutionPlan - the primary identifier for the open order execution plan entry. The result set is ordered by this column. |
| 3 | CID | INT | YES | - | CODE-BACKED | Customer ID from History.OpenExecutionPlan - who placed the order. |
| 4 | MirrorID | INT | YES | - | CODE-BACKED | Mirror/CopyTrader ID from History.OpenExecutionPlan. Non-NULL when the order was placed as part of a copy-trading relationship. |
| 5 | Units | DECIMAL | YES | - | CODE-BACKED | Units from History.OpenExecutionPlan - the total units requested in the execution plan. |
| 6 | Level | INT | YES | - | CODE-BACKED | Hierarchy level in the execution plan tree from History.OpenExecutionPlan (e.g., 0=root order, 1=child). |
| 7 | SettlementTypeID | TINYINT | YES | - | CODE-BACKED | Settlement type from History.OpenExecutionPlan. 1=Real stock, 0=CFD (same value space as Trade.PositionTbl.SettlementTypeID). |
| 8 | IsHedged | BIT | YES | - | CODE-BACKED | From History.OpenExecutionPlan. Whether this execution was routed to a hedging server (1=yes, 0=no). |
| 9 | OpenActionType | INT | YES | - | CODE-BACKED | Open action type from History.OpenExecutionPlan. Same value space as Trade.PositionTbl.OpenActionType (e.g., 1=Manual, 3=CopyTrade). |
| 10 | OpenCorrelationID | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Correlation GUID from History.OpenExecutionPlan linking the plan entry to History.ExecutedOpenOrders rows. Primary join key to heoo. |
| 11 | ParentOpenCorrelationID | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Parent correlation GUID from History.OpenExecutionPlan for hierarchical open orders. NULL for root-level opens. |
| 12 | Amount | DECIMAL | YES | - | CODE-BACKED | Amount in base currency from History.OpenExecutionPlan - the planned position value. |
| 13 | OrderID1 | INT | YES | - | CODE-BACKED | OrderID from History.ExecutedOpenOrders (the actual executed order). May differ from hoep.OrderID in split/hierarchical execution scenarios. Aliased as OrderID1 due to column name conflict with hoep.OrderID. |
| 14 | PositionID | BIGINT | YES | - | CODE-BACKED | Position ID from History.ExecutedOpenOrders - the position that was created by this execution. NULL if no execution record exists (LEFT JOIN). |
| 15 | ExecutionID | INT | YES | - | CODE-BACKED | Execution record ID from History.ExecutedOpenOrders - identifies the specific fill event. |
| 16 | Units1 | DECIMAL | YES | - | CODE-BACKED | Units from History.ExecutedOpenOrders - the actual executed units (vs. planned units in column 5). Aliased as Units1. |
| 17 | OpenCorrelationID1 | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | OpenCorrelationID from History.ExecutedOpenOrders. Aliased as OpenCorrelationID1. Matches hoep.OpenCorrelationID in join. |
| 18 | PostAdjustmentRatio | DECIMAL | YES | - | CODE-BACKED | From History.ExecutedOpenOrders. Ratio applied after execution for corporate actions (e.g., stock splits affecting unit count at open). |
| 19 | RequestedUnits | DECIMAL | YES | - | CODE-BACKED | From History.ExecutedOpenOrders. The originally requested units before any partial fill or adjustment. |
| 20 | TreeID | BIGINT | YES | - | CODE-BACKED | From History.ExecutedOpenOrders. The copy-trade tree this position belongs to. |
| 21 | CID1 | INT | YES | - | CODE-BACKED | CID from #CombinedPositionData (the position's customer). Aliased as CID1 due to column conflict. Should match CID from execution plan. |
| 22 | PositionID1 | BIGINT | YES | - | CODE-BACKED | PositionID from #CombinedPositionData. Aliased as PositionID1 due to column conflict with heoo.PositionID. |
| 23 | InstrumentID | INT | YES | - | CODE-BACKED | Instrument (asset) ID from the position. FK to Trade.Instrument. |
| 24 | Leverage | INT | YES | - | CODE-BACKED | Position leverage multiplier (e.g., 2, 5, 10, 50). 1 for real stock positions. |
| 25 | InitForexRate | DECIMAL | YES | - | CODE-BACKED | Initial forex conversion rate between position currency and account base currency at open time. |
| 26 | InitDateTime | DATETIME | YES | - | CODE-BACKED | The timestamp when the position was initialized/created. |
| 27 | ActionType | INT | YES | - | CODE-BACKED | OpenActionType from the position (aliased as ActionType in CTE). Describes how the position was opened. See Trade.PositionTbl.OpenActionType for value map. |
| 28 | StopRate | DECIMAL | YES | - | CODE-BACKED | Stop-loss rate from PositionChangeLog_Active (open event). From pcl.StopRate. |
| 29 | LimitRate | DECIMAL | YES | - | CODE-BACKED | Take-profit rate from PositionChangeLog_Active (open event). From pcl.LimitRate. |
| 30 | Amount1 | DECIMAL | YES | - | CODE-BACKED | Position amount from PositionChangeLog_Active: pcl.UnitsBaseValueCents / 100.00. Converts cents to dollars. Aliased as Amount1. |
| 31 | AmountInUnitsDecimal | DECIMAL | YES | - | CODE-BACKED | Position size in instrument units from pcl.AmountInUnits. For CFDs this is the number of contract units; for real stocks this is share count. |
| 32 | Commission | DECIMAL | YES | - | CODE-BACKED | Spread commission charged at open from Trade.PositionTbl / History.Position_Active. |
| 33 | SpreadedCommission | DECIMAL | YES | - | CODE-BACKED | Additional spread-based commission applied at open. |
| 34 | IsBuy | BIT | YES | - | CODE-BACKED | Position direction: 1=Buy/Long, 0=Sell/Short. |
| 35 | OpenOccurred | DATETIME | YES | - | CODE-BACKED | Exact timestamp when the position was opened (from Trade.PositionTbl.Occurred or History.Position_Active.OpenOccurred). The WHERE clause filters to BETWEEN @start AND @end. |
| 36 | OrderID | INT | YES | - | CODE-BACKED | OrderID from #CombinedPositionData (cpd.OrderID). The order that created this position. Duplicated from column 2 but sourced from position data rather than execution plan. |
| 37 | TradeRange | DECIMAL | YES | - | CODE-BACKED | Maximum allowed rate deviation accepted by customer at open (market range / slippage tolerance). |
| 38 | InitForexPriceRateID | INT | YES | - | CODE-BACKED | Rate record ID for the initial forex conversion rate used at open. FK to the rates pricing system. |
| 39 | ParentPositionID | BIGINT | YES | - | CODE-BACKED | From pcl. Parent position ID for copy-trade child positions. NULL for manually opened positions. |
| 40 | LastOpPriceRate | DECIMAL | YES | - | CODE-BACKED | Last operation price rate from PositionChangeLog_Active - the execution rate at open. |
| 41 | LastOpPriceRateID | INT | YES | - | CODE-BACKED | Rate record ID for the last operation price rate. |
| 42 | LastOpConversionRate | DECIMAL | YES | - | CODE-BACKED | Last operation forex conversion rate at open. |
| 43 | LastOpConversionRateID | INT | YES | - | CODE-BACKED | Rate record ID for the last operation conversion rate. |
| 44 | UnitMargin | DECIMAL | YES | - | CODE-BACKED | Margin required per unit at open time. Used for margin calculations and equity reporting. |
| 45 | MirrorID1 | BIGINT | YES | - | CODE-BACKED | MirrorID from position data (pcl.MirrorID). Aliased as MirrorID1 due to conflict with hoep.MirrorID (column 4). |
| 46 | PositionRatio | DECIMAL | YES | - | CODE-BACKED | Ratio of this position within its copy-trade tree (how much of the leader's position this copier replicates). |
| 47 | InitialAmountCents | INT | YES | - | CODE-BACKED | Initial position amount in cents (integer). Stores the amount in 1/100ths of the base currency for precision. |
| 48 | HedgeServerID | INT | YES | - | CODE-BACKED | Effective hedge server ID after applying routing correction: ISNULL(hs.FromHedgeServerID, TPOS.HedgeServerID). Reflects the server responsible for this position at open. |
| 49 | InitExecutionID | INT | YES | - | CODE-BACKED | Execution ID at initial open. Links to execution records for the position's creation event. |
| 50 | RootHedgeServerID | INT | YES | - | CODE-BACKED | Root hedge server in the hedging hierarchy after routing correction: ISNULL(hs.FromRootHedgeServerID, TPOS.RootHedgeServerID). |
| 51 | IsOpenOpen | BIT | YES | - | CODE-BACKED | 1 if the position was opened while another position on the same instrument was already open by the same customer. Tracks concurrent position scenario. |
| 52 | TreeID1 | BIGINT | YES | - | CODE-BACKED | TreeID from position data (cpd.TreeID). Aliased as TreeID1 due to conflict with heoo.TreeID. The copy-trade tree this position belongs to. |
| 53 | IsComputeForHedge | BIT | YES | - | CODE-BACKED | 1 if this position is included in hedge computation. Flags positions relevant to the hedging exposure calculation. |
| 54 | IsTslEnabled | BIT | YES | - | CODE-BACKED | From pcl. 1 if Trailing Stop Loss is enabled for this position at open. |
| 55 | FullCommission | DECIMAL | YES | - | CODE-BACKED | Total commission at open including all components (spread + overnight + other fees). |
| 56 | IsSettled | BIT | YES | - | CODE-BACKED | Legacy settlement flag from position: 1=Real stock position (actual share ownership), 0=CFD. Predates SettlementTypeID. See Section 2.3 for fallback logic. |
| 57 | SettlementTypeID1 | TINYINT | YES | - | CODE-BACKED | Normalized settlement type from position: ISNULL(SettlementTypeID, cast(IsSettled as tinyint)). Aliased as SettlementTypeID1 to distinguish from hoep.SettlementTypeID (column 7). Values: 0=CFD, 1=Real. |
| 58 | RedeemStatus | TINYINT | YES | - | CODE-BACKED | Redemption status of the position. Relevant for real stock positions being redeemed. See Trade.PositionTbl.RedeemStatus for value map. |
| 59 | InitialUnits | DECIMAL | YES | - | CODE-BACKED | Original unit count at position open before any partial close or adjustment. NULL for positions opened before this column was added. |
| 60 | IsDiscounted | BIT | YES | - | CODE-BACKED | From Trade.PositionTreeInfo (for live) or History.Position_Active (for archived). 1 if a discount was applied to this position's fees. |
| 61 | OrderType | TINYINT | YES | - | CODE-BACKED | Order type from position. Indicates whether the open was a market order, limit order, etc. See Trade.PositionTbl.OrderType for value map. |
| 62 | OpenMarketPriceRateID | INT | YES | - | CODE-BACKED | Rate record ID for the market price at open time. Used for spread and markup calculations. |
| 63 | PnLVersion | TINYINT | YES | - | CODE-BACKED | P&L calculation formula version used for this position. 0=legacy CFD formula, 1=real stock formula. Derived from SettlementType. |
| 64 | InitConversionRate | DECIMAL | YES | - | CODE-BACKED | Initial currency conversion rate at position open. Used for converting position P&L to account base currency. |
| 65 | SpreadedPipBid | DECIMAL | YES | - | CODE-BACKED | Bid price including spread at open time (spread-adjusted bid). |
| 66 | SpreadedPipAsk | DECIMAL | YES | - | CODE-BACKED | Ask price including spread at open time (spread-adjusted ask). |
| 67 | OpenMarkup | DECIMAL | YES | - | CODE-BACKED | Markup applied to the open price above the raw market rate. Part of eToro's spread revenue. |
| 68 | OpenEtoroPrice | DECIMAL | YES | - | CODE-BACKED | eToro's displayed open price shown to the customer (market rate + markup). |
| 69 | CloseMarkupOnOpen | DECIMAL | YES | - | CODE-BACKED | Close-side markup amount that was locked in at open time (relevant for spreads guaranteed at open). |
| 70 | OpenTotalTaxes | DECIMAL | YES | - | CODE-BACKED | Total tax amount charged at position open. |
| 71 | OpenTotalFees | DECIMAL | YES | - | CODE-BACKED | Total fee amount charged at position open (sum of all applicable fees). |
| 72 | OpenMarketSpread | DECIMAL | YES | - | CODE-BACKED | Raw market spread (bid-ask) at open time, before eToro markup. |
| 73 | IsNoStopLoss | BIT | YES | - | CODE-BACKED | From pcl. 1 if this position has no stop-loss set (customer opted out of stop-loss protection). |
| 74 | IsNoTakeProfit | BIT | YES | - | CODE-BACKED | From pcl. 1 if this position has no take-profit set. |
| 75 | LotCountDecimal | DECIMAL | YES | - | CODE-BACKED | Position size expressed in lots (Units / Instrument.Unit lot size). From pcl.LotCountDecimal. |
| 76 | SplitPositionID | BIGINT | YES | - | CODE-BACKED | From History.PositionSplit. Non-NULL if this position was involved in a stock split since @start. Links to the split record for unit adjustment tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @start, @end (filter) | History.OpenExecutionPlan | Lookup | Date range filter on OccurredAsDate (partition key) |
| @start, @end (filter) | Trade.PositionTbl | Lookup | Filters live positions by Occurred in window |
| @start, @end (filter) | History.Position_Active | Lookup | Filters archived positions by OpenOccurred in window |
| @start (filter) | Trade.PositionsHedgeServerChangeLog | Lookup | Gets hedge server rerouting events since @start |
| @start (filter) | History.PositionSplit | Lookup | Gets stock splits since @start |
| TPOS.TreeID = TPTI.TreeID | Trade.PositionTreeInfo | JOIN | Gets IsDiscounted for live positions |
| pcl.ChangeTypeID=0 | History.PositionChangeLog_Active | JOIN | Open event records for positions in window |
| heoo.PositionID = cpd.PositionID | History.ExecutedOpenOrders | JOIN | Links execution fills to positions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| UsersPermissions.TradingOvt | GRANT EXECUTE | Permission | OVT tool role granted execute permission - called by operational view tooling |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderForOpenPositionsOvt (procedure)
|- Trade.PositionTbl (table) - live open positions
|- Trade.PositionTreeInfo (table) - IsDiscounted flag
|- Trade.PositionsHedgeServerChangeLog (table) - hedge server routing overrides
|- History.PositionChangeLog_Active (table) - open event log with rate/amount data
|- History.Position_Active (table) - archived positions
|- History.OpenExecutionPlan (table) - execution plan entries (main driver)
|- History.ExecutedOpenOrders (table) - actual fill records
|- History.PositionSplit (table) - stock split events
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Live open positions (StatusID=1), JOINed with PositionChangeLog and PositionTreeInfo |
| Trade.PositionTreeInfo | Table | JOINed for IsDiscounted flag via TreeID |
| Trade.PositionsHedgeServerChangeLog | Table | LEFT JOIN for hedge server routing correction |
| History.PositionChangeLog_Active | Table | INNER JOIN on PositionID + ChangeTypeID=0 - provides open-event rate/amount data |
| History.Position_Active | Table | Archived positions in UNION ALL branch |
| History.OpenExecutionPlan | Table | Primary driver table - execution plan entries for the window |
| History.ExecutedOpenOrders | Table | LEFT JOIN - actual fill records matched by OpenCorrelationID |
| History.PositionSplit | Table | LEFT JOIN - stock split records since @start |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| UsersPermissions.TradingOvt | Permission role | Execute permission granted for OVT tooling |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. (Temp table indexes created internally: CIX on #PositionsHedgeServerChangeLog(ADM_DATE, PositionID), CIX on #CombinedPositionData(OpenOccurred), CIX on #OpenExecutionPlan(OrderID))

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION (RECOMPILE) | Query hint | Applied on key temp table population queries to prevent suboptimal cached plans for different date ranges |
| SET QUOTED_IDENTIFIER OFF | Session setting | Allows double-quoted string literals; applied at SP creation |

---

## 8. Sample Queries

### 8.1 Get open positions from a recent time window

```sql
EXEC Trade.GetOrderForOpenPositionsOvt
    @start = '2026-03-17 08:00:00',
    @end   = '2026-03-17 09:00:00'
```

### 8.2 Find all positions opened by a specific customer in a window

```sql
-- After executing the SP into a temp table or CTE:
-- (SP returns full result set; filter client-side or wrap in a view)
EXEC Trade.GetOrderForOpenPositionsOvt
    @start = '2026-03-16 00:00:00',
    @end   = '2026-03-17 00:00:00'
-- Then: WHERE CID = 12345678
```

### 8.3 Check hedge server rerouting events for opened positions

```sql
-- Reference: underlying data source for rerouting logic
SELECT TOP 20
    PositionID,
    FromHedgeServerID,
    ToHedgeServerID,
    ADM_DATE
FROM Trade.PositionsHedgeServerChangeLog WITH (NOLOCK)
WHERE ADM_DATE >= DATEADD(MINUTE, -10, '2026-03-17 08:00:00')
ORDER BY ADM_DATE DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 76 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderForOpenPositionsOvt | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderForOpenPositionsOvt.sql*
