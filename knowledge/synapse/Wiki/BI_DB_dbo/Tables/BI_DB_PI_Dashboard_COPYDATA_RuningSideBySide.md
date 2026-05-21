# BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide

> Daily PI Dashboard comparison table storing ~3,400 rows per day for every active Popular Investor and CopyFund account, capturing KPI snapshots across performance (YTD/MTD/QTD gains), risk (7-day and 12-month risk scores), trading style (classification, trader type, holding time), portfolio composition (top instruments/industries), and financials (AUM, equity, commission). Covers 2020-01-01 to 2024-04-14 with 1,501 daily snapshots. Refreshed daily via SP_PI_Dashboard_COPYDATA_RuningSideBySide (DELETE+INSERT by Date).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide` from Dim_Customer, DWH_GainDaily, BI_DB_CopyDailyData, DWH_CIDsDailyRisk, Dim_Position, and 10+ other sources |
| **Refresh** | Daily — DELETE WHERE Date=@yesterday + INSERT |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide` is a daily KPI dashboard snapshot table for all active **Popular Investors (PIs)** and **CopyFund accounts** on the eToro platform. Each row represents one PI or CopyFund on a given date, consolidating metrics from 15+ upstream tables into a single denormalized row for dashboard consumption.

The table serves as the primary data source for PI-vs-PI comparison dashboards, enabling side-by-side analysis of:
- **Performance**: YTD, QTD, MTD, last-month, and last-day compound returns; average yearly gain across all completed calendar years
- **Risk**: 7-day average risk score (matching platform display), highest average monthly risk in the last 12 months, current-month average risk score
- **Trading Style**: Classification (Long Equity, Multi-Strategy, Crypto, etc.), TraderType (Day/Swing/Medium/Long term), average holding time, average weekly trades
- **Portfolio Composition**: Largest asset class, top 3 traded instruments (all-time and current open), top 3 invested industries
- **Financials**: AUM (copy trading assets), total equity, past year commission
- **Status**: PI tier (Cadet through Elite Pro), blocked status

**Population**: Active PIs (GuruStatusID IN 2,3,4,5,6 AND IsValidCustomer=1) plus CopyFund accounts (AccountTypeID=9). ~3,391 rows on the latest date (2024-04-14): 3,215 PIs + 176 CopyFunds.

**ETL Pattern**: The SP maintains three incremental shadow tables (`BI_DB_PI_Positions`, `BI_DB_PI_GainDaily`, `BI_DB_PI_WeeklyTrades`) that cache position, gain, and trade data for PIs to avoid re-scanning the large DWH tables. On each run, new PIs are backfilled and yesterday's data is appended. The final INSERT joins ~15 temp tables to produce the denormalized output.

**Side effect**: The SP also appends to `BI_DB_PastYearsGain` on Jan 1 of each year (section 3.4 of the SP), capturing the trailing yearly gain for each customer.

---

## 2. Business Logic

### 2.1 PI Population Filter

**What**: Determines which customers appear in the dashboard.

**Columns Involved**: `CID`, `PI/CP`

**Rules**:
- Active Popular Investors: `GuruStatusID IN (2,3,4,5,6) AND IsValidCustomer = 1`
- CopyFund accounts: `AccountTypeID = 9` (regardless of GuruStatus)
- Population is derived from `Dim_Customer` joined to `Dim_GuruStatus`, `Dim_Country`, and `Dim_PlayerStatus`
- `PI/CP`: 'PI' for regular Popular Investors, 'CopyFund' for AccountTypeID=9 accounts

### 2.2 Classification — Open Position Asset Allocation

**What**: Categorizes each PI's trading strategy based on the asset class distribution of their current open positions.

**Columns Involved**: `Classification`

