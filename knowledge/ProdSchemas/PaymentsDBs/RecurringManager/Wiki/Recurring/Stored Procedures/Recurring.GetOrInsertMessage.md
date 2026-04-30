# Recurring.GetOrInsertMessage

> Idempotently creates or retrieves a recurring program message by composite key (EntityId + EntityTypeId + AdditionalData), returning the message record with an IsNew flag.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns RecurringProgramMessages record + IsNew flag |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure implements idempotent message creation for the RecurringProgramMessages outbound queue. When the system needs to send a notification about a payment or execution event, it calls this procedure which either creates a new message or returns the existing one if a duplicate already exists. The IsNew flag tells the caller whether to proceed with delivery or skip (already queued).

The composite key (EntityId, EntityTypeId, AdditionalData) ensures each entity+event combination generates exactly one message, preventing duplicate notifications even under concurrent processing.

---

## 2. Business Logic

### 2.1 Idempotent Insert with Composite Key

**What**: Ensures one message per (EntityId, EntityTypeId, AdditionalData) combination.

**Columns/Parameters Involved**: `@EntityId`, `@EntityTypeId`, `@AdditionalData`

**Rules**:
- Uses `ISNULL(AdditionalData, -1) = ISNULL(@AdditionalData, -1)` for NULL-safe comparison
- If NOT EXISTS: INSERT with all provided values, set @isNew = 1
- Always returns TOP 1 matching record + @isNew flag
- Retries defaults to 1 if NULL passed via ISNULL(@Retries, 1)
- Returns SysStartTime and SysEndTime (temporal columns) in the result set

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @EntityId | int (IN) | NO | - | CODE-BACKED | ID of the entity (PaymentId or PaymentExecutionId depending on EntityTypeId). |
| 2 | @EntityTypeId | int (IN) | NO | - | CODE-BACKED | Entity discriminator: 1=Payment, 2=PaymentExecution (Dictionary.EntityType). |
| 3 | @AdditionalData | int (IN) | YES | - | CODE-BACKED | Context data (e.g., status value). Part of idempotency key. NULL-safe comparison. |
| 4 | @MessagesTypeId | int (IN) | NO | - | CODE-BACKED | Message type: 1=PaymentExecutionResult, 2=RecurringProgramStatus. |
| 5 | @Body | nvarchar(MAX) (IN) | YES | - | CODE-BACKED | JSON payload with event details. |
| 6 | @MessageStatusId | int (IN) | NO | - | CODE-BACKED | Initial status: typically 1=New. |
| 7 | @Retries | int (IN) | NO | - | CODE-BACKED | Initial retry count. Defaults to 1 if NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.RecurringProgramMessages | WRITER + READER | Idempotent INSERT + SELECT |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.GetOrInsertMessage (procedure)
└── Recurring.RecurringProgramMessages (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.RecurringProgramMessages | Table | SELECT for existence check, INSERT for new message |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Create a payment status message
```sql
EXEC Recurring.GetOrInsertMessage @EntityId = 200820, @EntityTypeId = 1, @AdditionalData = 2,
    @MessagesTypeId = 1, @Body = '{"PaymentId":200820,"IsActive":false}', @MessageStatusId = 1, @Retries = 1
```

### 8.2 Idempotent re-call returns existing
```sql
-- Same call returns IsNew=0
EXEC Recurring.GetOrInsertMessage @EntityId = 200820, @EntityTypeId = 1, @AdditionalData = 2,
    @MessagesTypeId = 1, @Body = '{"PaymentId":200820}', @MessageStatusId = 1, @Retries = 1
```

### 8.3 Create an execution result message
```sql
EXEC Recurring.GetOrInsertMessage @EntityId = 859547, @EntityTypeId = 2, @AdditionalData = NULL,
    @MessagesTypeId = 1, @Body = '{"PaymentExecutionId":859547}', @MessageStatusId = 1, @Retries = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.GetOrInsertMessage | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.GetOrInsertMessage.sql*
