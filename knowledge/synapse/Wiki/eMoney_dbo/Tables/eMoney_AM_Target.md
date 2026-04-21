# eMoney_dbo.eMoney_AM_Target

> Daily account-manager-grain eToro Money MIMO (Money-In/Money-Out) performance table. Each row represents one eligible customer on one reporting date, showing the assigned account manager, customer segmentation (club, region, country), and three windows of MIMO action activity: a fixed target period (2023-07-01 to 2023-10-01), a cumulative current period (2023-10-01 to report date), and a daily snapshot. Contains 385M rows spanning 2023-07-01 to 2026-04-11 (~520K eligible customers per day).

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + Fact_CustomerAction (ActionTypeID=7) via SP_eMoney_AM_Target |
| **Refresh** | Daily incremental while-loop (DELETE+INSERT per date); currently suspended (~10 days stale as of 2026-04-21; SP commented out in SP_eMoney_Execute_Group_One) |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`eMoney_AM_Target` is the eToro Money account-manager performance tracking table. Each row represents one **eligible eToro Money customer on a specific reporting date**, paired with their assigned account manager and a set of MIMO (Money-In/Money-Out) action metrics.

The table was designed for the eToro Money Account Manager (AM) team to track:
1. **Which customers** their AMs are responsible for each day (based on `DWH_dbo.Dim_Customer.AccountManagerID`)
2. **How much MIMO activity** those customers generated — split by eToro Money (FundingTypeID=33) vs. other funding types
3. **Progress toward quarterly targets** using fixed target-period windows

The table holds **385,394,399 rows** across **1,016 days** from 2023-07-01 to 2026-04-11. The daily eligible population is approximately **520,000 customers**. Rows are partitioned by `Report_Date_ID`; the `DELETE+INSERT` pattern ensures each date is fully replaced on re-run.

**Eligibility criteria** (from SP): `IsDepositor=1`, `IsValidCustomer=1`, `VerificationLevelID=3`, `PlayerLevelID>1`, `AccountTypeID<>2`, AM is active (`Dim_Manager.IsActive=1`), plus country-level filters (certain countries excluded, eToro Money rollout countries only via `eMoney_Dim_Country_Rollout`).

**Sentinel value**: `Attemp_Last_Date` and `Contacted_Last_Date` are hardcoded to `1900-01-01` — the code that pulled these from BI_DB_UsageTracking_SF was commented out and these columns are currently non-functional.

**Status as of 2026-04-21**: The SP is commented out as SP 13 in `SP_eMoney_Execute_Group_One`. The table was last populated on 2026-04-12 (for Report_Date 2026-04-11) and has not been refreshed for ~10 days. The table may be in the process of being deprecated or is temporarily suspended.

---

## 2. Business Logic

### 2.1 Three MIMO Time Windows

**What**: Each row carries three sets of 6 MIMO columns (count + value × total/eMoney/other), representing three different time windows for the same customer.

**Columns Involved**: `CNT_TotalActions`, `Value_TotalActions`, `CNT_eMoneyActions`, `Value_eMoneyActions`, `CNT_OtherActions`, `Value_OtherActions` (current); same pattern for `_Targets` (target period) and `_Daily` (single-day).

**Rules**:
- **Current period** (`CNT/Value_TotalActions`, `_eMoneyActions`, `_OtherActions`): DateID between 2023-10-01 and `Report_Date` (cumulative from Q4 2023 start to report date)
- **Target period** (`*_Targets`): DateID between 2023-07-01 and 2023-10-01 (fixed Q3 2023 baseline — original target-setting window)
- **Daily** (`*_Daily`): DateID = `Report_Date` only (single-day snapshot)
- All windows filter `Fact_CustomerAction.ActionTypeID = 7` (MIMO action type)
- **eMoney split**: `FundingTypeID = 33` = eToro Money (eTM); all other FundingTypeIDs = OtherActions

### 2.2 Euro/GBP/Non-Euro Currency Classification

