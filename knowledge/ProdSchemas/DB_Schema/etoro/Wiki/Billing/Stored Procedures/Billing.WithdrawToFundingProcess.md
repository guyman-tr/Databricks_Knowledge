# Billing.WithdrawToFundingProcess

> Core payout settlement procedure: marks a WithdrawToFunding leg as Processed (status 3), debits the customer's balance, cascades to parent Withdraw status (Processed or Partially Processed), cancels sibling legs, and triggers a withdrawal-complete email notification.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID + @FundingID + @ID (WithdrawToFunding PK) -> settlement |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawToFundingProcess` is the central settlement procedure for the eToro payout system. It is called when a payment provider confirms that a withdrawal payment has been successfully processed - i.e., the funds have left eToro and reached the customer. This is the most consequential point in the withdrawal lifecycle.

The procedure orchestrates a multi-step atomic settlement:
1. Marks the specific payment leg (`Billing.WithdrawToFunding`) as Processed (status 3)
2. Debits the customer's account balance via `Customer.SetBalance` (the cash exits the customer's account)
3. Determines whether the parent withdrawal is **fully settled** (all expected funds moved) or **partially settled** (still waiting for other payment legs)
4. If fully settled: marks `Billing.Withdraw` as Processed (3), cancels all remaining sibling WTF legs, and triggers a withdrawal-complete email notification to the customer
5. If partially settled: marks `Billing.Withdraw` as Partially Processed (5) to indicate more payment legs are pending

The procedure has a rich history of deadlock-avoidance engineering: it uses two "fiktive" (phantom) UPDATE statements to pre-acquire locks on `Billing.Withdraw` and `Billing.WithdrawToFunding` before doing real work, preventing concurrent settlements from causing deadlocks. It uses `@BookMark` + `CONTEXT_INFO` to track execution position for post-mortem debugging.

@MID (merchant identifier string) is resolved to a `Billing.ProtocolMIDSettings.ID` at settlement time, capturing which exact MID configuration was used to process the payment. This enables per-MID settlement reporting and financial reconciliation.

When `@CalculateFTP=1`, the procedure additionally returns an `IsFtp` (Is First Time Payout) bit indicating whether this is the customer's first ever successfully processed withdrawal - used by marketing and fraud systems.

---

## 2. Business Logic

### 2.1 Pre-Transaction Validation Gates

**What**: Three guards run before BEGIN TRANSACTION to reject clearly invalid calls without acquiring any locks.

**Rules**:
- **Gate 1** (@BookMark 10150): `Billing.Withdraw` must have CashoutStatusID IN (1,2,3,5,7,9,10) AND no other filter - validates the withdrawal exists and is not in a terminal non-processable state. Fails: RAISERROR 60025 "request does Not Exists Or have illegal status"
- **Gate 2** (@BookMark 10160): `Billing.Withdraw` must have Approved=1. Fails: RAISERROR 60025 "request is Not approved"
- **Gate 3** (@BookMark 10170): The specific WTF leg (WithdrawID + FundingID + ID) must NOT already be CashoutStatusID=3 (Processed). Fails: RAISERROR 60072 "Withdrawal status is already Processed. Cannot process again." - prevents double settlement

### 2.2 Deadlock-Avoidance Lock Acquisition

**What**: Two phantom UPDATEs acquire table locks before the real work, preventing concurrent settlements from causing deadlocks.

**Rules**:
- `UPDATE Billing.Withdraw SET ManagerID=ManagerID WHERE WithdrawID=@WithdrawID` - acquires a row lock on the Withdraw record without changing any data
- `UPDATE Billing.WithdrawToFunding SET WithdrawID=WithdrawID WHERE WithdrawID=@WithdrawID` - acquires locks on ALL WTF legs for this withdrawal (not just @ID) to prevent other concurrent processes from modifying sibling legs during settlement
- Pattern added by Ran Ovadia 26/07/2018 for deadlock prevention; extended for WTF by Adi Cohn 20/05/2019

### 2.3 @CreditAmount Calculation (Double-Debit Prevention)

**What**: Determines how much to debit from the customer's balance - zero if already debited for a prior processed leg.

**Columns/Parameters Involved**: `@CreditAmount`, `Billing.WithdrawToFunding.Amount`, `Billing.Withdraw.Fee`

