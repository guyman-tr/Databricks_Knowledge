# RecurringInvestment.PlanInsertInstanceInsert

> Atomically creates a new recurring investment plan and its first plan instance in a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | 22 input params, returns all user plans via PlansGetByGCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the atomic entry point for creating a brand-new recurring investment plan along with its very first execution instance. It ensures that both the plan record and the initial instance record are created together in a single transaction, preventing orphaned plans without instances or instances without plans.

Without this procedure, plan creation would require two separate INSERT operations that could partially fail, leaving the system in an inconsistent state. The transactional wrapper guarantees all-or-nothing: if either the plan insert or the instance insert fails, the entire operation rolls back.

The procedure is called by the application when a user sets up a new recurring investment plan. After creating the plan and first instance, it calls `PlansGetByGCID` to return the complete list of the user's plans, allowing the UI to refresh immediately. The @AmountUsd parameter was added per EDGE-6637 (Miri Rismani) to support USD-normalized amount tracking.

---

## 2. Business Logic

### 2.1 Atomic Plan + Instance Creation

**What**: Ensures a plan and its first instance are created together or not at all.

**Columns/Parameters Involved**: All plan params, `@NextOrderDate`, `SCOPE_IDENTITY()`

**Rules**:
- BEGIN TRAN wraps both INSERT statements and the EXEC call
- The plan is inserted first; SCOPE_IDENTITY() captures the new PlanID
- The first PlanInstance is inserted with only PlanID and NextOrderDate (all other instance columns start as NULL)
- On success, PlansGetByGCID returns the updated plan list
- On failure, the catch block rolls back if this is the outermost transaction

**Diagram**:
```
BEGIN TRAN
    |
    v
INSERT INTO Plans (20 columns)
    |
    v
@PlanID = SCOPE_IDENTITY()
    |
    v
INSERT INTO PlanInstances (PlanID, NextOrderDate)
    |
    v
EXEC PlansGetByGCID @GCID --> returns all user plans
    |
    v
COMMIT TRAN
```

### 2.2 Transaction Error Handling

**What**: Nested-transaction-aware error handling that preserves the transaction state.

**Columns/Parameters Involved**: `@@TRANCOUNT`

