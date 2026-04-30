# Trade.FunUnRegisterMirrorMot

> Returns 1 if there are non-terminal open orders for the given customer and mirror in the MOT (Market Order Table) context; used to block unregister until orders are resolved.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns INT (1=has blocking orders, 0=none) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FunUnRegisterMirrorMot determines whether a customer has outstanding non-terminal open orders tied to a specific CopyTrader mirror. In the MOT (Market Order Table) flow, when a user requests to unregister from a copy relationship, the system must first ensure no open orders are still in-flight. If orders exist with StatusID where IsTerminal=0, unregister must be blocked until those orders are resolved (filled or canceled).

This function exists to prevent data inconsistency: unregistering while orders are pending could orphan order references or create mismatched positions. Trade.UnRegisterMirrorForMoe calls it with the customer and mirror IDs; when the result is 1, unregister is deferred.

Data flow: Trade.UnRegisterMirrorForMoe calls `Trade.FunUnRegisterMirrorMot(@CID,@MirrorID)` before allowing unregister. The function looks up Trade.OpenExecutionPlan joined to Trade.OrderForOpen and Trade.ExecutedOpenOrders to find orders for the mirror where no PositionID has been created yet (eo.PositionID IS NULL) and the order status is not terminal.

---

## 2. Business Logic

### 2.1 MOT (Market Order Table) Blocking Gate

**What**: Prevents CopyTrader unregister while orders for the mirror are still in execution.

**Columns/Parameters Involved**: `@CID`, `@MirrorID`, `OrderForOpen.StatusID`, `ExecutedOpenOrders.PositionID`

**Rules**:
- Returns 1 if EXISTS non-terminal open orders for (CID, MirrorID) with no PositionID yet
- Returns 0 (or NULL converted to 0) if no blocking orders
- Dictionary.OrderForExecutionStatus.IsTerminal=0 means order is still in progress

**Diagram**:
```
OpenExecutionPlan (ep) -> OrderForOpen (ofo) -> OrderForExecutionStatus (dofe)
                           |
                           v
                    ExecutedOpenOrders (eo)
                    eo.PositionID IS NULL = order not yet filled
                    dofe.IsTerminal = 0 = order not finished
                    => Block unregister
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID. The copier who wants to unregister. Filter on ep.CID. |
| 2 | @MirrorID | int | NO | - | CODE-BACKED | Mirror ID. The copy relationship (Trade.Mirror). Filter on ep.MirrorID. |
| 3 | (Return) | int | NO | - | CODE-BACKED | 1 = blocking orders exist (unregister blocked); 0 = no blocking orders (unregister allowed). ISNULL(@IsExists, 0). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | Implicit | Copier customer |
| @MirrorID | Trade.Mirror | Implicit | Copy relationship to check |
| OpenExecutionPlan | Trade.OpenExecutionPlan | JOIN | Execution plan for open orders |
| OrderForOpen | Trade.OrderForOpen | JOIN | Open order details |
| OrderForExecutionStatus | Dictionary.OrderForExecutionStatus | Lookup | IsTerminal flag |
| ExecutedOpenOrders | Trade.ExecutedOpenOrders | JOIN | Filled order linkage |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UnRegisterMirrorForMoe | Procedure | Calls | IF (SELECT Trade.FunUnRegisterMirrorMot(@CID,@MirrorID))=1 then blocks unregister |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FunUnRegisterMirrorMot (function)
├── Trade.OpenExecutionPlan (table)
├── Trade.OrderForOpen (table)
├── Dictionary.OrderForExecutionStatus (table)
└── Trade.ExecutedOpenOrders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OpenExecutionPlan | Table | INNER JOIN - ep.OrderID, ep.CID, ep.MirrorID |
| Trade.OrderForOpen | Table | INNER JOIN - ofo.OrderID, ofo.StatusID |
| Dictionary.OrderForExecutionStatus | Table | LEFT JOIN - IsTerminal for status |
| Trade.ExecutedOpenOrders | Table | LEFT JOIN - eo.PositionID IS NULL check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UnRegisterMirrorForMoe | Procedure | Calls - blocks unregister when result=1 |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

NATIVE_COMPILATION, SCHEMABINDING. ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'English').

---

## 8. Sample Queries

### 8.1 Check if unregister is blocked for a mirror

```sql
SELECT Trade.FunUnRegisterMirrorMot(1488218, 372) AS CanUnregister;
-- 0 = allowed, 1 = blocked
```

### 8.2 Batch check multiple mirrors for a customer

```sql
SELECT m.MirrorID, Trade.FunUnRegisterMirrorMot(m.CID, m.MirrorID) AS Blocked
FROM Trade.Mirror m WITH (NOLOCK)
WHERE m.CID = 1488218 AND m.IsActive = 1;
```

### 8.3 Inspect blocking orders manually

```sql
SELECT ep.OrderID, ep.CID, ep.MirrorID, ofo.StatusID, dofe.Status, dofe.IsTerminal
FROM Trade.OpenExecutionPlan ep WITH (NOLOCK)
INNER JOIN Trade.OrderForOpen ofo WITH (NOLOCK) ON ofo.OrderID = ep.OrderID
INNER JOIN Dictionary.OrderForExecutionStatus dofe WITH (NOLOCK) ON ofo.StatusID = dofe.ID
LEFT JOIN Trade.ExecutedOpenOrders eo WITH (NOLOCK) ON eo.OpenCorrelationID = ep.OpenCorrelationID
WHERE ep.CID = 1488218 AND ep.MirrorID = 372
  AND eo.PositionID IS NULL AND ISNULL(dofe.IsTerminal, 0) = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FunUnRegisterMirrorMot | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.FunUnRegisterMirrorMot.sql*
