# Hedge.NettingDaily

> Append-only time-series of daily netting position snapshots - records every position state change as a new row (by UpdateTime), unlike Hedge.Netting which maintains only the current position via upsert.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (LiquidityAccountID, InstrumentID, UpdateTime) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK only) |

---

## 1. Business Meaning

Hedge.NettingDaily is an append-only variant of Hedge.Netting designed to preserve the full history of position changes as a time-series log. While Hedge.Netting stores only the current net hedge position per instrument per LP account (and relies on SQL Server system versioning for history), NettingDaily accumulates each state change as a separate row keyed by UpdateTime. This makes it suitable for daily reconciliation, position change analytics, and reporting that requires direct row-level access to historical states without using `FOR SYSTEM_TIME` queries.

The table structure is nearly identical to Hedge.Netting, with one critical difference: the PK replaces ValueDate with UpdateTime. This allows multiple rows for the same (LiquidityAccountID, InstrumentID) pair at different timestamps, making the table a flat time-series rather than a single-row-per-position store.

Hedge.AddOrUpdateNettingDaily only INSERTs (no UPDATE path) - meaning every call appends a new snapshot regardless of whether a position already exists. The table is currently empty in production, indicating this feature is deployed but not yet activated. It may be part of a planned reconciliation or analytics pipeline.

---

## 2. Business Logic

### 2.1 Append vs Upsert - Key Difference from Hedge.Netting

**What**: NettingDaily is INSERT-only, creating a complete audit trail of all position states over time at the row level.

**Columns/Parameters Involved**: `LiquidityAccountID`, `InstrumentID`, `UpdateTime`, `Units`, `IsBuy`, `AvgRate`

**Rules**:
- Hedge.AddOrUpdateNettingDaily always INSERTs - never checks for existing rows
- Every call creates a new row with a distinct (LiquidityAccountID, InstrumentID, UpdateTime) key
- A query for the LATEST position requires `WHERE UpdateTime = MAX(UpdateTime) GROUP BY LiquidityAccountID, InstrumentID`
- The complete position history is available without joining to History.NettingDaily or using temporal queries
- This is the fundamental design difference from Hedge.Netting (which uses UPDATE + fallback INSERT)

**Diagram**:
```
Hedge.Netting (live state)          Hedge.NettingDaily (time series)
+------+---------+-------+          +------+---------+----------+-------+
| LA10 | Inst=5  | 100M  |          | LA10 | Inst=5  | 08:00:00 |  95M  |
+------+---------+-------+          | LA10 | Inst=5  | 14:30:00 | 100M  |
  (single row, always current)      | LA10 | Inst=5  | 21:00:00 | 102M  |
                                      (multiple rows, full history)
```

### 2.2 Temporal Columns Without Active System Versioning

**What**: NettingDaily defines temporal period columns (SysStartTime, SysEndTime) but does not activate SYSTEM_VERSIONING ON in the SSDT definition.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- The PERIOD FOR SYSTEM_TIME clause is present in the DDL, defining the temporal framework
- Unlike Hedge.Netting, no `WITH (SYSTEM_VERSIONING = ON ...)` clause links to a history table in the SSDT
- This means the temporal infrastructure is prepared but may not be actively versioning, OR the history table link is managed outside SSDT
- Since the table is append-only by design, the temporal versioning adds less value here than in Hedge.Netting

---

## 3. Data Overview

No data available - Hedge.NettingDaily is currently empty in production. The table is deployed (DDL exists, procedure Hedge.AddOrUpdateNettingDaily exists) but has not been populated. When active, rows would have the same structure as Hedge.Netting but with UpdateTime as the PK timestamp component instead of ValueDate.

Expected row structure when active:

