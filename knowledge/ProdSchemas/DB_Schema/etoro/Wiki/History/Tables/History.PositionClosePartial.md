# History.PositionClosePartial

> Partitioned staging table for partial close position records (PositionID % 50 hash partitioning), holding the complete position snapshot at the moment of each partial close event before batch migration to History.Position_Active. Included in the History.Position view.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PositionID (BIGINT, NONCLUSTERED PK on PositionID + PartitionCol) |
| **Partition** | Yes - PS_PositionPartialCLose partition scheme; PartitionCol = PositionID % 50 (50 hash partitions) |
| **Indexes** | 3 (NONCLUSTERED PK, CLUSTERED on CID+CloseOccurred+OpenOccurred, NC on CID+OpenOccurred) |

---

## 1. Business Meaning

History.PositionClosePartial is the staging table for partial position close records. When a customer partially closes a position (selling a fraction of their holding while keeping the rest open), the full position snapshot at the time of the partial close is written here. The record captures both the closed portion and the context of the original position.

The table is part of a two-step archival pipeline:
1. **Write**: The trading engine writes the partial close record to this table.
2. **Migrate**: History.MovePartialClosePositionToPosition_Active runs in batches by partition (0-49), moving rows to History.Position_Active.

While data resides here (before migration), it is visible via the History.Position view (which UNIONs this table with History.Position_Active). The current live database has 0 rows - all partial close records have been migrated to History.Position_Active.

The partition scheme PS_PositionPartialCLose uses `PositionID % 50` (the computed column PartitionCol) to hash-distribute records across 50 partitions for efficient batch migration. This differs from time-based partitioning used in tables like PositionChangeLog_Active_BIGINT.

The 124-column schema mirrors History.Position_Active exactly, with three additional columns specific to partial closes: `OriginalPositionID`, `PartialCloseRatio`, and `ReopenForPositionID`.

---

## 2. Business Logic

### 2.1 Partial Close Record Lifecycle

**What**: A partial close creates a new completed position record (representing the closed fraction) while the remainder stays open as a new position.

**Columns/Parameters Involved**: `PositionID`, `OriginalPositionID`, `PartialCloseRatio`, `ReopenForPositionID`, `Amount`, `AmountInUnitsDecimal`

**Rules**:
- PositionID: the NEW position ID assigned to the closed-out partial portion.
- OriginalPositionID: the original position that was partially closed (may differ if the position was itself a result of prior partials).
- ReopenForPositionID: the new position ID created for the remaining open portion.
- PartialCloseRatio: the fraction of the original position that was closed. decimal(16,15) for maximum precision (e.g., 0.5 = 50% closed, 0.333333333333333 = 1/3 closed).
- InitialUnits: the original position's unit count before the partial close.
- Amount/AmountInUnitsDecimal: reflect the CLOSED portion's value/units.
- SubCloseTypeID: identifies the sub-type of close operation.

### 2.2 Hash Partition Strategy (PositionID % 50)

**What**: The 50-partition hash scheme enables efficient batch migration to History.Position_Active.

**Columns/Parameters Involved**: `PartitionCol` (computed: PositionID % 50)

**Rules**:
- PartitionCol is a persisted computed column: `[PositionID] % 50`.
- History.MovePartialClosePositionToPosition_Active accepts @StartPartitionID and @EndPartitionID (0-49) to process specific partition ranges.
- Batch size @Batch (default 1000) limits rows moved per call.
- The migration INSERT...SELECT moves rows to History.Position_Active using the same PositionID%50 partition scheme.
- After migration, rows are deleted from this staging table.

### 2.3 Full Position Snapshot at Close

**What**: Every field from the position record is captured at the moment of the partial close.

**Columns/Parameters Involved**: `InitForexRate`, `EndForexRate`, `NetProfit`, `Commission`, `ActionType`, all rate columns

**Rules**:
- InitForexRate/InitDateTime: instrument rate and time when the position was OPENED (not partially closed).
- EndForexRate/EndDateTime: instrument rate and time when the partial close was executed.
- OpenOccurred/CloseOccurred: the actual open and close timestamps for this partial close record.
- NetProfit: P&L in USD for the CLOSED fraction only.
- Commission/CommissionOnClose: fees for open and close legs.
- All dbo.dtPrice columns (decimal(16,8)) for rates, spreads, markups.
- IsBuy: whether this was a BUY position (true) or SELL position (false) at open.
- Markup/fee columns (OpenMarkup, CloseMarkup, etc.): pricing cost breakdown for revenue accounting.

