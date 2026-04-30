# AffiliateReport.ReportSummaryByAffiliate_RAN

> Earlier admin-facing affiliate performance report variant with staging table optimization, supporting registrations, FTDs, sales, chargebacks, eCost, and active traders. Predecessor to the enhanced ReportSummaryByAffiliate.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateReport |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns aggregated commission/performance data (legacy admin variant) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ReportSummaryByAffiliate_RAN is the earlier variant of the admin affiliate performance report, originally written by Ran Ovadia (Jun 2022, PART-44) as a performance-optimized replacement for the legacy [AffWizReports].[ReportSummaryByAffiliate]. It shares the same core architecture as ReportSummaryByAffiliate (staged temp table with conditional AType inserts), but lacks the newer features: no click/impression support, no AdditionalData dimension, no banner attribute filtering, no monthly grouping, and single @AffiliateID (not comma-separated).

This procedure likely still serves some callers that haven't been migrated to the newer ReportSummaryByAffiliate. It follows the same AType UNION pattern (0=Registration, 1=CPA, 3=Sale, 4=Chargeback, 5=eCost, 6=Active Traders) with the same tier-aware attribution logic and dynamic temp table indexing.

Data is staged into a #Results temp table, indexed dynamically based on @ByTrackingDate, then aggregated in a final SELECT with conditional GROUP BY columns. Uses min/max ClosedPositionID pre-filtering for the Sales query and OPTION(RECOMPILE) on heavy queries.

---

## 2. Business Logic

### 2.1 Staged Temp Table Pattern (Same as ReportSummaryByAffiliate)

**What**: Commission data is conditionally inserted into #Results, then indexed and aggregated.

**Columns/Parameters Involved**: All @Show flags, #Results, #Affilaites

**Rules**:
- #Affilaites temp table built with indexed AffiliateID for efficient filtering
- Each AType is conditionally inserted based on @Show flags
- Dynamic indexes created on #Results based on @ByTrackingDate (TrackingDate or CommissionDate)
- Final SELECT joins #Results to #Affilaites, dbo.tblaff_Country, dbo.tblaff_Banners, Dictionary.MarketingRegion

### 2.2 AType Event Sources (6 types - no clicks)

**What**: Six commission/event types without click/impression support.

**Columns/Parameters Involved**: AType (internal)

