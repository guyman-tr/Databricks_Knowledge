# AffWizReports.GetFTDData

> Builds the dynamic SQL SELECT DISTINCT clause for individual First Time Deposit (FTD) records, contributing rows to allDataUnion. Uses INNER JOIN subquery to commission records.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended SELECT DISTINCT clause |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetFTDData builds the raw FTD event query fragment for the AffWiz report. It extracts SELECT DISTINCT rows from `tblaff_CPA` INNER JOINed to a subquery on `dbo.tblaff_CPA_Commissions`, contributing FTD dimensional rows to the orchestrator's allDataUnion.

The INNER JOIN subquery pattern (similar to GetFPData) means only CPA events with commission records are included. This procedure does NOT filter to first deposits only (no Optional2=1 filter) - it includes all CPA events with commissions, letting the aggregation SPs handle the first-deposit filtering.

---

## 2. Business Logic

### 2.1 CPA Event Dimensional Extraction

**What**: Extracts CPA/deposit events that have commission records as dimensional rows.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`, `@Tier`

**Rules**:
- INNER JOIN to commission subquery - excludes events without commissions
- Subquery selects AffiliateID, DepositID, SubAffiliateID with optional Tier filter
- Customer ID uses Optional3
- No first-deposit filter (unlike GetFTDAggregatedData)

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
| 4 | @Tier | int | NO | - | CODE-BACKED | Commission tier filter in subquery. |
| 5 | @ShowDate | bit | NO | - | CODE-BACKED | When 1, includes ORDER_DATE as Date. |
| 6 | @ShowMonth | bit | NO | - | CODE-BACKED | When 1, includes YEAR/MONTH. |
| 7 | @ShowProviderID | bit | NO | - | CODE-BACKED | When 1, includes ProviderID. |
| 8 | @ShowDownloadID | bit | NO | - | CODE-BACKED | When 1, includes DownloadID. |
| 9 | @ShowRelevantRevenues | bit | NO | - | CODE-BACKED | When 1, restricts via qry_aff_LeadRegistrationDate. |
| 10 | @ShowSerialID | bit | NO | - | CODE-BACKED | When 1, includes SubAffiliateID as SerialID. |
| 11 | @ShowCountryName | bit | NO | - | CODE-BACKED | When 1, includes CountryID. |
| 12 | @ShowBanner | bit | NO | - | CODE-BACKED | When 1, includes BannerID. |
| 13 | @ShowPlayerLevel | bit | NO | - | CODE-BACKED | When 1, includes PlayerLevelID. |
| 14 | @ShowCustomerID | bit | NO | - | CODE-BACKED | When 1, includes Optional3 as CustomerID. |
| 15 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | When 1, includes CountryID. |
| 16 | @ShowLabelID | bit | NO | - | CODE-BACKED | When 1, includes LabelID. |
| 17 | @ShowFunnelID | bit | NO | - | CODE-BACKED | When 1, includes FunnelID. |
| 18 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends SELECT DISTINCT clause. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.tblaff_CPA | Table read | CPA/deposit events |
| INNER JOIN | dbo.tblaff_CPA_Commissions | Table read | Commission records (INNER JOIN subquery) |
| WHERE subquery | fiktivo.qry_aff_LeadRegistrationDate | View read | Relevant revenues filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Contributes FTD rows to allDataUnion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetFTDData (procedure)
+-- dbo.tblaff_CPA (table)
+-- dbo.tblaff_CPA_Commissions (table)
+-- fiktivo.qry_aff_LeadRegistrationDate (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_CPA | Table | CPA deposit event records |
| dbo.tblaff_CPA_Commissions | Table | Commission records (INNER JOIN) |
| fiktivo.qry_aff_LeadRegistrationDate | View | Relevant revenues filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls for FTD dimensional rows |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View CPA events with commissions

```sql
SELECT TOP 50 cpa.ORDER_DATE, comm.AffiliateID, comm.SubAffiliateID,
    cpa.Optional3 AS CustomerID, cpa.CountryID, cpa.BannerID
FROM dbo.tblaff_CPA cpa WITH (NOLOCK)
INNER JOIN dbo.tblaff_CPA_Commissions comm WITH (NOLOCK) ON comm.DepositID = cpa.DepositID
WHERE cpa.ORDER_DATE >= '2026-03-01'
ORDER BY cpa.ORDER_DATE DESC
```

### 8.2 Build FTD data SQL fragment

```sql
DECLARE @sql VARCHAR(MAX) = ' UNION ALL '
EXEC AffWizReports.GetFTDData
    @fromDate = '2026-03-01', @toDate = '2026-03-31',
    @BannerId = NULL, @Tier = 0, @ShowDate = 1, @ShowMonth = 0,
    @ShowProviderID = 0, @ShowDownloadID = 0, @ShowRelevantRevenues = 0,
    @ShowSerialID = 0, @ShowCountryName = 1, @ShowBanner = 0,
    @ShowPlayerLevel = 0, @ShowCustomerID = 1, @ShowMarketingRegion = 0,
    @ShowLabelID = 0, @ShowFunnelID = 0,
    @strSQL = @sql OUTPUT
PRINT @sql
```

### 8.3 Count CPA events with vs without commissions

```sql
SELECT
    (SELECT COUNT(*) FROM dbo.tblaff_CPA cpa WITH (NOLOCK)
     INNER JOIN dbo.tblaff_CPA_Commissions comm WITH (NOLOCK) ON comm.DepositID = cpa.DepositID
     WHERE cpa.ORDER_DATE >= '2026-03-01' AND cpa.ORDER_DATE < '2026-04-01') AS WithCommission,
    (SELECT COUNT(*) FROM dbo.tblaff_CPA cpa WITH (NOLOCK)
     WHERE cpa.ORDER_DATE >= '2026-03-01' AND cpa.ORDER_DATE < '2026-04-01') AS TotalEvents
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffWizReports.GetFTDData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetFTDData.sql*
