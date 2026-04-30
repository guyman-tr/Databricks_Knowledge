# AffWizReports.QueryHeader

> Builds the dynamic SQL outer SELECT with GROUP BY aggregations (SUM, COUNT, ROUND) for the AffWiz report, transforming the FieldSelection inner results into grouped report output.

| Property | Value |
|----------|-------|
| **Schema** | AffWizReports |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @strSQL OUTPUT - appended GROUP BY SELECT clause |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

QueryHeader is the counterpart to FieldSelection in the AffWiz report assembly. While FieldSelection builds the inner SELECT with raw column references from allDataUnion and temp tables, QueryHeader builds the outer SELECT with GROUP BY aggregations - SUMming metrics, COUNTing events, and ROUNDing financial values.

This procedure exists because the AffWiz report requires a two-level query: an inner query that UNIONs all event types and LEFT JOINs aggregated data, and an outer query that groups by the selected dimensions and sums the metrics. QueryHeader builds this outer aggregation layer.

The procedure takes the same @Show* parameters as FieldSelection to ensure consistency - the outer SELECT must include GROUP BY for every dimension included in the inner SELECT, and SUM/COUNT for every metric column.

---

## 2. Business Logic

### 2.1 Outer Aggregation Layer

**What**: Builds the GROUP BY SELECT clause that wraps the inner query results.

**Columns/Parameters Involved**: All @Show* parameters, `@strSQL`

**Rules**:
- Dimensional columns (Date, Month, AffiliateID, Contact, etc.) appear directly in SELECT and GROUP BY
- Metric columns use SUM(): Registrations, Leads, Active Traders (Sales), FTD, FTDE, FP, FTCT
- Financial columns use CAST(ROUND(SUM(...),4) AS DECIMAL(18,4)) for precision
- Total Commissions dynamically sums only the enabled commission types
- The trailing comma/plus removal uses `LEFT(@strSQL, LEN(@strSQL)-2)` for Total Commissions

### 2.2 Dynamic Total Commissions

**What**: Builds a composite SUM expression for Total Commissions based on which commission types are visible.

**Columns/Parameters Involved**: `@ShowTotalCommissions`, `@ShowRegistrationCommissions`, `@ShowLeadCommissions`, `@ShowSaleCommissions`, `@ShowCPACommissions`, `@ShowFirstPositionCommissions`, `@ShowCopyTraderCommissions`, `@ShoweCost`

**Rules**:
- Only commission types with @Show* = 1 are included in the Total
- Each commission type is added as `SUM({type}_Commissions) +`
- The last `+` is stripped before closing the CAST/ROUND wrapper
- This ensures Total Commissions matches the visible commission columns exactly

### 2.3 Financial Precision

**What**: All monetary values are rounded and cast to DECIMAL(18,4).

