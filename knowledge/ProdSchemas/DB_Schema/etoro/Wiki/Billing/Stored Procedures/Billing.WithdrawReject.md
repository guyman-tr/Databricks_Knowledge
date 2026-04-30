# Billing.WithdrawReject

> Atomically rejects a pending withdrawal request by setting its status to Rejected (7) and recording the rejection reason, manager, and follow-up schedule in the audit table.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID - the withdrawal being rejected |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawReject` is the single entry point for operations and compliance managers to formally reject a withdrawal request. A rejection occurs when a withdrawal cannot be processed as-is: the customer may have submitted incorrect banking details, failed a document verification step, or triggered a compliance review.

The procedure exists to make the rejection atomic - two writes must happen together: the parent `Billing.Withdraw` row must have its status changed to `CashoutStatusID=7` (Rejected), AND a rejection record must be created in `Billing.WithdrawRejects` with the reason, responsible manager, and follow-up date. Splitting these into separate calls would risk the audit record being created without the status update, or vice versa.

Data flows from the operations tooling (back-office or compliance UI) where a manager selects a reject reason and optionally adds a comment and follow-up date. The procedure is called once per rejection decision. If the customer re-submits the withdrawal after receiving the rejection, `Billing.SetRejectsAsInactiveForWithdraw` is called first to archive the prior rejection, then this procedure is called again to record the new rejection.

---

## 2. Business Logic

### 2.1 Cancellation Guard (Error 60065)

**What**: A cancelled withdrawal cannot be rejected - the guard prevents invalid state transitions.

**Columns/Parameters Involved**: `Billing.Withdraw.CashoutStatusID`, return code 60065

**Rules**:
- Before any writes, the procedure reads the current `CashoutStatusID` from `Billing.Withdraw`.
- If `CashoutStatusID=4` (Cancelled), the procedure raises an error and returns 60065.
- Any other status (Pending=1, InProcess=2, etc.) proceeds to the rejection writes.
- This guard prevents rejected/re-rejected cycles from operating on already-cancelled withdrawals, which would corrupt the audit trail.

**Diagram**:
```
Read Billing.Withdraw.CashoutStatusID WHERE WithdrawID=@WithdrawID
    |
    +-- CashoutStatusID = 4 (Cancelled) --> RAISERROR, RETURN 60065
    |
    +-- CashoutStatusID != 4 --> proceed to rejection writes
```

### 2.2 Atomic Rejection Write (Transaction)

**What**: The status update and rejection audit record are written in a single named transaction.

**Columns/Parameters Involved**: `@WithdrawID`, `@ManagerID`, `@RejectDate`, `@RejectReasonID`, `@FollowupDate`, `@Comment`, `@SessionID`

**Rules**:
- `Billing.UpsertWithdraw` is called with `CashoutStatusID=7`, `ManagerID=@ManagerID`, `ModificationDate=@RejectDate`, and `SessionID=@SessionID` to update the parent withdrawal.
- `Billing.WithdrawRejects` receives a new row with `IsActive=1`, the reject reason, manager, dates, comment, and NULL values for `CaseNumber`/`CaseDate` (to be filled later by `Billing.FollowupEdit`).
- `@Comment` is stored in `WithdrawRejects` only - it was removed from the `UpsertWithdraw` call (MIMOPS-5288, Oct 2021).
- On any error, transaction is rolled back (single-transaction scope). If nested in an outer transaction (@@TRANCOUNT > 1), the outer transaction is preserved.

**Diagram**:
```
BEGIN TRANSACTION WithdrawReject
  |
  +--> EXEC Billing.UpsertWithdraw(@Info)
  |      Billing.Withdraw: CashoutStatusID = 7 (Rejected)
  |                        ManagerID = @ManagerID
  |                        ModificationDate = @RejectDate
  |
  +--> INSERT Billing.WithdrawRejects
             RejectReasonID = @RejectReasonID
             IsActive = 1
             FollowupDate = @FollowupDate
             Comment = @Comment
             CaseNumber = NULL (pending)
             CaseDate = NULL (pending)
  |
