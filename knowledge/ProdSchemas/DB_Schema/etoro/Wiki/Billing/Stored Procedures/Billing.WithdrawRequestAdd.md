# Billing.WithdrawRequestAdd

> Creates a new withdrawal (cashout) request: estimates bonus deduction, validates IB eligibility, calculates cashout fee, creates the Billing.Withdraw record via UpsertWithdraw, and atomically debits the customer's balance for both the fee and net withdrawal amount.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawRequestAdd` is the primary entry point for creating a new withdrawal (cashout) request on the eToro platform. It orchestrates the full withdrawal creation flow:

1. **Bonus deduction estimation**: Calls `WithdrawalService_EstimateBonusDeduction` to calculate how much of the customer's bonus must be returned.
2. **IB validation**: Blocks Introducing Brokers (IB providers) from submitting withdrawals (error 60015).
3. **Cashout fee calculation**: Looks up the applicable fee from `Trade.CashoutRange` based on the withdrawal amount and the customer's `CashoutFeeGroupID`. Fee is waived for compensation-type withdrawals (CompensationReasonID 41, 51, 121).
4. **Withdrawal record creation**: Builds a `Billing.TBL_Withdraw` TVP and calls `Billing.UpsertWithdraw` to INSERT the new withdrawal into `Billing.Withdraw` and create the initial `History.WithdrawAction` entry. Returns the new `@WithdrawID`.
5. **Balance debits**: Calls `Customer.SetBalance` twice within the same transaction:
   - CreditType=15 (cashout fee): deducts the fee amount
   - CreditType=9 (cashout request): deducts the net withdrawal amount

The entire write (UpsertWithdraw + two SetBalance calls) runs within a single transaction with full TRY/CATCH. Amounts are passed in integer cents (×100) throughout; divided by 100.0 when storing as MONEY values.

Change history: Geri Reshef 03/02/2016 (CashoutReasonID), pini 23.02.16 (pass to SetBalance), Geri Reshef 14/11/2016 (new columns), pini 23.11.16 (bonus deduction), Avraham 17/11/2019 (ClientPersonalID), Adi 19/11/2019 (rollback), Shay Oren 23/09/2021 DBA-648 (UpsertWithdraw).

---

## 2. Business Logic

### 2.1 Default CashoutReasonID

**What**: If no cashout reason is provided, defaults to 16 (Requested by User).

**Rules**:
- `IF ISNULL(@CashoutReasonID, 0) = 0 SET @CashoutReasonID = 16`
- CashoutReasonID=16 = standard customer-initiated withdrawal
- Compensation-type reasons (e.g., 41=Guru cash, 51=Affiliate payment, 121=PI Reimbursement) can be passed explicitly

### 2.2 Bonus Deduction Estimation

**What**: Calls `WithdrawalService_EstimateBonusDeduction` to determine how much bonus credit to claw back.

**Rules**:
- `@RequestedAmountInDollars = @Amount / 100.0` - converts cents to dollars for the estimation call
- `EXEC Billing.WithdrawalService_EstimateBonusDeduction @CID, @RequestedAmountInDollars, @BonusDeduction OUTPUT`
- Result stored in `@BonusDeduction`; written to `Billing.Withdraw.SuggestedBonusDeductionAmount`
- 0 if no deposit-related bonuses exist; positive amount otherwise

### 2.3 IB (Introducing Broker) Block

**What**: Prevents customers who are associated with an Introducing Broker provider from submitting withdrawals.

**Rules**:
- `IF EXISTS (SELECT 1 FROM Customer.Customer CCST CROSS JOIN Trade.Provider TPRV WHERE CCST.CID=@CID AND CCST.ProviderID=TPRV.ProviderID AND TPRV.IsIB=1)`
  - RAISERROR(60015, 16, 1) + RETURN 60015
- `Trade.Provider.IsIB=1` identifies Introducing Broker providers
- IB customers use a different withdrawal pathway managed by the IB agreements

