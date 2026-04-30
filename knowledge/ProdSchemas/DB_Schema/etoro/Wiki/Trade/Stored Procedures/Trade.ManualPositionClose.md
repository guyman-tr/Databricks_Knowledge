# Trade.ManualPositionClose

> Closes a single position at a specified rate - calculates PnL using Trade.FnCalculatePnLWrapper, computes close commission, either routes to the new SBR event pipeline or executes the legacy Trade.PositionClose, cancels pending exit orders, and sends a Service Broker close notification.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (position to close) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ManualPositionClose is the procedure used to close a single position at a specified execution rate, typically triggered by manual/admin operations, stop-loss/take-profit triggers, or hierarchy-level closes. It calculates the position's profit/loss using the PnL wrapper function, computes the close commission based on spreads and conversion rates, and then either routes to the new SBR (Service Broker) event pipeline or executes the legacy Trade.PositionClose directly.

The procedure handles the full close lifecycle: reading position data from Trade.Position view, calculating PnL and commission, closing the position, canceling any pending exit orders (StatusID=11 -> 7=Canceled), and sending a close notification via Service Broker for downstream processing (notifications, aggregations, analytics).

There are two code paths: when Maintenance.Feature 121 is enabled, the close is routed through Trade.InsertEventsIntoSbrQueueTable as an event (EventTypeID=2 = position close). When disabled, the legacy Trade.PositionClose is called directly. The Feature flag controls the migration from synchronous to asynchronous close processing.

---

## 2. Business Logic

### 2.1 PnL Calculation

**What**: Computes net profit using the full PnL calculation stack.

**Columns/Parameters Involved**: `@EndForexRate`, `@InstrumentID`, `@IsBuy`, `@AmountInUnitsDecimal`, `@IsSettled`, `@PnLVersion`

**Rules**:
- Uses Trade.FnCalculatePnLWrapper with init rates and end rates
- Supports both legacy PnL (PnLVersion=0) and new PnL (PnLVersion=1)
- When BuyCurrencyID = AccountCurrencyID: uses 1/EndForexRate as conversion rate
- Returns NetProfit in cents and conversion rate/ID

### 2.2 Close Commission Calculation (Dual Path)

**What**: Computes FullCommissionOnClose and CommissionOnClose differently based on whether OpenMarketSpread is available.

**Rules**:
- **Legacy path** (OpenMarketSpread IS NULL): Uses spread-based formula with ConversionRateAsk/Bid from Trade.FnGetCurrentConversionRate
- **New path** (OpenMarketSpread IS NOT NULL): Uses markup-based formula combining OpenMarkup + CloseMarkup + market spread
- Both paths output values in cents (*100)
- For discounted positions (IsDiscounted=1): CommissionOnClose = 0

### 2.3 Feature Flag Routing (Feature 121)

**What**: Routes close processing to either SBR event pipeline or legacy direct close.

**Rules**:
- Feature 121 enabled: InsertEventsIntoSbrQueueTable with EventTypeID=2 (async close), then RETURN
- Feature 121 disabled: Direct call to Trade.PositionClose (synchronous legacy path)
- The SBR path returns immediately after queuing - actual position closure happens asynchronously

### 2.4 Exit Order Cancellation

**What**: Cancels pending exit orders for the closed position.

