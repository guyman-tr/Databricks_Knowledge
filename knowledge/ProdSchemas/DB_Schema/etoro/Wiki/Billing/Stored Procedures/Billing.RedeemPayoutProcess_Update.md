# Billing.RedeemPayoutProcess_Update

> Atomic transactional wrapper that finalizes a redeem payout processing step by updating the redeem status and the associated funding payment status in a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProcessID + @RedeemID + @PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When the redeem payout processor completes a processing step (e.g., a position has been closed or units transferred), two separate subsystems must be updated atomically: the redeem lifecycle record and the withdraw-to-funding payment record. `Billing.RedeemPayoutProcess_Update` is the top-level orchestrator that combines both updates in a single BEGIN TRAN / COMMIT block so they never diverge.

The procedure delegates to two specialized sub-procedures: `Billing.RedeemPayoutProcess_UpdateStatus` handles releasing the processing lock and advancing the redeem status (see that proc's docs for lock/state-machine logic), while `Billing.WithdrawToFundingChangePaymentStatus` transitions the cashout payment status on the `Billing.WithdrawToFunding` record (e.g., moving it to SentToBilling). If either call fails, both are rolled back.

This procedure is the entry point called by the Redeem Service at the end of each processing phase. The calling service identifies which phase completed via `@RedeemProcessType` - NULL means a status-only update with no lock to release; 1 = close-position phase complete; 2 = transfer-units phase complete.

Note: `@PositionID` was changed from INT to BIGINT on 20/06/2021 to support large position IDs.

---

## 2. Business Logic

### 2.1 Two-Phase Atomic Finalization

**What**: A single BEGIN TRAN ensures that both the redeem status advance and the funding payment status update are committed together or rolled back together.

**Columns/Parameters Involved**: `@ProcessID`, `@RedeemID`, `@PositionID`, `@RedeemStatusID`, `@RedeemReasonID`, `@RedeemProcessType`, `@CorrelationID`, `@WithdrawToFundingID`, `@CashoutStatusID`

**Rules**:
- Step 1: `Billing.RedeemPayoutProcess_UpdateStatus` is called with the redeem-side parameters. If `@RedeemProcessType IS NOT NULL`, it also releases the processing lock before updating status.
- Step 2: `Billing.WithdrawToFundingChangePaymentStatus` is called with the funding-side parameters to transition the cashout status.
- Both steps must succeed. If either raises, the CATCH block rolls back (when @@TRANCOUNT = 1) or commits outer transaction (when nested via @@TRANCOUNT > 1), then re-throws.
- `@WithdrawToFundingChangePaymentStatus` validates that the funding record is in an InProcess status (2, 8, 9, 10, 11, 12) before allowing the update. Status 11 (SentToBilling) cannot be set twice.

**Diagram**:
```
BEGIN TRAN
  EXEC RedeemPayoutProcess_UpdateStatus
       @ProcessID, @RedeemID, @PositionID, @RedeemStatusID,
       @RedeemReasonID, @RedeemProcessType, @CorrelationID
       --> IF @RedeemProcessType NOT NULL: releases lock on RedeemPayoutProcess
       --> Always: advances Redeem status via RedeemStatusUpdate

  EXEC WithdrawToFundingChangePaymentStatus
       @WithdrawToFundingID, @ManagerID, @Remark, @CashoutStatusID
       --> Validates InProcess status; updates WithdrawToFunding
COMMIT
  (CATCH: ROLLBACK if @@TRANCOUNT=1, re-THROW)
```

### 2.2 Processing Lock Release (via Delegation)

**What**: The @RedeemProcessType parameter controls whether a processing lock is released as part of this update.

**Columns/Parameters Involved**: `@RedeemProcessType`, `@ProcessID`, `@CorrelationID`

**Rules**:
- NULL: no lock release - only the redeem status is updated (status-only path, used for intermediate status transitions)
- 1: close-position lock (`InClosePositionProcess` flag) is cleared via `RedeemPayoutProcess_Abort`
- 2: transfer-units lock (`InTransferUnitsProcess` flag) is cleared via `RedeemPayoutProcess_Abort`
- The `@CorrelationID` (GUID, 36 chars) is passed to `RedeemPayoutProcess_Abort` to validate that the lock being released was set by the same processing invocation. Prevents race conditions where a newer process acquires the lock before the abort call.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProcessID | INT | NO | - | CODE-BACKED | Primary key of the `Billing.RedeemPayoutProcess` record representing the in-progress processing slot. Passed to `RedeemPayoutProcess_UpdateStatus` to identify which lock to release. |
| 2 | @RedeemID | INT | NO | - | CODE-BACKED | FK to `Billing.Redeem.ID`. Identifies the redeem request being finalized. Passed to `RedeemStatusUpdate` (via UpdateStatus) to advance the redeem's state machine. |
| 3 | @PositionID | BIGINT | NO | - | CODE-BACKED | FK to the trading position associated with this redeem. Changed from INT to BIGINT (20/06/2021) to support large position IDs. Used by `RedeemStatusUpdate` to locate the correct redeem record (RedeemID + PositionID together uniquely identify a redeem step). |
| 4 | @RedeemStatusID | INT | YES | NULL | CODE-BACKED | Target redeem status to set after this processing step. Passed to `RedeemStatusUpdate`. NULL means no status change is applied (lock release only). Typical values: 6 = PositionClosed, 8 = completed terminal state. Lookup: `Billing.RedeemStatus` (see `Billing.RedeemPayoutProcess_UpdateStatus`). |
| 5 | @RedeemReasonID | INT | YES | NULL | CODE-BACKED | Optional reason code accompanying the status transition. Passed to `RedeemStatusUpdate`. NULL when the transition has no specific reason. Lookup: `Billing.RedeemReason`. |
| 6 | @WithdrawToFundingID | INT | NO | - | CODE-BACKED | FK to `Billing.WithdrawToFunding.ID`. Identifies the withdraw-to-funding record whose cashout payment status will be updated by `WithdrawToFundingChangePaymentStatus`. |
| 7 | @ManagerID | INT | NO | - | CODE-BACKED | ID of the operator or service account performing the update. Passed to `WithdrawToFundingChangePaymentStatus`. -1 indicates the billing service (automated); non-(-1) values are stored on the WithdrawToFunding record. |
| 8 | @Remark | VARCHAR(255) | NO | - | CODE-BACKED | Free-text audit remark describing the reason for the payment status change. Stored on the WithdrawToFunding record via `WithdrawToFundingChangePaymentStatus`. |
| 9 | @CashoutStatusID | INT | NO | - | CODE-BACKED | Target cashout status to set on the `Billing.WithdrawToFunding` record. Must transition from a valid InProcess status (2, 8, 9, 10, 11, 12). 11 = SentToBilling (cannot be set twice). Lookup: `Billing.CashoutStatus`. |
| 10 | @RedeemProcessType | INT | YES | NULL | CODE-BACKED | Controls lock release in `RedeemPayoutProcess_UpdateStatus`: NULL = no lock to release (status-only update); 1 = close-position phase completed (releases InClosePositionProcess lock); 2 = transfer-units phase completed (releases InTransferUnitsProcess lock). |
| 11 | @CorrelationID | VARCHAR(36) | YES | NULL | CODE-BACKED | GUID correlation token passed to `RedeemPayoutProcess_Abort` to validate that the lock being released was acquired by the same invocation. Prevents race conditions when a newer processing job acquires the slot before the abort fires. NULL when @RedeemProcessType is NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProcessID | Billing.RedeemPayoutProcess | Lookup | Identifies the payout processing slot to finalize/release |
| @RedeemID | Billing.Redeem | Lookup | Identifies the redeem request whose status is being advanced |
| @PositionID | Trade.PositionTbl (cross-schema) | Lookup | Trading position associated with the redeem |
| @WithdrawToFundingID | Billing.WithdrawToFunding | Lookup | Withdraw-to-funding record whose cashout status is updated |
| (delegated) | Billing.RedeemPayoutProcess_UpdateStatus | EXEC | Handles lock release + redeem status advance |
| (delegated) | Billing.WithdrawToFundingChangePaymentStatus | EXEC | Handles cashout payment status transition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RedeemServiceUser permission grant | - | GRANT EXECUTE | Reachable from RedeemServiceUser (etoro\UsersPermissions\RedeemServiceUser.sql) |
| SQL_SecurePay permission grant | - | GRANT EXECUTE | Reachable from SQL_SecurePay role (etoro\UsersPermissions\SQL_SecurePay.sql) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RedeemPayoutProcess_Update (procedure)
├── Billing.RedeemPayoutProcess_UpdateStatus (procedure)
│     ├── Billing.RedeemPayoutProcess_Abort (procedure)
│     │     └── Billing.RedeemPayoutProcess (table)
│     └── Billing.RedeemStatusUpdate (procedure)
│           └── Billing.Redeem (table)
└── Billing.WithdrawToFundingChangePaymentStatus (procedure)
      └── Billing.WithdrawToFunding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.RedeemPayoutProcess_UpdateStatus | Stored Procedure | EXEC - called first to release lock and update redeem status |
| Billing.WithdrawToFundingChangePaymentStatus | Stored Procedure | EXEC - called second to update cashout payment status on WithdrawToFunding |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RedeemServiceUser (permission grant) | Security | GRANT EXECUTE - Redeem Service calls this procedure |
| SQL_SecurePay (permission grant) | Security | GRANT EXECUTE - payment processing role |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Business validation (delegated) | RAISERROR | `WithdrawToFundingChangePaymentStatus` raises error 60000 if WithdrawToFunding is not in InProcess status (2,8,9,10,11,12) |
| Business validation (delegated) | RAISERROR | `WithdrawToFundingChangePaymentStatus` raises error if CashoutStatusID=11 (SentToBilling) is applied to a record already in status 11 |
| Transaction integrity | TRY/CATCH | ROLLBACK when @@TRANCOUNT=1 on error; outer-transaction-safe (COMMIT when @@TRANCOUNT>1); THROW re-propagates |

---

## 8. Sample Queries

### 8.1 Execute a redeem payout completion (close-position phase)
```sql
-- Finalize a redeem after position close completes
EXEC Billing.RedeemPayoutProcess_Update
    @ProcessID            = 100001,
    @RedeemID             = 55001,
    @PositionID           = 9876543210,
    @RedeemStatusID       = 6,           -- PositionClosed
    @RedeemReasonID       = NULL,
    @WithdrawToFundingID  = 44001,
    @ManagerID            = -1,          -- billing service
    @Remark               = 'RedeemPayout close-position phase complete',
    @CashoutStatusID      = 11,          -- SentToBilling
    @RedeemProcessType    = 1,           -- release InClosePositionProcess lock
    @CorrelationID        = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
```

### 8.2 Status-only update (no lock release)
```sql
-- Update redeem status without releasing a processing lock
EXEC Billing.RedeemPayoutProcess_Update
    @ProcessID            = 100002,
    @RedeemID             = 55002,
    @PositionID           = 9876543211,
    @RedeemStatusID       = 3,           -- intermediate status
    @RedeemReasonID       = NULL,
    @WithdrawToFundingID  = 44002,
    @ManagerID            = 9001,        -- human operator
    @Remark               = 'Manual status correction',
    @CashoutStatusID      = 9,           -- InProcess
    @RedeemProcessType    = NULL,        -- no lock release
    @CorrelationID        = NULL;
```

### 8.3 Check the current state of a redeem and its associated funding record
```sql
SELECT
    r.ID            AS RedeemID,
    r.PositionID,
    r.RedeemStatusID,
    rs.Name         AS RedeemStatus,
    wtf.ID          AS WithdrawToFundingID,
    wtf.CashoutStatusID,
    rpp.ProcessID,
    rpp.CorrelationID
FROM Billing.Redeem r WITH (NOLOCK)
JOIN Billing.WithdrawToFunding wtf WITH (NOLOCK)
    ON wtf.WithdrawID = r.WithdrawID
LEFT JOIN Billing.RedeemPayoutProcess rpp WITH (NOLOCK)
    ON rpp.RedeemID = r.ID
LEFT JOIN Billing.RedeemStatus rs WITH (NOLOCK)
    ON rs.ID = r.RedeemStatusID
WHERE r.ID = 55001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.RedeemPayoutProcess_Update | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.RedeemPayoutProcess_Update.sql*
