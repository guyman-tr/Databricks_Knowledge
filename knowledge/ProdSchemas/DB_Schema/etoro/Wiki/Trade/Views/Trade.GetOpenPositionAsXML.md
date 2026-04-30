# Trade.GetOpenPositionAsXML

> Returns customer-level data with their OPEN positions embedded as FOR XML sub-select. Filters GetPositionForXML to IsOpened=1 only. Used for XML serialization of open position snapshots per customer.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | CID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

This view aggregates customer-level attributes (credit, total profit, total investment, online status) with their **open positions only** serialized as an XML fragment. It filters `Trade.GetPositionForXML` via `IsOpened = 1`, so only currently open positions appear in the PositionList XML. This distinguishes it from `Trade.GetPositionAsXML`, which returns both open and closed game positions.

The view is designed for XML export of open position snapshots—typically consumed by external systems or APIs that need a structured representation of a customer's currently open positions. The row set is limited to customers who have at least one position in `Trade.Position`.

---

## 2. Business Logic

### 2.1 Open-Only Position Filter

**What**: Restricts the embedded PositionList to open positions only.
**Columns/Parameters Involved**: `IsOpened` (from GetPositionForXML subquery), `PositionList` (XML output)
**Rules**:
- Subquery filters `TXML.IsOpened = 1`
- Closed positions are excluded from the XML output

### 2.2 Real vs Demo Account Flag

**What**: Exposes account type as a string for XML consumers.
**Columns/Parameters Involved**: `IsReal` (Customer.Customer), `IsRealAcount` (output)
**Rules**:
- `IsReal = 1` → `IsRealAcount = 'true'` (real account)
- `IsReal <> 1` → `IsRealAcount = 'false'` (demo account)
- Note: Original DDL uses typo "IsRealAcount"

### 2.3 Online Status

**What**: Indicates whether the customer has an active session.
**Columns/Parameters Involved**: `Customer.LoggedCustomer.CustomerSessionID`, `IsOnLine` (output)
**Rules**:
- `CustomerSessionID IS NULL` → `IsOnLine = 'false'`
- `CustomerSessionID IS NOT NULL` → `IsOnLine = 'true'`

### 2.4 Financial Amounts in Cents

**What**: Converts decimal amounts to integer cents for consistent serialization.
**Columns/Parameters Involved**: `Credit`, `TotalProfit`, `TotalInvestment`
**Rules**:
- CreditCents = CAST(Credit * 100 AS INTEGER)
- TotalNetProfitCents = CAST(TotalProfit * 100 AS INTEGER)
- TotalInvestetmentCents = CAST(TotalInvestment * 100 AS INTEGER)
- Note: Typo "Investetment" preserved in original DDL

---

## 3. Data Overview

One row per customer who has at least one position in `Trade.Position`. Each row contains 11 scalar columns (customer attributes and aggregated financials) plus one XML column (`PositionList`) holding all open positions for that customer as a FOR XML RAW fragment with BINARY BASE64 and ELEMENTS.

---

## 4. Elements

| # | Column Name | Data Type | Source | Confidence | Description |
|---|-------------|-----------|--------|------------|-------------|
| 1 | CID | int | Customer.Customer | High | Customer identifier |
| 2 | ProviderID | int | Customer.Customer | High | Provider/broker identifier |
| 3 | SpreadGroupID | int | Customer.Customer | High | Spread group for commission |
| 4 | IsRealAcount | varchar | Computed CASE | High | String 'true'/'false' for real/demo account |
| 5 | IsOnLine | varchar | Computed CASE | High | String 'true'/'false' based on LoggedCustomer session |
| 6 | ActionType | int | Hardcoded 1 | High | Always 1 (open action type) |
| 7 | CreditCents | int | Computed Credit*100 | High | Customer credit balance in cents |
| 8 | TotalNetProfitCents | int | BackOffice.CustomerAllTimeAggregatedData | High | All-time total profit in cents |
| 9 | TotalInvestetmentCents | int | BackOffice.CustomerAllTimeAggregatedData | High | All-time total investment in cents |
| 10 | TotalVolume | decimal | BackOffice.CustomerAllTimeAggregatedData | High | All-time trading volume |
| 11 | PositionList | xml | Trade.GetPositionForXML subquery (IsOpened=1) | High | XML fragment containing all open positions for the customer |

---

## 5. Relationships

### 5.1 References To

| Referenced Object | Join Type | Join Condition |
|-------------------|-----------|----------------|
| Customer.Customer | FROM | Base table |
| BackOffice.CustomerAllTimeAggregatedData | LEFT OUTER JOIN | CCST.CID = BCAD.CID |
| Customer.LoggedCustomer | LEFT OUTER JOIN | CCST.CID = CLGC.CID |
| Trade.GetPositionForXML | Subquery | TXML.CID = CCST.CID AND TXML.IsOpened = 1 |
| Trade.Position | EXISTS | TPOS.CID = CCST.CID |

### 5.2 Referenced By

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOpenPositionAsXML
├── Customer.Customer
├── BackOffice.CustomerAllTimeAggregatedData
├── Customer.LoggedCustomer
├── Trade.GetPositionForXML
│   └── (position-related views/tables)
└── Trade.Position
```

### 6.1 Objects This Depends On

| Object | Type |
|--------|------|
| Customer.Customer | Table |
| BackOffice.CustomerAllTimeAggregatedData | Table |
| Customer.LoggedCustomer | Table |
| Trade.GetPositionForXML | View |
| Trade.Position | Table |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get open position XML for a specific customer

```sql
SELECT CID, ProviderID, SpreadGroupID, IsRealAcount, IsOnLine, ActionType,
       CreditCents, TotalNetProfitCents, TotalInvestetmentCents, TotalVolume, PositionList
FROM Trade.GetOpenPositionAsXML
WHERE CID = 12345;
```

### 8.2 Get open position XML for all online customers

```sql
SELECT *
FROM Trade.GetOpenPositionAsXML
WHERE IsOnLine = 'true';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Quality: 8.5/10*
*Object: Trade.GetOpenPositionAsXML | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetOpenPositionAsXML.sql*
