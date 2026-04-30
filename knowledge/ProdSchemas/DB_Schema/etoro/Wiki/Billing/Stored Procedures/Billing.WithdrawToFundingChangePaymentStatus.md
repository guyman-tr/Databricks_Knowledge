# Billing.WithdrawToFundingChangePaymentStatus

> Transitions a WithdrawToFunding payment leg to a new CashoutStatusID, with guards against illegal state transitions, and delegates the write + audit-log to UpdateWithdraw2Funding via a TBL_Withdraw2Funding TVP.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ID (WithdrawToFunding.ID) + @CashoutStatusID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawToFundingChangePaymentStatus` is the standard state-transition procedure for a `Billing.WithdrawToFunding` payment leg. After a withdrawal payment leg has been submitted to a payment provider and moves through its lifecycle - from InProcess (2) through provider-specific intermediate states (8-12) to Processed (3) or Rejected (7) - payout services call this procedure to record each status change.

The procedure enforces two guards: it prevents transitioning a payment leg that is not currently in an "in-flight" state (must be one of 2, 8, 9, 10, 11, 12), and it prevents double-transition to status 11 (SentToBilling) - the state where the payment is handed off to the billing engine for final settlement. Status 11 is irreversible via this procedure because re-setting it would re-trigger the auto-payment clock.

When `@CashoutStatusID=11` (SentToBilling), the procedure sets `AutoPaymentStartDate` to the current UTC timestamp - this marks the moment the billing engine begins auto-payment processing, and is used downstream to calculate SLA compliance and to trigger time-based payment escalation.

The billing service identity (`@ManagerID = -1`) is explicitly handled: when -1 is passed, the existing `ManagerID` on the WTF record is preserved rather than overwritten, so that the audit trail shows the human operator who originally initiated the payment, not the service account that ran the status change.

The actual write path (UPDATE to `Billing.WithdrawToFunding` + INSERT to `History.WithdrawToFundingAction`) is delegated to `Billing.UpdateWithdraw2Funding` via a `Billing.TBL_Withdraw2Funding` TVP (DBA-648 refactor, 2021-09-23).

---

## 2. Business Logic

### 2.1 Status 11 (SentToBilling) Idempotency Guard

**What**: Prevents a payment leg from being sent to the billing engine twice.

**Columns/Parameters Involved**: `@CashoutStatusID`, `CashoutStatusID` (on `Billing.WithdrawToFunding`)

**Rules**:
- IF @CashoutStatusID = 11:
  - Check `Billing.WithdrawToFunding` WHERE ID=@ID AND CashoutStatusID=11
  - If EXISTS -> RAISERROR "Withdraw to funding is already In status 11 (SentToBilling) And cannot be updated again to 11"; RETURN 0
- The error is non-fatal (severity 16, state 1); no transaction is started before this check

**Why SentToBilling is special**: Status 11 triggers `AutoPaymentStartDate` to be stamped, which starts the auto-payment timer. A duplicate transition would reset this timestamp, potentially causing SLA violations or double-payment triggers in downstream systems.

### 2.2 In-Flight Status Guard

**What**: Prevents state transitions on payment legs that are not currently active.

**Columns/Parameters Involved**: `@ID`, `CashoutStatusID` (on `Billing.WithdrawToFunding`)

**Rules**:
- Check `Billing.WithdrawToFunding` WHERE ID=@ID AND CashoutStatusID IN (2,8,9,10,11,12)
- If NOT EXISTS -> RAISERROR "Withdraw to funding is Not In InProcess status"; RETURN 0
- This prevents transitioning legs that are already in terminal states (3=Processed, 4=Canceled, 7=Rejected) or that were never in-flight (1=Pending)

**Valid source states**:
```
2  = InProcess (standard active processing state)
8  = (provider-specific intermediate state)
9  = (provider-specific intermediate state)
10 = (provider-specific intermediate state)
11 = SentToBilling (already handed to billing engine - can still be updated further)
12 = (provider-specific intermediate state)
```

### 2.3 AutoPaymentStartDate Stamp for SentToBilling (Status 11)

**What**: Records when a payment leg was handed to the billing engine for settlement processing.

**Columns/Parameters Involved**: `@CashoutStatusID`, `AutoPaymentStartDate`, `@Now`

**Rules**:
- `AutoPaymentStartDate = CASE WHEN @CashoutStatusID=11 THEN @Now ELSE NULL END`
- When transitioning to 11: sets AutoPaymentStartDate to current UTC time
- All other transitions: passes NULL for AutoPaymentStartDate (UpdateWithdraw2Funding ISNULL patch preserves existing value)
- This timestamp drives downstream billing SLA monitoring and auto-payment escalation logic

### 2.4 ManagerID Billing-Service Passthrough

**What**: Preserves the original operator's identity when the billing service executes status transitions.

**Columns/Parameters Involved**: `@ManagerID`

**Rules**:
- `ManagerID = CASE WHEN @ManagerID != -1 THEN @ManagerID ELSE NULL END`
- @ManagerID=-1 is the billing service identity sentinel value
- When -1: NULL is passed in the TVP, and UpdateWithdraw2Funding's ISNULL patch preserves the existing ManagerID
- When any other value: the new ManagerID overwrites the existing one
- This ensures the audit trail in `History.WithdrawToFundingAction` shows the human operator, not "-1"

### 2.5 Conditional Field Updates

**What**: Several optional fields are only updated when explicitly provided (non-zero / non-NULL).

**Rules**:
- `ProtocolMIDSettingsID`: `CASE WHEN @ProtocolMIDSettingsID <> 0 THEN @ProtocolMIDSettingsID ELSE NULL END` - zero means "preserve existing"
- `ResponseID`: `CASE WHEN @ResponseID IS NOT NULL THEN @ResponseID ELSE NULL END` - NULL means "preserve existing" (added PAYUA-2900)
- `RequestExecuteEntryMethodId`: `CASE WHEN @RequestExecuteEntryMethodId <> 0 THEN @RequestExecuteEntryMethodId ELSE NULL END` - zero means "not specified, preserve existing"
- `MerchantAccountID`: always passed through directly (no conditional; @MerchantAccountID=0 is a valid "no merchant account" value)
- `CashoutActionStatusID`: hardcoded to 2 (Processed) in the TVP - every status transition via this procedure is recorded as a "Processed" action in the history

### 2.6 DBA-648 TVP Delegation Pattern

**What**: The actual write to `Billing.WithdrawToFunding` and the corresponding audit insert into `History.WithdrawToFundingAction` are delegated to `Billing.UpdateWithdraw2Funding` via a TVP.

**Rules**:
- Populate `@InfoWTF Billing.TBL_Withdraw2Funding` with the transition fields
- `EXECUTE @ID = Billing.UpdateWithdraw2Funding @InfoWTF` - @ID receives the return value (rows updated)
- The original direct UPDATE + INSERT code remains commented out in the DDL (historical reference)
- This ensures all WTF mutations go through the same write path with guaranteed history logging

**Diagram**:
```
[CALL] WithdrawToFundingChangePaymentStatus (@ID, @CashoutStatusID, ...)
    |
    v
