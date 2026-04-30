# fiktivo.viewLeads

> View that extracts tier-1 lead events from the dbo affiliate leads and commissions tables, producing daily lead records with affiliate attribution for the conversion funnel union.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | View |
| **Key Identifier** | Date + AffiliateID + SerialID (composite) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

viewLeads extracts lead conversion events from the dbo.tblaff_Leads and dbo.tblaff_Leads_Commissions tables. This represents the fourth stage of the affiliate funnel: Download -> Install -> First Time Run -> **Lead** -> Sale. A "lead" in this context is a customer registration event that qualifies for affiliate commission.

Unlike the download/install views that read from fiktivo-schema tables, viewLeads reads from the cross-schema dbo tables that are shared across the main affiliate commission system. The view filters to Tier=1 commissions only, meaning it captures direct affiliate-to-lead relationships (not sub-affiliate tiers).

The view JOINs tblaff_Leads with tblaff_Leads_Commissions to get the AffiliateID and SubAffiliateID (mapped to SerialID) for each lead. The LEFT OUTER JOIN ensures all leads are included even if commission records are partially missing.

---

## 2. Business Logic

### 2.1 Tier-1 Lead Filtering

**What**: Only first-tier (direct affiliate) lead commissions are included in the funnel view.

**Columns/Parameters Involved**: `Tier`

**Rules**:
- WHERE Tier = 1 filters to direct affiliate commissions only
- Tier 2+ would represent sub-affiliate commissions, excluded from this funnel view
- AffiliateID comes from the commissions table, not the leads table
- SubAffiliateID from commissions is mapped to SerialID for funnel consistency

---

## 3. Data Overview

| Date | AffiliateID | SerialID | Meaning |
|---|---|---|---|
| 2012-07-24 | 25202 | bottom | Lead attributed to affiliate 25202 with sub-affiliate code 'bottom', likely indicating a bottom-of-page banner placement. |
| 2012-07-24 | 10099 | insider | Lead from affiliate 10099 with 'insider' sub-tracking, suggesting an insider/editorial content placement. |
| 2012-07-24 | 28600 | 00fLLXSJQMlb3e... | Lead from affiliate 28600 with a complex tracking code containing traffic source details ('traffadsmarkopenbookenglish'). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Date | datetime | YES | - | CODE-BACKED | Date of the lead event, truncated to day level. Source: CAST(FLOOR(CAST(dbo.tblaff_Leads.ORDER_DATE AS FLOAT)) AS DATETIME). |
| 2 | AffiliateID | int | YES | - | CODE-BACKED | Affiliate attributed with this lead. Source: dbo.tblaff_Leads_Commissions.AffiliateID. Only tier-1 (direct) affiliates included. |
| 3 | SerialID | nvarchar(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking code. Source: dbo.tblaff_Leads_Commissions.SubAffiliateID. Used for campaign-level attribution within an affiliate's traffic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Date | dbo.tblaff_Leads | LEFT JOIN | Lead date from ORDER_DATE |
| AffiliateID, SerialID | dbo.tblaff_Leads_Commissions | LEFT JOIN | Commission record with affiliate attribution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| fiktivo.viewUnion | All columns | UNION | Combined into the unified funnel view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.viewLeads (view)
├── dbo.tblaff_Leads (table, cross-schema)
└── dbo.tblaff_Leads_Commissions (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Leads | Table (cross-schema) | LEFT JOIN source for lead date and LeadID |
| dbo.tblaff_Leads_Commissions | Table (cross-schema) | LEFT JOIN for AffiliateID and SubAffiliateID, WHERE Tier=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| fiktivo.viewUnion | View | UNION member - contributes lead funnel stage |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Daily lead counts
```sql
SELECT Date, COUNT(*) AS Leads
FROM fiktivo.viewLeads WITH (NOLOCK)
GROUP BY Date
ORDER BY Date DESC
```

### 8.2 Top affiliates by lead volume
```sql
SELECT AffiliateID, COUNT(*) AS TotalLeads
FROM fiktivo.viewLeads WITH (NOLOCK)
GROUP BY AffiliateID
ORDER BY COUNT(*) DESC
```

### 8.3 Leads with campaign tracking codes
```sql
SELECT Date, AffiliateID, SerialID
FROM fiktivo.viewLeads WITH (NOLOCK)
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
*Object: fiktivo.viewLeads | Type: View | Source: fiktivo/fiktivo/Views/fiktivo.viewLeads.sql*
