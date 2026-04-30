# Trade.GetOrdersEntryForMirror

> Returns all pending entry orders for a given copy-trade mirror relationship from Trade.OrdersEntry - used by mirror processing to find all pending entry orders belonging to a mirror.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersEntryForMirror` retrieves all pending entry orders from `Trade.OrdersEntry` for a given MirrorID. It is the mirror-context entry order lookup - returning all orders that were placed as part of a specific copy-trade mirror relationship.

**WHY:** Copy-trade mirror processing needs to find all pending entry orders belonging to a mirror when performing mirror lifecycle operations (e.g., closing/pausing a mirror, reconciling mirror state). By filtering on MirrorID, this SP isolates the entry orders that belong to a specific follower-leader mirror relationship.

**HOW:** Simple SELECT from Trade.OrdersEntry WHERE MirrorID=@MirrorID. Uses older column set without IsTslEnabled, AmountInUnitsDecimal, IsDiscounted, or OrderTypeID. No ISNULL defaults applied - raw values returned. SET NOCOUNT ON suppresses row count.

---

## 2. Business Logic

### 2.1 Mirror Entry Order Retrieval

**What:** Filters Trade.OrdersEntry by MirrorID to return all entry orders placed for a specific copy-trade relationship.

**Columns/Parameters Involved:** `@MirrorID`, `MirrorID`

**Rules:**
- `WHERE MirrorID = @MirrorID` -> returns all pending entry orders for this mirror
- 0 rows returned if mirror has no pending entry orders (queue empty for this mirror)
- Results are unordered - callers must ORDER BY if sequence matters

### 2.2 Older Column Set - Pre-Free Stocks

**What:** This SP uses the original entry order column set from before the Free Stocks feature. It does NOT include IsTslEnabled (FB 47233 2017), AmountInUnitsDecimal (FB 47233 2017), IsDiscounted (FB 53719 2019), or OrderTypeID.

**Rules:**
- Missing columns: IsTslEnabled, AmountInUnitsDecimal, IsDiscounted, OrderTypeID
- Amount is returned as-is (dollars, no /100 conversion) - consistent with Trade.OrdersEntry storage
- No ISNULL defaults applied - raw NULL values passed to caller

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | The mirror relationship ID to filter by. Returns all pending entry orders for this copy-trade mirror. |

**Output columns (from Trade.OrdersEntry WHERE MirrorID=@MirrorID):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Entry order ID. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID (the follower/copier). Raw value - no ISNULL default. |
| 3 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument being ordered. Raw value - no ISNULL default. |
| 4 | Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier. Raw value. |
| 5 | Amount | DECIMAL | NO | - | CODE-BACKED | Entry order amount in base currency (dollars). Raw value. NOT divided by 100. |
| 6 | IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. Raw value. |
| 7 | StopLosPercentage | DECIMAL | YES | - | CODE-BACKED | Stop-loss threshold as percentage. May be NULL. |
| 8 | TakeProfitPercentage | DECIMAL | YES | - | CODE-BACKED | Take-profit threshold as percentage. May be NULL. |
| 9 | Occurred | DATETIME | NO | - | CODE-BACKED | Entry order placement timestamp. |
| 10 | ParentPositionID | BIGINT | YES | - | CODE-BACKED | The leader's position being copied. NULL for non-copy-trade orders (but all rows should have this set given the MirrorID filter). |
| 11 | MirrorID | BIGINT | YES | - | CODE-BACKED | Copy-trade mirror relationship ID. Equals @MirrorID for all returned rows. |
| 12 | InitialMirrorAmountInCents | INT | YES | - | CODE-BACKED | Initial copy amount in cents for this mirror order. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM Trade.OrdersEntry | Trade.OrdersEntry | Lookup | Source of pending entry orders filtered by MirrorID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrdersEntryForMirror (procedure)
|- Trade.OrdersEntry (view) - pending entry orders
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersEntry | View | All pending entry orders for @MirrorID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by mirror management/copy-trade application code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row count messages |
| Older column set | Column scope | Does not include IsTslEnabled, AmountInUnitsDecimal, IsDiscounted, OrderTypeID |
| No ISNULL defaults | Null handling | Raw values returned - callers must handle NULLs |

---

## 8. Sample Queries

### 8.1 Get all pending entry orders for a mirror

```sql
EXEC Trade.GetOrdersEntryForMirror
    @MirrorID = 123456
```

### 8.2 Verify directly on Trade.OrdersEntry

```sql
SELECT OrderID, CID, InstrumentID, Amount, IsBuy, MirrorID, Occurred
FROM Trade.OrdersEntry WITH (NOLOCK)
WHERE MirrorID = 123456
ORDER BY Occurred ASC
```

### 8.3 Count pending entry orders per mirror

```sql
SELECT MirrorID, COUNT(*) AS PendingEntryOrders
FROM Trade.OrdersEntry WITH (NOLOCK)
WHERE MirrorID IS NOT NULL
GROUP BY MirrorID
ORDER BY PendingEntryOrders DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9.0/10, Logic: 7.0/10, Relationships: 5.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersEntryForMirror | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersEntryForMirror.sql*
