# Trade.GetLivePositionWithPartialCloseData

> Returns a position's current live state (including partial-close pending status) and its full close/partial-close history, for position lifecycle and audit display.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: two result sets keyed by PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetLivePositionWithPartialCloseData retrieves a comprehensive view of a single position's current state and close history. The first result set shows the live position from Trade.Position, enriched with partial-close status from Trade.OrdersExit - determining whether the position is "Live", "PendingPartialClose", or "PendingClose". The second result set returns all historical close/partial-close records from History.Position for the same original position.

This procedure exists to support position lifecycle display in operations and trading tools. When a position undergoes partial closing, units are deducted in stages - this procedure reveals that intermediate state. For example, a position might show "PendingPartialClose" with 50 units pending deduction, while History.Position shows previous partial closes that already executed.

No explicit callers found in the database permission files, suggesting this is called directly from an application service (likely internal tools or operations API). The @PostionID parameter (note: misspelled in DDL as "Postion") accepts a BIGINT position ID.

---

## 2. Business Logic

### 2.1 Live Position Status Derivation

**What**: Computes the current status of the position by checking whether a pending exit order exists.

**Columns/Parameters Involved**: `Trade.Position`, `Trade.OrdersExit`, `toe.UnitsToDeduct`

**Rules**:
- If no OrdersExit row exists (toe.PositionID IS NULL) -> Status = 'Live' (no pending close/partial close)
- If OrdersExit row exists AND UnitsToDeduct > 0 -> Status = 'PendingPartialClose' (partial close in progress)
- If OrdersExit row exists AND UnitsToDeduct = 0 -> Status = 'PendingClose' (full close pending)
- PendingUnitsToClose follows the same logic: 0 for Live, UnitsToDeduct for PendingPartialClose, full AmountInUnitsDecimal for PendingClose

**Diagram**:
```
Trade.Position (live row)
     |
     +-- LEFT JOIN Trade.OrdersExit
     |        |
     |        +--> No match          -> Status = 'Live', PendingUnitsToClose = 0
     |        +--> UnitsToDeduct > 0 -> Status = 'PendingPartialClose', PendingUnitsToClose = UnitsToDeduct
     |        +--> UnitsToDeduct = 0 -> Status = 'PendingClose', PendingUnitsToClose = AmountInUnitsDecimal
     |
     +-- LEFT JOIN Dictionary.OrdersExitOpenActionType -> ExitOrderOpenActionType name
```

### 2.2 Historical Close Records with Original Position Tracking

**What**: Returns all History.Position records linked to the same original position via OriginalPositionID.

**Columns/Parameters Involved**: `History.Position`, `OriginalPositionID`, `Dictionary.ClosePositionActionType`

**Rules**:
- Matches on ISNULL(OriginalPositionID, PositionID) = @PostionID
- This captures both the original position close AND all partial-close child records
- Each history row includes ActionType resolved to ClosePositionActionName (e.g., Manual, StopLoss, TakeProfit, PartialClose)
- ParentCID is hardcoded to 0 in this query (not resolved)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @PostionID | bigint | IN | - | CODE-BACKED | The PositionID to look up. Used to find the live position and all related historical close/partial-close records. Note: parameter name is misspelled ("Postion" not "Position") in the DDL. |

