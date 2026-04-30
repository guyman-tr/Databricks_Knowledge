# Recurring.Alert_NotScheduled_Payments

> Monitoring alert that detects active payments without a corresponding Scheduler.Plan, indicating the scheduling pipeline failed to create a plan for a new payment.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns count of unscheduled payments |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This alert detects a critical pipeline failure: when a recurring payment is created but the scheduler fails to generate a corresponding Scheduler.Plan. Every active payment should have a plan within minutes of creation. Payments without plans will never execute, meaning the customer's recurring deposit/investment silently stops working.

The SP queries Recurring.Payment LEFT JOIN Scheduler.Plan and returns counts of payments where no plan exists, excluding invalid payments (StatusId=4) and using a configurable time window (default: 3 minutes to 2 days ago) to avoid flagging brand-new payments that haven't been processed yet.

---

## 2. Business Logic

### 2.1 Unscheduled Payment Detection

**What**: Identifies payments created within a time window that have no associated scheduler plan.

**Columns/Parameters Involved**: `@MinutsToAlert`, `@GapInDays`, `@FromDate`, `@ToDate`

**Rules**:
- LEFT JOIN Scheduler.Plan ON PaymentId, filter WHERE PlanId IS NULL
- Excludes StatusId=4 (Invalid payments)
- Default time window: payments created between 2 days ago and 3 minutes ago
- @FromDate/@ToDate override the default window when provided
- RETURN 0 = all payments have plans (healthy)
- RETURN 1 = unscheduled payments found (alert fires)
- Returns (UnscheduledPayments count, FirstUnscheduledPayment ID)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MinutsToAlert | int (IN) | NO | 3 | CODE-BACKED | Minutes before current time to exclude from the search. Payments created in the last N minutes are too new to expect a plan. |
| 2 | @GapInDays | int (IN) | NO | 2 | CODE-BACKED | How many days back to search for unscheduled payments. |
| 3 | @FromDate | datetime (IN) | YES | NULL | CODE-BACKED | Override start of the search window. NULL uses DATEADD(DAY, -@GapInDays, GETUTCDATE()). |
| 4 | @ToDate | datetime (IN) | YES | NULL | CODE-BACKED | Override end of the search window. NULL uses DATEADD(MINUTE, -@MinutsToAlert, GETUTCDATE()). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.Payment | READER | Reads active payments within time window |
| - | Scheduler.Plan | READER (Cross-Schema) | LEFT JOINs to check for plan existence |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.Alert_NotScheduled_Payments (procedure)
├── Recurring.Payment (table)
└── Scheduler.Plan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.Payment | Table | SELECT with date filter and status exclusion |
| Scheduler.Plan | Table | LEFT JOIN to detect missing plans |

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
EXEC Recurring.Alert_NotScheduled_Payments
```

### 8.2 Check a custom time window
```sql
EXEC Recurring.Alert_NotScheduled_Payments @FromDate = '2026-04-15', @ToDate = '2026-04-16'
```

### 8.3 Equivalent ad-hoc query
```sql
SELECT COUNT(p.PaymentId) AS UnscheduledPayments, MIN(p.PaymentId) AS FirstUnscheduled
FROM Recurring.Payment p WITH (NOLOCK)
LEFT JOIN Scheduler.[Plan] pl WITH (NOLOCK) ON p.PaymentId = pl.PaymentId
WHERE pl.PlanId IS NULL AND p.StatusId != 4
  AND p.CreateDate BETWEEN DATEADD(DAY, -2, GETUTCDATE()) AND DATEADD(MINUTE, -3, GETUTCDATE())
HAVING COUNT(p.PaymentId) > 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.Alert_NotScheduled_Payments | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.Alert_NotScheduled_Payments.sql*
