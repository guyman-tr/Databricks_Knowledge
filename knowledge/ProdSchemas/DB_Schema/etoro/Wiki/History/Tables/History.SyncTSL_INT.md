# History.SyncTSL_INT

> Legacy INT-variant of History.SyncTSL, the TSL event staging buffer - identical structure but with PositionID as INT rather than BIGINT; retired after the November 2021 PositionID migration to BIGINT.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (BIGINT, NONCLUSTERED PK) |
| **Partition** | No - CLUSTERED on PositionID, NC PK on ID, both on [MAIN] filegroup |
| **Indexes** | 2 active (NONCLUSTERED PK on ID, CLUSTERED on PositionID) |

---

## 1. Business Meaning

History.SyncTSL_INT is the pre-migration legacy version of History.SyncTSL, the intermediate staging buffer for Trailing Stop Loss (TSL) adjustment events in the TSL synchronization pipeline. The only structural difference from History.SyncTSL is that `PositionID` is typed as `INT` here, whereas History.SyncTSL uses `BIGINT` to accommodate the expanded position ID space introduced in November 2021.

This table served the same function as History.SyncTSL: holding confirmed TSL events (Status IN (2,3) in Trade.SyncTSL) while they awaited batch transfer to the DAG analytics/downstream system via BCP. After the PositionID BIGINT migration, the pipeline was updated to write to History.SyncTSL exclusively, and this table was retired.

The table is currently empty (0 rows) and has no active stored procedure references. It is retained for schema historical reference and in case any legacy data tooling still references the INT-based pipeline. For full pipeline documentation, see History.SyncTSL.

---

## 2. Business Logic

### 2.1 Legacy TSL Pipeline (Retired)

**What**: Prior to November 2021, this table was used identically to History.SyncTSL in the 3-stage TSL event pipeline: Trade.SyncTSL -> History.SyncTSL_INT -> DAG/pass system.

**Columns/Parameters Involved**: `ID`, `PositionID`, `StopLoss`, `SLManualVer`, `NextThresHold`, `IsBuy`, `DateInserted`

**Rules**:
- Pipeline was retired when PositionID was expanded from INT to BIGINT (Nov 2021)
- History.SyncTSL (BIGINT PositionID) replaced this table entirely
- The TABLE SWITCH pattern used with History.SyncTSLSwitch was the same mechanism used here
- No active procedures write to or read from this table post-migration

**Diagram**:
```
[BEFORE Nov 2021]
Trade.SyncTSL (INT PositionID)
    --> History.SyncTSL_INT  (staging buffer - this table)
        --> History.SyncTSLSwitch_INT (switch twin, if existed)
            --> BCP to DAG

[AFTER Nov 2021]
Trade.SyncTSL (BIGINT PositionID)
    --> History.SyncTSL       (current staging buffer)
        --> History.SyncTSLSwitch
            --> BCP to DAG
```

---

## 3. Data Overview

Table is currently empty (0 rows). This is expected: the table was retired post-BIGINT migration and no new records are written. Historically, it held transient TSL staging records that were cleared after each BCP cycle - similar to History.SyncTSL, which also typically holds 0 rows in non-production environments.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | BIGINT | NO | - | CODE-BACKED | Unique sequence-assigned identifier for each TSL sync event. NONCLUSTERED PK. Despite the table name containing "INT" (legacy PositionID type), the ID column itself was always BIGINT to accommodate the global TSL sequence (Trade.SequenceSyncTSL). Matches the ID in History.SyncTSL. |
| 2 | PositionID | INT | NO | - | CODE-BACKED | Legacy INT position identifier - the defining difference from History.SyncTSL (which uses BIGINT). Identifies the trading position whose trailing stop loss was adjusted. Post-migration PositionIDs exceed INT range; hence this table is retired. Clustered index key for lookup by position. |
| 3 | StopLoss | dbo.dtPrice | NO | - | CODE-BACKED | The adjusted trailing stop-loss price level, expressed in the instrument's rate units using the dbo.dtPrice UDT (a decimal precision type for exchange rates). When the market price hits this level, the position closes. Inherited from Trade.SyncTSL at archival time. See History.SyncTSL Section 4 for full dtPrice context. |
| 4 | SLManualVer | SMALLINT | NO | - | CODE-BACKED | Manual stop-loss version counter. Tracks how many times the customer has manually adjusted their stop-loss on this position. Used by the downstream DAG system to distinguish TSL-driven adjustments from customer-initiated overrides. Matches Trade.SyncTSL.SLManualVer. |
| 5 | NextThresHold | dbo.dtPrice | NO | - | CODE-BACKED | The next price threshold at which the TSL will trigger another adjustment event. When the market price moves favorably past this level, a new TSL adjustment is generated and recorded in Trade.SyncTSL. Expressed in the instrument's rate units (dbo.dtPrice). |
| 6 | IsBuy | BIT | NO | - | CODE-BACKED | Position direction: 1 = Buy/Long position (TSL trails upward as price rises), 0 = Sell/Short position (TSL trails downward as price falls). Determines the direction of TSL threshold movement. |
| 7 | DateInserted | DATETIME | NO | - | CODE-BACKED | UTC timestamp when this TSL event was recorded in Trade.SyncTSL (via getutcdate() default). Preserved through the pipeline as the original event time, not the time of archival to this table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl (legacy, INT era) | Implicit FK (retired) | References the trading position whose TSL was adjusted. In the legacy INT era, all PositionIDs fit within INT range. No FK constraint defined. |

### 5.2 Referenced By (other objects point to this)

No active dependents. All procedures previously writing to this table were updated to target History.SyncTSL after the Nov 2021 BIGINT migration.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.SyncTSL_INT (table)
  (leaf - no code-level dependencies; uses dbo.dtPrice UDT as a column type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.dtPrice | User Defined Type | Column type for StopLoss and NextThresHold |

### 6.2 Objects That Depend On This

No dependents found. Retired post-BIGINT migration; no active procedures reference this table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistSyncTSL | NONCLUSTERED PK | ID ASC | - | - | Active |
| Idx_History_SyncTSL_PositionID | CLUSTERED | PositionID ASC | - | - | Active (FILLFACTOR=85) |

Note: Same index structure as History.SyncTSL. FILLFACTOR=85 on clustered index accommodates row insertions between existing PositionID values. PAGE compression on both table and index reduces storage for the archived data.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistSyncTSL | PRIMARY KEY NONCLUSTERED | Enforces uniqueness on ID; NONCLUSTERED to allow the clustered index to be on PositionID for lookup performance |

---

## 8. Sample Queries

### 8.1 Check if any legacy INT-era rows still exist
```sql
SELECT COUNT(*) AS LegacyRowCount
FROM History.SyncTSL_INT WITH (NOLOCK);
```

### 8.2 Compare schema structure to current SyncTSL
```sql
-- Check SyncTSL_INT (legacy INT PositionID)
SELECT TOP 1 * FROM History.SyncTSL_INT WITH (NOLOCK);

-- Check SyncTSL (current BIGINT PositionID)
SELECT TOP 1 * FROM History.SyncTSL WITH (NOLOCK);
```

### 8.3 Look up historical TSL events for a legacy INT-range position
```sql
SELECT
    s.ID,
    s.PositionID,
    s.StopLoss,
    s.SLManualVer,
    s.NextThresHold,
    s.IsBuy,
    s.DateInserted
FROM History.SyncTSL_INT s WITH (NOLOCK)
WHERE s.PositionID = 123456
ORDER BY s.DateInserted;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.6/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SyncTSL_INT | Type: Table | Source: etoro/etoro/History/Tables/History.SyncTSL_INT.sql*