**Rules**:
- `OUTER APPLY (SELECT SUM(Amount) Val FROM Billing.WithdrawToFunding WHERE WithdrawID=@WithdrawID AND CashoutStatusID=3) SumWtf`
- If SumWtf.Val IS NULL or 0 (no already-processed WTFs): `@CreditAmount = CAST((BW.Amount + BW.Fee) * 100 AS INT)` (total withdrawal amount + fee, in cents)
- If SumWtf.Val > 0 (prior processed WTF exists): `@CreditAmount = 0` (do not debit again)
- This ensures that for partial withdrawals with multiple payment legs, the customer's balance is only debited once - on the first leg that processes

### 2.4 WTF Status Transition to Processed (Status 3) via DBA-648 TVP

**What**: Sets the payment leg to Processed, records the provider's verification code, vendor code, value date, and MID.

**Columns/Parameters Involved**: `CashoutStatusID`, `VerificationCode`, `VendorCode`, `ProtocolMIDSettingsID`, `ProcessorValueDate`

**Rules**:
- Builds `@InfoWTF Billing.TBL_Withdraw2Funding` with:
  - ID = @ID, CashoutStatusID = 3 (Processed), CashoutActionStatusID = 2 (Processed)
  - VerificationCode = @VerificationCode (provider auth/reference code)
  - VendorCode = @VendorCode
  - ProtocolMIDSettingsID = `ISNULL(BPMS.ID, existing_ProtocolMIDSettingsID)` - resolved from @MID string via `Billing.ProtocolMIDSettings WHERE Value=@MID AND ParameterID=52`
  - ProcessorValueDate = @ProcessorValueDate (defaults to GETUTCDATE() if NULL - PAYUS-1560)
  - RequestExecuteEntryMethodId = @RequestExecuteEntryMethodId
  - ManagerID = @RelevantManagerID (resolved: -1 = billing service, preserve existing)
- Delegates to `EXEC Billing.UpdateWithdraw2Funding @InfoWTF` (DBA-648 pattern)
- This triggers automatic audit INSERT into `History.WithdrawToFundingAction`

### 2.5 Billing.InsertScheduledTaskFirstWtf

**What**: Schedules a post-processing task for this WTF (purpose: first WTF in a series).

**Rules**:
- `EXEC Billing.InsertScheduledTaskFirstWtf @WtfID=@ID, @Cid=@CID`
- Called after the WTF is marked Processed but before the Withdraw-level updates

### 2.6 Second History INSERT (Comprehensive Snapshot)

**What**: Inserts a second history record with a full snapshot of all WTF financial fields at the time of settlement.

**Rules**:
- Unlike UpdateWithdraw2Funding's OUTPUT-based history (which uses TVP fields), this second INSERT reads directly from `Billing.WithdrawToFunding` WITHOUT NOLOCK after the update
- Captures: MatchStatusID, ProtocolMIDSettingsID, AdditionalInformation, MerchantAccountID, BaseExchangeRate, ExchangeFee, ExchangeRate, RefundAmountInDepositCurrency, CashoutTypeID, CashoutModeID
- These fields are NOT included in UpdateWithdraw2Funding's OUTPUT insert - this is why a second INSERT is needed
- CashoutStatusID=3, CashoutActionStatusID=2 in this history entry

### 2.7 Customer Balance Debit via Customer.SetBalance

**What**: Removes the withdrawal funds from the customer's eToro balance.

**Columns/Parameters Involved**: `@CreditAmount`, `@CID`, `@CashoutReasonID`, `@MoveMoneyReasonID`

**Rules**:
- `EXEC Customer.SetBalance @CID, @CreditAmount, 2 (cashout), ...`
- @CreditAmount=0 if already debited (prior processed WTF for this withdrawal) - prevents double-debit
- @CashoutReasonID: `12=Foreclose account`, `14=PI Payment`, `15=Affiliate Payment` - affect notification behavior
- @MoveMoneyReasonID:
  - Auto-set to 5 if FundingTypeID=33 AND FlowID=2 AND WithdrawTypeID=1 (local currency withdrawal)
  - Auto-set to 6 if FlowID=3 AND WithdrawTypeID=1
  - Otherwise uses caller-supplied value (default NULL)
- If SetBalance returns @Answer != 0: ROLLBACK + RETURN @Answer

### 2.8 Over-Payment Guard

**What**: Prevents more than $1 over-settlement across all payment legs.

