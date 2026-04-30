# dbo.qry_aff_OverallTierCommissions

> System-wide aggregation view summarizing total sales commissions and grand totals grouped by tier, showing how commission volume distributes across all 5 affiliate tiers.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Aggregate by Tier across tblaff_Sales + tblaff_Sales_Commissions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.qry_aff_OverallTierCommissions provides a system-wide summary of sales commission activity broken down by tier level. It joins the sales event table (tblaff_Sales) with the commission table (tblaff_Sales_Commissions) and aggregates count, gross sale value, and total commissions for each of the 5 affiliate tiers across the entire program.

This is a global summary view -- it is not filtered to a specific affiliate. Finance and program managers use it to understand how commissions are distributed across the tier hierarchy: for example, what proportion of total commission outflow goes to direct (tier 1) affiliates versus parent/grandparent tiers (tiers 2-5). It is the sales-model counterpart to qry_aff_OverallLeadCommissions.

Only affiliate-accepted, valid events are included, matching the standard payment-eligibility gate applied throughout the affiliate system.

---

## 2. Business Logic

### 2.1 Payment Eligibility Filter

**What**: Restricts aggregation to events that qualify for commission payout.

**Columns/Parameters Involved**: `AffiliateSaleAccepted`, `Valid`

**Rules**:
- `AffiliateSaleAccepted <> 0`: the sale was attributed to an affiliate (any non-zero value accepted)
- `Valid <> 0`: the sale passed internal validation (not reversed, not fraudulent)
- Both conditions must be satisfied; failing either gate excludes the event from all tier totals

### 2.2 Tier Grouping and Ordering

**What**: Groups all qualifying records by Tier and sums commissions and sale values per tier.

**Columns/Parameters Involved**: `Tier`, `GRAND_TOTAL`, `Commission`, `SalesID`

**Rules**:
- GROUP BY Tier produces one summary row per tier level
- COUNT(SalesID) counts distinct qualifying sale events for that tier
- SUM(GRAND_TOTAL) sums the gross sale amount for those events
- SUM(Commission) sums the commission amount owed at that tier
- ORDER BY Tier returns results in ascending tier order (1 through 5)

---

## 3. Data Overview

Returns up to 5 rows -- one per tier level that has at least one qualifying sale event. Tier 1 (direct affiliates) typically shows the highest CountOfSalesID and SumOfCommission values. Tiers 2-5 accumulate lower aggregate totals reflecting the override/residual nature of upper-tier commissions.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountOfSalesID | int | YES | - | VERIFIED | Count of qualifying sale events for this tier. Derived from COUNT(SalesID) on tblaff_Sales_Commissions. |
| 2 | SumOfGRAND_TOTAL | float | YES | - | VERIFIED | Sum of gross sale value (GRAND_TOTAL) across all qualifying events at this tier. Sourced from tblaff_Sales. |
| 3 | Tier | int | YES | - | VERIFIED | Tier level (1-5). The grouping key. Tier 1 = direct/referring affiliate; Tiers 2-5 = parent levels up the recruitment chain. |
| 4 | SumOfCommission | float | YES | - | VERIFIED | Sum of commission amounts owed to affiliates at this tier. Sourced from tblaff_Sales_Commissions.Commission. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SalesID, AffiliateSaleAccepted, Valid, GRAND_TOTAL | dbo.tblaff_Sales | Base table | Source of sale event records and eligibility flags |
| Tier, Commission | dbo.tblaff_Sales_Commissions | JOIN on SalesID | Source of tier level and commission amounts |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Finance / program management reporting | FROM | Consumer (reporting) | Tier-level commission distribution analysis |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.qry_aff_OverallTierCommissions (view)
  +-- dbo.tblaff_Sales (table)
  +-- dbo.tblaff_Sales_Commissions (table, JOIN on SalesID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Sales | Table | Source of SalesID, GRAND_TOTAL, AffiliateSaleAccepted, Valid |
| dbo.tblaff_Sales_Commissions | Table | Source of Tier and Commission; JOIN on SalesID |

### 6.2 Objects That Depend On This

No dependents registered. Used by reporting and finance tooling at runtime.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view (not indexed/materialized). Performance depends on indexes on tblaff_Sales and tblaff_Sales_Commissions; filtering on AffiliateSaleAccepted and Valid benefits from a composite index on those columns.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Full tier commission summary
```sql
SELECT Tier, CountOfSalesID, SumOfGRAND_TOTAL, SumOfCommission
FROM dbo.qry_aff_OverallTierCommissions WITH (NOLOCK)
ORDER BY Tier
```

### 8.2 Average commission per sale by tier
```sql
SELECT Tier,
       CountOfSalesID,
       SumOfCommission,
       CASE WHEN CountOfSalesID > 0
            THEN SumOfCommission / CountOfSalesID
            ELSE NULL END AS AvgCommissionPerSale
FROM dbo.qry_aff_OverallTierCommissions WITH (NOLOCK)
ORDER BY Tier
```

### 8.3 Commission as a percentage of gross sales by tier
```sql
SELECT Tier,
       SumOfGRAND_TOTAL,
       SumOfCommission,
       CASE WHEN SumOfGRAND_TOTAL > 0
            THEN CAST(SumOfCommission AS float) / SumOfGRAND_TOTAL * 100
            ELSE NULL END AS CommissionPct
FROM dbo.qry_aff_OverallTierCommissions WITH (NOLOCK)
ORDER BY Tier
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.qry_aff_OverallTierCommissions | Type: View | Source: fiktivo/dbo/Views/dbo.qry_aff_OverallTierCommissions.sql*
