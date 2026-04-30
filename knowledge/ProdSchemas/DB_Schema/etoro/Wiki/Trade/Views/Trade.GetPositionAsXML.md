# Trade.GetPositionAsXML

> Same as GetOpenPositionAsXML but includes BOTH open AND closed game positions (no IsOpened filter on GetPositionForXML subquery). Used for full game session position snapshots including historical game positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | CID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

This view aggregates customer-level attributes (credit, total profit, total investment, online status) with **all positions**—both open and closed game positions—serialized as an XML fragment. It is used for full game session position snapshots where historical game positions must be included alongside currently open ones.

Unlike `Trade.GetOpenPositionAsXML`, this view does not filter the `Trade.GetPositionForXML` subquery by `IsOpened`. The PositionList XML therefore contains every position returned by GetPositionForXML, which itself is a UNION ALL of open and closed game positions. The row set is limited to customers who have at least one position in `Trade.Position`.

---

## 2. Business Logic

### 2.1 All-Position Inclusion (No IsOpened Filter)

**What**: Includes both open and closed game positions in the embedded PositionList.
**Columns/Parameters Involved**: `IsOpened` (implicitly not filtered), `PositionList` (XML output)
**Rules**:
- Subquery filters only by `TXML.CID = CCST.CID`
- No `IsOpened = 1` filter; all positions from GetPositionForXML are included

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

One row per customer who has at least one position in `Trade.Position`. Each row contains 11 scalar columns (customer attributes and aggregated financials) plus one XML column (`PositionList`) holding all positions—open and closed—for that customer as a FOR XML RAW fragment with BINARY BASE64 and ELEMENTS.

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
| 11 | PositionList | xml | Trade.GetPositionForXML subquery (no IsOpened filter) | High | XML fragment containing all open and closed game positions for the customer |

---

## 5. Relationships

### 5.1 References To

| Referenced Object | Join Type | Join Condition |
|-------------------|-----------|----------------|
| Customer.Customer | FROM | Base table |
| BackOffice.CustomerAllTimeAggregatedData | LEFT OUTER JOIN | CCST.CID = BCAD.CID |
| Customer.LoggedCustomer | LEFT OUTER JOIN | CCST.CID = CLGC.CID |
| Trade.GetPositionForXML | Subquery | TXML.CID = CCST.CID |
| Trade.Position | EXISTS | TPOS.CID = CCST.CID |

### 5.2 Referenced By

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionAsXML
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

### 8.1 Get full position XML for a specific customer

```sql
SELECT CID, ProviderID, SpreadGroupID, IsRealAcount, IsOnLine, ActionType,
       CreditCents, TotalNetProfitCents, TotalInvestetmentCents, TotalVolume, PositionList
FROM Trade.GetPositionAsXML
WHERE CID = 12345;
```

### 8.2 Get full position XML for all real-account customers

```sql
SELECT *
FROM Trade.GetPositionAsXML
WHERE IsRealAcount = 'true';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Quality: 8.5/10*
*Object: Trade.GetPositionAsXML | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetPositionAsXML.sql*
