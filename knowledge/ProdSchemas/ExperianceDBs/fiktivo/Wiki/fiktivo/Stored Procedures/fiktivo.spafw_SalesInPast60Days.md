# fiktivo.spafw_SalesInPast60Days

> Returns a daily summary of sales counts and commission totals for a specific affiliate over the past 60 days, grouped by date and ordered most recent first.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Result set: TotalSales, SalesCommission, DateDay, DateMonth, DateYear |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a reporting procedure that provides a 60-day rolling window of sales activity for a given affiliate. It returns daily aggregates of sales counts and their associated commission amounts, enabling affiliates to monitor their recent sales performance on a day-by-day basis.

The procedure is designed for the affiliate dashboard or reporting interface, giving affiliates visibility into how many valid, accepted sales they have generated each day over the last two months, along with the total commission earned per day.

Only Tier 1 commissions (direct, not sub-affiliate) are included, and only sales that are both Valid and AffiliateSaleAccepted are counted. This is the sales counterpart to `spafw_LeadsInPast60Days`.

---

## 2. Business Logic

### 2.1 60-Day Rolling Window Sales Aggregation

**What**: Aggregates sales counts and commissions per day for the last 60 days.

**Columns/Parameters Involved**: `@AffiliateID`, `tblaff_Sales.ORDER_DATE`, `tblaff_Sales_Commissions.Commission`

**Rules**:
- Joins tblaff_Sales to tblaff_Sales_Commissions on SalesID
- Filters to Tier = 1 only (direct affiliate commissions)
- Filters to Valid <> 0 (sale must be valid)
- Filters to AffiliateSaleAccepted <> 0 (sale must be accepted by affiliate)
- Filters to AffiliateID = @AffiliateID on the commissions table
- Date filter: ORDER_DATE >= DATEADD(dd, -60, GETDATE())
- Groups by day (DatePart dd), month (DatePart mm), year (DatePart yyyy)
- Orders by year DESC, month DESC, day DESC (most recent first)

### 2.2 LEFT JOIN Strategy

**What**: Uses LEFT JOIN from sales to commissions.

**Rules**:
- LEFT JOIN tblaff_Sales_Commissions ON SalesID allows sale rows without commissions to appear
- However, WHERE clause filters on Tier and AffiliateID effectively convert it to an INNER JOIN at runtime
- COUNT counts SalesIDs, SUM aggregates Commission amounts

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID (IN) | INT | NO | - | CODE-BACKED | The affiliate ID to retrieve sales data for. Filters on tblaff_Sales_Commissions.AffiliateID. |

**Result Set Columns**:

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | TotalSales | INT | Count of valid, accepted sales for the day |
| 2 | SalesCommission | FLOAT | Sum of Tier 1 commissions for sales on the day |
| 3 | DateDay | INT | Day of month (1-31) from ORDER_DATE |
| 4 | DateMonth | INT | Month number (1-12) from ORDER_DATE |
| 5 | DateYear | INT | Four-digit year from ORDER_DATE |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | dbo.tblaff_Sales | Table read | Source of sales records and ORDER_DATE |
| (SELECT) | dbo.tblaff_Sales_Commissions | Table read | Source of commission amounts, Tier, and AffiliateID filter |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.spafw_SalesInPast60Days (procedure)
    ├── dbo.tblaff_Sales (table)
    └── dbo.tblaff_Sales_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Sales | Table | SELECT - sales records with ORDER_DATE and validity flags |
| dbo.tblaff_Sales_Commissions | Table | SELECT - commission amounts, Tier, AffiliateID, and join key |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Session Settings

- SET ANSI_NULLS ON
- SET QUOTED_IDENTIFIER ON

---

## 8. Sample Queries

### 8.1 Get sales in past 60 days for an affiliate
```sql
EXEC fiktivo.spafw_SalesInPast60Days @AffiliateID = 100
```

### 8.2 Verify sales data manually
```sql
SELECT COUNT(s.SalesID) AS TotalSales, SUM(sc.Commission) AS SalesCommission,
       CAST(s.ORDER_DATE AS DATE) AS SaleDate
FROM dbo.tblaff_Sales s
    INNER JOIN dbo.tblaff_Sales_Commissions sc ON s.SalesID = sc.SalesID
WHERE sc.Tier = 1 AND s.Valid <> 0 AND s.AffiliateSaleAccepted <> 0
    AND sc.AffiliateID = 100
    AND s.ORDER_DATE >= DATEADD(dd, -60, GETDATE())
GROUP BY CAST(s.ORDER_DATE AS DATE)
ORDER BY CAST(s.ORDER_DATE AS DATE) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.spafw_SalesInPast60Days | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.spafw_SalesInPast60Days.sql*
