# AffWizReports.GetCopyTraderAggregatedData

> Aggregates CopyTrader commission and FTCT (First Time Copy Trader) metrics by affiliate for the AffWiz report, inserting into a temp table and building join clauses.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended JOIN clause for CopyTrader data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetCopyTraderAggregatedData aggregates CopyTrader event data for the Affiliate Wizard report. CopyTrader is a social trading feature where customers copy the trades of other traders. When a referred customer first uses CopyTrader, the affiliate earns a commission.

This procedure exists to compute per-affiliate CopyTrader commissions and FTCT (First Time Copy Trader) counts within a date range. These metrics feed into the broader AffWiz report alongside registrations, leads, sales, FTD, and other affiliate performance indicators.

The procedure executes in two stages: (1) it builds and executes a dynamic SQL query that aggregates CopyTrader data into the `#CopyTradersAggregatedData` temp table, then (2) it appends JOIN conditions to the @strSQL OUTPUT parameter so the orchestrator can LEFT JOIN this temp table into the final report query.

---

## 2. Business Logic

### 2.1 CopyTrader Aggregation

**What**: Counts CopyTrader events and sums commissions per affiliate, optionally grouped by dimensional attributes.

**Columns/Parameters Involved**: `@fromDate`, `@toDate`, `@Tier`, `@PaymentStatus`, all @Show* flags

**Rules**:
- Joins `tblaff_CopyTraders` with `tblaff_CopyTraders_Commissions` on CopyTraderID
- FTCT is a COUNT of CopyTraderID - representing distinct first-time copy events
- Commissions are SUMmed from `tblaff_CopyTraders_Commissions.Commission`
- Tier filtering isolates multi-tier affiliate structures (0 = all tiers, >0 = specific tier)
- PaymentStatus filters by paid/unpaid status when specified
- Date range filters on ORDER_DATE using >= start and < end+1 day pattern

### 2.2 Relevant Revenues Filter

**What**: Optional filter to include only CopyTrader events for customers who had a lead/registration in the same period.

**Columns/Parameters Involved**: `@ShowRelevantRevenues`