**Rules**:
- AType 0 = Registration (AffiliateCommission.RegistrationCommission + Registration)
- AType 1 = CPA/FTD (AffiliateCommission.Credit + CreditCommission, CreditTypeID=1)
- AType 3 = Sale/RevShare (AffiliateCommission.ClosedPositionCommission + ClosedPosition)
- AType 4 = Chargeback (AffiliateCommission.Credit + CreditCommission, CreditTypeID IN (4,5))
- AType 5 = eCost (dbo.tblaff_eCost + tblaff_eCost_Commissions)
- AType 6 = Active Traders (derived from AType 3 results in #Results)
- Note: uses AffiliateCommission.Registration directly (not RegistrationVW like the newer variant)
- Note: uses AffiliateCommission.Credit directly (not CreditVW)

### 2.3 Output Metrics

**What**: Final aggregated output with commission breakdowns.

**Columns/Parameters Involved**: All output columns

**Rules**:
- Registrations = COUNT of AType 0
- FTD = COUNT of AType 1 WHERE Optional=1 (IsFirstDeposit)
- FTDE = COUNT of AType 1 WHERE Optional=1 AND IsValid=1
- CPA Commissions = SUM Commission of valid FTDs
- RevShare Commissions = SUM Commission of AType 3+4
- Gross Revenues = SUM Total of AType 3
- Net Revenues = SUM Total of AType 3+4 (includes chargebacks)
- Refunds & Chargebacks = SUM Total of AType 4
- eCost = SUM Commission of AType 5
- Active Traders = COUNT of AType 6
- Total Commissions = SUM of all Commission values

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | datetime | YES | NULL | CODE-BACKED | Start of reporting period (inclusive). |
| 2 | @ToDate | datetime | YES | NULL | CODE-BACKED | End of reporting period (inclusive). |
| 3 | @Tier | int | NO | 1 | CODE-BACKED | Affiliate tier level. 1=direct, 2+=sub-affiliate. |
| 4 | @BannerID | int | YES | NULL | CODE-BACKED | Optional banner filter. NULL = all banners. |
| 5 | @AffiliateID | int | YES | NULL | CODE-BACKED | Single affiliate ID filter. NULL = all (filtered by other criteria). Note: unlike ReportSummaryByAffiliate, this is INT not VARCHAR - single ID only. |
| 6 | @AffiliateCountry | int | YES | NULL | CODE-BACKED | Affiliate country filter. |
| 7 | @CountryName | varchar(50) | YES | NULL | CODE-BACKED | Comma-separated customer country IDs. |
| 8 | @ChannelID | int | YES | NULL | CODE-BACKED | Marketing channel filter. |
| 9 | @MarketingRegionGroup | varchar(4000) | YES | NULL | CODE-BACKED | Comma-separated marketing region IDs. |
| 10 | @CustomerID | bigint | YES | NULL | CODE-BACKED | Customer ID filter (OriginalCID). |
| 11 | @ShowDate | bit | NO | 0 | CODE-BACKED | Include Date dimension in grouping. |
| 12 | @ShowSerialID | bit | NO | 1 | CODE-BACKED | Include Campaign (SerialID) in grouping. |
| 13 | @ShowCountryName | bit | NO | 0 | CODE-BACKED | Include customer country in grouping. |
| 14 | @ShowChannelID | bit | NO | 0 | CODE-BACKED | Include marketing channel in output. |
| 15 | @ShowBanner | bit | NO | 0 | CODE-BACKED | Include banner name in grouping. |
| 16 | @ShowAffiliateID | bit | NO | 1 | CODE-BACKED | Include AffiliateID and Contact in output. |
| 17 | @ShowAffiliateGroups | bit | NO | 0 | CODE-BACKED | Include affiliate group name in output. |
| 18 | @ShowAffiliateCountry | bit | NO | 0 | CODE-BACKED | Include affiliate country in output. |
| 19 | @ShowRegistrations | bit | NO | 0 | CODE-BACKED | Enable Registration data (AType 0). |
| 20 | @ShowActiveTraders | bit | NO | 0 | CODE-BACKED | Derive Active Trader count from Sales results. |
| 21 | @ShowFTD | bit | NO | 1 | CODE-BACKED | Enable CPA/FTD data (AType 1). |
| 22 | @ShowSales | bit | NO | 1 | CODE-BACKED | Enable Sales/RevShare data (AType 3). |
| 23 | @ShowTotalCommissions | bit | NO | 0 | CODE-BACKED | Include total commission sum. |
| 24 | @ShoweCost | bit | NO | 0 | CODE-BACKED | Enable eCost data (AType 5). |
| 25 | @ShowCustomerID | bit | NO | 0 | CODE-BACKED | Include CustomerID in grouping. |
| 26 | @ShowMarketingRegion | bit | NO | 0 | CODE-BACKED | Include marketing region in output. |
| 27 | @AffGroups | varchar(4000) | YES | NULL | CODE-BACKED | Comma-separated affiliate group IDs. |
| 28 | @PaymentStatus | bit | YES | NULL | CODE-BACKED | Payment status filter. NULL=all, 1=paid, 0=unpaid. |
| 29 | @ByTrackingDate | bit | NO | 1 | CODE-BACKED | When 1, filter/group by TrackingDate. When 0, by CommissionDate. |
| 30 | @CID | bigint | YES | NULL | CODE-BACKED | Direct CID filter. |
| 31 | @ShowCID | bit | NO | 0 | CODE-BACKED | Include CID in grouping. |
| 32 | @ShowFTDCommission | bit | NO | 0 | CODE-BACKED | Enable CPA commission display. |
| 33 | @ShowDeposit | bit | NO | 0 | CODE-BACKED | Enable deposit amount display. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.RegistrationCommission | READ | Registration commission data |
| - | AffiliateCommission.Registration | READ | Registration details (direct table, not VW) |
| - | AffiliateCommission.Credit | READ | CPA/FTD and Chargeback data (direct table, not VW) |
| - | AffiliateCommission.CreditCommission | READ | Credit commission amounts |
| - | AffiliateCommission.ClosedPositionCommission | READ | Sale commission data |
| - | AffiliateCommission.ClosedPosition | READ | Closed position details (direct table) |
| - | dbo.tblaff_Affiliates | READ | Affiliate master data |
| - | dbo.tblaff_Country | READ | Country names |
| - | dbo.tblaff_AffiliatesGroups | READ | Affiliate group names |
| - | dbo.tblaff_Banners | READ | Banner names |
| - | dbo.tblaff_eCost | READ | eCost data |
| - | dbo.tblaff_eCost_Commissions | READ | eCost commissions |
| - | dbo.tblaff_MarketingExpense | READ | Marketing channel names |
| - | Dictionary.MarketingRegion | READ | Marketing region names |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Admin Dashboard (external) | - | Caller | Legacy admin reporting interface callers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateReport.ReportSummaryByAffiliate_RAN (procedure)
+-- AffiliateCommission.RegistrationCommission (table, cross-schema)
+-- AffiliateCommission.Registration (table, cross-schema)
+-- AffiliateCommission.Credit (table, cross-schema)
+-- AffiliateCommission.CreditCommission (table, cross-schema)
+-- AffiliateCommission.ClosedPositionCommission (table, cross-schema)
+-- AffiliateCommission.ClosedPosition (table, cross-schema)
+-- dbo.tblaff_Affiliates (table, cross-schema)
+-- dbo.tblaff_Country (table, cross-schema)
+-- dbo.tblaff_AffiliatesGroups (table, cross-schema)
+-- dbo.tblaff_Banners (table, cross-schema)
+-- dbo.tblaff_eCost (table, cross-schema)
+-- dbo.tblaff_eCost_Commissions (table, cross-schema)
+-- dbo.tblaff_MarketingExpense (table, cross-schema)
+-- Dictionary.MarketingRegion (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationCommission | Table | Registration commission data |
| AffiliateCommission.Registration | Table | Registration details (direct, not VW) |
| AffiliateCommission.Credit | Table | CPA/FTD and chargeback data (direct, not VW) |
| AffiliateCommission.ClosedPosition | Table | Closed position details + min/max ID |
| dbo.tblaff_Affiliates | Table | Affiliate master data |
| Dictionary.MarketingRegion | Table | Region name resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Admin Dashboard (external) | Application | Legacy callers not yet migrated to ReportSummaryByAffiliate |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure (creates dynamic temp table indexes at runtime).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION(RECOMPILE) | Query Hint | Applied on CPA and Sales queries |
| Dynamic temp indexes | Runtime | IX_AffiliateIDTrackingDate or IX_AffiliateIDCommissionDate on #Results |

---

## 8. Sample Queries

### 8.1 Basic report for a single affiliate
```sql
EXEC AffiliateReport.ReportSummaryByAffiliate_RAN
    @FromDate = '2026-04-01', @ToDate = '2026-04-13',
    @AffiliateID = 12345,
    @ShowDate = 1, @ShowFTD = 1, @ShowSales = 1
```

### 8.2 Multi-dimension report with eCost and active traders
```sql
EXEC AffiliateReport.ReportSummaryByAffiliate_RAN
    @FromDate = '2026-01-01', @ToDate = '2026-03-31',
    @ShowDate = 1, @ShowAffiliateID = 1,
    @ShowRegistrations = 1, @ShowFTD = 1, @ShowSales = 1,
    @ShoweCost = 1, @ShowActiveTraders = 1, @ShowTotalCommissions = 1
```

### 8.3 Payment audit - unpaid commissions only
```sql
EXEC AffiliateReport.ReportSummaryByAffiliate_RAN
    @FromDate = '2026-04-01', @ToDate = '2026-04-13',
    @PaymentStatus = 0,
    @ShowAffiliateID = 1, @ShowFTD = 1, @ShowSales = 1
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-44 (referenced in SQL comments) | Jira | Original rewrite from AffWizReports (Jun 2022, Ran O & Noga R) |

No direct Confluence pages found for this procedure.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 33 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 1 Jira (ref) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateReport.ReportSummaryByAffiliate_RAN | Type: Stored Procedure | Source: fiktivo/AffiliateReport/Stored Procedures/AffiliateReport.ReportSummaryByAffiliate_RAN.sql*
