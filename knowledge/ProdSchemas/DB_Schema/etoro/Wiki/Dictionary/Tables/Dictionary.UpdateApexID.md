# Dictionary.UpdateApexID

> Single-row watermark table that tracks the last execution time of the Apex ID update process, which synchronizes instrument identifiers with the Apex clearing system for US stock trading.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | LastUpdate (single-row table, no PK) |
| **Partition** | DICTIONARY filegroup (heap) |
| **Indexes** | 0 (heap — no indexes) |

---

## 1. Business Meaning

Dictionary.UpdateApexID is a single-row configuration table that stores the timestamp of the last successful Apex ID synchronization run. Apex is the clearing and execution broker used for US equity (stock) trading. Each instrument tradable through Apex needs a unique Apex identifier, and this table tracks when the synchronization process last ran to ensure it operates on schedule.

Without this table, the Apex ID update process would have no way to know when it last ran, potentially causing it to either skip updates (stale instrument IDs) or re-run unnecessarily. Stale Apex IDs could cause order routing failures for US stock positions.

The table is read and updated by Trade.UpdateApexID (the active synchronization procedure) and Trade.UpdateApexIDOld (a legacy version). The single row is updated in-place each time the sync completes, with LastUpdate set to the current UTC timestamp.

---

## 2. Business Logic

### 2.1 Apex Synchronization Watermark

**What**: Tracks when instrument-to-Apex ID mapping was last synchronized with the Apex clearing system.

**Columns/Parameters Involved**: `LastUpdate`

**Rules**:
- Contains exactly one row — the table acts as a global configuration singleton
- `LastUpdate` is set to the current UTC time after each successful Apex ID sync
- Trade.UpdateApexID reads this value to determine if a sync is needed (based on scheduling interval)
- The current value (2026-03-11 05:05:20) indicates the sync runs regularly during early morning UTC hours
- If this timestamp is stale (e.g., more than 24 hours old), it indicates the sync job has failed and needs investigation

**Diagram**:
```
Apex ID Sync Flow:
  ┌───────────────────────┐
  │  Trade.UpdateApexID   │
  │  1. Read LastUpdate   │◄── Dictionary.UpdateApexID
  │  2. Check if due      │
  │  3. Sync instrument   │
  │     IDs with Apex     │
  │  4. UPDATE LastUpdate │──► Dictionary.UpdateApexID
  └───────────────────────┘
```

---

## 3. Data Overview

| LastUpdate | Meaning |
|---|---|
| 2026-03-11 05:05:20 | The most recent Apex ID synchronization completed on March 11, 2026 at 05:05 UTC. This is the only row in the table — it's updated in-place each sync cycle. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LastUpdate | datetime2(7) | YES | - | CODE-BACKED | UTC timestamp of the last successful Apex ID synchronization run. Updated in-place by Trade.UpdateApexID after each sync completes. Used to determine sync scheduling and detect stale/failed sync jobs. High-precision datetime2(7) provides sub-microsecond accuracy. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateApexID | LastUpdate | Reader/Writer | Reads to check sync schedule, writes to record completion |
| Trade.UpdateApexIDOld | LastUpdate | Reader/Writer | Legacy version of the sync procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.UpdateApexID (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateApexID | Stored Procedure | Reads and updates the watermark during Apex ID sync |
| Trade.UpdateApexIDOld | Stored Procedure | Legacy sync procedure, reads and updates the watermark |

---

## 7. Technical Details

### 7.1 Indexes

No indexes (heap table, single-row).

### 7.2 Constraints

None — no PK, FK, or CHECK constraints. The single-row nature is enforced by application logic, not by database constraints.

---

## 8. Sample Queries

### 8.1 Check when Apex sync last ran
```sql
SELECT  LastUpdate,
        DATEDIFF(HOUR, LastUpdate, GETUTCDATE()) AS HoursSinceLastSync
FROM    [Dictionary].[UpdateApexID] WITH (NOLOCK);
```

### 8.2 Alert if sync is stale (more than 24 hours old)
```sql
SELECT  LastUpdate,
        CASE WHEN DATEDIFF(HOUR, LastUpdate, GETUTCDATE()) > 24
             THEN 'STALE - Investigate Apex sync failure'
             ELSE 'OK'
        END AS SyncStatus
FROM    [Dictionary].[UpdateApexID] WITH (NOLOCK);
```

### 8.3 View sync timestamp with readable format
```sql
SELECT  FORMAT(LastUpdate, 'yyyy-MM-dd HH:mm:ss.fff') AS LastSyncUTC,
        FORMAT(LastUpdate AT TIME ZONE 'UTC' AT TIME ZONE 'Israel Standard Time', 'yyyy-MM-dd HH:mm:ss') AS LastSyncIST
FROM    [Dictionary].[UpdateApexID] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.UpdateApexID | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.UpdateApexID.sql*
