# AffWizReports.GeteCostData

> Builds the dynamic SQL SELECT DISTINCT clause for individual eCost records, contributing rows to the report's allDataUnion dataset.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended SELECT DISTINCT clause |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GeteCostData builds the raw eCost event query fragment for the AffWiz report. It produces SELECT DISTINCT rows for each eCost (electronic cost/marketing expense) event, contributing dimensional rows to the orchestrator's allDataUnion.

eCost events are sourced from `tblaff_eCost` LEFT JOINed to `tblaff_eCost_Commissions`. Each event has an AffiliateID (from commissions), optional SubAffiliateID, and standard dimensional attributes. Unlike some other data SPs, eCost data does not carry PlayerLevelID, LabelID, or FunnelID - these are always returned as NULL.

---

## 2. Business Logic

### 2.1 eCost Dimensional Extraction

**What**: Extracts individual eCost events as dimensional rows.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`, `@Tier`

**Rules**:
- PlayerLevelID, LabelID, FunnelID always return NULL (not available in eCost data)
- Other dimensions (CountryID, ProviderID, DownloadID, CustomerID) are conditionally included
- Tier filtering on tblaff_eCost_Commissions.Tier

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
| 5 | @ShowDate | bit | NO | - | CODE-BACKED | When 1, includes ORDER_DATE as Date. |
| 6 | @ShowMonth | bit | NO | - | CODE-BACKED | When 1, includes YEAR/MONTH. |
| 7 | @ShowProviderID | bit | NO | - | CODE-BACKED | When 1, includes ProviderID. |
| 8 | @ShowDownloadID | bit | NO | - | CODE-BACKED | When 1, includes DownloadID. |
| 9 | @ShowRelevantRevenues | bit | NO | - | CODE-BACKED | When 1, restricts via qry_aff_LeadRegistrationDate. |
| 10 | @ShowSerialID | bit | NO | - | CODE-BACKED | When 1, includes SubAffiliateID as SerialID. |
| 11 | @ShowCountryName | bit | NO | - | CODE-BACKED | When 1, includes CountryID. |
| 12 | @ShowBanner | bit | NO | - | CODE-BACKED | When 1, includes BannerID. |
| 13 | @ShowPlayerLevel | bit | NO | - | CODE-BACKED | Not used - eCost lacks player level data. Returns NULL. |
| 14 | @ShowCustomerID | bit | NO | - | CODE-BACKED | When 1, includes Optional3 as CustomerID. |
| 15 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | When 1, includes CountryID for region resolution. |
| 16 | @ShowLabelID | bit | NO | - | CODE-BACKED | Not used - eCost lacks label data. Returns NULL. |
| 17 | @ShowFunnelID | bit | NO | - | CODE-BACKED | Not used - eCost lacks funnel data. Returns NULL. |
| 18 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends SELECT DISTINCT clause for eCost dimensional data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.tblaff_eCost | Table read | eCost event data |
| JOIN | dbo.tblaff_eCost_Commissions | Table read | Commission attribution |
| WHERE subquery | fiktivo.qry_aff_LeadRegistrationDate | View read | Relevant revenues filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Contributes eCost rows to allDataUnion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GeteCostData (procedure)
+-- dbo.tblaff_eCost (table)
+-- dbo.tblaff_eCost_Commissions (table)
+-- fiktivo.qry_aff_LeadRegistrationDate (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_eCost | Table | eCost event source |
| dbo.tblaff_eCost_Commissions | Table | Affiliate attribution via eCostID JOIN |
| fiktivo.qry_aff_LeadRegistrationDate | View | Relevant revenues filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls for eCost dimensional rows |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View eCost events with commissions

```sql
SELECT TOP 50 e.ORDER_DATE, ec.AffiliateID, ec.SubAffiliateID,
    e.CountryID, e.ProviderID, e.Optional3 AS CustomerID, ec.Commission
FROM dbo.tblaff_eCost e WITH (NOLOCK)
LEFT JOIN dbo.tblaff_eCost_Commissions ec WITH (NOLOCK) ON e.eCostID = ec.eCostID
WHERE e.ORDER_DATE >= '2026-03-01'
ORDER BY e.ORDER_DATE DESC
```

### 8.2 Build eCost data SQL fragment

```sql
DECLARE @sql VARCHAR(MAX) = ' UNION ALL '
EXEC AffWizReports.GeteCostData
    @fromDate = '2026-03-01', @toDate = '2026-03-31',
    @BannerId = NULL, @Tier = 0, @ShowDate = 1, @ShowMonth = 0,
    @ShowProviderID = 0, @ShowDownloadID = 0, @ShowRelevantRevenues = 0,
    @ShowSerialID = 0, @ShowCountryName = 1, @ShowBanner = 0,
    @ShowPlayerLevel = 0, @ShowCustomerID = 0, @ShowMarketingRegion = 0,
    @ShowLabelID = 0, @ShowFunnelID = 0,
    @strSQL = @sql OUTPUT
PRINT @sql
```

### 8.3 Count eCost events by tier

```sql
SELECT ec.Tier, COUNT(*) AS EventCount, SUM(ec.Commission) AS TotalCommission
FROM dbo.tblaff_eCost e WITH (NOLOCK)
LEFT JOIN dbo.tblaff_eCost_Commissions ec WITH (NOLOCK) ON e.eCostID = ec.eCostID
WHERE e.ORDER_DATE >= '2026-03-01' AND e.ORDER_DATE < '2026-04-01'
GROUP BY ec.Tier
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffWizReports.GeteCostData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GeteCostData.sql*
