# History.GetChampionshipInfo

> Simplified query interface for completed trading championships - exposes identification, date range, and duration label for championships that have formally ended.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | ChampionshipID (int) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

History.GetChampionshipInfo provides a simplified, cleaned view of completed trading championships. It filters `History.Championship` to only championships with a non-NULL EndDateTime (i.e., championships that have formally concluded) and exposes a subset of five key columns including a human-readable Duration label derived from the DurationType integer.

The view is part of the eToro gaming platform era (all 267 source rows are from 2012). The gaming/championship feature has been inactive in production for many years. The view provides a clean interface for any queries that need to list completed championships with their time windows - historical analytics, prize audit trails, or legacy data investigations.

No stored procedures in the current codebase reference this view directly. It is an ad-hoc query interface and is used as a dependency by `History.GetChampionshipInfoWithChampType` (which adds ChampionshipTypeID and Title via a JOIN to Championship.Championship).

**Important note**: In the live data, the Duration column returns NULL for all 267 rows. This indicates that the actual DurationType values stored in History.Championship do not match the 1/2/3 values defined in the CASE expression. The duration label feature is effectively non-functional on current data - all rows show NULL Duration.

---

## 2. Business Logic

### 2.1 Completed Championships Filter

**What**: Only championships with a formal end date are exposed.

**Columns/Parameters Involved**: `EndDateTime`

**Rules**:
- WHERE EndDateTime IS NOT NULL excludes championships still in progress or that were never formally ended
- All 267 History.Championship rows with non-NULL EndDateTime are returned (verified from live data - all 267 rows have EndDateTime set since the gaming platform is inactive)
- Championships with EndDateTime=NULL would be "in progress" - none currently exist since gaming is inactive

### 2.2 Duration Label (Computed - Currently Non-Functional)

**What**: The Duration column translates DurationType int to a human-readable label.

**Columns/Parameters Involved**: `DurationType` (base table), `Duration` (computed output)

**Rules**:
- CASE DurationType WHEN 1 THEN 'Daily' WHEN 2 THEN 'Weekly' WHEN 3 THEN 'Manual' END
- In live data: Duration is NULL for ALL rows - meaning DurationType values do not match 1, 2, or 3
- Actual DurationType values in History.Championship are not known from this data sample
- The weekly pattern of the championship date ranges (approximately 7 days each) suggests DurationType=2 (Weekly) was intended, but the actual stored values differ

**Diagram**:
```
DurationType (base table int) -> Duration (view output varchar):
  1 -> 'Daily'
  2 -> 'Weekly'
  3 -> 'Manual'
  any other value -> NULL  <-- actual live data result for all 267 rows
```

---

## 3. Data Overview

| ChampionshipID | ChampionshipSetupID | StartDateTime | EndDateTime | Duration |
|---|---|---|---|---|
| 270 | 32 | 2012-02-26 15:45 | 2012-03-04 08:27 | NULL | Championship 270: a ~6-day competition (ID suggests it ran weekly, but Duration=NULL because DurationType doesn't match 1/2/3). Last championship in data set. SetupID=32 identifies the template it was based on. |
| 269 | 32 | 2012-02-19 14:56 | 2012-02-26 15:43 | NULL | Another ~7-day competition sharing setup template 32. Sequential championships with overlapping setup IDs indicate a recurring weekly cycle run from the same setup. |
| 268 | 32 | 2012-02-12 07:13 | 2012-02-19 13:00 | NULL | Same ~7-day pattern. SetupID=32 reused consistently - the same championship template ran many times as periodic cycles. |
| 266 | 31 | 2012-02-05 19:22 | 2012-02-05 22:45 | NULL | A very short championship (~3.5 hours) using a different setup (SetupID=31). The duration variety in the raw data contrasts with the Duration column returning NULL for all. |
| 267 | 32 | 2012-02-05 23:07 | 2012-02-12 07:12 | NULL | Normal weekly-pattern championship on setup 32. All rows from 2012; gaming feature now inactive in production. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ChampionshipID | int | NO | - | VERIFIED | Unique identifier for the completed championship. Assigned by Internal.GetChampionshipID at championship start. PK of History.Championship. Shared with History.ChampionshipPlayer to link players to their competition. |
| 2 | ChampionshipSetupID | int | NO | 0 | VERIFIED | ID of the setup template in Championship.Championship from which this championship was launched. Multiple ChampionshipIDs can share the same ChampionshipSetupID (the same competition template runs multiple times). |
| 3 | StartDateTime | datetime | YES | - | VERIFIED | Wall-clock datetime when the championship started. Set at insert time by Championship.ChampionshipStart. |
| 4 | EndDateTime | datetime | YES | - | VERIFIED | Wall-clock datetime when the championship ended. Set by Championship.ChampionshipEnd. Non-NULL guaranteed by this view's WHERE filter. |
| 5 | Duration | varchar (computed) | YES | - | CODE-BACKED | Human-readable duration label derived from DurationType: 1='Daily', 2='Weekly', 3='Manual'. Returns NULL when DurationType is not in {1, 2, 3} - which is the case for all current live data rows. Effectively non-functional on current data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns, WHERE filter) | History.Championship | View | Filtered subset of completed championships only, 5 columns exposed |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.GetChampionshipInfoWithChampType | ChampionshipID/ChampionshipSetupID | View (JOIN base) | Extends this view's output with ChampionshipTypeID and Title from Championship.Championship |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetChampionshipInfo (view)
└── History.Championship (table - leaf node)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Championship | Table | Sole data source - SELECT 4 columns + CASE on DurationType, WHERE EndDateTime IS NOT NULL |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.GetChampionshipInfoWithChampType | View | Joins to this view's base table (History.Championship) with identical logic, extends with Title |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Uses History.Championship clustered PK index (ChampionshipID).

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 List all completed championships ordered by most recent
```sql
SELECT
    ChampionshipID,
    ChampionshipSetupID,
    StartDateTime,
    EndDateTime,
    Duration,
    DATEDIFF(HOUR, StartDateTime, EndDateTime) AS DurationHours
FROM History.GetChampionshipInfo WITH (NOLOCK)
ORDER BY ChampionshipID DESC;
```

### 8.2 Find championships for a specific setup template
```sql
SELECT
    ChampionshipID,
    StartDateTime,
    EndDateTime,
    Duration
FROM History.GetChampionshipInfo WITH (NOLOCK)
WHERE ChampionshipSetupID = 32
ORDER BY StartDateTime DESC;
```

### 8.3 Championships that ran within a specific date range
```sql
SELECT
    ChampionshipID,
    ChampionshipSetupID,
    StartDateTime,
    EndDateTime
FROM History.GetChampionshipInfo WITH (NOLOCK)
WHERE StartDateTime >= '2012-01-01'
  AND EndDateTime <= '2012-12-31'
ORDER BY StartDateTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for History.GetChampionshipInfo. Business context inherited from History.Championship documentation.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.7/10 (Elements: 10/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 consumers | App Code: 0 repos | Corrections: 0 applied*
*Object: History.GetChampionshipInfo | Type: View | Source: etoro/etoro/History/Views/History.GetChampionshipInfo.sql*