COMMIT / ROLLBACK on error
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INT | NO | - | CODE-BACKED | The withdrawal being rejected. FK to `Billing.Withdraw.WithdrawID`. Used to read the current status (guard check) and to key both writes. |
| 2 | @RejectReasonID | INT | NO | - | CODE-BACKED | The coded rejection reason selected by the manager. Stored in `Billing.WithdrawRejects.RejectReasonID`. References a rejection reason lookup - common reasons include missing documents, incorrect bank details, and compliance holds. |
| 3 | @ManagerID | INT | NO | - | CODE-BACKED | ID of the operations or compliance manager performing the rejection. Written to both `Billing.Withdraw.ManagerID` (via UpsertWithdraw) and `Billing.WithdrawRejects.ManagerID` for accountability tracking. |
| 4 | @RejectDate | DATETIME | NO | - | CODE-BACKED | Timestamp of the rejection decision. Written as `ModificationDate` in `Billing.Withdraw` (via UpsertWithdraw) and as `RejectDate` in `Billing.WithdrawRejects`. |
| 5 | @FollowupDate | DATETIME | NO | - | CODE-BACKED | Date by which the operations team expects the customer to respond or take action (typically 3-7 business days). Drives the ops team's follow-up work queue. Stored in `Billing.WithdrawRejects.FollowupDate`. |
| 6 | @Comment | NVARCHAR(MAX) | NO | - | CODE-BACKED | Free-text manager comment explaining the rejection (visible to customer or internal). Stored in `Billing.WithdrawRejects.Comment` only - was removed from the `UpsertWithdraw` call in Oct 2021 (MIMOPS-5288). |
| 7 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Optional back-office session identifier for audit trail correlation. Passed to `Billing.UpsertWithdraw` which writes it to `Billing.Withdraw.SessionID` if non-NULL. Added 2015-10-20. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.Withdraw | FK (read + write via UpsertWithdraw) | Reads current status for guard check; updates CashoutStatusID=7 via UpsertWithdraw. |
| @WithdrawID | Billing.WithdrawRejects | FK (write) | Inserts rejection audit record with IsActive=1. |
| (internal) | Billing.UpsertWithdraw | Procedure call | Used to update Billing.Withdraw atomically using the TBL_Withdraw TVP. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer (back-office/compliance UI) | - | Caller | Called when an operations or compliance manager formally rejects a withdrawal in the back-office tool. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawReject (procedure)
├── Billing.Withdraw (table) - read for status guard
├── Billing.UpsertWithdraw (procedure)
│     └── Billing.Withdraw (table) - written
└── Billing.WithdrawRejects (table) - written
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | SELECT to read CashoutStatusID for cancellation guard check |
| Billing.UpsertWithdraw | Procedure | EXEC to update CashoutStatusID=7 (Rejected), ManagerID, ModificationDate via TBL_Withdraw TVP |
| Billing.WithdrawRejects | Table | INSERT to create rejection audit record with reason, manager, dates, comment |
| Billing.TBL_Withdraw | User Defined Type | Table variable type used to pass parameters to UpsertWithdraw |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.SetRejectsAsInactiveForWithdraw | Procedure | Called before this procedure on re-rejection to archive the prior rejection |
| Billing.FollowupEdit | Procedure | Called after this procedure to update CaseNumber/CaseDate once a CRM case is assigned |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Cancellation guard | Application-level | Returns error 60065 if CashoutStatusID=4 (Cancelled) - prevents rejecting an already-cancelled withdrawal |
| Named transaction | Transactional | All writes are wrapped in BEGIN TRANSACTION "WithdrawReject" with TRY/CATCH rollback on error |

---

## 8. Sample Queries

### 8.1 Reject a withdrawal with bank details issue

```sql
EXEC Billing.WithdrawReject
    @WithdrawID = 987654,
    @RejectReasonID = 3,
    @ManagerID = 12,
    @RejectDate = '2026-03-18 10:30:00',
    @FollowupDate = '2026-03-25 00:00:00',
    @Comment = N'Incorrect IBAN provided - please resubmit with correct bank details.',
    @SessionID = NULL;
```

### 8.2 Check current rejection details for a withdrawal

```sql
SELECT
    wr.RejectID,
    wr.WithdrawID,
    wr.RejectReasonID,
    wr.ManagerID,
    wr.RejectDate,
    wr.FollowupDate,
    wr.IsActive,
    wr.Comment,
    w.CashoutStatusID
FROM Billing.WithdrawRejects wr WITH (NOLOCK)
JOIN Billing.Withdraw w WITH (NOLOCK) ON w.WithdrawID = wr.WithdrawID
WHERE wr.WithdrawID = 987654
ORDER BY wr.RejectDate DESC;
```

### 8.3 Find all active rejections pending follow-up today

```sql
SELECT
    wr.WithdrawID,
    wr.RejectReasonID,
    wr.ManagerID,
    wr.FollowupDate,
    wr.Comment,
    w.CID,
    w.Amount
FROM Billing.WithdrawRejects wr WITH (NOLOCK)
JOIN Billing.Withdraw w WITH (NOLOCK) ON w.WithdrawID = wr.WithdrawID
WHERE wr.IsActive = 1
  AND wr.FollowupDate <= GETDATE()
  AND w.CashoutStatusID = 7
ORDER BY wr.FollowupDate ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawReject | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawReject.sql*
