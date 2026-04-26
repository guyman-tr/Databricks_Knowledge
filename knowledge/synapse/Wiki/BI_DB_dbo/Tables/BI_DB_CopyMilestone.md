# BI_DB_dbo.BI_DB_CopyMilestone

**Generated**: 2026-04-23  
**Schema**: BI_DB_dbo  
**Object Type**: Table  
**Writer SP**: SP_CopyMilestone  
**Load Pattern**: DELETE WHERE Date=@date + INSERT (append-only historical table)  
**Distribution**: ROUND_ROBIN  
**Index**: CLUSTERED INDEX (CID ASC)  
**Column Count**: 22  
**Row Count**: 5,922,626 (2026-04-11)  
**Date Range**: 2019-08-25 → 2026-04-11 (2,377 distinct dates)  
**Distinct Managers**: 8,225 (CIDs ever tracked)  
**Priority**: 0 (OpsDB)  
**Frequency**: Daily  
**UC Migration**: Not Migrated  

---

## 1. Overview

Daily **milestone tracking table for Popular Investors (PIs) and CopyPortfolio accounts**. Each row represents one active PI or Portfolio manager on a given `Date`, recording binary flags that indicate whether they achieved specific performance milestones on that day.

**Population**: All active PIs/CopyPortfolios appearing in `BI_DB_CopyDailyData` for @date. Every manager gets a row regardless of milestone achievement — the flags default to 0 for non-events.

**Two milestone categories**:

| Category | Columns | Logic |
|---|---|---|
| **Profitability streaks** | Months6InRow, Month12InRow, Year3InRow, Year4InRow, Year5inRow | Consecutive month-end / calendar-year gains from DWH_GainDaily |
| **MTD performance** | Up5Percent30Days, Down5Percent30Days | Current month's Gain_m vs ±5% threshold |
| **Copier growth** | GainMoreThen100Copiers, CopiersGained, PI_Passing_*, CopyPortfolio_Passing_* | Copier count change vs 7 days ago + first-time threshold crossings vs historical high-water mark |

**Load semantics**: `DELETE WHERE @date = Date` then `INSERT` — the table is append-mode history, not a snapshot. Rows for prior dates are never touched (DELETE only removes the current day before re-insert for idempotent re-runs).

**Data observed** (2026-04-11): 3,976 rows — PI: 3,850 (96.8%), Portfolio: 126 (3.2%).

---

## 2. Business Logic

### 2.1 Streak Milestone Calculation

The SP reads `DWH_GainDaily` for each managed CID and calculates monthly profit for the 12 month-end dates before @date, and yearly profit for the 5 calendar year-starts before @date.

