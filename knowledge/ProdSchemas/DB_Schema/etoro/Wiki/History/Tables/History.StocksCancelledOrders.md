# History.StocksCancelledOrders

> Legacy audit log of stock order cancellation events from 2014, recording which customer orders were cancelled, when the cancellation was initiated, and when it completed.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CancelOrderID (IDENTITY-like PK, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK on CancelOrderID) |

---

## 1. Business Meaning

This table is a **legacy audit log** for stock order cancellations from eToro's early stocks trading system (2014). Each row records one stock order cancellation event: which order was cancelled (`OrderID`), which customer owned the order (`CID`), when the cancellation was initiated (`Occurred`), when it completed (`Completed`), and any comment.

The table has only **5 rows** covering February-March 2014. It is no longer actively written to and represents a frozen historical record of the early stocks trading system. The early stocks trading infrastructure (see also History.StocksHedge, History.StocksOrders) was superseded and this log was abandoned after March 2014.

No procedures in the repository reference this table - it is a read-only archive.

---

## 2. Business Logic

### 2.1 Order Cancellation Audit

**What**: Records each stock order that was cancelled during the early stocks trading period.

**Columns/Parameters Involved**: `CancelOrderID`, `OrderID`, `CID`, `Occurred`, `Completed`

**Rules**:
- Each row represents one cancellation event
- `Occurred` = when the cancellation was initiated (some rows have midnight values suggesting date-only precision)
- `Completed` = when the cancellation was fully processed (has time component)
- `CancelOrderID` is the PK but NOT declared as IDENTITY in the DDL (plain int); values are manually assigned or from a sequence

---

## 3. Data Overview

| CancelOrderID | OrderID | CID | Occurred | Completed | Meaning |
|---|---|---|---|---|---|
| 1 | 841835 | 3368553 | 2014-02-12 | 2014-02-12 14:50 | First recorded order cancellation |
| 2 | 828036 | 1777231 | 2014-02-12 | 2014-02-12 15:04 | Second cancellation on same day |
| 5 | (last) | (various) | 2014-03-05 | 2014-03-05 14:36 | Last recorded cancellation |

Total: 5 rows | Feb-Mar 2014

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CancelOrderID | int | NO | - | CODE-BACKED | Primary key for the cancellation event. Not defined as IDENTITY but acts as one. Uniquely identifies each cancellation record. |
| 2 | OrderID | int | NO | - | VERIFIED | The stock order that was cancelled. References the order in the stocks order system. |
| 3 | CID | int | NO | - | VERIFIED | Customer ID who owned the cancelled order. Implicit FK to Customer.CustomerStatic. |
| 4 | Occurred | datetime | NO | - | CODE-BACKED | When the cancellation was initiated. Some rows have midnight timestamps (date-only precision) suggesting manual entry or batch processing. |
| 5 | Completed | datetime | NO | - | CODE-BACKED | When the cancellation was fully processed and completed. Has full timestamp precision. |
| 6 | Comment | varchar(max) | YES | - | CODE-BACKED | Optional comment or reason for the cancellation. NULL for all 5 recorded rows. TEXTIMAGE_ON [PRIMARY] for max storage. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit FK | Customer who owned the cancelled order. |
| OrderID | History.StocksOrders (implicit) | Implicit | The cancelled order; may reference the early stocks order system. |

### 5.2 Referenced By (other objects point to this)

No active writers or readers. Static legacy archive.

---

## 6. Dependencies

No dependencies. Legacy archive table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_StocksCancelledOrders | CLUSTERED PK | CancelOrderID ASC | - | - | Active |

---

## 8. Sample Queries

### 8.1 View all cancelled orders
```sql
SELECT CancelOrderID, OrderID, CID, Occurred, Completed, Comment
FROM [History].[StocksCancelledOrders] WITH (NOLOCK)
ORDER BY Occurred ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.2/10 (Elements: 7.5/10, Logic: 6.5/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.StocksCancelledOrders | Type: Table | Source: etoro/etoro/History/Tables/History.StocksCancelledOrders.sql*
