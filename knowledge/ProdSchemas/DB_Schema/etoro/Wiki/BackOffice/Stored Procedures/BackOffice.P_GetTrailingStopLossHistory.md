# BackOffice.P_GetTrailingStopLossHistory

> Returns the complete trailing stop loss (TSL) adjustment history for a position by unioning records from three sources: the local History.SyncTSL table, the cross-server SyncTSL archive view, and the History.SyncTSLSwitch migration table.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UNION ALL from History.SyncTSL + [synctsl].[SyncTsl].History.VSyncTSL + History.SyncTSLSwitch WHERE PositionID = @PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.P_GetTrailingStopLossHistory` retrieves the full adjustment trail of the Trailing Stop Loss (TSL) for a specific trading position. TSL is a dynamic stop loss that automatically moves upward as the position's profit increases, locking in gains. Each time the TSL level adjusts, a record is written. This procedure aggregates all such records across three data stores to provide a complete chronological picture.

The three-source UNION architecture reflects eToro's data migration history: TSL records were originally stored in a separate SQL Server instance ([synctsl].[SyncTsl]), then migrated to the local database. History.SyncTSLSwitch is a transition table capturing records created during or after the cross-server migration. By UNIONing all three, the procedure returns a complete history regardless of where data landed during the migration.

Used by the BackOffice risk and compliance teams to investigate how a position's stop loss evolved over its lifetime - important for dispute resolution, margin call analysis, and automated TSL system audits.

---

## 2. Business Logic

### 2.1 Three-Source UNION for Complete History

**What**: TSL history spans three tables due to server migration. UNION ALL combines all records without deduplication.

**Sources**:
1. `History.SyncTSL` (local): primary post-migration TSL record store.
2. `[synctsl].[SyncTsl].History.VSyncTSL` (cross-server linked server): archive view on the original SyncTSL server. Requires the [synctsl] linked server to be available.
3. `History.SyncTSLSwitch` (local): records created during the switch/migration period.

**Rules**:
- UNION ALL (not UNION): preserves duplicates if the same record appears in multiple sources (possible during migration overlap periods).
- All three SELECT lists are identical: ID, PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy, DateInserted.
- All three filter on PositionID = @PositionID.
- Results are NOT ordered - caller must order if needed.
- If the [synctsl] linked server is unavailable, the entire query fails (no error handling for linked server outage).

### 2.2 TSL Record Meaning

**What**: Each row captures a TSL threshold adjustment event for the position.

**Columns**: `StopLoss`, `SLManualVer`, `NextThresHold`, `IsBuy`, `DateInserted`

**Rules**:
- StopLoss: the new stop loss rate set at this adjustment.
- NextThresHold: the profit level at which the NEXT TSL adjustment will trigger.
- SLManualVer: version counter for manual stop loss overrides - distinguishes automatic TSL movements from manager-initiated adjustments.
- IsBuy: 1=long position, 0=short. TSL moves upward for longs, downward for shorts.
- DateInserted: when this TSL adjustment occurred.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | bigint | NO | - | CODE-BACKED | ID of the trading position whose TSL history to retrieve. Changed from INT to BIGINT (per code comment by Shay O, June 2021) to support large position IDs. Filters all three UNION sources. |

Output columns (same from all three sources):

| # | Output Column | Type | Confidence | Description |
|---|--------------|------|------------|-------------|
| 1 | ID | int/bigint | CODE-BACKED | Row identifier in the source table (History.SyncTSL, VSyncTSL, or SyncTSLSwitch). |
| 2 | PositionID | bigint | CODE-BACKED | The position ID this TSL record belongs to. Matches @PositionID. |
| 3 | StopLoss | decimal | CODE-BACKED | The stop loss rate as set by this TSL adjustment. |
| 4 | SLManualVer | int | CODE-BACKED | Manual stop loss version counter. Incremented when a manager overrides the TSL manually. Distinguishes automated TSL movements from human interventions. |
| 5 | NextThresHold | decimal | CODE-BACKED | The next price threshold that will trigger another TSL upward adjustment. |
| 6 | IsBuy | bit | CODE-BACKED | Position direction: 1=Long (Buy), 0=Short (Sell). TSL moves upward for longs, locking in profits above the current level. |
| 7 | DateInserted | datetime | CODE-BACKED | When this TSL adjustment record was written. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Source 1 | History.SyncTSL | Reader | Local post-migration TSL records |
| Source 2 | [synctsl].[SyncTsl].History.VSyncTSL | Reader (cross-server) | Archive view on original SyncTSL linked server |
| Source 3 | History.SyncTSLSwitch | Reader | Migration-period TSL records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.P_GetTrailingStopLossHistorytest | EXEC (cross-server) | Callee | Called from the cross-server version of this procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.P_GetTrailingStopLossHistory (procedure)
+-- History.SyncTSL (table) [local, source 1]
+-- [synctsl].[SyncTsl].History.VSyncTSL (view) [cross-server, source 2]
+-- History.SyncTSLSwitch (table) [local, source 3]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.SyncTSL | Table | SELECT TSL records for the position (local, post-migration) |
| [synctsl].[SyncTsl].History.VSyncTSL | Cross-server view | SELECT TSL archive records from the original SyncTSL server |
| History.SyncTSLSwitch | Table | SELECT TSL records from the migration transition period |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.P_GetTrailingStopLossHistorytest | Stored Procedure | Cross-server proxy - calls this procedure via [synctsl] linked server |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Requires [synctsl] linked server connectivity. Query failure if linked server is down (no fallback).

---

## 8. Sample Queries

### 8.1 Get TSL history for a specific position

```sql
EXEC BackOffice.P_GetTrailingStopLossHistory @PositionID = 123456789;
```

### 8.2 Get TSL history ordered by date

```sql
-- Capture into temp table for ordered output
CREATE TABLE #TSLHistory (
    ID BIGINT, PositionID BIGINT, StopLoss DECIMAL(18,8),
    SLManualVer INT, NextThresHold DECIMAL(18,8), IsBuy BIT, DateInserted DATETIME
);
INSERT INTO #TSLHistory
EXEC BackOffice.P_GetTrailingStopLossHistory @PositionID = 123456789;
SELECT * FROM #TSLHistory ORDER BY DateInserted;
DROP TABLE #TSLHistory;
```

### 8.3 Check local TSL history directly (if linked server unavailable)

```sql
SELECT ID, PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy, DateInserted
FROM History.SyncTSL WITH (NOLOCK)
WHERE PositionID = 123456789
UNION ALL
SELECT ID, PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy, DateInserted
FROM History.SyncTSLSwitch WITH (NOLOCK)
WHERE PositionID = 123456789
ORDER BY DateInserted;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller (P_GetTrailingStopLossHistorytest) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.P_GetTrailingStopLossHistory | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.P_GetTrailingStopLossHistory.sql*
