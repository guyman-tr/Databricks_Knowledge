# Scheduler.UpdatePlan

> Updates a recurring plan's scheduling configuration - frequency, charging day, and/or start date - using selective ISNULL-based patching so only supplied parameters are changed.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns the updated Plan row with all columns |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.UpdatePlan modifies the scheduling configuration of an existing recurring payment plan. It supports partial updates through an ISNULL-based pattern: each optional parameter (@FrequencyId, @ChargingDay, @StartDate) only overwrites the existing value when explicitly provided. When passed as NULL (or omitted), the existing column value is preserved. This allows the caller to change one, two, or all three scheduling parameters in a single call.

This procedure is called when a user or the system needs to modify how a recurring plan is scheduled - for example, switching from [Monthly](_glossary.md#frequency) to [Weekly](_glossary.md#frequency) frequency, changing the day of the month on which charges occur, or adjusting the start date. These modifications affect all future executions that have not yet been processed, as the scheduling engine recalculates execution dates based on the updated plan configuration.

The OUTPUT clause returns the complete plan record including columns not modified by this procedure (PaymentId, StartDateWithUserOffset, EndDate), giving the caller a full view of the plan's current state after the update. The procedure does not modify EndDate or StartDateWithUserOffset - EndDate is managed by SetEndDateForPlanOfPayment, and StartDateWithUserOffset is set at creation time.

---

## 2. Business Logic

### 2.1 Selective Plan Update (ISNULL Pattern)

**What**: Updates only the plan columns for which non-NULL parameters are provided, preserving existing values for omitted parameters.

**Columns/Parameters Involved**: `@PlanId`, `@FrequencyId`, `@ChargingDay`, `@StartDate`

**Rules**:
- ChargingDay = ISNULL(@ChargingDay, ChargingDay) - only changes if @ChargingDay is non-NULL
- FrequencyId = ISNULL(@FrequencyId, FrequencyId) - only changes if @FrequencyId is non-NULL
- StartDate = ISNULL(@StartDate, StartDate) - only changes if @StartDate is non-NULL
- All three parameters can be updated in a single call
- PlanId is the WHERE key - must match an existing plan
- Does not validate parameter values (e.g., FrequencyId must be 1-3, but no check is in the SP)
- Does not update EndDate or StartDateWithUserOffset
- OUTPUT returns all plan columns: PlanId, PaymentId, FrequencyId, StartDate, StartDateWithUserOffset, EndDate, ChargingDay
- Returns zero rows if PlanId does not exist

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanId | int (IN) | NO | - | VERIFIED | Primary key of the plan to update. |
| 2 | @FrequencyId | int (IN) | YES | NULL | CODE-BACKED | New recurring cadence. See [Frequency](_glossary.md#frequency). 1=Weekly, 2=BiWeekly, 3=Monthly. NULL preserves the existing value. |
| 3 | @ChargingDay | int (IN) | YES | NULL | CODE-BACKED | New day-of-period for charges (e.g., 15 for the 15th of the month for monthly plans). NULL preserves the existing value. |
| 4 | @StartDate | datetime (IN) | YES | NULL | CODE-BACKED | New start date for the plan's scheduling anchor. NULL preserves the existing value. Note: datetime type, not datetime2. |
| 5 | PlanId | int (OUT) | NO | - | CODE-BACKED | PK of the updated plan. |
| 6 | PaymentId | int (OUT) | NO | - | CODE-BACKED | Cross-schema link to the Recurring schema. Not modifiable. |
| 7 | FrequencyId | int (OUT) | NO | - | CODE-BACKED | Current frequency after update. See [Frequency](_glossary.md#frequency). |
| 8 | StartDate | datetime2 (OUT) | NO | - | CODE-BACKED | Current start date after update. |
| 9 | StartDateWithUserOffset | nvarchar (OUT) | YES | - | CODE-BACKED | User-timezone-adjusted start date. Not modified by this procedure. |
| 10 | EndDate | datetime2 (OUT) | YES | - | CODE-BACKED | Plan termination date. Not modified by this procedure. NULL for active plans. |
| 11 | ChargingDay | int (OUT) | YES | - | CODE-BACKED | Current charging day after update. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PlanId | Scheduler.Plan | PK parameter | Identifies the plan to update |
| (UPDATE/OUTPUT) | Scheduler.Plan | Direct Write/Read | Updates scheduling columns and returns the full plan record |

### 5.2 Referenced By (other objects point to this)

| Caller | Type | Description |
|--------|------|-------------|
| RecurringScheduler | Application | K8S worker updates plan configuration when users modify their recurring settings |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.UpdatePlan (procedure)
└── Scheduler.Plan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Plan | Table | WRITER/READER - updates scheduling configuration and returns the full plan record |

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

### 8.1 Change a plan's frequency to Monthly
```sql
EXEC Scheduler.UpdatePlan @PlanId = 189836, @FrequencyId = 3;
```

### 8.2 Change the charging day to the 15th of the month
```sql
EXEC Scheduler.UpdatePlan @PlanId = 189836, @ChargingDay = 15;
```

### 8.3 Update frequency and charging day together
```sql
EXEC Scheduler.UpdatePlan
    @PlanId = 189836,
    @FrequencyId = 3,
    @ChargingDay = 1,
    @StartDate = '2026-05-01T00:00:00';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.UpdatePlan | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.UpdatePlan.sql*
