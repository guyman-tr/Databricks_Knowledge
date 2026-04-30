# Scheduler.Plan

> Defines the recurring payment schedule for each user payment instruction, including frequency, start/end dates, and the preferred charging day within the billing cycle.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Table |
| **Key Identifier** | PlanId (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 (1 clustered PK + 1 nonclustered) |

---

## 1. Business Meaning

Scheduler.Plan represents a recurring payment schedule tied to a specific payment instruction in the Recurring schema. Each plan defines when charges should occur (frequency, start date, charging day) and when to stop (end date). It is the scheduling blueprint that the RecurringScheduler worker uses to generate individual execution records at each billing cycle.

This table exists because recurring payments need a persistent schedule definition that outlives any single execution attempt. A user setting up a monthly deposit of $100 on the 15th creates one Plan row that persists for the lifetime of that recurring arrangement. Each month, the scheduler reads this plan and creates an Execution row for that cycle. Without the Plan table, the system would have no way to know what to charge, when, or whether the arrangement is still active.

Plans are created by Scheduler.CreateOrGetPlan when a user first sets up a recurring payment (idempotent - returns existing plan if PaymentId already exists). They are modified by Scheduler.UpdatePlan (frequency/day changes) and terminated by Scheduler.SetEndDateForPlanOfPayment (sets EndDate to current UTC time). The scheduler worker reads plans via Scheduler.GetPlansWithLastAndNextExecutions to determine which plans need their next execution created. The table is system-versioned with History.Plan for full audit trail of schedule changes.

---

## 2. Business Logic

### 2.1 Plan Lifecycle (Active vs Ended)

**What**: A plan is active when EndDate is NULL, and ended when EndDate is set to the termination timestamp.

**Columns/Parameters Involved**: `EndDate`, `StartDate`, `PaymentId`

**Rules**:
- EndDate IS NULL means the plan is active and will continue generating executions
- EndDate IS NOT NULL means the plan was terminated - no further executions will be generated
- Termination is performed by Scheduler.SetEndDateForPlanOfPayment, which sets EndDate = GETUTCDATE()
- Once ended, a plan cannot be reactivated - a new plan must be created
- Currently 8.8% of plans are active (EndDate IS NULL), 91.2% have been ended

**Diagram**:
```
[CreateOrGetPlan] --> Plan (EndDate = NULL) --> [Active: generates executions]
                                                        |
                                            [SetEndDateForPlanOfPayment]
                                                        |
                                                        v
                                              Plan (EndDate = GETUTCDATE())
                                                        |
                                              [Ended: no more executions]
```

### 2.2 Charging Day and Frequency Coordination

**What**: The ChargingDay column works with FrequencyId to determine the exact date of each execution within the billing cycle.

**Columns/Parameters Involved**: `ChargingDay`, `FrequencyId`, `StartDate`

**Rules**:
- For Monthly plans (FrequencyId=3): ChargingDay specifies the day of the month (1-28) for charges. 66% of plans have NULL ChargingDay (legacy plans or Weekly/BiWeekly where it is not applicable)
- For Weekly (FrequencyId=1) and BiWeekly (FrequencyId=2) plans: ChargingDay may be NULL as the day is derived from StartDate's day-of-week
- ChargingDay can be updated via Scheduler.UpdatePlan if the user changes their preferred billing day
- The application calculates the next PlannedDate for an Execution using the combination of FrequencyId + ChargingDay + the last execution date

### 2.3 User Timezone Handling

**What**: The plan stores both a UTC start date and the user's local time representation to ensure charges align with the user's expected date.

**Columns/Parameters Involved**: `StartDate`, `StartDateWithUserOffset`

**Rules**:
- StartDate is stored in UTC (datetime) - used for scheduling engine calculations
- StartDateWithUserOffset is stored as an ISO 8601 string with timezone offset (e.g., "2026-05-10T03:00:00+02:00")
- This dual storage prevents timezone conversion issues where a user in UTC+8 sets a charge for "the 15th" but UTC conversion shifts it to the 14th
- The application code uses StartDateWithUserOffset to display the schedule to the user, while the scheduler engine uses StartDate for actual processing

---

## 3. Data Overview

| PlanId | PaymentId | FrequencyId | StartDate | EndDate | ChargingDay | Meaning |
|--------|-----------|-------------|-----------|---------|-------------|---------|
| 189836 | 200820 | 3 (Monthly) | 2026-05-01 | NULL | 1 | Active monthly plan charging on the 1st of each month - the most common configuration for recurring deposits |
| 189830 | 200814 | 2 (BiWeekly) | 2026-04-18 | NULL | 1 | Active bi-weekly plan - charges every 14 days from the start date, ChargingDay=1 indicates first occurrence |
| 189827 | 200811 | 1 (Weekly) | 2026-04-16 | NULL | 5 | Active weekly plan - charges every 7 days, user is in UTC-4 timezone (StartDateWithUserOffset shows 03:00-04:00) |
| 189812 | 200796 | 3 (Monthly) | 2026-05-01 | 2026-04-15 | 1 | Ended plan - was monthly on the 1st, terminated on April 15 before any execution occurred (EndDate before StartDate) |
| 1 | 1 | 3 (Monthly) | 2021-06-09 | 2021-06-09 | NULL | Earliest plan in the system - created and ended same day during initial system launch in June 2021, ChargingDay NULL (legacy) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlanId | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key uniquely identifying each recurring payment schedule. Referenced by Scheduler.Execution.PlanId to link executions to their parent plan. Currently ~189K plans exist. |
| 2 | PaymentId | int | NO | - | VERIFIED | Foreign key to the Recurring.Payment table identifying which user payment instruction this schedule belongs to. One-to-one relationship enforced by CreateOrGetPlan's idempotent check. Used as the primary lookup key by GetPlanByPaymentId and SetEndDateForPlanOfPayment. Indexed for fast lookups. |
| 3 | FrequencyId | int | NO | - | VERIFIED | Billing cycle frequency: 1=Weekly (15%), 2=BiWeekly (7%), 3=Monthly (78%). See [Frequency](_glossary.md#frequency) for full definitions. Determines how the scheduler calculates the next PlannedDate for each execution. Can be updated via UpdatePlan. (Dictionary.Frequency) |
| 4 | StartDate | datetime | NO | - | CODE-BACKED | UTC timestamp of when the first execution should occur. Used by the scheduling engine to calculate subsequent execution dates based on FrequencyId. Set once during plan creation via CreateOrGetPlan. Range: 2021-06-09 to 2026-05-15. |
| 5 | StartDateWithUserOffset | nvarchar(50) | NO | - | CODE-BACKED | ISO 8601 formatted start date preserving the user's local timezone offset (e.g., "2026-05-10T03:00:00+02:00"). Stored alongside StartDate to prevent timezone conversion ambiguity when displaying the schedule to the user. Never used for scheduling calculations - only for display. |
| 6 | EndDate | datetime | YES | - | VERIFIED | UTC timestamp when the plan was terminated. NULL = plan is active and generating executions. Set by SetEndDateForPlanOfPayment to GETUTCDATE() when the user cancels or the system stops the plan. 91.2% of plans have EndDate set (ended). Once set, the plan is permanently inactive. |
| 7 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning row start time. Automatically managed by SQL Server temporal tables. Tracks when this version of the row became current. |
| 8 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System-versioning row end time. Value of 9999-12-31 indicates the current version. When a row is modified, the previous version is moved to History.Plan with SysEndTime set to the modification timestamp. |
| 9 | ChargingDay | int | YES | - | CODE-BACKED | Day of the month (1-28) when the charge should occur for Monthly plans. NULL for 66% of plans (legacy plans created before this column was added, or Weekly/BiWeekly plans where the charge day is derived from StartDate). Can be updated via UpdatePlan if the user changes their preferred billing day. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FrequencyId | Dictionary.Frequency | Implicit Lookup | Determines the billing cycle interval: 1=Weekly, 2=BiWeekly, 3=Monthly |
| PaymentId | Recurring.Payment | Implicit FK | Links the schedule to its parent payment instruction in the Recurring schema (cross-schema) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Scheduler.Execution | PlanId | Implicit FK | Each execution belongs to exactly one plan; the plan defines the schedule that generated the execution |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Execution | Table | Execution.PlanId references Plan.PlanId |
| Scheduler.CreateOrGetPlan | Stored Procedure | WRITER - creates plan if not exists for PaymentId, returns it |
| Scheduler.GetPlanById | Stored Procedure | READER - retrieves plan by PlanId |
| Scheduler.GetPlanByPaymentId | Stored Procedure | READER - retrieves plan by PaymentId |
| Scheduler.GetPlansWithLastAndNextExecutions | Stored Procedure | READER - retrieves plans with their last/next execution details for batch of PaymentIds |
| Scheduler.SetEndDateForPlanOfPayment | Stored Procedure | MODIFIER - sets EndDate to terminate the plan |
| Scheduler.UpdatePlan | Stored Procedure | MODIFIER - updates FrequencyId, ChargingDay, StartDate |
| Recurring.Alert_NotScheduled_Payments | Stored Procedure | READER (cross-schema) - LEFT JOINs to detect payments without a plan |
| Recurring.DD_Alert_NotScheduled_Payments | Stored Procedure | READER (cross-schema) - DataDog variant of the unscheduled payments alert |
| History.Plan | Table | System-versioned history table - stores previous row versions on UPDATE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Recurring_Plan | CLUSTERED PK | PlanId ASC | - | - | Active |
| IX_SchedulerPlan_ExecutionStatusId_Stamp | NC | PaymentId ASC | FrequencyId, StartDate, StartDateWithUserOffset, EndDate | - | Active |

Note: IX_SchedulerPlan_ExecutionStatusId_Stamp is a misnomer (likely copied from Execution index naming) - it actually indexes PaymentId for fast lookups by the application and stored procedures.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Recurring_Plan | PRIMARY KEY | PK name reveals the table was originally named "Recurring.Plan" before being moved to the Scheduler schema |
| DF_SysStartTime | DEFAULT | SysStartTime defaults to GETUTCDATE() - system-versioning row start |
| DF_SysEndTime | DEFAULT | SysEndTime defaults to 9999-12-31 23:59:59.9999999 - marks current row version |

---

## 8. Sample Queries

### 8.1 Find all active plans (not ended) with their frequency names
```sql
SELECT p.PlanId, p.PaymentId, f.Name AS Frequency, p.StartDate, p.ChargingDay
FROM Scheduler.[Plan] p WITH (NOLOCK)
JOIN Dictionary.Frequency f WITH (NOLOCK) ON p.FrequencyId = f.FrequencyID
WHERE p.EndDate IS NULL
ORDER BY p.PlanId DESC;
```

### 8.2 Check the audit history of a specific plan
```sql
SELECT p.PlanId, p.FrequencyId, p.ChargingDay, p.EndDate,
       p.SysStartTime AS VersionStart, p.SysEndTime AS VersionEnd
FROM Scheduler.[Plan] FOR SYSTEM_TIME ALL p
WHERE p.PlanId = 189836
ORDER BY p.SysStartTime;
```

### 8.3 Find plans without any executions (potential scheduling issues)
```sql
SELECT p.PlanId, p.PaymentId, f.Name AS Frequency, p.StartDate
FROM Scheduler.[Plan] p WITH (NOLOCK)
JOIN Dictionary.Frequency f WITH (NOLOCK) ON p.FrequencyId = f.FrequencyID
LEFT JOIN Scheduler.Execution e WITH (NOLOCK) ON p.PlanId = e.PlanId
WHERE p.EndDate IS NULL
  AND e.ExecutionId IS NULL
  AND p.StartDate < GETUTCDATE()
ORDER BY p.StartDate;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Scheduler](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1922891789/Recurring+Scheduler) | Confluence | RecurringScheduler is a K8S worker service that reads plans and generates executions; connects to RecurringManager DB via SQL connection string |

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.Plan | Type: Table | Source: RecurringManager/Scheduler/Tables/Scheduler.Plan.sql*
