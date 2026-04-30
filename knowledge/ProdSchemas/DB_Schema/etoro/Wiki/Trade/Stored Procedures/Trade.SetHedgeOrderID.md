# Trade.SetHedgeOrderID

> Updates Trade.HedgeRequest.OrderID for a given HedgeID, recording the external hedge order identifier returned by the liquidity provider after order placement.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @HedgeID INTEGER - identifies the hedge request to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When eToro sends a hedge order to a liquidity provider (to offset risk from customer positions), the provider returns an external order identifier. This procedure records that external `OrderID` back into `Trade.HedgeRequest`, linking the internal hedge request to the provider-side order.

This is a critical step in the hedge lifecycle: once `OrderID` is populated, the system can track the hedge order status, confirmations, and fills from the liquidity provider using this identifier.

The procedure is minimal by design - a simple UPDATE with no transaction or complex logic. The caller is responsible for validating that the HedgeID exists and the OrderID is valid before calling. If the HedgeID does not exist, the UPDATE silently affects 0 rows (no error raised).

---

## 2. Business Logic

### 2.1 OrderID Assignment

**What**: Links the internal hedge request to the external provider order.

**Columns/Parameters Involved**: `Trade.HedgeRequest.OrderID`, `Trade.HedgeRequest.HedgeID`

**Rules**:
- UPDATE Trade.HedgeRequest SET OrderID=@OrderID WHERE HedgeID=@HedgeID
- RETURN @@ERROR (legacy pattern; 0 on success)
- No validation - if HedgeID not found, 0 rows affected with no error

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeID | INTEGER | NO | - | CODE-BACKED | The internal hedge request identifier in Trade.HedgeRequest. Identifies which hedge record receives the OrderID. |
| 2 | @OrderID | VARCHAR(50) | NO | - | CODE-BACKED | The external order identifier returned by the liquidity provider after the hedge order was placed. Stored in HedgeRequest.OrderID for subsequent tracking and reconciliation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE | Trade.HedgeRequest | Modifier | Sets OrderID for the specified HedgeID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - called by hedge execution service after receiving order confirmation from liquidity provider.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SetHedgeOrderID (procedure)
|- Trade.HedgeRequest (table - update target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.HedgeRequest | Table | UPDATE target - OrderID is written to link internal request to provider order |

### 6.2 Objects That Depend On This

No dependents found - called by hedge execution service.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No existence check | Logic | Silent 0-row update if HedgeID not found - no RAISERROR |
| Legacy error return | Pattern | RETURN @@ERROR - returns 0 on success, error number on failure |

---

## 8. Sample Queries

### 8.1 Set the provider order ID for a hedge request

```sql
EXEC Trade.SetHedgeOrderID
    @HedgeID = 999,
    @OrderID = 'PROV-ORD-12345678'
```

### 8.2 Verify the update

```sql
SELECT HedgeID, OrderID, InstrumentID, Amount, Direction
FROM Trade.HedgeRequest WITH (NOLOCK)
WHERE HedgeID = 999
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SetHedgeOrderID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SetHedgeOrderID.sql*
