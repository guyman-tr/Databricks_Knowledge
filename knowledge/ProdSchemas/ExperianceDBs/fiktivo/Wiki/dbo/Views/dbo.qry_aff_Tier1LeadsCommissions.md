# dbo.qry_aff_Tier1LeadsCommissions

> Tier 1 filter view over tblaff_Leads_Commissions, extracting leads commissions for tier 1 (direct/referring) affiliates with aliased column names for cross-tier joining.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: dbo.tblaff_Leads_Commissions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.qry_aff_Tier1LeadsCommissions filters the leads commissions table to return only tier 1 (direct/referring) records. Column names are aliased with the "Tier1" prefix (e.g., Tier1AffiliateID, Tier1Commission) to enable clean LEFT OUTER JOINs in the qry_aff_LeadDetailAllTiers view, which pivots all 5 tiers into a single row per event.

This is one of 5 tier-filter views (Tier 1-5) for leads commissions. Together they feed qry_aff_LeadDetailAllTiers.

---

## 2. Business Logic

No complex logic. Simple tier filter: WHERE Tier = 1.

---

## 3. Data Overview

Filtered subset of tblaff_Leads_Commissions where Tier = 1.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LeadID | int | YES | - | VERIFIED | Event ID from source. References tblaff_Leads.LeadID. |
| 2 | Tier1AffiliateID | int | YES | - | VERIFIED | Affiliate ID at tier 1. Aliased from AffiliateID. direct/referring affiliate. |
| 3 | Tier1Commission | float | YES | - | VERIFIED | Commission amount for tier 1. |
| 4 | Tier1Paid | bit | NO | - | VERIFIED | Payment status for this tier 1 commission. |
| 5 | Tier1SubAffiliateID | nvarchar(1024) | YES | - | VERIFIED | Sub-affiliate tracking tag for tier 1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all) | dbo.tblaff_Leads_Commissions | Base table | Filtered by Tier = 1 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.qry_aff_LeadDetailAllTiers | LEFT OUTER JOIN | View | All-tiers pivot joins this for tier 1 data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.qry_aff_Tier1LeadsCommissions (view)
  +-- dbo.tblaff_Leads_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Leads_Commissions | Table | Base table (WHERE Tier = 1) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.qry_aff_LeadDetailAllTiers | View | LEFT OUTER JOIN for tier 1 pivot |

---

## 7. Technical Details

N/A for view.

---

## 8. Sample Queries

### 8.1 Tier 1 leads commissions for an affiliate
```sql
SELECT LeadID, Tier1Commission, Tier1Paid
FROM dbo.qry_aff_Tier1LeadsCommissions WITH (NOLOCK)
WHERE Tier1AffiliateID = @AffiliateID
```

### 8.2 Total unpaid tier 1 leads commissions
```sql
SELECT Tier1AffiliateID, SUM(Tier1Commission) AS TotalUnpaid
FROM dbo.qry_aff_Tier1LeadsCommissions WITH (NOLOCK)
WHERE Tier1Paid = 0
GROUP BY Tier1AffiliateID ORDER BY TotalUnpaid DESC
```

### 8.3 Count tier 1 records
```sql
SELECT COUNT(*) AS TierRecords FROM dbo.qry_aff_Tier1LeadsCommissions WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.qry_aff_Tier1LeadsCommissions | Type: View | Source: fiktivo/dbo/Views/dbo.qry_aff_Tier1LeadsCommissions.sql*