**Rules**:
- `@TotalProcessedAmount = SUM(Amount) FROM Billing.WithdrawToFunding WHERE WithdrawID=@WithdrawID AND CashoutStatusID=3`
- If `@TotalProcessedAmount - @TotalAmount >= 1`: ROLLBACK "Too much Money processed"
- $1 tolerance accommodates minor rounding differences

### 2.9 Completion vs. Partial Processing Decision

**What**: Based on the total settled amount vs. the expected withdrawal amount, determines whether the withdrawal is complete or still partial.

**Rules**:
- **Fully settled** (`|@TotalProcessedAmount - @TotalAmount| < 1`):
  1. Mark `Billing.Withdraw` as CashoutStatusID=3 (Processed) via `Billing.UpsertWithdraw`
  2. Cancel all non-terminal WTF legs: `CashoutStatusID NOT IN (3,7,8,9,10,11,12,13)` -> set to CashoutStatusID=4 (Canceled) via `Billing.UpdateWithdraw2Funding`
  3. Send customer email notification via `BackOffice.NotificationsAdd` (unless CashoutReasonID IN (12,14,15) OR FundingTypeID=27)
- **Partially settled** (else):
  - If Billing.Withdraw is NOT already at status 5 (partial) or 7 (rejected): update to CashoutStatusID=5 (Partially Processed)
  - If already at 5 or 7: do not change CashoutStatusID (preserves existing partial/reject state)

### 2.10 First Time Payout (FTP) Flag

**What**: Optional output indicating if this is the customer's first ever processed withdrawal.

**Rules**:
- Only computed when `@CalculateFTP = 1`
- Returns a result set with one column `IsFtp BIT`:
  - 1 (true) if: for all WTFs for all of this customer's withdrawals, (1) no WTF other than @ID has CashoutStatusID=3, AND (2) @ID itself has CashoutStatusID=3 (just processed)
  - 0 (false) if any other WTF for the customer already has CashoutStatusID=3
- Logic: `COUNT(*) > 0 THEN 0 ELSE 1` where count is WTFs with (status=3 AND ID!=@ID) OR (status!=3 AND ID=@ID)