**Rules**:
- When enabled, adds an IN clause against `fiktivo.qry_aff_LeadRegistrationDate` to restrict to customers with matching lead dates
- Uses Optional3 column as the customer identifier (CID)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fromDate | datetime | NO | - | CODE-BACKED | Start of the reporting date range (inclusive). Filters tblaff_CopyTraders.ORDER_DATE >= @fromDate. |
| 2 | @toDate | datetime | NO | - | CODE-BACKED | End of the reporting date range (inclusive). Filters ORDER_DATE < @toDate + 1 day. |
| 3 | @BannerId | int | NO | - | CODE-BACKED | Marketing banner filter. When not NULL and @ShowBanner=1, restricts to CopyTrader events linked to this banner. |
| 4 | @Tier | int | NO | - | CODE-BACKED | Affiliate tier filter. 0 = all tiers, >0 = specific tier from tblaff_CopyTraders_Commissions.Tier. Used in multi-level affiliate structures. |
| 5 | @ShowDate | bit | NO | - | CODE-BACKED | When 1, groups results by ORDER_DATE (daily granularity) and includes Date in output. |
| 6 | @ShowMonth | bit | NO | - | CODE-BACKED | When 1, groups results by YEAR and MONTH of ORDER_DATE. |
| 7 | @ShowProviderID | bit | NO | - | CODE-BACKED | When 1, groups by ProviderID - the trading platform provider. |
| 8 | @ShowDownloadID | bit | NO | - | CODE-BACKED | When 1, groups by DownloadID - the app download event identifier. |
| 9 | @ShowRelevantRevenues | bit | NO | - | CODE-BACKED | When 1, restricts to CopyTrader events for customers who had a lead/registration in the date range (via fiktivo.qry_aff_LeadRegistrationDate). |
| 10 | @ShowSerialID | bit | NO | - | CODE-BACKED | When 1, groups by SubAffiliateID (sub-affiliate tracking code) with Latin1_General_Bin collation. |
| 11 | @ShowCountryName | bit | NO | - | CODE-BACKED | When 1, groups by CountryID from tblaff_CopyTraders for customer country segmentation. |
| 12 | @ShowBanner | bit | NO | - | CODE-BACKED | When 1, groups by BannerID and enables @BannerId filter. |
| 13 | @ShowPlayerLevel | bit | NO | - | CODE-BACKED | When 1, groups by PlayerLevelID - customer loyalty tier. |
| 14 | @ShowCustomerID | bit | NO | - | CODE-BACKED | When 1, groups by Optional3 (customer CID) for per-customer detail. |
| 15 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | When 1, groups by CountryID (used for marketing region resolution in the orchestrator). |
| 16 | @Debug | bit | YES | 0 | CODE-BACKED | When 1, prints the generated SQL and copies temp table data to a global ##CopyTradersAggregatedData for inspection. |
| 17 | @ShowFunnelID | bit | NO | - | CODE-BACKED | When 1, groups by FunnelID - conversion funnel identifier. |
| 18 | @ShowLabelID | bit | NO | - | CODE-BACKED | When 1, groups by LabelID - marketing label for campaign segmentation. |
| 19 | @PaymentStatus | bit | YES | - | CODE-BACKED | When not NULL, filters by tblaff_CopyTraders_Commissions.Paid = @PaymentStatus. 1 = paid commissions only, 0 = unpaid only. |
| 20 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT parameter. Appends the LEFT JOIN clause for #CopyTradersAggregatedData onto the orchestrator's query, matching on AffiliateID and all enabled dimensional columns. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.tblaff_CopyTraders | Table read | Source of CopyTrader event data (ORDER_DATE, CountryID, ProviderID, Optional3, BannerID, etc.) |
| JOIN | dbo.tblaff_CopyTraders_Commissions | Table read | Commission amounts and AffiliateID per CopyTrader event, joined on CopyTraderID |
| WHERE subquery | fiktivo.qry_aff_LeadRegistrationDate | View read | Used for @ShowRelevantRevenues filter - restricts to customers with leads in the date range |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Called to populate #CopyTradersAggregatedData and build the CopyTrader JOIN clause |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetCopyTraderAggregatedData (procedure)
+-- dbo.tblaff_CopyTraders (table)
+-- dbo.tblaff_CopyTraders_Commissions (table)
+-- fiktivo.qry_aff_LeadRegistrationDate (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_CopyTraders | Table | Source table for CopyTrader events, filtered by date and grouped for aggregation |
| dbo.tblaff_CopyTraders_Commissions | Table | Commission data joined on CopyTraderID for commission sums and affiliate attribution |
| fiktivo.qry_aff_LeadRegistrationDate | View | Used in relevant revenues subquery filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls this SP for CopyTrader report metrics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get CopyTrader aggregated data for last month

```sql
DECLARE @sql VARCHAR(MAX) = ' LEFT JOIN '
EXEC AffWizReports.GetCopyTraderAggregatedData
    @fromDate = '2026-03-01', @toDate = '2026-03-31',
    @BannerId = NULL, @Tier = 0,
    @ShowDate = 1, @ShowMonth = 0,
    @ShowProviderID = 0, @ShowDownloadID = 0,
    @ShowRelevantRevenues = 0, @ShowSerialID = 0,
    @ShowCountryName = 1, @ShowBanner = 0,
    @ShowPlayerLevel = 0, @ShowCustomerID = 0,
    @ShowMarketingRegion = 0, @ShowFunnelID = 0,
    @ShowLabelID = 0, @PaymentStatus = NULL,
    @Debug = 1, @strSQL = @sql OUTPUT

SELECT * FROM ##CopyTradersAggregatedData
```

### 8.2 Filter to paid commissions only

```sql
DECLARE @sql VARCHAR(MAX) = ' LEFT JOIN '
EXEC AffWizReports.GetCopyTraderAggregatedData
    @fromDate = '2026-01-01', @toDate = '2026-03-31',
    @BannerId = NULL, @Tier = 0,
    @ShowDate = 0, @ShowMonth = 1,
    @ShowProviderID = 0, @ShowDownloadID = 0,
    @ShowRelevantRevenues = 0, @ShowSerialID = 0,
    @ShowCountryName = 0, @ShowBanner = 0,
    @ShowPlayerLevel = 0, @ShowCustomerID = 0,
    @ShowMarketingRegion = 0, @ShowFunnelID = 0,
    @ShowLabelID = 0, @PaymentStatus = 1,
    @Debug = 1, @strSQL = @sql OUTPUT
```

### 8.3 View the raw CopyTrader data with joins resolved

```sql
SELECT
    cc.AffiliateID,
    ct.ORDER_DATE,
    ct.Optional3 AS CustomerID,
    cc.Commission,
    cc.Tier,
    cc.Paid
FROM dbo.tblaff_CopyTraders ct WITH (NOLOCK)
LEFT JOIN dbo.tblaff_CopyTraders_Commissions cc WITH (NOLOCK)
    ON ct.CopyTraderID = cc.CopyTraderID
WHERE ct.ORDER_DATE >= '2026-03-01'
    AND ct.ORDER_DATE < '2026-04-01'
ORDER BY ct.ORDER_DATE DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffWizReports.GetCopyTraderAggregatedData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetCopyTraderAggregatedData.sql*
