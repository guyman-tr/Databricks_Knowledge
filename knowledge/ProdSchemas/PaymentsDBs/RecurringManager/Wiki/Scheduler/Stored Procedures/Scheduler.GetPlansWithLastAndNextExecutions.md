# Scheduler.GetPlansWithLastAndNextExecutions

> Retrieves plans for a batch of PaymentIds with their two most recent planned executions, enabling the application to display both the last completed and next upcoming charge for each plan.

| Property | Value |
|----------|-------|
| **Schema** | Scheduler |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns Plan rows joined with up to 2 most recent Planned-type Execution rows per plan |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Scheduler.GetPlansWithLastAndNextExecutions is a batch-oriented procedure that retrieves recurring plans and their two most recent planned executions for a set of PaymentIds. The "last and next" in the name refers to the pattern of returning the two newest Planned-type executions, which typically represent the most recently processed charge and the next upcoming charge. This powers user-facing dashboards that show "Last payment: March 1 | Next payment: April 1."

The procedure accepts a table-valued parameter (Scheduler.Ids TVP) containing PaymentIds, making it efficient for bulk lookups when the UI needs to display recurring payment status for multiple users or accounts in a single call. The @IncludeExecutions flag controls whether execution data is included at all - when set to 0, only the plan configuration is returned without any execution details, reducing payload when only plan metadata is needed.

When @IncludeExecutions = 1, the procedure uses a ROW_NUMBER() window function partitioned by PlanId and ordered by PaymentExecutionId DESC to identify the two most recent planned executions (ExecutionTypeId = 1). It filters exclusively for Planned-type executions, deliberately excluding Dunning (2) executions to show only the regular charge cadence. The LEFT JOIN ensures plans without any executions still appear in the result set.

---

## 2. Business Logic

### 2.1 Batch Plan Retrieval

**What**: Loads plans for multiple PaymentIds into a temp table for efficient joining.

**Columns/Parameters Involved**: `@PaymentIds` (Scheduler.Ids TVP), `Scheduler.Plan`

**Rules**:
- Accepts a Scheduler.Ids table-valued parameter containing PaymentId values
- Inserts matching plans into a #plans temp table for subsequent joins
- Returns all plan columns: PlanId, PaymentId, FrequencyId, StartDate, EndDate, StartDateWithUserOffset, ChargingDay

### 2.2 Execution Inclusion Toggle

**What**: Controls whether execution data is included in the result set.

**Columns/Parameters Involved**: `@IncludeExecutions`

**Rules**:
- When @IncludeExecutions = 0: returns plan data only with NULL execution columns
- When @IncludeExecutions = 1: returns plans LEFT JOINed with the two most recent planned executions
- The toggle allows callers to optimize for cases where only plan metadata is needed

### 2.3 Last-and-Next Execution Window

**What**: Uses ROW_NUMBER() to return the two most recent planned executions per plan.

**Columns/Parameters Involved**: `ExecutionTypeId`, `PaymentExecutionId`, `ROW_NUMBER() ... N`