**Rules**:
```
Classification =
  WHEN Equity_Percent >= 0.7 AND Equity_Buy_Percent >= 0.2 AND Equity_Short_Percent >= 0.2
    → 'Long/Short Equity'
  WHEN Equity_Percent >= 0.7 AND Equity_Buy_Percent > 0.8
    → 'Long Equity'
  WHEN Currencies_Percent >= 0.7 → 'Currencies'
  WHEN Commodities_Percent >= 0.7 → 'Commodities'
  WHEN Crypto_Percent >= 0.7 → 'Crypto'
  WHEN ETF_Percent >= 0.7 → 'ETF'
  WHEN Total_invest = 0 → '100% cash balance'
  ELSE 'Multi-Strategy'
```
- Only manual positions (MirrorID=0) are considered for classification
- "Equity" in this context means InstrumentTypeID IN (5=Stocks, 4=Indices)
- Observed distribution (2024-04-14): Long Equity 56.4%, Multi-Strategy 24.4%, ETF 7.1%, Crypto 7.1%, 100% cash 2.4%, Currencies 1.2%, Long/Short Equity 1.2%, Commodities 0.2%

### 2.3 TraderType — Holding Time Segmentation

**What**: Classifies each PI by average holding time of their manual positions (last 2 years).

**Columns Involved**: `TraderType`, `Avgerage_Holding_Time`

**Rules**:
```
TraderType =
  WHEN AvgerageHoldingTime < 3 days    → 'Day trader'
  WHEN AvgerageHoldingTime >= 3 AND < 22 days  → 'Swing trader'
  WHEN AvgerageHoldingTime >= 22 AND < 94 days → 'Medium term investor'
  WHEN AvgerageHoldingTime >= 94 days  → 'Long term investor'
  DEFAULT (no closed positions)        → 'Long term investor'
```
- Holding time calculated as `DATEDIFF(mi, OpenOccurred, CloseOccurred) / 60 / 24` (in days)
- Both manual positions (MirrorID=0) and copy relationships (Dim_Mirror) are included
- Only closed positions in the last 2 years are considered
- Observed distribution (2024-04-14): Long term 50.7%, Medium term 34.4%, Swing 12.6%, Day 2.3%

### 2.4 Risk Score — Platform-Matching 7-Day Average

**What**: Computes a 1-10 risk score matching the eToro platform's display.

**Columns Involved**: `Acc_RiskIndex`, `Highest_AVG_12Months_Risk`, `AvgRiskScore_CurrentMonth`

**Rules**:
- Sources from `DWH_CIDsDailyRisk.AvgSTD` (daily portfolio standard deviation)
- STD is mapped to a 1-10 score via `External_etoro_Internal_RiskScore` band thresholds:
  - STD < 0.0011 → 1, < 0.0024 → 2, ..., >= 0.0475 → 10, no match → 0
- `Acc_RiskIndex`: ROUND(AVG(RiskScore)) over the last 7 days (matches platform display)
- `Highest_AVG_12Months_Risk`: MAX of monthly-average risk scores over the last 12 months
- `AvgRiskScore_CurrentMonth`: AVG(RiskScore) for dates in the current calendar month up to @yesterday

### 2.5 Average Yearly Gain

**What**: Computes lifetime average annual performance by combining completed calendar years with current YTD.

**Columns Involved**: `Avg_Yearly_gain`

**Rules**:
```
#AvgGain0 =
  SELECT year, CID, Gain_YTD FROM #YTD (current year's YTD gain)
  UNION ALL
  SELECT Year1, CID, Gain_y FROM BI_DB_PastYearsGain (completed past years)

Avg_Yearly_gain = AVG(Gain_y) per CID
```
- Includes the current partial year as YTD, averaged equally with completed years
- Gain values are decimal fractions (0.10 = 10% return)

### 2.6 Past Year Commission — Rolling 365-Day Window

**What**: Calculates copy-trading commission earned in the trailing 365-day window.

**Columns Involved**: `Past_Year_Commission`

