# AffWizReports.GetLeadsAggregatedData

> Aggregates lead counts and commissions by affiliate from tblaff_Leads for the AffWiz report.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended JOIN clause for lead data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetLeadsAggregatedData computes lead counts and commissions per affiliate. A "lead" represents a customer who completed verification/KYC after registration - a qualified prospect. Lead commissions are a key compensation metric for affiliates operating under CPL (Cost Per Lead) models.

The procedure uses a specific index hint (`INDEX(IX_tblaff_Leads_ORDER_DATE)`) on the Leads table for date range performance. Results are inserted into `#LeadsAggregatedData`.

---

## 2. Business Logic

### 2.1 Lead Aggregation

**What**: Counts leads and sums commissions per affiliate.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`, `@Tier`, `@PaymentStatus`

**Rules**:
- Lead count: COUNT(tblaff_Leads.LeadID)
- Commission: SUM(tblaff_Leads_Commissions.Commission)
- Uses index hint IX_tblaff_Leads_ORDER_DATE for date range queries
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
| 20 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends LEFT JOIN for #LeadsAggregatedData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.tblaff_Leads | Table read | Lead event data with index hint |
| JOIN | dbo.tblaff_Leads_Commissions | Table read | Commission amounts and affiliate attribution |
| WHERE subquery | fiktivo.qry_aff_LeadRegistrationDate | View read | Relevant revenues filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Populates #LeadsAggregatedData |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetLeadsAggregatedData (procedure)
+-- dbo.tblaff_Leads (table)
+-- dbo.tblaff_Leads_Commissions (table)
+-- fiktivo.qry_aff_LeadRegistrationDate (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Leads | Table | Lead events (with index hint) |
| dbo.tblaff_Leads_Commissions | Table | Commission data |
| fiktivo.qry_aff_LeadRegistrationDate | View | Relevant revenues filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls for lead metrics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View lead data

```sql
SELECT TOP 50 l.ORDER_DATE, lc.AffiliateID, lc.Commission, l.CountryID, l.Optional3 AS CustomerID
FROM dbo.tblaff_Leads l WITH (NOLOCK) LEFT JOIN dbo.tblaff_Leads_Commissions lc WITH (NOLOCK) ON l.LeadID = lc.LeadID
WHERE l.ORDER_DATE >= '2026-03-01' ORDER BY l.ORDER_DATE DESC
```

### 8.2 Aggregate leads by affiliate

```sql
SELECT lc.AffiliateID, COUNT(*) AS Leads, SUM(lc.Commission) AS TotalCommission
FROM dbo.tblaff_Leads l WITH (NOLOCK, INDEX(IX_tblaff_Leads_ORDER_DATE))
LEFT JOIN dbo.tblaff_Leads_Commissions lc WITH (NOLOCK) ON l.LeadID = lc.LeadID
WHERE l.ORDER_DATE >= '2026-03-01' AND l.ORDER_DATE < '2026-04-01'
GROUP BY lc.AffiliateID ORDER BY Leads DESC
```

### 8.3 Execute in debug mode

```sql
DECLARE @sql VARCHAR(MAX) = ' LEFT JOIN '
EXEC AffWizReports.GetLeadsAggregatedData
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
*Object: AffWizReports.GetLeadsAggregatedData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetLeadsAggregatedData.sql*