### 2.4 History.Position View Integration

**What**: This table contributes to the unified History.Position view alongside History.Position_Active.

**Rules**:
- History.Position is a view that UNIONs multiple sources including this table and History.Position_Active.
- While records reside in this staging table (pre-migration), they are queryable via History.Position.
- After migration to History.Position_Active, the record is no longer in this table but still in History.Position (via the _Active source).

---

## 3. Data Overview

Table is currently empty (0 rows) - all partial close records have been migrated to History.Position_Active. This is the expected steady state; the table serves as a staging buffer.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | The new position ID assigned to the CLOSED portion of the partial close. PK. |
| 2 | CID | int | YES | - | CODE-BACKED | Customer who owns this position. CLUSTERED INDEX key for customer-centric queries. |
| 3 | ForexResultID | bigint | NO | - | CODE-BACKED | Result record ID from the forex engine for this close operation. |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Account currency for P&L calculation. Implicit FK to Dictionary.Currency. |
| 5 | ProviderID | int | NO | - | CODE-BACKED | Liquidity provider ID for this position. Implicit FK to Trade.Provider. |
| 6 | GameServerID | int | NO | - | CODE-BACKED | Trading server ID that processed this position. |
| 7 | InstrumentID | int | NO | - | CODE-BACKED | Trading instrument. Implicit FK to Trade.Instrument. |
| 8 | HedgeID | int | YES | - | CODE-BACKED | Hedge record ID for this position's hedge. |
| 9 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server that managed this position's hedge. |
| 10 | OrderID | int | YES | - | CODE-BACKED | Order that triggered this position open. |
| 11 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier applied at open (e.g., 1, 2, 5, 10). |
| 12 | Amount | money | NO | - | CODE-BACKED | Investment amount (USD) for the closed portion of this partial close. |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position size in instrument units for the closed portion. |
| 14 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count for the closed portion. |
| 15 | InitForexRate | dbo.dtPrice | NO | - | CODE-BACKED | Instrument rate when the ORIGINAL position was opened. dbo.dtPrice = decimal(16,8). |
| 16 | InitDateTime | datetime | NO | - | CODE-BACKED | Server datetime when the original position was opened. |
| 17 | NetProfit | money | NO | - | CODE-BACKED | Net P&L in USD for the closed portion. |
| 18 | LimitRate | dbo.dtPrice | NO | - | CODE-BACKED | Take profit rate at time of close. 0 = no take profit. |
| 19 | StopRate | dbo.dtPrice | NO | - | CODE-BACKED | Stop loss rate at time of close. |
| 20 | SpreadedPipBid | dbo.dtPrice | YES | - | CODE-BACKED | Bid-side spreaded pip value. |
| 21 | SpreadedPipAsk | dbo.dtPrice | YES | - | CODE-BACKED | Ask-side spreaded pip value. |
| 22 | IsBuy | bit | NO | - | CODE-BACKED | 1=BUY position (long), 0=SELL position (short). |
| 23 | CloseOnEndOfWeek | bit | NO | - | CODE-BACKED | Whether this position was configured to close at end-of-week. |
| 24 | EndOfWeekFee | money | NO | 0 | CODE-BACKED | End-of-week fee accumulated. Default 0. |
| 25 | Commission | money | NO | - | CODE-BACKED | Opening commission charged. |
| 26 | CommissionOnClose | money | NO | - | CODE-BACKED | Closing commission charged. |
| 27 | SpreadedCommission | int | NO | - | CODE-BACKED | Commission encoded as spread pips (integer). |
| 28 | EndForexRate | dbo.dtPrice | NO | - | CODE-BACKED | Instrument execution rate at close. |
| 29 | RequestedEndForexRate | dbo.dtPrice | YES | - | CODE-BACKED | Client-requested close rate (for limit/stop orders). |
| 30 | EndDateTime | datetime | NO | GETDATE() | CODE-BACKED | Server datetime when this partial close was executed. |
| 31 | ActionType | int | NO | - | CODE-BACKED | Close action type (system, stop loss, take profit, manual, etc.). |
| 32 | AdditionalParam | sql_variant | YES | - | CODE-BACKED | Flexible parameter slot for action-type-specific data. sql_variant type allows any scalar value. |
| 33 | RequestOpenOccurred | datetime | YES | - | CODE-BACKED | Client-submitted open request timestamp. |
| 34 | RequestCloseOccurred | datetime | YES | - | CODE-BACKED | Client-submitted close request timestamp. |
| 35 | OpenOccurred | datetime | NO | - | CODE-BACKED | Server UTC timestamp when the position was opened. |
| 36 | CloseOccurred | datetime | NO | GETDATE() | CODE-BACKED | Server UTC timestamp when this partial close occurred. CLUSTERED INDEX key. |
| 37 | SpreadGroupID | int | YES | - | CODE-BACKED | Spread group configuration applied to this position. |
| 38 | LotCountGroupID | int | YES | - | CODE-BACKED | Lot count group for fee calculation. |
| 39 | TradeRange | int | YES | - | CODE-BACKED | Market range setting for this position's execution. |
| 40 | InitForexPriceRateID | bigint | NO | - | CODE-BACKED | Rate record ID for the opening price (for audit/price reconstruction). |
| 41 | OrderPriceRateID | bigint | NO | - | CODE-BACKED | Rate record ID for the order price. |
| 42 | EndForexPriceRateID | bigint | NO | - | CODE-BACKED | Rate record ID for the closing price. |
| 43 | OrderPriceRate | dbo.dtPrice | NO | - | CODE-BACKED | The price at which the order was placed. |
| 44 | MarketPriceRate | dbo.dtPrice | NO | - | CODE-BACKED | Market price at order time. |
| 45 | MarketPriceRateID | bigint | NO | - | CODE-BACKED | Rate record ID for the market price at order time. |
| 46 | EntryHedgeQuery | int | NO | -1 | CODE-BACKED | Hedge engine query ID for entry. -1 = not hedged. |
| 47 | EndHedgeQuery | int | YES | -1 | CODE-BACKED | Hedge engine query ID for exit. -1 = not hedged. |
| 48 | ParentPositionID | bigint | YES | 1 | CODE-BACKED | Copy trade parent position ID. Default 1 (no parent). |
| 49 | OrigParentPositionID | bigint | YES | 1 | CODE-BACKED | Original copy trade parent position. Default 1. |
| 50 | LastOpPriceRate | dbo.dtPrice | YES | 0 | CODE-BACKED | Instrument price at the last operation before close. |
| 51 | LastOpPriceRateID | bigint | YES | 0 | CODE-BACKED | Rate ID for last operation price. |
| 52 | LastOpConversionRate | dbo.dtPrice | YES | 0 | CODE-BACKED | Currency conversion rate at last operation. |
| 53 | LastOpConversionRateID | bigint | YES | 0 | CODE-BACKED | Rate ID for last operation conversion rate. |
| 54 | MirrorID | int | YES | 0 | CODE-BACKED | Copy portfolio (mirror) ID. 0 = no mirror. |
| 55 | EndMarketRate | dbo.dtPrice | YES | - | CODE-BACKED | Market rate at close time (may differ from execution rate due to slippage). |
| 56 | EndMarketPriceRateID | bigint | YES | - | CODE-BACKED | Rate ID for end market rate. |
| 57 | PositionRatio | decimal(7,6) | YES | - | CODE-BACKED | Ratio of this position within the copy portfolio. |
| 58 | DirectAggLotCount | decimal(16,6) | YES | - | CODE-BACKED | Direct aggregate lot count for hedge calculation. |
| 59 | StocksOrderID | int | YES | - | CODE-BACKED | Stocks brokerage order ID if this is a stock position. |
| 60 | InitialAmountCents | money | NO | 1 | CODE-BACKED | Original investment amount in cents at open. Note: stored as money but represents cents. Default 1 (placeholder). |
| 61 | IsOpenOpen | bit | YES | - | CODE-BACKED | Whether the position was "open-to-open" (opened against another open position). |
| 62 | OpenExposureID | int | YES | - | CODE-BACKED | Exposure record ID at open. |
| 63 | CloseExposureID | int | YES | - | CODE-BACKED | Exposure record ID at close. |
| 64 | OpenMarketPriceRateID | bigint | YES | - | CODE-BACKED | Market rate record ID at open. |
| 65 | CloseMarketPriceRateID | bigint | YES | - | CODE-BACKED | Market rate record ID at close. |
| 66 | AmountInUnitsDecimalUnAdjusted | decimal(16,6) | YES | - | CODE-BACKED | Units before platform adjustments. |
| 67 | LotCountDecimalUnAdjusted | decimal(16,6) | YES | - | CODE-BACKED | Lot count before platform adjustments. |
| 68 | InitForexRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Opening rate before platform adjustments. |
| 69 | LimitRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Take profit rate as originally set by customer. |
| 70 | StopRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Stop loss rate as originally set by customer. |
| 71 | EndForexRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Closing rate before platform adjustments. |
| 72 | OrderPriceRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Order price before adjustments. |
| 73 | MarketPriceRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Market price before adjustments. |
| 74 | LastOpPriceRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | Last operation price before adjustments. |
| 75 | EndMarketRateUnAdjusted | dbo.dtPrice | YES | - | CODE-BACKED | End market rate before adjustments. |
| 76 | InitExecutionID | bigint | YES | - | CODE-BACKED | Execution engine ID for the open leg. |
| 77 | EndExecutionID | bigint | YES | - | CODE-BACKED | Execution engine ID for the close leg. |
| 78 | RootHedgeServerID | int | YES | - | CODE-BACKED | Root hedge server ID in the hedge hierarchy. |
| 79 | TreeID | bigint | NO | 0 | CODE-BACKED | Copy relationship tree ID. |
| 80 | ExitOrderID | int | YES | - | CODE-BACKED | Exit order ID (for limit/stop orders that triggered close). |
| 81 | OrderType | int | YES | - | CODE-BACKED | Type of order used for this close. |
| 82 | IsTslEnabled | tinyint | NO | 0 | CODE-BACKED | Trailing stop loss enabled flag at close. |
| 83 | IsComputeForHedge | smallint | YES | - | CODE-BACKED | Whether hedge computation was performed. |
| 84 | FullCommission | money | YES | - | CODE-BACKED | Full commission including all components. |
| 85 | FullCommissionOnClose | money | YES | - | CODE-BACKED | Full commission on close leg. |
| 86 | IsSettled | bit | NO | 0 | CODE-BACKED | Whether this position was physically settled (stock delivery vs cash). |
| 87 | RedeemStatus | tinyint | YES | 0 | CODE-BACKED | Redemption status. 0=not in redeem workflow. |
| 88 | RedeemID | int | YES | 0 | CODE-BACKED | Redemption operation ID if redeemed. Default 0. |
| 89 | OriginalPositionID | bigint | YES | - | CODE-BACKED | **PARTIAL CLOSE KEY**: The original position that was partially closed to generate this record. Used to link back to the pre-close position. |
| 90 | InitialUnits | decimal(16,6) | YES | - | CODE-BACKED | **PARTIAL CLOSE KEY**: Unit count of the original position before this partial close. |
| 91 | SubCloseTypeID | decimal(16,6) | YES | - | CODE-BACKED | Sub-type of close operation. Note: stored as decimal despite being an ID-type field. |
| 92 | PartialCloseRatio | decimal(16,15) | YES | - | CODE-BACKED | **PARTIAL CLOSE KEY**: Fraction of the original position that was closed (e.g., 0.5 = 50%). decimal(16,15) for maximum precision in ratio calculations. |
| 93 | ReopenForPositionID | bigint | YES | - | CODE-BACKED | **PARTIAL CLOSE KEY**: The new position ID created for the remaining open portion after the partial close. |
| 94 | UnitsBaseValueCents | int | YES | - | CODE-BACKED | Base unit value in cents at close. |
| 95 | IsDiscounted | bit | YES | - | CODE-BACKED | Whether a fee discount was applied. |
| 96 | InitConversionRate | decimal(16,8) | YES | - | CODE-BACKED | Currency conversion rate at open. Separate from dtPrice columns for accounting precision. |
| 97 | ExitOrderType | int | YES | - | CODE-BACKED | Type of exit order (market, limit, stop). |
| 98 | OpenActionType | int | NO | -1 | CODE-BACKED | Action type at position open (entry method). -1 = legacy/unknown. |
| 99 | MarketRangeValidationType | tinyint | YES | 1 | CODE-BACKED | Market range validation method used at close. Default 1. |
| 100 | MarketRangePercentage | decimal(5,2) | YES | - | CODE-BACKED | Market range tolerance percentage for execution. |
| 101 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement method for this position. |
| 102 | InitConversionRateID | bigint | YES | - | CODE-BACKED | Rate record ID for the opening conversion rate. |
| 103 | OpenMarketSpread | dbo.dtPrice | YES | - | CODE-BACKED | Market spread at open time. |
| 104 | PnLVersion | tinyint | YES | - | CODE-BACKED | P&L calculation version (platform methodology versioning). |
| 105 | CloseMarkupOnOpen | money | YES | - | CODE-BACKED | Close markup calculated relative to open price. |
| 106 | EstimatedConversionMarkupRatio | decimal(20,4) | YES | - | CODE-BACKED | Estimated markup on currency conversion. |
| 107 | EstimatedMarkupRatio | decimal(20,4) | YES | - | CODE-BACKED | Estimated overall markup ratio. |
| 108 | OpenMarkup | money | YES | - | CODE-BACKED | Revenue markup charged at open. |
| 109 | OpenEtoroPrice | dbo.dtPrice | YES | - | CODE-BACKED | eToro platform price at open (includes markup). |
| 110 | CloseMarketSpread | dbo.dtPrice | YES | - | CODE-BACKED | Market spread at close time. |
| 111 | CloseEtoroPrice | dbo.dtPrice | YES | - | CODE-BACKED | eToro platform price at close (includes markup). |
| 112 | CloseMarkup | money | YES | - | CODE-BACKED | Revenue markup charged at close. |
| 113 | UnitMargin | decimal(16,8) | NO | - | CODE-BACKED | Margin per unit required for this position. |
| 114 | OpenTotalTaxes | money | YES | 0 | CODE-BACKED | Total taxes assessed at open. |
| 115 | OpenTotalFees | money | YES | 0 | CODE-BACKED | Total fees at open (stamp duty, regulatory etc.). |
| 116 | CloseTotalTaxes | money | YES | 0 | CODE-BACKED | Total taxes at close. |
| 117 | CloseTotalFees | money | YES | 0 | CODE-BACKED | Total fees at close. |
| 118 | PartitionCol | AS PositionID%50 PERSISTED | NO | - | CODE-BACKED | Computed partition column. PositionID % 50. Persisted for partition alignment. Part of the NONCLUSTERED PK. Values 0-49. |
| 119 | IsNoStopLoss | bit | YES | - | CODE-BACKED | Whether position had no stop loss (platform safety net). |
| 120 | IsNoTakeProfit | bit | YES | - | CODE-BACKED | Whether position had no take profit. |
| 121 | InitialLotCount | decimal(16,6) | YES | - | CODE-BACKED | Lot count of the original position at open. |
| 122 | OriginalOpenActionType | int | YES | - | CODE-BACKED | Original action type when the position was first opened (preserved through partials). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | History.Position_Active | Implicit | After migration, this record lives in Position_Active. |
| OriginalPositionID | Trade.Position / History.Position | Implicit | The original position that was partially closed. |
| ReopenForPositionID | Trade.Position | Implicit | The new open position created for the remaining fraction. |
| InstrumentID | Trade.Instrument | Implicit | The traded instrument. |
| CID | Customer.Customer | Implicit | The customer. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.MovePartialClosePositionToPosition_Active | PositionID | READER+DELETE | Migrates rows to History.Position_Active in partition batches. |
| History.Position (View) | PositionID | READER | Includes this table in the unified closed position view. |
| History.PositionSlim (View) | PositionID | READER | Slim view also references this table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