**Rules**:
- Sources from `BI_DB_PI_Dashboard` (2 days ago) and `BI_DB_DailyCopyRevenue` (yesterday)
- Formula: `Prior_365d_commission_from_PI_Dashboard + Yesterday_Revenue_Copy`
- Uses LEAD window function to compute the rolling difference, then adds yesterday's daily copy revenue
- Result: cumulative copy trading commission for the past 365 days

### 2.7 IsBlocked — Active PI with Blocked Operations

**What**: Identifies PIs who have active copiers but are blocked from certain operations.

**Columns Involved**: `IsBlocked`

**Rules**:
- 'Yes' if CID appears in `External_etoro_Customer_BlockedCustomerOperations` (OperationTypeID=2) AND has active copiers in `etoroGeneral_History_GuruCopiers`
- 'No' otherwise
- Checks against the most recent block occurrence per CID

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no distribution key, no clustered index. ~3,400 rows per daily slice; ~5.1M total rows across 1,501 dates. Always filter by `Date` to avoid full table scans. Date-filtered queries are fast given the modest per-day row count.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| PI dashboard for a specific date | `WHERE [Date] = @date ORDER BY AUM DESC` |
| Compare PI performance across dates | `WHERE CID = @cid ORDER BY [Date]` |
| Find high-risk PIs | `WHERE [Date] = @date AND Acc_RiskIndex >= 7` |
| PI classification distribution | `WHERE [Date] = @date GROUP BY Classification` |
| Top PIs by AUM | `WHERE [Date] = @date ORDER BY AUM DESC` |
| Swing traders with high YTD | `WHERE [Date] = @date AND TraderType = 'Swing trader' ORDER BY YTD DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Additional customer attributes not in dashboard |
| BI_DB_dbo.BI_DB_CopyDailyData | ON CID + DateID | Detailed PI equity decomposition (CopyAUM, manual stocks/crypto) |
| BI_DB_dbo.BI_DB_DailyCopyRevenue | ON CID = ParentCID + Date | Revenue breakdown by instrument type |

### 3.4 Gotchas

- **Table name has a typo**: "RuningSideBySide" (should be "RunningSideBySide"). This is the authoritative DDL name.
- **Column name typo**: `Avgerage_Holding_Time` (should be "Average"). Use the exact spelling in queries.
- **Gain values are decimals, not percentages**: 0.2249 = 22.49% gain. Multiply by 100 for display.
- **Classification only uses manual positions**: MirrorID=0. Copy positions are excluded from the asset allocation calculation.
- **TraderType defaults to 'Long term investor'**: If a PI has no closed positions in the last 2 years, ISNULL defaults to 'Long term investor' rather than NULL.
- **Past_Year_Commission = 0 for many PIs**: Commission calculation depends on `BI_DB_PI_Dashboard` having a prior-day row with a hardcoded date filter. New PIs or PIs without matching records show 0.
- **AUM and Total_Equity can be NULL**: If the PI has no row in `BI_DB_CopyDailyData` for @yesterday, these values are NULL.
- **Data stops at 2024-04-14**: The table has not been refreshed since this date based on live data.
- **IsBlocked is a varchar 'Yes'/'No'**: Not a bit flag. Use `WHERE IsBlocked = 'Yes'` for filtering.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (Dim_Customer, Dim_Country, Dim_GuruStatus) |
| Tier 2 | SP-computed / ETL-derived |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date (SP @yesterday parameter). DELETE+INSERT key. One row per PI per date. (Tier 2 — SP_PI_Dashboard_COPYDATA_RuningSideBySide) |
| 2 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 3 | UserName | varchar(20) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic) |
| 4 | Name | nvarchar(101) | YES | PI display name: FirstName + ' ' + LastName from Dim_Customer. (Tier 2 — Dim_Customer) |
| 5 | PI_level | varchar(50) | YES | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Passthrough from Dim_GuruStatus. (Tier 1 — Dictionary.GuruStatus) |
| 6 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 7 | Region | varchar(50) | YES | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values. Passthrough from Dim_Country. (Tier 4 — Dictionary.Country) |
| 8 | Desk | nvarchar(50) | YES | Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join. Passthrough from Dim_Country. (Tier 2 — Ext_Dim_Country_Region_Desk) |
| 9 | PI/CP | varchar(13) | NO | PI category: 'PI' for active Popular Investors (GuruStatusID IN 2-6), 'CopyFund' for AccountTypeID=9 (Copy Portfolio accounts). Derived from Dim_Customer.AccountTypeID. (Tier 2 — Dim_Customer) |
| 10 | Largest_Asset_Class | varchar(50) | YES | Asset class with the highest total invested amount across all manual positions (MirrorID=0) in the PI's trade history. Values: Stocks, Currencies, Commodities, Indices, ETF, Crypto Currencies. Determined by ROW_NUMBER on SUM(Amount) per InstrumentType. (Tier 2 — Dim_Instrument / BI_DB_PI_Positions) |
| 11 | Top_3_Traded_Instruments | nvarchar(max) | YES | Comma-separated symbols of the top 3 instruments by total invested amount across all manual positions (full trade history). E.g., 'AAPL,MSFT,GOOGL'. (Tier 2 — Dim_Instrument / BI_DB_PI_Positions) |
| 12 | YTD | float | YES | Year-to-date compound portfolio return as a decimal. 0.2249 = 22.49% gain. From Jan 1 to @yesterday. Passthrough from DWH_GainDaily.Gain_YTD via BI_DB_PI_GainDaily. (Tier 2 — DWH_GainDaily) |
| 13 | MTD | float | YES | Month-to-date compound portfolio return as a decimal. From first of current month to @yesterday. Passthrough from DWH_GainDaily.Gain_MTD via BI_DB_PI_GainDaily. (Tier 2 — DWH_GainDaily) |
| 14 | Last_Day_Performance | float | YES | Daily compound portfolio return as a decimal for @yesterday. Single-day gain. Passthrough from DWH_GainDaily.Gain_d via BI_DB_PI_GainDaily. (Tier 2 — DWH_GainDaily) |
| 15 | Positive_Months_percent | numeric(29,15) | YES | Fraction of months with positive returns (Gain_m > 0) out of all months the PI has gain data. 0.78 = 78% of months were profitable. Computed from BI_DB_PI_GainDaily monthly gain snapshots. (Tier 2 — DWH_GainDaily) |
| 16 | Avg_weekly_trades | numeric(38,6) | YES | Average number of new trades per week over the last 52 weeks. Computed as AVG(NewTrades) from BI_DB_PI_WeeklyTrades WHERE FirstDayOfWeek >= @yesterday - 1 year. (Tier 2 — BI_DB_CID_WeeklyPanel_FullData) |
| 17 | Avgerage_Holding_Time | numeric(38,2) | YES | Average position holding time in days for closed manual positions and copy relationships in the last 2 years. Calculated as AVG(DATEDIFF(minutes, Open, Close) / 60 / 24). Note: column name has typo ('Avgerage'). (Tier 2 — BI_DB_PI_Positions / Dim_Mirror) |
| 18 | Acc_RiskIndex | int | YES | Portfolio risk score 1-10, matching the eToro platform display. Computed as ROUND(AVG(RiskScore)) over the last 7 days, where RiskScore is mapped from DWH_CIDsDailyRisk.AvgSTD via External_etoro_Internal_RiskScore band thresholds. Higher score = more volatile portfolio. 0 = no data. (Tier 2 — DWH_CIDsDailyRisk) |
| 19 | Highest_AVG_12Months_Risk | numeric(38,6) | YES | Maximum of monthly-average risk scores over the last 12 months. Each month's average is the mean daily RiskScore for that calendar month. Identifies the PI's peak risk period. (Tier 2 — DWH_CIDsDailyRisk) |
| 20 | AUM | money | YES | Copy-trading AUM (Assets Under Management): total value managed through copy relationships. Passthrough from BI_DB_CopyDailyData.CopyAUM at @yesterday. NULL if no CopyDailyData row exists. (Tier 2 — BI_DB_CopyDailyData) |
| 21 | Total_Equity | decimal(23,4) | YES | PI's total equity: Liabilities + ActualNWA from V_Liabilities. Represents total account value including liabilities. Passthrough from BI_DB_CopyDailyData.TotalEquity at @yesterday. NULL if no CopyDailyData row exists. (Tier 2 — BI_DB_CopyDailyData) |
| 22 | Past_Year_Commission | money | YES | Cumulative copy-trading commission earned in the trailing 365-day window. Rolling calculation: prior day's 365-day commission from BI_DB_PI_Dashboard plus yesterday's Revenue_Copy from BI_DB_DailyCopyRevenue. 0 for PIs without matching prior records. (Tier 2 — BI_DB_PI_Dashboard / BI_DB_DailyCopyRevenue) |
| 23 | QTD | float | YES | Quarter-to-date compound portfolio return as a decimal. From first of current quarter to @yesterday. Passthrough from DWH_GainDaily.Gain_QTD via BI_DB_PI_GainDaily. (Tier 2 — DWH_GainDaily) |
| 24 | Last_Month_Performance | float | YES | Trailing 30-day (monthly) compound portfolio return as a decimal. Passthrough from DWH_GainDaily.Gain_m via BI_DB_PI_GainDaily. (Tier 2 — DWH_GainDaily) |
| 25 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_PI_Dashboard_COPYDATA_RuningSideBySide. Set to GETDATE(). (Tier 2 — SP_PI_Dashboard_COPYDATA_RuningSideBySide) |
| 26 | Top_3_Traded_Instruments_yesteday | nvarchar(max) | YES | Comma-separated symbols of the top 3 instruments by invested amount among currently open manual positions only. Differs from Top_3_Traded_Instruments which uses full history. Note: column name has typo ('yesteday'). (Tier 2 — Dim_Instrument / BI_DB_PI_Positions) |
| 27 | Avg_Yearly_gain | numeric(38,6) | YES | Average annual compound return across all completed calendar years plus the current year's YTD. Computed as AVG(Gain_y) from BI_DB_PastYearsGain UNION current YTD. Gain values are decimal fractions (0.10 = 10%). (Tier 2 — BI_DB_PastYearsGain / DWH_GainDaily) |
| 28 | Classification | nvarchar(50) | YES | PI trading strategy classification based on open manual position asset allocation. Values: 'Long Equity' (stocks/indices >= 70%, buy > 80%), 'Long/Short Equity' (stocks/indices >= 70%, mixed buy/sell), 'Currencies' (FX >= 70%), 'Commodities' (>= 70%), 'Crypto' (>= 70%), 'ETF' (>= 70%), '100% cash balance' (no open positions), 'Multi-Strategy' (no single asset class >= 70%). See section 2.2. (Tier 2 — BI_DB_PI_Positions / Dim_Instrument) |
| 29 | TraderType | nvarchar(50) | YES | PI trading style based on average holding time of closed positions in the last 2 years. Values: 'Day trader' (< 3 days), 'Swing trader' (3-22 days), 'Medium term investor' (22-94 days), 'Long term investor' (>= 94 days or no closed positions). See section 2.3. (Tier 2 — BI_DB_PI_Positions / Dim_Mirror) |
| 30 | IsBlocked | varchar(20) | YES | Whether this PI has blocked operations while still having active copiers. 'Yes' if CID appears in External_etoro_Customer_BlockedCustomerOperations (OperationTypeID=2) with active copiers; 'No' otherwise. (Tier 2 — External_etoro_Customer_BlockedCustomerOperations) |
| 31 | Top3TradedIndustries | nvarchar(50) | YES | Comma-separated top 3 industries by invested amount among currently open manual positions. E.g., 'Technology,Consumer Goods,Healthcare'. Based on Dim_Instrument.Industry for open positions (CloseDateID=0). (Tier 2 — Dim_Instrument / BI_DB_PI_Positions) |
| 32 | AvgRiskScore_CurrentMonth | int | YES | Average daily risk score for the current calendar month up to @yesterday. Computed as ROUND(AVG(RiskScore)) for dates >= first of current month. Same band-mapping logic as Acc_RiskIndex but scoped to the current month. (Tier 2 — DWH_CIDsDailyRisk) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | SP parameter | @yesterday | Passthrough |
| CID | Dim_Customer | RealCID | Passthrough |
| UserName | Dim_Customer | UserName | Passthrough (dim-lookup) |
| Name | Dim_Customer | FirstName, LastName | Concatenation: FirstName + ' ' + LastName |
| PI_level | Dim_GuruStatus | GuruStatusName | Passthrough (dim-lookup via GuruStatusID) |
| Country | Dim_Country | Name | Passthrough (dim-lookup via CountryID) |
| Region | Dim_Country | Region | Passthrough (dim-lookup via CountryID) |
| Desk | Dim_Country | Desk | Passthrough (dim-lookup via CountryID) |
| PI/CP | Dim_Customer | AccountTypeID | CASE: 9='CopyFund', else='PI' |
| Largest_Asset_Class | Dim_Instrument | InstrumentType | Top 1 by SUM(Amount) from BI_DB_PI_Positions (manual only) |
| Top_3_Traded_Instruments | Dim_Instrument | Symbol | STRING_AGG top 3 by Amount (full history, manual) |
| Top_3_Traded_Instruments_yesteday | Dim_Instrument | Symbol | STRING_AGG top 3 by Amount (open positions only) |
| YTD / QTD / MTD / Last_Month / Last_Day | DWH_GainDaily | Gain_YTD / QTD / MTD / m / d | Passthrough via BI_DB_PI_GainDaily |
| Positive_Months_percent | BI_DB_PI_GainDaily | Gain_m | COUNT(positive months) / COUNT(total months) |
| Avg_weekly_trades | BI_DB_PI_WeeklyTrades | NewTrades | AVG over last year |
| Avgerage_Holding_Time | BI_DB_PI_Positions + Dim_Mirror | OpenOccurred, CloseOccurred | AVG holding time in days (last 2 years) |
| Acc_RiskIndex | DWH_CIDsDailyRisk | AvgSTD | 7-day AVG of band-mapped RiskScore |
| Highest_AVG_12Months_Risk | DWH_CIDsDailyRisk | AvgSTD | MAX(monthly AVG RiskScore) over 12 months |
| AvgRiskScore_CurrentMonth | DWH_CIDsDailyRisk | AvgSTD | Current month AVG of band-mapped RiskScore |
| AUM | BI_DB_CopyDailyData | CopyAUM | Passthrough at @yesterday |
| Total_Equity | BI_DB_CopyDailyData | TotalEquity | Passthrough at @yesterday |
| Past_Year_Commission | BI_DB_PI_Dashboard + BI_DB_DailyCopyRevenue | Past_Year_Commission + Revenue_Copy | Rolling 365-day commission |
| Avg_Yearly_gain | BI_DB_PastYearsGain + DWH_GainDaily | Gain_y + Gain_YTD | AVG across all years + current YTD |
| Classification | BI_DB_PI_Positions + Dim_Instrument | Amount, InstrumentTypeID, IsBuy | CASE on asset class percentages |
| TraderType | BI_DB_PI_Positions + Dim_Mirror | OpenOccurred, CloseOccurred | CASE on AVG holding time |
| IsBlocked | External_etoro_Customer_BlockedCustomerOperations | OperationTypeID, CID | 'Yes'/'No' based on block + active copiers |
| Top3TradedIndustries | Dim_Instrument | Industry | STRING_AGG top 3 by Amount (open positions) |
| UpdateDate | SP | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer + Dim_GuruStatus + Dim_Country + Dim_PlayerStatus
  → #pop (PI/CopyFund population: ~3,400 CIDs)

DWH_dbo.Dim_Position → BI_DB_dbo.BI_DB_PI_Positions (incremental shadow cache)
  → #BI_DB_PI_Positions (manual positions, MirrorID=0)
  → #instrumntstype (largest asset class per CID)
  → #Top3instrumnts (top 3 symbols, full history)
  → #Top3openinstrumnts (top 3 symbols, open only)
  → #Top3openinstrumnts_industries (top 3 industries, open only)
  → #openpositions → #Clssification (asset allocation classification)
  → #hold1 → #avghold (avg holding time + TraderType)

BI_DB_dbo.DWH_GainDaily → BI_DB_dbo.BI_DB_PI_GainDaily (incremental shadow cache)
  → #GainDaily → #YTD (YTD/QTD/MTD/monthly/daily gains)
  → #positive_months → #positive_months_percent

BI_DB_dbo.BI_DB_PastYearsGain + #YTD
  → #AvgGain0 → #AvgGain (average yearly gain)

BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData → BI_DB_dbo.BI_DB_PI_WeeklyTrades (incremental shadow)
  → #Avg_weekly_trades

BI_DB_dbo.BI_DB_CopyDailyData → #CopyDailyData (PI_Level, TotalEquity, CopyAUM)
BI_DB_dbo.BI_DB_PI_Dashboard + BI_DB_DailyCopyRevenue → #Past_Year_Commission

BI_DB_dbo.DWH_CIDsDailyRisk + External_etoro_Internal_RiskScore
  → #RiskAll → #RiskScore (7-day avg)
  → #MaxAvgRisk12Months (peak monthly risk)
  → #AvgRiskCurrentMonth (current month avg)

External_etoro_Customer_BlockedCustomerOperations + etoroGeneral_History_GuruCopiers
  → #BCO → #BI_DB_Guru_CopiersCID (blocked PI detection)
  |
  |-- SP_PI_Dashboard_COPYDATA_RuningSideBySide @yesterday
  |     DELETE WHERE Date=@yesterday + INSERT (15-way LEFT JOIN)
  v
BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide
  (~3,400 rows/day | 2020-01-01 to 2024-04-14 | 1,501 dates)
  |-- UC Target: _Not_Migrated ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension (CID = RealCID) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| — | — | Terminal dashboard table; no known downstream consumers in SSDT |

---

## 7. Sample Queries

### 7.1 PI Dashboard for a Specific Date

```sql
SELECT CID, UserName, Name, PI_level, Country,
       [PI/CP], Classification, TraderType,
       YTD, MTD, Avg_Yearly_gain,
       Acc_RiskIndex, AUM, Total_Equity, Past_Year_Commission
