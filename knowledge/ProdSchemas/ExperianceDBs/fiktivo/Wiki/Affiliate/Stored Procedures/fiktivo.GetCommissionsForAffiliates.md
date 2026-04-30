# fiktivo.GetCommissionsForAffiliates

> Retrieves all unpaid commission amounts across all commission types (First Positions, Sales, Bonuses, Chargebacks, CPA, Leads, Registrations, Copy Traders, eCost) for a list of affiliate IDs within a date range.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | AffiliateID + Commission Type + Tier (composite output) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetCommissionsForAffiliates is the master commission retrieval procedure for the affiliate payment system. Given a comma-separated list of affiliate IDs and an optional date range, it returns all unpaid commissions across nine commission types: First Positions, Sales, Bonuses, Chargebacks, CPA (Cost Per Acquisition), Leads, Registrations, Copy Traders, and eCost. This is the data source for generating affiliate payment reports and processing commission payouts.

This procedure is critical for the affiliate payment cycle. It aggregates commission amounts by affiliate, tier, and commission type, filtering to only unpaid commissions (Paid=0) where the underlying event was accepted (AffiliateSaleAccepted<>0) and valid (Valid<>0). The result set feeds directly into the payment approval workflow.

The procedure parses the comma-separated affiliate ID list into a temp table, then executes 9 UNION'd queries (one per commission type) against the dbo.tblaff_* commission and event tables. Clicks commissions were removed (Noga Rozen, 22/7/22).

---

## 2. Business Logic

### 2.1 Commission Types

**What**: Nine distinct commission types are aggregated in a single result set.

**Columns/Parameters Involved**: `Commission Type` output column

**Rules**:
- **First Pos**: From tblaff_FirstPositions + tblaff_FirstPositions_Commissions. Customer's first closed position triggers commission.
- **Sales**: From tblaff_Sales + tblaff_Sales_Commissions. Includes UsedBonusCommission added to base Commission.
- **Sales (Bonuses)**: From tblaff_Bonuses + tblaff_Bonuses_Commissions. Bonus credits that generate additional sales commission.
- **Sales (Chargebacks)**: From tblaff_Chargebacks + tblaff_Chargebacks_Commissions. Payment reversals that reduce commission (typically negative).
- **CPA**: From tblaff_CPA + tblaff_CPA_Commissions. Cost-per-acquisition commissions on first deposits.
- **Leads**: From tblaff_Leads + tblaff_Leads_Commissions. Lead generation commissions.
- **Regs**: From tblaff_Registrations + tblaff_Registrations_Commissions. Registration commissions.
- **Copys**: From tblaff_CopyTraders + tblaff_CopyTraders_Commissions. Copy trading activity commissions.
- **eCost**: From tblaff_eCost + tblaff_eCost_Commissions. Electronic cost/marketing expense commissions.

### 2.2 Filtering Criteria

**What**: Only unpaid, accepted, valid commissions within the date range are returned.

**Rules**:
- Paid = 0 (only unpaid commissions)
- Valid <> 0 (event must be valid)
- AffiliateSaleAccepted <> 0 / AffiliateFirstPositionAccepted <> 0 / etc. (event must be accepted)
- ORDER_DATE within @dateFrom to @dateTo range
- For Sales specifically: ISNULL(Optional1, '0') = '0' (excludes certain special sales)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @affiliateIDs | NVARCHAR(MAX) (IN) | NO | - | CODE-BACKED | Comma-separated list of affiliate IDs to retrieve commissions for (e.g., '100,200,300'). Parsed into a temp table #tbl using a string-splitting loop. |
| 2 | @dateFrom | DATETIME (IN) | YES | '2000-01-01' | CODE-BACKED | Start of the date range filter. Defaults to 2000-01-01 if NULL, effectively returning all historical commissions. |
| 3 | @dateTo | DATETIME (IN) | YES | GETDATE() | CODE-BACKED | End of the date range filter. Defaults to current date/time if NULL. |
| 4 | AffiliateID (output) | INT | NO | - | CODE-BACKED | Affiliate ID from the commission record. |
| 5 | Tier (output) | INT | NO | - | CODE-BACKED | Commission tier level. Tier 1 = direct affiliate, Tier 2+ = sub-affiliate tiers. |
| 6 | Commission (output) | FLOAT | NO | - | CODE-BACKED | Total unpaid commission amount for this affiliate/tier/type combination. SUM aggregated. For Sales, includes UsedBonusCommission. |
| 7 | Commission Type (output) | VARCHAR | NO | - | CODE-BACKED | Type label: 'First Pos', 'Sales', 'CPA', 'Leads', 'Regs', 'Copys', 'eCost'. Bonuses and Chargebacks are labeled as 'Sales'. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.tblaff_FirstPositions + _Commissions | JOIN + SELECT | First position commissions |
| - | dbo.tblaff_Sales + _Commissions | JOIN + SELECT | Sales commissions |
| - | dbo.tblaff_Bonuses + _Commissions | JOIN + SELECT | Bonus commissions |
| - | dbo.tblaff_Chargebacks + _Commissions | JOIN + SELECT | Chargeback commissions |
| - | dbo.tblaff_CPA + _Commissions | JOIN + SELECT | CPA commissions |
| - | dbo.tblaff_Leads + _Commissions | JOIN + SELECT | Lead commissions |
| - | dbo.tblaff_Registrations + _Commissions | JOIN + SELECT | Registration commissions |
| - | dbo.tblaff_CopyTraders + _Commissions | JOIN + SELECT | Copy trader commissions |
| - | dbo.tblaff_eCost + _Commissions | JOIN + SELECT | eCost commissions |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.GetCommissionsForAffiliates (procedure)
├── dbo.tblaff_FirstPositions (table, cross-schema)
├── dbo.tblaff_FirstPositions_Commissions (table, cross-schema)
├── dbo.tblaff_Sales (table, cross-schema)
├── dbo.tblaff_Sales_Commissions (table, cross-schema)
├── dbo.tblaff_Bonuses (table, cross-schema)
├── dbo.tblaff_Bonuses_Commissions (table, cross-schema)
├── dbo.tblaff_Chargebacks (table, cross-schema)
├── dbo.tblaff_Chargebacks_Commissions (table, cross-schema)
├── dbo.tblaff_CPA (table, cross-schema)
├── dbo.tblaff_CPA_Commissions (table, cross-schema)
├── dbo.tblaff_Leads (table, cross-schema)
├── dbo.tblaff_Leads_Commissions (table, cross-schema)
├── dbo.tblaff_Registrations (table, cross-schema)
├── dbo.tblaff_Registrations_Commissions (table, cross-schema)
├── dbo.tblaff_CopyTraders (table, cross-schema)
├── dbo.tblaff_CopyTraders_Commissions (table, cross-schema)
├── dbo.tblaff_eCost (table, cross-schema)
└── dbo.tblaff_eCost_Commissions (table, cross-schema)
```

### 6.1 Objects This Depends On

18 cross-schema dbo tables (9 event tables + 9 commission tables).

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get all unpaid commissions for specific affiliates
```sql
EXEC fiktivo.GetCommissionsForAffiliates @affiliateIDs = '100,200,300'
```

### 8.2 Get commissions for a date range
```sql
EXEC fiktivo.GetCommissionsForAffiliates
    @affiliateIDs = '100',
    @dateFrom = '2012-01-01',
    @dateTo = '2012-12-31'
```

### 8.3 Get all-time commissions for a single affiliate
```sql
EXEC fiktivo.GetCommissionsForAffiliates @affiliateIDs = '3'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.GetCommissionsForAffiliates | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.GetCommissionsForAffiliates.sql*
