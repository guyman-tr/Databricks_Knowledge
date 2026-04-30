# dbo.qry_aff_Tier2BonusesCommissions

> Tier 2 filter view over tblaff_Bonuses_Commissions, extracting bonuses commissions for tier 2 (parent of direct) affiliates with aliased column names for cross-tier joining.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: dbo.tblaff_Bonuses_Commissions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.qry_aff_Tier2BonusesCommissions filters the bonuses commissions table to return only tier 2 (parent of direct) records. Column names are aliased with the "Tier2" prefix (e.g., Tier2AffiliateID, Tier2Commission) to enable clean LEFT OUTER JOINs in the qry_aff_BonusesDetailAllTiers view, which pivots all 5 tiers into a single row per event.

This is one of 5 tier-filter views (Tier 1-5) for bonuses commissions. Together they feed qry_aff_BonusesDetailAllTiers.

---

## 2. Business Logic

No complex logic. Simple tier filter: WHERE Tier = 2.

---

## 3. Data Overview

Filtered subset of tblaff_Bonuses_Commissions where Tier = 2.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BonusID | int | YES | - | VERIFIED | Event ID from source. References tblaff_Bonuses.BonusID. |
| 2 | Tier2AffiliateID | int | YES | - | VERIFIED | Affiliate ID at tier 2. Aliased from AffiliateID. parent of direct affiliate. |
| 3 | Tier2Commission | float | YES | - | VERIFIED | Commission amount for tier 2. |
| 4 | Tier2Paid | bit | NO | - | VERIFIED | Payment status for this tier 2 commission. |
| 5 | Tier2SubAffiliateID | nvarchar(1024) | YES | - | VERIFIED | Sub-affiliate tracking tag for tier 2. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all) | dbo.tblaff_Bonuses_Commissions | Base table | Filtered by Tier = 2 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.qry_aff_BonusesDetailAllTiers | LEFT OUTER JOIN | View | All-tiers pivot joins this for tier 2 data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.qry_aff_Tier2BonusesCommissions (view)
  +-- dbo.tblaff_Bonuses_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Bonuses_Commissions | Table | Base table (WHERE Tier = 2) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.qry_aff_BonusesDetailAllTiers | View | LEFT OUTER JOIN for tier 2 pivot |

---

## 7. Technical Details

N/A for view.

---

## 8. Sample Queries

### 8.1 Tier 2 bonuses commissions for an affiliate
```sql
SELECT BonusID, Tier2Commission, Tier2Paid
FROM dbo.qry_aff_Tier2BonusesCommissions WITH (NOLOCK)
WHERE Tier2AffiliateID = @AffiliateID
```

### 8.2 Total unpaid tier 2 bonuses commissions
```sql
SELECT Tier2AffiliateID, SUM(Tier2Commission) AS TotalUnpaid
FROM dbo.qry_aff_Tier2BonusesCommissions WITH (NOLOCK)
WHERE Tier2Paid = 0
GROUP BY Tier2AffiliateID ORDER BY TotalUnpaid DESC
```

### 8.3 Count tier 2 records
```sql
SELECT COUNT(*) AS TierRecords FROM dbo.qry_aff_Tier2BonusesCommissions WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.qry_aff_Tier2BonusesCommissions | Type: View | Source: fiktivo/dbo/Views/dbo.qry_aff_Tier2BonusesCommissions.sql*
