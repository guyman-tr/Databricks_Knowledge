# History.PriceWorkingInterval

> Operational log of price feed active intervals, tracking the periods during which the price system operates in normal (non-weekend) mode - each row defines a start and end datetime for a continuous pricing window.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (DateFrom, DateTo) composite clustered PK |
| **Partition** | No (ON [HISTORY] filegroup) |
| **Indexes** | 2 (1 clustered PK + 1 nonclustered on DateTo) |

---

## 1. Business Meaning

`History.PriceWorkingInterval` records the time periods during which the trading platform's price feed operates in its normal continuous-pricing mode. Each row represents one uninterrupted pricing window: `DateFrom` marks when that window opened, and `DateTo` marks when it closed (or `3000-01-01 00:00:00.000` as a sentinel meaning "currently active").

The table is managed by `Maintenance.SetEndOfWeekMode`, which is called by operations to toggle the platform between normal pricing mode and end-of-week (weekend/holiday) mode. When transitioning to weekend mode (`@EndOfWeekMode=1`), the currently active interval is closed by setting its `DateTo` to the transition timestamp. When returning to normal mode (`@EndOfWeekMode=0`), a new interval row is inserted with `DateTo = '3000-01-01'`.

Despite living in the History schema, this is **not a SQL Server temporal table** - it is a standalone operational/audit table that serves as a time-series log of pricing mode transitions. With 401 rows spanning 2014 to 2017 (and a current active interval), it captures over a decade of pricing windows.

External systems query this table (via the `History.GetPriceWorkingInterval` view) to determine whether a given timestamp falls within a valid pricing interval - for example, to assess whether a historical price anomaly occurred during an active pricing period.

---

## 2. Business Logic

### 2.1 Interval Management - Open/Close Pattern

**What**: Each row represents one continuous pricing window. Exactly one row is always "open" (DateTo = sentinel).

**Columns/Parameters Involved**: `DateFrom`, `DateTo`

**Rules**:
- `DateTo = '3000-01-01 00:00:00.000'` = sentinel value for "currently active" interval
- At any point in time, exactly ONE row should have this sentinel value
- To CLOSE an interval: `UPDATE SET DateTo = @Date WHERE DateTo = '3000-01-01'`
- To OPEN a new interval: `INSERT VALUES (@Date, '3000-01-01')`
- The HPWI_DATETO nonclustered index on DateTo makes the sentinel lookup (WHERE DateTo = '3000-01-01') efficient

**Diagram**:
```
Normal Mode (pricing active):
  Row: DateFrom=2017-02-16, DateTo=3000-01-01  <- currently active

End of week transition (@EndOfWeekMode=1, @Date='2017-02-17 22:00'):
  UPDATE: DateFrom=2017-02-16, DateTo=2017-02-17 22:00  <- closed

Return to normal (@EndOfWeekMode=0, @Date='2017-02-19 22:00'):
  INSERT: DateFrom=2017-02-19 22:00, DateTo=3000-01-01  <- new active interval
```

### 2.2 Synchronization with Maintenance.Feature

**What**: PriceWorkingInterval changes are always synchronized with the Feature table's end-of-week flag.

**Columns/Parameters Involved**: `DateFrom`, `DateTo`

**Rules**:
- `Maintenance.SetEndOfWeekMode` checks `Maintenance.Feature WHERE FeatureID=1` before acting
- If the feature flag already matches the requested mode, no change is made (idempotent call)
- PriceWorkingInterval and Feature FeatureID=1 are updated together - they stay in sync
- Callers can safely call SetEndOfWeekMode multiple times without creating duplicate intervals

---

## 3. Data Overview

401 rows. Earliest interval opened 2014-03-09. Current interval opened 2017-02-16 and remains active.

| DateFrom | DateTo | Context |
|---|---|---|
| 2017-02-16 xx:xx:xx | 3000-01-01 00:00:00.000 | Currently active interval - platform in normal pricing mode since 2017-02-16 |
| 2017-02-12 xx:xx:xx | 2017-02-16 xx:xx:xx | Closed interval - one pricing window from Feb 2017 |
| 2014-03-09 xx:xx:xx | ... | Oldest recorded interval - first pricing window since temporal tracking began |

*401 rows across ~3 years (2014-2017) reflects regular weekly open/close cycles during that period. Fewer changes since 2017 suggests a more stable operational mode.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DateFrom | datetime | NO | - | VERIFIED | The datetime when this pricing window opened - when the platform transitioned FROM weekend/end-of-week mode INTO normal pricing mode. Part of the composite clustered PK. Written by Maintenance.SetEndOfWeekMode when @EndOfWeekMode=0. Local server time (not UTC). |
| 2 | DateTo | datetime | NO | - | VERIFIED | The datetime when this pricing window closed - when the platform transitioned TO end-of-week mode. Sentinel value '3000-01-01 00:00:00.000' indicates the interval is currently active (no close time yet). Part of the composite clustered PK. Written by SetEndOfWeekMode when @EndOfWeekMode=1. HPWI_DATETO index supports efficient lookup of the active interval (WHERE DateTo = '3000-01-01'). |

---

## 5. Relationships

### 5.1 References To (this object points to)

None. Standalone operational log with no FK constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Maintenance.SetEndOfWeekMode | DateFrom, DateTo | WRITER | Inserts new intervals (open) and updates DateTo (close) based on @EndOfWeekMode flag |
| History.GetPriceWorkingInterval | SELECT | READER (thin view) | Passthrough view exposing this table to callers; used by systems that check pricing window membership |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PriceWorkingInterval (table)
(leaf - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.SetEndOfWeekMode | Stored Procedure | WRITER - manages open/close of pricing intervals |
| History.GetPriceWorkingInterval | View | READER - thin wrapper exposing this table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HPWI | CLUSTERED PK | DateFrom ASC, DateTo ASC | - | - | Active |
| HPWI_DATETO | NONCLUSTERED | DateTo ASC | - | - | Active |

*ON [HISTORY] filegroup, FILLFACTOR=90 on both indexes. HPWI_DATETO index enables efficient sentinel lookup (WHERE DateTo = '3000-01-01') to find the currently active interval.*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HPWI | PK | (DateFrom, DateTo) composite clustered PK - prevents duplicate interval records |

---

## 8. Sample Queries

### 8.1 Current active pricing interval

```sql
SELECT DateFrom, DateTo
FROM History.PriceWorkingInterval WITH (NOLOCK)
WHERE DateTo = '3000-01-01 00:00:00.000'
```

### 8.2 Check if a specific timestamp falls within a pricing interval

```sql
SELECT COUNT(*) AS IsActiveInterval
FROM History.PriceWorkingInterval WITH (NOLOCK)
WHERE @CheckTime >= DateFrom
  AND @CheckTime < CASE WHEN DateTo = '3000-01-01' THEN GETDATE() ELSE DateTo END
```

### 8.3 All pricing windows ordered by time

```sql
SELECT
    DateFrom,
    CASE WHEN DateTo = '3000-01-01' THEN NULL ELSE DateTo END AS DateTo,
    CASE WHEN DateTo = '3000-01-01' THEN 1 ELSE 0 END AS IsCurrentlyActive,
    DATEDIFF(HOUR, DateFrom, CASE WHEN DateTo = '3000-01-01' THEN GETDATE() ELSE DateTo END) AS DurationHours
FROM History.PriceWorkingInterval WITH (NOLOCK)
ORDER BY DateFrom DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PriceWorkingInterval | Type: Table | Source: etoro/etoro/History/Tables/History.PriceWorkingInterval.sql*
