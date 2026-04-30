# Billing.DepositActionAdd

> Appends a new action record to History.DepositAction for a given deposit, inheriting the last MatchStatusID and optionally the SessionID from the deposit, recording each payment status transition in the deposit's audit trail.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID + @PaymentActionStatusID + @PaymentActionTypeID append to History.DepositAction |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositActionAdd` writes a new row to `History.DepositAction`, the immutable audit log of every status transition a deposit undergoes throughout its lifecycle. It is the standard mechanism for recording deposit lifecycle events: initial purchase, authorization, capture, approval, rejection, refund, chargeback, and any manual intervention by operations staff.

`History.DepositAction` is an append-only history table - rows are never updated or deleted. Each call to `DepositActionAdd` records one discrete event: who triggered it (`@ManagerID`), what happened (`@PaymentActionTypeID`, `@PaymentActionStatusID`), what the deposit's resulting status is (`@PaymentStatusID`), and contextual details (`@AuthCode`, `@ApprovalNumber`, `@ResponseID`, `@ExchangeRate`, `@SessionID`).

Two implicit data inheritance behaviors make this procedure significant:
1. **MatchStatusID inheritance**: The procedure queries `History.DepositAction` for the most recent MatchStatusID and propagates it to the new action row. MatchStatusID is set externally by fraud/matching processes and must carry forward to each new action to preserve the deposit's current fraud classification state.
2. **SessionID fallback**: If `@SessionID` is not provided by the caller, the procedure reads the SessionID from `Billing.Deposit` itself. This ensures browser/user session context is recorded on every action even when callers don't explicitly pass it.

Created as part of the deposit processing pipeline (referenced in comment "Billing.DepositActionAdd, Billing.DepositProcess, Billing.DepositUpdate"). `Billing.DepositAdd` calls this procedure inline within its transaction to record the initial creation action.

Confluence pages found (not accessible): "Deposit Finalize Steps Refactor", "Deposit Finalize Steps Current" - these likely describe the full deposit lifecycle pipeline that this procedure serves.

---

## 2. Business Logic

### 2.1 SessionID Inheritance from Deposit

**What**: If the caller does not supply @SessionID, the procedure reads the customer's SessionID from Billing.Deposit to populate the action record.

**Columns/Parameters Involved**: `@SessionID`, `Billing.Deposit.SessionID`

**Rules**:
- `SELECT @SessionID = (CASE WHEN @SessionID IS NULL THEN SessionID ELSE @SessionID END) FROM Billing.Deposit WITH(NOLOCK) WHERE DepositID=@DepositID`
- If @SessionID IS NOT NULL: use the caller's value unchanged
- If @SessionID IS NULL: read the SessionID that was stored when the deposit was first created
- If the DepositID doesn't exist: @SessionID remains NULL (no row to read from)
- SessionID is BIGINT - represents the browser/user session that initiated the deposit

### 2.2 MatchStatusID Carry-Forward

**What**: Reads the last recorded MatchStatusID from the deposit's history and propagates it to the new action record, ensuring fraud classification state is preserved across all actions.

**Columns/Parameters Involved**: `@MatchStatusID`, `History.DepositAction.MatchStatusID`, `History.DepositAction.DepositActionID`

**Rules**:
- Uses ROW_NUMBER() OVER (ORDER BY DepositActionID DESC) to find the most recent action row for this DepositID
- Selects the MatchStatusID from rank=1 (the latest action)
- If no previous actions exist (first action for this deposit): @MatchStatusID remains NULL -> inserted as NULL (MatchStatusID is TINYINT, starts at 0 for new deposits via DepositAdd which hardcodes 0)
- MatchStatusID is NOT a caller parameter - it is always inherited, never directly set via this procedure (external matching/fraud processes update it through other procedures)
- Pattern uses ROW_NUMBER to avoid a subquery with MAX() on DepositActionID

### 2.3 Append Action to History

**What**: Inserts the complete action record into History.DepositAction and returns the new row's identity.

**Columns/Parameters Involved**: All parameters -> `History.DepositAction`

**Rules**:
- ModificationDate set to @Now (GETDATE() if not provided by caller)
- MatchStatusID and SessionID use the inherited values from sections 2.1 and 2.2
- SCOPE_IDENTITY() -> @DepositActionID OUTPUT
- On INSERT error: `RAISERROR(60000, 16, 1, 'Billing.DepositActionAdd', @LocalError)` and RETURN 60000
- On success: RETURN 0

