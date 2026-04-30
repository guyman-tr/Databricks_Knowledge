# RecurringInvestment.PlansCancelAllUserPlansUpdateInstanceStatus

> Atomically cancels all of a user's active plans and updates their in-progress instance statuses in a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CancelPlansType + @PlanInstancesUpdateStatus TVPs, modifies Plans + PlanInstances |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure performs an atomic batch cancellation of all active plans for a single user. It updates both the plan statuses (to cancelled) and any in-progress instance statuses (to cancelled or appropriate terminal state) in a single transaction. This is used when a user requests to cancel all their recurring investment plans, or when the system needs to cancel all plans due to compliance, eligibility, or payment issues.

The procedure enforces a critical safety constraint: all rows in the @CancelPlansType TVP must have the same GCID. If different GCIDs are found, the procedure throws error 50001 and rolls back, preventing accidental cross-user cancellations. After the updates, it calls PlansGetByGCID to return the updated plan list.

Created per EDGE-4581 (Nilly, 08/12/24).

---

## 2. Business Logic

### 2.1 Atomic Batch Cancellation

**What**: Cancels all user plans and their instances in a single transaction with GCID validation.

**Columns/Parameters Involved**: `@CancelPlansType`, `@PlanInstancesUpdateStatus`, `GCID`, `PlanStatusID`, `StatusReasonID`, `EndDate`, `InstanceStatusID`, `InstanceStatusReasonID`

**Rules**:
- BEGIN TRAN wraps all operations
- Step 1: UPDATE PlanInstances -- sets InstanceStatusID and InstanceStatusReasonID from TVP
- Step 2: Extract GCID from @CancelPlansType (TOP 1)
- Step 3: Validate all rows have same GCID (THROW 50001 if not)
- Step 4: UPDATE Plans -- sets PlanStatusID, StatusReasonId, EndDate from TVP, filtered by Plans.GCID = @GCID
- Step 5: EXEC PlansGetByGCID to return updated plan list
- Standard nested-transaction-aware CATCH block

**Diagram**:
```
BEGIN TRAN
    |
    +-- UPDATE PlanInstances (status from @PlanInstancesUpdateStatus TVP)
    |       - Set InstanceStatusID, InstanceStatusReasonID, UpdateDate
    |
    +-- Extract @GCID from @CancelPlansType
    |
    +-- VALIDATE: All GCIDs in TVP are the same
    |       |
    |       +-- Different GCIDs? --> THROW 50001, ROLLBACK
    |
    +-- UPDATE Plans (status from @CancelPlansType TVP)
    |       - Set PlanStatusID, StatusReasonId, EndDate
    |       - WHERE Plans.GCID = @GCID (additional safety)
    |
    +-- EXEC PlansGetByGCID @GCID --> return updated plans
    |
    v
COMMIT TRAN
```

### 2.2 Single-User GCID Enforcement

**What**: Validates that all plans being cancelled belong to the same user.

**Columns/Parameters Involved**: `@CancelPlansType.GCID`

**Rules**:
- SELECT TOP 1 @GCID from TVP
- IF EXISTS (SELECT 1 FROM TVP WHERE GCID <> @GCID): different GCIDs found
- THROW 50001: 'Multiple different GCIDs found in @CancelPlansType. Expected only one.'
- This prevents a programming error from accidentally cancelling plans for multiple users in one call
- The Plans UPDATE also joins on @GCID = P.GCID for double safety

### 2.3 Instance Status Update

**What**: Updates in-progress instance statuses before cancelling the plans.

**Columns/Parameters Involved**: `@PlanInstancesUpdateStatus`, `InstanceStatusID`, `InstanceStatusReasonID`, `UpdateDate`

