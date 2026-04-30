# fiktivo.viewSales

> View that extracts tier-1 sales events from the dbo affiliate sales and commissions tables, producing daily sale records with affiliate attribution for the conversion funnel union.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | Date + AffiliateID + SerialID (composite) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

viewSales extracts sales conversion events from the dbo.tblaff_Sales and dbo.tblaff_Sales_Commissions tables. This represents the final stage of the affiliate funnel: Download -> Install -> First Time Run -> Lead -> **Sale**. A "sale" in this context is a trading activity event that qualifies for affiliate commission - typically when a referred customer opens or closes a trading position.

Like viewLeads, this view reads from the cross-schema dbo tables and filters to Tier=1 commissions (direct affiliate relationships). It JOINs sales with their commission records to extract the affiliate attribution.

Sales are the ultimate conversion metric for affiliates - they represent actual revenue-generating activity by referred customers. This is where affiliate commissions are typically the highest.

---

## 2. Business Logic

### 2.1 Tier-1 Sales Filtering

**What**: Only first-tier (direct affiliate) sales commissions are included.

**Columns/Parameters Involved**: `Tier`

**Rules**:
- WHERE Tier = 1 filters to direct affiliate sales commissions
- AffiliateID sourced from tblaff_Sales_Commissions
- SubAffiliateID mapped to SerialID for funnel consistency
- LEFT OUTER JOIN preserves sales even with partial commission data

---

## 3. Data Overview

| Date | AffiliateID | SerialID | Meaning |
|---|---|---|---|
| 2012-06-18 | 1 | (empty) | Sales activity attributed to affiliate 1 (likely internal/house) with no sub-affiliate tracking. |
| 2012-06-17 | 1 | (empty) | Another house affiliate sale the previous day. Repeated AffiliateID=1 pattern suggests organic trading activity. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Date | datetime | YES | - | CODE-BACKED | Date of the sales event, truncated to day level. Source: CAST(FLOOR(CAST(dbo.tblaff_Sales.ORDER_DATE AS FLOAT)) AS DATETIME). |
| 2 | AffiliateID | int | YES | - | CODE-BACKED | Affiliate attributed with this sale. Source: dbo.tblaff_Sales_Commissions.AffiliateID. Only tier-1 (direct) affiliates included. |
| 3 | SerialID | nvarchar(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking code. Source: dbo.tblaff_Sales_Commissions.SubAffiliateID. Used for campaign-level attribution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Date | dbo.tblaff_Sales | LEFT JOIN | Sales date from ORDER_DATE |
| AffiliateID, SerialID | dbo.tblaff_Sales_Commissions | LEFT JOIN | Commission record with affiliate attribution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.viewUnion | All columns | UNION | Combined into the unified funnel view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.viewSales (view)
├── dbo.tblaff_Sales (table, cross-schema)
└── dbo.tblaff_Sales_Commissions (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Sales | Table (cross-schema) | LEFT JOIN source for sales date and SalesID |
| dbo.tblaff_Sales_Commissions | Table (cross-schema) | LEFT JOIN for AffiliateID and SubAffiliateID, WHERE Tier=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.viewUnion | View | UNION member - contributes sales funnel stage |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Daily sales counts
```sql
SELECT Date, COUNT(*) AS Sales
FROM fiktivo.viewSales WITH (NOLOCK)
GROUP BY Date
ORDER BY Date DESC
```

### 8.2 Top affiliates by sales volume
```sql
SELECT AffiliateID, COUNT(*) AS TotalSales
FROM fiktivo.viewSales WITH (NOLOCK)
GROUP BY AffiliateID
ORDER BY COUNT(*) DESC
```

### 8.3 Sales with sub-affiliate tracking
```sql
SELECT Date, AffiliateID, SerialID
FROM fiktivo.viewSales WITH (NOLOCK)
WHERE SerialID IS NOT NULL AND SerialID <> ''
ORDER BY Date DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.viewSales | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.viewSales.sql*