**Rules**:
- CAST(ROUND(SUM(...), 4) AS DECIMAL(18,4)) for all commission and amount columns
- CAST(ROUND(SUM(...), 2) AS DECIMAL(18,4)) for Bonuses and Chargebacks (2 decimal places)
- LTV uses CAST(ROUND(SUM(LTV), 4) AS DECIMAL(18,4))

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | int | YES | NULL | CODE-BACKED | Not used in body. Interface compatibility. |
| 2 | @BannerId | int | YES | NULL | CODE-BACKED | Not used in body. Interface compatibility. |
| 3 | @ShowDate | bit | YES | 1 | CODE-BACKED | When 1, includes Date in SELECT and GROUP BY. |
| 4 | @ShowYear | bit | YES | 1 | CODE-BACKED | Not directly used (Month controls both Year and Month). |
| 5 | @ShowMonth | bit | YES | 1 | CODE-BACKED | When 1, includes Month and Year in SELECT and GROUP BY. |
| 6 | @ShowSerialID | bit | YES | 1 | CODE-BACKED | When 1, includes SerialID in SELECT and GROUP BY. |
| 7 | @ShowCountryName | bit | YES | 1 | CODE-BACKED | When 1, includes CountryName in SELECT and GROUP BY. |
| 8 | @ShowMarketingRegion | bit | YES | 1 | CODE-BACKED | When 1, includes MarketingRegionName in SELECT and GROUP BY. |
| 9 | @ShowBanner | bit | YES | 1 | CODE-BACKED | When 1, includes Banner in SELECT and GROUP BY. |
| 10 | @ShowAffiliateID | bit | YES | 1 | CODE-BACKED | When 1, includes AffiliateID and Contact. Always includes in GROUP BY. |
| 11 | @ShowAffiliateGroups | bit | YES | 1 | CODE-BACKED | When 1, includes AffiliatesGroupsName in GROUP BY. |
| 12 | @ShowAffiliateCountry | bit | YES | 1 | CODE-BACKED | Not directly used in this SP. |
| 13 | @ShowProviderID | bit | YES | 1 | CODE-BACKED | When 1, includes ProviderID in SELECT and GROUP BY. |
| 14 | @ShowDownloadID | bit | YES | 1 | CODE-BACKED | When 1, includes DownloadID in SELECT and GROUP BY. |
| 15 | @ShowPlayerLevel | bit | YES | 1 | CODE-BACKED | When 1, includes PlayerLevel in SELECT and GROUP BY. |
| 16 | @ShowLabelID | bit | YES | 1 | CODE-BACKED | When 1, includes LabelID in SELECT and GROUP BY. |
| 17 | @ShowFunnelID | bit | YES | 1 | CODE-BACKED | When 1, includes FunnelID in SELECT and GROUP BY. |
| 18 | @ShowCustomerID | bit | YES | 1 | CODE-BACKED | When 1, includes CustomerID in SELECT and GROUP BY. |
| 19 | @ShowImpressions | bit | YES | 1 | CODE-BACKED | Deprecated. Clicks/Impressions removed July 2022. |
| 20 | @ShowClicks | bit | YES | 1 | CODE-BACKED | Deprecated. Clicks removed July 2022. |
| 21 | @ShowRegistrations | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(Registrations) AS Registrations. |
| 22 | @ShowLeads | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(Leads) AS Leads. |
| 23 | @ShowSales | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(Sales) AS [Active Traders]. |
| 24 | @ShowFTD | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(FTD) and SUM(FTDE). |
| 25 | @ShowFTDAmount | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(FTDAmount) and SUM(FTDEAmount) rounded to 4 decimals. |
| 26 | @ShowDepositAmount | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(DepositAmount) rounded to 4 decimals. |
| 27 | @ShowFirstPosition | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(FP). |
| 28 | @ShowRevenues | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(Revenues) AS [Gross Revenues]. |
| 29 | @ShowBonus | bit | YES | 1 | CODE-BACKED | When 1 AND @ShowRevenues=1, includes SUM(Bonus) rounded to 2 decimals. |
| 30 | @ShowChargeback | bit | YES | 1 | CODE-BACKED | When 1 AND @ShowRevenues=1, includes SUM(Chargeback) AS [Refunds & Chargebacks]. |
| 31 | @ShowNet | bit | YES | 1 | CODE-BACKED | When 1 AND @ShowRevenues=1, includes SUM(Net_Revenue) AS [Net Revenues]. |
| 32 | @ShowClickCommissions | bit | YES | 1 | CODE-BACKED | Deprecated. Clicks removed July 2022. |
| 33 | @ShowRegistrationCommissions | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(Registrations_Commissions). |
| 34 | @ShowLeadCommissions | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(Leads_Commissions). |
| 35 | @ShowSaleCommissions | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(Revenues_Commissions). |
| 36 | @ShowCPACommissions | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(CPA_Commissions). |
| 37 | @ShowFirstPositionCommissions | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(FirstPosition_Commissions). |
| 38 | @ShowTotalCommissions | bit | YES | 1 | CODE-BACKED | When 1, dynamically builds a SUM of all enabled commission types as [Total Commissions]. |
| 39 | @ShowPNLCommissions | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(PNL_Commissions) AS [P&L]. |
| 40 | @ShowHedgeCommissions | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(Hedge_Commissions). |
| 41 | @ShoweCost | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(eCost). Also contributes to Total Commissions. |
| 42 | @ShowRelevantRevenues | bit | YES | 1 | CODE-BACKED | Not used in this SP. Interface compatibility. |
| 43 | @ShowManagerName | bit | YES | 1 | CODE-BACKED | When 1, includes [Manager Name] in SELECT and GROUP BY. |
| 44 | @ShowUsedBonus | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(USED_BONUS_GRAND_TOTAL) AS [Used Bonus]. |
| 45 | @ShowChannelID | bit | YES | 1 | CODE-BACKED | When 1, includes Channel in SELECT and GROUP BY. |
| 46 | @ShowCopyTraderCommissions | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(CopyTrader_Commissions). Contributes to Total. |
| 47 | @ShowCopyTrader | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(FTCT) AS [FTCT]. |
| 48 | @ShowLtv | bit | YES | 1 | CODE-BACKED | When 1, includes SUM(LTV) rounded to 4 decimals. |
| 49 | @strSQL | varchar(max) | NO | - | CODE-BACKED | OUTPUT. Appends the outer aggregated SELECT clause to the orchestrator's query. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This procedure has no direct table references - it builds SQL string fragments referencing column aliases from the inner query built by FieldSelection and the data-gathering SPs.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External orchestrator | EXEC call | Caller | Called to build the outer aggregation SELECT clause |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffWizReports.QueryHeader (procedure)
    (no code-level dependencies - builds dynamic SQL strings only)
