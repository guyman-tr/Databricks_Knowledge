# Billing.PayoutProcess_FinalizeRequest

> Finalizes an approved payout request by updating PayoutProcess to Processed status and executing the full payment disbursement to the customer's funding instrument via WithdrawToFundingProcess.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawToFundingID - the payout record being finalized |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PayoutProcess_FinalizeRequest` is the critical last-mile step in eToro's cashout (withdrawal) payout pipeline. Once a payout service worker has claimed a `Billing.PayoutProcess` record (InProcess=1), submitted it to the payment provider, and received approval, this procedure is called to finalize the outcome: it marks the PayoutProcess record as Processed (CashoutStatusID=3) and triggers the full downstream payment processing via `Billing.WithdrawToFundingProcess`.

The procedure handles two actor types: automated system execution (@ManagerID=0, which sets RequestExecuteEntryMethodId=1) and human manager execution (@ManagerID>0, which sets RequestExecuteEntryMethodId=2). This allows the audit trail to distinguish between system-driven payouts (the normal path) and manually-triggered finalizations.

Data flow: Payout service calls this procedure with the WithdrawToFundingID and the provider's external reference code. The procedure (1) looks up WithdrawID and FundingID from WithdrawToFunding, (2) marks the PayoutProcess record as Processed, (3) derives the execution entry method from ManagerID, and (4) delegates to WithdrawToFundingProcess for the actual payment execution - all within a single transaction with full error handling and deadlock-safe commit/rollback logic.

This v1 procedure supports the @CalculateFTP parameter to optionally trigger fee-to-provider calculations. For the new payout service that excludes FTP, see `Billing.PayoutProcess_FinalizeRequest_v2`.

---

## 2. Business Logic

### 2.1 PayoutProcess Status Update

**What**: Marks the payout record as successfully finalized before handing off to payment execution.

**Columns/Parameters Involved**: `@WithdrawToFundingID`, `@ExtReferenceCode`, `Billing.PayoutProcess.CashoutStatusID`, `Billing.PayoutProcess.InProcess`, `Billing.PayoutProcess.ExtReferenceCode`

**Rules**:
- Updates `Billing.PayoutProcess` WHERE WithdrawToFundingID = @WithdrawToFundingID AND CashoutStatusID NOT IN (3).
- The `NOT IN (3)` guard prevents double-processing: if the record is already Processed (status=3), the UPDATE is a no-op.
- Sets CashoutStatusID = 3 (Processed), ExtReferenceCode = @ExtReferenceCode, InProcess = 0.
- InProcess reset to 0 releases the worker's claim on the record.

### 2.2 Execution Actor Classification

**What**: Determines whether the finalization was triggered by the automated system or a human manager, for audit trail purposes.

**Columns/Parameters Involved**: `@ManagerID`, `@RequestExecuteEntryMethodId`

**Rules**:
- IF @ManagerID = 0: @RequestExecuteEntryMethodId = 1 (system/automated execution).
- ELSE (ManagerID > 0): @RequestExecuteEntryMethodId = 2 (human manager execution).
- This value is passed to `Billing.WithdrawToFundingProcess` to tag the execution method in downstream records.
- Added Dec 2024 by Data Rostiashvili.

### 2.3 VerificationCode Fallback

**What**: Ensures a VerificationCode is always passed to the payment process even if not explicitly provided.

**Columns/Parameters Involved**: `@VerificationCode`, `@ExtReferenceCode`

**Rules**:
- @VerificationCode defaults to NULL. If not supplied, it falls back to @ExtReferenceCode: `SELECT @VerificationCode = ISNULL(@VerificationCode, @ExtReferenceCode)`.
- This means the external provider reference code doubles as the verification code when no separate verification token is passed.
- @VerificationCode was added Feb 2022 (PAYI-6071).

### 2.4 Transaction Safety and Deadlock Handling

**What**: Wraps all operations in a transaction with proper TRY/CATCH for deadlock safety.

**Rules**:
- BEGIN TRAN wraps the PayoutProcess UPDATE and the WithdrawToFundingProcess EXEC.
- On success: COMMIT.
- On exception: IF @@TranCount = 1 -> ROLLBACK (we opened the transaction). IF @@TranCount > 1 -> COMMIT (nested transaction context - avoid double rollback).
- THROW re-raises the exception to the caller.
- This transaction pattern was refined through multiple deadlock incidents in 2017 (tickets 45223 and 47478) and further fixed in 2018 by Ran Ovadia.

