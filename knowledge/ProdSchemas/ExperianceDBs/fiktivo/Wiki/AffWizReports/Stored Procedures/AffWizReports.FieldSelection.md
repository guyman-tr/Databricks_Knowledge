# AffWizReports.FieldSelection

> Builds the dynamic SQL SELECT clause for the Affiliate Wizard report, conditionally including metric columns based on visibility flags.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended SELECT clause |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

FieldSelection is a dynamic SQL builder that constructs the SELECT column list for the Affiliate Wizard reporting system. It determines which metrics, commissions, and dimensional attributes appear in the final report output based on dozens of visibility flags passed by the caller.

This procedure exists because the AffWiz report supports a highly customizable column layout. Rather than returning all columns and filtering on the client, the system dynamically builds the SQL at the database layer, including only the columns the user selected. This avoids transferring unnecessary data and keeps the query plan efficient.

FieldSelection is one of two "header" procedures (along with QueryHeader) called by an orchestrating procedure that assembles a complete report query. FieldSelection builds the inner SELECT (from the aggregated temp table results), while QueryHeader builds the outer SELECT with GROUP BY and SUM aggregations. The orchestrator combines their output with data-gathering procedures (GetRegistrationsAggregatedData, GetSalesAggregatedData, etc.) to produce the full report.

---

## 2. Business Logic

### 2.1 Conditional Column Inclusion

**What**: Each @Show* bit flag controls whether a specific column or metric appears in the SELECT output.

**Columns/Parameters Involved**: All 48 @Show* parameters, `@strSQL`

**Rules**:
- When a @Show* flag = 1, the corresponding column is appended to the dynamic SQL SELECT string
- Columns reference aliases from the orchestrator's temp table JOINs (e.g., `REGISTRATION.Registrations`, `SALE.Revenues`, `FTD.FTD`)
- ISNULL wrappers ensure NULL values from LEFT JOINs appear as 0 in the report
- Some columns have compound visibility logic: @ShowRevenues AND @ShowBonus must both be 1 for Bonus to appear

### 2.2 Commission Aggregation Categories

**What**: The report separates commissions into distinct business categories that align with the affiliate compensation model.

**Columns/Parameters Involved**: `@ShowRegistrationCommissions`, `@ShowLeadCommissions`, `@ShowSaleCommissions`, `@ShowCPACommissions`, `@ShowFirstPositionCommissions`, `@ShowCopyTraderCommissions`, `@ShoweCost`, `@ShowTotalCommissions`

**Rules**:
- Revenue commissions combine sale commissions + bonus commissions + used bonus commissions + chargeback commissions
- Total Commissions is a dynamic sum of whichever commission types are visible (only sums the ones included)
- Net Revenue = Revenues + Used Bonus + Chargebacks (chargebacks are negative)
- PNL commissions and Hedge commissions are tracked separately from revenue commissions

**Diagram**:
```
Total Commissions = SUM of enabled:
  +-- Registration Commissions
  +-- Lead Commissions
  +-- Revenue Commissions (Sales + Bonus + UsedBonus + Chargeback)
  +-- CPA Commissions
  +-- FirstPosition Commissions
  +-- CopyTrader Commissions
  +-- eCost
```

### 2.3 Deprecated/Removed Features

**What**: Several report features have been removed over time, with their code commented out.

