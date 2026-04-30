# BackOffice.WithdrawToFundingAdd

> Creates a new cashout-to-funding-method routing record linking an approved withdrawal to a specific funding instrument, validating eligibility and deposit-refund limits before inserting into Billing.WithdrawToFunding with a History.WithdrawToFundingAction audit row.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ID OUTPUT - SCOPE_IDENTITY() of the new Billing.WithdrawToFunding row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.WithdrawToFundingAdd` is the write procedure for `Billing.WithdrawToFunding` - the table that routes an approved withdrawal request to a specific payment method (funding instrument). When a back-office agent processes a customer's cashout, they specify which funding method (credit card, wire, e-wallet, etc.) should receive the funds. This SP validates eligibility and creates the routing record.

This procedure handles two distinct cashout scenarios via `@CashoutTypeID`:
- **CashoutTypeID=1 (Standard)**: Direct withdrawal - funds sent to a funding method with no deposit tie-back.
- **CashoutTypeID=2 (Refund)**: Refund back to the original deposit source - requires `@DepositID` and `@RefundAmountInDepositCurrency` and validates the deposit hasn't already been fully refunded.

A critical data transformation: `@Amount` is received in **cents** (integer units) and stored in `Billing.WithdrawToFunding` as **dollars** (Money type) via the `/100` division. The DDL comment says "in dollars" but the division pattern `CAST(@Amount AS MONEY) / 100` confirms the input is cents.

This SP is called by the back-office cashout processing system after a withdrawal has been approved (`Billing.Withdraw.Approved=1`) and is in a processable status (CashoutStatusID 2=Processing or 5=WaitingForWire).

---

## 2. Business Logic

### 2.1 FundingType Special Case - Empty WithdrawData for FundingType=3 + Refund

**What**: Auto-generates a minimal XML WithdrawData for specific funding type + cashout type combinations.

**Columns/Parameters Involved**: `@FundingID`, `@CashoutTypeID`, `@WithdrawData`

**Rules**:
- Read `FundingTypeID` from `Billing.Funding WHERE FundingID = @FundingID`
- If `FundingTypeID=3` AND `@CashoutTypeID=2` (refund): override any provided @WithdrawData with empty XML `<Withdraw xmlns:xsd="..." xmlns:xsi="..." />`
- This prevents FundingType=3 refund cashouts from carrying forward the original funding data in an incompatible format

### 2.2 DepotID Resolution from DepositID

**What**: Looks up the banking depot that processed the original deposit, for routing the refund back to the same institution.

**Columns/Parameters Involved**: `@DepositID`, `@DepotID`

**Rules**:
- If `@DepositID > 0 AND @DepositID IS NOT NULL`: SET @DepotID = (SELECT DepotID FROM Billing.Deposit WHERE DepositID = @DepositID)
- This overrides the caller-provided @DepotID with the actual depot from the deposit record
- Ensures refunds go through the same banking channel that received the original deposit

### 2.3 Withdrawal Status Validation

**What**: Ensures the withdrawal is both approved and in a processable state.

**Columns/Parameters Involved**: `@WithdrawID`

**Rules**:
- `NOT EXISTS (SELECT * FROM Billing.Withdraw WHERE WithdrawID=@WithdrawID AND CashoutStatusID IN (2, 5) AND Approved=1)`: RAISERROR(60025, 16, 1, 'Cashout Request is in an illegal status or is not approved'), RETURN 60025
- CashoutStatusID=2: Processing (ready to be routed)
- CashoutStatusID=5: WaitingForWire (wire transfer pending)
- Both Approved=1 AND processable status must be true simultaneously

### 2.4 Refund Deposit Validation (CashoutTypeID=2)

**What**: For refund cashouts, validates the source deposit exists and has sufficient unrefunded balance.

**Columns/Parameters Involved**: `@CashoutTypeID`, `@DepositID`, `@RefundAmountInDepositCurrency`

**Rules**:
- Only runs when `@CashoutTypeID=2`
- If both @DepositID and @RefundAmountInDepositCurrency are provided:
  1. Validates the DepositID exists in Billing.Deposit - RAISERROR 60025 if not
  2. Checks for over-refund: `Deposit.Amount - SUM(existing refunds WHERE CashoutStatusID != 4) < @RefundAmountInDepositCurrency` -> RAISERROR 60025 'This Deposit has already been refunded to this Cashout Request'
  3. Existing refunds are counted excluding CashoutStatusID=4 (Canceled) rows
- If either @DepositID or @RefundAmountInDepositCurrency is NULL (but type=2): RAISERROR 60025 'Cannot refund from deposit without DepositID and Refund Amount In Deposit Currency'

**Amount unit transformation**: `CAST(@Amount AS MONEY) / 100` converts cents (input) to dollars (stored).

**Diagram**:
```
@CashoutTypeID
    |
    +--> 1 (Standard): no deposit validation needed
    |
    +--> 2 (Refund):
              |
              +--> @DepositID + @RefundAmount both provided?
              |         YES:
              |             DepositID exists? NO -> RAISERROR
              |             Deposit balance remaining >= @RefundAmount? NO -> RAISERROR
              |
              +--> Either NULL? YES -> RAISERROR 'Cannot refund without both'
