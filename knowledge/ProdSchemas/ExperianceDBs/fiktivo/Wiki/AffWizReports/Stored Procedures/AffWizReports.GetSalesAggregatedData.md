# AffWizReports.GetSalesAggregatedData

> Aggregates sales (active trader) metrics including revenue, commissions, PnL, hedge, used bonus, and FTD counts by affiliate for the AffWiz report. The most complex aggregation SP in the schema.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended JOIN clause for sales data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetSalesAggregatedData is the most complex aggregation SP in the AffWizReports schema. It computes sales (active trader) metrics including revenue, commissions, PnL (Profit & Loss), hedge commissions, used bonus amounts, and FTD counts per affiliate.

"Sales" in the affiliate context means active traders - customers who have made at least one trade. Revenue commissions are the primary compensation for affiliates under revenue-share models. This SP uses a nested subquery pattern: inner query groups by AffiliateID + Optional3 (CustomerID) to compute per-customer metrics, then outer query aggregates across customers.

Results are inserted into `#SalesAggregatedData`. The two-level aggregation prevents double-counting when customers have multiple sales records.

---

## 2. Business Logic

### 2.1 Two-Level Sales Aggregation

**What**: Computes per-customer metrics first, then aggregates across customers per affiliate.

**Columns/Parameters Involved**: `@ShowPNLCommissions`, `@ShowHedgeCommissions`, `@ShowSaleCommissions`, `@ShowUsedBonus`

**Rules**:
- Inner subquery: GROUP BY AffiliateID, Optional3 (customer) to get per-customer totals
- Inner metrics: FTDs (SUM of Optional2), Revenues (GRAND_TOTAL - HedgeCommission), SCommissions, NetProfit, HedgeCommission, UsedBonusCommission, USED_BONUS_GRAND_TOTAL
- Outer query: GROUP BY AffiliateID + dimensions, COUNT(Optional3) AS Sales (count of active traders)
- Sales count is COUNT, not SUM - each customer counted once
- Revenue = GRAND_TOTAL minus HedgeCommission

### 2.2 Commission Components

**What**: Multiple commission types tracked separately.

**Rules**:
- SCommissions: direct sale commissions from tblaff_Sales_Commissions
- NetProfit: PnL-based commissions from tblaff_Sales.NetProfit
- HedgeCommission: hedge/market-making commissions from tblaff_Sales.HedgeCommission
- UsedBonusCommission: commission on used bonus amounts from tblaff_Sales_Commissions
- USED_BONUS_GRAND_TOTAL: total used bonus amounts from tblaff_Sales

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
| 13 | @ShowPNLCommissions | bit | NO | - | CODE-BACKED | When 1, includes SUM(NetProfit) AS NetProfit in output. |
| 14 | @ShowHedgeCommissions | bit | NO | - | CODE-BACKED | When 1, includes SUM(HedgeCommission) in output. |
| 15 | @ShowSaleCommissions | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(UsedBonusCommission) in output. |
| 16 | @ShowUsedBonus | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(USED_BONUS_GRAND_TOTAL) in output. |
| 17 | @ShowPlayerLevel | bit | NO | - | CODE-BACKED | When 1, groups by PlayerLevelID. |
| 18 | @ShowCustomerID | bit | NO | - | CODE-BACKED | When 1, groups by Optional3 (CustomerID). |
| 19 | @ShowMarketingRegion | bit | NO | - | CODE-BACKED | When 1, groups by CountryID. |
| 20 | @ShowLabelID | bit | NO | - | CODE-BACKED | When 1, groups by LabelID. |
| 21 | @ShowFunnelID | bit | NO | - | CODE-BACKED | When 1, groups by FunnelID. |
| 22 | @PaymentStatus | bit | YES | - | CODE-BACKED | When not NULL, filters by Paid status. |
| 23 | @Debug | bit | YES | 0 | CODE-BACKED | Debug mode flag. |
| 24 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends LEFT JOIN for #SalesAggregatedData. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.tblaff_Sales | Table read | Sales event data with revenue, PnL, hedge, and used bonus amounts |
| JOIN | dbo.tblaff_Sales_Commissions | Table read | Commission amounts, UsedBonusCommission, and affiliate attribution |
| WHERE subquery | fiktivo.qry_aff_LeadRegistrationDate | View read | Relevant revenues filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Populates #SalesAggregatedData |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.GetSalesAggregatedData (procedure)
+-- dbo.tblaff_Sales (table)
+-- dbo.tblaff_Sales_Commissions (table)
+-- fiktivo.qry_aff_LeadRegistrationDate (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Sales | Table | Sales events with financial data |
| dbo.tblaff_Sales_Commissions | Table | Commission data |
| fiktivo.qry_aff_LeadRegistrationDate | View | Relevant revenues filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls for sales/revenue metrics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View sales with commission breakdown

```sql
SELECT TOP 50 s.ORDER_DATE, sc.AffiliateID, s.GRAND_TOTAL, s.NetProfit, s.HedgeCommission,
    sc.Commission, sc.UsedBonusCommission, s.USED_BONUS_GRAND_TOTAL, s.Optional3 AS CustomerID
FROM dbo.tblaff_Sales s WITH (NOLOCK) LEFT JOIN dbo.tblaff_Sales_Commissions sc WITH (NOLOCK) ON s.SalesID = sc.SalesID
WHERE s.ORDER_DATE >= '2026-03-01' ORDER BY s.ORDER_DATE DESC
```

### 8.2 Two-level aggregation pattern

```sql
SELECT AffiliateID, COUNT(CustomerID) AS ActiveTraders, SUM(Revenues) AS TotalRevenues, SUM(SCommissions) AS TotalCommissions
FROM (
    SELECT sc.AffiliateID, s.Optional3 AS CustomerID, SUM(s.GRAND_TOTAL - ISNULL(s.HedgeCommission,0)) AS Revenues, SUM(sc.Commission) AS SCommissions
    FROM dbo.tblaff_Sales s WITH (NOLOCK) LEFT JOIN dbo.tblaff_Sales_Commissions sc WITH (NOLOCK) ON s.SalesID = sc.SalesID
    WHERE s.ORDER_DATE >= '2026-03-01' AND s.ORDER_DATE < '2026-04-01'
    GROUP BY sc.AffiliateID, s.Optional3
) temp GROUP BY AffiliateID ORDER BY TotalRevenues DESC
```

### 8.3 Execute in debug mode

```sql
DECLARE @sql VARCHAR(MAX) = ' LEFT JOIN '
EXEC AffWizReports.GetSalesAggregatedData
    @fromDate = '2026-03-01', @toDate = '2026-03-31', @BannerId = NULL, @Tier = 0,
    @ShowDate = 0, @ShowMonth = 1, @ShowProviderID = 0, @ShowDownloadID = 0, @ShowRelevantRevenues = 0,
    @ShowSerialID = 0, @ShowCountryName = 0, @ShowBanner = 0,
    @ShowPNLCommissions = 1, @ShowHedgeCommissions = 1, @ShowSaleCommissions = 1, @ShowUsedBonus = 1,
    @ShowPlayerLevel = 0, @ShowCustomerID = 0, @ShowMarketingRegion = 0,
    @ShowLabelID = 0, @ShowFunnelID = 0, @PaymentStatus = NULL,
    @Debug = 1, @strSQL = @sql OUTPUT
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffWizReports.GetSalesAggregatedData | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.GetSalesAggregatedData.sql*