**Rules**:
- If @@TRANCOUNT = 1 (outermost transaction): ROLLBACK the entire operation
- If @@TRANCOUNT > 1 (nested inside another transaction): COMMIT (release savepoint) and let the outer transaction decide
- THROW re-raises the original error in all cases
- This pattern is consistent across all write SPs in the RecurringInvestment schema

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | bigint | NO | - | VERIFIED | Global Customer ID of the user creating the plan. |
| 2 | @CID | bigint | NO | - | VERIFIED | Customer ID of the user. |
| 3 | @InstrumentID | int | NO | - | VERIFIED | Target instrument ID for instrument-type plans. NULL-able for copy plans at the table level. |
| 4 | @Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount per cycle in the plan's currency. |
| 5 | @AmountUsd | decimal(18,2) | YES | NULL | VERIFIED | Investment amount per cycle in USD. Added per EDGE-6637 for normalized reporting. |
| 6 | @CurrencyID | int | NO | - | VERIFIED | Currency of the investment amount. |
| 7 | @FrequencyID | int | NO | - | VERIFIED | Execution frequency: 3=Monthly. See [Plan Frequencies](../../_glossary.md#plan-frequencies). |
| 8 | @RepeatsOn | int | NO | - | VERIFIED | Day of month for execution (1-28). |
| 9 | @HasBackupPayment | bit | YES | 0 | VERIFIED | Whether a fallback payment method is configured. Defaults to 0 (no backup). |
| 10 | @DepositStartDate | datetime | NO | - | VERIFIED | Scheduled date for the first deposit. |
| 11 | @PlanCreationDate | datetime | NO | - | VERIFIED | Timestamp of plan creation, mapped to Plans.CreationDate. |
| 12 | @EndDate | datetime | NO | - | VERIFIED | End date for the plan. Typically NULL at creation (passed explicitly). |
| 13 | @PlanStatusID | int | NO | - | VERIFIED | Initial plan status. Typically 1=Active at creation. See [Plan Status](../../_glossary.md#plan-status). |
| 14 | @StatusReasonID | int | NO | - | VERIFIED | Reason for initial status, typically 100=CreatePlanSuccess. See [Plan Event Code](../../_glossary.md#plan-event-code). |
| 15 | @FundingID | int | NO | - | VERIFIED | Payment method ID for deposits. |
| 16 | @NextOrderDate | datetime | NO | - | VERIFIED | Scheduled date for the first instance's order. Used only for the PlanInstances INSERT. |
| 17 | @PlanType | int | NO | - | VERIFIED | Plan type: 1=Instrument, 2=Copy. See [Plan Type](../../_glossary.md#plan-type). |
| 18 | @CopyType | int | NO | - | VERIFIED | Copy trading type: 0=None, 1=PI, 4=SmartPortfolio. See [Copy Type](../../_glossary.md#copy-type). |
| 19 | @CopyParentCID | bigint | NO | - | VERIFIED | CID of the trader to copy (for copy plans). |
| 20 | @CopyParentGCID | bigint | NO | - | VERIFIED | GCID of the trader to copy (for copy plans). |
| 21 | @MopType | int | YES | 1 | VERIFIED | Method of payment type. Defaults to 1. See [MOP Type](../../_glossary.md#mop-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.Plans | Write (INSERT) | Creates a new plan row |
| - | RecurringInvestment.PlanInstances | Write (INSERT) | Creates the first instance for the new plan |
| - | RecurringInvestment.PlansGetByGCID | EXEC | Returns all user plans after creation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer | - | EXEC | Called from plan creation API endpoint |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInsertInstanceInsert (procedure)
├── RecurringInvestment.Plans (table)
├── RecurringInvestment.PlanInstances (table)
└── RecurringInvestment.PlansGetByGCID (procedure)
    ├── RecurringInvestment.Plans (table)
    └── RecurringInvestment.PlanInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | INSERT INTO |
| RecurringInvestment.PlanInstances | Table | INSERT INTO |
| RecurringInvestment.PlansGetByGCID | Stored Procedure | EXEC to return updated plan list |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application layer | Service | Calls to create plan + first instance atomically |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses SCOPE_IDENTITY() to capture the auto-generated PlanID
- Transaction-wrapped with nested-transaction-aware CATCH block
- Plans table has a unique constraint on GCID+InstrumentID+PlanStatusID+CopyParentGCID WHERE PlanStatusID=1

---

## 8. Sample Queries

### 8.1 Create an instrument-type plan
```sql
EXEC [RecurringInvestment].[PlanInsertInstanceInsert]
    @GCID = 12345678, @CID = 87654321,
    @InstrumentID = 1001, @Amount = 100.00, @AmountUsd = 100.00,
    @CurrencyID = 1, @FrequencyID = 3, @RepeatsOn = 15,
    @HasBackupPayment = 0, @DepositStartDate = '2026-05-15',
    @PlanCreationDate = '2026-04-13', @EndDate = NULL,
    @PlanStatusID = 1, @StatusReasonID = 100, @FundingID = 5001,
    @NextOrderDate = '2026-05-15', @PlanType = 1, @CopyType = 0,
    @CopyParentCID = NULL, @CopyParentGCID = NULL, @MopType = 1
```

### 8.2 Create a copy-type plan (Popular Investor)
```sql
EXEC [RecurringInvestment].[PlanInsertInstanceInsert]
    @GCID = 12345678, @CID = 87654321,
    @InstrumentID = NULL, @Amount = 200.00, @AmountUsd = 200.00,
    @CurrencyID = 1, @FrequencyID = 3, @RepeatsOn = 1,
    @HasBackupPayment = 0, @DepositStartDate = '2026-05-01',
    @PlanCreationDate = '2026-04-13', @EndDate = NULL,
    @PlanStatusID = 1, @StatusReasonID = 100, @FundingID = 5001,
    @NextOrderDate = '2026-05-01', @PlanType = 2, @CopyType = 1,
    @CopyParentCID = 99999, @CopyParentGCID = 88888, @MopType = 1
```

### 8.3 Verify the new plan was created
```sql
SELECT p.ID, p.GCID, p.PlanStatusID, p.PlanType, pi.InstanceID, pi.NextOrderDate
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
LEFT JOIN [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK) ON p.ID = pi.PlanID
WHERE p.GCID = 12345678
ORDER BY p.ID DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Plans and PlanInstances table structures |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Plan creation flow architecture |
| [EDGE-6637](https://etoro-jira.atlassian.net/browse/EDGE-6637) | Jira | Added AmountUsd parameter (Miri Rismani) |

---

*Generated: 2026-04-13 | Quality: 9.3/10*
*Object: RecurringInvestment.PlanInsertInstanceInsert | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInsertInstanceInsert.sql*
