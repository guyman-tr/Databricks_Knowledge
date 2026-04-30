# fiktivo.spafw_LeadsInPast60Days

> Returns daily lead counts and commission totals for a specific affiliate over the past 60 days.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Result set (LeadCount, TotalCommission, Day, Month, Year) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

spafw_LeadsInPast60Days provides a rolling 60-day summary of lead activity for a single affiliate. It is used in the affiliate portal dashboard to display recent lead generation performance, allowing affiliates to track their daily lead volume and associated commission earnings at a glance.

The procedure joins the leads table with the leads commissions table to produce aggregated daily totals. Only Tier 1 (direct) commissions are included, and records must be both valid and accepted to appear in the results. This ensures that rejected, fraudulent, or invalidated leads are excluded from the affiliate's performance view.

The output is grouped by day/month/year date components, providing a time-series suitable for charting in the affiliate dashboard. Each row represents one calendar day's aggregate lead count and total commission amount.

---

## 2. Business Logic

### 2.1 Lead Activity Aggregation

**What**: Aggregates lead counts and commission totals per day for the specified affiliate, limited to the past 60 days.

**Columns/Parameters Involved**: LeadID, Commission, ORDER_DATE (dd, mm, yyyy parts), AffiliateID, Tier, Valid, AffiliateSaleAccepted

**Rules**:
- SELECT COUNT(LeadID) AS LeadCount, SUM(Commission) AS TotalCommission, DATEPART(dd, ORDER_DATE), DATEPART(mm, ORDER_DATE), DATEPART(yyyy, ORDER_DATE)
- FROM dbo.tblaff_Leads INNER JOIN dbo.tblaff_Leads_Commissions ON LeadID
- WHERE Tier = 1 (direct affiliate commissions only)
- AND Valid <> 0 (exclude invalidated leads)
- AND AffiliateSaleAccepted <> 0 (exclude rejected leads)
- AND AffiliateID = @AffiliateID
- AND ORDER_DATE >= DATEADD(DAY, -60, GETDATE())
- GROUP BY DATEPART(dd, ORDER_DATE), DATEPART(mm, ORDER_DATE), DATEPART(yyyy, ORDER_DATE)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | INT (IN) | NO | - | CODE-BACKED | The affiliate whose lead activity is being queried. Filters both tblaff_Leads and tblaff_Leads_Commissions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.tblaff_Leads | SELECT | Reads lead records for the specified affiliate |
| - | dbo.tblaff_Leads_Commissions | JOIN | Joins to get Tier 1 commission amounts per lead |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.spafw_LeadsInPast60Days (procedure)
├── dbo.tblaff_Leads (table, cross-schema)
└── dbo.tblaff_Leads_Commissions (table, cross-schema)
```

### 6.1 Objects This Depends On

2 cross-schema dbo tables (tblaff_Leads, tblaff_Leads_Commissions).

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get lead performance for affiliate 100 over the past 60 days
```sql
EXEC fiktivo.spafw_LeadsInPast60Days
    @AffiliateID = 100
```

### 8.2 Manual equivalent query with NOLOCK for ad-hoc analysis
```sql
SELECT
    COUNT(l.LeadID) AS LeadCount,
    SUM(lc.Commission) AS TotalCommission,
    DATEPART(dd, l.ORDER_DATE) AS [Day],
    DATEPART(mm, l.ORDER_DATE) AS [Month],
    DATEPART(yyyy, l.ORDER_DATE) AS [Year]
FROM dbo.tblaff_Leads l WITH (NOLOCK)
INNER JOIN dbo.tblaff_Leads_Commissions lc WITH (NOLOCK)
    ON l.LeadID = lc.LeadID
WHERE lc.Tier = 1
    AND l.Valid <> 0
    AND l.AffiliateSaleAccepted <> 0
    AND lc.AffiliateID = 100
    AND l.ORDER_DATE >= DATEADD(DAY, -60, GETDATE())
GROUP BY DATEPART(dd, l.ORDER_DATE), DATEPART(mm, l.ORDER_DATE), DATEPART(yyyy, l.ORDER_DATE)
ORDER BY [Year], [Month], [Day]
```

### 8.3 Count total leads per affiliate for the last 60 days
```sql
SELECT
    lc.AffiliateID,
    COUNT(l.LeadID) AS TotalLeads,
    SUM(lc.Commission) AS TotalCommission
FROM dbo.tblaff_Leads l WITH (NOLOCK)
INNER JOIN dbo.tblaff_Leads_Commissions lc WITH (NOLOCK)
    ON l.LeadID = lc.LeadID
WHERE lc.Tier = 1
    AND l.Valid <> 0
    AND l.AffiliateSaleAccepted <> 0
    AND l.ORDER_DATE >= DATEADD(DAY, -60, GETDATE())
GROUP BY lc.AffiliateID
ORDER BY TotalLeads DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 7.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.spafw_LeadsInPast60Days | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.spafw_LeadsInPast60Days.sql*
