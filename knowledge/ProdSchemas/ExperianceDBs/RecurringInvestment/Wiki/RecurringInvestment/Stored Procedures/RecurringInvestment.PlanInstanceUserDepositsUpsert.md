# RecurringInvestment.PlanInstanceUserDepositsUpsert

> V2 version of the deposit upsert procedure using PlanInstancesDepositsTypeV2 TVP (without DepositFailReason column).

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | PlanInstancesDepositsTypeV2 TVP + deposit params, writes to PlanInstances + UserDeposits |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the V2 version of `PlanInstanceUserDepositUpsert`. It performs the same atomic deposit processing -- updating plan instance records from a TVP and inserting a UserDeposits record -- but uses the `PlanInstancesDepositsTypeV2` TVP which does not include the DepositFailReason column.

The V2 version exists because the DepositFailReason was removed from the TVP schema in a later iteration. The deposit fail reason may still be set by other means or was determined to not be needed at the TVP level. The core transactional logic is identical to V1.

This procedure is called by newer versions of the Deposit Message Handler when the application determines that the fail reason does not need to be passed through the TVP.

---

## 2. Business Logic

### 2.1 Atomic Deposit Processing (V2)

**What**: Same as V1 -- updates instances from TVP and inserts UserDeposits in a transaction.

**Columns/Parameters Involved**: `@PlanInstancesDepositsInsertMultiple` (PlanInstancesDepositsTypeV2), `@GCID`, `@DepositID`, deposit amounts

**Rules**:
- Identical transaction pattern to PlanInstanceUserDepositUpsert (V1)
- UPDATE PlanInstances from TVP on InstanceID join
- INSERT UserDeposits with scalar parameters
- Key difference: TVP does NOT contain DepositFailReason -- the UPDATE does not set this column
- UpdateDate set to GETUTCDATE() on each updated instance
- Same nested-transaction-aware error handling

**Diagram**:
```
V2 Deposit Callback Message
    |
    v
BEGIN TRAN
    |
    +-- UPDATE PlanInstances (from V2 TVP: no DepositFailReason)
    |       - DepositAmountUsd/Currency from scalar params
    |       - UpdateDate = GETUTCDATE()
    |
    +-- INSERT UserDeposits
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
| 1 | @PlanInstancesDepositsInsertMultiple | RecurringInvestment.PlanInstancesDepositsTypeV2 (TVP) | NO | - | VERIFIED | V2 table-valued parameter for instance updates. Does NOT include DepositFailReason column. |
| 2 | @GCID | bigint | NO | - | VERIFIED | Global Customer ID. Used for UserDeposits INSERT. |
| 3 | @DepositID | int | NO | - | VERIFIED | Deposit ID from Money Group. Used for UserDeposits INSERT. |
| 4 | @DepositAmountUsd | decimal(18,2) | YES | NULL | VERIFIED | Deposit amount in USD. |
| 5 | @DepositAmountCurrency | decimal(18,2) | YES | NULL | VERIFIED | Deposit amount in plan currency. |
| 6 | @DepositDate | datetime | YES | NULL | VERIFIED | Timestamp of the deposit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Write (UPDATE) | Updates instance records with deposit results |
| - | RecurringInvestment.UserDeposits | Write (INSERT) | Creates deposit log record |
| @PlanInstancesDepositsInsertMultiple | RecurringInvestment.PlanInstancesDepositsTypeV2 | TVP | V2 input type (no DepositFailReason) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit Message Handler (V2) | - | EXEC | Called for deposit callbacks using V2 TVP schema |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstanceUserDepositsUpsert (procedure)
├── RecurringInvestment.PlanInstances (table)
├── RecurringInvestment.UserDeposits (table)
└── RecurringInvestment.PlanInstancesDepositsTypeV2 (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | UPDATE via TVP JOIN |
| RecurringInvestment.UserDeposits | Table | INSERT INTO |
| RecurringInvestment.PlanInstancesDepositsTypeV2 | User Defined Type | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Deposit Message Handler (V2) | Application | Processes V2 deposit callbacks |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Transaction-wrapped with nested-transaction-aware CATCH block
- TVP is READONLY

---

## 8. Sample Queries

### 8.1 Call with V2 TVP
```sql
DECLARE @TVP RecurringInvestment.PlanInstancesDepositsTypeV2
INSERT INTO @TVP (InstanceID, PlanID, NextOrderDate, DepositID, DepositCycleNumber, DepositDate,
    HighLevelDepositStatusId, DepositStatusID, InstanceStatusID)
VALUES (5001, 1001, '2026-04-15', 99001, 1, GETUTCDATE(), 1, 1, 5)

EXEC [RecurringInvestment].[PlanInstanceUserDepositsUpsert]
    @PlanInstancesDepositsInsertMultiple = @TVP,
    @GCID = 12345678, @DepositID = 99001,
    @DepositAmountUsd = 100.00, @DepositAmountCurrency = 100.00,
    @DepositDate = '2026-04-13'
```

### 8.2 Verify deposit was recorded in UserDeposits
```sql
SELECT * FROM [RecurringInvestment].[UserDeposits] WITH (NOLOCK)
WHERE DepositID = 99001
```

### 8.3 Compare V1 vs V2 behavior on DepositFailReason
```sql
-- V2 does not update DepositFailReason; check if it was left as-is
SELECT InstanceID, DepositFailReason, UpdateDate
FROM [RecurringInvestment].[PlanInstances] WITH (NOLOCK)
WHERE InstanceID = 5001
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | PlanInstances and UserDeposits structure |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Deposit message handling architecture, V2 TVP rationale |

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: RecurringInvestment.PlanInstanceUserDepositsUpsert | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstanceUserDepositsUpsert.sql*
