# Trade.GetOrderForOpenInfo

> Returns two result sets for an open order: (1) order status/type info from Trade+History fallback, (2) positions opened by this order from Trade+History fallback - used to show order fill status across its lifecycle.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID BIGINT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrderForOpenInfo` returns the status of an open order and the positions it produced, using a History-first-then-Trade pattern. Result set 1 shows the order record (with `IsInHistory` flag) from both sources. Result set 2 shows all positions created by this order, also from both sources (open positions in Trade + closed positions in History.PositionSlim).

**WHY:** Used by the UI and back-office to show the full lifecycle of an open order: is it still active, has it been filled, and what positions did it produce? The dual-source design handles orders at any stage - in-flight (only in Trade), completed (in History), or transitioning.

**HOW:** Uses a temp table `#tblOrder` with an `IsInHistory` flag. First inserts from `Trade.OrderForOpen` (IsInHistory=0), then from `History.OrderForOpen` (IsInHistory=1). The CID is extracted from `#tblOrder` for the position query. Result set 2 UNIONs open positions from `Trade.PositionTbl` with closed positions from `History.PositionSlim`.

---

## 2. Business Logic

### 2.1 History-First with Trade Fallback (Dual Source)

**What:** Same pattern as GetOrderForCloseInfo. The ORDER appears in both Trade and History during a transition window - both rows are returned with `IsInHistory` discriminator.

**Rules:**
- Trade.OrderForOpen (IsInHistory=0) -> in-flight orders
- History.OrderForOpen (IsInHistory=1) -> completed/archived orders
- Same OrderID can return 2 rows if transitioning

### 2.2 Result Set 2: Open + Closed Positions

**What:** UNION ALL of:
1. `Trade.PositionTbl WHERE OrderID=@OrderID AND StatusID=1 AND CID=@CID` -> currently open positions
2. `History.PositionSlim WHERE OrderID=@OrderID AND CID=@CID` -> closed positions from this order

**Rules:**
- `StatusID=1` in Trade filter -> open positions only
- History.PositionSlim `OpenOccurred AS CloseOccurred` (actually maps `OpenOccurred` to `CloseOccurred` column position in UNION) -> some columns are aliased differently
- Both results include `IsInHistory` flag: 0 for Trade, 1 for History

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | bigint | NO | - | CODE-BACKED | The open order ID to retrieve. |

**Result Set 1 - Order Info:**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| R1 | OrderID | bigint | NO | CODE-BACKED | Open order ID. |
| R2 | CID | int | NO | CODE-BACKED | Customer who placed the order. |
| R3 | StatusID | int | NO | CODE-BACKED | Current order status. |
| R4 | OrderType | tinyint | YES | CODE-BACKED | Open order type. |
| R5 | OpenActionType | int | YES | CODE-BACKED | Why this position was opened. |
| R6 | OperationType | tinyint | YES | CODE-BACKED | Operation classification. |
| R7 | ErrorCode | int | YES | CODE-BACKED | Error code if failed. |
| R8 | ErrorMessage | nvarchar | YES | CODE-BACKED | Error description. |
| R9 | InstrumentID | int | NO | CODE-BACKED | Instrument being opened. |
| R10 | Amount | money | NO | CODE-BACKED | Order amount. |
| R11 | Units (AmountInUnits) | decimal | YES | CODE-BACKED | Order size in units (aliased as 'Units'). |
| R12 | RequestOccurred | datetime | YES | CODE-BACKED | When the order was placed. |
| R13 | IsInHistory | bit | NO | CODE-BACKED | 0=from Trade.OrderForOpen (active), 1=from History.OrderForOpen (archived). |

**Result Set 2 - Positions Created by This Order:**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| R14 | PositionID | bigint | NO | CODE-BACKED | Position opened by this order. |
| R15 | OrderType | tinyint | YES | CODE-BACKED | Position order type. |
| R16 | Occurred / OpenOccurred | datetime | YES | CODE-BACKED | When the position was created. |
| R17 | Rate (InitForexRate) | money | NO | CODE-BACKED | Entry rate (aliased as 'Rate'). |
| R18 | Units (AmountInUnitsDecimal) | decimal | YES | CODE-BACKED | Position size in units (aliased as 'Units'). |
| R19 | ConversionRate (InitConversionRate) | money | YES | CODE-BACKED | Forex conversion rate at open (aliased as 'ConversionRate'). |
| R20 | Amount | money | NO | CODE-BACKED | Position amount. |
| R21 | IsInHistory | bit | NO | CODE-BACKED | 0=open in Trade, 1=closed in History. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.OrderForOpen | Direct query (RS1 source 1) | Active order lookup |
| @OrderID | History.OrderForOpen | Direct query (RS1 source 2) | Historical order lookup |
| @OrderID + @CID | Trade.PositionTbl | Direct query (RS2 source 1) | Currently open positions |
| @OrderID + @CID | History.PositionSlim | Direct query (RS2 source 2) | Closed positions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Order status display / back-office | N/A | CALLER | Full open order lifecycle status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderForOpenInfo (procedure)
├── Trade.OrderForOpen (table)
├── History.OrderForOpen (table)
├── Trade.PositionTbl (table)
└── History.PositionSlim (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpen | Table | RS1: active order |
| History.OrderForOpen | Table | RS1: archived order |
| Trade.PositionTbl | Table | RS2: open positions by OrderID |
| History.PositionSlim | Table | RS2: closed positions by OrderID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Order lifecycle services / UI | External | Shows open order fill status |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Note:** CID is extracted from `#tblOrder` via `SELECT TOP 1 CID` for use in the position queries. If the order doesn't exist in either source, `@CID` will be NULL and the position queries will return nothing.

**Note:** History.PositionSlim uses `(NOLOCK)` without WITH keyword (old syntax). Trade.PositionTbl uses `(NOLOCK)` without WITH. Trade.OrderForOpen has no hint.

---

## 8. Sample Queries

### 8.1 Get open order lifecycle status
```sql
EXEC Trade.GetOrderForOpenInfo @OrderID = 987654321
```

### 8.2 Manual equivalent - result set 1
```sql
SELECT OrderID, CID, StatusID, OrderType, OpenActionType, OperationType,
       ErrorCode, ErrorMessage, InstrumentID, Amount, AmountInUnits AS Units,
       RequestOccurred, CAST(0 AS BIT) AS IsInHistory
FROM   Trade.OrderForOpen WHERE OrderID = 987654321
UNION ALL
SELECT OrderID, CID, StatusID, OrderType, OpenActionType, OperationType,
       ErrorCode, ErrorMessage, InstrumentID, Amount, AmountInUnits,
       RequestOccurred, CAST(1 AS BIT)
FROM   History.OrderForOpen (NOLOCK) WHERE OrderID = 987654321
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderForOpenInfo | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderForOpenInfo.sql*
