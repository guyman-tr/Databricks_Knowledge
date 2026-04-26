# BI_DB_dbo.BI_DB_M_LifeStage_Matrix

> 35,935-row monthly customer life stage transition matrix tracking how many users moved between life stage statuses (Lead, Active Open, Churn, Holder, Win Back, etc.) from one month to the next, segmented by marketing region, from January 2023 to March 2026. Used for customer lifecycle funnel analysis and retention reporting. Refreshed monthly via `SP_M_LifeStage_Matrix` with delete-insert by ToMonthFull.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed from BI_DB_CID_LifeStageDefinition + BI_DB_CIDFirstDates + Dim_Date via `SP_M_LifeStage_Matrix` |
| **Refresh** | Monthly (delete-insert by ToMonthFull >= @ToMonth). Author: Ben Einav, 2024-05-07. OpsDB: SB_Daily, Priority 0 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (ToMonthFull ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table is a **transition matrix** showing how customers move between life stage statuses month-over-month. Each row represents one transition pair (FromStatus → ToStatus) for one Region in one month, with the count of customers (Users) making that transition.

The life stage definitions come from `BI_DB_CID_LifeStageDefinition`, which assigns an LSD (Life Stage Definition) status to each customer based on their activity. The SP consolidates granular LSD values into 11 higher-level statuses using CASE WHEN logic:

- **Lead**: Registered but not yet funded
- **Dump Lead**: Inactive lead (long-term no activity)
- **New FTD**: New first-time depositor (mapped from "New Funded" or "New Depositor Only")
- **Active LogIn**: Logged in but no open positions
- **Active Open**: Has open positions
- **Active Open 30-90**: Consolidated from "Active Open 30-90 ..." variants
- **Active Open Club**: Higher-tier club active
- **Holder**: Has positions but no recent trading activity
- **Win Back**: Previously churned, now returning
- **No Activity**: No recent activity
- **Churn**: Long-term inactive, consolidated from Churn% variants

The table contains 35,935 rows covering 14 regions and 11 statuses over ~38 monthly transitions. The largest transitions are self-loops (e.g., Lead→Lead 223K users, Dump Lead→Dump Lead 966K users).

**Fake registration filter**: Customers registered in March 2024 via Direct SubChannel with first login in April 2024 are excluded to avoid skewing Dump Lead→Lead transitions.

---

## 2. Business Logic

### 2.1 Life Stage Consolidation

**What**: Maps granular LSD values from BI_DB_CID_LifeStageDefinition into 11 reporting-level statuses.
**Columns Involved**: FromStatus, ToStatus
**Rules**:
- `LSD LIKE '%Churn%'` → 'Churn'
- `LSD LIKE '%No Activity%'` → 'No Activity'
- `LSD LIKE '%Holder%'` → 'Holder'
- `LSD LIKE '%Win Back%'` → 'Win Back'
- `LSD LIKE '%Active Open 30-90 %'` → 'Active Open 30-90'
- `LSD IN ('New Funded','New Depositor Only')` → 'New FTD'
- All other LSD values pass through unchanged (Active LogIn, Active Open, Active Open Club, Lead, Dump Lead)

### 2.2 Month-to-Month Transition

**What**: Identifies each customer's status in two consecutive months and counts transitions.
**Columns Involved**: Users, FromMonthFull, ToMonthFull, FromStatus, ToStatus
**Rules**:
- @FromMonth = EOMONTH(@ToMonth - 1 month) — the previous month-end
- For each customer: find LSD at @FromMonth (using DateID range) and at @ToMonth
- GROUP BY Region, FromStatus, ToStatus, both month columns → COUNT(*) = Users

### 2.3 Fake Registration Exclusion

**What**: Removes March 2024 fake registrations that skew transition data.
**Columns Involved**: (filter, not a column)
**Rules**:
- Excludes CIDs from BI_DB_CIDFirstDates where registered >= 2024-03-01 AND < 2024-04-01 AND SubChannel='Direct' AND FirstLoggedIn in April
- LEFT JOIN + IS NULL pattern

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on ToMonthFull ASC. Filter on ToMonthFull for efficient scans of specific months.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many users churned last month? | `SELECT Region, SUM(Users) FROM ... WHERE ToMonthFull = '2026-03-31' AND ToStatus = 'Churn' GROUP BY Region` |
| What's the biggest transition flow for a given month? | `SELECT * FROM ... WHERE ToMonthFull = '2026-03-31' ORDER BY Users DESC` |
| Retention rate (same status month-to-month)? | `SELECT FromStatus, SUM(Users) FROM ... WHERE ToMonthFull = '2026-03-31' AND FromStatus = ToStatus GROUP BY FromStatus` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| BI_DB_dbo.BI_DB_CID_LifeStageDefinition | N/A (aggregated) | Source table — drill down to individual CIDs |
| BI_DB_dbo.BI_DB_CIDFirstDates | N/A (aggregated) | Source of Region mapping |

### 3.4 Gotchas

- **Users is a COUNT, not a CID**: This is an aggregated table — each row represents a group of customers, not an individual
- **Self-loops dominate**: Most customers stay in the same status month-to-month. Lead→Lead and Dump Lead→Dump Lead are the largest rows
- **Fake reg filter is hardcoded**: The March 2024 filter is a one-time exclusion. Future fake registration patterns would need SP modification
- **Year is from FromMonth**: The Year column uses the CalendarYear from the FromMonth's Dim_Date record, not ToMonth. For Dec→Jan transitions, Year will be the previous year
- **11 statuses**: Active LogIn, Active Open, Active Open 30-90, Active Open Club, Churn, Dump Lead, Holder, Lead, New FTD, No Activity, Win Back
- **14 regions**: Arabic, Australia, CEE, French, German, Italian, Latam, Nordics, ROW, SEA, Spain, UK, USA, Unknown

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB docs) | Highest — verified against source system documentation |
| Tier 2 | SP code analysis | High — traced from ETL stored procedure logic |
| Tier 3 | Live data observation | Medium — inferred from data patterns |
| Tier 4 | Contextual inference | Lower — best available knowledge |
| Tier 5 | Standard ETL column | Canonical — well-known ETL metadata pattern |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Users | int | YES | Count of customers who transitioned between FromStatus and ToStatus in the given month and region. Aggregated via COUNT(*) GROUP BY Region, FromStatus, ToStatus, month columns. (Tier 2 — SP_M_LifeStage_Matrix) |
| 2 | Region | nvarchar(50) | YES | Marketing region of the customer, sourced from BI_DB_CIDFirstDates.NewMarketingRegion. 14 values: Arabic, Australia, CEE, French, German, Italian, Latam, Nordics, ROW, SEA, Spain, UK, USA, Unknown. (Tier 2 — SP_M_LifeStage_Matrix) |
| 3 | FromStatus | nvarchar(50) | YES | Customer life stage status at the start of the transition (previous month). Consolidated from BI_DB_CID_LifeStageDefinition.LSD via CASE WHEN logic. 11 values: Active LogIn, Active Open, Active Open 30-90, Active Open Club, Churn, Dump Lead, Holder, Lead, New FTD, No Activity, Win Back. (Tier 2 — SP_M_LifeStage_Matrix) |
| 4 | ToStatus | nvarchar(50) | YES | Customer life stage status at the end of the transition (current month). Same CASE WHEN consolidation as FromStatus. 11 values. (Tier 2 — SP_M_LifeStage_Matrix) |
| 5 | FromMonthFull | date | YES | End-of-month date for the "from" month (previous month). Computed as EOMONTH(DATEADD(MONTH,-1,@ToMonth)). (Tier 2 — SP_M_LifeStage_Matrix) |
| 6 | FromMonth | nvarchar(50) | YES | Abbreviated month name for the "from" month, from Dim_Date.MonthNameAbbreviation (e.g., "Jan", "Feb", "Mar"). (Tier 2 — SP_M_LifeStage_Matrix) |
| 7 | ToMonthFull | date | YES | End-of-month date for the "to" month (current month). This is the SP parameter @Date. Used as the delete-insert key and clustered index column. (Tier 2 — SP_M_LifeStage_Matrix) |
| 8 | ToMonth | nvarchar(50) | YES | Abbreviated month name for the "to" month, from Dim_Date.MonthNameAbbreviation. (Tier 2 — SP_M_LifeStage_Matrix) |
| 9 | Year | int | YES | Calendar year of the "from" month, from Dim_Date.CalendarYear. For Dec→Jan transitions, this is the previous year (from the FromMonth perspective). (Tier 2 — SP_M_LifeStage_Matrix) |
| 10 | UpdateDate | date | YES | ETL metadata: date when this row was inserted. Set to GETDATE() (cast to date by the column type). (Tier 5 — SP_M_LifeStage_Matrix) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Users | (computed) | COUNT(*) | Aggregation |
| Region | BI_DB_dbo.BI_DB_CIDFirstDates | NewMarketingRegion | Passthrough |
| FromStatus | BI_DB_dbo.BI_DB_CID_LifeStageDefinition | LSD | CASE WHEN consolidation at @FromMonth |
| ToStatus | BI_DB_dbo.BI_DB_CID_LifeStageDefinition | LSD | CASE WHEN consolidation at @ToMonth |
| FromMonthFull | (computed) | @FromMonth | EOMONTH(@ToMonth - 1 month) |
| FromMonth | DWH_dbo.Dim_Date | MonthNameAbbreviation | Lookup |
| ToMonthFull | (computed) | @ToMonth | SP parameter |
| ToMonth | DWH_dbo.Dim_Date | MonthNameAbbreviation | Lookup |
| Year | DWH_dbo.Dim_Date | CalendarYear | From FromMonth |
| UpdateDate | (computed) | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_CID_LifeStageDefinition (a: @FromMonth range, b: @ToMonth range)
  |-- JOIN a.RealCID = b.RealCID
  v
