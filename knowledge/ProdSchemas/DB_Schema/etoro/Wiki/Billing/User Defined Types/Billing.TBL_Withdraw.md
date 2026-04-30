# Billing.TBL_Withdraw

> Core table-valued parameter type representing a withdrawal (cashout) record, used by 25+ stored procedures as the staging type for all INSERT and UPDATE operations on `Billing.Withdraw` via `Billing.UpsertWithdraw`.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | User Defined Type |
| **Key Identifier** | WithdrawID (primary identifier within the TVP) |
| **Partition** | N/A |
| **Indexes** | N/A - inline table type, no persistent indexes |

---

## 1. Business Meaning

`Billing.TBL_Withdraw` is the primary table-valued parameter (TVP) type for the `Billing.Withdraw` table. It mirrors the column structure of `Billing.Withdraw` and serves as the intermediary staging type that stored procedures populate before calling `Billing.UpsertWithdraw` to perform the actual INSERT or UPDATE. Every column in this type corresponds directly to a column in `Billing.Withdraw`.

This type exists as the central element of a DBA-648 refactoring (Shay Oren, September 2021) that removed all direct `INSERT INTO Billing.Withdraw` and `UPDATE Billing.Withdraw` statements from individual procedures and replaced them with a single `Billing.UpsertWithdraw` call. This centralized history logging and validation, and reduced duplication across 25+ procedures.

Data flows from many call sites: procedures such as `WithdrawRequestAdd`, `CashoutRequestUpdate`, `WithdrawToFundingProcess`, `UpsertWithdraw`, and others declare a local `@Info [Billing].[TBL_Withdraw]`, populate the columns they need to set (leaving others NULL/default), and pass the TVP to `Billing.UpsertWithdraw`, which performs an UPSERT on `Billing.Withdraw` and logs to `History.WithdrawAction`.

---

## 2. Business Logic

### 2.1 Partial-Update Pattern

**What**: Procedures typically populate only the columns they need to change, leaving other columns NULL. The UpsertWithdraw procedure uses ISNULL/COALESCE logic to apply only the non-NULL values, preserving existing values for unspecified columns.

**Columns/Parameters Involved**: All columns (any subset may be populated per call)

**Rules**:
- A procedure inserting a new withdrawal populates all mandatory fields (CID, CurrencyID, FundingTypeID, Amount, CashoutStatusID, RequestDate, etc.)
- A procedure updating only the status populates only WithdrawID + CashoutStatusID + ModificationDate
- A procedure updating only the manager populates only WithdrawID + ManagerID
- NULL columns in the TVP mean "do not change this column" in the underlying Withdraw record

**Diagram**:
```
WithdrawRequestAdd:
  Populates: CurrencyID, FundingID, FundingTypeID, CID, ManagerID, CashoutStatusID,
             CashoutReasonID, RequestDate, Amount, Fee, IPAddress, ModificationDate,
             Remark, Comment, SessionID, ClientWithdrawReasonID, ClientWithdrawReasonComment,
             SuggestedBonusDeductionAmount, Commission, Approved, ClientPersonalID
  -> EXEC Billing.UpsertWithdraw @Info -> INSERT INTO Billing.Withdraw

CashoutRequestUpdate:
  Populates: WithdrawID=@CashoutID, CashoutStatusID=2, Remark, ModificationDate, SessionID,
             WithrawActionManagerID=0, Comment=@Remark
  -> EXEC Billing.UpsertWithdraw @Info -> UPDATE Billing.Withdraw SET CashoutStatusID=2 WHERE WithdrawID=@CashoutID
```

### 2.2 Fee and Bonus Deduction Tracking

**What**: The TVP carries both the net withdrawal amount and the associated deductions (cashout fee and bonus deduction).

**Columns/Parameters Involved**: `Amount`, `Fee`, `Commission`, `SuggestedBonusDeductionAmount`, `ActualBonusDeductionAmount`

