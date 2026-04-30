# Billing.GetPaymentsForWithdraw

> Returns human-readable payment method display rows for a specific withdrawal request, showing the payment method name, masked/formatted account identifier, calculated payout amount, and currency - used for withdrawal confirmation screens and reports.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns display rows from Billing.WithdrawToFunding for a given WithdrawID where CashoutStatusID=3 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetPaymentsForWithdraw` produces presentation-ready rows for the payment methods used in a specific customer withdrawal. Where other procedures return raw IDs and amounts, this procedure formats the data for display: it shows the payment method name (e.g., "Visa"), a masked account identifier (e.g., "..4444" for a credit card, or "user@paypal.com" for PayPal), the payout amount in the deposit currency, and the currency abbreviation.

The procedure exists to support withdrawal confirmation UIs and reports that need to show customers and agents the "what payment method received the money" summary without exposing full card or account numbers. The `CLR.Decrypt4` call partially decrypts the encrypted card number to show only the last 4 digits (prefixed with "..").

Data flows: it is called after a withdrawal has been processed (CashoutStatusID=3 filter), joining `Billing.WithdrawToFunding` to `Billing.Funding` (for FundingData XML and type), `Dictionary.FundingType` (for method name), `Dictionary.Currency` (for abbreviation), `Dictionary.CardType` (for card brand like Visa/Mastercard for CC), and optionally `Billing.Deposit` (for PayPal deposit-refund payer name). Created in 2014 (idanfe).

---

## 2. Business Logic

### 2.1 Payment Method Identification Display (IIF + CASE)

**What**: The Method column shows the most specific payment method name available. For credit cards it shows the card brand (Visa, Mastercard) from Dictionary.CardType; for all others it shows the FundingType name.

**Columns/Parameters Involved**: `DFTY.FundingTypeID`, `DCTY.Name` (CardType), `DFTY.Name` (FundingType)

**Rules**:
- `IIF(DFTY.FundingTypeID=1, DCTY.Name, DFTY.Name)` - credit card -> card brand name; everything else -> funding type name
- CardType join: `ON BFUN.FundingTypeID = 1 AND BFUN.FundingData.value('Funding[1]/CardTypeIDAsInteger[1]', 'INT') = DCTY.CardTypeID`

### 2.2 Account Identifier Formatting by Funding Type

**What**: The AccountId column shows a masked or formatted account identifier appropriate for each payment method type.

**Columns/Parameters Involved**: `DFTY.FundingTypeID`, `BFUN.FundingData` (XML), `BWTF.WithdrawData` (XML), `BDEP.PaymentData` (XML)

**Rules**:
- FundingTypeID=1 (Credit Card): `'..' + CLR.Decrypt4(FundingData/CardNumberAsString)` - decrypts card number and shows only last 4 digits with ".." prefix
- FundingTypeID=2 (Wire Transfer): `'to ' + WithdrawData/PayeeNameAsString` - shows payee name from the withdraw XML
- FundingTypeID=8: `FundingData/EmailAsString` - shows the account email
- FundingTypeID=3 (PayPal) with no linked deposit: `FundingData/EmailAsString` - shows PayPal email from funding record
- FundingTypeID=3 (PayPal) with linked deposit (refund scenario): `Deposit.PaymentData/PayerAsString` - shows payer name from the original deposit
- FundingTypeID=6 (Neteller) - shows email if AccountIDAsDecimal is 0/'0'/NULL, otherwise `'Account ' + AccountIDAsDecimal`
- FundingTypeID=7, 10, 11, 14: `'Account ' + FundingData/AccountIDAsDecimal` - shows account ID
- FundingTypeID=19: `'Internal Payment'` (literal)
- All others: empty string

### 2.3 Amount Calculation (Refund vs Exchange Rate vs Raw)

**What**: The Amount column shows the payout amount in the deposit's original currency using a three-way priority: refund amount, exchange-rate-back-converted amount, or raw USD amount.

**Columns/Parameters Involved**: `BWTF.RefundAmountInDepositCurrency`, `BWTF.ExchangeRate`, `BWTF.Amount`

**Rules**:
- Priority 1: `RefundAmountInDepositCurrency > 0` -> use the explicit refund amount in deposit currency
- Priority 2: `ExchangeRate IS NOT NULL AND ExchangeRate != 0` -> use `Amount / ExchangeRate` (back-convert USD to deposit currency)
- Priority 3: use `Amount` (raw USD amount)
- Result cast as MONEY

### 2.4 CashoutStatusID=3 Filter

**What**: Only payment order rows in status 3 are returned.

**Rules**:
- `WHERE WithdrawID = @WithdrawID AND CashoutStatusID = 3` - status 3 = processed/completed cashout items
- This filters out pending or failed payment attempts; only finalized cashout disbursements are shown

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INT | NO | - | CODE-BACKED | Identifier of the withdrawal request. FK to `Billing.Withdraw.WithdrawID`. The procedure returns all WithdrawToFunding rows for this withdrawal where CashoutStatusID=3. |

**Return columns:**

| # | Column | Source | Confidence | Description |
|---|--------|--------|------------|-------------|
| 2 | Method | IIF(FundingTypeID=1, Dictionary.CardType.Name, Dictionary.FundingType.Name) | CODE-BACKED | Human-readable payment method label. Credit cards show card brand (Visa, Mastercard); all others show the FundingType name. |
| 3 | AccountId | CASE on FundingTypeID + XML extraction | CODE-BACKED | Masked or formatted account identifier for display. Format varies by method: credit card shows "..{last4}", wire transfer shows "to {payee}", PayPal/Neteller show email or account ID. See Business Logic 2.2 for full mapping. |
| 4 | Amount | Priority calculation: RefundAmountInDepositCurrency / Amount/ExchangeRate / Amount | CODE-BACKED | Payout amount in the deposit's original currency (MONEY). See Business Logic 2.3 for priority rules. |
| 5 | Currency | Dictionary.Currency.Abbreviation | CODE-BACKED | ISO currency abbreviation for the processing currency (e.g., USD, EUR). From `Billing.WithdrawToFunding.ProcessCurrencyID` -> Dictionary.Currency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.WithdrawToFunding.WithdrawID | Filter | Primary filter - retrieves cashout disbursements for this withdrawal |
| (JOIN) | Billing.Funding | LEFT JOIN | Source of FundingData XML and FundingTypeID |
| (JOIN) | Dictionary.FundingType | LEFT JOIN | Source of payment method name |
| (JOIN) | Dictionary.Currency | LEFT JOIN | Source of currency abbreviation |
| (JOIN) | Dictionary.CardType | LEFT JOIN | Source of card brand name (credit card only, via XML CardTypeIDAsInteger) |
| (JOIN) | Billing.Deposit | LEFT JOIN | Source of PayPal payer name for deposit-refund scenarios |
| CLR.Decrypt4 | CLR Function | Function call | Decrypts card number to extract last 4 digits for display |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | GRANT EXECUTE | Permission | BI admin role - withdrawal reporting and analysis |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetPaymentsForWithdraw (procedure)
├── Billing.WithdrawToFunding (table)
├── Billing.Funding (table)
├── Dictionary.FundingType (table - cross-schema)
├── Dictionary.Currency (table - cross-schema)
├── Dictionary.CardType (table - cross-schema)
├── Billing.Deposit (table - conditional, PayPal refund)
└── CLR.Decrypt4 (function - cross-schema, credit card masking)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Primary data source; filtered by WithdrawID and CashoutStatusID=3 |
| Billing.Funding | Table | LEFT JOINed for FundingData XML and FundingTypeID |
| Dictionary.FundingType | Table | LEFT JOINed for method name display |
| Dictionary.Currency | Table | LEFT JOINed for currency abbreviation |
| Dictionary.CardType | Table | LEFT JOINed for card brand name (CC only) |
| Billing.Deposit | Table | LEFT JOINed for PayPal refund payer name (conditional on DepositID > 0 and FundingTypeID=3) |
| CLR.Decrypt4 | Function | Called to partially decrypt card number hash; returns decryptable portion for last-4-digits display |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | DB Security Principal | EXECUTE permission - withdrawal data analysis |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Notable**: Uses `OPTION (RECOMPILE)` hint - this forces a fresh execution plan each call, likely because the XML path queries and multi-way CASE on FundingTypeID produce very different query shapes depending on data distribution. The CLR.Decrypt4 function is a CLR-based decryption routine in a separate schema (CLR) - its presence indicates PCI-compliant partial masking of card numbers. The commented-out line for FundingTypeIDs 6,7,10,11,14 shows this code evolved over time as Neteller's account ID format changed.

---

## 8. Sample Queries

### 8.1 Get payment method display rows for a withdrawal
```sql
EXEC [Billing].[GetPaymentsForWithdraw] @WithdrawID = 88776655
```

### 8.2 Find withdrawals with multiple payment methods (split cashouts)
```sql
-- Withdrawals that have >1 WTF row with CashoutStatusID=3
SELECT WithdrawID, COUNT(*) AS PaymentMethodCount
FROM Billing.WithdrawToFunding WITH (NOLOCK)
WHERE CashoutStatusID = 3
GROUP BY WithdrawID
HAVING COUNT(*) > 1
ORDER BY PaymentMethodCount DESC
```

### 8.3 Understand the raw data for a withdrawal's payment methods
```sql
SELECT
    bwtf.ID,
    bwtf.WithdrawID,
    bwtf.CashoutStatusID,
    bwtf.ProcessCurrencyID,
    bwtf.Amount,
    bwtf.ExchangeRate,
    bwtf.RefundAmountInDepositCurrency,
    bf.FundingTypeID
FROM Billing.WithdrawToFunding bwtf WITH (NOLOCK)
LEFT JOIN Billing.Funding bf WITH (NOLOCK) ON bf.FundingID = bwtf.FundingID
WHERE bwtf.WithdrawID = 88776655
  AND bwtf.CashoutStatusID = 3
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetPaymentsForWithdraw | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetPaymentsForWithdraw.sql*
