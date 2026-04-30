# AffWizReports.GetRegistrationsData

> Builds the dynamic SQL SELECT DISTINCT clause for individual registration records, contributing rows to allDataUnion.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended SELECT DISTINCT clause |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetRegistrationsData builds the raw registration event query fragment for the AffWiz report. It extracts SELECT DISTINCT dimensional rows from `tblaff_Registrations` LEFT JOINed to `tblaff_Registrations_Commissions`, contributing to allDataUnion.

Registrations represent customer account creation events - the first conversion step after download/install. This SP provides the dimensional backbone for registration metrics in the report.

---

## 2. Business Logic

### 2.1 Registration Dimensional Extraction

**What**: Extracts individual registration events as dimensional rows.

**Rules**:
- LEFT OUTER JOIN to commissions (includes registrations without commission records)
- Customer ID uses Optional3
- Uses EXISTS for relevant revenues filter

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
| 9 | @ShowRelevantRevenues | bit | NO | - | CODE-BACKED | When 1, restricts via EXISTS on qry_aff_LeadRegistrationDate. |
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
| FROM | dbo.tblaff_Registrations | Table read | Registration event data |
| JOIN | dbo.tblaff_Registrations_Commissions | Table read | Commission attribution (LEFT JOIN) |
| WHERE subquery | fiktivo.qry_aff_LeadRegistrationDate | View read | Relevant revenues filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Contributes registration rows to allDataUnion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetRegistrationsData (procedure)
+-- dbo.tblaff_Registrations (table)
+-- dbo.tblaff_Registrations_Commissions (table)
+-- fiktivo.qry_aff_LeadRegistrationDate (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Registrations | Table | Registration events |
| dbo.tblaff_Registrations_Commissions | Table | Commission attribution |
| fiktivo.qry_aff_LeadRegistrationDate | View | Relevant revenues filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls for registration dimensional rows |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View registration events

```sql
SELECT TOP 50 r.ORDER_DATE, rc.AffiliateID, rc.SubAffiliateID, r.CountryID, r.Optional3 AS CustomerID
FROM dbo.tblaff_Registrations r WITH (NOLOCK) LEFT JOIN dbo.tblaff_Registrations_Commissions rc WITH (NOLOCK) ON r.RegistrationID = rc.RegistrationID
WHERE r.ORDER_DATE >= '2026-03-01' ORDER BY r.ORDER_DATE DESC
```

### 8.2 Build registrations data SQL fragment

```sql
DECLARE @sql VARCHAR(MAX) = ' UNION ALL '
EXEC AffWizReports.GetRegistrationsData @fromDate = '2026-03-01', @toDate = '2026-03-31', @BannerId = NULL, @Tier = 0,
    @ShowDate = 1, @ShowMonth = 0, @ShowProviderID = 0, @ShowDownloadID = 0, @ShowRelevantRevenues = 0,
    @ShowSerialID = 0, @ShowCountryName = 1, @ShowBanner = 0, @ShowPlayerLevel = 0, @ShowCustomerID = 0,
    @ShowMarketingRegion = 0, @ShowLabelID = 0, @ShowFunnelID = 0, @strSQL = @sql OUTPUT
PRINT @sql
```

### 8.3 Count registrations by provider

```sql
SELECT ProviderID, COUNT(*) AS Registrations FROM dbo.tblaff_Registrations WITH (NOLOCK)
WHERE ORDER_DATE >= '2026-03-01' AND ORDER_DATE < '2026-04-01' GROUP BY ProviderID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffWizReports.GetRegistrationsData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetRegistrationsData.sql*
