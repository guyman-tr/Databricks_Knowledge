# RecurringInvestment.UpdatePlansAndUpsertInstances

> Atomically upserts plan instances and updates plan configuration (amount, funding, schedule) for standard instrument plans, then propagates shared settings to all user plans.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PlanType + @PlanInstancesUpsert TVPs, modifies Plans + PlanInstances |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the primary plan modification procedure for standard instrument-type recurring investment plans. It handles two related operations in a single transaction: (1) upserting plan instance records (updating NextOrderDate for existing instances or inserting new ones), and (2) updating plan configuration fields like Amount, FundingID, RepeatsOn, and DepositStartDate.

A critical design aspect is the propagation of shared settings. When a user changes their funding method (FundingID), execution day (RepeatsOn), deposit start date, or backup payment flag, these changes apply to ALL the user's plans, not just the one being modified. This ensures consistency across a user's entire recurring investment portfolio. After all updates complete, the procedure returns the updated plan list by calling PlansGetByGCID.

This is the standard version for instrument plans (PlanType=1). Copy trading plans use UpdatePlansAndUpsertInstancesCopyVersion which accepts PlansTypeCopyVersion with additional copy-specific columns.

Created per EDGE-4377 (Nilly, 28/11/24).

---

## 2. Business Logic

### 2.1 Instance Upsert via MERGE

**What**: Inserts new plan instance records or updates existing ones within a single MERGE statement.

**Columns/Parameters Involved**: `@PlanInstancesUpsert`, `InstanceID`, `PlanID`, `NextOrderDate`, `PlanStatusID`

**Rules**:
- MERGE target is PlanInstances table
- Source is @PlanInstancesUpsert TVP, filtered by EXISTS to only include instances whose parent plan has PlanStatusID IN (1, 5) (Active or Initializing)
- WHEN MATCHED: UPDATE NextOrderDate (reschedules an existing instance)
- WHEN NOT MATCHED BY TARGET: INSERT new record with PlanID and NextOrderDate
- Match key is InstanceID
- This prevents modification of instances belonging to cancelled plans

### 2.2 Plan Configuration Update

**What**: Updates the specific plan's modifiable configuration fields.

**Columns/Parameters Involved**: `@PlanType`, `Amount`, `AmountUsd`, `FundingID`, `RepeatsOn`, `DepositStartDate`, `HasBackupPayment`

**Rules**:
- INNER JOIN Plans to @PlanType TVP on PlanID = ID
- Additional filter: PlanStatusID IN (1, 5) -- only active/initializing plans
- ISNULL pattern: Amount = ISNULL(TVP.Amount, existing.Amount) -- NULL in TVP means "don't change"
- FundingID is set directly (not ISNULL-wrapped), meaning it always updates even to NULL
- This asymmetry means FundingID is always overwritten while other fields are conditionally updated

### 2.3 Shared Settings Propagation

**What**: Propagates FundingID, RepeatsOn, DepositStartDate, and HasBackupPayment to all plans for the same user.

**Columns/Parameters Involved**: `@GCID`, `FundingID`, `RepeatsOn`, `DepositStartDate`, `HasBackupPayment`

**Rules**:
- Extracts @GCID from @PlanType TVP (SELECT DISTINCT @GCID = GCID)
- Updates ALL Plans WHERE GCID = @GCID AND PlanStatusID IN (1, 5)
- Same ISNULL pattern for RepeatsOn, DepositStartDate, HasBackupPayment
- FundingID is set directly
- This ensures all user plans share the same payment method and schedule
- Only active/initializing plans are affected

### 2.4 Return Updated Plans

**What**: Returns the full updated plan list by calling PlansGetByGCID.

**Columns/Parameters Involved**: `@GCID`

**Rules**:
- EXEC PlansGetByGCID @GCID after all updates
- Returns plans with aggregated SumPositionAmountUsd
- This is the final step before COMMIT

