# BI_DB_dbo.BI_DB_CorpDevDashboard

> Pre-aggregated Corporate Development dashboard table — 7,461 rows covering monthly KPIs (registrations, funded accounts, revenue by asset class, AUA, deposits, cashouts, PnL, and social engagement) segmented by macro-region and eToro Club tier. Sourced from 6-way UNION aggregation across MonthlyPanel, First5Actions, CIDFirstDates, PositionPnL, Social_Activity, and Guru_Copiers via SP_CorpDevDashboard. Date range 2012-10 to 2023-10; last refresh 2023-10-08 — appears dormant.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source ETL aggregation via SP_CorpDevDashboard (Author: Amir Gurewitz, 2021-05-24) |
| **Refresh** | Daily — DELETE WHERE Active_Month = @SdateINT + INSERT from 6-way UNION #tmp. Last observed refresh: 2023-10-08 |
| | |
| **Synapse Distribution** | HASH(CIDs) |
| **Synapse Index** | CLUSTERED INDEX (Active_Month ASC) |
| **Row Count** | ~7,461 |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_CorpDevDashboard` is a pre-aggregated reporting table designed to power a Corporate Development dashboard. It provides monthly KPIs segmented by macro-region (Americas, Europe, APAC, Middle East & Africa) and eToro Club tier, consolidating data from multiple upstream sources into a single, query-ready structure.

The table uses a **multi-indicator architecture**: the `Indicator` column discriminates between 6 distinct row types, each produced by a separate UNION branch in the writer SP:

| Indicator | Source | Populated Columns |
|-----------|--------|-------------------|
| `All` | BI_DB_CID_MonthlyPanel_FullData | CIDs, EOM_IsFunded, NewFundedAccounts, NewTrades, Revenue (4 asset classes + total), EOM_Equity, Deposits, Cashouts, PnL, MaxFunded |
| `FA` | BI_DB_First5Actions | Actions (count), FirstAction, FirstCross |
| `Regs` | BI_DB_CIDFirstDates | Regs (registration count) |
| `Age` | MonthlyPanel + CIDFirstDates | Age (sum of ages in years), CIDs (count of funded customers), EOM_Club |
| `AUA` | BI_DB_PositionPnL + Dim_Instrument | EOM_AUA by asset class (Currencies, Commodities, Crypto, Equities) |
| `Soc` | MonthlyPanel + Social_Activity + Guru_Copiers | Liked, Shared, WereCopied, CopiedOther |

Columns that are irrelevant to a given indicator are populated with 0 or NULL. This means most numeric columns are meaningful only for their specific indicator type — filtering by `Indicator` is essential for correct analysis.

**Region mapping**: The SP consolidates the ~20+ granular regions from upstream tables into 4 macro-regions via a CASE expression:
- **Americas**: South & Central America, USA, Canada
- **Middle East & Africa**: Israel, Arabic Other, Arabic GCC, Africa
- **APAC**: Australia, China, Other Asia, ROW, Russian, Unknown
- **Europe**: all others (default)

**Dormancy note**: The most recent data is from October 2023 (Active_Month=202310, UpdateDate=2023-10-08). The table appears to have stopped being refreshed, possibly indicating the dashboard was retired or replaced.

---

## 2. Business Logic

### 2.1 Multi-Indicator UNION Architecture

**What**: The SP constructs 6 separate aggregation queries, each writing rows with a different Indicator value, then UNIONs them into a single temp table before INSERT.

**Columns Involved**: `Indicator`, all metric columns

**Rules**:
- Each UNION branch sets non-applicable numeric columns to 0
- `Indicator='All'`: aggregates from MonthlyPanel grouped by Active_Month, Region (CASE-mapped), EOM_Club
- `Indicator='FA'`: counts from First5Actions grouped by Region, FirstActionTypeNew, FirstCrossNew — only rows where FirstActionTypeNew IS NOT NULL
- `Indicator='Regs'`: counts from CIDFirstDates grouped by registration month and Region
- `Indicator='Age'`: SUM of ages in years (DATEDIFF/365.25) for funded customers (IsFunded_New=1), joined to CIDFirstDates for BirthDate
- `Indicator='AUA'`: Assets Under Administration from PositionPnL (Amount + PositionPnL) bucketed by InstrumentTypeID via Dim_Instrument, filtered to depositors only
- `Indicator='Soc'`: Social engagement metrics from pre-computed temp tables (#Like, #Share, #WereCopied, #CopiedOther), all restricted to funded customers (IsEOM_Funded_NEW=1)

### 2.2 Region Macro-Mapping

**What**: Upstream granular regions are consolidated into 4 macro-regions via a CASE expression applied identically across all UNION branches.

**Columns Involved**: `Region`

**Rules**:
```
CASE
  WHEN Region IN ('South & Central America','USA','Canada') THEN 'Americas'
  WHEN Region IN ('Israel','Arabic Other','Arabic GCC','Africa') THEN 'Middle East & Africa'
  WHEN Region IN ('Australia','China','Other Asia','ROW','Russian','Unknown') THEN 'APAC'
  ELSE 'Europe'