### 2.4 Cashout Fee Calculation

**What**: Looks up the applicable fee percentage from Trade.CashoutRange based on amount and fee group.

**Rules**:
- `@CashoutFeeGroupID` from `BackOffice.Customer.CashoutFeeGroupID` for this customer
- `SELECT TOP 1 @CashoutFee = Fee*100 FROM Trade.CashoutRange WHERE CashoutFeeGroupID=@CashoutFeeGroupID AND @Amount/100.0 >= FromValue AND @Amount/100.0 <= ToValue AND @CompensationReasonID NOT IN (41, 51, 121)`
- Fee is returned as cents (Fee * 100) to match @Amount units
- CompensationReasonID 41 (Guru cash/CO), 51 (Affiliate payment/CO), 121 (PI Reimbursement) are exempt from fees → @CashoutFee remains 0
- If no matching range, @CashoutFee remains 0 (default MONEY = 0)

### 2.5 Withdrawal Record Creation via UpsertWithdraw

**What**: Builds a TBL_Withdraw TVP and delegates the INSERT to Billing.UpsertWithdraw.

**Rules**:
- Net amount stored: `CAST(@Amount - @CashoutFee AS MONEY) / 100.0` (cents after fee → dollars)
- Fee stored: `CAST(@CashoutFee AS MONEY) / 100.0` (cents → dollars)
- Commission=0, Approved=0 (initial state)
- `EXECUTE @WithdrawID = Billing.UpsertWithdraw @Info` - returns new WithdrawID on success
- UpsertWithdraw handles the INSERT to Billing.Withdraw and the initial INSERT to History.WithdrawAction

### 2.6 Dual Balance Debit via Customer.SetBalance

**What**: Two sequential calls to Customer.SetBalance debit the customer's cash balance for fee and net withdrawal.

**Rules**:
- Before first call: `@CashoutFee = -@CashoutFee` (makes it negative for debit)
- **Call 1** (fee debit): `EXEC Customer.SetBalance @CID, @CashoutFee, CreditType=15, ..., @WithdrawID, @CashoutReasonID`
  - CreditType=15 = cashout fee; creates a credit history entry for the fee deduction
- Before second call: `@Amount = -@Amount - @CashoutFee` (negative net amount in cents; @CashoutFee is already negative so this is: -@Amount - (-originalFee) = -(amount - fee))
  - Wait: at this point @CashoutFee is negative (set at line 227), so `@Amount = -@Amount - @CashoutFee = -@Amount + |originalFee|`. This is -(amount - |originalFee|) = -(net amount). Correct: deducts only the net (after-fee) amount.
- **Call 2** (net debit): `EXEC Customer.SetBalance @CID, @Amount, CreditType=9, ..., @WithdrawID, @CashoutReasonID`
  - CreditType=9 = cashout request; creates the main withdrawal debit in the credit history
- On error: RAISERROR('Call for Customer.SetBalance from Billing.WithdrawRequestAdd failed', 16, 0)

### 2.7 Transaction Scope

