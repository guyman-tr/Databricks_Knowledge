# Billing.WithdrawAndWithdrawToFundingAdd

> Orchestrates the full Redeem-to-WTF pipeline: checks idempotency, creates a Withdrawal via WithdrawalService_WithdrawRequestAdd (outside transaction), then in a single high-priority transaction: auto-approves the withdrawal, creates the WTF leg, advances it to InProcess and status 12, and links it back to the Redeem record.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RedeemID INT - the Redeem record to convert to a WTF leg |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the orchestration entry point for converting a `Billing.Redeem` record into a live WithdrawToFunding (WTF) payment leg. In eToro's billing model, a Redeem represents a redemption event where an existing credit or balance needs to be converted into an outgoing payment. This procedure transforms that intent into a concrete withdrawal + WTF leg, ready for processing by the Cashout Service.

The procedure creates a complete withdrawal lifecycle from scratch:
1. Creates a `Billing.Withdraw` record via `WithdrawalService_WithdrawRequestAdd`
2. Auto-approves it through the back-office risk approval system (no manual review)
3. Creates the `Billing.WithdrawToFunding` payment leg
4. Sets routing metadata (depot, XML data, execution method)
5. Advances the WTF through Pending -> InProcess -> status 12 (Payment Submitted)
6. Links the WTF back to the originating `Billing.Redeem` record

The `@CashoutReasonID=18` is hardcoded - this reason code identifies this withdrawal as a Redeem conversion. The withdrawal is auto-approved with `BackOffice.WithdrawApprovalAdd (UserGroupID=3=Risk, @WithdrawApprovalReasonID=7, @Approved=1)` because the Redeem approval was already obtained upstream.

**Critical architectural note**: `WithdrawalService_WithdrawRequestAdd` is called **outside** the transaction. This was changed in January 2021 (Shay Oren) because `History.ActiveCredit` uses an in-memory OLTP table, which cannot participate in a containing transaction. The implication is that if the transaction fails after the withdrawal is created, the `Billing.Withdraw` record exists but no WTF leg is linked - the idempotency check on the Redeem prevents duplicate withdrawals on retry.

**Idempotency**: The first guard checks if `Billing.Redeem.WithdrawToFundingID IS NOT NULL` - if the Redeem already has a WTF linked, the existing ID is returned immediately without creating any new records.

---

## 2. Business Logic

### 2.1 Idempotency Guard

**What**: Prevents duplicate withdrawal creation if the Redeem was already processed.

**Columns/Parameters Involved**: `Billing.Redeem.RedeemID`, `Billing.Redeem.WithdrawToFundingID`, `@WithdrawToFundingID OUTPUT`

**Rules**:
- `IF EXISTS (SELECT * FROM Billing.Redeem WHERE RedeemID=@RedeemID AND WithdrawToFundingID IS NOT NULL)` -> read existing ID and return
- `SELECT @WithdrawToFundingID = WithdrawToFundingID FROM Billing.Redeem WHERE RedeemID=@RedeemID`
- `RETURN` immediately - no new records created
- This handles the case where the SP is called twice (e.g., due to retry after a network timeout)

### 2.2 Withdrawal Creation (Outside Transaction)

**What**: Creates the parent Billing.Withdraw record.

**Columns/Parameters Involved**: `@OutWithdrawID OUTPUT`, `@CashoutReasonID=18`

**Rules**:
- Calls `Billing.WithdrawalService_WithdrawRequestAdd` with all input parameters + `@CashoutReasonID=18` (Redeem reason)
- `@Description=@Remark` (maps the Remark parameter to the Description/Comment field)
- Receives `@OutWithdrawID OUTPUT` for use in subsequent steps
- Called OUTSIDE the transaction because `History.ActiveCredit` is an in-memory OLTP table that cannot participate in containing transactions
- If this call fails: no records were created, retry is safe via idempotency guard (Redeem.WithdrawToFundingID still NULL)

### 2.3 Auto-Approval

**What**: Programmatically approves the withdrawal through the risk approval workflow.

**Columns/Parameters Involved**: `BackOffice.WithdrawApprovalAdd`, `BackOffice.WithdrawRequestApprove`

