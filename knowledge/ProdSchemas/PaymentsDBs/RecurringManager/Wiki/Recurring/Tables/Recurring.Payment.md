# Recurring.Payment

> Core transactional table storing recurring payment subscriptions - each row represents a customer's recurring deposit or recurring investment plan with its current status, amount, and payment method.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Table |
| **Key Identifier** | PaymentId (INT, IDENTITY) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + 4 nonclustered |

---

## 1. Business Meaning

Recurring.Payment is the central table in the RecurringManager database, representing a customer's subscription to a recurring payment program. Each row is a single plan where a customer has agreed to make periodic deposits or investments of a fixed amount using a specific payment method (funding source). The table tracks the plan's lifecycle from creation through cancellation or hard-decline blocking.

This table is essential to the recurring payments business. Without it, the system would have no record of which customers have active recurring plans, what amounts they deposit/invest, or which payment method they use. Every downstream process - scheduling, execution, deposit results, notifications - depends on a Payment row existing first.

Data flows into this table through Recurring.CreatePayment, which inserts a new plan with StatusId=1 (Active). The plan can be modified by Recurring.UpdatePayment (status changes, amount/funding updates) and reverted by Recurring.RevertPayment (optimistic concurrency rollback). The Scheduler schema reads payments to create execution plans (Scheduler.Plan), and the PaymentExecution table tracks individual execution cycles against each payment. System-versioned with History.Payment for full audit trail of all changes.

---

## 2. Business Logic

### 2.1 Payment Status Lifecycle

**What**: Each payment plan moves through a defined set of statuses representing its lifecycle from creation to termination.

**Columns/Parameters Involved**: `StatusId`, `StatusReasonId`, `ModificationDate`

**Rules**:
- New payments are always created with StatusId=1 (Active)
- StatusId=1 (Active) and StatusId=5 are both treated as "live" for duplicate detection - CreatePayment prevents a customer from having two active plans of the same program type
- StatusId=2 (Cancelled) is the most common terminal state (57% of all payments), triggered by user cancellation, investment cancellation, or removed payment method
- StatusId=3 (Blocked) is set when the payment method suffers a hard decline from the payment processor - the plan cannot retry
- StatusId=4 (Invalid) is a rare terminal state (26 rows total), excluded from scheduling alerts
- When StatusId changes, StatusReasonId is typically set to explain why (see Dictionary.StatusReason values below)

**Diagram**:
```
[1 Active] --user cancels--> [2 Cancelled] (StatusReasonId=2: CancelledByUser)
[1 Active] --hard decline--> [3 Blocked]   (StatusReasonId=5: HardDecline)
[1 Active] --invalid-------> [4 Invalid]
[1 Active] --investment cancel-> [2 Cancelled] (StatusReasonId=4: CanceledInvestment)
[1 Active] --MOP removed---> [2 Cancelled] (StatusReasonId=1: RemovedMOP)
[5 Pending?] --activate-----> [1 Active]   (included in duplicate check with 1)
```

### 2.2 Optimistic Concurrency Control (VersionStamp)

**What**: The VersionStamp column implements optimistic concurrency control for payment modifications, preventing concurrent updates from overwriting each other.

**Columns/Parameters Involved**: `VersionStamp`, `Generation`, `FundingId`, `Amount`, `AuthenticationId`

**Rules**:
- When a payment is being modified (amount change, funding update), VersionStamp is set to a GUID identifying the pending change
- RevertPayment uses `WHERE VersionStamp LIKE @VersionStamp` as a guard - only reverts if the expected version is still current
- On revert, VersionStamp is cleared to NULL, and FundingId/Amount are restored
- Generation tracks modification rounds: reset to 0 on non-status updates, preserved on status changes
- Generation=0 (98% of rows) means original/unmodified; Generation=1 (2%) indicates the plan has been updated at least once

### 2.3 Recurring Program Types

