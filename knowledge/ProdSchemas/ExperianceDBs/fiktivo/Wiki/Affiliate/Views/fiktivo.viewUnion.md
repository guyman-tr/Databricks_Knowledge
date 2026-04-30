# fiktivo.viewUnion

> Unified funnel view that combines all five affiliate conversion stages (Downloads, Installs, First Time Run, Leads, Sales) into a single dataset with a common (Date, AffiliateID, SerialID) schema.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | Date + AffiliateID + SerialID (composite) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

viewUnion is the unified affiliate conversion funnel view. It combines all five funnel-stage views (viewDownloads, viewInstalls, viewFirstTimeRun, viewLeads, viewSales) into a single dataset using UNION. Every row represents a conversion event at some stage of the funnel, normalized to the common (Date, AffiliateID, SerialID) format.

This view enables cross-funnel analysis by treating all conversion events as a single population. An affiliate's total "touches" across all funnel stages can be counted, and funnel progression patterns can be analyzed by grouping on AffiliateID and Date.

Note: The view previously also included viewImpressions (commented out, removed by Noga Rozen, 22/07/2022). UNION (not UNION ALL) is used, which means duplicate rows across stages are eliminated - if the same (Date, AffiliateID, SerialID) appears in both downloads and installs, only one row is kept. This is by design for counting unique affiliate touchpoints.

---

## 2. Business Logic

### 2.1 Funnel Stage Union

**What**: Five separate funnel stage views are combined into a single result set.

**Columns/Parameters Involved**: All columns from all 5 component views

**Rules**:
- UNION (not UNION ALL) eliminates duplicates across stages
- All 5 component views produce the same (Date, AffiliateID, SerialID) schema
- The output does NOT include a "stage" indicator column - callers cannot distinguish which funnel stage a row came from
- Order of UNION: Downloads, Installs, FirstTimeRun, Leads, Sales
- Previously included Impressions (removed 2022-07-22)

**Diagram**:
```
viewDownloads ────┐
viewInstalls ─────┤
viewFirstTimeRun ─┼──> UNION ──> viewUnion (Date, AffiliateID, SerialID)
viewLeads ────────┤
viewSales ────────┘
```

---

## 3. Data Overview

N/A - The view combines data from all five funnel views. Sample data would show a mix of download, install, lead, and sales events all in the same (Date, AffiliateID, SerialID) format with no stage indicator.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Date | datetime | YES | - | CODE-BACKED | Date of the conversion event (any funnel stage), truncated to day level. Inherited from all 5 component views. |
| 2 | AffiliateID | bigint/int | YES | - | CODE-BACKED | Affiliate attributed with the conversion event. Type varies by source: bigint from download/install views (etoro_Download.rid), int from lead/sales views (tblaff_*_Commissions.AffiliateID). |
| 3 | SerialID | nvarchar(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking code. Source varies: etoro_Download/Install.serial for downloads/installs, tblaff_*_Commissions.SubAffiliateID for leads/sales. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All columns | fiktivo.viewDownloads | UNION member | Completed downloads (status=1 from etoro_Download) |
| All columns | fiktivo.viewInstalls | UNION member | Completed installs (status=1 from etoro_Install) |
| All columns | fiktivo.viewFirstTimeRun | UNION member | First-time runs (status=3 from etoro_Install) |
| All columns | fiktivo.viewLeads | UNION member | Tier-1 leads (from dbo.tblaff_Leads) |
| All columns | fiktivo.viewSales | UNION member | Tier-1 sales (from dbo.tblaff_Sales) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

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
│     ├── dbo.tblaff_Leads (table, cross-schema)
│     └── dbo.tblaff_Leads_Commissions (table, cross-schema)
└── fiktivo.viewSales (view)
      ├── dbo.tblaff_Sales (table, cross-schema)
      └── dbo.tblaff_Sales_Commissions (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.viewDownloads | View | UNION member - completed downloads |
| fiktivo.viewInstalls | View | UNION member - completed installs |
| fiktivo.viewFirstTimeRun | View | UNION member - first-time runs |
| fiktivo.viewLeads | View | UNION member - tier-1 leads |
| fiktivo.viewSales | View | UNION member - tier-1 sales |

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Total funnel events by date
```sql
SELECT Date, COUNT(*) AS TotalEvents
FROM fiktivo.viewUnion WITH (NOLOCK)
GROUP BY Date
ORDER BY Date DESC
```

### 8.2 Total funnel events by affiliate
```sql
SELECT AffiliateID, COUNT(*) AS TotalTouchpoints
FROM fiktivo.viewUnion WITH (NOLOCK)
GROUP BY AffiliateID
ORDER BY COUNT(*) DESC
```

### 8.3 Daily affiliate activity with serial breakdown
```sql
SELECT Date, AffiliateID, SerialID, COUNT(*) AS Events
FROM fiktivo.viewUnion WITH (NOLOCK)
WHERE AffiliateID IS NOT NULL AND AffiliateID > 0
GROUP BY Date, AffiliateID, SerialID
ORDER BY Date DESC, Events DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.viewUnion | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.viewUnion.sql*