**Rules**:
- `Amount` is the net amount sent to the customer after fees (in account currency)
- `Fee` is the cashout processing fee charged by eToro (deducted from Amount before transfer)
- `Commission` is a legacy column (not used per code comment in WithdrawToFundingProcess: "Commission In Billing.Withdraw Not used. Alex")
- `SuggestedBonusDeductionAmount` is calculated by `WithdrawalService_EstimateBonusDeduction` before the withdraw is created
- `ActualBonusDeductionAmount` is the bonus actually deducted at the time of processing

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | int | YES | NULL | CODE-BACKED | Primary key of the withdraw record in `Billing.Withdraw`. NULL when creating a new withdrawal (auto-assigned by IDENTITY); non-NULL when updating an existing record. Returned as OUTPUT by UpsertWithdraw after INSERT. |
| 2 | CurrencyID | int | YES | NULL | CODE-BACKED | Currency of the withdrawal. References `Dictionary.Currency`. Set from the customer's account currency for the withdrawal. |
| 3 | FundingTypeID | int | YES | NULL | CODE-BACKED | Payment method for this withdrawal. See [Funding Type](_glossary.md#funding-type) (e.g., 1=CreditCard, 2=WireTransfer, 3=PayPal). |
| 4 | CID | int | YES | NULL | CODE-BACKED | Customer ID submitting the withdrawal. References `Customer.Customer.CID`. |
| 5 | ManagerID | int | YES | NULL | CODE-BACKED | BackOffice manager handling the withdrawal. NULL for customer-self-initiated withdrawals. References `BackOffice.Manager`. |
| 6 | CashoutStatusID | int | YES | NULL | CODE-BACKED | Lifecycle state of the withdrawal. See [Cashout Status](_glossary.md#cashout-status) (1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Partially Processed, 7=Rejected). |
| 7 | RequestDate | datetime | YES | NULL | CODE-BACKED | Timestamp when the customer submitted the withdrawal request. Set to GETUTCDATE() at creation. |
| 8 | Amount | money | YES | NULL | CODE-BACKED | Net withdrawal amount in account currency after fee deduction. In WithdrawRequestAdd: `CAST(@Amount - @CashoutFee AS Money) / 100.0` (amount is passed in cents). |
| 9 | Commission | money | YES | NULL | CODE-BACKED | Legacy fee field - not used per code comments ("Commission In Billing.Withdraw Not used. Alex"). Set to 0 on creation. Preserved for backward compatibility. |
| 10 | Approved | bit | YES | NULL | CODE-BACKED | Whether the withdrawal has been approved for processing. Set to 0 on creation. Set to 1 by the approval workflow before payment processing begins. WithdrawToFundingProcess verifies `Approved=1` before proceeding. |
| 11 | IPAddress | numeric(18,0) | YES | NULL | CODE-BACKED | Customer's IP address at the time of the withdrawal request, stored as a numeric value (converted from dotted notation). Used for fraud detection. |
| 12 | ModificationDate | datetime | YES | NULL | CODE-BACKED | Timestamp of the last modification to this record. Updated on every status change. |
| 13 | Remark | nvarchar(500) | YES | NULL | CODE-BACKED | Internal note or description for BackOffice use. May contain the reason for status changes. Collation: Latin1_General_BIN. |
| 14 | Comment | nvarchar(255) | YES | NULL | CODE-BACKED | Additional comment, typically the original remark passed to the procedure. In CashoutRequestUpdate, set to @Remark. Collation: Latin1_General_BIN. |
| 15 | Fee | money | YES | NULL | CODE-BACKED | Cashout processing fee charged by eToro. Calculated from `Trade.CashoutRange` based on the CashoutFeeGroupID and amount. Stored as negative value after calculation (`Set @CashoutFee = -@CashoutFee`). |
| 16 | FundingID | int | YES | NULL | CODE-BACKED | ID of the funding record (payment method) used for this withdrawal. References `Billing.Funding.FundingID`. |
| 17 | RequestorComments | nvarchar(255) | YES | NULL | NAME-INFERRED | Comments from the requestor (customer or manager) at the time of the withdrawal request. Collation: Latin1_General_BIN. |
| 18 | SessionID | bigint | YES | NULL | CODE-BACKED | Session identifier linking the withdrawal to a specific user session. Used for audit trail and security correlation. Set from @SessionID parameter passed by the caller. |
| 19 | CashoutReasonID | int | YES | NULL | CODE-BACKED | Reason code for the withdrawal. Defaults to 16 (Requested by User) if not specified. Special values: 12=Foreclose account, 14=PI Payment, 15=Affiliate Payment, 16=Requested by User. Referenced in WithdrawToFundingProcess for notification logic. |
| 20 | SuggestedBonusDeductionAmount | money | YES | NULL | CODE-BACKED | Estimated bonus amount to be deducted from the withdrawal, calculated by `Billing.WithdrawalService_EstimateBonusDeduction` before the record is created. Stored for comparison against the actual deduction. |
| 21 | ActualBonusDeductionAmount | money | YES | NULL | NAME-INFERRED | The bonus amount actually deducted at the time the withdrawal was processed. May differ from the suggested amount if conditions changed between request and processing. |
| 22 | ClientWithdrawReasonComment | nvarchar(510) | YES | NULL | CODE-BACKED | Free-text reason comment provided by the customer when submitting the withdrawal request. Collation: Latin1_General_BIN. |
| 23 | AccountCurrencyID | int | YES | NULL | NAME-INFERRED | Currency of the customer's trading account at the time of withdrawal. May differ from CurrencyID if the withdrawal is processed in a different currency. |
| 24 | ClientWithdrawReasonID | int | YES | NULL | CODE-BACKED | Structured reason code selected by the customer from a predefined list when requesting the withdrawal. References a client-facing reason lookup. |
| 25 | ClientWithdrawCommentID | int | YES | NULL | NAME-INFERRED | ID reference to a predefined comment template selected by the customer, supplementing the free-text ClientWithdrawReasonComment. |
| 26 | ClientPersonalID | varchar(255) | YES | NULL | CODE-BACKED | Customer's personal identification (national ID, passport number) provided at the time of withdrawal for KYC/AML compliance. Collation: Latin1_General_BIN. Per code history (Yoav 12/09/2019): "Remove ClientPersonalID from Billing.Withdraw" - this column was later removed from the actual Withdraw table but retained in the TVP for backward compatibility. |
| 27 | WithrawActionManagerID | int | YES | NULL | CODE-BACKED | Manager ID specifically associated with the withdraw action/status transition, separate from the general ManagerID. Note: column name has typo "Withraw" (missing 'd'). Set to 0 in CashoutRequestUpdate for system-initiated transitions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | Lookup | Withdrawal currency |
| FundingTypeID | Dictionary.FundingType | Lookup | Payment method used for the withdrawal |
| CID | Customer.Customer | Implicit | Customer making the withdrawal |
| ManagerID | BackOffice.Manager | Implicit | Manager handling the withdrawal |
| CashoutStatusID | Dictionary.CashoutStatus | Lookup | Withdrawal lifecycle state |
| FundingID | Billing.Funding | Implicit | Payment instrument record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.UpsertWithdraw | Parameter | TVP Parameter | Primary consumer - performs INSERT/UPDATE on Billing.Withdraw |
| Billing.WithdrawRequestAdd | @Info (local) | TVP (local) | Stages new withdraw record before calling UpsertWithdraw |
| Billing.CashoutRequestUpdate | @Info (local) | TVP (local) | Stages status transition to InProcess (2) |
| Billing.WithdrawToFundingProcess | @InfoWithdraw (local) | TVP (local) | Updates withdraw status during payment processing |
| Billing.WithdrawalService_WithdrawRequestAdd | (local) | TVP (local) | Alternative withdrawal creation path |
| 20+ other procedures | (local) | TVP (local) | Various status and data updates to Billing.Withdraw |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.UpsertWithdraw | Stored Procedure | Primary consumer - receives TVP and upserts Billing.Withdraw |
| Billing.WithdrawRequestAdd | Stored Procedure | Creates new withdrawal records |
| Billing.CashoutRequestUpdate | Stored Procedure | Updates cashout status to InProcess |
| Billing.WithdrawToFundingProcess | Stored Procedure | Updates withdraw during WTF processing |
| Billing.WithdrawToFundingProcess_v2 | Stored Procedure | V2 processing path |
| Billing.WithdrawalService_WithdrawRequestAdd | Stored Procedure | Alternative withdrawal creation |
| Billing.UpsertWithdraw | Stored Procedure | Receives and processes the TVP |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View recent withdrawal requests

```sql
SELECT TOP 20
    w.WithdrawID,
    w.CID,
    cs.Name AS Status,
    ft.Name AS FundingType,
    w.Amount,
    w.Fee,
    w.RequestDate,
    w.ModificationDate
FROM Billing.Withdraw w WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON cs.CashoutStatusID = w.CashoutStatusID
JOIN Dictionary.FundingType ft WITH (NOLOCK) ON ft.FundingTypeID = w.FundingTypeID
ORDER BY w.RequestDate DESC
```

### 8.2 Track withdrawal amount vs fee breakdown

```sql
SELECT TOP 20
    WithdrawID,
    CID,
    Amount AS NetAmount,
    Fee AS CashoutFee,
    Amount + ISNULL(Fee, 0) AS GrossAmount,
    ISNULL(SuggestedBonusDeductionAmount, 0) AS BonusDeductionSuggested,
    ISNULL(ActualBonusDeductionAmount, 0) AS BonusDeductionActual,
    CashoutStatusID,
    RequestDate
FROM Billing.Withdraw WITH (NOLOCK)
WHERE CashoutStatusID IN (3, 5)  -- Processed or Partially Processed
ORDER BY RequestDate DESC
```

### 8.3 View withdrawal reasons and comments

```sql
SELECT TOP 20
    w.WithdrawID,
    w.CID,
    w.CashoutReasonID,
    w.ClientWithdrawReasonID,
    w.ClientWithdrawReasonComment,
    w.Remark,
    cs.Name AS Status
FROM Billing.Withdraw w WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON cs.CashoutStatusID = w.CashoutStatusID
WHERE w.RequestDate > DATEADD(DAY, -7, GETUTCDATE())
ORDER BY w.RequestDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.6/10 (Elements: 8.5/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.TBL_Withdraw | Type: User Defined Type | Source: etoro/etoro/Billing/User Defined Types/Billing.TBL_Withdraw.sql*