**Rules**:
- `BackOffice.WithdrawApprovalAdd @WithdrawID=@OutWithdrawID, @UserGroupID=3 (Risk), @ManagerID, @WithdrawApprovalReasonID=7, @Approved=1, @Comment=@Remark`
- `BackOffice.WithdrawRequestApprove @OutWithdrawID` - processes the approval to advance Withdraw to approved state
- `SET DEADLOCK_PRIORITY HIGH` prevents this transaction from being chosen as deadlock victim
- These calls are inside the transaction

### 2.4 WTF Leg Creation and Initialization

**What**: Creates the WithdrawToFunding leg and initializes routing metadata.

**Columns/Parameters Involved**: `@AmountW2FInCents`, `@AmountW2FInUSD`, `DepotID`, `WithdrawData`, `RequestExecuteEntryMethodId`

**Rules**:
- `@AmountW2FInCents = @RequestedAmountInCents - @CashoutFeeInCents` (net amount for the WTF)
- `@AmountW2FInUSD = CAST(@AmountW2FInCents AS Money)/100`
- `Billing.WithdrawToFundingAdd` creates the WTF record, outputs `@OutWithdrawToFundingID`
- Post-creation update via TVP (`@WTFInfo`):
  - `DepotID = @DepotID` (routing target)
  - `WithdrawData` = minimal XML skeleton: `<Withdraw xmlns:xsd=... xmlns:xsi=... />`
  - `RequestExecuteEntryMethodId = CASE WHEN @ManagerID=0 THEN 1 (Auto Execute) ELSE 2 (Manual Execute) END`
- ManagerID=0 = automated/system trigger; ManagerID!=0 = back-office manual action

### 2.5 WTF Status Advancement

**What**: Advances the new WTF leg through the initial workflow states.

**Columns/Parameters Involved**: `CashoutStatusID` progression: Pending(1) -> InProcess(2) -> 12

**Rules**:
- `Billing.WithdrawToFundingToInProcess @ID=@OutWithdrawToFundingID, @ManagerID, @Remark` - Pending -> InProcess
- `Billing.WithdrawToFundingChangePaymentStatus @ID=@OutWithdrawToFundingID, @ManagerID, @Remark, @CashoutStatusID=12` - InProcess -> status 12
- Status 12 likely = "Payment Submitted" or "Sent to Provider" (the WTF is immediately handed off to the payment flow)

### 2.6 Redeem Linkage

**What**: Records the created WTF ID on the originating Redeem record, completing the idempotency gate.

**Columns/Parameters Involved**: `Billing.Redeem.WithdrawToFundingID`

**Rules**:
- `UPDATE Billing.Redeem SET WithdrawToFundingID=@OutWithdrawToFundingID WHERE RedeemID=@RedeemID`
- This is the final write inside the transaction - once committed, future calls hit the idempotency guard
- `SELECT @WithdrawToFundingID=@OutWithdrawToFundingID` sets the OUTPUT parameter

