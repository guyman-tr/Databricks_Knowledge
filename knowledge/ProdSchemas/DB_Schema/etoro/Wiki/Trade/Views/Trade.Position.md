# Trade.Position

> The PRIMARY open positions view joining PositionTbl with PositionTreeInfo for comprehensive open position data including SL/TP rates, TSL flags, and backward-compatible computed columns.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.Position is the **primary open positions view** in the Trade schema. It joins Trade.PositionTbl with Trade.PositionTreeInfo to produce a comprehensive record for each open position, combining base position data (amount, leverage, forex rates, mirror/copy-trade linkage) with tree-level settings (limit/stop rates, trailing stop-loss flags, discounting, weekend close settings).

This view exists because open position data is split across two tables: PositionTbl holds the core transactional data (amounts, rates, mirror IDs), while PositionTreeInfo holds the risk-management settings (SL/TP rates, TSL enablement, partition metadata). Consumers need both in a single row. The view also provides backward-compatible computed columns (InitialUnits, UnitsBaseValueCents, SettlementTypeID) for legacy positions that lack newer columns, and prorated commission/markup columns (CommissionByUnits, FullCommissionByUnits, OpenMarkupByUnits) for partial-close scenarios.

The view filters WHERE StatusID = 1 (open only). The JOIN uses partition-aligned matching: `ABS(TPOS.TreeID%50) = TPTI.PartitionCol` for optimal partition elimination. Key identifiers are PositionID, CID, InstrumentID, HedgeID, and TreeID.

---

## 2. Business Logic

**Filter**: WHERE TPOS.StatusID = 1. Only open positions are returned.

**Join**: INNER JOIN Trade.PositionTreeInfo TPTI ON TPOS.TreeID = TPTI.TreeID AND ABS(TPOS.TreeID%50) = TPTI.PartitionCol. The partition condition aligns with the physical partitioning of PositionTreeInfo for efficient plan generation.

**Computed columns**:
- **InitialUnits**: ISNULL(InitialUnits, AmountInUnitsDecimal) - backward-compatible initial units for positions opened before InitialUnits existed.
- **UnitsBaseValueCents**: ISNULL(UnitsBaseValueCents, CONVERT(INT, InitialAmountCents)) - backward-compatible base value in cents.
- **SettlementTypeID**: ISNULL(SettlementTypeID, cast(IsSettled as tinyint)) - backward-compatible; falls back to IsSettled when modern column is NULL.
- **CommissionByUnits**: Prorated commission when InitialUnits/AmountInUnitsDecimal > 0; formula: (AmountInUnitsDecimal / InitialUnits) * Commission. Used for partial-close PnL.
- **FullCommissionByUnits**: Same proration for FullCommission.
- **OpenMarkupByUnits**: Prorated open markup; formula: OpenMarkup * AmountInUnitsDecimal / InitialUnits.
- **PositionPartitionCol** / **TreePartitionCol**: Aliases exposing partition columns from both tables.

---

## 3. Data Overview

