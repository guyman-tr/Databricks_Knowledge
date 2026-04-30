# AffiliateReport.PortalReportSummaryByAffiliate

> Portal-facing affiliate performance report that aggregates registrations, FTDs, sales, chargebacks, and click metrics for a single affiliate with flexible grouping dimensions and conditional metric aggregation.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateReport |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns aggregated commission/performance data for one affiliate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

PortalReportSummaryByAffiliate is the primary report procedure used by the affiliate portal (self-service dashboard). It returns aggregated performance metrics for a single affiliate across a date range, with fully configurable grouping dimensions (by date, month, banner, campaign, country, customer, tier) and selective metric aggregation (registrations, FTDs, sales, clicks, refunds/chargebacks). The affiliate sees their own performance data through this report.

This procedure exists to power the affiliate portal's performance dashboards. It replaced the legacy [AffWizReports].[ReportSummaryByAffiliate] (Aug 2020, Ran Ovadia) and has been continuously enhanced: CPA revenue support (PART-2448), click/impression metrics (PART-2689), AdditionalData dimension (PART-3693), ProductType and CommissionSource (PART-5499).

The procedure uses a UNION ALL pattern to combine 5 distinct data sources (registrations, CPA/FTD credits, closed position sales, chargebacks/refunds, clicks/impressions) into a unified structure with an AType discriminator, then applies conditional GROUP BY and aggregation based on the caller's requested dimensions. Uses OPTION(RECOMPILE) to handle the highly variable parameter combinations efficiently.

---

## 2. Business Logic

### 2.1 AType Discriminator Pattern

**What**: Five different commission/event types are UNION ALL'd into a common structure, with an AType column distinguishing the source.

**Columns/Parameters Involved**: AType (internal), all aggregate flags

**Rules**:
- AType 0 = Registration (from AffiliateCommission.RegistrationCommission + RegistrationVW)
- AType 1 = CPA/FTD (from AffiliateCommission.CreditVW + CreditCommission, WHERE CreditTypeID=1)
- AType 3 = Sale/RevShare (from AffiliateCommission.ClosedPositionCommission + ClosedPositionVW)
- AType 4 = Refund/Chargeback (from AffiliateCommission.CreditVW + CreditCommission, WHERE CreditTypeID IN (4,5))
- AType 5 = Clicks/Impressions (from AffiliateClicks.ClicksImpressionsAggregation, ClicksCount mapped to Commission, ImpressionsCount mapped to Tier)
- Each UNION branch is conditionally included based on the aggregate flags (@AggregateRegistrations, @AggregateFTDs, etc.)

### 2.2 Conditional Grouping and Aggregation

**What**: The report dynamically adjusts its GROUP BY and SELECT columns based on caller-specified flags.

**Columns/Parameters Involved**: @GroupBy* flags, @Aggregate* flags

**Rules**:
- Each @GroupBy flag controls whether a dimension appears in output (CASE WHEN @GroupByX = 1 THEN value ELSE NULL END)
- Each @Aggregate flag controls whether a metric family is calculated (case when @AggregateX=1 then SUM(...) else null end)
- Setting a flag to 0 collapses that dimension (NULL) and excludes that metric family
- This creates a single flexible procedure instead of dozens of fixed reports

### 2.3 Click Conversion Metrics

**What**: Calculated conversion rates using click data as the denominator.

**Columns/Parameters Involved**: @AggregateClicks, ClicksCount, ImpressionsCount

**Rules**:
- LCR (Lead Conversion Rate) = Registrations / Clicks * 100 (guarded by IIF to avoid division by zero)
- FTDCR (FTD Conversion Rate) = FTDs / Clicks * 100
- CTR (Click-Through Rate) = Clicks / Impressions * 100
- FTDECR (FTDE Conversion Rate) = FTDEs / Clicks * 100
- All metrics are NULL when @AggregateClicks = 0

### 2.4 FTD vs FTDE Distinction

**What**: FTD (First Time Deposit) and FTDE (First Time Deposit Eligible) are tracked separately.

**Columns/Parameters Involved**: `Optional`, `IsValid`, `Commission`