END
```

### 2.3 Revenue by Asset Class (All Indicator)

**What**: Revenue is broken into 4 asset class buckets from MonthlyPanel's A_Revenue_* columns.

**Columns Involved**: `Revenue_Currencies`, `Revenue_Commodities`, `Revenue_Crypto`, `Revenue_Equities`, `Revenue_Total`

**Rules**:
- Revenue_Currencies = SUM(mp.A_Revenue_Currencies) — forex revenue
- Revenue_Commodities = SUM(mp.A_Revenue_Commodities) — commodity revenue
- Revenue_Crypto = SUM(mp.A_Revenue_Crypto) — crypto revenue
- Revenue_Equities = SUM(mp.A_Revenue_Equities) — equities revenue (stocks, ETFs, indices)
- Revenue_Total = SUM(mp.Revenue_Total) — total legacy revenue (excludes function fees)
- Note: Revenue_Total here uses the legacy formula from MonthlyPanel, NOT Revenue_Total_New

### 2.4 AUA by Asset Class (AUA Indicator)

**What**: Assets Under Administration computed from open positions' market value (Amount + unrealized PnL) on the reporting date.

**Columns Involved**: `EOM_AUA_Currencies`, `EOM_AUA_Commodities`, `EOM_AUA_Crypto`, `EOM_AUA_Equities`

**Rules**:
```sql
EOM_AUA_Currencies  = SUM(CASE WHEN di.InstrumentTypeID = 1  THEN mp.Amount + mp.PositionPnL ELSE 0 END)
EOM_AUA_Commodities = SUM(CASE WHEN di.InstrumentTypeID = 2  THEN mp.Amount + mp.PositionPnL ELSE 0 END)
EOM_AUA_Crypto      = SUM(CASE WHEN di.InstrumentTypeID = 10 THEN mp.Amount + mp.PositionPnL ELSE 0 END)
EOM_AUA_Equities    = SUM(CASE WHEN di.InstrumentTypeID IN (4,5,6) THEN mp.Amount + mp.PositionPnL ELSE 0 END)
```
- Source: BI_DB_PositionPnL joined to Dim_Instrument on InstrumentID, filtered to depositors via CIDFirstDates (FirstDepositDate IS NOT NULL)
- DateID = @dateINT (single day snapshot)

### 2.5 Social Engagement Metrics (Soc Indicator)

**What**: Counts of distinct funded customers who performed social actions during the month.

**Columns Involved**: `Liked`, `Shared`, `WereCopied`, `CopiedOther`

**Rules**:
- Liked = COUNT(DISTINCT RealCID) from BI_DB_Social_Activity WHERE ActionTypeID=3 AND IsEOM_Funded_NEW=1
- Shared = COUNT(DISTINCT RealCID) from BI_DB_Social_Activity WHERE ActionTypeID=4 AND IsEOM_Funded_NEW=1
- WereCopied = COUNT(DISTINCT ParentCID) from BI_DB_Guru_Copiers WHERE IsEOM_Funded_NEW=1
- CopiedOther = COUNT(DISTINCT CID) from BI_DB_Guru_Copiers WHERE IsEOM_Funded_NEW=1
- All social metrics are joined to MonthlyPanel for the funded filter and for Region assignment
- Pre-computed into temp tables (#Like, #Share, #WereCopied, #CopiedOther) then LEFT JOINed to MonthlyPanel rows in the Soc UNION branch

### 2.6 Age Calculation (Age Indicator)

**What**: Sum of customer ages in years for funded customers, used to compute average age per region/club.

**Columns Involved**: `Age`, `CIDs`

**Rules**:
```sql
Age  = SUM(DATEDIFF(DAY, fd.BirthDate, mp.ActiveDate) / 365.25)
CIDs = COUNT(*) -- count of funded customers in this group
-- Average age per group = Age / CIDs
```
- Only funded customers (IsFunded_New=1) are included
- BirthDate from BI_DB_CIDFirstDates (LEFT JOIN, FirstDepositDate IS NOT NULL filter)

### 2.7 Write Pattern

**What**: Monthly DELETE + INSERT pattern — the SP replaces all rows for the target month.

**Columns Involved**: All

**Rules**:
```sql
DELETE FROM BI_DB_CorpDevDashboard WHERE Active_Month = @SdateINT
INSERT INTO BI_DB_CorpDevDashboard SELECT ... FROM #tmp
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CIDs) distribution is unusual for an aggregation table — CIDs is a metric column (COUNT), not a customer identifier. This means data is distributed by the count value, which provides no co-location benefit. The CLUSTERED INDEX on Active_Month supports month-filtered queries efficiently. With only 7,461 rows, distribution strategy has minimal impact.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly KPI summary by region | `SELECT * WHERE Indicator = 'All' AND Active_Month = 202309` |
| First action distribution | `SELECT FirstAction, FirstCross, SUM(Actions) WHERE Indicator = 'FA' GROUP BY ...` |
| Registration trend | `SELECT Active_Month, Region, SUM(Regs) WHERE Indicator = 'Regs' GROUP BY ...` |
| AUA by asset class | `SELECT * WHERE Indicator = 'AUA' AND Active_Month = 202309` |
| Average customer age by club | `SELECT EOM_Club, SUM(Age)/SUM(CIDs) WHERE Indicator = 'Age' GROUP BY EOM_Club` |
| Social engagement | `SELECT * WHERE Indicator = 'Soc' AND Active_Month = 202309` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| N/A — self-contained | — | This is a pre-aggregated dashboard table. It does not typically require JOINs for analysis. |

