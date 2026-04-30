# Trade.GetPositionDataForAllocation

> Returns position metadata (MirrorID, ActionType, ExecutionTime, InitDate, InitRate) for allocation services - handles both open and closed positions by unioning live and history sources.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID + @IsOpen flag |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetPositionDataForAllocation` retrieves the minimal position context needed for allocation processing: MirrorID, ActionType (open/close action), the execution timestamp, the initial open date, and the initial forex rate. It operates in two modes controlled by @IsOpen: open-position mode (PositionTbl + History.Position_Active UNION) and closed-position mode (History.Position_Active + PositionTbl StatusID=2 UNION).

**WHY:** Allocation services need to know when a trade was executed (ExecutionTime), how it was opened (ActionType), and what rate it opened at (InitRate) regardless of whether the position is currently open or has just closed. The UNION pattern ensures the data is found even when the position is in transition between live and history tables.

**HOW:** Uses READ UNCOMMITTED isolation (SET TRAN ISOLATION LEVEL READ UNCOMMITTED) for maximum read performance. Resolves ExecutionTime from the ExecutedOpenOrders/OrderForOpen chain (for open) or ExecutedCloseOrders/OrderForClose chain (for close), with History tables tried first and live tables as fallback (ISNULL(@HistoryExecutionTime, @ExecutionTime)).

---

## 2. Business Logic

### 2.1 Open Position Mode (@IsOpen=1)

**What:** Looks up open position allocation context.

**Columns/Parameters Involved:** `@IsOpen = 1`, `ExecutionTime`

**Rules:**
- ExecutionTime resolved from: `History.ExecutedOpenOrders -> History.OrderForOpen.OpenOccurred` (history first)
- If NULL: `Trade.ExecutedOpenOrders -> Trade.OrderForOpen.OpenOccurred` (live fallback)
- Data from: Trade.PositionTbl WHERE PositionID=@PositionID AND PartitionCol=@PositionID%50
- UNION with History.Position_Active WHERE PositionID=@PositionID (safety net for recently-archived positions)
- OpenActionType aliased as ActionType

### 2.2 Closed Position Mode (@IsOpen=0)

**What:** Looks up closed position allocation context.

**Columns/Parameters Involved:** `@IsOpen = 0`, `ExecutionTime`

**Rules:**
- ExecutionTime resolved from: `History.ExecutedCloseOrders -> History.OrderForClose.OpenOccurred` (history first)
- If NULL: `Trade.ExecutedCloseOrders -> Trade.OrderForClose.OpenOccurred` (live fallback)
- Data from: History.Position_Active WHERE PositionID=@PositionID (closed positions)
- UNION with Trade.PositionTbl WHERE PositionID=@PositionID AND PartitionCol=@PositionID%50 AND StatusID=2 (recently-closed still in live table)

### 2.3 History-First with Live Fallback

**What:** History tables are tried before live tables for ExecutionTime; this pattern ensures the most stable (archived) timestamp is used when available.

**Rules:**
- `ISNULL(@HistoryExecutionTime, @ExecutionTime)` - history preferred, live as fallback
- Applies to both open and close modes
- Prevents timestamp discrepancies from in-flight archiving operations

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Position ID to look up. |
| 2 | @IsOpen | BIT | NO | - | CODE-BACKED | 1=position is open (use PositionTbl+ExecutedOpenOrders); 0=position is closed (use History+ExecutedCloseOrders). |
| 3 | MirrorID | INT | YES | - | CODE-BACKED | Copy relationship ID. NULL for manual positions. |
| 4 | ActionType | INT | YES | - | CODE-BACKED | Open action type (OpenActionType for @IsOpen=1) or close action type (ActionType for @IsOpen=0). Identifies how the position was opened/closed. |
| 5 | ExecutionTime | DATETIME2 | YES | - | CODE-BACKED | When the execution occurred. History.OrderForOpen/OrderForClose.OpenOccurred, with history preferred over live. |
| 6 | InitDate | DATETIME | YES | - | CODE-BACKED | Position open timestamp (InitDateTime from PositionTbl or Position_Active). |
| 7 | InitRate | DECIMAL | YES | - | CODE-BACKED | Initial forex rate at position open (InitForexRate). Used for PnL reference. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID (open) | Trade.PositionTbl | Lookup | Live open position data |
| @PositionID (open) | History.Position_Active | Lookup | Recently-archived open position (safety net) |
| @PositionID (open) | History.ExecutedOpenOrders | Lookup | Executed open order for ExecutionTime |
| @PositionID (open) | History.OrderForOpen | Lookup | OpenOccurred timestamp (history) |
| @PositionID (open) | Trade.ExecutedOpenOrders | Lookup | Executed open order for ExecutionTime (live fallback) |
| @PositionID (open) | Trade.OrderForOpen | Lookup | OpenOccurred timestamp (live) |
| @PositionID (closed) | History.Position_Active | Lookup | Closed position primary source |
| @PositionID (closed) | Trade.PositionTbl | Lookup | Recently-closed position (StatusID=2) safety net |
| @PositionID (closed) | History.ExecutedCloseOrders | Lookup | Executed close order for ExecutionTime |
| @PositionID (closed) | History.OrderForClose | Lookup | OpenOccurred timestamp (history) |
| @PositionID (closed) | Trade.ExecutedCloseOrders | Lookup | Executed close order for ExecutionTime (live fallback) |
| @PositionID (closed) | Trade.OrderForClose | Lookup | OpenOccurred timestamp (live) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by allocation processing services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionDataForAllocation (procedure)
|- Trade.PositionTbl (table) - live positions
|- History.Position_Active (table) - archived positions
|- Trade.ExecutedOpenOrders (table) - live open execution records
|- Trade.OrderForOpen (table) - open order timestamps
|- History.ExecutedOpenOrders (table) - archived open execution records
|- History.OrderForOpen (table) - archived open order timestamps
|- Trade.ExecutedCloseOrders (table) - live close execution records
|- Trade.OrderForClose (table) - close order timestamps
|- History.ExecutedCloseOrders (table) - archived close execution records
|- History.OrderForClose (table) - archived close order timestamps
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Open position data (partition-routed) |
| History.Position_Active | Table | Archived/closed position data |
| Trade.ExecutedOpenOrders | Table | ExecutionID for live open timestamp lookup |
| Trade.OrderForOpen | Table | OpenOccurred for live open ExecutionTime |
| History.ExecutedOpenOrders | Table | ExecutionID for history open timestamp lookup |
| History.OrderForOpen | Table | OpenOccurred for history open ExecutionTime |
| Trade.ExecutedCloseOrders | Table | ExecutionID for live close timestamp lookup |
| Trade.OrderForClose | Table | OpenOccurred for live close ExecutionTime |
| History.ExecutedCloseOrders | Table | ExecutionID for history close timestamp lookup |
| History.OrderForClose | Table | OpenOccurred for history close ExecutionTime |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by allocation processing |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET TRAN ISOLATION LEVEL READ UNCOMMITTED | Performance | Dirty read - maximum throughput for allocation lookups |
| PartitionCol = @PositionID%50 | Partition routing | Modulo-50 shard routing for PositionTbl |
| StatusID = 2 (closed mode) | Filter | Only recently-closed positions in live table |
| History-first ISNULL pattern | Reliability | Stable archived timestamps preferred over in-flight live data |
| UNION (not UNION ALL) | Safety | Deduplication if position appears in both live and history |

---

## 8. Sample Queries

### 8.1 Get allocation data for an open position

```sql
EXEC Trade.GetPositionDataForAllocation @PositionID = 987654321, @IsOpen = 1
```

### 8.2 Get allocation data for a closed position

```sql
EXEC Trade.GetPositionDataForAllocation @PositionID = 987654321, @IsOpen = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionDataForAllocation | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionDataForAllocation.sql*