### 4.2 Result Set 1 (Live Position with Partial Close Status)

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | PositionID | bigint | NO | CODE-BACKED | Unique position identifier. PK of Trade.PositionTbl. |
| 2 | CID | int | NO | CODE-BACKED | Customer ID who owns this position. ISNULL coalesced to 0. |
| 3 | Amount | money | YES | CODE-BACKED | Position amount in dollars. |
| 4 | InitDateTime | datetime | YES | CODE-BACKED | When the position was opened. |
| 5 | InitForexRate | float | YES | CODE-BACKED | Conversion rate at position open time. |
| 6 | InstrumentID | int | YES | CODE-BACKED | The instrument being traded. FK to Trade.Instrument. |
| 7 | IsBuy | bit | YES | CODE-BACKED | 1=Long/Buy, 0=Short/Sell direction. |
| 8 | Leverage | int | YES | CODE-BACKED | Leverage multiplier applied to this position. |
| 9 | LimitRate | float | YES | CODE-BACKED | Take-profit rate. Position auto-closes when market reaches this rate. |
| 10 | StopRate | float | YES | CODE-BACKED | Stop-loss rate. Position auto-closes to limit losses at this rate. |
| 11 | MirrorID | bigint | NO | CODE-BACKED | CopyTrader mirror ID if this is a copied position. ISNULL coalesced to 0. |
| 12 | OrderID | bigint | NO | CODE-BACKED | Associated order ID. ISNULL coalesced to 0. |
| 13 | ParentPositionID | bigint | NO | CODE-BACKED | Parent position for partial close children. ISNULL coalesced to 0. |
| 14 | AmountInUnitsDecimal | decimal | NO | CODE-BACKED | Current position size in units (shares/contracts). ISNULL coalesced to 0. |
| 15 | EndOfWeekFee | money | YES | CODE-BACKED | Weekend/overnight fee charged for holding this position. |
| 16 | InitialAmountInDollars | money | NO | CODE-BACKED | Computed: InitialAmountCents / 100. Original investment in dollars at open. |
| 17 | IsTslEnabled | bit | YES | CODE-BACKED | Whether Trailing Stop Loss is enabled for this position. |
| 18 | StopLossVersion | int | YES | CODE-BACKED | Stop loss manual version counter (aliased from SLManualVer). Tracks SL modifications. |
| 19 | TreeID | bigint | YES | CODE-BACKED | CopyTrader tree identifier linking copied positions to their tree hierarchy. |
| 20 | IsSettled | bit | YES | CODE-BACKED | Legacy flag: 1=real stock position, 0=CFD. Predates SettlementTypeID. |
| 21 | SettlementTypeID | tinyint | YES | CODE-BACKED | Position settlement type: 1=Real, 2=CFD, 3=Crypto, 5=MarginTrade. FK to Dictionary.SettlementTypes. |
| 22 | RedeemStatus | tinyint | NO | CODE-BACKED | Redemption status for real stock positions. ISNULL coalesced to 0. |
| 23 | InitialUnits | decimal | NO | CODE-BACKED | Computed: ISNULL(InitialUnits, AmountInUnitsDecimal). Original unit count at position open; falls back to current units for older positions. |
| 24 | Status | varchar | NO | CODE-BACKED | Computed position lifecycle status: 'Live' (no pending close), 'PendingPartialClose' (partial close in progress), or 'PendingClose' (full close pending). Derived from Trade.OrdersExit presence. |
| 25 | PendingUnitsToClose | decimal | NO | CODE-BACKED | Units awaiting close: 0 for Live, UnitsToDeduct for PendingPartialClose, full AmountInUnitsDecimal for PendingClose. |
| 26 | ExitOrderOpenActionType | varchar | YES | CODE-BACKED | The action type name that initiated the exit order (e.g., 'Manual', 'StopLoss'). From Dictionary.OrdersExitOpenActionType. NULL if no exit order exists. |

