# Dictionary.WithdrawStatuses

> Lookup table defining the top-level lifecycle states of withdrawal requests in the MoneyBus payment system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.WithdrawStatuses defines the high-level outcome categories for withdrawal requests. Withdrawal processing follows a more complex pipeline than standard transactions - it includes hold, authorize, and payout steps before funds leave the platform. This table captures the top-level state that summarizes where a withdrawal stands in that pipeline.

This table mirrors the structure of Dictionary.TransactionStatuses but is dedicated to the withdrawal workflow. The distinction exists because withdrawals have a fundamentally different lifecycle (hold-authorize-payout) compared to transactions (hold-debit-credit), and the terminal states may be reached through different paths. The parent-child relationship with Dictionary.WithdrawStatusReasons provides the granular step-level tracking within each status.

Data flow: This is a static reference table maintained via schema migrations. It is implicitly referenced by MoneyBus.Withdrawals (StatusID column) and serves as the parent classification for Dictionary.WithdrawStatusReasons (WithdrawStatusID column). Withdrawal procedures (WithdrawAdd, WithdrawUpdate, WithdrawGet, WithdrawGetList, WithdrawGetListV2) all work with StatusID values defined by this table.

---

## 2. Business Logic

### 2.1 Withdrawal Status State Machine

**What**: Withdrawals follow a deterministic lifecycle from creation to terminal state, with InProcess as the only non-terminal status.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- A withdrawal is created with StatusID=1 (InProcess) and remains there through the hold-authorize-payout pipeline
- StatusID=2 (Success) is the only positive terminal state - funds have been paid out to the user
- StatusID=3 (Decline) means a processing step was rejected (hold declined, payout declined)
- StatusID=4 (Technical) means a system/infrastructure failure during withdrawal processing
- StatusID=5 (Cancelled) means the withdrawal was explicitly cancelled by user, backoffice, or abort workflow
- Note: uses double-l "Cancelled" spelling, unlike TransactionStatuses which uses single-l "Canceled"

**Diagram**:
```
                     +---> [2] Success   (terminal - payout confirmed)
                     |
[1] InProcess -------+---> [3] Decline   (terminal - processing rejected)
                     |
                     +---> [4] Technical  (terminal - system failure)
                     |
                     +---> [5] Cancelled  (terminal - explicit cancellation)
```

### 2.2 Parent-Child Status Hierarchy

**What**: WithdrawStatuses is the parent tier; WithdrawStatusReasons is the child tier providing step-level detail through the hold-authorize-payout pipeline.

**Columns/Parameters Involved**: `ID` (this table), `WithdrawStatusID` (Dictionary.WithdrawStatusReasons)

**Rules**:
- Each WithdrawStatusReason maps to exactly one WithdrawStatus via WithdrawStatusID
- InProcess (1) has the most sub-reasons: Created, HoldInitiated, HoldApproved, AuthorizeInitiated, AuthorizeApproved, AuthorizeDeclined, PayoutInitiated, PayoutDeclined, AbortInitiated, AbortFailed, RiskManualReview
- Success (2) has two sub-reasons: Success (final confirmation) and PayoutApproved (payout confirmed by provider)
- Decline (3) has only HoldDeclined
- Cancelled (5) has AbortCompleted
- The withdrawal pipeline adds authorization and risk review steps not present in the transaction pipeline

---

## 3. Data Overview

| ID | Name | Meaning |
|----|------|---------|
| 1 | InProcess | Withdrawal is actively being processed through the hold-authorize-payout pipeline. May be waiting for hold approval, authorization, payout confirmation, or stuck in risk manual review |
| 2 | Success | Withdrawal completed successfully - funds have been paid out to the user via the payment provider. This is the only terminal state where money has actually left the platform |
| 3 | Decline | Withdrawal was declined at one of the processing steps - most commonly when the hold on funds fails due to insufficient balance or account restrictions |
| 4 | Technical | Withdrawal failed due to a system-level error during processing (timeout, connectivity, unexpected exception). Not a business-rule rejection |
| 5 | Cancelled | Withdrawal was explicitly cancelled - either by the user, by backoffice staff, or by the system's automated abort workflow when a payout reversal completes |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying each withdrawal status. Explicitly assigned (not IDENTITY). Referenced as StatusID in MoneyBus.Withdrawals and as WithdrawStatusID in Dictionary.WithdrawStatusReasons. Values: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Cancelled. See [Withdraw Status](../../_glossary.md#withdraw-status) for full business definitions. |
| 2 | Name | nvarchar(50) | NO | - | CODE-BACKED | Human-readable status label used for display in withdrawal reports and operational dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MoneyBus.Withdrawals | StatusID | Implicit Lookup | Current top-level lifecycle state of the withdrawal |
| Dictionary.WithdrawStatusReasons | WithdrawStatusID | Implicit FK | Parent status that each granular withdrawal reason maps to |
| History.MoneyBusWithdrawals | StatusID | Implicit Lookup | Historical record of the withdrawal's final status |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.WithdrawStatusReasons | Table | WithdrawStatusID references WithdrawStatuses.ID (parent-child hierarchy) |
| MoneyBus.Withdrawals | Table | StatusID references WithdrawStatuses.ID |
| History.MoneyBusWithdrawals | Table | StatusID references WithdrawStatuses.ID |
| MoneyBus.WithdrawAdd | Stored Procedure | Receives @StatusID and INSERTs into Withdrawals |
| MoneyBus.WithdrawUpdate | Stored Procedure | Receives @StatusID and UPDATEs Withdrawals.StatusID |
| MoneyBus.WithdrawGetListV2 | Stored Procedure | Filters by @StatusID when querying withdrawals |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WithdrawStatuses | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all withdrawal statuses
```sql
SELECT ID, Name
FROM Dictionary.WithdrawStatuses WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Count withdrawals by status
```sql
SELECT ws.Name AS Status, COUNT(*) AS WithdrawalCount
FROM MoneyBus.Withdrawals w WITH (NOLOCK)
INNER JOIN Dictionary.WithdrawStatuses ws WITH (NOLOCK) ON ws.ID = w.StatusID
GROUP BY ws.Name
ORDER BY WithdrawalCount DESC
```

### 8.3 View withdrawal status reasons with their parent status
```sql
SELECT ws.Name AS ParentStatus, wsr.ID AS ReasonID, wsr.Name AS ReasonName
FROM Dictionary.WithdrawStatusReasons wsr WITH (NOLOCK)
INNER JOIN Dictionary.WithdrawStatuses ws WITH (NOLOCK) ON ws.ID = wsr.WithdrawStatusID
ORDER BY ws.ID, wsr.ID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.9/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.WithdrawStatuses | Type: Table | Source: MoneyBusDB/Dictionary/Tables/Dictionary.WithdrawStatuses.sql*