**Diagram**:
```
@SessionID IS NULL?
  YES -> Read SessionID FROM Billing.Deposit WHERE DepositID=@DepositID
  NO  -> Use caller's @SessionID

Read last MatchStatusID FROM History.DepositAction
  WHERE DepositID=@DepositID (ROW_NUMBER ORDER BY DepositActionID DESC)

INSERT INTO History.DepositAction (all params + inherited values)
         |
  @@ERROR != 0? -> RAISERROR(60000) + RETURN 60000
  SUCCESS?      -> @DepositActionID = SCOPE_IDENTITY(), RETURN 0
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositActionID | INT | YES (OUTPUT) | - | CODE-BACKED | OUTPUT: SCOPE_IDENTITY() of the newly inserted History.DepositAction row. Callers use this to reference the specific action record for downstream processing. |
| 2 | @DepositID | INT | NO | - | CODE-BACKED | The deposit whose lifecycle this action belongs to. Used to read SessionID from Billing.Deposit and MatchStatusID from History.DepositAction, and as the FK for the inserted action record. |
| 3 | @PaymentActionStatusID | INT | NO | - | CODE-BACKED | Status of this action (e.g., 1=New/Purchase per DepositAdd usage). Records the outcome of the payment gateway interaction for this step. |
| 4 | @PaymentActionTypeID | INT | NO | - | CODE-BACKED | Type of action being recorded (e.g., 2=Purchase per DepositAdd usage). Categorizes what kind of deposit event this action represents. |
| 5 | @PaymentStatusID | INT | NO | - | CODE-BACKED | The deposit's resulting payment status after this action (e.g., 2=Approved, 3=Rejected). This becomes the current status of the deposit as recorded in the history trail. |
| 6 | @ManagerID | INT | YES | NULL | CODE-BACKED | eToro staff member ID who triggered this action. NULL for system-automated actions; populated for manual operations team actions. |
| 7 | @ResponseID | INT | YES | NULL | CODE-BACKED | Payment gateway response code reference. Links to a response code lookup table for the specific provider's reply. |
| 8 | @AuthCode | VARCHAR(20) | YES | NULL | CODE-BACKED | Authorization code returned by the payment gateway upon successful authorization. Used for card transactions (CVV/3DS auth codes). |
| 9 | @ApprovalNumber | VARCHAR(20) | YES | NULL | CODE-BACKED | Approval number returned by the payment processor. Complements AuthCode - some processors return one, some return both. |
| 10 | @ExchangeRate | dtPrice | YES | NULL | CODE-BACKED | Exchange rate in effect at the time of this action, if different from the original deposit rate. Recorded for FX audit trail. |
| 11 | @Now | DATETIME | YES | NULL | CODE-BACKED | Timestamp for the action. If NULL, the procedure sets it to GETDATE(). Callers can override to ensure transactional consistency with related records written at the same moment. |
| 12 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Browser/user session ID. If NULL, inherited from Billing.Deposit.SessionID for the deposit (added 20/10/2015 by Eitan). Ensures session context is preserved on every action even when not explicitly provided. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID + SessionID fallback | Billing.Deposit | Read | Reads SessionID when @SessionID is not provided by caller. See [Billing.Deposit](../Tables/Billing.Deposit.md). |
| @DepositID + MatchStatusID inherit | History.DepositAction | Read + Write (cross-schema) | Reads last MatchStatusID for the deposit, then INSERTs the new action. Cross-schema dependency on History. |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| Billing.DepositAdd | Stored Procedure | Called within transaction immediately after INSERT to Billing.Deposit to record the initial deposit action (PaymentActionStatusID=1, PaymentActionTypeID=2). |
| Deposit payment gateway handlers | External (App) | Called to record each payment processing step: authorization, capture, approval, rejection, refund, chargeback. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositActionAdd (procedure)
├── Billing.Deposit (table) [read - SessionID fallback]
└── History.DepositAction (table) [cross-schema, read + write]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Read WITH(NOLOCK) - inherits SessionID when not provided by caller |
| History.DepositAction | Table (cross-schema) | Read (last MatchStatusID for deposit) + Write (INSERT new action row) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.DepositAdd | Stored Procedure | Calls this as last step in the deposit creation transaction |
| Billing payment service | External (App) | Core call in deposit lifecycle state machine |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record a new deposit action (initial purchase)

```sql
DECLARE @ActionID INT;
EXEC Billing.DepositActionAdd
    @DepositActionID = @ActionID OUTPUT,
    @DepositID       = 12345678,
    @PaymentActionStatusID = 1,   -- New/Purchase
    @PaymentActionTypeID   = 2,   -- Purchase
    @PaymentStatusID       = 1,   -- Pending
    @ManagerID             = NULL,
    @ResponseID            = NULL,
    @AuthCode              = NULL,
    @ApprovalNumber        = NULL,
    @ExchangeRate          = 1.0;
SELECT @ActionID AS NewDepositActionID;
```

### 8.2 Record an approval action with auth code

```sql
DECLARE @ActionID INT;
EXEC Billing.DepositActionAdd
    @DepositActionID       = @ActionID OUTPUT,
    @DepositID             = 12345678,
    @PaymentActionStatusID = 1,
    @PaymentActionTypeID   = 2,
    @PaymentStatusID       = 2,       -- Approved
    @AuthCode              = 'XYZ123',
    @ApprovalNumber        = 'APP987654';
```

### 8.3 Review the full action history for a deposit

```sql
SELECT da.DepositActionID,
       da.DepositID,
       da.PaymentStatusID,
       da.PaymentActionTypeID,
       da.PaymentActionStatusID,
       da.ModificationDate,
       da.MatchStatusID,
       da.ManagerID,
       da.AuthCode,
       da.SessionID
FROM History.DepositAction da WITH (NOLOCK)
WHERE da.DepositID = 12345678
ORDER BY da.DepositActionID ASC;
```

### 8.4 Check the last MatchStatusID for a deposit (what DepositActionAdd will inherit)

```sql
SELECT TOP 1 MatchStatusID, DepositActionID, ModificationDate
FROM History.DepositAction WITH (NOLOCK)
WHERE DepositID = 12345678
ORDER BY DepositActionID DESC;
```

---

## 9. Atlassian Knowledge Sources

Confluence search found related pages ("Deposit Finalize Steps Refactor", "Deposit Finalize Steps Current", "Deposit Recovery Estimation" in MIMO Group space) but content was not accessible. These pages likely describe the full deposit lifecycle pipeline that `Billing.DepositActionAdd` participates in as the action-logging step.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 3 Confluence (not accessible) + 0 Jira | Procedures: 1 caller analyzed (DepositAdd) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositActionAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositActionAdd.sql*
