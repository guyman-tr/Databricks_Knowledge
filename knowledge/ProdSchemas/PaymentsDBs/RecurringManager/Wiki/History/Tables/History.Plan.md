# History.Plan

> Temporal history table storing previous versions of recurring payment schedule plans, capturing changes to frequency, start dates, and charging day configurations over time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PlanId (mirrors PK of Scheduler.Plan) |
| **Partition** | No |
| **Indexes** | 1 clustered (SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.Plan is the system-versioned temporal history table for `Scheduler.Plan`. Each row represents a previous state of a payment schedule plan - the scheduling configuration that determines when a recurring payment's executions are created. A plan defines the frequency (weekly, biweekly, monthly), the start date, and optionally a specific charging day of the month. There is a 1:1 relationship between a Payment and its Plan.

This table exists to provide an audit trail of scheduling configuration changes. When a customer changes their recurring payment frequency (e.g., from weekly to monthly) or adjusts the charging day, the previous schedule configuration is preserved here. This is important for reconciliation - understanding why an execution was scheduled on a particular date requires knowing which plan configuration was in effect at that time.

Data enters this table automatically via SQL Server's temporal mechanism. Plans are created by `Scheduler.CreateOrGetPlan` (idempotent - one plan per PaymentId) and modified by `Scheduler.UpdatePlan` (frequency, charging day, or start date changes). The base table lives in the Scheduler schema, while the history table is in the History schema. With 227K+ rows and monthly frequency dominating (76%), this table reflects frequent plan adjustments across the user base.

---

## 2. Business Logic

### 2.1 One-Plan-Per-Payment Pattern

**What**: Each recurring payment has exactly one scheduling plan, managed via an idempotent create-or-get pattern.

**Columns/Parameters Involved**: `PaymentId`, `PlanId`

**Rules**:
- `Scheduler.CreateOrGetPlan` checks `WHERE PaymentId = @PaymentId` before inserting
- If a plan already exists for the payment, returns the existing plan
- This enforces a strict 1:1 relationship between Payment and Plan
- PlanId is IDENTITY-generated; PaymentId is the logical lookup key

### 2.2 Schedule Configuration

**What**: The plan defines the recurring cadence and timing of payment executions.

**Columns/Parameters Involved**: `FrequencyId`, `StartDate`, `StartDateWithUserOffset`, `ChargingDay`, `EndDate`

**Rules**:
- FrequencyId maps to Dictionary.Frequency: 1=Weekly, 2=BiWeekly, 3=Monthly. See [Frequency](../../_glossary.md#frequency). Distribution: Monthly 76%, Weekly 16%, BiWeekly 8%
- StartDate is the UTC date of the first scheduled execution
- StartDateWithUserOffset stores the same date in the user's local timezone as an ISO 8601 string (e.g., "2021-06-10T03:00:00+03:00")
- ChargingDay specifies the day of the month for monthly plans (NULL in early data, introduced later)
- EndDate is NULL for open-ended plans (no end date); set by `Scheduler.SetEndDateForPlanOfPayment` when a plan is terminated
- `Scheduler.UpdatePlan` can change FrequencyId, ChargingDay, and StartDate using the ISNULL optional-update pattern

### 2.3 Temporal Versioning

**What**: Automatic audit trail of schedule configuration changes.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- When a plan is updated (frequency change, charging day change, etc.), the old version moves to History.Plan
- Point-in-time queries on Scheduler.Plan with `FOR SYSTEM_TIME AS OF` reconstruct the schedule that was active at any date

---

## 3. Data Overview

| PlanId | PaymentId | FrequencyId | StartDate | StartDateWithUserOffset | ChargingDay | Meaning |
|---|---|---|---|---|---|---|
| 1 | 1 | 1 | 2021-06-09 | 2021-06-09T03:00:00+03:00 | NULL | Early weekly plan (June 2021) - shows the +03:00 timezone offset (Israel), indicating the user is in UTC+3. No ChargingDay since this is weekly. |
| 2 | 2 | 3 | 2021-06-10 | 2021-06-10T03:00:00+03:00 | NULL | Monthly plan - the most common frequency (76% of plans). ChargingDay is NULL in early data. |
| 4 | 4 | 2 | 2021-06-15 | 2021-06-15T03:00:00+03:00 | NULL | BiWeekly plan - the least common frequency (8%). Shows variety across the three supported cadences. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlanId | int | NO | - | CODE-BACKED | Mirrors the IDENTITY PK of Scheduler.Plan. Identifies which plan this historical version belongs to. Not unique in history - the same PlanId appears for each configuration change. Created by `Scheduler.CreateOrGetPlan`. |
| 2 | PaymentId | int | NO | - | VERIFIED | References the recurring payment this plan schedules. Links to Recurring.Payment / History.Payment. 1:1 relationship enforced by CreateOrGetPlan's existence check. Indexed in the base table (IX_SchedulerPlan_ExecutionStatusId_Stamp). Set at creation and never changed. |
| 3 | FrequencyId | int | NO | - | VERIFIED | The recurring cadence of the plan. Maps to Dictionary.Frequency: 1=Weekly, 2=BiWeekly, 3=Monthly. See [Frequency](../../_glossary.md#frequency). Distribution: Monthly 76%, Weekly 16%, BiWeekly 8%. Updatable via `Scheduler.UpdatePlan`. (Dictionary.Frequency) |
| 4 | StartDate | datetime | NO | - | CODE-BACKED | UTC date when the first execution should be scheduled. Set at creation via @StartDate parameter. Can be updated by `Scheduler.UpdatePlan`. The scheduling engine uses this as the anchor date to calculate future execution dates based on FrequencyId. |
| 5 | StartDateWithUserOffset | nvarchar(50) | NO | - | CODE-BACKED | The start date in the user's local timezone, stored as an ISO 8601 string with timezone offset (e.g., "2021-06-10T03:00:00+03:00"). Preserves the user's local time context that would be lost in the UTC StartDate. Set at creation; not updated by UpdatePlan. Sample data shows +03:00 offset (Israel timezone). |
| 6 | EndDate | datetime | YES | - | CODE-BACKED | UTC date when the plan should stop generating new executions. NULL means the plan runs indefinitely until explicitly stopped or cancelled. Set by `Scheduler.SetEndDateForPlanOfPayment` when a payment is terminated. All sample history rows have NULL EndDate (open-ended plans). |
| 7 | SysStartTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Records when this version became active. Part of the clustered index. |
| 8 | SysEndTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Records when this version was superseded. Part of the clustered index. |
| 9 | ChargingDay | int | YES | - | CODE-BACKED | Specific day of the month for monthly charges (1-31). NULL for weekly/biweekly plans or when no specific day is configured. Updatable via `Scheduler.UpdatePlan`. NULL in all early data - feature added later to allow users to specify their preferred charging date. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | Scheduler.Plan | Temporal History | This is the system-versioned history table for Scheduler.Plan |
| PaymentId | Recurring.Payment / History.Payment | Implicit FK | The recurring payment this plan schedules (1:1 relationship) |
| FrequencyId | Dictionary.Frequency | Implicit Lookup | Recurring cadence: 1=Weekly, 2=BiWeekly, 3=Monthly |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.Execution | PlanId | Implicit FK | Scheduler execution records reference the plan they were generated from |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Plan | Table | This is the temporal history table (SYSTEM_VERSIONING = ON) |
| Scheduler.CreateOrGetPlan | Stored Procedure | WRITER - creates plans idempotently (one per PaymentId) |
| Scheduler.UpdatePlan | Stored Procedure | MODIFIER - updates frequency, charging day, start date |
| Scheduler.SetEndDateForPlanOfPayment | Stored Procedure | MODIFIER - sets EndDate when a payment is terminated |
| Scheduler.GetPlanByPaymentId | Stored Procedure | READER - retrieves plan by payment |
| Scheduler.GetPlanById | Stored Procedure | READER - retrieves plan by PlanId |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_Plan | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

PAGE compression is enabled. The base table has one additional NC index (IX_SchedulerPlan_ExecutionStatusId_Stamp on PaymentId, including FrequencyId, StartDate, StartDateWithUserOffset, EndDate).

### 7.2 Constraints

None. The base table (Scheduler.Plan) holds:
- PK_Recurring_Plan (PK on PlanId - note: constraint name references "Recurring" but table is in Scheduler schema, suggesting a schema rename occurred)

---

## 8. Sample Queries

### 8.1 View schedule change history for a payment
```sql
SELECT PlanId, PaymentId, FrequencyId, StartDate, ChargingDay, EndDate,
       SysStartTime AS ConfigStart, SysEndTime AS ConfigEnd
FROM History.Plan WITH (NOLOCK)
WHERE PaymentId = 100
ORDER BY SysStartTime ASC
```

### 8.2 Find plans that changed frequency
```sql
SELECT h1.PlanId, h1.FrequencyId AS OldFrequency, h2.FrequencyId AS NewFrequency,
       h1.SysEndTime AS ChangedAt
FROM History.Plan h1 WITH (NOLOCK)
JOIN History.Plan h2 WITH (NOLOCK) ON h2.PlanId = h1.PlanId
    AND h2.SysStartTime = h1.SysEndTime
WHERE h1.FrequencyId <> h2.FrequencyId
ORDER BY h1.SysEndTime DESC
```

### 8.3 Reconstruct the schedule for a payment at a point in time
```sql
SELECT p.PlanId, p.PaymentId, f.Name AS Frequency,
       p.StartDate, p.ChargingDay, p.EndDate
FROM Scheduler.Plan
FOR SYSTEM_TIME AS OF '2024-01-15 00:00:00' p
JOIN Dictionary.Frequency f WITH (NOLOCK) ON f.FrequencyId = p.FrequencyId
WHERE p.PaymentId = 100
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Plan | Type: Table | Source: RecurringManager/History/Tables/History.Plan.sql*