**Diagram**:
```
[CALL] WithdrawToFundingProcess (@WithdrawID, @FundingID, @ID, @ManagerID, ...)
    |
    v Gate 1: Billing.Withdraw CashoutStatusID IN (1,2,3,5,7,9,10)
    v Gate 2: Billing.Withdraw Approved=1
    v Gate 3: WTF NOT already CashoutStatusID=3
    v
BEGIN TRANSACTION
    Phantom UPDATE Billing.Withdraw (lock)
    Phantom UPDATE Billing.WithdrawToFunding (lock all WTF legs)
    Calc @CreditAmount (0 if already-processed WTFs exist)
    Build TVP -> EXEC UpdateWithdraw2Funding (WTF -> status 3, VerifCode, MID, ValueDate)
    EXEC InsertScheduledTaskFirstWtf
    EXEC UpsertWithdraw (update ManagerID + SessionID on Billing.Withdraw)
    INSERT History.WithdrawToFundingAction (comprehensive snapshot)
    EXEC Customer.SetBalance (@CreditAmount, cashout)
    IF SetBalance failed -> ROLLBACK; RETURN
    Check @TotalProcessedAmount vs @TotalAmount:
        IF over by $1+ -> ROLLBACK "Too much Money processed"
        IF within $1 (fully settled):
            EXEC UpsertWithdraw (Withdraw -> status 3)
            EXEC UpdateWithdraw2Funding (sibling WTFs -> status 4 Canceled)
            EXEC BackOffice.NotificationsAdd (email notification)
        ELSE (partial):
            IF Withdraw not already at 5 or 7:
                EXEC UpsertWithdraw (Withdraw -> status 5 partial)
    IF @CalculateFTP=1: SELECT IsFtp
COMMIT TRANSACTION
Post-commit: verify WTF.CashoutStatusID=3 (eToroMoney validation)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | int | NO | - | CODE-BACKED | Required. FK to `Billing.Withdraw`. The parent withdrawal request being settled. |
| 2 | @FundingID | int | NO | - | CODE-BACKED | Required. FK to `Billing.Funding`. The payment instrument used for this payment leg. Together with @WithdrawID, identifies the WTF record alongside @ID. |
| 3 | @ManagerID | int | NO | - | CODE-BACKED | Required. Manager or service account processing the settlement. -1 = billing service (preserves existing ManagerID on WTF and Withdraw records). |
| 4 | @Remark | varchar(255) | YES | NULL | CODE-BACKED | Optional. Free-text audit note written to history records and passed to Customer.SetBalance. |
| 5 | @ID | int | NO | - | CODE-BACKED | Required. PK of `Billing.WithdrawToFunding` - the specific payment leg being settled. Must NOT already be CashoutStatusID=3 or RAISERROR 60072 is raised. |
| 6 | @VerificationCode | varchar(50) | YES | NULL | CODE-BACKED | Optional. Provider-assigned authorization/reference code confirming the payment. Written to `Billing.WithdrawToFunding.VerificationCode` via the TVP update. Key reconciliation field. |
| 7 | @ProcessorValueDate | datetime | YES | NULL | CODE-BACKED | Optional. Value date assigned by the payment processor. Defaults to GETUTCDATE() if NULL (added PAYUS-1560 Elrom 29/07/2020). Written to `Billing.WithdrawToFunding.ProcessorValueDate`. |
| 8 | @SessionID | bigint | YES | NULL | CODE-BACKED | Optional. Session identifier for the operator performing the settlement. Written to `Billing.Withdraw.SessionID` via UpsertWithdraw. |
| 9 | @VendorCode | nvarchar(250) | YES | NULL | CODE-BACKED | Optional. Vendor-specific transaction identifier from the payment provider. Written to `Billing.WithdrawToFunding.VendorCode`. |
| 10 | @MID | nvarchar(250) | YES | NULL | CODE-BACKED | Optional. Merchant ID string value from the payment provider. Resolved to `Billing.ProtocolMIDSettings.ID` via `WHERE Value=@MID AND ParameterID=52`. Written to `ProtocolMIDSettingsID` on the WTF record. |
| 11 | @RequestExecuteEntryMethodId | int | YES | NULL | CODE-BACKED | Optional. Entry method that triggered this payout execution. Written to `Billing.WithdrawToFunding.RequestExecuteEntryMethodId`. |
| 12 | @CalculateFTP | bit | YES | NULL | CODE-BACKED | Optional. When 1, returns a single-row result set with `IsFtp BIT` indicating whether this is the customer's first successfully processed withdrawal. Used by marketing/fraud systems. |
| 13 | @MoveMoneyReasonID | int | YES | NULL | CODE-BACKED | Optional. Money movement reason passed to `Customer.SetBalance`. Auto-overridden to 5 for local currency withdrawals (FundingTypeID=33, FlowID=2, WithdrawTypeID=1) and to 6 for FlowID=3 withdrawals. |

### Output (when @CalculateFTP=1)

| # | Column | Type | Confidence | Description |
|---|--------|------|------------|-------------|
| 1 | IsFtp | bit | CODE-BACKED | 1 = this is the customer's first ever successfully processed withdrawal leg; 0 = prior processed WTFs exist for this customer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.Withdraw | Validation + Lock + Update | Gates check status/approval; phantom UPDATE acquires lock; UpsertWithdraw transitions status |
| @ID | Billing.WithdrawToFunding | Lock + Update via TVP | Phantom UPDATE locks all WTF legs; UpdateWithdraw2Funding sets status 3 |
| @MID | Billing.ProtocolMIDSettings | Lookup | Resolves @MID string to ProtocolMIDSettingsID for the settlement record |
| (via UpdateWithdraw2Funding) | History.WithdrawToFundingAction | Indirect INSERT | DBA-648 TVP delegation: audit row for WTF status=3 |
| (direct INSERT) | History.WithdrawToFundingAction | INSERT | Second comprehensive snapshot including financial detail columns |
| @CID | Customer.SetBalance | Callee | Debits customer account balance for the withdrawal amount |
| (sibling WTFs) | Billing.WithdrawToFunding | Cascade Update | Non-terminal sibling legs cancelled (status 4) when withdrawal is fully settled |
| (notifications) | BackOffice.NotificationsAdd | Callee | Triggers withdrawal-complete email notification (NotificationTypeID=1, TriggerID=1) |
| @WtfID | Billing.InsertScheduledTaskFirstWtf | Callee | Schedules post-processing tasks for this WTF |
| @InfoWithdraw | Billing.UpsertWithdraw | Callee | Updates Billing.Withdraw status and metadata |
| @InfoWTF | Billing.TBL_Withdraw2Funding | TVP Type | Staging type for UpdateWithdraw2Funding delegation |
| @InfoWithdraw | Billing.TBL_Withdraw | TVP Type | Staging type for UpsertWithdraw delegation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.PayoutProcess_FinalizeRequest | EXEC | Caller | Primary caller in the payout processing pipeline |
| Billing.PayoutProcess_FinalizeRequest_v2 | EXEC | Caller | V2 variant of the payout finalization flow |
| Billing.WithdrawToFundingProcessBatch | EXEC | Caller | Batch settlement caller |
| Billing.WithdrawToFundingProcessForBatch | EXEC | Caller | Alternative batch settlement path |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingProcess (procedure)
├── Billing.Withdraw (table) [validation + lock + status update via UpsertWithdraw]
├── Billing.WithdrawToFunding (table) [validation + lock + status update via UpdateWithdraw2Funding]
├── Billing.ProtocolMIDSettings (table) [MID string -> ID lookup]
├── Billing.TBL_Withdraw2Funding (UDT) [TVP type for UpdateWithdraw2Funding]
├── Billing.TBL_Withdraw (UDT) [TVP type for UpsertWithdraw]
├── Billing.UpdateWithdraw2Funding (procedure) [DBA-648 WTF write path]
├── Billing.UpsertWithdraw (procedure) [DBA-648 Withdraw write path]
├── Billing.InsertScheduledTaskFirstWtf (procedure) [post-processing task scheduler]
├── History.WithdrawToFundingAction (table) [direct INSERT for comprehensive snapshot]
├── Customer.SetBalance (procedure) [balance debit]
├── Customer.Customer (table) [reads IsReal, Email for notification]
└── BackOffice.NotificationsAdd (procedure) [email notification trigger]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Validation (status/approval gates); phantom lock UPDATE; read @CID, @TotalAmount; update via UpsertWithdraw |
| Billing.WithdrawToFunding | Table | Validation (duplicate processed check); phantom lock UPDATE; update via UpdateWithdraw2Funding; read @CurrencyID, @Amount; sibling cancellation |
| Billing.ProtocolMIDSettings | Table | LEFT JOIN to resolve @MID string to ProtocolMIDSettingsID (ParameterID=52) |
| Billing.TBL_Withdraw2Funding | User Defined Type | TVP for UpdateWithdraw2Funding |
| Billing.TBL_Withdraw | User Defined Type | TVP for UpsertWithdraw |
| Billing.UpdateWithdraw2Funding | Procedure | DBA-648: WTF status transition + history INSERT |
| Billing.UpsertWithdraw | Procedure | DBA-648: Withdraw status/metadata update |
| Billing.InsertScheduledTaskFirstWtf | Procedure | Schedules post-processing tasks |
| History.WithdrawToFundingAction | Table | Comprehensive settlement snapshot INSERT (direct, not via OUTPUT) |
| Customer.SetBalance | Procedure | Customer balance debit for the settled withdrawal |
| Customer.Customer | Table | Reads IsReal + Email for the email notification JSON payload |
| BackOffice.NotificationsAdd | Procedure | Enqueues withdrawal-complete email notification |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.PayoutProcess_FinalizeRequest | Procedure | Primary caller in payout finalization |
| Billing.PayoutProcess_FinalizeRequest_v2 | Procedure | V2 payout finalization caller |
| Billing.WithdrawToFundingProcessBatch | Procedure | Batch settlement caller |
| Billing.WithdrawToFundingProcessForBatch | Procedure | Alternative batch settlement path |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Outer TRY/CATCH | Design | Wraps the entire procedure; THROW re-raises inner unhandled exceptions |
| Nested TRY/CATCH blocks | Design | Separate CATCH blocks at @BookMark 10200 (WTF update), 10300 (completion logic), 10400 (partial logic) - each rolls back and re-raises |
| @BookMark tracking | Design | Integer position tracker (10150-10400) stored in CONTEXT_INFO for deadlock/error post-mortem analysis |
| CONTEXT_INFO | Design | Used to pass @BookMark value into catch blocks for error reporting (VARBINARY(128) limited) |
| Phantom UPDATEs | Architecture | Two no-op UPDATEs to pre-acquire row locks before real work - deadlock prevention pattern (Ran Ovadia 2018, Adi Cohn 2019) |
| @ManagerID=-1 sentinel | Business Rule | -1 = billing service; resolved to existing WTF.ManagerID for @RelevantManagerID at the start of the procedure |
| @CreditAmount=0 guard | Business Rule | If any prior WTF for the same WithdrawID already has CashoutStatusID=3, SetBalance is called with 0 - prevents double-debit on partial payments |
| $1 over-payment tolerance | Business Rule | TotalProcessedAmount - TotalAmount >= 1 triggers rollback; difference < 1 is tolerated as rounding |
| eToroMoney post-commit check | Architecture | After COMMIT, verifies WTF.CashoutStatusID=3; throws 60000 if not (eToroMoney-specific validation added as unreachable code after COMMIT/RETURN) |
| DBA-648 refactor (2021-09-23) | Architecture | Both WTF and Withdraw updates now delegated via TVP to UpdateWithdraw2Funding / UpsertWithdraw; original direct UPDATE/INSERT code is commented out |

---

## 8. Sample Queries

### 8.1 Process a single payment leg settlement

```sql
EXEC Billing.WithdrawToFundingProcess
    @WithdrawID = 1234567,
    @FundingID = 987654,
    @ManagerID = 42,
    @Remark = 'Provider confirmed settlement',
    @ID = 9876543,
    @VerificationCode = 'AUTH-ABC123',
    @MID = 'VISA_MID_001',
    @ProcessorValueDate = '2026-03-18 10:00:00';
