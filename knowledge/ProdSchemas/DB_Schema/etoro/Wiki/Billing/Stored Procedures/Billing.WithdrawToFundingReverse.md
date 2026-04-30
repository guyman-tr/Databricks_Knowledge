# Billing.WithdrawToFundingReverse

> Cancels (reverses) a specific WithdrawToFunding leg - sets CashoutStatusID=4 (Cancelled) after validating the withdrawal is not from an IB customer and has not already been processed; writes audit history via UpdateWithdraw2Funding and UpsertWithdraw.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (@WithdrawID, @FundingID, @ID) - uniquely identifies the WTF leg being reversed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the official reversal (cancellation) endpoint for a WithdrawToFunding leg. When a payment leg needs to be cancelled - for example, when the customer's withdrawal is being rerouted to a different funding instrument, an operational error occurred, or the withdrawal needs to be restarted from a clean state - the Cashout Service calls this procedure to set the WTF leg to status 4 (Cancelled).

"Reverse" is semantically distinct from "Reject" (`Billing.WithdrawToFundingReject`): Reverse sets status 4 (Cancelled), indicating the payment leg was administratively cancelled and may be retried. Reject sets status 7 (Rejected), indicating a definitive payment-layer refusal. In practice both prevent further processing of the leg, but the status value carries different meaning for reporting and retry logic.

The procedure shares identical parameter signatures and pre-flight validation logic with `WithdrawToFundingReject`. The only substantive difference in the body is the `CashoutStatusID=4` vs `CashoutStatusID=7` assignment. Both were originally independent implementations (Reverse dates to June 2014, Fogbugz 22894) and both were refactored to use the `UpdateWithdraw2Funding` + `UpsertWithdraw` pattern in September 2021 (DBA-648).

The four pre-flight guards are identical to `WithdrawToFundingReject`: IB customer check (60015), withdraw existence (60025), WTF existence (60025), already-processed guard (60025).

---

## 2. Business Logic

### 2.1 IB Customer Guard

**What**: IB (Introducing Broker) customer withdrawals cannot be reversed via this procedure.

**Columns/Parameters Involved**: `Customer.Customer.ProviderID`, `Trade.Provider.IsIB`, `Billing.Withdraw.CID`

**Rules**:
- Uses implicit JOIN syntax (comma-separated FROM): `Customer.Customer CCST, Trade.Provider TPRV, Billing.Withdraw BWDR`
- Conditions: `BWDR.WithdrawID=@WithdrawID AND CCST.CID=BWDR.CID AND CCST.ProviderID=TPRV.ProviderID AND TPRV.IsIB=1`
- If yes: `RAISERROR(60015, 16, 1)` and `RETURN 60015`
- Note: `WithdrawToFundingReject` uses explicit INNER JOIN syntax for the same check; functionally identical

### 2.2 Pre-Flight Existence and State Guards

**What**: Validates the withdrawal and WTF record exist and are reversible.

**Rules**:
- Guard 2: Withdraw exists -> RAISERROR(60025) "requested withdraw not found"
- Guard 3: WTF (WithdrawID+FundingID+ID) exists -> RAISERROR(60025) "requested withdraw funding not found"
- Guard 4: WTF CashoutStatusID != 3 (not already Processed) -> RAISERROR(60025) "requested withdraw already processed"

### 2.3 WTF Status Transition: -> Cancelled (4)

**What**: Sets the WTF leg to CashoutStatusID=4 (Cancelled) and logs audit history.

**Columns/Parameters Involved**: `CashoutStatusID=4`, `CashoutActionStatusID=2`, `ModificationDate`, `ManagerID`, `Remark`

**Rules**:
- Populates `@InfoWTF` with: WithdrawID, FundingID, ID, CashoutStatusID=4 (Cancelled), ModificationDate=GETUTCDATE(), ManagerID, CashoutActionStatusID=2 (processed), Remark
- `EXECUTE Billing.UpdateWithdraw2Funding @InfoWTF` -> updates WTF record + writes WTF history
- Populates `@InfoWithdraw` with: WithdrawID, ManagerID, SessionID
- `EXECUTE Billing.UpsertWithdraw @Withdraw=@InfoWithdraw, @HistoryOnlyRemark=@Remark` -> updates Withdraw + writes Withdraw history
- Both wrapped in BEGIN TRANSACTION / COMMIT

**Key difference from Reject**:

| Aspect | WithdrawToFundingReverse | WithdrawToFundingReject |
|--------|--------------------------|------------------------|
| WTF status set | 4 (Cancelled) | 7 (Rejected) |
| Semantic meaning | Administrative cancellation; may retry | Payment-layer refusal; definitive |
| Date of creation | June 2014 (Fogbugz 22894) | September 2021 (DBA-648) |

