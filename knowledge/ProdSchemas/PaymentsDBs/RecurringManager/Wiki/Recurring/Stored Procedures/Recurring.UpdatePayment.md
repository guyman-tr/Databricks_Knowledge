# Recurring.UpdatePayment

> General-purpose modifier for recurring payments that can update status, reason, amount, funding, currency, version stamp, authentication, and generation - all fields are optional via ISNULL pattern.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns updated Payment row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the primary UPDATE procedure for Recurring.Payment, handling all modification scenarios: status changes (cancel, block), amount/currency adjustments, funding source updates, and optimistic concurrency stamping. All parameters except @PaymentId are optional - only the fields provided are modified, others retain their current values via ISNULL pattern.

The procedure contains nuanced conditional logic for VersionStamp and Generation fields that support the optimistic concurrency workflow used by the payment modification pipeline.

---

## 2. Business Logic

### 2.1 Selective Field Update with ISNULL

**What**: Each optional parameter updates its column only when provided; NULL means "keep current value."

**Columns/Parameters Involved**: All parameters except @PaymentId

**Rules**:
- `StatusId = ISNULL(@Status, StatusId)` - only changes if @Status provided
- `StatusReasonId = ISNULL(@StatusReason, StatusReasonId)` - only changes if provided
- ModificationDate is always set to GETUTCDATE() on any call
- Same pattern for Amount, FundingId, CurrencyId

### 2.2 VersionStamp Conditional Logic

**What**: VersionStamp behavior depends on whether a status change is happening.

**Columns/Parameters Involved**: `@Status`, `@VersionStamp`

**Rules**:
- When @Status IS NULL (no status change): `VersionStamp = @VersionStamp` - directly sets the stamp (for initiating a pending modification)
- When @Status IS NOT NULL (status change): `VersionStamp = ISNULL(@VersionStamp, VersionStamp)` - keeps existing unless explicitly provided
- This prevents status transitions from accidentally clearing a pending modification stamp

### 2.3 Generation Conditional Logic

**What**: Generation counter behavior depends on context.

**Columns/Parameters Involved**: `@Status`, `@Generation`

**Rules**:
- When @Status IS NULL (modification, not status change): `Generation = ISNULL(@Generation, 0)` - resets to 0 unless specified
- When @Status IS NOT NULL (status change): `Generation = ISNULL(@Generation, Generation)` - preserves existing
- This tracks modification rounds: resets on new modifications, preserves on status transitions

### 2.4 AuthenticationId Conditional Logic

**What**: AuthenticationId is linked to FundingId changes.

**Columns/Parameters Involved**: `@FundingID`, `@AuthenticationId`

**Rules**:
- When @FundingID IS NOT NULL (funding change): `AuthenticationId = @AuthenticationId` - directly sets (may be NULL, clearing old auth)
- When @FundingID IS NULL (no funding change): `AuthenticationId = ISNULL(@AuthenticationId, AuthenticationId)` - keeps existing unless provided

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentId | int (IN) | NO | - | CODE-BACKED | PK of the payment to update. |
| 2 | @Status | int (IN) | YES | NULL | VERIFIED | New StatusId. NULL = no status change. Maps to payment lifecycle (1=Active, 2=Cancelled, 3=Blocked, etc.). |
| 3 | @StatusReason | int (IN) | YES | NULL | CODE-BACKED | New StatusReasonId. Maps to Dictionary.StatusReason (1=RemovedMOP, 2=CancelledByUser, etc.). |
| 4 | @Amount | decimal (IN) | YES | NULL | CODE-BACKED | New recurring amount. NULL = keep current. |
| 5 | @Currency | int (IN) | YES | NULL | CODE-BACKED | New CurrencyId. NULL = keep current. |
| 6 | @FundingID | int (IN) | YES | NULL | CODE-BACKED | New payment method. NULL = keep current. When set, also controls AuthenticationId behavior. |
| 7 | @VersionStamp | nvarchar(100) (IN) | YES | NULL | VERIFIED | Optimistic concurrency token. Behavior depends on whether @Status is provided (see Business Logic 2.2). |
| 8 | @AuthenticationId | int (IN) | YES | NULL | CODE-BACKED | SCA/authentication reference. Behavior depends on whether @FundingID is provided (see Business Logic 2.4). |
| 9 | @Generation | int (IN) | YES | NULL | CODE-BACKED | Modification generation counter. Behavior depends on whether @Status is provided (see Business Logic 2.3). |

**Return Columns**: PaymentId, Cid, FundingId, Amount, CurrencyId, StatusId, CreateDate, ModificationDate, SysStartTime, SysEndTime, StatusReasonId, RecurringProgramTypeId, AuthenticationId, Generation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.Payment | MODIFIER + READER | UPDATE with selective fields, then SELECT to return |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.UpdatePayment (procedure)
└── Recurring.Payment (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.Payment | Table | UPDATE SET (selective) WHERE PaymentId, then SELECT |

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

### 8.1 Cancel a payment
```sql
EXEC Recurring.UpdatePayment @PaymentId = 200820, @Status = 2, @StatusReason = 2
```

### 8.2 Update amount and funding
```sql
EXEC Recurring.UpdatePayment @PaymentId = 200820, @Amount = 200, @FundingID = 16809115,
    @VersionStamp = 'new-guid-here', @AuthenticationId = 12345
```

### 8.3 Set version stamp for pending modification
```sql
EXEC Recurring.UpdatePayment @PaymentId = 200820, @VersionStamp = 'abc-123-def'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.UpdatePayment | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.UpdatePayment.sql*
