# eMoney_Panel_Retention_Daily

**Schema**: eMoney_dbo  |  **Type**: Table  |  **Database**: Synapse DWH

---

## 1. Table Summary

Daily per-customer eMoney retention analytics panel. Each row captures one eToro customer's eMoney MIMO (Move-In / Move-Out) engagement metrics for a single calendar day, segmented across three time windows — **Lifetime (LT)**, **trailing 3-month (3M)**, and **current calendar month (Monthly)** — and three action sub-scopes: all MIMO (base), deposits only (Deposits), and withdrawals/cancellations (CO = Cancel-Out).

For each time window × sub-scope combination the table stores two metrics: **Value** (total USD transaction volume) and **CNT** (transaction count), each split by funding type: eMoney (FundingTypeID=33), Other (FundingTypeID≠33), and Total. Twelve derived **tier classification** columns summarise each customer's eMoney engagement intensity using a standardised ratio threshold: `eMoney_Inactive` (zero eMoney volume), `Low_Active` (eMoney share ≤ 80% of total), `High_Active` (eMoney share > 80% of total), and `No_MIMO_3M` / `No_MIMO_Monthly` for customers with no MIMO activity in the rolling window.

The table is the primary daily tracking artifact for the eMoney Retention & Club analytics domain, feeding club-segmented MIMO dashboards and product health reporting for the eMoney card programme.

---

## 2. Quick Facts

| Attribute | Value |
|-----------|-------|
| **Rows (total)** | ~786 M (as of 2026-04-11) |
| **Daily volume** | ~1.3 M rows per day |
| **Date range** | 2022-01-01 → 2026-04-11 |
| **Grain** | 1 row per (Report_Date, CID) |
| **Distribution** | HASH(CID) |
| **Storage** | HEAP |
| **Writer SP** | SP_eMoney_Panel_Retention |
| **ETL pattern** | WHILE loop incremental; watermark = MAX(Report_Date) |
| **Author / Created** | Jan Iablunovskey, 2022-10-27 |
| **Monthly extension** | Added 2022-11-14 (FMI dedup added 2022-12-19) |
| **UC Target** | _Not_Migrated |

---

## 3. Grain & Lifecycle

**Grain**: One row per `(Report_Date, CID)`. A customer appears on a date only if they are in the eligible population: present in `eMoney_Panel_FirstDates` with `FMI_Date IS NOT NULL`, and in `eMoney_Dim_Account` with `IsValidETM=1` and `GCID_Unique_Count=1` (single-account customers only).

**Multi-account dedup**: Customers with multiple eMoney currency balance accounts are deduplicated at the start of each SP run via `#Duplicate1` / `#Duplicate2` temp tables; the account with the earliest `FMI_Date` is kept.

**ETL lifecycle**:
1. WHILE `@ReportDate <= GETDATE()-1` — iterates daily from the watermark forward
2. Per iteration: DELETE rows for that date, then INSERT from `#Final` aggregation
3. The Monthly sibling table (`eMoney_Panel_Retention_Monthly`) is rebuilt from this table at the end of each SP run (EOM rows only)

**Indexes**: HEAP (no clustered index); distribution is HASH(CID) for even customer-level spread.

---

