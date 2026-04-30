# dbo.qry_aff_Tier4UsedBonusCommissions

> Tier 4 filter view over tblaff_Sales_Commissions, extracting used bonus commission deductions for tier 4 (great-grandparent) affiliates with aliased column names for cross-tier joining.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: dbo.tblaff_Sales_Commissions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.qry_aff_Tier4UsedBonusCommissions filters the sales commissions table to return only tier 4 (great-grandparent) records, selecting the UsedBonusCommission column (bonus offset amount) aliased as Tier4Commission. Column names are aliased with the "Tier4" prefix (e.g., Tier4AffiliateID, Tier4Commission) to enable clean LEFT OUTER JOINs in the qry_aff_UsedBonusDetailAllTiers view, which pivots all 5 tiers into a single row per event.

This is one of 5 tier-filter views (Tier 1-5) for used bonus commission deductions. Together they feed qry_aff_UsedBonusDetailAllTiers.

---

## 2. Business Logic

No complex logic. Simple tier filter: WHERE Tier = 4. Selects UsedBonusCommission (not regular Commission) to surface the bonus offset amounts applied against earned commissions.

---

## 3. Data Overview

Filtered subset of tblaff_Sales_Commissions where Tier = 4, projecting UsedBonusCommission as the commission column.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SalesID | int | YES | - | VERIFIED | Event ID from source. References tblaff_Sales.SalesID. |
| 2 | Tier4AffiliateID | int | YES | - | VERIFIED | Affiliate ID at tier 4. Aliased from AffiliateID. great-grandparent affiliate. |
| 3 | Tier4Commission | float | YES | - | VERIFIED | Used bonus commission deduction for tier 4. Aliased from UsedBonusCommission (bonus offset amount, not regular Commission). |
| 4 | Tier4Paid | bit | NO | - | VERIFIED | Payment status for this tier 4 commission. |
| 5 | Tier4SubAffiliateID | nvarchar(1024) | YES | - | VERIFIED | Sub-affiliate tracking tag for tier 4. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all) | dbo.tblaff_Sales_Commissions | Base table | Filtered by Tier = 4 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.qry_aff_UsedBonusDetailAllTiers | LEFT OUTER JOIN | View | All-tiers pivot joins this for tier 4 data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.qry_aff_Tier4UsedBonusCommissions (view)
  +-- dbo.tblaff_Sales_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Sales_Commissions | Table | Base table (WHERE Tier = 4, UsedBonusCommission column) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.qry_aff_UsedBonusDetailAllTiers | View | LEFT OUTER JOIN for tier 4 pivot |

---

## 7. Technical Details

N/A for view.

---

## 8. Sample Queries

### 8.1 Tier 4 used bonus commissions for an affiliate
```sql
SELECT SalesID, Tier4Commission, Tier4Paid
FROM dbo.qry_aff_Tier4UsedBonusCommissions WITH (NOLOCK)
WHERE Tier4AffiliateID = @AffiliateID
```

### 8.2 Total unpaid tier 4 used bonus commissions
```sql
SELECT Tier4AffiliateID, SUM(Tier4Commission) AS TotalUnpaid
FROM dbo.qry_aff_Tier4UsedBonusCommissions WITH (NOLOCK)
WHERE Tier4Paid = 0
GROUP BY Tier4AffiliateID ORDER BY TotalUnpaid DESC
```

### 8.3 Count tier 4 records
```sql
SELECT COUNT(*) AS TierRecords FROM dbo.qry_aff_Tier4UsedBonusCommissions WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.qry_aff_Tier4UsedBonusCommissions | Type: View | Source: fiktivo/dbo/Views/dbo.qry_aff_Tier4UsedBonusCommissions.sql*
