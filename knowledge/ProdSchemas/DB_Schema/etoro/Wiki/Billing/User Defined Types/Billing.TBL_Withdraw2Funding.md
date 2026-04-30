# Billing.TBL_Withdraw2Funding

> Table-valued parameter type representing a WithdrawToFunding (WTF) record, used as the staging type for all INSERT and UPDATE operations on `Billing.WithdrawToFunding` via `Billing.InsertWithdraw2Funding` and `Billing.UpdateWithdraw2Funding`.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | User Defined Type |
| **Key Identifier** | (WithdrawID, FundingID) composite - uniqueness per WTF record |
| **Partition** | N/A |
| **Indexes** | N/A - inline table type, no persistent indexes |

---

## 1. Business Meaning

`Billing.TBL_Withdraw2Funding` is the table-valued parameter (TVP) type for the `Billing.WithdrawToFunding` table. Each row represents one WithdrawToFunding (WTF) record - the link between a withdrawal request and a specific payment instrument (funding record). A single withdrawal may be paid out across multiple funding records (partial payments), hence the many-to-one relationship between WTF records and withdraw records.

This type exists as part of the DBA-648 refactoring pattern: instead of direct INSERT/UPDATE on `Billing.WithdrawToFunding`, procedures populate this TVP and call `Billing.InsertWithdraw2Funding` (for new WTF records) or `Billing.UpdateWithdraw2Funding` (for status updates). Both procedures also maintain the `History.WithdrawToFundingAction` audit trail.

Data flows from payment processing procedures: when a withdrawal is matched to a funding instrument and sent to a payment provider, the procedure populates `TBL_Withdraw2Funding` with the payment details (exchange rate, amount, depot/terminal routing, verification code from the provider) and calls the appropriate upsert procedure.

---

## 2. Business Logic

### 2.1 Payment Routing Fields

**What**: Controls which payment provider depot/terminal processes the withdrawal and how currency exchange is handled.

**Columns/Parameters Involved**: `DepotID`, `ProtocolMIDSettingsID`, `ProcessCurrencyID`, `ExchangeRate`, `BaseExchangeRate`, `ExchangeFee`

