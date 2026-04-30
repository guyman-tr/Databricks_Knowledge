# BackOffice.WithdrawRequestSetCommission

> Sets the processing commission on an approved withdrawal via Billing.UpsertWithdraw; if the processed amount + commission equals the full request amount (within $1), auto-cancels all remaining unprocessed payout legs via Billing.UpdateWithdraw2Funding.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID - PK of Billing.Withdraw |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.WithdrawRequestSetCommission` is a post-approval operation that allows back-office managers to set or adjust the processing commission for a withdrawal that has been approved but not yet fully processed. Commission represents the platform fee taken from the gross withdrawal amount before the customer receives the remainder.

The SP enforces multiple business rules before allowing the change:
- The withdrawal must exist
- The withdrawal must already be approved (`Approved=1`)
- It must not be fully processed or cancelled (`CashoutStatusID NOT IN (3,4)`)
- The commission cannot exceed what remains after already-processed amounts (`Amount >= ProcessedAmount + Commission`)

When the commission is set such that the total processed amount plus commission equals the full withdrawal amount (within a $1 tolerance), the SP automatically cancels all remaining unprocessed `Billing.WithdrawToFunding` legs - signaling that all funds have been accounted for and no further processing is needed.

Like `WithdrawRequestApprove`, this SP was refactored in September 2021 (DBA-648) to use `Billing.UpsertWithdraw` and `Billing.UpdateWithdraw2Funding` instead of direct table updates.

---

## 2. Business Logic

### 2.1 Pre-Validation (4 Checks)

**Rules**:
1. `NOT EXISTS (Billing.Withdraw WHERE WithdrawID=@WithdrawID)`: RAISERROR(60025) - "request does not exist". Return 60025.
2. `NOT EXISTS (Billing.Withdraw WHERE WithdrawID=@WithdrawID AND Approved=1)`: RAISERROR(60025) - "request still not approved". Return 60025.
3. `EXISTS (Billing.Withdraw WHERE CashoutStatusID IN (3,4) AND WithdrawID=@WithdrawID)`: RAISERROR(60025) - "cashout status is not compatible". Return 60025.
4. `@RequestedAmount < @ProcessedAmount + @Commission`: RAISERROR(60025) - "too big commission". Return 60025.
   - `@ProcessedAmount` = SUM(Amount*ExchangeRate) from Billing.WithdrawToFunding WHERE CashoutStatusID=3 (processed legs)
   - `@RequestedAmount` = Amount from Billing.Withdraw

### 2.2 Commission Update via Billing.UpsertWithdraw

**What**: Sets Commission, ManagerID, Comment, and optionally SessionID on Billing.Withdraw.

**Rules**:
- Constructs @Info (Billing.TBL_Withdraw TVT) with: WithdrawID, Commission=@Commission, ManagerID=@ManagerID, Comment=@Comment, SessionID=@SessionID
- EXEC Billing.UpsertWithdraw @Info - delegates update + history write to billing procedure

### 2.3 Auto-Cancel Remaining Payout Legs (Conditional)

**What**: When the full withdrawal amount has been accounted for (processed + commission == requested within $1), automatically cancels all outstanding payout legs.

**Condition**: `ABS(@ProcessedAmount + @Commission - @RequestedAmount) <= 1.00`

**Rules**:
- Identifies Billing.WithdrawToFunding rows for this withdrawal where CashoutStatusID NOT IN (3,4) - unprocessed/non-cancelled legs
- Sets them to CashoutStatusID=4 (cancelled), ManagerID=@ManagerID, CashoutActionStatusID=2 (processed), Remark='Auto cancel, all money already passed'
- Executes via `Billing.UpdateWithdraw2Funding @InfoDetail` (TVT containing the rows to update)

This cleanup prevents "zombie" payout legs from remaining open after the funds are fully disbursed.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | int | NO | - | CODE-BACKED | The withdrawal to set commission on (maps to Billing.Withdraw.WithdrawID). Must exist and be approved (Approved=1) and not processed/cancelled (CashoutStatusID not 3 or 4). |
| 2 | @ManagerID | int | NO | - | CODE-BACKED | The manager setting the commission (maps to Billing.Withdraw.ManagerID via UpsertWithdraw). Also applied to any auto-cancelled payout legs. |
| 3 | @Commission | money | NO | - | CODE-BACKED | The processing commission amount in USD (maps to Billing.Withdraw.Commission). Cannot exceed Amount - AlreadyProcessedAmount. |
| 4 | @Comment | varchar(255) | NO | - | CODE-BACKED | Processing note for this commission change (maps to Billing.Withdraw.Comment via UpsertWithdraw). Max 255 chars. |
| 5 | @SessionID | bigint | YES | NULL | CODE-BACKED | Optional session identifier (maps to Billing.Withdraw.SessionID via UpsertWithdraw). NULL = no session tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.Withdraw | SELECT (validation + requested amount) | Pre-validation and amount lookup |
| @WithdrawID | Billing.WithdrawToFunding | SELECT (processed amount) | Computes already-processed amount for commission cap check |
| @WithdrawID | Billing.UpsertWithdraw | EXEC callee | Sets Commission + ManagerID + Comment on Billing.Withdraw |
| Unprocessed legs | Billing.UpdateWithdraw2Funding | EXEC callee (conditional) | Auto-cancels remaining payout legs when fully accounted for |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No direct callers found in BackOffice SPs. | - | - | Called from back-office withdrawal processing workflows. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.WithdrawRequestSetCommission (procedure)
+-- Billing.Withdraw (table) [SELECT: validation + amount + approved state]
+-- Billing.WithdrawToFunding (table) [SELECT: processed amount sum; UPDATE via callee]
+-- Billing.UpsertWithdraw (procedure) [EXEC: Commission/ManagerID/Comment update]
+-- Billing.UpdateWithdraw2Funding (procedure) [EXEC (conditional): auto-cancel payout legs]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | SELECT for validation and amount/approved/status checks |
| Billing.WithdrawToFunding | Table | SELECT for processed amount (CashoutStatusID=3 legs); also source for auto-cancel selection |
| Billing.UpsertWithdraw | Procedure | EXEC: updates Commission, ManagerID, Comment, SessionID on Billing.Withdraw |
| Billing.UpdateWithdraw2Funding | Procedure | EXEC (conditional): cancels remaining payout legs when fully accounted for |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo. | - | Called from withdrawal processing services. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- RAISERROR(60025) for all pre-validation failures.
- BEGIN/COMMIT TRANSACTION wraps all writes.
- TRY/CATCH: ROLLBACK on error + RAISERROR(60000) - old-style error code on CATCH.
- $1.00 tolerance for processed+commission == requested comparison handles floating-point currency rounding.
- CashoutStatusID meanings: 3=Processed, 4=Cancelled.
- CashoutActionStatusID=2 (Processed) is set on auto-cancelled legs for audit trail.

---

## 8. Sample Queries

### 8.1 Set commission on an approved withdrawal

```sql
DECLARE @ret INT;
EXEC @ret = BackOffice.WithdrawRequestSetCommission
    @WithdrawID  = 1234567,
    @ManagerID   = 99,
    @Commission  = 5.00,     -- $5 commission
    @Comment     = 'Standard wire transfer commission',
    @SessionID   = NULL;
SELECT @ret AS ReturnCode;   -- 0 = success
```

### 8.2 Check how much has already been processed for a withdrawal

```sql
SELECT
    w.WithdrawID,
    w.Amount AS RequestedAmount,
    w.Commission AS CurrentCommission,
    SUM(wtf.Amount * wtf.ExchangeRate) AS ProcessedAmount
FROM Billing.Withdraw w WITH (NOLOCK)
LEFT JOIN Billing.WithdrawToFunding wtf WITH (NOLOCK)
    ON wtf.WithdrawID = w.WithdrawID AND wtf.CashoutStatusID = 3
WHERE w.WithdrawID = 1234567
GROUP BY w.WithdrawID, w.Amount, w.Commission;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| DBA-648 | Jira | Refactored Billing.Withdraw and Billing.WithdrawToFunding updates to use procedures - September 2021 |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (DDL, Dependency Inheritance, Caller Scan, Code Analysis, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 1 Jira (from DDL comments) | Procedures: 2 callees analyzed (Billing.UpsertWithdraw, Billing.UpdateWithdraw2Funding) | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.WithdrawRequestSetCommission | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.WithdrawRequestSetCommission.sql*
