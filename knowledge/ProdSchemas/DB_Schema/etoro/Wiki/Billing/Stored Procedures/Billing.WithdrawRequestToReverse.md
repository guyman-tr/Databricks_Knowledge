# Billing.WithdrawRequestToReverse

> Cancels a pending withdrawal request by cancelling all its payment legs, setting the withdrawal status to Cancelled (4), and refunding the withdrawal amount and cashout fee to the customer's balance - the older variant of WithdrawRequestReverse without the Comment and MoveMoneyReasonID parameters.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID - the withdrawal being reversed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawRequestToReverse` reverses (cancels) a pending withdrawal request and restores the customer's funds. It performs the same core operations as `Billing.WithdrawRequestReverse` - cancelling payment legs, updating the withdrawal status to Cancelled (4), and crediting the customer's account for both the withdrawal amount and the cashout fee.

This procedure exists alongside `WithdrawRequestReverse` as the older variant used by the payout pipeline and Billing SQL users. It predates the 2024 additions of `@Comment` (MIMOPS2-314, Feb 2024) and `@MoveMoneyReasonID` (MIMOPSA-12732, Apr 2024) that were added to `WithdrawRequestReverse`. `WithdrawRequestToReverse` does not pass a comment to the withdrawal update and does not forward a move money reason ID to the balance credit operations.

The name reflects the action: a withdrawal request that is being sent "to reverse" (queued for reversal). It is called by PayoutUser (the payout execution service) and PROD_SQL_Billing (operational SQL access), as opposed to `WithdrawRequestReverse` which is called by the withdrawal service, CashoutTool, and approval tooling.

---

## 2. Business Logic

### 2.1 Identical Guard Logic to WithdrawRequestReverse

**What**: Four guards prevent invalid reversals, identical to `Billing.WithdrawRequestReverse`.

**Columns/Parameters Involved**: `@WithdrawID`, `Billing.Withdraw.CashoutStatusID`, `Trade.Provider.IsIB`

**Rules**:
- Guard 1: IB customer -> RAISERROR 60015
- Guard 2: Withdraw not found (RequestDate IS NULL) -> RAISERROR 60025
- Guard 3: Already cancelled (CashoutStatusID=4) -> RAISERROR 60025
- Guard 4: Already processed (WTF CashoutStatusID=3) -> RAISERROR 60025

See `Billing.WithdrawRequestReverse` Section 2.1 for full diagram - logic is identical.

### 2.2 Reversal Write Sequence (No Comment, No MoveMoneyReason)

**What**: Atomic cancellation of WTF legs, Withdraw status, and balance restoration - same as WithdrawRequestReverse but without @Comment or @MoveMoneyReasonID.

**Columns/Parameters Involved**: `@Description`, `@ResponseID`, `@ManagerID`

**Rules**:
- `UpdateWithdraw2Funding`: all non-cancelled WTF legs -> CashoutStatusID=4, ResponseID=@ResponseID.
- `UpsertWithdraw`: Withdraw -> CashoutStatusID=4, Remark=@Description. Comment field is NOT set (no @Comment parameter in this procedure).
- `Customer.SetBalance(CreditTypeID=8)`: restore withdrawal amount * 100 (cents). No MoveMoneyReasonID forwarded.
- `Customer.SetBalance(CreditTypeID=15)`: restore cashout fee * 100 (cents). No MoveMoneyReasonID forwarded.
- Note: error message in RAISERROR still references 'Billing.WithdrawRequestReverse' (copy-paste artifact from when this procedure was split from the original).

### 2.3 Difference Table vs WithdrawRequestReverse

**What**: Summary of the functional differences between the two reversal procedures.

**Columns/Parameters Involved**: All parameters

**Rules**:

```
Feature                         WithdrawRequestToReverse    WithdrawRequestReverse
---                             ---                         ---
@Comment parameter              ABSENT                      Present (added Feb 2024)
@MoveMoneyReasonID parameter    ABSENT                      Present (added Apr 2024)
Comment written to Withdraw     NO                          YES (via UpsertWithdraw)
MoveMoneyReasonID to SetBalance NO                          YES (both SetBalance calls)
Called by                       PayoutUser, Billing SQL     WithdrawalService, CashoutTool
History (last change)           2021-12-20 (PAYUA-3081)     2024-08-05 (bug fix)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INTEGER | NO | - | CODE-BACKED | The withdrawal to reverse. FK to `Billing.Withdraw.WithdrawID`. Used in all guard checks and as the key for all writes. |
| 2 | @ManagerID | INTEGER | NO | - | CODE-BACKED | ID of the manager or system user authorizing the reversal. Written to `Billing.Withdraw.ManagerID` (via UpsertWithdraw) and `Billing.WithdrawToFunding.ManagerID` (via UpdateWithdraw2Funding). Also passed to `Customer.SetBalance`. |
| 3 | @Description | VARCHAR(255) | YES | NULL | CODE-BACKED | Free-text description/remark for the reversal. Written to `Billing.Withdraw.Remark` and `Billing.WithdrawToFunding.Remark`. Also passed as description to `Customer.SetBalance` calls. No separate @Comment parameter exists in this variant. |
| 4 | @ResponseID | INTEGER | YES | NULL | CODE-BACKED | Optional payment provider response ID. Written to `Billing.WithdrawToFunding.ResponseID` via `UpdateWithdraw2Funding`. Added 2021-12-20 (PAYUA-3081). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.Withdraw | FK (read + write) | Reads for guards; cancels via UpsertWithdraw (CashoutStatusID=4, Remark set). |
| @WithdrawID | Billing.WithdrawToFunding | FK (read + write) | Reads for guard; cancels non-cancelled legs via UpdateWithdraw2Funding. |
| @WithdrawID | History.Credit | Lookup | Reads CreditTypeID=15 for cashout fee amount to refund. |
| @WithdrawID | History.ActiveCreditRecentMemoryBucket | Lookup | Supplements History.Credit with recent in-memory credit data. |
| @CID | Customer.Customer | Read | Joined for IB customer guard. |
| @CID | Trade.Provider | Read | IsIB check via Customer.Customer.ProviderID. |
| (internal) | Billing.UpdateWithdraw2Funding | Procedure call | Cancels WTF payment legs. |
| (internal) | Billing.UpsertWithdraw | Procedure call | Cancels Withdraw row. |
| (internal) | Customer.SetBalance | Procedure call x2 | Restores amount (type=8) and cashout fee (type=15). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PayoutUser | - | Caller (app) | Payout execution service uses this older variant for reversal operations. |
| PROD_SQL_Billing | - | Caller (ops) | Operational Billing SQL user calls this for manual reversal operations. |
| Billing | - | Caller | Billing user (DB principal) has execute permission. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawRequestToReverse (procedure)
├── Customer.Customer (table) - IB guard
├── Billing.Withdraw (table) - status guards + read amount
├── Trade.Provider (table) - IsIB check
├── Billing.WithdrawToFunding (table) - processed guard + legs to cancel
├── History.Credit (table) - cashout fee (CreditTypeID=15)
├── History.ActiveCreditRecentMemoryBucket (memory-optimized table) - recent credit cache
├── Billing.UpdateWithdraw2Funding (procedure)
├── Billing.UpsertWithdraw (procedure)
└── Customer.SetBalance (procedure) - called twice
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | SELECT for guards and amount; write via UpsertWithdraw |
| Billing.WithdrawToFunding | Table | SELECT for processed guard; cancel via UpdateWithdraw2Funding |
| Customer.Customer | Table | JOIN for IB guard |
| Trade.Provider | Table | IsIB check |
| History.Credit | Table | SELECT CreditTypeID=15 for cashout fee |
| History.ActiveCreditRecentMemoryBucket | Memory-optimized table | Recent credit supplement |
| Billing.UpdateWithdraw2Funding | Procedure | Cancel WTF legs |
| Billing.UpsertWithdraw | Procedure | Cancel Withdraw |
| Customer.SetBalance | Procedure | Restore amount (type=8) + fee (type=15) |
| Billing.TBL_Withdraw2Funding | User Defined Type | TVP for UpdateWithdraw2Funding |
| Billing.TBL_Withdraw | User Defined Type | TVP for UpsertWithdraw |
| History.ActiveCreditRecentMemoryBucket_TYPE | User Defined Type | In-memory table type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No DB-layer callers found | - | Called from application layer (PayoutUser, Billing SQL users) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IB guard | Application-level | Returns 60015 if IB customer |
| Not found / Already cancelled / Processed guard | Application-level | Returns 60025 for all three conditions |
| Balance guard | Application-level | Raises 60000 if Customer.SetBalance returns non-zero |
| Stale error message | Note | RAISERROR in catch references 'Billing.WithdrawRequestReverse' - copy-paste artifact |

---

## 8. Sample Queries

### 8.1 Reverse a withdrawal (payout path)

```sql
EXEC Billing.WithdrawRequestToReverse
    @WithdrawID = 987654,
    @ManagerID = 0,
    @Description = 'Payment provider rejection - funds returned',
    @ResponseID = 112233;
```

### 8.2 Compare which reversal procedure to use

```sql
-- Use WithdrawRequestToReverse when called from payout pipeline (no Comment/MoveMoneyReason needed)
-- Use WithdrawRequestReverse when Comment or MoveMoneyReasonID classification is required
-- Both have identical guard logic and write sequence for the core cancellation

SELECT 'WithdrawRequestToReverse: Parameters = 4 (no Comment, no MoveMoneyReasonID)'
UNION ALL
SELECT 'WithdrawRequestReverse:   Parameters = 6 (has Comment + MoveMoneyReasonID)';
```

### 8.3 Verify reversal result

```sql
SELECT
    w.WithdrawID,
    w.CashoutStatusID,
    w.Remark,
    w.ManagerID,
    w.ModificationDate,
    wtf.CashoutStatusID AS WTF_Status,
    wtf.ResponseID
FROM Billing.Withdraw w WITH (NOLOCK)
LEFT JOIN Billing.WithdrawToFunding wtf WITH (NOLOCK) ON wtf.WithdrawID = w.WithdrawID
WHERE w.WithdrawID = 987654;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawRequestToReverse | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawRequestToReverse.sql*
