# AffWizReports.GetFPAggregatedData

> Aggregates first-position COUNT data (not commissions) by affiliate for the AffWiz report, with optional LTV calculation.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended JOIN clause for FP count data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetFPAggregatedData counts first-position events per affiliate for the Affiliate Wizard report. While GetFirstPositionAggregatedData sums commissions, this SP counts the number of first positions and optionally calculates LTV (Lifetime Value) from the `tblaff_CustomersLTV` table.

This procedure exists to report the "FP" (First Position) metric - how many referred customers opened their first trade. It also supports LTV aggregation when @ShowLtv=1, joining to `dbo.tblaff_CustomersLTV` to sum customer lifetime values.

Notable: this SP hardcodes `Tier = 1` (unlike other SPs that use @Tier parameter), meaning it always reports Tier 1 first-position counts regardless of the tier parameter.

---

## 2. Business Logic

### 2.1 First Position Count with LTV

**What**: Counts first-position events and optionally sums customer LTV per affiliate.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`, `@ShowLtv`

**Rules**:
- FirstPosition count uses COUNT(CAST(Optional2 AS INT))
- Always filters to Tier = 1 (hardcoded, not using @Tier parameter)
- LTV joins tblaff_CustomersLTV on SerialID=AffiliateID AND CustomerID=OriginalCID
- Uses OriginalCID for customer identification
- LTV is SUM(tblaff_CustomersLTV.Ltv)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fromDate | datetime | NO | - | CODE-BACKED | Start of reporting period. |
| 2 | @toDate | datetime | NO | - | CODE-BACKED | End of reporting period. |
| 3 | @BannerId | int | NO | - | CODE-BACKED | Banner filter. |
| 4 | @Tier | int | NO | - | CODE-BACKED | Not used - Tier is hardcoded to 1 in this SP. Present for interface compatibility. |
| 5 | @ShowDate | bit | NO | - | CODE-BACKED | When 1, groups by ORDER_DATE. |
| 6 | @ShowMonth | bit | NO | - | CODE-BACKED | When 1, groups by YEAR/MONTH. |
| 7 | @ShowProviderID | bit | NO | - | CODE-BACKED | When 1, groups by ProviderID. |
| 8 | @ShowDownloadID | bit | NO | - | CODE-BACKED | When 1, groups by DownloadID. |
| 9 | @ShowRelevantRevenues | bit | NO | - | CODE-BACKED | When 1, restricts via qry_aff_LeadRegistrationDate. |
| 10 | @ShowSerialID | bit | NO | - | CODE-BACKED | When 1, groups by SubAffiliateID. |
| 11 | @ShowCountryName | bit | NO | - | CODE-BACKED | When 1, groups by CountryID. |
| 12 | @ShowBanner | bit | NO | - | CODE-BACKED | When 1, groups by BannerID. |
| 13 | @ShowPlayerLevel | bit | NO | - | CODE-BACKED | When 1, groups by PlayerLevelID. |
| 14 | @ShowCustomerID | bit | NO | - | CODE-BACKED | When 1, groups by OriginalCID as CustomerID. |
| 15 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | When 1, groups by CountryID. |
| 16 | @ShowLtv | bit | NO | - | CODE-BACKED | When 1, LEFT JOINs tblaff_CustomersLTV and includes SUM(Ltv) AS LTV. Key differentiator for this SP. |
| 17 | @ShowLabelID | bit | NO | - | CODE-BACKED | When 1, groups by LabelID. |
| 18 | @ShowFunnelID | bit | NO | - | CODE-BACKED | When 1, groups by FunnelID. |
| 19 | @Debug | bit | YES | 0 | CODE-BACKED | Debug mode flag. |
| 20 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends LEFT JOIN for #FPAggregatedData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.tblaff_FirstPositions | Table read | First-position event data |
| JOIN | dbo.tblaff_FirstPositions_Commissions | Table read | Affiliate attribution |
| JOIN | dbo.tblaff_CustomersLTV | Table read | Customer lifetime value data (when @ShowLtv=1) |
| WHERE subquery | fiktivo.qry_aff_LeadRegistrationDate | View read | Relevant revenues filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Populates #FPAggregatedData for first-position count and LTV |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetFPAggregatedData (procedure)
+-- dbo.tblaff_FirstPositions (table)
+-- dbo.tblaff_FirstPositions_Commissions (table)
+-- dbo.tblaff_CustomersLTV (table)
+-- fiktivo.qry_aff_LeadRegistrationDate (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_FirstPositions | Table | First-position events |
| dbo.tblaff_FirstPositions_Commissions | Table | Affiliate attribution |
| dbo.tblaff_CustomersLTV | Table | Customer LTV data (optional) |
| fiktivo.qry_aff_LeadRegistrationDate | View | Relevant revenues filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls for FP count and LTV metrics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View first positions with LTV

```sql
SELECT fpc.AffiliateID, fp.OriginalCID, fp.ORDER_DATE, ltv.Ltv
FROM dbo.tblaff_FirstPositions fp WITH (NOLOCK)
LEFT JOIN dbo.tblaff_FirstPositions_Commissions fpc WITH (NOLOCK) ON fp.FirstPositionID = fpc.FirstPositionID
LEFT JOIN dbo.tblaff_CustomersLTV ltv WITH (NOLOCK) ON ltv.SerialID = fpc.AffiliateID AND ltv.CustomerID = fp.OriginalCID
WHERE fp.ORDER_DATE >= '2026-03-01' AND fpc.Tier = 1
ORDER BY fp.ORDER_DATE DESC
```

### 8.2 Aggregate FP count with LTV by affiliate

```sql
SELECT fpc.AffiliateID, COUNT(*) AS FPCount, SUM(ISNULL(ltv.Ltv, 0)) AS TotalLTV
FROM dbo.tblaff_FirstPositions fp WITH (NOLOCK)
LEFT JOIN dbo.tblaff_FirstPositions_Commissions fpc WITH (NOLOCK) ON fp.FirstPositionID = fpc.FirstPositionID
LEFT JOIN dbo.tblaff_CustomersLTV ltv WITH (NOLOCK) ON ltv.SerialID = fpc.AffiliateID AND ltv.CustomerID = fp.OriginalCID
WHERE fp.ORDER_DATE >= '2026-03-01' AND fp.ORDER_DATE < '2026-04-01' AND fpc.Tier = 1
GROUP BY fpc.AffiliateID
ORDER BY TotalLTV DESC
```

### 8.3 Execute in debug mode

```sql
DECLARE @sql VARCHAR(MAX) = ' LEFT JOIN '
EXEC AffWizReports.GetFPAggregatedData
    @fromDate = '2026-03-01', @toDate = '2026-03-31',
    @BannerId = NULL, @Tier = 0, @ShowDate = 0, @ShowMonth = 1,
    @ShowProviderID = 0, @ShowDownloadID = 0, @ShowRelevantRevenues = 0,
    @ShowSerialID = 0, @ShowCountryName = 0, @ShowBanner = 0,
    @ShowPlayerLevel = 0, @ShowCustomerID = 0, @ShowMarketingRegion = 0,
    @ShowLtv = 1, @ShowLabelID = 0, @ShowFunnelID = 0,
    @Debug = 1, @strSQL = @sql OUTPUT
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffWizReports.GetFPAggregatedData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetFPAggregatedData.sql*
