# Billing.WithdrawToFundingUpdate

> Updates a WithdrawToFunding leg with new processing details (amount, currency, XML data, depot) after five pre-flight guards including IB check and parent-withdraw state validation; writes history via UpdateWithdraw2Funding and UpsertWithdraw.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (@WithdrawID, @FundingID, @ID) - uniquely identifies the WTF leg being updated |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure updates the processing data on a WithdrawToFunding leg - setting the process currency, amount, XML enrichment data, and depot assignment. It is called when the Cashout Service has resolved the routing details for a withdrawal leg and needs to record them before or during processing.

The procedure enforces five validation guards before modifying data, adding a unique guard compared to Reject/Reverse: the **parent Withdraw status check** (guard 5) requires the parent `Billing.Withdraw` to be in an active state (Pending/InProcess/PartialProcess). This prevents updating legs of already-completed or cancelled withdrawals.

There is one exception: the `@IsCloseConfirmedLine` flag. When set to `1` AND the parent withdrawal is in status 7 (Rejected), the parent status guard is bypassed. This was added specifically to allow back-office users to close a "confirmed line" on the "Payment To Send" screen even when the parent withdrawal has been rejected - a manual reconciliation flow where the WTF leg needs to be finalized despite the parent being in rejected state.

The `@Amount` parameter is in **cents (integer)** and is divided by 100 before storage: `CAST(@Amount AS MONEY)/100`. This is the standard cents-to-dollars conversion used across Billing procedures.

Created June 2014 (Fogbugz 22891, Geri Reshef). Various field and behavior additions through 2021, then DBA-648 refactoring to TVP abstraction pattern.

---

## 2. Business Logic

### 2.1 Five Pre-Flight Guards

**What**: Prevents invalid updates via sequential existence, state, and permission checks.

**Rules**:
1. **IB guard**: Customer's provider IsIB=1 -> RAISERROR(60015) (IB withdrawals require separate flow)
2. **Withdraw exists**: `Billing.Withdraw WHERE WithdrawID=@WithdrawID` -> RAISERROR(60025) "requested withdraw not found"
3. **WTF exists**: `Billing.WithdrawToFunding WHERE WithdrawID=@WithdrawID AND FundingID=@FundingID AND ID=@ID` -> RAISERROR(60025) "requested withdraw funding not found"
4. **Not already processed**: WTF CashoutStatusID != 3 -> RAISERROR(60025) "requested withdraw already processed"
5. **Parent active state** (conditional): If `@IsCloseConfirmedLine=0 OR parentCashoutStatusID != 7`, parent Withdraw must be IN (1=Pending, 2=InProcess, 5=PartialProcess) -> RAISERROR(60025) "withdraw in illegal state"

### 2.2 IsCloseConfirmedLine Exception

**What**: Allows back-office to update a WTF leg even when the parent withdrawal is Rejected (status 7).

**Columns/Parameters Involved**: `@IsCloseConfirmedLine bit`, `@cashoutstatusIDParent`

**Rules**:
- `@cashoutstatusIDParent` is read at SP start: `SELECT CashoutStatusID FROM Billing.Withdraw WHERE WithdrawID=@WithdrawID`
- Guard 5 is skipped IF: `@IsCloseConfirmedLine=1 AND @cashoutstatusIDParent=7`
- In all other cases, guard 5 applies (including when `@IsCloseConfirmedLine=1` but parent is NOT status 7)
- Default: `@IsCloseConfirmedLine=0` (standard path, guard 5 always applies)

### 2.3 Amount: Cents-to-Dollars Conversion

**What**: The input @Amount is in cents (integer); stored as dollars (money) by dividing by 100.

**Columns/Parameters Involved**: `@Amount INTEGER`, `Billing.WithdrawToFunding.Amount MONEY`

**Rules**:
- `CAST(@Amount AS MONEY)/100` - e.g., input `10000` cents -> stored `100.00` dollars
- This conversion happens inside the TVP INSERT, not on the @Amount parameter itself

### 2.4 WTF Update with History