**Rules**:
- Filters to ExecutionTypeId = 1 (Planned only) - dunning executions are excluded
- ROW_NUMBER() partitioned by PlanId, ordered by PaymentExecutionId DESC
- Keeps rows where N <= 2 (the two most recent planned executions)
- N=1 is the most recent (typically the next upcoming), N=2 is the previous (typically the last completed)
- LEFT JOIN ensures plans with no executions still appear in results
- Does not filter by ExecutionStatusId - returns the latest planned executions regardless of status

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentIds | Scheduler.Ids (IN, TVP) | NO | - | VERIFIED | Table-valued parameter containing PaymentId values to look up. Enables batch retrieval of multiple plans in one call. |
| 2 | @IncludeExecutions | bit (IN) | NO | - | VERIFIED | Toggle for execution inclusion. 0 = plan data only; 1 = plan data plus last two planned executions. |
| 3 | PlanId | int (OUT) | NO | - | CODE-BACKED | Primary key of the plan. |
| 4 | PaymentId | int (OUT) | NO | - | CODE-BACKED | Cross-schema link to the Recurring schema's payment record. |
| 5 | FrequencyId | int (OUT) | NO | - | CODE-BACKED | See [Frequency](_glossary.md#frequency). 1=Weekly, 2=BiWeekly, 3=Monthly. |
| 6 | StartDate | datetime2 (OUT) | NO | - | CODE-BACKED | UTC date when the plan's scheduling begins. |
| 7 | EndDate | datetime2 (OUT) | YES | - | CODE-BACKED | UTC date when the plan was terminated. NULL for active plans. |
| 8 | StartDateWithUserOffset | nvarchar (OUT) | YES | - | CODE-BACKED | Start date adjusted for user's timezone. |
| 9 | ChargingDay | int (OUT) | YES | - | CODE-BACKED | Day of the period on which charges occur. |
| 10 | ExecutionId | int (OUT) | YES | - | CODE-BACKED | PK of the execution record. NULL when @IncludeExecutions = 0 or no executions exist. |
| 11 | ActualExecutionDate | datetime (OUT) | YES | - | CODE-BACKED | UTC timestamp when the execution was actually picked up. NULL for unprocessed executions. |
| 12 | ExecutionTypeId | int (OUT) | YES | - | CODE-BACKED | Always 1 (Planned) in results due to the filter. NULL when executions are excluded. See [Execution Type](_glossary.md#execution-type). |
| 13 | PlannedDate | datetime2 (OUT) | YES | - | CODE-BACKED | Scheduled UTC date for the execution. NULL when executions are excluded. |
| 14 | ExecutionStatusId | int (OUT) | YES | - | CODE-BACKED | Current lifecycle state. See [Execution Status](_glossary.md#execution-status). NULL when executions are excluded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PaymentIds | Scheduler.Plan | FK parameter (batch) | Filters plans by PaymentId values from the TVP |
| (SELECT) | Scheduler.Plan | Direct Read | Reads plan configuration into temp table |
| (SELECT) | Scheduler.Execution | Direct Read | Reads the two most recent planned executions per plan |
| @PaymentIds | Scheduler.Ids | TVP Type | Uses the Scheduler.Ids table-valued type for batch input |

### 5.2 Referenced By (other objects point to this)

| Caller | Type | Description |
|--------|------|-------------|
| RecurringScheduler | Application | K8S worker retrieves plans with execution context for dashboard/status views |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Scheduler.GetPlansWithLastAndNextExecutions (procedure)
├── Scheduler.Plan (table)
├── Scheduler.Execution (table)
└── Scheduler.Ids (TVP type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Scheduler.Plan | Table | READER - loads plans matching the PaymentIds batch |
| Scheduler.Execution | Table | READER - retrieves the two most recent planned executions per plan |
| Scheduler.Ids | Table-Valued Type | INPUT - defines the shape of the @PaymentIds batch parameter |

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

### 8.1 Get plans with executions for a batch of PaymentIds
```sql
DECLARE @Ids Scheduler.Ids;
INSERT INTO @Ids (Id) VALUES (500123), (500124), (500125);
EXEC Scheduler.GetPlansWithLastAndNextExecutions @PaymentIds = @Ids, @IncludeExecutions = 1;
```

### 8.2 Get plans only (no execution data) for a batch
```sql
DECLARE @Ids Scheduler.Ids;
INSERT INTO @Ids (Id) VALUES (500123), (500124);
EXEC Scheduler.GetPlansWithLastAndNextExecutions @PaymentIds = @Ids, @IncludeExecutions = 0;
```

### 8.3 Manually reproduce the last-and-next execution window
```sql
SELECT e.ExecutionId, e.PlanId, e.PlannedDate, e.ExecutionStatusId,
       ROW_NUMBER() OVER (PARTITION BY e.PlanId ORDER BY e.PaymentExecutionId DESC) AS N
FROM Scheduler.Execution e
WHERE e.ExecutionTypeId = 1
  AND e.PlanId IN (SELECT PlanId FROM Scheduler.[Plan] WHERE PaymentId IN (500123, 500124))
ORDER BY e.PlanId, N;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this procedure.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Scheduler.GetPlansWithLastAndNextExecutions | Type: Stored Procedure | Source: RecurringManager/Scheduler/Stored Procedures/Scheduler.GetPlansWithLastAndNextExecutions.sql*