**Diagram**:
```
BEGIN TRAN
    |
    +-- MERGE PlanInstances (upsert from @PlanInstancesUpsert)
    |       - Match on InstanceID
    |       - Update NextOrderDate or Insert new
    |       - Only for plans with PlanStatusID IN (1, 5)
    |
    +-- Extract @GCID from @PlanType
    |
    +-- UPDATE Plans (specific plan fields from @PlanType)
    |       - Amount, AmountUsd, FundingID, RepeatsOn, DepositStartDate, HasBackupPayment
    |
    +-- UPDATE Plans (propagate shared settings to ALL user plans)
    |       - FundingID, RepeatsOn, DepositStartDate, HasBackupPayment
    |       - WHERE GCID = @GCID
    |
    +-- EXEC PlansGetByGCID @GCID --> return updated plans
    |
    v
COMMIT TRAN
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanType | RecurringInvestment.PlansType (TVP) | NO | - | VERIFIED | TVP containing PlanID, GCID, Amount, AmountUsd, FundingID, RepeatsOn, DepositStartDate, HasBackupPayment. |
| 2 | @PlanInstancesUpsert | RecurringInvestment.PlanInstancesType (TVP) | NO | - | VERIFIED | TVP containing InstanceID, PlanID, NextOrderDate for instance upsert. |

**Return Columns**: Same as PlansGetByGCID (see [PlansGetByGCID](RecurringInvestment.PlansGetByGCID.md)).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Write (MERGE) | Upserts instance records |
| - | RecurringInvestment.Plans | Write (UPDATE) | Updates plan configuration and propagates shared settings |
| - | RecurringInvestment.PlansGetByGCID | EXEC | Returns updated plan list |
| @PlanType | RecurringInvestment.PlansType | TVP | Plan modification data |
| @PlanInstancesUpsert | RecurringInvestment.PlanInstancesType | TVP | Instance upsert data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Plan Modification Service | - | EXEC | Updates instrument plan configuration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.UpdatePlansAndUpsertInstances (procedure)
├── RecurringInvestment.PlanInstances (table)
├── RecurringInvestment.Plans (table)
├── RecurringInvestment.PlansType (type)
├── RecurringInvestment.PlanInstancesType (type)
└── RecurringInvestment.PlansGetByGCID (procedure)
    ├── RecurringInvestment.Plans (table)
    └── RecurringInvestment.PlanInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | MERGE target for upsert |
| RecurringInvestment.Plans | Table | UPDATE for plan config and shared settings propagation |
| RecurringInvestment.PlansGetByGCID | Stored Procedure | Returns updated plan list |
| RecurringInvestment.PlansType | User Defined Type | TVP for plan modification data |
| RecurringInvestment.PlanInstancesType | User Defined Type | TVP for instance upsert data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Plan Modification Service | Application | Instrument plan configuration updates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Transaction-wrapped with nested-transaction-aware CATCH block
- CATCH logic: @@TRANCOUNT = 1 -> ROLLBACK; @@TRANCOUNT > 1 -> COMMIT (propagate to outer transaction)
- Both TVPs are READONLY
- MERGE only processes instances for plans with PlanStatusID IN (1, 5)
- FundingID is always overwritten; other fields use ISNULL for conditional update

---

## 8. Sample Queries

### 8.1 Update a plan's amount and reschedule its instance
```sql
DECLARE @Plans RecurringInvestment.PlansType
DECLARE @Instances RecurringInvestment.PlanInstancesType

INSERT INTO @Plans (PlanID, GCID, Amount, AmountUsd, FundingID, RepeatsOn, DepositStartDate, HasBackupPayment)
VALUES (1001, 12345678, 200.00, 200.00, 55, 15, '2025-02-15', 1)

INSERT INTO @Instances (InstanceID, PlanID, NextOrderDate)
VALUES (5001, 1001, '2025-03-15T10:00:00')

EXEC [RecurringInvestment].[UpdatePlansAndUpsertInstances]
    @PlanType = @Plans,
    @PlanInstancesUpsert = @Instances
```

### 8.2 Insert a new instance for an existing plan
```sql
DECLARE @Plans RecurringInvestment.PlansType
DECLARE @Instances RecurringInvestment.PlanInstancesType

INSERT INTO @Plans (PlanID, GCID, Amount, FundingID)
VALUES (1001, 12345678, NULL, 55)

INSERT INTO @Instances (PlanID, NextOrderDate)
VALUES (1001, '2025-04-15T10:00:00')

EXEC [RecurringInvestment].[UpdatePlansAndUpsertInstances]
    @PlanType = @Plans,
    @PlanInstancesUpsert = @Instances
```

### 8.3 Verify shared settings propagation
```sql
SELECT ID, FundingID, RepeatsOn, DepositStartDate, HasBackupPayment
FROM [RecurringInvestment].[Plans] WITH (NOLOCK)
WHERE GCID = 12345678
ORDER BY ID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Plans and PlanInstances table structure, shared settings concept |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Plan modification flow and shared settings propagation architecture |
| [EDGE-4377](https://etoro-jira.atlassian.net/browse/EDGE-4377) | Jira | Plan update with instance upsert implementation |

---

*Generated: 2026-04-13 | Quality: 9.4/10*
*Object: RecurringInvestment.UpdatePlansAndUpsertInstances | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.UpdatePlansAndUpsertInstances.sql*
