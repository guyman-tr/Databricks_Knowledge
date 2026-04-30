# Billing.ManualWithdrawRequestReverse

> DBA crisis-management tool that reverses all open withdrawal requests for a customer, either completely (all pending/in-process/rejected withdrawals) or selectively (only while the customer's account balance remains negative).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer whose withdrawals are reversed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.ManualWithdrawRequestReverse` is an emergency operations procedure designed for crisis intervention. When a customer has open withdrawal requests but the platform needs to reclaim funds (for example, during a margin call event, a trading halt, or a negative-balance scenario), this procedure iterates over every open withdrawal for the customer and calls `Billing.WithdrawRequestReverse` to cancel and reverse each one.

The procedure was originally written for "Crisis 21.1.15" (January 21, 2015) based on its embedded comment. The comment also captures the intent: "You want all money or only until he got positive credit?" - meaning the operator can choose between full reversal (all withdrawals regardless of balance) or targeted reversal (only enough to bring the account out of negative).

Without this tool, operations staff would need to manually reverse each withdrawal one by one. This procedure automates the cursor-based iteration to handle customers who have multiple open withdrawals simultaneously.

Data flow: operator calls this procedure with a CID and the `@IsCloseNegative` mode. The procedure opens a cursor over `Billing.Withdraw` for the CID, loops through each active withdrawal (CashoutStatusID IN 1=Pending, 2=InProcess, 7=Rejected), conditionally checks `Customer.CustomerMoney.Credit`, and calls `Billing.WithdrawRequestReverse` per row. The '`Crisis 21.1.15`' string is passed as a remark to the reversal procedure to tag all reversals with this context.

---

## 2. Business Logic

### 2.1 Two Reversal Modes

**What**: Controls whether ALL withdrawals are reversed or only the subset needed to restore a positive balance.

**Parameters Involved**: `@IsCloseNegative`, `Customer.CustomerMoney.Credit`

**Rules**:
- `@IsCloseNegative = 1` (Close All): every open withdrawal is reversed regardless of current balance. Used when full fund reclamation is required.
- `@IsCloseNegative = 0` (Default - Close Only While Negative): for each withdrawal in the cursor loop, checks `Customer.CustomerMoney.Credit` for the CID. If credit < 0, reverses the withdrawal. If credit >= 0, stops reversing (prints "Balance is now positive" and skips remaining rows). Used to restore the account to zero without over-reversing.
- Default value of `@IsCloseNegative` is 0 (targeted mode) - the safer default that stops once balance is positive.

**Diagram**:
```
CURSOR: Billing.Withdraw WHERE CID=@CID AND CashoutStatusID IN (1, 2, 7)
  For each WithdrawID:
    |
    IsCloseNegative=1?
    YES -> EXEC WithdrawRequestReverse(@WithdrawID, 0, 'Crisis 21.1.15')
    NO  -> SELECT Credit FROM Customer.CustomerMoney WHERE CID=@CID
             Credit < 0?
             YES -> EXEC WithdrawRequestReverse(@WithdrawID, 0, 'Crisis 21.1.15')
             NO  -> PRINT 'Balance is now positive' (loop continues but skips)
```

### 2.2 Target Withdrawal Statuses

**What**: The procedure only targets withdrawals that are still actionable (not yet finalized).

**Columns Involved**: `Billing.Withdraw.CashoutStatusID`

**Rules**:
- CashoutStatusID = 1 (Pending): withdrawal submitted but not yet started processing.
- CashoutStatusID = 2 (InProcess): withdrawal is being processed but not yet sent to provider.
- CashoutStatusID = 7 (Rejected): withdrawal was rejected but not yet cancelled/reversed.
- Terminal statuses (3=Processed, 4=Canceled, 5=Partially Processed, 6=Payment Sent, etc.) are excluded - those cannot be reversed.
- The `'Crisis 21.1.15'` remark string is hardcoded - all reversals created by this procedure are tagged with this historical context string in `History.WithdrawAction`.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer identifier. Identifies the customer whose open withdrawal requests should be reversed. All rows in `Billing.Withdraw` with this CID and reversible statuses (1=Pending, 2=InProcess, 7=Rejected) are targeted. |
| 2 | @IsCloseNegative | int | YES | 0 | VERIFIED | Reversal mode flag. 0 (default) = selective mode: reverse withdrawals one by one, stopping as soon as `Customer.CustomerMoney.Credit >= 0` (targeted recovery to zero). 1 = full mode: reverse ALL open withdrawals for the customer regardless of balance. Despite the name, 1 means "close all" not just "close negative"; 0 means "close only until balance is positive". The comment in the code clarifies: "You want all money or only until he got positive credit?" |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + CashoutStatusID filter | [Billing.Withdraw](../Tables/Billing.Withdraw.md) | Read (cursor) | Iterates all open withdrawal requests for the customer with statuses 1=Pending, 2=InProcess, 7=Rejected. |
| @CID | Customer.CustomerMoney | Read (SELECT) | Reads current credit balance to determine if reversal should continue (mode 0 only). Checks Credit < 0. |
| @WithdrawID (per cursor row) | Billing.WithdrawRequestReverse | EXEC (callee) | Performs the actual reversal of each withdrawal. Called with WithdrawID, 0, and 'Crisis 21.1.15' remark. Not yet documented. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DBA / Operations staff | - | Manual EXEC | Executed manually by operations during crisis events or negative-balance interventions. No SQL-layer callers found. GRANT VIEW DEFINITION given to PROD\BIadmins. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.ManualWithdrawRequestReverse (procedure)
├── Billing.Withdraw (table) - cursor source
├── Customer.CustomerMoney (table) - credit balance check
└── Billing.WithdrawRequestReverse (procedure) - executes reversal per row
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.Withdraw](../Tables/Billing.Withdraw.md) | Table | Cursor SELECT - reads all open withdrawal rows for the customer (CashoutStatusID IN 1, 2, 7). |
| Customer.CustomerMoney | Table | SELECT Credit - reads current account balance per loop iteration (mode 0 only). |
| Billing.WithdrawRequestReverse | Stored Procedure | EXEC - performs the actual reversal. Called with (WithdrawID, 0, 'Crisis 21.1.15'). Pending documentation (future batch). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL-layer dependents found | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

