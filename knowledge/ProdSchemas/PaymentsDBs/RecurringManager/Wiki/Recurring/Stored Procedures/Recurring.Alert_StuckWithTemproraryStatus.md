# Recurring.Alert_StuckWithTemproraryStatus

> Monitoring alert that detects payment executions stuck in transient statuses (InProcess or SentToBilling) for longer than expected, indicating a processing pipeline hang.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns count of stuck executions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This alert detects executions that entered a transient processing state (InProcess=2 or SentToBilling=3) but never progressed to a terminal state. These represent hung processing pipelines - the execution was picked up but the billing response was never recorded. Requires investigation to determine if the charge actually went through.

Note: the procedure name contains a typo ("Temproraty" instead of "Temporary") preserved from the original implementation.

---

## 2. Business Logic

### 2.1 Transient Status Stuckness Detection

**What**: Finds executions in InProcess (2) or SentToBilling (3) status beyond the expected processing time.

**Columns/Parameters Involved**: `@MinutsToAlert`, PaymentExecution.`StatusId`, PaymentExecution.`ModificationDate`

**Rules**:
- Filters PaymentExecution WHERE StatusId IN (2=InProcess, 3=SentToBilling)
- Uses ModificationDate for time window (default: 30 minutes to 2 days)
- These statuses should be transient (seconds to minutes) - anything over 30 minutes is suspect
- RETURN 1 if stuck executions found

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MinutsToAlert | int (IN) | NO | 30 | CODE-BACKED | Minutes threshold - executions in transient status longer than N minutes are flagged. |
| 2 | @GapInDays | int (IN) | NO | 2 | CODE-BACKED | How many days back to search. |
| 3 | @FromDate | datetime (IN) | YES | NULL | CODE-BACKED | Override start of search window. |
| 4 | @ToDate | datetime (IN) | YES | NULL | CODE-BACKED | Override end of search window. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.PaymentExecution | READER | Filters by StatusId IN (2, 3) and ModificationDate window |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.Alert_StuckWithTemproraryStatus (procedure)
└── Recurring.PaymentExecution (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecution | Table | SELECT WHERE StatusId IN (2, 3) |

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

### 8.1 Run with defaults
```sql
EXEC Recurring.Alert_StuckWithTemproraryStatus
```

### 8.2 Equivalent ad-hoc query
```sql
SELECT COUNT(pe.PaymentExecutionId) AS StuckCount, MIN(pe.PaymentExecutionId) AS FirstStuck
FROM Recurring.PaymentExecution pe WITH (NOLOCK)
WHERE pe.StatusId IN (2, 3) AND pe.ModificationDate IS NOT NULL
  AND pe.ModificationDate BETWEEN DATEADD(DAY, -2, GETUTCDATE()) AND DATEADD(MINUTE, -30, GETUTCDATE())
HAVING COUNT(pe.PaymentExecutionId) > 0
```

### 8.3 Check with tighter threshold
```sql
EXEC Recurring.Alert_StuckWithTemproraryStatus @MinutsToAlert = 10
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.Alert_StuckWithTemproraryStatus | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.Alert_StuckWithTemproraryStatus.sql*
