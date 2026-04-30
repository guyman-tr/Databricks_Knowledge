# AffWizReports.GetFTDEAggregatedData

> Aggregates First Time Deposit Eligible (FTDE) counts and amounts by affiliate from the CPA table, filtering to valid eligible deposits only.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended JOIN clause for FTDE data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetFTDEAggregatedData computes First Time Deposit Eligible (FTDE) metrics per affiliate. FTDE represents deposits that meet eligibility criteria for commission payment - a deposit must be the customer's first AND pass validation checks (Valid=1) to count as FTDE.

This procedure differs from GetFTDAggregatedData in one critical way: it adds `WHERE tblaff_CPA.Valid = 1` to filter for validated/eligible deposits only. FTD counts all first deposits; FTDE counts only those that passed eligibility rules. The FTDE metric is key for CPA-based affiliate compensation.

Results are inserted into `#FTDEAggregatedData` and joined to the report via @strSQL.

---

## 2. Business Logic

### 2.1 FTDE vs FTD Distinction

**What**: FTDE adds a validity check on top of the FTD filter.

**Columns/Parameters Involved**: `tblaff_CPA.Valid`, `tblaff_CPA.Optional2`

**Rules**:
- Filters to `CAST(Optional2 AS INT) = 1` (first deposit) AND `Valid = 1` (eligible)
- FTDE count: SUM(CAST(Optional2 AS INT))
- FTDE amount: SUM(GRAND_TOTAL) when @ShowFTDEAmount=1
- LTV optionally included via tblaff_CustomersLTV join
- A deposit can be FTD but not FTDE if it fails eligibility rules

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
| 13 | @ShowFTDEAmount | bit | NO | - | CODE-BACKED | When 1, includes SUM(GRAND_TOTAL) AS FTDEAmount. |
| 14 | @ShowPlayerLevel | bit | NO | - | CODE-BACKED | When 1, groups by PlayerLevelID. |
| 15 | @ShowCustomerID | bit | NO | - | CODE-BACKED | When 1, groups by Optional3 (CustomerID). |
| 16 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | When 1, groups by CountryID. |
| 17 | @ShowLtv | bit | NO | - | CODE-BACKED | When 1, JOINs tblaff_CustomersLTV for LTV. |
| 18 | @ShowLabelID | bit | NO | - | CODE-BACKED | When 1, groups by LabelID. |
| 19 | @ShowFunnelID | bit | NO | - | CODE-BACKED | When 1, groups by FunnelID. |
| 20 | @Debug | bit | YES | 0 | CODE-BACKED | Debug mode flag. |
| 21 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends LEFT JOIN for #FTDEAggregatedData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.tblaff_CPA | Table read | CPA deposits filtered to Valid=1 AND Optional2=1 |
| JOIN | dbo.tblaff_CPA_Commissions | Table read | Commission attribution |
| JOIN | dbo.tblaff_CustomersLTV | Table read | LTV data (optional) |
| WHERE subquery | fiktivo.qry_aff_LeadRegistrationDate | View read | Relevant revenues filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Populates #FTDEAggregatedData |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetFTDEAggregatedData (procedure)
+-- dbo.tblaff_CPA (table)
+-- dbo.tblaff_CPA_Commissions (table)
+-- dbo.tblaff_CustomersLTV (table)
+-- fiktivo.qry_aff_LeadRegistrationDate (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_CPA | Table | CPA deposits (Valid=1 filter) |
| dbo.tblaff_CPA_Commissions | Table | Commission attribution |
| dbo.tblaff_CustomersLTV | Table | LTV data (optional) |
| fiktivo.qry_aff_LeadRegistrationDate | View | Relevant revenues filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls for FTDE metrics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Compare FTD vs FTDE counts

```sql
SELECT
    SUM(CASE WHEN CAST(Optional2 AS INT) = 1 THEN 1 ELSE 0 END) AS FTD_All,
    SUM(CASE WHEN CAST(Optional2 AS INT) = 1 AND Valid = 1 THEN 1 ELSE 0 END) AS FTDE_Eligible
FROM dbo.tblaff_CPA WITH (NOLOCK)
WHERE ORDER_DATE >= '2026-03-01' AND ORDER_DATE < '2026-04-01'
```

### 8.2 FTDE by affiliate with amounts

```sql
SELECT comm.AffiliateID,
    SUM(CAST(cpa.Optional2 AS INT)) AS FTDE,
    SUM(cpa.GRAND_TOTAL) AS FTDEAmount
FROM dbo.tblaff_CPA cpa WITH (NOLOCK)
LEFT JOIN dbo.tblaff_CPA_Commissions comm WITH (NOLOCK) ON cpa.DepositID = comm.DepositID
WHERE cpa.Valid = 1 AND CAST(cpa.Optional2 AS INT) = 1
    AND cpa.ORDER_DATE >= '2026-03-01' AND cpa.ORDER_DATE < '2026-04-01'
GROUP BY comm.AffiliateID
ORDER BY FTDE DESC
```

### 8.3 Execute in debug mode

```sql
DECLARE @sql VARCHAR(MAX) = ' LEFT JOIN '
EXEC AffWizReports.GetFTDEAggregatedData
    @fromDate = '2026-03-01', @toDate = '2026-03-31',
    @BannerId = NULL, @Tier = 0, @ShowDate = 0, @ShowMonth = 1,
    @ShowProviderID = 0, @ShowDownloadID = 0, @ShowRelevantRevenues = 0,
    @ShowSerialID = 0, @ShowCountryName = 0, @ShowBanner = 0,
    @ShowFTDEAmount = 1, @ShowPlayerLevel = 0, @ShowCustomerID = 0,
    @ShowMarketingRegion = 0, @ShowLtv = 1,
    @ShowLabelID = 0, @ShowFunnelID = 0,
    @Debug = 1, @strSQL = @sql OUTPUT
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffWizReports.GetFTDEAggregatedData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetFTDEAggregatedData.sql*
