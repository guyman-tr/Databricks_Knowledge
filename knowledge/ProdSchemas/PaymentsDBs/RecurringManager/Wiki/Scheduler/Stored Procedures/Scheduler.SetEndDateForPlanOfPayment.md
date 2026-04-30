# Scheduler.SetEndDateForPlanOfPayment

> Terminates a recurring plan by setting its EndDate to the current UTC time, stopping all future execution scheduling for the associated payment.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns the updated Plan row with EndDate populated |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.SetEndDateForPlanOfPayment terminates a recurring payment plan by setting its EndDate to the current UTC timestamp. Once EndDate is set, the scheduling engine will no longer create new executions for this plan. This is the primary mechanism for stopping a recurring payment schedule - whether triggered by the user canceling their recurring deposit, the back-office team intervening, or an automated process detecting an invalid state.

The procedure operates by PaymentId rather than PlanId, which aligns with the calling pattern: cancellation requests typically originate from the payment side of the system (Recurring schema), where the PaymentId is the natural identifier. The one-to-one relationship between Payment and Plan means this effectively terminates exactly one plan.

The OUTPUT clause returns the updated plan record including the newly set EndDate, confirming the termination was applied. The caller can use this to verify the correct plan was terminated and to propagate the EndDate to other systems. Note that this procedure does NOT cancel pending executions - it only stops new ones from being created. Existing Planned executions must be canceled separately via UpdateExecutionsStatus.

---

## 2. Business Logic

### 2.1 Plan Termination

**What**: Sets the EndDate on a plan to stop future execution scheduling.

**Columns/Parameters Involved**: `@PaymentId`, `EndDate`

**Rules**:
- Sets EndDate = GETUTCDATE() on the plan matching the given PaymentId
- The PaymentId-to-Plan relationship is one-to-one
- Does not check whether EndDate is already set - calling on an already-terminated plan will overwrite the previous EndDate
- Does not cancel existing Planned executions - only prevents new ones from being created
- Does not modify any other plan columns (FrequencyId, StartDate, ChargingDay remain unchanged)
- OUTPUT returns the full plan record including FrequencyId, StartDate, StartDateWithUserOffset, and the new EndDate
- Does not return ChargingDay in the OUTPUT (unlike GetPlanById)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentId | int (IN) | NO | - | VERIFIED | Cross-schema identifier for the payment whose plan should be terminated. Resolves to exactly one plan. |
| 2 | PlanId | int (OUT) | NO | - | CODE-BACKED | Primary key of the terminated plan. |
| 3 | PaymentId | int (OUT) | NO | - | CODE-BACKED | Echoes back the input PaymentId. |
| 4 | FrequencyId | int (OUT) | NO | - | CODE-BACKED | Recurring cadence of the terminated plan. See [Frequency](_glossary.md#frequency). 1=Weekly, 2=BiWeekly, 3=Monthly. |
| 5 | StartDate | datetime2 (OUT) | NO | - | CODE-BACKED | UTC date when the plan originally began. |
| 6 | StartDateWithUserOffset | nvarchar (OUT) | YES | - | CODE-BACKED | Start date adjusted for user's timezone. |
| 7 | EndDate | datetime2 (OUT) | NO | - | CODE-BACKED | The newly set termination date (GETUTCDATE() at time of execution). Confirms the plan is now terminated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PaymentId | Scheduler.Plan | FK parameter | Identifies the plan to terminate via its PaymentId |
| (UPDATE/OUTPUT) | Scheduler.Plan | Direct Write/Read | Sets EndDate and returns the updated plan |

### 5.2 Referenced By (other objects point to this)

| Caller | Type | Description |
|--------|------|-------------|
| RecurringScheduler | Application | K8S worker terminates plans when payments are canceled, stopped, or invalidated |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.SetEndDateForPlanOfPayment (procedure)
└── Scheduler.Plan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Plan | Table | WRITER/READER - sets EndDate and returns the updated plan record |

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

### 8.1 Terminate the plan for a specific payment
```sql
EXEC Scheduler.SetEndDateForPlanOfPayment @PaymentId = 500123;
```

### 8.2 Verify a plan was terminated
```sql
SELECT p.PlanId, p.PaymentId, p.EndDate
FROM Scheduler.[Plan] p
WHERE p.PaymentId = 500123;
-- EndDate should be non-NULL after termination
```

### 8.3 Find plans that were terminated today
```sql
SELECT p.PlanId, p.PaymentId, p.EndDate, p.FrequencyId
FROM Scheduler.[Plan] p
WHERE CAST(p.EndDate AS DATE) = CAST(GETUTCDATE() AS DATE)
ORDER BY p.EndDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.SetEndDateForPlanOfPayment | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.SetEndDateForPlanOfPayment.sql*
