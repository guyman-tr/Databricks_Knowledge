# Billing.WithdrawToFundingAdd

> Creates a new payment execution leg (WithdrawToFunding row) for an approved, in-process withdrawal request, with full validation of withdrawal status, cashout type, and deposit linkage for refund scenarios.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID + @FundingID -> new WithdrawToFunding row, ID returned via @ID OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawToFundingAdd` is the write procedure for creating a new payment execution leg in `Billing.WithdrawToFunding`. When the payout system decides to send a withdrawal payment to a specific funding instrument (card, bank, wallet), this procedure creates the record that tracks that execution attempt.

The procedure enforces the core business rules of the withdrawal pipeline: a payment leg can only be created for a withdrawal that is both approved and in-process (CashoutStatusID=2 or 5 and Approved=1). This prevents creating payment legs for pending, cancelled, or already-processed withdrawals. A withdrawal can have multiple payment legs if earlier legs are rejected or cancelled and a re-attempt is made with a different routing.

For refund scenarios (CashoutTypeID=2, where a prior deposit is being refunded back to the customer), the procedure validates that the referenced deposit exists and has not already been refunded to this same withdrawal request - preventing double-refunds.

The actual INSERT into `Billing.WithdrawToFunding` (and the corresponding audit insert into `History.WithdrawToFundingAction`) is delegated to `Billing.InsertWithdraw2Funding` via a `Billing.TBL_Withdraw2Funding` TVP. This indirection was introduced in DBA-648 (2021-09-23) to standardize the write path through a common data procedure.

Note: `@Amount` is accepted as an **integer in cents** and converted to MONEY by dividing by 100. This is a common eToro internal convention for monetary amounts.

---

## 2. Business Logic

### 2.1 Pre-Insert Validation

**What**: Three validation gates that must all pass before the INSERT proceeds.

**Columns/Parameters Involved**: `@WithdrawID`, `@CashoutTypeID`, `@DepositID`, `@RefundAmountInDepositCurrency`

**Rules**:
- **Gate 1 - Withdrawal status check**: `Billing.Withdraw` must have CashoutStatusID IN (2, 5) AND Approved=1. If not: RAISERROR 60025 "Cashout Request is in an illegal status or is not approved".
- **Gate 2 - CashoutType validity**: @CashoutTypeID must exist in `Dictionary.CashoutType`. If not: RAISERROR 60025 "Unsupported Cashout Type".
- **Gate 3 - Refund validation** (only when CashoutTypeID=2):
  - @DepositID must exist in `Billing.Deposit`. If not: RAISERROR 60025 "DepositID does not exist".
  - The deposit must not already have a non-cancelled/non-rejected WithdrawToFunding row for this withdrawal (CashoutStatusID NOT IN (4, 7)). If so: RAISERROR 60025 "This Deposit has already been refunded to this Cashout Request".
  - Both @DepositID AND @RefundAmountInDepositCurrency must either both be provided or both be NULL (NULL sum check: `(@DepositID + @RefundAmountInDepositCurrency) IS NULL`). If mixed: RAISERROR 60025 "Cannot refund from deposit without DepositID and Refund Amount In Deposit Currency".

**Diagram**:
```
[CALL] WithdrawToFundingAdd
    |
    v
Check: Billing.Withdraw CashoutStatusID IN (2,5) AND Approved=1
    |-- FAIL -> RAISERROR 60025, RETURN 60025
    v
Check: Dictionary.CashoutType has @CashoutTypeID
    |-- FAIL -> RAISERROR 60025, RETURN 60025
    v
IF CashoutTypeID=2 (Refund):
    Check: Billing.Deposit has @DepositID
        |-- FAIL -> RAISERROR 60025, RETURN 60025
    Check: No active refund for this deposit+withdraw already
        |-- EXISTS -> RAISERROR 60025, RETURN 60025
    Check: Both DepositID AND RefundAmount provided (or both NULL)
        |-- FAIL -> RAISERROR 60025, RETURN 60025
    v
BEGIN TRY / BEGIN TRAN
    INSERT into @InfoWTF TVP
    EXEC @ID = Billing.InsertWithdraw2Funding @InfoWTF