## 4. Column Elements

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | Report_Date | date | The report calendar date. Each row represents eMoney activity metrics for this customer on this date. Loop variable `@ReportDate` in SP_eMoney_Panel_Retention. (Tier 2 — SP_eMoney_Panel_Retention) |
| 2 | Report_Date_ID | int | Integer date surrogate key in YYYYMMDD format (e.g., 20260411). Derived as `CONVERT(int, @ReportDate, 112)`. FK to DWH_dbo.Dim_Date. (Tier 2 — SP_eMoney_Panel_Retention) |
| 3 | GCID | int | Global Customer ID; the eToro platform master customer identifier linking the eMoney currency balance account to the eToro trading account. Sourced from eMoney_Panel_FirstDates via the #Pop eligibility population. (Tier 2 — SP_eMoney_Panel_Retention) |
| 4 | CID | int | Customer ID; primary eToro customer identifier. Distribution key (HASH). Sourced from eMoney_Panel_FirstDates via the #Pop population. (Tier 2 — SP_eMoney_Panel_Retention) |
| 5 | ClubID | int | eToro Club tier numeric ID from DWH_dbo.Dim_PlayerLevel. 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond. Reflects the customer's club status on Report_Date via Fact_SnapshotCustomer. (Tier 2 — SP_eMoney_Panel_Retention) |
| 6 | Club | nvarchar(50) | Club tier display name; denormalised from DWH_dbo.Dim_PlayerLevel. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. (Tier 2 — SP_eMoney_Panel_Retention) |
| 7 | ClubCategory | nvarchar(50) | Coarse club bracket computed in SP_eMoney_Panel_Retention #Final: NoClub (ClubID=1/Bronze), LowClub (ClubID IN (3,5) → Gold/Silver), HighClub (ClubID IN (2,6,7) → Platinum/Platinum Plus/Diamond), Internal (ClubID=4). (Tier 2 — SP_eMoney_Panel_Retention) |
| 8 | CountryID | int | Customer country of residence numeric ID from DWH_dbo.Dim_Country, resolved via Fact_SnapshotCustomer. Reflects the customer's country on Report_Date. (Tier 2 — SP_eMoney_Panel_Retention) |
| 9 | Country | nvarchar(50) | Country display name; denormalised from DWH_dbo.Dim_Country. (Tier 2 — SP_eMoney_Panel_Retention) |
| 10 | Seniority_TP_RegDate | int | Days elapsed from the customer's eToro trading platform registration date to Report_Date. Computed as `DATEDIFF(DAY, TP_Registration_Date, @ReportDate)`. Source: eMoney_Panel_FirstDates.TP_Registration_Date. (Tier 2 — SP_eMoney_Panel_Retention) |
| 11 | Seniority_TP_FTDDate | int | Days elapsed from the customer's first eToro trading platform deposit (FTD) to Report_Date. Computed as `DATEDIFF(DAY, TP_FTD_Date, @ReportDate)`. Source: eMoney_Panel_FirstDates.TP_FTD_Date. (Tier 2 — SP_eMoney_Panel_Retention) |
| 12 | Seniority_eMoney_AccCreatedDate | int | Days elapsed from the eMoney currency balance account creation date to Report_Date. Computed as `DATEDIFF(DAY, CurrencyBalanceCreateDate, @ReportDate)`. Source: eMoney_Dim_Account.CurrencyBalanceCreateDate. (Tier 2 — SP_eMoney_Panel_Retention) |
| 13 | Seniority_eMoney_FMIDate | int | Days elapsed from the customer's First Money In (FMI) eMoney action to Report_Date. FMI = first settled eMoney inbound transaction (TxTypeID IN (5,7)). Computed as `DATEDIFF(DAY, FMI_Date, @ReportDate)`. Source: eMoney_Panel_FirstDates.FMI_Date. (Tier 2 — SP_eMoney_Panel_Retention) |
| 14 | Value_TotalActions_LT | int | Lifetime total MIMO transaction volume in USD across all funding types (FundingTypeID=33 eMoney + all other). ActionTypeID IN (7=Deposit, 8=Withdrawal). Sourced from DWH_dbo.Fact_CustomerAction. (Tier 2 — SP_eMoney_Panel_Retention) |
| 15 | Value_eMoneyActions_LT | int | Lifetime eMoney-specific MIMO transaction volume in USD (FundingTypeID=33 only). Sourced from DWH_dbo.Fact_CustomerAction. (Tier 2 — SP_eMoney_Panel_Retention) |
| 16 | Value_OtherActions_LT | int | Lifetime MIMO transaction volume in USD through non-eMoney funding types (FundingTypeID<>33). Sourced from DWH_dbo.Fact_CustomerAction. (Tier 2 — SP_eMoney_Panel_Retention) |
| 17 | Value_TotalActions_3M | int | Total MIMO transaction volume in USD in the trailing 3-month window (DATEADD(MONTH,-3,@ReportDate) to @ReportDate), all funding types. (Tier 2 — SP_eMoney_Panel_Retention) |
| 18 | Value_eMoneyActions_3M | int | eMoney MIMO transaction volume in USD in the trailing 3-month window (FundingTypeID=33). (Tier 2 — SP_eMoney_Panel_Retention) |
| 19 | Value_OtherActions_3M | int | Non-eMoney MIMO transaction volume in USD in the trailing 3-month window (FundingTypeID<>33). (Tier 2 — SP_eMoney_Panel_Retention) |
| 20 | Value_TotalActions_3M_CO | int | Total cancellation/withdrawal (CO) volume in USD in the trailing 3-month window; ActionTypeID=8 (Withdrawal), all funding types. (Tier 2 — SP_eMoney_Panel_Retention) |
| 21 | Value_eMoneyActions_3M_CO | int | eMoney cancellation/withdrawal volume in USD in the trailing 3-month window; FundingTypeID=33, ActionTypeID=8. (Tier 2 — SP_eMoney_Panel_Retention) |
| 22 | Value_OtherActions_3M_CO | int | Non-eMoney cancellation/withdrawal volume in USD in the trailing 3-month window; FundingTypeID<>33, ActionTypeID=8. (Tier 2 — SP_eMoney_Panel_Retention) |
| 23 | Value_TotalActions_3M_Deposits | int | Total deposit volume in USD in the trailing 3-month window; ActionTypeID=7 (Deposit), all funding types. (Tier 2 — SP_eMoney_Panel_Retention) |
| 24 | Value_eMoneyActions_3M_Deposits | int | eMoney deposit volume in USD in the trailing 3-month window; FundingTypeID=33, ActionTypeID=7. (Tier 2 — SP_eMoney_Panel_Retention) |
| 25 | Value_OtherActions_3M_Deposits | int | Non-eMoney deposit volume in USD in the trailing 3-month window; FundingTypeID<>33, ActionTypeID=7. (Tier 2 — SP_eMoney_Panel_Retention) |
| 26 | Value_TotalActions_LT_CO | int | Lifetime total cancellation/withdrawal volume in USD; ActionTypeID=8, all funding types. (Tier 2 — SP_eMoney_Panel_Retention) |
| 27 | Value_eMoneyActions_LT_CO | int | Lifetime eMoney cancellation/withdrawal volume in USD; FundingTypeID=33, ActionTypeID=8. (Tier 2 — SP_eMoney_Panel_Retention) |
| 28 | Value_OtherActions_LT_CO | int | Lifetime non-eMoney cancellation/withdrawal volume in USD; FundingTypeID<>33, ActionTypeID=8. (Tier 2 — SP_eMoney_Panel_Retention) |
| 29 | Value_TotalActions_LT_Deposits | int | Lifetime total deposit volume in USD; ActionTypeID=7, all funding types. (Tier 2 — SP_eMoney_Panel_Retention) |
| 30 | Value_eMoneyActions_LT_Deposits | int | Lifetime eMoney deposit volume in USD; FundingTypeID=33, ActionTypeID=7. (Tier 2 — SP_eMoney_Panel_Retention) |
| 31 | Value_OtherActions_LT_Deposits | int | Lifetime non-eMoney deposit volume in USD; FundingTypeID<>33, ActionTypeID=7. (Tier 2 — SP_eMoney_Panel_Retention) |
| 32 | CNT_TotalActions_LT | int | Lifetime total MIMO transaction count across all funding types; ActionTypeID IN (7,8). (Tier 2 — SP_eMoney_Panel_Retention) |
| 33 | CNT_eMoneyActions_LT | int | Lifetime eMoney MIMO transaction count; FundingTypeID=33, ActionTypeID IN (7,8). (Tier 2 — SP_eMoney_Panel_Retention) |
| 34 | CNT_OtherActions_LT | int | Lifetime non-eMoney MIMO transaction count; FundingTypeID<>33, ActionTypeID IN (7,8). (Tier 2 — SP_eMoney_Panel_Retention) |
| 35 | CNT_TotalActions_3M | int | Total MIMO transaction count in the trailing 3-month window, all funding types. (Tier 2 — SP_eMoney_Panel_Retention) |
| 36 | CNT_eMoneyActions_3M | int | eMoney MIMO transaction count in the trailing 3-month window; FundingTypeID=33. (Tier 2 — SP_eMoney_Panel_Retention) |
| 37 | CNT_OtherActions_3M | int | Non-eMoney MIMO transaction count in the trailing 3-month window; FundingTypeID<>33. (Tier 2 — SP_eMoney_Panel_Retention) |
| 38 | CNT_TotalActions_3M_CO | int | Total cancellation/withdrawal count in the trailing 3-month window; ActionTypeID=8, all funding types. (Tier 2 — SP_eMoney_Panel_Retention) |
| 39 | CNT_eMoneyActions_3M_CO | int | eMoney cancellation/withdrawal count in the trailing 3-month window; FundingTypeID=33, ActionTypeID=8. (Tier 2 — SP_eMoney_Panel_Retention) |
| 40 | CNT_OtherActions_3M_CO | int | Non-eMoney cancellation/withdrawal count in the trailing 3-month window; FundingTypeID<>33, ActionTypeID=8. (Tier 2 — SP_eMoney_Panel_Retention) |
| 41 | CNT_TotalActions_3M_Deposits | int | Total deposit count in the trailing 3-month window; ActionTypeID=7, all funding types. (Tier 2 — SP_eMoney_Panel_Retention) |
| 42 | CNT_eMoneyActions_3M_Deposits | int | eMoney deposit count in the trailing 3-month window; FundingTypeID=33, ActionTypeID=7. (Tier 2 — SP_eMoney_Panel_Retention) |
| 43 | CNT_OtherActions_3M_Deposits | int | Non-eMoney deposit count in the trailing 3-month window; FundingTypeID<>33, ActionTypeID=7. (Tier 2 — SP_eMoney_Panel_Retention) |
| 44 | CNT_TotalActions_LT_CO | int | Lifetime total cancellation/withdrawal count; ActionTypeID=8, all funding types. (Tier 2 — SP_eMoney_Panel_Retention) |
| 45 | CNT_eMoneyActions_LT_CO | int | Lifetime eMoney cancellation/withdrawal count; FundingTypeID=33, ActionTypeID=8. (Tier 2 — SP_eMoney_Panel_Retention) |
| 46 | CNT_OtherActions_LT_CO | int | Lifetime non-eMoney cancellation/withdrawal count; FundingTypeID<>33, ActionTypeID=8. (Tier 2 — SP_eMoney_Panel_Retention) |
| 47 | CNT_TotalActions_LT_Deposits | int | Lifetime total deposit count; ActionTypeID=7, all funding types. (Tier 2 — SP_eMoney_Panel_Retention) |
| 48 | CNT_eMoneyActions_LT_Deposits | int | Lifetime eMoney deposit count; FundingTypeID=33, ActionTypeID=7. (Tier 2 — SP_eMoney_Panel_Retention) |
| 49 | CNT_OtherActions_LT_Deposits | int | Lifetime non-eMoney deposit count; FundingTypeID<>33, ActionTypeID=7. (Tier 2 — SP_eMoney_Panel_Retention) |
| 50 | Amount_Tier_LT | nvarchar(50) | Lifetime eMoney activity tier by transaction volume. Computed from the ratio of eMoney to total MIMO volume: `eMoney_Inactive` if Value_eMoneyActions_LT=0; `Low_Active` if eMoney share ≤ 80% of total; `High_Active` if eMoney share > 80% of total. (Tier 2 — SP_eMoney_Panel_Retention) |
| 51 | Amount_Tier_3M | nvarchar(50) | Trailing 3-month eMoney activity tier by transaction volume. Same thresholds as Amount_Tier_LT with an additional value: `No_MIMO_3M` when total MIMO volume in the 3M window is NULL/zero. (Tier 2 — SP_eMoney_Panel_Retention) |
| 52 | TX_Tier_LT | nvarchar(50) | Lifetime eMoney activity tier by transaction count. Same tier logic as Amount_Tier_LT applied to CNT columns (CNT_eMoneyActions_LT / CNT_TotalActions_LT ratio). Values: eMoney_Inactive, Low_Active, High_Active. (Tier 2 — SP_eMoney_Panel_Retention) |
| 53 | TX_Tier_3M | nvarchar(50) | Trailing 3-month eMoney activity tier by transaction count. Same logic as Amount_Tier_3M on CNT columns. Values: eMoney_Inactive, Low_Active, High_Active, No_MIMO_3M. (Tier 2 — SP_eMoney_Panel_Retention) |
| 54 | Amount_Tier_LT_Deposits | nvarchar(50) | Lifetime eMoney tier by deposit-only transaction volume (Value_eMoneyActions_LT_Deposits / Value_TotalActions_LT_Deposits ratio). Same thresholds as Amount_Tier_LT. (Tier 2 — SP_eMoney_Panel_Retention) |
| 55 | Amount_Tier_3M_Deposits | nvarchar(50) | Trailing 3-month eMoney tier by deposit volume. Adds `No_MIMO_3M` for no deposit activity in the 3M window. (Tier 2 — SP_eMoney_Panel_Retention) |
| 56 | TX_Tier_LT_Deposits | nvarchar(50) | Lifetime eMoney tier by deposit transaction count (CNT_eMoneyActions_LT_Deposits / CNT_TotalActions_LT_Deposits ratio). (Tier 2 — SP_eMoney_Panel_Retention) |
| 57 | TX_Tier_3M_Deposits | nvarchar(50) | Trailing 3-month eMoney tier by deposit transaction count. Adds `No_MIMO_3M` for no deposit count in 3M window. (Tier 2 — SP_eMoney_Panel_Retention) |
| 58 | Amount_Tier_LT_CO | nvarchar(50) | Lifetime eMoney tier by cancellation/withdrawal volume (Value_eMoneyActions_LT_CO / Value_TotalActions_LT_CO ratio). Same thresholds. (Tier 2 — SP_eMoney_Panel_Retention) |
| 59 | Amount_Tier_3M_CO | nvarchar(50) | Trailing 3-month eMoney tier by cancellation/withdrawal volume. Adds `No_MIMO_3M` for no CO activity in 3M window. (Tier 2 — SP_eMoney_Panel_Retention) |
| 60 | TX_Tier_LT_CO | nvarchar(50) | Lifetime eMoney tier by cancellation/withdrawal count (CNT_eMoneyActions_LT_CO / CNT_TotalActions_LT_CO ratio). (Tier 2 — SP_eMoney_Panel_Retention) |
| 61 | TX_Tier_3M_CO | nvarchar(50) | Trailing 3-month eMoney tier by cancellation/withdrawal count. Adds `No_MIMO_3M` for no CO count in 3M window. (Tier 2 — SP_eMoney_Panel_Retention) |
| 62 | Value_TotalActions_Monthly | int | Total MIMO transaction volume in USD in the current calendar month (month of Report_Date), all funding types, ActionTypeID IN (7,8). (Tier 2 — SP_eMoney_Panel_Retention) |
| 63 | Value_eMoneyActions_Monthly | int | eMoney MIMO transaction volume in USD in the current calendar month; FundingTypeID=33. (Tier 2 — SP_eMoney_Panel_Retention) |
| 64 | Value_OtherActions_Monthly | int | Non-eMoney MIMO transaction volume in USD in the current calendar month; FundingTypeID<>33. (Tier 2 — SP_eMoney_Panel_Retention) |
| 65 | CNT_TotalActions_Monthly | int | Total MIMO transaction count in the current calendar month; all funding types, ActionTypeID IN (7,8). (Tier 2 — SP_eMoney_Panel_Retention) |
| 66 | CNT_eMoneyActions_Monthly | int | eMoney MIMO transaction count in the current calendar month; FundingTypeID=33. (Tier 2 — SP_eMoney_Panel_Retention) |
| 67 | CNT_OtherActions_Monthly | int | Non-eMoney MIMO transaction count in the current calendar month; FundingTypeID<>33. (Tier 2 — SP_eMoney_Panel_Retention) |
| 68 | Value_TotalActions_Monthly_Deposits | int | Total deposit volume in USD in the current calendar month; ActionTypeID=7, all funding types. (Tier 2 — SP_eMoney_Panel_Retention) |
| 69 | Value_eMoneyActions_Monthly_Deposits | int | eMoney deposit volume in USD in the current calendar month; FundingTypeID=33, ActionTypeID=7. (Tier 2 — SP_eMoney_Panel_Retention) |
| 70 | Value_OtherActions_Monthly_Deposits | int | Non-eMoney deposit volume in USD in the current calendar month; FundingTypeID<>33, ActionTypeID=7. (Tier 2 — SP_eMoney_Panel_Retention) |
| 71 | CNT_TotalActions_Monthly_Deposits | int | Total deposit count in the current calendar month; ActionTypeID=7, all funding types. (Tier 2 — SP_eMoney_Panel_Retention) |
| 72 | CNT_eMoneyActions_Monthly_Deposits | int | eMoney deposit count in the current calendar month; FundingTypeID=33, ActionTypeID=7. (Tier 2 — SP_eMoney_Panel_Retention) |
| 73 | CNT_OtherActions_Monthly_Deposits | int | Non-eMoney deposit count in the current calendar month; FundingTypeID<>33, ActionTypeID=7. (Tier 2 — SP_eMoney_Panel_Retention) |
| 74 | Value_TotalActions_Monthly_CO | int | Total cancellation/withdrawal volume in USD in the current calendar month; ActionTypeID=8, all funding types. (Tier 2 — SP_eMoney_Panel_Retention) |
| 75 | Value_eMoneyActions_Monthly_CO | int | eMoney cancellation/withdrawal volume in USD in the current calendar month; FundingTypeID=33, ActionTypeID=8. (Tier 2 — SP_eMoney_Panel_Retention) |
| 76 | Value_OtherActions_Monthly_CO | int | Non-eMoney cancellation/withdrawal volume in USD in the current calendar month; FundingTypeID<>33, ActionTypeID=8. (Tier 2 — SP_eMoney_Panel_Retention) |
| 77 | CNT_TotalActions_Monthly_CO | int | Total cancellation/withdrawal count in the current calendar month; ActionTypeID=8, all funding types. (Tier 2 — SP_eMoney_Panel_Retention) |
| 78 | CNT_eMoneyActions_Monthly_CO | int | eMoney cancellation/withdrawal count in the current calendar month; FundingTypeID=33, ActionTypeID=8. (Tier 2 — SP_eMoney_Panel_Retention) |
| 79 | CNT_OtherActions_Monthly_CO | int | Non-eMoney cancellation/withdrawal count in the current calendar month; FundingTypeID<>33, ActionTypeID=8. (Tier 2 — SP_eMoney_Panel_Retention) |
| 80 | Amount_Tier_Monthly | nvarchar(50) | Current-month eMoney activity tier by transaction volume. Same threshold logic as Amount_Tier_3M. Values: eMoney_Inactive, Low_Active, High_Active, No_MIMO_Monthly (no MIMO volume in current month). (Tier 2 — SP_eMoney_Panel_Retention) |
| 81 | TX_Tier_Monthly | nvarchar(50) | Current-month eMoney activity tier by transaction count. Same logic as Amount_Tier_Monthly on CNT columns. (Tier 2 — SP_eMoney_Panel_Retention) |
| 82 | Amount_Tier_Monthly_Deposits | nvarchar(50) | Current-month eMoney tier by deposit volume. Adds `No_MIMO_Monthly` for no monthly deposit activity. (Tier 2 — SP_eMoney_Panel_Retention) |
| 83 | TX_Tier_Monthly_Deposits | nvarchar(50) | Current-month eMoney tier by deposit transaction count. (Tier 2 — SP_eMoney_Panel_Retention) |
| 84 | Amount_Tier_Monthly_CO | nvarchar(50) | Current-month eMoney tier by cancellation/withdrawal volume. Adds `No_MIMO_Monthly` for no monthly CO activity. (Tier 2 — SP_eMoney_Panel_Retention) |
| 85 | TX_Tier_Monthly_CO | nvarchar(50) | Current-month eMoney tier by cancellation/withdrawal count. (Tier 2 — SP_eMoney_Panel_Retention) |
| 86 | UpdateDate | datetime | ETL batch timestamp; set to GETDATE() at SP execution time. Monotonically increasing per WHILE loop iteration. (Tier 2 — SP_eMoney_Panel_Retention) |