```

### 2.5 Transaction: Insert + Audit

**What**: Atomically creates the routing record and its audit entry.

**Rules**:
- INSERT INTO Billing.WithdrawToFunding with all parameters, storing Amount as CAST(@Amount AS MONEY) / 100
- @ID = SCOPE_IDENTITY() (returned to caller as OUTPUT parameter)
- INSERT INTO History.WithdrawToFundingAction:
  - CashoutActionStatusID=1 (New)
  - MatchStatusID=0
  - Remark=NULL
  - BW2F_ID=@ID (links audit to the new routing row)
- COMMIT; RETURN 0 on success

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | int | NO | - | CODE-BACKED | PK of the withdrawal request being processed. Must exist in Billing.Withdraw with Approved=1 AND CashoutStatusID IN (2,5). Written to Billing.WithdrawToFunding.WithdrawID. |
| 2 | @FundingID | int | NO | - | CODE-BACKED | PK of the funding method that will receive the cashout funds. Written to Billing.WithdrawToFunding.FundingID. Used to look up FundingTypeID for the special CashoutTypeID=2+FundingType=3 XML override. |
| 3 | @ProcessCurrencyID | int | NO | - | CODE-BACKED | Currency in which the cashout is being processed. Written to Billing.WithdrawToFunding.ProcessCurrencyID. Determines the currency unit for @Amount and exchange rate calculations. |
| 4 | @ManagerID | int | NO | - | CODE-BACKED | Manager submitting this routing entry. Written to Billing.WithdrawToFunding.ManagerID and History.WithdrawToFundingAction.ManagerID. Identifies who routed the cashout to this funding method. |
| 5 | @Amount | int | NO | - | CODE-BACKED | Cashout amount in CENTS (despite the DDL comment saying "in dollars"). Stored in Billing.WithdrawToFunding.Amount as CAST(@Amount AS MONEY) / 100 (i.e., stored as dollars). Example: @Amount=5000 -> stored as 50.00. |
| 6 | @ID | int OUTPUT | NO | - | CODE-BACKED | OUTPUT: receives SCOPE_IDENTITY() of the newly inserted Billing.WithdrawToFunding row. Also written as BW2F_ID in the History audit entry. Returned to caller to reference the new routing record. |
| 7 | @CashoutTypeID | tinyint | YES | 1 | CODE-BACKED | Type of cashout: 1=Standard direct withdrawal, 2=Refund to original deposit source. Defaults to 1. Controls whether deposit validation runs and whether FundingType=3 XML override applies. Must exist in Dictionary.CashoutType. |
| 8 | @DepositID | int | YES | NULL | CODE-BACKED | For refund cashouts (@CashoutTypeID=2): the original deposit being refunded. Used to look up @DepotID (overrides caller-provided @DepotID). Also validated for existence and remaining refundable balance. NULL for standard cashouts. |
| 9 | @RefundAmountInDepositCurrency | money | YES | NULL | CODE-BACKED | For refund cashouts: the amount to refund expressed in the deposit's original currency (not necessarily USD). Used in the over-refund balance check: remaining = Deposit.Amount - SUM(previous non-canceled refunds). Required when @CashoutTypeID=2 and @DepositID is provided. |
| 10 | @ExchangeRate | dtPrice | YES | 1.0 | CODE-BACKED | Exchange rate between the withdrawal currency and the processing currency. Defaults to 1.0 (same currency). Written to Billing.WithdrawToFunding.ExchangeRate. |
| 11 | @BaseExchangeRate | dtPrice | YES | NULL | CODE-BACKED | Base exchange rate before any markup or spread. Written to Billing.WithdrawToFunding.BaseExchangeRate. NULL when not applicable (same-currency transactions). |
| 12 | @ExchangeFee | int | YES | NULL | CODE-BACKED | Currency exchange fee in cents. Written to Billing.WithdrawToFunding.ExchangeFee. NULL when no conversion fee applies. |
| 13 | @CashoutModeID | tinyint | YES | NULL | CODE-BACKED | Mode identifier for the cashout processing channel. Written to Billing.WithdrawToFunding.CashoutModeID. NULL when default processing mode applies. |
| 14 | @CashoutStatusID | int | YES | 1 | CODE-BACKED | Initial status for the new Billing.WithdrawToFunding row. Defaults to 1 (New/Pending). Can be overridden by caller to create a row in a specific status. |
| 15 | @AdditionalInformation | nvarchar(250) | YES | NULL | CODE-BACKED | Free-text additional information for the cashout routing. Written to both Billing.WithdrawToFunding and History.WithdrawToFundingAction. |
| 16 | @DepotID | int | NO | - | CODE-BACKED | ID of the banking depot routing institution. Overridden internally if @DepositID resolves to a Billing.Deposit row with a DepotID. Written to Billing.WithdrawToFunding.DepotID. |
| 17 | @WithdrawData | xml | YES | NULL | CODE-BACKED | Payment provider-specific XML payload. Auto-set to empty XML when FundingTypeID=3 AND @CashoutTypeID=2. Written to both Billing.WithdrawToFunding and History.WithdrawToFundingAction. |
| 18 | @ExchangeFeeInUSD | money | YES | NULL | CODE-BACKED | Exchange fee expressed in USD. Written to Billing.WithdrawToFunding.ExchangeFeeInUSD. Provides the USD equivalent of @ExchangeFee for cross-currency fee reporting. |
| 19 | @ExchangeFeeInPercentage | decimal(10,2) | YES | NULL | CODE-BACKED | Exchange fee as a percentage of the transaction amount. Written to Billing.WithdrawToFunding.ExchangeFeeInPercentage. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID | Billing.Funding | SELECT (FundingTypeID lookup) | Reads FundingTypeID to check FundingType=3+refund special case |
| @DepositID | Billing.Deposit | SELECT (DepotID resolution + existence + balance check) | Resolves DepotID, validates DepositID exists, checks remaining refundable amount |
| @WithdrawID | Billing.Withdraw | EXISTS (status validation) | Validates Approved=1 AND CashoutStatusID IN (2,5) |
| @CashoutTypeID | Dictionary.CashoutType | EXISTS (type validation) | Validates @CashoutTypeID is a known cashout type |
| @DepositID | Billing.WithdrawToFunding | SELECT SUM (over-refund check) | Sums existing non-canceled refunds for the same DepositID |
| All params | Billing.WithdrawToFunding | INSERT (writer) | Creates the cashout-to-funding routing record |
| @ID + key columns | History.WithdrawToFundingAction | INSERT (audit) | Creates the initial audit entry with CashoutActionStatusID=1 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back-office application | API call | Consumer | Called by the BO cashout processing interface when routing an approved withdrawal to a payment method |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.WithdrawToFundingAdd (procedure)
+-- Billing.Funding (table) [SELECT: FundingTypeID for special-case detection]
+-- Billing.Deposit (table) [SELECT: DepotID resolution + balance check for refunds]
+-- Billing.Withdraw (table) [EXISTS: status/approval validation]
+-- Dictionary.CashoutType (table) [EXISTS: CashoutTypeID validation]
+-- Billing.WithdrawToFunding (table) [SELECT SUM: over-refund check; INSERT: routing record]
+-- History.WithdrawToFundingAction (table) [INSERT: audit trail]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | SELECT FundingTypeID to detect FundingType=3+refund XML override case |
| Billing.Deposit | Table | SELECT DepotID for routing; validates DepositID existence; computes refundable balance |
| Billing.Withdraw | Table | EXISTS: validates withdrawal is approved and in processable status |
| Dictionary.CashoutType | Table | EXISTS: validates @CashoutTypeID is a known/supported type |
| Billing.WithdrawToFunding | Table | SELECT SUM: over-refund balance check; INSERT: new routing record |
| History.WithdrawToFundingAction | Table | INSERT: new audit record with CashoutActionStatusID=1 (New) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Back-office cashout processing | External | Primary consumer - called to route an approved withdrawal to a payment method |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `SET NOCOUNT ON` - suppresses row-count messages
- All validation runs OUTSIDE the transaction - no rollback overhead for rejected requests
- Transaction wraps only the two INSERT statements + SCOPE_IDENTITY() read
- Amount unit conversion: `CAST(@Amount AS MONEY) / 100` - @Amount is in cents, stored as dollars
- `@@TRANCOUNT=1` -> ROLLBACK; `@@TRANCOUNT>1` -> COMMIT in CATCH (nested SP safety)
- THROW re-raises any SQL exceptions from within the transaction
- RETURN 0 on success (always, no error codes returned on happy path)
- Error code 60025 used for all validation failures (no distinction between error types at the error code level)

---

## 8. Sample Queries

### 8.1 Check if a withdrawal is eligible before calling (CashoutStatusID IN 2 or 5 + Approved)

```sql
SELECT
    w.WithdrawID, w.Amount, w.Approved, w.CashoutStatusID,
    cs.Name AS CashoutStatus
