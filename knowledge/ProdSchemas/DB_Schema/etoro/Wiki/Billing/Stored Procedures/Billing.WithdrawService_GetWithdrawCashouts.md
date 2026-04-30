# Billing.WithdrawService_GetWithdrawCashouts

> Returns the payment execution legs (cashouts/refunds) for a specific withdrawal, enriching each leg with payment instrument identifiers extracted from the XML FundingData per payment method type, card type, and conversion cost.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @withdrawID - the withdrawal whose cashout legs are retrieved |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WithdrawService_GetWithdrawCashouts` is the primary read procedure for fetching the full cashout detail of a withdrawal request. When the WithdrawalService needs to display or process the payment legs of a specific withdrawal, this procedure retrieves all `Billing.WithdrawToFunding` rows for that withdrawal, enriched with funding instrument details and computed financial fields.

The core enrichment this procedure performs is extracting a human-readable payment account identifier (`PaymentDetails`) from the raw XML `FundingData` column of `Billing.Funding`. Each payment method stores its account identifier in a different XML node (a card stores a masked card number, a bank wire stores an account ID, PayPal stores an email, ACH stores a masked account), so the procedure uses a 15-branch CASE expression to extract the correct field for each `FundingTypeID`. This abstraction allows the caller to receive a uniform `PaymentDetails` column regardless of payment method.

The optional `@CID` parameter (added in MIMOPSA-6875) adds a security check: if provided, only the withdrawal whose `CID` matches the given value is returned. This prevents a caller from accidentally or maliciously retrieving cashout data for a withdrawal that belongs to a different customer.

---

## 2. Business Logic

### 2.1 Payment Method Identifier Extraction (PaymentDetails)

**What**: A 15-branch CASE on FundingTypeID extracts the most meaningful account identifier for each payment method from the XML FundingData blob.

**Columns/Parameters Involved**: `FundingTypeID`, `FundingData` (XML), `PaymentDetails` (output)

**Rules**:
- FundingTypeID=1 (Credit Card): extracts `SecuredCardDataAsString` - masked card number or token
- FundingTypeID=2 (Wire transfer): extracts `AccountIDAsString`
- FundingTypeID=3 (PayPal): extracts `EmailAsString` from FundingData; if empty falls back to `PayerAsString` from `Billing.Deposit.PaymentData` XML (added PAYUA-2633)
- FundingTypeID=6 (Neteller): extracts `AccountIDAsDecimal` if non-empty/non-zero, otherwise falls back to `EmailAsString`
- FundingTypeID=8 (MoneyBookers): extracts `EmailAsString`
- FundingTypeID=10 (WebMoney): extracts `AccountIDAsDecimal`
- FundingTypeID=11 (Giropay/Sofort): extracts `IBANCodeAsString`
- FundingTypeID=22 (UnionPay): extracts `AccountIDAsDecimal`
- FundingTypeID=28 (OnlineBanking): extracts `BankAccountAsString`
- FundingTypeID=29 (ACH): extracts `MaskedAccountIDAsString`
- FundingTypeID=32 (PWMB): extracts `MaskedAccountIDAsString`
- FundingTypeID=33 (eToro Card): reads IBAN from `Billing.WithdrawAdditionalParameters` (ParameterTypeID=8) - card withdrawals store their IBAN in the extension table, not in FundingData XML
- FundingTypeID=34 (iDeal, added PAYUS-1897): extracts `IBANCodeAsString`
- FundingTypeID=35 (Trustly, added PAYUS-1552): extracts `IBANCodeAsString`
- All other types: returns NULL

**Diagram**:
```
FundingTypeID -> PaymentDetails source
=================================================
1  (CC)          -> FundingData/SecuredCardDataAsString (masked card)
2  (Wire)        -> FundingData/AccountIDAsString
3  (PayPal)      -> FundingData/EmailAsString (fallback: Deposit/PayerAsString)
6  (Neteller)    -> FundingData/AccountIDAsDecimal (fallback: EmailAsString)
8  (MoneyBkrs)   -> FundingData/EmailAsString
10 (WebMoney)    -> FundingData/AccountIDAsDecimal
11 (Giropay)     -> FundingData/IBANCodeAsString
22 (UnionPay)    -> FundingData/AccountIDAsDecimal
28 (OnlineBnk)   -> FundingData/BankAccountAsString
29 (ACH)         -> FundingData/MaskedAccountIDAsString
32 (PWMB)        -> FundingData/MaskedAccountIDAsString
33 (eToroCard)   -> WithdrawAdditionalParameters (ParameterTypeID=8 = IBAN)
34 (iDeal)       -> FundingData/IBANCodeAsString
35 (Trustly)     -> FundingData/IBANCodeAsString
other            -> NULL
```

### 2.2 ConversionCost Calculation

**What**: For processed (finalized) cashout legs, computes the conversion cost in PIPs USD using the BackOffice calculation function.

**Columns/Parameters Involved**: `CashoutStatusID`, `ProcessCurrencyID`, `ExchangeRate`, `BaseExchangeRate`, `Amount`, `ConversionCost` (output)

**Rules**:
- `ConversionCost = -ISNULL(BackOffice.CalculateWithdrawPIPsUSD(ProcessCurrencyID, ExchangeRate, BaseExchangeRate, Amount).Value, 0)` when `CashoutStatusID = 3` (Processed)
- `ConversionCost = 0` for all non-Processed legs (Pending, InProcess, Cancelled, etc.)
- The result is negated (negative number = cost incurred) - consistent with BI PIPS reporting convention
- Added in PAYUA-3088 to enable FX fee reporting for processed withdrawals

### 2.3 Optional CID Security Filter

**What**: When @CID is provided, limits results to the withdrawal row whose CID matches, preventing cross-customer data exposure.

**Columns/Parameters Involved**: `@CID`, `w.CID`

**Rules**:
- `WHERE w.CID = ISNULL(@CID, w.CID)` - if @CID is NULL, `ISNULL` resolves to `w.CID` which always equals itself, effectively no filter
- If @CID is provided and does not match the withdrawal's owner CID, zero rows are returned
- Added in MIMOPSA-6875 to support customer-scoped API calls

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @withdrawID | INTEGER | NO | - | CODE-BACKED | Required. The WithdrawID to retrieve cashout legs for. Filters `Billing.WithdrawToFunding` and `Billing.Withdraw` to this specific withdrawal. |
| 2 | @CID | INT | YES | NULL | CODE-BACKED | Optional. Customer ID ownership check. If supplied, only rows where `Billing.Withdraw.CID` matches are returned. Prevents cross-customer data access. Added MIMOPSA-6875. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | PK of `Billing.WithdrawToFunding`. Unique identifier for this payment execution leg. From `wtf.ID`. |
| 2 | Amount | money | NO | - | CODE-BACKED | Payout amount in `ProcessCurrencyID` currency for this leg. From `wtf.Amount`. See Billing.WithdrawToFunding Section 2.3 for exchange rate context. |
| 3 | ProcessCurrencyID | int | YES | - | CODE-BACKED | Currency in which the provider processes this payout. FK to Dictionary.Currency. From `wtf.ProcessCurrencyID`. |
| 4 | ExchangeRate | decimal | YES | - | CODE-BACKED | Applied FX rate for currency conversion (customer currency to ProcessCurrency). From `wtf.ExchangeRate`. Used in ConversionCost calculation. |
| 5 | BaseExchangeRate | decimal | YES | - | CODE-BACKED | Base FX rate before fee markup. From `wtf.BaseExchangeRate`. Difference between ExchangeRate and BaseExchangeRate reflects the exchange fee. |
| 6 | CashoutStatusID | int | NO | - | CODE-BACKED | Execution status of this payment leg. Key values: 1=Pending, 2=InProcess, 3=Processed (money sent), 4=Canceled, 7=Rejected, 8=RejectedByProvider. See Billing.WithdrawToFunding Section 2.1 for full state machine. From `wtf.CashoutStatusID`. |
| 7 | ModificationDate | datetime | NO | - | CODE-BACKED | Last modification timestamp for this payment leg. From `wtf.ModificationDate`. |
| 8 | WithdrawID | int | NO | - | CODE-BACKED | FK to Billing.Withdraw. The parent withdrawal request this leg belongs to. From `wtf.WithdrawID`. Always equals @withdrawID. |
| 9 | FundingID | int | NO | - | CODE-BACKED | FK to Billing.Funding. The specific payment instrument (card, bank account, wallet) the payout is being sent to. From `wtf.FundingID`. |
| 10 | AmountInCurrency | money | YES | - | CODE-BACKED | For refund legs (CashoutTypeID=2): the refund amount expressed in the original deposit's currency. Aliased from `wtf.RefundAmountInDepositCurrency`. May differ from `Amount` due to exchange rate differences between original deposit and withdrawal. |
| 11 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type. Drives the PaymentDetails extraction logic. Key values: 1=CC, 2=Wire, 3=PayPal, 6=Neteller, 8=MoneyBookers, 10=WebMoney, 11=Giropay, 22=UnionPay, 28=OnlineBanking, 29=ACH, 32=PWMB, 33=eToroCard, 34=iDeal, 35=Trustly. From `f.FundingTypeID`. |
| 12 | PaymentDetails | varchar(MAX) | YES | - | CODE-BACKED | Human-readable payment account identifier extracted from FundingData XML, specific to each payment method. See Section 2.1 for the full per-method extraction map. NULL for unrecognized FundingTypeIDs. |
| 13 | CardType | varchar(MAX) | YES | - | CODE-BACKED | Credit card scheme identifier (CardTypeIDAsInteger from FundingData XML). Only populated for FundingTypeID=1 (Credit Card); returns '0' for all other payment methods. |
| 14 | ConversionCost | money | NO | - | CODE-BACKED | FX conversion cost in USD PIPs for this payment leg. Negative value = cost incurred. Only non-zero when CashoutStatusID=3 (Processed). Computed via `BackOffice.CalculateWithdrawPIPsUSD`. Added PAYUA-3088. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @withdrawID | Billing.WithdrawToFunding | Reader | Primary source table - filters to the specified WithdrawID |
| @withdrawID | Billing.Withdraw | Reader | Joined for CID ownership check |
| FundingID | Billing.Funding | Reader | Joined for FundingTypeID and FundingData XML |
| ParameterTypeID=8 | Billing.WithdrawAdditionalParameters | Reader | Subquery for FundingTypeID=33 (eToroCard) IBAN lookup |
| (fallback) | Billing.Deposit | Reader | Subquery for FundingTypeID=3 (PayPal) PayerAsString fallback |
| ConversionCost | BackOffice.CalculateWithdrawPIPsUSD | OUTER APPLY | Computes FX conversion cost in PIPs USD for processed legs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WithdrawalService (application) | @withdrawID | Caller | Called by the withdrawal API to retrieve cashout detail for display in the UI or for processing decisions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawService_GetWithdrawCashouts (procedure)
├── Billing.WithdrawToFunding (table)
├── Billing.Funding (table)
├── Billing.Withdraw (table)
├── Billing.WithdrawAdditionalParameters (table)
├── Billing.Deposit (table)
└── BackOffice.CalculateWithdrawPIPsUSD (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Primary source - all cashout legs for the withdrawal |
| Billing.Funding | Table | INNER JOIN for FundingTypeID and FundingData XML |
| Billing.Withdraw | Table | INNER JOIN for CID ownership check |
| Billing.WithdrawAdditionalParameters | Table | Subquery - IBAN for eToroCard (FundingTypeID=33) |
| Billing.Deposit | Table | Subquery - PayerAsString fallback for PayPal (FundingTypeID=3) |
| BackOffice.CalculateWithdrawPIPsUSD | Function | OUTER APPLY - FX conversion cost calculation for Processed legs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| WithdrawalService (application) | External application | Caller - retrieves cashout details for withdrawal processing and UI display |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages to reduce network overhead for the application layer |
| CID filter pattern | Design | `w.CID = ISNULL(@CID, w.CID)` - when @CID is NULL, the filter is a no-op (column always equals itself). When @CID is provided, acts as a strict equality filter. |
| OUTER APPLY | Design | BackOffice.CalculateWithdrawPIPsUSD uses OUTER APPLY so rows with no conversion cost data still appear (ConversionCost.Value = NULL -> defaulted to 0) |

---

## 8. Sample Queries

### 8.1 Get all cashout legs for a withdrawal with payment details

```sql
EXEC Billing.WithdrawService_GetWithdrawCashouts
    @withdrawID = 1234567;