```

### 6.1 Objects This Depends On

No dependencies. This procedure builds SQL string fragments referencing aliases.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External orchestrator (not in SSDT) | Procedure/Application | Calls to build outer aggregation layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Build outer aggregation clause

```sql
DECLARE @sql VARCHAR(MAX) = ''
EXEC AffWizReports.QueryHeader
    @ShowDate = 1, @ShowMonth = 0, @ShowAffiliateID = 1,
    @ShowRegistrations = 1, @ShowLeads = 1, @ShowSales = 1,
    @ShowFTD = 1, @ShowRevenues = 1, @ShowTotalCommissions = 1,
    @strSQL = @sql OUTPUT
PRINT @sql
```

### 8.2 Build with full commission breakdown

```sql
DECLARE @sql VARCHAR(MAX) = ''
EXEC AffWizReports.QueryHeader
    @ShowDate = 0, @ShowMonth = 1, @ShowAffiliateID = 1,
    @ShowRegistrationCommissions = 1, @ShowLeadCommissions = 1,
    @ShowSaleCommissions = 1, @ShowCPACommissions = 1,
    @ShowFirstPositionCommissions = 1, @ShowCopyTraderCommissions = 1,
    @ShowTotalCommissions = 1, @ShoweCost = 1,
    @ShowPNLCommissions = 1, @ShowHedgeCommissions = 1,
    @strSQL = @sql OUTPUT
PRINT @sql
```

### 8.3 Verify Total Commissions dynamic composition

```sql
-- Total should only sum enabled commission types
DECLARE @sql VARCHAR(MAX) = ''
EXEC AffWizReports.QueryHeader
    @ShowRegistrationCommissions = 1, @ShowLeadCommissions = 0,
    @ShowSaleCommissions = 1, @ShowCPACommissions = 0,
    @ShowFirstPositionCommissions = 0, @ShowCopyTraderCommissions = 0,
    @ShowTotalCommissions = 1, @ShoweCost = 0,
    @strSQL = @sql OUTPUT
-- Expected: Total = SUM(Registrations_Commissions) + SUM(Revenues_Commissions)
PRINT @sql
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 49 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffWizReports.QueryHeader | Type: Stored Procedure | Source: fiktivo/AffWizReports/Stored Procedures/AffWizReports.QueryHeader.sql*