FROM Billing.Withdraw w WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON cs.CashoutStatusID = w.CashoutStatusID
WHERE w.WithdrawID = 1734869
  AND w.CashoutStatusID IN (2, 5)
  AND w.Approved = 1;
```

### 8.2 View routing records for a withdrawal

```sql
SELECT
    wtf.WithdrawToFundingID,
    wtf.WithdrawID,
    wtf.FundingID,
    wtf.Amount,
    wtf.CashoutStatusID,
    wtf.CashoutTypeID,
    wtf.DepositID,
    wtf.ExchangeRate,
    wtf.ModificationDate
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
WHERE wtf.WithdrawID = 1734869
ORDER BY wtf.ModificationDate;
```

### 8.3 Check refundable balance remaining for a deposit before refund cashout

```sql
DECLARE @DepositID INT = 123456;

SELECT
    d.DepositID,
    d.Amount AS OriginalAmount,
    ISNULL(SUM(CASE WHEN wtf.CashoutStatusID != 4 THEN wtf.RefundAmountInDepositCurrency ELSE 0 END), 0) AS AlreadyRefunded,
    d.Amount - ISNULL(SUM(CASE WHEN wtf.CashoutStatusID != 4 THEN wtf.RefundAmountInDepositCurrency ELSE 0 END), 0) AS RemainingRefundable
FROM Billing.Deposit d WITH (NOLOCK)
LEFT JOIN Billing.WithdrawToFunding wtf WITH (NOLOCK) ON wtf.DepositID = d.DepositID AND wtf.CashoutStatusID NOT IN (4, 7)
WHERE d.DepositID = @DepositID
GROUP BY d.DepositID, d.Amount;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Code Analysis, Dependency Inheritance, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callees with existing docs | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.WithdrawToFundingAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.WithdrawToFundingAdd.sql*
