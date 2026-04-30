# fiktivo.viewSales

> Returns daily sales (deposit) events attributed to primary-tier (Tier 1) affiliates, providing the sales component of the unified affiliate activity report.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | Base tables: dbo.tblaff_Sales + dbo.tblaff_Sales_Commissions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view extracts Tier 1 (primary affiliate) sales events from the commission system, outputting the date, affiliate ID, and sub-affiliate serial for each sale. A "sale" in the affiliate context represents a customer deposit event that qualifies for commission. The view filters to Tier=1 only, excluding tier-2 sub-affiliate commissions.

The view is a component of the unified affiliate activity report - it feeds into `fiktivo.viewUnion` which combines downloads, installs, first-time runs, leads, and sales into a single dataset. It also feeds into `fiktivo.report_summary` for aggregate daily sales counts. Sales represent the most valuable conversion event in the affiliate funnel - they indicate actual revenue-generating customer activity.

---

## 2. Business Logic

### 2.1 Tier 1 Sales Filtering

**What**: Extracts only primary-affiliate sales events.

**Columns/Parameters Involved**: `Date`, `AffiliateID`, `SerialID`

**Rules**:
- JOINs dbo.tblaff_Sales to dbo.tblaff_Sales_Commissions on SalesID
- Filters WHERE Tier = 1 (primary affiliate level only)
- Date is truncated to midnight via CAST(FLOOR(CAST(ORDER_DATE AS FLOAT)) AS DATETIME)
- LEFT OUTER JOIN ensures sales without commission records are included
- AffiliateID comes from the commission record, not the sales record

---

## 3. Data Overview

| Date | AffiliateID | SerialID | Meaning |
|------|-------------|----------|---------|
| 2012-07-08 | 1 | (empty) | Sale attributed to the default/house affiliate (ID=1) with no sub-affiliate tracking. Likely a direct customer deposit. |
| 2012-07-06 | 1 | (empty) | Multiple sales on the same day for the house affiliate - high-volume default attribution. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Date | DATETIME | YES | - | CODE-BACKED | Sales event date truncated to midnight. Computed from dbo.tblaff_Sales.ORDER_DATE. Used for daily aggregation in viewUnion and report_summary. |
| 2 | AffiliateID | INT | YES | - | CODE-BACKED | Primary (Tier 1) affiliate credited with the sale. Sourced from dbo.tblaff_Sales_Commissions.AffiliateID. References dbo.tblaff_Affiliates. |
| 3 | SerialID | NVARCHAR | YES | - | CODE-BACKED | Sub-affiliate tracking identifier. Sourced from dbo.tblaff_Sales_Commissions.SubAffiliateID. Contains campaign or traffic source identifiers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | dbo.tblaff_Sales | View base table | Source of sales events (ORDER_DATE, SalesID). |
| (JOIN) | dbo.tblaff_Sales_Commissions | View base table | Source of affiliate attribution (AffiliateID, SubAffiliateID, Tier). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.viewUnion | (UNION) | View composition | Combined with viewDownloads, viewInstalls, viewFirstTimeRun, viewLeads into unified activity dataset. |
| fiktivo.report_summary | (subquery) | View reference | Aggregated for daily sales counts (COUNT WHERE Tier=1). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.viewSales (view)
    ├── dbo.tblaff_Sales (table)
    └── dbo.tblaff_Sales_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Sales | Table | LEFT OUTER JOIN source for ORDER_DATE, SalesID |
| dbo.tblaff_Sales_Commissions | Table | JOIN on SalesID, filtered by Tier=1, provides AffiliateID and SubAffiliateID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.viewUnion | View | UNION member for unified affiliate activity |
| fiktivo.report_summary | View | Subquery for daily sales count aggregation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Daily sales count by affiliate
```sql
SELECT Date, AffiliateID, COUNT(*) AS SalesCount
FROM fiktivo.viewSales WITH (NOLOCK)
GROUP BY Date, AffiliateID
ORDER BY Date DESC, SalesCount DESC
```

### 8.2 Sales with affiliate name
```sql
SELECT v.Date, v.AffiliateID, a.Username, v.SerialID
FROM fiktivo.viewSales v WITH (NOLOCK)
JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON v.AffiliateID = a.AffiliateID
ORDER BY v.Date DESC
```

### 8.3 Top affiliates by total sales
```sql
SELECT TOP 20 AffiliateID, COUNT(*) AS TotalSales
FROM fiktivo.viewSales WITH (NOLOCK)
GROUP BY AffiliateID
ORDER BY TotalSales DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.viewSales | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.viewSales.sql*
