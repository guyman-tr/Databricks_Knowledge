# AffWizReports.GetDepositAggregatedData

> Aggregates deposit amounts by affiliate from the CPA table for the AffWiz report, inserting into a temp table and building join clauses.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended JOIN clause for deposit data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetDepositAggregatedData computes total deposit amounts per affiliate for the Affiliate Wizard report. Deposits are sourced from the `tblaff_CPA` table, which records all CPA (Cost Per Acquisition) deposit events - both first-time deposits and subsequent deposits.

This procedure exists to calculate the aggregate deposit amounts that affiliates have driven within a reporting period. The deposit amount metric helps measure the monetary value of customers referred by each affiliate, beyond simple counts.

The procedure builds a dynamic SQL query that aggregates deposit data into `#DepositAggregatedData`, then appends JOIN conditions to @strSQL. It uses `SUM(CAST(tblaff_CPA.Optional2 as INT))` for FTD count and `SUM(tblaff_CPA.GRAND_TOTAL)` for deposit amounts. The deposit amount column is controlled by the @ShowDepositAmount flag.

---

## 2. Business Logic

### 2.1 Deposit Aggregation from CPA Table

**What**: Sums deposit amounts and counts from the CPA events table per affiliate.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`, `@Tier`, `@ShowDepositAmount`

**Rules**:
- Source is `tblaff_CPA` LEFT JOINed to `dbo.tblaff_CPA_Commissions` on DepositID
- FTD count uses `SUM(CAST(Optional2 AS INT))` - Optional2 stores 1 for first deposit, 0 otherwise
- Deposit amount uses `SUM(GRAND_TOTAL)` - the full deposit amount
- Unlike GetFTDAggregatedData, this SP does NOT filter to first deposits only (no `Optional2 = 1` filter)
- Tier filtering on commission records when @Tier > 0

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fromDate | datetime | NO | - | CODE-BACKED | Start of reporting period. Filters ORDER_DATE >= @fromDate. |
| 2 | @toDate | datetime | NO | - | CODE-BACKED | End of reporting period. Filters ORDER_DATE < @toDate + 1 day. |
| 3 | @BannerId | int | NO | - | CODE-BACKED | Banner filter when @ShowBanner=1 and value is not NULL. |
| 4 | @Tier | int | NO | - | CODE-BACKED | Commission tier filter. 0 = all, >0 = specific tier. |
| 5 | @ShowDate | bit | NO | - | CODE-BACKED | When 1, groups by ORDER_DATE (daily). |
| 6 | @ShowMonth | bit | NO | - | CODE-BACKED | When 1, groups by YEAR and MONTH. |
| 7 | @ShowProviderID | bit | NO | - | CODE-BACKED | When 1, groups by ProviderID. |
| 8 | @ShowDownloadID | bit | NO | - | CODE-BACKED | When 1, groups by DownloadID. |
| 9 | @ShowRelevantRevenues | bit | NO | - | CODE-BACKED | When 1, restricts to customers in qry_aff_LeadRegistrationDate. |
| 10 | @ShowDepositAmount | bit | NO | - | CODE-BACKED | When 1, includes SUM(GRAND_TOTAL) AS DepositAmount in output. This is the key flag unique to this SP. |
| 11 | @ShowSerialID | bit | NO | - | CODE-BACKED | When 1, groups by SubAffiliateID with binary collation. |
| 12 | @ShowCountryName | bit | NO | - | CODE-BACKED | When 1, groups by CountryID. |
| 13 | @ShowBanner | bit | NO | - | CODE-BACKED | When 1, groups by BannerID and enables banner filter. |
| 14 | @ShowPlayerLevel | bit | NO | - | CODE-BACKED | When 1, groups by PlayerLevelID. |
| 15 | @ShowCustomerID | bit | NO | - | CODE-BACKED | When 1, groups by Optional3 (CustomerID). |
| 16 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | When 1, groups by CountryID for region resolution. |
| 17 | @ShowLabelID | bit | NO | - | CODE-BACKED | When 1, groups by LabelID. |
| 18 | @ShowFunnelID | bit | NO | - | CODE-BACKED | When 1, groups by FunnelID. |
| 19 | @Debug | bit | YES | 0 | CODE-BACKED | When 1, prints SQL and copies results to ##DepositAggregatedData. |
| 20 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends LEFT JOIN clause for #DepositAggregatedData matching on AffiliateID and dimensional columns. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.tblaff_CPA | Table read | Source of deposit event data (all deposits, not just first-time) |
| JOIN | dbo.tblaff_CPA_Commissions | Table read | Commission attribution joined on DepositID |
| WHERE subquery | fiktivo.qry_aff_LeadRegistrationDate | View read | Relevant revenues filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Populates #DepositAggregatedData for deposit amount metrics |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetDepositAggregatedData (procedure)
+-- dbo.tblaff_CPA (table)
+-- dbo.tblaff_CPA_Commissions (table)
+-- fiktivo.qry_aff_LeadRegistrationDate (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_CPA | Table | Deposit events with amounts (GRAND_TOTAL) |
| dbo.tblaff_CPA_Commissions | Table | Affiliate attribution for deposits |
| fiktivo.qry_aff_LeadRegistrationDate | View | Relevant revenues filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls this SP for deposit amount metrics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View deposit data from CPA table

```sql
SELECT TOP 50
    cpa.ORDER_DATE,
    comm.AffiliateID,
    cpa.GRAND_TOTAL AS DepositAmount,
    CAST(cpa.Optional2 AS INT) AS IsFTD,
    cpa.Optional3 AS CustomerID
FROM dbo.tblaff_CPA cpa WITH (NOLOCK)
LEFT JOIN dbo.tblaff_CPA_Commissions comm WITH (NOLOCK)
    ON cpa.DepositID = comm.DepositID
WHERE cpa.ORDER_DATE >= '2026-03-01'
ORDER BY cpa.ORDER_DATE DESC
```

### 8.2 Aggregate deposits by affiliate

```sql
SELECT comm.AffiliateID,
    SUM(cpa.GRAND_TOTAL) AS TotalDeposits,
    COUNT(*) AS DepositCount
FROM dbo.tblaff_CPA cpa WITH (NOLOCK)
LEFT JOIN dbo.tblaff_CPA_Commissions comm WITH (NOLOCK)
    ON cpa.DepositID = comm.DepositID
WHERE cpa.ORDER_DATE >= '2026-03-01'
    AND cpa.ORDER_DATE < '2026-04-01'
GROUP BY comm.AffiliateID
ORDER BY TotalDeposits DESC
```

### 8.3 Execute in debug mode

```sql
DECLARE @sql VARCHAR(MAX) = ' LEFT JOIN '
EXEC AffWizReports.GetDepositAggregatedData
    @fromDate = '2026-03-01', @toDate = '2026-03-31',
    @BannerId = NULL, @Tier = 0,
    @ShowDate = 0, @ShowMonth = 1,
    @ShowProviderID = 0, @ShowDownloadID = 0,
    @ShowRelevantRevenues = 0, @ShowDepositAmount = 1,
    @ShowSerialID = 0, @ShowCountryName = 0, @ShowBanner = 0,
    @ShowPlayerLevel = 0, @ShowCustomerID = 0,
    @ShowMarketingRegion = 0, @ShowLabelID = 0, @ShowFunnelID = 0,
    @Debug = 1, @strSQL = @sql OUTPUT
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffWizReports.GetDepositAggregatedData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetDepositAggregatedData.sql*