### 3.4 Gotchas

- **Multi-indicator architecture**: Most numeric columns are 0 for indicators other than their specific type. Always filter `WHERE Indicator = '...'` before aggregating. Summing across indicators double-counts or produces meaningless totals.
- **Dormant table**: Last refresh was 2023-10-08. Data only covers 2012-10 through 2023-10. The dashboard may have been retired or replaced.
- **Active_Month is INT, not CHAR**: Unlike MonthlyPanel's Active_Month (char(7)), this table stores Active_Month as INT (YYYYMM format, e.g., 202309). No trailing space issue.
- **Region is macro-mapped**: Only 4 values (Americas, Europe, APAC, Middle East & Africa) — not the granular marketing regions from upstream tables.
- **Age is a SUM, not an average**: The `Age` column stores the total age-years for all funded customers in the group. Divide by `CIDs` to get average age.
- **Revenue_Total uses legacy formula**: This is SUM of MonthlyPanel.Revenue_Total (which excludes function fees). It does NOT use Revenue_Total_New.
- **HASH(CIDs) distribution is misleading**: CIDs is a metric (count), not a customer ID. No co-location benefit from this distribution key.
- **EOM_Club is NULL for non-All/Age indicators**: Only All and Age indicator rows carry EOM_Club values. FA, Regs, AUA, and Soc rows have NULL EOM_Club.
- **Soc indicator duplication**: The Soc UNION branch produces one row per (Region × MonthlyPanel row) via LEFT JOIN, resulting in social metrics being repeated across multiple rows for the same region. Aggregating Soc rows without deduplication will overcount.

---

## 4. Data Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki — description copied as-is |
| Tier 2 | ETL-computed in SP_CorpDevDashboard — transform documented from SP code |

