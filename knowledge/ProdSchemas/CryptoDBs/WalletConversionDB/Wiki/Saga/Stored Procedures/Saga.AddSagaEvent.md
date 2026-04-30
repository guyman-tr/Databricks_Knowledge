# Saga.AddSagaEvent

> Inserts a new event record into the saga event log for auditing and diagnostic purposes.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts into Saga.SagaEvents |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddSagaEvent is the sole writer to the `Saga.SagaEvents` event log table. It records notable occurrences during saga lifecycle execution - such as step transitions, errors, or operational events - providing a chronological audit trail for each saga run. The procedure accepts all event attributes as parameters and performs a simple INSERT.

This procedure enables the application-layer saga orchestrator to emit events at key points during execution. When a saga enters rollback, completes, or encounters an error, the orchestrator calls AddSagaEvent to record the event for later investigation and monitoring.

The procedure is called by the conversion worker application during saga execution. Events are later retrieved by `Saga.GetSagaEvents` for a specific saga run, or purged by `Saga.PurgeTable` when they exceed the retention window.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple INSERT procedure with direct parameter-to-column mapping.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | CODE-BACKED | Business-level identifier of the saga run this event belongs to. Maps directly to SagaEvents.SagaKey. Links the event to a specific saga run in SagaRuns. |
| 2 | @SagaName | varchar(256) | NO | - | CODE-BACKED | Name of the saga type (e.g., "CryptoToFiatSaga"). Denormalized into the event row for self-contained querying. Maps to SagaEvents.SagaName. |
| 3 | @CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Distributed tracing correlation ID for cross-service event correlation. Maps to SagaEvents.CorrelationId. |
| 4 | @EventType | nvarchar(32) | NO | - | CODE-BACKED | Categorical label for the event (e.g., step started, error occurred). Free-text, set by the application. Maps to SagaEvents.EventType. |
| 5 | @EventDescription | nvarchar(128) | NO | - | CODE-BACKED | Human-readable description of the event. Maps to SagaEvents.EventDescription. Note: parameter is NOT NULL but the column allows NULL. |
| 6 | @JsonDetails | nvarchar(128) | NO | - | CODE-BACKED | Structured JSON metadata for the event. Maps to SagaEvents.JsonDetails. Note: parameter is nvarchar(128) but the column is nvarchar(1024) - the parameter is narrower, truncating large payloads. |
| 7 | @Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp for the event. Set by the application (not GETUTCDATE()). Maps to SagaEvents.Created (partition column). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Saga.SagaEvents | INSERT target | Writes event rows to the SagaEvents event log |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.AddSagaEvent (procedure)
└── Saga.SagaEvents (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaEvents | Table | INSERT target - writes event rows |

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

### 8.1 Record a saga start event
```sql
EXEC Saga.AddSagaEvent
    @SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E',
    @SagaName = 'CryptoToFiatSaga',
    @CorrelationId = 'C41CB3AD-BEA7-46CB-8A1B-E01186B17B97',
    @EventType = 'SagaStarted',
    @EventDescription = 'Saga execution initiated',
    @JsonDetails = '{"step": 1}',
    @Created = '2026-04-15T08:00:00.000'
```

### 8.2 Record an error event
```sql
EXEC Saga.AddSagaEvent
    @SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E',
    @SagaName = 'CryptoToFiatSaga',
    @CorrelationId = 'C41CB3AD-BEA7-46CB-8A1B-E01186B17B97',
    @EventType = 'StepFailed',
    @EventDescription = 'Step 5 failed: insufficient balance',
    @JsonDetails = '{"stepIndex": 5, "error": "InsufficientBalance"}',
    @Created = '2026-04-15T08:01:30.000'
```

### 8.3 Verify event was recorded
```sql
SELECT TOP 1 * FROM Saga.SagaEvents WITH (NOLOCK)
WHERE SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E'
ORDER BY Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.AddSagaEvent | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.AddSagaEvent.sql*
