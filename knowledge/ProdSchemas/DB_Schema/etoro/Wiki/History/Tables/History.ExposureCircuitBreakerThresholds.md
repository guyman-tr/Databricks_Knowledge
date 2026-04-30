# History.ExposureCircuitBreakerThresholds

> SQL Server system-versioned temporal history table for Hedge.ExposureCircuitBreakerThresholds, recording every change to per-instrument exposure circuit breaker alert and trigger thresholds with precise row-validity timestamps for auditing configuration adjustments.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, IsOverHedged, SysStartTime, SysEndTime) - no formal PK; temporal history semantics |
| **Partition** | No |
| **Indexes** | 1 (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Hedge.ExposureCircuitBreakerThresholds`. SQL Server's system-versioning feature manages this table transparently: whenever a row in `Hedge.ExposureCircuitBreakerThresholds` is inserted, updated, or deleted, SQL Server writes the previous row state here with SysStartTime/SysEndTime stamped to record the exact validity window. No application code writes directly to this table.

`Hedge.ExposureCircuitBreakerThresholds` defines per-instrument, per-direction USD exposure circuit breaker thresholds used by the hedging engine. Each instrument has two rows in the source table: one for the over-hedged direction (IsOverHedged=1) and one for the under-hedged direction (IsOverHedged=0). When live exposure crosses `CircuitBreakerAlertThresholdUSD`, an alert fires; when it crosses `CircuitBreakerTriggerThresholdUSD`, the circuit breaker trips and can halt further execution. These thresholds are operationally critical - changes must be auditable for risk management reviews and incident post-mortems.

Data flows automatically: any UPDATE or DELETE on `Hedge.ExposureCircuitBreakerThresholds` causes SQL Server to move the current row (with original SysStartTime and the change timestamp as SysEndTime) into this history table. Additionally, a special INSERT trigger (`TRG_T_ExposureCircuitBreakerThresholds`) fires on INSERT and immediately executes a no-op UPDATE (SET InstrumentID=InstrumentID) to force SQL Server to also capture newly inserted rows into history - ensuring every threshold configuration from creation is permanently auditable. To query historical configurations, use `Hedge.ExposureCircuitBreakerThresholds FOR SYSTEM_TIME AS OF '...'`.

---

## 2. Business Logic

### 2.1 Circuit Breaker Two-Tier Threshold System

**What**: Each instrument/direction combination has two escalating USD exposure thresholds - an alert level and a hard trigger level.

**Columns/Parameters Involved**: `InstrumentID`, `IsOverHedged`, `CircuitBreakerAlertThresholdUSD`, `CircuitBreakerTriggerThresholdUSD`

**Rules**:
- Alert < Trigger: CircuitBreakerAlertThresholdUSD is always below CircuitBreakerTriggerThresholdUSD - alert fires first to give operators time to act
- CircuitBreakerTriggerThresholdUSD must be <= $10,000,000 for any tradable, publicly visible instrument - enforced by Monitor.AlertForDealingMarketDataConfigurationManager
- Two separate rows per InstrumentID: one for over-hedged exposure risk, one for under-hedged exposure risk
- All amounts are in USD regardless of the instrument's native currency

**Diagram**:
```
Exposure Exposure Monitor Alert       Circuit Breaker Trips
    |           |                           |
    v           v                           v
----+-----[AlertThresholdUSD]----------[TriggerThresholdUSD]-----> USD Exposure
    |               |                           |
  Normal         Alert fires              Execution halted /
  operation      (notification)           hedge suspended
```

### 2.2 INSERT Trigger Forces History Capture on Creation

**What**: A special INSERT trigger ensures every threshold row is recorded in history from the moment it is created, not just when it is later modified or deleted.

**Columns/Parameters Involved**: `InstrumentID`, `IsOverHedged`, `SysStartTime`, `SysEndTime`

**Rules**:
- Trigger `TRG_T_ExposureCircuitBreakerThresholds` fires FOR INSERT on `Hedge.ExposureCircuitBreakerThresholds`
- The trigger immediately executes `UPDATE A SET A.InstrumentID = A.InstrumentID` for the inserted row - a deliberate no-op update
- SQL Server temporal versioning captures every UPDATE (even no-ops) - this forces the newly inserted row to be written to this history table right away
- Without this trick, INSERT-only rows (never modified after creation) would not appear in the history table at all
- Result: this history table contains a complete audit trail from the moment each threshold is defined, not just changes after first creation

**Diagram**:
```
INSERT into Hedge.ExposureCircuitBreakerThresholds:
  (InstrumentID=1, IsOverHedged=0, AlertThreshold=500000, TriggerThreshold=2000000)
        |
        v
TRG_T_ExposureCircuitBreakerThresholds fires -> UPDATE SET InstrumentID=InstrumentID
        |
        v
SQL Server temporal engine captures "change" -> writes row to History.ExposureCircuitBreakerThresholds
  SysStartTime = creation time, SysEndTime = forced update time (milliseconds later)

Later UPDATE on same row:
  Previous version (creation -> update) -> already in History
  New version (update time -> now) -> lives in Hedge.ExposureCircuitBreakerThresholds
```

### 2.3 SQL Server System-Versioned Temporal Table Pattern

**What**: SQL Server automatically manages row versioning between Hedge.ExposureCircuitBreakerThresholds (current) and History.ExposureCircuitBreakerThresholds (historical versions), enabling point-in-time reconstruction of any instrument's circuit breaker configuration.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `InstrumentID`, `IsOverHedged`

**Rules**:
- SysStartTime = UTC timestamp when this row version became active in Hedge.ExposureCircuitBreakerThresholds
- SysEndTime = UTC timestamp when this row version was superseded; current rows in source table have SysEndTime = '9999-12-31 23:59:59.9999999'
- A single (InstrumentID, IsOverHedged) pair may appear many times here (one entry per threshold change event)
- CLUSTERED index on (SysEndTime ASC, SysStartTime ASC) is the standard SQL Server temporal history index pattern for efficient range-based queries
- DbLoginName and AppLoginName are computed columns in Hedge.ExposureCircuitBreakerThresholds (suser_name() and CONVERT(varchar(500), context_info())), materialized here at version creation to capture who made the change

---

## 3. Data Overview

| InstrumentID | IsOverHedged | AlertThresholdUSD | TriggerThresholdUSD | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|---|
| (empty) | (empty) | (empty) | (empty) | (empty) | (empty) | Table currently has 0 rows. Either Hedge.ExposureCircuitBreakerThresholds has never been modified since system provisioning, or historical rows have been pruned. The INSERT trigger ensures all future changes will be captured here. |

*Note: No live data available at documentation time. Row structure and meaning derived from source table DDL and Monitor.AlertForDealingMarketDataConfigurationManager procedure.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Trading instrument identifier. Matches the InstrumentID in the source table `Hedge.ExposureCircuitBreakerThresholds` PK (InstrumentID, IsOverHedged). Multiple rows with the same InstrumentID+IsOverHedged represent successive threshold configuration versions. Implicit FK to Trade.Instrument - no constraint in this history table per SQL Server temporal history table conventions. |
| 2 | IsOverHedged | bit | NO | - | CODE-BACKED | The hedging direction this threshold row governs. 1 = over-hedged direction (circuit breaker for when the instrument has more hedge than needed, excess long exposure), 0 = under-hedged direction (circuit breaker for when the instrument has less hedge than needed, excess short/open exposure). Forms the second component of the source table's composite PK - each instrument has exactly two threshold rows, one per direction. |
| 3 | CircuitBreakerAlertThresholdUSD | money | NO | - | CODE-BACKED | USD exposure amount at which an alert notification fires. First tier of the two-tier circuit breaker system. When live instrument exposure (over-hedged or under-hedged depending on IsOverHedged) exceeds this amount, the risk/hedging monitoring system generates an alert for operator attention. Always less than CircuitBreakerTriggerThresholdUSD. All values in USD regardless of instrument currency. |
| 4 | CircuitBreakerTriggerThresholdUSD | money | NO | - | CODE-BACKED | USD exposure amount at which the circuit breaker actually trips, potentially halting further hedging or execution for this instrument. Second tier of the two-tier system. Monitor.AlertForDealingMarketDataConfigurationManager validates that this value does not exceed $10,000,000 for tradable, publicly visible instruments (FeedID=1, Tradable=1, VisibleInternallyOnly=0). Exceeding the $10M limit generates a monitoring alert. |
| 5 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login name (suser_name()) of the database session that made the configuration change captured in this version. Computed column in Hedge.ExposureCircuitBreakerThresholds, materialized into this history table at version creation time. Identifies the operator or service account that changed the threshold. NULL if the session context was not set. |
| 6 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level login from SQL Server context_info() at time of change. Computed column in Hedge.ExposureCircuitBreakerThresholds as CONVERT(varchar(500), context_info()). Populated by application services that set context_info before modifying threshold configuration. NULL if the calling application did not set context_info. |
| 7 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version became active in Hedge.ExposureCircuitBreakerThresholds. GENERATED ALWAYS AS ROW START in the source table. Records when the threshold configuration was set. Due to the INSERT trigger pattern (Section 2.2), the initial-creation version has SysStartTime very slightly before SysEndTime (milliseconds apart for the trigger-forced no-op update). Subsequent versions have longer validity windows. |
| 8 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version was superseded by a new threshold configuration. GENERATED ALWAYS AS ROW END in the source table. CLUSTERED index leading column for efficient temporal range scans by time window. SysEndTime close to SysStartTime (milliseconds apart) marks rows created by the INSERT trigger capture pattern. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | History.Instrument | Implicit | Identifies which trading instrument's circuit breaker thresholds this historical version records. No FK constraint in history table (SQL Server temporal history tables never carry FK constraints). For full instrument metadata at the same point in time, join to History.Instrument on InstrumentID and overlapping SysStartTime/SysEndTime windows. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.ExposureCircuitBreakerThresholds | SYSTEM_VERSIONING | Temporal history source | Hedge.ExposureCircuitBreakerThresholds is configured with `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[ExposureCircuitBreakerThresholds])`. All historical versions are automatically routed here by SQL Server on UPDATE/DELETE, and by the INSERT trigger on creation. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ExposureCircuitBreakerThresholds (table)
- no code-level dependencies (leaf table, temporal history)
```