### 4.1 Grain / Dimension Columns

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Active_Month | int | YES | Calendar month as YYYYMM integer (e.g., 202309). Derived from @date parameter: YEAR(@date)*100+MONTH(@date). Used as the DELETE/INSERT partition key. (Tier 2 — SP_CorpDevDashboard) |
| 2 | ActiveDate | date | YES | First day of the calendar month (e.g., 2023-09-01). Derived from mp.ActiveDate or DATEFROMPARTS(YEAR,MONTH,1). (Tier 2 — SP_CorpDevDashboard) |
| 3 | Indicator | varchar(5) | YES | Row type discriminator identifying which UNION branch produced this row. 6 values: 'All' (monthly panel KPIs), 'FA' (first action distribution), 'Regs' (registration counts), 'Age' (customer age for funded), 'AUA' (assets under administration), 'Soc' (social engagement). (Tier 2 — SP_CorpDevDashboard) |
| 4 | Region | varchar(50) | YES | Macro-region derived via CASE mapping from upstream granular regions: 'Americas' (South & Central America, USA, Canada), 'Middle East & Africa' (Israel, Arabic Other, Arabic GCC, Africa), 'APAC' (Australia, China, Other Asia, ROW, Russian, Unknown), 'Europe' (all others). (Tier 2 — SP_CorpDevDashboard) |
| 5 | EOM_Club | varchar(50) | YES | eToro Club loyalty tier at end of month: LowBronze (equity < $1,000), HighBronze (equity $1,000-Bronze threshold), Silver, Gold, Platinum, Platinum Plus, Diamond. Bronze is split at $1,000; Silver+ use Dim_PlayerLevel.Name directly. Passthrough from BI_DB_CID_MonthlyPanel_FullData. NULL for FA, Regs, AUA, Soc indicator rows. (Tier 1 — DWH_dbo.Dim_PlayerLevel wiki) |

### 4.2 Age / First Action Dimensions

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 6 | Age | int | YES | Sum of customer ages in years: SUM(DATEDIFF(DAY, BirthDate, ActiveDate) / 365.25). Only populated for Indicator='Age' (funded customers). Divide by CIDs to get average age. 0 or NULL for other indicators. (Tier 2 — SP_CorpDevDashboard, BI_DB_CIDFirstDates.BirthDate) |
| 7 | FirstAction | varchar(50) | YES | First position asset class using the new 3-way taxonomy. CASE on ActionTypeNew: 'Crypto', 'FX/Commodities' (typeID 1/2), 'Stocks/ETFs/Indices' (typeID 4/5/6), 'Copy', 'Copy Fund'. Only populated for Indicator='FA'. Renamed from BI_DB_First5Actions.FirstActionTypeNew. (Tier 2 — SP_First5Actions via BI_DB_First5Actions) |
| 8 | FirstCross | varchar(50) | YES | Asset class of 1st position using new ActionTypeNew taxonomy (BI_DB_CustomerCross_New, rn=1). Values: Crypto, FX/Commodities, Stocks/ETFs/Indices, Copy, Copy Fund. Only populated for Indicator='FA'. Renamed from BI_DB_First5Actions.FirstCrossNew. (Tier 2 — SP_First5Actions via BI_DB_First5Actions) |

### 4.3 Count Metrics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 9 | Regs | bigint | YES | Count of customer registrations in this month. Only populated for Indicator='Regs' (COUNT(*) from BI_DB_CIDFirstDates grouped by registration month and Region). 0 for other indicators. (Tier 2 — SP_CorpDevDashboard) |
| 10 | CIDs | bigint | YES | Count of distinct customers. For Indicator='All': COUNT(DISTINCT CID) from MonthlyPanel. For Indicator='Age': COUNT(*) of funded customers. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard) |
| 11 | EOM_IsFunded | bigint | YES | Count of funded customers at end of month: SUM(IsEOM_Funded_NEW) from MonthlyPanel. Only populated for Indicator='All'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard) |
| 12 | NewFundedAccounts | bigint | YES | Count of newly funded accounts this month: COUNT(DISTINCT CID) WHERE Seniority_FundedNew=0. Only populated for Indicator='All'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard) |