**Rules**:
- FTD: AType=1 AND Optional=1 (IsFirstDeposit=1) - the customer's first deposit
- FTDE: AType=1 AND Optional=1 AND IsValid=1 - first deposit that is also validated/eligible for commission
- FTDCommission includes both AType=4 (chargebacks) and AType=1 valid FTDs (since PART-4802)
- RevenuesPercentage is summed only for FTD rows (AType=1, Optional=1)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateId | int | NO | - | CODE-BACKED | The single affiliate to report on. Filters all data sources by this affiliate ID. Also used for partition elimination on ClicksImpressionsAggregation (PartitionCol100 = @AffiliateId%100). |
| 2 | @FromDate | datetime | NO | - | CODE-BACKED | Start of the reporting period (inclusive). Converted to DATE internally. Filters all UNION branches by their respective date columns. |
| 3 | @ToDate | datetime | NO | - | CODE-BACKED | End of the reporting period (inclusive). Converted to DATE internally. |
| 4 | @GroupByDate | bit | NO | - | CODE-BACKED | When 1, includes Date as a grouping dimension in the output. When 0, Date is collapsed to NULL (all dates aggregated together). |
| 5 | @GroupByMonth | bit | NO | - | CODE-BACKED | When 1, includes Month number as a grouping dimension. Enables monthly aggregation without daily granularity. |
| 6 | @GroupByBannerId | bit | NO | - | CODE-BACKED | When 1, includes BannerID as a grouping dimension. Enables per-banner performance breakdown. |
| 7 | @GroupBySerialId | bit | NO | - | CODE-BACKED | When 1, includes SerialID (AffiliateCampaign) as a grouping dimension. Enables per-campaign tracking. |
| 8 | @GroupByAdditionalData | bit | NO | - | CODE-BACKED | When 1, includes AdditionalData as a grouping dimension. Added PART-3693 (Nov 2024). |
| 9 | @GroupByCustomerId | bit | NO | - | CODE-BACKED | When 1, includes CustomerID as a grouping dimension. Enables per-customer detail. Also controls whether AssetName, ProductType, CommissionSource are aggregated via STRING_AGG. |
| 10 | @GroupByCountryId | bit | NO | - | CODE-BACKED | When 1, includes CountryID as a grouping dimension. Enables geographic breakdown. |
| 11 | @GroupByTier | bit | NO | - | CODE-BACKED | When 1, includes Tier as a grouping dimension. Enables breakdown by affiliate tier level. |
| 12 | @AggregateRegistrations | bit | NO | - | CODE-BACKED | When 1, includes Registration count and RegistrationCommission in the output. Also enables the Registration UNION branch. |
| 13 | @AggregateFTDs | bit | NO | - | CODE-BACKED | When 1, includes FTD/FTDE counts, FTDCommission, FTDAmount, DepositAmount, FTDEAmount, RevenuesPercentage. Also enables the CPA and Chargeback UNION branches. |
| 14 | @AggregateSales | bit | NO | - | CODE-BACKED | When 1, includes RevenueCommission, GrossRevenue, NetRevenue, Bonuses. Enables the Sales UNION branch. |
| 15 | @AggregateClicks | bit | NO | - | CODE-BACKED | When 1, includes LCR, FTDCR, CTR, FTDECR, Impressions, Clicks. Enables the Clicks UNION branch and Registration/CPA branches for conversion calculations. |
| 16 | @AggregateRefundAndChargeback | bit | NO | - | CODE-BACKED | When 1, includes RefundsAndChargebacks metric. Enables the Chargeback UNION branch. Added PART-4802 (Aug 2025). |
| 17 | @Tiers | dbo.IDTableType | NO | - | CODE-BACKED | Table-valued parameter containing tier IDs to include. Filters all commission data by Tier IN (SELECT ID FROM @Tiers). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.RegistrationCommission | READ | Registration commission data (AType 0) |
| - | AffiliateCommission.RegistrationVW | READ | Registration details joined on RegistrationID |
| - | AffiliateCommission.CreditVW | READ | CPA/FTD credit data (AType 1) and Chargeback data (AType 4) |
| - | AffiliateCommission.CreditCommission | READ | Credit commission amounts |
| - | AffiliateCommission.ClosedPositionCommission | READ | Sale/RevShare commission data (AType 3) |
| - | AffiliateCommission.ClosedPositionVW | READ | Closed position details |
| - | AffiliateConfiguration.TraderFirstAssetPosition | READ (LEFT JOIN) | First position asset type for AssetName resolution |
| - | Dictionary.PositionAssetType | READ (LEFT JOIN) | Asset type name lookup. See [Position Asset Type](../../_glossary.md#position-asset-type) |
| - | AffiliateCommission.CreditAccountMapping | READ (LEFT JOIN) | Credit-to-account mapping |
| - | AffiliateClicks.ClicksImpressionsAggregation | READ | Click/impression counts (AType 5) with partition elimination |
| @Tiers | dbo.IDTableType | Parameter Type | Table type for tier filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Affiliate Portal (external) | - | Caller | Portal dashboards call this for affiliate performance data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateReport.PortalReportSummaryByAffiliate (procedure)
+-- AffiliateCommission.RegistrationCommission (table/view, cross-schema)
+-- AffiliateCommission.RegistrationVW (view, cross-schema)
+-- AffiliateCommission.CreditVW (view, cross-schema)
+-- AffiliateCommission.CreditCommission (table, cross-schema)
+-- AffiliateCommission.ClosedPositionCommission (table, cross-schema)
+-- AffiliateCommission.ClosedPositionVW (view, cross-schema)
+-- AffiliateConfiguration.TraderFirstAssetPosition (table, cross-schema)
+-- Dictionary.PositionAssetType (table, cross-schema)
+-- AffiliateCommission.CreditAccountMapping (table, cross-schema)
+-- AffiliateClicks.ClicksImpressionsAggregation (table, cross-schema)
+-- dbo.IDTableType (type, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationCommission | Table | INNER JOIN for registration commission data |
| AffiliateCommission.RegistrationVW | View | INNER JOIN for registration details |
| AffiliateCommission.CreditVW | View | INNER JOIN for CPA/FTD and chargeback credit data |
| AffiliateCommission.CreditCommission | Table | INNER JOIN for credit commission amounts |
| AffiliateCommission.ClosedPositionCommission | Table | INNER JOIN for sale commission data |
| AffiliateCommission.ClosedPositionVW | View | INNER JOIN for closed position details |
| AffiliateConfiguration.TraderFirstAssetPosition | Table | LEFT JOIN for first asset type resolution |
| Dictionary.PositionAssetType | Table | LEFT JOIN for asset type name |
| AffiliateCommission.CreditAccountMapping | Table | LEFT JOIN for credit-account mapping |
| AffiliateClicks.ClicksImpressionsAggregation | Table | SELECT for click/impression data with partition elimination |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Affiliate Portal (external) | Application | Calls for affiliate self-service performance reports |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION(RECOMPILE) | Query Hint | Forces recompilation on every execution to handle the highly variable parameter combinations (16 BIT flags) without parameter sniffing issues |

---

## 8. Sample Queries

### 8.1 Basic daily report with all metrics
```sql
DECLARE @Tiers dbo.IDTableType
INSERT INTO @Tiers VALUES (1)
EXEC AffiliateReport.PortalReportSummaryByAffiliate
    @AffiliateId = 12345,
    @FromDate = '2026-04-01', @ToDate = '2026-04-13',
    @GroupByDate = 1, @GroupByMonth = 0,
    @GroupByBannerId = 0, @GroupBySerialId = 0,
    @GroupByAdditionalData = 0, @GroupByCustomerId = 0,
    @GroupByCountryId = 0, @GroupByTier = 0,
    @AggregateRegistrations = 1, @AggregateFTDs = 1,
    @AggregateSales = 1, @AggregateClicks = 1,
    @AggregateRefundAndChargeback = 1, @Tiers = @Tiers
```

### 8.2 Campaign-level breakdown
```sql
DECLARE @Tiers dbo.IDTableType
INSERT INTO @Tiers VALUES (1)
EXEC AffiliateReport.PortalReportSummaryByAffiliate
    @AffiliateId = 12345,
    @FromDate = '2026-01-01', @ToDate = '2026-03-31',
    @GroupByDate = 0, @GroupByMonth = 1,
    @GroupByBannerId = 1, @GroupBySerialId = 1,
    @GroupByAdditionalData = 0, @GroupByCustomerId = 0,
    @GroupByCountryId = 0, @GroupByTier = 0,
    @AggregateRegistrations = 1, @AggregateFTDs = 1,
    @AggregateSales = 0, @AggregateClicks = 1,
    @AggregateRefundAndChargeback = 0, @Tiers = @Tiers
```

### 8.3 Customer-level detail with asset names
```sql
DECLARE @Tiers dbo.IDTableType
INSERT INTO @Tiers VALUES (1)
EXEC AffiliateReport.PortalReportSummaryByAffiliate
    @AffiliateId = 12345,
    @FromDate = '2026-04-01', @ToDate = '2026-04-13',
    @GroupByDate = 1, @GroupByMonth = 0,
    @GroupByBannerId = 0, @GroupBySerialId = 0,
    @GroupByAdditionalData = 0, @GroupByCustomerId = 1,
    @GroupByCountryId = 0, @GroupByTier = 0,
    @AggregateRegistrations = 0, @AggregateFTDs = 1,
    @AggregateSales = 0, @AggregateClicks = 0,
    @AggregateRefundAndChargeback = 0, @Tiers = @Tiers
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-2448 (referenced in SQL comments) | Jira | CPA New Compensation Design (Dec 2023, Gil & Noga) |
| PART-3052 (referenced in SQL comments) | Jira | Fix rounding bug (May 2024, Gil Haba) |
| PART-4552 (referenced in SQL comments) | Jira | Enhancement (Jul 2025, Gil Haba) |
| PART-4802 (referenced in SQL comments) | Jira | Refund & chargeback reclassified as CPA not revenue (Aug 2025, Gil Haba) |
| PART-5499 (referenced in SQL comments) | Jira | Added ProductType & CommissionSource (Jan 2026, Gil Haba) |

No direct Confluence pages found for this procedure.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 5 Jira (ref) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateReport.PortalReportSummaryByAffiliate | Type: Stored Procedure | Source: fiktivo/AffiliateReport/Stored Procedures/AffiliateReport.PortalReportSummaryByAffiliate.sql*
