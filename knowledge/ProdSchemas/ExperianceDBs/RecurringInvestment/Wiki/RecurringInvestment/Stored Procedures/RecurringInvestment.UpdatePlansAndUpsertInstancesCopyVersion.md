# RecurringInvestment.UpdatePlansAndUpsertInstancesCopyVersion

> Atomically upserts plan instances and updates plan configuration for copy trading plans, using the extended PlansTypeCopyVersion TVP that includes copy-specific columns.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PlanTypeCopyVersion + @PlanInstancesUpsert TVPs, modifies Plans + PlanInstances |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the copy trading variant of UpdatePlansAndUpsertInstances. It performs the same transactional operations -- upserting plan instances and updating plan configuration -- but accepts the PlansTypeCopyVersion TVP instead of the standard PlansType. The copy version includes additional columns for copy trading relationships: PlanType, CopyType, CopyParentCID, and CopyParentGCID.

Copy trading plans (PlanType=2) allow users to automatically invest by copying another trader's portfolio. When modifying a copy plan, the system may need to update not just the amount and schedule but also the copy relationship itself (e.g., switching which trader to copy). This procedure supports that use case.

The shared settings propagation logic (FundingID, RepeatsOn, DepositStartDate, HasBackupPayment) works identically to the standard version -- these settings are propagated to ALL the user's plans regardless of plan type.

Created per EDGE-4377 (Nilly, 25/5/25).

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
- Identical MERGE logic to UpdatePlansAndUpsertInstances

### 2.2 Copy Plan Configuration Update

**What**: Updates the specific copy plan's modifiable configuration fields.

**Columns/Parameters Involved**: `@PlanTypeCopyVersion`, `Amount`, `AmountUsd`, `FundingID`, `RepeatsOn`, `DepositStartDate`, `HasBackupPayment`

**Rules**:
- INNER JOIN Plans to @PlanTypeCopyVersion TVP on PlanID = ID
- Additional filter: PlanStatusID IN (1, 5) -- only active/initializing plans
- ISNULL pattern: Amount = ISNULL(TVP.Amount, existing.Amount) -- NULL means "don't change"
- FundingID is set directly (always overwritten)
- Note: Although the TVP includes PlanType, CopyType, CopyParentCID, and CopyParentGCID, the UPDATE statement does not modify these columns -- they are available in the TVP for potential future use or for the application layer

### 2.3 Shared Settings Propagation

**What**: Propagates FundingID, RepeatsOn, DepositStartDate, and HasBackupPayment to all plans for the same user.

**Columns/Parameters Involved**: `@GCID`, `FundingID`, `RepeatsOn`, `DepositStartDate`, `HasBackupPayment`

**Rules**:
- Extracts @GCID from @PlanTypeCopyVersion TVP (SELECT DISTINCT @GCID = GCID)
- Updates ALL Plans WHERE GCID = @GCID AND PlanStatusID IN (1, 5)
- Same ISNULL pattern for RepeatsOn, DepositStartDate, HasBackupPayment
- FundingID is set directly
- Propagation applies to ALL user plans (both instrument and copy plans)

### 2.4 Return Updated Plans

**What**: Returns the full updated plan list by calling PlansGetByGCID.

**Columns/Parameters Involved**: `@GCID`

**Rules**:
- EXEC PlansGetByGCID @GCID after all updates
- Returns plans with aggregated SumPositionAmountUsd

