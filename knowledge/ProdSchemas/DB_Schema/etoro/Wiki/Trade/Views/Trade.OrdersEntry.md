# Trade.OrdersEntry

> Filtered view of Trade.OrdersEntryTbl showing only active/pending entry orders (StatusID=1), used by the order matching engine and trading platform.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | OrderID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.OrdersEntry is a filtered view of Trade.OrdersEntryTbl that exposes only active entry orders - orders to OPEN new positions. StatusID=1 means "Active": the order is waiting to be triggered or executed. The view hides cancelled, filled, and expired orders so consumers see only actionable orders.

This view exists because the order matching engine and trading platform need a clean abstraction over entry orders. By filtering at the view level, applications avoid repetitive WHERE StatusID=1 clauses and reduce the risk of accidentally processing inactive orders. The view exposes 20 columns covering direction (IsBuy), size (Amount, AmountInUnitsDecimal), leverage, stop-loss/take-profit settings, mirror/copy-trade linkage, and settlement type.

The view is a simple pass-through SELECT with a single WHERE clause. No joins, no computed columns. All columns map directly to Trade.OrdersEntryTbl. Key identifiers: OrderID (PK), CID (customer), InstrumentID (what to trade), IsBuy (direction), Amount (size), Leverage.

---

## 2. Business Logic

**Filter**: WHERE StatusID = 1. Only rows with StatusID=1 (Active) are returned. All other statuses (e.g., cancelled, filled, expired) are excluded.

**Column pass-through**: All 20 output columns are direct references to Trade.OrdersEntryTbl. No transformations, no defaults.

---

## 3. Data Overview

N/A - output mirrors Trade.OrdersEntryTbl. See [Trade.OrdersEntryTbl](../Tables/Trade.OrdersEntryTbl.md) for data overview.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | int | NO | - | CODE-BACKED | Primary key. Unique identifier for the entry order. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID. FK to Customer.Customer. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | Instrument being traded. FK to Trade.Instrument. |
| 4 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier (1, 2, 5, 10, etc.). |
| 5 | Amount | money | NO | - | CODE-BACKED | Order size in denomination currency. |
| 6 | IsBuy | bit | NO | - | CODE-BACKED | 1=buy/long, 0=sell/short. |
| 7 | StopLosPercentage | float | YES | - | CODE-BACKED | Stop-loss percentage (note: typo "Los" in DDL). |
| 8 | TakeProfitPercentage | float | YES | - | CODE-BACKED | Take-profit percentage. |
| 9 | Occurred | datetime | YES | - | CODE-BACKED | When the order was placed. |
| 10 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position for copy-trade/add-to-position orders. |
| 11 | MirrorID | int | YES | - | CODE-BACKED | Mirror/copy-trade ID. 0 = manual order. |
| 12 | InitialMirrorAmountInCents | int | YES | - | CODE-BACKED | Initial amount in cents for mirror orders. |
| 13 | IsTslEnabled | bit | YES | - | CODE-BACKED | Trailing stop-loss enabled. |
| 14 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Order size in units/shares. |
| 15 | OrderTypeID | int | YES | - | CODE-BACKED | Order type. FK to dictionary. |
| 16 | OpenOpenOperationTypeID | int | YES | - | CODE-BACKED | Open operation type for open-open flows. |
| 17 | IsDiscounted | bit | YES | - | CODE-BACKED | Whether order has discount applied. |
| 18 | SettlementTypeID | tinyint | YES | - | CODE-BACKED | Settlement type (CFD vs Real). |
| 19 | IsNoStopLoss | bit | YES | - | CODE-BACKED | Order without stop-loss. |
| 20 | IsNoTakeProfit | bit | YES | - | CODE-BACKED | Order without take-profit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | FK | Customer who placed the order |
| InstrumentID | Trade.Instrument | FK | Instrument being traded |
| ParentPositionID | Trade.PositionTbl | FK | Parent position for add-to-position |
| MirrorID | Trade.Mirror | FK | Mirror/copy-trade configuration |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrdersEntryTbl
    ^
Trade.OrdersEntry
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersEntryTbl | Table | Base table. Filtered WHERE StatusID=1. |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Active entry orders for a customer

```sql
SELECT OrderID, InstrumentID, IsBuy, Amount, Leverage, Occurred
FROM Trade.OrdersEntry WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.2 Active entry orders for an instrument

```sql
SELECT OrderID, CID, Amount, IsBuy, StopLosPercentage, TakeProfitPercentage
FROM Trade.OrdersEntry WITH (NOLOCK)
WHERE InstrumentID = 100017;
```

### 8.3 Mirror/copy-trade entry orders

```sql
SELECT OrderID, CID, MirrorID, InitialMirrorAmountInCents, Amount
FROM Trade.OrdersEntry WITH (NOLOCK)
WHERE MirrorID > 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrdersEntry | Type: View | Source: etoro/etoro/Trade/Views/Trade.OrdersEntry.sql*
