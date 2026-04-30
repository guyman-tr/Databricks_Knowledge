# Billing.WithdrawRejects

> Tracks manual withdrawal rejection records created by operations/compliance managers, including the reason, responsible manager, follow-up schedule, and whether the rejection is still active.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | RejectID (int IDENTITY, NONCLUSTERED PK) |
| **Partition** | No - stored on MAIN filegroup |
| **Indexes** | 2 active (NONCLUSTERED PK on RejectID + CLUSTERED on WithdrawID) |

---

## 1. Business Meaning

Billing.WithdrawRejects is the rejection audit table for withdrawal requests. When an operations or compliance manager rejects a withdrawal (e.g., missing documents, fraud risk, alternative payment method required), a row is inserted here recording who rejected it, why, when, and when to follow up with the customer. The parent withdrawal in `Billing.Withdraw` is simultaneously updated to `CashoutStatusID=7` (Rejected).

This table exists because a withdrawal can be rejected multiple times (rejected, re-submitted, rejected again) and may need follow-up tracking between rejections. The `IsActive` flag distinguishes the current active rejection from historical ones for a given withdrawal, while `FollowupDate` drives the operations team's work queue. `CaseNumber`/`CaseDate` link the rejection to an external support/CRM ticket.

Data is written exclusively by `Billing.WithdrawReject` (the main rejection procedure), which atomically sets `Billing.Withdraw.CashoutStatusID=7` and inserts here. `Billing.SetRejectsAsInactiveForWithdraw` sets prior rejections to `IsActive=0` before a new rejection is recorded. `Billing.FollowupEdit` updates `FollowupDate` and `CaseNumber`/`CaseDate` after the initial rejection.

---

## 2. Business Logic

### 2.1 Rejection Lifecycle and IsActive Pattern

**What**: Multiple rejection records can exist per withdrawal; IsActive identifies the current active rejection.

**Columns/Parameters Involved**: `WithdrawID`, `IsActive`, `RejectDate`

**Rules**:
- A withdrawal starts with no reject records. When first rejected, one row is inserted with `IsActive=1`.
- If re-rejected after being re-submitted, `SetRejectsAsInactiveForWithdraw` sets all prior rows to `IsActive=0` before the new rejection row is inserted with `IsActive=1`.
- A withdrawal with any `IsActive=1` row is in "Rejected" state in the operations queue.
- `Billing.WithdrawReject` guards against rejecting already-cancelled withdrawals (CashoutStatusID=4): returns error 60065 if attempted.

**Diagram**:
```
Withdrawal submitted -> CashoutStatusID=Pending
    |
Manager rejects -> WithdrawReject proc:
    - Billing.Withdraw.CashoutStatusID = 7 (Rejected)
    - WithdrawRejects: INSERT IsActive=1
    |
Customer re-submits (different flow - not in this table)
    |
Manager rejects again -> SetRejectsAsInactiveForWithdraw (prior rows: IsActive=0)
                      -> WithdrawReject: INSERT new row IsActive=1
```

### 2.2 Follow-Up Scheduling (FollowupDate)

**What**: FollowupDate defines when the operations team should next action this rejected withdrawal.

**Columns/Parameters Involved**: `FollowupDate`, `CaseNumber`, `CaseDate`, `Comment`

**Rules**:
- `FollowupDate` is set at rejection time to the expected date by which the customer should have responded (typically 3-7 business days out, based on live data).
- `FollowupEdit` procedure updates `FollowupDate` if the customer needs more time or if the case escalates.
- `CaseNumber` and `CaseDate` are NULL on initial INSERT (set by `FollowupEdit` when a support ticket is created). They link to an external CRM or support platform.
- `Comment` contains the operations agent's notes, often a case ID reference or customer instruction (e.g., "25402491 follow up", "test").

### 2.3 Reject Reason Categories

**What**: Dictionary.CashoutRejectReason defines 28 reason codes covering operational, compliance, and customer-service categories.

**Columns/Parameters Involved**: `RejectReasonID`

**Rules**:
- `IsInDisplay=true` reasons (11, 15, 19, 23, 24, 26, 27) are shown in the customer-facing UI or operations dashboards.
- Compliance reasons (5=Denied, 6=Bonus Abuse, 7=Risk, 8=Off Market Abuse): require further compliance review.
- Operational reasons (0=Wrong Details MOP, 1=Missing Documents, 2=Missing Payment Information): customer needs to provide correct information before re-submission.
- `RejectReasonID=11` (Alternative Payment method) is the dominant reason in recent data - customer's withdrawal method is unavailable or needs changing.
- `ManagerID=0` in recent data suggests automated/system-initiated rejections for some reason codes.

