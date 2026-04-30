# AffiliateReport.ReportSummaryByAffiliate

> Admin-facing comprehensive affiliate performance report with extensive filtering (multi-affiliate, banner attributes, media tags, payment status), conditional grouping, and optimized temp table staging for large-scale commission data across registrations, FTDs, sales, chargebacks, clicks, eCost, and active traders.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateReport |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns aggregated commission/performance data with full admin filtering |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ReportSummaryByAffiliate is the primary admin-facing affiliate performance report. Unlike the Portal variants (which serve a single affiliate's self-service view), this procedure serves internal operations staff who need to analyze performance across multiple affiliates with extensive filtering: by affiliate group, country, marketing channel, banner attributes (language, type, media tags, target URL), payment status, and customer-level drill-down. It is the most feature-rich report in the AffiliateReport schema.

This procedure exists to power the internal affiliate admin dashboard. It replaced the legacy [AffWizReports].[ReportSummaryByAffiliate] (Jun 2022, Ran O & Noga R, PART-44) and has undergone continuous enhancement: registration commission support (PART-1277), multi-affiliate filtering (PART-817/815), monthly grouping (PART-454), CPA revenue (PART-2440), clicks/impressions (PART-2855), ClosedPositionDailySummary optimization (PART-3602), AdditionalData filtering (PART-3664), banner attribute filtering (latest additions).

The procedure uses an optimized staging pattern: it builds a #Affiliaites temp table (indexed) of qualifying affiliates, inserts commission data into a #Results temp table conditionally (only enabled ATypes), creates dynamic indexes on #Results based on the date mode, then performs the final aggregation with GROUP BY. Uses OPTION(RECOMPILE) on heavy queries and min/max ID pre-filtering for CreditID and ClosedPositionID range optimization.

---

## 2. Business Logic

### 2.1 Multi-Affiliate + Filter Pipeline

**What**: Pre-filters qualifying affiliates into a temp table before querying commission data.

**Columns/Parameters Involved**: `@AffiliateID`, `@AffiliateCountry`, `@ChannelID`, `@AffGroups`, `@MarketingRegionGroup`

**Rules**:
- @AffiliateID accepts comma-separated list (parsed via STRING_SPLIT) - supports multi-affiliate reporting
- #Affiliaites temp table is built by joining dbo.tblaff_Affiliates with Country, Groups, MarketingExpense
- Indexed on AffiliateID for efficient IN subquery performance
- All subsequent commission queries filter by `AffiliateID IN (SELECT AffiliateID FROM #Affiliaites)`

### 2.2 Banner Attribute Filtering

**What**: Conditionally filters commission data by banner language, type, media tags, and target URL.

**Columns/Parameters Involved**: `@ShowBannerLanguage`, `@BannerLanguages`, `@ShowBannerType`, `@BannerTypes`, `@ShowMediaTags`, `@MediaTags`, `@ShowBannerTargetUrl`, `@BannerTargetUrl`

**Rules**:
- Each banner filter is activated only when both the @Show flag AND the parameter TVP are populated
- @BannerFilterExists = sum of all active filters (0 = no banner filtering needed)
- When active, commission queries LEFT JOIN to dbo.tblaff_Banners and the filter TVPs
- Registration and CPA queries support all 4 banner filters; Sales queries use standard BannerID filter

### 2.3 Staged #Results with Dynamic Indexing

**What**: Commission data is staged into a temp table with indexes created dynamically based on the date mode.

**Columns/Parameters Involved**: `@ByTrackingDate`, `#Results`

**Rules**:
- #Results includes TheMonth and TheYear columns for monthly grouping support
- When @ByTrackingDate=1: index on (AffiliateID, TrackingDate) with INCLUDE of all other columns
- When @ByTrackingDate=0: index on (AffiliateID, CommissionDate) with INCLUDE of all other columns
- This dynamic indexing ensures the final aggregation query can seek efficiently regardless of date mode

### 2.4 AType Event Sources (7 types)

**What**: The most comprehensive AType set across all report SPs.

**Columns/Parameters Involved**: AType (internal), all @Show flags

**Rules**:
- AType 0 = Registration (AffiliateCommission.RegistrationCommission + RegistrationVW)
- AType 1 = CPA/FTD (AffiliateCommission.CreditVW + CreditCommission, CreditTypeID=1)
- AType 3 = Sale/RevShare (AffiliateCommission.ClosedPositionCommission + ClosedPosition)
- AType 4 = Chargeback/Refund (AffiliateCommission.Credit + CreditCommission, CreditTypeID IN (4,5))
- AType 5 = eCost (dbo.tblaff_eCost + tblaff_eCost_Commissions)
- AType 6 = Active Traders (derived from AType 3 sales results - duplicated with zeroed commission)
- Clicks/Impressions are aggregated from AffiliateClicks.ClicksImpressionsAggregation when @ShowClicks=1
- Each AType is conditionally inserted based on @Show flags
- Note: AType 3 (Sales) uses pre-calculated min/max ClosedPositionID for range optimization
- Note: AType 6 (Active Traders) is generated from existing #Results WHERE AType=3 (avoids re-querying)

### 2.5 Tier-Aware Commission Attribution

**What**: Commission attribution varies by tier level.

**Columns/Parameters Involved**: `@Tier`, `AffiliateID`

**Rules**:
- When @Tier=1: filters by Tier=1 AND affiliate from #Affiliaites (the affiliate is the direct referrer)
- When @Tier!=1: filters by Tier=@Tier AND the COMMISSION record's AffiliateID from #Affiliaites (sub-affiliate commission)
- This dual condition handles the difference between direct and sub-affiliate commission attribution

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | datetime | YES | NULL | CODE-BACKED | Start of the reporting period (inclusive). Used as >= filter on tracking or commission dates. |
| 2 | @ToDate | datetime | YES | NULL | CODE-BACKED | End of the reporting period (inclusive). Used as <= filter. |
| 3 | @Tier | int | NO | 1 | CODE-BACKED | Affiliate tier level to report on. 1 = direct affiliate, 2+ = sub-affiliate tiers. Controls commission attribution logic. |
| 4 | @BannerID | int | YES | NULL | CODE-BACKED | Optional single banner filter. NULL = all banners. |
| 5 | @AffiliateID | varchar(4000) | YES | NULL | CODE-BACKED | Comma-separated list of affiliate IDs to include. NULL = all affiliates (filtered by other criteria). Parsed via STRING_SPLIT. |
| 6 | @AffiliateCountry | int | YES | NULL | CODE-BACKED | Filter affiliates by their registered country. NULL = all countries. |
| 7 | @CountryName | varchar(50) | YES | NULL | CODE-BACKED | Comma-separated customer country IDs for filtering result rows. |
| 8 | @ChannelID | int | YES | NULL | CODE-BACKED | Marketing expense channel filter on affiliates. NULL = all channels. |
| 9 | @MarketingRegionGroup | varchar(4000) | YES | NULL | CODE-BACKED | Comma-separated marketing region IDs for filtering. |
| 10 | @CustomerID | bigint | YES | NULL | CODE-BACKED | Optional customer ID filter (OriginalCID). NULL = all customers. |
| 11 | @ShowDate | bit | NO | 0 | CODE-BACKED | When 1, includes Date in grouping output. |
| 12 | @ShowSerialID | bit | NO | 1 | CODE-BACKED | When 1, includes Campaign (SerialID) in grouping output. |
| 13 | @ShowAdditionalData | bit | NO | 1 | CODE-BACKED | When 1, includes AdditionalData in grouping output. Added PART-3664. |
| 14 | @ShowCountryName | bit | NO | 0 | CODE-BACKED | When 1, includes customer country in grouping output. |
| 15 | @ShowChannelID | bit | NO | 0 | CODE-BACKED | When 1, includes marketing channel in output. |
| 16 | @ShowBanner | bit | NO | 0 | CODE-BACKED | When 1, includes banner name in grouping output. |
| 17 | @ShowAffiliateID | bit | NO | 1 | CODE-BACKED | When 1, includes AffiliateID and Contact name in output. |
| 18 | @ShowAffiliateGroups | bit | NO | 0 | CODE-BACKED | When 1, includes affiliate group name in output. |
| 19 | @ShowAffiliateCountry | bit | NO | 0 | CODE-BACKED | When 1, includes affiliate country in output. |
| 20 | @ShowRegistrations | bit | NO | 0 | CODE-BACKED | When 1, enables Registration data (AType 0) and Clicks branches. |
| 21 | @ShowActiveTraders | bit | NO | 0 | CODE-BACKED | When 1, derives Active Trader count from Sales results (AType 6). |
| 22 | @ShowFTD | bit | NO | 1 | CODE-BACKED | When 1, enables CPA/FTD data (AType 1). |
| 23 | @ShowSales | bit | NO | 1 | CODE-BACKED | When 1, enables Sales/RevShare data (AType 3). |
| 24 | @ShowTotalCommissions | bit | NO | 0 | CODE-BACKED | When 1, includes total commission sum in output. |
| 25 | @ShoweCost | bit | NO | 0 | CODE-BACKED | When 1, enables eCost data (AType 5). |
| 26 | @ShowCustomerID | bit | NO | 0 | CODE-BACKED | When 1, includes customer ID in grouping output. |
| 27 | @ShowMarketingRegion | bit | NO | 0 | CODE-BACKED | When 1, includes marketing region in output. |
| 28 | @AffGroups | varchar(4000) | YES | NULL | CODE-BACKED | Comma-separated affiliate group IDs for filtering. |
| 29 | @PaymentStatus | bit | YES | NULL | CODE-BACKED | Filter by commission payment status. NULL = all statuses. 1 = paid, 0 = unpaid. |
| 30 | @ByTrackingDate | bit | NO | 1 | CODE-BACKED | When 1, date filters use TrackingDate. When 0, use CommissionDate. Also controls dynamic index creation on #Results. |
| 31 | @CID | bigint | YES | NULL | CODE-BACKED | Optional customer CID filter (direct CID, not OriginalCID). |
| 32 | @ShowCID | bit | NO | 0 | CODE-BACKED | When 1, includes CID in grouping output. |
| 33 | @ShowFTDCommission | bit | NO | 0 | CODE-BACKED | When 1, enables CPA commission display (valid FTDs only). |
| 34 | @ShowDeposit | bit | NO | 0 | CODE-BACKED | When 1, enables deposit amount display (all deposits, not just FTD). |
| 35 | @ShowMonth | bit | NO | 0 | CODE-BACKED | When 1, includes Month+Year in grouping output. Added PART-454. |
| 36 | @ShowClicks | bit | NO | 0 | CODE-BACKED | When 1, enables Clicks/Impressions aggregation from AffiliateClicks schema. Added PART-2855. |
| 37 | @ShowBannerLanguage | bit | NO | 0 | CODE-BACKED | When 1 with @BannerLanguages populated, filters by banner language. |
| 38 | @BannerLanguages | dbo.IDTableType | NO | - | CODE-BACKED | TVP of banner language IDs to filter by. |
| 39 | @ShowBannerType | bit | NO | 0 | CODE-BACKED | When 1 with @BannerTypes populated, filters by banner type. |
| 40 | @BannerTypes | dbo.IDTableType | NO | - | CODE-BACKED | TVP of banner type IDs to filter by. |
| 41 | @ShowMediaTags | bit | NO | 0 | CODE-BACKED | When 1 with @MediaTags populated, filters by media tags. |
| 42 | @MediaTags | dbo.IDTableType | NO | - | CODE-BACKED | TVP of media tag IDs to filter by. |
| 43 | @ShowBannerTargetUrl | bit | NO | 0 | CODE-BACKED | When 1 with @BannerTargetUrl set, filters by banner target URL. |
| 44 | @BannerTargetUrl | nvarchar(255) | YES | NULL | CODE-BACKED | Banner target URL to filter by (exact match). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.RegistrationCommission | READ | Registration commission data (AType 0) |
| - | AffiliateCommission.RegistrationVW | READ | Registration details |
| - | AffiliateCommission.CreditVW | READ | CPA/FTD credit data (AType 1) |
| - | AffiliateCommission.CreditCommission | READ | Credit commission amounts |
| - | AffiliateCommission.Credit | READ | Direct Credit table for min/max CreditID optimization |
| - | AffiliateCommission.ClosedPositionCommission | READ | Sale commission data (AType 3) |
| - | AffiliateCommission.ClosedPosition | READ | Direct ClosedPosition table for min/max ID optimization |
| - | AffiliateConfiguration.TraderFirstAssetPosition | READ (LEFT JOIN) | First position asset type |
| - | AffiliateClicks.ClicksImpressionsAggregation | READ | Click/impression counts |
| - | dbo.tblaff_Affiliates | READ | Affiliate master data for #Affiliaites temp table |
| - | dbo.tblaff_Country | READ | Country name resolution |
| - | dbo.tblaff_AffiliatesGroups | READ | Affiliate group names |
| - | dbo.tblaff_Banners | READ | Banner names and attributes |
| - | dbo.tblaff_eCost | READ | eCost data (AType 5) |
| - | dbo.tblaff_eCost_Commissions | READ | eCost commission amounts |
| - | dbo.tblaff_MarketingExpense | READ | Marketing expense/channel names |
| - | dbo.MediaTagBanner | READ | Banner-to-media-tag mappings |
| - | Dictionary.MarketingRegion | READ | Marketing region names. See [Marketing Region](../../_glossary.md#marketing-region) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Admin Dashboard (external) | - | Caller | Internal affiliate admin reporting interface |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateReport.ReportSummaryByAffiliate (procedure)
+-- AffiliateCommission.RegistrationCommission (table, cross-schema)
+-- AffiliateCommission.RegistrationVW (view, cross-schema)
+-- AffiliateCommission.CreditVW (view, cross-schema)
+-- AffiliateCommission.CreditCommission (table, cross-schema)
+-- AffiliateCommission.Credit (table, cross-schema)
+-- AffiliateCommission.ClosedPositionCommission (table, cross-schema)
+-- AffiliateCommission.ClosedPosition (table, cross-schema)
+-- AffiliateConfiguration.TraderFirstAssetPosition (table, cross-schema)
+-- AffiliateClicks.ClicksImpressionsAggregation (table, cross-schema)
+-- dbo.tblaff_Affiliates (table, cross-schema)
+-- dbo.tblaff_Country (table, cross-schema)
+-- dbo.tblaff_AffiliatesGroups (table, cross-schema)
+-- dbo.tblaff_Banners (table, cross-schema)
+-- dbo.tblaff_eCost (table, cross-schema)
+-- dbo.tblaff_eCost_Commissions (table, cross-schema)
+-- dbo.tblaff_MarketingExpense (table, cross-schema)
+-- dbo.MediaTagBanner (table, cross-schema)
+-- Dictionary.MarketingRegion (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationCommission | Table | Registration commission data |
| AffiliateCommission.RegistrationVW | View | Registration details |
| AffiliateCommission.CreditVW | View | CPA/FTD credit data |
| AffiliateCommission.Credit | Table | Min/max CreditID optimization |
| AffiliateCommission.ClosedPositionCommission | Table | Sale commission data |
| AffiliateCommission.ClosedPosition | Table | Min/max ClosedPositionID optimization |
| AffiliateClicks.ClicksImpressionsAggregation | Table | Click/impression counts |
| dbo.tblaff_Affiliates | Table | Affiliate master data |
| dbo.tblaff_Banners | Table | Banner names and attribute filtering |
| Dictionary.MarketingRegion | Table | Region name resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Admin Dashboard (external) | Application | Internal affiliate performance reporting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure (creates dynamic temp table indexes at runtime).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION(RECOMPILE) | Query Hint | Applied on CPA and Sales queries to handle variable parameter combinations |
| Dynamic temp indexes | Runtime | IX_AffiliateIDTrackingDate or IX_AffiliateIDCommissionDate created on #Results based on @ByTrackingDate |

---

## 8. Sample Queries

### 8.1 Basic admin report for all affiliates
```sql
EXEC AffiliateReport.ReportSummaryByAffiliate
    @FromDate = '2026-04-01', @ToDate = '2026-04-13',
    @ShowDate = 1, @ShowAffiliateID = 1,
    @ShowFTD = 1, @ShowSales = 1, @ShowRegistrations = 1
```

### 8.2 Multi-affiliate with banner filtering
```sql
DECLARE @BL dbo.IDTableType, @BT dbo.IDTableType, @MT dbo.IDTableType
EXEC AffiliateReport.ReportSummaryByAffiliate
    @FromDate = '2026-01-01', @ToDate = '2026-03-31',
    @AffiliateID = '12345,67890',
    @ShowDate = 0, @ShowMonth = 1,
    @ShowAffiliateID = 1, @ShowBanner = 1,
    @ShowFTD = 1, @ShowSales = 1,
    @BannerLanguages = @BL, @BannerTypes = @BT, @MediaTags = @MT
```

### 8.3 Full report with clicks and eCost
```sql
DECLARE @BL dbo.IDTableType, @BT dbo.IDTableType, @MT dbo.IDTableType
EXEC AffiliateReport.ReportSummaryByAffiliate
    @FromDate = '2026-04-01', @ToDate = '2026-04-13',
    @ShowDate = 1, @ShowAffiliateID = 1,
    @ShowRegistrations = 1, @ShowFTD = 1, @ShowSales = 1,
    @ShowClicks = 1, @ShoweCost = 1, @ShowActiveTraders = 1,
    @ShowTotalCommissions = 1,
    @BannerLanguages = @BL, @BannerTypes = @BT, @MediaTags = @MT
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-44 (referenced in SQL comments) | Jira | Original rewrite from AffWizReports (Jun 2022, Ran O & Noga R) |
| PART-454 (referenced in SQL comments) | Jira | Added @ShowMonth flag (Aug 2022, Noga) |
| PART-817/815 (referenced in SQL comments) | Jira | Multi-affiliate ID list support (Dec 2022, Noga) |
| PART-1277 (referenced in SQL comments) | Jira | Registration commission support (Mar 2023, Noga) |
| PART-2440 (referenced in SQL comments) | Jira | New CPA revenue support (Nov 2023, Noga) |
| PART-2855 (referenced in SQL comments) | Jira | Clicks and impressions support (Mar 2024, Noga) |
| PART-2997 (referenced in SQL comments) | Jira | BannerID filter (May 2024, Noga) |
| PART-3602 (referenced in SQL comments) | Jira | ClosedPositionDailySummary partition optimization (Nov 2024, Noga) |
| PART-3664 (referenced in SQL comments) | Jira | AdditionalData filter (Nov 2024, Noga) |
| PART-3693 (referenced in SQL comments) | Jira | AdditionalData for Clicks (Nov 2024, Noga) |
| PART-4613 (referenced in SQL comments) | Jira | Fix duplicate FTD with multiple banner tags (Jul 2025, Noga) |
| PART-4943 (referenced in SQL comments) | Jira | Fix TO date issue in Registrations (Oct 2025, Noga) |

No direct Confluence pages found for this procedure.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 44 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 12 Jira (ref) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateReport.ReportSummaryByAffiliate | Type: Stored Procedure | Source: fiktivo/AffiliateReport/Stored Procedures/AffiliateReport.ReportSummaryByAffiliate.sql*