**Full Execution Diagram**:
```
GUARD: Billing.Redeem.WithdrawToFundingID IS NOT NULL?
  YES -> return existing @WithdrawToFundingID (idempotent)
  NO -> continue

-- OUTSIDE TRANSACTION (in-memory OLTP constraint):
EXEC WithdrawalService_WithdrawRequestAdd
  @CashoutReasonID=18, ...
  -> @OutWithdrawID (new Billing.Withdraw.WithdrawID)

-- INSIDE TRANSACTION (DEADLOCK_PRIORITY HIGH):
EXEC BackOffice.WithdrawApprovalAdd
  @WithdrawID=@OutWithdrawID, @UserGroupID=3(risk), @Approved=1, reason=7

EXEC BackOffice.WithdrawRequestApprove @OutWithdrawID

@AmountW2FInCents = @RequestedAmountInCents - @CashoutFeeInCents
@AmountW2FInUSD = @AmountW2FInCents / 100

EXEC Billing.WithdrawToFundingAdd
  -> @OutWithdrawToFundingID (new WTF record, Pending status)

UPDATE WTF via @WTFInfo TVP:
  DepotID, WithdrawData (empty XML), RequestExecuteEntryMethodId (1=auto, 2=manual)

EXEC WithdrawToFundingToInProcess @OutWithdrawToFundingID  (Pending -> InProcess)
EXEC WithdrawToFundingChangePaymentStatus @OutWithdrawToFundingID, CashoutStatusID=12

UPDATE Billing.Redeem SET WithdrawToFundingID = @OutWithdrawToFundingID
COMMIT

@WithdrawToFundingID OUTPUT = @OutWithdrawToFundingID
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RedeemID | int | NO | - | CODE-BACKED | Input parameter. `Billing.Redeem.RedeemID` - the redemption event to convert to a WTF payment leg. Used in idempotency guard and final Redeem linkage update. |
| 2 | @CashoutStatusID | integer | NO | - | CODE-BACKED | Input parameter. Initial cashout status for the new `Billing.Withdraw` record. Passed to `WithdrawalService_WithdrawRequestAdd`. |
| 3 | @FundingTypeID | integer | NO | - | CODE-BACKED | Input parameter. Payment method type. Passed to `WithdrawalService_WithdrawRequestAdd` and used to identify the payment instrument category. |
| 4 | @CurrencyID | integer | NO | - | CODE-BACKED | Input parameter. Currency for the withdrawal. Passed as both `@CurrencyID` to `WithdrawRequestAdd` and as `@ProcessCurrencyID` to `WithdrawToFundingAdd`. |
| 5 | @CID | integer | NO | - | CODE-BACKED | Input parameter. Customer identifier. Passed to `WithdrawalService_WithdrawRequestAdd`. |
| 6 | @RequestDate | datetime | NO | - | CODE-BACKED | Input parameter. Withdrawal request timestamp. Written to `Billing.Withdraw.RequestDate` via `WithdrawalService_WithdrawRequestAdd`. |
| 7 | @RequestedAmountInCents | integer | NO | - | CODE-BACKED | Input parameter. Gross withdrawal amount in cents. Used to compute net WTF amount: `@RequestedAmountInCents - @CashoutFeeInCents`. Passed to `WithdrawalService_WithdrawRequestAdd`. |
| 8 | @CashoutFeeInCents | integer | NO | - | CODE-BACKED | Input parameter. Cashout fee in cents. Subtracted from @RequestedAmountInCents to compute the net WTF amount. Passed to `WithdrawalService_WithdrawRequestAdd`. |
| 9 | @IPAddress | numeric | NO | - | CODE-BACKED | Input parameter. Customer IP address (stored as numeric). Passed to `WithdrawalService_WithdrawRequestAdd`. |
| 10 | @ManagerID | integer | YES | NULL | CODE-BACKED | Input parameter. Manager initiating the operation. 0=automated/system trigger (sets RequestExecuteEntryMethodId=1); non-zero=manual (sets RequestExecuteEntryMethodId=2). Used throughout as manager context. |
| 11 | @FundingID | integer | YES | NULL | CODE-BACKED | Input parameter. Optional funding record ID. Passed to both `WithdrawalService_WithdrawRequestAdd` and `WithdrawToFundingAdd`. |
| 12 | @Remark | varchar(max) | YES | NULL | CODE-BACKED | Input parameter. Description/comment for the operation. Passed as `@Description` to `WithdrawalService_WithdrawRequestAdd` and as `@Comment` to `WithdrawApprovalAdd`. Also used as `@Remark` in status transitions. |
| 13 | @DepotID | int | NO | - | CODE-BACKED | Input parameter. Routing depot assignment for the WTF leg. Set on the WTF record via `UpdateWithdraw2Funding` after `WithdrawToFundingAdd`. |
| 14 | @WithdrawToFundingID | int | NO | - (OUTPUT) | CODE-BACKED | Output parameter. The `Billing.WithdrawToFunding.ID` of the created (or pre-existing) WTF leg. Callers use this to track the payment leg for the Redeem. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (Guard) | Billing.Redeem | Read + Write | Idempotency check (read WithdrawToFundingID) + final linkage (update WithdrawToFundingID) |
| (EXEC) | Billing.WithdrawalService_WithdrawRequestAdd | Procedure call | Creates Billing.Withdraw record; called outside transaction |
| (EXEC) | BackOffice.WithdrawApprovalAdd | Procedure call | Creates risk approval record (UserGroupID=3, auto-approved) |
| (EXEC) | BackOffice.WithdrawRequestApprove | Procedure call | Processes the approval, advances Withdraw state |
| (EXEC) | Billing.WithdrawToFundingAdd | Procedure call | Creates the WTF payment leg |
| (EXEC) | Billing.UpdateWithdraw2Funding | Procedure call | Sets DepotID, WithdrawData, RequestExecuteEntryMethodId on WTF |
| (EXEC) | Billing.WithdrawToFundingToInProcess | Procedure call | Advances WTF from Pending to InProcess |
| (EXEC) | Billing.WithdrawToFundingChangePaymentStatus | Procedure call | Advances WTF to status 12 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from application code (Redeem processing flow).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawAndWithdrawToFundingAdd (procedure)
|- Billing.Redeem (table) -- idempotency + linkage
+-- Billing.WithdrawalService_WithdrawRequestAdd (procedure) -- create Withdraw [outside txn]
+-- BackOffice.WithdrawApprovalAdd (procedure) -- auto-approve
+-- BackOffice.WithdrawRequestApprove (procedure) -- process approval
+-- Billing.WithdrawToFundingAdd (procedure) -- create WTF leg
+-- Billing.UpdateWithdraw2Funding (procedure) -- set routing metadata
+-- Billing.WithdrawToFundingToInProcess (procedure) -- status: Pending -> InProcess
+-- Billing.WithdrawToFundingChangePaymentStatus (procedure) -- status: InProcess -> 12
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | Idempotency guard (read WithdrawToFundingID) + final linkage update |
| Billing.WithdrawalService_WithdrawRequestAdd | Stored Procedure | Creates Billing.Withdraw record (outside transaction, @CashoutReasonID=18) |
| BackOffice.WithdrawApprovalAdd | Stored Procedure | Adds risk approval (UserGroupID=3, auto-approved, reason 7) |
| BackOffice.WithdrawRequestApprove | Stored Procedure | Processes the approval to advance Withdraw state |
| Billing.WithdrawToFundingAdd | Stored Procedure | Creates the WTF payment leg |
| Billing.UpdateWithdraw2Funding | Stored Procedure | Updates DepotID, WithdrawData, RequestExecuteEntryMethodId on WTF |
| Billing.WithdrawToFundingToInProcess | Stored Procedure | Advances WTF from Pending to InProcess |
| Billing.WithdrawToFundingChangePaymentStatus | Stored Procedure | Advances WTF to status 12 |

### 6.2 Objects That Depend On This

No SQL callers found in SSDT repo. Called from application code (Redeem/Cashout Service).

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute for a Redeem-to-WTF conversion

```sql
DECLARE @WTF_ID INT;

