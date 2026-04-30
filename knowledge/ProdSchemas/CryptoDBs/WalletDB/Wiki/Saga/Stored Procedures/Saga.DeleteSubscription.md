# Saga.DeleteSubscription

> Soft-deletes a message subscription by setting IsDeleted=1, removing it from active routing without physically deleting the record.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: @@ROWCOUNT as Results (rows affected) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure performs a graceful shutdown of a subscription by soft-deleting it. When a saga service instance shuts down cleanly, it calls this procedure to mark its subscription as deleted so the pub/sub infrastructure immediately stops routing messages to it, rather than waiting for the lease to expire naturally.

The soft-delete pattern (setting `IsDeleted=1` instead of physically deleting the row) preserves the subscription record for auditing and debugging. All query procedures in the saga framework filter on `IsDeleted = 0`, so a soft-deleted subscription is effectively invisible to the routing system.

The procedure uses `SubscriptionName` as the lookup key (which has a UNIQUE index), making the operation efficient. Returns @@ROWCOUNT to indicate success (1) or no-op (0 if the name doesn't exist).

---

## 2. Business Logic

### 2.1 Soft Delete Pattern

**What**: Subscriptions are never physically deleted - they are marked as inactive.

**Columns/Parameters Involved**: `@SubscriptionName`, `IsDeleted`

**Rules**:
- Sets `IsDeleted = 1` for the matching SubscriptionName
- All saga subscription queries filter `WHERE IsDeleted = 0`, immediately excluding this subscription
- Returns 1 if the subscription existed and was updated, 0 if the name was not found
- No transaction wrapping - single atomic UPDATE statement

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SubscriptionName | nvarchar(256) | NO | - | CODE-BACKED | Unique name of the subscription to soft-delete. Matched against the UNIQUE index `UX_Saga_Subscriptions_SubscriptionName`. |
| 2 | Results (output) | int | - | - | CODE-BACKED | Returns @@ROWCOUNT: 1 if the subscription was found and soft-deleted, 0 if no matching SubscriptionName exists. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SubscriptionName | Saga.Subscriptions | UPDATE (soft delete) | Sets IsDeleted=1 for the matching subscription |

### 5.2 Referenced By (other objects point to this)

No callers found within the Saga schema stored procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.DeleteSubscription (procedure)
└── Saga.Subscriptions (table) [UPDATE]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.Subscriptions | Table | UPDATE - sets IsDeleted=1 |

### 6.2 Objects That Depend On This

No dependents found within the schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Soft-delete a subscription
```sql
EXEC Saga.DeleteSubscription @SubscriptionName = N'receive-handler-pod-1'
```

### 8.2 Verify the subscription was soft-deleted
```sql
SELECT Id, SubscriptionName, IsDeleted FROM Saga.Subscriptions WITH (NOLOCK)
WHERE SubscriptionName = N'receive-handler-pod-1'
```

### 8.3 N/A
N/A - single code path.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.DeleteSubscription | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.DeleteSubscription.sql*
