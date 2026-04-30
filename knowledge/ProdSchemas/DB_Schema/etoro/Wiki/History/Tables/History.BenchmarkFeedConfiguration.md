# History.BenchmarkFeedConfiguration

> SQL Server temporal history table for Price.BenchmarkFeedConfiguration: records all past states of benchmark price feed assignments (which price feed is designated as the quality benchmark per currency type), automatically maintained by SYSTEM_VERSIONING. Currently 0 rows - the source table has never been populated since temporal was enabled.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (BenchmarkAccountRateSourceID, CurrencyTypeID) - no PK constraint |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.BenchmarkFeedConfiguration is the SQL Server temporal system-versioning history table for `Price.BenchmarkFeedConfiguration`. It automatically captures every state change (INSERT, UPDATE, DELETE) made to the benchmark price feed configuration table, preserving complete row history with precise timestamps.

`Price.BenchmarkFeedConfiguration` configures which price feed provider is designated as the **benchmark feed** for a given currency type. This benchmark is used for price quality comparison: the view `Price.GetInstrumentRateSources` checks whether a given `AccountRateSourceID` matches a benchmark configuration entry, returning `IsBenchmark=1` and the associated `Quality` score when a match exists, and `IsBenchmark=0` with `Quality=-1` when no benchmark is configured.

**Purpose of benchmark feeds**: In a multi-provider price feed architecture, one feed per currency type is designated as the reference benchmark. Other feeds' price quality can be evaluated relative to this benchmark's declared quality score. This is used by the price server infrastructure to select or weight feeds.

**Current state**: Both the live table and the history table contain **0 rows**. The configuration was never populated since temporal versioning was activated. The infrastructure is in place but not actively used.

**Dual audit coverage**: The source table `Price.BenchmarkFeedConfiguration` has both:
1. SQL Server SYSTEM_VERSIONING temporal history (this table) - full-row snapshots with precise timestamps
2. ASM audit triggers (`AuditInsert/Update/Delete_Price_BenchmarkFeedConfiguration`) - column-level changes to `History.AuditHistory`

Additionally, the no-op INSERT trigger `TRG_T_BenchmarkFeedConfiguration` forces SQL Server temporal to capture INSERT events (same pattern as History.ActiveFeatureThreshold and History.Address - the self-UPDATE technique that fires the temporal system on INSERTs).

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: SQL Server automatically writes rows to this history table on any INSERT, UPDATE, or DELETE to Price.BenchmarkFeedConfiguration.

**Rules**:
- INSERT into source: current row gets SysStartTime=NOW, SysEndTime=9999-12-31; no history row immediately (the no-op INSERT trigger fires an UPDATE which DOES generate a history row via temporal)
- UPDATE to source: old row moved to history with SysEndTime=NOW; new row active with SysStartTime=NOW
- DELETE from source: deleted row moved to history with SysEndTime=NOW
- History rows are immutable - only SQL Server temporal can write here
- SysStartTime and SysEndTime use UTC (datetime2(7)) - consistent with other temporal tables

### 2.2 Benchmark Feed Role in Price.GetInstrumentRateSources

**What**: When the source table is populated, the benchmark configuration drives quality metadata for instrument rate sources.

**Rules**:
- `Price.GetInstrumentRateSources` joins `Price.BenchmarkFeedConfiguration BFC ON BFC.BenchmarkAccountRateSourceID = PIRS.AccountRateSourceID AND InstrumentTypeID = CurrencyTypeID`
- Returns `IsBenchmark = IIF(BenchmarkAccountRateSourceID IS NULL, 0, 1)` - flag for whether this feed is a benchmark
- Returns `Quality = ISNULL(BFC.Quality, -1)` - quality score from config, or -1 if not configured
- Since source table is empty, all instruments currently show IsBenchmark=0 and Quality=-1

---

## 3. Data Overview

