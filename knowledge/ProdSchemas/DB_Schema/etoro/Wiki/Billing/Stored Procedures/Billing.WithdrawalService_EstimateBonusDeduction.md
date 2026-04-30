# Billing.WithdrawalService_EstimateBonusDeduction

> Calculates the suggested bonus deduction amount for a withdrawal request: how much of the customer's deposit-related bonus should be clawed back based on their in/out balance ratio over the last 18 months. Returns 0 if no deposit-related bonuses exist.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID, @CurrentWithdrawAmount |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawalService_EstimateBonusDeduction` computes a "suggested bonus deduction amount" - the portion of a customer's bonus balance that should be reclaimed by eToro when a customer withdraws funds. Bonuses tied to deposits (DepositRelated bonuses) must be proportionally returned when a customer cashes out, to prevent bonus abuse where a customer deposits, claims a bonus, then immediately withdraws.

The algorithm is:
1. If the customer has NO deposit-related bonuses in the last 18 months: `@SuggestedBonusDeductionAmount = 0` (no deduction)
2. If they DO have deposit-related bonuses: calculate the deduction as the MINIMUM of:
   - **NWA minus non-deposit bonuses** (`NWA - NonDepositRelatedBonuses`): how much bonus remains after accounting for non-deposit bonuses (capped at 0 if negative)
   - **Proportional share** (`CurrentWithdrawAmount * DepositRelatedBonuses / InOutBalance`): the fraction of deposit-related bonus proportional to the withdrawal amount vs. total in/out flow

Called by `Billing.WithdrawRequestAdd` before creating the withdrawal record, to populate `Billing.Withdraw.SuggestedBonusDeductionAmount`.

Change history: Adi 25/12/2016 FB:42847 (negative check), Shay Oren 03/01/2021 (in-memory table access).

---

## 2. Business Logic

### 2.1 Dual-Store Credit Load (18-month window)

**What**: Loads CreditTypeIDs 1 (Deposit), 6 (Compensation), and 7 (Bonus) into a local table variable from both History.Credit and History.ActiveCreditRecentMemoryBucket.

**Rules**:
- `@PeriodicCalc INT = -18` months lookback window
- INSERT from `History.Credit WHERE CID=@CID AND CreditTypeID IN (7,6,1) AND Occurred >= DateAdd(mm, -18, CAST(GetUTCDate() AS DATE))`
- INSERT from `History.ActiveCreditRecentMemoryBucket` with same filter (catches recent credits)
- `@ActiveCreditLocal` is a local table variable of type `History.ActiveCreditRecentMemoryBucket_TYPE`

### 2.2 Bonus Aggregation

**What**: Sums deposit-related bonuses, non-deposit bonuses, compensation adjustments, and total deposits.

**Rules**:
- FROM `@ActiveCreditLocal` LEFT JOIN `BackOffice.BonusType` ON BonusTypeID (to get IsDepositRelated flag)
- **@DepositRelatedBonuses**: SUM(TotalCashChange WHERE CreditTypeID=7 AND IsDepositRelated=1) - bonuses tied to deposits
- **@NonDepositRelatedBonuses**: SUM(TotalCashChange WHERE CreditTypeID=7 AND IsDepositRelated=0) - non-deposit bonuses (e.g., retention, referral)
- **@CompensasionAdjustment**: SUM(TotalCashChange WHERE CreditTypeID=6 AND CompensationReasonID=33) - specific compensation type
- **@TotalDeposits**: SUM(TotalCashChange WHERE CreditTypeID=1) - total deposit amounts
- All use COALESCE(..., 0) to default NULL to 0

### 2.3 Deduction Calculation (Only When Deposit-Related Bonuses Exist)

**What**: Computes the deduction only if @DepositRelatedBonuses > 0.

**Rules**:
- If @DepositRelatedBonuses = 0: skip calculation entirely, @SuggestedBonusDeductionAmount = ISNULL(NULL, 0) = 0
- If @DepositRelatedBonuses > 0:

**Step 1**: Get NWA (Net Withdrawable Amount - bonus credit balance):
- `@NWA = Customer.CustomerMoney.BonusCredit WHERE CID = @CID`

**Step 2**: Get total processed withdrawals (last 18 months):
- `@TotalProcessedWithdrawals = SUM(Amount) FROM Billing.Withdraw WHERE CID=@CID AND CashoutStatusID=3 AND CashoutReasonID IN (1,2,3,6,7,8,10,11,12,13,16,17) AND RequestDate >= DateAdd(mm,-18,...)`

**Step 3**: Compute In/Out Balance:
- `@InOutBalance = @TotalDeposits + @TotalProcessedWithdrawals + @CompensasionAdjustment`
- Floor at 1 if < 1 (prevents division by zero)

**Step 4**: Compute two candidate deduction amounts:
- `@LeftResultQueryAmount = MAX(0, NWA - NonDepositRelatedBonuses)` - NWA minus non-deposit bonuses, floored at 0 (FB:42847 fix)
- `@RighResultQueryAmount = CurrentWithdrawAmount * (DepositRelatedBonuses / InOutBalance)` - proportional share

