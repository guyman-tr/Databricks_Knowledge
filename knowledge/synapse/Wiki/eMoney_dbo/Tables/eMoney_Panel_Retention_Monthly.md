# eMoney_Panel_Retention_Monthly

**Schema**: eMoney_dbo  |  **Type**: Table  |  **Database**: Synapse DWH

---

## 1. Table Summary

Monthly per-customer eMoney retention analytics panel — the calendar-month roll-up of `eMoney_Panel_Retention_Daily`. Each row represents one eToro customer's eMoney MIMO engagement metrics for a single calendar month, captured as the customer's state on the last available date of that month (end-of-month snapshot).

The table schema is structurally identical to `eMoney_Panel_Retention_Daily` with two key differences: `Report_Date` (date) is replaced by `Report_Month` (int, YYYYMM format), and `Report_Date_ID` (int, YYYYMMDD) is replaced by `Date_for_Report` (date, the actual EOM date from which the row was extracted).

All 84 metric and classification columns — MIMO volumes (Value_*), transaction counts (CNT_*), tier classifications (Amount_Tier_*, TX_Tier_*), seniority measures, club and country identifiers — are identical in definition and semantics to their counterparts in the Daily table. The Monthly table is rebuilt from scratch (TRUNCATE + INSERT) at the end of each SP_eMoney_Panel_Retention run by selecting EOM rows from Daily.

---

## 2. Quick Facts

| Attribute | Value |
|-----------|-------|
| **Rows (total)** | ~27.4 M (as of 2026-04) |
| **Monthly volume** | ~530 K rows per month |
| **Month range** | 202201 → 202604 (YYYYMM) |
| **Grain** | 1 row per (Report_Month, CID) |
| **Distribution** | HASH(CID) |
| **Storage** | HEAP |
| **Writer SP** | SP_eMoney_Panel_Retention |
| **ETL pattern** | TRUNCATE + full rebuild from Daily (post WHILE-loop) |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly` |

---

## 3. Grain & Lifecycle

**Grain**: One row per `(Report_Month, CID)`. The row is the customer's state as recorded in `eMoney_Panel_Retention_Daily` on the end-of-month (EOM) date — i.e., the latest `Report_Date` within each calendar month.

**Rebuild logic**:
1. SP_eMoney_Panel_Retention completes the WHILE-loop populating Daily
2. `#RelDays` temp table computes `EOM_Date = MAX(Report_Date) GROUP BY year*100+month`
3. `TRUNCATE TABLE eMoney_Panel_Retention_Monthly`
4. `INSERT INTO eMoney_Panel_Retention_Monthly SELECT Report_Month=YearMonth, Date_for_Report=Report_Date, [all other columns] FROM eMoney_Panel_Retention_Daily JOIN #RelDays ON Report_Date = EOM_Date`

**Note**: Because EOM_Date is the maximum `Report_Date` in each month's data (not necessarily the last calendar day), the monthly table reflects the most-recently-loaded daily snapshot per month. In the current month (202604 as of 2026-04-11), `Date_for_Report` will be 2026-04-11 (not the calendar EOM).

---

