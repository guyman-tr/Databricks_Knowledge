# Trade.GetPublicOrdersEntryDataWithCIDForAPI

> Returns all pending entry (limit/stop) orders from Trade.OrdersEntry for a given customer. Single-result-set entry order feed for the public API.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all pending entry orders for a customer from `Trade.OrdersEntry`. Entry orders are conditional open orders - they are queued to open a position when the instrument price reaches a specified entry rate. They differ from market orders (Trade.Orders) which execute at the current market price.

The CID-scoped version of `GetPublicOrdersEntryDataWithOrderIdForAPI`.

---

## 2. Business Logic

Simple SELECT from Trade.OrdersEntry WHERE CID=@CID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose entry orders to retrieve. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | OrderID | INT | NO | - | CODE-BACKED | Entry order identifier. |
| 3 | CID | INT | NO | 0 | CODE-BACKED | Customer ID (ISNULL -> 0). |
| 4 | InstrumentID | INT | NO | 0 | CODE-BACKED | Instrument for this entry order (ISNULL -> 0). |
| 5 | IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Buy, 0=Sell. |
| 6 | StopLosPercentage | DECIMAL | NO | 0 | CODE-BACKED | Stop-loss as percentage from entry rate (ISNULL -> 0). |
| 7 | TakeProfitPercentage | DECIMAL | NO | 0 | CODE-BACKED | Take-profit as percentage from entry rate (ISNULL -> 0). |
| 8 | Occurred | DATETIME | NO | - | CODE-BACKED | When the entry order was placed. |
| 9 | ParentPositionID | BIGINT | NO | 0 | CODE-BACKED | For copy-trade entry orders, the leader's position ID (ISNULL -> 0). |
| 10 | MirrorID | INT | NO | 0 | CODE-BACKED | Mirror ID if this is a copied entry order (ISNULL -> 0). |
| 11 | InitialMirrorAmountInCents | BIGINT | NO | 0 | CODE-BACKED | Mirror investment amount in cents at order creation (ISNULL -> 0). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.OrdersEntry | Reader | Pending entry/limit orders for the customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Public API service | @CID | Application call | Entry order list for customer display |

---

## 6. Dependencies

```
Trade.GetPublicOrdersEntryDataWithCIDForAPI (procedure)
+-- Trade.OrdersEntry (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersEntry | Table | All pending entry/limit orders for the customer |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Public API service | External application | Entry order list display |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK | Isolation | READ UNCOMMITTED for API performance |

---

## 8. Sample Queries

```sql
EXEC Trade.GetPublicOrdersEntryDataWithCIDForAPI @CID = 1234567;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPublicOrdersEntryDataWithCIDForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPublicOrdersEntryDataWithCIDForAPI.sql*
