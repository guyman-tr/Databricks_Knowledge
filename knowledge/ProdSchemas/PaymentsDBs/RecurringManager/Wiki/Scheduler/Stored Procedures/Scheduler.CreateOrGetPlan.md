# Scheduler.CreateOrGetPlan

> Idempotently creates a new recurring payment plan or returns the existing one for a given PaymentId, ensuring exactly one plan exists per payment instruction.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns the Plan record (existing or newly created) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.CreateOrGetPlan is the primary WRITER procedure for the Scheduler.Plan table. When a user sets up a new recurring payment (deposit or investment), the RecurringScheduler application calls this procedure with the schedule parameters. The procedure checks if a plan already exists for the PaymentId and either creates a new one or returns the existing one.

This idempotent pattern prevents duplicate plans for the same payment instruction. Since the application may retry plan creation due to transient failures or service restarts, the database-level EXISTS check guarantees exactly one plan per PaymentId.

Called during the recurring payment setup flow. The application computes StartDate and StartDateWithUserOffset from the user's timezone and chosen start date, then passes them along with the frequency. After creation, the plan is active (EndDate = NULL) and the scheduler will begin creating executions for it.

---

## 2. Business Logic

### 2.1 Idempotent Plan Creation

**What**: Guarantees one plan per PaymentId using check-then-insert pattern.

**Columns/Parameters Involved**: `@PaymentId`, `PaymentId`

**Rules**:
- IF NOT EXISTS (SELECT 1 FROM Plan WHERE PaymentId = @PaymentId) THEN INSERT
- EndDate is NOT set on insert - new plans are always active
- @ChargingDay is optional (NULL default) - legacy plans and Weekly/BiWeekly plans may not have a charging day
- Always returns the plan for the given PaymentId, regardless of whether insert occurred

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentId | int (IN) | NO | - | VERIFIED | Cross-schema FK to the Recurring.Payment record. Used as the idempotency key - if a plan already exists for this PaymentId, no insert occurs. One-to-one relationship with Scheduler.Plan. |
| 2 | @FrequencyId | int (IN) | NO | - | VERIFIED | Billing cycle frequency: 1=Weekly, 2=BiWeekly, 3=Monthly. See [Frequency](_glossary.md#frequency). Determines how the scheduler calculates subsequent execution dates. |
| 3 | @StartDate | datetime2 (IN) | NO | - | CODE-BACKED | UTC timestamp of when the first execution should occur. Calculated by the application based on user input and timezone conversion. |
| 4 | @StartDateWithUserOffset | nvarchar(50) (IN) | NO | - | CODE-BACKED | ISO 8601 string with the user's timezone offset (e.g., "2026-05-10T03:00:00+02:00"). Preserved for user-facing display to avoid timezone ambiguity. |
| 5 | @ChargingDay | int (IN) | YES | NULL | CODE-BACKED | Day of the month (1-28) for monthly plans. NULL for weekly/biweekly plans where the charge day is derived from StartDate. Can be updated later via Scheduler.UpdatePlan. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (INSERT/SELECT) | Scheduler.Plan | Direct Write/Read | Creates new plan rows and reads existing ones |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by RecurringScheduler application.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.CreateOrGetPlan (procedure)
└── Scheduler.Plan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Plan | Table | WRITER/READER - inserts new plan or reads existing one |

### 6.2 Objects That Depend On This

No dependents found. Called by RecurringScheduler application.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Create a new monthly plan
```sql
EXEC Scheduler.CreateOrGetPlan
    @PaymentId = 200999,
    @FrequencyId = 3,
    @StartDate = '2026-05-01T14:00:00',
    @StartDateWithUserOffset = '2026-05-01T14:00:00+00:00',
    @ChargingDay = 1;
```

### 8.2 Create a weekly plan (no ChargingDay needed)
```sql
EXEC Scheduler.CreateOrGetPlan
    @PaymentId = 201000,
    @FrequencyId = 1,
    @StartDate = '2026-04-21T07:00:00',
    @StartDateWithUserOffset = '2026-04-21T03:00:00-04:00';
```

### 8.3 Idempotent retry returns existing plan
```sql
-- Second call with same PaymentId returns existing plan without insert
EXEC Scheduler.CreateOrGetPlan
    @PaymentId = 200999,
    @FrequencyId = 3,
    @StartDate = '2026-05-01T14:00:00',
    @StartDateWithUserOffset = '2026-05-01T14:00:00+00:00',
    @ChargingDay = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.CreateOrGetPlan | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.CreateOrGetPlan.sql*
