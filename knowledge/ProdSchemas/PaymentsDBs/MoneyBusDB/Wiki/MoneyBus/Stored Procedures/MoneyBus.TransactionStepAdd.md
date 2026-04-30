# MoneyBus.TransactionStepAdd

> Inserts a new step entry into Log.TransactionStep, recording each discrete processing step during transaction execution with its status, errors, and correlation context.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT @ID - returns new TransactionStep.ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.TransactionStepAdd records each discrete processing step during a transaction's execution. Unlike TransactionLogInsert which logs API request/response pairs, this procedure logs the higher-level pipeline steps (e.g., "holdInitiate", "debitComplete", "creditFailed") with their statuses and any errors. Together, the two logging mechanisms provide complete observability into what happened during transaction processing.

The procedure writes to Log.TransactionStep (cross-schema). The @Created defaults to GETUTCDATE() if not provided. The @TransactionTypeID was added later (2023-04-23 modification) to support conditional step tracking by transaction type.

---

## 2. Business Logic

No complex business logic. Direct INSERT with default timestamp handling.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int OUTPUT | NO | - | CODE-BACKED | Returns the auto-generated IDENTITY value of the new step entry. |
| 2 | @Created | datetime | YES | GETUTCDATE() | CODE-BACKED | Optional step timestamp. Defaults to GETUTCDATE(). |
| 3 | @InitiateRequest | nvarchar(4000) | YES | NULL | CODE-BACKED | The request payload or context that initiated this step. May contain JSON with the full step input. |
| 4 | @TransactionID | bigint | YES | NULL | CODE-BACKED | The transaction this step belongs to. Nullable for steps that occur before transaction creation. |
| 5 | @StepName | nvarchar(100) | YES | NULL | CODE-BACKED | Human-readable name of the pipeline step (e.g., "holdInitiate", "debitComplete", "creditFailed"). |
| 6 | @StepStatus | nvarchar(50) | YES | NULL | CODE-BACKED | Status of the step execution (e.g., "Started", "Completed", "Failed"). |
| 7 | @Error | nvarchar(4000) | YES | NULL | CODE-BACKED | Error details if the step failed. Contains exception messages, stack traces, or provider error responses. |
| 8 | @Comment | nvarchar(4000) | YES | NULL | CODE-BACKED | Free-text comment providing additional context about the step. |
| 9 | @CorrelationID | nvarchar(100) | YES | NULL | CODE-BACKED | Distributed tracing correlation ID for linking this step to the broader request flow. |
| 10 | @TransactionTypeID | int | YES | NULL | CODE-BACKED | Transaction type classifier. Added to support type-specific step logging. Nullable for backward compatibility. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (INSERT target) | Log.TransactionStep | Writer | Creates new step log entry |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.TransactionStepAdd (procedure)
└── Log.TransactionStep (table) [INSERT INTO - cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Log.TransactionStep | Table (cross-schema) | INSERT INTO - creates step log entries |

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

### 8.1 Log a pipeline step
```sql
DECLARE @StepID INT;
EXEC MoneyBus.TransactionStepAdd @ID = @StepID OUTPUT,
    @TransactionID = 7747200,
    @StepName = 'holdInitiate', @StepStatus = 'Completed',
    @CorrelationID = 'trace-xyz-001';
SELECT @StepID AS NewStepID;
```

### 8.2 Log a failed step with error
```sql
DECLARE @StepID INT;
EXEC MoneyBus.TransactionStepAdd @ID = @StepID OUTPUT,
    @TransactionID = 7747200,
    @StepName = 'creditInitiate', @StepStatus = 'Failed',
    @Error = 'Provider returned HTTP 503: Service Unavailable',
    @CorrelationID = 'trace-xyz-001';
```

### 8.3 Find all steps for a transaction
```sql
SELECT * FROM Log.TransactionStep WITH (NOLOCK)
WHERE TransactionID = 7747200 ORDER BY Created ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.TransactionStepAdd | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.TransactionStepAdd.sql*
