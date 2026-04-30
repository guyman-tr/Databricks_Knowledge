# AffWizReports.GetCopyTraderData

> Builds the dynamic SQL SELECT DISTINCT clause for individual CopyTrader event records, contributing rows to the report's allDataUnion dataset.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended SELECT DISTINCT clause |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetCopyTraderData builds the raw/individual-level CopyTrader event query fragment for the AffWiz report. Unlike its aggregated counterpart (GetCopyTraderAggregatedData), this procedure produces SELECT DISTINCT rows for each CopyTrader event, returning one row per unique combination of affiliate, date, and dimensional attributes.

This procedure exists to contribute CopyTrader event rows to the orchestrator's `allDataUnion` - a UNION ALL of all event types (registrations, leads, sales, FTD, downloads, installs, CopyTraders, etc.). The allDataUnion provides the dimensional backbone of the report - every unique combination of (AffiliateID, Date, SerialID, CountryID, ...) across all event types.

The procedure appends a SELECT DISTINCT clause to @strSQL. It reads from `tblaff_CopyTraders` LEFT JOINed to `tblaff_CopyTraders_Commissions` to get the AffiliateID and SubAffiliateID. Each @Show* flag controls whether the corresponding dimensional column is included or returned as NULL.

---

## 2. Business Logic

### 2.1 Dimensional Data Extraction

**What**: Extracts individual CopyTrader events as dimensional rows for the allDataUnion.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`, `@Tier`, all @Show* flags

**Rules**:
- Returns SELECT DISTINCT rows to avoid duplicate dimension combinations
- Each dimensional column is either included (from the source table) or returned as NULL based on the @Show* flag
- AffiliateID comes from tblaff_CopyTraders_Commissions (the commission record determines attribution)
- SubAffiliateID is collated with Latin1_General_Bin for case-sensitive matching
- Tier filtering restricts to a specific commission tier when @Tier > 0
- Date range uses ORDER_DATE with the standard >= start, < end+1 pattern

### 2.2 Relevant Revenues Filter

**What**: Optional restriction to customers with matching lead/registration dates.

**Columns/Parameters Involved**: `@ShowRelevantRevenues`

**Rules**:
- When enabled, uses EXISTS against fiktivo.qry_aff_LeadRegistrationDate to verify the customer (Optional3) had a lead in the date range

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fromDate | datetime | NO | - | CODE-BACKED | Start of reporting period (inclusive). Filters ORDER_DATE >= @fromDate. |
| 2 | @toDate | datetime | NO | - | CODE-BACKED | End of reporting period (inclusive). Filters ORDER_DATE < @toDate + 1 day. |
| 3 | @BannerId | int | NO | - | CODE-BACKED | Banner filter. When not NULL and @ShowBanner=1, restricts to events for this banner. |
| 4 | @Tier | int | NO | - | CODE-BACKED | Commission tier filter. 0 = all tiers, >0 = specific tier. |
| 5 | @ShowDate | bit | NO | - | CODE-BACKED | When 1, includes ORDER_DATE as Date. When 0, returns NULL AS Date. |
| 6 | @ShowMonth | bit | NO | - | CODE-BACKED | When 1, includes YEAR and MONTH from ORDER_DATE. When 0, returns NULL for both. |
| 7 | @ShowProviderID | bit | NO | - | CODE-BACKED | When 1, includes ProviderID from tblaff_CopyTraders. |
| 8 | @ShowDownloadID | bit | NO | - | CODE-BACKED | When 1, includes DownloadID from tblaff_CopyTraders. |
| 9 | @ShowRelevantRevenues | bit | NO | - | CODE-BACKED | When 1, restricts to customers present in qry_aff_LeadRegistrationDate for the date range. |
| 10 | @ShowSerialID | bit | NO | - | CODE-BACKED | When 1, includes SubAffiliateID as SerialID with binary collation. |
| 11 | @ShowCountryName | bit | NO | - | CODE-BACKED | When 1, includes CountryID from tblaff_CopyTraders. |
| 12 | @ShowBanner | bit | NO | - | CODE-BACKED | When 1, includes BannerID and enables banner filtering. |
| 13 | @ShowPlayerLevel | bit | NO | - | CODE-BACKED | When 1, includes PlayerLevelID from tblaff_CopyTraders. |
| 14 | @ShowCustomerID | bit | NO | - | CODE-BACKED | When 1, includes Optional3 as CustomerID. |
| 15 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | When 1, includes CountryID (resolved to region name in the orchestrator). |
| 16 | @ShowLabelID | bit | NO | - | CODE-BACKED | When 1, includes LabelID from tblaff_CopyTraders. |
| 17 | @ShowFunnelID | bit | NO | - | CODE-BACKED | When 1, includes FunnelID from tblaff_CopyTraders. |
| 18 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT parameter. Appends SELECT DISTINCT clause for CopyTrader dimensional data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.tblaff_CopyTraders | Table read | Source of CopyTrader event records with dimensional attributes |
| JOIN | dbo.tblaff_CopyTraders_Commissions | Table read | Provides AffiliateID and SubAffiliateID for attribution |
| WHERE subquery | fiktivo.qry_aff_LeadRegistrationDate | View read | Relevant revenues filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Called to contribute CopyTrader rows to allDataUnion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetCopyTraderData (procedure)
+-- dbo.tblaff_CopyTraders (table)
+-- dbo.tblaff_CopyTraders_Commissions (table)
+-- fiktivo.qry_aff_LeadRegistrationDate (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_CopyTraders | Table | Source of event records filtered by date and dimensional flags |
| dbo.tblaff_CopyTraders_Commissions | Table | Joined for affiliate attribution (AffiliateID, SubAffiliateID) |
| fiktivo.qry_aff_LeadRegistrationDate | View | Relevant revenues subquery filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls this SP for CopyTrader dimensional rows in allDataUnion |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Build CopyTrader data query fragment

```sql
DECLARE @sql VARCHAR(MAX) = ' UNION ALL '
EXEC AffWizReports.GetCopyTraderData
    @fromDate = '2026-03-01', @toDate = '2026-03-31',
    @BannerId = NULL, @Tier = 0,
    @ShowDate = 1, @ShowMonth = 0, @ShowProviderID = 0,
    @ShowDownloadID = 0, @ShowRelevantRevenues = 0,
    @ShowSerialID = 0, @ShowCountryName = 1, @ShowBanner = 0,
    @ShowPlayerLevel = 0, @ShowCustomerID = 0,
    @ShowMarketingRegion = 0, @ShowLabelID = 0, @ShowFunnelID = 0,
    @strSQL = @sql OUTPUT
