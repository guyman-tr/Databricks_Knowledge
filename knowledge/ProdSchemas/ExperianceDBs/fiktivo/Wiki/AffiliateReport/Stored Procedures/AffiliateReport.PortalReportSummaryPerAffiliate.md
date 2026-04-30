# AffiliateReport.PortalReportSummaryPerAffiliate

> Portal-facing per-affiliate detail report that returns row-level commission data for a single affiliate and their sub-affiliate tier hierarchy (up to 5 levels), supporting registrations, FTDs, sales, chargebacks, and click metrics.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateReport |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns row-level commission detail for one affiliate + sub-affiliate hierarchy |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

PortalReportSummaryPerAffiliate is the detail-level companion to PortalReportSummaryByAffiliate. While the "ByAffiliate" version returns aggregated totals grouped by configurable dimensions, this "PerAffiliate" version returns individual commission rows with full dimensional context - enabling the portal to display granular per-transaction data and support drill-down from summary to detail views.

This procedure also handles the sub-affiliate (multi-tier) hierarchy. Using a recursive CTE on dbo.tblaff_Tier2Members, it walks up to 5 levels of sub-affiliates below the requested affiliate. The result set contains two UNIONed blocks: (1) the affiliate's own data (Tier 1) with all commission types, and (2) sub-affiliate data for tiers specified in @tiers, excluding clicks (sub-affiliates don't have their own click data).

The procedure replaced the legacy [AffWizReports].[ReportSummaryByAffiliate] (Aug 2020, Ran Ovadia) and shares the same evolution history as its aggregated counterpart.

---

## 2. Business Logic

### 2.1 Recursive Sub-Affiliate Hierarchy (CTE)

**What**: Walks the tier-2 member hierarchy to find all sub-affiliates up to 5 levels deep.

**Columns/Parameters Involved**: `@AffiliateId`, `@tiers`, CTE on `dbo.tblaff_Tier2Members`

**Rules**:
- Base case: SELECT from tblaff_Tier2Members WHERE AffiliateID = @AffiliateId (direct sub-affiliates, Tier 2)
- Recursive step: JOIN tblaff_Tier2Members on NewMemberID = parent's AffiliateID, incrementing Tier, WHERE Tier < 5
- Filtered by @tiers parameter (which tier levels to include)
- Sub-affiliate IDs stored in #childAffiliates temp table
- The main affiliate's own data (Tier 1) is returned in the first UNION block
- Sub-affiliate data is returned in the second UNION block with Tier = 1 forced (sub-affiliates report at their own Tier 1 within the hierarchy)

### 2.2 Dual Result Set Architecture

**What**: Returns both the affiliate's own data and sub-affiliate data in a single UNION ALL.

**Columns/Parameters Involved**: All output columns

**Rules**:
- Block 1: Affiliate's own data - filtered by @AffiliateId directly, includes all 5 ATypes (0-5), date-filtered per type
- Block 2: Sub-affiliate data - filtered by #childAffiliates, includes ATypes 0-4 only (no clicks), Tier forced to 1
- Both blocks share the same output column structure
- Block 2 does NOT include click data (AType 5) since sub-affiliates' clicks are tracked separately
- Block 2 includes 0 for Impressions and Clicks columns, and empty strings for ProductType and CommissionSource

### 2.3 Row-Level Detail (No GROUP BY)

**What**: Unlike PortalReportSummaryByAffiliate, this procedure returns individual rows without aggregation.

**Columns/Parameters Involved**: All output columns