---

## 5. Business Logic

### FundingTypeID Segmentation
The core segmentation axis is `FundingTypeID`: **33 = eMoney** (the eToro card / eMoney programme), **<>33 = Other** (bank transfers, other payment methods). All Value/CNT metric columns exist in triplicate: `Total` (all), `eMoney` (=33), and `Other` (<>33).

### ActionTypeID Scope
- **ActionTypeID=7** = Deposit (money inflow to eToro platform)
- **ActionTypeID=8** = Withdrawal / Cancel-Out (CO — money outflow from eToro platform)
- **Base window** (no suffix): both ActionTypeID 7 and 8 combined
- **_Deposits sub-window**: ActionTypeID=7 only
- **_CO sub-window**: ActionTypeID=8 only (CO = Cancel-Out)

### Time Window Definitions
- **LT (Lifetime)**: All dates from the customer's first transaction to Report_Date (no date lower bound)
- **3M (Trailing 3-Month)**: DATEADD(MONTH,-3,@ReportDate) to @ReportDate
- **Monthly (Current Calendar Month)**: First day of the month containing Report_Date to Report_Date

### Tier Classification Logic
Applied independently per time window and sub-scope (6 Amount_Tier and 6 TX_Tier columns):

```
IF eMoney_volume_in_window = 0          → eMoney_Inactive
ELSE IF total_volume_in_window IS NULL  → No_MIMO_3M / No_MIMO_Monthly  (window-bound tiers only)
ELSE IF eMoney / total ≤ 0.80           → Low_Active
ELSE                                    → High_Active
```

