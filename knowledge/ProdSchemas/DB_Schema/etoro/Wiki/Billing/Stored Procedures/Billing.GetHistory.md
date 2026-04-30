# Billing.GetHistory

> Returns a paginated, date-filtered transaction history for a customer, unifying deposits, withdrawals, and bonus/compensation credits into a single ranked result set.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer filter; @From/@To - pagination window |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetHistory` is the unified financial transaction history query for the customer-facing account statement. Given a customer ID and date range, it retrieves a merged and paginated view of three transaction types: deposits, withdrawals, and bonus/compensation credits. The result is ordered chronologically (newest first) and sliced to the requested page window via row number.

This procedure exists to power the "History" tab in the eToro customer portal. Without it, the UI would need to make three separate queries and merge/sort/paginate the results in application code. The single-procedure design places that complexity in the database layer.

Data flows outward only. The procedure was created in 2016 (comment: "Geri Reshef, 01/09/2016, 40628, (PCI) integrate GetHistory with CryptoService"), indicating it was extended at that time for PCI-compliant handling of card data and crypto service integration. No SQL-layer callers were identified - it is consumed directly by the customer portal application.

---

## 2. Business Logic

### 2.1 Three-Branch UNION ALL - Unified History

**What**: The MyCTE uses UNION ALL of three independently filtered SELECT statements to combine deposits, withdrawals, and credits into one columnized result. Most columns are NULL in branches where they don't apply.

**Columns/Parameters Involved**: `Operation`, `DepositID`, `WithdrawID`, `CreditID`, `CreditTypeID`, `BonusTypeID`

**Rules**:
- **Branch 1 - Deposits**: `Operation='Deposit'`. Source: `Billing.Deposit` + `Billing.Funding` + `Dictionary.FundingType`. Filter: `PaymentDate BETWEEN @DateFrom AND @DateTo AND CID=@CID`. WithdrawID, FundingTypeID, Approved, CashoutStatusID, CreditTypeID, etc. are all NULL.
- **Branch 2 - Withdrawals**: `Operation='Withdraw'`. Source: `Billing.Withdraw` + `BackOffice.WithdrawApproval` + `History.Credit` + `Billing.WithdrawToFunding`. Filter: `CID=@CID AND RequestDate BETWEEN @DateFrom AND @DateTo`. DepositID, CurrencyID (in Position 2), Amount, etc. are NULL; WithdrawID, Amount2, CashoutFee, FundingXML are populated.
- **Branch 3 - Credits**: `Operation='Credit'`. Source: `History.Credit` + `BackOffice.BonusType` + `BackOffice.Campaign` + `BackOffice.CompensationReason`. Filter: `CID=@CID AND CreditTypeID IN (6,7) AND Occurred BETWEEN @DateFrom AND @DateTo`. Only Bonus (7) and Compensation (6) credit types are included - not all History.Credit rows.
- NULL-heavy design: each branch fills only its relevant columns, leaving all others NULL; consumers must check the `Operation` column first

**Diagram**:
```
MyCTE:
  Branch 1: Deposits         (Operation='Deposit')
  UNION ALL
  Branch 2: Withdrawals      (Operation='Withdraw')
  UNION ALL
  Branch 3: Credits (6,7)    (Operation='Credit')
       |
  OrderdData: ROW_NUMBER OVER (ORDER BY COALESCE(Occurred, RequestDate, PaymentDate) DESC)
       |
  Final SELECT: WHERE Position >= @From AND Position <= @To