## 4. Column Elements

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | Report_Month | int | Calendar month identifier in YYYYMM format (e.g., 202604). Computed as `year(Report_Date)*100+month(Report_Date)` from the #RelDays temp table in SP_eMoney_Panel_Retention. (Tier 2 — SP_eMoney_Panel_Retention) |
| 2 | Date_for_Report | date | The actual date from which the row was extracted; the end-of-month (EOM) snapshot date, i.e., `MAX(Report_Date)` within the Report_Month in eMoney_Panel_Retention_Daily. For completed months this is the last day of the month present in Daily; for the current month it is the latest loaded date. Passthrough from eMoney_Panel_Retention_Daily.Report_Date. (Tier 2 — SP_eMoney_Panel_Retention) |
| 3 | GCID | int | Global Customer ID; the eToro platform master customer identifier. Passthrough from eMoney_Panel_Retention_Daily. See Daily wiki for full description. (Tier 2 — SP_eMoney_Panel_Retention) |
| 4 | CID | int | Customer ID; primary eToro customer identifier. Distribution key (HASH). Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 5 | ClubID | int | eToro Club tier numeric ID from DWH_dbo.Dim_PlayerLevel. 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond. Reflects the customer's club status on Date_for_Report. Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 6 | Club | nvarchar(50) | Club tier display name. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 7 | ClubCategory | nvarchar(50) | Coarse club bracket: NoClub (ClubID=1), LowClub (ClubID IN (3,5)), HighClub (ClubID IN (2,6,7)), Internal (ClubID=4). Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 8 | CountryID | int | Customer country of residence numeric ID from DWH_dbo.Dim_Country as of Date_for_Report. Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 9 | Country | nvarchar(50) | Country display name. Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 10 | Seniority_TP_RegDate | int | Days elapsed from eToro trading platform registration date to Date_for_Report. Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 11 | Seniority_TP_FTDDate | int | Days elapsed from first eToro trading deposit (FTD) to Date_for_Report. Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 12 | Seniority_eMoney_AccCreatedDate | int | Days elapsed from eMoney account creation date to Date_for_Report. Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 13 | Seniority_eMoney_FMIDate | int | Days elapsed from first eMoney MIMO action (FMI) to Date_for_Report. Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 14 | Value_TotalActions_LT | int | Lifetime total MIMO transaction volume (USD), all funding types, ActionTypeID IN (7,8). Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 15 | Value_eMoneyActions_LT | int | Lifetime eMoney MIMO volume (USD); FundingTypeID=33. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 16 | Value_OtherActions_LT | int | Lifetime non-eMoney MIMO volume (USD); FundingTypeID<>33. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 17 | Value_TotalActions_3M | int | MIMO volume (USD) in trailing 3-month window, all funding types. As of Date_for_Report (EOM). Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 18 | Value_eMoneyActions_3M | int | eMoney MIMO volume (USD) in trailing 3-month window; FundingTypeID=33. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 19 | Value_OtherActions_3M | int | Non-eMoney MIMO volume (USD) in trailing 3-month window; FundingTypeID<>33. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 20 | Value_TotalActions_3M_CO | int | Cancellation/withdrawal volume (USD) in trailing 3-month window, all funding types, ActionTypeID=8. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 21 | Value_eMoneyActions_3M_CO | int | eMoney cancellation/withdrawal volume (USD) in trailing 3-month window. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 22 | Value_OtherActions_3M_CO | int | Non-eMoney cancellation/withdrawal volume (USD) in trailing 3-month window. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 23 | Value_TotalActions_3M_Deposits | int | Deposit volume (USD) in trailing 3-month window, all funding types, ActionTypeID=7. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 24 | Value_eMoneyActions_3M_Deposits | int | eMoney deposit volume (USD) in trailing 3-month window. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 25 | Value_OtherActions_3M_Deposits | int | Non-eMoney deposit volume (USD) in trailing 3-month window. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 26 | Value_TotalActions_LT_CO | int | Lifetime total cancellation/withdrawal volume (USD), all funding types. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 27 | Value_eMoneyActions_LT_CO | int | Lifetime eMoney cancellation/withdrawal volume (USD). Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 28 | Value_OtherActions_LT_CO | int | Lifetime non-eMoney cancellation/withdrawal volume (USD). Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 29 | Value_TotalActions_LT_Deposits | int | Lifetime total deposit volume (USD), all funding types. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 30 | Value_eMoneyActions_LT_Deposits | int | Lifetime eMoney deposit volume (USD). Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 31 | Value_OtherActions_LT_Deposits | int | Lifetime non-eMoney deposit volume (USD). Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 32 | CNT_TotalActions_LT | int | Lifetime total MIMO transaction count, all funding types, ActionTypeID IN (7,8). Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 33 | CNT_eMoneyActions_LT | int | Lifetime eMoney MIMO transaction count; FundingTypeID=33. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 34 | CNT_OtherActions_LT | int | Lifetime non-eMoney MIMO transaction count; FundingTypeID<>33. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 35 | CNT_TotalActions_3M | int | MIMO transaction count in trailing 3-month window, all funding types. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 36 | CNT_eMoneyActions_3M | int | eMoney MIMO count in trailing 3-month window; FundingTypeID=33. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 37 | CNT_OtherActions_3M | int | Non-eMoney MIMO count in trailing 3-month window; FundingTypeID<>33. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 38 | CNT_TotalActions_3M_CO | int | Cancellation/withdrawal count in trailing 3-month window, all funding types. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 39 | CNT_eMoneyActions_3M_CO | int | eMoney cancellation/withdrawal count in trailing 3-month window. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 40 | CNT_OtherActions_3M_CO | int | Non-eMoney cancellation/withdrawal count in trailing 3-month window. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 41 | CNT_TotalActions_3M_Deposits | int | Deposit count in trailing 3-month window, all funding types. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 42 | CNT_eMoneyActions_3M_Deposits | int | eMoney deposit count in trailing 3-month window. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 43 | CNT_OtherActions_3M_Deposits | int | Non-eMoney deposit count in trailing 3-month window. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 44 | CNT_TotalActions_LT_CO | int | Lifetime total cancellation/withdrawal count, all funding types. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 45 | CNT_eMoneyActions_LT_CO | int | Lifetime eMoney cancellation/withdrawal count. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 46 | CNT_OtherActions_LT_CO | int | Lifetime non-eMoney cancellation/withdrawal count. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 47 | CNT_TotalActions_LT_Deposits | int | Lifetime total deposit count, all funding types. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 48 | CNT_eMoneyActions_LT_Deposits | int | Lifetime eMoney deposit count. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 49 | CNT_OtherActions_LT_Deposits | int | Lifetime non-eMoney deposit count. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 50 | Amount_Tier_LT | nvarchar(50) | Lifetime eMoney activity tier by transaction volume. eMoney_Inactive (eMoneyActions_LT=0), Low_Active (eMoney share ≤ 80%), High_Active (eMoney share > 80%). Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 51 | Amount_Tier_3M | nvarchar(50) | Trailing 3-month eMoney tier by volume. Values: eMoney_Inactive, Low_Active, High_Active, No_MIMO_3M. Passthrough from Daily as of EOM date. (Tier 2 — SP_eMoney_Panel_Retention) |
| 52 | TX_Tier_LT | nvarchar(50) | Lifetime eMoney tier by transaction count. Same logic as Amount_Tier_LT on CNT columns. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 53 | TX_Tier_3M | nvarchar(50) | Trailing 3-month eMoney tier by count. Values: eMoney_Inactive, Low_Active, High_Active, No_MIMO_3M. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 54 | Amount_Tier_LT_Deposits | nvarchar(50) | Lifetime eMoney tier by deposit-only volume. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 55 | Amount_Tier_3M_Deposits | nvarchar(50) | Trailing 3-month eMoney tier by deposit volume; adds No_MIMO_3M. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 56 | TX_Tier_LT_Deposits | nvarchar(50) | Lifetime eMoney tier by deposit count. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 57 | TX_Tier_3M_Deposits | nvarchar(50) | Trailing 3-month eMoney tier by deposit count; adds No_MIMO_3M. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 58 | Amount_Tier_LT_CO | nvarchar(50) | Lifetime eMoney tier by cancellation/withdrawal volume. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 59 | Amount_Tier_3M_CO | nvarchar(50) | Trailing 3-month eMoney tier by CO volume; adds No_MIMO_3M. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 60 | TX_Tier_LT_CO | nvarchar(50) | Lifetime eMoney tier by CO count. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 61 | TX_Tier_3M_CO | nvarchar(50) | Trailing 3-month eMoney tier by CO count; adds No_MIMO_3M. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 62 | Value_TotalActions_Monthly | int | Total MIMO volume (USD) in the calendar month of Report_Month; all funding types. In the Monthly table this captures the full month's activity as of Date_for_Report. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 63 | Value_eMoneyActions_Monthly | int | eMoney MIMO volume (USD) for the calendar month; FundingTypeID=33. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 64 | Value_OtherActions_Monthly | int | Non-eMoney MIMO volume (USD) for the calendar month; FundingTypeID<>33. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 65 | CNT_TotalActions_Monthly | int | Total MIMO transaction count for the calendar month, all funding types. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 66 | CNT_eMoneyActions_Monthly | int | eMoney transaction count for the calendar month; FundingTypeID=33. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 67 | CNT_OtherActions_Monthly | int | Non-eMoney transaction count for the calendar month; FundingTypeID<>33. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 68 | Value_TotalActions_Monthly_Deposits | int | Total deposit volume (USD) for the calendar month; ActionTypeID=7. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 69 | Value_eMoneyActions_Monthly_Deposits | int | eMoney deposit volume (USD) for the calendar month. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 70 | Value_OtherActions_Monthly_Deposits | int | Non-eMoney deposit volume (USD) for the calendar month. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 71 | CNT_TotalActions_Monthly_Deposits | int | Total deposit count for the calendar month. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 72 | CNT_eMoneyActions_Monthly_Deposits | int | eMoney deposit count for the calendar month. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 73 | CNT_OtherActions_Monthly_Deposits | int | Non-eMoney deposit count for the calendar month. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 74 | Value_TotalActions_Monthly_CO | int | Total cancellation/withdrawal volume (USD) for the calendar month; ActionTypeID=8. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 75 | Value_eMoneyActions_Monthly_CO | int | eMoney cancellation/withdrawal volume (USD) for the calendar month. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 76 | Value_OtherActions_Monthly_CO | int | Non-eMoney cancellation/withdrawal volume (USD) for the calendar month. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 77 | CNT_TotalActions_Monthly_CO | int | Total cancellation/withdrawal count for the calendar month. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 78 | CNT_eMoneyActions_Monthly_CO | int | eMoney cancellation/withdrawal count for the calendar month. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 79 | CNT_OtherActions_Monthly_CO | int | Non-eMoney cancellation/withdrawal count for the calendar month. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 80 | Amount_Tier_Monthly | nvarchar(50) | Calendar-month eMoney activity tier by volume. In the Monthly table, this captures the full-month tier as of Date_for_Report (EOM). Values: eMoney_Inactive, Low_Active, High_Active, No_MIMO_Monthly. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 81 | TX_Tier_Monthly | nvarchar(50) | Calendar-month eMoney tier by transaction count. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 82 | Amount_Tier_Monthly_Deposits | nvarchar(50) | Calendar-month eMoney tier by deposit volume; adds No_MIMO_Monthly. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 83 | TX_Tier_Monthly_Deposits | nvarchar(50) | Calendar-month eMoney tier by deposit count. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 84 | Amount_Tier_Monthly_CO | nvarchar(50) | Calendar-month eMoney tier by CO volume; adds No_MIMO_Monthly. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 85 | TX_Tier_Monthly_CO | nvarchar(50) | Calendar-month eMoney tier by CO count. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |
| 86 | UpdateDate | datetime | ETL batch timestamp; set to GETDATE() at SP execution time. Passthrough from Daily. (Tier 2 — SP_eMoney_Panel_Retention) |