**What**: Two distinct recurring program types determine the business flow and downstream processing.

**Columns/Parameters Involved**: `RecurringProgramTypeId`

**Rules**:
- RecurringDeposit (1): Automatic periodic deposit into the customer's trading account (84% of plans)
- RecurringInvestment (2): Automatic periodic investment into a specific strategy or portfolio (16% of plans)
- A customer can only have ONE active plan per program type (enforced by CreatePayment duplicate check)

---

## 3. Data Overview

| PaymentId | Cid | Amount | CurrencyId | StatusId | RecurringProgramTypeId | StatusReasonId | Meaning |
|---|---|---|---|---|---|---|---|
| 200820 | 9252179 | 100 | 1 | 1 | 2 | NULL | Active RecurringInvestment plan depositing 100 in currency 1 (likely USD). No status reason because the plan is still active. |
| 200817 | 44915307 | 50 | 2 | 1 | 2 | NULL | Active RecurringInvestment with VersionStamp set and Generation=1, meaning the customer recently modified this plan's funding or amount. |
| 200814 | 41066147 | 200 | 5 | 1 | 1 | NULL | Active RecurringDeposit plan for 200 in currency 5 (likely AUD). Standard first-generation plan with no modifications. |
| 108530 | (redacted) | 100 | 5 | 2 | 1 | 2 | Cancelled RecurringDeposit - the user voluntarily cancelled (CancelledByUser). Represents the most common termination path. |
| 200403 | (redacted) | - | - | 3 | 1 | 5 | Blocked RecurringDeposit due to HardDecline - the payment processor permanently rejected the card, so the plan cannot retry. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentId | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key uniquely identifying each recurring payment plan. Referenced by PaymentExecution.PaymentId, PaymentConsent.PaymentId, and Scheduler.Plan.PaymentId. Current max ~200,820. |
| 2 | Cid | int | NO | - | CODE-BACKED | Customer ID identifying the account holder who owns this recurring plan. Indexed for lookups by customer (IX_RecurringPayment_CID). Used by GetPaymentsByCid and Alert_CIDWithMoreThanAllowed to find all plans for a customer. |
| 3 | FundingId | int | NO | - | CODE-BACKED | External reference to the customer's payment method (credit card, bank account, etc.) in the billing/payments system. Can be updated via UpdatePayment when a customer changes their funding source, and reverted via RevertPayment. |
| 4 | Amount | money | NO | - | CODE-BACKED | The recurring payment amount in the currency specified by CurrencyId. Represents the fixed amount charged each execution cycle. Can be modified via UpdatePayment and reverted via RevertPayment. Observed range: 50-1,300 in sample data. |
| 5 | CurrencyId | int | NO | - | CODE-BACKED | Currency of the recurring payment amount. References an external currency dictionary (likely etoro Dictionary.Currency). Top values: 1 (49% - likely USD), 2 (25% - likely EUR), 3 (16% - likely GBP), 5 (6% - likely AUD). 26 distinct currencies observed. |
| 6 | StatusId | int | NO | - | VERIFIED | Payment plan lifecycle status. No explicit Dictionary table exists in this database - values inferred from code and data: 1=Active (8.2%, created by CreatePayment, included in duplicate check), 2=Cancelled (57.1%, voluntary termination), 3=Blocked (34.1%, hard decline from processor), 4=Invalid (0.01%, rare terminal state), 5=Pending/Paused (0.6%, included with Active in duplicate prevention). Indexed for filtering (IX_RecurringPayment_StatusId). |
| 7 | CreateDate | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when the payment plan was first created by CreatePayment. Auto-set via default constraint. Indexed for time-range queries (IX_RecurringPayment_CreateDate). Used by alert SPs to find recently created but unscheduled payments. |
| 8 | ModificationDate | datetime | YES | - | CODE-BACKED | UTC timestamp of the last modification to this payment. Set to GETUTCDATE() by UpdatePayment on every update. NULL if never modified after creation. Used by alert SPs with time-window filtering. |
| 9 | StatusReasonId | int | YES | - | VERIFIED | Reason why the payment reached its current status. FK to Dictionary.StatusReason: 1=RemovedMOP (1.5% - payment method removed), 2=CancelledByUser (34% - voluntary cancellation), 3=CancelledByBO (0.001% - back-office cancellation), 4=CanceledInvestment (6% - investment program cancelled), 5=HardDecline (6% - processor permanently declined). NULL for active payments (53%). |
| 10 | RecurringProgramTypeId | int | NO | 1 | VERIFIED | Type of recurring program. FK to Dictionary.RecurringProgramType: 1=RecurringDeposit (84% - periodic account deposits), 2=RecurringInvestment (16% - periodic portfolio investments). Defaults to 1. A customer can have only one active plan per type (enforced by CreatePayment). |
| 11 | VersionStamp | nvarchar(100) | YES | - | CODE-BACKED | Optimistic concurrency token (GUID format). Set when a modification is in progress. RevertPayment checks `WHERE VersionStamp LIKE @VersionStamp` before reverting - if another process changed it, the revert is a no-op. Cleared to NULL on successful revert. NULL for most rows (no pending modification). |
| 12 | AuthenticationId | int | YES | - | CODE-BACKED | Reference to an external authentication/authorization record for the payment method. Populated when the funding method requires SCA (Strong Customer Authentication) or similar verification. NULL when no authentication is needed (e.g., previously authorized methods). |
| 13 | Generation | int | NO | 0 | CODE-BACKED | Modification counter tracking how many update rounds the plan has undergone. 0=original/unmodified (98%), 1=modified once (2%). Reset to 0 by UpdatePayment on non-status updates; preserved on status changes. Used with VersionStamp for concurrency control. |
| 14 | SysStartTime | datetime2(7) | NO | sysutcdatetime() | CODE-BACKED | System-versioning row start time (HIDDEN). Marks when this version of the row became current. Auto-managed by SQL Server temporal tables. |
| 15 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System-versioning row end time (HIDDEN). Set to max datetime for current rows; updated to actual end time when the row is modified. History rows are stored in History.Payment. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| StatusReasonId | Dictionary.StatusReason | Implicit FK (Lookup) | Explains why the payment reached its current status (cancellation reason, decline type) |
| RecurringProgramTypeId | Dictionary.RecurringProgramType | Implicit FK (Lookup) | Determines whether this is a recurring deposit or recurring investment plan |
| CurrencyId | External Dictionary.Currency | Implicit FK (Cross-DB) | Currency denomination of the payment amount; references an external currency system |
| - | History.Payment | System Versioning | All row changes are automatically tracked in the history table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Recurring.PaymentExecution | PaymentId | Implicit FK | Each execution cycle for this payment plan. Multiple executions per payment over time. |
| Recurring.PaymentConsent | PaymentId | Implicit FK | Consent/authorization documents linked to this payment plan. |
| Scheduler.Plan | PaymentId | Implicit FK (Cross-Schema) | The scheduling plan that determines when this payment's executions are triggered. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentExecution | Table | PaymentId FK - each execution cycle belongs to a payment |
| Recurring.PaymentConsent | Table | PaymentId FK - consent documents linked to a payment |
| Scheduler.Plan | Table | PaymentId FK - scheduling plan for payment execution timing |
| Recurring.CreatePayment | Stored Procedure | WRITER - creates new payment plans |
| Recurring.UpdatePayment | Stored Procedure | MODIFIER - updates status, amount, funding, version |
| Recurring.RevertPayment | Stored Procedure | MODIFIER - reverts pending changes using VersionStamp guard |
| Recurring.GetPayment | Stored Procedure | READER - retrieves single payment by ID |
| Recurring.GetPaymentsByCid | Stored Procedure | READER - retrieves all payments for a customer |
| Recurring.Alert_CIDWithMoreThanAllowed | Stored Procedure | READER - counts active plans per customer |
| Recurring.Alert_NotScheduled_Payments | Stored Procedure | READER - finds payments without a Scheduler.Plan |
| Recurring.DD_Alert_NotScheduled_Payments | Stored Procedure | READER - DataDog version of unscheduled payment alert |
| Recurring.GetPaymentExecutionsDepositsResultByCid | Stored Procedure | READER - joins through PaymentExecution to get deposit results |
| Recurring.GetPaymentExecutionsResultsForPayment | Stored Procedure | READER - joins through PaymentExecution and Request for results |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Recurring_Payment | CLUSTERED | PaymentId ASC | - | - | Active |
| IX_Recurring_Payment_Cid_Inc | NONCLUSTERED (PAGE compressed) | Cid ASC | PaymentId, FundingId, Amount, CurrencyId, StatusId, CreateDate, ModificationDate, StatusReasonId, RecurringProgramTypeId | - | Active |
| IX_RecurringPayment_CID | NONCLUSTERED | Cid ASC | - | - | Active |
| IX_RecurringPayment_CreateDate | NONCLUSTERED | CreateDate ASC | - | - | Active |
| IX_RecurringPayment_StatusId | NONCLUSTERED | StatusId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Recurring_Payment | PRIMARY KEY | Clustered on PaymentId |
| DF_Recurring_Payment_CreateDate | DEFAULT | getutcdate() for CreateDate - auto-timestamps creation |
| DF_Payment_SysStart | DEFAULT | sysutcdatetime() for SysStartTime - temporal versioning |
| DF_Payment_SysEnd | DEFAULT | CONVERT(datetime2, '9999-12-31 23:59:59.9999999') for SysEndTime - temporal versioning |
| (unnamed) | DEFAULT | 1 for RecurringProgramTypeId - defaults to RecurringDeposit |
| DF_Recurring_Payment_Generation | DEFAULT | 0 for Generation - new payments start as unmodified |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.Payment - full audit trail of all row changes |

