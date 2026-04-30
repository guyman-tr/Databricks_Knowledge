# Recurring.RevertPayment

> Reverts a pending payment modification by restoring the original FundingId and Amount, using VersionStamp as an optimistic concurrency guard to prevent stale rollbacks.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns updated Payment row (or empty if guard failed) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure implements the rollback side of the optimistic concurrency pattern on Recurring.Payment. When a customer initiates a payment modification (e.g., changing their recurring amount or payment method), the system sets a VersionStamp on the payment. If the modification needs to be rolled back (e.g., the new payment method validation fails), RevertPayment restores the original values - but ONLY if the VersionStamp still matches, preventing stale rollbacks.

After revert, VersionStamp is cleared to NULL (no pending modification), and FundingId/Amount are restored to the provided values.

---

## 2. Business Logic

### 2.1 Optimistic Concurrency Revert

**What**: Rolls back a pending modification using VersionStamp as a concurrency guard.

**Columns/Parameters Involved**: `@PaymentId`, `@VersionStamp`, `@FundingId`, `@Amount`, `@AuthenticationId`, `@Generation`

**Rules**:
- UPDATE WHERE `PaymentId = @PaymentId AND VersionStamp LIKE @VersionStamp`
- If another process already changed/cleared the VersionStamp, the UPDATE affects 0 rows (safe no-op)
- Sets: FundingId = @FundingId, Amount = @Amount, VersionStamp = NULL (cleared), AuthenticationId = @AuthenticationId
- Generation = ISNULL(@Generation, Generation) - preserves existing if not provided
- Uses OUTPUT INSERTED to return the reverted payment state
- Returns empty result set if the VersionStamp guard fails (concurrency conflict)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentId | int (IN) | NO | - | CODE-BACKED | PK of the payment to revert. |
| 2 | @FundingId | int (IN) | NO | - | CODE-BACKED | Original funding source to restore. |
| 3 | @Amount | money (IN) | NO | - | CODE-BACKED | Original amount to restore. |
| 4 | @VersionStamp | nvarchar(100) (IN) | NO | - | VERIFIED | Concurrency guard. Must match current VersionStamp or update is a no-op. LIKE comparison used (not exact =). |
| 5 | @AuthenticationId | int (IN) | YES | NULL | CODE-BACKED | Authentication reference to restore. |
| 6 | @Generation | int (IN) | YES | NULL | CODE-BACKED | Generation counter. Preserves existing if NULL. |

**Return Columns** (via OUTPUT INSERTED): PaymentId, Cid, FundingId, Amount, CurrencyId, StatusId, CreateDate, ModificationDate, StatusReasonId, RecurringProgramTypeId, VersionStamp.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.Payment | MODIFIER | UPDATE with VersionStamp guard, OUTPUT INSERTED |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.RevertPayment (procedure)
└── Recurring.Payment (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.Payment | Table | UPDATE WHERE PaymentId AND VersionStamp LIKE |

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

### 8.1 Revert a payment modification
```sql
EXEC Recurring.RevertPayment @PaymentId = 200817, @FundingId = 17985890, @Amount = 50,
    @VersionStamp = '963654ff-ff08-4e7b-8381-632b64ce750c'
```

### 8.2 Revert with authentication
```sql
EXEC Recurring.RevertPayment @PaymentId = 200817, @FundingId = 17985890, @Amount = 50,
    @VersionStamp = '963654ff-ff08-4e7b-8381-632b64ce750c', @AuthenticationId = 12247
```

### 8.3 Check if revert was applied (returns empty if guard failed)
```sql
-- If VersionStamp no longer matches, returns empty result set
EXEC Recurring.RevertPayment @PaymentId = 200817, @FundingId = 100, @Amount = 100,
    @VersionStamp = 'wrong-stamp-will-not-match'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.RevertPayment | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.RevertPayment.sql*
