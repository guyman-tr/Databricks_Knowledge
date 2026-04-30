# AffWizReports.GetRegistrationsAggregatedData

> Aggregates registration counts and commissions by affiliate from tblaff_Registrations for the AffWiz report.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended JOIN clause for registration data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetRegistrationsAggregatedData computes registration counts and commissions per affiliate. Registrations are the earliest post-download conversion event - when a referred customer creates an account on the platform. Registration commissions compensate affiliates under CPR (Cost Per Registration) models.

The procedure aggregates from `tblaff_Registrations` LEFT JOINed to `tblaff_Registrations_Commissions` on RegistrationID. Results are inserted into `#RegistrationsAggregatedData`.

---

## 2. Business Logic

### 2.1 Registration Aggregation

**What**: Counts registrations and sums commissions per affiliate.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`, `@Tier`, `@PaymentStatus`

**Rules**:
- Registration count: COUNT(tblaff_Registrations.RegistrationID)
- Commission: SUM(tblaff_Registrations_Commissions.Commission)
- Customer ID uses Optional3
- Tier and PaymentStatus filtering on commission records

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
| 9 | @ShowRelevantRevenues | bit | NO | - | CODE-BACKED | When 1, restricts via qry_aff_LeadRegistrationDate. |
| 10 | @ShowSerialID | bit | NO | - | CODE-BACKED | When 1, groups by SubAffiliateID. |
| 11 | @ShowCountryName | bit | NO | - | CODE-BACKED | When 1, groups by CountryID. |
| 12 | @ShowBanner | bit | NO | - | CODE-BACKED | When 1, groups by BannerID. |
| 13 | @ShowPlayerLevel | bit | NO | - | CODE-BACKED | When 1, groups by PlayerLevelID. |
| 14 | @ShowCustomerID | bit | NO | - | CODE-BACKED | When 1, groups by Optional3 (CustomerID). |
| 15 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | When 1, groups by CountryID. |
| 16 | @ShowLabelID | bit | NO | - | CODE-BACKED | When 1, groups by LabelID. |
| 17 | @ShowFunnelID | bit | NO | - | CODE-BACKED | When 1, groups by FunnelID. |
| 18 | @PaymentStatus | bit | YES | - | CODE-BACKED | When not NULL, filters by Paid status. |
| 19 | @Debug | bit | YES | 0 | CODE-BACKED | Debug mode flag. |
| 20 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends LEFT JOIN for #RegistrationsAggregatedData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.tblaff_Registrations | Table read | Registration event data |
| JOIN | dbo.tblaff_Registrations_Commissions | Table read | Commission amounts and affiliate attribution |
| WHERE subquery | fiktivo.qry_aff_LeadRegistrationDate | View read | Relevant revenues filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Populates #RegistrationsAggregatedData |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetRegistrationsAggregatedData (procedure)
+-- dbo.tblaff_Registrations (table)
+-- dbo.tblaff_Registrations_Commissions (table)
+-- fiktivo.qry_aff_LeadRegistrationDate (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Registrations | Table | Registration events |
| dbo.tblaff_Registrations_Commissions | Table | Commission data |
| fiktivo.qry_aff_LeadRegistrationDate | View | Relevant revenues filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls for registration metrics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View registration data

```sql
SELECT TOP 50 r.ORDER_DATE, rc.AffiliateID, rc.Commission, r.CountryID, r.Optional3 AS CustomerID
FROM dbo.tblaff_Registrations r WITH (NOLOCK) LEFT JOIN dbo.tblaff_Registrations_Commissions rc WITH (NOLOCK) ON r.RegistrationID = rc.RegistrationID
WHERE r.ORDER_DATE >= '2026-03-01' ORDER BY r.ORDER_DATE DESC
```

### 8.2 Aggregate registrations by affiliate

```sql
SELECT rc.AffiliateID, COUNT(*) AS Registrations, SUM(rc.Commission) AS TotalCommission
FROM dbo.tblaff_Registrations r WITH (NOLOCK) LEFT JOIN dbo.tblaff_Registrations_Commissions rc WITH (NOLOCK) ON r.RegistrationID = rc.RegistrationID
WHERE r.ORDER_DATE >= '2026-03-01' AND r.ORDER_DATE < '2026-04-01'
GROUP BY rc.AffiliateID ORDER BY Registrations DESC
```

### 8.3 Execute in debug mode

```sql
DECLARE @sql VARCHAR(MAX) = ' LEFT JOIN '
EXEC AffWizReports.GetRegistrationsAggregatedData
    @fromDate = '2026-03-01', @toDate = '2026-03-31', @BannerId = NULL, @Tier = 0,
    @ShowDate = 0, @ShowMonth = 1, @ShowProviderID = 0, @ShowDownloadID = 0,
    @ShowRelevantRevenues = 0, @ShowSerialID = 0, @ShowCountryName = 0, @ShowBanner = 0,
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
*Object: AffWizReports.GetRegistrationsAggregatedData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetRegistrationsAggregatedData.sql*
