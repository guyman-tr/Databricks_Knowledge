# BI_DB_dbo.BI_DB_PI_WeeklyTrades

> PI-specific shadow cache of weekly trade counts from BI_DB_CID_WeeklyPanel_FullData, storing one row per active Popular Investor or CopyFund account per calendar week (~4,419 distinct CIDs, ~225 weeks from Dec 2019 to Apr 2024 — estimates; DMV row count unavailable). Maintained incrementally by SP_PI_Dashboard_COPYDATA_RuningSideBySide (sections 4.1 + daily refresh) to compute Avg_weekly_trades for the PI Dashboard. Data stopped refreshing around 2024-04-15.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide` (section 4.1 + daily refresh) from BI_DB_CID_WeeklyPanel_FullData |
| **Refresh** | Daily — new PI backfill (full history) + DELETE WHERE FirstDayOfWeek=@FirstDayOfWeek + INSERT for current week. Stopped ~2024-04-15. |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_PI_WeeklyTrades` is a filtered shadow cache of `BI_DB_CID_WeeklyPanel_FullData` containing weekly new-trade counts for **active Popular Investors (PIs)** and **CopyFund accounts** only. It exists to avoid re-scanning the large WeeklyPanel table (~5.87M CIDs per week) during the daily PI Dashboard computation.

The table holds an estimated ~4,419 distinct CIDs across ~225 distinct weeks, covering 2019-12-29 through 2024-04-14 (row counts estimated from live aggregation queries; DMV access was denied). Each row records the total number of new trades (`NewTrades_Total` from WeeklyPanel, renamed to `NewTrades`) opened by a PI during a given calendar week, identified by `FirstDayOfWeek` (Sunday of the target week).

**ETL pattern**: The SP has two data paths:
1. **New PI backfill** (section 4.1): When a customer first enters the PI population, ALL their historical weekly trade data from `BI_DB_CID_WeeklyPanel_FullData` are copied in (WHERE @yesterday > FirstDayOfWeek).
2. **Daily incremental** (daily refresh): Each day, DELETE rows for the current week's FirstDayOfWeek and INSERT the current week's data from `BI_DB_CID_WeeklyPanel_FullData` for the current PI population.

**Consumer** (section 4.2 of the same SP):
- `Avg_weekly_trades`: AVG(NewTrades) over the last 52 weeks (WHERE FirstDayOfWeek >= DATEADD(YEAR,-1,@yesterday)), producing the `Avg_weekly_trades` column in `BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide`.

**Data stopped refreshing around 2024-04-15**, consistent with the parent dashboard table `BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide`.

---

## 2. Business Logic

### 2.1 PI Population Filter

**What**: Only PI-eligible and CopyFund customers have their weekly trades cached.

**Columns Involved**: `CID`

**Rules**:
- Active Popular Investors: `Dim_Customer.GuruStatusID IN (2,3,4,5,6) AND Dim_Customer.IsValidCustomer = 1`
- CopyFund accounts: `Dim_Customer.AccountTypeID = 9`
- Population is determined from `#pop` temp table built in section 1 of the SP
- GuruStatusID values: 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro

### 2.2 New PI Backfill (Section 4.1)

**What**: When a customer first appears in the PI population, their full weekly trade history is loaded.

**Columns Involved**: All columns

**Rules**:
- SP checks for PIs in `#pop` that have no existing rows in `BI_DB_PI_WeeklyTrades`
- For each new PI, ALL historical weekly rows from `BI_DB_CID_WeeklyPanel_FullData` where `@yesterday > FirstDayOfWeek` are inserted
- This ensures that the `Avg_weekly_trades` metric has full history from day one

### 2.3 Daily Incremental Refresh

**What**: The current week's trade data is refreshed for the entire PI population.

**Columns Involved**: All columns

