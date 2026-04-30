# Billing.WithdrawRequestReverse

> Reverses (cancels) a pending withdrawal request by cancelling all its payment legs, setting the withdrawal status to Cancelled (4), and refunding the withdrawal amount and cashout fee back to the customer's account balance.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID - the withdrawal being reversed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawRequestReverse` is the full withdrawal reversal procedure. It is called when a pending or in-process withdrawal needs to be cancelled and the customer's funds returned to their account - for example, when a customer requests cancellation, when a payment provider rejects the withdrawal before funds are sent, or during operational interventions.

The procedure exists as a single atomic unit because a reversal requires multiple coordinated writes: the `Billing.WithdrawToFunding` payment legs must be cancelled, the parent `Billing.Withdraw` row must be set to Cancelled (status 4), and `Customer.SetBalance` must be called twice to restore both the withdrawal amount and any cashout fee that was deducted. All of these must succeed together or be rolled back.

Data flows from the withdrawal service (WithdrawalServiceUser), the CashoutTool (operations back-office), and approval tooling (ApprovalUserEtoro) into this procedure. It is also called in bulk by `Billing.ManualWithdrawRequestReverse` for crisis scenarios where all open withdrawals for a customer must be reversed simultaneously (labelled "Crisis 21.1.15" in the code).

---

## 2. Business Logic

### 2.1 Pre-Reversal Guard Checks (Four Guards)

**What**: Four validation checks prevent invalid reversals before any writes occur.

**Columns/Parameters Involved**: `@WithdrawID`, `Billing.Withdraw.CashoutStatusID`, `Billing.Withdraw.RequestDate`, `Billing.WithdrawToFunding.CashoutStatusID`, `Customer.Customer.ProviderID` / `Trade.Provider.IsIB`

**Rules**:
- **Guard 1 - IB Customer (error 60015)**: If the withdrawal belongs to a customer whose provider is an Introducing Broker (`Trade.Provider.IsIB=1`), the reversal is blocked. IB withdrawals follow a different reconciliation flow.
- **Guard 2 - Not Found (error 60025)**: If no `Billing.Withdraw` row exists for the given `@WithdrawID` (RequestDate IS NULL), the request is invalid.
- **Guard 3 - Already Cancelled (error 60025)**: If `Billing.Withdraw.CashoutStatusID=4`, the withdrawal is already cancelled - no action needed.
- **Guard 4 - Already Processed (error 60025)**: If any `Billing.WithdrawToFunding` row for this withdrawal has `CashoutStatusID=3` (Processed), funds have already been sent - a reversal cannot undo a completed payment.

**Diagram**:
```
Check IB customer (Customer.Customer + Trade.Provider.IsIB=1) --> 60015 (IB withdrawal)
Check RequestDate IS NULL                                       --> 60025 (not found)
Check Billing.Withdraw.CashoutStatusID = 4                     --> 60025 (already cancelled)
Check Billing.WithdrawToFunding.CashoutStatusID = 3            --> 60025 (already processed)
All guards pass --> proceed to reversal writes
```

### 2.2 Reversal Write Sequence

**What**: The reversal updates three data areas atomically: the WTF payment legs, the parent withdrawal, and the customer balance.

**Columns/Parameters Involved**: `@Description`, `@ResponseID`, `@Comment`, `@MoveMoneyReasonID`

**Rules**:
- Step 1: `Billing.UpdateWithdraw2Funding` sets all non-cancelled WTF rows to `CashoutStatusID=4`, `CashoutActionStatusID=2`, with `@ResponseID` recorded.
- Step 2: `Billing.UpsertWithdraw` sets `Billing.Withdraw.CashoutStatusID=4` (Cancelled), `ManagerID=@ManagerID`, `Comment=@Comment`, `Remark=@Description`. Only proceeds if the row is not already cancelled (@@ROWCOUNT guard - raises 60025 if 0 rows updated).
- Step 3: `Customer.SetBalance` called with CreditTypeID=8 (reverse cashout) to restore `Amount * 100` cents to the customer account.
- Step 4: `Customer.SetBalance` called with CreditTypeID=15 (reverse cashout fee) to restore the cashout fee amount (from `History.Credit` where CreditTypeID=15, Payment column * 100 cents).
- `@MoveMoneyReasonID` is forwarded to both `Customer.SetBalance` calls for money movement categorization.

**Diagram**:
```
BEGIN TRANSACTION
  |
  +--> UpdateWithdraw2Funding: WTF legs -> CashoutStatusID=4 (Cancelled)
  |
  +--> UpsertWithdraw: Billing.Withdraw -> CashoutStatusID=4 (Cancelled)
  |      [abort if @@ROWCOUNT=0 - already cancelled race condition]
  |
  +--> Customer.SetBalance(CID, Amount*100, CreditTypeID=8)
  |      Restore withdrawal amount to customer balance
  |      [abort if @Answer != 0]
  |
  +--> Customer.SetBalance(CID, CashoutFee*100, CreditTypeID=15)
         Restore cashout fee to customer balance
         [abort if @Answer != 0]
  |
COMMIT / ROLLBACK on any error
```

### 2.3 Cashout Fee Recovery from History.Credit

**What**: The cashout fee to be returned is read from the `History.Credit` table (and in-memory cache) before the transaction begins.

**Columns/Parameters Involved**: `History.Credit.CreditTypeID`, `History.Credit.Payment`, `History.ActiveCreditRecentMemoryBucket`

**Rules**:
- The procedure reads `History.Credit WHERE CreditTypeID=15 AND WithdrawID=@WithdrawID`, scoped to ±1 year from the original `RequestDate` to avoid full table scans.
- It also reads from `History.ActiveCreditRecentMemoryBucket` (a memory-optimized table with recent credit data) as a fallback/supplement.
- The fee is `Payment * -100` (Payment is negative for fee deductions; negating and multiplying by 100 converts to positive cents for the balance credit).
- If no fee credit exists, `@CashoutFee` remains 0 and the second `Customer.SetBalance` call is a no-op.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INTEGER | NO | - | CODE-BACKED | The withdrawal to reverse. FK to `Billing.Withdraw.WithdrawID`. Used in all guard checks and as the key for all writes. |
| 2 | @ManagerID | INTEGER | NO | - | CODE-BACKED | ID of the manager or system user authorizing the reversal. Written to `Billing.Withdraw.ManagerID` (via UpsertWithdraw) and `Billing.WithdrawToFunding.ManagerID` (via UpdateWithdraw2Funding) for audit trail. Also passed to `Customer.SetBalance` as the actor. |
| 3 | @Description | VARCHAR(255) | YES | NULL | CODE-BACKED | Free-text description or remark for the reversal (e.g., "Crisis 21.1.15", "Customer requested cancellation"). Written to `Billing.Withdraw.Remark` and `Billing.WithdrawToFunding.Remark`. Also passed as description to `Customer.SetBalance` calls. |
| 4 | @ResponseID | INTEGER | YES | NULL | CODE-BACKED | Optional payment provider response ID to associate with the WTF cancellation. Written to `Billing.WithdrawToFunding.ResponseID` via `UpdateWithdraw2Funding`. Added 2021-12-20 (PAYUA-3081) to support provider reversal tracking. |
| 5 | @Comment | VARCHAR(255) | YES | NULL | CODE-BACKED | Separate comment field for the withdrawal cancellation (distinct from @Description/Remark). Written to `Billing.Withdraw.Comment` via `UpsertWithdraw`. Added 2024-02-20 (MIMOPS2-314). |
| 6 | @MoveMoneyReasonID | INT | YES | NULL | CODE-BACKED | Categorization code for the money movement reason, forwarded to both `Customer.SetBalance` calls (CreditTypeID=8 and 15). Used to classify why the reversal occurred in the customer balance history. Added 2024-04-24 (MIMOPSA-12732). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.Withdraw | FK (read + write) | Reads RequestDate and CashoutStatusID for guards; cancels via UpsertWithdraw. |
| @WithdrawID | Billing.WithdrawToFunding | FK (read + write) | Reads for processed guard; cancels all non-cancelled legs via UpdateWithdraw2Funding. |
| @WithdrawID | History.Credit | Lookup | Reads CreditTypeID=15 credits to determine cashout fee amount to refund. |
| @WithdrawID | History.ActiveCreditRecentMemoryBucket | Lookup | Reads recent credit data from memory-optimized table as supplement to History.Credit. |
| @CID | Customer.Customer | Read | Joined to check ProviderID for IB customer guard. |
| @CID | Trade.Provider | Read | Joined via Customer.Customer.ProviderID to check IsIB flag. |
| (internal) | Billing.UpdateWithdraw2Funding | Procedure call | Cancels all WTF payment legs. |
| (internal) | Billing.UpsertWithdraw | Procedure call | Cancels the parent Withdraw row. |
| (internal) | Customer.SetBalance | Procedure call x2 | Restores withdrawal amount (CreditTypeID=8) and cashout fee (CreditTypeID=15) to customer balance. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.ManualWithdrawRequestReverse | - | Caller | Calls this procedure in a loop for all open withdrawals of a customer (crisis/bulk reversal). |
| WithdrawalServiceUser | - | Caller (app) | Withdrawal microservice calls this for system-triggered reversals. |
| CashoutTool | - | Caller (app) | Operations back-office tool calls this for manual reversals. |
| ApprovalUserEtoro | - | Caller (app) | Approval workflow calls this when a withdrawal is declined at the approval stage. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawRequestReverse (procedure)
├── Customer.Customer (table) - IB guard check
├── Billing.Withdraw (table) - read RequestDate + status guards
├── Trade.Provider (table) - IsIB check via JOIN
├── Billing.WithdrawToFunding (table) - processed guard + WTF rows to cancel
├── History.Credit (table) - read cashout fee (CreditTypeID=15)
├── History.ActiveCreditRecentMemoryBucket (memory-optimized table) - recent credit cache
├── Billing.UpdateWithdraw2Funding (procedure)
├── Billing.UpsertWithdraw (procedure)
└── Customer.SetBalance (procedure) - called twice
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | SELECT for guards (RequestDate, CashoutStatusID); write via UpsertWithdraw |
| Billing.WithdrawToFunding | Table | SELECT for processed guard; rows read and cancelled via UpdateWithdraw2Funding |
| Customer.Customer | Table | JOIN for IB customer guard check |
| Trade.Provider | Table | JOIN via Customer.Customer.ProviderID to check IsIB=1 |
| History.Credit | Table | SELECT to get cashout fee credit (CreditTypeID=15, WithdrawID match, date-scoped) |
| History.ActiveCreditRecentMemoryBucket | Memory-optimized table | SELECT as supplement to History.Credit for recent credits |
| Billing.UpdateWithdraw2Funding | Procedure | EXEC to cancel all WTF payment legs |
| Billing.UpsertWithdraw | Procedure | EXEC to cancel parent Withdraw row |
| Customer.SetBalance | Procedure | EXEC x2: restore withdrawal amount (type=8) + restore cashout fee (type=15) |
| Billing.TBL_Withdraw2Funding | User Defined Type | Table variable type for UpdateWithdraw2Funding input |
| Billing.TBL_Withdraw | User Defined Type | Table variable type for UpsertWithdraw input |
| History.ActiveCreditRecentMemoryBucket_TYPE | User Defined Type | Table type for in-memory credit lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.ManualWithdrawRequestReverse | Procedure | Calls this in a loop for crisis/bulk reversals of all open withdrawals for a CID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IB guard | Application-level | Returns 60015 if withdrawal belongs to an IB (Introducing Broker) customer |
| Not found guard | Application-level | Returns 60025 if RequestDate IS NULL (withdrawal doesn't exist) |
| Already cancelled guard | Application-level | Returns 60025 if CashoutStatusID=4 |
| Already processed guard | Application-level | Returns 60025 if any WTF leg has CashoutStatusID=3 |
| Balance restore guard | Application-level | Raises 60000 if Customer.SetBalance returns non-zero (balance update failed) |
| Named transaction | Transactional | All writes wrapped in transaction; TRY/CATCH rolls back on error (@@TRANCOUNT=1) or commits inner (>1) |

---

## 8. Sample Queries

### 8.1 Reverse a pending withdrawal (standard cancellation)

```sql
EXEC Billing.WithdrawRequestReverse
    @WithdrawID = 987654,
    @ManagerID = 42,
    @Description = 'Customer requested cancellation',
    @Comment = 'Customer called support to cancel',
    @MoveMoneyReasonID = NULL;
```

### 8.2 Check if a withdrawal is eligible for reversal

```sql
SELECT
    w.WithdrawID,
    w.CashoutStatusID,
    w.Amount,
    w.CID,
    CASE WHEN w.CashoutStatusID = 4 THEN 'Already Cancelled'
         WHEN w.CashoutStatusID = 3 THEN 'Already Processed'
         WHEN p.IsIB = 1 THEN 'IB Customer - blocked'
         ELSE 'Eligible for reversal'
    END AS ReversalEligibility,
    (SELECT COUNT(*) FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
     WHERE wtf.WithdrawID = w.WithdrawID AND wtf.CashoutStatusID = 3) AS ProcessedLegs
FROM Billing.Withdraw w WITH (NOLOCK)
JOIN Customer.Customer c WITH (NOLOCK) ON c.CID = w.CID
JOIN Trade.Provider p WITH (NOLOCK) ON p.ProviderID = c.ProviderID
WHERE w.WithdrawID = 987654;
```

### 8.3 View balance credits created by a withdrawal reversal

```sql
SELECT
    hc.CreditID,
    hc.CreditTypeID,
    CASE hc.CreditTypeID
        WHEN 8  THEN 'Reverse Cashout (amount returned)'
        WHEN 15 THEN 'Reverse Cashout Fee (fee returned)'
        ELSE CAST(hc.CreditTypeID AS VARCHAR)
    END AS CreditTypeName,
    hc.Credit,
    hc.Payment,
    hc.Occurred,
    hc.Description
FROM History.Credit hc WITH (NOLOCK)
WHERE hc.WithdrawID = 987654
  AND hc.CreditTypeID IN (8, 15)
ORDER BY hc.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawRequestReverse | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawRequestReverse.sql*