EXEC Billing.WithdrawAndWithdrawToFundingAdd
    @RedeemID             = 55555,
    @CashoutStatusID      = 2,
    @FundingTypeID        = 1,
    @CurrencyID           = 1,       -- USD
    @CID                  = 12345,
    @RequestDate          = '2026-03-18T10:00:00',
    @RequestedAmountInCents = 10000, -- $100.00
    @CashoutFeeInCents    = 500,     -- $5.00 fee
    @IPAddress            = 0,
    @ManagerID            = 0,       -- automated
    @FundingID            = 67890,
    @Remark               = 'Auto Approval',
    @DepotID              = 5,
    @WithdrawToFundingID  = @WTF_ID OUTPUT;

SELECT @WTF_ID AS CreatedWTF_ID;
```

### 8.2 Check Redeem linkage status

```sql
SELECT
    r.RedeemID,
    r.WithdrawToFundingID,
    wtf.CashoutStatusID,
    wtf.ModificationDate
FROM Billing.Redeem r WITH (NOLOCK)
LEFT JOIN Billing.WithdrawToFunding wtf WITH (NOLOCK)
    ON wtf.ID = r.WithdrawToFundingID
WHERE r.RedeemID = 55555;
-- WithdrawToFundingID NULL = not yet processed; non-NULL = already linked
```

### 8.3 Audit the full created withdrawal chain

```sql
SELECT
    w.WithdrawID,
    w.CashoutStatusID,
    w.CID,
    w.Amount,
    w.RequestDate,
    wtf.ID AS WTF_ID,
    wtf.CashoutStatusID AS WTF_Status
FROM Billing.Withdraw w WITH (NOLOCK)
JOIN Billing.WithdrawToFunding wtf WITH (NOLOCK) ON wtf.WithdrawID = w.WithdrawID
WHERE w.CashoutReasonID = 18  -- Redeem conversions
ORDER BY w.RequestDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawAndWithdrawToFundingAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawAndWithdrawToFundingAdd.sql*
