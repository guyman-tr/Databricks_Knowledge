# Billing.RegisterRecurringExecution

> Idempotent registration of a recurring deposit execution: inserts a new tracking record if none exists for the given execution key, then returns the record regardless.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ExecutionId + @ExecutionKey (unique pair) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Recurring deposits are automated deposit executions triggered on a schedule (daily, weekly, etc.). Before executing a recurring deposit charge, the system calls `Billing.RegisterRecurringExecution` to register the execution attempt and obtain a tracking record. The procedure is idempotent: if the same execution has already been registered (matching @ExecutionId AND @ExecutionKey), it returns the existing record instead of creating a duplicate.

This idempotency is critical for retry safety - if the service crashes after registration but before completing the deposit, a retry will not create a second Billing.RecurringDeposit row. The procedure uses a MERGE statement for this check-and-insert in a single atomic operation.

---

## 2. Business Logic

### 2.1 Idempotent Insert via MERGE

**What**: Ensures exactly-once registration semantics for recurring deposit executions.

**Columns/Parameters Involved**: `@ExecutionId`, `@ExecutionKey`, `ExecutionID`, `ExecutionKey`, `CreateDate`

**Rules**:
- MERGE checks: does `Billing.RecurringDeposit` already have a row with (ExecutionID = @ExecutionId AND ExecutionKey = @ExecutionKey)?
- If NOT MATCHED (new execution): INSERT with CreateDate = GETUTCDATE().
- If MATCHED (duplicate): no action (WHEN MATCHED clause absent - effectively a no-op).
- After MERGE: always SELECTs back the full record for the (ExecutionId, ExecutionKey) pair.
- Returns: RecurringDepositID (newly assigned or existing), ExecutionID, ExecutionKey, DepositID (NULL until deposit completes), CreateDate, ModificationDate.

**Diagram**:
```
MERGE Billing.RecurringDeposit
  ON ExecutionID = @ExecutionId AND ExecutionKey = @ExecutionKey
  WHEN NOT MATCHED:
    INSERT (ExecutionID, ExecutionKey, CreateDate) VALUES (...)
  [WHEN MATCHED: no action]

SELECT full record WHERE ExecutionID = @ExecutionId AND ExecutionKey = @ExecutionKey
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecutionId | INT | NO | - | CODE-BACKED | Execution plan/schedule identifier that identifies which recurring deposit rule is being run. Part of the unique key for idempotency. |
| 2 | @ExecutionKey | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Unique GUID for this specific execution attempt. Combined with @ExecutionId forms the composite idempotency key. Allows the same execution plan to run multiple times (different GUIDs = different executions). |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | RecurringDepositID | INT | NO | - | CODE-BACKED | PK of the Billing.RecurringDeposit tracking record. Newly generated on first call, existing on retry. |
| 4 | ExecutionID | INT | NO | - | CODE-BACKED | Echo of @ExecutionId. The execution plan ID. |
| 5 | ExecutionKey | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Echo of @ExecutionKey. The execution instance GUID. |
| 6 | DepositID | INT | YES | NULL | CODE-BACKED | The actual deposit created for this recurring execution. NULL immediately after registration; populated later by Billing.SetDepositIdToRecurringDeposit when the deposit is processed. |
| 7 | CreateDate | DATETIME | NO | - | CODE-BACKED | UTC timestamp when the execution was registered. GETUTCDATE() on INSERT. |
| 8 | ModificationDate | DATETIME | YES | - | CODE-BACKED | UTC timestamp of last update. NULL initially; updated by SetDepositIdToRecurringDeposit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ExecutionId, @ExecutionKey | Billing.RecurringDeposit | MERGE (INSERT if new) | Creates the execution tracking record |

### 5.2 Referenced By (other objects point to this)

No SQL callers found. Called by the recurring deposit scheduler service before executing a charge.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RegisterRecurringExecution (procedure)
└── Billing.RecurringDeposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.RecurringDeposit | Table | MERGE target (idempotent INSERT) and SELECT source |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.SetDepositIdToRecurringDeposit | Procedure | Updates DepositID on the record created by this procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Idempotent MERGE | Atomicity | Single atomic check-and-insert. No race condition between check and insert. |

---

## 8. Sample Queries

### 8.1 Register a new recurring deposit execution

```sql
DECLARE @execKey UNIQUEIDENTIFIER = NEWID()
EXEC Billing.RegisterRecurringExecution
    @ExecutionId = 42,
    @ExecutionKey = @execKey
```

### 8.2 Retry registration (idempotent - returns same record)

```sql
-- Second call with same params returns existing row, not a new one
EXEC Billing.RegisterRecurringExecution
    @ExecutionId = 42,
    @ExecutionKey = 'a1b2c3d4-1234-5678-abcd-ef0123456789'
```

### 8.3 View recent recurring executions and their deposit status

```sql
SELECT rd.RecurringDepositID, rd.ExecutionID, rd.ExecutionKey,
       rd.DepositID, rd.CreateDate, rd.ModificationDate,
       d.PaymentStatusID
FROM Billing.RecurringDeposit rd WITH (NOLOCK)
LEFT JOIN Billing.Deposit d WITH (NOLOCK) ON d.DepositID = rd.DepositID
WHERE rd.CreateDate >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY rd.CreateDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 related analyzed (SetDepositIdToRecurringDeposit) | App Code: skipped | Corrections: 0 applied*
*Object: Billing.RegisterRecurringExecution | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.RegisterRecurringExecution.sql*
