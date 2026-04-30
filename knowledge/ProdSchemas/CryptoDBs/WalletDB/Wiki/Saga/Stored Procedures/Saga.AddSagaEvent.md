# Saga.AddSagaEvent

> Inserts an operational event record into the saga event log for a given saga run, enabling post-mortem debugging and operational monitoring.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: implicit (row inserted) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records a freeform operational event during saga execution. While status transitions are tracked in `Saga.SagaRunStatuses` and step execution in `Saga.SagaSteps`, this procedure captures diagnostic events that provide additional context - warnings, errors, decision points, and notable occurrences that don't fit into the structured status/step model.

The procedure serves as the write interface for the `Saga.SagaEvents` table. It is called by the saga framework whenever a notable event occurs during saga processing that warrants logging for operational visibility or post-mortem investigation.

The procedure takes all event attributes as parameters (including the timestamp, which is passed by the application rather than generated server-side) and performs a straightforward INSERT with no validation, transactions, or error handling. This fire-and-forget design ensures event logging never blocks or slows saga execution.

---

## 2. Business Logic

No complex multi-column business logic. This is a simple INSERT procedure with direct parameter-to-column mapping.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Identifies which saga run this event belongs to. Maps to `Saga.SagaRuns.SagaKey`. Used by `Saga.GetSagaEvents` to retrieve all events for a saga. |
| 2 | @SagaName | varchar(256) | NO | - | CODE-BACKED | Saga type name, denormalized from SagaRuns for independent queryability. Expected values: `ExternalReceiveTransactionSaga`, `TravelRuleMessageReceiveSentSaga`, etc. |
| 3 | @CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Business correlation GUID, denormalized from SagaRuns. Links the event to the originating business request. |
| 4 | @EventType | nvarchar(32) | NO | - | CODE-BACKED | Short classification code for the event category (e.g., warning, error, decision). |
| 5 | @EventDescription | nvarchar(128) | NO | - | CODE-BACKED | Human-readable summary of what occurred. Note: parameter is NOT NULL in the SP signature but the column is nullable - the SP always passes a value. |
| 6 | @JsonDetails | nvarchar(128) | NO | - | CODE-BACKED | Structured JSON payload with event context. Note: SP parameter is nvarchar(128) but column is nvarchar(1024) - effective limit is 128 chars when using this procedure. |
| 7 | @Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when the event occurred. Passed by the application (not generated server-side via GETUTCDATE()), allowing the caller to set the exact event time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Saga.SagaRuns | Lookup (via SagaKey) | Identifies the parent saga run for this event |

### 5.2 Referenced By (other objects point to this)

No callers found within the Saga schema stored procedures. Called by the application saga framework directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.AddSagaEvent (procedure)
└── Saga.SagaEvents (table) [INSERT INTO]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaEvents | Table | INSERT INTO - writes event records |

### 6.2 Objects That Depend On This

No dependents found within the schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. The procedure performs a direct INSERT with no validation, no transaction wrapping, and no duplicate checks.

---

## 8. Sample Queries

### 8.1 Log an event for a saga run
```sql
EXEC Saga.AddSagaEvent
    @SagaKey = 'EBEAAEE2-EF39-480A-91BF-489ED0CF6D28',
    @SagaName = 'ExternalReceiveTransactionSaga',
    @CorrelationId = 'F08F5895-8683-4427-B047-EC441C9AE5E8',
    @EventType = 'Warning',
    @EventDescription = 'AML check returned inconclusive',
    @JsonDetails = '{"amlProvider":"Chainalysis","score":0.5}',
    @Created = '2026-04-15T10:07:00.000Z'
```

### 8.2 Verify event was written
```sql
SELECT TOP 1 * FROM Saga.SagaEvents WITH (NOLOCK)
WHERE SagaKey = 'EBEAAEE2-EF39-480A-91BF-489ED0CF6D28'
ORDER BY Id DESC
```

### 8.3 N/A
N/A - procedure has a single code path with no variations.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.AddSagaEvent | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.AddSagaEvent.sql*