### 4.4 Trading Metrics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 13 | NewTrades_Copy | bigint | YES | Total new copy-trade positions opened this month: SUM(NewTrades_Copy) from MonthlyPanel. Only populated for Indicator='All'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard) |
| 14 | NewTrades_Total | bigint | YES | Total new positions opened this month (all asset classes): SUM(NewTrades_Total) from MonthlyPanel. Only populated for Indicator='All'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard) |

### 4.5 Revenue Metrics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 15 | Revenue_Currencies | money | YES | Total forex revenue for the month: SUM(A_Revenue_Currencies) from MonthlyPanel. Only populated for Indicator='All'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard) |
| 16 | Revenue_Commodities | money | YES | Total commodity revenue for the month: SUM(A_Revenue_Commodities) from MonthlyPanel. Only populated for Indicator='All'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard) |
| 17 | Revenue_Crypto | money | YES | Total crypto revenue for the month: SUM(A_Revenue_Crypto) from MonthlyPanel. Only populated for Indicator='All'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard) |
| 18 | Revenue_Equities | money | YES | Total equities revenue for the month: SUM(A_Revenue_Equities) from MonthlyPanel. Only populated for Indicator='All'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard) |
| 19 | Revenue_Total | money | YES | Total legacy revenue for the month: SUM(Revenue_Total) from MonthlyPanel. Uses legacy formula (excludes function fees). Only populated for Indicator='All'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard) |

### 4.6 Equity & Financial Metrics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 20 | EOM_Equity | money | YES | Total account equity (USD) across all customers in this group at end of month: SUM(EOM_Equity) from MonthlyPanel. Only populated for Indicator='All'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard) |
| 21 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_CorpDevDashboard. GETDATE() at INSERT time. (Tier 2 — SP_CorpDevDashboard) |
| 22 | Actions | int | YES | Count of first actions (positions opened): COUNT(*) from BI_DB_First5Actions WHERE FirstActionTypeNew IS NOT NULL. Only populated for Indicator='FA'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard) |

### 4.7 AUA (Assets Under Administration) by Asset Class

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 23 | EOM_AUA_Currencies | money | YES | End-of-month assets under administration for forex positions: SUM(Amount + PositionPnL) from BI_DB_PositionPnL WHERE InstrumentTypeID=1 (Currencies). Only populated for Indicator='AUA'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard, BI_DB_PositionPnL + Dim_Instrument) |
| 24 | EOM_AUA_Commodities | money | YES | End-of-month AUA for commodity positions: SUM(Amount + PositionPnL) WHERE InstrumentTypeID=2 (Commodities). Only populated for Indicator='AUA'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard, BI_DB_PositionPnL + Dim_Instrument) |
| 25 | EOM_AUA_Crypto | money | YES | End-of-month AUA for crypto positions: SUM(Amount + PositionPnL) WHERE InstrumentTypeID=10 (Crypto Currencies). Only populated for Indicator='AUA'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard, BI_DB_PositionPnL + Dim_Instrument) |
| 26 | EOM_AUA_Equities | money | YES | End-of-month AUA for equities positions: SUM(Amount + PositionPnL) WHERE InstrumentTypeID IN (4=Indices, 5=Stocks, 6=ETF). Only populated for Indicator='AUA'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard, BI_DB_PositionPnL + Dim_Instrument) |

### 4.8 Deposit / Cashout / PnL Metrics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 27 | Total_Deposits | money | YES | Total deposit amount (USD) for all customers in this group this month: SUM(TotalDeposits) from MonthlyPanel. Only populated for Indicator='All'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard) |
| 28 | Total_Cashouts | money | YES | Total cashout/withdrawal amount (USD) for the group this month: SUM(TotalCashouts) from MonthlyPanel. Only populated for Indicator='All'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard) |
| 29 | Total_PnL | money | YES | Total realized PnL (USD) for the group this month: SUM(PnL_Total) from MonthlyPanel. Only populated for Indicator='All'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard) |

