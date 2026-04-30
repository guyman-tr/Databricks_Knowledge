# Scheduler.Ids

> A table-valued parameter type used to pass a list of integer IDs in bulk to stored procedures that operate on multiple records at once.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | User Defined Type |
| **Key Identifier** | Single-column table type: `Id` (int) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.Ids is a table-valued parameter (TVP) type that enables batch operations across the Scheduler schema. Instead of calling a stored procedure once per record in a loop, the application passes a set of integer IDs in a single call, reducing round-trips between the RecurringScheduler worker service and the database.

This type exists because the Scheduler processes executions in bulk. When the RecurringScheduler K8S worker picks up a batch of executions to process, it needs to update their statuses in a single atomic operation rather than issuing individual UPDATE statements. Without this type, batch status updates would require either dynamic SQL with comma-delimited ID lists or repeated single-row calls.

The RecurringScheduler worker service (eToro.Payments.RecurringScheduler) populates this type from in-memory collections of Payment IDs or Execution IDs, then passes it as a READONLY parameter to stored procedures. The type is consumed by procedures that need to filter or join against a caller-supplied set of IDs.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple structural type that serves as a parameter container. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for User Defined Type. This type defines a structure, not persistent data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | The integer identifier being passed in bulk. Semantics depend on the consuming procedure: for Scheduler.GetPlansWithLastAndNextExecutions, this carries PaymentId values (external payment identifiers from the Recurring schema). For Scheduler.UpdateExecutionsStatus, this carries ExecutionId values (PK of Scheduler.Execution). The NOT NULL constraint ensures no null IDs leak into batch operations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a structural type with no foreign keys.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Scheduler.GetPlansWithLastAndNextExecutions | @PaymentIds | Parameter Type | Accepts a list of PaymentId values to retrieve plans with their last and next execution details |
| Scheduler.UpdateExecutionsStatus | @ExecutionIds | Parameter Type | Accepts a list of ExecutionId values to update their status in a single batch operation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.GetPlansWithLastAndNextExecutions | Stored Procedure | Parameter type for @PaymentIds (READONLY) |
| Scheduler.UpdateExecutionsStatus | Stored Procedure | Parameter type for @ExecutionIds (READONLY) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (inline) | NOT NULL | Id column is NOT NULL - prevents null values from being passed in batch operations |

---

## 8. Sample Queries

### 8.1 Pass a list of payment IDs to retrieve plans with executions
```sql
DECLARE @PaymentIds Scheduler.Ids;
INSERT INTO @PaymentIds (Id) VALUES (1001), (1002), (1003);
EXEC Scheduler.GetPlansWithLastAndNextExecutions @PaymentIds = @PaymentIds, @IncludeExecutions = 1;
```

### 8.2 Batch update execution statuses to Done (6)
```sql
DECLARE @ExecutionIds Scheduler.Ids;
INSERT INTO @ExecutionIds (Id) VALUES (5001), (5002), (5003);
EXEC Scheduler.UpdateExecutionsStatus @ExecutionIds = @ExecutionIds, @ExecutionStatus = 6;
```

### 8.3 Populate from a query result for dynamic batch operations
```sql
DECLARE @Ids Scheduler.Ids;
INSERT INTO @Ids (Id)
SELECT e.ExecutionId
FROM Scheduler.Execution e WITH (NOLOCK)
WHERE e.ExecutionStatusId = 3 -- Sent
  AND e.ActualExecutionDate < DATEADD(HOUR, -1, GETUTCDATE());
-- Pass @Ids to a batch procedure
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Scheduler](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1922891789/Recurring+Scheduler) | Confluence | RecurringScheduler is a K8S worker service owned by MIMO US team, connecting to RecurringManager DB and Azure Service Bus for processing |

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.Ids | Type: User Defined Type | Source: RecurringManager/Scheduler/User Defined Types/Scheduler.Ids.sql*