```

### 8.2 Process with First Time Payout check

```sql
EXEC Billing.WithdrawToFundingProcess
    @WithdrawID = 1234567,
    @FundingID = 987654,
    @ManagerID = 42,
    @Remark = 'Settlement with FTP check',
    @ID = 9876543,
    @VerificationCode = 'AUTH-XYZ999',
    @CalculateFTP = 1;
-- Returns result set with IsFtp BIT
```

### 8.3 Verify settlement - check parent withdrawal status

```sql
SELECT
    w.WithdrawID,
    w.CashoutStatusID,    -- 3=Processed, 5=Partially Processed
    w.Amount,
    w.Fee,
    w.ModificationDate
FROM Billing.Withdraw w WITH (NOLOCK)
WHERE w.WithdrawID = 1234567;
```

### 8.4 Check all payment legs after settlement

```sql
SELECT
    wtf.ID,
    wtf.FundingID,
    wtf.CashoutStatusID,  -- 3=Processed (settled), 4=Canceled (sibling closed)
    wtf.Amount,
    wtf.VerificationCode,
    wtf.ProcessorValueDate,
    wtf.ProtocolMIDSettingsID,
    wtf.ModificationDate
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.WithdrawID = 1234567
ORDER BY wtf.ID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Payout Service Gen 2.0 - Changes (Confluence /spaces/MG/pages/1218937110) | Confluence | Confirmed this SP is called by the Payout Service via PayoutProcess_FinalizeRequest. @ProcessorValueDate=NULL default was added as part of Gen 2.0 changes (PAYUS-1560). Service uses Azure Service Bus (payout-requests, payout-toprovider queues) and PayoutUser SQL account. |
| PAYUS-1560 (referenced in DDL comment, 2020-07-29) | Jira | Added @ProcessorValueDate parameter as nullable with ISNULL default to GETUTCDATE() |
| MIMOPS-4536 (referenced in DDL comment, 2021-07-07) | Jira | Added @MID parameter for MID routing reference at settlement time |
| DBA-648 (referenced in DDL comment, 2021-09-23) | Jira | Refactored direct UPDATE/INSERT to delegate via TBL_Withdraw2Funding TVP through UpdateWithdraw2Funding; same for Billing.Withdraw via UpsertWithdraw |
| PAYIL-4186 (referenced in DDL comment, 2022-05-08) | Jira | @CreditAmount calculation changed to use Billing.Withdraw.Amount+Fee from the table directly (vs. prior approach) to correctly calculate RealizedEquity |
| MIMOPSA-12732 (referenced in DDL comment, 2024-04-24) | Jira | Added @MoveMoneyReasonID parameter for money movement reason tracking in Customer.SetBalance |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 1 Confluence + 0 Jira (6 tickets referenced in DDL comments) | Procedures: 4 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingProcess | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingProcess.sql*
