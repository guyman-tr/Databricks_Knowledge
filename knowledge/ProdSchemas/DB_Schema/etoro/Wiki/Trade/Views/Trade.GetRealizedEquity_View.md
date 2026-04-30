# Trade.GetRealizedEquity_View

> Thin wrapper exposing Customer ID and Realized Equity (closed-trade P&L) from Customer.CustomerMoney for reporting and balance lookups.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetRealizedEquity_View exposes each customer's RealizedEquity - the cumulative profit or loss from all closed positions - alongside their Customer ID (CID). Realized equity is the portion of a customer's balance that reflects settled trading outcomes, distinct from open position unrealized P&L. The view is a direct pass-through from Customer.CustomerMoney with no filters or joins, providing a simple API for applications that need CID and RealizedEquity together.

This view exists to give the Trade schema a stable, documented surface for realized equity lookups without coupling callers to the Customer schema. The synonym dbo.RealGetRealizedEquity maps to this view for backward compatibility.

---

## 2. Business Logic

### 2.1 Direct Pass-Through

**What**: The view selects two columns from Customer.CustomerMoney with no transformation.

**Columns/Parameters Involved**: `CID`, `RealizedEquity`

**Rules**:
- One row per customer; CID is the primary key of Customer.CustomerMoney
- RealizedEquity can be NULL (default 0 via CCST_RealizedEquity constraint); sample data shows values from 0.1 to 109415.66
- CID=-1 appears in sample data (system or test record) with high RealizedEquity
- No WHERE filter - all customers are returned

---

## 3. Data Overview

| CID | RealizedEquity | Meaning |
|-----|----------------|---------|
| -1 | 355555 | System or test record (high value likely synthetic) |
| 5 | 0.1 | Small realized P&L |
| 15 | 109415.66 | Large cumulative realized profit |
| 17 | 0.2 | Minimal realized P&L |
| 18 | 0.2 | Minimal realized P&L |

**Selection criteria**: TOP 5 from view. NULL patterns: RealizedEquity is non-NULL in sample; base table allows NULL with default 0.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID. Primary key of Customer.CustomerMoney. Source: Customer.CustomerMoney.CID. |
| 2 | RealizedEquity | money | YES | 0 | CODE-BACKED | Cumulative realized profit or loss from all closed positions. Source: Customer.CustomerMoney.RealizedEquity. Default CCST_RealizedEquity=0. Updated by cash settlement and position close logic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, RealizedEquity | Customer.CustomerMoney | SELECT | All columns sourced from Customer.CustomerMoney; no JOINs. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.RealGetRealizedEquity | Synonym | Alias | Synonym FOR Trade.GetRealizedEquity_View - callers may use either name. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetRealizedEquity_View (view)
└── Customer.CustomerMoney (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | FROM - sole data source for CID and RealizedEquity |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.RealGetRealizedEquity | Synonym | Points to this view |

---

## 7. Technical Details

### 7.1 DDL Summary

```sql
SELECT CID, RealizedEquity
  FROM Customer.CustomerMoney WITH (NOLOCK)
```

### 7.2 Column-to-Source Mapping

| Output Column | Base Table | Base Column |
|---------------|------------|-------------|
| CID | Customer.CustomerMoney | CID |
| RealizedEquity | Customer.CustomerMoney | RealizedEquity |

---

## 8. Sample Queries

### 8.1 Get realized equity for specific customers
```sql
SELECT CID, RealizedEquity
  FROM Trade.GetRealizedEquity_View WITH (NOLOCK)
 WHERE CID IN (15, 17, 18)
```

### 8.2 Top 10 customers by realized equity
```sql
SELECT TOP 10 CID, RealizedEquity
  FROM Trade.GetRealizedEquity_View WITH (NOLOCK)
 WHERE RealizedEquity IS NOT NULL
 ORDER BY RealizedEquity DESC
```

### 8.3 Use via synonym (backward compatibility)
```sql
SELECT CID, RealizedEquity
  FROM dbo.RealGetRealizedEquity WITH (NOLOCK)
 WHERE CID > 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetRealizedEquity_View | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetRealizedEquity_View.sql*
