# Dictionary.TransactionStatusReasons

> Lookup table providing granular sub-states within the transaction lifecycle, mapping each step-level reason to its parent transaction status.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.TransactionStatusReasons provides the detailed step-level tracking within the transaction lifecycle. While Dictionary.TransactionStatuses captures the top-level outcome (InProcess, Success, Decline, Technical, Canceled), this table records the specific step a transaction has reached in the hold-debit-credit pipeline. Each reason maps to exactly one parent status via TransactionStatusID, creating a two-tier status hierarchy.

This table is essential for operational monitoring and debugging. When a transaction is "InProcess," the team needs to know whether it is just Created, has funds on Hold, is mid-Debit, or stuck at CreditDecline. Without these granular reasons, the only visibility is the top-level status which is insufficient for diagnosing pipeline issues. The MoneyBus.TransactionStatusReasonsGet procedure exposes the full reason set to application services for status mapping.

Data flow: This is a static reference table maintained via schema migrations. It is read by TransactionStatusReasonsGet (which returns all rows for application caching). It is implicitly referenced by MoneyBus.Transactions (StatusReasonID column) and by the UDT MoneyBus.TransactionsTable_New (StatusReasonID column). Transaction procedures (TransactionAdd, TransactionUpdate, TransactionsAndGroupAdd) set the StatusReasonID as transactions progress through the pipeline.

---

## 2. Business Logic

### 2.1 Transaction Processing Pipeline

**What**: The status reasons map the step-by-step progression of a transaction through the hold-debit-credit pipeline, where each step has an "Initiated" and "Completed/Declined" sub-state.

**Columns/Parameters Involved**: `ID`, `Name`, `TransactionStatusID`

**Rules**:
- The happy path follows: Created(1) -> HoldInitiated(12) -> Held(3) -> DebitInitiated(11) -> Debited(5) -> CreditInitiated(13) -> Credited(4) -> Success(2)
- Each pipeline step has three possible outcomes: Initiated (sent to provider), Completed (provider confirmed), or Declined (provider rejected)
- CreditDecline(7) and DebitDecline(8) map to InProcess (not Decline) because the transaction may still be retried or reversed
- HoldDecline(6) and ValidateDecline(9) map to Decline because recovery is not possible at those stages
- HoldCanceled(14) and ReconciliationAborted(15) are the two cancellation sub-reasons
- Technical(10) maps directly to the Technical parent status for system-level failures

**Diagram**:
```
[1] Created (InProcess)
  |
  v
[12] HoldInitiated (InProcess) --fail--> [6] HoldDecline (Decline) [TERMINAL]
  |
  v
[3] Held (InProcess) ---------------cancel--> [14] HoldCanceled (Canceled) [TERMINAL]
  |
  v
[11] DebitInitiated (InProcess) --fail--> [8] DebitDecline (InProcess - retryable)
  |
  v
[5] Debited (InProcess)
  |
  v
[13] CreditInitiated (InProcess) --fail--> [7] CreditDecline (InProcess - retryable)
  |
  v
[4] Credited (InProcess)
  |
  v
[2] Success (Success) [TERMINAL]

Side paths:
  [9] ValidateDecline (Decline) [TERMINAL] -- pre-execution validation failed
  [10] Technical (Technical) [TERMINAL] -- system error at any step
  [15] ReconciliationAborted (Canceled) [TERMINAL] -- stale transaction cleanup
```

### 2.2 Recoverable vs Non-Recoverable Failures

**What**: The mapping between status reasons and parent statuses encodes whether a failure is recoverable.

**Columns/Parameters Involved**: `ID`, `TransactionStatusID`

**Rules**:
- Reasons mapping to InProcess (TransactionStatusID=1) that indicate failure (CreditDecline, DebitDecline) are RECOVERABLE - the transaction stays in-process for retry
- Reasons mapping to Decline (TransactionStatusID=3) are NON-RECOVERABLE - the transaction has permanently failed
- This distinction is critical for the application's retry logic: only InProcess transactions should be retried

---

## 3. Data Overview

