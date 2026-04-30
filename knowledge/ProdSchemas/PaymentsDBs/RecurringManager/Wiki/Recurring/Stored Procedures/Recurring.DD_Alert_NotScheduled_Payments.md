# Recurring.DD_Alert_NotScheduled_Payments

> DataDog-formatted version of Alert_NotScheduled_Payments. Same detection logic but returns a scalar value row (always returns a result) suitable for DataDog metric ingestion.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar value + FirstUnscheduledPayment |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

DataDog-compatible reformulation of Recurring.Alert_NotScheduled_Payments (see that doc for full business context). Same logic: finds active payments without a Scheduler.Plan within a time window. Key difference: uses OUTER APPLY + table variable to ALWAYS return exactly one row with a scalar `value` column (0 if healthy, count if unhealthy), making it suitable for DataDog custom query monitoring which expects a consistent result set.

Reformatted by Shay Oren (2022-12-28, DBAD-19).

---

## 2. Business Logic

### 2.1 Same as Alert_NotScheduled_Payments

**What**: Identical detection logic - see [Recurring.Alert_NotScheduled_Payments](Recurring.Alert_NotScheduled_Payments.md).

**Rules**:
- Output format differs: always returns one row with `value` column (0 or count) and `FirstUnscheduledPayment`
- Uses INSERT INTO @res + OUTER APPLY pattern instead of HAVING + RETURN code
- No RETURN code - DataDog reads the result set, not the return value

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MinutsToAlert | int (IN) | NO | 3 | CODE-BACKED | Minutes before now to exclude (too new for plan creation). |
| 2 | @GapInDays | int (IN) | NO | 2 | CODE-BACKED | Days back to search. |
| 3 | @FromDate | datetime (IN) | YES | NULL | CODE-BACKED | Override start of window. |
| 4 | @ToDate | datetime (IN) | YES | NULL | CODE-BACKED | Override end of window. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.Payment | READER | Active payments within time window |
| - | Scheduler.Plan | READER (Cross-Schema) | LEFT JOIN for plan existence check |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.DD_Alert_NotScheduled_Payments (procedure)
├── Recurring.Payment (table)
└── Scheduler.Plan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.Payment | Table | SELECT with date filter |
| Scheduler.Plan | Table | LEFT JOIN on PaymentId |

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

### 8.1 Run for DataDog monitoring
```sql
EXEC Recurring.DD_Alert_NotScheduled_Payments
```

### 8.2 Custom window
```sql
EXEC Recurring.DD_Alert_NotScheduled_Payments @MinutsToAlert = 10, @GapInDays = 1
```

### 8.3 Compare with legacy alert
```sql
-- Both should detect the same issues
EXEC Recurring.Alert_NotScheduled_Payments
EXEC Recurring.DD_Alert_NotScheduled_Payments
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.DD_Alert_NotScheduled_Payments | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.DD_Alert_NotScheduled_Payments.sql*
