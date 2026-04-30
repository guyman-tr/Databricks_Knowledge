# Trade.GetPositionDataFromReal

> Returns comprehensive open position data from dbo.RealOpenPositions including instrument, provider, fund, and exit order context - the full position snapshot for copy-trade and close processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID - the live open position to retrieve |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetPositionDataFromReal` returns a comprehensive single-row position snapshot from `dbo.RealOpenPositions` for a given PositionID. It provides all fields needed for position close processing, copy-trade child opens, and copy-trade hierarchy navigation: instrument details, provider details, forex rates, copy hierarchy fields (MirrorID, ParentPositionID, TreeID), fund detection (IsFund), and exit order status (ExitOrderID).

**WHY:** Position close and copy processing services need a complete position context in a single call. Rather than joining PositionTbl + Instrument + ProviderToInstrument + Fund + OrdersExit in application code, this SP provides the consolidated row. The `IsOpened=1` hardcoded flag signals to callers that this is a live open position.

**HOW:** Joins dbo.RealOpenPositions to Trade.Instrument (forex buy/sell currencies), Trade.ProviderToInstrument (precision/units), LEFT JOINs to dbo.RealFund (fund account detection), dbo.RealOpenPositions PTI (tree root settlement), and Trade.OrdersExit (exit order detection). No partition filter on the main table - relies on the distributed view's own routing. EndForexRate, EndDateTime, ActionType, NetProfit all return NULL (open position, not yet closed).

**Note:** Unlike GetParentPositionWithMirrorData which also returns Mirror data (RS2), this SP returns ONLY the position data - no mirror result set.

---

## 2. Business Logic

### 2.1 Full Position Snapshot

**What:** Returns one row per PositionID with all fields needed for close/copy processing.

**Columns/Parameters Involved:** All 45 output columns

**Rules:**
- `WHERE TPOS.PositionID = @PositionID` - no PartitionCol filter (relies on RealOpenPositions view routing)
- `IsOpened = 1` hardcoded (confirms live open status)
- `EndForexRate = NULL`, `EndDateTime = NULL`, `ActionType = NULL`, `NetProfit = NULL` - not yet closed
- `EndExecutionID = 0` hardcoded
- `IsBuy` and `CloseOnEndOfWeek` returned as 'true'/'false' string (CASE expression)
- Returns 0 or 1 rows

### 2.2 Tree Root Settlement Lookup

**What:** PTI join resolves the root position's settlement type for the copy tree.

**Columns/Parameters Involved:** `TreeID`, `PTI.IsSettled`, `IsRootSettled`

**Rules:**
- `INNER JOIN dbo.RealOpenPositions PTI ON TPOS.TreeID = PTI.PositionID` - no NOLOCK on PTI (note: main join is NOLOCK)
- `PTI.IsSettled AS IsRootSettled` - root's settlement determines CFD vs real-stock processing path

### 2.3 Fund Account Detection

**What:** IsFund flag identifies positions belonging to eToro fund accounts.

**Columns/Parameters Involved:** `IsFund`, `TF.FundID`

**Rules:**
- `LEFT JOIN dbo.RealFund TF ON TPOS.CID = TF.FundAccountID`
- `IsFund = CASE WHEN TF.FundID IS NOT NULL THEN 1 ELSE 0 END`
- IsFund=1 means this is a position in a fund account (affects copy hierarchy and fee rules)

### 2.4 Exit Order Detection

**What:** ExitOrderID indicates if the position's tree root already has an exit order.

**Columns/Parameters Involved:** `ExitOrderID`, `OE.OrderID`

**Rules:**
- `LEFT JOIN Trade.OrdersExit OE ON OE.PositionID = PTI.PositionID` - joins on the TREE ROOT (PTI), not on TPOS
- `ISNULL(OE.OrderID, 0) AS ExitOrderID` - 0 = no exit order on root, >0 = exit order ID
- Useful for detecting whether the position's copy tree is being closed

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Live position ID. Changed to BIGINT 2021-11-17. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 3 | PositionID | BIGINT | NO | - | CODE-BACKED | Echo of @PositionID. |
| 4 | ForexResultID | INT | YES | - | CODE-BACKED | Forex result reference ID. |
| 5 | IsOpened | INT | NO | 1 | CODE-BACKED | Always 1 (hardcoded) - confirms live open position. |
| 6 | Currency | INT | YES | - | CODE-BACKED | Account denomination currency ID (CurrencyID). |
| 7 | ProviderID | INT | YES | - | CODE-BACKED | Market data provider ID. |
| 8 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument being traded. |
| 9 | PositionHedgeServerID | INT | YES | - | CODE-BACKED | Hedge server for this position (HedgeServerID). |
| 10 | Leverage | INT | YES | - | CODE-BACKED | Position leverage multiplier. |
| 11 | ForexBuy | INT | YES | - | CODE-BACKED | Buy-side currency ID from Trade.Instrument.BuyCurrencyID. |
| 12 | ForexSell | INT | YES | - | CODE-BACKED | Sell-side currency ID from Trade.Instrument.SellCurrencyID. |
| 13 | InitForexRate | DECIMAL | YES | - | CODE-BACKED | Initial forex rate at position open. |
| 14 | EndForexRate | NULL | YES | NULL | CODE-BACKED | Always NULL - position is open. |
| 15 | InitDateTime | DATETIME | YES | - | CODE-BACKED | Position open timestamp. |
| 16 | EndDateTime | NULL | YES | NULL | CODE-BACKED | Always NULL - position is open. |
| 17 | ActionType | NULL | YES | NULL | CODE-BACKED | Always NULL - open position has no close action type yet. |
| 18 | NetProfit | NULL | YES | NULL | CODE-BACKED | Always NULL - position is open (no realized PnL). |
| 19 | LimitRate | DECIMAL | YES | - | CODE-BACKED | Take profit rate. |
| 20 | StopRate | DECIMAL | YES | - | CODE-BACKED | Stop loss rate. |
| 21 | Amount | MONEY | YES | - | CODE-BACKED | Current position amount in account currency. |
| 22 | AmountInUnitsDecimal | DECIMAL | YES | - | CODE-BACKED | Position size in units (instrument-denominated). |
| 23 | Commission | MONEY | YES | - | CODE-BACKED | Commission charged at open. |
| 24 | SpreadedCommission | MONEY | YES | - | CODE-BACKED | Spread-adjusted commission. |
| 25 | IsBuy | VARCHAR(5) | NO | - | CODE-BACKED | 'true' (Long) or 'false' (Short). CASE expression on BIT. |
| 26 | CloseOnEndOfWeek | VARCHAR(5) | NO | - | CODE-BACKED | 'true' or 'false' - whether position auto-closes on weekend. |
| 27 | EndOfWeekFee | MONEY | YES | - | CODE-BACKED | End-of-week fee amount. |
| 28 | LotCountDecimal | DECIMAL | YES | - | CODE-BACKED | Position size in lots/contracts. |
| 29 | AdditionalParam | NVARCHAR | YES | - | CODE-BACKED | Additional parameters JSON or text. |
| 30 | OpenOccurred | DATETIME | YES | - | CODE-BACKED | When position was opened (Occurred aliased). |
| 31 | CloseOccurred | NULL | YES | NULL | CODE-BACKED | Always NULL - position is open. |
| 32 | OrderID | BIGINT | YES | - | CODE-BACKED | The order ID that opened this position. |
| 33 | TradeRange | DECIMAL | YES | - | CODE-BACKED | Trade range setting at open. |
| 34 | InitForexPriceRateID | BIGINT | YES | - | CODE-BACKED | Price rate record ID at open. |
| 35 | ParentPositionID | BIGINT | YES | - | CODE-BACKED | Leader's PositionID for copy positions. 0 or NULL for manual. |
| 36 | OrigParentPositionID | BIGINT | YES | - | CODE-BACKED | Original parent before any position reassignment. |
| 37 | LastOpPriceRate | DECIMAL | YES | - | CODE-BACKED | Price rate at last operation. |
| 38 | LastOpPriceRateID | BIGINT | YES | - | CODE-BACKED | Price rate record ID at last operation. |
| 39 | LastOpConversionRate | DECIMAL | YES | - | CODE-BACKED | Conversion rate at last operation. Used in PnL calculation. |
| 40 | LastOpConversionRateID | BIGINT | YES | - | CODE-BACKED | Conversion rate record ID at last operation. |
| 41 | UnitMargin | DECIMAL | YES | - | CODE-BACKED | Margin per unit. |
| 42 | Units | DECIMAL | YES | - | CODE-BACKED | Unit size from Trade.ProviderToInstrument.Unit. |
| 43 | InstrumentPrecision | INT | YES | - | CODE-BACKED | Decimal precision from Trade.ProviderToInstrument.Precision. |
| 44 | MirrorID | INT | YES | - | CODE-BACKED | Copy relationship ID. NULL for manual positions. |
| 45 | PositionRatio | DECIMAL | YES | - | CODE-BACKED | Position size ratio relative to copy allocation. |
| 46 | DirectAggLotCount | DECIMAL | YES | - | CODE-BACKED | Direct aggregated lot count for hedge. |
| 47 | SpreadGroupID | INT | YES | - | CODE-BACKED | Customer's spread group at position open. |
| 48 | InitialAmountCents | BIGINT | YES | - | CODE-BACKED | Initial amount in cents (integer representation). |
| 49 | HedgeServerID | INT | YES | - | CODE-BACKED | Hedge server (duplicate of PositionHedgeServerID). |
| 50 | InitExecutionID | BIGINT | YES | - | CODE-BACKED | Execution ID at position open. |
| 51 | EndExecutionID | INT | NO | 0 | CODE-BACKED | Always 0 - no close execution yet. |
| 52 | RootHedgeServerID | INT | YES | - | CODE-BACKED | Hedge server of the tree root position. |
| 53 | IsOpenOpen | BIT | YES | - | CODE-BACKED | Whether the position was opened via open market order. |
| 54 | TreeID | BIGINT | YES | - | CODE-BACKED | Root position ID of the copy tree. |
| 55 | IsComputeForHedge | BIT | YES | - | CODE-BACKED | Whether position is included in hedge computation. |
| 56 | ExitOrderID | BIGINT | NO | 0 | CODE-BACKED | Exit order ID on the tree root position. 0 = no exit order (ISNULL to 0). |
| 57 | SLManualVer | INT | YES | - | CODE-BACKED | Stop loss manual version counter for optimistic concurrency. |
| 58 | IsTslEnabled | BIT | YES | - | CODE-BACKED | Trailing stop loss enabled. |
| 59 | IsSettled | BIT | YES | - | CODE-BACKED | Whether this position is real stock (1) or CFD (0). |
| 60 | SettlementTypeID | INT | YES | - | CODE-BACKED | Settlement type FK. |
| 61 | IsRootSettled | BIT | YES | - | CODE-BACKED | Whether tree root position is settled. From PTI INNER JOIN. |
| 62 | RedeemStatus | INT | NO | 0 | CODE-BACKED | Redeem process status (ISNULL to 0). |
| 63 | InitConversionRate | DECIMAL | YES | - | CODE-BACKED | Conversion rate at position open. Used in PnL calculations. |
| 64 | IsFund | BIT | NO | - | CODE-BACKED | 1=position belongs to a fund account; 0=regular. From dbo.RealFund LEFT JOIN. |
| 65 | UnitsBaseValueCents | BIGINT | YES | - | CODE-BACKED | Base value of units in cents. Used in settlement calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | dbo.RealOpenPositions | Lookup | Live open position data |
| InstrumentID | Trade.Instrument | Lookup | BuyCurrencyID, SellCurrencyID |
| ProviderID + InstrumentID | Trade.ProviderToInstrument | Lookup | Precision, Unit |
| CID | dbo.RealFund | LEFT JOIN | Fund account detection (IsFund) |
| TreeID | dbo.RealOpenPositions PTI | INNER JOIN | Root position's IsSettled (IsRootSettled) |
| PTI.PositionID | Trade.OrdersExit | LEFT JOIN | Exit order detection on tree root |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by copy-trade and close processing services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionDataFromReal (procedure)
|- dbo.RealOpenPositions (view) - live open positions
|- Trade.Instrument (table) - forex currency IDs
|- Trade.ProviderToInstrument (table) - precision, units
|- dbo.RealFund (table/view) - fund account detection
|- Trade.OrdersExit (table) - exit order detection
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.RealOpenPositions | View | Primary position data source |
| Trade.Instrument | Table | BuyCurrencyID, SellCurrencyID |
| Trade.ProviderToInstrument | Table | Precision, Unit per provider-instrument |
| dbo.RealFund | Table/View | Fund account detection (CID = FundAccountID) |
| Trade.OrdersExit | Table | Exit order detection on tree root (PTI.PositionID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by copy-trade/close processing |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK on main tables | Performance | Dirty read acceptable for live position lookup |
| No NOLOCK on PTI join | Note | PTI (tree root) join does not have NOLOCK hint |
| IsOpened=1 hardcoded | Signal | Signals caller this is a live open position snapshot |
| All close fields NULL/0 | Contract | EndForexRate, EndDateTime, ActionType, NetProfit, CloseOccurred=NULL; EndExecutionID=0 |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Get full position data from live

```sql
EXEC Trade.GetPositionDataFromReal @PositionID = 987654321
```

### 8.2 Check if position is in a fund and has exit order

```sql
DECLARE @t TABLE (IsFund BIT, ExitOrderID BIGINT, InstrumentID INT, CID INT)
INSERT @t (IsFund, ExitOrderID, InstrumentID, CID)
    SELECT IsFund, ExitOrderID, InstrumentID, CID FROM (
        EXEC Trade.GetPositionDataFromReal @PositionID = 987654321
    ) x
SELECT IsFund, ExitOrderID FROM @t
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 65 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionDataFromReal | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionDataFromReal.sql*