| ID | Name | TransactionStatusID | Meaning |
|----|------|---------------------|---------|
| 1 | Created | 1 (InProcess) | Transaction record created, processing has not yet begun. Initial state for all new transactions |
| 2 | Success | 2 (Success) | All pipeline steps completed successfully. Terminal positive state - funds fully transferred |
| 6 | HoldDecline | 3 (Decline) | Hold request rejected by provider (e.g., insufficient funds). Non-recoverable - transaction permanently failed |
| 9 | ValidateDecline | 3 (Decline) | Pre-execution validation failed before any fund movement. Non-recoverable |
| 15 | ReconciliationAborted | 5 (Canceled) | Stale or orphaned transaction cleaned up by automated reconciliation process |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying each transaction status reason. Explicitly assigned (not IDENTITY). Referenced as StatusReasonID in MoneyBus.Transactions and MoneyBus.TransactionsTable_New (UDT). Values: 1=Created, 2=Success, 3=Held, 4=Credited, 5=Debited, 6=HoldDecline, 7=CreditDecline, 8=DebitDecline, 9=ValidateDecline, 10=Technical, 11=DebitInitiated, 12=HoldInitiated, 13=CreditInitiated, 14=HoldCanceled, 15=ReconciliationAborted. See [Transaction Status Reason](../../_glossary.md#transaction-status-reason) for full business definitions. |
| 2 | Name | nvarchar(100) | NO | - | CODE-BACKED | Human-readable label for the status reason. Descriptive names follow a consistent pattern: {Step}{Outcome} (e.g., HoldInitiated, CreditDecline). Consumed by TransactionStatusReasonsGet for application-level caching and display. |
| 3 | TransactionStatusID | int | NO | - | VERIFIED | Parent status that this reason belongs to. Implicit FK to Dictionary.TransactionStatuses.ID. Maps each granular reason to its top-level outcome category: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Canceled. Critical for determining recoverability - reasons mapping to InProcess are retryable, others are terminal. See [Transaction Status](../../_glossary.md#transaction-status). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TransactionStatusID | Dictionary.TransactionStatuses | Implicit FK | Parent status category for this reason (1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Canceled) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MoneyBus.Transactions | StatusReasonID | Implicit Lookup | Current step-level state of the transaction in the processing pipeline |
| MoneyBus.TransactionsTable_New | StatusReasonID | UDT Column | Table-valued parameter type carrying StatusReasonID for batch transaction operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.TransactionStatusReasons (table)
└── Dictionary.TransactionStatuses (table) [via TransactionStatusID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.TransactionStatuses | Table | TransactionStatusID references TransactionStatuses.ID (parent status) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Transactions | Table | StatusReasonID references TransactionStatusReasons.ID |
| MoneyBus.TransactionsTable_New | User Defined Type | StatusReasonID column for batch operations |
| MoneyBus.TransactionStatusReasonsGet | Stored Procedure | SELECT * from this table - returns all rows for app caching |
| MoneyBus.TransactionAdd | Stored Procedure | Receives @StatusReasonID and INSERTs into Transactions |
| MoneyBus.TransactionUpdate | Stored Procedure | Receives @StatusReasonID and UPDATEs Transactions.StatusReasonID |
| MoneyBus.TransactionsAndGroupAdd | Stored Procedure | Inserts StatusReasonID when creating grouped transactions |
| MoneyBus.TransactionsGetByParams | Stored Procedure | Reads StatusReasonID from Transactions |
| MoneyBus.TransactionGet | Stored Procedure | Reads StatusReasonID from Transactions |
| MoneyBus.UserTransactionsGet | Stored Procedure | Reads StatusReasonID from Transactions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all reasons grouped by parent status
```sql
SELECT ts.Name AS ParentStatus, tsr.ID, tsr.Name AS Reason
FROM Dictionary.TransactionStatusReasons tsr WITH (NOLOCK)
INNER JOIN Dictionary.TransactionStatuses ts WITH (NOLOCK) ON ts.ID = tsr.TransactionStatusID
ORDER BY tsr.TransactionStatusID, tsr.ID
```

### 8.2 Find transactions stuck in non-terminal in-process sub-states
```sql
SELECT t.ID, tsr.Name AS CurrentReason, t.Created
FROM MoneyBus.Transactions t WITH (NOLOCK)
INNER JOIN Dictionary.TransactionStatusReasons tsr WITH (NOLOCK) ON tsr.ID = t.StatusReasonID
WHERE tsr.TransactionStatusID = 1 -- InProcess parent
  AND tsr.Name LIKE '%Initiated%' -- Waiting for provider response
ORDER BY t.Created ASC
```

### 8.3 Count transactions by detailed reason
```sql
SELECT tsr.Name AS Reason, ts.Name AS ParentStatus, COUNT(*) AS TxCount
FROM MoneyBus.Transactions t WITH (NOLOCK)
INNER JOIN Dictionary.TransactionStatusReasons tsr WITH (NOLOCK) ON tsr.ID = t.StatusReasonID
INNER JOIN Dictionary.TransactionStatuses ts WITH (NOLOCK) ON ts.ID = tsr.TransactionStatusID
GROUP BY tsr.Name, ts.Name
ORDER BY TxCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.1/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 9 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.TransactionStatusReasons | Type: Table | Source: MoneyBusDB/Dictionary/Tables/Dictionary.TransactionStatusReasons.sql*