0 rows. History table is empty - no benchmark feed configuration changes have been recorded since temporal versioning was activated. The source table Price.BenchmarkFeedConfiguration also contains 0 rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BenchmarkAccountRateSourceID | int | NO | - | CODE-BACKED | The AccountRateSourceID (from Price.AccountRateSource) designated as the benchmark feed for this currency type. Part of the composite PK (no formal PK constraint on history table). Used in Price.GetInstrumentRateSources to identify benchmark feeds. |
| 2 | CurrencyTypeID | int | NO | - | CODE-BACKED | The currency type for which this feed is the benchmark. FK in source table to Dictionary.CurrencyType. Matched against Trade.Instrument.InstrumentTypeID in Price.GetInstrumentRateSources. Part of the composite PK (no formal PK constraint on history table). |
| 3 | Quality | int | NO | - | CODE-BACKED | Quality score assigned to this benchmark feed for the given currency type. Used in Price.GetInstrumentRateSources as the quality metadata for instruments matched to this benchmark. Value -1 is returned for unmatched instruments (not stored in this table). |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login name at the time of the change. Computed column in source (suser_name()); stored as data here after temporal captures it. Identifies who made the configuration change. |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application context at the time of the change. Computed column in source (CONVERT(varchar(500), context_info())); stored as data here. Identifies the application that made the change. |
| 6 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row became the active configuration (i.e., when the INSERT or UPDATE was applied to Price.BenchmarkFeedConfiguration). Set by SQL Server temporal system. |
| 7 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row was superseded (i.e., when the next UPDATE or DELETE was applied to Price.BenchmarkFeedConfiguration). Set by SQL Server temporal system. Clustered index leading key - supports efficient range queries on historical states. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints on history table (temporal history tables do not carry FKs from source). In the source table:
- BenchmarkAccountRateSourceID -> Price.AccountRateSource
- CurrencyTypeID -> Dictionary.CurrencyType

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server SYSTEM_VERSIONING | Automatic | Writer | Temporal versioning engine writes all historical states here automatically when Price.BenchmarkFeedConfiguration is modified. |
| Price.GetInstrumentRateSources | (reads source table, not history directly) | Consumer of source | LEFT JOINs Price.BenchmarkFeedConfiguration to determine IsBenchmark and Quality for each instrument rate source. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BenchmarkFeedConfiguration (temporal history table)
  - automatically maintained by: Price.BenchmarkFeedConfiguration (source table)
  - consumed via source by: Price.GetInstrumentRateSources (view)
  - consumed via source by: Price.GetInstrumentAllocationData (view)
```

### 6.1 Objects This Depends On

None. Temporal history tables have no code-level dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Server temporal engine | System | Automatically writes historical rows from Price.BenchmarkFeedConfiguration changes |
| Price.GetInstrumentRateSources | View | Reads source table Price.BenchmarkFeedConfiguration for IsBenchmark/Quality flags |
| Price.GetInstrumentAllocationData | View | References Price.BenchmarkFeedConfiguration for instrument allocation data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_BenchmarkFeedConfiguration | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

**Standard temporal clustering**: (SysEndTime, SysStartTime) is the recommended index for temporal history tables. Leading SysEndTime enables efficient `FOR SYSTEM_TIME AS OF @point_in_time` queries (SQL Server uses SysEndTime >= @point AND SysStartTime <= @point).

PAGE compression applied to both history DDL and the clustered index.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none - no PK) | - | Temporal history tables have no PK constraint. Rows are identified by (BenchmarkAccountRateSourceID, CurrencyTypeID, SysStartTime). |

---

## 8. Sample Queries

### 8.1 Full history for a specific benchmark configuration
```sql
-- All historical states of a specific benchmark feed assignment
SELECT
    BenchmarkAccountRateSourceID,
    CurrencyTypeID,
    Quality,
    DbLoginName,
    AppLoginName,
    SysStartTime,
    SysEndTime,
    DATEDIFF(MINUTE, SysStartTime, SysEndTime) AS ActiveMinutes
FROM History.BenchmarkFeedConfiguration WITH (NOLOCK)
WHERE BenchmarkAccountRateSourceID = @SourceID
  AND CurrencyTypeID = @CurrencyTypeID
ORDER BY SysStartTime ASC;
```

### 8.2 Point-in-time configuration (using temporal syntax on source table)
```sql
-- What was the benchmark configuration at a specific point in time?
SELECT *
FROM Price.BenchmarkFeedConfiguration
FOR SYSTEM_TIME AS OF '2025-06-01T00:00:00';
```

### 8.3 All benchmark configurations active today
```sql
SELECT
    b.BenchmarkAccountRateSourceID,
    b.CurrencyTypeID,
    ct.[Name] AS CurrencyType,
    b.Quality,
    b.SysStartTime AS ActiveSince
FROM Price.BenchmarkFeedConfiguration b WITH (NOLOCK)
LEFT JOIN Dictionary.CurrencyType ct WITH (NOLOCK) ON b.CurrencyTypeID = ct.CurrencyTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found directly referencing this table or benchmark feed configuration.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.7/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BenchmarkFeedConfiguration | Type: Table | Source: etoro/etoro/History/Tables/History.BenchmarkFeedConfiguration.sql*