| LiquidityAccountID | InstrumentID | Units | IsBuy | AvgRate | ValueDate | UpdateTime | Meaning |
|---|---|---|---|---|---|---|---|
| 10 | 5 | 224,924,151 | true | 159.32 | 2026-02-09 | 2026-02-09 08:00:00 | Snapshot of LP account 10's position in InstrumentID 5 at 08:00 - 224M units long at 159.32 avg rate settling 2026-02-09 |
| 10 | 5 | 225,100,000 | true | 159.33 | 2026-02-09 | 2026-02-09 14:30:00 | Same instrument, updated 6 hours later - position grew by 176K units, avg rate shifted slightly |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountID | int | NO | - | VERIFIED | First component of composite PK. FK to Trade.LiquidityAccounts - identifies which LP account's hedge position is being recorded. See [Trade.LiquidityAccounts](../../Trade/Tables/Trade.LiquidityAccounts.md) for account type meanings. |
| 2 | InstrumentID | int | NO | - | VERIFIED | Second component of composite PK. FK to Trade.Instrument (implicit). The financial instrument whose hedge position is being snapshotted. |
| 3 | Units | decimal(16,2) | YES | - | VERIFIED | The net position size in instrument units at the time of this snapshot. Same semantics as Hedge.Netting.Units - the aggregate hedged quantity. See [Hedge.Netting](Hedge.Netting.md) for full description. |
| 4 | IsBuy | bit | NO | - | VERIFIED | Net position direction. true = long (bought hedge), false = short (sold hedge). Same semantics as Hedge.Netting.IsBuy. |
| 5 | AvgRate | dbo.dtPrice | YES | - | VERIFIED | Volume-weighted average entry rate of the position at snapshot time. Used for PnL calculation relative to current market rate. Same semantics as Hedge.Netting.AvgRate. |
| 6 | ValueDate | date | NO | - | CODE-BACKED | Settlement/delivery date for the hedge position with the LP. Same semantics as Hedge.Netting.ValueDate but NOT part of the PK here (UpdateTime is). |
| 7 | ExecTime | datetime2(7) | YES | - | CODE-BACKED | Timestamp of the hedge execution that produced this position state. May differ slightly from UpdateTime (execution vs database write). Same semantics as Hedge.Netting.ExecTime. |
| 8 | UpdateTime | datetime2(7) | NO | - | VERIFIED | Third component of composite PK. Timestamp when this snapshot was written. NOT NULL (vs nullable in Hedge.Netting) because it serves as the PK differentiator - without a value this row couldn't be uniquely identified. Each unique UpdateTime creates a new historical record for the same (LA, Instrument) pair. |
| 9 | HedgeServerID | int | NO | - | VERIFIED | FK to Trade.HedgeServer (implicit). Which hedge server instance generated this snapshot. Same semantics as Hedge.Netting.HedgeServerID. |
| 10 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | System-generated temporal period start. Defined via PERIOD FOR SYSTEM_TIME but system versioning may not be actively linked to a history table in this environment. For append-only rows, each row has a distinct SysStartTime matching its insert timestamp. |
| 11 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | System-generated temporal period end. Expected to be 9999-12-31 for all active rows in an append-only design where rows are never updated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityAccountID | Trade.LiquidityAccounts | FK (explicit, WITH CHECK) | Constrains which LP accounts can have netting snapshots |
| InstrumentID | Trade.Instrument | Implicit | Identifies the financial instrument for the position snapshot |
| HedgeServerID | Trade.HedgeServer | Implicit | Identifies the hedge server that generated the snapshot |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.AddOrUpdateNettingDaily | LiquidityAccountID, InstrumentID | WRITER | The sole write path - always inserts new snapshot rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.NettingDaily (table)
├── Trade.LiquidityAccounts (table) [FK target - leaf]
├── Trade.Instrument (table) [implicit FK target - leaf]
└── Trade.HedgeServer (table) [implicit FK target - leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | FK target for LiquidityAccountID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AddOrUpdateNettingDaily | Stored Procedure | WRITER - inserts daily position snapshots (INSERT only, no upsert) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_NettingDailyTemp | CLUSTERED PK | LiquidityAccountID ASC, InstrumentID ASC, UpdateTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_NettingDailyTemp | PRIMARY KEY | Unique snapshot per (LiquidityAccount, Instrument, UpdateTime). FILLFACTOR=95. |
| FK_NettingDaily_LiquidityAccountID_Temp | FOREIGN KEY (WITH CHECK) | LiquidityAccountID must exist in Trade.LiquidityAccounts |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime/SysEndTime defined as temporal period (system versioning status uncertain from SSDT alone) |

---

## 8. Sample Queries

### 8.1 Latest snapshot per instrument for the main LP account (when populated)
```sql
SELECT  nd.LiquidityAccountID,
        nd.InstrumentID,
        nd.Units,
        nd.IsBuy,
        nd.AvgRate,
        nd.ValueDate,
        nd.UpdateTime
FROM    [Hedge].[NettingDaily] nd WITH (NOLOCK)
WHERE   nd.LiquidityAccountID = 10
AND     nd.UpdateTime = (
            SELECT MAX(nd2.UpdateTime)
            FROM [Hedge].[NettingDaily] nd2 WITH (NOLOCK)
            WHERE nd2.LiquidityAccountID = nd.LiquidityAccountID
              AND nd2.InstrumentID = nd.InstrumentID
        )
ORDER BY nd.InstrumentID;
```

### 8.2 Position change history for a specific instrument (time series)
```sql
SELECT  nd.UpdateTime,
        nd.Units,
        CASE WHEN nd.IsBuy = 1 THEN 'Long' ELSE 'Short' END AS Direction,
        nd.AvgRate,
        nd.ValueDate
FROM    [Hedge].[NettingDaily] nd WITH (NOLOCK)
WHERE   nd.LiquidityAccountID = 10
AND     nd.InstrumentID = 5
ORDER BY nd.UpdateTime;
```

### 8.3 Compare NettingDaily vs Netting current position (reconciliation)
```sql
-- Current live position
SELECT  'Netting (live)' AS Source,
        n.LiquidityAccountID, n.InstrumentID, n.Units, n.AvgRate, n.UpdateTime
FROM    [Hedge].[Netting] n WITH (NOLOCK)
WHERE   n.LiquidityAccountID = 10

UNION ALL

-- Latest daily snapshot
SELECT  'NettingDaily (latest snapshot)',
        nd.LiquidityAccountID, nd.InstrumentID, nd.Units, nd.AvgRate, nd.UpdateTime
FROM    [Hedge].[NettingDaily] nd WITH (NOLOCK)
WHERE   nd.LiquidityAccountID = 10
AND     nd.UpdateTime = (
            SELECT MAX(nd2.UpdateTime)
            FROM [Hedge].[NettingDaily] nd2 WITH (NOLOCK)
            WHERE nd2.LiquidityAccountID = nd.LiquidityAccountID
              AND nd2.InstrumentID = nd.InstrumentID
        )
ORDER BY InstrumentID, Source;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.NettingDaily | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.NettingDaily.sql*
