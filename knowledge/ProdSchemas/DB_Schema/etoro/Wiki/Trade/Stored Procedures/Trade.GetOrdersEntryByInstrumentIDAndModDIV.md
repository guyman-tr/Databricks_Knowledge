# Trade.GetOrdersEntryByInstrumentIDAndModDIV

> Returns pending entry orders from Trade.OrdersEntry for a single instrument with modulo-based sharding - the single-instrument predecessor to the TVP-based OME entry order matching SPs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID INT + @ModDivider INT + @ModResult INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersEntryByInstrumentIDAndModDIV` retrieves pending entry orders from `Trade.OrdersEntry` for a single instrument, filtered by modulo sharding. It is the single-instrument predecessor to `GetOrderMatchingItemsByInstrumentID_EntryOrders` (TVP-based) and the entry-order counterpart to `GetOrdersByInstrumentIDAndModDIV` (which reads Trade.Orders).

**NOTE - SSDT Anomaly:** The procedure name contains a trailing space: `[Trade].[GetOrdersEntryByInstrumentIDAndModDIV ]`. This is an SSDT artifact. The actual SQL Server procedure object name is `GetOrdersEntryByInstrumentIDAndModDIV ` (with trailing space). Callers must use the exact name including the space.

**WHY:** Used by older OME instances that retrieve entry orders per-instrument rather than in batches. The modulo sharding distributes the work across multiple OME instances.

**HOW:** Direct query on Trade.OrdersEntry with InstrumentID filter and modulo shard filter. Returns a subset of entry order fields (no IsTslEnabled, AmountInUnitsDecimal, or SettlementTypeID compared to newer SPs).

---

## 2. Business Logic

### 2.1 Modulo Sharding for OME Instances

**What:** Same modulo sharding pattern as `GetOrdersByInstrumentIDAndModDIV` - each OME instance handles a bucket of OrderIDs.

**Columns/Parameters Involved:** `@ModDivider`, `@ModResult`

**Rules:**
- `WHERE o.OrderID % @ModDivider = @ModResult` -> this OME shard's entry orders for this instrument
- No ParentOrderID filter (unlike Orders SP - entry orders don't have a parent hierarchy)

### 2.2 Older Column Set (Pre-Free Stocks)

**What:** This SP does NOT include IsTslEnabled, AmountInUnitsDecimal, IsDiscounted, or SettlementTypeID. It predates the Free Stocks feature (FB 53719, 2019) and was not updated.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Single instrument to retrieve entry orders for. |
| 2 | @ModDivider | INT | NO | - | CODE-BACKED | Total number of OME shards for modulo partitioning. |
| 3 | @ModResult | INT | NO | - | CODE-BACKED | This OME shard's remainder value. |

**Output columns (from Trade.OrdersEntry):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Entry order ID. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 3 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument being ordered (equals @InstrumentID). |
| 4 | Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier. |
| 5 | Amount | DECIMAL | NO | - | CODE-BACKED | Order amount. Note: Trade.OrdersEntry stores Amount in the base currency directly (unlike Trade.Orders which stores in cents). No /100 conversion applied. |
| 6 | IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. |
| 7 | StopLosPercentage | DECIMAL | YES | - | CODE-BACKED | Stop-loss threshold as percentage of amount. |
| 8 | TakeProfitPercentage | DECIMAL | YES | - | CODE-BACKED | Take-profit threshold as percentage of amount. |
| 9 | Occurred | DATETIME | NO | - | CODE-BACKED | Entry order placement timestamp. |
| 10 | ParentPositionID | BIGINT | YES | - | CODE-BACKED | For copy-trade orders: the leader's position being copied. NULL for manual orders. |
| 11 | MirrorID | BIGINT | YES | - | CODE-BACKED | Copy-trade mirror relationship ID. NULL for manual orders. |
| 12 | InitialMirrorAmountInCents | INT | YES | - | CODE-BACKED | Initial copy amount in cents for mirror orders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM Trade.OrdersEntry | Trade.OrdersEntry | Lookup | Source of pending entry orders |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrdersEntryByInstrumentIDAndModDIV (procedure)
|- Trade.OrdersEntry (view) - pending entry orders
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersEntry | View | Single-instrument query with modulo shard filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by older OME application code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Trailing space in procedure name | SSDT anomaly | Procedure is created as `[Trade].[GetOrdersEntryByInstrumentIDAndModDIV ]` (with trailing space). Callers must use exact name with space. |

---

## 8. Sample Queries

### 8.1 Execute for Bitcoin, OME shard 0 of 4

```sql
-- Note: procedure name has trailing space
EXEC [Trade].[GetOrdersEntryByInstrumentIDAndModDIV ]
    @InstrumentID = 1,
    @ModDivider = 4,
    @ModResult = 0
```

### 8.2 View pending entry orders for an instrument

```sql
SELECT TOP 10
    OrderID, CID, InstrumentID, Amount, IsBuy, Occurred
FROM Trade.OrdersEntry WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY Occurred DESC
```

### 8.3 Modulo shard preview

```sql
SELECT TOP 10 OrderID, CID, InstrumentID
FROM Trade.OrdersEntry WITH (NOLOCK)
WHERE InstrumentID = 1 AND OrderID % 4 = 0
ORDER BY OrderID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9.5/10, Logic: 6.5/10, Relationships: 5.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersEntryByInstrumentIDAndModDIV (trailing space) | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersEntryByInstrumentIDAndModDIV .sql*