**What**: Customers are classified by their operating currency region for eToro Money reporting.

**Columns Involved**: `Euro_Non_Euro`, `Country`, `CountryID`

**Rules**:
- `GBP`: CountryID = 218 (United Kingdom)
- `Non_Euro`: CountryID IN (154, 196, 72, 57, 95) — non-euro European countries (Poland, Sweden, Denmark, Czech Republic, Hungary — exact mapping from SP code)
- `Euro`: all remaining eligible countries
- Distribution on 2026-04-11: Euro 66%, GBP 28%, Non_Euro 5%

### 2.3 Account Manager Assignment

**What**: Each customer is paired with their current account manager at ETL run time (point-in-time snapshot from `Dim_Customer.AccountManagerID`).

**Columns Involved**: `Account_Manager`, `Account_Manager_ID`, `GCID`, `CID`

**Rules**:
- `Account_Manager_ID` = `Dim_Customer.AccountManagerID` — the BackOffice AM ID
- `Account_Manager` = `Dim_Manager.FirstName + ' ' + Dim_Manager.LastName` — full name string
- Only customers with `Dim_Manager.IsActive = 1` are included; unassigned or inactive AMs filter out the customer
- Club distribution on 2026-04-11: Silver 37%, Gold 34%, Platinum 16%, Platinum Plus 11%, Diamond 1%

### 2.4 Contact Dates (Disabled)

**What**: Two contact tracking columns exist but are non-functional.

**Columns Involved**: `Attemp_Last_Date`, `Contacted_Last_Date`

**Rules**:
- Both are hardcoded to `1900-01-01` sentinel
- Original design: `Attemp_Last_Date` = last outbound contact attempt (SF ActionName = 'Contacted__c' or 'Outbound_Email__c'); `Contacted_Last_Date` = last successful contact
- The source query from `BI_DB.dbo.BI_DB_UsageTracking_SF` is commented out in the SP
- These columns should be treated as non-informative until the feature is re-enabled

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) ensures that per-customer aggregations are single-node. The HEAP index avoids ordered scans but means full-table scans are required for any non-GCID filter. With 385M rows, **always filter on `Report_Date` or `Report_Date_ID`** to avoid full-table scans — these columns are not the distribution key so you'll get a broadcast-style shuffle, but date filters are essential for response time.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| AM performance for a specific date | `WHERE Report_Date = 'YYYY-MM-DD'` — returns ~520K rows |
| eMoney MIMO totals by AM for a month | `WHERE Report_Date BETWEEN ... GROUP BY Account_Manager_ID, Account_Manager` |
| Customers with zero eMoney activity | `WHERE Report_Date = 'X' AND CNT_eMoneyActions = 0` |
| Trend of eMoney actions over time | `GROUP BY Report_Date, Account_Manager` on daily values |
| Target attainment (target vs. current) | Compare `Value_TotalActions_Targets` vs. `Value_TotalActions` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_dbo.eMoney_Dim_Account | `eMoney_AM_Target.GCID = eMoney_Dim_Account.GCID AND GCID_Unique_Count=1` | Add eToro Money account details |
| DWH_dbo.Dim_Customer | `eMoney_AM_Target.CID = Dim_Customer.RealCID` | Additional customer attributes |
| DWH_dbo.Dim_Manager | `eMoney_AM_Target.Account_Manager_ID = Dim_Manager.ManagerID` | AM details, team, department |

### 3.4 Gotchas