---

## 5. Business Logic

All business logic is identical to `eMoney_Panel_Retention_Daily` — see that wiki for full definitions of:
- FundingTypeID=33 (eMoney) vs <>33 (Other) segmentation
- ActionTypeID=7 (Deposit / Deposits sub-scope) vs ActionTypeID=8 (Withdrawal / CO sub-scope)
- Time window definitions (LT, 3M, Monthly)
- Tier thresholds (eMoney_Inactive / Low_Active / High_Active / No_MIMO_*)
- ClubCategory groupings (NoClub / LowClub / HighClub / Internal)
- Seniority column semantics

**Monthly-specific note**: In the Monthly table, the `Value_TotalActions_Monthly` / `CNT_TotalActions_Monthly` (and `_Deposits` / `_CO` variants) represent the **full calendar month's** activity because the EOM row is chosen — i.e., they accumulate from the first day of the month through EOM. This makes Monthly a reliable month-complete aggregate, unlike the mid-month state that these columns would show on any given day in the Daily table.

### EOM Date Semantics

`Date_for_Report` is the `MAX(Report_Date)` within each calendar month in the Daily table. For completed months this is the last day loaded for that month. For the current month in-progress (202604 as of 2026-04-11), it is 2026-04-11, and the monthly metrics reflect partial-month activity.