COMMIT / RETURN 0
```

### 2.2 Amount Cents-to-Money Conversion

**What**: @Amount is passed as integer cents and must be divided by 100 to store as MONEY.

**Columns/Parameters Involved**: `@Amount`, `Amount` (in Billing.WithdrawToFunding)

**Rules**:
- `CAST(@Amount AS MONEY) / 100` - converts cent integer to MONEY (e.g., 5000 cents = $50.00)
- This is the eToro internal convention for passing monetary amounts as integers to avoid floating-point precision issues

### 2.3 PayPal Refund XML Initialization

**What**: For PayPal refunds, WithdrawData is initialized to a blank XML template rather than NULL.

**Columns/Parameters Involved**: `FundingTypeID`, `@CashoutTypeID`, `@WithdrawData`

**Rules**:
- When FundingTypeID=3 (PayPal) AND CashoutTypeID=2 (Refund): `@WithdrawData = '<Withdraw xmlns:xsd="..." xmlns:xsi="..." />'` (empty XML element)
- All other cases: `@WithdrawData = NULL`
- Historical comment from 2015-05-18 indicates this is specific to PayPal refund processing behavior

### 2.4 DepotID Derivation for Refunds

**What**: For refunds, the DepotID is inherited from the original deposit being refunded.

**Columns/Parameters Involved**: `@DepositID`, `@DepotID`

**Rules**:
- If @DepositID IS NOT NULL: `@DepotID = Billing.Deposit.DepotID` for that deposit
- If @DepositID IS NULL (cashout type, not refund): `@DepotID = NULL`
- This ensures refund legs are routed through the same depot as the original deposit

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | int | NO | - | CODE-BACKED | Required. FK to Billing.Withdraw. The parent withdrawal request this payment leg belongs to. Must be in CashoutStatusID IN (2,5) AND Approved=1 or validation fails. |
| 2 | @FundingID | int | NO | - | CODE-BACKED | Required. FK to Billing.Funding. The payment instrument the funds will be sent to (card, bank account, wallet). |
| 3 | @ProcessCurrencyID | int | NO | - | CODE-BACKED | Required. FK to Dictionary.Currency. Currency in which the provider will process this payout. |
| 4 | @ManagerID | int | NO | - | CODE-BACKED | Required. ID of the manager or system user initiating this payment leg. Written directly to WithdrawToFunding.ManagerID. |
| 5 | @Amount | int | NO | - | CODE-BACKED | Required. Withdrawal amount in CENTS (integer). Stored as `CAST(@Amount AS MONEY) / 100` - e.g., 5000 = $50.00. This is the eToro cents convention for monetary amounts. |
| 6 | @ID | int OUTPUT | NO | - | CODE-BACKED | Required output. Returns the identity value of the newly created Billing.WithdrawToFunding row. Set by Billing.InsertWithdraw2Funding via EXECUTE @ID = ... |
| 7 | @CashoutTypeID | tinyint | YES | 1 | CODE-BACKED | Payment leg type. 1=Cashout (direct withdrawal, default), 2=Refund (refund of a prior deposit). Must exist in Dictionary.CashoutType. |
| 8 | @DepositID | int | YES | NULL | CODE-BACKED | For refund legs (CashoutTypeID=2): the DepositID being refunded. Used to derive DepotID and to prevent duplicate refunds. Must exist in Billing.Deposit. NULL for cashout legs. |
| 9 | @RefundAmountInDepositCurrency | money | YES | NULL | CODE-BACKED | For refund legs: the refund amount in the original deposit's currency (may differ from @Amount due to FX changes). Must be provided alongside @DepositID. |
| 10 | @ExchangeRate | dtPrice | YES | 1.0 | CODE-BACKED | FX rate used to convert from the customer's currency to @ProcessCurrencyID. Default=1.0 (no conversion). |
| 11 | @BaseExchangeRate | dtPrice | YES | NULL | CODE-BACKED | Base FX rate before fee markup. Used for spread/fee calculation. NULL if no exchange rate adjustment. |
| 12 | @ExchangeFee | int | YES | NULL | CODE-BACKED | FX fee amount in provider-specific units. NULL if no fee. |
| 13 | @CashoutModeID | tinyint | YES | NULL | CODE-BACKED | Withdrawal execution mode. 1=Standard, 2=Alternate (eToroMoney/ACH), NULL=legacy. |
| 14 | @CashoutStatusID | int | YES | 1 | CODE-BACKED | Initial status for the new leg. Default=1 (Pending). Allows creating legs in other initial states if needed. |
| 15 | @AdditionalInformation | nvarchar(250) | YES | NULL | CODE-BACKED | Free-text additional information for this payment leg. Stored in WithdrawToFunding.AdditionalInformation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.Withdraw | Validation + FK | Validates status/approval; parent of the new row |
| @FundingID | Billing.Funding | Lookup | Reads FundingTypeID for PayPal refund XML logic |
| @DepositID | Billing.Deposit | Validation + FK | Validates existence; reads DepotID for refund legs |
| @CashoutTypeID | Dictionary.CashoutType | Validation | Validates cashout type exists |
| (writes via) | Billing.InsertWithdraw2Funding | Callee | Actual INSERT delegated to this procedure via TBL_Withdraw2Funding TVP |
| (writes to) | Billing.WithdrawToFunding | Indirect writer | InsertWithdraw2Funding writes the row and audit history |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawAndWithdrawToFundingAdd | @WithdrawID, @FundingID, ... | Caller | Composite procedure that creates a Withdraw + WithdrawToFunding in one call |
| Payout application service | various params | Caller | Called when routing a withdrawal payment to a specific funding instrument |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFundingAdd (procedure)
├── Billing.Withdraw (table)
├── Billing.Funding (table)
├── Billing.Deposit (table)
├── Dictionary.CashoutType (table)
├── Billing.WithdrawToFunding (table)
└── Billing.InsertWithdraw2Funding (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Validation: checks CashoutStatusID + Approved |
| Billing.Funding | Table | Reads FundingTypeID for PayPal refund logic |
| Billing.Deposit | Table | Validation + reads DepotID for refund legs |
| Dictionary.CashoutType | Table | Validates @CashoutTypeID exists |
| Billing.WithdrawToFunding | Table | Duplicate refund check |
| Billing.InsertWithdraw2Funding | Procedure | Delegates the actual INSERT |
| Billing.TBL_Withdraw2Funding | User Defined Type | TVP for passing data to InsertWithdraw2Funding |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawAndWithdrawToFundingAdd | Procedure | Calls this procedure as part of a composite atomic operation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BEGIN TRY/CATCH with transaction | Design | COMMIT on success; ROLLBACK if @@TRANCOUNT=1; COMMIT if @@TRANCOUNT>1 (nested transaction); THROW re-raises exception |
| RAISERROR 60025 | Business Rule | Used for all business validation failures; returns 60025 error code |
| Amount in cents | Convention | @Amount is INT cents divided by 100 to get MONEY - not standard MONEY type |
| DBA-648 refactor | Architecture | INSERT into Billing.WithdrawToFunding and History.WithdrawToFundingAction are now done inside Billing.InsertWithdraw2Funding. The original direct INSERT code is commented out in the DDL. |

---

## 8. Sample Queries

### 8.1 Create a standard cashout payment leg

```sql
DECLARE @NewID INT;
EXEC Billing.WithdrawToFundingAdd
    @WithdrawID = 1234567,
    @FundingID = 987654,
    @ProcessCurrencyID = 1,       -- USD
    @ManagerID = 42,
    @Amount = 50000,              -- $500.00 (in cents)
    @ID = @NewID OUTPUT,
    @CashoutTypeID = 1,           -- Cashout
    @ExchangeRate = 1.0;