---

## 3. Data Overview

| RejectID | WithdrawID | RejectReasonID | ManagerID | RejectDate | FollowupDate | IsActive | Meaning |
|----------|-----------|----------------|-----------|------------|--------------|----------|---------|
| 230 | 1734756 | 11 (Alternative Payment) | 0 (System) | 2026-03-17 | 2026-03-20 | 1 | Active rejection - customer's payment method needs changing; follow-up scheduled in 3 days. Likely automated system rejection. |
| 228 | 1725397 | 11 (Alternative Payment) | 0 (System) | 2026-03-13 | 2026-03-18 | 1 | Pending follow-up with customer (comment: "25402491 follow up" - a support ticket reference). |
| (typical) | (any) | 1 (Missing Documents) | (mgr) | (reject date) | (N+5 days) | 0 | Historical rejection - customer previously rejected for missing docs, since re-submitted; this record superseded by newer rejection or approval. |
| (typical) | (any) | 7 (Risk) | (compliance mgr) | (date) | (date) | 1 | Compliance hold - withdrawal flagged for risk review. FollowupDate drives compliance team's review schedule. |
| (typical) | (any) | 5 (Denied) | (mgr) | (date) | (date) | 1 | Hard denial - withdrawal permanently rejected (AML, bonus abuse, or other compliance grounds). No re-submission expected. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RejectID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate primary key, auto-incremented. NOT FOR REPLICATION. No business meaning beyond row identity. |
| 2 | WithdrawID | int | NO | - | VERIFIED | FK to Billing.Withdraw (WithdrawID) - enforced by FK_BWWR_BW. Identifies the withdrawal being rejected. The CLUSTERED index on this column enables fast lookup of all rejection records for a withdrawal. |
| 3 | RejectReasonID | tinyint | NO | - | VERIFIED | FK to Dictionary.CashoutRejectReason (RejectReasonID) - enforced by FK_BWWR_DCRR. Reason the withdrawal was rejected. Key values: 0=Wrong Details MOP, 1=Missing Documents, 2=Missing Payment Info, 3=Missing Alternative MOP, 4=Unclaimed, 5=Denied, 6=Bonus Abuse, 7=Risk, 8=Off Market Abuse, 9=Management Approval, 10=Other, 11=Alternative Payment method (dominant), 15=CO Issues, 19=Missing/incorrect payment info, 27=Deceased client. Full list in Dictionary.CashoutRejectReason. |
| 4 | ManagerID | int | NO | - | VERIFIED | FK to BackOffice.Manager (ManagerID) - enforced by FK_BWWR_BMNG. The operations/compliance manager who performed the rejection. Value 0 appears in recent automated/system rejections. |
| 5 | RejectDate | datetime | NO | - | VERIFIED | Timestamp when the rejection was recorded. Set by `Billing.WithdrawReject` as @RejectDate parameter (caller provides timestamp). Used to sequence multiple rejections per withdrawal. |
| 6 | FollowupDate | datetime | NO | - | VERIFIED | Date by which the operations team should follow up on this rejection (check if customer responded, re-submitted, or needs chasing). Typically set 3-7 business days from RejectDate. Updated by `Billing.FollowupEdit`. Drives the operations team's work queue. |
| 7 | CaseNumber | int | YES | - | CODE-BACKED | External support/CRM ticket number linked to this rejection. NULL on initial insert (set by `Billing.FollowupEdit` when a support case is created). Allows linking the DB rejection record to a support platform case. |
| 8 | CaseDate | datetime | YES | - | CODE-BACKED | Date the external support case was created. NULL on initial insert, set alongside CaseNumber by `Billing.FollowupEdit`. |
| 9 | IsActive | bit | NO | - | VERIFIED | Whether this rejection record is the current active rejection for the withdrawal. 1=active (this is the current rejection), 0=superseded (a newer rejection has been recorded). Set to 1 on insert by `Billing.WithdrawReject`. Set to 0 by `Billing.SetRejectsAsInactiveForWithdraw` when a re-rejection occurs. Only one IsActive=1 record should exist per WithdrawID at any time. |
| 10 | Comment | nvarchar(max) | YES | - | CODE-BACKED | Free-text notes from the rejecting manager. May contain case reference numbers, customer instructions, or context for the rejection (e.g., "Missing IBAN for wire transfer", "25402491 follow up"). NULL is allowed but rarely used in practice. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.Withdraw | FK (FK_BWWR_BW) | Links rejection record to the parent withdrawal request being rejected. |
| RejectReasonID | Dictionary.CashoutRejectReason | FK (FK_BWWR_DCRR) | Resolves reason code to human-readable rejection category. |
| ManagerID | BackOffice.Manager | FK (FK_BWWR_BMNG) | Links rejection to the operations/compliance manager who performed it. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawReject | @WithdrawID | Writer | Primary insertion point - creates rejection record and atomically updates Billing.Withdraw.CashoutStatusID=7. |
| Billing.SetRejectsAsInactiveForWithdraw | WithdrawID | Modifier | Sets all prior rejection records to IsActive=0 before a re-rejection is recorded. |
| Billing.FollowupEdit | RejectID | Modifier | Updates FollowupDate, CaseNumber, CaseDate after initial rejection. |
| Billing.GetRejectedWithdrawsByRequestDate | WithdrawID | Reader | Returns rejected withdrawals filtered by original request date for reporting. |
| Billing.GetRejectedWithdrawsByRejectDate | RejectDate | Reader | Returns rejected withdrawals filtered by rejection date for reporting. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf table).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | FK target - WithdrawID must exist in Billing.Withdraw. |
| Dictionary.CashoutRejectReason | Table | FK target - RejectReasonID must exist in this lookup. |
| BackOffice.Manager | Table | FK target - ManagerID must exist in BackOffice.Manager. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawReject | Stored Procedure | Writer - primary rejection procedure, inserts new rejection records. |
| Billing.SetRejectsAsInactiveForWithdraw | Stored Procedure | Modifier - deactivates prior rejection records before re-rejection. |
| Billing.FollowupEdit | Stored Procedure | Modifier - updates follow-up scheduling fields. |
| Billing.GetRejectedWithdrawsByRequestDate | Stored Procedure | Reader - rejection reporting by request date. |
| Billing.GetRejectedWithdrawsByRejectDate | Stored Procedure | Reader - rejection reporting by reject date. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BWWR | NONCLUSTERED PK | RejectID ASC | - | - | Active |
| IX_WithdrawRejects_WithdrawID | CLUSTERED | WithdrawID ASC | - | - | Active |

