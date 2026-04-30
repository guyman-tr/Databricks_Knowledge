# History.BoundariesConfiguration

> Temporal history table automatically maintained by SQL Server for Hedge.BoundariesConfiguration; each row captures one past version of a hedge boundary configuration with its validity interval.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (SysEndTime, SysStartTime) - clustered index (no PK; managed by SQL Server temporal) |
| **Partition** | No |
| **Indexes** | 1 active (clustered on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.BoundariesConfiguration is the auto-managed temporal history table for Hedge.BoundariesConfiguration. SQL Server's SYSTEM_VERSIONING feature writes here automatically whenever a row in Hedge.BoundariesConfiguration is updated or deleted - the previous version is preserved here with the SysStartTime/SysEndTime interval during which it was the active configuration.

This enables point-in-time queries: "what were the hedge boundary thresholds for StrategyID=X, InstrumentID=Y as of date Z?" The primary table Hedge.BoundariesConfiguration holds only the current active configuration per (StrategyID, InstrumentID) pair. Historical versions accumulate here.

Hedge boundary configuration controls the hedging server's exposure management: for each strategy-instrument combination, it defines USD threshold ranges that trigger hedging actions and the desired exposure boundaries within those ranges. Tracking history of these settings matters for post-trade analysis, compliance, and debugging hedging behavior.

---

## 2. Business Logic

### 2.1 Temporal System Versioning Pattern

**What**: SQL Server automatically populates this table when rows in Hedge.BoundariesConfiguration change.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, all configuration columns

**Rules**:
- On UPDATE to Hedge.BoundariesConfiguration: the OLD values are copied here with SysStartTime=previous_SysStartTime, SysEndTime=GETUTCDATE()
- On DELETE from Hedge.BoundariesConfiguration: the deleted row is preserved here with SysEndTime=GETUTCDATE()
- This table is NEVER written to directly - all inserts are performed by SQL Server's temporal engine
- Do NOT query this table directly for current state - use Hedge.BoundariesConfiguration; use FOR SYSTEM_TIME AS OF syntax for point-in-time queries
- The trigger Tr_T_BoundariesConfiguration_INSERT on the main table performs a self-join UPDATE after INSERT to force SysStartTime to be set correctly by the temporal mechanism

**Diagram**:
```
Hedge.BoundariesConfiguration (current state)
  SYSTEM_VERSIONING = ON -> History.BoundariesConfiguration

  UPDATE Hedge.BoundariesConfiguration SET LowerThresholdUSD=500 WHERE StrategyID=1 AND InstrumentID=100
    -> Old row moved to History.BoundariesConfiguration with SysEndTime=GETUTCDATE()
    -> New row remains in Hedge.BoundariesConfiguration with SysStartTime=GETUTCDATE()

Point-in-time query:
  SELECT * FROM Hedge.BoundariesConfiguration
  FOR SYSTEM_TIME AS OF '2025-01-01 12:00:00'
  WHERE StrategyID=1 AND InstrumentID=100
  -- SQL Server automatically unions current + history tables
```

### 2.2 Hedge Boundary Configuration Semantics

**What**: Each row defines the exposure management parameters for one strategy-instrument pair during the recorded time period.

**Columns/Parameters Involved**: `StrategyID`, `InstrumentID`, `LowerThresholdUSD`, `UpperThresholdUSD`, `LowerBoundaryDesiredExposureUSD`, `UpperBoundaryDesiredExposureUSD`

**Rules**:
- LowerThresholdUSD / UpperThresholdUSD: the USD exposure range within which the hedge strategy monitors positions for the instrument
- LowerBoundaryDesiredExposureUSD / UpperBoundaryDesiredExposureUSD: the target exposure range the hedge server aims to achieve when it acts
- DbLoginName captures the SQL login that made the change (suser_name() computed column)
- AppLoginName captures the application context info at time of change (CONVERT(varchar(500), context_info()))

---

## 3. Data Overview

The table is empty (0 rows). No changes have been made to Hedge.BoundariesConfiguration since system versioning was enabled, so no historical versions exist yet.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StrategyID | int | NO | - | CODE-BACKED | Identifies the hedging strategy this configuration applies to. Part of the composite key (StrategyID, InstrumentID) from the parent table Hedge.BoundariesConfiguration. Implicit FK to the hedge strategy catalogue. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Identifies the financial instrument (stock, crypto, FX pair) this boundary configuration covers. Part of the composite key. Implicit FK to Trade.Instrument. |
| 3 | LowerThresholdUSD | int | NO | 0 | CODE-BACKED | Lower USD exposure threshold. Below this value the hedge strategy may trigger actions. USD-denominated integer amount. Default 0 in the parent table. |
| 4 | UpperThresholdUSD | int | NO | 0 | CODE-BACKED | Upper USD exposure threshold. Above this value the hedge strategy may trigger actions. USD-denominated integer amount. Default 0 in the parent table. |
| 5 | LowerBoundaryDesiredExposureUSD | int | NO | 0 | CODE-BACKED | Lower bound of the target exposure range the hedge server aims to achieve when it rebalances for this strategy-instrument pair. USD-denominated. Default 0 in the parent table. |
| 6 | UpperBoundaryDesiredExposureUSD | int | NO | 0 | CODE-BACKED | Upper bound of the target exposure range the hedge server aims to achieve when it rebalances for this strategy-instrument pair. USD-denominated. Default 0 in the parent table. |
| 7 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login name of the database user who last modified the parent row. Captured via suser_name() computed column in Hedge.BoundariesConfiguration at time of change. Provides a basic database-level audit trail. |
| 8 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level identity at time of change, captured from SQL Server context_info(). Allows application services to tag their changes with a service name or username for audit purposes. |
| 9 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this configuration version became active in Hedge.BoundariesConfiguration. Managed automatically by SQL Server temporal engine. Precision: 100 nanoseconds. |
| 10 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this configuration version was superseded (row was updated or deleted in Hedge.BoundariesConfiguration). Managed automatically by SQL Server temporal engine. The clustered index leads with SysEndTime for efficient point-in-time queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| StrategyID | Hedge.BoundariesConfiguration | Temporal | This row is a past version of a Hedge.BoundariesConfiguration row with matching (StrategyID, InstrumentID) |
| InstrumentID | Trade.Instrument | Implicit | Identifies the instrument the boundary config applied to |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.BoundariesConfiguration | HISTORY_TABLE | Temporal system | Parent table - SQL Server writes here automatically on UPDATE/DELETE |
| Hedge.GetBoundariesConfiguration | - | Reader (via temporal) | Reads the parent table; temporal history available via FOR SYSTEM_TIME queries |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BoundariesConfiguration (table)
```

Tables are always leaf nodes - no code-level dependencies.

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.BoundariesConfiguration | Table | Parent temporal table - this is its HISTORY_TABLE target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.BoundariesConfiguration | Table | SQL Server temporal engine writes here automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_BoundariesConfiguration | Clustered | SysEndTime ASC, SysStartTime ASC | - | - | Active |

Note: No primary key - temporal history tables are managed by SQL Server and do not require a PK. The clustered index on (SysEndTime, SysStartTime) is the standard SQL Server-recommended pattern for temporal history tables, optimizing FOR SYSTEM_TIME AS OF queries.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| None | - | Temporal history tables have no constraints - integrity enforced by SQL Server temporal engine |

Storage: ON [DICTIONARY] filegroup with PAGE compression.

---

## 8. Sample Queries

### 8.1 View full change history for a strategy-instrument pair
```sql
SELECT StrategyID, InstrumentID,
       LowerThresholdUSD, UpperThresholdUSD,
       LowerBoundaryDesiredExposureUSD, UpperBoundaryDesiredExposureUSD,
       DbLoginName, AppLoginName,
       SysStartTime, SysEndTime
FROM [History].[BoundariesConfiguration] WITH (NOLOCK)
WHERE StrategyID = @StrategyID AND InstrumentID = @InstrumentID
ORDER BY SysStartTime DESC
```

### 8.2 Point-in-time query using temporal syntax (preferred)
```sql
-- Query the parent table with FOR SYSTEM_TIME - SQL Server unions current + history automatically
SELECT StrategyID, InstrumentID,
       LowerThresholdUSD, UpperThresholdUSD,
       LowerBoundaryDesiredExposureUSD, UpperBoundaryDesiredExposureUSD
FROM [Hedge].[BoundariesConfiguration] WITH (NOLOCK)
FOR SYSTEM_TIME AS OF '2025-06-01 00:00:00'
WHERE StrategyID = @StrategyID
```

### 8.3 Find all configurations that changed in a date range
```sql
SELECT StrategyID, InstrumentID, DbLoginName, AppLoginName,
       SysStartTime AS ChangedAt,
       LowerThresholdUSD, UpperThresholdUSD
FROM [History].[BoundariesConfiguration] WITH (NOLOCK)
WHERE SysEndTime BETWEEN @StartDate AND @EndDate
ORDER BY SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Hedge.GetBoundariesConfiguration) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BoundariesConfiguration | Type: Table | Source: etoro/etoro/History/Tables/History.BoundariesConfiguration.sql*
