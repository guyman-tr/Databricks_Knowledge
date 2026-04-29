# BI_DB_dbo.BI_DB_RevenueForum

> 71.8K-row monthly aggregation table powering the Revenue Forum dashboard. Aggregates customer metrics (funded, FTD, churn, AUA), revenue (total, ARPU), and deposit/withdraw activity by Country × Region × Club × Regulation dimensions. Built from DDR fact tables via SP_RevenueForum since April 2024. Refreshed daily with month-to-date figures.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DDR tables (Customer_Daily_Status, Fact_Revenue_Generating_Actions, Fact_MIMO_AllPlatforms, Fact_AUM) + Fivetran cost sheet via SP_RevenueForum |
| **Refresh** | Daily (SB_Daily, Priority 0) — DELETE+INSERT by FirstDayOfMonth (month-to-date) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table aggregates key business metrics for the **Revenue Forum** executive dashboard, providing a monthly view of platform performance broken down by geography (Country, Region), customer tier (Club), and regulatory entity (Regulation).

Each row represents one unique combination of `FirstDayOfMonth × Country × Region × Club × Regulation`. The table stores month-to-date figures that are recomputed daily — the DELETE+INSERT pattern replaces the entire current month's data on each run.

**Key metrics provided**:
- **Customer base**: Funded count, Club members, new FTDs this month, churn (funded→unfunded)
- **Revenue**: Total revenue (IncludedInTotalRevenue=1 actions), ARPU (revenue ÷ distinct CIDs)
- **Activity**: Active CFD traders, active customers (CountAsActiveTrade=1)
- **Money movement**: Deposits and withdrawals (amounts, counts, distinct CIDs)
- **Assets**: AUA (Assets Under Administration = sum of EquityGlobal)
- **Cost**: Marketing cost per region from Google Sheets (Fivetran sync)

**Population filters**: Only valid customers (IsValidCustomer=1, IsCreditReportValidCB=1), excludes Internal tier (PlayerLevelID≠4), excludes known fake FTDs from 2025-08-19 to 2025-08-21 with Amount=1.

**Sibling table**: `BI_DB_RevenueForum_Revenue` (same SP writes asset-type × settled × copy breakdowns).

**Unpopulated columns**: 14 asset-level amount columns (CopyAmount through UnknownInstrumentAmount) exist in the DDL but are 100% NULL — the SP code that would populate them is commented out.

---

## 2. Business Logic

### 2.1 Churn Calculation

**What**: Customer who was funded last month but unfunded this month.
**Columns Involved**: Churn
**Rules**:
- Compare IsFunded on last day of previous month vs run date
- If IsFunded went from 1→0, that CID counts as churned
- Aggregated as SUM(Churn) per dimension group

### 2.2 FTD Detection

**What**: First-Time Depositor count for the current month.
**Columns Involved**: FTD, FTDA
**Rules**:
- FTD: COUNT of CIDs whose Global_FTD_Date falls within the current month
- FTDA: SUM of Global_FTDA for those FTD customers
- Uses TP (trading platform) FTD dates from DDR_Customer_Daily_Status

### 2.3 Revenue and ARPU

**What**: Total platform revenue and average revenue per user.
**Columns Involved**: TotalRevenue, ARPU, CIDs_Distinct
**Rules**:
- TotalRevenue = SUM(Amount) from DDR_Fact_Revenue_Generating_Actions WHERE IncludedInTotalRevenue=1
- CIDs_Distinct = COUNT DISTINCT revenue-generating CIDs
- ARPU = TotalRevenue / CIDs_Distinct

### 2.4 Active Customer Definitions

**What**: Two distinct activity measures.
**Columns Involved**: ActiveOpenCFD, ActiveCustomers
**Rules**:
- ActiveOpenCFD: COUNT DISTINCT CIDs with ActionTypeID IN (1,2,3,39), IsCopy=0, IsSettled=0 (manual CFD trades)
- ActiveCustomers: COUNT DISTINCT CIDs with ActionTypeID IN (1,2,3,39), IsCopy=0, CountAsActiveTrade=1

### 2.5 Marketing Cost Allocation