**Rules**:
- `BEGIN TRANSACTION` wraps UpsertWithdraw + both SetBalance calls
- TRY/CATCH: ROLLBACK if @@TRANCOUNT=1 (outermost), COMMIT if @@TRANCOUNT>1 (nested safe), THROW re-propagates
- On COMMIT: RETURN 0

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INTEGER OUTPUT | NO | - | CODE-BACKED | Output: the new WithdrawID assigned by Billing.UpsertWithdraw (SCOPE_IDENTITY of Billing.Withdraw). The caller must pass a variable to capture this. |
| 2 | @CashoutStatusID | INTEGER | NO | - | CODE-BACKED | Initial cashout status for the new withdrawal. Typically 1 (Pending). |
| 3 | @CashoutReasonID | INTEGER | YES | NULL | CODE-BACKED | Reason for the withdrawal. Defaults to 16 (Requested by User) if NULL or 0. Compensation reasons 41/51/121 are fee-exempt. |
| 4 | @FundingTypeID | INTEGER | NO | - | CODE-BACKED | Payment method for the withdrawal (e.g., 1=Credit Card, 2=Wire Transfer). Stored on Billing.Withdraw. |
| 5 | @CurrencyID | INTEGER | NO | - | CODE-BACKED | Currency of the withdrawal amount. Stored on Billing.Withdraw. |
| 6 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Used for all customer lookups and as the IB check subject. |
| 7 | @RequestDate | DATETIME | NO | - | CODE-BACKED | The timestamp of the withdrawal request. Stored as Billing.Withdraw.RequestDate. |
| 8 | @Amount | INTEGER | NO | - | CODE-BACKED | Requested withdrawal amount in integer cents (e.g., 50000 = $500.00). Divided by 100.0 when stored as MONEY. Net amount stored = (Amount - CashoutFee) / 100.0. |
| 9 | @IPAddress | NUMERIC | NO | - | CODE-BACKED | Customer IP address at time of request (stored as NUMERIC). |
| 10 | @ManagerID | INTEGER | YES | NULL | CODE-BACKED | Operator or service account. NULL = customer self-service. -1 = billing service. |
| 11 | @Description | VARCHAR(255) | YES | NULL | CODE-BACKED | Internal description/remark. Passed to Customer.SetBalance as the description. Stored as Billing.Withdraw.Remark. |
| 12 | @Comment | NVARCHAR(255) | YES | NULL | CODE-BACKED | Customer-visible comment. Stored as Billing.Withdraw.Comment. |
| 13 | @FundingID | INTEGER | YES | NULL | CODE-BACKED | Optional FK to Billing.Funding. Links the withdrawal to a specific funding method record. |
| 14 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Web session ID at time of request. Stored on Billing.Withdraw. |
| 15 | @ClientWithdrawReasonID | INT | YES | NULL | CODE-BACKED | Customer-provided reason for withdrawal (selected from UI dropdown). |
| 16 | @ClientWithdrawReasonComment | NVARCHAR(510) | YES | NULL | CODE-BACKED | Free-text customer comment on withdrawal reason. |
| 17 | @ClientPersonalID | VARCHAR(255) | YES | NULL | CODE-BACKED | Personal identification provided by customer (added/removed per Yoav 12/09/2019 #13312 - removed from Billing.Withdraw, but parameter kept for API compatibility). |
| 18 | @CompensationReasonID | INTEGER | YES | 0 | CODE-BACKED | Compensation type for operator-initiated withdrawals. 0 = standard. 41=Guru cash/CO, 51=Affiliate payment/CO, 121=PI Reimbursement are fee-exempt. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Billing.WithdrawalService_EstimateBonusDeduction | EXEC | Estimates bonus deduction amount |
| @CID | Customer.Customer + Trade.Provider | SELECT (IB check) | Validates customer is not an IB |
| @CID | BackOffice.Customer | SELECT | Retrieves CashoutFeeGroupID |
| @CashoutFeeGroupID | Trade.CashoutRange | SELECT | Retrieves applicable cashout fee |
| @Info TVP | Billing.UpsertWithdraw | EXEC | Creates Billing.Withdraw record and initial history |
| @CID | Customer.SetBalance | EXEC x2 | Debits customer balance (fee + net amount) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Withdrawal Service (application) | Withdrawal submission EP | Application call | Primary caller for new withdrawal creation |
| Back Office (application) | Manual withdrawal creation | Application call | BO operators create withdrawals on behalf of customers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawRequestAdd (procedure)
+-- Billing.WithdrawalService_EstimateBonusDeduction (procedure) [EXEC - bonus deduction]
+-- Customer.Customer (table) [SELECT - IB check]
+-- Trade.Provider (table) [CROSS JOIN - IB flag]
+-- BackOffice.Customer (table) [SELECT - CashoutFeeGroupID]
+-- Trade.CashoutRange (table) [SELECT - fee lookup]
+-- Billing.TBL_Withdraw (UDT) [TVP for UpsertWithdraw]
+-- Billing.UpsertWithdraw (procedure) [EXEC - Withdraw INSERT + history]
    +-- Billing.Withdraw (table) [INSERT]
    +-- History.WithdrawAction (table) [INSERT]
+-- Customer.SetBalance (procedure) [EXEC x2 - balance debit]
    +-- History.Credit (table) [INSERT - CreditType 15 + 9]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawalService_EstimateBonusDeduction | Stored Procedure | Bonus deduction estimate |
| Customer.Customer | Table | IB check |
| Trade.Provider | Table | IsIB flag check |
| BackOffice.Customer | Table | CashoutFeeGroupID lookup |
| Trade.CashoutRange | Table | Fee lookup by amount range and group |
| Billing.UpsertWithdraw | Stored Procedure | Withdraw record creation + initial history |
| Customer.SetBalance | Stored Procedure | Customer balance debits (fee + net) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Withdrawal Service (application) | Application | Primary caller for new customer withdrawal requests |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IB block | Business Rule | RAISERROR 60015 if customer is an IB; no withdrawals for IB providers |
| Fee exemption | Business Rule | CompensationReasonID 41/51/121 exempt from cashout fee (zero @CashoutFee) |
| Amount in cents | Design | @Amount and @CashoutFee are integer cents; must be divided by 100.0 for MONEY storage |
| Nested transaction safe | Design | TRY/CATCH uses @@TRANCOUNT to safely handle both outermost and nested callers |
| CashoutReasonID default | Design | NULL or 0 → 16 (Requested by User) |

---

## 8. Sample Queries

### 8.1 Create a standard customer withdrawal ($500.00)
```sql
DECLARE @NewWithdrawID INT;
EXEC Billing.WithdrawRequestAdd
    @WithdrawID                   = @NewWithdrawID OUTPUT,
    @CashoutStatusID              = 1,          -- Pending
    @CashoutReasonID              = NULL,        -- defaults to 16 (User Request)
    @FundingTypeID                = 1,           -- Credit Card
    @CurrencyID                   = 1,           -- USD
    @CID                          = 123456,
    @RequestDate                  = GETUTCDATE(),
    @Amount                       = 50000,       -- $500.00 in cents
    @IPAddress                    = 3232235520,  -- 192.168.0.0
    @ManagerID                    = NULL,
    @FundingID                    = 98765,
    @CompensationReasonID         = 0;
SELECT @NewWithdrawID AS NewWithdrawID;
```

### 8.2 Create a compensation-type withdrawal (fee-exempt)
```sql
DECLARE @NewWithdrawID INT;
EXEC Billing.WithdrawRequestAdd
    @WithdrawID           = @NewWithdrawID OUTPUT,
    @CashoutStatusID      = 1,
    @CashoutReasonID      = 41,       -- Guru cash/CO
    @FundingTypeID        = 1,
    @CurrencyID           = 1,
    @CID                  = 123456,
    @RequestDate          = GETUTCDATE(),
    @Amount               = 10000,    -- $100.00 in cents
    @IPAddress            = 3232235520,
    @CompensationReasonID = 41;       -- fee-exempt
SELECT @NewWithdrawID AS NewWithdrawID;
```

### 8.3 View the withdrawal just created
```sql
SELECT w.WithdrawID, w.CID, w.Amount, w.Fee, w.CashoutStatusID,
       w.SuggestedBonusDeductionAmount, w.RequestDate
FROM Billing.Withdraw w WITH (NOLOCK)
WHERE w.WithdrawID = @NewWithdrawID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.4/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (EstimateBonusDeduction) | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.WithdrawRequestAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawRequestAdd.sql*