FROM [BI_DB_dbo].[BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide]
WHERE [Date] = '2024-04-14'
ORDER BY AUM DESC;
```

### 7.2 PI Risk Distribution on Latest Date

```sql
SELECT Acc_RiskIndex, COUNT(*) AS PI_Count,
       AVG(CAST(YTD AS FLOAT)) AS Avg_YTD
FROM [BI_DB_dbo].[BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide]
WHERE [Date] = '2024-04-14'
  AND [PI/CP] = 'PI'
GROUP BY Acc_RiskIndex
ORDER BY Acc_RiskIndex;
```

### 7.3 Classification Distribution Over Time

```sql
SELECT [Date], Classification, COUNT(*) AS PI_Count
FROM [BI_DB_dbo].[BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide]
WHERE [Date] >= '2024-01-01'
  AND [PI/CP] = 'PI'
GROUP BY [Date], Classification
ORDER BY [Date], PI_Count DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode -- Phase 10 skipped).

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 5 T1, 27 T2, 0 T3, 0 T4, 0 T5 | Elements: 32/32, Logic: 9/10, Relationships: 6/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide | Type: Table | Production Source: SP_PI_Dashboard_COPYDATA_RuningSideBySide (multi-source ETL from Dim_Customer, DWH_GainDaily, BI_DB_CopyDailyData, DWH_CIDsDailyRisk)*
