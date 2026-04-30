# AffWizReports.GetFTDAggregatedData

> Aggregates First Time Deposit (FTD) counts, amounts, and LTV by affiliate from the CPA table for the AffWiz report.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended JOIN clause for FTD data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetFTDAggregatedData computes First Time Deposit metrics per affiliate for the Affiliate Wizard report. FTD is a critical affiliate performance metric representing how many referred customers made their first deposit on the platform and the total amount deposited.

This procedure sources from `tblaff_CPA` filtered to first deposits only (`Optional2 = 1`). It computes FTD count, FTD amount (SUM of GRAND_TOTAL), and optionally LTV (Lifetime Value) from `tblaff_CustomersLTV`. Results are inserted into `#FTDAggregatedData`.

The key difference from GetDepositAggregatedData: this SP filters to first deposits only (Optional2=1), while deposits counts all deposit events.

---

## 2. Business Logic

### 2.1 FTD Aggregation with LTV

**What**: Counts first-time deposits and sums amounts, with optional LTV.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`, `@Tier`, `@ShowFTDAmount`, `@ShowLtv`

**Rules**:
- Filters to `CAST(tblaff_CPA.Optional2 AS INT) = 1` - only first deposits
- FTD count: SUM(CAST(Optional2 AS INT)) = count of first deposits
- FTD amount: SUM(GRAND_TOTAL) when @ShowFTDAmount=1
- LTV: SUM(tblaff_CustomersLTV.Ltv) when @ShowLtv=1, joined on AffiliateID and CustomerID
- LEFT JOIN to commissions (unlike GetFTDData which uses INNER JOIN subquery)

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
| 13 | @ShowFTDAmount | bit | NO | - | CODE-BACKED | When 1, includes SUM(GRAND_TOTAL) AS FTDAmount. |
| 14 | @ShowPlayerLevel | bit | NO | - | CODE-BACKED | When 1, groups by PlayerLevelID. |
| 15 | @ShowCustomerID | bit | NO | - | CODE-BACKED | When 1, groups by Optional3 (CustomerID). |
| 16 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | When 1, groups by CountryID. |
| 17 | @ShowLtv | bit | NO | - | CODE-BACKED | When 1, JOINs tblaff_CustomersLTV and includes SUM(Ltv) AS LTV. |
| 18 | @ShowLabelID | bit | NO | - | CODE-BACKED | When 1, groups by LabelID. |
| 19 | @ShowFunnelID | bit | NO | - | CODE-BACKED | When 1, groups by FunnelID. |
| 20 | @Debug | bit | YES | 0 | CODE-BACKED | Debug mode flag. |
| 21 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends LEFT JOIN for #FTDAggregatedData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.tblaff_CPA | Table read | CPA/deposit event data filtered to first deposits (Optional2=1) |
| JOIN | dbo.tblaff_CPA_Commissions | Table read | Commission attribution |
| JOIN | dbo.tblaff_CustomersLTV | Table read | Customer lifetime value (when @ShowLtv=1) |
| WHERE subquery | fiktivo.qry_aff_LeadRegistrationDate | View read | Relevant revenues filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Populates #FTDAggregatedData |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetFTDAggregatedData (procedure)
+-- dbo.tblaff_CPA (table)
+-- dbo.tblaff_CPA_Commissions (table)
+-- dbo.tblaff_CustomersLTV (table)
+-- fiktivo.qry_aff_LeadRegistrationDate (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_CPA | Table | CPA deposit events |
| dbo.tblaff_CPA_Commissions | Table | Commission attribution |
| dbo.tblaff_CustomersLTV | Table | LTV data (optional) |
| fiktivo.qry_aff_LeadRegistrationDate | View | Relevant revenues filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls for FTD metrics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View first-time deposits

```sql
SELECT TOP 50 cpa.ORDER_DATE, comm.AffiliateID, cpa.GRAND_TOTAL AS FTDAmount,
    cpa.Optional3 AS CustomerID, CAST(cpa.Optional2 AS INT) AS IsFTD
FROM dbo.tblaff_CPA cpa WITH (NOLOCK)
LEFT JOIN dbo.tblaff_CPA_Commissions comm WITH (NOLOCK) ON cpa.DepositID = comm.DepositID
WHERE CAST(cpa.Optional2 AS INT) = 1 AND cpa.ORDER_DATE >= '2026-03-01'
ORDER BY cpa.ORDER_DATE DESC
```

### 8.2 FTD count and amount by affiliate with LTV

```sql
SELECT comm.AffiliateID,
    COUNT(*) AS FTDCount,
    SUM(cpa.GRAND_TOTAL) AS TotalFTDAmount,
    SUM(ISNULL(ltv.Ltv, 0)) AS TotalLTV
FROM dbo.tblaff_CPA cpa WITH (NOLOCK)
LEFT JOIN dbo.tblaff_CPA_Commissions comm WITH (NOLOCK) ON cpa.DepositID = comm.DepositID
LEFT JOIN dbo.tblaff_CustomersLTV ltv WITH (NOLOCK) ON ltv.SerialID = comm.AffiliateID AND ltv.CustomerID = cpa.Optional3
WHERE CAST(cpa.Optional2 AS INT) = 1 AND cpa.ORDER_DATE >= '2026-03-01' AND cpa.ORDER_DATE < '2026-04-01'
GROUP BY comm.AffiliateID
ORDER BY TotalFTDAmount DESC
```

### 8.3 Execute in debug mode

```sql
DECLARE @sql VARCHAR(MAX) = ' LEFT JOIN '
EXEC AffWizReports.GetFTDAggregatedData
    @fromDate = '2026-03-01', @toDate = '2026-03-31',
    @BannerId = NULL, @Tier = 0, @ShowDate = 0, @ShowMonth = 1,
    @ShowProviderID = 0, @ShowDownloadID = 0, @ShowRelevantRevenues = 0,
    @ShowSerialID = 0, @ShowCountryName = 0, @ShowBanner = 0,
    @ShowFTDAmount = 1, @ShowPlayerLevel = 0, @ShowCustomerID = 0,
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
*Object: AffWizReports.GetFTDAggregatedData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetFTDAggregatedData.sql*