The LT tiers (`Amount_Tier_LT`, `TX_Tier_LT`, `*_LT_*`) cannot produce `No_MIMO_*` values since a customer only enters the panel after their first eMoney action.

### Club Category Groupings
ClubCategory collapses the 6-tier club structure into 3 analytical groups:

| ClubCategory | ClubIDs | Club Names |
|-------------|---------|------------|
| NoClub | 1 | Bronze |
| LowClub | 3, 5 | Gold, Silver |
| HighClub | 2, 6, 7 | Platinum, Platinum Plus, Diamond |
| Internal | 4 | (internal accounts) |

### Seniority Columns
All four Seniority columns measure **days elapsed** from a milestone date to Report_Date. They are always ≥ 0 for eligible customers. `Seniority_TP_FTDDate` may equal `Seniority_TP_RegDate` if the customer deposited on the same day they registered.

---

## 6. ETL Orchestration

| Attribute | Detail |
|-----------|--------|
| **Writer SP** | SP_eMoney_Panel_Retention |
| **Author** | Jan Iablunovskey |
| **Created** | 2022-10-27 |
| **Lines** | 703 |
| **Pattern** | WHILE loop incremental; no input parameter |
| **Watermark** | `SELECT @MaxDate = MAX(Report_Date) FROM eMoney_Panel_Retention_Daily` |
| **Loop condition** | `WHILE @ReportDate <= GETDATE()-1` (processes up to yesterday) |
| **Per iteration** | DELETE WHERE Report_Date = @ReportDate; INSERT from #Final |
| **Downstream write** | At loop end, rebuilds eMoney_Panel_Retention_Monthly via TRUNCATE + INSERT from Daily (EOM rows only) |
| **Monthly extension** | Added 2022-11-14; FMI multi-account dedup added 2022-12-19 |