```

### 8.2 Get cashout legs with customer ownership verification

```sql
EXEC Billing.WithdrawService_GetWithdrawCashouts
    @withdrawID = 1234567,
    @CID = 987654;
-- Returns 0 rows if withdrawal 1234567 does not belong to CID 987654
```

### 8.3 Query cashout legs with resolved status names

```sql
SELECT
    wtf.ID,
    wtf.WithdrawID,
    wtf.Amount,
    wtf.ProcessCurrencyID,
    CASE wtf.CashoutStatusID
        WHEN 1 THEN 'Pending'
        WHEN 2 THEN 'InProcess'
        WHEN 3 THEN 'Processed'
        WHEN 4 THEN 'Canceled'
        WHEN 7 THEN 'Rejected'
        WHEN 8 THEN 'RejectedByProvider'
        ELSE CAST(wtf.CashoutStatusID AS VARCHAR(10))
    END AS StatusName,
    f.FundingTypeID,
    wtf.ModificationDate
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
INNER JOIN Billing.Funding f WITH (NOLOCK) ON f.FundingID = wtf.FundingID
WHERE wtf.WithdrawID = 1234567;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUS-1552 (referenced in DDL comment) | Jira | Added Trustly (FundingTypeID=35) IBAN extraction support |
| PAYUS-1897 (referenced in DDL comment) | Jira | Added iDeal (FundingTypeID=34) IBAN extraction support |
| PAYUA-2633 (referenced in DDL comment) | Jira | Changed PayPal behavior: added fallback to Billing.Deposit.PayerAsString when FundingData email is empty |
| PAYUA-3088 (referenced in DDL comment) | Jira | Added ConversionCost calculation via BackOffice.CalculateWithdrawPIPsUSD |
| MIMOPSA-6875 (referenced in DDL comment) | Jira | Added @CID parameter for customer-scoped filtering |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira (5 tickets referenced in DDL comments) | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawService_GetWithdrawCashouts | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawService_GetWithdrawCashouts.sql*
