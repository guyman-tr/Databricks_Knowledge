# fiktivo.GetCommissionsForAffiliates

> Retrieves unpaid commission totals across all commission types (First Positions, Sales, Bonuses, Chargebacks, CPA, Leads, Registrations, CopyTraders, eCost) for a list of affiliate IDs within a date range.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Result set: AffiliateID, Tier, Commission, Commission Type |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the primary commission reporting procedure for the affiliate platform. Given a comma-separated list of affiliate IDs and an optional date range, it queries all nine commission tables and returns unpaid commission totals grouped by affiliate, tier, and commission type. It provides a unified view across all revenue streams: first positions, sales, bonuses, chargebacks, CPA deposits, leads, registrations, copy traders, and eCost.

This procedure powers the affiliate commission dashboard and payment processing workflow. It shows how much each affiliate is owed across all commission types, filtered to unpaid (Paid=0) and accepted/valid commissions only. Originally included Clicks commissions, removed by Noga Rozen on 22/7/22.

The procedure parses the comma-separated affiliate ID list into a temp table for efficient JOINs across all nine commission table pairs.

---

## 2. Business Logic

### 2.1 Multi-Commission Type Aggregation

**What**: UNIONs nine separate commission queries into a single result set.

**Columns/Parameters Involved**: `@affiliateIDs`, `@dateFrom`, `@dateTo`

**Rules**:
- Parses @affiliateIDs (comma-separated) into #tbl temp table
- Defaults: @dateFrom = '2000-01-01', @dateTo = GetDate()
- Each UNION block: JOIN commission table + event table, filter Paid=0 + Accepted<>0 + Valid<>0
- Commission types returned: 'First Pos', 'Sales' (includes bonuses and chargebacks), 'CPA', 'Leads', 'Regs', 'Copys', 'eCost'
- Sales commission includes UsedBonusCommission: ISNULL(Commission, 0) + ISNULL(UsedBonusCommission, 0)
- Sales additionally filters ISNULL(Optional1, '0') = '0' to exclude special sales
- Results ordered by AffiliateID, Tier, Commission Type

### 2.2 Commission Table Pairs

**What**: Each commission type uses a paired table structure: event table + commission table.

**Rules**:
- First Positions: tblaff_FirstPositions + tblaff_FirstPositions_Commissions
- Sales: tblaff_Sales + tblaff_Sales_Commissions (optimized with #comm temp table)
- Bonuses: tblaff_Bonuses + tblaff_Bonuses_Commissions
- Chargebacks: tblaff_Chargebacks + tblaff_Chargebacks_Commissions
- CPA: tblaff_CPA + tblaff_CPA_Commissions
- Leads: tblaff_Leads + tblaff_Leads_Commissions
- Registrations: tblaff_Registrations + tblaff_Registrations_Commissions
- CopyTraders: tblaff_CopyTraders + tblaff_CopyTraders_Commissions
- eCost: tblaff_eCost + tblaff_eCost_Commissions

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @affiliateIDs (IN) | NVARCHAR(MAX) | NO | - | CODE-BACKED | Comma-separated list of affiliate IDs to query (e.g., '100,200,300'). Parsed into temp table for multi-affiliate lookup. |
| 2 | @dateFrom (IN) | DATETIME | YES | '2000-01-01' | CODE-BACKED | Start of date range filter. Applied to each commission type's ORDER_DATE. Defaults to 2000-01-01 (all history). |
| 3 | @dateTo (IN) | DATETIME | YES | GetDate() | CODE-BACKED | End of date range filter. Defaults to current date. |

**Result Set Columns**:

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | AffiliateID | BIGINT | Affiliate receiving the commission |
| 2 | Tier | INT | Commission tier (1=primary, 2=sub-affiliate) |
| 3 | Commission | FLOAT | Total unpaid commission amount for this type |
| 4 | Commission Type | VARCHAR | Type label: 'First Pos', 'Sales', 'CPA', 'Leads', 'Regs', 'Copys', 'eCost' |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | dbo.tblaff_FirstPositions + _Commissions | Table read | First position commission query |
| (SELECT) | dbo.tblaff_Sales + _Commissions | Table read | Sales commission query |
| (SELECT) | dbo.tblaff_Bonuses + _Commissions | Table read | Bonus commission query |
| (SELECT) | dbo.tblaff_Chargebacks + _Commissions | Table read | Chargeback commission query |
| (SELECT) | dbo.tblaff_CPA + _Commissions | Table read | CPA deposit commission query |
| (SELECT) | dbo.tblaff_Leads + _Commissions | Table read | Lead commission query |
| (SELECT) | dbo.tblaff_Registrations + _Commissions | Table read | Registration commission query |
| (SELECT) | dbo.tblaff_CopyTraders + _Commissions | Table read | Copy trader commission query |
| (SELECT) | dbo.tblaff_eCost + _Commissions | Table read | eCost commission query |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.GetCommissionsForAffiliates (procedure)
    ├── dbo.tblaff_FirstPositions (table)
    ├── dbo.tblaff_FirstPositions_Commissions (table)
    ├── dbo.tblaff_Sales (table)
    ├── dbo.tblaff_Sales_Commissions (table)
    ├── dbo.tblaff_Bonuses (table)
    ├── dbo.tblaff_Bonuses_Commissions (table)
    ├── dbo.tblaff_Chargebacks (table)
    ├── dbo.tblaff_Chargebacks_Commissions (table)
    ├── dbo.tblaff_CPA (table)
    ├── dbo.tblaff_CPA_Commissions (table)
    ├── dbo.tblaff_Leads (table)
    ├── dbo.tblaff_Leads_Commissions (table)
    ├── dbo.tblaff_Registrations (table)
    ├── dbo.tblaff_Registrations_Commissions (table)
    ├── dbo.tblaff_CopyTraders (table)
    ├── dbo.tblaff_CopyTraders_Commissions (table)
    ├── dbo.tblaff_eCost (table)
    └── dbo.tblaff_eCost_Commissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| 9 event tables + 9 commission tables | Tables | SELECT with UNION for multi-commission-type reporting |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all unpaid commissions for specific affiliates
```sql
EXEC fiktivo.GetCommissionsForAffiliates @affiliateIDs = '100,200,300'
```

### 8.2 Get commissions for a date range
```sql
EXEC fiktivo.GetCommissionsForAffiliates @affiliateIDs = '100', @dateFrom = '2012-01-01', @dateTo = '2012-12-31'
```

### 8.3 Verify commission types available
```sql
-- Check what commission types have unpaid records
SELECT 'Sales' AS Type, COUNT(*) AS UnpaidCount
FROM dbo.tblaff_Sales_Commissions WITH (NOLOCK) WHERE Paid = 0
UNION ALL
SELECT 'Leads', COUNT(*) FROM dbo.tblaff_Leads_Commissions WITH (NOLOCK) WHERE Paid = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.GetCommissionsForAffiliates | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.GetCommissionsForAffiliates.sql*