**SP Processing Steps (summarised)**:
1. Build `#Duplicate1` / `#Duplicate2` — deduplicate customers with multiple eMoney accounts (keep earliest FMI_Date)
2. Build `#Pop` — eligible population: eMoney_Panel_FirstDates (FMI_Date IS NOT NULL) JOIN eMoney_Dim_Account (IsValidETM=1, GCID_Unique_Count=1) JOIN DWH_dbo.Fact_SnapshotCustomer / Dim_Range / Dim_PlayerLevel / Dim_Country
3. Steps 4–13: Build 9 aggregation temp tables for LT/3M/Monthly × Total/Deposits/CO combinations from DWH_dbo.Fact_CustomerAction (FundingTypeID split 33 vs <>33)
4. Step 14: Build `#Final` — JOIN all aggregation tables, compute Seniority columns, derive ClubCategory and all Tier classifications via CASE expressions
5. DELETE + INSERT per @ReportDate

---

## 7. Data Quality

| Check | Observation |
|-------|-------------|
| **NULLs in core columns** | None observed in Report_Date, GCID, CID, Value, CNT columns (2026-04-11 snapshot) |
| **Tier enum completeness** | All nvarchar tier columns are non-NULL for eligible customers |
| **Club coverage** | 6 distinct ClubID values observed (1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond) |
| **ClubID=4 (Internal)** | Present in SP logic but not observed in sample data; rarely populated |
| **LT tier distribution (2026)** | Amount_Tier_LT: High_Active=75%, Low_Active=24%, eMoney_Inactive=1% |
| **3M tier distribution (2026)** | Amount_Tier_3M: No_MIMO_3M=76%, High_Active=14%, eMoney_Inactive=6%, Low_Active=5% |
| **Monthly tier distribution (2026)** | Amount_Tier_Monthly: No_MIMO_Monthly=93%, High_Active=4%, eMoney_Inactive=3%, Low_Active=1% |
| **Single-account filter** | GCID_Unique_Count=1 filter means multi-account holders are excluded from the panel entirely |
| **Population size (latest day)** | ~1.3M eligible customers per day (2026-04-11) |
| **Value_TotalActions_LT=0 edge case** | Some recent customers show 0 LT volume but High_Active tier — likely due to SP CASE defaulting when ratio=0/0 |

