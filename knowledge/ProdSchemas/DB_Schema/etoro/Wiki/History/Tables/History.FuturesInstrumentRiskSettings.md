# History.FuturesInstrumentRiskSettings

> SQL Server system-versioned temporal history table for Trade.FuturesInstrumentRiskSettings, recording every change to the stop-loss and take-profit percentage buffer configurations for futures instruments.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, SysStartTime, SysEndTime) - no formal PK; temporal history semantics |
| **Partition** | No (stored on [PRIMARY] filegroup) |
| **Indexes** | 1 (CLUSTERED on SysEndTime ASC, SysStartTime ASC, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Trade.FuturesInstrumentRiskSettings`. SQL Server's system-versioning manages this table transparently: whenever a row in `Trade.FuturesInstrumentRiskSettings` is inserted, updated, or deleted, the previous row state is written here with SysStartTime/SysEndTime bracketing the validity window.

`Trade.FuturesInstrumentRiskSettings` stores two risk buffer percentages for each futures instrument: `StopLossPercentageBuffer` and `TakeProfitPercentageBuffer`. These define a safety margin applied around customer-set stop-loss and take-profit price levels. For futures instruments (which can have high intraday volatility and execution gaps), a percentage buffer ensures that order execution is not triggered by momentary price noise near the configured level.

1,404 history rows span July 2025 to March 2026 across 13 distinct instruments. Production-active futures instruments (IDs 18, 27, 481, 482, 484) have the most history; synthetic/test instruments (200000+) have minimal history. The high row counts for InstrumentID=481 (741 rows) and InstrumentID=18 (328 rows) reflect active configuration testing - the `Trade.UpsertFuturesInstrumentRiskSettings` MERGE procedure uses the same values but is called repeatedly by the OpsFlowAPI service.

Changes are made exclusively by the `OpsFlowAPI` service account via the `EtoroOps.Configurations` tool.

---

## 2. Business Logic

### 2.1 SL/TP Buffer Percentage Configuration

**What**: Each futures instrument has a stop-loss buffer and a take-profit buffer, expressed as percentages. These are applied during order execution to prevent false triggers near configured price levels.

**Columns/Parameters Involved**: `InstrumentID`, `StopLossPercentageBuffer`, `TakeProfitPercentageBuffer`

**Rules**:
- Source table PK is InstrumentID (not IDENTITY) - one row per instrument
- Default value for both buffers when not specified: 2.00% (enforced in `Trade.UpsertFuturesInstrumentRiskSettings`)
- Observed range: 1-100% for StopLossPercentageBuffer, 1-50% for TakeProfitPercentageBuffer (extreme values from testing)
- Typical production values: 2-5% for standard instruments; 3% observed for InstrumentID=18
- InstrumentIDs 200000+ are synthetic/test futures instruments

**Known instrument configurations (from history)**:
| InstrumentID | SL Buffer Range | TP Buffer Range | Notes |
|---|---|---|---|
| 18 | 1-100% | 1-30% | Active production instrument, 328 history rows |
| 27 | 2% | 2% | Stable config, 101 history rows (mostly re-upserts at same value) |
| 481 | 1-100% | 1-50% | Most active, 741 history rows - significant configuration experimentation |
| 482 | 2-20% | 2-20% | 196 history rows |
| 484 | 5-30% | 6-30% | 15 history rows |
| 200000-204013 | 2% | 2-5% | Synthetic/test instruments, minimal history |

### 2.2 MERGE Upsert Pattern with TVP

**What**: The sole write path uses a MERGE statement via a table-valued parameter, allowing batch updates to multiple instruments simultaneously.

**Columns/Parameters Involved**: `InstrumentID`, `StopLossPercentageBuffer`, `TakeProfitPercentageBuffer`

**Rules**:
- `Trade.UpsertFuturesInstrumentRiskSettings` accepts `@FuturesInstrumentRiskSettings Trade.Tv_FuturesInstrumentRiskSettings READONLY` (table-valued parameter)
- MERGE: UPDATE if InstrumentID exists (only updates non-null source values, preserving existing value otherwise); INSERT with DEFAULT 2.00% for new instruments
- Repeated calls with same values still generate history rows (each MERGE UPDATE creates a new temporal version even if values unchanged)

### 2.3 SQL Server Temporal + INSERT Trigger Capture

**What**: Same dual-capture pattern: temporal versioning for UPDATE/DELETE, INSERT trigger for creation events.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- INSERT trigger `Tr_T_FuturesInstrumentRiskSettings_INSERT` fires a no-op UPDATE (SET InstrumentID=InstrumentID) on InstrumentID match to force SQL Server to write the new row into history
- Zero-duration rows (SysStartTime=SysEndTime) are INSERT trigger captures
- AppLoginName format: "email;EtoroOps.Configurations" with trailing space padding (e.g., "alexre@etoro.com;EtoroOps.Configurations   ") - different from null-byte padding observed in other tables; this tool stores the value as a fixed-width space-padded string
- DbLoginName: "OpsFlowAPI" - the operations flow API service account

---

## 3. Data Overview

| InstrumentID | StopLossPercentageBuffer | TakeProfitPercentageBuffer | DbLoginName | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|---|
| 18 | 3.00% | 3.00% | OpsFlowAPI | 2026-03-18 18:18 | 2026-03-19 08:57 | Latest version before superseded. Changed by alexre@etoro.com via EtoroOps.Configurations. 52,770s duration. |
| 18 | 3.00% | 3.00% | OpsFlowAPI | 2026-03-18 18:17 | 2026-03-18 18:18 | Rapid re-upsert (53s duration). Same values, new temporal version. OpsFlowAPI testing cycle. |
| 481 | (varies) | (varies) | OpsFlowAPI | 2025-07 | 2026-03 | 741 rows - most active instrument. SL tested from 1% to 100%. |
| 27 | 2.00% | 2.00% | OpsFlowAPI | 2025-07 | 2026-03 | Stable: always 2% for both buffers. 101 rows of re-upserts at same value. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The futures instrument for which these risk buffers apply. PK in source (not IDENTITY). Implicit FK to Trade.Instrument. One configuration row per instrument in the source table. Multiple history rows with same InstrumentID = successive configuration versions. Observed IDs include production instruments (18, 27, 481, 482, 484) and synthetic/test instruments (200000-204013). |
| 2 | StopLossPercentageBuffer | decimal(10,2) | NO | - | CODE-BACKED | Percentage buffer applied to customer-configured stop-loss levels on this futures instrument. Prevents false triggers due to momentary price noise near the SL. Default 2.00% when not specified in the MERGE upsert. Observed range: 1-100% (extreme values reflect configuration testing). Typical production value: 2-5%. |
| 3 | TakeProfitPercentageBuffer | decimal(10,2) | NO | - | CODE-BACKED | Percentage buffer applied to customer-configured take-profit levels on this futures instrument. Same purpose as StopLossPercentageBuffer but for TP. Default 2.00%. Observed range: 1-50%. Can be configured independently from StopLossPercentageBuffer (asymmetric SL/TP buffers allowed). |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login (suser_name()) at time of change. Computed in source, materialized here. Observed: "OpsFlowAPI" - the operations flow API service account that exclusively manages these settings. |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application context from context_info() at time of change. Format: "email;EtoroOps.Configurations" with trailing space padding (e.g., "alexre@etoro.com;EtoroOps.Configurations   "). Different from the null-byte padding pattern used by ConfigurationManager and trading-opstool-api - this tool stores context_info as a space-padded fixed-width string. Identifies the specific operator who triggered the configuration change via OpsFlow. |
| 6 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this configuration version became active. For INSERT-trigger-captured rows, equals SysEndTime (zero-duration). |
| 7 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version was superseded. CLUSTERED index leading column. Frequent repeated upserts (same value) produce many short-duration history rows with small DurationMs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | History.Instrument | Implicit | The futures instrument these risk settings apply to. No FK in history table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FuturesInstrumentRiskSettings | SYSTEM_VERSIONING | Temporal history source | All superseded row versions routed here; INSERT trigger captures creations. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.FuturesInstrumentRiskSettings (table)
- no code-level dependencies (leaf table, temporal history)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FuturesInstrumentRiskSettings | Table | Source temporal table |
| Trade.UpsertFuturesInstrumentRiskSettings | Stored Procedure | MERGE upsert: inserts new and updates existing buffer configurations per instrument |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_FuturesInstrumentRiskSettings | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (DATA_COMPRESSION=PAGE, on [PRIMARY] filegroup) |

### 7.2 Constraints

None on history table. Source table has: CLUSTERED PK on InstrumentID (FILLFACTOR=90, DATA_COMPRESSION=PAGE).

---

## 8. Sample Queries

### 8.1 What buffer percentages were configured for an instrument on a specific date?

```sql
SELECT
    firs.InstrumentID,
    firs.StopLossPercentageBuffer,
    firs.TakeProfitPercentageBuffer,
    firs.SysStartTime,
    firs.SysEndTime
FROM Trade.FuturesInstrumentRiskSettings FOR SYSTEM_TIME AS OF '2026-01-01T00:00:00' firs WITH (NOLOCK)
WHERE firs.InstrumentID = @InstrumentID;
```

### 8.2 Change history for an instrument's risk buffers

```sql
SELECT
    h.InstrumentID,
    h.StopLossPercentageBuffer,
    h.TakeProfitPercentageBuffer,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidUntil,
    h.DbLoginName AS ChangedBy,
    LEFT(h.AppLoginName, CHARINDEX(';', h.AppLoginName + ';') - 1) AS OperatorEmail,
    DATEDIFF(SECOND, h.SysStartTime, h.SysEndTime) AS VersionDurationSecs
FROM History.FuturesInstrumentRiskSettings h WITH (NOLOCK)
WHERE h.InstrumentID = @InstrumentID
  AND DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100  -- exclude INSERT captures
ORDER BY h.SysStartTime;
```

### 8.3 All buffer configuration changes in a time window

```sql
SELECT
    h.InstrumentID,
    h.StopLossPercentageBuffer,
    h.TakeProfitPercentageBuffer,
    h.SysEndTime AS ChangeTime,
    h.DbLoginName AS ChangedBy,
    LEFT(h.AppLoginName, CHARINDEX(';', h.AppLoginName + ';') - 1) AS OperatorEmail
FROM History.FuturesInstrumentRiskSettings h WITH (NOLOCK)
WHERE h.SysEndTime >= @StartDate
  AND h.SysEndTime < @EndDate
  AND DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100
ORDER BY h.SysEndTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Trade.UpsertFuturesInstrumentRiskSettings) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.FuturesInstrumentRiskSettings | Type: Table | Source: etoro/etoro/History/Tables/History.FuturesInstrumentRiskSettings.sql*
