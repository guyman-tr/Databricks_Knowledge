# Trade.GetOrdersExitDataWithCIDForAPI

> Returns all pending exit orders for a customer - the bulk counterpart to GetOrdersExitDataWithCIDAndOrderIdForAPI. Joins Trade.OrdersExit with Trade.Position to provide InstrumentID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersExitDataWithCIDForAPI` retrieves all pending exit orders from `Trade.OrdersExit` for a given customer ID. It is the bulk counterpart to `GetOrdersExitDataWithCIDAndOrderIdForAPI` - returning ALL of a customer's pending exit (close) orders rather than a specific one.

**WHY:** APIs need to display a customer's full pending exit order list. This SP provides that data by joining Trade.OrdersExit with Trade.Position to include InstrumentID (not stored in OrdersExit directly).

**HOW:** SELECT from Trade.OrdersExit INNER JOIN Trade.Position WHERE CID=@CID. Identical output schema to `GetOrdersExitDataWithCIDAndOrderIdForAPI`. Comment in DDL labels this "exit order repository (#3)".

---

## 2. Business Logic

### 2.1 All Exit Orders for Customer - No Status Filter

**What:** Returns all Trade.OrdersExit rows for the customer without status filtering.

**Columns/Parameters Involved:** `@CID`

**Rules:**
- `WHERE TOE.CID = @CID` -> all pending exit orders for this customer

### 2.2 Position Join for InstrumentID

**What:** Trade.OrdersExit does not store InstrumentID. JOIN to Trade.Position is required.

**Rules:**
- `INNER JOIN Trade.Position TP ON TOE.PositionID = TP.PositionID` -> provides InstrumentID
- INNER JOIN means exit orders without a matching open position are excluded

### 2.3 No ISNULL Defaults

**What:** Raw values returned without null-safe defaults. API consumer must handle NULLs.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose exit orders to retrieve. All pending exit orders for this customer are returned. |

**Output columns (from Trade.OrdersExit INNER JOIN Trade.Position WHERE CID=@CID) - identical to GetOrdersExitDataWithCIDAndOrderIdForAPI:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Exit order ID. From Trade.OrdersExit. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID (equals @CID). From Trade.OrdersExit. |
| 3 | PositionID | BIGINT | NO | - | CODE-BACKED | The open position being closed. From Trade.OrdersExit. |
| 4 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument of the position being closed. From Trade.Position. |
| 5 | OpenOccurred | DATETIME | YES | - | CODE-BACKED | Timestamp when the exit order was placed. From Trade.OrdersExit. |
| 6 | MirrorID | BIGINT | YES | - | CODE-BACKED | Copy-trade mirror relationship ID. NULL for manual closes. |
| 7 | MirrorCloseActionType | INT | YES | - | CODE-BACKED | Close action type for mirror exits. NULL for non-mirror orders. |
| 8 | OpenActionType | INT | YES | - | CODE-BACKED | Action type that originally opened the position being closed. |
| 9 | UnitsToDeduct | DECIMAL | YES | - | CODE-BACKED | Number of instrument units to close. NULL for amount-based close orders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM Trade.OrdersExit | Trade.OrdersExit | Lookup | Source of all pending exit orders for the customer |
| INNER JOIN Trade.Position | Trade.Position | Enrichment | Provides InstrumentID for each exit order's position |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrdersExitDataWithCIDForAPI (procedure)
|- Trade.OrdersExit (table) - pending exit orders
|- Trade.Position (view) - provides InstrumentID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersExit | Table | All exit orders for @CID |
| Trade.Position | View | InstrumentID enrichment via PositionID join |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by trading API for customer exit order book display |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOIN Trade.Position | Data requirement | Excludes exit orders with no open position |
| No ISNULL defaults | Null handling | Raw values returned; callers must handle NULLs |

---

## 8. Sample Queries

### 8.1 Get all exit orders for a customer

```sql
EXEC Trade.GetOrdersExitDataWithCIDForAPI
    @CID = 87654321
```

### 8.2 Get a specific exit order (use CID+OrderId variant)

```sql
EXEC Trade.GetOrdersExitDataWithCIDAndOrderIdForAPI
    @OrderID = 12345678,
    @CID = 87654321
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9.0/10, Logic: 6.5/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersExitDataWithCIDForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersExitDataWithCIDForAPI.sql*
