# Trade.GetPublicOrdersExitDataWithCIDForAPI

> Returns all pending exit (close) orders from Trade.OrdersExit for a given customer, with InstrumentID resolved via JOIN to Trade.Position. Single-result-set exit order feed for the public API.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all pending exit orders for a customer from `Trade.OrdersExit`. Exit orders are pending close requests for open positions - they represent a customer's instruction to close a position either at market, at a specific rate, or as part of a mirror close operation. The InstrumentID is not stored directly in Trade.OrdersExit, so it is resolved via an INNER JOIN to Trade.Position (using PositionID).

---

## 2. Business Logic

SELECT from Trade.OrdersExit WHERE CID=@CID, INNER JOIN Trade.Position ON PositionID to get InstrumentID. Only returns exit orders where the position is still open (INNER JOIN to Trade.Position which only contains StatusID=1).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose exit orders to retrieve. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | OrderID | INT | NO | - | CODE-BACKED | Exit order identifier. |
| 3 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 4 | PositionID | BIGINT | NO | - | CODE-BACKED | Position being closed by this exit order. |
| 5 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument of the position. Resolved from Trade.Position JOIN. |
| 6 | OpenOccurred | DATETIME | YES | - | CODE-BACKED | When the exit order was created. |
| 7 | MirrorID | INT | YES | - | CODE-BACKED | Mirror ID if this is a mirror-driven close. 0/NULL = manual close. |
| 8 | MirrorCloseActionType | INT | YES | - | CODE-BACKED | Type of mirror action that triggered this exit (e.g., stop-copy, mirror SL). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.OrdersExit | Reader | Pending exit/close orders for the customer |
| PositionID | Trade.Position | INNER JOIN | InstrumentID resolution; also enforces position still open |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Public API service | @CID | Application call | Exit order list for customer display |

---

## 6. Dependencies

```
Trade.GetPublicOrdersExitDataWithCIDForAPI (procedure)
+-- Trade.OrdersExit (table)
+-- Trade.Position (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersExit | Table | Pending close orders for the customer |
| Trade.Position | View | INNER JOIN for InstrumentID; also filters to positions still open |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Public API service | External application | Exit order list display |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOIN Trade.Position | Implicit filter | Exit orders for already-closed positions (not in Trade.Position) are excluded |
| NOLOCK | Isolation | READ UNCOMMITTED for API performance |

---

## 8. Sample Queries

```sql
EXEC Trade.GetPublicOrdersExitDataWithCIDForAPI @CID = 1234567;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPublicOrdersExitDataWithCIDForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPublicOrdersExitDataWithCIDForAPI.sql*
