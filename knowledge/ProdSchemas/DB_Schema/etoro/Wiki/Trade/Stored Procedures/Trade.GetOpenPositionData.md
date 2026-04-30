# Trade.GetOpenPositionData

> Retrieves the complete data snapshot for a single open position, joining PositionTbl with Instrument, ProviderToInstrument, PositionTreeInfo, Mirror, and OrdersExit - with a retry loop and optional shared-lock mode for consistency-critical reads.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID BIGINT + @LockPosition BIT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOpenPositionData` fetches the full set of data attributes for a single open position (StatusID=1). It combines position core data (from `Trade.PositionTbl`) with instrument rates (`Trade.Instrument`), unit/precision data (`Trade.ProviderToInstrument`), copy-trade tree settings (`Trade.PositionTreeInfo`), mirror status (`Trade.Mirror`), and exit-order linkage (`Trade.OrdersExit`). The result is the canonical "open position snapshot" used by the execution engine for close, edit, and reporting operations.

**WHY:** Closing or editing a position requires a complete view of its current state across multiple tables. Rather than having callers issue multiple SELECTs, this SP provides a single consistent snapshot. The retry loop handles the case where a concurrent write has just changed the position status (race condition during close flow) - if @@ROWCOUNT=0, the SP retries up to 3 times before returning empty.

**HOW:** Called from the trading execution service (position close, SL/TP edit, post-execution flows). The `@LockPosition` parameter switches between NOLOCK (default, fast) and shared-lock (READ COMMITTED, used when consistency is critical - e.g., during actual close execution). Partition elimination is applied via `PartitionCol = @PositionID % 50` for PositionTbl and `CID % 50` for OrdersExit. Returns one result set via the `@PositionData` table variable of type `Trade.OpenPositionData`.

---

## 2. Business Logic

### 2.1 Retry Loop for Race Condition Handling

**What:** The SP attempts up to 3 times to fetch the position. If the first attempt returns 0 rows (position was concurrently closed between the caller's check and this SP's execution), it retries. This prevents false-empty results during high-throughput close operations.

**Columns/Parameters Involved:** `@RetryUpdate`, `@@ROWCOUNT`, `StatusID`

**Rules:**
- `@RetryUpdate` starts at 3; decremented on each empty result
- If @@ROWCOUNT > 0 on any attempt, `@RetryUpdate = 0` (stops loop)
- Only open positions (StatusID=1) are returned - closed positions (StatusID=2) return empty even after retries
- After 3 failures, returns empty result set (caller handles this as "position not found / already closed")

**Diagram:**
```
Attempt 1: SELECT ... WHERE PositionID=X AND StatusID=1
  -> @@ROWCOUNT=0 (position being closed concurrently) -> retry
Attempt 2: SELECT again
  -> @@ROWCOUNT=1 (position still open) -> break, return data
