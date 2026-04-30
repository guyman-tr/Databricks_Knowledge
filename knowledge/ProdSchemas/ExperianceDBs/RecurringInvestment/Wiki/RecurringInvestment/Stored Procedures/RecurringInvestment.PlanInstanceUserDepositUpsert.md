# RecurringInvestment.PlanInstanceUserDepositUpsert

> Transactionally updates plan instance deposit data from a TVP and inserts a UserDeposits record, serving as the Deposit Message Handler entry point.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | PlanInstancesDepositsType TVP + deposit params, writes to PlanInstances + UserDeposits |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary entry point for processing deposit callbacks in the recurring investment pipeline. When the Money Group system confirms a deposit (or reports a failure), the application calls this procedure to atomically update the plan instance(s) with the deposit result and record the deposit details in the UserDeposits table.

Without this procedure, deposit confirmations would need to be processed in multiple non-atomic steps, risking data inconsistency between the PlanInstances status and the UserDeposits log. The transaction wrapper ensures that either both the instance update and the deposit record are persisted, or neither is.

The TVP (PlanInstancesDepositsType) carries the full instance state update including deposit status, order data, and position data. This allows a single call to update multiple fields on one or more instances. The separate scalar parameters (@GCID, @DepositID, etc.) are used for the UserDeposits INSERT.

---

## 2. Business Logic

### 2.1 Atomic Deposit Processing

**What**: Updates instance records from TVP and inserts a UserDeposits record within a single transaction.

**Columns/Parameters Involved**: `@PlanInstancesDepositsInsertMultiple` (TVP), `@GCID`, `@DepositID`, `@DepositAmountUsd`, `@DepositAmountCurrency`, `@DepositDate`

**Rules**:
- BEGIN TRAN wraps both the UPDATE and INSERT
- UPDATE joins PlanInstances to the TVP on InstanceID, setting all deposit/order/position fields
- DepositAmountUsd and DepositAmountCurrency come from scalar params (not from TVP)
- UpdateDate is set to GETUTCDATE() on each updated instance
- INSERT adds one UserDeposits row with the deposit summary
- Standard nested-transaction-aware CATCH block (ROLLBACK if outermost, COMMIT if nested)

**Diagram**:
```
Deposit Callback Message
    |
    v
BEGIN TRAN
    |
    +-- UPDATE PlanInstances (from TVP: deposit status, order, position data)
    |       - DepositAmountUsd/Currency from scalar params
    |       - UpdateDate = GETUTCDATE()
    |
    +-- INSERT UserDeposits (GCID, DepositID, amounts, date)
    |
    v
COMMIT TRAN
```

### 2.2 TVP-Based Batch Instance Update

**What**: Uses a table-valued parameter to update one or more instance records in a single UPDATE statement.

**Columns/Parameters Involved**: `PlanInstancesDepositsType` TVP columns

**Rules**:
- TVP contains InstanceID as the join key
- All deposit-related, order-related, and position-related columns are updated from the TVP
- The TVP includes DepositFailReason column (V1 version; V2 removes this)
- This allows updating multiple instances in a single statement if the deposit affects multiple instances

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanInstancesDepositsInsertMultiple | RecurringInvestment.PlanInstancesDepositsType (TVP) | NO | - | VERIFIED | Table-valued parameter containing instance updates with deposit/order/position data. Includes DepositFailReason column. |
| 2 | @GCID | bigint | NO | - | VERIFIED | Global Customer ID of the depositing user. Used for UserDeposits INSERT. |
| 3 | @DepositID | int | NO | - | VERIFIED | Deposit ID from Money Group. Used for UserDeposits INSERT. |
| 4 | @DepositAmountUsd | decimal(18,2) | YES | NULL | VERIFIED | Deposit amount in USD. Written to both PlanInstances.DepositAmountUsd and UserDeposits. |
| 5 | @DepositAmountCurrency | decimal(18,2) | YES | NULL | VERIFIED | Deposit amount in the plan's currency. Written to both PlanInstances.DepositAmountCurrency and UserDeposits. |
| 6 | @DepositDate | datetime | YES | NULL | VERIFIED | Timestamp of the deposit. Written to UserDeposits. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Write (UPDATE) | Updates instance records with deposit results |
| - | RecurringInvestment.UserDeposits | Write (INSERT) | Creates deposit log record |
| @PlanInstancesDepositsInsertMultiple | RecurringInvestment.PlanInstancesDepositsType | TVP | Input type for instance updates |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit Message Handler | - | EXEC | Called when deposit callback is received |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstanceUserDepositUpsert (procedure)
├── RecurringInvestment.PlanInstances (table)
├── RecurringInvestment.UserDeposits (table)
└── RecurringInvestment.PlanInstancesDepositsType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | UPDATE via TVP JOIN |
| RecurringInvestment.UserDeposits | Table | INSERT INTO |
| RecurringInvestment.PlanInstancesDepositsType | User Defined Type | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Deposit Message Handler Service | Application | Calls to process deposit callbacks |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Transaction-wrapped with nested-transaction-aware CATCH block
- TVP is READONLY (cannot be modified within the procedure)

---

## 8. Sample Queries

### 8.1 Call with a deposit success
```sql
DECLARE @TVP RecurringInvestment.PlanInstancesDepositsType
INSERT INTO @TVP (InstanceID, PlanID, NextOrderDate, DepositID, DepositCycleNumber, DepositDate,
    HighLevelDepositStatusId, DepositStatusID, InstanceStatusID)
VALUES (5001, 1001, '2026-04-15', 99001, 1, GETUTCDATE(), 1, 1, 5)

EXEC [RecurringInvestment].[PlanInstanceUserDepositUpsert]
    @PlanInstancesDepositsInsertMultiple = @TVP,
    @GCID = 12345678, @DepositID = 99001,
    @DepositAmountUsd = 100.00, @DepositAmountCurrency = 100.00,
    @DepositDate = '2026-04-13'
```

### 8.2 Check UserDeposits for a user
```sql
SELECT * FROM [RecurringInvestment].[UserDeposits] WITH (NOLOCK)
WHERE GCID = 12345678
ORDER BY DepositDate DESC
```

### 8.3 Verify instance was updated
```sql
SELECT InstanceID, DepositID, HighLevelDepositStatusId, DepositAmountUsd, UpdateDate
FROM [RecurringInvestment].[PlanInstances] WITH (NOLOCK)
WHERE InstanceID = 5001
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | PlanInstances and UserDeposits table structures, deposit flow |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Deposit message handling architecture |

---

*Generated: 2026-04-13 | Quality: 9.2/10*
*Object: RecurringInvestment.PlanInstanceUserDepositUpsert | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstanceUserDepositUpsert.sql*
