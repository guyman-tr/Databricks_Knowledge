# Recurring.UpdateMessageStatus

> Updates the delivery status of a recurring program message and returns the updated record, using the composite key (EntityId + EntityTypeId + AdditionalData + MessagesTypeId) for lookup.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns updated RecurringProgramMessages row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure transitions a message's delivery status in the outbound queue (e.g., from New to Sent, or New to Failed). Used by the message delivery service after attempting to send a notification to downstream consumers. The composite key lookup matches the same idempotency key used by GetOrInsertMessage.

---

## 2. Business Logic

### 2.1 Status Transition with Composite Key

**What**: Updates MessageStatusId for a message identified by (EntityId, EntityTypeId, AdditionalData, MessagesTypeId).

**Columns/Parameters Involved**: `@EntityId`, `@EntityTypeId`, `@AdditionalData`, `@MessagesTypeId`, `@MessageStatusId`

**Rules**:
- UPDATE SET MessageStatusId = @MessageStatusId, ModificationDate = GETUTCDATE()
- WHERE uses NULL-safe comparison: `ISNULL(AdditionalData, -1) = ISNULL(@AdditionalData, -1)`
- Returns TOP 1 matching record after update (including temporal columns SysStartTime, SysEndTime)
- Typical transitions: 1 (New) -> 2 (Sent) on success, 1 (New) -> 3 (Failed) on failure

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @EntityId | int (IN) | NO | - | CODE-BACKED | Entity ID (PaymentId or PaymentExecutionId). |
| 2 | @EntityTypeId | int (IN) | NO | - | CODE-BACKED | Entity discriminator: 1=Payment, 2=PaymentExecution. |
| 3 | @AdditionalData | int (IN) | YES | - | CODE-BACKED | Context data. NULL-safe comparison in WHERE clause. |
| 4 | @MessagesTypeId | int (IN) | NO | - | CODE-BACKED | Message type: 1=PaymentExecutionResult, 2=RecurringProgramStatus. |
| 5 | @MessageStatusId | int (IN) | NO | - | CODE-BACKED | New status to set: 1=New, 2=Sent, 3=Failed (Dictionary.MessageStatus). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.RecurringProgramMessages | MODIFIER + READER | UPDATE MessageStatusId, then SELECT to return |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.UpdateMessageStatus (procedure)
└── Recurring.RecurringProgramMessages (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.RecurringProgramMessages | Table | UPDATE + SELECT by composite key |

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

### 8.1 Mark a message as sent
```sql
EXEC Recurring.UpdateMessageStatus @EntityId = 200820, @EntityTypeId = 1, @AdditionalData = 2,
    @MessagesTypeId = 1, @MessageStatusId = 2
```

### 8.2 Mark a message as failed
```sql
EXEC Recurring.UpdateMessageStatus @EntityId = 200820, @EntityTypeId = 1, @AdditionalData = 2,
    @MessagesTypeId = 1, @MessageStatusId = 3
```

### 8.3 Update an execution-level message
```sql
EXEC Recurring.UpdateMessageStatus @EntityId = 859547, @EntityTypeId = 2, @AdditionalData = NULL,
    @MessagesTypeId = 1, @MessageStatusId = 2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.UpdateMessageStatus | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.UpdateMessageStatus.sql*
