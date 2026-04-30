# Customer.SetBalance

> The central balance router for all financial events on a customer account: routes 10 modern CreditTypeIDs to dedicated specialized sub-procedures (SetBalanceDeposit, SetBalanceCashOut, SetBalanceClosePosition, etc.) and handles ~20 legacy CreditTypeIDs inline with full balance update, credit record, MIMO trigger, affiliate tracking, and payment queue notification.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INTEGER, @Payment BIGINT, @CreditTypeID TINYINT; @ErrOut OUTPUT, @CreditID OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`SetBalance` is the primary financial gateway for eToro's trading platform. Every monetary event on a customer's account - deposits, withdrawals, position opens/closes, bonuses, chargebacks, refunds, and more - flows through this procedure or its specialized sub-procedures.

The procedure operates as a **two-tier router**:

**Tier 1 - Modern fast path** (lines 72-180): For the 10 most common CreditTypeIDs (1, 2, 4, 6, 7, 11, 12, 16, 22, 33), SetBalance immediately delegates to a purpose-built sub-procedure and returns. These specialized procedures contain complex business logic, idempotency guards, regulatory integrations, and have their own transaction management.

**Tier 2 - Legacy inline path** (line 182+): For all remaining CreditTypeIDs (~20 types), SetBalance executes the original "monolithic" balance logic that predates the specialized procedure extraction. This includes mirror position management, championship events, IB sync, stock order accounting, and internal mirror cash movements.

The architecture reflects eToro's incremental refactoring history: each specialized sub-procedure was extracted from this original monolithic code over time (FB: 23824, 31696, etc.), leaving the legacy code for types that were not yet split out or are rare enough not to warrant a dedicated procedure.

---

## 2. Business Logic

### 2.1 Tier 1: Fast-Path Delegation (CreditTypeIDs 1, 2, 4, 6, 7, 11, 12, 16, 22, 33)

**What**: For modern CreditTypeIDs, immediately EXECs the relevant specialized procedure and returns. No balance logic runs in this procedure.

**Rules**:

| CreditTypeID | Name | Delegated To |
|-------------|------|-------------|
| 1 | Deposit | Customer.SetBalanceDeposit |
| 2 | CashOut | Customer.SetBalanceCashOut |
| 4 | ClosePosition | Customer.SetBalanceClosePosition |
| 6 | Compensation | Customer.SetBalanceCompensation |
| 7 | Bonus | Customer.SetBalanceBonus |
| 11 | ChargeBack | Customer.SetBalanceChargeBack |
| 12 | Refund | Customer.SetBalanceRefund |
| 16 | RefundAsChargeBack | Customer.SetBalanceRefundAsChargeBack |
| 22 | ClosePositionByMirrorHierarchy | Customer.SetBalanceClosePosition |
| 33 | CashoutRollback | Customer.SetBalanceCashoutRollback |

- After delegation (for CreditTypeIDs 1, 2, 7): also calls `BackOffice.UpsertMIMOAggregation` for on-the-fly MIMO aggregation update (PAYUS-1770).
- RETURN(0) after the fast-path block - legacy code does NOT execute.
- Error handling: THROW re-raises sub-procedure exceptions.

### 2.2 Tier 2: Legacy Path - Row Lock Acquisition

**What**: Acquires XLOCK + HOLDLOCK on CustomerMoney to prevent concurrent modifications.

**Columns/Parameters Involved**: `Customer.CustomerMoney.CID`, `TotalCash`, `BonusCredit`

**Rules**:
- `SELECT @CID, @TotalCash, @OldBonusCredit FROM Customer.CustomerMoney WITH (XLOCK, HOLDLOCK) WHERE CID = @CID`
- XLOCK acquired at transaction start and held until COMMIT (HOLDLOCK).
- Comment in code: "We had few cases credit was taken from Customer.Customer table and modified before the end of the procedure by a different procedures."

### 2.3 Mirror Detection (Position-Based)

**What**: For CreditTypeIDs involving positions (1, 3, 4, 13, 22, 23, 24, 25, stock orders 29/30), determines whether the position is mirror-affiliated.

**Columns/Parameters Involved**: `Trade.Position.MirrorID`, `Trade.Position.ParentPositionID`, `@IsMirror`, `@MirrorID`, `@InstrumentID`