The cursor iterates `Billing.Withdraw` filtered on (CID, CashoutStatusID IN (1,2,7)). The `ix_BillingWithdraw_CoveringNew` index covers (CID, CashoutStatusID) - this is the optimal index path for this query. However, the cursor re-reads `Customer.CustomerMoney` on every loop iteration (in mode 0), which is inefficient for customers with many open withdrawals. For high-volume scenarios, this is a DBA-awareness item.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Reverse all open withdrawals for a customer (full mode)

```sql
-- Mode 1: Reverse ALL open withdrawals regardless of balance
EXEC Billing.ManualWithdrawRequestReverse @CID = 123456, @IsCloseNegative = 1;
```

### 8.2 Reverse open withdrawals until balance is restored (targeted mode)

```sql
-- Mode 0 (default): Reverse only until Credit >= 0
EXEC Billing.ManualWithdrawRequestReverse @CID = 123456, @IsCloseNegative = 0;
-- Same as above (0 is default):
EXEC Billing.ManualWithdrawRequestReverse @CID = 123456;
```

### 8.3 Preview which withdrawals would be targeted before reversing

```sql
SELECT
    w.WithdrawID,
    w.CashoutStatusID,
    cs.Name AS StatusName,
    w.Amount,
    w.FundingTypeID,
    w.RequestDate
FROM Billing.Withdraw w WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON cs.CashoutStatusID = w.CashoutStatusID
WHERE w.CID = 123456
  AND w.CashoutStatusID IN (1, 2, 7)  -- Pending, InProcess, Rejected
ORDER BY w.RequestDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 callee (WithdrawRequestReverse) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ManualWithdrawRequestReverse | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.ManualWithdrawRequestReverse.sql*
