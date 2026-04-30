# Scheduler.GetPlanById

> Retrieves a single recurring payment plan by its primary key, returning the complete plan configuration including frequency, date range, and charging day.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns a single Plan row for the specified PlanId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.GetPlanById is a straightforward lookup procedure that retrieves a recurring payment plan's full configuration by its primary key (PlanId). It returns the plan's frequency, start and end dates, user-offset start date, and charging day - all the parameters needed to understand the plan's scheduling behavior.

This procedure is used whenever the application needs to inspect a plan's configuration - for example, before creating the next execution, the RecurringScheduler must know the plan's [Frequency](_glossary.md#frequency) (weekly, bi-weekly, monthly) and ChargingDay to calculate the correct PlannedDate. It is also called during plan management operations where the UI or API needs to display the current plan settings to the user.

The procedure uses a NOLOCK hint for read performance, accepting the possibility of dirty reads in exchange for non-blocking access. This is appropriate because plan data changes infrequently and the caller typically validates or rechecks before making mutations. The result set includes all columns from Scheduler.Plan.

---

## 2. Business Logic

### 2.1 Plan Configuration Lookup

**What**: Retrieves the full plan record by primary key.

**Columns/Parameters Involved**: `@PlanId`, `Scheduler.Plan.PlanId`

**Rules**:
- Exact match on PlanId (primary key lookup)
- Uses NOLOCK hint for non-blocking reads
- Returns zero rows if the PlanId does not exist
- Returns all plan configuration columns: PaymentId, FrequencyId, StartDate, StartDateWithUserOffset, EndDate, ChargingDay
- EndDate is NULL for active open-ended plans; populated when the plan has been terminated via SetEndDateForPlanOfPayment

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanId | int (IN) | NO | - | VERIFIED | Primary key of the plan to retrieve. |
| 2 | PlanId | int (OUT) | NO | - | CODE-BACKED | Primary key of the plan. Matches @PlanId. |
| 3 | PaymentId | int (OUT) | NO | - | CODE-BACKED | Cross-schema link to the Recurring schema's payment record. One plan per payment. |
| 4 | FrequencyId | int (OUT) | NO | - | CODE-BACKED | Recurring cadence. See [Frequency](_glossary.md#frequency). 1=Weekly, 2=BiWeekly, 3=Monthly. |
| 5 | StartDate | datetime2 (OUT) | NO | - | CODE-BACKED | UTC date when the plan's scheduling begins. Used as the anchor for calculating execution dates. |
| 6 | StartDateWithUserOffset | nvarchar (OUT) | YES | - | CODE-BACKED | The plan's start date adjusted for the user's timezone offset. Stored as a string representation to preserve the user's local perspective. |
| 7 | EndDate | datetime2 (OUT) | YES | - | CODE-BACKED | UTC date when the plan was terminated. NULL for active plans. Set by Scheduler.SetEndDateForPlanOfPayment. |
| 8 | ChargingDay | int (OUT) | YES | - | CODE-BACKED | Day of the month (1-31) or day of the week on which charges should occur. Interpretation depends on FrequencyId. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | Scheduler.Plan | Direct Read | Reads the plan record by PlanId |

### 5.2 Referenced By (other objects point to this)

| Caller | Type | Description |
|--------|------|-------------|
| RecurringScheduler | Application | K8S worker retrieves plan configuration for execution scheduling |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.GetPlanById (procedure)
└── Scheduler.Plan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Plan | Table | READER - retrieves plan by primary key |

### 6.2 Objects That Depend On This

No database dependents. Called by RecurringScheduler application.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Retrieve a plan by its ID
```sql
EXEC Scheduler.GetPlanById @PlanId = 189836;
```

### 8.2 Check if a plan has an end date set (terminated)
```sql
-- Returns EndDate = NULL for active plans
EXEC Scheduler.GetPlanById @PlanId = 189836;
```

### 8.3 Manually inspect plan with frequency label
```sql
SELECT p.PlanId, p.PaymentId, f.Name AS FrequencyName, p.StartDate, p.EndDate, p.ChargingDay
FROM Scheduler.[Plan] p WITH (NOLOCK)
JOIN Dictionary.Frequency f ON p.FrequencyId = f.FrequencyId
WHERE p.PlanId = 189836;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.GetPlanById | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.GetPlanById.sql*