---

## 8. Sample Queries

### 8.1 Get all active recurring payments for a customer
```sql
SELECT p.PaymentId, p.Amount, p.CurrencyId, rpt.Name AS ProgramType,
       p.CreateDate, p.FundingId, p.Generation
FROM Recurring.Payment p WITH (NOLOCK)
INNER JOIN Dictionary.RecurringProgramType rpt WITH (NOLOCK)
    ON p.RecurringProgramTypeId = rpt.RecurringProgramTypeID
WHERE p.Cid = @Cid AND p.StatusId = 1
```

### 8.2 Analyze payment cancellation reasons
```sql
SELECT sr.Name AS StatusReason,
       rpt.Name AS ProgramType,
       COUNT(*) AS PaymentCount
FROM Recurring.Payment p WITH (NOLOCK)
INNER JOIN Dictionary.StatusReason sr WITH (NOLOCK)
    ON p.StatusReasonId = sr.StatusReasonID
INNER JOIN Dictionary.RecurringProgramType rpt WITH (NOLOCK)
    ON p.RecurringProgramTypeId = rpt.RecurringProgramTypeID
WHERE p.StatusId IN (2, 3)
GROUP BY sr.Name, rpt.Name
ORDER BY PaymentCount DESC
```

### 8.3 Find payments with pending modifications (VersionStamp set)
```sql
SELECT p.PaymentId, p.Cid, p.Amount, p.CurrencyId,
       p.VersionStamp, p.Generation, p.ModificationDate
FROM Recurring.Payment p WITH (NOLOCK)
WHERE p.VersionStamp IS NOT NULL AND p.StatusId = 1
ORDER BY p.ModificationDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.Payment | Type: Table | Source: RecurringManager/Recurring/Tables/Recurring.Payment.sql*
