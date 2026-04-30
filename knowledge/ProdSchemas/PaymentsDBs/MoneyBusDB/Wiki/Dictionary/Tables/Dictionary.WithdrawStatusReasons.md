# Dictionary.WithdrawStatusReasons

> Lookup table providing granular sub-states within the withdrawal lifecycle, tracking step-level progress through the hold-authorize-payout pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.WithdrawStatusReasons provides detailed step-level tracking for withdrawal requests. While Dictionary.WithdrawStatuses captures the top-level outcome (InProcess, Success, Decline, Technical, Cancelled), this table records the specific step a withdrawal has reached in the hold-authorize-payout pipeline. Each reason maps to exactly one parent status via WithdrawStatusID.

The withdrawal pipeline is more complex than the transaction pipeline because it adds an authorization step (between hold and payout) and a risk manual review gate. This table enables operational teams to pinpoint exactly where a withdrawal is stuck - whether it is waiting for hold approval, blocked in risk review, or pending payout confirmation from the payment provider. The Dictionary.WithdrawStatusReasonGet stored procedure exposes this table for application-level caching.

Data flow: This is a static reference table maintained via schema migrations. It is read by Dictionary.WithdrawStatusReasonGet (which returns all rows). It is implicitly referenced by MoneyBus.Withdrawals (StatusReasonID column). Withdrawal procedures (WithdrawAdd, WithdrawUpdate) set the StatusReasonID as withdrawals progress through the pipeline. The procedure is granted EXECUTE permission to the withdrawal executor service identities (prod-mbwithdrawex-msi-ne/we).

---

## 2. Business Logic

### 2.1 Withdrawal Processing Pipeline

**What**: The status reasons map the step-by-step progression of a withdrawal through the hold-authorize-payout pipeline, which is more complex than the transaction pipeline due to the added authorization and risk review gates.

**Columns/Parameters Involved**: `ID`, `Name`, `WithdrawStatusID`

**Rules**:
- Happy path: Created(1) -> HoldInitiated(3) -> HoldApproved(4) -> AuthorizeInitiated(6) -> AuthorizeApproved(7) -> PayoutInitiated(9) -> PayoutApproved(10) -> Success(2)
- Risk review gate: RiskManualReview(15) can pause the pipeline at any point until compliance clears the withdrawal
- Authorization step (unique to withdrawals): AuthorizeInitiated -> AuthorizeApproved/AuthorizeDeclined
- AuthorizeDeclined(8) maps to InProcess (retryable), unlike HoldDeclined(5) which maps to Decline (terminal)
- PayoutApproved(10) is the ONLY reason that maps to Success(2) - confirming funds have actually left the platform
- AbortFailed(14) maps to InProcess (not a terminal state) because manual intervention is still expected
- AbortCompleted(13) maps to Cancelled(5) - the abort workflow successfully released held funds

**Diagram**:
```
[1] Created (InProcess)
  |
  v
[3] HoldInitiated (InProcess) ----fail----> [5] HoldDeclined (Decline) [TERMINAL]
  |
  v
[4] HoldApproved (InProcess)
  |
  v
[6] AuthorizeInitiated (InProcess) --fail--> [8] AuthorizeDeclined (InProcess - retryable)
  |
  v
[7] AuthorizeApproved (InProcess)
  |
  v
[9] PayoutInitiated (InProcess) ---fail----> [11] PayoutDeclined (InProcess - retryable)
  |
  v
[10] PayoutApproved (Success) [TERMINAL - funds left platform]
  |
  v
[2] Success (Success) [TERMINAL]

Abort path (at any InProcess step):
  [12] AbortInitiated (InProcess)
    |
    +---> [13] AbortCompleted (Cancelled) [TERMINAL - funds released]
    |
    +---> [14] AbortFailed (InProcess - needs manual intervention)

Risk gate (can pause any step):
  [15] RiskManualReview (InProcess - waiting for compliance)
```

### 2.2 Withdrawal vs Transaction Pipeline Comparison

**What**: The withdrawal pipeline adds authorization and risk review steps not present in the transaction pipeline, reflecting the higher regulatory requirements for funds leaving the platform.

**Columns/Parameters Involved**: `ID`, `Name`, `WithdrawStatusID`

**Rules**:
- Transaction pipeline: Hold -> Debit -> Credit (3 main steps)
- Withdrawal pipeline: Hold -> Authorize -> Payout (3 main steps + risk review gate)
- Authorization is withdrawal-specific because outbound funds require payment provider pre-approval
- RiskManualReview is withdrawal-specific because outbound funds face stricter compliance checks
- Abort workflow is withdrawal-specific (transactions use HoldCanceled/ReconciliationAborted instead)

---

## 3. Data Overview