```

### 2.2 Lock Mode Selection

**What:** The `@LockPosition` flag controls isolation level - NOLOCK for fast reads vs shared lock (READ COMMITTED) for consistent reads during critical operations.

**Columns/Parameters Involved:** `@LockPosition`

**Rules:**
- `@LockPosition = 0` (default): Uses `WITH (NOLOCK)` on PositionTbl - may read uncommitted data, but fast
- `@LockPosition = 1`: No NOLOCK hint - uses READ COMMITTED, ensuring the read sees only committed data
- Callers use `@LockPosition = 1` when the accuracy of the read is critical (e.g., computing P&L for close)

### 2.3 Settlement Type Fallback

**What:** `SettlementTypeID` uses a ISNULL fallback to `IsSettled` for legacy positions that predate the SettlementTypeID column.

**Columns/Parameters Involved:** `SettlementTypeID`, `IsSettled`

**Rules:**
- `ISNULL(TPOS.SettlementTypeID, CAST(ISNULL(TPOS.IsSettled, 0) AS TINYINT))` - if SettlementTypeID is NULL (old position), cast IsSettled (0/1) as the settlement type
- IsSettled=1 -> SettlementTypeID=1 (REAL stock position)
- IsSettled=0 -> SettlementTypeID=0 (CFD position)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | bigint | NO | - | CODE-BACKED | Input: the open position to retrieve. Must match a row in Trade.PositionTbl with StatusID=1. Used for partition elimination (PartitionCol=@PositionID%50). |
| 2 | @LockPosition | bit | YES | 0 | CODE-BACKED | Input: lock mode. 0=NOLOCK (default, fast, may read uncommitted); 1=shared lock (READ COMMITTED, consistent read for close/edit operations). |

**Return Columns (Trade.OpenPositionData type):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | CID | int | NO | - | CODE-BACKED | Customer ID. Owner of the position. |
| R2 | PositionID | bigint | NO | - | CODE-BACKED | The position identifier. |
| R3 | ForexResultID | int | YES | - | CODE-BACKED | Foreign exchange result ID for PnL tracking. |
| R4 | IsOpened | bit | NO | - | CODE-BACKED | Always 1 (hardcoded in SELECT) - indicates this is an open position snapshot. |
| R5 | Currency | int | NO | - | CODE-BACKED | From PositionTbl.CurrencyID. Denomination currency for PnL (inherited from Trade.PositionTbl). |
| R6 | ProviderID | int | NO | - | CODE-BACKED | Liquidity provider ID. Used to join ProviderToInstrument for unit/precision data. |
| R7 | InstrumentID | int | NO | - | CODE-BACKED | The traded instrument. FK to Trade.Instrument. |
| R8 | PositionHedgeServerID | int | NO | - | CODE-BACKED | Hedge server that owns this position (from HedgeServerID). |
| R9 | Leverage | int | NO | - | CODE-BACKED | Position leverage multiplier. |
| R10 | ForexBuy | int | NO | - | CODE-BACKED | From Trade.Instrument.BuyCurrencyID. Buy-side forex currency for this instrument. |
| R11 | ForexSell | int | NO | - | CODE-BACKED | From Trade.Instrument.SellCurrencyID. Sell-side forex currency. |
| R12 | InitForexRate | money | NO | - | CODE-BACKED | Opening forex conversion rate. |
| R13 | EndForexRate | money | YES | NULL | CODE-BACKED | Always NULL for open positions (set on close). |
| R14 | InitDateTime | datetime | NO | - | CODE-BACKED | Position open timestamp. |
| R15 | EndDateTime | datetime | YES | NULL | CODE-BACKED | Always NULL for open positions. |
| R16 | ActionType | int | YES | NULL | CODE-BACKED | Always NULL for open positions (set on close via close action type). |
| R17 | NetProfit | money | YES | NULL | CODE-BACKED | Always NULL for open positions. |
| R18 | LimitRate | money | YES | - | CODE-BACKED | Take-profit rate from PositionTreeInfo. The rate at which the position auto-closes in profit. |
| R19 | StopRate | money | YES | - | CODE-BACKED | Stop-loss rate from PositionTreeInfo. |
| R20 | Amount | money | NO | - | CODE-BACKED | Position amount in account currency (dollars/cents). |
| R21 | AmountInUnitsDecimal | decimal | NO | - | CODE-BACKED | Position size in instrument units. |
| R22 | Commission | money | NO | - | CODE-BACKED | Opening commission charged. |
| R23 | SpreadedCommission | money | NO | - | CODE-BACKED | Commission including spread component. |
| R24 | IsBuy | varchar(5) | NO | - | CODE-BACKED | Direction: 'true'=long/buy, 'false'=short/sell. String representation (CASE WHEN IsBuy=1). |
| R25 | CloseOnEndOfWeek | varchar(5) | NO | - | CODE-BACKED | 'true'/'false' - from PositionTreeInfo. Whether this position auto-closes at week end. |
| R26 | EndOfWeekFee | money | YES | - | CODE-BACKED | Weekend fee charged on this position. |
| R27 | LotCountDecimal | decimal | YES | - | CODE-BACKED | Position size in lots. |
| R28 | AdditionalParam | int | YES | - | CODE-BACKED | Additional parameter field. |
| R29 | OpenOccurred | datetime | NO | - | CODE-BACKED | From PositionTbl.Occurred. Actual open timestamp. |
| R30 | CloseOccurred | datetime | YES | NULL | CODE-BACKED | Always NULL for open positions. |
| R31 | OrderID | bigint | YES | - | CODE-BACKED | The open order that created this position. |
| R32 | TradeRange | int | YES | - | CODE-BACKED | Trade range setting at open. |
| R33 | InitForexPriceRateID | bigint | YES | - | CODE-BACKED | Price rate ID at position open. |
| R34 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position ID for copy-trade hierarchy. 0 for root. |
| R35 | OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent position before any splits/reopens. |
| R36 | LastOpPriceRate | money | YES | - | CODE-BACKED | Last operational price rate. |
| R37 | LastOpPriceRateID | bigint | YES | - | CODE-BACKED | ID of the last operational price rate. |
| R38 | LastOpConversionRate | money | YES | - | CODE-BACKED | Last operational forex conversion rate. |
| R39 | LastOpConversionRateID | bigint | YES | - | CODE-BACKED | ID of the last operational conversion rate. |
| R40 | UnitMargin | decimal | NO | - | CODE-BACKED | Margin per unit. Used in margin calculations. |
| R41 | Units | decimal | NO | - | CODE-BACKED | From ProviderToInstrument.Unit. Lot size for this instrument/provider combination. |
| R42 | InstrumentPrecision | int | NO | - | CODE-BACKED | From ProviderToInstrument.Precision. Decimal precision for price display. |
| R43 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror ID. 0=manual position; >0=copied from leader. |
| R44 | PositionRatio | decimal | YES | - | CODE-BACKED | Ratio of this position in the copy tree. |
| R45 | DirectAggLotCount | decimal | YES | - | CODE-BACKED | Direct aggregate lot count for hedging. |
| R46 | SpreadGroupID | int | YES | - | CODE-BACKED | Spread group assigned at open. |
| R47 | InitialAmountCents | bigint | YES | - | CODE-BACKED | Initial position amount in cents. |
| R48 | HedgeServerID | int | NO | - | CODE-BACKED | Hedge server ID (same as PositionHedgeServerID). |
| R49 | InitExecutionID | bigint | YES | - | CODE-BACKED | Execution ID from the open flow. |
| R50 | EndExecutionID | int | NO | - | CODE-BACKED | Always 0 for open positions. |
| R51 | RootHedgeServerID | int | YES | - | CODE-BACKED | Root hedge server in copy-trade tree. |
| R52 | IsOpenOpen | bit | YES | - | CODE-BACKED | Whether this is an "open within an open" position. |
| R53 | TreeID | bigint | YES | - | CODE-BACKED | Copy-trade tree root position ID. Used to join PositionTreeInfo. |
| R54 | IsComputeForHedge | bit | NO | - | CODE-BACKED | Whether this position is included in hedge computations. |
| R55 | ExitOrderID | bigint | NO | - | CODE-BACKED | From Trade.OrdersExit via LEFT JOIN. 0 if no exit order exists. |
| R56 | IsTslEnabled | bit | NO | - | CODE-BACKED | Whether trailing stop-loss is enabled for this position. |
| R57 | IsMirrorActive | bit | NO | - | CODE-BACKED | From Mirror.IsActive (ISNULL -> 0). 1=the copy relationship is still active. |
| R58 | SLManualVer | int | YES | - | CODE-BACKED | From PositionTreeInfo. Stop-loss manual version counter. |
| R59 | FullCommission | money | YES | - | CODE-BACKED | Total commission (open + spread). |
| R60 | FullCommissionOnClose | money | YES | NULL | CODE-BACKED | Always NULL for open positions. |
| R61 | RedeemStatus | tinyint | NO | - | CODE-BACKED | ISNULL(RedeemStatus, 0). 0=not redeemed; >0=redemption status. |
| R62 | IsSettled | tinyint | NO | - | CODE-BACKED | ISNULL(IsSettled, 0). Legacy: 1=real stock, 0=CFD. |
| R63 | SettlementTypeID | tinyint | NO | - | CODE-BACKED | ISNULL(SettlementTypeID, CAST(IsSettled as tinyint)). Settlement: 0=CFD, 1=REAL, 2=TRS. Falls back to IsSettled for legacy positions. |
| R64 | UnitsBaseValueCents | int | NO | - | CODE-BACKED | ISNULL(UnitsBaseValueCents, CONVERT(INT, InitialAmountCents)). Unit base value in cents. |
| R65 | IsDiscounted | bit | YES | - | CODE-BACKED | From PositionTreeInfo. Whether a discount was applied. |
| R66 | InitConversionRate | money | YES | - | CODE-BACKED | Initial forex conversion rate at open. |
| R67 | RedeemID | bigint | NO | - | CODE-BACKED | ISNULL(RedeemID, 0). ID of redemption event if applicable. |
| R68 | PnLVersion | tinyint | YES | - | CODE-BACKED | P&L calculation version. 1=real-stock formula, 0=CFD formula. |
| R69 | IsNoStopLoss | bit | YES | - | CODE-BACKED | From PositionTreeInfo. 1=no stop-loss on this position. |
| R70 | IsNoTakeProfit | bit | YES | - | CODE-BACKED | From PositionTreeInfo. 1=no take-profit on this position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | Trade.PositionTbl | Direct query | Primary data source, filter by StatusID=1 |
| InstrumentID | Trade.Instrument | JOIN | Gets BuyCurrencyID, SellCurrencyID for forex pair |
| ProviderID+InstrumentID | Trade.ProviderToInstrument | JOIN | Gets Unit, Precision |
| TreeID | Trade.PositionTreeInfo | JOIN | Gets LimitRate, StopRate, CloseOnEndOfWeek, SLManualVer, IsDiscounted, IsNoStopLoss/TakeProfit |
| MirrorID | Trade.Mirror | LEFT JOIN | Gets IsMirrorActive |
| PositionID | Trade.OrdersExit | LEFT JOIN | Gets ExitOrderID if any exit order exists |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application execution services | N/A | CALLER | Called during position close, edit, and post-execution flows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOpenPositionData (procedure)
├── Trade.PositionTbl (table)
├── Trade.Instrument (table)
├── Trade.ProviderToInstrument (table)
├── Trade.PositionTreeInfo (table)
├── Trade.Mirror (table)
└── Trade.OrdersExit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Primary SELECT - open position core data |
| Trade.Instrument | Table | INNER JOIN - forex buy/sell currency IDs |
| Trade.ProviderToInstrument | Table | INNER JOIN - unit size and precision |
| Trade.PositionTreeInfo | Table | INNER JOIN via TreeID+PartitionCol - SL/TP rates, tree settings |
| Trade.Mirror | Table | LEFT JOIN - mirror active status |
| Trade.OrdersExit | Table | LEFT JOIN - exit order linkage |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application execution services | External | Reads full position snapshot for close/edit/reporting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**UDT Used:** `Trade.OpenPositionData` (table type) - used as the internal accumulation variable `@PositionData`.

**Partition Elimination:**
- PositionTbl: `PartitionCol = @PositionID % 50`
- OrdersExit: `PartitionCol = CID % 50`
- PositionTreeInfo: `abs(TreeID % 50) = PartitionCol`

---

## 8. Sample Queries

### 8.1 Get open position data
```sql
EXEC Trade.GetOpenPositionData @PositionID = 987654321, @LockPosition = 0
```

### 8.2 Get with shared lock (for consistency-critical operations)
```sql
EXEC Trade.GetOpenPositionData @PositionID = 987654321, @LockPosition = 1
```

### 8.3 Manual equivalent - verify position state
```sql
SELECT p.PositionID, p.CID, p.InstrumentID, p.Amount, p.IsBuy, p.StatusID,
       pti.LimitRate, pti.StopRate,
       m.IsActive AS IsMirrorActive,
       ISNULL(oe.OrderID, 0) AS ExitOrderID
FROM   Trade.PositionTbl p WITH (NOLOCK)
       INNER JOIN Trade.PositionTreeInfo pti WITH (NOLOCK)
           ON pti.TreeID = p.TreeID AND ABS(p.TreeID % 50) = pti.PartitionCol
       LEFT JOIN Trade.Mirror m WITH (NOLOCK) ON m.MirrorID = p.MirrorID
       LEFT JOIN Trade.OrdersExit oe WITH (NOLOCK)
           ON oe.PositionID = p.PositionID AND oe.PartitionCol = p.CID % 50
WHERE  p.PositionID = 987654321
       AND p.StatusID = 1
       AND p.PartitionCol = 987654321 % 50
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 70 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1, 5, 8, 9B partial, 10 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 1 test file | Corrections: 0 applied*
*Object: Trade.GetOpenPositionData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOpenPositionData.sql*
