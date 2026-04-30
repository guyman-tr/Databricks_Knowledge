# AffWizReports.GetFirstPositionAggregatedData

> Aggregates first-position commission data by affiliate for the AffWiz report, computing commission sums from customer first-trade events.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended JOIN clause for FirstPosition commission data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetFirstPositionAggregatedData aggregates first-position (first trade) commission data for the Affiliate Wizard report. A "first position" occurs when a referred customer opens their first trading position on the platform. Affiliates can earn a commission for this milestone event.

This procedure computes commission sums from `tblaff_FirstPositions` and `tblaff_FirstPositions_Commissions`, inserting results into `#FirstPositionAggregatedData`. It differs from GetFPAggregatedData which counts first positions; this SP sums the commissions paid for those events.

The procedure uses OriginalCID (original customer ID) rather than Optional3 for customer identification, reflecting that first-position tracking may predate the standard Optional3 convention used in other event tables.

---

## 2. Business Logic

### 2.1 First Position Commission Aggregation

**What**: Sums commissions earned per affiliate from customer first-trade events.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`, `@Tier`, `@PaymentStatus`

**Rules**:
- Joins tblaff_FirstPositions with tblaff_FirstPositions_Commissions on FirstPositionID
- Commission uses SUM(tblaff_FirstPositions_Commissions.Commission)
- Customer ID uses OriginalCID (not Optional3 like other event types)
- PaymentStatus filters on Paid column when specified
- Date range on ORDER_DATE with standard pattern

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
| 4 | @Tier | int | NO | - | CODE-BACKED | Commission tier filter. |
| 5 | @ShowDate | bit | NO | - | CODE-BACKED | When 1, groups by ORDER_DATE. |
| 6 | @ShowMonth | bit | NO | - | CODE-BACKED | When 1, groups by YEAR/MONTH. |
| 7 | @ShowProviderID | bit | NO | - | CODE-BACKED | When 1, groups by ProviderID. |
| 8 | @ShowDownloadID | bit | NO | - | CODE-BACKED | When 1, groups by DownloadID. |
| 9 | @ShowRelevantRevenues | bit | NO | - | CODE-BACKED | When 1, restricts via qry_aff_LeadRegistrationDate using Optional3. |
| 10 | @ShowSerialID | bit | NO | - | CODE-BACKED | When 1, groups by SubAffiliateID. |
| 11 | @ShowCountryName | bit | NO | - | CODE-BACKED | When 1, groups by CountryID. |
| 12 | @ShowBanner | bit | NO | - | CODE-BACKED | When 1, groups by BannerID. |
| 13 | @ShowPlayerLevel | bit | NO | - | CODE-BACKED | When 1, groups by PlayerLevelID. |
| 14 | @ShowCustomerID | bit | NO | - | CODE-BACKED | When 1, groups by OriginalCID as CustomerID. |
| 15 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | When 1, groups by CountryID for region lookup. |
| 16 | @ShowLabelID | bit | NO | - | CODE-BACKED | When 1, groups by LabelID. |
| 17 | @ShowFunnelID | bit | NO | - | CODE-BACKED | When 1, groups by FunnelID. |
| 18 | @PaymentStatus | bit | YES | - | CODE-BACKED | When not NULL, filters by Paid status on commissions. |
| 19 | @Debug | bit | YES | 0 | CODE-BACKED | Debug mode flag. |
| 20 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends LEFT JOIN for #FirstPositionAggregatedData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.tblaff_FirstPositions | Table read | First-position event data with OriginalCID |
| JOIN | dbo.tblaff_FirstPositions_Commissions | Table read | Commission amounts and affiliate attribution |
| WHERE subquery | fiktivo.qry_aff_LeadRegistrationDate | View read | Relevant revenues filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Populates #FirstPositionAggregatedData |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetFirstPositionAggregatedData (procedure)
+-- dbo.tblaff_FirstPositions (table)
+-- dbo.tblaff_FirstPositions_Commissions (table)
+-- fiktivo.qry_aff_LeadRegistrationDate (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_FirstPositions | Table | First-position events |
| dbo.tblaff_FirstPositions_Commissions | Table | Commission data |
| fiktivo.qry_aff_LeadRegistrationDate | View | Relevant revenues filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls for first-position commission metrics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View first position commissions

```sql
SELECT TOP 50 fp.ORDER_DATE, fpc.AffiliateID, fpc.Commission, fpc.Paid, fp.OriginalCID AS CustomerID
FROM dbo.tblaff_FirstPositions fp WITH (NOLOCK)
LEFT JOIN dbo.tblaff_FirstPositions_Commissions fpc WITH (NOLOCK) ON fp.FirstPositionID = fpc.FirstPositionID
WHERE fp.ORDER_DATE >= '2026-03-01'
ORDER BY fp.ORDER_DATE DESC
```

### 8.2 Aggregate first-position commissions by affiliate

```sql
SELECT fpc.AffiliateID, SUM(fpc.Commission) AS TotalCommission, COUNT(*) AS FirstPositionCount
FROM dbo.tblaff_FirstPositions fp WITH (NOLOCK)
LEFT JOIN dbo.tblaff_FirstPositions_Commissions fpc WITH (NOLOCK) ON fp.FirstPositionID = fpc.FirstPositionID
WHERE fp.ORDER_DATE >= '2026-03-01' AND fp.ORDER_DATE < '2026-04-01'
GROUP BY fpc.AffiliateID
ORDER BY TotalCommission DESC
```

### 8.3 Execute in debug mode

```sql
DECLARE @sql VARCHAR(MAX) = ' LEFT JOIN '
EXEC AffWizReports.GetFirstPositionAggregatedData
    @fromDate = '2026-03-01', @toDate = '2026-03-31',
    @BannerId = NULL, @Tier = 0, @ShowDate = 0, @ShowMonth = 1,
    @ShowProviderID = 0, @ShowDownloadID = 0, @ShowRelevantRevenues = 0,
    @ShowSerialID = 0, @ShowCountryName = 0, @ShowBanner = 0,
    @ShowPlayerLevel = 0, @ShowCustomerID = 0, @ShowMarketingRegion = 0,
    @ShowLabelID = 0, @ShowFunnelID = 0, @PaymentStatus = NULL,
    @Debug = 1, @strSQL = @sql OUTPUT
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffWizReports.GetFirstPositionAggregatedData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetFirstPositionAggregatedData.sql*
