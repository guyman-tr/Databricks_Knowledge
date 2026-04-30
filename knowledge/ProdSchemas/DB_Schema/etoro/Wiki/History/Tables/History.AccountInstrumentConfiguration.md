# History.AccountInstrumentConfiguration

> Temporal history table for Hedge.AccountInstrumentConfiguration, automatically capturing all changes to per-account per-instrument hedge execution configuration over time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Clustered index on (SysEndTime, SysStartTime) - temporal history access pattern |
| **Partition** | No |
| **Indexes** | 1 active (clustered on SysEndTime, SysStartTime, PAGE compressed) |

---

## 1. Business Meaning

History.AccountInstrumentConfiguration is the SQL Server system-versioning history table for `Hedge.AccountInstrumentConfiguration`. It is populated automatically by the SQL Server temporal mechanism — no procedure ever writes to it directly. Every time a row in `Hedge.AccountInstrumentConfiguration` is inserted or updated, the old version of that row is moved here with its validity period (SysStartTime to SysEndTime), creating a complete audit trail of configuration changes over time.

The source table `Hedge.AccountInstrumentConfiguration` defines execution throttling rules for hedge accounts per instrument: maximum execution unit sizes (with threshold-based upper/lower bounds), rate limits (max requests per interval), and limit rate rounding precision. These settings control how aggressively the hedge system can execute at a liquidity account for a given instrument. Without this history table, there would be no way to audit "what were the execution limits for Account 308 on InstrumentID 1016586 on 2025-12-01?" — which is critical for post-incident analysis of hedge execution behavior.

Data flows in automatically: SQL Server moves rows from `Hedge.AccountInstrumentConfiguration` into this table whenever a row is updated or deleted. The INSERT trigger `Tr_T_AccountInstrumentConfiguration_INSERT` on the source table performs a no-op UPDATE (sets columns to themselves) which tricks the temporal system into recording INSERTs as history entries too. To query point-in-time state, use `Hedge.AccountInstrumentConfiguration FOR SYSTEM_TIME AS OF @PointInTime` — SQL Server automatically joins with this history table.

---

## 2. Business Logic

### 2.1 Temporal History Access Pattern

**What**: As a SQL Server system-versioned history table, this table is accessed via temporal queries against the source table, not queried directly.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- SysStartTime: the UTC moment this row version became active in Hedge.AccountInstrumentConfiguration
- SysEndTime: the UTC moment this row version was superseded (by an UPDATE) or removed (by DELETE)
- A row with SysEndTime = 9999-12-31 23:59:59.9999999 is currently active (still in the source table) - such rows typically do NOT appear here
- Clustered index on (SysEndTime ASC, SysStartTime ASC) enables efficient FOR SYSTEM_TIME AS OF queries
- To see configuration at a point in time: `SELECT * FROM Hedge.AccountInstrumentConfiguration FOR SYSTEM_TIME AS OF '2025-12-01'`

**Diagram**:
```
Hedge.AccountInstrumentConfiguration (current state):
  AccountID=308, InstrumentID=1016586, LimitRoundPrecision=2, SysStart=2026-02-17

History.AccountInstrumentConfiguration (all past versions):
  AccountID=308, InstrumentID=1016586, LimitRoundPrecision=4, SysStart=2025-11-20, SysEnd=2026-02-12
  AccountID=308, InstrumentID=1016586, LimitRoundPrecision=2, SysStart=2026-02-12, SysEnd=2026-02-17
```

### 2.2 INSERT Capture via Trigger Workaround

**What**: A trigger on the source table forces INSERTs to appear in history by performing a no-op UPDATE.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- SQL Server SYSTEM_VERSIONING normally only captures UPDATEs and DELETEs in history (INSERTs create the first current row)
- Trigger `Tr_T_AccountInstrumentConfiguration_INSERT` runs FOR INSERT and executes `UPDATE A SET A.InstrumentID=A.InstrumentID, A.AccountID=A.AccountID` which modifies nothing but forces SQL Server to write the inserted row to history
- This ensures every INSERT also appears in History.AccountInstrumentConfiguration, enabling full lifecycle tracking (not just changes)
- The SysStartTime/SysEndTime of the history row from an INSERT will have very close timestamps (milliseconds apart)