No enforced FK dependencies.

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.dtPrice | User Defined Type | Type used for all rate/price columns (decimal(16,8)) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.MovePartialClosePositionToPosition_Active | Stored Procedure | READER/WRITER - moves rows to History.Position_Active by partition |
| History.Position | View | READER - includes in unified closed position view |
| History.PositionSlim | View | READER - includes in slim position view |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryPartialPosition_BIGINT | NONCLUSTERED PK | PositionID ASC, PartitionCol ASC | - | Partitioned PS_PositionPartialCLose | Active |
| CLU_IX_...BIGINT_CloseOccurred | CLUSTERED | CID ASC, CloseOccurred ASC, OpenOccurred ASC | - | Partitioned on PartitionCol | Active |
| IX_PositionClosePartial_CID_OpenOccurred | NONCLUSTERED | CID ASC, OpenOccurred ASC | PositionID, ProviderID, InstrumentID | Partitioned on PartitionCol | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryPartialPosition_BIGINT | PRIMARY KEY | Unique per partial close record; includes partition col |
| DF_...EndOfWeekFee | DEFAULT | EndOfWeekFee = 0 |
| DF_...EndDateTime | DEFAULT | EndDateTime = GETDATE() |
| DF_...CloseOccurred | DEFAULT | CloseOccurred = GETDATE() |
| DF_...EntryHedgeQuery | DEFAULT | EntryHedgeQuery = -1 |
| DF_...EndHedgeQuery | DEFAULT | EndHedgeQuery = -1 |
| DF_...ParentPositionID | DEFAULT | ParentPositionID = 1 |
| DF_...OrigParentPositionID | DEFAULT | OrigParentPositionID = 1 |
| DF_...LastOpPriceRate | DEFAULT | LastOpPriceRate = 0 |
| DF_...LastOpConversionRate | DEFAULT | LastOpConversionRate = 0 |
| DF_...MirrorID | DEFAULT | MirrorID = 0 |
| DF_...InitialAmountCents | DEFAULT | InitialAmountCents = 1 |
| DF_...TreeID | DEFAULT | TreeID = 0 |
| DF_...IsTslEnabled | DEFAULT | IsTslEnabled = 0 |
| DF_...IsSettled | DEFAULT | IsSettled = 0 |
| DF_...RedeemStatus | DEFAULT | RedeemStatus = 0 |
| DF_...RedeemID | DEFAULT | RedeemID = 0 |
| DF_...OpenActionType | DEFAULT | OpenActionType = -1 |
| DF_PartialMarketRangeValidationType | DEFAULT | MarketRangeValidationType = 1 |
| DF_...OpenTotalTaxes/Fees/CloseTotalTaxes/Fees | DEFAULT | = 0 |

