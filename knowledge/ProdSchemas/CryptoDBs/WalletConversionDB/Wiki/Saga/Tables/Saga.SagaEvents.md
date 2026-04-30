# Saga.SagaEvents

> Partitioned event log capturing notable occurrences during saga orchestration runs for auditing, debugging, and operational monitoring.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint IDENTITY) + Created (composite PK CLUSTERED) |
| **Partition** | Yes - DatesToFilegroup scheme on Created column (weekly partitions through 2040) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

SagaEvents is an append-only event log that records notable occurrences during the lifecycle of saga runs. Each event captures what happened (EventType), a description, optional JSON details, and the saga context (SagaKey, SagaName, CorrelationId). This provides an audit trail and diagnostic resource for understanding saga behavior, investigating failures, and monitoring operations.

Without this table, operators would have no visibility into what happened inside a saga run beyond its current status and step states. When a saga fails or behaves unexpectedly, the events log provides the chronological narrative of what occurred, enabling root cause analysis.

Events are written exclusively by `Saga.AddSagaEvent`, which receives all event attributes as parameters. Events are queried by `Saga.GetSagaEvents`, which retrieves all events for a given SagaKey. The table is partitioned by Created date using weekly partitions (DatesToFilegroup scheme) and old partitions are truncated by `Saga.PurgeTable`, keeping the table size manageable. The table currently has 0 rows, indicating either recent purging or low saga activity.

---

## 2. Business Logic

### 2.1 Event Logging Pattern

**What**: SagaEvents implements a write-once, read-by-saga-key event sourcing pattern for saga audit trails.

**Columns/Parameters Involved**: `SagaKey`, `EventType`, `EventDescription`, `JsonDetails`, `Created`

**Rules**:
- Events are immutable once written - no UPDATE or DELETE procedures exist (only partition-level TRUNCATE via PurgeTable)
- Each event is tied to a specific saga run via SagaKey (not via SagaRuns.Id, but via the business-level GUID)
- EventType categorizes the event (e.g., step started, step failed, rollback initiated) while EventDescription provides human-readable context
- JsonDetails allows structured metadata to be attached to any event (capped at 1024 characters)
- The composite PK (Id + Created) enables partition-aligned queries and efficient partition-level truncation

### 2.2 Data Retention via Partition Purging

**What**: Events are retained for a configurable time window and purged by truncating entire weekly partitions.

**Columns/Parameters Involved**: `Created`

**Rules**:
- `Saga.PurgeTable` accepts a table name and time span in weeks, truncating partitions older than the threshold
- The partition scheme (DatePartitionFunctionByWeek2040) provides weekly granularity from creation through 2040
- Truncation by partition is an O(1) operation regardless of row count, avoiding expensive DELETE operations
- The commented example in PurgeTable uses `'Saga.SagaEvents'` as the reference table, confirming this is a primary purge target

---

## 3. Data Overview

Table is currently empty (0 rows). Events are periodically purged via partition truncation by `Saga.PurgeTable`.

| Id | SagaKey | SagaName | EventType | Meaning |
|----|---------|----------|-----------|---------|
| *(no data)* | | | | Events are transient - written during saga execution and purged after the retention window |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint IDENTITY(1,1) | NO | IDENTITY | CODE-BACKED | Auto-incrementing surrogate key. Part of composite PK with Created to enable partition-aligned clustering. Not referenced by other tables. |
| 2 | SagaKey | uniqueidentifier | NO | - | CODE-BACKED | Business-level identifier for the saga run this event belongs to. Links to `Saga.SagaRuns.SagaKey` (implicit - no FK constraint). Used by `GetSagaEvents` to retrieve all events for a saga. |
| 3 | SagaName | varchar(256) | NO | - | CODE-BACKED | Name of the saga type (e.g., the conversion workflow name). Denormalized from SagaRuns for self-contained event querying without JOINs. |
| 4 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Distributed tracing correlation identifier. Enables cross-service event correlation for the same business operation across multiple systems. |
| 5 | EventType | nvarchar(32) | NO | - | CODE-BACKED | Categorical label for the event (e.g., step started, step completed, error occurred). Free-text field set by the application - not backed by a lookup table. |
| 6 | EventDescription | nvarchar(128) | YES | - | CODE-BACKED | Human-readable description of the event. Optional additional context beyond what EventType conveys. NULL when the EventType alone is sufficient. |
| 7 | JsonDetails | nvarchar(1024) | YES | - | CODE-BACKED | Structured JSON payload containing event-specific metadata. Capped at 1024 characters. NULL when no additional structured data is needed. Note: parameter in AddSagaEvent is nvarchar(128) which is narrower than the column (1024). |
| 8 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when the event was recorded. Partition column (DatesToFilegroup weekly scheme). Part of composite PK. Set by the application via @Created parameter in AddSagaEvent. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SagaKey | Saga.SagaRuns | Implicit (no FK constraint) | Links event to the saga run that produced it, via SagaRuns.SagaKey |

### 5.2 Referenced By (other objects point to this)

No other objects reference this table directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Saga.AddSagaEvent | Stored Procedure | WRITER - inserts event rows |
| Saga.GetSagaEvents | Stored Procedure | READER - retrieves all events for a SagaKey |
| Saga.PurgeTable | Stored Procedure | DELETER - truncates old partitions (referenced in comments as example target) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaEvents | CLUSTERED | Id ASC, Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_SagaEvents | PRIMARY KEY | Composite PK on (Id, Created). Created is included to enable partition alignment - the PK must contain the partition column for partition-level operations. DATA_COMPRESSION = PAGE. |

---

## 8. Sample Queries

### 8.1 Get all events for a specific saga run
```sql
SELECT Id, SagaKey, SagaName, EventType, EventDescription, JsonDetails, Created
FROM Saga.SagaEvents WITH (NOLOCK)
WHERE SagaKey = @SagaKey
ORDER BY Created ASC
```

### 8.2 Find recent events by type
```sql
SELECT TOP 20 SagaKey, SagaName, EventType, EventDescription, Created
FROM Saga.SagaEvents WITH (NOLOCK)
WHERE EventType = @EventType
AND Created > DATEADD(HOUR, -24, GETUTCDATE())
ORDER BY Created DESC
```

### 8.3 Count events by type for operational monitoring
```sql
SELECT EventType, COUNT(*) AS EventCount
FROM Saga.SagaEvents WITH (NOLOCK)
WHERE Created > DATEADD(HOUR, -1, GETUTCDATE())
GROUP BY EventType
ORDER BY EventCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.SagaEvents | Type: Table | Source: WalletConversionDB/Saga/Tables/Saga.SagaEvents.sql*