BI_DB_dbo.BI_DB_CIDFirstDates (NewMarketingRegion for each CID)
  |-- JOIN on RealCID = CID
  v
DWH_dbo.Dim_Date (MonthNameAbbreviation, CalendarYear for both months)
  v
#fakereg (exclusion: March 2024 Direct SubChannel + April first login)
  |-- LEFT JOIN + IS NULL filter
  v
#tempp (per-customer: Region, FromStatus, ToStatus, months, year)
  |-- GROUP BY → COUNT(*) = Users
  v
BI_DB_dbo.BI_DB_M_LifeStage_Matrix (DELETE WHERE ToMonthFull >= @ToMonth + INSERT, 35,935 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| FromStatus / ToStatus | BI_DB_dbo.BI_DB_CID_LifeStageDefinition | Source of life stage definitions (LSD column) |
| Region | BI_DB_dbo.BI_DB_CIDFirstDates | Source of marketing region |
| FromMonth / ToMonth | DWH_dbo.Dim_Date | Month name abbreviation lookup |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the BI_DB_dbo schema.

---

## 7. Sample Queries

### 7.1 Month-over-Month Churn by Region

```sql
SELECT Region,
       ToMonthFull,
       SUM(Users) AS users_entering_churn
FROM BI_DB_dbo.BI_DB_M_LifeStage_Matrix
WHERE ToStatus = 'Churn' AND FromStatus <> 'Churn'
GROUP BY Region, ToMonthFull
ORDER BY ToMonthFull DESC, users_entering_churn DESC
```

### 7.2 Life Stage Transition Heatmap for Latest Month

```sql
SELECT FromStatus, ToStatus, SUM(Users) AS total_users
FROM BI_DB_dbo.BI_DB_M_LifeStage_Matrix
WHERE ToMonthFull = '2026-03-31'
GROUP BY FromStatus, ToStatus
ORDER BY total_users DESC
```

### 7.3 New FTD Retention — Where Do New Depositors Go Next Month?

```sql
SELECT ToStatus,
       SUM(Users) AS users,
       ROUND(SUM(Users) * 100.0 / SUM(SUM(Users)) OVER(), 1) AS pct
FROM BI_DB_dbo.BI_DB_M_LifeStage_Matrix
WHERE FromStatus = 'New FTD'
  AND ToMonthFull = '2026-03-31'
GROUP BY ToStatus
ORDER BY users DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 0 T1, 9 T2, 0 T3, 0 T4, 1 T5 | Elements: 10/10, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_M_LifeStage_Matrix | Type: Table | Production Source: SP_M_LifeStage_Matrix*
