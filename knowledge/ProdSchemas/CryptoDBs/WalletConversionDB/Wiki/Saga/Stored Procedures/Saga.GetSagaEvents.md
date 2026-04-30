# Saga.GetSagaEvents

> Retrieves all event log entries for a specific saga run, ordered for chronological review and debugging.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: SagaEvents rows for a given SagaKey |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetSagaEvents retrieves the complete event log for a single saga run, identified by SagaKey. This is the primary diagnostic query used by operators and application code to understand what happened during a saga's execution. The events provide a narrative of notable occurrences - step transitions, errors, retries, and completions.

The procedure supports operational monitoring and incident investigation. When a saga fails or behaves unexpectedly, the event log retrieved by this procedure provides the chronological context needed for root cause analysis.

Called by the application layer to display saga execution history, or by monitoring tools to check recent saga activity.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple SELECT with SagaKey filter.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | CODE-BACKED | Business-level identifier of the saga run whose events to retrieve. Filters SagaEvents.SagaKey. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | Event surrogate key from SagaEvents |
| 2 | SagaKey | uniqueidentifier | NO | - | CODE-BACKED | Saga run identifier (matches input parameter) |
| 3 | SagaName | varchar(256) | NO | - | CODE-BACKED | Saga workflow type name |
| 4 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Distributed tracing correlation ID |
| 5 | EventType | nvarchar(32) | NO | - | CODE-BACKED | Event category label |
| 6 | EventDescription | nvarchar(128) | YES | - | CODE-BACKED | Human-readable event description |
| 7 | JsonDetails | nvarchar(1024) | YES | - | CODE-BACKED | Structured JSON event metadata |
| 8 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp of the event |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Saga.SagaEvents | SELECT source | Reads event rows by SagaKey |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetSagaEvents (procedure)
└── Saga.SagaEvents (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaEvents | Table | SELECT source - reads event rows by SagaKey |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all events for a saga
```sql
EXEC Saga.GetSagaEvents @SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E'
```

### 8.2 Get events and filter by type
```sql
-- After calling GetSagaEvents, filter in application for specific EventType
EXEC Saga.GetSagaEvents @SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E'
-- Filter results for EventType = 'StepFailed' in application code
```

### 8.3 Verify events exist for a saga
```sql
SELECT COUNT(*) AS EventCount
FROM Saga.SagaEvents WITH (NOLOCK)
WHERE SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetSagaEvents | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.GetSagaEvents.sql*
