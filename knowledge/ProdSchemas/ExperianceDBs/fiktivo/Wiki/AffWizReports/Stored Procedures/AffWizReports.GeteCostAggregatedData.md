# AffWizReports.GeteCostAggregatedData

> Aggregates eCost (electronic cost/marketing expense) commission data by affiliate for the AffWiz report.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended JOIN clause for eCost data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GeteCostAggregatedData computes eCost (electronic cost) commission totals per affiliate for the Affiliate Wizard report. eCost represents marketing expenses or cost reimbursements tracked in the affiliate system through the `tblaff_eCost` and `tblaff_eCost_Commissions` tables.

This procedure aggregates eCost event counts and commission amounts, inserting results into `#eCostAggregatedData`. The eCost metric allows tracking affiliate-driven marketing costs alongside revenue metrics in the same report, enabling ROI calculations.

A notable difference from other aggregation SPs: when @ShowPlayerLevel, @ShowLabelID, or @ShowFunnelID are enabled, this SP returns 0 for those dimensions rather than looking them up from the source table (eCost events do not carry player level, label, or funnel data).

---

## 2. Business Logic

### 2.1 eCost Aggregation

**What**: Counts eCost events and sums commissions per affiliate.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`, `@Tier`, `@PaymentStatus`

**Rules**:
- eCost count uses `COUNT(tblaff_eCost.eCostID)`
- Commission sum uses `SUM(tblaff_eCost_Commissions.Commission)`
- PlayerLevelID, LabelID, FunnelID always return 0 (not available in eCost data)
- Payment status filter on tblaff_eCost_Commissions.Paid when specified

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
| 9 | @ShowRelevantRevenues | bit | NO | - | CODE-BACKED | When 1, restricts to customers in qry_aff_LeadRegistrationDate. |
| 10 | @ShowSerialID | bit | NO | - | CODE-BACKED | When 1, groups by SubAffiliateID. |
| 11 | @ShowCountryName | bit | NO | - | CODE-BACKED | When 1, groups by CountryID. |
| 12 | @ShowBanner | bit | NO | - | CODE-BACKED | When 1, groups by BannerID. |
| 13 | @ShowPlayerLevel | bit | NO | - | CODE-BACKED | When 1, includes 0 AS PlayerLevelID (eCost has no player level data). |
| 14 | @ShowCustomerID | bit | NO | - | CODE-BACKED | When 1, groups by Optional3 (CustomerID). |
| 15 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | When 1, groups by CountryID for region lookup. |
| 16 | @ShowLabelID | bit | NO | - | CODE-BACKED | When 1, includes 0 AS LabelID (eCost has no label data). |
| 17 | @ShowFunnelID | bit | NO | - | CODE-BACKED | When 1, includes 0 AS FunnelID (eCost has no funnel data). |
| 18 | @PaymentStatus | bit | YES | - | CODE-BACKED | When not NULL, filters by Paid status. |
| 19 | @Debug | bit | YES | 0 | CODE-BACKED | Debug mode flag. |
| 20 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends LEFT JOIN for #eCostAggregatedData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.tblaff_eCost | Table read | eCost event data |
| JOIN | dbo.tblaff_eCost_Commissions | Table read | Commission amounts and affiliate attribution |
| WHERE subquery | fiktivo.qry_aff_LeadRegistrationDate | View read | Relevant revenues filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Populates #eCostAggregatedData |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GeteCostAggregatedData (procedure)
+-- dbo.tblaff_eCost (table)
+-- dbo.tblaff_eCost_Commissions (table)
+-- fiktivo.qry_aff_LeadRegistrationDate (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_eCost | Table | Source of eCost events |
| dbo.tblaff_eCost_Commissions | Table | Commission data joined on eCostID |
| fiktivo.qry_aff_LeadRegistrationDate | View | Relevant revenues filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls for eCost metrics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View eCost data

```sql
SELECT TOP 50 e.ORDER_DATE, ec.AffiliateID, ec.Commission, ec.Paid, e.Optional3 AS CustomerID
FROM dbo.tblaff_eCost e WITH (NOLOCK)
LEFT JOIN dbo.tblaff_eCost_Commissions ec WITH (NOLOCK) ON e.eCostID = ec.eCostID
WHERE e.ORDER_DATE >= '2026-03-01'
ORDER BY e.ORDER_DATE DESC
```

### 8.2 Aggregate eCost by affiliate

```sql
SELECT ec.AffiliateID, COUNT(*) AS eCosts, SUM(ec.Commission) AS TotalCommission
FROM dbo.tblaff_eCost e WITH (NOLOCK)
LEFT JOIN dbo.tblaff_eCost_Commissions ec WITH (NOLOCK) ON e.eCostID = ec.eCostID
WHERE e.ORDER_DATE >= '2026-03-01' AND e.ORDER_DATE < '2026-04-01'
GROUP BY ec.AffiliateID
ORDER BY TotalCommission DESC
```

### 8.3 Execute in debug mode

```sql
DECLARE @sql VARCHAR(MAX) = ' LEFT JOIN '
EXEC AffWizReports.GeteCostAggregatedData
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
*Object: AffWizReports.GeteCostAggregatedData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GeteCostAggregatedData.sql*