- **1900-01-01 sentinel**: `Attemp_Last_Date` and `Contacted_Last_Date` are always `1900-01-01` — do not use these columns for contact analysis
- **Stale as of 2026-04-21**: Max date is 2026-04-11; the SP is suspended — verify currency before using for current-state reporting
- **Not customer-grain**: Multiple rows per GCID across dates; use `WHERE Report_Date = <latest>` for current state
- **CountryID hardcoding for Euro_Non_Euro**: The classification uses hardcoded country IDs in SP — if eToro Money expands to new countries, this classification may be stale
- **Target window is fixed**: `*_Targets` always reflects 2023-07-01 to 2023-10-01; this was the Q3 2023 baseline and does not move with the report date

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description sourced verbatim from upstream production database wiki (highest confidence) |
| Tier 2 | Description derived from SP code, DDL, or DWH wiki (high confidence) |
| Tier 3 | Inferred from column name, data pattern, or business context (medium confidence) |
| Tier 4 | Best available knowledge — limited upstream documentation (lower confidence) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Report_Date | date | YES | ETL reporting date. Each row is valid for this calendar date. The while-loop iterates over dates from MAX(Report_Date)+1 to yesterday. (Tier 2 — SP_eMoney_AM_Target) |
| 2 | Report_Date_ID | int | YES | Report date as integer in YYYYMMDD format (e.g., 20260411). Used for date-range filtering without date conversion. CAST(CONVERT(VARCHAR(8), Report_Date, 112) AS INT). (Tier 2 — SP_eMoney_AM_Target) |
| 3 | GCID | int | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 4 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 5 | Country | nvarchar(50) | YES | Country name text from DWH_dbo.Dim_Country.Name at time of ETL run. Reflects current country assignment in Dim_Customer; not a point-in-time snapshot. (Tier 2 — SP_eMoney_AM_Target via Dim_Country) |
| 6 | Region | nvarchar(50) | YES | eToro Money regional grouping from eMoney_Dim_Country_Rollout. Values: UK, German, French, Italian, Spain, North Europe, Australia, Eastern Europe, ROE. (Tier 2 — eMoney_Dim_Country_Rollout) |
| 7 | Euro_Non_Euro | nvarchar(50) | YES | Currency classification bucket. 'GBP' (CountryID=218), 'Non_Euro' (CountryID IN 154,196,72,57,95), 'Euro' (all other eligible countries). (Tier 2 — SP_eMoney_AM_Target) |
| 8 | Club | nvarchar(50) | YES | eToro loyalty club tier name from DWH_dbo.Dim_PlayerLevel.Name. Values: Silver, Gold, Platinum, Platinum Plus, Diamond. (Tier 2 — SP_eMoney_AM_Target via Dim_PlayerLevel) |
| 9 | Account_Manager | nvarchar(150) | YES | Full name of the assigned account manager (Dim_Manager.FirstName + ' ' + Dim_Manager.LastName). Current assignment at ETL run time; historical rows reflect the AM assigned on that date. (Tier 2 — SP_eMoney_AM_Target via Dim_Manager) |
| 10 | Account_Manager_ID | int | YES | Currently assigned BackOffice sales/service agent ID (Dim_Customer.AccountManagerID, renamed from ManagerID). FK to BackOffice.Manager. Only active AMs are included (Dim_Manager.IsActive=1). (Tier 2 — SP_eMoney_AM_Target via Dim_Customer) |
| 11 | Attemp_Last_Date | date | YES | **DISABLED** — Last date an AM attempted contact (outbound email or call). Currently hardcoded to 1900-01-01 sentinel. Contact tracking code is commented out in the SP and this column carries no real data. (Tier 2 — SP_eMoney_AM_Target) |
| 12 | Contacted_Last_Date | date | YES | **DISABLED** — Last date a customer was successfully contacted (phone call or email completion in Salesforce). Currently hardcoded to 1900-01-01 sentinel. (Tier 2 — SP_eMoney_AM_Target) |
| 13 | Value_TotalActions | int | YES | Sum of MIMO transaction amounts (USD) for all funding types (ActionTypeID=7) in the cumulative current period (2023-10-01 to Report_Date). NULL → 0 via ISNULL. (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 14 | Value_eMoneyActions | int | YES | Sum of eToro Money MIMO amounts (FundingTypeID=33, ActionTypeID=7) in the cumulative current period. This is the primary eTM contribution metric for the AM team. (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 15 | Value_OtherActions | int | YES | Sum of non-eToro-Money MIMO amounts (FundingTypeID≠33, ActionTypeID=7) in the cumulative current period. Residual = TotalActions - eMoneyActions. (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 16 | CNT_TotalActions | int | YES | Count of all MIMO actions (ActionTypeID=7) for all funding types in the cumulative current period (2023-10-01 to Report_Date). (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 17 | CNT_eMoneyActions | int | YES | Count of eToro Money MIMO actions (FundingTypeID=33, ActionTypeID=7) in the cumulative current period. Key KPI for AM eTM promotion activities. (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 18 | CNT_OtherActions | int | YES | Count of non-eToro-Money MIMO actions (FundingTypeID≠33, ActionTypeID=7) in the cumulative current period. (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 19 | Value_TotalActions_Targets | int | YES | Sum of all MIMO amounts in the fixed target period (2023-07-01 to 2023-10-01). Baseline for quarterly target setting. (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 20 | Value_eMoneyActions_Targets | int | YES | Sum of eToro Money MIMO amounts in the fixed target period (2023-07-01 to 2023-10-01). Used as eTM target baseline. (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 21 | Value_OtherActions_Targets | int | YES | Sum of non-eToro-Money MIMO amounts in the fixed target period. (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 22 | CNT_TotalActions_Targets | int | YES | Count of all MIMO actions in the fixed target period (2023-07-01 to 2023-10-01). (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 23 | CNT_eMoneyActions_Targets | int | YES | Count of eToro Money MIMO actions in the fixed target period. (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 24 | CNT_OtherActions_Targets | int | YES | Count of non-eToro-Money MIMO actions in the fixed target period. (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 25 | Value_TotalActions_Daily | int | YES | Sum of all MIMO amounts on Report_Date only (single-day window). Used for daily performance monitoring. (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 26 | Value_eMoneyActions_Daily | int | YES | Sum of eToro Money MIMO amounts on Report_Date only. (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 27 | Value_OtherActions_Daily | int | YES | Sum of non-eToro-Money MIMO amounts on Report_Date only. (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 28 | CNT_TotalActions_Daily | int | YES | Count of all MIMO actions on Report_Date only. (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 29 | CNT_eMoneyActions_Daily | int | YES | Count of eToro Money MIMO actions on Report_Date only. (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 30 | CNT_OtherActions_Daily | int | YES | Count of non-eToro-Money MIMO actions on Report_Date only. (Tier 2 — SP_eMoney_AM_Target via Fact_CustomerAction) |
| 31 | UpdateDate | datetime | YES | ETL run timestamp (GETDATE() at time of SP execution). All rows for a given report date share the same UpdateDate. (Tier 2 — SP_eMoney_AM_Target) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| GCID | DWH_dbo.Dim_Customer | GCID | Passthrough |
| CID | DWH_dbo.Dim_Customer | RealCID | Rename |
| Country | DWH_dbo.Dim_Country | Name | Passthrough |
| Region | eMoney_dbo.eMoney_Dim_Country_Rollout | Region | Passthrough |
| Euro_Non_Euro | SP logic | Dim_Customer.CountryID | CASE expression (hardcoded country IDs) |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Passthrough |
| Account_Manager | DWH_dbo.Dim_Manager | FirstName + LastName | String concat |
| Account_Manager_ID | DWH_dbo.Dim_Customer | AccountManagerID | Passthrough |
| Attemp_Last_Date | Hardcoded | — | '1900-01-01' sentinel (feature disabled) |
| Contacted_Last_Date | Hardcoded | — | '1900-01-01' sentinel (feature disabled) |
| Value/CNT_*Actions | DWH_dbo.Fact_CustomerAction | Amount / HistoryID | SUM/COUNT per time window and FundingTypeID |
| Report_Date | SP while-loop | @ReportDate | Loop variable |
| Report_Date_ID | SP while-loop | @ReportDate | CAST(CONVERT VARCHAR(8) 112 AS INT) |
| UpdateDate | SP | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (GCID, RealCID→CID, AccountManagerID)
  + DWH_dbo.Dim_Country (Country name)
  + DWH_dbo.Dim_PlayerLevel (Club name)
  + DWH_dbo.Dim_Manager (Account_Manager full name)
  + eMoney_dbo.eMoney_Dim_Country_Rollout (Region filter)
  + DWH_dbo.Fact_CustomerAction (ActionTypeID=7, FundingTypeID=33 split)
    |
    |-- SP_eMoney_AM_Target (daily while-loop, DELETE+INSERT per date) ---|
    |   Orchestrated via: SP_eMoney_Execute_Group_One (SP 13)             |
    |   STATUS: Currently commented out — table stale since 2026-04-12    |
    v
eMoney_dbo.eMoney_AM_Target
  (385M rows, 2023-07-01 to 2026-04-11, ~520K rows/day)
    |
    |-- UC Gold: _Not_Migrated ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | DWH_dbo.Dim_Customer.GCID | Customer lookup (via ETL); GCID is distribution key |
| CID | DWH_dbo.Dim_Customer.RealCID | Customer CID (RealCID at ETL time) |
| Account_Manager_ID | DWH_dbo.Dim_Manager.ManagerID | Account manager details |
| Country | DWH_dbo.Dim_Country.Name | Country name (via ETL) |
| Club | DWH_dbo.Dim_PlayerLevel.Name | Player club tier (via ETL) |
| Region | eMoney_dbo.eMoney_Dim_Country_Rollout.Region | eTM region grouping (via ETL) |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers documented in existing wikis. This table is primarily a reporting layer for the AM team BI dashboards.

---

## 7. Sample Queries

### Daily AM Performance Summary (Latest Available Date)

```sql
SELECT Account_Manager,
       Account_Manager_ID,
       COUNT(*) AS customer_count,
       SUM(CNT_eMoneyActions_Daily) AS daily_etm_actions,
       SUM(Value_eMoneyActions_Daily) AS daily_etm_value_usd,
       SUM(CNT_OtherActions_Daily) AS daily_other_actions
FROM [eMoney_dbo].[eMoney_AM_Target]
WHERE Report_Date = '2026-04-11'
GROUP BY Account_Manager, Account_Manager_ID
ORDER BY daily_etm_value_usd DESC;
```

### eTM vs Other MIMO Split by Region (Cumulative Current Period)

```sql
SELECT Region,
       Euro_Non_Euro,
       SUM(Value_TotalActions) AS total_mimo_value,
       SUM(Value_eMoneyActions) AS etm_value,
       SUM(Value_OtherActions) AS other_value,
       ROUND(100.0 * SUM(Value_eMoneyActions) / NULLIF(SUM(Value_TotalActions), 0), 1) AS etm_pct
FROM [eMoney_dbo].[eMoney_AM_Target]
WHERE Report_Date = '2026-04-11'
GROUP BY Region, Euro_Non_Euro
ORDER BY total_mimo_value DESC;
```

### AM Target Attainment vs Baseline (Q3 2023 Target Period)

```sql
SELECT Account_Manager,
       SUM(Value_TotalActions_Targets) AS baseline_q3_2023,
       SUM(Value_TotalActions) AS current_period,
       ROUND(100.0 * SUM(Value_TotalActions) / NULLIF(SUM(Value_TotalActions_Targets), 0), 1) AS attainment_pct
FROM [eMoney_dbo].[eMoney_AM_Target]
WHERE Report_Date = '2026-04-11'
  AND Value_TotalActions_Targets > 0
GROUP BY Account_Manager
ORDER BY attainment_pct DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for eMoney_AM_Target.

---

*Generated: 2026-04-21 | Quality: 8.8/10 | Phases: 11/14*
*Tiers: 2 T1, 29 T2, 0 T3, 0 T4, 0 T5 | Elements: 31/31, Logic: 4 sections*
*Object: eMoney_dbo.eMoney_AM_Target | Type: Table | Production Source: SP_eMoney_AM_Target (Fact_CustomerAction, Dim_Customer)*