**Rules**:
- `DepotID` identifies which payment provider depot (merchant account gateway) processes the payment
- `ProtocolMIDSettingsID` identifies the specific Merchant ID (MID) settings to use
- `ProcessCurrencyID` is the currency in which the payment provider processes the transaction (may differ from the customer's withdrawal currency)
- `ExchangeRate` is the rate applied to convert from account currency to `ProcessCurrencyID`
- `BaseExchangeRate` is the reference rate before markup/fee adjustment (`dbo.dtPrice` type)
- `ExchangeFee` is the fee charged for the currency exchange, in integer units

### 2.2 Match Status and Cashout Mode

**What**: Tracks whether the WTF record was matched to a specific deposit record (for refund flows) and the operational mode of the cashout.

**Columns/Parameters Involved**: `MatchStatusID`, `DepositID`, `RefundAmountInDepositCurrency`, `CashoutTypeID`, `CashoutModeID`

**Rules**:
- `MatchStatusID` indicates whether this withdrawal was matched to an original deposit (for refund/chargeback flows). Defaults to 0 if NULL in InsertWithdraw2Funding.
- `DepositID` links to the originating deposit when this is a refund/reversal payment
- `RefundAmountInDepositCurrency` is the refund amount expressed in the original deposit's currency
- `CashoutTypeID` categorizes the withdrawal type (tinyint)
- `CashoutModeID` is the operational mode of this cashout processing (tinyint)

### 2.3 Lifecycle State Tracking

**What**: The CashoutStatusID on the WTF record tracks each individual payment leg's state, independent of the parent Withdraw's status.

**Columns/Parameters Involved**: `CashoutStatusID`, `CashoutActionStatusID`, `ResponseID`

**Rules**:
- A WithdrawToFunding starts at status 1 (Pending) and advances through to 3 (Processed) or 4 (Canceled)
- `CashoutActionStatusID` tracks the payment action state (2=Processed in WithdrawToFundingProcess)
- `ResponseID` references the payment provider's response record

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | int | YES | NULL | CODE-BACKED | ID of the parent withdrawal request in `Billing.Withdraw`. Part of the composite key for the WTF record. |
| 2 | FundingID | int | YES | NULL | CODE-BACKED | ID of the funding (payment instrument) record in `Billing.Funding` that will process this payment leg. |
| 3 | CashoutStatusID | int | YES | NULL | CODE-BACKED | Lifecycle state of this specific WTF payment leg. See [Cashout Status](_glossary.md#cashout-status) (1=Pending, 3=Processed, 4=Canceled). Set to 3 (Processed) in WithdrawToFundingProcess. |
| 4 | ProcessCurrencyID | int | YES | NULL | CODE-BACKED | Currency in which the payment provider processes this leg. May differ from the customer's account currency. References `Dictionary.Currency`. |
| 5 | ManagerID | int | YES | NULL | CODE-BACKED | Manager ID associated with this WTF record operation. May be -1 (meaning the billing service is running it - preserve existing ManagerID). |
| 6 | ExchangeRate | dbo.dtPrice | YES | NULL | CODE-BACKED | FX exchange rate applied when converting the withdrawal amount to the processing currency. `dbo.dtPrice` is a decimal precision type for financial rates. |
| 7 | Amount | money | YES | NULL | CODE-BACKED | Amount of this payment leg in the processing currency. A withdrawal may be split across multiple WTF records with different amounts summing to the total. |
| 8 | ModificationDate | datetime | YES | NULL | CODE-BACKED | Timestamp of the last status change on this WTF record. Updated on every transition. |
| 9 | WithdrawData | xml | YES | NULL | CODE-BACKED | XML payload containing additional payment provider data for this WTF record. Format depends on the payment provider (Skrill, Neteller, wire transfer, etc.). |
| 10 | ID | int | YES | NULL | CODE-BACKED | Auto-generated primary key of the `Billing.WithdrawToFunding` record. NULL on insert (IDENTITY column in the target table); returned by InsertWithdraw2Funding via OUTPUT into @out. |
| 11 | DepositID | int | YES | NULL | CODE-BACKED | For refund/reversal flows: the ID of the originating deposit in `Billing.Deposit` to which this withdrawal is matched. |
| 12 | RefundAmountInDepositCurrency | money | YES | NULL | CODE-BACKED | For refund flows: the amount being refunded expressed in the original deposit's currency. May differ from Amount if exchange rates changed. |
| 13 | CashoutTypeID | tinyint | YES | NULL | CODE-BACKED | Category/type of this cashout payment leg. References a cashout type lookup. |
| 14 | VerificationCode | varchar(50) | YES | NULL | CODE-BACKED | Authorization or reference code returned by the payment provider confirming the transaction. Stored for reconciliation and dispute resolution. Collation: Latin1_General_BIN. |
| 15 | ProcessorValueDate | datetime | YES | NULL | CODE-BACKED | Value date assigned by the payment processor - the date the funds are considered transferred. Defaults to GETUTCDATE() if NULL in InsertWithdraw2Funding. |
| 16 | MatchStatusID | int | YES | NULL | CODE-BACKED | Status of the deposit-to-withdrawal matching process. Used in refund flows. Defaults to 0 if NULL in InsertWithdraw2Funding. |
| 17 | DepotID | int | YES | NULL | CODE-BACKED | ID of the payment provider depot (merchant account) routing this payment leg. References `Billing.Depot`. |
| 18 | AutoPaymentStartDate | datetime | YES | NULL | CODE-BACKED | Start date for automatic/recurring payment processing. Defaults to GETUTCDATE() if NULL in InsertWithdraw2Funding. |
| 19 | ProtocolMIDSettingsID | int | YES | NULL | CODE-BACKED | ID of the Merchant ID (MID) settings record defining which payment provider configuration to use. Defaults to 0 if NULL in InsertWithdraw2Funding. References `Billing.ProtocolMIDSettings`. |
| 20 | BaseExchangeRate | dbo.dtPrice | YES | NULL | CODE-BACKED | Reference FX rate before fee/markup adjustment. Used alongside ExchangeRate to calculate the exchange fee. |
| 21 | ExchangeFee | int | YES | NULL | CODE-BACKED | Fee charged for currency exchange on this payment leg, in integer units (typically representing basis points or fixed amounts). |
| 22 | CashoutModeID | tinyint | YES | NULL | CODE-BACKED | Operational mode for this cashout processing (e.g., instant vs. batch). References a cashout mode lookup. |
| 23 | CreationDate | datetime | YES | NULL | CODE-BACKED | Timestamp when this WTF record was first created. Defaults to GETUTCDATE() if NULL in InsertWithdraw2Funding. |
| 24 | AdditionalInformation | nvarchar(250) | YES | NULL | CODE-BACKED | Supplementary data from the payment provider or processing system, stored as free text. Collation: Latin1_General_BIN. |
| 25 | VendorCode | nvarchar(250) | YES | NULL | CODE-BACKED | Provider-specific reference code or transaction identifier from the payment vendor. Used for reconciliation. Collation: Latin1_General_BIN. |
| 26 | MerchantAccountID | int | YES | NULL | CODE-BACKED | ID of the merchant account used to process this payment leg. Defaults to 0 if NULL in InsertWithdraw2Funding. References `Billing.MerchantAccountValues`. |
| 27 | Remark | varchar(250) | YES | NULL | CODE-BACKED | Internal note associated with this WTF record. Used in history logging via WithdrawToFundingAction. Collation: Latin1_General_BIN. |
| 28 | CashoutActionStatusID | int | YES | NULL | CODE-BACKED | Status of the cashout action on this WTF record (separate from CashoutStatusID). Set to 2 (Processed) in WithdrawToFundingProcess. |
| 29 | SchemeId | int | YES | NULL | CODE-BACKED | Card scheme identifier (Visa, Mastercard, etc.) associated with this WTF record. Added Shay Oren 24/10/2021 (PAYUS-3900). |
| 30 | ResponseID | int | YES | NULL | CODE-BACKED | ID of the payment provider response record. Added Shay Oren 31/10/2021 (PAYUA-2822). References `Billing.GetResponse` or response tracking table. |
| 31 | RequestExecuteEntryMethodId | int | YES | NULL | CODE-BACKED | Entry method identifier for the payment request execution (e.g., online, recurring, batch). References a payment entry method lookup. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.Withdraw | Implicit | Parent withdrawal request |
| FundingID | Billing.Funding | Implicit | Payment instrument for this leg |
| ProcessCurrencyID | Dictionary.Currency | Lookup | Currency for processing |
| DepotID | Billing.Depot | Implicit | Payment provider depot |
| ProtocolMIDSettingsID | Billing.ProtocolMIDSettings | Implicit | Merchant ID configuration |
| DepositID | Billing.Deposit | Implicit | Original deposit for refund flows |
| CashoutStatusID | Dictionary.CashoutStatus | Lookup | WTF payment leg state |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.InsertWithdraw2Funding | @Widraw2F parameter | TVP Parameter | Primary insert consumer - creates new WTF records and logs history |
| Billing.UpdateWithdraw2Funding | Parameter | TVP Parameter | Update consumer - modifies existing WTF records |
| Billing.WithdrawToFundingProcess | @InfoWTF (local) | TVP (local) | Stages WTF status updates during payment processing |
| Billing.WithdrawToFundingProcess_v2 | @InfoWTF (local) | TVP (local) | V2 processing path |

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
| Billing.InsertWithdraw2Funding | Stored Procedure | Receives TVP; inserts into Billing.WithdrawToFunding; logs to History.WithdrawToFundingAction |
| Billing.UpdateWithdraw2Funding | Stored Procedure | Receives TVP; updates existing Billing.WithdrawToFunding records |
| Billing.WithdrawToFundingProcess | Stored Procedure | Uses locally to stage WTF status updates |
| Billing.WithdrawToFundingProcess_v2 | Stored Procedure | V2 variant of the processing path |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View recent WTF records for a withdrawal

```sql
SELECT TOP 10
    wtf.ID,
    wtf.WithdrawID,
    wtf.FundingID,
    cs.Name AS Status,
    wtf.Amount,
    wtf.ProcessCurrencyID,
    wtf.DepotID,
    wtf.VerificationCode,
    wtf.ProcessorValueDate,
    wtf.ModificationDate
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON cs.CashoutStatusID = wtf.CashoutStatusID
ORDER BY wtf.ModificationDate DESC
```

### 8.2 View partial payment breakdown for a withdrawal

```sql
SELECT
    wtf.WithdrawID,
    wtf.ID AS WTF_ID,
    wtf.FundingID,
    wtf.Amount,
    wtf.CashoutStatusID,
    cs.Name AS StatusName,
    wtf.ProcessorValueDate
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON cs.CashoutStatusID = wtf.CashoutStatusID
-- Replace @WithdrawID with a specific withdraw ID
-- WHERE wtf.WithdrawID = @WithdrawID
ORDER BY wtf.ID
```

### 8.3 View WTF records with exchange rate details

```sql
SELECT TOP 20
    wtf.ID,
    wtf.WithdrawID,
    wtf.ProcessCurrencyID,
    c.Symbol AS ProcessCurrency,
    wtf.ExchangeRate,
    wtf.BaseExchangeRate,
    wtf.ExchangeFee,
    wtf.Amount,
    wtf.MerchantAccountID,
    wtf.ProtocolMIDSettingsID
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
JOIN Dictionary.Currency c WITH (NOLOCK) ON c.CurrencyID = wtf.ProcessCurrencyID
WHERE wtf.CashoutStatusID = 3  -- Processed
ORDER BY wtf.ModificationDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 29 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.TBL_Withdraw2Funding | Type: User Defined Type | Source: etoro/etoro/Billing/User Defined Types/Billing.TBL_Withdraw2Funding.sql*
