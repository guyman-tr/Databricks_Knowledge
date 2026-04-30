# AffiliateAdmin.ReportSummaryByAffiliate

> Generates a comprehensive affiliate performance summary report with configurable columns, date filtering, and aggregation across registrations, commissions, credits, and marketing expenses.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Result set of affiliate performance metrics |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** ReportSummaryByAffiliate is a large, complex reporting procedure (~400 lines) that generates a multi-metric performance summary for affiliates. It accepts approximately 60 parameters that control date ranges, column visibility (show/hide toggles), affiliate filters, and grouping options. The procedure aggregates data from registrations, commissions, credits, marketing expenses, and banner/media interactions to produce a comprehensive performance dashboard.

**WHY:** Affiliate performance reporting is a core business function for any affiliate management platform. Stakeholders need to analyze affiliate contributions across multiple dimensions -- registrations generated, commissions earned, credit activity, and marketing spend efficiency. The high parameter count reflects the need for a single, flexible reporting endpoint that can serve multiple report variants (detailed vs. summary, filtered by group/country/type, with or without commission breakdowns) without requiring separate stored procedures for each view.

**HOW:** The procedure builds its result set through a multi-stage query pipeline. It first populates a `#Affiliates` temp table with the filtered set of affiliates based on group, country, region, and type criteria. It then constructs a `#Results` temp table by joining across registration views, commission views, credit views, marketing expense tables, and banner interaction data. The ~40 show/hide bit parameters control which columns are included in the final SELECT, allowing the application to request only the data dimensions needed for a particular report view. The procedure uses `AffiliateCommission.RegistrationVW`, `AffiliateCommission.CreditVW`, and related views to pre-aggregate commission data before final assembly.

---

## 2. Business Logic

### 2.1 Parameter Categories
The ~60 parameters fall into distinct functional categories:
- **Date Range:** Start/end date parameters for filtering time-bound data (registrations, commissions, credits)
- **Show/Hide Toggles:** ~40 BIT parameters that control which metric columns appear in the output (e.g., ShowRegistrations, ShowCommissions, ShowCredits, ShowPNL, etc.)
- **Filter Parameters:** AffiliateID, GroupID, CountryID, RegionID, AffiliateTypeID for narrowing the affiliate population
- **Grouping/Sorting:** Parameters controlling how results are aggregated and ordered

### 2.2 Affiliate Population Filtering
The first stage populates the `#Affiliates` temp table by selecting from `tblaff_Affiliates` with optional joins to `AffiliateAdmin.AffiliatesGroups`, `tblaff_Country`, and `Dictionary.MarketingRegion`. Filter parameters narrow the population; if a filter parameter is NULL or 0, that dimension is not filtered.

### 2.3 Registration Metrics
Registration data is sourced from `AffiliateCommission.RegistrationCommission` and `AffiliateCommission.RegistrationVW`. Metrics include registration counts, registration commission amounts, and country-specific registration breakdowns. Date range parameters filter the registration period.

### 2.4 Commission Aggregation
Commission data is aggregated from `AffiliateCommission.CreditVW` and `AffiliateCommission.CreditCommission`. This covers deposit commissions, trade commissions, PNL-based commissions, and other commission types defined in the affiliate type configuration.

### 2.5 Marketing Expense Integration
Marketing expense data from `tblaff_MarketingExpense` is joined to provide cost context alongside revenue metrics. This enables ROI calculations at the affiliate level.

### 2.6 Banner and Media Tag Metrics
Banner interaction data is joined through `tblaff_Banners` and `MediaTagBanner` to attribute banner performance to specific affiliates. This links creative asset performance to affiliate outcomes.

### 2.7 Temp Table Pipeline
The procedure uses a two-stage temp table approach:
1. `#Affiliates` - Filtered affiliate population with basic attributes
2. `#Results` - Final aggregated result set combining all metric dimensions

### 2.8 First Asset Position
Data from `AffiliateConfiguration.TraderFirstAssetPosition` is optionally included to track the first trading position of traders referred by each affiliate, providing quality-of-trader metrics.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

