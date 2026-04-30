# Trade.GetOrderForCloseInfo

> Returns two-result-set close order status info: (1) the order with instrument currency details from History+Trade fallback, (2) filled positions plus still-pending plan positions - used to display close order status including partial fills.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID BIGINT + @CID INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrderForCloseInfo` returns the status of a close order for display or audit purposes. It provides: (1) the order record with the instrument's sell currency, sourced from History first and falling back to the active Trade table; (2) the positions associated with this order - already-filled positions (with P&L details) and still-pending plan entries (units allocated but not yet executed).

**WHY:** Used by the UI and back-office tools to show close order status: was it fully filled, partially filled, or pending? The dual-source lookup (History -> Trade fallback) handles orders that are still in-flight (not yet in History) as well as completed orders.

**HOW:** Uses a temp table `#tblOrder` to first try `History.OrderForClose` (for completed orders), then inserts from `Trade.OrderForClose` for orders still active. Then selects the merged result joined to `Trade.Instrument` for the sell currency. Result set 2 unions `History.PositionSlim` (filled positions with full P&L) with `Trade.CloseExecutionPlan` (pending plan entries without P&L data).

---

## 2. Business Logic

### 2.1 History-First with Active-Trade Fallback

**What:** The SP first tries History (completed orders), then adds rows from Trade (active orders). Because both use INSERT into `#tblOrder`, the same OrderID can appear twice if it exists in both. The SELECT deduplicates by showing all rows (caller expected to handle).

**Columns/Parameters Involved:** `#tblOrder.OrderID`, `History.OrderForClose`, `Trade.OrderForClose`

**Rules:**
- First INSERT: `History.OrderForClose WHERE OrderID=@OrderID AND CID=@CID` -> completed orders
- Second INSERT: `Trade.OrderForClose WHERE OrderID=@OrderID AND CID=@CID` -> active orders
- If order exists in both (transition state): both rows are in `#tblOrder` (no deduplication)

### 2.2 Result Set 2: Filled vs Pending Positions

**What:** UNION ALL of:
1. `History.PositionSlim`: positions that were actually closed by this order (with full P&L data)
2. `Trade.CloseExecutionPlan`: positions still in the plan but not yet executed (no P&L, all money columns cast to NULL)

**Rules:**
- History.PositionSlim `WHERE CID=@CID AND ExitOrderID=@OrderID` -> positions already closed
- Trade.CloseExecutionPlan `WHERE CID=@CID AND OrderID=@OrderID` -> positions still pending execution
- NULL casts for CloseExecutionPlan money columns indicate no settlement data yet

### 2.3 Instrument Currency Enrichment

**What:** JOIN to `Trade.Instrument` on `ofc.InstrumentID` returns `SellCurrencyID` - the currency in which the position is denominated for settlement purposes.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | bigint | NO | - | CODE-BACKED | The close order ID to retrieve. |
| 2 | @CID | int | NO | - | CODE-BACKED | Customer ID. Scopes all queries to this customer's data. |

**Result Set 1 - Close Order with Currency:**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| R1 | OrderID | bigint | NO | CODE-BACKED | Close order ID. |
| R2 | CID | int | NO | CODE-BACKED | Customer ID. |
| R3 | StatusID | int | NO | CODE-BACKED | Order status. |
| R4 | OrderType | tinyint | YES | CODE-BACKED | Close order type. |
| R5 | OrderCloseActionType | tinyint | YES | CODE-BACKED | Why this position was closed. |
| R6 | OperationType | tinyint | YES | CODE-BACKED | Operation classification. |
| R7 | ErrorCode | int | YES | CODE-BACKED | Error code if close failed. |
| R8 | ErrorMessage | nvarchar | YES | CODE-BACKED | Error description if failed. |
| R9 | InstrumentID | int | NO | CODE-BACKED | Instrument that was closed. |
| R10 | RequestOccurred | datetime | YES | CODE-BACKED | When the close was requested. |
| R11 | SellCurrencyID | int | YES | CODE-BACKED | Currency ID for selling (from Trade.Instrument). Used for P&L settlement conversion. |

