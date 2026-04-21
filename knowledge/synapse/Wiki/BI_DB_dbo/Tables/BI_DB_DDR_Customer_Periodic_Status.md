# BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status

> 12.7B-row DDR customer periodic pre-aggregation — rolls up the daily customer status into ThisWeek, ThisMonth, ThisQuarter, and ThisYear snapshots for each customer, eliminating expensive on-the-fly aggregations from the DDR dashboard layer.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Dimension — DDR periodic customer status) |
| **Production Source** | Pre-aggregation of `BI_DB_DDR_Customer_Daily_Status` via `SP_DDR_Customer_Periodic_Status` |
| **Refresh** | Daily — `DELETE WHERE DateID = @dateID` + `INSERT` per business date |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_DDR_Customer_Periodic_Status` is a **pre-aggregation table** that rolls up `BI_DB_DDR_Customer_Daily_Status` into four time periods per customer: **ThisWeek**, **ThisMonth**, **ThisQuarter**, and **ThisYear**. Each period contains the same set of 25+ customer status and activity columns.

The table exists because computing period-level aggregations on-the-fly from the 13.3B-row daily table is too expensive for dashboard queries. By pre-computing these aggregations daily, the DDR framework can serve week/month/quarter/year views instantly.

The table was created in July 2024 by Guy Manova. Key changes include IsFunded logic fix (May 2025), Options FTDs (Oct 2025), MoneyFarm support (Nov 2025), and IsFunded changed to last-day-of-period semantics (Nov 2025).

**ETL**: `SP_DDR_Customer_Periodic_Status` runs daily (Priority 100, SB_Daily — runs after Daily Status at P99). Data spans from 2015-01-01 to present with ~12.7B rows across ~6.8M distinct CIDs.

---

## 2. Business Logic

### 2.1 Time Period Boundaries

**What**: Four rolling time windows calculated from `@date`.

**Rules**:
- `WeekStart` = `DATEADD(week, DATEDIFF(ww, 0, @date), -1)` (Sunday)
- `MonthStart` = first of current month
- `QuarterStart` = first of current quarter
- `YearStart` = first of current year

### 2.2 Snapshot Attributes (Latest-Day Semantics)

**What**: Attributes like RegulationID, CountryID, MarketingRegion take the **latest day's value** (rn=1) within each period.

**Columns**: `*RegulationID_ThisX`, `*CountryID_ThisX`, `*MarketingRegion_ThisX`, `*PlayerLevelID_ThisX`, etc.

**Rules**: `MAX(CASE WHEN DateID BETWEEN @periodStart AND @dateInt AND rn = 1 THEN value END)` — rn=1 is the most recent day (ROW_NUMBER DESC by DateID).

### 2.3 Activity Flags (Ever-Happened Semantics)

**What**: Binary flags like ActiveTraded, GlobalDeposited aggregate as "did this happen at least once in the period?"

**Columns**: `*ActiveTraded_ThisX`, `*GlobalDeposited_ThisX`, `*TPFirstDeposited_ThisX`, etc.

**Rules**: `MAX(flag)` across the period — 1 if the event occurred on any day within the period.

### 2.4 IsFunded (Last-Day Semantics)

**What**: Whether the customer is funded. Changed in Nov 2025 from "funded during period" to "funded on the last day of the period."

**Rules**: `MAX(CASE WHEN rn = 1 THEN IsFunded END)` — uses the latest day's funded status rather than any day.

### 2.5 Portfolio_Only and BalanceOnlyAccount (Conditional Hierarchy)

**What**: These follow a waterfall: BalanceOnly requires NOT ActiveTraded AND NOT Portfolio_Only.

**Rules**:
- `Portfolio_Only_ThisX` = COUNT(CASE WHEN Portfolio_Only > 0 AND ActiveTraded = 0)
- `BalanceOnlyAccount_ThisX` = COUNT(CASE WHEN BalanceOnlyAccount > 0 AND ActiveTraded = 0 AND Portfolio_Only = 0)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(RealCID) with CLUSTERED COLUMNSTORE. **Always filter on DateID.** This is a 12.7B-row table — unfiltered queries will be extremely slow.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly active traders | `WHERE DateID = @dateID AND ActiveTraded_ThisMonth > 0` |
| Quarterly FTDs by region | `WHERE DateID = @dateID AND GlobalFirstDeposited_ThisQuarter > 0 GROUP BY MarketingRegion_ThisQuarter` |
| YTD funded customers | `WHERE DateID = @dateID AND IsFunded_ThisYear > 0` |
| Weekly deposit activity | `WHERE DateID = @dateID AND GlobalDeposited_ThisWeek > 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status | RealCID + DateID | Daily detail drill-down |
| BI_DB_dbo.BI_DB_DDR_Fact_AUM | RealCID + DateID | AUM for the customer |
| DWH_dbo.Dim_Customer | RealCID | Extended customer attributes |

### 3.4 Gotchas