**What**: Updates WTF processing fields and logs the change.

**Columns/Parameters Involved**: `ProcessCurrencyID`, `ManagerID`, `Amount`, `WithdrawData` (XML), `DepotID`, `CashoutActionStatusID=2`

**Rules**:
- Populates `@InfoWTF` with: WithdrawID, FundingID, ID, ProcessCurrencyID, ManagerID, Amount (cents/100), WithdrawData (XML), DepotID, CashoutActionStatusID=2 (processed), ModificationDate
- `EXECUTE Billing.UpdateWithdraw2Funding @InfoWTF` -> updates WTF record + history
- Populates `@InfoWithdraw` with: WithdrawID, ManagerID, SessionID, ModificationDate
- `EXECUTE Billing.UpsertWithdraw @InfoWithdraw` (NOTE: no `@HistoryOnlyRemark` - remark is NOT logged to Withdraw history in this call, unlike Reject/Reverse)
- Both writes inside BEGIN TRANSACTION / COMMIT

**Diagram**:
```
@cashoutstatusIDParent = SELECT CashoutStatusID FROM Billing.Withdraw WHERE WithdrawID=@WithdrawID

Guards 1-5 (sequential):
  1. IB customer? -> 60015
  2. Withdraw exists? -> 60025
  3. WTF (WithdrawID+FundingID+ID) exists? -> 60025
  4. WTF status=3 (processed)? -> 60025
  5. IF NOT (@IsCloseConfirmedLine=1 AND parentStatus=7):
       Parent Withdraw status IN (1,2,5)? else -> 60025

BEGIN TRANSACTION:
  INSERT @InfoWTF (WithdrawID, FundingID, ID, ProcessCurrencyID, ManagerID,
         Amount=CAST(@Amount/100), WithdrawData, DepotID, CashoutActionStatusID=2)
  EXEC Billing.UpdateWithdraw2Funding @InfoWTF

  INSERT @InfoWithdraw (WithdrawID, ManagerID, SessionID, ModificationDate)
  EXEC Billing.UpsertWithdraw @InfoWithdraw
COMMIT
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | integer | NO | - | CODE-BACKED | Input parameter. Parent withdrawal ID in `Billing.Withdraw`. Used in IB guard, existence checks, and write target. |
| 2 | @FundingID | integer | NO | - | CODE-BACKED | Input parameter. Funding record ID. With @WithdrawID and @ID identifies the WTF leg. |
| 3 | @ManagerID | integer | NO | - | CODE-BACKED | Input parameter. Manager performing the update. Written to both WTF and Withdraw records. |
| 4 | @Amount | integer | NO | - | CODE-BACKED | Input parameter. Amount in **cents**. Converted to dollars via `CAST(@Amount AS MONEY)/100` before storage in `Billing.WithdrawToFunding.Amount`. |
| 5 | @ProcessCurrencyID | integer | NO | - | CODE-BACKED | Input parameter. Currency ID for processing this WTF leg. FK to Dictionary.Currency. |
| 6 | @WithdrawData | xml | YES | - | CODE-BACKED | Input parameter. XML document with provider-specific payment data. Stored in `Billing.WithdrawToFunding.WithdrawData`. XML schema validation is commented out (was formerly validated against Dictionary.GetXMLSchema). |
| 7 | @Remark | varchar(255) | YES | - | CODE-BACKED | Input parameter. Note for the update. Present in the parameter list but NOT passed to `UpsertWithdraw` as @HistoryOnlyRemark (commented out in the code). The remark is therefore not written to Withdraw history. |
| 8 | @ID | int | NO | - | CODE-BACKED | Input parameter. `Billing.WithdrawToFunding.ID` - the specific WTF payment leg to update. |
| 9 | @DepotID | int | NO | - | CODE-BACKED | Input parameter. Depot (payment processor routing target) assignment for this WTF leg. Written to `Billing.WithdrawToFunding.DepotID`. Added Fogbugz 51303 (02/05/2018). |
| 10 | @SessionID | bigint | YES | NULL | CODE-BACKED | Input parameter. Optional audit session identifier. Written to `Billing.Withdraw.SessionID` via `@InfoWithdraw` TVP. |
| 11 | @IsCloseConfirmedLine | bit | YES | 0 | CODE-BACKED | Input parameter. When `1` AND parent Withdraw is in Rejected status (7), bypasses the parent active-state guard (guard 5). Enables back-office to close a confirmed line on "Payment To Send" screen for a rejected parent withdrawal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (Guard 1) | Customer.Customer | Read (implicit JOIN) | Customer ProviderID for IB check |
| (Guard 1) | Trade.Provider | Read (implicit JOIN) | IsIB flag |
| (Guard 2, 5) | Billing.Withdraw | Read | Existence + parent status check |
| (Guard 3-4) | Billing.WithdrawToFunding | Read | WTF existence + processed state check |
| (EXEC) | Billing.UpdateWithdraw2Funding | Procedure call | Writes ProcessCurrencyID, Amount, WithdrawData, DepotID to WTF + history |
| (EXEC) | Billing.UpsertWithdraw | Procedure call | Updates Withdraw manager/session + history |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from application code (Cashout Service routing flows).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingUpdate (procedure)
|- Customer.Customer (table) -- IB guard
|- Trade.Provider (table) -- IsIB check
|- Billing.Withdraw (table) -- existence + state guards
|- Billing.WithdrawToFunding (table) -- WTF existence + state guard
+-- Billing.UpdateWithdraw2Funding (procedure) -- WTF field update + history
+-- Billing.UpsertWithdraw (procedure) -- Withdraw update + history
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Pre-flight guard 1: IB customer check |
| Trade.Provider | Table | Pre-flight guard 1: IsIB=1 check |
| Billing.Withdraw | Table | Pre-flight guards 2 + 5: existence + active status check |
| Billing.WithdrawToFunding | Table | Pre-flight guards 3-4: WTF existence + processed check |
| Billing.UpdateWithdraw2Funding | Stored Procedure | Writes WTF processing data (amount, currency, XML, depot) + history |
| Billing.UpsertWithdraw | Stored Procedure | Updates Withdraw manager/session + logs Withdraw history |

### 6.2 Objects That Depend On This

No SQL callers found in SSDT repo. Called by Cashout Service application code.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute standard update

```sql
EXEC Billing.WithdrawToFundingUpdate
    @WithdrawID         = 12345,
    @FundingID          = 67890,
    @ManagerID          = -1,
    @Amount             = 10000,   -- cents: $100.00
    @ProcessCurrencyID  = 1,       -- USD
    @WithdrawData       = N'<WithdrawData><Ref>ABC123</Ref></WithdrawData>',
    @Remark             = NULL,
    @ID                 = 111,
    @DepotID            = 5,
    @SessionID          = NULL,
    @IsCloseConfirmedLine = 0;
```

### 8.2 Close confirmed line on rejected parent (BO manual flow)

```sql
EXEC Billing.WithdrawToFundingUpdate
    @WithdrawID         = 12345,
    @FundingID          = 67890,
    @ManagerID          = 999,
    @Amount             = 10000,
    @ProcessCurrencyID  = 1,
    @WithdrawData       = NULL,
    @Remark             = 'Closing confirmed line - parent rejected',
    @ID                 = 111,
    @DepotID            = 5,
    @IsCloseConfirmedLine = 1;  -- bypasses parent-status guard
```

### 8.3 Check parent withdrawal status before calling

```sql
SELECT w.WithdrawID, w.CashoutStatusID, wtf.ID, wtf.CashoutStatusID AS WTF_Status
FROM Billing.Withdraw w WITH (NOLOCK)
JOIN Billing.WithdrawToFunding wtf WITH (NOLOCK) ON wtf.WithdrawID = w.WithdrawID
WHERE w.WithdrawID = 12345
  AND wtf.ID = 111;
-- Parent must be IN (1,2,5) for standard call; WTF must not be 3 (Processed)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingUpdate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingUpdate.sql*