### 4.9 Social Engagement Metrics

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 30 | Liked | int | YES | Count of distinct funded customers who liked social content this month. From BI_DB_Social_Activity WHERE ActionTypeID=3, restricted to funded customers (IsEOM_Funded_NEW=1). Only populated for Indicator='Soc'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard, BI_DB_Social_Activity) |
| 31 | Shared | int | YES | Count of distinct funded customers who shared social content this month. From BI_DB_Social_Activity WHERE ActionTypeID=4, restricted to funded customers (IsEOM_Funded_NEW=1). Only populated for Indicator='Soc'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard, BI_DB_Social_Activity) |
| 32 | WereCopied | int | YES | Count of distinct funded customers whose trades were copied by others this month. From BI_DB_Guru_Copiers (ParentCID), restricted to funded customers (IsEOM_Funded_NEW=1). Only populated for Indicator='Soc'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard, BI_DB_Guru_Copiers) |
| 33 | CopiedOther | int | YES | Count of distinct funded customers who started copying other traders this month. From BI_DB_Guru_Copiers (CID), restricted to funded customers (IsEOM_Funded_NEW=1). Only populated for Indicator='Soc'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard, BI_DB_Guru_Copiers) |
| 34 | MaxFunded | int | YES | Count of funded customers (new funded definition): SUM(IsFunded_New) from MonthlyPanel. Only populated for Indicator='All'. 0 for other indicators. (Tier 2 — SP_CorpDevDashboard) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| Active_Month | SP_CorpDevDashboard | @date param | YEAR(@date)*100+MONTH(@date) |
| ActiveDate | SP_CorpDevDashboard | @date param / mp.ActiveDate | DATEFROMPARTS or passthrough |
| Indicator | SP_CorpDevDashboard | — | Hardcoded per UNION branch |
| Region | SP_CorpDevDashboard | mp.Region / fd.Region | CASE mapping to 4 macro-regions |
| EOM_Club | BI_DB_CID_MonthlyPanel_FullData | EOM_Club | Passthrough (GROUP BY) |
| Age | SP_CorpDevDashboard | fd.BirthDate, mp.ActiveDate | SUM(DATEDIFF(DAY,...)/365.25) |
| FirstAction | BI_DB_First5Actions | FirstActionTypeNew | Rename |
| FirstCross | BI_DB_First5Actions | FirstCrossNew | Rename |
| Regs | SP_CorpDevDashboard | BI_DB_CIDFirstDates | COUNT(*) |
| CIDs | SP_CorpDevDashboard | MonthlyPanel.CID | COUNT(DISTINCT) or COUNT(*) |
| EOM_IsFunded | SP_CorpDevDashboard | MonthlyPanel.IsEOM_Funded_NEW | SUM |
| NewFundedAccounts | SP_CorpDevDashboard | MonthlyPanel.Seniority_FundedNew | COUNT(DISTINCT WHERE =0) |
| NewTrades_Copy | SP_CorpDevDashboard | MonthlyPanel.NewTrades_Copy | SUM |
| NewTrades_Total | SP_CorpDevDashboard | MonthlyPanel.NewTrades_Total | SUM |
| Revenue_Currencies | SP_CorpDevDashboard | MonthlyPanel.A_Revenue_Currencies | SUM |
| Revenue_Commodities | SP_CorpDevDashboard | MonthlyPanel.A_Revenue_Commodities | SUM |
| Revenue_Crypto | SP_CorpDevDashboard | MonthlyPanel.A_Revenue_Crypto | SUM |
| Revenue_Equities | SP_CorpDevDashboard | MonthlyPanel.A_Revenue_Equities | SUM |
| Revenue_Total | SP_CorpDevDashboard | MonthlyPanel.Revenue_Total | SUM |
| EOM_Equity | SP_CorpDevDashboard | MonthlyPanel.EOM_Equity | SUM |
| UpdateDate | SP_CorpDevDashboard | — | GETDATE() |
| Actions | SP_CorpDevDashboard | BI_DB_First5Actions | COUNT(*) |
| EOM_AUA_* | SP_CorpDevDashboard | PositionPnL.Amount + PositionPnL.PositionPnL | SUM(CASE by InstrumentTypeID) |
| Total_Deposits | SP_CorpDevDashboard | MonthlyPanel.TotalDeposits | SUM |
| Total_Cashouts | SP_CorpDevDashboard | MonthlyPanel.TotalCashouts | SUM |
| Total_PnL | SP_CorpDevDashboard | MonthlyPanel.PnL_Total | SUM |
| Liked | SP_CorpDevDashboard | BI_DB_Social_Activity | COUNT(DISTINCT) via #Like |
| Shared | SP_CorpDevDashboard | BI_DB_Social_Activity | COUNT(DISTINCT) via #Share |
| WereCopied | SP_CorpDevDashboard | BI_DB_Guru_Copiers.ParentCID | COUNT(DISTINCT) via #WereCopied |
| CopiedOther | SP_CorpDevDashboard | BI_DB_Guru_Copiers.CID | COUNT(DISTINCT) via #CopiedOther |
| MaxFunded | SP_CorpDevDashboard | MonthlyPanel.IsFunded_New | SUM |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData (353.8M rows, monthly CRM panel)
BI_DB_dbo.BI_DB_First5Actions (46.3M rows, first actions per depositor)
BI_DB_dbo.BI_DB_CIDFirstDates (46.7M rows, customer lifecycle milestones)
BI_DB_dbo.BI_DB_PositionPnL (daily position P&L snapshot)
BI_DB_dbo.BI_DB_Social_Activity (social engagement events)
BI_DB_dbo.BI_DB_Guru_Copiers (copy-trade relationships)
DWH_dbo.Dim_Instrument (15.7K rows, instrument dimension)
  |
  |-- SP_CorpDevDashboard @date --|
  |   6-way UNION into #tmp       |
  |   DELETE + INSERT by month     |
  v