IF @CashoutStatusID=11:
    Check: WTF.CashoutStatusID != 11 already
        |-- EXISTS (already 11) -> RAISERROR, RETURN 0
    v
Check: WTF.CashoutStatusID IN (2,8,9,10,11,12)
    |-- NOT EXISTS -> RAISERROR "Not In InProcess status", RETURN 0
    v
BEGIN TRY / BEGIN TRAN
    Build @InfoWTF TVP:
        ID = @ID
        CashoutStatusID = @CashoutStatusID
        AutoPaymentStartDate = (NOW if status=11, else NULL)
        ProtocolMIDSettingsID = (value if != 0, else NULL)
        MerchantAccountID = @MerchantAccountID
        CashoutActionStatusID = 2 (hardcoded: Processed)
        ManagerID = (value if != -1, else NULL)
        Remark = @Remark
        ResponseID = (value if NOT NULL, else NULL)
        RequestExecuteEntryMethodId = (value if != 0, else NULL)
    EXECUTE Billing.UpdateWithdraw2Funding @InfoWTF
        -> UPDATE Billing.WithdrawToFunding (patch: ISNULL preserves existing for NULL fields)
        -> INSERT History.WithdrawToFundingAction (via OUTPUT clause)
COMMIT / RETURN 0
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int | NO | - | CODE-BACKED | Required. PK of `Billing.WithdrawToFunding` (the payment leg to transition). Must currently be in CashoutStatusID IN (2,8,9,10,11,12) or validation fails. |
| 2 | @ManagerID | int | NO | - | CODE-BACKED | Required. Manager or service account performing this transition. Special value -1 = billing service (preserves existing ManagerID in the audit record rather than overwriting with -1). |
| 3 | @Remark | varchar(255) | NO | - | CODE-BACKED | Required. Free-text audit note for this status transition. Written to `History.WithdrawToFundingAction.Remark` (not stored on the live WTF record itself). |
| 4 | @CashoutStatusID | int | NO | - | CODE-BACKED | Required. The NEW status to assign to the payment leg. Must differ from current status; for 11 (SentToBilling) must not already be 11. Common transitions: 2->11 (submit to billing), 11->3 (billing confirms settlement), 2->7 (provider rejects). |
| 5 | @ProtocolMIDSettingsID | int | YES | 0 | CODE-BACKED | Optional. Protocol MID Settings ID to record on this transition. Default=0 means "no change" (NULL passed to UpdateWithdraw2Funding, existing value preserved). Non-zero value overwrites the existing ProtocolMIDSettingsID. Added FB-52952 (2018-01-11). |
| 6 | @MerchantAccountID | int | YES | 0 | CODE-BACKED | Optional. Merchant account ID used for this payment processing step. Always passed through to the TVP (0 is a valid value meaning "no specific merchant account"). Added PAYUS-20163 (2020-12-27). |
| 7 | @ResponseID | int | YES | NULL | CODE-BACKED | Optional. Payment provider response record ID. NULL means "no change" (existing value preserved via ISNULL patch in UpdateWithdraw2Funding). Non-NULL overwrites existing ResponseID. Added PAYUA-2900 (2021-11-10). |
| 8 | @RequestExecuteEntryMethodId | int | YES | 0 | CODE-BACKED | Optional. Entry method that triggered this payment execution (e.g., 0=None, 1=Auto, 2=Manually). Default=0 means "not specified" (NULL passed, existing preserved). Added 2023-07-11. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ID | Billing.WithdrawToFunding | Validation + Indirect Update | Validates status; delegated update via UpdateWithdraw2Funding |
| (via UpdateWithdraw2Funding) | History.WithdrawToFundingAction | Indirect Insert | Every status transition is mirrored to the audit history table |
| @InfoWTF | Billing.TBL_Withdraw2Funding | TVP Type | Staging type for the delegated write call |
| (callee) | Billing.UpdateWithdraw2Funding | Callee | Handles the actual UPDATE + history INSERT |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawAndWithdrawToFundingAdd | EXEC | Caller | Transitions payment leg status after composite withdraw+WTF creation |
| Billing.PayoutProcess_Update | EXEC | Caller | Core payout processing loop - transitions WTF through provider interaction states |
| Billing.RedeemPayoutProcess_Update | EXEC | Caller | Redeem/voucher payout processing - same state transition pattern |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingChangePaymentStatus (procedure)
├── Billing.WithdrawToFunding (table) [validation reads]
├── Billing.TBL_Withdraw2Funding (UDT) [TVP type]
└── Billing.UpdateWithdraw2Funding (procedure)
    ├── Billing.WithdrawToFunding (table) [UPDATE]
    └── History.WithdrawToFundingAction (table) [INSERT via OUTPUT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Validation: checks current CashoutStatusID via EXISTS queries |
| Billing.TBL_Withdraw2Funding | User Defined Type | TVP type for passing update data to UpdateWithdraw2Funding |
| Billing.UpdateWithdraw2Funding | Procedure | Delegates the actual patch UPDATE + history INSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawAndWithdrawToFundingAdd | Procedure | Post-creation status transition |
| Billing.PayoutProcess_Update | Procedure | Core payout processing state transitions |
| Billing.RedeemPayoutProcess_Update | Procedure | Redeem payout processing state transitions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BEGIN TRY/CATCH with transaction | Design | COMMIT on success; ROLLBACK if @@TRANCOUNT=1; COMMIT (preserve outer) if @@TRANCOUNT>1; RAISERROR 60000 with original error number re-raised to caller |
| Status 11 idempotency guard | Business Rule | Cannot transition to SentToBilling (11) if already at 11. Pre-transaction check; no rollback needed. |
| In-flight status guard | Business Rule | Source status must be IN (2,8,9,10,11,12). Prevents mutating terminal or pre-flight payment legs. |
| CashoutActionStatusID=2 hardcoded | Design | Every transition via this SP is recorded as "Processed" (2) action type in history. |
| DBA-648 refactor (2021-09-23) | Architecture | Original direct UPDATE + History INSERT commented out; all writes now via UpdateWithdraw2Funding TVP. |
| SELECT TOP 1 (before INSERT) | Performance | `SELECT TOP 1 * FROM Billing.WithdrawToFunding` before the TVP population - forces SQL Server to include WTF columns in the query plan compilation, preventing "lazy spool" optimization issues. No data is returned. |

---

## 8. Sample Queries

### 8.1 Transition a payment leg to SentToBilling (status 11)

```sql
EXEC Billing.WithdrawToFundingChangePaymentStatus
    @ID = 9876543,
    @ManagerID = 42,
    @Remark = 'Payment submitted to billing engine for settlement',
    @CashoutStatusID = 11,           -- SentToBilling
    @ProtocolMIDSettingsID = 55,     -- MID used for this payment
    @MerchantAccountID = 12;
```

### 8.2 Transition to Processed (status 3) by the billing service

```sql
EXEC Billing.WithdrawToFundingChangePaymentStatus
    @ID = 9876543,
    @ManagerID = -1,                 -- -1 = billing service, preserve existing ManagerID
    @Remark = 'Settlement confirmed',
    @CashoutStatusID = 3,            -- Processed
    @ResponseID = 112233;            -- Provider response record
```

### 8.3 Check payment leg status before transitioning

```sql
SELECT
    wtf.ID,
    wtf.WithdrawID,
    wtf.CashoutStatusID,
    wtf.ManagerID,
    wtf.ProtocolMIDSettingsID,
    wtf.AutoPaymentStartDate,
    wtf.ModificationDate
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.ID = 9876543;
-- CashoutStatusID must be IN (2,8,9,10,11,12) for the transition to succeed
-- If CashoutStatusID=11 and target is 11, the procedure will RAISERROR
```

### 8.4 Verify the transition in audit history

```sql
SELECT TOP 5
    wfa.WithdrawToFundingActionID,
    wfa.BW2F_ID AS WTF_ID,
    wfa.CashoutStatusID,
    wfa.CashoutActionStatusID,
    wfa.ManagerID,
    wfa.Remark,
    wfa.ModificationDate
FROM History.WithdrawToFundingAction wfa WITH (NOLOCK)
WHERE wfa.BW2F_ID = 9876543
ORDER BY wfa.WithdrawToFundingActionID DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| FB-52952 (referenced in DDL comment, 2018-01-11) | Jira | Added @ProtocolMIDSettingsID parameter to capture MID routing reference during status transitions |
| PAYUS-20163 (referenced in DDL comment, 2020-12-27) | Jira | Added @MerchantAccountID parameter to record merchant account used for the payment |
| DBA-648 (referenced in DDL comment, 2021-09-23) | Jira | Refactored direct UPDATE + History INSERT to delegate via UpdateWithdraw2Funding TVP - standardized WTF write path |
| PAYUA-2900 (referenced in DDL comment, 2021-11-10) | Jira | Added @ResponseID parameter to capture payment provider response record reference on status transitions |
| Payout Design (Confluence /spaces/MG/pages/1182334977) | Confluence | Page found in search but body not accessible via API (404) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira (4 tickets referenced in DDL comments) | Procedures: 3 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingChangePaymentStatus | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingChangePaymentStatus.sql*
