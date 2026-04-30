# fiktivo.spafw_LeadsInPast60Days

> Returns a daily summary of lead counts and commission totals for a specific affiliate over the past 60 days, grouped by date and ordered most recent first.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Result set: TotalLeads, LeadCommission, DateDay, DateMonth, DateYear |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a reporting procedure that provides a 60-day rolling window of lead activity for a given affiliate. It returns daily aggregates of lead counts and their associated commission amounts, enabling affiliates to see their recent lead performance trends on a day-by-day basis.

The procedure is designed for the affiliate dashboard or reporting interface, giving affiliates visibility into how many valid, accepted leads they have generated each day over the last two months, along with the total commission earned per day.

Only Tier 1 commissions (direct, not sub-affiliate) are included, and only leads that are both Valid and AffiliateSaleAccepted are counted.

---

## 2. Business Logic

### 2.1 60-Day Rolling Window Lead Aggregation

**What**: Aggregates lead counts and commissions per day for the last 60 days.

**Columns/Parameters Involved**: `@AffiliateID`, `tblaff_Leads.ORDER_DATE`, `tblaff_Leads_Commissions.Commission`

**Rules**:
- Joins tblaff_Leads to tblaff_Leads_Commissions on LeadID
- Filters to Tier = 1 only (direct affiliate commissions)
- Filters to Valid <> 0 (lead must be valid)
- Filters to AffiliateSaleAccepted <> 0 (lead must be accepted by affiliate)
- Filters to AffiliateID = @AffiliateID on the commissions table
- Date filter: ORDER_DATE >= DATEADD(dd, -60, GETDATE())
- Groups by day (DatePart dd), month (DatePart mm), year (DatePart yyyy)
- Orders by year DESC, month DESC, day DESC (most recent first)

### 2.2 LEFT JOIN Strategy

**What**: Uses LEFT JOIN from leads to commissions.

**Rules**:
- LEFT JOIN tblaff_Leads_Commissions ON LeadID allows lead rows without commissions to appear
- However, WHERE clause filters on Tier and AffiliateID effectively convert it to an INNER JOIN at runtime
- COUNT counts LeadIDs, SUM aggregates Commission amounts

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID (IN) | INT | NO | - | CODE-BACKED | The affiliate ID to retrieve lead data for. Filters on tblaff_Leads_Commissions.AffiliateID. |

**Result Set Columns**:

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | TotalLeads | INT | Count of valid, accepted leads for the day |
| 2 | LeadCommission | FLOAT | Sum of Tier 1 commissions for leads on the day |
| 3 | DateDay | INT | Day of month (1-31) from ORDER_DATE |
| 4 | DateMonth | INT | Month number (1-12) from ORDER_DATE |
| 5 | DateYear | INT | Four-digit year from ORDER_DATE |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | dbo.tblaff_Leads | Table read | Source of lead records and ORDER_DATE |
| (SELECT) | dbo.tblaff_Leads_Commissions | Table read | Source of commission amounts, Tier, and AffiliateID filter |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.spafw_LeadsInPast60Days (procedure)
    ├── dbo.tblaff_Leads (table)
    └── dbo.tblaff_Leads_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Leads | Table | SELECT - lead records with ORDER_DATE and validity flags |
| dbo.tblaff_Leads_Commissions | Table | SELECT - commission amounts, Tier, AffiliateID, and join key |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Session Settings

- SET ANSI_NULLS OFF
- SET QUOTED_IDENTIFIER OFF

---

## 8. Sample Queries

### 8.1 Get leads in past 60 days for an affiliate
```sql
EXEC fiktivo.spafw_LeadsInPast60Days @AffiliateID = 100
```

### 8.2 Verify lead data manually
```sql
SELECT COUNT(l.LeadID) AS TotalLeads, SUM(lc.Commission) AS LeadCommission,
       CAST(l.ORDER_DATE AS DATE) AS LeadDate
FROM dbo.tblaff_Leads l
    INNER JOIN dbo.tblaff_Leads_Commissions lc ON l.LeadID = lc.LeadID
WHERE lc.Tier = 1 AND l.Valid <> 0 AND l.AffiliateSaleAccepted <> 0
    AND lc.AffiliateID = 100
    AND l.ORDER_DATE >= DATEADD(dd, -60, GETDATE())
GROUP BY CAST(l.ORDER_DATE AS DATE)
ORDER BY CAST(l.ORDER_DATE AS DATE) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.spafw_LeadsInPast60Days | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.spafw_LeadsInPast60Days.sql*
