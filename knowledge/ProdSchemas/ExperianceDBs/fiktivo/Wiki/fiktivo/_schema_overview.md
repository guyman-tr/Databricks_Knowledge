# fiktivo Schema Overview

> The fiktivo schema contains the legacy affiliate tracking infrastructure - download/install telemetry, pixel firing logs, IP geo-resolution, and the service layer stored procedures that create and manage commission records across all affiliate revenue streams.

## Schema Statistics

| Metric | Value |
|--------|-------|
| **Database** | fiktivo |
| **Schema** | fiktivo |
| **Total Objects** | 57 |
| **Tables** | 6 |
| **Views** | 9 |
| **Functions** | 5 |
| **Stored Procedures** | 37 |
| **Documentation Date** | 2026-04-12 |

---

## Schema Purpose

The fiktivo schema serves three primary functions in the affiliate marketing platform:

### 1. Download and Install Tracking
Tables `etoro_Download` and `etoro_Install` capture the application download and installation funnel - from initial download through installation completion and first-time run. Views (`viewDownloads`, `viewInstalls`, `viewFirstTimeRun`, `viewUnion`, `report_summary`) aggregate this data for daily reporting dashboards.

### 2. Conversion Pixel Logging
Tables `etoro_FTDPixel` and `etoro_LeadPixel` log the firing of conversion tracking pixels back to affiliate systems when customers complete key milestones (registration as a lead, first-time deposit). These are historical/legacy tables from 2008-2009 - the modern system uses the event-driven pipeline.

### 3. IP Geo-Resolution
The `CountryIP` table with its companion functions (`IPAddressToIPNum`, `GetCountryIDByIP`, `GetActualCountryIDByIP`) provides IP-to-country resolution for affiliate event attribution.

### 4. Commission Service Layer
37 stored procedures form the service API for the commission system:
- **Authentication**: ChangePassword, CheckPassword, DecryptPassword, EncryptPassword, IsPasswordExpired, P_ResetPassword, ValidateAffiliate
- **Commission Writers**: sp_Update{Bonuses|Chargebacks|CPA|CopyTraders|FirstPositions|Leads|Registrations|Sales}Commissions - INSERT/UPDATE commission records
- **Event Writers**: sp_UpdateCopyTraders, sp_UpdateFirstPositions, sp_UpdateSales - CREATE event records
- **Payment Processing**: spafw_Set{Bonuses|CPA|Chargebacks|CopyTraders|FirstPositions|Leads|Registrations|Sales|eCost}AsPaid - Mark commissions as paid
- **Reporting**: GetCommissionsForAffiliates, spafw_LeadsInPast60Days, spafw_SalesInPast60Days
- **Maintenance**: sp_defragindexes, spafw_RebuildIndices, spafw_DeleteOldCommissionsPriorToDate

---

## Data Flow

```
Visitor clicks affiliate link
       |
       v
[etoro_Download] --> [etoro_Install] --> First-time Run
       |                                      |
       v                                      v
[etoro_LeadPixel]                    [etoro_FTDPixel]
  (lead pixel fired)                 (FTD pixel fired)
       |                                      |
       v                                      v
sp_Update* procedures create event + commission records in dbo tables
       |
       v
spafw_Set*AsPaid marks commissions as paid during payment runs
       |
       v
GetCommissionsForAffiliates reports unpaid totals
```

---

## Cross-Schema Dependencies

The fiktivo schema heavily depends on the **dbo schema** for data storage:
- All event tables (tblaff_Sales, tblaff_Leads, tblaff_Registrations, etc.) are in dbo
- All commission tables (tblaff_*_Commissions) are in dbo
- Affiliate configuration (tblaff_Affiliates, tblaff_AffiliateTypes) is in dbo
- Country reference (tblaff_Country) is in dbo

The fiktivo schema contains only the service layer (procedures) and the tracking/telemetry tables unique to the affiliate platform.

---

## Key Business Concepts

- **Affiliate Funnel**: Download -> Install -> First-Time Run -> Registration (Lead) -> First Deposit (FTD) -> Sales
- **Commission Types**: First Positions, Sales, Bonuses, Chargebacks, CPA, Leads, Registrations, CopyTraders, eCost
- **Tiered Attribution**: Tier 1 = primary affiliate, Tier 2 = sub-affiliate
- **Pixel Tracking**: Legacy conversion notification mechanism (replaced by event-driven pipeline)
- **IP Geo-Resolution**: Country attribution via numeric IP range lookup

---

*Generated: 2026-04-12*
