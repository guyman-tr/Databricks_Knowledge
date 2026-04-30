# Trade.GetOpenPositionsData

> Returns position data for a batch of position IDs with retry logic and optional lock mode - used during close-order execution to atomically fetch current state of multiple positions including pending close status.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionIDs TVP + @CID INT + @InstrumentID INT |
| **Partition** | PositionTbl: PartitionCol = PositionID%50, PositionTreeInfo: PartitionCol = abs(TreeID%50) |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOpenPositionsData` fetches the current state of a specified set of open positions (provided as a table-valued parameter) for a given customer and instrument, including their pending close orders. It uses a retry loop (up to 3 attempts) with the `Trade.OpenPositionDataSlim` UDT as the output buffer - on each iteration it tries to load data, and continues if rows are returned.

**WHY:** During close-order processing, the execution engine needs the current live state of each position being closed: size, rates, mirror association, settlement type, and any already-in-flight close orders (to exclude or account for them). The retry loop handles transient lock/race conditions where data may not be immediately available.

**HOW:** The caller provides a list of PositionIDs (via `Trade.PositionIDsTbl` TVP) plus CID, InstrumentID, and OrderID. The SP loads matching open positions from `Trade.PositionTbl`, joins `Trade.PositionTreeInfo` for limit/stop rates, `Trade.Mirror` for copy status, and `OUTER APPLY` to `Trade.CloseExecutionPlan`/`Trade.OrderForClose` for pending close detection. After the retry loop, the accumulated result is selected from the UDT buffer.

---

## 2. Business Logic

### 2.1 Retry Loop - Transient Data Loading

**What:** The procedure retries up to 3 times to populate the `@PositionData` UDT. It stops as soon as `@@ROWCOUNT > 0`. If all 3 attempts yield 0 rows, the query returns empty (no explicit error).

**Columns/Parameters Involved:** `@RetryUpdate` (counter), `@@ROWCOUNT`

**Rules:**
- `@RetryUpdate = 3` on entry; decremented per failed attempt
- Loop exits immediately when rows are inserted (success path)
- If 0 rows after 3 attempts: caller receives empty result set (positions may have been closed between request and execution)

### 2.2 Lock Mode Selection

**What:** `@LockPosition` controls transaction isolation to balance between consistency and throughput.

**Columns/Parameters Involved:** `@LockPosition`, `TRANSACTION ISOLATION LEVEL`

**Rules:**
- `@LockPosition = 1` -> `READ COMMITTED` (shared locks, consistent reads - used when accuracy is critical)
- `@LockPosition = 0` (default) -> `READ UNCOMMITTED` (NOLOCK equivalent - faster, tolerates dirty reads)

### 2.3 Pending Close Order Detection (OUTER APPLY)

**What:** For each position, the SP looks up any non-terminal close order already in flight (excluding the current @OrderID to avoid self-reference). This tells the caller whether another close is already processing.

**Columns/Parameters Involved:** `PendingOrderForClose`, `PendingOrderForCloseStatus`, `PendingOrderForCloseType`, `PendingOrderForCloseUnitsToDeduct`

**Rules:**
- `CEP.OrderID <> @OrderID` -> excludes the triggering order itself (default @OrderID=0 means no exclusion)
- `DOFE.IsTerminal = 0` -> only non-terminal (active/in-progress) close orders count
- `PendingOrderForCloseUnitsToDeduct`: returns `OFC.Units` only if `OFC.UnitsToDeduct > 0`, otherwise 0

### 2.4 Partition Elimination

**What:** Both PositionTbl and PositionTreeInfo use explicit partition column predicates for performance.

**Rules:**
- `PositionTbl.PartitionCol = PositionID % 50`
- `PositionTreeInfo.PartitionCol = ABS(TreeID % 50)`

### 2.5 Settlement Type Fallback

**What:** Unlike GetOpenPositionData (which has the `ISNULL(SettlementTypeID, IsSettled)` fallback), this SP reads `SettlementTypeID` directly from PositionTbl without fallback.

---

## 3. Data Overview

N/A for Stored Procedure. Uses `Trade.OpenPositionDataSlim` UDT as internal buffer.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionIDs | Trade.PositionIDsTbl READONLY | NO | - | CODE-BACKED | Input TVP: list of PositionIDs to fetch. Each row is matched with PositionTbl via partition-aware JOIN. |
| 2 | @LockPosition | bit | YES | 0 | CODE-BACKED | Lock mode: 0=READ UNCOMMITTED (NOLOCK, default), 1=READ COMMITTED (shared locks). Set to 1 when position consistency is critical. |
| 3 | @InstrumentID | int | NO | - | CODE-BACKED | Instrument filter. If > 0, restricts to positions on this instrument. If 0, all instruments for the CID are returned. |
| 4 | @CID | int | NO | - | CODE-BACKED | Customer ID. Scopes all queries to a single customer's positions. |
| 5 | @OrderID | bigint | YES | 0 | CODE-BACKED | Triggering close order ID. Used to exclude self from pending-close detection. Default 0 = no exclusion. |

**Return Columns (from Trade.OpenPositionDataSlim UDT):**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| R1 | CID | int | NO | CODE-BACKED | Customer owning the position. |
| R2 | PositionID | bigint | NO | CODE-BACKED | Primary key of the position. |
| R3 | InstrumentID | int | NO | CODE-BACKED | Financial instrument. |
| R4 | PositionHedgeServerID | int | YES | CODE-BACKED | Hedge server handling this position (= TPOS.HedgeServerID). |
| R5 | Leverage | smallint | NO | CODE-BACKED | Leverage multiplier applied at open. |
| R6 | InitForexRate | money | NO | CODE-BACKED | Entry rate of the position. |
| R7 | InitDateTime | datetime | NO | CODE-BACKED | Timestamp when position was opened. |
| R8 | LimitRate | money | YES | CODE-BACKED | Take-profit rate (from PositionTreeInfo). |
| R9 | StopRate | money | YES | CODE-BACKED | Stop-loss rate (from PositionTreeInfo). |
| R10 | Amount | money | NO | CODE-BACKED | Position amount in account currency cents. |
| R11 | AmountInUnitsDecimal | decimal | NO | CODE-BACKED | Position size in instrument units. |
| R12 | IsBuy | bit | NO | CODE-BACKED | Direction: 1=long, 0=short. |
| R13 | ParentPositionID | bigint | YES | CODE-BACKED | Parent in copy-trade tree (0 if root). |
| R14 | UnitMargin | money | NO | CODE-BACKED | Margin required per unit. |
| R15 | MirrorID | int | YES | CODE-BACKED | Copy relationship ID (0 if not copied). |
| R16 | PositionRatio | decimal | YES | CODE-BACKED | Ratio in copy portfolio. |
| R17 | HedgeServerID | int | YES | CODE-BACKED | Duplicate of PositionHedgeServerID from TPOS. |
| R18 | RootHedgeServerID | int | YES | CODE-BACKED | Root-level hedge server for tree positions. |
| R19 | TreeID | bigint | YES | CODE-BACKED | Tree root PositionID (for copy-tree navigation). |
| R20 | IsComputeForHedge | bit | NO | CODE-BACKED | Whether this position is tracked by the hedge engine. |
| R21 | IsTslEnabled | bit | YES | CODE-BACKED | Whether trailing stop-loss is enabled. |
| R22 | IsMirrorActive | bit | NO | CODE-BACKED | ISNULL(Mirror.IsActive, 0) - is the copy relationship currently active. |
| R23 | RedeemStatus | tinyint | NO | CODE-BACKED | ISNULL(RedeemStatus, 0) - redemption state of position. |
| R24 | IsSettled | bit | NO | CODE-BACKED | ISNULL(IsSettled, 0) - stock settlement flag. |
| R25 | SettlementTypeID | tinyint | YES | CODE-BACKED | Settlement type (0=not set, 1=Real, 2=Virtual). |
| R26 | UnitsBaseValueCents | int | NO | CODE-BACKED | ISNULL(UnitsBaseValueCents, InitialAmountCents) - base value of units in cents. |
| R27 | IsDiscounted | bit | YES | CODE-BACKED | Whether commission discount applies (from PositionTreeInfo). |
| R28 | PendingOrderForClose | bigint | NO | CODE-BACKED | ISNULL(CloseExecutionPlan.OrderID, 0) - active pending close order. 0 = none. |
| R29 | MirrorStatusID | int | NO | CODE-BACKED | ISNULL(Mirror.MirrorStatusID, 0). 0=Active mirror, other=stopped/closed. |
| R30 | RedeemID | int | NO | CODE-BACKED | ISNULL(RedeemID, 0) - NFT/redemption transaction ID. |
| R31 | InitForexPriceRateID | bigint | YES | CODE-BACKED | Rate record ID for entry forex conversion. |
| R32 | PendingOrderForCloseStatus | int | NO | CODE-BACKED | ISNULL(OrderForClose.StatusID, 0) - status of the pending close order. |
| R33 | PendingOrderForCloseType | int | NO | CODE-BACKED | ISNULL(OrderForClose.OrderType, 0) - type of the pending close order. |
| R34 | PendingOrderForCloseUnitsToDeduct | money | NO | CODE-BACKED | Units being deducted by the pending close. 0 if no active deduction. |
| R35 | StopLossVersion | int | YES | CODE-BACKED | SLManualVer from PositionTreeInfo - tracks manual stop-loss version. |
| R36 | IsNoStopLoss | bit | YES | CODE-BACKED | Whether position has no stop-loss requirement (from PositionTreeInfo). |
| R37 | IsNoTakeProfit | bit | YES | CODE-BACKED | Whether position has no take-profit requirement (from PositionTreeInfo). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionIDs + @CID | Trade.PositionTbl | Direct query | Fetches open positions (StatusID=1) matching input TVP with partition elimination |
| TreeID | Trade.PositionTreeInfo | INNER JOIN | Gets LimitRate, StopRate, IsDiscounted, IsTslEnabled, StopLossVersion, IsNoStopLoss, IsNoTakeProfit |
| MirrorID | Trade.Mirror | LEFT JOIN | Gets IsActive, MirrorStatusID |
| PositionID | Trade.CloseExecutionPlan | OUTER APPLY | Detects non-terminal pending close orders |
| CloseExecutionPlan.OrderID | Trade.OrderForClose | INNER JOIN (in OUTER APPLY) | Gets close order status and units |
| OrderForClose.StatusID | Dictionary.OrderForExecutionStatus | INNER JOIN (in OUTER APPLY) | Filters non-terminal statuses (IsTerminal=0) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Close-order execution service | N/A | CALLER | Fetches current state of positions being closed |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOpenPositionsData (procedure)
├── Trade.PositionTbl (table)
├── Trade.PositionTreeInfo (table)
├── Trade.Mirror (table)
├── Trade.CloseExecutionPlan (table)
├── Trade.OrderForClose (table)
└── Dictionary.OrderForExecutionStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionIDsTbl | User Defined Type | Input TVP parameter type |
| Trade.OpenPositionDataSlim | User Defined Type | Internal result buffer (DECLARE @PositionData) |
| Trade.PositionTbl | Table | Main position data source |
| Trade.PositionTreeInfo | Table | Limit/stop rates and tree-level flags |
| Trade.Mirror | Table | Copy relationship active status |
| Trade.CloseExecutionPlan | Table | Pending close order detection |
| Trade.OrderForClose | Table | Close order status/type/units |
| Dictionary.OrderForExecutionStatus | Table | IsTerminal flag for close order filtering |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Close-order execution service | External | Fetches position state before executing close |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Note:** Uses a retry loop (up to 3 iterations). The lock mode (`@LockPosition`) is set at the session level using `SET TRANSACTION ISOLATION LEVEL`, not at the table hint level. This affects the entire session for the duration of the SP execution.

**Note:** `Trade.PositionIDsTbl` is different from `Trade.PositionIDsTbl_MOT` used in `GetOrderForCloseContextData`. The `_MOT` variant is memory-optimized.

---

## 8. Sample Queries

### 8.1 Fetch open positions for a batch close operation
```sql
DECLARE @ids Trade.PositionIDsTbl
INSERT INTO @ids VALUES (111111111), (222222222), (333333333)
EXEC Trade.GetOpenPositionsData @PositionIDs = @ids, @LockPosition = 0, @InstrumentID = 1234, @CID = 9876543, @OrderID = 0
```

### 8.2 Fetch with shared lock (pre-execution consistency mode)
```sql
DECLARE @ids Trade.PositionIDsTbl
INSERT INTO @ids VALUES (111111111)
EXEC Trade.GetOpenPositionsData @PositionIDs = @ids, @LockPosition = 1, @InstrumentID = 1234, @CID = 9876543, @OrderID = 99887766
```

### 8.3 Manual equivalent - check positions with pending close
```sql
SELECT  TPOS.PositionID,
        TPOS.AmountInUnitsDecimal,
        ISNULL(OrderData.OrderID, 0) AS PendingOrderForClose,
        ISNULL(OrderData.StatusID, 0) AS PendingOrderForCloseStatus
FROM    Trade.PositionTbl TPOS WITH (NOLOCK)
        OUTER APPLY (
            SELECT TOP 1 CEP.OrderID, OFC.StatusID
            FROM   Trade.CloseExecutionPlan CEP
                   INNER JOIN Trade.OrderForClose OFC ON CEP.OrderID = OFC.OrderID
                   INNER JOIN Dictionary.OrderForExecutionStatus DOFE ON OFC.StatusID = DOFE.ID
            WHERE  TPOS.PositionID = CEP.PositionID AND DOFE.IsTerminal = 0
        ) AS OrderData
WHERE   TPOS.CID = 9876543 AND TPOS.InstrumentID = 1234 AND TPOS.StatusID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOpenPositionsData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOpenPositionsData.sql*