### 4.3 Result Set 2 (Historical Close Records)

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | Amount | money | YES | CODE-BACKED | Position amount at time of close. |
| 2 | CID | int | YES | CODE-BACKED | Customer ID. |
| 3 | InstrumentID | int | YES | CODE-BACKED | Instrument traded. |
| 4 | IsBuy | bit | YES | CODE-BACKED | Trade direction. |
| 5 | Leverage | int | YES | CODE-BACKED | Leverage at close. |
| 6 | InitDateTime | datetime | YES | CODE-BACKED | Position open time. |
| 7 | InitForexRate | float | YES | CODE-BACKED | Conversion rate at open. |
| 8 | PositionID | bigint | NO | CODE-BACKED | Position ID of this close record. May differ from @PostionID for partial close children. |
| 9 | StopRate | float | YES | CODE-BACKED | Stop-loss rate at close. |
| 10 | LimitRate | float | YES | CODE-BACKED | Take-profit rate at close. |
| 11 | AmountInUnitsDecimal | decimal | NO | CODE-BACKED | Units at close time. ISNULL coalesced to 0. |
| 12 | EndOfWeekFee | money | YES | CODE-BACKED | Weekend fee at close. |
| 13 | InitialAmountInDollars | money | NO | CODE-BACKED | Computed: InitialAmountCents / 100. |
| 14 | OrderID | bigint | NO | CODE-BACKED | Associated order ID. ISNULL coalesced to 0. |
| 15 | ParentPositionID | bigint | NO | CODE-BACKED | Parent position ID. ISNULL coalesced to 0. |
| 16 | MirrorID | bigint | NO | CODE-BACKED | CopyTrader mirror ID. ISNULL coalesced to 0. |
| 17 | ActionType | tinyint | YES | CODE-BACKED | Close action type ID. FK to Dictionary.ClosePositionActionType. |
| 18 | NetProfit | money | YES | CODE-BACKED | Realized PnL from this close. |
| 19 | EndForexRate | float | YES | CODE-BACKED | Conversion rate at close time. |
| 20 | CloseOccurred | datetime | YES | CODE-BACKED | When the close was executed. |
| 21 | ParentCID | int | NO | CODE-BACKED | Hardcoded to 0 in this query. Not resolved. |
| 22 | IsSettled | bit | YES | CODE-BACKED | Legacy settlement flag. |
| 23 | SettlementTypeID | tinyint | YES | CODE-BACKED | Settlement type at close. |
| 24 | RedeemStatus | tinyint | NO | CODE-BACKED | Redemption status. ISNULL coalesced to 0. |
| 25 | OriginalPositionID | bigint | NO | CODE-BACKED | Computed: ISNULL(OriginalPositionID, PositionID). Links partial close records back to the original position. |
| 26 | ClosePositionActionType | varchar | YES | CODE-BACKED | Human-readable close action name from Dictionary.ClosePositionActionType (e.g., 'Manual', 'StopLoss', 'TakeProfit', 'PartialClose'). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Position | SELECT (READER) | Reads live position data (view over Trade.PositionTbl) |
| LEFT JOIN | Trade.OrdersExit | SELECT (READER) | Checks for pending exit orders to determine partial/full close status |
| LEFT JOIN | Dictionary.OrdersExitOpenActionType | SELECT (READER) | Resolves exit order action type ID to name |
| FROM | History.Position | SELECT (READER) | Reads closed position history for same original position |
| JOIN | Dictionary.ClosePositionActionType | SELECT (READER) | Resolves close action type ID to name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application) | Direct call | Application | No database-level callers found; called from application services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetLivePositionWithPartialCloseData (procedure)
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table)
+-- Trade.OrdersExit (table)
+-- Dictionary.OrdersExitOpenActionType (table)
+-- History.Position (table)
+-- Dictionary.ClosePositionActionType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Main data source for live position |
| Trade.OrdersExit | Table | LEFT JOIN to detect pending exit orders |
| Dictionary.OrdersExitOpenActionType | Table | Resolve exit order action type name |
| History.Position | Table | Historical close records for the position |
| Dictionary.ClosePositionActionType | Table | Resolve close action type name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No DB-level dependents found) | - | Called from application services directly |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get live position with partial close data

```sql
EXEC Trade.GetLivePositionWithPartialCloseData @PostionID = 1234567890;
```

### 8.2 Find positions with pending partial closes

```sql
SELECT  p.PositionID,
        p.CID,
        p.InstrumentID,
        p.AmountInUnitsDecimal,
        toe.UnitsToDeduct,
        CASE
            WHEN toe.PositionID IS NULL THEN 'Live'
            WHEN toe.UnitsToDeduct > 0 THEN 'PendingPartialClose'
            ELSE 'PendingClose'
        END AS Status
FROM    Trade.Position p WITH (NOLOCK)
        LEFT JOIN Trade.OrdersExit toe WITH (NOLOCK)
            ON p.PositionID = toe.PositionID
WHERE   toe.PositionID IS NOT NULL
ORDER BY p.PositionID;
```

### 8.3 View close history for a position

```sql
SELECT  hp.PositionID,
        ISNULL(hp.OriginalPositionID, hp.PositionID) AS OriginalPositionID,
        hp.ActionType,
        dca.ClosePositionActionName,
        hp.NetProfit,
        hp.CloseOccurred,
        hp.AmountInUnitsDecimal
FROM    History.Position hp WITH (NOLOCK)
        JOIN Dictionary.ClosePositionActionType dca WITH (NOLOCK)
            ON hp.ActionType = dca.ID
WHERE   ISNULL(hp.OriginalPositionID, hp.PositionID) = 1234567890
ORDER BY hp.CloseOccurred;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 52 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetLivePositionWithPartialCloseData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetLivePositionWithPartialCloseData.sql*
