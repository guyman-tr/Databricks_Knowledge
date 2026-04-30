# History.SyncTSLSwitch

> Structural twin of History.SyncTSL used exclusively in the atomic TABLE SWITCH operation that enables zero-downtime BCP transfer of TSL events to the DAG downstream system.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (BIGINT, NONCLUSTERED PK) |
| **Partition** | No - CLUSTERED on PositionID, NC PK on ID, both on [HISTORY] filegroup |
| **Indexes** | 2 active (NONCLUSTERED PK on ID, CLUSTERED on PositionID) |

---

## 1. Business Meaning

History.SyncTSLSwitch is a structural mirror of History.SyncTSL, maintained solely to enable SQL Server's `ALTER TABLE ... SWITCH TO` metadata operation. The TABLE SWITCH is a near-instantaneous (metadata-only) operation that atomically renames the two tables in place, allowing History.SyncTSL to be handed off for BCP transfer without locking it against new incoming TSL events.

This table must be an exact structural copy of History.SyncTSL - identical columns, data types, indexes, filegroup placement, and compression settings - because SQL Server requires this for the SWITCH operation to succeed.

The data flow in the TSL pipeline's Stage 3:
1. `ALTER TABLE History.SyncTSL SWITCH TO History.SyncTSLSwitch` - History.SyncTSL is instantly emptied (its rows now live in SyncTSLSwitch), and History.SyncTSL is again available for Stage 2 writes
2. `History.MoveRecsFromHistorySyncTSLToPass_BCP` runs BCP on History.SyncTSLSwitch (the data is now safe from concurrent modification)
3. `TRUNCATE TABLE History.SyncTSLSwitch` clears it after successful BCP

This table should always be empty outside of the brief BCP window. For full TSL pipeline documentation, see History.SyncTSL.

---

## 2. Business Logic

### 2.1 TABLE SWITCH Mechanism

**What**: The SWITCH operation exchanges the internal page pointers of two identically-structured tables as a metadata update - no data is physically moved.

**Columns/Parameters Involved**: All columns (must match History.SyncTSL exactly)

**Rules**:
- History.SyncTSLSwitch MUST have identical schema to History.SyncTSL (same column names, types, nullability, indexes, filegroup, compression) - any mismatch causes the SWITCH to fail
- After SWITCH: History.SyncTSL is empty and immediately available for new Stage 2 inserts; History.SyncTSLSwitch holds all the data for BCP
- BCP reads from SyncTSLSwitch while SyncTSL continues to receive new records - zero downtime
- After successful BCP: SyncTSLSwitch is TRUNCATED, returning it to the empty state
- If BCP fails: SyncTSLSwitch retains the data; the pipeline can retry BCP without re-fetching from Trade.SyncTSL

**Diagram**:
```
Stage 3 of TSL Pipeline:

Before SWITCH:
  History.SyncTSL      [rows: 0..N]   <- Stage 2 writes here
  History.SyncTSLSwitch [rows: 0]     <- empty, waiting

SWITCH operation (instant, metadata only):
  ALTER TABLE History.SyncTSL SWITCH TO History.SyncTSLSwitch

After SWITCH:
  History.SyncTSL       [rows: 0]     <- available for new Stage 2 writes
  History.SyncTSLSwitch [rows: N]     <- holds the batch for BCP

BCP runs against SyncTSLSwitch -> sends to DAG system

TRUNCATE History.SyncTSLSwitch       <- cleared after successful BCP
  History.SyncTSLSwitch [rows: 0]    <- ready for next cycle
```

---

## 3. Data Overview

Table is normally empty. It holds data only during the BCP transfer window (seconds to minutes per cycle). In non-production environments this table will always be 0 rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | BIGINT | NO | - | CODE-BACKED | TSL event sequence ID from Trade.SequenceSyncTSL. NONCLUSTERED PK. Must match History.SyncTSL.ID exactly (same type, same constraint type) to satisfy TABLE SWITCH requirements. |
| 2 | PositionID | BIGINT | NO | - | CODE-BACKED | BIGINT trading position identifier. CLUSTERED index key. Must match History.SyncTSL.PositionID exactly. Post-Nov 2021 BIGINT era (distinguishes from the retired History.SyncTSL_INT). |
| 3 | StopLoss | dbo.dtPrice | NO | - | CODE-BACKED | Trailing stop-loss price at the time of the TSL adjustment event, using the dbo.dtPrice UDT (decimal precision for exchange rates). Must match History.SyncTSL.StopLoss type exactly including UDT. |
| 4 | SLManualVer | SMALLINT | NO | - | CODE-BACKED | Manual stop-loss version counter inherited from Trade.SyncTSL. Tracks customer-initiated manual adjustments vs. automatic TSL movements. Must match History.SyncTSL.SLManualVer exactly. |
| 5 | NextThresHold | dbo.dtPrice | NO | - | CODE-BACKED | Next TSL trigger threshold price, in instrument rate units (dbo.dtPrice). When market crosses this level, a new TSL adjustment event is generated. Must match History.SyncTSL.NextThresHold exactly. |
| 6 | IsBuy | BIT | NO | - | CODE-BACKED | Position direction: 1 = Buy/Long (TSL trails upward), 0 = Sell/Short (TSL trails downward). Must match History.SyncTSL.IsBuy exactly. |
| 7 | DateInserted | DATETIME | NO | - | CODE-BACKED | UTC timestamp of original TSL event creation in Trade.SyncTSL. Preserved through the pipeline. Must match History.SyncTSL.DateInserted exactly. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | Implicit | Inherits the position reference from History.SyncTSL during SWITCH. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.MoveRecsFromTradeSyncTSLToPass | - | SWITCH target + TRUNCATE | Receives History.SyncTSL rows via TABLE SWITCH, then truncates after BCP |
| History.MoveRecsFromHistorySyncTSLToPass_BCP | - | Reader (BCP source) | Reads all rows for BCP transfer to the DAG system |
| History.MoveRecsFromDagSyncTslToPass | - | Referenced | Part of the broader DAG sync process that uses this table |
| BackOffice.P_GetTrailingStopLossHistory | - | Reader | Queries TSL history data, potentially from this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.SyncTSLSwitch (table)
  (leaf - no code-level dependencies; uses dbo.dtPrice UDT as column type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.dtPrice | User Defined Type | Column type for StopLoss and NextThresHold (must match History.SyncTSL exactly for SWITCH) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.MoveRecsFromTradeSyncTSLToPass | Stored Procedure | SWITCH target (receives SyncTSL rows) + TRUNCATE after BCP |
| History.MoveRecsFromHistorySyncTSLToPass_BCP | Stored Procedure | BCP source - reads all rows for DAG transfer |
| History.MoveRecsFromDagSyncTslToPass | Stored Procedure | Part of DAG sync pipeline using this table |
| BackOffice.P_GetTrailingStopLossHistory | Stored Procedure | Reader of TSL history data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistSyncTSL_BIGINT1Switch | NONCLUSTERED PK | ID ASC | - | - | Active (PAGE compression) |
| Idx_History_SyncTSL_PositionID_BIGINT11Switch | CLUSTERED | PositionID ASC | - | - | Active (FILLFACTOR=85, PAGE compression) |

Note: Indexes mirror History.SyncTSL exactly - required for TABLE SWITCH compatibility. FILLFACTOR=85 and PAGE compression match the source table.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistSyncTSL_BIGINT1Switch | PRIMARY KEY NONCLUSTERED | Enforces uniqueness on ID; NONCLUSTERED to allow CLUSTERED on PositionID (same as SyncTSL) |

---

## 8. Sample Queries

### 8.1 Check if BCP is currently in progress (table has data)
```sql
SELECT COUNT(*) AS RowsInSwitch
FROM History.SyncTSLSwitch WITH (NOLOCK);
-- > 0 means BCP is currently in progress or failed mid-cycle
```

### 8.2 Review rows awaiting BCP transfer
```sql
SELECT TOP 10
    sw.ID,
    sw.PositionID,
    sw.StopLoss,
    sw.NextThresHold,
    sw.IsBuy,
    sw.DateInserted
FROM History.SyncTSLSwitch sw WITH (NOLOCK)
ORDER BY sw.DateInserted;
```

### 8.3 Compare switch table and staging table row counts (pipeline health check)
```sql
SELECT
    'History.SyncTSL' AS TableName, COUNT(*) AS RowCount
    FROM History.SyncTSL WITH (NOLOCK)
UNION ALL
SELECT
    'History.SyncTSLSwitch', COUNT(*)
    FROM History.SyncTSLSwitch WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 found (MoveRecsFromTradeSyncTSLToPass, MoveRecsFromHistorySyncTSLToPass_BCP, MoveRecsFromDagSyncTslToPass, BackOffice.P_GetTrailingStopLossHistory) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SyncTSLSwitch | Type: Table | Source: etoro/etoro/History/Tables/History.SyncTSLSwitch.sql*
