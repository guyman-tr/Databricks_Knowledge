# dbo.ClosedPositions_LastTimeUpdate

> Watermark table storing the timestamp of the most recent closed position synchronization, used by the ETL pipeline to fetch only new records.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | LastTimeUpdate (datetime, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

dbo.ClosedPositions_LastTimeUpdate is a single-row watermark table that tracks the last time closed position data was synchronized from the core trading platform into dbo.ClosedPositionsTbl. The ETL process reads this timestamp to determine the starting point for the next incremental data pull, ensuring only new closed positions are fetched.

Without this table, the ETL process would need to scan all closed positions to determine what has already been synced, or risk re-importing duplicate records. It acts as the "high-water mark" for incremental data loading.

The ETL pipeline reads the current watermark before querying the source, then updates it with the maximum `Occurred` timestamp from the newly imported batch. The single-row design (PK on datetime) means each sync creates a new watermark or updates the existing one.

---

## 2. Business Logic

### 2.1 Incremental Sync Watermark

**What**: Tracks the point-in-time boundary for incremental data loading of closed positions.

**Columns/Parameters Involved**: `LastTimeUpdate`

**Rules**:
- Contains exactly one row with the timestamp of the last successful sync
- ETL reads this value to query source: `WHERE Occurred > @LastTimeUpdate`
- After successful import, the watermark is updated to the newest `Occurred` value
- Current value (2013-01-23) indicates the sync pipeline has been dormant since early 2013 in this environment

**Diagram**:
```
Source Trading DB                 fiktivo DB
     |                                |
     |  WHERE Occurred >              |
     |  LastTimeUpdate -----> [Read watermark]
     |                                |
     |  New closed positions -------> [INSERT into ClosedPositionsTbl]
     |                                |
     |                        [UPDATE watermark to MAX(Occurred)]
```

---

## 3. Data Overview

| LastTimeUpdate | Meaning |
|---|---|
| 2013-01-23 11:00:00 | Last sync occurred on January 23, 2013. The dormant timestamp (13+ years ago) indicates this environment's closed position pipeline was active during the early days of the affiliate system and has not run since. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LastTimeUpdate | datetime | NO | - | CODE-BACKED | High-water mark timestamp for closed position synchronization. The PK constraint ensures uniqueness. Value represents the maximum `Occurred` timestamp from the most recently synced batch of closed positions from the trading platform into dbo.ClosedPositionsTbl. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Likely consumed by an external ETL process not defined in the SSDT project.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (External ETL process) | External | Reads watermark for incremental sync of closed positions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ClosedPositions_LastTimeUpdate | CLUSTERED PK | LastTimeUpdate ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Read the current sync watermark
```sql
SELECT LastTimeUpdate FROM dbo.ClosedPositions_LastTimeUpdate WITH (NOLOCK)
```

### 8.2 Check sync freshness against actual data
```sql
SELECT w.LastTimeUpdate AS SyncWatermark, MAX(cp.Occurred) AS LatestPosition,
       DATEDIFF(DAY, w.LastTimeUpdate, MAX(cp.Occurred)) AS DaysGap
FROM dbo.ClosedPositions_LastTimeUpdate w WITH (NOLOCK)
CROSS JOIN dbo.ClosedPositionsTbl cp WITH (NOLOCK)
GROUP BY w.LastTimeUpdate
```

### 8.3 Update the watermark after a sync run
```sql
-- Read-only example: show what the new watermark would be
SELECT MAX(Occurred) AS ProposedNewWatermark
FROM dbo.ClosedPositionsTbl WITH (NOLOCK)
WHERE Occurred > (SELECT LastTimeUpdate FROM dbo.ClosedPositions_LastTimeUpdate WITH (NOLOCK))
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.ClosedPositions_LastTimeUpdate | Type: Table | Source: fiktivo/dbo/Tables/dbo.ClosedPositions_LastTimeUpdate.sql*
