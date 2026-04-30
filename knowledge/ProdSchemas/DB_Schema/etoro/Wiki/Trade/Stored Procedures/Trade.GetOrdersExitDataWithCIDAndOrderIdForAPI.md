# Trade.GetOrdersExitDataWithCIDAndOrderIdForAPI

> Returns a single exit order for a specific customer and order ID - API-facing exit order lookup joining Trade.OrdersExit with Trade.Position to provide InstrumentID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID INT + @CID INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersExitDataWithCIDAndOrderIdForAPI` retrieves a single pending exit order from `Trade.OrdersExit` by OrderID and CID. It is the exit-order counterpart to `GetOrdersDataWithCIDAndOrderIdForAPI` (Trade.Orders) and `GetOrdersEntryDataWithCIDAndOrderIdForAPI` (Trade.OrdersEntry).

**WHY:** APIs need to check the current state of a specific pending exit (close) order for a specific customer. The CID filter is a security boundary. The JOIN to Trade.Position is required to provide InstrumentID, which is not stored in Trade.OrdersExit directly.

**HOW:** SELECT from Trade.OrdersExit INNER JOIN Trade.Position WHERE OrderID=@OrderID AND CID=@CID. No ISNULL defaults applied - unlike the entry/standard order API variants, raw values are returned.

---

## 2. Business Logic

### 2.1 Customer Ownership Validation

**What:** The dual filter on OrderID + CID ensures an exit order can only be retrieved if it belongs to the requesting customer.

**Columns/Parameters Involved:** `@OrderID`, `@CID`

**Rules:**
- `WHERE TOE.OrderID = @OrderID AND TOE.CID = @CID` -> returns 0 rows if order belongs to another customer
- Security boundary: CID acts as ownership gate

### 2.2 Position Join Required - InstrumentID Not in OrdersExit

**What:** Trade.OrdersExit does not store InstrumentID. Must JOIN Trade.Position on PositionID to get InstrumentID.

**Rules:**
- `INNER JOIN Trade.Position TP ON TOE.PositionID = TP.PositionID` -> provides InstrumentID
- If the position has been deleted, exit order will not be returned (INNER JOIN)

### 2.3 No ISNULL Defaults

**What:** Unlike the entry/standard order API variants, this SP does NOT apply ISNULL(value, 0) defaults. Raw values including possible NULLs are returned to the API.

**Rules:**
- All output columns returned as-is
- API consumer must handle NULL values for MirrorID, MirrorCloseActionType, OpenActionType, UnitsToDeduct

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | INT | NO | - | CODE-BACKED | The specific exit order ID to retrieve. Combined with @CID for customer ownership validation. |
| 2 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Acts as security filter. |

**Output columns (from Trade.OrdersExit INNER JOIN Trade.Position WHERE OrderID=@OrderID AND CID=@CID):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Exit order ID (matches @OrderID). Sourced from Trade.OrdersExit. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID (matches @CID). Sourced from Trade.OrdersExit. |
| 3 | PositionID | BIGINT | NO | - | CODE-BACKED | The open position being closed. From Trade.OrdersExit.PositionID. |
| 4 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument of the position being closed. Sourced from Trade.Position (not in OrdersExit). |
| 5 | OpenOccurred | DATETIME | YES | - | CODE-BACKED | Timestamp when the exit order was placed. From Trade.OrdersExit. |
| 6 | MirrorID | BIGINT | YES | - | CODE-BACKED | Copy-trade mirror relationship ID if exit is part of a mirror close. NULL for manual closes. |
| 7 | MirrorCloseActionType | INT | YES | - | CODE-BACKED | Close action type for mirror exits. Determines mirror-specific close processing. NULL for non-mirror orders. |
| 8 | OpenActionType | INT | YES | - | CODE-BACKED | The action type that originally opened the position being closed. |
| 9 | UnitsToDeduct | DECIMAL | YES | - | CODE-BACKED | Number of instrument units to close. NULL for amount-based close orders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM Trade.OrdersExit | Trade.OrdersExit | Lookup | Source of pending exit orders |
| INNER JOIN Trade.Position | Trade.Position | Enrichment | Provides InstrumentID not stored in OrdersExit |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrdersExitDataWithCIDAndOrderIdForAPI (procedure)
|- Trade.OrdersExit (table) - pending exit orders
|- Trade.Position (view) - provides InstrumentID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersExit | Table | Single-row lookup by OrderID + CID |
| Trade.Position | View | InstrumentID enrichment via PositionID join |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by trading API for exit order status lookups |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| AND TOE.CID = @CID | Security filter | Ensures customer can only view their own exit orders |
| INNER JOIN Trade.Position | Data requirement | Requires open position to exist; excludes orphaned exit orders |
| No ISNULL defaults | Null handling | Raw values returned; callers must handle NULLs |

---

## 8. Sample Queries

### 8.1 Get a specific exit order for a customer

```sql
EXEC Trade.GetOrdersExitDataWithCIDAndOrderIdForAPI
    @OrderID = 12345678,
    @CID = 87654321
```

### 8.2 Verify exit order exists for customer

```sql
SELECT oe.OrderID, oe.CID, oe.PositionID, p.InstrumentID, oe.OpenOccurred
FROM Trade.OrdersExit oe WITH (NOLOCK)
INNER JOIN Trade.Position p WITH (NOLOCK) ON oe.PositionID = p.PositionID
WHERE oe.OrderID = 12345678 AND oe.CID = 87654321
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9.0/10, Logic: 7.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersExitDataWithCIDAndOrderIdForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersExitDataWithCIDAndOrderIdForAPI.sql*