Note: Unusual pattern - NONCLUSTERED PK with separate CLUSTERED index on WithdrawID. This optimizes for the common access pattern (lookup by WithdrawID) while preserving a unique row identifier.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BWWR | PRIMARY KEY | Unique row identity on RejectID. |
| FK_BWWR_BW | FOREIGN KEY | WithdrawID -> Billing.Withdraw(WithdrawID). Prevents orphaned rejection records. |
| FK_BWWR_DCRR | FOREIGN KEY | RejectReasonID -> Dictionary.CashoutRejectReason(RejectReasonID). Enforces valid reason codes. |
| FK_BWWR_BMNG | FOREIGN KEY | ManagerID -> BackOffice.Manager(ManagerID). Enforces valid manager references. |

---

## 8. Sample Queries

### 8.1 Get active rejection details for a specific withdrawal

```sql
SELECT
    wr.RejectID,
    crr.RejectReasonName,
    wr.ManagerID,
    wr.RejectDate,
    wr.FollowupDate,
    wr.CaseNumber,
    wr.Comment
FROM Billing.WithdrawRejects wr WITH (NOLOCK)
JOIN Dictionary.CashoutRejectReason crr WITH (NOLOCK) ON crr.RejectReasonID = wr.RejectReasonID
WHERE wr.WithdrawID = 1734756
  AND wr.IsActive = 1;
```

### 8.2 Withdrawals requiring follow-up today or overdue

```sql
SELECT
    wr.WithdrawID,
    crr.RejectReasonName,
    wr.FollowupDate,
    wr.Comment,
    w.CID,
    w.Amount
FROM Billing.WithdrawRejects wr WITH (NOLOCK)
JOIN Billing.Withdraw w WITH (NOLOCK) ON w.WithdrawID = wr.WithdrawID
JOIN Dictionary.CashoutRejectReason crr WITH (NOLOCK) ON crr.RejectReasonID = wr.RejectReasonID
WHERE wr.IsActive = 1
  AND wr.FollowupDate <= GETDATE()
ORDER BY wr.FollowupDate ASC;
```

### 8.3 Rejection reason frequency summary (active rejections)

```sql
SELECT
    crr.RejectReasonName,
    COUNT(*) AS ActiveCount
FROM Billing.WithdrawRejects wr WITH (NOLOCK)
JOIN Dictionary.CashoutRejectReason crr WITH (NOLOCK) ON crr.RejectReasonID = wr.RejectReasonID
WHERE wr.IsActive = 1
GROUP BY crr.RejectReasonName
ORDER BY COUNT(*) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawRejects | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.WithdrawRejects.sql*