---

## 3. Data Overview

839 historical row versions across 9 distinct hedge accounts, spanning May 2025 to February 2026. All MaxExecutionUnits* and rate-limit columns were NULL in the most recent rows, indicating these throttling features are configured at a higher level or not actively used on these accounts. LimitRoundPrecision is the primary actively-managed column.

| AccountID | InstrumentID | LimitRoundPrecision | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|
| 308 | 1048319 | 4 | 2025-11-20 09:46:26 | 2026-02-12 11:54:48 | Historical version of Account 308's config for InstrumentID 1048319 with 4-decimal rounding. Was changed on 2026-02-12 (likely to 2-decimal precision). |
| 308 | 1016586 | 2 | 2026-02-17 10:27:40 | 2026-02-17 10:27:40 | INSERT-triggered history row (SysStart = SysEnd, sub-millisecond apart). Captures the initial creation of the configuration row. |
| 10 | 1016586 | 2 | 2026-02-17 10:27:40 | 2026-02-17 10:27:40 | Account 10 initial config capture for same instrument on same day - suggests a batch provisioning operation added multiple account-instrument configs simultaneously. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountID | int | NO | - | CODE-BACKED | Hedge/execution account identifier. Small integers (10, 308, etc.) represent hedge server accounts, not customer IDs. Part of the natural key (AccountID, InstrumentID) for the source Hedge.AccountInstrumentConfiguration table. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Financial instrument identifier. Combined with AccountID identifies which account-instrument pair this configuration version applied to. Maps to the instrument being hedged (currency pair, stock, crypto, etc.). |
| 3 | MaxExecutionUnitsThreshold | int | YES | - | NAME-INFERRED | Threshold unit count for switching between upper and lower execution bounds. When the execution request is above this threshold, UpperBound applies; below it, LowerBound applies. NULL in most current rows - this dynamic threshold control is not actively used on most accounts. |
| 4 | MaxExecutionUnitsUpperBound | int | YES | - | NAME-INFERRED | Maximum execution units allowed per request when above MaxExecutionUnitsThreshold. Controls the ceiling for large hedge executions. NULL when threshold-based dynamic sizing is not configured. |
| 5 | MaxExecutionUnitsLowerBound | int | YES | - | NAME-INFERRED | Maximum execution units per request when below MaxExecutionUnitsThreshold. Controls the ceiling for smaller hedge executions. NULL when threshold-based dynamic sizing is not configured. |
| 6 | ExecutionUnitsStep | int | YES | - | NAME-INFERRED | Step increment for adjusting execution unit size. Used in adaptive sizing algorithms to scale hedge execution up or down. NULL when step-based adjustment is not configured. |
| 7 | MaxRequestedPerInterval | int | YES | - | NAME-INFERRED | Maximum number of hedge execution requests allowed within the IntervalPeriodSeconds window. Rate limiter for hedge request frequency per account-instrument pair. NULL when rate limiting is not active. |
| 8 | IntervalPeriodSeconds | int | YES | - | NAME-INFERRED | Duration of the rate-limit interval in seconds (paired with MaxRequestedPerInterval). Defines the rolling window for request count enforcement. NULL when rate limiting is not active. |
| 9 | LimitRoundPrecision | smallint | NO | -1 | CODE-BACKED | Decimal precision for rounding limit rates (stop-loss, take-profit rates) for hedge orders on this account-instrument pair. Values seen: 2 (2 decimal places) and 4 (4 decimal places). Default -1 means no rounding override (use system default). This is the most actively modified column - its change in 839 history rows reflects limit precision updates during instrument configuration management. |
| 10 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this row version became the active configuration in Hedge.AccountInstrumentConfiguration. Generated by SQL Server temporal system. Provides the "valid from" bound for point-in-time queries. |
| 11 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this row version was replaced or removed from Hedge.AccountInstrumentConfiguration. Generated by SQL Server temporal system. For INSERT-triggered rows: equals SysStartTime (nearly identical). For superseded rows: the moment an UPDATE replaced this version. |
| 12 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | Database login name of the session that made the change. Computed column in source (suser_name()), captured as literal value in history. Enables audit trail: identifies which service account or DBA session modified the configuration. |
| 13 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application-level login name, captured from SQL Server context_info() at change time. Computed column in source (CONVERT(varchar, context_info())). Identifies the application or user session responsible for the change, beyond the database login. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. History tables do not carry FK constraints - they are raw snapshots from the source table.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.AccountInstrumentConfiguration | (temporal system) | Source Table | SQL Server automatically moves superseded rows from the source table into this history table via SYSTEM_VERSIONING. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.AccountInstrumentConfiguration (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies. History tables do not have FK constraints.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountInstrumentConfiguration | Table | Source table - SQL Server temporal mechanism writes superseded rows here automatically. Point-in-time queries via FOR SYSTEM_TIME implicitly join to this table. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_AccountInstrumentConfiguration | CLUSTERED (PAGE compressed) | SysEndTime ASC, SysStartTime ASC | - | - | Active |

**Note**: SysEndTime-first ordering is the SQL Server recommended pattern for temporal history tables. It optimizes FOR SYSTEM_TIME AS OF queries because SQL Server filters on SysEndTime >= @PointInTime AND SysStartTime <= @PointInTime, and placing SysEndTime first improves selectivity for point-in-time lookups.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none) | - | Temporal history tables have no PK or FK constraints by SQL Server design - they are append-only snapshot stores. |