**Diagram**:
```
BEGIN TRAN
    |
    +-- MERGE PlanInstances (upsert from @PlanInstancesUpsert)
    |       - Match on InstanceID
    |       - Update NextOrderDate or Insert new
    |       - Only for plans with PlanStatusID IN (1, 5)
    |
    +-- Extract @GCID from @PlanTypeCopyVersion
    |
    +-- UPDATE Plans (specific plan fields from @PlanTypeCopyVersion)
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
| 1 | @PlanTypeCopyVersion | RecurringInvestment.PlansTypeCopyVersion (TVP) | NO | - | VERIFIED | TVP with PlanID, GCID, Amount, AmountUsd, FundingID, RepeatsOn, DepositStartDate, HasBackupPayment, PlanType, CopyType, CopyParentCID, CopyParentGCID. |
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
| @PlanTypeCopyVersion | RecurringInvestment.PlansTypeCopyVersion | TVP | Copy plan modification data |
| @PlanInstancesUpsert | RecurringInvestment.PlanInstancesType | TVP | Instance upsert data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Plan Modification Service | - | EXEC | Updates copy trading plan configuration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.UpdatePlansAndUpsertInstancesCopyVersion (procedure)
├── RecurringInvestment.PlanInstances (table)
├── RecurringInvestment.Plans (table)
├── RecurringInvestment.PlansTypeCopyVersion (type)
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
| RecurringInvestment.PlansTypeCopyVersion | User Defined Type | TVP for copy plan modification data |
| RecurringInvestment.PlanInstancesType | User Defined Type | TVP for instance upsert data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Plan Modification Service | Application | Copy trading plan configuration updates |

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
- Functionally identical to UpdatePlansAndUpsertInstances except for the TVP type used

---

## 8. Sample Queries

### 8.1 Update a copy plan's amount and reschedule its instance
```sql
DECLARE @Plans RecurringInvestment.PlansTypeCopyVersion
DECLARE @Instances RecurringInvestment.PlanInstancesType

INSERT INTO @Plans (PlanID, GCID, Amount, AmountUsd, FundingID, RepeatsOn, DepositStartDate, HasBackupPayment, PlanType, CopyType, CopyParentCID, CopyParentGCID)
VALUES (2001, 12345678, 500.00, 500.00, 55, 15, '2025-02-15', 1, 2, 1, 99999, 88888)

INSERT INTO @Instances (InstanceID, PlanID, NextOrderDate)
VALUES (6001, 2001, '2025-03-15T10:00:00')

EXEC [RecurringInvestment].[UpdatePlansAndUpsertInstancesCopyVersion]
    @PlanTypeCopyVersion = @Plans,
    @PlanInstancesUpsert = @Instances
```

### 8.2 Insert a new instance for an existing copy plan
```sql
DECLARE @Plans RecurringInvestment.PlansTypeCopyVersion
DECLARE @Instances RecurringInvestment.PlanInstancesType

INSERT INTO @Plans (PlanID, GCID, Amount, FundingID, PlanType, CopyType, CopyParentCID, CopyParentGCID)
VALUES (2001, 12345678, NULL, 55, 2, 1, 99999, 88888)

INSERT INTO @Instances (PlanID, NextOrderDate)
VALUES (2001, '2025-04-15T10:00:00')

EXEC [RecurringInvestment].[UpdatePlansAndUpsertInstancesCopyVersion]
    @PlanTypeCopyVersion = @Plans,
    @PlanInstancesUpsert = @Instances
```

### 8.3 Verify shared settings propagated across all plan types
```sql
SELECT ID, PlanType, CopyType, FundingID, RepeatsOn, DepositStartDate, HasBackupPayment
FROM [RecurringInvestment].[Plans] WITH (NOLOCK)
WHERE GCID = 12345678 AND PlanStatusID IN (1, 5)
ORDER BY PlanType, ID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Plans table copy trading columns, PlansTypeCopyVersion TVP structure |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Copy plan modification flow and shared settings propagation |
| [EDGE-4377](https://etoro-jira.atlassian.net/browse/EDGE-4377) | Jira | Copy version of plan update with instance upsert |

---

*Generated: 2026-04-13 | Quality: 9.4/10*
*Object: RecurringInvestment.UpdatePlansAndUpsertInstancesCopyVersion | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.UpdatePlansAndUpsertInstancesCopyVersion.sql*