This object has no code-level dependencies. As a SQL Server-managed temporal history table, it is populated automatically by the database engine.

### 6.1 Objects This Depends On

No dependencies. Temporal history tables have no FK constraints or code references.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ExposureCircuitBreakerThresholds | Table | Source temporal table - SQL Server automatically writes previous row versions here on UPDATE/DELETE; INSERT trigger forces capture on creation |
| Monitor.AlertForDealingMarketDataConfigurationManager | Stored Procedure | Reads the source table Hedge.ExposureCircuitBreakerThresholds (not this history table directly) to validate CircuitBreakerTriggerThresholdUSD <= $10,000,000 for tradable instruments |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ExposureCircuitBreakerThresholds | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (DATA_COMPRESSION=PAGE) |

No primary key constraint. The CLUSTERED index on (SysEndTime, SysStartTime) is the standard SQL Server temporal history index pattern, optimized for temporal range queries. Table stored with PAGE data compression.

### 7.2 Constraints

None. Temporal history tables intentionally have no CHECK, UNIQUE, DEFAULT, or FOREIGN KEY constraints - these all reside on the source table `Hedge.ExposureCircuitBreakerThresholds`.

---

## 8. Sample Queries

### 8.1 What were an instrument's circuit breaker thresholds on a specific date?

```sql
-- Use FOR SYSTEM_TIME on the source table, not this history table directly
SELECT
    e.InstrumentID,
    e.IsOverHedged,
    e.CircuitBreakerAlertThresholdUSD,
    e.CircuitBreakerTriggerThresholdUSD,
    e.SysStartTime,
    e.SysEndTime,
    e.DbLoginName
FROM Hedge.ExposureCircuitBreakerThresholds FOR SYSTEM_TIME AS OF '2025-06-01T00:00:00' e WITH (NOLOCK)
WHERE e.InstrumentID = @InstrumentID;
```

