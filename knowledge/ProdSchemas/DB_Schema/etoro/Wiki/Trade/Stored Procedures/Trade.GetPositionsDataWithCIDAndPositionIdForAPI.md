# Trade.GetPositionsDataWithCIDAndPositionIdForAPI

> Returns the full open position record for a specific customer and position ID, including an in-flight close order indicator, used by the Trading API to load a single position's state.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @positionId BIGINT + @cid INT (composite filter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the complete state of a single open trading position, identified by both position ID and customer ID. It is the single-position variant of `Trade.GetPositionsDataWithCIDForAPI` (which returns all positions for a customer), adding one extra output: `OrderForCloseID`, which indicates whether a close order is currently being processed for this position. This is the core "read one position" operation used when a specific position's data is needed - for example, when the API fetches position details after an order update, or to validate state before allowing an action.

The procedure exists as the canonical data access for the `Position` domain object in the `eToro.Trading.Infrastructure.Repositories.PositionRepository` class. It is called by `PositionRepository.GetPositionByIdAsync(cid, positionId)`. Including the CID in the filter (in addition to PositionID) is a security guard: it ensures a customer can only read their own positions even if a PositionID is known.

Data flows: Reads from `Trade.Position` view (the canonical open-positions view, which joins Trade.PositionTbl with SL/TP settings via Trade.PositionTreeInfo). Uses `PositionPartitionCol = PositionID % 50` for partition elimination, making the query fast even on the large partitioned table. An OUTER APPLY to Trade.CloseExecutionPlan + Trade.OrderForClose + Dictionary.OrderForExecutionStatus detects if a non-terminal close order is already active. Consumers: TradingSettingsAPI and TAPIUser (per execute permissions).

---

## 2. Business Logic

### 2.1 In-Flight Close Order Detection

**What**: The OUTER APPLY finds any active (non-terminal) close order for the position, surfacing its OrderID to the caller.

**Columns/Parameters Involved**: `OrderForCloseID`, `Dictionary.OrderForExecutionStatus.IsTerminal`

**Rules**:
- OUTER APPLY: if no non-terminal close order exists, OrderForCloseID is NULL.
- If OrderForCloseID is non-NULL, the position is currently being closed - the caller should not submit another close request.
- Non-terminal statuses (IsTerminal=0): 1=RECEIVED, 2=PLACED, 5=PARTIALLY_FILLED, 6=PENDING_CANCEL, 11=WAITING_FOR_MARKET.
- Only one close order is expected per position at a time; the OUTER APPLY returns the first matching OrderID.

### 2.2 Partition-Aligned Position Lookup

**What**: The WHERE clause includes `p.PositionPartitionCol = @positionId % 50` to direct SQL Server to the correct partition.

**Columns/Parameters Involved**: `@positionId`, `PositionPartitionCol`

