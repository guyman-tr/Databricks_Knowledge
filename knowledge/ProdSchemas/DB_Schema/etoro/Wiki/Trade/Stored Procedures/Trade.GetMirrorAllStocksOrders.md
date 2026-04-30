# Trade.GetMirrorAllStocksOrders

> Returns all stock orders associated with a specific CopyTrader mirror relationship, including their entry/exit status.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: OrderID, MirrorID, PositionID, IsEntry |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMirrorAllStocksOrders retrieves all stock orders belonging to a specific CopyTrader mirror relationship. In eToro's CopyTrader feature, when a copier mirrors a trader, stock orders are created in Stocks.Orders. This procedure returns all orders for a given MirrorID, showing which are entry orders (opening positions) and which are exit orders (closing positions).

This procedure exists to support CopyTrader stock order auditing and reconciliation. When a mirror relationship is being closed or reviewed, the system needs to identify all associated stock orders. The Stocks schema is separate from the Trade schema, reflecting that stock orders have different processing from CFD orders.

Called by PROD_BIadmins for analytics.

---

## 2. Business Logic

### 2.1 Mirror Stock Order Lookup

**What**: Simple filter on Stocks.Orders by MirrorID to get all stock orders for a copy relationship.

**Columns/Parameters Involved**: `@MirrorID`, `Stocks.Orders`

**Rules**:
- Filters Stocks.Orders by MirrorID
- MirrorID and PositionID are ISNULL-coalesced to 0 to avoid NULLs in output
- IsEntry flag: 1=entry order (opens a position), 0=exit order (closes a position)
- Returns all orders regardless of status

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @MirrorID | int | IN | - | CODE-BACKED | The CopyTrader mirror relationship ID to look up stock orders for. |

### 4.2 Result Set

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | OrderID | bigint | NO | CODE-BACKED | Unique stock order identifier from Stocks.Orders. |
| 2 | MirrorID | int | NO | CODE-BACKED | The mirror relationship ID. ISNULL coalesced to 0. |
| 3 | PositionID | bigint | NO | CODE-BACKED | Associated position ID. ISNULL coalesced to 0 (0 means order hasn't been matched to a position yet). |
| 4 | IsEntry | bit | NO | CODE-BACKED | 1=entry order (opening a position), 0=exit order (closing a position). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Stocks.Orders | SELECT (READER) | Reads stock orders filtered by MirrorID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | GRANT EXECUTE | Application User | BI analytics |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorAllStocksOrders (procedure)
+-- Stocks.Orders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Stocks.Orders | Table | SELECT orders by MirrorID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | Application User | Analytics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all stock orders for a mirror

```sql
EXEC Trade.GetMirrorAllStocksOrders @MirrorID = 12345;
```

### 8.2 Check stock orders with entry/exit breakdown

```sql
SELECT  MirrorID,
        SUM(CASE WHEN IsEntry = 1 THEN 1 ELSE 0 END) AS EntryOrders,
        SUM(CASE WHEN IsEntry = 0 THEN 1 ELSE 0 END) AS ExitOrders,
        COUNT(*) AS TotalOrders
FROM    Stocks.Orders WITH (NOLOCK)
WHERE   MirrorID = 12345
GROUP BY MirrorID;
```

### 8.3 Find mirrors with unmatched stock orders

```sql
SELECT  MirrorID,
        COUNT(*) AS UnmatchedOrders
FROM    Stocks.Orders WITH (NOLOCK)
WHERE   PositionID IS NULL
        OR PositionID = 0
GROUP BY MirrorID
ORDER BY UnmatchedOrders DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorAllStocksOrders | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorAllStocksOrders.sql*
