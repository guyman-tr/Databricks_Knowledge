# dbo.qry_aff_Tier5SalesCommissions

> Tier 5 filter view over tblaff_Sales_Commissions, extracting sales commissions for tier 5 (great-great-grandparent) affiliates with aliased column names for cross-tier joining.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: dbo.tblaff_Sales_Commissions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.qry_aff_Tier5SalesCommissions filters the sales commissions table to return only tier 5 (great-great-grandparent) records. Column names are aliased with the "Tier5" prefix (e.g., Tier5AffiliateID, Tier5Commission) to enable clean LEFT OUTER JOINs in the qry_aff_SalesDetailAllTiers view, which pivots all 5 tiers into a single row per event.

This is one of 5 tier-filter views (Tier 1-5) for sales commissions. Together they feed qry_aff_SalesDetailAllTiers.

---

## 2. Business Logic

No complex logic. Simple tier filter: WHERE Tier = 5.

---

## 3. Data Overview

Filtered subset of tblaff_Sales_Commissions where Tier = 5.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SalesID | int | YES | - | VERIFIED | Event ID from source. References tblaff_Sales.SalesID. |
| 2 | Tier5AffiliateID | int | YES | - | VERIFIED | Affiliate ID at tier 5. Aliased from AffiliateID. great-great-grandparent affiliate. |
| 3 | Tier5Commission | float | YES | - | VERIFIED | Commission amount for tier 5. |
| 4 | Tier5Paid | bit | NO | - | VERIFIED | Payment status for this tier 5 commission. |
| 5 | Tier5SubAffiliateID | nvarchar(1024) | YES | - | VERIFIED | Sub-affiliate tracking tag for tier 5. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all) | dbo.tblaff_Sales_Commissions | Base table | Filtered by Tier = 5 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.qry_aff_SalesDetailAllTiers | LEFT OUTER JOIN | View | All-tiers pivot joins this for tier 5 data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.qry_aff_Tier5SalesCommissions (view)
  +-- dbo.tblaff_Sales_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Sales_Commissions | Table | Base table (WHERE Tier = 5) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.qry_aff_SalesDetailAllTiers | View | LEFT OUTER JOIN for tier 5 pivot |

---

## 7. Technical Details

N/A for view.

---

## 8. Sample Queries

### 8.1 Tier 5 sales commissions for an affiliate
```sql
SELECT SalesID, Tier5Commission, Tier5Paid
FROM dbo.qry_aff_Tier5SalesCommissions WITH (NOLOCK)
WHERE Tier5AffiliateID = @AffiliateID
```

### 8.2 Total unpaid tier 5 sales commissions
```sql
SELECT Tier5AffiliateID, SUM(Tier5Commission) AS TotalUnpaid
FROM dbo.qry_aff_Tier5SalesCommissions WITH (NOLOCK)
WHERE Tier5Paid = 0
GROUP BY Tier5AffiliateID ORDER BY TotalUnpaid DESC
```

### 8.3 Count tier 5 records
```sql
SELECT COUNT(*) AS TierRecords FROM dbo.qry_aff_Tier5SalesCommissions WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.qry_aff_Tier5SalesCommissions | Type: View | Source: fiktivo/dbo/Views/dbo.qry_aff_Tier5SalesCommissions.sql*
