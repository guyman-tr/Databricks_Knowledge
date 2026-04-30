# Trade.GetPublicOrdersEntryDataWithOrderIdForAPI

> Returns a single pending entry (limit/stop) order from Trade.OrdersEntry by OrderID. Single-row entry order fetch for the public API.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves a specific entry order by its OrderID from `Trade.OrdersEntry`. It is the OrderID-scoped counterpart to `GetPublicOrdersEntryDataWithCIDForAPI`. Returns the same column set - see that procedure's documentation for full column descriptions.

---

## 2. Business Logic

Simple SELECT from Trade.OrdersEntry WHERE OrderID=@OrderID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | INT | NO | - | CODE-BACKED | The entry order identifier to retrieve. |

**Output Columns**: Same as `Trade.GetPublicOrdersEntryDataWithCIDForAPI` (OrderID, CID, InstrumentID, IsBuy, StopLosPercentage, TakeProfitPercentage, Occurred, ParentPositionID, MirrorID, InitialMirrorAmountInCents).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.OrdersEntry | Reader | Single entry order lookup by OrderID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Public API service | @OrderID | Application call | Single entry order detail fetch |

---

## 6. Dependencies

```
Trade.GetPublicOrdersEntryDataWithOrderIdForAPI (procedure)
+-- Trade.OrdersEntry (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersEntry | Table | Single entry order lookup by OrderID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Public API service | External application | Entry order detail display |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK | Isolation | READ UNCOMMITTED for API performance |

---

## 8. Sample Queries

```sql
EXEC Trade.GetPublicOrdersEntryDataWithOrderIdForAPI @OrderID = 9876543;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPublicOrdersEntryDataWithOrderIdForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPublicOrdersEntryDataWithOrderIdForAPI.sql*