**Result Set 2 - Positions (Filled + Pending):**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| R12 | PositionID | bigint | NO | CODE-BACKED | Position ID. From History (filled) or CloseExecutionPlan (pending). |
| R13 | CloseOccurred | datetime | YES | CODE-BACKED | When the position was closed. NULL for pending plan entries. |
| R14 | EndForexRate | money | YES | CODE-BACKED | Exit rate. NULL for pending. |
| R15 | AmountInUnitsDecimal | decimal | YES | CODE-BACKED | Units at close. NULL for pending. |
| R16 | Amount | money | YES | CODE-BACKED | Amount at close. NULL for pending. |
| R17 | InitConversionRate | money | YES | CODE-BACKED | Forex conversion rate at open. NULL for pending. |
| R18 | NetProfit | money | YES | CODE-BACKED | Net P&L. NULL for pending (not yet realized). |
| R19 | CloseTotalFees | money | YES | CODE-BACKED | Total fees at close. NULL for pending. |
| R20 | CloseTotalTaxes | money | YES | CODE-BACKED | Total taxes at close. NULL for pending. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID + @CID | History.OrderForClose | Direct query (RS1 source 1) | History order lookup |
| @OrderID + @CID | Trade.OrderForClose | Direct query (RS1 source 2) | Active order fallback |
| #tblOrder.InstrumentID | Trade.Instrument | INNER JOIN (RS1) | Get SellCurrencyID |
| @CID + @OrderID | History.PositionSlim | Direct query (RS2 source 1) | Filled positions with P&L |
| @CID + @OrderID | Trade.CloseExecutionPlan | Direct query (RS2 source 2) | Pending plan positions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Close order status display / back-office | N/A | CALLER | Shows order fill status including partial fills |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderForCloseInfo (procedure)
├── History.OrderForClose (table)
├── Trade.OrderForClose (table)
├── Trade.Instrument (table)
├── History.PositionSlim (table)
└── Trade.CloseExecutionPlan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.OrderForClose | Table | RS1: completed order lookup |
| Trade.OrderForClose | Table | RS1: active order fallback |
| Trade.Instrument | Table | RS1: SellCurrencyID enrichment |
| History.PositionSlim | Table | RS2: filled positions with P&L |
| Trade.CloseExecutionPlan | Table | RS2: pending plan positions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Order status services / UI | External | Close order status display with fill progress |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Note:** Uses a temp table `#tblOrder` rather than a CTE/UNION to allow the two-step INSERT pattern. `History.OrderForClose` uses `with(nolock)`, `Trade.OrderForClose` does NOT use NOLOCK (consistent read for active orders).

---

## 8. Sample Queries

### 8.1 Get close order info
```sql
EXEC Trade.GetOrderForCloseInfo @OrderID = 987654321, @CID = 9876543
```

### 8.2 Manual equivalent - result set 1
```sql
SELECT ofc.*, i.SellCurrencyID
FROM   (
    SELECT OrderID, CID, StatusID, OrderType, OrderCloseActionType, OperationType, ErrorCode, ErrorMessage, InstrumentID, RequestOccurred
    FROM   History.OrderForClose WITH(NOLOCK) WHERE OrderID = 987654321 AND CID = 9876543
    UNION ALL
    SELECT OrderID, CID, StatusID, OrderType, OrderCloseActionType, OperationType, ErrorCode, ErrorMessage, InstrumentID, RequestOccurred
    FROM   Trade.OrderForClose WHERE OrderID = 987654321 AND CID = 9876543
) ofc
INNER JOIN Trade.Instrument i ON ofc.InstrumentID = i.InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderForCloseInfo | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderForCloseInfo.sql*