**Rules**:
- Clicks and Impressions were removed (comment: "20/7/2022 Noga, Remove Clicks from SP")
- Downloads, Installs, and FTR (First Time Run) sections are commented out
- RealProviderID was removed
- Category display was removed
- Customer Support commissions were removed

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | int | YES | NULL | CODE-BACKED | Affiliate identifier filter. Not used in the body of this procedure - passed through for interface compatibility with the orchestrator. |
| 2 | @BannerId | int | YES | NULL | CODE-BACKED | Marketing banner/creative identifier filter. Not used directly in this procedure. |
| 3 | @ShowDate | bit | YES | 1 | CODE-BACKED | When 1, includes `allDataUnion.Date AS Date` in SELECT - shows daily granularity. |
| 4 | @ShowYear | bit | YES | 1 | CODE-BACKED | Controls year display. Not directly used in body (Month flag handles both Year and Month). |
| 5 | @ShowMonth | bit | YES | 1 | CODE-BACKED | When 1, includes both `Month` and `Year` columns from allDataUnion. |
| 6 | @ShowSerialID | bit | YES | 1 | CODE-BACKED | When 1, includes SubAffiliateID/SerialID - the sub-affiliate tracking code used for campaign-level attribution. |
| 7 | @ShowCountryName | bit | YES | 1 | CODE-BACKED | When 1, includes `tblaff_Country.Name AS CountryName` - the customer's country. |
| 8 | @ShowMarketingRegion | bit | YES | 1 | CODE-BACKED | When 1, includes `Dictionary.MarketingRegion.Name AS MarketingRegionName` - geographic/linguistic market segment. See [Marketing Region](../../_glossary.md#marketing-region). |
| 9 | @ShowBanner | bit | YES | 1 | CODE-BACKED | When 1, includes `BannerName` - the name of the marketing banner/creative asset. |
| 10 | @ShowAffiliateID | bit | YES | 1 | CODE-BACKED | Always includes AffiliateID and Contact (affiliate name) regardless of this flag. Controls display intent for the UI. |
| 11 | @ShowAffiliateGroups | bit | YES | 1 | CODE-BACKED | Controls affiliate group name display. Always included via Affiliates.AffiliatesGroupsName. |
| 12 | @ShowAffiliateCountry | bit | YES | 1 | CODE-BACKED | When 1, includes `Affiliates.AffiliateCountryName` - the affiliate's own country (distinct from customer country). |
| 13 | @ShowProviderID | bit | YES | 1 | CODE-BACKED | When 1, includes `allDataUnion.ProviderID` - the trading platform provider identifier. |
| 14 | @ShowDownloadID | bit | YES | 1 | CODE-BACKED | When 1, includes `allDataUnion.DownloadID` - links to the app download event that led to the customer. |
| 15 | @ShowPlayerLevel | bit | YES | 1 | CODE-BACKED | When 1, includes `tblPlayerLevel.Name AS PlayerLevel` - customer loyalty tier (Bronze/Silver/Gold/VIP). See [Player Level](../../_glossary.md#player-level). |
| 16 | @ShowLabelID | bit | YES | 1 | CODE-BACKED | When 1, includes `allDataUnion.LabelID` - marketing label for campaign segmentation. |
| 17 | @ShowFunnelID | bit | YES | 1 | CODE-BACKED | When 1, includes `allDataUnion.FunnelID` - conversion funnel identifier for attribution tracking. |
| 18 | @ShowCustomerID | bit | YES | 1 | CODE-BACKED | When 1, includes `allDataUnion.CustomerID` - the end customer's CID. Enables per-customer drill-down. |
| 19 | @ShowImpressions | bit | YES | 1 | CODE-BACKED | Deprecated. Was for ad impression counts. Code is commented out (removed July 2022). |
| 20 | @ShowClicks | bit | YES | 1 | CODE-BACKED | Deprecated. Was for click tracking counts. Code is commented out (removed July 2022). |
| 21 | @ShowRegistrations | bit | YES | 1 | CODE-BACKED | When 1, includes `REGISTRATION.Registrations` - count of customer registrations attributed to the affiliate. |
| 22 | @ShowLeads | bit | YES | 1 | CODE-BACKED | When 1, includes `LEAD.Leads` - count of qualified leads (customers who completed KYC/verification). |
| 23 | @ShowSales | bit | YES | 1 | CODE-BACKED | When 1, includes `SALE.Sales` - count of active traders (customers who made at least one trade). |
| 24 | @ShowFTD | bit | YES | 1 | CODE-BACKED | When 1, includes `FTD.FTD` and `FTDE.FTDE` - First Time Deposit count and First Time Deposit Eligible count. |
| 25 | @ShowFTDAmount | bit | YES | 1 | CODE-BACKED | When 1, includes `FTD.FTDAmount` and `FTDE.FTDEAmount` - monetary amounts of first-time deposits. |
| 26 | @ShowDepositAmount | bit | YES | 1 | CODE-BACKED | When 1, includes `DEPOSIT.DepositAmount` - total deposit amount within the date range. |
| 27 | @ShowFirstPosition | bit | YES | 1 | CODE-BACKED | When 1, includes `FP.FirstPosition` - count of first trading positions opened by referred customers. |
| 28 | @ShowRevenues | bit | YES | 1 | CODE-BACKED | When 1, includes `SALE.Revenues` (Gross Revenues). Also gates Bonus, Chargeback, and Net Revenue columns. |
| 29 | @ShowBonus | bit | YES | 1 | CODE-BACKED | When 1 AND @ShowRevenues=1, includes `BONUS.Revenues AS Bonus` - bonus credits applied to customer accounts. |
| 30 | @ShowChargeback | bit | YES | 1 | CODE-BACKED | When 1 AND @ShowRevenues=1, includes `CHARGEBACK.Revenues AS Chargeback` - payment reversals/refunds (negative values). |
| 31 | @ShowNet | bit | YES | 1 | CODE-BACKED | When 1 AND @ShowRevenues=1, includes Net_Revenue = Revenues + Used_Bonus + Chargebacks. |
| 32 | @ShowClickCommissions | bit | YES | 1 | CODE-BACKED | Deprecated. Click commission tracking was removed July 2022. |
| 33 | @ShowRegistrationCommissions | bit | YES | 1 | CODE-BACKED | When 1, includes `REGISTRATION.Commissions` - commissions earned per customer registration. |
| 34 | @ShowLeadCommissions | bit | YES | 1 | CODE-BACKED | When 1, includes `LEAD.Commissions` - commissions earned per qualified lead. |
| 35 | @ShowSaleCommissions | bit | YES | 1 | CODE-BACKED | When 1, includes combined Revenue Commissions = Sale + Bonus + UsedBonus + Chargeback commissions. |
| 36 | @ShowCPACommissions | bit | YES | 1 | CODE-BACKED | When 1, includes `CPA.Commissions` - Cost Per Acquisition commissions paid on first deposits. |
| 37 | @ShowFirstPositionCommissions | bit | YES | 1 | CODE-BACKED | When 1, includes `FirstPosition.Commissions` - commissions earned when a referred customer opens their first trade. |
| 38 | @ShowTotalCommissions | bit | YES | 1 | CODE-BACKED | When 1, includes a computed sum of all enabled commission types as Total Commissions. |
| 39 | @ShowPNLCommissions | bit | YES | 1 | CODE-BACKED | When 1, includes `SALE.NetProfit` - profit & loss based commissions from customer trading activity. |
| 40 | @ShowHedgeCommissions | bit | YES | 1 | CODE-BACKED | When 1, includes `SALE.HedgeCommission` - commissions derived from hedge/market-making activity. |
| 41 | @ShoweCost | bit | YES | 1 | CODE-BACKED | When 1, includes `ECOST.Commissions` - electronic cost/marketing expense commissions. |
| 42 | @ShowRelevantRevenues | bit | YES | 1 | CODE-BACKED | Not used in this procedure. Passed through for interface compatibility. Filters revenues in data-gathering SPs. |
| 43 | @ShowManagerName | bit | YES | 1 | CODE-BACKED | When 1, includes `[Manager Name]` - the affiliate's account manager at the company. |
| 44 | @ShowUsedBonus | bit | YES | 1 | CODE-BACKED | When 1, includes `SALE.USED_BONUS_GRAND_TOTAL` - total bonus amount used/consumed by customers. |
| 45 | @ShowChannelID | bit | YES | 1 | CODE-BACKED | When 1, includes `MarketingExpenseName AS Channel` - the marketing expense channel name. |
| 46 | @ShowCopyTraderCommissions | bit | YES | 1 | CODE-BACKED | When 1, includes `CopyTraders.Commissions` - commissions from CopyTrader product referrals. |
| 47 | @ShowCopyTrader | bit | YES | 1 | CODE-BACKED | When 1, includes `CopyTraders.FTCT` - First Time Copy Trader count (customers who first used CopyTrader). |
| 48 | @ShowLtv | bit | YES | 1 | CODE-BACKED | When 1, includes LTV (Lifetime Value) calculation. Only shows non-zero LTV when FTD count > 0. |
| 49 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT parameter. The procedure APPENDS the SELECT clause to this string. The caller initializes it and passes it through multiple procedures to build the complete query. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Dynamic SQL | Dictionary.MarketingRegion | Lookup | MarketingRegion name is resolved via JOIN in the orchestrator's SQL |
| Dynamic SQL | dbo.tblPlayerLevel | Lookup | Player level name is resolved via JOIN in the orchestrator's SQL |
| Dynamic SQL | Affiliates (temp/CTE) | JOIN | Affiliate details (ID, Contact, Group, Country) come from orchestrator's Affiliates dataset |
| Dynamic SQL | allDataUnion (temp/CTE) | JOIN | Dimensional data (Date, Month, SerialID, CountryID, etc.) comes from the orchestrator's union of all data SPs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Called by application code or a non-SSDT procedure to build the SELECT clause of the AffWiz report |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.FieldSelection (procedure)
    (no code-level dependencies - builds dynamic SQL strings only)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.MarketingRegion | Table | Referenced in generated SQL for region name lookup |
| dbo.tblPlayerLevel | Table | Referenced in generated SQL for player level name lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls this SP to build the SELECT clause |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute FieldSelection with common report columns

```sql
DECLARE @sql VARCHAR(MAX) = ''
EXEC AffWizReports.FieldSelection
    @ShowDate = 1, @ShowMonth = 0, @ShowSerialID = 0,
    @ShowCountryName = 1, @ShowMarketingRegion = 0,
    @ShowBanner = 0, @ShowAffiliateID = 1,
    @ShowRegistrations = 1, @ShowLeads = 1, @ShowSales = 1,
    @ShowFTD = 1, @ShowFTDAmount = 1,
    @ShowRevenues = 1, @ShowTotalCommissions = 1,
    @strSQL = @sql OUTPUT
PRINT @sql
```

### 8.2 Execute with commission breakdown only

```sql
DECLARE @sql VARCHAR(MAX) = ''
EXEC AffWizReports.FieldSelection
    @ShowDate = 0, @ShowMonth = 1,
    @ShowRegistrationCommissions = 1, @ShowLeadCommissions = 1,
    @ShowSaleCommissions = 1, @ShowCPACommissions = 1,
    @ShowFirstPositionCommissions = 1, @ShowCopyTraderCommissions = 1,
    @ShowTotalCommissions = 1, @ShoweCost = 1,
    @strSQL = @sql OUTPUT
PRINT @sql
```

### 8.3 Inspect generated SQL structure

```sql
DECLARE @sql VARCHAR(MAX) = ' FROM allDataUnion '
EXEC AffWizReports.FieldSelection
    @ShowDate = 1, @ShowAffiliateID = 1, @ShowFTD = 1,
    @ShowRevenues = 1, @ShowNet = 1, @ShowLtv = 1,
    @strSQL = @sql OUTPUT
SELECT LEN(@sql) AS SqlLength, @sql AS GeneratedSQL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 49 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffWizReports.FieldSelection | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.FieldSelection.sql*
