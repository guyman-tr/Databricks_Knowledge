# Trade.GetMirrorPartialExitOrdersDataWithCIDAndMirrorIdForSSE

> Returns pending partial-close (exit) order IDs for a customer within a specific mirror where units remain to be deducted, used by the SSE service during mirror detach processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @mirrorId + @cid - scopes to one user's exit orders in one mirror |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMirrorPartialExitOrdersDataWithCIDAndMirrorIdForSSE` retrieves all in-flight partial-close (exit) orders for a specific customer (`@cid`) within a mirror (`@mirrorId`) that still have units remaining to be deducted (`UnitsToDeduct > 0`). These are copy-trade partial close orders that have been submitted but not yet fully executed.

The procedure is part of the SSE mirror detach flow (matching `GetMirrorOrderIdForSSEDetach` for open orders). Before a copier can detach from a mirror, any partial exit orders still in flight must be identified and handled. The `UnitsToDeduct > 0` filter ensures only genuinely pending partial closes are returned - completed exits would have `UnitsToDeduct = 0`.

Data flows: Called by the SSE detach service. Returns a list of `ExitOrderID` values that the caller must cancel or await completion before finalizing the mirror detachment.

---

## 2. Business Logic

### 2.1 Partial Exit Order Identification

**What**: Identifies only truly pending partial close orders for the mirror-customer pair.

**Columns/Parameters Involved**: `@mirrorId`, `@cid`, `UnitsToDeduct`

**Rules**:
- `MirrorID = @mirrorId AND CID = @cid`: Scopes to the specific mirror-user combination.
- `UnitsToDeduct > 0`: Only orders with units still pending deduction. A value of 0 means the partial close is complete; only active/pending orders are relevant during detach.
- Returns `OrderID` aliased as `ExitOrderID` to clarify it is an exit (close) order, not an open order.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @mirrorId | INT | NO | - | CODE-BACKED | The mirror identifier. Filters Trade.OrdersExit to orders associated with this mirror. |
| 2 | @cid | INT | NO | - | CODE-BACKED | The customer ID. Together with @mirrorId, scopes the result to one user's pending exit orders in the mirror. |

**Output columns** (result set):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | ExitOrderID | Trade.OrdersExit.OrderID | The exit order identifier for a pending partial close. Aliased from OrderID to distinguish from open order IDs returned by companion SSE procedures. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @mirrorId + @cid | Trade.OrdersExit | Lookup | Reads partial close orders for the mirror-customer pair where UnitsToDeduct > 0. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorPartialExitOrdersDataWithCIDAndMirrorIdForSSE (procedure)
└── Trade.OrdersExit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersExit | Table | SELECT OrderID WHERE MirrorID + CID match AND UnitsToDeduct > 0 - pending partial close orders |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get pending partial exit orders for a mirror customer

```sql
EXEC Trade.GetMirrorPartialExitOrdersDataWithCIDAndMirrorIdForSSE
    @mirrorId = 12345,
    @cid = 67890;
```

### 8.2 Check pending partial exit orders directly

```sql
SELECT OrderID AS ExitOrderID, UnitsToDeduct, MirrorID, CID
FROM Trade.OrdersExit WITH (NOLOCK)
WHERE MirrorID = 12345
  AND CID = 67890
  AND UnitsToDeduct > 0;
```

### 8.3 Count pending exit orders across all customers in a mirror

```sql
SELECT CID, COUNT(*) AS PendingExitOrders
FROM Trade.OrdersExit WITH (NOLOCK)
WHERE MirrorID = 12345
  AND UnitsToDeduct > 0
GROUP BY CID
ORDER BY PendingExitOrders DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 10/10, Logic: 6/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorPartialExitOrdersDataWithCIDAndMirrorIdForSSE | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorPartialExitOrdersDataWithCIDAndMirrorIdForSSE.sql*