PRINT @sql
```

### 8.2 View raw CopyTrader events

```sql
SELECT TOP 100
    cc.AffiliateID,
    cc.SubAffiliateID,
    ct.ORDER_DATE,
    ct.Optional3 AS CustomerID,
    ct.CountryID,
    ct.BannerID
FROM dbo.tblaff_CopyTraders ct WITH (NOLOCK)
LEFT JOIN dbo.tblaff_CopyTraders_Commissions cc WITH (NOLOCK)
    ON ct.CopyTraderID = cc.CopyTraderID
WHERE ct.ORDER_DATE >= '2026-03-01'
    AND ct.ORDER_DATE < '2026-04-01'
ORDER BY ct.ORDER_DATE DESC
```

### 8.3 Check distinct dimensional combinations

```sql
SELECT COUNT(DISTINCT CONCAT(cc.AffiliateID, '-', CAST(ct.ORDER_DATE AS DATE))) AS UniqueCombinations
FROM dbo.tblaff_CopyTraders ct WITH (NOLOCK)
LEFT JOIN dbo.tblaff_CopyTraders_Commissions cc WITH (NOLOCK)
    ON ct.CopyTraderID = cc.CopyTraderID
WHERE ct.ORDER_DATE >= '2026-03-01'
    AND ct.ORDER_DATE < '2026-04-01'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffWizReports.GetCopyTraderData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetCopyTraderData.sql*
