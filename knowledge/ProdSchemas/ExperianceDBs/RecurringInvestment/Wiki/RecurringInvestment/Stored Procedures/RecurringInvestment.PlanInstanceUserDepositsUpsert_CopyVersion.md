# RecurringInvestment.PlanInstanceUserDepositsUpsert_CopyVersion

> Copy-plan version of the deposit upsert procedure, using a TVP that includes copy-trading columns (MirrorOrderCreated, MirrorID, CopyPositionStatusID, CopyFailErrorCode).

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | PlanInstancesDepositsType_CopyVersion TVP + deposit params, writes to PlanInstances + UserDeposits |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the copy-plan variant of the deposit upsert family. It performs the same atomic deposit processing as `PlanInstanceUserDepositUpsert` and `PlanInstanceUserDepositsUpsert`, but uses the `PlanInstancesDepositsType_CopyVersion` TVP which includes four additional copy-trading columns: MirrorOrderCreated, MirrorID, CopyPositionStatusID, and CopyFailErrorCode.

This variant exists because copy-type plans (PlanType=2) have additional state fields related to the mirror/copy trading flow that must be updated alongside the deposit data. When a deposit completes for a copy plan, the system may also need to record the initial copy-trading state (whether a mirror order was created, the mirror relationship ID, etc.).

The procedure is called by the Deposit Message Handler when processing deposits for copy-type recurring investment plans.

---

## 2. Business Logic

### 2.1 Atomic Copy-Plan Deposit Processing

**What**: Updates instance records with deposit AND copy-trading data from a copy-specific TVP, plus inserts a UserDeposits record.

**Columns/Parameters Involved**: `@PlanInstancesDepositsInsertMultiple` (PlanInstancesDepositsType_CopyVersion), scalar deposit params

**Rules**:
- Same transactional pattern as V1 and V2
- UPDATE PlanInstances from TVP includes all standard fields PLUS:
  - MirrorOrderCreated: whether a copy order was initiated
  - MirrorID: the mirror/copy relationship ID
  - CopyPositionStatusID: status of copy position creation
  - CopyFailErrorCode: error code if copy failed
- Also includes DepositFailReason (like V1, unlike V2)
- INSERT UserDeposits with scalar parameters (same as V1/V2)

**Diagram**:
```
Copy Plan Deposit Callback
    |
    v
BEGIN TRAN
    |
    +-- UPDATE PlanInstances (from Copy TVP):
    |       Standard fields + MirrorOrderCreated, MirrorID,
    |       CopyPositionStatusID, CopyFailErrorCode
    |       + DepositAmountUsd/Currency from scalar params
    |       + UpdateDate = GETUTCDATE()
    |
    +-- INSERT UserDeposits
    |
    v
COMMIT TRAN
```

### 2.2 Copy-Trading State Tracking

**What**: The copy-specific TVP enables recording copy-trading lifecycle events alongside deposit events.

**Columns/Parameters Involved**: `MirrorOrderCreated`, `MirrorID`, `CopyPositionStatusID`, `CopyFailErrorCode`

**Rules**:
- MirrorOrderCreated = 1 when a mirror order has been created for this instance
- MirrorID identifies the copy relationship in the copy-trading system
- CopyPositionStatusID tracks whether register and add-funds steps succeeded (1=RegisterSuccess, 2=AddFundsSuccess, 3=RegisterFailed, 4=AddFundFailed)
- CopyFailErrorCode records the specific error if copy failed

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanInstancesDepositsInsertMultiple | RecurringInvestment.PlanInstancesDepositsType_CopyVersion (TVP) | NO | - | VERIFIED | Copy-specific TVP with standard deposit fields plus MirrorOrderCreated, MirrorID, CopyPositionStatusID, CopyFailErrorCode. |
| 2 | @GCID | bigint | NO | - | VERIFIED | Global Customer ID. Used for UserDeposits INSERT. |
| 3 | @DepositID | int | NO | - | VERIFIED | Deposit ID from Money Group. |
| 4 | @DepositAmountUsd | decimal(18,2) | YES | NULL | VERIFIED | Deposit amount in USD. |
| 5 | @DepositAmountCurrency | decimal(18,2) | YES | NULL | VERIFIED | Deposit amount in plan currency. |
| 6 | @DepositDate | datetime | YES | NULL | VERIFIED | Timestamp of the deposit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Write (UPDATE) | Updates instance records with deposit + copy data |
| - | RecurringInvestment.UserDeposits | Write (INSERT) | Creates deposit log record |
| @PlanInstancesDepositsInsertMultiple | RecurringInvestment.PlanInstancesDepositsType_CopyVersion | TVP | Copy-version input type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit Message Handler (Copy) | - | EXEC | Processes deposits for copy-type plans |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstanceUserDepositsUpsert_CopyVersion (procedure)
├── RecurringInvestment.PlanInstances (table)
├── RecurringInvestment.UserDeposits (table)
└── RecurringInvestment.PlanInstancesDepositsType_CopyVersion (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | UPDATE via TVP JOIN |
| RecurringInvestment.UserDeposits | Table | INSERT INTO |
| RecurringInvestment.PlanInstancesDepositsType_CopyVersion | User Defined Type | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Deposit Message Handler (Copy) | Application | Processes copy-plan deposit callbacks |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Transaction-wrapped with nested-transaction-aware CATCH block
- TVP is READONLY

---

## 8. Sample Queries

### 8.1 Call with copy-version TVP
```sql
DECLARE @TVP RecurringInvestment.PlanInstancesDepositsType_CopyVersion
INSERT INTO @TVP (InstanceID, PlanID, NextOrderDate, DepositID, DepositCycleNumber, DepositDate,
    HighLevelDepositStatusId, DepositStatusID, InstanceStatusID,
    MirrorOrderCreated, MirrorID, CopyPositionStatusID, CopyFailErrorCode)
VALUES (5001, 1001, '2026-04-15', 99001, 1, GETUTCDATE(), 1, 1, 5, 1, 50001, 1, NULL)

EXEC [RecurringInvestment].[PlanInstanceUserDepositsUpsert_CopyVersion]
    @PlanInstancesDepositsInsertMultiple = @TVP,
    @GCID = 12345678, @DepositID = 99001,
    @DepositAmountUsd = 200.00, @DepositAmountCurrency = 200.00,
    @DepositDate = '2026-04-13'
```

### 8.2 Verify copy fields were updated
```sql
SELECT InstanceID, MirrorOrderCreated, MirrorID, CopyPositionStatusID, CopyFailErrorCode, UpdateDate
FROM [RecurringInvestment].[PlanInstances] WITH (NOLOCK)
WHERE InstanceID = 5001
```

### 8.3 Find copy instances with failed copy positions
```sql
SELECT PI.InstanceID, PI.CopyPositionStatusID, PI.CopyFailErrorCode, P.CopyType
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON PI.PlanID = P.ID
WHERE P.PlanType = 2 AND PI.CopyPositionStatusID IN (3, 4)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Copy-trading columns in PlanInstances, deposit flow |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Copy plan deposit handling architecture |

---

*Generated: 2026-04-13 | Quality: 9.1/10*
*Object: RecurringInvestment.PlanInstanceUserDepositsUpsert_CopyVersion | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstanceUserDepositsUpsert_CopyVersion.sql*