**Rules**:
- Each row represents one commission event (registration, deposit, sale, chargeback, or click aggregation)
- CommissionID identifies the source record (RegistrationID, CreditID, ClosedPositionID, or 0 for clicks)
- AffiliateCommission is output as cast(0 as decimal) - placeholder for application-level calculation
- The @Aggregate flags control which metric columns are populated (NULL when flag is 0)
- No GROUP BY means no conversion rate calculations (those are in the aggregated version)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateId | int | NO | - | CODE-BACKED | The primary affiliate to report on. Used both as the direct filter for Block 1 data and as the root for the recursive sub-affiliate CTE. Also used for click partition elimination (PartitionCol100 = @AffiliateId%100). |
| 2 | @FromDate | datetime | NO | - | CODE-BACKED | Start of the reporting period (inclusive). Converted to DATE. Used as >= filter on commission dates. |
| 3 | @ToDate | datetime | NO | - | CODE-BACKED | End of the reporting period. Converted to DATE + 1 day (exclusive upper bound: < @ToDate). |
| 4 | @AggregateRegistrations | bit | NO | - | CODE-BACKED | When 1, populates Registration columns. When 0, those columns return NULL. Also controls whether the Registration UNION branch is included. |
| 5 | @AggregateFTDs | bit | NO | - | CODE-BACKED | When 1, populates FTD/FTDE/Commission/Amount columns. Also controls CPA and Chargeback UNION branches. |
| 6 | @AggregateSales | bit | NO | - | CODE-BACKED | When 1, populates SaleCommission, GrossRevenue, SaleRevenue, Bonuses columns. |
| 7 | @AggregateClicks | bit | NO | - | CODE-BACKED | When 1, populates Impressions and Clicks columns. Enables Clicks UNION branch (Block 1 only). Also enables Registration and CPA branches for conversion context. |
| 8 | @AggregateRefundAndChargeback | bit | NO | - | CODE-BACKED | When 1, populates ChargebackRevenue column. Enables Chargeback UNION branch. |
| 9 | @tiers | dbo.IDTableType | NO | - | CODE-BACKED | Table-valued parameter containing tier levels to include. Filters both the CTE hierarchy and the commission data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.tblaff_Tier2Members | READ (recursive CTE) | Sub-affiliate hierarchy walk up to 5 levels |
| - | AffiliateCommission.RegistrationCommission | READ | Registration commission data (AType 0) |
| - | AffiliateCommission.RegistrationVW | READ | Registration details |
| - | AffiliateCommission.CreditVW | READ | CPA/FTD (AType 1) and Chargeback (AType 4) data |
| - | AffiliateCommission.CreditCommission | READ | Credit commission amounts |
| - | AffiliateCommission.ClosedPositionCommission | READ | Sale commission data (AType 3) |
| - | AffiliateCommission.ClosedPositionVW | READ | Closed position details |
| - | AffiliateConfiguration.TraderFirstAssetPosition | READ (LEFT JOIN) | First position asset type |
| - | Dictionary.PositionAssetType | READ (LEFT JOIN) | Asset type name lookup |
| - | AffiliateCommission.CreditAccountMapping | READ (LEFT JOIN) | Credit-account mapping |
| - | AffiliateClicks.ClicksImpressionsAggregation | READ | Click/impression data (Block 1 only) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Affiliate Portal (external) | - | Caller | Portal detail/drill-down views |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateReport.PortalReportSummaryPerAffiliate (procedure)
+-- dbo.tblaff_Tier2Members (table, cross-schema)
+-- AffiliateCommission.RegistrationCommission (table, cross-schema)
+-- AffiliateCommission.RegistrationVW (view, cross-schema)
+-- AffiliateCommission.CreditVW (view, cross-schema)
+-- AffiliateCommission.CreditCommission (table, cross-schema)
+-- AffiliateCommission.ClosedPositionCommission (table, cross-schema)
+-- AffiliateCommission.ClosedPositionVW (view, cross-schema)
+-- AffiliateConfiguration.TraderFirstAssetPosition (table, cross-schema)
+-- Dictionary.PositionAssetType (table, cross-schema)
+-- AffiliateCommission.CreditAccountMapping (table, cross-schema)
+-- AffiliateClicks.ClicksImpressionsAggregation (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Tier2Members | Table | Recursive CTE for sub-affiliate hierarchy |
| AffiliateCommission.RegistrationCommission | Table | Registration commission data |
| AffiliateCommission.RegistrationVW | View | Registration details |
| AffiliateCommission.CreditVW | View | CPA/FTD and chargeback credit data |
| AffiliateCommission.CreditCommission | Table | Credit commission amounts |
| AffiliateCommission.ClosedPositionCommission | Table | Sale commission data |
| AffiliateCommission.ClosedPositionVW | View | Closed position details |
| AffiliateConfiguration.TraderFirstAssetPosition | Table | First asset type resolution |
| Dictionary.PositionAssetType | Table | Asset type name lookup |
| AffiliateClicks.ClicksImpressionsAggregation | Table | Click/impression counts |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Affiliate Portal (external) | Application | Detail-level affiliate performance data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. No OPTION(RECOMPILE) on the main query (unlike the aggregated version).

---

## 8. Sample Queries

### 8.1 Get detail rows for a single affiliate with all metrics
```sql
DECLARE @Tiers dbo.IDTableType
INSERT INTO @Tiers VALUES (1)
EXEC AffiliateReport.PortalReportSummaryPerAffiliate
    @AffiliateId = 12345,
    @FromDate = '2026-04-01', @ToDate = '2026-04-13',
    @AggregateRegistrations = 1, @AggregateFTDs = 1,
    @AggregateSales = 1, @AggregateClicks = 1,
    @AggregateRefundAndChargeback = 1, @tiers = @Tiers
```

### 8.2 Get sub-affiliate data (tiers 2 and 3)
```sql
DECLARE @Tiers dbo.IDTableType
INSERT INTO @Tiers VALUES (2), (3)
EXEC AffiliateReport.PortalReportSummaryPerAffiliate
    @AffiliateId = 12345,
    @FromDate = '2026-01-01', @ToDate = '2026-03-31',
    @AggregateRegistrations = 1, @AggregateFTDs = 1,
    @AggregateSales = 1, @AggregateClicks = 0,
    @AggregateRefundAndChargeback = 0, @tiers = @Tiers
```

### 8.3 FTD-only detail for commission review
```sql
DECLARE @Tiers dbo.IDTableType
INSERT INTO @Tiers VALUES (1)
EXEC AffiliateReport.PortalReportSummaryPerAffiliate
    @AffiliateId = 12345,
    @FromDate = '2026-04-01', @ToDate = '2026-04-13',
    @AggregateRegistrations = 0, @AggregateFTDs = 1,
    @AggregateSales = 0, @AggregateClicks = 0,
    @AggregateRefundAndChargeback = 0, @tiers = @Tiers
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-2448 (referenced in SQL comments) | Jira | CPA New Compensation Design (Dec 2023, Gil & Noga) |
| PART-2146 (referenced in SQL comments) | Jira | Added RevenuesPercentage calc for CPA (Nov 2023, Gil Haba) |
| PART-4552 (referenced in SQL comments) | Jira | Enhancement (Jul 2025, Gil Haba) |
| PART-4802 (referenced in SQL comments) | Jira | Refund & chargeback part of CPA not revenue (Aug 2025, Gil Haba) |
| PART-5499 (referenced in SQL comments) | Jira | Added ProductType & CommissionSource (Jan 2026, Gil Haba) |

No direct Confluence pages found for this procedure.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 5 Jira (ref) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateReport.PortalReportSummaryPerAffiliate | Type: Stored Procedure | Source: fiktivo/AffiliateReport/Stored Procedures/AffiliateReport.PortalReportSummaryPerAffiliate.sql*