---

## 8. Usage Notes

- **Primary use case**: Daily eMoney MIMO engagement tracking for the eToro card programme; feeds Club-segmented retention dashboards and product health KPIs.
- **Sibling table**: `eMoney_Panel_Retention_Monthly` contains the same schema with `Report_Month` (int, YYYYMM) replacing `Report_Date`. The monthly table is rebuilt from this table at the end of each SP run (EOM date rows only).
- **FundingTypeID=33**: All eMoney-specific metrics require this discriminator. Do not aggregate across Total/eMoney/Other for the same transaction — they are not additive (Total = eMoney + Other).
- **CO vs. Withdrawals**: The `_CO` sub-scope (ActionTypeID=8) represents customer-initiated outflows from the platform. CO stands for Cancel-Out in the eMoney card context.
- **Tier columns for segmentation**: Use `Amount_Tier_LT` for long-term engagement classification; `Amount_Tier_3M` for current activity health; `Amount_Tier_Monthly` for month-to-date performance.
- **Multi-account exclusion**: Customers with `GCID_Unique_Count>1` in eMoney_Dim_Account are excluded from this panel. Metrics for such customers are not in this table.
- **No Tier 1 columns**: This is a DWH-native aggregation table; all columns are SP-computed. No upstream production wiki exists.
