# dbo.GetAffiliateStats

> Returns daily aggregated commission statistics (commissions earned, registration count, FTD count, valid FTD count) for a given affiliate, tier, and date range across all event types.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | affiliateId + tier + fromDate/toDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the core reporting engine for the affiliate Partners portal dashboard. It aggregates commission activity for a specific affiliate across five event types (registrations, CPA deposits, sales, bonuses, chargebacks) and returns one row per calendar day showing total commissions earned and counts of key milestones. The @tier parameter enables the view to show either the affiliate's own direct activity (Tier 2) or cascaded downstream activity from recruited sub-affiliates (Tiers 3-5). Created by Ran Ovadia (July 2019), with a RECOMPILE hint added (May 2020) to handle parameter sniffing on the large date-range queries.

---

## 2. Business Logic

- Builds a UNION ALL of five sub-queries, each reading from a commission join table paired with its parent event table:
  1. Registrations: tblaff_Registrations_Commissions JOIN tblaff_Registrations (ORDER_DATE range, Tier filter)
  2. CPA: tblaff_CPA_Commissions JOIN tblaff_CPA (ORDER_DATE range, Tier filter; Optional2 column used for FTD flag)
  3. Sales: tblaff_Sales_Commissions JOIN tblaff_Sales
  4. Bonuses: tblaff_Bonuses_Commissions JOIN tblaff_Bonuses
  5. Chargebacks: tblaff_Chargebacks_Commissions JOIN tblaff_Chargebacks
- All tables use NOLOCK.
- The outer query groups by CONVERT(date, DT) and aggregates:
  - Commission: SUM where IsValid = 1.
  - CountReg: COUNT of 'Reg' type rows.
  - CountFTD: COUNT of 'CPA' rows where Optional (Optional2) = 1.
  - CountFTDE: COUNT of 'CPA' rows where Optional = 1 AND IsValid = 1 (effective/approved FTDs).
- OPTION (RECOMPILE) prevents parameter sniffing issues with variable date ranges.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @affiliateId | INT | IN | (required) | High | Affiliate whose commission stats are being aggregated |
| 2 | @fromDate | DATETIME | IN | (required) | High | Start of the date range (inclusive, based on ORDER_DATE) |
| 3 | @toDate | DATETIME | IN | (required) | High | End of the date range (exclusive, ORDER_DATE < @toDate) |
| 4 | @tier | INT | IN | (required) | High | Tier level to filter (2 = direct, 3-5 = sub-affiliate tiers) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | dbo.tblaff_Registrations_Commissions | Read | Commission rows for registration events |
| JOIN | dbo.tblaff_Registrations | Read | Registration event dates |
| JOIN | dbo.tblaff_CPA_Commissions | Read | Commission rows for CPA/FTD events |
| JOIN | dbo.tblaff_CPA | Read | CPA event dates and validity flags |
| JOIN | dbo.tblaff_Sales_Commissions | Read | Commission rows for sales events |
| JOIN | dbo.tblaff_Sales | Read | Sale event dates |
| JOIN | dbo.tblaff_Bonuses_Commissions | Read | Commission rows for bonus events |
| JOIN | dbo.tblaff_Bonuses | Read | Bonus event dates |
| JOIN | dbo.tblaff_Chargebacks_Commissions | Read | Commission rows for chargeback events |
| JOIN | dbo.tblaff_Chargebacks | Read | Chargeback event dates |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAffiliateStats
  ├── dbo.tblaff_Registrations_Commissions  (READ)
  ├── dbo.tblaff_Registrations              (READ)
  ├── dbo.tblaff_CPA_Commissions            (READ)
  ├── dbo.tblaff_CPA                        (READ)
  ├── dbo.tblaff_Sales_Commissions          (READ)
  ├── dbo.tblaff_Sales                      (READ)
  ├── dbo.tblaff_Bonuses_Commissions        (READ)
  ├── dbo.tblaff_Bonuses                    (READ)
  ├── dbo.tblaff_Chargebacks_Commissions    (READ)
  └── dbo.tblaff_Chargebacks                (READ)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.tblaff_Registrations_Commissions | Table | Commission amounts per registration event |
| dbo.tblaff_Registrations | Table | Registration event dates |
| dbo.tblaff_CPA_Commissions | Table | Commission amounts per CPA/FTD event |
| dbo.tblaff_CPA | Table | CPA event dates and Optional2 (FTD) flag |
| dbo.tblaff_Sales_Commissions | Table | Commission amounts per sale |
| dbo.tblaff_Sales | Table | Sale event dates |
| dbo.tblaff_Bonuses_Commissions | Table | Commission amounts per bonus |
| dbo.tblaff_Bonuses | Table | Bonus event dates |
| dbo.tblaff_Chargebacks_Commissions | Table | Commission amounts per chargeback |
| dbo.tblaff_Chargebacks | Table | Chargeback event dates |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes
N/A for stored procedure.

### 7.2 Constraints
N/A for stored procedure.

---

## 8. Sample Queries

```sql
-- Get direct (Tier 2) stats for affiliate 12345 for Q1 2026
EXEC dbo.GetAffiliateStats
    @affiliateId = 12345,
    @fromDate    = '2026-01-01',
    @toDate      = '2026-04-01',
    @tier        = 2;

-- Get Tier 3 sub-affiliate stats for a specific month
EXEC dbo.GetAffiliateStats
    @affiliateId = 12345,
    @fromDate    = '2026-03-01',
    @toDate      = '2026-04-01',
    @tier        = 3;

-- Get full year stats at Tier 2 for a high-volume affiliate
EXEC dbo.GetAffiliateStats
    @affiliateId = 56663,
    @fromDate    = '2025-01-01',
    @toDate      = '2026-01-01',
    @tier        = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.
*(Author notes: Ran Ovadia, 17/7/2019 - Creating for Partners; 14/05/2020 - Adding Recompile hint.)*

---

*Generated: 2026-04-12 | Quality: 8.6/10*
*Object: dbo.GetAffiliateStats | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAffiliateStats.sql*