**Monthly streak formula**:
- Month-end date N = `DATEADD(DAY, 1, EOMONTH(@date, -N))` — the first day of the prior N-th month (when the period's gain is finalized)
- A month "counts" if `Gain_m > 0` on that date
- `Months6InRow = 1` if all 6 prior consecutive months had `Gain_m > 0` (must be the immediately preceding 6 months, not a moving window)

**Yearly streak formula**:
- Calendar year start N = `DATEADD(yy, DATEDIFF(yy, 0, @date) - N, 0)` — January 1 of year N years ago
- `Gain_y > 0` on that date = profitable that calendar year
- `Year3InRow/4/5` require the most recent N complete calendar years to all be profitable

**MTD flags** — `Up5Percent30Days` / `Down5Percent30Days`: Despite the "30Days" naming, these use `gd.Gain_m` (month-to-date gain, not rolling 30 days) compared against ±5% threshold as of @date.

### 2.2 Copier Milestone Detection (First-Time Threshold Crossing)

The SP computes a **historical high-water mark** per CID from all prior `BI_DB_CopyDailyData` rows (WHERE Date < @date-1). A crossing flag is set to 1 only on the day the current copier count enters a new range AND has never previously been that high.

**PI bands** (exclusive — only one band fires per crossing):
- `PI_Passing_1000_Copiers`: current ∈ (1000, 1500) AND historical max ≤ 1000
- `PI_Passing_1500_Copiers`: current ∈ (1500, 2000) AND historical max ≤ 1500
- `PI_Passing_2000_Copiers`: current ∈ (2000, 2500) AND historical max ≤ 2000
- `PI_Passing_2500_Copiers`: current ∈ (2500, 3000) AND historical max ≤ 2500
- `PI_Passing_3000_Copiers`: current ∈ (3000, 3500) AND historical max ≤ 3000
- `PI_Passing_3500_Copiers`: current ∈ (3500, 4000) AND historical max ≤ 3500
- `PI_Passing_4000_Copiers`: current > 4000 AND historical max ≤ 4000

**Portfolio**: `CopyPortfolio_Passing_1000_Investors`: current > 1000 AND historical max ≤ 1000 (no upper bound).

### 2.3 Column Naming Issues

Two known column name defects in the DDL:
- `Year5inRow` — lowercase 'i' (should be 'InRow'). DDL-authoritative; do not "correct" in queries.
- `GainMoreThen100Copiers` — typo "Then" (should be "Than"). DDL-authoritative.

The nullable `PI_Passing_1500_Copiers`, `PI_Passing_2500_Copiers`, `PI_Passing_3500_Copiers` are later additions (DDL shows NULL, unlike the original NOT NULL thresholds). Treat 0 and NULL as equivalent non-events.

---

## 3. Query Advisory

- **Append-mode table**: Always filter by `Date`. Without a date filter, the query scans all 5.9M rows.
- **Milestone queries**: Filter on the milestone flag = 1 after filtering by Date. Most days, fewer than 5% of rows have any flag set.
- **ROUND_ROBIN distributed**: Joins on CID will trigger data movement. Use `Date` as a selective predicate first.
- **Historical high-water mark**: The crossing flags in this table represent the first-time threshold crossing. A PI that dropped and recovered through 1,000 copiers a second time will NOT re-trigger `PI_Passing_1000_Copiers` (historical max was already > 1,000).
- **Streak interpretation**: `Months6InRow=1` means the 6 immediately preceding month-ends were all profitable — not any rolling 6-month window.

---

## 4. Elements

| Column | Nullable | Type | Description |
|--------|----------|------|-------------|
| CID | NOT NULL | int | Customer ID of the PI or CopyPortfolio manager being tracked (the copied person, not the copier). Customer ID — platform-internal primary key. Assigned at registration. (Tier 1 — BI_DB_dbo.BI_DB_CopyDailyData) |
| UserName | NOT NULL | varchar(200) | Login username of the PI or Portfolio manager. Wider than the standard varchar(20) — CopyPortfolio display names can be longer. (Tier 1 — BI_DB_dbo.BI_DB_CopyDailyData) |
| Date | NOT NULL | date | Reporting date — the business day this row covers (@date parameter). One row per CID per date. (Tier 2 — ETL parameter) |
| Months6InRow | NOT NULL | int | 1 if all 6 immediately preceding month-end gains (Gain_m > 0 from DWH_GainDaily) were positive; 0 otherwise. Streak is contiguous — one negative month resets it. (Tier 2 — DWH_GainDaily via #Profit) |
| Month12InRow | NOT NULL | int | 1 if all 12 immediately preceding month-end gains (Gain_m > 0) were positive; 0 otherwise. Requires unbroken 12-month profitability. (Tier 2 — DWH_GainDaily via #Profit) |
| Year5inRow | NOT NULL | int | 1 if the 5 most recent complete calendar year-starts (Gain_y > 0 on Jan 1 of each year) were all profitable. Column name has intentional lowercase 'i' — DDL-authoritative. (Tier 2 — DWH_GainDaily via #Profit) |
| Year4InRow | NOT NULL | int | 1 if the 4 most recent complete calendar year-starts were all profitable (Gain_y > 0). (Tier 2 — DWH_GainDaily via #Profit) |
| Year3InRow | NOT NULL | int | 1 if the 3 most recent complete calendar year-starts were all profitable (Gain_y > 0). (Tier 2 — DWH_GainDaily via #Profit) |
| Up5Percent30Days | NOT NULL | int | 1 if the PI's month-to-date gain (Gain_m) exceeded +5% on @date. Despite the "30Days" name, this uses the MTD monthly gain metric (Gain_m), not a trailing 30-day return. (Tier 2 — DWH_GainDaily.Gain_m) |
| Down5Percent30Days | NOT NULL | int | 1 if the PI's month-to-date gain (Gain_m) was below -5% on @date. Same MTD-not-30d caveat as Up5Percent30Days. (Tier 2 — DWH_GainDaily.Gain_m) |
| CopyType | NOT NULL | varchar(9) | PI category inherited from BI_DB_CopyDailyData. 'PI' = Popular Investor (GuruStatusID >= 2). 'Portfolio' = CopyPortfolio account (AccountTypeID=9). Observed: PI=96.8%, Portfolio=3.2%. (Tier 1 — BI_DB_dbo.BI_DB_CopyDailyData) |
| CopyPortfolio_Passing_1000_Investors | NOT NULL | int | 1 if this CopyPortfolio's current copier count exceeded 1,000 for the first time today (previous historical maximum was ≤ 1,000). CopyType='Portfolio' only; PIs always 0. (Tier 2 — SP milestone logic via BI_DB_CopyDailyData) |
| PI_Passing_1000_Copiers | NOT NULL | int | 1 if PI's copier count entered the 1,000–1,499 range for the first time (current > 1,000 AND current < 1,500 AND historical max ≤ 1,000). Each band fires at most once per PI lifetime. (Tier 2 — SP milestone logic via BI_DB_CopyDailyData) |
| PI_Passing_2000_Copiers | NOT NULL | int | 1 if PI's copier count entered the 2,000–2,499 range for the first time. (Tier 2 — SP milestone logic via BI_DB_CopyDailyData) |
| PI_Passing_3000_Copiers | NOT NULL | int | 1 if PI's copier count entered the 3,000–3,499 range for the first time. (Tier 2 — SP milestone logic via BI_DB_CopyDailyData) |
| PI_Passing_4000_Copiers | NOT NULL | int | 1 if PI's copier count exceeded 4,000 for the first time (no upper bound). (Tier 2 — SP milestone logic via BI_DB_CopyDailyData) |
| GainMoreThen100Copiers | NOT NULL | int | 1 if net copier gain vs 7 days ago exceeded 100 (CopiersGained > 100). Column name has typo "Then" (should be "Than") — DDL-authoritative. (Tier 2 — BI_DB_CopyDailyData 7-day differential) |
| CopiersGained | NOT NULL | int | Net copier count change: today's NumOfCopiers minus the NumOfCopiers from 7 days prior. Can be negative (net loss of copiers). Null-safe via ISNULL(…, 0) in SP. (Tier 2 — BI_DB_CopyDailyData 7-day differential) |
| UpdateDate | NULL | datetime | ETL metadata: timestamp when this row was inserted by the ETL pipeline (GETDATE() at insert time). (Propagation) |
| PI_Passing_1500_Copiers | NULL | int | 1 if PI's copier count entered the 1,500–1,999 range for the first time. Added after initial release — nullable (treat NULL as 0). (Tier 2 — SP milestone logic via BI_DB_CopyDailyData) |
| PI_Passing_2500_Copiers | NULL | int | 1 if PI's copier count entered the 2,500–2,999 range for the first time. Nullable — treat NULL as 0. (Tier 2 — SP milestone logic via BI_DB_CopyDailyData) |
| PI_Passing_3500_Copiers | NULL | int | 1 if PI's copier count entered the 3,500–3,999 range for the first time. Nullable — treat NULL as 0. (Tier 2 — SP milestone logic via BI_DB_CopyDailyData) |

---

## 5. Lineage Summary

| Source | Columns Derived |
|--------|-----------------|
| BI_DB_dbo.BI_DB_CopyDailyData (Date=@date) | CID, UserName, CopyType (base population) |
| BI_DB_dbo.BI_DB_CopyDailyData (DateID=@date-7d) | CopiersGained, GainMoreThen100Copiers |
| BI_DB_dbo.BI_DB_CopyDailyData (all history) | All PI_Passing_* and CopyPortfolio_Passing_* (high-water mark) |
| BI_DB_dbo.DWH_GainDaily | Months6InRow, Month12InRow, Year3/4/5InRow, Up/Down5Percent30Days |
| ETL metadata | Date (= @date parameter), UpdateDate (= GETDATE()) |

---

## 6. OpsDB Orchestration

| Property | Value |
|---|---|
| OpsDB Priority | 0 (base layer — no intra-schema dependencies) |
| Frequency | Daily |
| Writer SP | SP_CopyMilestone |
| ProcessType | SQL (1) |

---

## 7. Quality Notes

- `Year5inRow` and `GainMoreThen100Copiers` have persistent column name typos in the DDL. These are load-bearing names — do not alias or "correct" in application queries.
- `PI_Passing_1500_Copiers`, `PI_Passing_2500_Copiers`, `PI_Passing_3500_Copiers` are NULL (later additions) while original thresholds are NOT NULL. Use `ISNULL(column, 0)` for consistent treatment.
- `Up5Percent30Days` and `Down5Percent30Days` use `Gain_m` (month-to-date from first of month), not a trailing 30-day return — the column names are misleading.
- A PI that recovers past a threshold after dropping below it does NOT re-trigger the crossing flag (historical high-water mark logic is one-directional).