### 7.3 Storage

| Property | Value |
|----------|-------|
| Partition Scheme | PS_PositionPartialCLose (on PartitionCol = PositionID % 50, 50 partitions) |
| Fillfactor | 90% (PK), 80% (CLUSTERED) |

---

## 8. Sample Queries

### 8.1 Check staging table row count by partition

```sql
SELECT PartitionCol, COUNT(*) AS RowCount
FROM History.PositionClosePartial WITH (NOLOCK)
GROUP BY PartitionCol
ORDER BY PartitionCol;
```

### 8.2 Get partial close details for a specific original position

```sql
SELECT PositionID, OriginalPositionID, PartialCloseRatio, InitialUnits,
       AmountInUnitsDecimal, ReopenForPositionID, NetProfit,
       OpenOccurred, CloseOccurred
FROM History.PositionClosePartial WITH (NOLOCK)
WHERE OriginalPositionID = 12345678;
```

### 8.3 Unified closed position query (includes both staging and migrated)

```sql
-- Use History.Position view which includes this table + History.Position_Active
SELECT PositionID, CID, InstrumentID, Amount, NetProfit, OpenOccurred, CloseOccurred
FROM History.Position WITH (NOLOCK)
WHERE CID = 12345
  AND CloseOccurred >= DATEADD(MONTH, -3, GETUTCDATE())
ORDER BY CloseOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 122 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionClosePartial | Type: Table | Source: etoro/etoro/History/Tables/History.PositionClosePartial.sql*