| ID | Name | WithdrawStatusID | Meaning |
|----|------|------------------|---------|
| 1 | Created | 1 (InProcess) | Withdrawal request recorded, processing pipeline has not yet begun |
| 5 | HoldDeclined | 3 (Decline) | Hold on funds failed - insufficient balance or account restriction. Non-recoverable terminal failure |
| 10 | PayoutApproved | 2 (Success) | Payment provider confirmed the payout - funds are being sent to the user. Only reason that maps to Success |
| 13 | AbortCompleted | 5 (Cancelled) | Abort workflow successfully completed - previously held funds released back to the user's account |
| 15 | RiskManualReview | 1 (InProcess) | Withdrawal flagged by the risk engine and queued for manual compliance/fraud review. Pipeline paused until cleared |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying each withdrawal status reason. Explicitly assigned (not IDENTITY). Referenced as StatusReasonID in MoneyBus.Withdrawals. Values: 1=Created, 2=Success, 3=HoldInitiated, 4=HoldApproved, 5=HoldDeclined, 6=AuthorizeInitiated, 7=AuthorizeApproved, 8=AuthorizeDeclined, 9=PayoutInitiated, 10=PayoutApproved, 11=PayoutDeclined, 12=AbortInitiated, 13=AbortCompleted, 14=AbortFailed, 15=RiskManualReview. See [Withdraw Status Reason](../../_glossary.md#withdraw-status-reason) for full business definitions. |
| 2 | Name | nvarchar(100) | NO | - | CODE-BACKED | Human-readable label for the status reason. Names follow {Step}{Outcome} pattern (e.g., HoldApproved, PayoutDeclined, AbortCompleted). Read by Dictionary.WithdrawStatusReasonGet for application caching. |
| 3 | WithdrawStatusID | int | NO | - | VERIFIED | Parent status that this reason belongs to. Implicit FK to Dictionary.WithdrawStatuses.ID. Maps each granular reason to its top-level outcome: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Cancelled. Encodes recoverability: reasons mapping to InProcess can still progress, others are terminal. See [Withdraw Status](../../_glossary.md#withdraw-status). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawStatusID | Dictionary.WithdrawStatuses | Implicit FK | Parent status category for this reason (1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Cancelled) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MoneyBus.Withdrawals | StatusReasonID | Implicit Lookup | Current step-level state of the withdrawal in the processing pipeline |
| Dictionary.WithdrawStatusReasonGet | - | SELECT FROM | Procedure reads all rows from this table for application caching |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.WithdrawStatusReasons (table)
└── Dictionary.WithdrawStatuses (table) [via WithdrawStatusID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.WithdrawStatuses | Table | WithdrawStatusID references WithdrawStatuses.ID (parent status) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Withdrawals | Table | StatusReasonID references WithdrawStatusReasons.ID |
| Dictionary.WithdrawStatusReasonGet | Stored Procedure | SELECT * from this table - returns all rows |
| MoneyBus.WithdrawAdd | Stored Procedure | Receives @StatusReasonID and INSERTs into Withdrawals |
| MoneyBus.WithdrawUpdate | Stored Procedure | Receives @StatusReasonID and UPDATEs Withdrawals.StatusReasonID |
| MoneyBus.WithdrawGet | Stored Procedure | Reads StatusReasonID from Withdrawals |
| MoneyBus.WithdrawGetList | Stored Procedure | Reads StatusReasonID from Withdrawals |
| MoneyBus.WithdrawGetListV2 | Stored Procedure | Filters by @StatusReasonID when querying withdrawals |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WithdrawStatusReasons | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all reasons grouped by parent status
```sql
SELECT ws.Name AS ParentStatus, wsr.ID, wsr.Name AS Reason
FROM Dictionary.WithdrawStatusReasons wsr WITH (NOLOCK)
INNER JOIN Dictionary.WithdrawStatuses ws WITH (NOLOCK) ON ws.ID = wsr.WithdrawStatusID
ORDER BY wsr.WithdrawStatusID, wsr.ID
```

### 8.2 Find withdrawals stuck in risk review or abort-failed states
```sql
SELECT w.ID, wsr.Name AS CurrentReason, w.Created
FROM MoneyBus.Withdrawals w WITH (NOLOCK)
INNER JOIN Dictionary.WithdrawStatusReasons wsr WITH (NOLOCK) ON wsr.ID = w.StatusReasonID
WHERE wsr.ID IN (14, 15) -- AbortFailed, RiskManualReview
ORDER BY w.Created ASC
```

### 8.3 Count withdrawals by detailed reason
```sql
SELECT wsr.Name AS Reason, ws.Name AS ParentStatus, COUNT(*) AS WdCount
FROM MoneyBus.Withdrawals w WITH (NOLOCK)
INNER JOIN Dictionary.WithdrawStatusReasons wsr WITH (NOLOCK) ON wsr.ID = w.StatusReasonID
INNER JOIN Dictionary.WithdrawStatuses ws WITH (NOLOCK) ON ws.ID = wsr.WithdrawStatusID
GROUP BY wsr.Name, ws.Name
ORDER BY WdCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.1/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.WithdrawStatusReasons | Type: Table | Source: MoneyBusDB/Dictionary/Tables/Dictionary.WithdrawStatusReasons.sql*
