# Dictionary.SyncTslStatus

> Tracks the synchronization lifecycle of Trailing Stop Loss (TSL) position data across trading servers.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | StatusID (int, PK) |
| **Row Count** | 4 |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

### What It Is
Dictionary.SyncTslStatus is a lookup table containing the synchronization states for Trailing Stop Loss (TSL) data replication. TSL is a dynamic stop loss that adjusts as the market moves in the trader's favor.

### Why It Exists
When TSL (Trailing Stop Loss) positions need to be synchronized between trading servers or archived to history, each record goes through a defined lifecycle: not yet synced → currently syncing → finished → or synchronized because TSL was turned off. This table defines those states for tracking and monitoring the sync process.

### How It Works
The `StatusID` is used by the TSL synchronization infrastructure. Procedures like `History.MoveRecsFromTradeSyncTSLToPass` and `History.MoveRecsFromDagSyncTslToPass` move TSL records through these states during the archival process. `Trade.ActivateSplit_Inner` references TSL sync status during stock split processing. The `TslConnect` permission script grants access to TSL sync tables.

---

## 2. Business Logic

### Value Map (Complete — 4 rows)

| StatusID | StatusName | Business Meaning |
|----------|-----------|------------------|
| 0 | Before synchronization | TSL record hasn't been synced yet — initial state |
| 1 | Currently being synchronized | TSL record is actively being synced between servers/archive |
| 2 | Finished synchronization | TSL sync completed successfully |
| 3 | Synchronized due to TSL turn off | TSL was disabled on the position, triggering a final sync to record the turned-off state |

### State Flow
```
0 (Before sync) → 1 (Syncing) → 2 (Finished)
                                → 3 (TSL turned off)
```

---

## 3. Data Overview

| StatusID | StatusName | Scenario |
|----------|-----------|----------|
| 0 | Before synchronization | New TSL position created, not yet replicated to archive |
| 1 | Currently being synchronized | Nightly job is moving TSL records to history tables |
| 2 | Finished synchronization | TSL record successfully archived |
| 3 | Synchronized due to TSL turn off | User disabled trailing stop loss, final state captured |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StatusID | int | NO | — | HIGH | Primary key identifying the TSL sync state. `0`=Before, `1`=Syncing, `2`=Finished, `3`=TSL Off. Zero-based enumeration. |
| 2 | StatusName | varchar(50) | YES | — | HIGH | Human-readable description of the sync state. Nullable but populated for all rows. |

---

## 5. Relationships

### Referenced By (Implicit)

| Consumer | Context | Evidence |
|----------|---------|----------|
| TSL synchronization tables | StatusID column in sync tracking | Referenced by archival procedures |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| History.MoveRecsFromTradeSyncTSLToPass | SELECT/UPDATE | Moves TSL records from Trade to History, updates sync status |
| History.MoveRecsFromDagSyncTslToPass | SELECT/UPDATE | DAG-based TSL sync archival |
| History.MoveRecsFromHistorySyncTSLToPass_BCP | SELECT/UPDATE | BCP-based bulk TSL archival |
| BackOffice.P_GetTrailingStopLossHistory | SELECT | Retrieves TSL history with sync status |
| Trade.ActivateSplit_Inner | SELECT/UPDATE | Stock split processing updates TSL sync state |

### Other Consumers

| Object | Type | Context |
|--------|------|---------|
| History.SYN_MoveRecsFromDagSyncTslToPass_BCP | Synonym | Cross-server reference for DAG sync |
| UsersPermissions.TslConnect | Permission script | Grants access to TSL sync tables |

---

## 6. Dependencies

### Depends On
None — leaf dictionary table with no foreign keys.

### Depended On By
- TSL synchronization infrastructure (5+ archival/history procedures)
- BackOffice TSL history reporting

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_Dictionary_SyncTslStatus | CLUSTERED PK | StatusID ASC | Standard PK |

---

## 8. Sample Queries

```sql
-- Get all TSL sync statuses
SELECT  StatusID,
        StatusName
FROM    Dictionary.SyncTslStatus WITH (NOLOCK)
ORDER BY StatusID;

-- Check TSL sync status distribution (conceptual — actual table varies)
SELECT  sts.StatusName,
        COUNT(*) AS RecordCount
FROM    Trade.SyncTsl t WITH (NOLOCK)
JOIN    Dictionary.SyncTslStatus sts WITH (NOLOCK)
        ON t.StatusID = sts.StatusID
GROUP BY sts.StatusName;

-- Find records still pending synchronization
SELECT  sts.StatusName
FROM    Dictionary.SyncTslStatus sts WITH (NOLOCK)
WHERE   sts.StatusID = 0;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `SyncTslStatus`.

---

*Generated: 2026-03-14 | Quality: 9.0/10*
*Object: Dictionary.SyncTslStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.SyncTslStatus.sql*
