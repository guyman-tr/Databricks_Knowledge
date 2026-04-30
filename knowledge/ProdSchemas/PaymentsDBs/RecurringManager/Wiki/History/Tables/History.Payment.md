# History.Payment

> Temporal history table storing previous versions of recurring payment records, capturing every state change in a payment's lifecycle from creation through status transitions, amount adjustments, and funding source changes.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PaymentId (mirrors PK of Recurring.Payment) |
| **Partition** | No |
| **Indexes** | 1 clustered (SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.Payment is the system-versioned temporal history table for `Recurring.Payment`. Each row represents a previous state of a recurring payment record - the parent entity in the recurring payments domain that represents a customer's instruction to deposit or invest funds on a recurring schedule. This is the highest-volume history table in the schema (327K+ rows), reflecting the frequent status transitions and configuration changes that payments undergo throughout their lifecycle.

This table exists to provide a complete audit trail of every change to a recurring payment. Since payments transition through multiple statuses (Active, Paused, Stopped, Cancelled, Invalid), change funding sources, adjust amounts, and accumulate version stamps, the history table captures each intermediate state. This is critical for compliance, dispute resolution, and understanding customer payment behavior over time.

Data enters this table automatically via SQL Server's temporal mechanism whenever `Recurring.Payment` rows are modified or deleted. The two key procedures that drive changes are `Recurring.CreatePayment` (initial INSERT with StatusId=1/Active) and `Recurring.UpdatePayment` (status changes, amount adjustments, funding source changes). Each UPDATE to the base table moves the old version here. The history spans from June 2021 to present, covering the full operational lifetime of the RecurringManager system.

---

## 2. Business Logic

### 2.1 Payment Lifecycle (Status Transitions)

**What**: Recurring payments progress through a defined set of states that control whether new executions are scheduled.

**Columns/Parameters Involved**: `StatusId`, `StatusReasonId`, `ModificationDate`

**Rules**:
- StatusId maps to Dictionary.PlanStatus: 1=Active, 2=Cancelled, 3=Stopped, 4=Invalid, 5=Paused. See [Plan Status](../../_glossary.md#plan-status) for full definitions.
- Only Active (1) and Paused (5) payments are considered "live" - CreatePayment checks `StatusId IN (1, 5)` to detect duplicates
- StatusReasonId captures WHY a status changed. Maps to Dictionary.StatusReason: 1=RemovedMOP, 2=CancelledByUser, 3=CancelledByBO, 4=CanceledInvestment, 5=HardDecline. See [Status Reason](../../_glossary.md#status-reason)
- HardDecline (StatusReasonId=5) is the most common non-null reason (97% of status reasons), indicating payment provider permanently declined the charge
- ModificationDate is set to GETUTCDATE() on every UpdatePayment call

**Diagram**:
```
[Active (1)] --user cancels--> [Cancelled (2)] (StatusReasonId=2)
     |
     +--hard decline--> [Stopped (3)] (StatusReasonId=5)
     |
     +--removed MOP--> [Invalid (4)] (StatusReasonId=1)
     |
     +--user pauses--> [Paused (5)]
                            |
                            +--user resumes--> [Active (1)]
```

### 2.2 Duplicate Payment Prevention

**What**: The system prevents a customer from having more than one active/paused payment per recurring program type.

**Columns/Parameters Involved**: `Cid`, `RecurringProgramTypeId`, `StatusId`

**Rules**:
- `Recurring.CreatePayment` checks if the customer (Cid) already has a payment with the same RecurringProgramTypeId and StatusId IN (1, 5)
- If a duplicate exists, the existing payment is returned with `IsDuplicated=true` flag instead of creating a new one
- This means a customer can have at most one Active or Paused RecurringDeposit and one Active or Paused RecurringInvestment simultaneously
- Cancelled/Stopped/Invalid payments do not block new payment creation

### 2.3 Version Stamping and Generation

**What**: Optimistic concurrency control and payment regeneration tracking.

**Columns/Parameters Involved**: `VersionStamp`, `Generation`

**Rules**:
- VersionStamp is used for optimistic concurrency - set during non-status updates to track version changes
- UpdatePayment sets VersionStamp only when @Status IS NULL (configuration-only changes), preserving existing stamp during status transitions
- Generation tracks payment regeneration cycles. Default is 0 (original payment). Value 1 (4% of history rows) indicates a regenerated/recreated payment
- Generation is reset to ISNULL(@Generation, 0) when @Status IS NULL, preserving existing generation during status changes

---

## 3. Data Overview

| PaymentId | Cid | Amount | CurrencyId | StatusId | StatusReasonId | RecurringProgramTypeId | Meaning |
|---|---|---|---|---|---|---|---|
| 1 | 23469799 | 50 | 1 | 1 | NULL | 1 | Early test payment (June 2021) - $50 USD recurring deposit, initially Active with no status reason. This version was superseded within a day, suggesting rapid iteration during initial system setup. |
| 10 | 23525628 | 1500 | 2 | 1 | NULL | 1 | Larger recurring deposit in currency 2 (likely EUR) - shows the variety of amounts and currencies supported. Active status version captured before a subsequent change. |
| 11 | 23525628 | 5200 | 3 | 1 | NULL | 1 | High-value recurring deposit in currency 3 (likely GBP) - demonstrates the system handles significant recurring payment amounts. Version lasted only ~1 minute before being superseded. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentId | int | NO | - | CODE-BACKED | Mirrors the IDENTITY PK of Recurring.Payment. Identifies which recurring payment this historical version belongs to. Not unique in the history table - the same PaymentId appears multiple times representing successive versions. Created by `Recurring.CreatePayment` with OUTPUT INSERTED.PaymentId. |
| 2 | Cid | int | NO | - | CODE-BACKED | Customer identifier (external reference to the customer/user system). Passed as @CID parameter to `Recurring.CreatePayment`. Set once at creation and never changed - all versions of the same PaymentId share the same Cid. Used with RecurringProgramTypeId for duplicate detection: `WHERE Cid = @CID AND RecurringProgramTypeId = @RecurringProgramTypeId AND StatusId IN (1, 5)`. |
| 3 | FundingId | int | NO | - | CODE-BACKED | Identifies the customer's funding source (payment method) - e.g., credit card, bank account. External reference to the billing/payment system. Passed as @FundingId to CreatePayment; updatable via UpdatePayment (@FundingID). When FundingId changes, AuthenticationId is also reset (re-authentication required for new payment method). |
| 4 | Amount | money | NO | - | CODE-BACKED | The recurring payment amount in the specified currency. Passed as @Amount to CreatePayment; updatable via UpdatePayment. Observed range: $50 to $5,200+ across different currencies. Represents the amount to be charged on each execution cycle. |
| 5 | CurrencyId | int | NO | - | CODE-BACKED | Currency of the recurring payment amount. External reference to a currency lookup (not within RecurringManager). 26 distinct values observed; top currencies: 1 (53%, likely USD), 2 (26%, likely EUR), 3 (12%, likely GBP), 5 (5%). Updatable via UpdatePayment. |
| 6 | StatusId | int | NO | - | VERIFIED | Payment lifecycle state. Maps to Dictionary.PlanStatus: 1=Active, 2=Cancelled, 3=Stopped, 4=Invalid, 5=Paused. See [Plan Status](../../_glossary.md#plan-status). Set to 1 (Active) by `Recurring.CreatePayment`. Updated by `Recurring.UpdatePayment` via @Status parameter. CreatePayment treats StatusId IN (1, 5) as "live" for duplicate detection. (Dictionary.PlanStatus) |
| 7 | CreateDate | datetime | NO | - | CODE-BACKED | Timestamp when the recurring payment was originally created. Set to GETDATE() by CreatePayment (note: uses local time, while ModificationDate uses UTC). DEFAULT constraint: getutcdate(). Immutable after creation - carried forward through all historical versions. |
| 8 | ModificationDate | datetime | YES | - | CODE-BACKED | Timestamp of the most recent modification to the base table row. Set to GETUTCDATE() on every UpdatePayment call. NULL when the payment has never been updated after initial creation (visible in early history rows). Set to GETDATE() on CreatePayment initial insert. |
| 9 | SysStartTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Records when this version of the payment became the active version in the base table. DEFAULT: sysutcdatetime(). Part of the clustered index (SysEndTime, SysStartTime) for efficient temporal queries. |
| 10 | SysEndTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Records when this version was superseded by a newer version. DEFAULT: '9999-12-31 23:59:59.9999999' (for current rows in the base table). Part of the clustered index. Together with SysStartTime defines the validity period. |
| 11 | StatusReasonId | int | YES | - | VERIFIED | Reason for the most recent status change. Maps to Dictionary.StatusReason: 1=RemovedMOP, 2=CancelledByUser, 3=CancelledByBO, 4=CanceledInvestment, 5=HardDecline. See [Status Reason](../../_glossary.md#status-reason). NULL for 97% of history rows (Active payments with no status change reason). Updated by `Recurring.UpdatePayment` via @StatusReason. (Dictionary.StatusReason) |
| 12 | RecurringProgramTypeId | int | NO | - | VERIFIED | Classifies the recurring program. Maps to Dictionary.RecurringProgramType: 1=RecurringDeposit, 2=RecurringInvestment. See [Recurring Program Type](../../_glossary.md#recurring-program-type). DEFAULT: 1 (RecurringDeposit). Set at creation and never changed. Used with Cid for duplicate detection. Split: 53% RecurringDeposit, 47% RecurringInvestment. (Dictionary.RecurringProgramType) |
| 13 | VersionStamp | nvarchar(100) | YES | - | CODE-BACKED | Optimistic concurrency token. Set by UpdatePayment only during non-status changes (when @Status IS NULL). During status transitions, the existing VersionStamp is preserved unless explicitly overridden. NULL for payments that have never had a version-stamped update. |
| 14 | AuthenticationId | int | YES | - | CODE-BACKED | Links to an authentication/verification record for the payment method. External reference. Passed as @AuthenticationId to CreatePayment (optional, defaults to NULL). On UpdatePayment: reset to @AuthenticationId when FundingID changes (re-authentication required for new payment method); otherwise preserved or optionally updated. |
| 15 | Generation | int | NO | - | CODE-BACKED | Payment regeneration counter. DEFAULT: 0 (original payment). Incremented when a payment is regenerated/recreated. 96% of history rows have Generation=0 (original), 4% have Generation=1 (regenerated once). On UpdatePayment: reset to ISNULL(@Generation, 0) for non-status changes; preserved during status transitions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | Recurring.Payment | Temporal History | This is the system-versioned history table for Recurring.Payment |
| StatusId | Dictionary.PlanStatus | Implicit Lookup | Payment lifecycle state: 1=Active, 2=Cancelled, 3=Stopped, 4=Invalid, 5=Paused |
| StatusReasonId | Dictionary.StatusReason | Implicit Lookup | Reason for status change: 1=RemovedMOP, 2=CancelledByUser, 3=CancelledByBO, 4=CanceledInvestment, 5=HardDecline |
| RecurringProgramTypeId | Dictionary.RecurringProgramType | Implicit Lookup | Program type: 1=RecurringDeposit, 2=RecurringInvestment |
| Cid | External (Customer system) | Implicit FK | Customer identifier from the platform's user management system |
| FundingId | External (Billing system) | Implicit FK | Payment method identifier from the billing/payment provider system |
| CurrencyId | External (Currency lookup) | Implicit FK | Currency code from the platform's currency reference data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.Plan | PaymentId | Implicit FK | Payment plan schedule versions reference their parent payment |
| History.PaymentExecution | PaymentId | Implicit FK | Individual execution attempt versions reference their parent payment |
| History.PaymentConsent | PaymentId | Implicit FK | Consent document versions reference their parent payment |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies. It is a history table managed by SQL Server's temporal mechanism.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring.Payment | Table | This is the temporal history table for that base table (SYSTEM_VERSIONING = ON) |
| Recurring.CreatePayment | Stored Procedure | WRITER - creates new payments in the base table (StatusId=1), triggering temporal history on subsequent updates |
| Recurring.UpdatePayment | Stored Procedure | MODIFIER - updates payment status, amount, funding source, version stamp in the base table, generating history rows |
| Recurring.GetPayment | Stored Procedure | READER - reads payment data from the base table |
| Recurring.GetPaymentsByCid | Stored Procedure | READER - retrieves all payments for a customer |
| Recurring.GetPaymentExecutionsResultsForPayment | Stored Procedure | READER - retrieves execution results for a payment |
| Recurring.Alert_NotScheduled_Payments | Stored Procedure | READER - monitoring alert for payments without scheduled executions |
| Recurring.DD_Alert_NotScheduled_Payments | Stored Procedure | READER - data-driven monitoring alert for unscheduled payments |
| Recurring.Alert_CIDWithMoreThanAllowed | Stored Procedure | READER - alert for customers exceeding allowed payment count |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_Payment | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

PAGE compression is enabled. The clustered index on (SysEndTime, SysStartTime) optimizes temporal `FOR SYSTEM_TIME` queries.

### 7.2 Constraints

None. History tables managed by SQL Server temporal do not have constraints. The base table (Recurring.Payment) holds:
- PK_Recurring_Payment (PK on PaymentId)
- DF_Recurring_Payment_CreateDate (DEFAULT getutcdate() for CreateDate)
- DF_Payment_SysStart / DF_Payment_SysEnd (temporal defaults)
- DEFAULT (1) for RecurringProgramTypeId
- DF_Recurring_Payment_Generation (DEFAULT 0 for Generation)

---

## 8. Sample Queries

### 8.1 View full version history of a specific payment
```sql
SELECT PaymentId, StatusId, StatusReasonId, Amount, CurrencyId,
       FundingId, Generation, VersionStamp,
       SysStartTime AS VersionStart, SysEndTime AS VersionEnd
FROM History.Payment WITH (NOLOCK)
WHERE PaymentId = 100
ORDER BY SysStartTime ASC
```

### 8.2 Reconstruct a payment's state at a specific point in time
```sql
SELECT p.PaymentId, p.Cid, p.Amount, p.CurrencyId,
       ps.Name AS StatusName, sr.Name AS StatusReasonName,
       rpt.Name AS ProgramType
FROM Recurring.Payment
FOR SYSTEM_TIME AS OF '2024-01-15 12:00:00' p
LEFT JOIN Dictionary.PlanStatus ps WITH (NOLOCK) ON ps.PlanStatusId = p.StatusId
LEFT JOIN Dictionary.StatusReason sr WITH (NOLOCK) ON sr.StatusReasonId = p.StatusReasonId
LEFT JOIN Dictionary.RecurringProgramType rpt WITH (NOLOCK) ON rpt.RecurringProgramTypeId = p.RecurringProgramTypeId
WHERE p.PaymentId = 100
```

### 8.3 Find payments that were stopped due to hard declines
```sql
SELECT h.PaymentId, h.Cid, h.Amount, h.CurrencyId,
       h.StatusId, sr.Name AS StatusReasonName,
       h.SysStartTime AS StoppedAt, h.SysEndTime AS SupersededAt
FROM History.Payment h WITH (NOLOCK)
JOIN Dictionary.StatusReason sr WITH (NOLOCK) ON sr.StatusReasonId = h.StatusReasonId
WHERE h.StatusReasonId = 5  -- HardDecline
ORDER BY h.SysStartTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Confluence searches for "RecurringManager Payment" in the TRAD space returned no results.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Payment | Type: Table | Source: RecurringManager/History/Tables/History.Payment.sql*
