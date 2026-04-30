# AffiliateAdmin.ReportSummaryByAffiliateNoga

> Development/testing clone of ReportSummaryByAffiliate, generating the same comprehensive affiliate performance summary report with identical parameters and logic.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Result set of affiliate performance metrics |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** ReportSummaryByAffiliateNoga is a clone of `ReportSummaryByAffiliate` with identical structure, parameters (~60), and logic. It generates the same multi-metric affiliate performance summary report. The "Noga" suffix indicates this is a development or testing copy created by developer Noga, likely used for iterating on report changes without affecting the production version.

**WHY:** In complex reporting systems, it is common practice to create developer-specific copies of large stored procedures to test modifications in isolation. This allows the developer to modify report logic, add new metric columns, or adjust aggregation without risking the production report endpoint. The identical parameter signature ensures the same application code can call either version by changing only the procedure name.

**HOW:** The procedure follows the same multi-stage pipeline as `ReportSummaryByAffiliate`. It populates a `#Affiliates` temp table with filtered affiliates, then builds a `#Results` temp table by aggregating data from registration views, commission views, credit views, marketing expenses, and banner interaction tables. The ~40 show/hide bit parameters control column visibility. All table references, temp table structures, and query logic mirror the production version. See `ReportSummaryByAffiliate` documentation for full details.

---

## 2. Business Logic

### 2.1 Identical to ReportSummaryByAffiliate
All business logic is identical to `AffiliateAdmin.ReportSummaryByAffiliate`. This section summarizes the key stages; refer to the production version for comprehensive documentation.

### 2.2 Parameter Categories
The ~60 parameters fall into the same functional categories:
- **Date Range:** Start/end date parameters for filtering time-bound data
- **Show/Hide Toggles:** ~40 BIT parameters controlling which metric columns appear
- **Filter Parameters:** AffiliateID, GroupID, CountryID, RegionID, AffiliateTypeID
- **Grouping/Sorting:** Parameters controlling aggregation and ordering

### 2.3 Multi-Stage Query Pipeline
1. Stage 1: Populate `#Affiliates` with filtered affiliate population
2. Stage 2: Build `#Results` by joining registration, commission, credit, expense, and banner data
3. Stage 3: Return final result set with only the columns enabled by show/hide toggles

### 2.4 Development Copy Considerations
As a development clone, this procedure may diverge from the production version during active development cycles. Key differences to watch for:
- Additional experimental columns or metrics
- Modified aggregation logic under testing
- Potential data source changes being evaluated

### 2.5 Data Source References
Uses the same data sources as the production version: `AffiliateCommission.RegistrationVW`, `AffiliateCommission.CreditVW`, `AffiliateCommission.RegistrationCommission`, `AffiliateCommission.CreditCommission`, `tblaff_MarketingExpense`, `tblaff_Banners`, `MediaTagBanner`, and `AffiliateConfiguration.TraderFirstAssetPosition`.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

The procedure accepts approximately 60 parameters identical to `ReportSummaryByAffiliate`. Key parameters are listed below; the remainder are show/hide BIT flags.

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
| - | *(~40 additional)* | BIT | Yes | 0 | CODE-BACKED | Additional show/hide toggles for specific metric sub-columns |

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
| Development/testing environment | Application | Testing report modifications |
| Developer Noga's workspace | Application | Iterative report development |

---

## 6. Dependencies

### 6.0 Chain
`ReportSummaryByAffiliateNoga` -> `#Affiliates` (filter population) -> `RegistrationVW` + `CreditVW` + `MarketingExpense` + `Banners` (aggregate metrics) -> `#Results` (final assembly)

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
No known database dependencies. Development/testing copy -- not expected to be called from production application layer.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Generate a basic affiliate summary report (development version)
EXEC AffiliateAdmin.ReportSummaryByAffiliateNoga
    @StartDate = '2026-01-01',
    @EndDate = '2026-03-31',
    @ShowRegistrations = 1,
    @ShowCommissions = 1;
```

```sql
-- 2. Test filtered report for a specific group
EXEC AffiliateAdmin.ReportSummaryByAffiliateNoga
    @StartDate = '2026-01-01',
    @EndDate = '2026-03-31',
    @GroupID = 5,
    @ShowRegistrations = 1,
    @ShowCommissions = 1,
    @ShowCredits = 1,
    @ShowPNL = 1,
    @ShowMarketingExpense = 1;
```

```sql
-- 3. Compare output with production version
-- Run both and compare results for same parameters:
EXEC AffiliateAdmin.ReportSummaryByAffiliate
    @StartDate = '2026-01-01', @EndDate = '2026-03-31',
    @AffiliateID = 1234, @ShowRegistrations = 1, @ShowCommissions = 1;

EXEC AffiliateAdmin.ReportSummaryByAffiliateNoga
    @StartDate = '2026-01-01', @EndDate = '2026-03-31',
    @AffiliateID = 1234, @ShowRegistrations = 1, @ShowCommissions = 1;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL references: PART-5531, PART-5461, PART-4943, PART-4802.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.ReportSummaryByAffiliateNoga | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.ReportSummaryByAffiliateNoga.sql*