The procedure accepts approximately 60 parameters. The key parameters are listed below; the remainder are show/hide BIT flags controlling column visibility in the output.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | Yes | NULL | CODE-BACKED | Start of reporting date range |
| 2 | @EndDate | DATETIME | Yes | NULL | CODE-BACKED | End of reporting date range |
| 3 | @AffiliateID | INT | Yes | NULL | CODE-BACKED | Filter to a specific affiliate |
| 4 | @GroupID | INT | Yes | NULL | CODE-BACKED | Filter by affiliate group |
| 5 | @CountryID | INT | Yes | NULL | CODE-BACKED | Filter by country |
| 6 | @RegionID | INT | Yes | NULL | CODE-BACKED | Filter by marketing region |
| 7 | @AffiliateTypeID | INT | Yes | NULL | CODE-BACKED | Filter by affiliate type |
| 8 | @ShowRegistrations | BIT | Yes | 0 | CODE-BACKED | Include registration count columns |
| 9 | @ShowCommissions | BIT | Yes | 0 | CODE-BACKED | Include commission amount columns |
| 10 | @ShowCredits | BIT | Yes | 0 | CODE-BACKED | Include credit activity columns |
| 11 | @ShowPNL | BIT | Yes | 0 | CODE-BACKED | Include PNL-based commission columns |
| 12 | @ShowMarketingExpense | BIT | Yes | 0 | CODE-BACKED | Include marketing expense columns |
| 13 | @ShowBanners | BIT | Yes | 0 | CODE-BACKED | Include banner performance columns |
| 14 | @ShowDeposit | BIT | Yes | 0 | CODE-BACKED | Include deposit commission columns |
| 15 | @ShowCopyTrader | BIT | Yes | 0 | CODE-BACKED | Include copy trader commission columns |
| 16 | @ShowFirstPosition | BIT | Yes | 0 | CODE-BACKED | Include first asset position data |
| 17 | @SortColumn | NVARCHAR(100) | Yes | NULL | CODE-BACKED | Column name for result sorting |
| 18 | @SortDirection | NVARCHAR(4) | Yes | 'ASC' | CODE-BACKED | Sort direction (ASC/DESC) |
| - | *(~40 additional)* | BIT | Yes | 0 | CODE-BACKED | Additional show/hide toggles for specific metric sub-columns (e.g., ShowSaleCommission, ShowLeadCommission, ShowClickCommission, ShowIOB, ShowISA, etc.) |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Affiliates` | Table | Source affiliate records for population filtering |
| `AffiliateAdmin.AffiliatesGroups` | Table | JOIN for group-based filtering |
| `dbo.tblaff_Country` | Table | JOIN for country-based filtering |
| `Dictionary.MarketingRegion` | Table | JOIN for region-based filtering |
| `dbo.tblaff_MarketingExpense` | Table | Marketing expense data |
| `AffiliateCommission.RegistrationCommission` | Table | Registration commission amounts |
| `AffiliateCommission.RegistrationVW` | View | Pre-aggregated registration metrics |
| `AffiliateCommission.CreditVW` | View | Pre-aggregated credit metrics |
| `AffiliateCommission.CreditCommission` | Table | Credit commission amounts |
| `dbo.tblaff_Banners` | Table | Banner interaction data |
| `dbo.MediaTagBanner` | Table | Media tag to banner mapping |
| `AffiliateConfiguration.TraderFirstAssetPosition` | Table | First position tracking data |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Affiliate performance dashboard | Application | Main summary report view |
| Report export functionality | Application | CSV/Excel export of affiliate metrics |
| Management reporting | Application | Executive-level affiliate performance views |

---

## 6. Dependencies

### 6.0 Chain
`ReportSummaryByAffiliate` -> `#Affiliates` (filter population) -> `RegistrationVW` + `CreditVW` + `MarketingExpense` + `Banners` (aggregate metrics) -> `#Results` (final assembly)

### 6.1 Depends On
- `dbo.tblaff_Affiliates` - Core affiliate records
- `AffiliateAdmin.AffiliatesGroups` - Group membership for filtering
- `dbo.tblaff_Country` - Country reference data
- `Dictionary.MarketingRegion` - Region reference data
- `dbo.tblaff_MarketingExpense` - Marketing cost data
- `AffiliateCommission.RegistrationCommission` - Registration commission calculations
- `AffiliateCommission.RegistrationVW` - Pre-aggregated registration view
- `AffiliateCommission.CreditVW` - Pre-aggregated credit view
- `AffiliateCommission.CreditCommission` - Credit commission calculations
- `dbo.tblaff_Banners` - Banner records
- `dbo.MediaTagBanner` - Media tag junction table
- `AffiliateConfiguration.TraderFirstAssetPosition` - First position data

### 6.2 Depend On This
No known database dependencies. Called from application layer reporting module.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Generate a basic affiliate summary report for a date range
EXEC AffiliateAdmin.ReportSummaryByAffiliate
    @StartDate = '2026-01-01',
    @EndDate = '2026-03-31',
    @ShowRegistrations = 1,
    @ShowCommissions = 1;
```

```sql
-- 2. Filtered report for a specific affiliate group with all metrics
EXEC AffiliateAdmin.ReportSummaryByAffiliate
    @StartDate = '2026-01-01',
    @EndDate = '2026-03-31',
    @GroupID = 5,
    @ShowRegistrations = 1,
    @ShowCommissions = 1,
    @ShowCredits = 1,
    @ShowPNL = 1,
    @ShowMarketingExpense = 1,
    @ShowBanners = 1,
    @ShowDeposit = 1;
```

```sql
-- 3. Single affiliate detailed report with sorting
EXEC AffiliateAdmin.ReportSummaryByAffiliate
    @StartDate = '2026-01-01',
    @EndDate = '2026-03-31',
    @AffiliateID = 1234,
    @ShowRegistrations = 1,
    @ShowCommissions = 1,
    @ShowCredits = 1,
    @ShowFirstPosition = 1,
    @SortColumn = N'TotalCommission',
    @SortDirection = N'DESC';
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL references: PART-5531, PART-5461, PART-4943, PART-4802.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.ReportSummaryByAffiliate | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.ReportSummaryByAffiliate.sql*