**What**: Regional marketing spend from finance Google Sheet.
**Columns Involved**: Cost
**Rules**:
- Source: External_Fivetran_gsheet_costfinance (Google Sheet synced via Fivetran)
- Joined by Region and month
- MAX(Cost) per group (since cost is at region-month level, not country level)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no distribution optimization. Table is small (72K rows) and designed for dashboard consumption. Full scans are fast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly revenue trend by regulation | `GROUP BY FirstDayOfMonth, Regulation ORDER BY FirstDayOfMonth` |
| Regional ARPU comparison | `SELECT Region, SUM(TotalRevenue)/SUM(CIDs_Distinct) GROUP BY Region` |
| Churn rate by club tier | `SELECT Club, SUM(Churn)*1.0/SUM(Funded) GROUP BY Club` |
| FTD conversion by country | `SELECT Country, SUM(FTD), SUM(FTDA)/NULLIF(SUM(FTD),0) GROUP BY Country` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_RevenueForum_Revenue | FirstDayOfMonth + Country + Region + Club + Regulation | Add asset-type revenue breakdown |

### 3.4 Gotchas

- **14 NULL columns**: CopyAmount through UnknownInstrumentAmount are NEVER populated (commented-out SP code). Do not query them expecting data.
- **Month-to-date**: Data for the current month is partial until month-end; the SP runs daily and replaces the entire month.
- **Cost is MAX not SUM**: Cost is allocated at region-month level; MAX picks it up once per group (not additive across countries).
- **Fake FTD exclusion**: Hardcoded date range (2025-08-19 to 2025-08-21, Amount=1) excluded — a one-time data quality fix baked into the SP.
- **PlayerLevelID≠4**: Internal tier is always excluded; there is no "Internal" row in Club dimension here.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 1 | Verified from upstream wiki (production DB documentation) | Upstream wiki verbatim |
| Tier 2 | Derived from SP code analysis | SP source code |
| Tier 3 | Inferred from live data patterns | Ext_Dim_Country |
| Tier 4 | Low confidence — inferred or unverified | Best available |
| Tier 5 | ETL infrastructure / metadata | System convention |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FirstDayOfMonth | date | YES | First day of the aggregation month. Computed as DATEFROMPARTS(YEAR(Date), MONTH(Date), 1). Partition key for DELETE+INSERT. (Tier 2 — SP_RevenueForum) |
| 2 | Country | nvarchar(100) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 3 | Region | nvarchar(100) | YES | Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. Passthrough from Dim_Country. (Tier 3 — Ext_Dim_Country) |
| 4 | Club | nvarchar(100) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. Used in BackOffice reporting JOINs and customer-facing UI. Passthrough from Dim_PlayerLevel. (Tier 1 — Dictionary.PlayerLevel) |
| 5 | Regulation | nvarchar(100) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation. (Tier 1 — Dictionary.Regulation) |
| 6 | Funded | int | YES | Count of distinct CIDs with IsFunded=1 on the run date within this dimension group. (Tier 2 — SP_RevenueForum) |
| 7 | ClubMember | int | YES | Count of distinct CIDs with IsDepositor=1 (ever deposited) within this dimension group. (Tier 2 — SP_RevenueForum) |
| 8 | FTD | int | YES | Count of CIDs whose Global_FTD_Date falls within the current month (first-time depositors this month). (Tier 2 — SP_RevenueForum) |
| 9 | FTDA | decimal(18,2) | YES | Sum of Global_FTDA (first-time deposit amount in USD) for FTD customers in this month. NULL if no FTDs. (Tier 2 — SP_RevenueForum) |
| 10 | Churn | int | YES | Count of CIDs that were IsFunded=1 on last day of previous month but IsFunded=0 on run date (customer churn). (Tier 2 — SP_RevenueForum) |
| 11 | Cost | decimal(18,2) | YES | Marketing cost in USD for this region-month, from External_Fivetran_gsheet_costfinance (Google Sheet synced via Fivetran). MAX aggregation per group. (Tier 2 — SP_RevenueForum) |
| 12 | AUA | decimal(18,2) | YES | Assets Under Administration: SUM of EquityGlobal from DDR_Fact_AUM on run date for CIDs in this dimension group. (Tier 2 — SP_RevenueForum) |
| 13 | TotalRevenue | decimal(18,2) | YES | Total revenue: SUM(Amount) from DDR_Fact_Revenue_Generating_Actions WHERE IncludedInTotalRevenue=1 for the month-to-date period. (Tier 2 — SP_RevenueForum) |
| 14 | ARPU | decimal(18,2) | YES | Average Revenue Per User: TotalRevenue / COUNT(DISTINCT RealCID). NULL if no revenue-generating CIDs. (Tier 2 — SP_RevenueForum) |
| 15 | CIDs_Distinct | int | YES | Count of distinct CIDs that generated revenue (IncludedInTotalRevenue=1) in this month. (Tier 2 — SP_RevenueForum) |
| 16 | ActiveOpenCFD | int | YES | Count of distinct CIDs with manual (IsCopy=0) CFD (IsSettled=0) trades (ActionTypeID IN 1,2,3,39) this month. (Tier 2 — SP_RevenueForum) |
| 17 | ActiveCustomers | int | YES | Count of distinct CIDs with manual trades (IsCopy=0, ActionTypeID IN 1,2,3,39) where CountAsActiveTrade=1 this month. (Tier 2 — SP_RevenueForum) |
| 18 | DepositAmount | decimal(18,2) | YES | Total deposit amount in USD (non-internal transfers) for this dimension group in the month. From DDR_Fact_MIMO_AllPlatforms WHERE MIMOAction='Deposit'. (Tier 2 — SP_RevenueForum) |
| 19 | WithdrawAmount | decimal(18,2) | YES | Total withdrawal amount in USD (non-internal transfers) for this dimension group in the month. From DDR_Fact_MIMO_AllPlatforms WHERE MIMOAction='Withdraw'. (Tier 2 — SP_RevenueForum) |
| 20 | WithdrawCount | int | YES | Count of withdrawal transactions in this dimension group for the month. (Tier 2 — SP_RevenueForum) |
| 21 | WithdrawCIDs_Distinct | int | YES | Count of distinct CIDs that made at least one withdrawal in this month. (Tier 2 — SP_RevenueForum) |
| 22 | DepositCount | int | YES | Count of deposit transactions in this dimension group for the month. (Tier 2 — SP_RevenueForum) |
| 23 | DepositCIDs_Distinct | int | YES | Count of distinct CIDs that made at least one deposit in this month. (Tier 2 — SP_RevenueForum) |
| 24 | CopyAmount | decimal(18,2) | YES | NOT POPULATED. Planned: revenue from copy-trading positions. SP code commented out — column is 100% NULL. (Tier 4 — SP_RevenueForum, commented out) |
| 25 | ManualAmount | decimal(18,2) | YES | NOT POPULATED. Planned: revenue from manual (non-copy) positions. SP code commented out — column is 100% NULL. (Tier 4 — SP_RevenueForum, commented out) |
| 26 | RealAmount | decimal(18,2) | YES | NOT POPULATED. Planned: revenue from real/settled positions. SP code commented out — column is 100% NULL. (Tier 4 — SP_RevenueForum, commented out) |
| 27 | CFDAmount | decimal(18,2) | YES | NOT POPULATED. Planned: revenue from CFD positions. SP code commented out — column is 100% NULL. (Tier 4 — SP_RevenueForum, commented out) |
| 28 | ForexAmount | decimal(18,2) | YES | NOT POPULATED. Planned: revenue from Forex instruments. SP code commented out — column is 100% NULL. (Tier 4 — SP_RevenueForum, commented out) |
| 29 | CommodityAmount | decimal(18,2) | YES | NOT POPULATED. Planned: revenue from Commodity instruments. SP code commented out — column is 100% NULL. (Tier 4 — SP_RevenueForum, commented out) |
| 30 | IndicesAmount | decimal(18,2) | YES | NOT POPULATED. Planned: revenue from Indices instruments. SP code commented out — column is 100% NULL. (Tier 4 — SP_RevenueForum, commented out) |
| 31 | StocksAmount | decimal(18,2) | YES | NOT POPULATED. Planned: revenue from Stocks instruments. SP code commented out — column is 100% NULL. (Tier 4 — SP_RevenueForum, commented out) |
| 32 | ETFAmount | decimal(18,2) | YES | NOT POPULATED. Planned: revenue from ETF instruments. SP code commented out — column is 100% NULL. (Tier 4 — SP_RevenueForum, commented out) |
| 33 | BondsAmount | decimal(18,2) | YES | NOT POPULATED. Planned: revenue from Bonds instruments. SP code commented out — column is 100% NULL. (Tier 4 — SP_RevenueForum, commented out) |
| 34 | TrustFundsAmount | decimal(18,2) | YES | NOT POPULATED. Planned: revenue from Trust Funds instruments. SP code commented out — column is 100% NULL. (Tier 4 — SP_RevenueForum, commented out) |
| 35 | OptionsAmount | decimal(18,2) | YES | NOT POPULATED. Planned: revenue from Options instruments. SP code commented out — column is 100% NULL. (Tier 4 — SP_RevenueForum, commented out) |
| 36 | CryptoAmount | decimal(18,2) | YES | NOT POPULATED. Planned: revenue from Crypto instruments. SP code commented out — column is 100% NULL. (Tier 4 — SP_RevenueForum, commented out) |
| 37 | UnknownInstrumentAmount | decimal(18,2) | YES | NOT POPULATED. Planned: revenue from unclassified instruments. SP code commented out — column is 100% NULL. (Tier 4 — SP_RevenueForum, commented out) |
| 38 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by the pipeline (GETDATE()). (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-----------------|---------------|-----------|
| Country | DWH_dbo.Dim_Country | Name | Dim-lookup passthrough |
| Region | DWH_dbo.Dim_Country | MarketingRegionManualName | Dim-lookup passthrough |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Dim-lookup passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup passthrough |
| Funded–DepositCIDs_Distinct | DDR fact tables | Various | Aggregation (COUNT/SUM/AVG) |
| CopyAmount–UnknownInstrumentAmount | — | — | NOT POPULATED |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status (daily customer state)
  + BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions (revenue events)
  + BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms (deposits/withdrawals)
  + BI_DB_dbo.BI_DB_DDR_Fact_AUM (equity/AUA)
  + BI_DB_dbo.External_Fivetran_gsheet_costfinance (marketing cost)
  + DWH_dbo.Dim_Country / Dim_PlayerLevel / Dim_Regulation (dim lookups)
    |-- SP_RevenueForum @date (Daily, Priority 0)
    |-- Aggregates by Country × Region × Club × Regulation × Month
    v
BI_DB_dbo.BI_DB_RevenueForum (71.8K rows, ROUND_ROBIN HEAP)
    |-- Dashboard consumption (Revenue Forum)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Country | DWH_dbo.Dim_Country.Name | Country dimension lookup |
| Region | DWH_dbo.Dim_Country.MarketingRegionManualName | Marketing region |
| Club | DWH_dbo.Dim_PlayerLevel.Name | Club tier lookup |
| Regulation | DWH_dbo.Dim_Regulation.Name | Regulation entity lookup |

### 6.2 Referenced By (other objects point to this)

| Object | Context |
|--------|---------|
| BI_DB_dbo.BI_DB_RevenueForum_Revenue | Sibling table (same SP, asset-type breakdown) — JOIN on all 5 dimension columns |

---

## 7. Sample Queries

### 7.1 Monthly Revenue Trend by Regulation

```sql
SELECT
    FirstDayOfMonth,
    Regulation,
    SUM(TotalRevenue) AS Revenue,
    SUM(CIDs_Distinct) AS ActiveUsers,
    SUM(TotalRevenue) / NULLIF(SUM(CIDs_Distinct), 0) AS ARPU
FROM [BI_DB_dbo].[BI_DB_RevenueForum]
GROUP BY FirstDayOfMonth, Regulation
ORDER BY FirstDayOfMonth DESC, Revenue DESC
```

### 7.2 Churn Rate by Club Tier (Current Month)

```sql
SELECT
    Club,
    SUM(Funded) AS FundedCustomers,
    SUM(Churn) AS ChurnedCustomers,
    CAST(SUM(Churn) AS FLOAT) / NULLIF(SUM(Funded), 0) * 100 AS ChurnRatePct
FROM [BI_DB_dbo].[BI_DB_RevenueForum]
WHERE FirstDayOfMonth = (SELECT MAX(FirstDayOfMonth) FROM [BI_DB_dbo].[BI_DB_RevenueForum])
GROUP BY Club
ORDER BY ChurnRatePct DESC
```

### 7.3 Regional Cost Efficiency (Cost per FTD)

```sql
SELECT
    Region,
    SUM(Cost) AS TotalCost,
    SUM(FTD) AS TotalFTDs,
    SUM(Cost) / NULLIF(SUM(FTD), 0) AS CostPerFTD
FROM [BI_DB_dbo].[BI_DB_RevenueForum]
WHERE FirstDayOfMonth >= '2026-01-01'
GROUP BY Region
ORDER BY CostPerFTD
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. This table was created in September 2025 by Ofir Chloe Gal for the Revenue Forum dashboard.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 3 T1, 19 T2, 1 T3, 14 T4, 1 T5 | Elements: 38/38, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_RevenueForum | Type: Table | Production Source: DDR tables via SP_RevenueForum*