**Step 5**: Take the minimum:
- `@SuggestedBonusDeductionAmount = MIN(@LeftResultQueryAmount, @RighResultQueryAmount)`

**Diagram**:
```
IF DepositRelatedBonuses > 0:
  NWA = Customer.CustomerMoney.BonusCredit
  InOutBalance = TotalDeposits + ProcessedWithdrawals + CompensationAdj (min 1)

  Left  = MAX(0, NWA - NonDepositRelatedBonuses)
  Right = CurrentWithdrawAmount * (DepositRelatedBonuses / InOutBalance)

  SuggestedDeduction = MIN(Left, Right)
ELSE:
  SuggestedDeduction = 0
```

### 2.4 CashoutReasonID Filter for Processed Withdrawals

**Rules**:
- `CashoutReasonID IN (1,2,3,6,7,8,10,11,12,13,16,17)` - standard cashout reasons
- This excludes special compensation-type withdrawals (IDs not in this list, e.g., Guru cash=41, Affiliate=51, PI Reimbursement=121) from the processed withdrawal total
- Mirrors the logic in `Billing.WithdrawRequestAdd` for fee exemption

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Used to filter all credit/deposit/withdrawal queries. |
| 2 | @CurrentWithdrawAmount | MONEY | NO | - | CODE-BACKED | The requested withdrawal amount in USD. Used in the proportional deduction calculation: `@CurrentWithdrawAmount * (DepositRelatedBonuses / InOutBalance)`. Passed in dollars (not cents). |
| 3 | @SuggestedBonusDeductionAmount | MONEY OUTPUT | NO | - | CODE-BACKED | OUTPUT: the calculated bonus deduction amount in USD. 0 if no deposit-related bonuses exist. Stored in `Billing.Withdraw.SuggestedBonusDeductionAmount` by the caller. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | History.Credit | SELECT | 18-month credit history (deposits, bonuses, compensations) |
| @CID | History.ActiveCreditRecentMemoryBucket | SELECT | Recent credits not yet in History.Credit |
| @CID | Billing.Withdraw | SELECT | Processed withdrawals in last 18 months for InOutBalance calc |
| @CID | Customer.CustomerMoney | SELECT | NWA (BonusCredit) - current bonus balance |
| HC.BonusTypeID | BackOffice.BonusType | LEFT JOIN | IsDepositRelated flag to classify bonuses |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawRequestAdd | EXEC (line 61) | Caller | Called before creating the withdraw record; result stored in SuggestedBonusDeductionAmount |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawalService_EstimateBonusDeduction (procedure)
+-- History.Credit (table) [SELECT - deposit/bonus/compensation history]
+-- History.ActiveCreditRecentMemoryBucket (in-memory table) [SELECT - recent credits]
+-- Billing.Withdraw (table) [SELECT - processed withdrawals]
+-- Customer.CustomerMoney (table) [SELECT - NWA/BonusCredit]
+-- BackOffice.BonusType (table) [LEFT JOIN - IsDepositRelated flag]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | 18-month credit history for CreditTypeID IN (1,6,7) |
| History.ActiveCreditRecentMemoryBucket | In-Memory Table | Recent credits not archived yet |
| Billing.Withdraw | Table | Processed withdrawals (CashoutStatusID=3) last 18 months |
| Customer.CustomerMoney | Table | BonusCredit (NWA) for the customer |
| BackOffice.BonusType | Table | IsDepositRelated flag to classify CreditTypeID=7 bonuses |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawRequestAdd | Stored Procedure | Calls EXEC to populate @BonusDeduction before creating the withdraw record |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @InOutBalance floored at 1 | Logic | Prevents division by zero in proportional calculation |
| @LeftResultQueryAmount floored at 0 | Logic | FB:42847 fix - prevents negative deduction if NonDepositBonuses > NWA |
| Non-negative deduction | Logic | Both candidate amounts are >= 0; MIN of two non-negatives is always >= 0 |
| 18-month lookback | Business Rule | @PeriodicCalc = -18 months; credits/withdrawals older than 18 months not considered |
| TRY/CATCH THROW | Design | Propagates errors; no error suppression |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Estimate bonus deduction for a withdrawal
```sql
DECLARE @BonusDeduction MONEY;
EXEC Billing.WithdrawalService_EstimateBonusDeduction
    @CID                          = 123456,
    @CurrentWithdrawAmount        = 500.00,
    @SuggestedBonusDeductionAmount = @BonusDeduction OUTPUT;
SELECT @BonusDeduction AS SuggestedBonusDeduction;
```

### 8.2 Check customer's bonus credit balance (NWA)
```sql
SELECT BonusCredit AS NWA
FROM Customer.CustomerMoney WITH (NOLOCK)
WHERE CID = 123456;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.3/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.WithdrawalService_EstimateBonusDeduction | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawalService_EstimateBonusDeduction.sql*