**Diagram**:
```
Pre-flight checks (4 guards):
  1. IB customer? -> RAISERROR(60015)
  2. Withdraw exists? -> RAISERROR(60025)
  3. WTF (WithdrawID+FundingID+ID) exists? -> RAISERROR(60025)
  4. WTF CashoutStatusID=3? -> RAISERROR(60025)

BEGIN TRANSACTION:
  INSERT @InfoWTF (WithdrawID, FundingID, ID, CashoutStatusID=4, ManagerID, CashoutActionStatusID=2, Remark)
  EXEC Billing.UpdateWithdraw2Funding @InfoWTF
    -> UPDATE Billing.WithdrawToFunding SET CashoutStatusID=4
    -> INSERT History.WithdrawToFundingAction (status=4, Remark)

  INSERT @InfoWithdraw (WithdrawID, ManagerID, SessionID)
  EXEC Billing.UpsertWithdraw @Withdraw=@InfoWithdraw, @HistoryOnlyRemark=@Remark
    -> UPDATE Billing.Withdraw SET ManagerID, SessionID
    -> INSERT History.WithdrawAction (Comment=@Remark)
COMMIT
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | integer | NO | - | CODE-BACKED | Input parameter. Primary key of the withdrawal in `Billing.Withdraw`. Used in all four pre-flight guards and as the write key. |
| 2 | @FundingID | integer | NO | - | CODE-BACKED | Input parameter. Funding record ID from `Billing.Funding`. With `@WithdrawID` and `@ID` identifies the specific WTF leg. |
| 3 | @ManagerID | integer | NO | - | CODE-BACKED | Input parameter. Manager performing the reversal. Written to `Billing.WithdrawToFunding.ManagerID` and `Billing.Withdraw.ManagerID`. |
| 4 | @Remark | varchar(255) | YES | - | CODE-BACKED | Input parameter. Reversal reason or note. Passed as `@HistoryOnlyRemark` to `UpsertWithdraw` (history audit trail only) and included in WTF history via `UpdateWithdraw2Funding`. |
| 5 | @ID | int | NO | - | CODE-BACKED | Input parameter. `Billing.WithdrawToFunding.ID` - the WTF payment leg to reverse/cancel. |
| 6 | @SessionID | bigint | YES | NULL | CODE-BACKED | Input parameter. Optional audit session identifier. Written to `Billing.Withdraw.SessionID` via `@InfoWithdraw` TVP. Added 20/10/2015 (Eitan). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (Guard 1) | Customer.Customer | Read (implicit JOIN) | Customer's ProviderID for IB check |
| (Guard 1) | Trade.Provider | Read (implicit JOIN) | IsIB flag |
| (Guard 2) | Billing.Withdraw | Read | Existence check |
| (Guard 3-4) | Billing.WithdrawToFunding | Read | WTF existence + processed state check |
| (EXEC) | Billing.UpdateWithdraw2Funding | Procedure call | Writes CashoutStatusID=4 to WTF + history |
| (EXEC) | Billing.UpsertWithdraw | Procedure call | Updates Withdraw manager/session + history |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from application code.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingReverse (procedure)
|- Customer.Customer (table) -- IB guard
|- Trade.Provider (table) -- IsIB check
|- Billing.Withdraw (table) -- existence guard
|- Billing.WithdrawToFunding (table) -- WTF existence + state guard
+-- Billing.UpdateWithdraw2Funding (procedure) -- WTF status=4 write + history
+-- Billing.UpsertWithdraw (procedure) -- Withdraw update + history
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Pre-flight guard 1: implicit JOIN for IB check |
| Trade.Provider | Table | Pre-flight guard 1: IsIB=1 check |
| Billing.Withdraw | Table | Pre-flight guard 2: existence check |
| Billing.WithdrawToFunding | Table | Pre-flight guards 3-4: existence + processed state check |
| Billing.UpdateWithdraw2Funding | Stored Procedure | Writes WTF status=4 (Cancelled) and history |
| Billing.UpsertWithdraw | Stored Procedure | Updates Withdraw record and writes history |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawAndWithdrawToFundingAdd | Stored Procedure | Called to reverse existing WTF leg during withdrawal creation flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute a reversal

```sql
EXEC Billing.WithdrawToFundingReverse
    @WithdrawID = 12345,
    @FundingID  = 67890,
    @ManagerID  = 999,
    @Remark     = 'Rerouting to alternative payment method',
    @ID         = 111,
    @SessionID  = NULL;
-- Returns 0 on success; 60015/60025/60000 on failure
```

### 8.2 Check reversed WTF legs for a withdrawal

```sql
SELECT
    wtf.ID,
    wtf.WithdrawID,
    wtf.FundingID,
    wtf.CashoutStatusID,   -- 4 = Cancelled (reversed)
    wtf.ModificationDate,
    wtf.ManagerID
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.WithdrawID = 12345
  AND wtf.CashoutStatusID = 4;
```

### 8.3 Compare Reject vs Reverse history for a withdrawal

```sql
SELECT
    wfa.BW2F_ID         AS WTF_ID,
    wfa.CashoutStatusID,  -- 4=Reversed, 7=Rejected
    wfa.ManagerID,
    wfa.ModificationDate,
    wfa.Remark
FROM History.WithdrawToFundingAction wfa WITH (NOLOCK)
WHERE wfa.WithdrawID = 12345
  AND wfa.CashoutStatusID IN (4, 7)
ORDER BY wfa.ModificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingReverse | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingReverse.sql*