BI_DB_dbo.BI_DB_CorpDevDashboard (7,461 rows — dormant since 2023-10)
  |-- UC: Not Migrated --|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | BI_DB_CID_MonthlyPanel_FullData | Primary source for All, Age, Soc indicators — CIDs, revenue, equity, deposits, PnL |
| N/A | BI_DB_First5Actions | Source for FA indicator — first action/cross distributions |
| N/A | BI_DB_CIDFirstDates | Source for Regs indicator (registration counts) and Age indicator (BirthDate) |
| N/A | BI_DB_PositionPnL | Source for AUA indicator — open position market values |
| N/A | Dim_Instrument | Instrument classification for AUA asset class bucketing |
| N/A | BI_DB_Social_Activity | Source for social engagement metrics (Liked, Shared) |
| N/A | BI_DB_Guru_Copiers | Source for copy activity metrics (WereCopied, CopiedOther) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| — | — | No known downstream consumers identified. Dashboard consumption table. |

---

## 7. Sample Queries

### 7.1 Monthly revenue summary by region
```sql
SELECT Active_Month, Region, EOM_Club,
       Revenue_Currencies, Revenue_Commodities,
       Revenue_Crypto, Revenue_Equities, Revenue_Total
FROM BI_DB_dbo.BI_DB_CorpDevDashboard
WHERE Indicator = 'All'
  AND Active_Month = 202309
ORDER BY Region, EOM_Club;
```

### 7.2 First action distribution for a given month
```sql
SELECT Region, FirstAction, FirstCross, SUM(Actions) AS total_actions
FROM BI_DB_dbo.BI_DB_CorpDevDashboard
WHERE Indicator = 'FA'
  AND Active_Month = 202309
GROUP BY Region, FirstAction, FirstCross
ORDER BY total_actions DESC;
```

### 7.3 Average customer age by club tier
```sql
SELECT Active_Month, Region, EOM_Club,
       SUM(Age) / NULLIF(SUM(CIDs), 0) AS avg_age_years
FROM BI_DB_dbo.BI_DB_CorpDevDashboard
WHERE Indicator = 'Age'
GROUP BY Active_Month, Region, EOM_Club
ORDER BY Active_Month DESC, Region;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — skipped Phase 10).

---

*Generated: 2026-04-28 | Quality: 8.0/10 | Phases: 11/14*
*Tiers: 1 T1, 33 T2, 0 T3, 0 T4, 0 T5 | Elements: 34/34, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_CorpDevDashboard | Type: Table | Production Source: Multi-source ETL aggregation via SP_CorpDevDashboard*
