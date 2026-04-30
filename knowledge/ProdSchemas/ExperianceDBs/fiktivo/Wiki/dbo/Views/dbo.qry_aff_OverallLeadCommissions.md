# dbo.qry_aff_OverallLeadCommissions

> System-wide aggregation view summarizing total lead commission counts and amounts grouped by tier, showing how lead commission volume distributes across all 5 affiliate tiers.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Aggregate by Tier across tblaff_Leads + tblaff_Leads_Commissions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.qry_aff_OverallLeadCommissions provides a system-wide summary of lead commission activity broken down by tier level. It joins the lead event table (tblaff_Leads) with the commission table (tblaff_Leads_Commissions) and aggregates event count and total commissions for each of the 5 affiliate tiers across the entire program.

This is a global summary view -- it is not scoped to a specific affiliate. Finance and program managers use it to understand the distribution of lead-model commission outflow across the tier hierarchy. Unlike the sales model, lead events do not carry a gross sale value (GRAND_TOTAL), so the summary exposes event count and commission total only. It is the lead-model counterpart to qry_aff_OverallTierCommissions.

Only affiliate-accepted, valid lead events are included, matching the standard payment-eligibility gate applied throughout the affiliate system.

---

## 2. Business Logic

### 2.1 Payment Eligibility Filter

**What**: Restricts aggregation to lead events that qualify for commission payout.

**Columns/Parameters Involved**: `AffiliateSaleAccepted`, `Valid`

**Rules**:
- `AffiliateSaleAccepted <> 0`: the lead was attributed to an affiliate (any non-zero value accepted)
- `Valid <> 0`: the lead passed internal validation (not reversed, not fraudulent)
- Both conditions must be satisfied; failing either gate excludes the event from all tier totals

### 2.2 Tier Grouping

**What**: Groups all qualifying records by Tier and sums commissions per tier.

**Columns/Parameters Involved**: `Tier`, `Commission`, `LeadID`

**Rules**:
- GROUP BY Tier produces one summary row per tier level that has qualifying events
- COUNT(LeadID) counts qualifying lead events at that tier
- SUM(Commission) sums the commission amount owed at that tier
- Result set ordered by Tier in ascending order (1 through 5)

---

## 3. Data Overview

Returns up to 5 rows -- one per tier level with at least one qualifying lead event. Tier 1 typically dominates both CountOfLeadID and SumOfCommission. Upper tiers reflect override commissions earned by parent affiliates who recruited the direct (tier 1) referrer.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountOfLeadID | int | YES | - | VERIFIED | Count of qualifying lead events for this tier. Derived from COUNT(LeadID) on tblaff_Leads_Commissions. |
| 2 | Tier | int | YES | - | VERIFIED | Tier level (1-5). The grouping key. Tier 1 = direct/referring affiliate; Tiers 2-5 = parent levels up the recruitment chain. |
| 3 | SumOfCommission | float | YES | - | VERIFIED | Sum of commission amounts owed to affiliates at this tier. Sourced from tblaff_Leads_Commissions.Commission. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LeadID, AffiliateSaleAccepted, Valid | dbo.tblaff_Leads | Base table | Source of lead event records and eligibility flags |
| Tier, Commission | dbo.tblaff_Leads_Commissions | JOIN on LeadID | Source of tier level and commission amounts |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Finance / program management reporting | FROM | Consumer (reporting) | Tier-level lead commission distribution analysis |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.qry_aff_OverallLeadCommissions (view)
  +-- dbo.tblaff_Leads (table)
  +-- dbo.tblaff_Leads_Commissions (table, JOIN on LeadID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Leads | Table | Source of LeadID, AffiliateSaleAccepted, Valid |
| dbo.tblaff_Leads_Commissions | Table | Source of Tier and Commission; JOIN on LeadID |

### 6.2 Objects That Depend On This

No dependents registered. Used by reporting and finance tooling at runtime.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view (not indexed/materialized). Performance depends on indexes on tblaff_Leads and tblaff_Leads_Commissions; filtering on AffiliateSaleAccepted and Valid benefits from a composite index on those columns.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Full tier lead commission summary
```sql
SELECT Tier, CountOfLeadID, SumOfCommission
FROM dbo.qry_aff_OverallLeadCommissions WITH (NOLOCK)
ORDER BY Tier
```

### 8.2 Average commission per lead by tier
```sql
SELECT Tier,
       CountOfLeadID,
       SumOfCommission,
       CASE WHEN CountOfLeadID > 0
            THEN SumOfCommission / CountOfLeadID
            ELSE NULL END AS AvgCommissionPerLead
FROM dbo.qry_aff_OverallLeadCommissions WITH (NOLOCK)
ORDER BY Tier
```

### 8.3 Tier commission share as percentage of program total
```sql
SELECT Tier,
       CountOfLeadID,
       SumOfCommission,
       SumOfCommission / SUM(SumOfCommission) OVER () * 100 AS PctOfTotalCommission
FROM dbo.qry_aff_OverallLeadCommissions WITH (NOLOCK)
ORDER BY Tier
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.qry_aff_OverallLeadCommissions | Type: View | Source: fiktivo/dbo/Views/dbo.qry_aff_OverallLeadCommissions.sql*