**Rules**:
- `SELECT @IsMirror = CASE WHEN ISNULL(MirrorID,0)>0 AND ISNULL(ParentPositionID,0)>0 THEN 1 ELSE 0 END` from Trade.Position
- Fallback: if not in Trade.Position (active), checks `Trade.PositionTbl WHERE StatusID=2 UNION ALL History.Position_Active`
- Stock/mirror combination: CreditTypeID=29 with @MirrorID>0 -> @IsMirror=1; CreditTypeID=30 with @MirrorID>0 and NOT detached -> @IsMirror=1
- Mirror existence validation: if stock position (InstrumentTypeID=5) with @IsMirror=1 and Trade.Mirror row missing -> sets @IsMirror=0 (handles "mirror closed but stock position still open" edge case).

### 2.4 Credit Change Calculation

**What**: Converts payment amount to dollar value.

**Rules**:
- `@CreditChange = CAST(@Payment AS MONEY) / 100`
- Always applied in legacy path. Fast-path sub-procedures perform their own conversion.

### 2.5 CustomerMoney.Credit Update (Non-Mirror)

**What**: Updates customer's Credit balance for standalone (non-mirror) positions and non-position events.

**Columns/Parameters Involved**: `Customer.CustomerMoney.Credit`

**Rules**:

| CreditTypeID | Credit Update Rule |
|-------------|-------------------|
| 10 (IBSync) | `Credit = @CreditChange` (absolute SET, not +=) |
| 2 (CashOut) | `Credit` unchanged (credit already reserved at cashout request) |
| all others | `Credit += @CreditChange` |

- Output: INSERTED.Credit -> @Output.NewCredit; DELETED.Credit -> @Output.OldCredit
- After UPDATE: @Output populated with IsReal, ProviderID, CountryID from Customer.CustomerStatic (separate UPDATE on @Output)

### 2.6 Trade.Mirror Update (Mirror Path)

**What**: For mirror-affiliated positions, updates Trade.Mirror.Amount instead of CustomerMoney.Credit. CustomerMoney.Credit is NOT modified.

**Columns/Parameters Involved**: `Trade.Mirror.Amount`, `Trade.Mirror.RealizedEquity`, `@OldMirrorCredit`

**Rules**:
- `UPDATE Trade.Mirror SET Amount = ROUND(Amount + @CreditChange, 2), RealizedEquity = CASE WHEN @CreditTypeID IN (4,22,24) THEN RealizedEquity + @NetProfit ELSE RealizedEquity END WHERE MirrorID = @MirrorID`
- @Output for mirror path: populated via SELECT Credit+@CreditChange (simulated NewCredit) from Customer.Customer - Credit is NOT actually changed.
- Mirror RealizedEquity only updated on position close types (4, 22, 24).

### 2.7 RealizedEquity Update

**What**: Updates RealizedEquity for financial events that realize value.

**Columns/Parameters Involved**: `Customer.CustomerMoney.RealizedEquity`

**Rules**:
- Updated for CreditTypeIDs: 1, 5, 6, 7, 11, 12, 14, 16
- `RealizedEquity += @CreditChange` (same delta as Credit)
- Note: ClosePosition (4) RealizedEquity is handled by SetBalanceClosePosition; not here.

### 2.8 BonusCredit Update (Types 5 and 7)

**What**: Maintains the BonusCredit field for championship winner (5) and bonus (7) events.

**Rules**:
- `@TMP_NewBonusChange = ISNULL(BonusCredit,0) + @CreditChange`
- Clamped to 0 if negative: `IF @TMP_NewBonusChange < 0 SET @TMP_NewBonusChange = 0`
- `UPDATE CustomerMoney SET BonusCredit = @TMP_NewBonusChange WHERE CID = @CID`
- BonusCredit absorption: for Deposit (1) and positive Compensation (6), @TMP_NewBonusChange is further capped at OldRealizedEquity.

### 2.9 TotalCash Update

**What**: Updates TotalCash for all events except mirror internal movements.

