# Recurring.DD_Alert_NotTakenPaymentExecutions

> DataDog-formatted version of Alert_NotTakenPaymentExecutions. Same detection logic with scalar value output for metric ingestion.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar value + FirstStuckExecution |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

DataDog-compatible version of Recurring.Alert_NotTakenPaymentExecutions. Detects payment executions where Scheduler.Execution was sent but PaymentExecution remains Planned. Returns always one row with `value` (0 or count) for DataDog custom query monitoring. Reformatted by Shay Oren (2022-12-28, DBAD-19).

---

## 2. Business Logic

### 2.1 Same as Alert_NotTakenPaymentExecutions

**What**: Identical detection - see [Recurring.Alert_NotTakenPaymentExecutions](Recurring.Alert_NotTakenPaymentExecutions.md).

**Rules**: Same logic, DataDog-compatible output format (OUTER APPLY pattern).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MinutsToAlert | int (IN) | NO | 30 | CODE-BACKED | Minutes threshold for stuck detection. |
| 2 | @GapInDays | int (IN) | NO | 2 | CODE-BACKED | Days back to search. |
| 3 | @FromDate | datetime (IN) | YES | NULL | CODE-BACKED | Override start of window. |
| 4 | @ToDate | datetime (IN) | YES | NULL | CODE-BACKED | Override end of window. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.PaymentExecution | READER | StatusId=1 check |
| - | Scheduler.Execution | READER (Cross-Schema) | ExecutionStatusId=3, ActualExecutionDate window |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.DD_Alert_NotTakenPaymentExecutions (procedure)
├── Recurring.PaymentExecution (table)
└── Scheduler.Execution (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecution | Table | INNER JOIN, filter StatusId=1 |
| Scheduler.Execution | Table | INNER JOIN on PaymentExecutionId |

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

### 8.1 Run for DataDog
```sql
EXEC Recurring.DD_Alert_NotTakenPaymentExecutions
```

### 8.2 Tighter threshold
```sql
EXEC Recurring.DD_Alert_NotTakenPaymentExecutions @MinutsToAlert = 15
```

### 8.3 Custom date range
```sql
EXEC Recurring.DD_Alert_NotTakenPaymentExecutions @FromDate = '2026-04-15', @ToDate = '2026-04-16'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.DD_Alert_NotTakenPaymentExecutions | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.DD_Alert_NotTakenPaymentExecutions.sql*