- **130 columns**: 25+ columns × 4 periods + 8 boundary columns + 3 core (CID/Date/UpdateDate). Use column pruning.
- **Activity flags are SUM not MAX**: Despite being 0/1 daily, the periodic values represent count-of-days (e.g., ActiveTraded_ThisMonth = 5 means active on 5 days this month). Filter with `> 0` for "ever active."
- **IsFunded is last-day**: After Nov 2025 fix, IsFunded reflects status on the last day of the period, NOT "funded at any point during the period."
- **Portfolio_Only_ThisYear uses ActiveTraded_ThisQuarter** in the WHERE — this appears to be a potential bug in the SP (line 417/418).
- **Date boundaries are rolling**: WeekStart, MonthStart, etc. are computed relative to @date, so querying historical dates shows the boundaries as they were on that date.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — Synapse SP code | (Tier 2 — SP_DDR_Customer_Periodic_Status) |

The table has **130 columns** following a repeating pattern. Below lists the core columns and the pattern template; each `_ThisWeek` column has identical counterparts with suffixes `_ThisMonth`, `_ThisQuarter`, `_ThisYear`.

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Real customer ID. HASH distribution key. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 2 | Date | date | YES | Calendar date — equals parameter `@date`. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 3 | DateID | int | YES | Business date as YYYYMMDD integer. Delete/replace key. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 4 | FirstActionType_ThisWeek | varchar(100) | YES | First trading action type on latest day of the week (rn=1). From Daily_Status.FirstActionType. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 5 | RegulationID_ThisWeek | int | YES | Regulation ID on latest day of the week (rn=1). From Daily_Status.RegulationID. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 6 | IsCreditReportValidCB_ThisWeek | int | YES | Credit report valid on latest day of the week. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 7 | IsValidCustomer_ThisWeek | int | YES | Valid customer on latest day of the week. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 8 | MifidCategorizationID_ThisWeek | int | YES | MiFID categorization on latest day. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 9 | PlayerLevelID_ThisWeek | int | YES | Player level on latest day. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 10 | CountryID_ThisWeek | int | YES | Country ID on latest day. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 11 | MarketingRegion_ThisWeek | varchar(100) | YES | Marketing region on latest day. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 12 | IsFunded_ThisWeek | int | YES | **Funded on the last day of the week (last-day semantics, not any-day).** A customer is Funded if all four criteria held on that final day: (1) real deposit excl. bad-FTD cohort (Aug 18-20 2025); (2) KYC level 3; (3) at least one non-airdrop activity (TP trade, IOB, or Options); AND (4) positive equity across TP/eMoney/Options. Changed Nov 2025 from any-day to last-day. 0 if not funded on final day even if funded earlier in the week. Same pattern applies to _ThisMonth, _ThisQuarter, _ThisYear. Source: Function_Population_Funded. (Tier 1) |
| 13 | FirstTimeFunded_ThisWeek | int | YES | **Count of days in the week on which the customer first crossed the fully-funded threshold** (all four funded criteria met simultaneously for the first time). In practice 0 or 1 for any period since FirstFundedDateID is a permanent once-ever date. SUM across daily rows. Same pattern for _ThisMonth, _ThisQuarter, _ThisYear. Source: Function_Population_First_Time_Funded. (Tier 1) |
| 14 | ActiveTraded_ThisWeek | int | YES | **Count of days in the week on which the customer was a DDR active trader.** SUM (not 0/1) — value > 0 means active at least once. Active = explicitly opened a position (ActionTypeID 1 or 39), opened/added to a copy mirror (ActionTypeID 15=OpenMirror, 17=AddMirror), or placed an Options trade. Auto-created copy positions excluded. Same pattern for _ThisMonth, _ThisQuarter, _ThisYear. Source: Function_Population_Active_Traders. (Tier 1) |
| 15 | Portfolio_Only_ThisWeek | int | YES | **Count of days in the week on which the customer was in the HODL/Portfolio-Only segment.** Held open TP/Options position but placed no active trading actions. COUNT where Portfolio_Only>0 AND ActiveTraded=0 (Active Traders excluded by hierarchy). Value > 0 = HODL at least once. Same pattern for _ThisMonth, _ThisQuarter, _ThisYear. Source: Function_Population_Portfolio_Only. (Tier 1) |
| 16 | BalanceOnlyAccount_ThisWeek | int | YES | **Count of days in the week on which the customer had positive equity across any platform but held no open positions and placed no trading actions.** Cash at eToro with no portfolio. COUNT where BalanceOnlyAccount>0 AND ActiveTraded=0 AND Portfolio_Only=0. Value > 0 = balance-only at least once. Same pattern for _ThisMonth, _ThisQuarter, _ThisYear. Source: Function_Population_Balance_Only_Accounts. (Tier 1) |
| 17 | TPFirstDeposited_ThisWeek | int | YES | TP first deposit occurred this week. SUM(flag). (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 18 | IBANFirstDeposited_ThisWeek | int | YES | IBAN first deposit occurred this week. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 19 | TPExternalFirstDeposited_ThisWeek | int | YES | TP external first deposit this week (excl internal). (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 20 | GlobalFirstDeposited_ThisWeek | int | YES | Global first deposit (any platform) this week. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 21 | GlobalDeposited_ThisWeek | int | YES | Deposited on any platform this week (excl internal). (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 22 | GlobalRedeposited_ThisWeek | int | YES | Redeposited (not FTD, not internal) this week. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 23 | GlobalCashedOut_ThisWeek | int | YES | Withdrew on any platform this week. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 24 | Redeemed_ThisWeek | int | YES | Billing redeem this week. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 25 | DepositedTP_ThisWeek | int | YES | Deposited on TP this week. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 26 | DepositedIBAN_ThisWeek | int | YES | Deposited on IBAN this week. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 27 | ReDepositedTP_ThisWeek | int | YES | Redeposited on TP this week. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 28 | ReDepositedIBAN_ThisWeek | int | YES | Redeposited on IBAN this week. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| — | *_ThisMonth (cols 29-56)* | — | — | *Same pattern as ThisWeek, for month period.* |
| — | *_ThisQuarter (cols 57-84)* | — | — | *Same pattern as ThisWeek, for quarter period.* |
| — | *_ThisYear (cols 85-112)* | — | — | *Same pattern as ThisWeek, for year period.* |
| 113 | UpdateDate | datetime | YES | ETL load timestamp — GETDATE(). (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 114 | WeekStart | date | YES | Week start date (Sunday). Computed from @date. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 115 | MonthStart | date | YES | Month start date (1st). (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 116 | QuarterStart | date | YES | Quarter start date (1st). (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 117 | YearStart | date | YES | Year start date (Jan 1). (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 118 | WeekStartDateID | int | YES | Week start as YYYYMMDD. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 119 | MonthStartDateID | int | YES | Month start as YYYYMMDD. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 120 | QuarterStartDateID | int | YES | Quarter start as YYYYMMDD. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 121 | YearStartDateID | int | YES | Year start as YYYYMMDD. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 122 | OptionsFirstDeposited_ThisWeek | int | YES | Options first deposit this week. Added Oct 2025. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 123 | DepositedOptions_ThisWeek | int | YES | Deposited on Options this week. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| 124 | ReDepositedOptions_ThisWeek | int | YES | Redeposited on Options this week. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| — | *Options _ThisMonth/_ThisQuarter/_ThisYear (cols 125-133)* | — | — | *Same pattern.* |
| 134 | MoneyFarmFirstDeposited_ThisWeek | int | YES | MoneyFarm first deposit this week. Added Nov 2025. (Tier 2 — SP_DDR_Customer_Periodic_Status) |
| — | *MoneyFarm _ThisMonth/_ThisQuarter/_ThisYear (cols 135-137)* | — | — | *Same pattern.* |

---

## 5. Lineage

### 5.1 Production Sources

| Source | Columns | Transform |
|--------|---------|-----------|
| BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status | All 64 daily columns | CTE with ROW_NUMBER (rn=1 for latest), MAX/SUM across 4 time periods |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status (year-start to @dateID)
  |
  └─ CTE DAILY: ROW_NUMBER() OVER (PARTITION BY RealCID ORDER BY DateID DESC) AS rn
       |
       └─ CTE ACTIVETYPEPREP: MAX(CASE WHEN DateID BETWEEN @periodStart AND @dateInt ...)
            for each of: ThisWeek, ThisMonth, ThisQuarter, ThisYear
            |
            └─ Final SELECT with GROUP BY RealCID, Date, DateID, FirstActionType_*, MarketingRegion_*
                 |
                 └─ SP_DDR_Customer_Periodic_Status(@date) [Priority 100, SB_Daily]
                      |-- DELETE WHERE DateID = @dateID
                      |-- INSERT
                      v
                 BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status (12.7B rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension |
| DateID | DWH_dbo.Dim_Date | Calendar dimension |
| RegulationID_* | DWH_dbo.Dim_Regulation | Regulation lookup |
| CountryID_* | DWH_dbo.Dim_Country | Country lookup |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.BI_DB_V_DDR_* views | — | DDR periodic views reference this for week/month/quarter/year aggregations |

---

## 7. Sample Queries

### 7.1 Monthly active traders by regulation

```sql
SELECT RegulationID_ThisMonth, COUNT(*) AS ActiveTraders
FROM BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status
WHERE DateID = 20260309 AND ActiveTraded_ThisMonth > 0
GROUP BY RegulationID_ThisMonth
```

### 7.2 Quarterly FTD count by marketing region

```sql
SELECT MarketingRegion_ThisQuarter,
       SUM(CASE WHEN GlobalFirstDeposited_ThisQuarter > 0 THEN 1 ELSE 0 END) AS FTD_Customers
FROM BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status
WHERE DateID = 20260309
GROUP BY MarketingRegion_ThisQuarter
ORDER BY FTD_Customers DESC
```

### 7.3 YTD funded customers

```sql
SELECT COUNT(*) AS FundedCustomers
FROM BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status
WHERE DateID = 20260309 AND IsFunded_ThisYear > 0
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-26 | Quality: 8.0/10 (★★★★☆) | Phases: 11/14*
*Tiers: 0 T1, 130 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status | Type: Table | Production Source: SP_DDR_Customer_Periodic_Status*