**Rules**:
- `TotalCash += @CreditChange` for most CreditTypeIDs
- `TotalCash` unchanged (no-op) for CreditTypeIDs 18, 19, 20, 21 (mirror cash movements - TotalCash doesn't change when moving money in/out of a mirror)
- Updated in same UPDATE as BonusCredit (two-field update).

### 2.10 Credit Record Write (SetBalanceInsertCredit_Native)

**What**: Logs the financial event to History.ActiveCredit via the credit record writer.

**Rules**:
- Calls `Customer.SetBalanceInsertCredit_Native` with a comprehensive parameter set.
- CreditTypeID normalization: 22/24 -> stored as 4; 23/25 -> stored as 3; @ChampionshipID present -> stored as 5.
- @Payment in record: 0 for mirror positions (Credit didn't change); @CreditChange for standalone.
- @TotalCashChange: 0 for CreditTypeIDs 18,19,20,21; @CreditChange otherwise.
- @MirrorCash: context-dependent snapshot (see MirrorCash logic below).
- @BSLRealFunds: read from CustomerMoney and passed through (not calculated in legacy path).
- Returns @CreditID OUTPUT.

### 2.11 MIMO Trigger (Types 11, 12, 16, 26)

**What**: Queues async BSL recalculation for ChargeBack/Refund/RefundAsChargeBack/FixBonusCreditRealizedEquity events.

**Rules**:
- Builds XML: `<Root><CreditID Value="{id}"/><CreditTypeID Value="{type}"/><CID Value="{cid}"/></Root>`
- INSERT INTO `Internal.ActionsToExecute_MIMOOperations` (ActionID=7)
- INSERT INTO `Trade.BSLUsersWhiteList` (CID, CreditID)
- No CheckBonus="1" flag in legacy path.

### 2.12 Service Broker Payment Notification (svcPayment)

**What**: Notifies trade servers of balance changes via Service Broker.

**Rules**:
- Excluded from notification: CreditTypeIDs 2, 3, 4, 10, 13, 14, 15, 18, 19, 20, 21, 22, 27, 28, 29, 30
- Format: `'{CID};{CreditTypeID};{Payment};{NewCredit*100};'` + bonus change delta
- Reverse cashout (8) and cashout request (9) include fee adjustment in the payment/newcredit values (fee read from Billing.Withdraw.Fee).
- Sent via `BEGIN DIALOG CONVERSATION ... svcPayment ... SEND`.

### 2.13 Offline Notification

**What**: Sends push-style notifications to real customers who are not currently logged in.

**Rules**:
- Triggers for CreditTypeIDs: 1, 6, 7 (deposit, compensation, bonus)
- Condition: IsReal=1 AND NOT EXISTS in Customer.Login (offline check)
- Calls `Customer.SendMessage` with:
  - MessageTemplateID=7 for deposit
  - MessageTemplateID=6 for compensation or bonus

### 2.14 Zero Balance Alert

**What**: Sends event-9 (zero/negative balance alert) if the new credit is non-positive.

**Rules**:
- `IF @NewCredit <= 0 EXEC Customer.SendEvent 9, @CID, @ErrOut OUTPUT`
- Non-IB customers only.

### 2.15 Affiliate Tracking (QueuePiggyBankAdd)

**What**: Reports eligible events to affiliate and PiggyBank tracking systems.

**Rules**:
- Active for CreditTypeIDs: 1, 5, 6, 7, 10, 11, 12, 16
- Real customers only (IsReal=1); excludes test users (PlayerLevelID=4) except for deposits (CreditTypeID=1).
- Excludes bonus types with HideFromAffwiz=1 (from BackOffice.BonusType).
- @Type mapping for affiliate event classification:
  - 1 -> 1 (deposit), 5 -> 2 (champ win as bonus), 6 -> 3 (compensation), 7 -> 2 (bonus), 10 -> 1 (IB sync as deposit), 11 -> 4 (chargeback), 12 -> 5 (refund), 16 -> 4 (refund as chargeback)
- For Type=4 or Type=5: credit absorption calculation adjusts @Payment to the net-effective amount (prevents over-reporting when credit crosses zero).
- Calls `Broker.QueuePiggyBankAdd` (Note: CreditTypeID=1/deposit NOT handled here for modern callers - SetBalanceDeposit routes to fast path which calls its own affiliate logic).

### 2.16 MIMO Aggregation (BackOffice.UpsertMIMOAggregation)

**What**: Updates MIMO on-the-fly aggregation table for select event types.

**Rules**:
- Legacy path: CreditTypeIDs 5, 8, 9, 15 -> `BackOffice.UpsertMIMOAggregation`
- Fast path: CreditTypeIDs 1, 2, 7 -> `BackOffice.UpsertMIMOAggregation` (called in fast-path block after delegation)

### 2.17 Transaction and Error Handling

**What**: Full transaction wrap with ROLLBACK on error.

**Rules**:
- `BEGIN TRANSACTION` at start of legacy path; `COMMIT TRANSACTION` at end.
- CATCH: sets @ErrOut with full diagnostic string, ROLLBACK if @@TRANCOUNT=1, COMMIT if @@TRANCOUNT>1.
- RAISERROR(60000) on error; RETURN(@ErrNum).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID whose balance is being modified. XLOCK acquired on CustomerMoney row at start of legacy path. |
| 2 | @Payment | BIGINT | NO | - | CODE-BACKED | Amount in CENTS (divide by 100 for dollars). BIGINT - changed from INT in June 2018 to support large amounts. Positive=credit, negative=debit. |
| 3 | @CreditTypeID | TINYINT | NO | - | CODE-BACKED | Determines which financial event occurred. Routes to fast-path sub-procedures (1,2,4,6,7,11,12,16,22,33) or inline legacy logic. See CreditTypeID taxonomy below. |
| 4 | @Description | VARCHAR(255) | YES | NULL | CODE-BACKED | Human-readable event description stored in the credit record. |
| 5 | @ManagerID | INTEGER | YES | NULL | CODE-BACKED | Admin/manager who triggered the event. Stored in credit record. NULL for system/user-initiated events. |
| 6 | @PositionID | BIGINT | YES | NULL | CODE-BACKED | Position being opened or closed. BIGINT - changed in Nov 2021. Used to look up MirrorID and InstrumentID for position events. |
| 7 | @UpdateID | INTEGER | YES | NULL | CODE-BACKED | Passed through to SetBalanceInsertCredit_Native. Links the credit record to a specific update event. |
| 8 | @CashoutID | INTEGER | YES | NULL | CODE-BACKED | Cashout reference (passed to SetBalanceCashOut but removed from direct call per PAYIL-4186). Still accepted as parameter for backward compatibility. |
| 9 | @PaymentID | INTEGER | YES | NULL | CODE-BACKED | Payment system reference. Passed through to SetBalanceInsertCredit_Native. |
| 10 | @ChampionshipID | INTEGER | YES | NULL | CODE-BACKED | If set, treats CreditTypeID=5 as a Championship event. Affects CreditTypeID stored in credit record (stored as 5 instead of normalized type). |
| 11 | @CampaignID | INTEGER | YES | NULL | CODE-BACKED | Marketing campaign reference. Used for affiliate tracking (fetches CampaignCode from BackOffice.Campaign). Passed through for fast-path sub-procedures. |
| 12 | @BonusTypeID | INTEGER | YES | NULL | CODE-BACKED | Bonus classification ID. Used to check HideFromAffwiz=1 in BackOffice.BonusType (suppresses affiliate reporting for technical/test bonuses). |
| 13 | @CompensationReasonID | INTEGER | YES | NULL | CODE-BACKED | Compensation reason reference. Passed to SetBalanceCompensation in fast path; also stored in credit record for legacy compensation events. |
| 14 | @WithdrawID | INTEGER | YES | NULL | CODE-BACKED | Withdrawal reference. Required for CashOut (2), CashoutRequest (9), ReverseCashout (8) event types. Used to look up cashout fee from Billing.Withdraw. |
| 15 | @DepositID | INTEGER | YES | NULL | CODE-BACKED | Original deposit reference. Required for Bonus (7), ChargeBack (11), Refund (12), RefundAsChargeBack (16). Passed through to sub-procedures and credit record. |
| 16 | @BonusCredit | MONEY | YES | 0 | CODE-BACKED | Bonus amount being consumed/returned on close position events. Passed to SetBalanceClosePosition. Also used in BonusCredit absorption calculation. |
| 17 | @WithdrawProcessingID | INT | YES | NULL | CODE-BACKED | Withdrawal processing batch reference. Passed to SetBalanceCashOut and SetBalanceInsertCredit_Native. |
| 18 | @MirrorID | INT | YES | NULL | CODE-BACKED | Copy-trading mirror ID. If NULL and @PositionID provided, looked up from Trade.Position. Determines mirror vs. standalone accounting path. |
| 19 | @ParentCID | INT | YES | NULL | CODE-BACKED | CID of the mirror's guru (parent trader). Used in mirror position context. |
| 20 | @ParentUserName | VARCHAR(50) | YES | NULL | CODE-BACKED | Username of the mirror's guru. Stored context for mirror operations. |
| 21 | @IsInitiatedByUser | INT | YES | NULL | CODE-BACKED | Flag distinguishing user-initiated vs. system-initiated events. Affects mirror detection for StopLoss (13): system-initiated SL on mirror triggers mirror accounting. |
| 22 | @StocksOrderID | INT | YES | NULL | CODE-BACKED | Stock order reference for CreditTypeIDs 29/30. Passed to SetBalanceInsertCredit_Native. |
| 23 | @IsDetached | BIT | YES | NULL | CODE-BACKED | If 1, stock close order (30) on a mirror is treated as standalone (detached from mirror). |
| 24 | @ErrOut | NVARCHAR(4000) | YES | '' (OUTPUT) | CODE-BACKED | OUTPUT: diagnostic error string on failure. Includes server, DB, procedure, error line, message, severity, transaction count. |
| 25 | @MirrorEquityChange | MONEY | YES | 0 | CODE-BACKED | Mirror equity delta for detachment operations. Used in (now-commented-out) Mirror.RealizedEquity update for CreditTypeID=27 (detach). |
| 26 | @MoveMoneyReasonID | INT | YES | NULL | CODE-BACKED | Reason code for money movement operations. Passed to SetBalanceDeposit, SetBalanceCompensation, SetBalanceCashOut, SetBalanceBonus, SetBalanceInsertCredit_Native. |
| 27 | @CashoutReasonID | INT | YES | NULL | CODE-BACKED | Reason for the cashout. Passed to SetBalanceCashOut. |
| 28 | @DepositRollbackID | INT | YES | NULL | CODE-BACKED | Rollback tracking reference for deposit reversal events. Passed to SetBalanceChargeBack, SetBalanceRefund, SetBalanceRefundAsChargeBack, and SetBalanceInsertCredit_Native. Added Aug 2022 (MIMOPSA-7307). |
| 29 | @RollbackID | INT | YES | NULL | CODE-BACKED | Rollback reference for cashout rollback events. Passed to SetBalanceCashoutRollback. |
| 30 | @CreditID | BIGINT | YES | NULL (OUTPUT) | CODE-BACKED | OUTPUT: CreditID of the resulting credit record. Populated by fast-path sub-procedures or by SetBalanceInsertCredit_Native in legacy path. |

### CreditTypeID Reference Table

| CreditTypeID | Name | Path | Delegated To |
|-------------|------|------|-------------|
| 1 | Deposit | Fast | SetBalanceDeposit |
| 2 | CashOut | Fast | SetBalanceCashOut |
| 3 | OpenPosition | Legacy | Inline (Credit + TotalCash -= amount) |
| 4 | ClosePosition | Fast | SetBalanceClosePosition |
| 5 | ChampionshipWinner | Legacy | Inline (Credit + RealizedEquity + TotalCash + BonusCredit) |
| 6 | Compensation | Fast | SetBalanceCompensation |
| 7 | Bonus | Fast | SetBalanceBonus |
| 8 | ReverseCashout | Legacy | Inline |
| 9 | CashoutRequest | Legacy | Inline |
| 10 | IBSync | Legacy | Inline (Credit = absolute; IB virtual deposit) |
| 11 | ChargeBack | Fast | SetBalanceChargeBack |
| 12 | Refund | Fast | SetBalanceRefund |
| 13 | StopLoss | Legacy | Inline (mirror-aware) |
| 14 | EndOfWeekFee (ClameFee) | Legacy | Inline |
| 15 | CashoutFee | Legacy | Inline |
| 16 | RefundAsChargeBack | Fast | SetBalanceRefundAsChargeBack |
| 18 | MoveMoneyToMirror | Legacy | Inline (Trade.Mirror.Amount update) |
| 19 | MoveMoneyFromMirror | Legacy | Inline (Trade.Mirror.Amount update) |
| 20 | RegisterMirror | Legacy | Inline |
| 21 | UnregisterMirror | Legacy | Inline |
| 22 | ClosePositionByHierarchy | Fast | SetBalanceClosePosition (stored as 4) |
| 23 | OpenPositionByHierarchy | Legacy | Inline (stored as 3) |
| 24 | ClosePositionByRecovery | Legacy | Inline (stored as 4) |
| 25 | OpenPositionByRecovery | Legacy | Inline (stored as 3) |
| 26 | FixBonusCreditRealizedEquity | Legacy | Inline (MIMO trigger) |
| 27 | DetachPosition | Legacy | Inline |
| 28 | DetachStockOrder | Legacy | Inline |
| 29 | StockBuyOrder | Legacy | Inline (mirror-aware) |
| 30 | StockCloseOrder | Legacy | Inline (mirror-aware, detach flag) |
| 31 | DataFix | N/A | NOT routed through SetBalance - dedicated SetBalanceDataFix |
| 33 | CashoutRollback | Fast | SetBalanceCashoutRollback |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditTypeID=1 | Customer.SetBalanceDeposit | Caller (EXEC) | Fast-path delegate for deposits |
| CreditTypeID=2 | Customer.SetBalanceCashOut | Caller (EXEC) | Fast-path delegate for cashouts |
| CreditTypeID=4,22 | Customer.SetBalanceClosePosition | Caller (EXEC) | Fast-path delegate for position closes |
| CreditTypeID=6 | Customer.SetBalanceCompensation | Caller (EXEC) | Fast-path delegate for compensations |
| CreditTypeID=7 | Customer.SetBalanceBonus | Caller (EXEC) | Fast-path delegate for bonuses |
| CreditTypeID=11 | Customer.SetBalanceChargeBack | Caller (EXEC) | Fast-path delegate for chargebacks |
| CreditTypeID=12 | Customer.SetBalanceRefund | Caller (EXEC) | Fast-path delegate for refunds |
| CreditTypeID=16 | Customer.SetBalanceRefundAsChargeBack | Caller (EXEC) | Fast-path delegate for refund-as-chargeback |
| CreditTypeID=33 | Customer.SetBalanceCashoutRollback | Caller (EXEC) | Fast-path delegate for cashout rollbacks |
| @CID | Customer.CustomerMoney | MODIFIER | XLOCK + UPDATE Credit, TotalCash, BonusCredit (legacy path) |
| @CID | Customer.CustomerStatic | READ | IsReal, ProviderID, CountryID, tracking fields (legacy path) |
| @PositionID | Trade.Position | READ | Mirror detection (IsMirror, MirrorID, InstrumentID) |
| @PositionID | Trade.PositionTbl | READ | Mirror detection fallback (StatusID=2) |
| @PositionID | History.Position_Active | READ | Mirror detection fallback (closed positions) |
| @MirrorID | Trade.Mirror | MODIFIER | Amount update for mirror positions; RealizedEquity update on close |
| @InstrumentID | Trade.GetInstrument | READ | InstrumentTypeID=5 check (stock instrument validation) |
| - | Customer.SetBalanceInsertCredit_Native | Caller (EXEC) | Legacy path credit record writer |
| - | Internal.ActionsToExecute_MIMOOperations | INSERT | MIMO BSL recalculation trigger (types 11,12,16,26) |
| - | Trade.BSLUsersWhiteList | INSERT | BSL whitelist for MIMO window (types 11,12,16,26) |
| - | svcPayment (Service Broker) | SEND | Balance change notification to trade servers |
| @CID | Customer.Customer | READ | IsReal check for offline notification |
| @CID | Customer.Login | READ | Online status check for offline notification |
| - | Customer.SendMessage | Caller (EXEC) | Offline notification for deposits/compensations/bonuses |
| - | Customer.SendEvent | Caller (EXEC) | Zero-balance alert (event 9) |
| @BonusTypeID | BackOffice.BonusType | READ | HideFromAffwiz check for affiliate suppression |
| @CampaignID | BackOffice.Campaign | READ | CampaignCode lookup for affiliate tracking |
| @CID | Customer.CustomerStatic | READ | Affiliate tracking fields (SerialID, ProviderID, etc.) |
| - | Broker.QueuePiggyBankAdd | Caller (EXEC) | Affiliate / PiggyBank event reporting |
| - | BackOffice.UpsertMIMOAggregation | Caller (EXEC) | On-the-fly MIMO aggregation (types 1,2,5,7,8,9,15) |
| @WithdrawID | Billing.Withdraw | READ | Cashout fee lookup for reverse cashout / cashout request |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade position open/close pipelines | External | Caller | All trading events that modify balance |
| Billing payment processing | External | Caller | Deposit, cashout, chargeback, refund events |
| BackOffice administrative tools | External | Caller | Manual compensations, bonuses, campaign assignments |
| Mirror management services | External | Caller | Mirror registration, money movement, detachment |
| Championship system | External | Caller | Championship winner payouts (CreditTypeID=5) |
| IB (Introducing Broker) system | External | Caller | IB sync events (CreditTypeID=10) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetBalance (procedure)
+-- FAST PATH DELEGATION:
|   +-- Customer.SetBalanceDeposit (procedure) [CreditTypeID=1]
|   +-- Customer.SetBalanceCashOut (procedure) [CreditTypeID=2]
|   +-- Customer.SetBalanceClosePosition (procedure) [CreditTypeID=4,22]
|   +-- Customer.SetBalanceCompensation (procedure) [CreditTypeID=6]
|   +-- Customer.SetBalanceBonus (procedure) [CreditTypeID=7]
|   +-- Customer.SetBalanceChargeBack (procedure) [CreditTypeID=11]
|   +-- Customer.SetBalanceRefund (procedure) [CreditTypeID=12]
|   +-- Customer.SetBalanceRefundAsChargeBack (procedure) [CreditTypeID=16]
|   +-- Customer.SetBalanceCashoutRollback (procedure) [CreditTypeID=33]
|   +-- BackOffice.UpsertMIMOAggregation (procedure) [CreditTypeIDs 1,2,7]
+-- LEGACY PATH:
    +-- Customer.CustomerMoney (table) [XLOCK + UPDATE Credit, TotalCash, BonusCredit]
    +-- Customer.CustomerStatic (table) [READ IsReal, tracking fields]
    +-- Trade.Position (table) [READ mirror detection]
    +-- Trade.PositionTbl (table) [READ mirror detection fallback]
    +-- History.Position_Active (table) [READ mirror detection fallback]
    +-- Trade.Mirror (table) [UPDATE Amount, RealizedEquity for mirror positions]
    +-- Trade.GetInstrument (view/function) [READ InstrumentTypeID for stock validation]
    +-- Customer.SetBalanceInsertCredit_Native (procedure) [INSERT credit record]
    +-- Internal.ActionsToExecute_MIMOOperations (table) [INSERT MIMO trigger]
    +-- Trade.BSLUsersWhiteList (table) [INSERT BSL whitelist]
    +-- Customer.Customer (view/table) [READ IsReal for offline check]
    +-- Customer.Login (table) [READ online status]
    +-- Customer.SendMessage (procedure) [offline notification]
    +-- Customer.SendEvent (procedure) [zero-balance alert]
    +-- BackOffice.BonusType (table) [READ HideFromAffwiz]
    +-- BackOffice.Campaign (table) [READ CampaignCode]
    +-- Broker.QueuePiggyBankAdd (procedure) [affiliate tracking]
    +-- BackOffice.UpsertMIMOAggregation (procedure) [CreditTypeIDs 5,8,9,15]
    +-- Billing.Withdraw (table) [READ Fee for cashout events]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalanceDeposit | Procedure | Fast-path delegate for CreditTypeID=1 |
| Customer.SetBalanceCashOut | Procedure | Fast-path delegate for CreditTypeID=2 |
| Customer.SetBalanceClosePosition | Procedure | Fast-path delegate for CreditTypeID=4,22 |
| Customer.SetBalanceCompensation | Procedure | Fast-path delegate for CreditTypeID=6 |
| Customer.SetBalanceBonus | Procedure | Fast-path delegate for CreditTypeID=7 |
| Customer.SetBalanceChargeBack | Procedure | Fast-path delegate for CreditTypeID=11 |
| Customer.SetBalanceRefund | Procedure | Fast-path delegate for CreditTypeID=12 |
| Customer.SetBalanceRefundAsChargeBack | Procedure | Fast-path delegate for CreditTypeID=16 |
| Customer.SetBalanceCashoutRollback | Procedure | Fast-path delegate for CreditTypeID=33 |
| Customer.CustomerMoney | Table | XLOCK + UPDATE Credit, TotalCash, BonusCredit (legacy) |
| Customer.CustomerStatic | Table | SELECT IsReal, ProviderID, CountryID, tracking fields |
| Trade.Position | Table | SELECT mirror detection (IsMirror, MirrorID, InstrumentID) |
| Trade.PositionTbl | Table | SELECT mirror detection fallback |
| History.Position_Active | Table | SELECT mirror detection fallback |
| Trade.Mirror | Table | UPDATE Amount, RealizedEquity for mirror positions |
| Trade.GetInstrument | View/Function | SELECT InstrumentTypeID for stock/mirror edge case |
| Customer.SetBalanceInsertCredit_Native | Procedure | EXEC credit record writer (legacy path) |
| Internal.ActionsToExecute_MIMOOperations | Table | INSERT MIMO trigger (types 11,12,16,26) |
| Trade.BSLUsersWhiteList | Table | INSERT BSL whitelist entry |
| Customer.Customer | View/Table | SELECT IsReal for offline notification check |
| Customer.Login | Table | SELECT online status check |
| Customer.SendMessage | Procedure | EXEC offline notification |
| Customer.SendEvent | Procedure | EXEC zero-balance alert |
| BackOffice.BonusType | Table | SELECT HideFromAffwiz flag |
| BackOffice.Campaign | Table | SELECT CampaignCode |
| Broker.QueuePiggyBankAdd | Procedure | EXEC affiliate/PiggyBank tracking |
| BackOffice.UpsertMIMOAggregation | Procedure | EXEC MIMO on-the-fly aggregation |
| Billing.Withdraw | Table | SELECT Fee for cashout-related svcPayment messages |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade position pipelines | External | Balance modification entry point for position opens/closes |
| Billing payment processing | External | Entry point for deposit/cashout/refund events |
| BackOffice administrative tools | External | Entry point for compensation, bonus, manual adjustments |
| Mirror management services | External | Entry point for mirror registration, cash movement |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Fast-path early return | Architecture | RETURN(0) after fast-path block; legacy code does NOT run for modern CreditTypeIDs |
| XLOCK + HOLDLOCK | Concurrency | Prevents concurrent balance modifications; acquired on CustomerMoney row before any updates in legacy path |
| @Payment BIGINT | Type evolution | Changed from INT in June 2018 to support amounts >$21M in cents |
| CreditTypeID=31 not handled | Design | DataFix not routed through SetBalance - callers must use SetBalanceDataFix/SetBalanceDataFixDebug directly |
| Mirror vs. CustomerMoney | Design | Mirror positions (IsMirror=1) do not update CustomerMoney.Credit; only Trade.Mirror.Amount changes |
| TotalCash frozen for 18/19/20/21 | Design | Moving money to/from mirrors doesn't change TotalCash (it's an internal cash redistribution, not an external event) |
| Credit absorption formula | Affiliate | For ChargeBack/Refund events (Type=4/5), @Payment adjusted to net-effective amount to prevent over-reporting of negative-credit scenarios |
| CreditTypeID normalization | Credit record | Types 22/24 stored as 4; types 23/25 stored as 3 in History.ActiveCredit for clean querying |
| @ChampionshipID=NULL detection | Business | If @ChampionshipID is not NULL and CreditTypeID=7, stored as 5 (Championship) in credit record |
| File size | Historical | SetBalance.sql is 92.3KB - one of the largest procedures in the schema. The fast-path refactoring has reduced the code that actually executes for most events, but legacy path remains for backward compatibility. |

---

## 8. Sample Queries

### 8.1 Credit history by CreditTypeID category

```sql
SELECT
    CASE
        WHEN acb.CreditTypeID = 1  THEN 'Deposit'
        WHEN acb.CreditTypeID = 2  THEN 'CashOut'
        WHEN acb.CreditTypeID = 3  THEN 'OpenPosition'
        WHEN acb.CreditTypeID = 4  THEN 'ClosePosition'
        WHEN acb.CreditTypeID = 5  THEN 'ChampionshipWinner'
        WHEN acb.CreditTypeID = 6  THEN 'Compensation'
        WHEN acb.CreditTypeID = 7  THEN 'Bonus'
        WHEN acb.CreditTypeID = 11 THEN 'ChargeBack'
        WHEN acb.CreditTypeID = 12 THEN 'Refund'
        WHEN acb.CreditTypeID = 16 THEN 'RefundAsChargeBack'
        WHEN acb.CreditTypeID = 33 THEN 'CashoutRollback'
        ELSE 'Other (' + CAST(acb.CreditTypeID AS VARCHAR) + ')'
    END AS EventType,
    COUNT(*) AS EventCount,
    SUM(acb.Payment) AS TotalAmountUSD
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
WHERE acb.CID = 12345
GROUP BY acb.CreditTypeID
ORDER BY acb.CreditTypeID
```

### 8.2 Recent balance events for a customer

```sql
SELECT TOP 20
    acb.CreditID,
    acb.CreditTypeID,
    ct.Name AS EventType,
    acb.Payment AS AmountUSD,
    acb.Credit AS BalanceAfter,
    acb.TotalCash AS TotalCashAfter,
    acb.RealizedEquity AS EquityAfter,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
JOIN Dictionary.CreditType ct WITH (NOLOCK) ON ct.CreditTypeID = acb.CreditTypeID
WHERE acb.CID = 12345
ORDER BY acb.Occurred DESC
```

### 8.3 Check which path was taken for a credit event

```sql
-- CreditTypeIDs 1,2,4,6,7,11,12,16,22,33 -> fast path (specialized SP)
-- All others -> legacy path (inline in SetBalance)
SELECT CreditTypeID,
    CASE WHEN CreditTypeID IN (1,2,4,6,7,11,12,16,22,33)
         THEN 'Fast-path (delegated)'
         ELSE 'Legacy-path (inline)'
    END AS ExecutionPath
FROM Dictionary.CreditType
WHERE CreditTypeID < 40
ORDER BY CreditTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 30 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (92.3KB full read) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetBalance | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetBalance.sql*