**Rules**:
- Instance statuses are updated FIRST (before plan cancellation)
- UpdateDate set to GETUTCDATE() to track when the cancellation happened
- JOIN on InstanceID from the TVP
- Typical values: InstanceStatusID=2 (Cancelled), InstanceStatusReasonID=300 or 700-range

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CancelPlansType | RecurringInvestment.CancelPlansType (TVP) | NO | - | VERIFIED | TVP containing PlanID, GCID, PlanStatusID, StatusReasonId, EndDate for each plan to cancel. |
| 2 | @PlanInstancesUpdateStatus | RecurringInvestment.PlanInstancesUpdateStatus (TVP) | NO | - | VERIFIED | TVP containing InstanceID, InstanceStatusID, InstanceStatusReasonID for in-progress instances to update. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Write (UPDATE) | Updates instance statuses to cancelled |
| - | RecurringInvestment.Plans | Write (UPDATE) | Updates plan statuses to cancelled |
| - | RecurringInvestment.PlansGetByGCID | EXEC | Returns updated plan list after cancellation |
| @CancelPlansType | RecurringInvestment.CancelPlansType | TVP | Plan cancellation data |
| @PlanInstancesUpdateStatus | RecurringInvestment.PlanInstancesUpdateStatus | TVP | Instance cancellation data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Plan Cancellation Service | - | EXEC | Called when all user plans need cancellation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlansCancelAllUserPlansUpdateInstanceStatus (procedure)
├── RecurringInvestment.PlanInstances (table)
├── RecurringInvestment.Plans (table)
├── RecurringInvestment.CancelPlansType (type)
├── RecurringInvestment.PlanInstancesUpdateStatus (type)
└── RecurringInvestment.PlansGetByGCID (procedure)
    ├── RecurringInvestment.Plans (table)
    └── RecurringInvestment.PlanInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | UPDATE instance statuses |
| RecurringInvestment.Plans | Table | UPDATE plan statuses |
| RecurringInvestment.PlansGetByGCID | Stored Procedure | Returns updated plan list |
| RecurringInvestment.CancelPlansType | User Defined Type | TVP for plan cancellation |
| RecurringInvestment.PlanInstancesUpdateStatus | User Defined Type | TVP for instance status update |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Plan Cancellation Service | Application | Batch cancellation of all user plans |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Transaction-wrapped with nested-transaction-aware CATCH block
- THROW 50001 if multiple GCIDs detected in @CancelPlansType
- Both TVPs are READONLY

---

## 8. Sample Queries

### 8.1 Cancel all plans for a user
```sql
DECLARE @Plans RecurringInvestment.CancelPlansType
DECLARE @Instances RecurringInvestment.PlanInstancesUpdateStatus

INSERT INTO @Plans (PlanID, GCID, PlanStatusID, StatusReasonId, EndDate)
VALUES (1001, 12345678, 2, 700, GETUTCDATE()),
       (1002, 12345678, 2, 700, GETUTCDATE())

INSERT INTO @Instances (InstanceID, InstanceStatusID, InstanceStatusReasonID)
VALUES (5001, 2, 700), (5003, 2, 700)

EXEC [RecurringInvestment].[PlansCancelAllUserPlansUpdateInstanceStatus]
    @CancelPlansType = @Plans,
    @PlanInstancesUpdateStatus = @Instances
```

### 8.2 Verify cancellation
```sql
SELECT ID, PlanStatusID, StatusReasonID, EndDate
FROM [RecurringInvestment].[Plans] WITH (NOLOCK)
WHERE GCID = 12345678
ORDER BY ID
```

### 8.3 Check cancelled instance statuses
```sql
SELECT PI.InstanceID, PI.PlanID, PI.InstanceStatusID, PI.InstanceStatusReasonID, PI.UpdateDate
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE P.GCID = 12345678 AND PI.InstanceStatusID = 2
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Plan and instance lifecycle, cancellation flow |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Plan cancellation architecture |
| [EDGE-4581](https://etoro-jira.atlassian.net/browse/EDGE-4581) | Jira | Batch plan cancellation implementation |

---

*Generated: 2026-04-13 | Quality: 9.4/10*
*Object: RecurringInvestment.PlansCancelAllUserPlansUpdateInstanceStatus | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlansCancelAllUserPlansUpdateInstanceStatus.sql*