### 8.2 Full threshold change history for a specific instrument

```sql
SELECT
    h.InstrumentID,
    h.IsOverHedged,
    h.CircuitBreakerAlertThresholdUSD,
    h.CircuitBreakerTriggerThresholdUSD,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidUntil,
    h.DbLoginName AS ChangedBy,
    DATEDIFF(SECOND, h.SysStartTime, h.SysEndTime) AS VersionDurationSeconds
FROM History.ExposureCircuitBreakerThresholds h WITH (NOLOCK)
WHERE h.InstrumentID = @InstrumentID
ORDER BY h.IsOverHedged, h.SysStartTime ASC;
```

### 8.3 Find all threshold changes in a time window across all instruments

```sql
SELECT
    h.InstrumentID,
    h.IsOverHedged,
    h.CircuitBreakerAlertThresholdUSD AS OldAlert,
    h.CircuitBreakerTriggerThresholdUSD AS OldTrigger,
    h.SysEndTime AS ChangeTime,
    h.DbLoginName AS ChangedBy,
    DATEDIFF(SECOND, h.SysStartTime, h.SysEndTime) AS PriorVersionDurationSeconds
FROM History.ExposureCircuitBreakerThresholds h WITH (NOLOCK)
WHERE h.SysEndTime >= @StartDate
  AND h.SysEndTime <  @EndDate
  -- Exclude INSERT-trigger-forced captures (milliseconds apart = creation events, not real changes)
  AND DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100
ORDER BY h.SysEndTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Monitor.AlertForDealingMarketDataConfigurationManager) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ExposureCircuitBreakerThresholds | Type: Table | Source: etoro/etoro/History/Tables/History.ExposureCircuitBreakerThresholds.sql*
