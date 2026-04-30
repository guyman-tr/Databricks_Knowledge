# Trade.DetachFromParentOrder

> Detaches a child order from its parent order in the copy-trade hierarchy by setting ParentOrderID to 0 in Trade.Orders.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure **breaks the parent-child link** between copy-trade orders. In copy-trading, when a leader places an order, child (copier) orders are created with a ParentOrderID pointing to the leader's order. When a copier needs to stop following a specific order (e.g., the mirror relationship is dissolved), this procedure detaches the child order by setting its ParentOrderID to 0.

Without this procedure, detached copier orders would still reference a parent order that no longer governs them, potentially causing incorrect cascade operations (e.g., the parent closing would incorrectly trigger the child to close).

The procedure optionally looks up the ParentOrderID if not provided, then updates Trade.Orders SET ParentOrderID = 0 (when @ShouldUpdateTradeOrders = 1). It runs in an explicit transaction with XACT_ABORT ON. Error details are returned via @ErrOut OUTPUT parameter.

---

## 2. Business Logic

### 2.1 Parent Order Resolution

**What**: Resolves the parent order if not provided by the caller.

**Columns/Parameters Involved**: `@OrderID`, `@ParentOrderID`, `Trade.Orders.ParentOrderID`

**Rules**:
- If @ParentOrderID = 0 (default): looks up the actual ParentOrderID from Trade.Orders WHERE OrderID = @OrderID
- If @ParentOrderID is provided (non-zero): uses the provided value directly

### 2.2 Conditional Detachment

**What**: Optionally updates the order record to remove the parent link.

**Columns/Parameters Involved**: `@ShouldUpdateTradeOrders`, `Trade.Orders.ParentOrderID`

**Rules**:
- If @ShouldUpdateTradeOrders = 1 (default): UPDATE Trade.Orders SET ParentOrderID = 0 WHERE OrderID = @OrderID
- If @ShouldUpdateTradeOrders = 0: skips the update (caller handles the update externally, e.g., Trade.OrdersClose already detaches as part of closure)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | INT | NO | - | CODE-BACKED | The child order to detach from its parent. |
| 2 | @ParentOrderID | INT | NO | 0 | CODE-BACKED | The parent order ID. If 0 (default), looked up from Trade.Orders. |
| 3 | @ShouldUpdateTradeOrders | TINYINT | NO | 1 | CODE-BACKED | Controls whether Trade.Orders is updated: 1=yes (set ParentOrderID=0), 0=no (caller manages the update). |
| 4 | @ErrOut | NVARCHAR(4000) | YES | '' (OUTPUT) | CODE-BACKED | Error details returned to the caller if the operation fails. Contains ERROR_NUMBER, ERROR_LINE, ERROR_MESSAGE. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.Orders | Read + Write | Reads ParentOrderID, updates ParentOrderID to 0 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Copy-trade detachment flows) | N/A | Caller | Called during mirror/copy-trade disconnection to unlink child orders |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DetachFromParentOrder (procedure)
+-- Trade.Orders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders | Table | SELECT + UPDATE - reads and clears ParentOrderID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo | - | Called from application layer or other detachment procedures |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: Uses XACT_ABORT ON with explicit BEGIN TRAN / COMMIT. Returns 0 on success, ERROR_NUMBER on failure.

---

## 8. Sample Queries

### 8.1 Check parent-child order links

```sql
SELECT  OrderID, ParentOrderID, CID, InstrumentID
FROM    Trade.Orders WITH (NOLOCK)
WHERE   ParentOrderID > 0
ORDER BY ParentOrderID;
```

### 8.2 Find orders with a specific parent

```sql
SELECT  OrderID, CID, InstrumentID, OccurredTime
FROM    Trade.Orders WITH (NOLOCK)
WHERE   ParentOrderID = 54321;
```

### 8.3 Execute the detach

```sql
DECLARE @Err NVARCHAR(4000);
EXEC Trade.DetachFromParentOrder @OrderID = 12345, @ErrOut = @Err OUTPUT;
SELECT @Err AS ErrorOutput;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DetachFromParentOrder | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DetachFromParentOrder.sql*
