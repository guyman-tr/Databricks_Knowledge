# fiktivo.viewLeads

> Returns daily lead events attributed to primary-tier (Tier 1) affiliates, providing the lead component of the unified affiliate activity report.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | Base tables: dbo.tblaff_Leads + dbo.tblaff_Leads_Commissions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view extracts Tier 1 (primary affiliate) lead events from the commission system, outputting the date, affiliate ID, and sub-affiliate serial for each lead. It filters to Tier=1 only, excluding tier-2 (sub-affiliate) commissions, to provide an unduplicated count of leads per affiliate.

The view is a component of the unified affiliate activity report - it feeds into `fiktivo.viewUnion` which combines downloads, installs, first-time runs, leads, and sales into a single dataset for daily reporting. It also feeds into `fiktivo.report_summary` for aggregate daily lead counts.

The SerialID column contains rich sub-affiliate tracking data - values like URL referrers, campaign identifiers (e.g., 'traffadsmarkopenbookenglish'), or tracking tokens that reveal the specific campaign or traffic source that generated the lead.

---

## 2. Business Logic

### 2.1 Tier 1 Lead Filtering

**What**: Extracts only primary-affiliate lead events, excluding sub-affiliate (Tier 2) duplicates.

**Columns/Parameters Involved**: `Date`, `AffiliateID`, `SerialID`

**Rules**:
- JOINs dbo.tblaff_Leads to dbo.tblaff_Leads_Commissions on LeadID
- Filters WHERE Tier = 1 (primary affiliate level only)
- Date is truncated to midnight via CAST(FLOOR(CAST(ORDER_DATE AS FLOAT)) AS DATETIME)
- LEFT OUTER JOIN ensures leads without commission records are included
- AffiliateID comes from the commission record, not the lead record

---

## 3. Data Overview

| Date | AffiliateID | SerialID | Meaning |
|------|-------------|----------|---------|
| 2012-07-24 | 22397 | http://www.google.co.uk/url?sa=t | Lead from affiliate 22397 where the SerialID captures the Google referrer URL - shows this lead came from organic search through the affiliate's SEO. |
| 2012-07-24 | 28600 | ...traffadsmarkopenbookarabic | Lead from affiliate 28600's Arabic-language OpenBook campaign. The SerialID encodes the campaign name and language targeting. |
| 2012-07-24 | 37487 | (empty) | Lead from affiliate 37487 with no sub-affiliate tracking. Direct affiliate attribution without campaign-level detail. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Date | DATETIME | YES | - | CODE-BACKED | Lead event date truncated to midnight. Computed from dbo.tblaff_Leads.ORDER_DATE via CAST(FLOOR(CAST(... AS FLOAT)) AS DATETIME). Used for daily aggregation in viewUnion and report_summary. |
| 2 | AffiliateID | INT | YES | - | CODE-BACKED | Primary (Tier 1) affiliate credited with the lead. Sourced from dbo.tblaff_Leads_Commissions.AffiliateID. References dbo.tblaff_Affiliates. |
| 3 | SerialID | NVARCHAR | YES | - | CODE-BACKED | Sub-affiliate tracking identifier. Sourced from dbo.tblaff_Leads_Commissions.SubAffiliateID. Contains campaign identifiers, referrer URLs, or tracking tokens that identify the specific traffic source. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | dbo.tblaff_Leads | View base table | Source of lead events (ORDER_DATE, LeadID). |
| (JOIN) | dbo.tblaff_Leads_Commissions | View base table | Source of affiliate attribution (AffiliateID, SubAffiliateID, Tier). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.viewUnion | (UNION) | View composition | Combined with viewDownloads, viewInstalls, viewFirstTimeRun, viewSales into unified activity dataset. |
| fiktivo.report_summary | (subquery) | View reference | Aggregated for daily lead counts (COUNT WHERE Tier=1). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.viewLeads (view)
    ├── dbo.tblaff_Leads (table)
    └── dbo.tblaff_Leads_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Leads | Table | LEFT OUTER JOIN source for ORDER_DATE, LeadID |
| dbo.tblaff_Leads_Commissions | Table | JOIN on LeadID, filtered by Tier=1, provides AffiliateID and SubAffiliateID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.viewUnion | View | UNION member for unified affiliate activity |
| fiktivo.report_summary | View | Subquery for daily lead count aggregation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Daily lead count by affiliate
```sql
SELECT Date, AffiliateID, COUNT(*) AS LeadCount
FROM fiktivo.viewLeads WITH (NOLOCK)
GROUP BY Date, AffiliateID
ORDER BY Date DESC, LeadCount DESC
```

### 8.2 Top campaigns by lead volume
```sql
SELECT TOP 20 AffiliateID, SerialID, COUNT(*) AS Leads
FROM fiktivo.viewLeads WITH (NOLOCK)
WHERE SerialID <> ''
GROUP BY AffiliateID, SerialID
ORDER BY Leads DESC
```

### 8.3 Leads with affiliate name resolution
```sql
SELECT v.Date, v.AffiliateID, a.Username, v.SerialID
FROM fiktivo.viewLeads v WITH (NOLOCK)
JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON v.AffiliateID = a.AffiliateID
ORDER BY v.Date DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.viewLeads | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.viewLeads.sql*
