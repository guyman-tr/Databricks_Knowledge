# Dictionary.AggregationLastValue

> Operational tracking table that stores the last-processed watermark (ID and timestamp) per source table for incremental data aggregation jobs, enabling efficient ETL-style processing without re-scanning entire tables.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AggregationLastValueID (INT IDENTITY, no PK constraint) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 0 (heap — no indexes) |

---

## 1. Business Meaning

Dictionary.AggregationLastValue tracks the high-water mark for incremental data aggregation processes. Each row represents a source table and the last ID/timestamp that was successfully processed during an aggregation run. This allows aggregation jobs to pick up where they left off instead of re-processing the entire source table.

Without this table, aggregation jobs would need to either scan all historical data on every run (extremely expensive for tables like History.Credit with 2B+ rows) or rely on external state tracking. This table provides a lightweight, database-internal solution for incremental processing.

The table is read and updated by BackOffice.UpsertIntoAggregationTables (the main aggregation engine), BackOffice.UpsertIntoAggregationTablesAction, and BackOffice.UpsertIntoAggregationTables_Test. Monitor.ALERT_AggregationLastValue_DataDog monitors the table for staleness (alerting if aggregation hasn't run recently). Synonyms dbo.RW_AggregationLastValue provide cross-database access. A companion History table (Dictionary.AggregationLastValue_History) tracks watermark changes over time.

---

## 2. Business Logic

### 2.1 Incremental Processing Pattern

**What**: High-water mark tracking for efficient incremental data aggregation.

**Columns/Parameters Involved**: `TableName`, `IncreasingColumnName`, `LastSampleID`, `LastSampleDateTime`

**Rules**:
- Each row tracks one source table's aggregation progress
- `LastSampleID` stores the maximum ID value that was successfully aggregated — next run starts from LastSampleID + 1
- `LastSampleDateTime` stores when the last aggregation run completed
- The aggregation engine (BackOffice.UpsertIntoAggregationTables) reads the watermark, processes new rows from the source table WHERE ID > LastSampleID, then updates the watermark
- Monitor.ALERT_AggregationLastValue_DataDog checks if LastSampleDateTime is too old, triggering alerts for stale aggregations

### 2.2 Monitored Source Tables

**What**: Which source tables are tracked for incremental aggregation.

**Columns/Parameters Involved**: `TableName`, `IncreasingColumnName`

**Rules**:
- History.Credit tracked by CreditID — financial transaction aggregation (2B+ rows)
- History.Login tracked by LoggedOut — login session aggregation
- The IDENTITY(1,1) NOT FOR REPLICATION on AggregationLastValueID suggests cross-server replication scenarios where IDs shouldn't auto-generate on replicas

---

## 3. Data Overview

| AggregationLastValueID | TableName | IncreasingColumnName | LastSampleID | Meaning |
|---|---|---|---|---|
| 1 | History.Credit | CreditID | 2,174,670,153 | Financial transaction aggregation. Processing credit records incrementally by CreditID. The 2.1B watermark shows this is a massive table with billions of historical transactions. |
| 2 | History.Login | LoggedOut | 1 | Login session aggregation. Processing login records by logout timestamp. Low watermark suggests this aggregation may be inactive or recently reset. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AggregationLastValueID | int | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Auto-incrementing row identifier. NOT FOR REPLICATION prevents identity generation on subscriber databases in replication topology. No PK constraint — table is a heap. |
| 2 | TableName | varchar(255) | YES | - | CODE-BACKED | Fully qualified name of the source table being aggregated (e.g., 'History.Credit', 'History.Login'). Nullable to support future schema-less configurations. |
| 3 | IncreasingColumnName | varchar(255) | YES | - | CODE-BACKED | Name of the monotonically increasing column used as the watermark (e.g., 'CreditID', 'LoggedOut'). The aggregation engine queries WHERE [IncreasingColumnName] > LastSampleID. |
| 4 | LastSampleID | bigint | YES | - | CODE-BACKED | The maximum value of the increasing column that was successfully processed in the last aggregation run. Next run processes rows WHERE column > LastSampleID. BIGINT to handle tables with billions of rows (History.Credit has 2B+). |
| 5 | LastSampleDateTime | datetime | YES | - | CODE-BACKED | Timestamp of when the last aggregation run completed for this source table. Monitored by Monitor.ALERT_AggregationLastValue_DataDog for staleness detection — alerts trigger if this timestamp is too old. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.UpsertIntoAggregationTables | - | SELECT/UPDATE | Main aggregation engine — reads watermark, processes new data, updates watermark |
| BackOffice.UpsertIntoAggregationTablesAction | - | SELECT/UPDATE | Action-based aggregation processing |
| BackOffice.UpsertIntoAggregationTables_Test | - | SELECT/UPDATE | Test version of aggregation engine |
| Monitor.ALERT_AggregationLastValue_DataDog | - | SELECT | Monitors LastSampleDateTime for staleness alerts |
| dbo.RW_AggregationLastValue | - | Synonym | Cross-database access alias |
| Dictionary.AggregationLastValue_History | - | History | Temporal tracking of watermark changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.UpsertIntoAggregationTables | Stored Procedure | Reader/Writer — main aggregation engine |
| BackOffice.UpsertIntoAggregationTablesAction | Stored Procedure | Reader/Writer — action aggregation |
| Monitor.ALERT_AggregationLastValue_DataDog | Stored Procedure | Reader — staleness monitoring |
| dbo.RW_AggregationLastValue | Synonym | Cross-database alias |

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. Table is a heap on PRIMARY filegroup.

### 7.2 Constraints

None. No PK, no FK, no unique constraints. Minimal schema for a configuration/state table.

---

## 8. Sample Queries

### 8.1 Check all aggregation watermarks
```sql
SELECT  AggregationLastValueID,
        TableName,
        IncreasingColumnName,
        LastSampleID,
        LastSampleDateTime
FROM    Dictionary.AggregationLastValue WITH (NOLOCK)
ORDER BY AggregationLastValueID;
```

### 8.2 Find stale aggregations (not run in 24 hours)
```sql
SELECT  TableName,
        LastSampleDateTime,
        DATEDIFF(HOUR, LastSampleDateTime, GETUTCDATE()) AS HoursSinceLastRun
FROM    Dictionary.AggregationLastValue WITH (NOLOCK)
WHERE   LastSampleDateTime < DATEADD(HOUR, -24, GETUTCDATE());
```

### 8.3 Show aggregation progress with row estimates
```sql
SELECT  alv.TableName,
        alv.IncreasingColumnName,
        alv.LastSampleID,
        alv.LastSampleDateTime,
        DATEDIFF(MINUTE, alv.LastSampleDateTime, GETUTCDATE()) AS MinutesBehind
FROM    Dictionary.AggregationLastValue alv WITH (NOLOCK)
ORDER BY alv.LastSampleDateTime ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AggregationLastValue | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AggregationLastValue.sql*
