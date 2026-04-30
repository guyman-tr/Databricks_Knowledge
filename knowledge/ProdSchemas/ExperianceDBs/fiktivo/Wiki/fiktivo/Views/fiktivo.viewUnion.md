# fiktivo.viewUnion

> Unified affiliate activity view that combines downloads, installs, first-time runs, leads, and sales into a single dataset with a common (Date, AffiliateID, SerialID) schema for cross-channel reporting.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | Base views: viewDownloads, viewInstalls, viewFirstTimeRun, viewLeads, viewSales |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view is the top-level aggregation point for affiliate activity reporting. It UNIONs five event-specific views - downloads, installs, first-time runs, leads, and sales - into a single dataset where every row has the same three columns: Date, AffiliateID, and SerialID. This enables querying all affiliate-attributed events in one place.

The UNION (not UNION ALL) eliminates duplicates across event types for the same (Date, AffiliateID, SerialID) combination. This means if an affiliate has both a download and a lead on the same day with the same serial, only one row appears. This is useful for counting "days with any activity" per affiliate rather than total events.

Note: The original implementation included impressions (viewImpressions) but this was commented out (removed by Noga Rozen, 22/7/22), consistent with the report_summary view where Impressions and Clicks were also zeroed out.

---

## 2. Business Logic

### 2.1 Cross-Channel Activity Union

**What**: Combines five affiliate event types into a single standardized dataset.

**Columns/Parameters Involved**: `Date`, `AffiliateID`, `SerialID`

**Rules**:
- UNION (deduplicated) of: viewDownloads, viewInstalls, viewFirstTimeRun, viewLeads, viewSales
- All component views output the same schema: (Date DATETIME, AffiliateID BIGINT/INT, SerialID NVARCHAR)
- UNION removes exact duplicates across views
- Does NOT distinguish event type - a row could be a download, install, lead, or sale
- viewImpressions was removed from the UNION (commented out)

**Diagram**:
```
viewDownloads   ----+
viewInstalls    ----+
viewFirstTimeRun ---+--> UNION --> viewUnion (Date, AffiliateID, SerialID)
viewLeads       ----+
viewSales       ----+
```

---

## 3. Data Overview

| Date | AffiliateID | SerialID | Meaning |
|------|-------------|----------|---------|
| 2012-07-24 | 22397 | http://www.google.co.uk/url?sa=t | Activity from affiliate 22397 on this date. Could be a lead, sale, install, or download. The Google referrer URL in SerialID suggests SEO-driven traffic. |
| 2012-01-13 | 4802 | http://www.etoro.it/why-etoro/trade-registration.aspx | Activity from affiliate 4802 with Italian eToro registration page referrer. |
| 2012-01-13 | 3 | (empty) | Activity from the house affiliate (ID=3) with no sub-affiliate tracking. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Date | DATETIME | YES | - | CODE-BACKED | Event date truncated to midnight. Inherited from component views. Common date dimension across all event types. |
| 2 | AffiliateID | BIGINT/INT | YES | - | CODE-BACKED | Affiliate who drove the activity. Sourced from rid (downloads/installs) or Commissions.AffiliateID (leads/sales). Unifies attribution across event types. |
| 3 | SerialID | NVARCHAR | YES | - | CODE-BACKED | Sub-affiliate tracking identifier. Sourced from serial (downloads/installs) or SubAffiliateID (leads/sales). Contains campaign identifiers, referrer URLs, or tracking tokens. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (UNION) | [fiktivo.viewDownloads](fiktivo.viewDownloads.md) | View dependency | Completed downloads with affiliate attribution. |
| (UNION) | [fiktivo.viewInstalls](fiktivo.viewInstalls.md) | View dependency | Completed installs with affiliate attribution. |
| (UNION) | [fiktivo.viewFirstTimeRun](fiktivo.viewFirstTimeRun.md) | View dependency | First-time application runs with affiliate attribution. |
| (UNION) | [fiktivo.viewLeads](fiktivo.viewLeads.md) | View dependency | Tier 1 lead events with affiliate attribution. |
| (UNION) | [fiktivo.viewSales](fiktivo.viewSales.md) | View dependency | Tier 1 sales events with affiliate attribution. |

### 5.2 Referenced By (other objects point to this)

No objects in the fiktivo schema reference this view.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.viewUnion (view)
    ├── fiktivo.viewDownloads (view)
    │     └── fiktivo.etoro_Download (table)
    ├── fiktivo.viewInstalls (view)
    │     └── fiktivo.etoro_Install (table)
    ├── fiktivo.viewFirstTimeRun (view)
    │     └── fiktivo.etoro_Install (table)
    ├── fiktivo.viewLeads (view)
    │     ├── dbo.tblaff_Leads (table)
    │     └── dbo.tblaff_Leads_Commissions (table)
    └── fiktivo.viewSales (view)
          ├── dbo.tblaff_Sales (table)
          └── dbo.tblaff_Sales_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.viewDownloads | View | UNION member - completed downloads |
| fiktivo.viewInstalls | View | UNION member - completed installs |
| fiktivo.viewFirstTimeRun | View | UNION member - first-time runs |
| fiktivo.viewLeads | View | UNION member - Tier 1 leads |
| fiktivo.viewSales | View | UNION member - Tier 1 sales |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 All activity for a specific affiliate
```sql
SELECT Date, AffiliateID, SerialID
FROM fiktivo.viewUnion WITH (NOLOCK)
WHERE AffiliateID = 22397
ORDER BY Date DESC
```

### 8.2 Daily active affiliates count
```sql
SELECT Date, COUNT(DISTINCT AffiliateID) AS ActiveAffiliates
FROM fiktivo.viewUnion WITH (NOLOCK)
WHERE Date IS NOT NULL
GROUP BY Date
ORDER BY Date DESC
```

### 8.3 Top affiliates by activity days
```sql
SELECT TOP 20 AffiliateID, COUNT(DISTINCT Date) AS ActiveDays
FROM fiktivo.viewUnion WITH (NOLOCK)
WHERE Date IS NOT NULL
GROUP BY AffiliateID
ORDER BY ActiveDays DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.viewUnion | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.viewUnion.sql*