```

### 2.2 Amount Unit Conversion - Cents

**What**: Both deposit and withdrawal amounts are multiplied by 100 and cast to INT before being returned.

**Columns/Parameters Involved**: `Amount` (deposit branch), `Amount2` (withdraw branch)

**Rules**:
- `CAST(Amount * 100 AS integer)` in deposit branch - converts from dollars/currency units to integer cents
- `CAST(BWDR.Amount * 100 AS integer)` in withdraw branch (Amount2 column)
- The Payment column from History.Credit branch is NOT multiplied - credits return the raw payment value
- CashoutFee uses `ISNULL(ABS(HICR.Payment), 0) * 100` - also converted to cents
- Consumers must divide by 100 to get human-readable currency values

### 2.3 Pagination via @From/@To

**What**: The @From and @To parameters implement server-side pagination. @To is also applied as a TOP hint in each UNION branch.

**Columns/Parameters Involved**: `@From`, `@To`, `Position` output column

**Rules**:
- `TOP(@To)` is applied to each UNION branch independently - this limits each branch to @To rows before the pagination window is applied
- `ROW_NUMBER() OVER (ORDER BY COALESCE(Occurred, RequestDate, PaymentDate) DESC)` assigns global row numbers across all branches
- The final WHERE clause: `Position >= @From AND Position <= @To` slices to the requested page
- Result: page size = @To - @From + 1 rows; first page typically: @From=1, @To=25

### 2.4 Withdrawal FundingXML - Payment Method Detail

**What**: For withdrawals, the `FundingXML` column is an XML-over-Base64-encoded block containing the details of each funding instrument leg used for the withdrawal, including payment method, account identifier, amount, and currency.

**Columns/Parameters Involved**: `FundingXML`, `CashoutStatusID=3`

**Rules**:
- Built by a correlated subquery joining `Billing.WithdrawToFunding`, `Billing.Funding`, `Dictionary.FundingType`, `Dictionary.Currency`, `Dictionary.CardType`, `Billing.Deposit`
- Only `WithdrawToFunding` rows with `CashoutStatusID=3` (Processed) are included
- Payment method display name logic per FundingTypeID:
  - FundingTypeID=1 (CreditCard): shows card type name (from Dictionary.CardType + XML)
  - FundingTypeID=2 (Wire): shows payee name from WithdrawData XML
  - FundingTypeID=8 (MoneyBookers): shows email from FundingData XML
  - FundingTypeID=3 (PayPal): shows email or payer name depending on linked deposit
  - FundingTypeID=6 (Wire-variant): shows account ID or email
  - FundingTypeID=7,10,11,14: shows "Account {AccountID}"
  - FundingTypeID=19: shows "Internal Payment"
- Output: `FOR XML RAW('WithdrawDetail'), binary BASE64, ELEMENTS, TYPE, ROOT('WithdrawDetailList')`

### 2.5 Credit Type Filter (6 and 7 Only)

**What**: Only two credit types from History.Credit appear in the history: Compensation (CreditTypeID=6) and Bonus (CreditTypeID=7). All other credit types (fees, position PnL, etc.) are excluded.

**Columns/Parameters Involved**: `CreditTypeID`, `BonusTypeID`, `BonusCampaignCode`, `BonusTypeName`, `CompensationReasonName`

**Rules**:
- CreditTypeID=6 (Compensation): joins BackOffice.CompensationReason for the reason name
- CreditTypeID=7 (Bonus): joins BackOffice.Campaign (for campaign code) and BackOffice.BonusType (for display name)
- Other credit types (fees, trade PnL, etc.) are intentionally excluded from customer-visible history

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Applied as WHERE filter in all three UNION branches (Billing.Deposit.CID, Billing.Withdraw.CID, History.Credit.CID). |
| 2 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Start of date range (inclusive). Applied to PaymentDate (deposits), RequestDate (withdrawals), and Occurred (credits). |
| 3 | @DateTo | DATETIME | NO | - | CODE-BACKED | End of date range (inclusive). Applied to PaymentDate, RequestDate, and Occurred in respective branches. |
| 4 | @From | INT | NO | - | CODE-BACKED | Pagination start: the first row number to include in the result. Rows with Position < @From are excluded. Typically 1 for the first page. |
| 5 | @To | INT | NO | - | CODE-BACKED | Pagination end: the last row number to include. Also used as TOP(@To) in each UNION branch to pre-limit rows before global pagination. Page size = @To - @From + 1. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 6 | Operation | varchar | NO | - | CODE-BACKED | Transaction type: 'Deposit', 'Withdraw', or 'Credit'. Determines which other columns are populated - most columns are NULL for non-matching operation types. |
| 7 | DepositID | int | YES | NULL | CODE-BACKED | Deposit transaction ID. From Billing.Deposit.DepositID. NULL for Withdraw and Credit rows. |
| 8 | CurrencyID | int | YES | NULL | CODE-BACKED | Currency ID from Dictionary.Currency. Populated from Billing.Deposit.CurrencyID (deposits) or Billing.Withdraw.CurrencyID (withdrawals). NULL for Credit rows. |
| 9 | CID | int | NO | - | CODE-BACKED | Customer ID - echoed from the filter. Populated in all three branches. |
| 10 | PaymentStatusID | int | YES | NULL | CODE-BACKED | Deposit payment status (from Billing.Deposit.PaymentStatusID). NULL for Withdraw and Credit rows. |
| 11 | FundingID | int | YES | NULL | CODE-BACKED | Funding instrument ID. From Billing.Deposit.FundingID (deposits only). NULL for Withdraw and Credit rows. |
| 12 | Amount | int | YES | NULL | CODE-BACKED | Deposit amount in CENTS (CAST(Billing.Deposit.Amount * 100 AS integer)). NULL for Withdraw and Credit rows. Divide by 100 to get currency amount. |
| 13 | ExchangeRate | decimal/float | YES | NULL | CODE-BACKED | Exchange rate at time of deposit (Billing.Deposit.ExchangeRate). NULL for non-deposit rows. |
| 14 | PaymentDate | datetime | YES | NULL | CODE-BACKED | Date the deposit was processed (Billing.Deposit.PaymentDate). NULL for non-deposit rows. |
| 15 | TransactionID | varchar | YES | NULL | CODE-BACKED | External payment provider transaction reference (Billing.Deposit.TransactionID). NULL for non-deposit rows. |
| 16 | WithdrawID | int | YES | NULL | CODE-BACKED | Withdrawal request ID (Billing.Withdraw.WithdrawID). NULL for Deposit and Credit rows. |
| 17 | FundingTypeID | int | YES | NULL | CODE-BACKED | Payment method ID for withdrawals (Billing.Withdraw.FundingTypeID). NULL for Deposit and Credit rows. |
| 18 | Approved | bit | YES | NULL | CODE-BACKED | Whether the withdrawal was approved (Billing.Withdraw.Approved). NULL for Deposit and Credit rows. |
| 19 | CountWithdrawApproval | int | YES | NULL | CODE-BACKED | Count of pending approval requests for this withdrawal (subquery: COUNT(*) WHERE BackOffice.WithdrawApproval.Approved=0 for this WithdrawID). NULL for non-withdraw rows. |
| 20 | ManagerID | int | YES | NULL | CODE-BACKED | Manager who approved/processed the withdrawal (Billing.Withdraw.ManagerID). NULL for non-withdraw rows. |
| 21 | CashoutStatusID | int | YES | NULL | CODE-BACKED | Withdrawal lifecycle status (Billing.Withdraw.CashoutStatusID): 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled. NULL for non-withdraw rows. |
| 22 | RequestDate | datetime | YES | NULL | CODE-BACKED | Date the withdrawal was requested (Billing.Withdraw.RequestDate). NULL for non-withdraw rows. |
| 23 | Amount2 | int | YES | NULL | CODE-BACKED | Withdrawal amount in CENTS (CAST(Billing.Withdraw.Amount * 100 AS integer)). NULL for Deposit and Credit rows. Divide by 100 to get currency amount. |
| 24 | FundingXML | xml | YES | NULL | CODE-BACKED | Base64-encoded XML of withdrawal payment method details (FOR XML RAW('WithdrawDetail'), ROOT('WithdrawDetailList')). Only for Withdraw rows with CashoutStatusID=3 funding legs. NULL for all other rows. |
| 25 | IPAddress | varchar | YES | NULL | CODE-BACKED | Customer IP address at time of withdrawal request (Billing.Withdraw.IPAddress). NULL for non-withdraw rows. |
| 26 | Remark | nvarchar | YES | NULL | CODE-BACKED | Operator remark on the withdrawal (Billing.Withdraw.Remark). NULL for non-withdraw rows. |
| 27 | CashoutFee | int | YES | NULL | CODE-BACKED | Withdrawal fee in CENTS (ISNULL(ABS(History.Credit.Payment), 0) * 100, where CreditTypeID=15). NULL for non-withdraw rows. |
| 28 | CreditTypeID | int | YES | NULL | CODE-BACKED | Credit type (History.Credit.CreditTypeID): 6=Compensation, 7=Bonus. NULL for Deposit and Withdraw rows. |
| 29 | BonusTypeID | int | YES | NULL | CODE-BACKED | Bonus type ID (History.Credit.BonusTypeID). NULL for non-credit rows. |
| 30 | Payment | money | YES | NULL | CODE-BACKED | Credit amount in native currency units - NOT multiplied by 100 (History.Credit.Payment). NULL for Deposit and Withdraw rows. |
| 31 | Occurred | datetime | YES | NULL | CODE-BACKED | Date/time the credit occurred (History.Credit.Occurred). NULL for non-credit rows. |
| 32 | CreditID | int | YES | NULL | CODE-BACKED | Credit record ID (History.Credit.CreditID). NULL for non-credit rows. |
| 33 | Position | int | NO | - | CODE-BACKED | Global row number across all three branches, ordered by COALESCE(Occurred, RequestDate, PaymentDate) DESC. Used for pagination: WHERE Position >= @From AND Position <= @To. |
| 34 | FundingTypeName | varchar | YES | NULL | CODE-BACKED | Payment method name for deposit rows only (Dictionary.FundingType.Name). NULL for Withdraw and Credit rows. |
| 35 | BonusCampaignCode | varchar | YES | NULL | CODE-BACKED | Campaign code for CreditTypeID=7 bonus credits (BackOffice.Campaign.Code). NULL for non-credit rows or non-bonus credits. |
| 36 | BonusTypeName | nvarchar | YES | NULL | CODE-BACKED | Display name of the bonus type (BackOffice.BonusType.DisplayName). NULL for non-credit rows. |
| 37 | CompensationReasonName | nvarchar | YES | NULL | CODE-BACKED | Display name of the compensation reason for CreditTypeID=6 (BackOffice.CompensationReason.DisplayName). NULL for non-compensation rows. |
| 38 | CurrencyAbbr | varchar | YES | NULL | CODE-BACKED | Currency abbreviation from Dictionary.Currency joined on CurrencyID. Provides human-readable currency label (e.g., USD, EUR). |
| 39 | WithdrawApprovalDate | datetime | YES | NULL | CODE-BACKED | Date of the most recent approval action for this withdrawal (MAX(BackOffice.WithdrawApproval.Occurred)). NULL for non-withdraw rows. |
| 40 | WithdrawApprovalReasonID | int | YES | NULL | CODE-BACKED | Most recent non-7 WithdrawApprovalReasonID for this withdrawal; defaults to 7 if none found (subquery: SELECT TOP 1 WHERE WithdrawApprovalReasonID != 7, else 7). NULL for non-withdraw rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Deposit branch (FROM) | Billing.Deposit | Direct Read | Core deposit records for the customer |
| Deposit branch (LEFT JOIN) | Billing.Funding | Direct Read | Payment instrument linked to each deposit |
| Deposit branch (LEFT JOIN) | Dictionary.FundingType | Direct Read | Payment method name for deposits |
| Withdraw branch (FROM) | Billing.Withdraw | Direct Read | Withdrawal request records for the customer |
| Withdraw branch (subquery) | BackOffice.WithdrawApproval | Direct Read | Count of pending approvals and max approval date |
| Withdraw branch (LEFT JOIN) | History.Credit | Direct Read | Cashout fee credit (CreditTypeID=15) for the withdrawal |
| FundingXML subquery | Billing.WithdrawToFunding | Direct Read | Funding legs for each processed withdrawal |
| FundingXML subquery | Dictionary.CardType | Direct Read | Card type name for FundingTypeID=1 withdrawals |
| FundingXML subquery | Billing.Deposit | Direct Read | Linked deposit for FundingTypeID=3 PayPal payer name |
| Credit branch (FROM) | History.Credit | Direct Read | Bonus and compensation credit records |
| Credit branch (LEFT JOIN) | BackOffice.BonusType | Direct Read | Bonus type display name |
| Credit branch (LEFT JOIN) | BackOffice.Campaign | Direct Read | Campaign code for bonus credits |
| Credit branch (LEFT JOIN) | BackOffice.CompensationReason | Direct Read | Compensation reason display name |
| Final SELECT (LEFT JOIN) | Dictionary.Currency | Direct Read | Currency abbreviation for the result set |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (None found) | - | - | No SQL-layer callers identified. Consumed directly by the customer portal application. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetHistory (procedure)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Dictionary.FundingType (table)
├── Billing.Withdraw (table)
├── BackOffice.WithdrawApproval (table)
├── History.Credit (table)
├── Billing.WithdrawToFunding (table)
├── Dictionary.CardType (table)
├── History.Credit (table)
├── BackOffice.BonusType (table)
├── BackOffice.Campaign (table)
├── BackOffice.CompensationReason (table)
└── Dictionary.Currency (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Deposit branch - primary source for deposit records |
| Billing.Funding | Table | Deposit branch - LEFT JOIN for payment instrument name |
| Dictionary.FundingType | Table | Deposit branch - payment method name; FundingXML subquery |
| Billing.Withdraw | Table | Withdraw branch - primary source for withdrawal records |
| BackOffice.WithdrawApproval | Table | Withdraw branch - pending approval count and approval date |
| History.Credit | Table | Withdraw branch (CashoutFee, CreditTypeID=15); Credit branch (CreditTypeID IN 6,7) |
| Billing.WithdrawToFunding | Table | FundingXML subquery - withdrawal funding legs |
| Dictionary.Currency | Table | FundingXML subquery; Final SELECT - currency abbreviation |
| Dictionary.CardType | Table | FundingXML subquery - card type name for credit card withdrawals |
| Billing.Deposit (alias BDEP) | Table | FundingXML subquery - linked deposit for PayPal payer name |
| BackOffice.BonusType | Table | Credit branch - bonus type display name |
| BackOffice.Campaign | Table | Credit branch - campaign code for bonus credits |
| BackOffice.CompensationReason | Table | Credit branch - compensation reason display name |

### 6.2 Objects That Depend On This

No dependents found in the SQL layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get first page of history for customer 12345678 for the past 30 days

```sql
EXEC Billing.GetHistory
    @CID      = 12345678,
    @DateFrom = '2026-02-17',
    @DateTo   = '2026-03-18',
    @From     = 1,
    @To       = 25
```

### 8.2 Get second page (rows 26-50)

```sql
EXEC Billing.GetHistory
    @CID      = 12345678,
    @DateFrom = '2026-02-17',
    @DateTo   = '2026-03-18',
    @From     = 26,
    @To       = 50
```

### 8.3 Equivalent ad-hoc query for deposit branch only (with human-readable amounts)

```sql
SELECT
    'Deposit' AS Operation,
    d.DepositID,
    d.CurrencyID,
    d.Amount AS AmountInDollars,
    d.Amount * 100 AS AmountInCents,
    d.PaymentDate,
    ft.Name AS FundingTypeName,
    d.PaymentStatusID
FROM Billing.Deposit d WITH (NOLOCK)
LEFT JOIN Billing.Funding f WITH (NOLOCK) ON d.FundingID = f.FundingID
LEFT JOIN Dictionary.FundingType ft WITH (NOLOCK) ON f.FundingTypeID = ft.FundingTypeID
WHERE d.CID = 12345678
  AND d.PaymentDate BETWEEN '2026-02-17' AND '2026-03-18'
ORDER BY d.PaymentDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 35 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetHistory | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetHistory.sql*
