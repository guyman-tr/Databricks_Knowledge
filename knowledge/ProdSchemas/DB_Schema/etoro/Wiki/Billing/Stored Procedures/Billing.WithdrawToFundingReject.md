# Billing.WithdrawToFundingReject

> Rejects a specific WithdrawToFunding leg - sets CashoutStatusID=7 (Rejected) after validating the withdrawal is not from an IB customer and has not already been processed; writes audit history via UpdateWithdraw2Funding and UpsertWithdraw.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (@WithdrawID, @FundingID, @ID) - uniquely identifies the WTF leg being rejected |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the official rejection endpoint for a WithdrawToFunding leg. When the back-office or Cashout Service needs to reject a payment leg (e.g., the payment processor declined the transaction, fraud was detected, or compliance blocked the withdrawal), it calls this procedure to set the WTF record to status 7 (Rejected) and log the action in history.

"Reject" is distinct from "Reverse" (`Billing.WithdrawToFundingReverse`): Reject marks the WTF leg as definitively rejected (status 7), whereas Reverse cancels it (status 4). Rejected withdrawals indicate a payment-layer decision (the funds never left eToro from a payments perspective), while cancellation may be broader.

The procedure enforces four pre-flight guards before modifying any data: (1) IB customer protection - Introducing Broker customers cannot have their withdrawals rejected via this path; (2) withdrawal existence; (3) WTF record existence; (4) already-processed guard. All checks use RAISERROR with specific error codes (60015, 60025) that map to application-level error handling.

The procedure was refactored in September 2021 (DBA-648, Shay Oren) to replace direct table UPDATEs with the `UpdateWithdraw2Funding` + `UpsertWithdraw` pattern, adding history-logging abstraction. A comment/remark handling fix was applied in October 2021 (MIMOPS-5318).

> **Note**: The CATCH block error message text incorrectly reads "An error occured at Billing.WithdrawToFundingReverse" (copy-paste artifact from the Reverse procedure template). This is a cosmetic bug - the procedure correctly processes rejections.

---

## 2. Business Logic

### 2.1 IB Customer Guard

**What**: Withdrawals for customers belonging to an Introducing Broker (IB) provider cannot be rejected via this procedure.

**Columns/Parameters Involved**: `Customer.Customer.ProviderID`, `Trade.Provider.IsIB`, `Billing.Withdraw.CID`

**Rules**:
- Joins `Customer.Customer` -> `Trade.Provider` -> `Billing.Withdraw` to check if the withdrawal's customer has a provider with `IsIB=1`
- If yes: `RAISERROR(60015, 16, 1)` and `RETURN 60015`
- IB withdrawals are handled through a separate back-office flow with additional compliance steps
- This guard runs first, before any other validation

### 2.2 Pre-Flight Existence and State Guards

**What**: Validates the withdrawal and WTF record exist and are in a rejectable state.

**Columns/Parameters Involved**: `Billing.Withdraw.WithdrawID`, `Billing.WithdrawToFunding.(WithdrawID, FundingID, ID, CashoutStatusID)`

**Rules**:
- Guard 2: `Billing.Withdraw WHERE WithdrawID = @WithdrawID` must exist -> RAISERROR(60025) "requested withdraw not found"
- Guard 3: `Billing.WithdrawToFunding WHERE WithdrawID=@WithdrawID AND FundingID=@FundingID AND ID=@ID` must exist -> RAISERROR(60025) "requested withdraw to funding not found"
- Guard 4: Same WTF record must NOT have `CashoutStatusID=3` (Processed) -> RAISERROR(60025) "requested withdraw already processed"
- Note: only status 3 (Processed) is blocked - status 7 (Rejected) or 4 (Cancelled) WTF records are NOT explicitly blocked, meaning re-rejection is technically possible

### 2.3 WTF Status Transition: -> Rejected (7)

**What**: Sets the WTF leg to CashoutStatusID=7 (Rejected) and logs the audit history.

**Columns/Parameters Involved**: `CashoutStatusID=7`, `CashoutActionStatusID=2`, `ModificationDate`, `ManagerID`, `Remark`

**Rules**:
- Populates `@InfoWTF [Billing].[TBL_Withdraw2Funding]` with: ID, WithdrawID, FundingID, CashoutStatusID=7, ModificationDate=NOW, ManagerID, CashoutActionStatusID=2, Remark
- Calls `Billing.UpdateWithdraw2Funding @InfoWTF` -> updates `Billing.WithdrawToFunding` and writes `History.WithdrawToFundingAction`
- Populates `@InfoWithdraw [Billing].[TBL_Withdraw]` with: WithdrawID, ManagerID, SessionID
- Calls `Billing.UpsertWithdraw @Withdraw=@InfoWithdraw, @HistoryOnlyRemark=@Remark` -> updates `Billing.Withdraw` manager/session and logs `History.WithdrawAction`
- Both writes are wrapped in a single BEGIN TRANSACTION / COMMIT

