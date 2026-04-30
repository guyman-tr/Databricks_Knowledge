# dbo.qry_aff_Tier3CopyTradersCommissions

> Tier 3 filter view over tblaff_CopyTraders_Commissions, extracting copytraders commissions for tier 3 (grandparent) affiliates with aliased column names for cross-tier joining.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: dbo.tblaff_CopyTraders_Commissions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.qry_aff_Tier3CopyTradersCommissions filters the copytraders commissions table to return only tier 3 (grandparent) records. Column names are aliased with the "Tier3" prefix (e.g., Tier3AffiliateID, Tier3Commission) to enable clean LEFT OUTER JOINs in the qry_aff_CopyTraderDetailAllTiers view, which pivots all 5 tiers into a single row per event.

This is one of 5 tier-filter views (Tier 1-5) for copytraders commissions. Together they feed qry_aff_CopyTraderDetailAllTiers.

---

## 2. Business Logic

No complex logic. Simple tier filter: WHERE Tier = 3.

---

## 3. Data Overview

Filtered subset of tblaff_CopyTraders_Commissions where Tier = 3.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CopyTraderID | int | YES | - | VERIFIED | Event ID from source. References tblaff_CopyTraders.CopyTraderID. |
| 2 | Tier3AffiliateID | int | YES | - | VERIFIED | Affiliate ID at tier 3. Aliased from AffiliateID. grandparent affiliate. |
| 3 | Tier3Commission | float | YES | - | VERIFIED | Commission amount for tier 3. |
| 4 | Tier3Paid | bit | NO | - | VERIFIED | Payment status for this tier 3 commission. |
| 5 | Tier3SubAffiliateID | nvarchar(1024) | YES | - | VERIFIED | Sub-affiliate tracking tag for tier 3. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all) | dbo.tblaff_CopyTraders_Commissions | Base table | Filtered by Tier = 3 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.qry_aff_CopyTraderDetailAllTiers | LEFT OUTER JOIN | View | All-tiers pivot joins this for tier 3 data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.qry_aff_Tier3CopyTradersCommissions (view)
  +-- dbo.tblaff_CopyTraders_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_CopyTraders_Commissions | Table | Base table (WHERE Tier = 3) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.qry_aff_CopyTraderDetailAllTiers | View | LEFT OUTER JOIN for tier 3 pivot |

---

## 7. Technical Details

N/A for view.

---

## 8. Sample Queries

### 8.1 Tier 3 copytraders commissions for an affiliate
```sql
SELECT CopyTraderID, Tier3Commission, Tier3Paid
FROM dbo.qry_aff_Tier3CopyTradersCommissions WITH (NOLOCK)
WHERE Tier3AffiliateID = @AffiliateID
```

### 8.2 Total unpaid tier 3 copytraders commissions
```sql
SELECT Tier3AffiliateID, SUM(Tier3Commission) AS TotalUnpaid
FROM dbo.qry_aff_Tier3CopyTradersCommissions WITH (NOLOCK)
WHERE Tier3Paid = 0
GROUP BY Tier3AffiliateID ORDER BY TotalUnpaid DESC
```

### 8.3 Count tier 3 records
```sql
SELECT COUNT(*) AS TierRecords FROM dbo.qry_aff_Tier3CopyTradersCommissions WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.qry_aff_Tier3CopyTradersCommissions | Type: View | Source: fiktivo/dbo/Views/dbo.qry_aff_Tier3CopyTradersCommissions.sql*
