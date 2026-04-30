# Recurring.Alert_SendToBillingFailed

> Monitoring alert that detects payment executions stuck in SendToBillingFailed status, indicating the system failed to reach the billing processor.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns count of stuck executions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This alert detects payment executions that failed to reach the billing processor (StatusId=4, SendToBillingFailed). These represent infrastructure failures between the recurring system and the payment processor - the charge was attempted but the request never made it to the processor. These executions need manual investigation or automated retry.

Queries Recurring.PaymentExecution filtering by StatusId=4 within a configurable time window (default: 5 minutes to 2 days).

---

## 2. Business Logic

### 2.1 Billing Send Failure Detection

**What**: Finds executions where the billing request failed to transmit.

**Columns/Parameters Involved**: `@MinutsToAlert`, `@GapInDays`, PaymentExecution.`StatusId`, PaymentExecution.`ModificationDate`

**Rules**:
- Filters PaymentExecution WHERE StatusId IN (4) - SendToBillingFailed
- Uses ModificationDate (not CreateDate) for time window - checks when the failure occurred
- Only includes executions where ModificationDate IS NOT NULL
- Default window: 5 minutes to 2 days ago
- RETURN 1 if failures found

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MinutsToAlert | int (IN) | NO | 5 | CODE-BACKED | Minutes threshold - failures older than N minutes are flagged. |
| 2 | @GapInDays | int (IN) | NO | 2 | CODE-BACKED | How many days back to search. |
| 3 | @FromDate | datetime (IN) | YES | NULL | CODE-BACKED | Override start of search window. |
| 4 | @ToDate | datetime (IN) | YES | NULL | CODE-BACKED | Override end of search window. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.PaymentExecution | READER | Filters by StatusId=4 and ModificationDate window |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.Alert_SendToBillingFailed (procedure)
└── Recurring.PaymentExecution (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecution | Table | SELECT WHERE StatusId=4 |

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
EXEC Recurring.Alert_SendToBillingFailed
```

### 8.2 Equivalent ad-hoc query
```sql
SELECT COUNT(pe.PaymentExecutionId) AS FailedCount, MIN(pe.PaymentExecutionId) AS FirstFailed
FROM Recurring.PaymentExecution pe WITH (NOLOCK)
WHERE pe.StatusId = 4 AND pe.ModificationDate IS NOT NULL
  AND pe.ModificationDate BETWEEN DATEADD(DAY, -2, GETUTCDATE()) AND DATEADD(MINUTE, -5, GETUTCDATE())
HAVING COUNT(pe.PaymentExecutionId) > 0
```

### 8.3 Check with wider window
```sql
EXEC Recurring.Alert_SendToBillingFailed @GapInDays = 7
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.Alert_SendToBillingFailed | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.Alert_SendToBillingFailed.sql*