**Diagram**:
```
Pre-flight checks (4 guards - RETURN if any fails):
  1. IB customer? -> RAISERROR(60015)
  2. Withdraw exists? -> RAISERROR(60025)
  3. WTF (WithdrawID+FundingID+ID) exists? -> RAISERROR(60025)
  4. WTF already processed (status=3)? -> RAISERROR(60025)

BEGIN TRANSACTION:
  INSERT @InfoWTF (ID, WithdrawID, FundingID, CashoutStatusID=7, ManagerID, CashoutActionStatusID=2, Remark)
  EXEC Billing.UpdateWithdraw2Funding @InfoWTF
    -> UPDATE Billing.WithdrawToFunding SET CashoutStatusID=7
    -> INSERT History.WithdrawToFundingAction (CashoutStatusID=7, CashoutActionStatusID=2, Remark)

  INSERT @InfoWithdraw (WithdrawID, ManagerID, SessionID)
  EXEC Billing.UpsertWithdraw @Withdraw=@InfoWithdraw, @HistoryOnlyRemark=@Remark
    -> UPDATE Billing.Withdraw SET ManagerID, SessionID
    -> INSERT History.WithdrawAction (Comment=@Remark)
COMMIT

CashoutStatusID values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled, 7=Rejected
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | integer | NO | - | CODE-BACKED | Input parameter. Primary key of the withdrawal in `Billing.Withdraw`. Used in all four pre-flight guards and as the key for history logging. |
| 2 | @FundingID | integer | NO | - | CODE-BACKED | Input parameter. Funding record ID from `Billing.Funding`. Together with `@WithdrawID` and `@ID` uniquely identifies the WTF leg. |
| 3 | @ManagerID | integer | NO | - | CODE-BACKED | Input parameter. Manager performing the rejection. Written to both `Billing.WithdrawToFunding.ManagerID` and `Billing.Withdraw.ManagerID` via the TVP procedures. |
| 4 | @Remark | varchar(255) | YES | - | CODE-BACKED | Input parameter. Rejection reason or note. Passed as `@HistoryOnlyRemark` to `UpsertWithdraw` (history-only, not written to Billing.Withdraw.Comment) and embedded in WTF history via UpdateWithdraw2Funding. |
| 5 | @ID | int | NO | - | CODE-BACKED | Input parameter. `Billing.WithdrawToFunding.ID` - the specific WTF payment leg to reject. Used in pre-flight guards 3 and 4 and as the primary key in the WTF update. |
| 6 | @SessionID | bigint | YES | NULL | CODE-BACKED | Input parameter. Optional audit session identifier. Passed to `Billing.Withdraw` update via `@InfoWithdraw` TVP. Added 20/10/2015 (Eitan). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (Guard 1) | Customer.Customer | Read (JOIN) | Validates customer's provider IB status |
| (Guard 1) | Trade.Provider | Read (JOIN) | Checks IsIB flag on provider |
| (Guard 2-4) | Billing.Withdraw | Read | Existence + state validation |
| (Guard 3-4) | Billing.WithdrawToFunding | Read | WTF existence + already-processed check |
| (EXEC) | Billing.UpdateWithdraw2Funding | Procedure call | Writes CashoutStatusID=7 to WTF + history |
| (EXEC) | Billing.UpsertWithdraw | Procedure call | Updates Withdraw manager/session + history |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from application code (back-office rejection workflows).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingReject (procedure)
|- Customer.Customer (table) -- IB guard read
|- Trade.Provider (table) -- IsIB flag check
|- Billing.Withdraw (table) -- existence + state guard
|- Billing.WithdrawToFunding (table) -- WTF existence + state guard
+-- Billing.UpdateWithdraw2Funding (procedure) -- WTF status write + history
+-- Billing.UpsertWithdraw (procedure) -- Withdraw update + history
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Pre-flight guard 1: JOIN to get ProviderID for IB check |
| Trade.Provider | Table | Pre-flight guard 1: IsIB=1 check |
| Billing.Withdraw | Table | Pre-flight guards 2: existence check |
| Billing.WithdrawToFunding | Table | Pre-flight guards 3-4: existence + processed state check |
| Billing.UpdateWithdraw2Funding | Stored Procedure | Writes WTF status=7 (Rejected) and history row |
| Billing.UpsertWithdraw | Stored Procedure | Updates Withdraw record manager/session and writes history |

### 6.2 Objects That Depend On This

No SQL callers found in SSDT repo. Called by application code (back-office rejection flows).

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute a rejection

```sql
EXEC Billing.WithdrawToFundingReject
    @WithdrawID = 12345,
    @FundingID  = 67890,
    @ManagerID  = 999,
    @Remark     = 'Payment processor declined - risk policy violation',
    @ID         = 111,
    @SessionID  = NULL;
-- Returns 0 on success; error codes 60015/60025/60000 on failure
```

### 8.2 Check WTF records with Rejected status for a withdrawal

```sql
SELECT
    wtf.ID,
    wtf.WithdrawID,
    wtf.FundingID,
    wtf.CashoutStatusID,   -- 7 = Rejected
    wtf.ModificationDate,
    wtf.ManagerID
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.WithdrawID = 12345
  AND wtf.CashoutStatusID = 7;
```

### 8.3 View rejection history for a withdrawal

```sql
SELECT
    wfa.BW2F_ID AS WTF_ID,
    wfa.WithdrawID,
    wfa.CashoutStatusID,   -- 7 = Rejected
    wfa.ManagerID,
    wfa.ModificationDate,
    wfa.Remark
FROM History.WithdrawToFundingAction wfa WITH (NOLOCK)
WHERE wfa.WithdrawID = 12345
  AND wfa.CashoutStatusID = 7
ORDER BY wfa.ModificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingReject | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingReject.sql*