SELECT @NewID AS NewWithdrawToFundingID;
```

### 8.2 Create a refund payment leg

```sql
DECLARE @NewID INT;
EXEC Billing.WithdrawToFundingAdd
    @WithdrawID = 1234567,
    @FundingID = 987654,
    @ProcessCurrencyID = 1,
    @ManagerID = 42,
    @Amount = 50000,              -- $500.00 (in cents)
    @ID = @NewID OUTPUT,
    @CashoutTypeID = 2,           -- Refund
    @DepositID = 111222,
    @RefundAmountInDepositCurrency = 500.00,
    @ExchangeRate = 1.0;
```

### 8.3 Check if a withdrawal is eligible for a new payment leg

```sql
SELECT
    w.WithdrawID,
    w.CashoutStatusID,
    w.Approved,
    w.Amount,
    w.CID
FROM Billing.Withdraw w WITH (NOLOCK)
WHERE w.WithdrawID = 1234567
  AND w.CashoutStatusID IN (2, 5)
  AND w.Approved = 1;
-- If this returns 1 row, the withdrawal is eligible for WithdrawToFundingAdd
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| DBA-648 (referenced in DDL comment, 2021-09-23) | Jira | Refactored to delegate INSERT to Billing.InsertWithdraw2Funding via TVP rather than direct INSERT - standardized write path |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira (1 ticket referenced in DDL comment) | Procedures: 1 caller analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingAdd.sql*
