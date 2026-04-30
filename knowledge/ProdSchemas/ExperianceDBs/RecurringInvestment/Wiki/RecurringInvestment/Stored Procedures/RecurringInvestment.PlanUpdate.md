# RecurringInvestment.PlanUpdate

> Updates a recurring investment plan's configuration and handles cascading instance cancellation when a plan is cancelled.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PlanID + @GCID input, updates Plans and optionally PlanInstances |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the primary plan modification procedure. It handles plan updates (amount, currency, schedule, payment method, status) and includes critical business logic: when a plan is cancelled (PlanStatusID=2), it automatically cascades the cancellation to the latest in-progress instance. Created per EDGE-3688 (Nilly Ron & Noga, 24/4/24).

After the update, it calls PlansGetByGCID to return the refreshed plan list to the application. Runs in a transaction with TRY/CATCH error handling.

---

## 2. Business Logic

### 2.1 ISNULL-Based Partial Updates

**What**: Only non-NULL parameters update their respective columns.

**Columns/Parameters Involved**: All nullable parameters

**Rules**:
- Each column is updated with `ISNULL(@Param, ExistingValue)` - only overwrites if the parameter is provided
- This enables the application to update only specific fields without needing to pass all plan data

### 2.2 Cascading Instance Cancellation

**What**: When a plan is cancelled, the latest in-progress instance is also cancelled.

**Columns/Parameters Involved**: `@PlanStatusID`, `@StatusReasonID`, PlanInstances.InstanceStatusID

**Rules**:
- Only triggers when @PlanStatusID = 2 (Cancelled)
- Uses ROW_NUMBER() OVER (PARTITION BY PlanID ORDER BY NextOrderDate DESC) to find the latest instance
- Only cancels if the instance status is InProgress (5) or NULL: `ISNULL(PI.InstanceStatusID, 5) = 5`
- Does NOT cancel instances that are already completed (1=Success, 3=Skipped, 4=UserSkipped)
- Fix applied 6/4/25: added the completed status check to prevent overwriting final statuses

**Diagram**:
```
PlanUpdate(@PlanStatusID = 2)
    |
    v
UPDATE Plans SET PlanStatusID = 2, EndDate = @EndDate
    |
    v
Find latest instance (ROW_NUMBER DESC)
    |
    +-- Instance is InProgress/NULL --> SET InstanceStatusID = 2 (Cancelled)
    |
    +-- Instance is Success/Skipped/UserSkipped --> DO NOT update
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanID | int | NO | - | VERIFIED | Plan to update. |
| 2 | @GCID | bigint | NO | - | VERIFIED | Plan owner's GCID. Used to return all plans after update. |
| 3 | @RecurringDepositID | int | YES | NULL | VERIFIED | New recurring deposit plan ID. NULL = no change. |
| 4 | @PlanStatusID | int | YES | NULL | VERIFIED | New plan status. 2 triggers cascading instance cancellation. NULL = no change. |
| 5 | @StatusReasonID | int | YES | NULL | VERIFIED | Reason for status change. See [Plan Event Code](../../_glossary.md#plan-event-code). NULL = no change. |
| 6 | @EndDate | datetime | YES | NULL | VERIFIED | Cancellation date. Set when plan is cancelled. NULL = no change. |
| 7 | @Amount | int | YES | NULL | CODE-BACKED | New investment amount. NULL = no change. Note: declared as INT, not decimal. |
| 8 | @CurrencyID | int | YES | NULL | VERIFIED | New currency. NULL = no change. |
| 9 | @RepeatsOn | int | YES | NULL | VERIFIED | New execution day. NULL = no change. |
| 10 | @FundingID | int | YES | NULL | VERIFIED | New payment method. NULL = no change. |
| 11 | @HasBackupPayment | bit | YES | NULL | VERIFIED | New backup payment flag. NULL = no change. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.Plans | Write | UPDATE |
| - | RecurringInvestment.PlanInstances | Write | UPDATE latest instance on cancellation |
| - | RecurringInvestment.PlansGetByGCID | EXEC | Returns all plans after update |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanUpdate (procedure)
├── RecurringInvestment.Plans (table) [UPDATE]
├── RecurringInvestment.PlanInstances (table) [UPDATE on cancel]
└── RecurringInvestment.PlansGetByGCID (procedure) [EXEC]
      ├── RecurringInvestment.Plans (table)
      └── RecurringInvestment.PlanInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | UPDATE SET |
| RecurringInvestment.PlanInstances | Table | UPDATE latest instance on plan cancellation |
| RecurringInvestment.PlansGetByGCID | Stored Procedure | Called after update |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Uses TRY/CATCH with TRAN for atomicity.

---

## 8. Sample Queries

### 8.1 Update plan amount
```sql
EXEC [RecurringInvestment].[PlanUpdate] @PlanID = 100, @GCID = 12345678, @Amount = 200
```

### 8.2 Cancel a plan
```sql
EXEC [RecurringInvestment].[PlanUpdate] @PlanID = 100, @GCID = 12345678,
  @PlanStatusID = 2, @StatusReasonID = 700, @EndDate = '2026-04-13'
```

### 8.3 Link to recurring deposit plan
```sql
EXEC [RecurringInvestment].[PlanUpdate] @PlanID = 100, @GCID = 12345678,
  @RecurringDepositID = 200427
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Plan update and cancellation flows |
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Plans and PlanInstances table structure; code comment references EDGE-3688 |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 9 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.PlanUpdate | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanUpdate.sql*