**Rules**:
- Finds orders in Trade.OrderForClose with StatusID=11 (pending) for this PositionID
- Updates to StatusID=7 (Canceled) with OrderCloseActionType=11 (cancellation due to direct close)
- Queues an SBR event (EventTypeID=1) for the order status change

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | VERIFIED | Position to close. Must be an open position. Used with PartitionCol for partition elimination on Trade.Position view. |
| 2 | @EndForexRate | dtPrice | NO | - | CODE-BACKED | Closing execution rate for the instrument. Used in PnL calculation and commission computation. |
| 3 | @EndPriceRateID | BIGINT | NO | - | CODE-BACKED | Price rate snapshot ID at close time. Stored as EndForexPriceRateID. |
| 4 | @ActionType | INT | NO | - | VERIFIED | Close action type: 1=StopLoss, 5=TakeProfit, others per Dictionary.ClosePositionActionType. Stored in PositionTbl.ActionType. |
| 5 | @LastOpConversionRate | dtPrice | NO | - | CODE-BACKED | Currency conversion rate at close. Used in PnL calculation when @UseLastOpConversionRate=1. |
| 6 | @LastOpConversionRateID | BIGINT | NO | - | CODE-BACKED | Conversion rate snapshot ID at close. |
| 7 | @StopRate | dtPrice | NO | - | CODE-BACKED | Current stop-loss rate. Included in close notification for downstream systems. |
| 8 | @LimitRate | dtPrice | NO | - | CODE-BACKED | Current take-profit rate. Included in close notification. |
| 9 | @CloseMarketPriceRateID | BIGINT | NO | - | CODE-BACKED | Market price rate ID at close time. |
| 10 | @Description | VARCHAR(50) | YES | 'Manual hierarchy closed' | CODE-BACKED | Description of the close reason. Default indicates manual/hierarchy close. |
| 11 | @UseLastOpConversionRate | INT | YES | 0 | CODE-BACKED | When 1, uses the provided @LastOpConversionRate instead of recalculating. Auto-set to 1 when BuyCurrencyID = AccountCurrencyID. |
| 12 | @BidSpread | dtPrice | YES | 0 | CODE-BACKED | Bid-side spread at close time. Used in commission calculation. |
| 13 | @AskSpread | dtPrice | YES | 0 | CODE-BACKED | Ask-side spread at close time. Used in commission calculation. |
| 14 | @SkewValue | DECIMAL(19,8) | YES | 0 | CODE-BACKED | Price skew value for the instrument at close time. Included in close notification. |
| 15 | @Markup | DECIMAL(16,6) | YES | 0 | CODE-BACKED | Markup applied at close time. Included in close notification. |
| 16 | @OccurredDBTime | DATETIME OUTPUT | YES | NULL | CODE-BACKED | Actual DB execution timestamp of the close. Returned by Trade.PositionClose. |
| 17 | @SettlementTypeID | INT OUTPUT | YES | 0 | CODE-BACKED | Settlement type of the closed position. Returned by Trade.PositionClose. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Position | SELECT | Reads position data (view with partition elimination) |
| JOIN | Customer.CustomerStatic | SELECT | Gets GCID and CountryID for notifications |
| JOIN | Trade.Mirror | SELECT | Gets mirror activity status |
| APPLY | Trade.FnCalculatePnLWrapper | FUNCTION | Calculates net profit in cents |
| APPLY | Trade.FnGetCurrentConversionRate | FUNCTION | Gets conversion rates for commission calc |
| FROM | Trade.ProviderToInstrument | SELECT | Gets instrument precision |
| FROM | Trade.Instrument | SELECT | Gets BuyCurrencyID |
| FROM | Trade.InstrumentSpread | SELECT | Gets spread data for legacy commission |
| FROM | Trade.CurrencyPrice | SELECT | Gets discounted spread for market spread calc |
| EXEC | Trade.InsertEventsIntoSbrQueueTable | EXEC | Queues close events for async processing |
| EXEC | Trade.PositionClose | EXEC | Legacy synchronous position close |
| EXEC | Trade.OrderForCloseUpdate | EXEC | Cancels pending exit orders |
| FROM | Trade.OrderForClose | SELECT | Finds pending exit orders |
| JOIN | Trade.CloseExecutionPlan | SELECT | Links orders to positions |
| FROM | History.PositionSlim | SELECT | Reads closed position for notification |
| FROM | Maintenance.Feature | SELECT | Checks Feature 121 (SBR routing) |
| Service Broker | svcPosition | SEND | Sends close notification via Service Broker |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CloseManualPositionByInitRate | (batch #18) | EXEC | Closes at the init rate |
| Trade.ClosePositionsByInstrumentID | (batch #19) | EXEC | Batch closes by instrument |
| Trade.ManualPositionClose_Crisis | (batch #21) | EXEC | Crisis-mode manual close |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ManualPositionClose (procedure)
+-- Trade.Position (view)
+-- Trade.FnCalculatePnLWrapper (function)
+-- Trade.FnGetCurrentConversionRate (function)
+-- Trade.ProviderToInstrument (table)
+-- Trade.Instrument (table)
+-- Trade.InstrumentSpread (table)
+-- Trade.CurrencyPrice (table)
+-- Trade.InsertEventsIntoSbrQueueTable (procedure)
+-- Trade.PositionClose (procedure)
+-- Trade.OrderForCloseUpdate (procedure)
+-- Trade.OrderForClose (table)
+-- Trade.CloseExecutionPlan (table)
+-- History.PositionSlim (view/table)
+-- Customer.CustomerStatic (table)
+-- Trade.Mirror (table)
+-- Maintenance.Feature (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT - position data with partition elimination |
| Trade.FnCalculatePnLWrapper | Function | CROSS APPLY - PnL calculation |
| Trade.FnGetCurrentConversionRate | Function | CROSS APPLY - conversion rates |
| Trade.InsertEventsIntoSbrQueueTable | Procedure | EXEC - async event queuing |
| Trade.PositionClose | Procedure | EXEC - legacy close path |
| Trade.OrderForCloseUpdate | Procedure | EXEC - cancels pending exit orders |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CloseManualPositionByInitRate | Procedure | Calls this with EndForexRate = InitForexRate |
| Trade.ClosePositionsByInstrumentID | Procedure | Batch-calls this for each position on an instrument |
| Trade.ManualPositionClose_Crisis | Procedure | Calls this in crisis-mode close scenarios |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Partition elimination | Performance | @PositionID%50=PartitionCol for Trade.Position |
| Feature 121 flag | Routing | Controls SBR vs legacy close path |
| Error codes 60082/60083 | Special handling | These errors are NOT re-raised (silently caught) |

---

## 8. Sample Queries

### 8.1 View position details before manual close

```sql
SELECT  PositionID, CID, InstrumentID, IsBuy, Amount, AmountInUnitsDecimal,
        InitForexRate, LimitRate, StopRate, StatusID
FROM    Trade.Position WITH (NOLOCK)
WHERE   PositionID = 12345
        AND PositionPartitionCol = 12345 % 50;
```

### 8.2 Check pending exit orders for a position

```sql
SELECT  o.OrderID, o.CID, o.StatusID, ep.PositionID
FROM    Trade.OrderForClose o WITH (NOLOCK)
JOIN    Trade.CloseExecutionPlan ep WITH (NOLOCK) ON ep.OrderID = o.OrderID
WHERE   ep.PositionID = 12345
        AND o.StatusID = 11;
```

### 8.3 Execute a manual position close

```sql
DECLARE @DBTime DATETIME, @SettType INT;
EXEC Trade.ManualPositionClose
    @PositionID = 12345,
    @EndForexRate = 155.50,
    @EndPriceRateID = 99999,
    @ActionType = 1,
    @LastOpConversionRate = 1.0,
    @LastOpConversionRateID = 0,
    @StopRate = 150.00,
    @LimitRate = 160.00,
    @CloseMarketPriceRateID = 99999,
    @OccurredDBTime = @DBTime OUTPUT,
    @SettlementTypeID = @SettType OUTPUT;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.0/10 (Elements: 9.4/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ManualPositionClose | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ManualPositionClose.sql*