---

## 8. Sample Queries

### 8.1 Get configuration history for a specific account-instrument pair
```sql
SELECT
    AccountID,
    InstrumentID,
    MaxExecutionUnitsThreshold,
    MaxExecutionUnitsUpperBound,
    MaxExecutionUnitsLowerBound,
    LimitRoundPrecision,
    MaxRequestedPerInterval,
    IntervalPeriodSeconds,
    SysStartTime,
    SysEndTime,
    DbLoginName,
    AppLoginName
FROM History.AccountInstrumentConfiguration WITH (NOLOCK)
WHERE AccountID = 308
  AND InstrumentID = 1016586
ORDER BY SysStartTime ASC;
```

### 8.2 Point-in-time configuration (use temporal syntax on source table)
```sql
-- What was the configuration for all accounts on 2025-12-01?
SELECT
    AccountID,
    InstrumentID,
    LimitRoundPrecision,
    MaxExecutionUnitsThreshold,
    MaxRequestedPerInterval,
    IntervalPeriodSeconds
FROM Hedge.AccountInstrumentConfiguration
FOR SYSTEM_TIME AS OF '2025-12-01T00:00:00.000'
ORDER BY AccountID, InstrumentID;
```

### 8.3 Find recent configuration changes with who changed them
```sql
SELECT
    AccountID,
    InstrumentID,
    LimitRoundPrecision,
    MaxRequestedPerInterval,
    IntervalPeriodSeconds,
    SysStartTime  AS ChangedAt,
    SysEndTime    AS ReplacedAt,
    DbLoginName,
    AppLoginName
FROM History.AccountInstrumentConfiguration WITH (NOLOCK)
WHERE SysStartTime >= DATEADD(day, -30, GETUTCDATE())
ORDER BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 8.0/10, Logic: 9.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 7 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.AccountInstrumentConfiguration | Type: Table | Source: etoro/etoro/History/Tables/History.AccountInstrumentConfiguration.sql*