**Rules**:
- `DELETE FROM BI_DB_PI_WeeklyTrades WHERE @FirstDayOfWeek = FirstDayOfWeek`
- `INSERT` from `BI_DB_CID_WeeklyPanel_FullData` joined to `#pop` on `CID = RealCID` where `@FirstDayOfWeek = FirstDayOfWeek`
- Idempotent: re-running the SP for the same date replaces the current week's data cleanly

### 2.4 Average Weekly Trades Calculation (Consumer)

**What**: SP section 4.2 computes the trailing 52-week average of new trades per PI.

**Columns Involved**: `CID`, `NewTrades`, `FirstDayOfWeek`

**Rules**:
```
Avg_weekly_trades = AVG(NewTrades) WHERE FirstDayOfWeek >= DATEADD(YEAR, -1, @yesterday) GROUP BY CID
```
- This produces the `Avg_weekly_trades` column in `BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide`
- NewTrades=0 weeks are included in the average (PIs with no trades in a given week still have a row)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) distributed — co-located JOINs with other HASH(CID) tables (e.g., BI_DB_CID_WeeklyPanel_FullData). CLUSTERED INDEX on CID supports efficient per-PI lookups. Estimated ~3,220 rows per weekly slice; total table size is modest.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| PI's weekly trade history | `WHERE CID = @cid ORDER BY FirstDayOfWeek DESC` |
| Average trades per week (last year) | `WHERE CID = @cid AND FirstDayOfWeek >= DATEADD(YEAR, -1, @date) → AVG(NewTrades)` |
| Most active PIs in a given week | `WHERE FirstDayOfWeek = @week ORDER BY NewTrades DESC` |
| All PIs with zero trades in a week | `WHERE FirstDayOfWeek = @week AND NewTrades = 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer profile, PI tier, country |
| BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData | CID + FirstDayOfWeek | Cross-reference with full weekly panel data |
| BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide | CID | Parent dashboard table (consumer of AVG(NewTrades)) |

### 3.4 Gotchas

- **Shadow cache, not primary data**: This table is a filtered copy of `BI_DB_CID_WeeklyPanel_FullData`. For non-PI customers, query the WeeklyPanel directly.
- **Data stops at 2024-04-14**: The table has not been refreshed since this date. The parent SP appears to have stopped running.
- **NewTrades is renamed from NewTrades_Total**: Sourced from `NewTrades_Total` in WeeklyPanel, which counts total positions opened across all instrument types during the week.
- **NewTrades=0 rows exist**: PIs with no trades in a given week still have a row. These zeros are included in the AVG calculation for `Avg_weekly_trades`.
- **Population drift**: If a PI loses their status (e.g., demoted to GuruStatusID < 2 or = 7/8), their historical rows remain but no new rows are added.
- **Week1 is SQL Server week number**: Uses SSWeekNumberOfYear (1-53), not ISO week numbering. Week boundaries are Sunday-aligned.
- **HASH(CID) distribution**: JOINs on CID with other HASH(CID) tables are co-located. JOINs on FirstDayOfWeek will trigger data movement.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream wiki verbatim (Dim_Customer, BI_DB_CID_WeeklyPanel_FullData) |
| Tier 2 | ETL-computed (SP_PI_Dashboard_COPYDATA_RuningSideBySide) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Filtered to PI population (GuruStatusID IN 2-6, IsValidCustomer=1) and CopyFund accounts (AccountTypeID=9). HASH distribution key. (Tier 1 — Customer.CustomerStatic) |
| 2 | Week1 | int | YES | SQL Server week-of-year number (1–53) for the target week. From DWH_dbo.Dim_Date.SSWeekNumberOfYear. Renamed from SSWeekNumberOfYear. (Tier 1 — BI_DB_CID_WeeklyPanel_FullData) |
| 3 | Year1 | int | YES | Calendar year of the week (e.g., 2026). From DWH_dbo.Dim_Date.CalendarYear. Renamed from CalendarYear. (Tier 1 — BI_DB_CID_WeeklyPanel_FullData) |
| 4 | NewTrades | int | NO | Total positions opened across all instrument types during the week. SUM. Renamed from NewTrades_Total. Used to compute Avg_weekly_trades in the PI Dashboard via AVG(NewTrades) over the last 52 weeks. (Tier 1 — BI_DB_CID_WeeklyPanel_FullData) |
| 5 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by SP_PI_Dashboard_COPYDATA_RuningSideBySide. Set to GETDATE(). (Tier 2 — SP_PI_Dashboard_COPYDATA_RuningSideBySide) |
| 6 | FirstDayOfWeek | date | YES | Sunday date marking the start of the calendar week. Used as DELETE+INSERT key for daily incremental refresh. Primary grain column alongside CID. (Tier 1 — BI_DB_CID_WeeklyPanel_FullData) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData | CID | Passthrough (filtered to PI/CopyFund population) |
| Week1 | BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData | SSWeekNumberOfYear | Passthrough (rename) |
| Year1 | BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData | CalendarYear | Passthrough (rename) |
| NewTrades | BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData | NewTrades_Total | Passthrough (rename) |
| UpdateDate | — | — | ETL-computed: GETDATE() |
| FirstDayOfWeek | BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData | FirstDayOfWeek | Passthrough |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData (~5.87M CIDs/week, HASH(CID))
DWH_dbo.Dim_Customer + Dim_GuruStatus + Dim_Country + Dim_PlayerStatus
  → #pop (PI/CopyFund population: ~3,400 CIDs)
  |
  |-- SP_PI_Dashboard_COPYDATA_RuningSideBySide section 4.1 + daily refresh
  |   Section 4.1: New PI backfill (INSERT full history for new PIs)
  |   Daily: DELETE WHERE FirstDayOfWeek=@FirstDayOfWeek + INSERT current week
  v
BI_DB_dbo.BI_DB_PI_WeeklyTrades (~4,419 CIDs, ~225 weeks, PI/CopyFund only)
  |
  |-- Same SP section 4.2 (consumer)
  |   → #Avg_weekly_trades: AVG(NewTrades) WHERE FirstDayOfWeek >= @yesterday - 1 year
  v
BI_DB_dbo.BI_DB_PI_Dashboard_COPYDATA_RuningSideBySide.Avg_weekly_trades
  (PI Dashboard — final output)
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
| BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide | Section 4.2 | Consumed to compute Avg_weekly_trades for the PI Dashboard |

---

## 7. Sample Queries

### 7.1 Average weekly trades for a specific PI (last year)

```sql
SELECT CID, AVG(NewTrades * 1.0) AS Avg_Weekly_Trades, COUNT(*) AS Weeks_Tracked
FROM [BI_DB_dbo].[BI_DB_PI_WeeklyTrades]
WHERE CID = 2990627
  AND FirstDayOfWeek >= DATEADD(YEAR, -1, '2024-04-14')
GROUP BY CID;
```

### 7.2 Most active PIs in a given week

```sql
SELECT TOP 20 CID, NewTrades, Week1, Year1
FROM [BI_DB_dbo].[BI_DB_PI_WeeklyTrades]
WHERE FirstDayOfWeek = '2024-04-07'
ORDER BY NewTrades DESC;
```

### 7.3 Weekly trade trend for all PIs

```sql
SELECT FirstDayOfWeek, Year1, Week1,
       COUNT(*) AS PI_Count,
       AVG(NewTrades * 1.0) AS Avg_Trades,
       SUM(NewTrades) AS Total_Trades
FROM [BI_DB_dbo].[BI_DB_PI_WeeklyTrades]
WHERE FirstDayOfWeek >= '2024-01-01'
GROUP BY FirstDayOfWeek, Year1, Week1
ORDER BY FirstDayOfWeek;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — Phase 10 skipped).

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 5 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 6/6, Logic: 8/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_PI_WeeklyTrades | Type: Table | Production Source: SP_PI_Dashboard_COPYDATA_RuningSideBySide (section 4.1 + daily refresh from BI_DB_CID_WeeklyPanel_FullData)*
