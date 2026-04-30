# Trade.GetAccountAssets

> Returns all trading assets (positions, orders, mirrors) for a customer account across six result sets.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 6 result sets covering all account asset types |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves a comprehensive snapshot of all trading assets held by a customer. It returns six separate result sets covering manual positions, pending exit orders (regular and async), manual entry orders, all orders, CopyTrader mirrors, and async entry orders waiting for market. Together, these result sets provide a complete picture of a customer's active trading state.

The procedure exists to serve account-level asset queries where the caller needs every type of trading object associated with a customer. This is typically used by portfolio management, risk calculation, or account overview features that need the full picture of a customer's exposure.

Data flows from multiple Trade schema tables - Trade.Position (view) for open positions, Trade.OrdersExit plus Trade.OrderForClose/Trade.CloseExecutionPlan for exit orders in both regular and async execution modes, Trade.OrdersEntry for pending entry orders, Trade.Orders for general orders, Trade.Mirror for CopyTrader relationships, and Trade.OrderForOpen for async entry orders.

---

## 2. Business Logic

### 2.1 Multi-Result-Set Account Snapshot

**What**: The procedure returns six distinct result sets, each covering a different asset type.

**Columns/Parameters Involved**: `@CID`, various tables

**Rules**:
- Result Set 1: Manual positions (ParentPositionID = 0 filters out copy positions - only top-level manual)
- Result Set 2: Pending exit orders from both regular (Trade.OrdersExit) and async (Trade.OrderForClose with StatusID=11 "Waiting for Market") mechanisms via UNION ALL
- Result Set 3: Manual entry orders (MirrorID = 0 excludes copy-initiated orders)
- Result Set 4: All orders for the customer
- Result Set 5: CopyTrader mirrors with active status
- Result Set 6: Async manual entry orders waiting for market (StatusID=11, MirrorID=0)

### 2.2 Async Execution Model

**What**: The procedure accounts for both regular (synchronous) and async execution paths for orders.

**Columns/Parameters Involved**: `StatusID`, `Trade.OrderForClose`, `Trade.OrderForOpen`

**Rules**:
- StatusID = 11 represents "Waiting for Market" status
- Async close orders go through Trade.OrderForClose -> Trade.CloseExecutionPlan pipeline (Level=0 for root entries)
- Async open orders go through Trade.OrderForOpen
- Both async paths are included to provide a complete view alongside regular orders

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to retrieve all assets for. |

**Result Set 1 - Manual Positions:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | PositionID | BIGINT | NO | - | CODE-BACKED | Unique identifier of the open manual position. |
| 3 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument of the position. |

**Result Set 2 - Pending Exit Orders (regular + async):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | PositionID | BIGINT | NO | - | CODE-BACKED | Position being closed by a pending exit order. |

**Result Set 3 - Manual Entry Orders:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 5 | OrderID | BIGINT | NO | - | CODE-BACKED | Pending manual entry order (open order waiting to be filled). |

**Result Set 4 - All Orders:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 6 | OrderID | BIGINT | NO | - | CODE-BACKED | Any order for the customer from Trade.Orders. |

**Result Set 5 - Mirrors:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 7 | MirrorID | BIGINT | NO | - | CODE-BACKED | CopyTrader mirror relationship ID. |
| 8 | IsActive | BIT | NO | - | CODE-BACKED | Whether the mirror (copy) relationship is currently active. |

**Result Set 6 - Async Entry Orders Waiting for Market:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 9 | OrderID | BIGINT | NO | - | CODE-BACKED | Async entry order waiting for market opening (StatusID=11, manual only). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM RS1 | Trade.Position | Direct Read (View) | Reads open manual positions |
| FROM RS2 | Trade.OrdersExit | Direct Read | Reads pending regular exit orders |
| JOIN RS2 | Trade.OrderForClose | Direct Read | Reads async close orders |
| JOIN RS2 | Trade.CloseExecutionPlan | Direct Read | Reads close execution plan entries (Level=0) |
| FROM RS3 | Trade.OrdersEntry | Direct Read | Reads manual entry orders |
| FROM RS4 | Trade.Orders | Direct Read | Reads all customer orders |
| FROM RS5 | Trade.Mirror | Direct Read | Reads CopyTrader mirror relationships |
| FROM RS6 | Trade.OrderForOpen | Direct Read | Reads async entry orders waiting for market |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAccountAssets (procedure)
├── Trade.Position (view)
├── Trade.OrdersExit (table)
├── Trade.OrderForClose (table)
├── Trade.CloseExecutionPlan (table)
├── Trade.OrdersEntry (table)
├── Trade.Orders (table)
├── Trade.Mirror (table)
└── Trade.OrderForOpen (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT - manual positions |
| Trade.OrdersExit | Table | SELECT - regular exit orders |
| Trade.OrderForClose | Table | INNER JOIN - async close orders |
| Trade.CloseExecutionPlan | Table | INNER JOIN - async close execution plan |
| Trade.OrdersEntry | Table | SELECT - manual entry orders |
| Trade.Orders | Table | SELECT - all orders |
| Trade.Mirror | Table | SELECT - CopyTrader mirrors |
| Trade.OrderForOpen | Table | SELECT - async entry orders |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all account assets for a customer

```sql
EXEC Trade.GetAccountAssets @CID = 12345678;
```

### 8.2 Check open manual positions for a customer

```sql
SELECT  TP.PositionID,
        TP.InstrumentID
FROM    Trade.Position TP WITH (NOLOCK)
WHERE   TP.CID = 12345678
    AND TP.ParentPositionID = 0;
```

### 8.3 Check pending async close orders for a customer

```sql
SELECT  cep.PositionID,
        ofc.OrderID,
        ofc.StatusID
FROM    Trade.OrderForClose ofc WITH (NOLOCK)
INNER JOIN Trade.CloseExecutionPlan cep WITH (NOLOCK)
    ON ofc.OrderID = cep.OrderID
WHERE   cep.Level = 0
    AND ofc.CID = 12345678
    AND ofc.StatusID = 11;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAccountAssets | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAccountAssets.sql*