**Rules**:
- Trade.Position view is built on Trade.PositionTbl, which is partitioned by PositionID % 50.
- Including the partition key in the WHERE clause enables partition elimination, avoiding full table scans.
- CID is also in the WHERE for security: even if @positionId is known, the position is only returned if it belongs to @cid.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @positionId | BIGINT | NO | - | CODE-BACKED | The position to fetch. Combined with @cid to prevent cross-customer data access. Uses PositionPartitionCol = @positionId % 50 for partition elimination. |
| 2 | @cid | INT | NO | - | CODE-BACKED | The customer ID. Security guard ensuring only the position owner can retrieve it. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | PositionID | BIGINT | NO | - | VERIFIED | Unique position identifier. Maps to `Position.PositionID` in app code. |
| 4 | CID | INT | NO | - | VERIFIED | Customer ID of the position owner. ISNULL(..., 0) - defaults to 0 if null (defensive). Maps to `Position.CID`. |
| 5 | Amount | DECIMAL | NO | - | VERIFIED | Current invested amount in USD. Maps to `Position.Amount`. |
| 6 | InitDateTime | DATETIME | NO | - | VERIFIED | Timestamp when the position was opened. App property: `Position.OpenDateTime`. |
| 7 | InitForexRate | DECIMAL | NO | - | VERIFIED | Instrument price at position open (the open rate). App property: `Position.OpenRate`. Also known as "open rate" in application code. |
| 8 | InstrumentID | INT | NO | - | VERIFIED | The traded instrument. Maps to `Position.InstrumentID`. FK to Trade.Instrument. |
| 9 | IsBuy | BIT | NO | - | VERIFIED | Direction: 1=Buy/Long, 0=Sell/Short. Maps to `Position.IsBuy`. |
| 10 | Leverage | INT | NO | - | VERIFIED | Leverage multiplier applied at open. 1=no leverage (real stocks). Maps to `Position.Leverage`. |
| 11 | LimitRate | DECIMAL | NO | - | VERIFIED | Take-profit rate: if the instrument reaches this price, the position closes with profit. App property: `Position.TakeProfitRate`. LimitRate IS the take-profit rate. |
| 12 | StopRate | DECIMAL | NO | - | VERIFIED | Stop-loss rate: if the instrument drops to this price, the position closes to limit loss. App initializes as `new Position(stopLossRate, stopLossVersion)`. |
| 13 | MirrorID | INT | NO | - | VERIFIED | CopyTrader mirror ID. 0 = manual (non-copy) trade. ISNULL(..., 0). FK to Trade.Mirror. Maps to `Position.MirrorID`. |
| 14 | OrderID | BIGINT | NO | - | VERIFIED | The order that opened this position. 0 if position was opened without an order. ISNULL(..., 0). FK to Trade.Orders. Maps to `Position.OrderID`. |
| 15 | OrderType | INT | NO | - | CODE-BACKED | Type of the originating order. 0=default if null. ISNULL(..., 0). Maps to `Position.OrderType`. |
| 16 | ParentPositionID | BIGINT | NO | - | VERIFIED | For copy-trade positions: the leader's position this was copied from. 0=root/non-copy. ISNULL(..., 0). Maps to `Position.ParentPositionID`. |
| 17 | AmountInUnitsDecimal | DECIMAL | NO | - | VERIFIED | Current position size in instrument units (e.g., shares). ISNULL(..., 0). App property: `Position.Units`. |
| 18 | EndOfWeekFee | DECIMAL | NO | - | VERIFIED | Overnight/end-of-week financing fee accumulated on this position. App property: `Position.TotalFees` - the EOW fee is treated as the total fee amount at this stage. |
| 19 | InitialAmountInDollars | DECIMAL | NO | - | VERIFIED | Original invested amount at position open, in USD. Computed as `InitialAmountCents / 100` (cents-to-dollars conversion). App property: `Position.InitialAmountInDollars`. |
| 20 | IsTslEnabled | BIT | NO | - | VERIFIED | Trailing stop-loss enabled flag. 1=TSL is active (stop-loss moves with the price). 0=fixed stop-loss. Maps to `Position.IsTslEnabled`. |
| 21 | StopLossVersion | INT | NO | - | VERIFIED | Stop-loss version indicator (from SLManualVer). Tracks which generation of the stop-loss UI the level was set with; used for backward compatibility in SL calculations. App property: `Position.StopLossVersion`. |
| 22 | TreeID | BIGINT | NO | - | VERIFIED | CopyTrader tree root identifier. Equal to PositionID for root positions. Children share the root's TreeID. Links to Trade.PositionTreeInfo for SL/TP/TSL settings. Maps to `Position.TreeID`. |
| 23 | IsSettled | BIT | NO | - | VERIFIED | Legacy settlement flag. 1=real stock position (customer owns actual shares), 0=CFD. Predates SettlementTypeID. Maps to `Position.IsSettled`. |
| 24 | SettlementTypeID | INT | NO | - | VERIFIED | Modern settlement type: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. (Dictionary.SettlementTypes). Maps to `Position.SettlementTypeID`. |
| 25 | RedeemStatus | INT | NO | - | VERIFIED | Current redemption status of the position. ISNULL(..., 0). 0=no active redemption. App property: `Position.RedeemStatusID`. |
| 26 | InitialUnits | DECIMAL | NO | - | VERIFIED | Original position size in units at open. Computed as `ISNULL(InitialUnits, ISNULL(AmountInUnitsDecimal, 0))` - falls back to current units for older positions that predate the InitialUnits column. App uses reader.CreateIfContainsColumnWithValueDecimal("InitialUnits", position.Units). |
| 27 | UnitsBaseValueDollars | DECIMAL | NO | - | VERIFIED | Base value of units in USD. Computed as `CONVERT(DECIMAL(12,2), UnitsBaseValueCents) / 100` (cents-to-dollars). App uses CreateIfContainsColumnWithValueDecimal("UnitsBaseValueDollars", InitialAmountInDollars) as fallback. |
| 28 | IsDiscounted | BIT | NO | - | CODE-BACKED | Whether a fee discount is applied to this position. Maps to `Position.IsDiscounted`. |
| 29 | OpenActionType | INT | NO | - | VERIFIED | How the position was originally opened. Maps to `Position.OpenPositionActionType`. Common values: 0=Customer manual, 1=CopyTrader hierarchical. |
| 30 | OrigParentPositionID | BIGINT | NO | - | VERIFIED | Original parent position ID before any re-parenting operations (e.g., mirror rebalancing). ISNULL(..., 0). Maps to `Position.OrigParentPositionID`. |
| 31 | InitConversionRate | DECIMAL | NO | - | VERIFIED | Currency conversion rate (instrument currency to USD) at the time the position was opened. Used in PnL calculations. Maps to `Position.InitConversionRate`. |
| 32 | PnLVersion | INT | NO | - | VERIFIED | PnL calculation formula version. 0=legacy CFD formula, 1=real stock formula. Derived from SettlementType. Maps to `Position.PnlVersion`. |
| 33 | OpenTotalTaxes | DECIMAL | NO | - | VERIFIED | Total external taxes applied at position open. Maps to `Position.TotalExternalTaxes`. |
| 34 | OpenTotalFees | DECIMAL | NO | - | VERIFIED | Total external fees (non-EOW) applied at position open. Maps to `Position.TotalExternalFees`. |
| 35 | OrderForCloseID | BIGINT | YES | - | CODE-BACKED | If a non-terminal close order is currently in the execution pipeline, its OrderID is returned here. NULL if no active close order exists. Unique to this procedure vs GetPositionsDataWithCIDForAPI. Derived via OUTER APPLY to Trade.CloseExecutionPlan WHERE IsTerminal=0. |
| 36 | IsNoStopLoss | BIT | YES | - | VERIFIED | If TRUE, the position explicitly has no stop-loss (user opted out). NULL means the flag is not set. Maps to `Position.IsNoStopLoss`. |
| 37 | IsNoTakeProfit | BIT | YES | - | VERIFIED | If TRUE, the position explicitly has no take-profit (user opted out). NULL means the flag is not set. Maps to `Position.IsNoTakeProfit`. |
| 38 | LotCountDecimal | DECIMAL | NO | - | VERIFIED | Position size expressed in lots (standardized contract units). Computed from units / instrument lot size. App property: `Position.LotCount`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @positionId, @cid | Trade.Position | Primary source | Reads open position data from this view (which wraps Trade.PositionTbl + PositionTreeInfo) |
| OrderForCloseID | Trade.CloseExecutionPlan | OUTER APPLY | Checks for active close orders |
| OrderForCloseID | Trade.OrderForClose | JOIN | Gets close order status |
| IsTerminal | Dictionary.OrderForExecutionStatus | Lookup | Filters to non-terminal statuses only |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PositionRepository.GetPositionByIdAsync | @positionId, @cid | Application call | Called from trading-shared PositionRepository to load a single Position domain object |
| TradingSettingsAPI (DB user) | GRANT EXECUTE | Permission | Trading settings service has execute access |
| TAPIUser (DB user) | GRANT EXECUTE | Permission | TAPI user has execute access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionsDataWithCIDAndPositionIdForAPI (procedure)
├── Trade.Position (view)
│     ├── Trade.PositionTbl (table)
│     └── Trade.PositionTreeInfo (table)
├── Trade.CloseExecutionPlan (table)
├── Trade.OrderForClose (table)
└── Dictionary.OrderForExecutionStatus (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Primary SELECT source for all position fields; filtered by PositionID, CID, and partition key |
| Trade.CloseExecutionPlan | Table | OUTER APPLY to find in-flight close orders for the position |
| Trade.OrderForClose | Table | JOIN to get status of the close order |
| Dictionary.OrderForExecutionStatus | Table | Lookup to filter non-terminal statuses (IsTerminal=0) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| eToro.Trading.Infrastructure.Repositories.PositionRepository | Application class | GetPositionByIdAsync() calls this procedure to load a single Position domain object (trading-shared repo) |
| TradingSettingsAPI | Application service | Reads individual position state for settings/configuration operations |
| TAPIUser | Application | TAPI trading operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Partition elimination | Performance | WHERE PositionPartitionCol = @positionId % 50 routes to correct partition |
| Security | Business rule | Both @positionId AND @cid must match - prevents cross-customer reads |

---

## 8. Sample Queries

### 8.1 Get a single position for a customer

```sql
EXEC Trade.GetPositionsDataWithCIDAndPositionIdForAPI
    @positionId = 2152972412,
    @cid = 14952810;
```

### 8.2 Check if the returned position has an active close order

```sql
-- OrderForCloseID non-NULL means a close is in progress
EXEC Trade.GetPositionsDataWithCIDAndPositionIdForAPI
    @positionId = 2152972412,
    @cid = 14952810;
-- IF result.OrderForCloseID IS NOT NULL -> do not submit another close
```

### 8.3 Inline query to verify position ownership and partition alignment

```sql
SELECT p.PositionID, p.CID, p.InstrumentID, p.StatusID, p.PositionPartitionCol
FROM Trade.Position p WITH (NOLOCK)
WHERE p.PositionID = 2152972412
  AND p.PositionPartitionCol = 2152972412 % 50
  AND p.CID = 14952810;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 26 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 1 files (PositionRepository.cs) | Corrections: 0 applied*
*Object: Trade.GetPositionsDataWithCIDAndPositionIdForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionsDataWithCIDAndPositionIdForAPI.sql*