---

## 6. ETL Orchestration

| Attribute | Detail |
|-----------|--------|
| **Writer SP** | SP_eMoney_Panel_Retention |
| **Pattern** | TRUNCATE + full rebuild (post Daily WHILE-loop) |
| **Source** | eMoney_Panel_Retention_Daily (EOM rows only) |
| **Trigger** | Runs at end of each SP_eMoney_Panel_Retention execution |
| **Frequency** | Same as Daily — nightly |
| **Monthly extension added** | 2022-11-14 |

For full SP context (WHILE-loop, eligibility logic, aggregation steps), see `eMoney_Panel_Retention_Daily` ETL section.

---

## 7. Data Quality

| Check | Observation |
|-------|-------------|
| **Rows per month** | ~530K on average; growing over time as eMoney programme expands |
| **Month range** | 202201 (Jan 2022) → 202604 (Apr 2026 partial) |
| **Current month completeness** | 202604 row reflects data through 2026-04-11 only; will be overwritten on subsequent SP runs |
| **Tier distributions** | Same distributions as the Daily table's EOM snapshot; No_MIMO_Monthly is common (~93%) |
| **No NULLs** | Inherited from Daily; all metric columns are non-NULL for eligible customers |

---

## 8. Usage Notes

- **Primary use case**: Monthly eMoney engagement reporting, trend analysis, and cohort studies requiring a complete-month view.
- **Relationship to Daily**: Derived from `eMoney_Panel_Retention_Daily` at EOM. For mid-month tracking, use the Daily table directly.
- **Current month caveat**: The current month's row (`max Report_Month`) reflects partial-month data; treat with caution for month-to-date vs. full-month comparisons.
- **`Value_TotalActions_Monthly` semantics**: In this table, because the EOM row is selected, these columns represent the customer's full-month activity. In the Daily table on a non-EOM date, they reflect month-to-date activity only.
- **`Date_for_Report` vs `Report_Month`**: Use `Report_Month` (int) for month-level grouping and JOINs to period tables; use `Date_for_Report` (date) when you need the exact snapshot date for joining to other daily-grain tables.
- **No Tier 1 columns**: DWH-native aggregation table derived from Daily; all columns are SP passthrough or computations.