N/A - output mirrors Trade.PositionTbl enriched with Trade.PositionTreeInfo. See [Trade.PositionTbl](../Tables/Trade.PositionTbl.md) for data overview.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Primary key. Unique identifier for the open position. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID. FK to Customer.Customer. |
| 3 | ForexResultID | bigint | NO | - | CODE-BACKED | Legacy forex result tracking (deprecated). |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Denomination currency. FK to Dictionary.Currency. |
| 5 | ProviderID | int | NO | - | CODE-BACKED | Execution provider. FK to Trade.Provider. |
| 6 | GameServerID | int | YES | - | CODE-BACKED | Game/demo server ID. |
| 7 | InstrumentID | int | NO | - | CODE-BACKED | Instrument traded. FK to Trade.Instrument. |
| 8 | HedgeID | bigint | YES | - | CODE-BACKED | Hedge record ID. |
| 9 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server managing this position. |
| 10 | OrderID | int | YES | - | CODE-BACKED | Originating order. FK to Trade.Orders. |
| 11 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier (1, 2, 5, 10, etc.). |
| 12 | Amount | money | NO | - | CODE-BACKED | Position size in denomination currency. |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in units/shares. |
| 14 | UnitMargin | money | YES | - | CODE-BACKED | Unit margin for hedge/exposure. |
| 15 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count from provider. |
| 16 | NetProfit | money | YES | - | CODE-BACKED | Unrealized PnL (live-calculated). |
| 17 | InitForexRate | float | YES | - | CODE-BACKED | Forex rate at open. |
| 18 | InitDateTime | datetime | YES | - | CODE-BACKED | When position was opened. |
| 19 | LimitRate | float | YES | - | CODE-BACKED | Take-profit price (from PositionTreeInfo). |
| 20 | StopRate | float | YES | - | CODE-BACKED | Stop-loss price (from PositionTreeInfo). |
| 21 | SpreadedPipBid | float | YES | - | CODE-BACKED | Spread-adjusted pip bid. |
| 22 | SpreadedPipAsk | float | YES | - | CODE-BACKED | Spread-adjusted pip ask. |
| 23 | IsBuy | bit | NO | - | CODE-BACKED | 1=buy/long, 0=sell/short. |
| 24 | CloseOnEndOfWeek | bit | YES | - | CODE-BACKED | From TPTI. Close before weekend. |
| 25 | EndOfWeekFee | money | YES | - | CODE-BACKED | Weekend close fee. |
| 26 | Commission | money | YES | - | CODE-BACKED | Commission at open. |
| 27 | SpreadedCommission | money | YES | - | CODE-BACKED | Spread-adjusted commission. |
| 28 | FullCommission | money | YES | - | CODE-BACKED | Full commission including extras. |
| 29 | InitialUnits | decimal(16,6) | YES | - | CODE-BACKED | Computed: ISNULL(InitialUnits, AmountInUnitsDecimal). |
| 30 | UnitsBaseValueCents | int | YES | - | CODE-BACKED | Computed: ISNULL(UnitsBaseValueCents, CONVERT(INT, InitialAmountCents)). |
| 31 | CommissionByUnits | money | YES | - | CODE-BACKED | Computed: Prorated commission for partial close. |
| 32 | FullCommissionByUnits | money | YES | - | CODE-BACKED | Computed: Prorated full commission for partial close. |
| 33 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Computed: ISNULL(SettlementTypeID, cast(IsSettled as tinyint)). |
| 34 | OpenMarkupByUnits | money | YES | - | CODE-BACKED | Computed: Prorated open markup for partial close. |
| 35 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent for add-to-position hierarchy. |
| 36 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent before splits. |
| 37 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror ID. 0 = manual. |
| 38 | TreeID | bigint | YES | - | CODE-BACKED | Tree identifier for partition/join. |
| 39 | RowVersionPosition | rowversion | YES | - | CODE-BACKED | Optimistic concurrency from PositionTbl. |
| 40 | RowVersionTree | rowversion | YES | - | CODE-BACKED | Optimistic concurrency from PositionTreeInfo. |
| 41-85+ | (Additional columns) | various | - | - | CODE-BACKED | AdditionalParam, RequestOccurred, Occurred, ClamedOnDay, SpreadGroupID, LotCountGroupID, TradeRange, InitForexPriceRateID, OrderPriceRateID, OrderPriceRate, MarketPriceRate, MarketPriceRateID, EntryHedgeQuery, LastOpPriceRate, LastOpPriceRateID, LastOpConversionRate, LastOpConversionRateID, PositionRatio, IsComputeForHedge, DirectAggLotCount, StocksOrderID, InitialAmountCents, LastEOWClameDate, IsOpenOpen, OpenExposureID, OpenMarketPriceRateID, UnAdjusted columns (AmountInUnitsDecimal, LotCountDecimal, InitForexRate, LimitRate, StopRate, SpreadedPipBid, SpreadedPipAsk, OrderPriceRate, MarketPriceRate, LastOpPriceRate), InitExecutionID, RootHedgeServerID, PartitionCol, LastOverNightClameDate, OrderType, IsTslEnabled, SLManualVer, NextThresHold, IsDiscounted, RedeemStatus, RedeemID, ReopenForPositionID, InitConversionRate, InitConversionRateID, OpenActionType, MarketRangeValidationType, MarketRangePercentage, PositionPartitionCol, TreePartitionCol, IsNoStopLoss, IsNoTakeProfit, OpenMarketSpread, PnLVersion, CloseMarkupOnOpen, EstimatedConversionMarkupRatio, EstimatedMarkupRatio, OpenMarkup, OpenEtoroPrice, OpenTotalTaxes, OpenTotalFees, InitialLotCount, CloseMarkup. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | FK | Customer who owns the position |
| InstrumentID | Trade.Instrument | FK | Instrument being traded |
| ProviderID | Trade.Provider | FK | Execution provider |
| OrderID | Trade.Orders | FK | Originating order |
| HedgeID | Trade.Hedge | FK | Hedge record |
| ParentPositionID | Trade.PositionTbl | FK | Parent position in hierarchy |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionTbl
    |
Trade.PositionTreeInfo
    |
    +-- Trade.Position (INNER JOIN, StatusID=1)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Base table; JOIN key TreeID, filter StatusID=1 |
| Trade.PositionTreeInfo | Table | JOIN for LimitRate, StopRate, CloseOnEndOfWeek, IsTslEnabled, IsDiscounted, IsNoStopLoss, IsNoTakeProfit, RowVersionTree |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Open positions for a customer

```sql
SELECT PositionID, InstrumentID, IsBuy, Amount, Leverage, InitDateTime
FROM Trade.Position WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.2 Open positions with partial-close commission

```sql
SELECT PositionID, AmountInUnitsDecimal, InitialUnits, CommissionByUnits, FullCommissionByUnits
FROM Trade.Position WITH (NOLOCK)
WHERE CommissionByUnits > 0;
```

### 8.3 Mirror/copy-trade open positions

```sql
SELECT PositionID, CID, MirrorID, Amount, InitForexRate
FROM Trade.Position WITH (NOLOCK)
WHERE MirrorID > 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 85 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Position | Type: View | Source: etoro/etoro/Trade/Views/Trade.Position.sql*
