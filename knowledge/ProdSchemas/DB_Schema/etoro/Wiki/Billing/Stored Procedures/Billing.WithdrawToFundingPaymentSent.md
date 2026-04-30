# Billing.WithdrawToFundingPaymentSent

> Transitions a single WithdrawToFunding payment leg from InProcess (2) to Payment Sent (6), with a status guard and a corresponding audit history INSERT.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ID (WithdrawToFunding.ID) - single leg transition to status 6 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawToFundingPaymentSent` records the moment a withdrawal payment instruction has been dispatched to the payment provider or banking system. CashoutStatusID=6 ("Payment Sent") represents the intermediate state after InProcess (2) where the funds have been sent but not yet confirmed as settled by the receiving party.

This status is used in payment flows where there is an observable "sent" event distinct from final confirmation - for example, when a bank wire is initiated but the provider has not yet confirmed receipt, or when a card credit is submitted but not yet posted. The payout service calls this procedure after successfully transmitting the payment instruction to the external system.

The procedure enforces a strict single-source state: only legs currently at CashoutStatusID=2 (InProcess) can be transitioned here. This prevents marking a payment as "sent" when it is in a state that doesn't logically precede being sent (e.g., already at Processed, Rejected, or Cancelled).

Note: Unlike `Billing.WithdrawToFundingChangePaymentStatus`, this procedure does not use the DBA-648 TVP delegation pattern. It uses direct UPDATE + INSERT, suggesting it either predates the DBA-648 refactor or was not migrated because of its narrow scope (single status, single target state).

---

## 2. Business Logic

### 2.1 InProcess Status Guard

**What**: Validates the payment leg is in the expected source state before transitioning.

**Columns/Parameters Involved**: `@ID`, `CashoutStatusID`

**Rules**:
- `IF NOT EXISTS (SELECT * FROM Billing.WithdrawToFunding WHERE ID = @ID AND CashoutStatusID = 2)` -> RAISERROR "Withdraw to funding is not in InProcess status"; RETURN 0
- Pre-transaction check: no BEGIN TRAN has been opened at this point, so no rollback is needed
- This rejects transitions from all other states: Pending (1), Payment Sent (6) [already sent], Processed (3), Cancelled (4), etc.

### 2.2 Status Transition to Payment Sent (6)

**What**: Moves the payment leg to CashoutStatusID=6 and updates the modification timestamp.

**Columns/Parameters Involved**: `CashoutStatusID`, `ModificationDate`

**Rules**:
- `SET CashoutStatusID = 6` (Payment Sent) - hardcoded target state
- `SET ModificationDate = GETUTCDATE()` - UTC timestamp of the transition
- No other fields on `Billing.WithdrawToFunding` are modified

### 2.3 History INSERT (Post-Update Read Pattern)

**What**: Creates an audit record in `History.WithdrawToFundingAction` reflecting the post-transition state.

**Columns/Parameters Involved**: `History.WithdrawToFundingAction`, `BW2F_ID`, `CashoutStatusID`, `CashoutActionStatusID`

**Rules**:
- `INSERT INTO History.WithdrawToFundingAction SELECT ... FROM Billing.WithdrawToFunding WITH (NOLOCK) WHERE ID = @ID`
- The SELECT reads AFTER the UPDATE in the same transaction: CashoutStatusID in the history row is 6 (Payment Sent)
- `CashoutActionStatusID = 2` (Processed) - hardcoded action type for this history entry
- `ManagerID = @ManagerID` - overrides whatever ManagerID is on the WTF row
- `ModificationDate = GETUTCDATE()` - new timestamp for the history entry
- `Remark = @Remark` - caller-supplied audit note
- `BW2F_ID = @ID` - FK back to the WithdrawToFunding.ID

**Diagram**:
```
[CALL] WithdrawToFundingPaymentSent (@ID, @ManagerID, @Remark)
    |
    v
Check: WTF.CashoutStatusID = 2 (InProcess)
    |-- NOT EXISTS -> RAISERROR, RETURN 0
    v
BEGIN TRY / BEGIN TRAN
    UPDATE WTF: CashoutStatusID = 6, ModificationDate = GETUTCDATE()
    INSERT History (read from WTF post-UPDATE):
        CashoutStatusID = 6 (Payment Sent)
        CashoutActionStatusID = 2 (Processed)
        ManagerID = @ManagerID
        ModificationDate = GETUTCDATE()
        Remark = @Remark
COMMIT / RETURN 0
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int | NO | - | CODE-BACKED | Required. PK of `Billing.WithdrawToFunding` (the payment leg to transition). Must currently have CashoutStatusID=2 (InProcess) or RAISERROR is raised. |
| 2 | @ManagerID | int | NO | - | CODE-BACKED | Required. Manager or service account recording the payment dispatch. Written to the new `History.WithdrawToFundingAction` row as the audit operator. |
| 3 | @Remark | varchar(255) | NO | - | CODE-BACKED | Required. Free-text audit note describing the payment-sent event. Written only to `History.WithdrawToFundingAction.Remark`, not stored on the live WTF record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ID | Billing.WithdrawToFunding | Validation + UPDATE | Guards on CashoutStatusID=2; sets CashoutStatusID=6 |
| @ID | History.WithdrawToFundingAction | INSERT | Records the payment-sent event in the audit log |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payout processing service (application) | @ID, @ManagerID, @Remark | Caller | Called after successfully dispatching a payment instruction to an external provider |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingPaymentSent (procedure)
├── Billing.WithdrawToFunding (table) [validation + UPDATE + SELECT for history]
└── History.WithdrawToFundingAction (table) [INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Validates CashoutStatusID=2; UPDATE target; source for history INSERT |
| History.WithdrawToFundingAction | Table | INSERT target for the payment-sent audit record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payout processing service (application) | External application | Caller - records payment dispatch event |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| BEGIN TRY/CATCH with transaction | Design | COMMIT on success; ROLLBACK if @@TRANCOUNT=1; COMMIT (preserve outer) if @@TRANCOUNT>1; RAISERROR 60000 re-raised to caller |
| InProcess-only guard | Business Rule | CashoutStatusID must be 2 before transition. Pre-transaction check. |
| Target status hardcoded | Design | CashoutStatusID=6 (Payment Sent) is the only possible output status - no @CashoutStatusID parameter |
| Direct UPDATE + INSERT (not DBA-648) | Architecture | Does not use UpdateWithdraw2Funding TVP pattern. Predates or was excluded from DBA-648 migration scope. |
| History read after UPDATE | Design | History INSERT SELECTs from Billing.WithdrawToFunding WITH(NOLOCK) after the UPDATE; CashoutStatusID in history row is 6, not the prior value 2. |

---

## 8. Sample Queries

### 8.1 Transition a payment leg to Payment Sent (status 6)

```sql
EXEC Billing.WithdrawToFundingPaymentSent
    @ID = 9876543,
    @ManagerID = 77,
    @Remark = 'Wire transfer dispatched to correspondent bank';
```

### 8.2 Check which payment legs are in InProcess status (eligible for this procedure)

```sql
SELECT TOP 50
    wtf.ID,
    wtf.WithdrawID,
    wtf.FundingID,
    wtf.CashoutStatusID,
    wtf.Amount,
    wtf.DepotID,
    wtf.ModificationDate
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.CashoutStatusID = 2  -- InProcess: eligible for WithdrawToFundingPaymentSent
ORDER BY wtf.ModificationDate;
```

### 8.3 Verify the transition in audit history

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
-- Most recent row should show CashoutStatusID=6, CashoutActionStatusID=2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 7.5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT (called from application) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingPaymentSent | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingPaymentSent.sql*