**Diagram**:
```
BEGIN TRAN
  |
  SELECT @WithdrawID, @FundingID FROM WithdrawToFunding WHERE ID=@WithdrawToFundingID
  |
  UPDATE PayoutProcess SET CashoutStatusID=3, ExtReferenceCode=@ExtReferenceCode, InProcess=0
  WHERE WithdrawToFundingID=@WithdrawToFundingID AND CashoutStatusID NOT IN (3)
  |
  EXEC WithdrawToFundingProcess(@WithdrawID, @FundingID, @ManagerID, @Remark, ...)
  |
  COMMIT
  |
  [On error: @@TranCount=1 -> ROLLBACK, else COMMIT, then THROW]
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawToFundingID | int | NO | - | CODE-BACKED | The payout record identifier. References `Billing.WithdrawToFunding.ID` and `Billing.PayoutProcess.WithdrawToFundingID`. Used to look up the WithdrawID and FundingID, and to target the PayoutProcess update. |
| 2 | @Remark | varchar(255) | YES | NULL | CODE-BACKED | Free-text remark passed through to `Billing.WithdrawToFundingProcess`. Used for audit and reconciliation notes. NULL if not provided. |
| 3 | @ManagerID | int | NO | - | VERIFIED | The actor initiating finalization. 0 = system/automated payout service. >0 = back-office manager ID. Controls @RequestExecuteEntryMethodId: 0->1 (system), >0->2 (human). Passed to `WithdrawToFundingProcess` for downstream audit trail. |
| 4 | @ExtReferenceCode | varchar(50) | NO | - | CODE-BACKED | External payment provider's transaction reference code. Stored in `Billing.PayoutProcess.ExtReferenceCode` on update. Also used as fallback value for @VerificationCode if that parameter is NULL. Used for reconciliation and dispute resolution with the payment provider. |
| 5 | @CalculateFTP | bit | YES | NULL | CODE-BACKED | Optional flag controlling whether fee-to-provider (FTP) calculations should run inside `Billing.WithdrawToFundingProcess`. NULL = default behavior. This parameter distinguishes v1 from v2 of this procedure (v2 does not have this parameter and always skips FTP). |
| 6 | @VerificationCode | varchar(50) | YES | NULL | VERIFIED | Verification token for the payment transaction. Added Feb 2022 (PAYI-6071). If NULL, falls back to @ExtReferenceCode value (`ISNULL(@VerificationCode, @ExtReferenceCode)`). Passed to `Billing.WithdrawToFundingProcess` as part of payment verification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawToFundingID | [Billing.WithdrawToFunding](../Tables/Billing.WithdrawToFunding.md) | Read (SELECT) | Looks up WithdrawID and FundingID for the WithdrawToFundingID to pass to WithdrawToFundingProcess. |
| @WithdrawToFundingID | [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | Write (UPDATE) | Sets CashoutStatusID=3, ExtReferenceCode, InProcess=0 for the payout record. Guard: only if not already CashoutStatusID=3. |
| @WithdrawID, @FundingID, ... | Billing.WithdrawToFundingProcess | EXEC (callee) | Delegates full payment disbursement - handles Billing.Withdraw status update, payment provider submission, and WithdrawToFunding finalization. Pending documentation (future batch). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PayoutUser (db role) | - | EXEC | Payout service application user - calls this to finalize approved payouts. |
| SQL_SecurePay (db role) | - | EXEC | SecurePay payment provider integration - calls this to finalize SecurePay payouts. |
| [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | WithdrawToFundingID | Referenced By | PayoutProcess.md documents this procedure as the UPDATE writer for CashoutStatusID=3 finalization. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PayoutProcess_FinalizeRequest (procedure)
├── Billing.WithdrawToFunding (table) - lookup for WithdrawID/FundingID
├── Billing.PayoutProcess (table) - update to CashoutStatusID=3
└── Billing.WithdrawToFundingProcess (procedure) - actual payment processing
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.WithdrawToFunding](../Tables/Billing.WithdrawToFunding.md) | Table | SELECT - looks up WithdrawID and FundingID by ID=@WithdrawToFundingID. |
| [Billing.PayoutProcess](../Tables/Billing.PayoutProcess.md) | Table | UPDATE - sets CashoutStatusID=3, ExtReferenceCode, InProcess=0 for the payout record. |
| Billing.WithdrawToFundingProcess | Stored Procedure | EXEC - full payment execution. Pending documentation (future batch). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PayoutUser application role | Application | Payout service calls this to finalize approved payouts. |
| SQL_SecurePay application role | Application | SecurePay provider integration calls this. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

The PayoutProcess UPDATE targets `WHERE WithdrawToFundingID = @WithdrawToFundingID` - this hits the UNIQUE NC index `IX_BillingPayoutProcess_WithdrawToFundingID` directly (single-seek). The `NOT IN (3)` guard adds a small overhead but prevents double-processing safely.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Finalize a payout as the automated payout service

```sql
-- System-driven (ManagerID=0): sets RequestExecuteEntryMethodId=1
EXEC Billing.PayoutProcess_FinalizeRequest
    @WithdrawToFundingID = 12345678,
    @ManagerID           = 0,
    @ExtReferenceCode    = 'PROVREF-ABC123',
    @Remark              = NULL,
    @CalculateFTP        = NULL,
    @VerificationCode    = NULL;
```

### 8.2 Finalize a payout as a back-office manager

```sql
-- Human manager (ManagerID>0): sets RequestExecuteEntryMethodId=2
EXEC Billing.PayoutProcess_FinalizeRequest
    @WithdrawToFundingID = 12345678,
    @ManagerID           = 999,
    @ExtReferenceCode    = 'PROVREF-DEF456',
    @Remark              = 'Manual finalization approved by compliance',
    @CalculateFTP        = 1,
    @VerificationCode    = 'VERIF-XYZ789';
```

### 8.3 Preview PayoutProcess records ready for finalization

```sql
SELECT
    pp.ProcessID,
    pp.WithdrawToFundingID,
    pp.CashoutStatusID,
    cs.Name AS StatusName,
    pp.InProcess,
    pp.ManagerID,
    pp.InProcessDate
FROM Billing.PayoutProcess pp WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON cs.CashoutStatusID = pp.CashoutStatusID
WHERE pp.CashoutStatusID IN (9, 10)  -- PendingByProvider, SentToProvider
  AND pp.InProcess = 0
ORDER BY pp.InProcessDate;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Payout Service Recovery Design | Confluence | Referenced in search - describes payout service architecture and recovery patterns. Page content not retrievable via API. |
| Payout Design | Confluence | Referenced in search - describes payout service flow design. Page content not retrievable via API. |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 applicable*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 callee (WithdrawToFundingProcess) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PayoutProcess_FinalizeRequest | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PayoutProcess_FinalizeRequest.sql*
