# BackOffice.GetPaymentsDetailsHTMLTable

> Builds the payment method summary data for withdrawal notification emails - returns aggregated rows of (method label, amount, currency) for all approved payment orders within a withdrawal, with payment-type-specific display logic for credit cards, wire transfers, PayPal, Skrill, Neteller, and other methods.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID + @WithdrawToFundingCCLast4DigitsTbl |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is step 5 (final step) of the withdrawal notification email pipeline run by the Azure function `prod-WithdrawNotif-func-ne` (see `BackOffice.GetNotificationRecordsForProcessing` documentation for pipeline context). It generates the payment breakdown data used to populate the HTML table in the withdrawal completion email sent to customers.

For a given withdrawal, it returns one row per (payment method description, currency) pair, showing:
- How the funds were paid (e.g., "Visa ..1234", "Wire Transfer to John Smith", "PayPal user@example.com")
- How much was paid in that method
- In what currency

The `@WithdrawToFundingCCLast4DigitsTbl` TVP is a security design choice: credit card last-4 digits are passed in externally by the caller (pre-fetched from PCI-compliant systems) rather than joined inside this procedure, keeping this SP free from direct access to sensitive card data.

**Applies to**: Only approved payment orders (`CashoutStatusID = 3`).

**Permissions**: EXECUTE granted to WithdrawalServiceUser and BOUserTaskScheduler.

---

## 2. Business Logic

### 2.1 Approved Payments Only

**What**: Restricts results to completed, approved payment orders.

**Columns/Parameters Involved**: Billing.WithdrawToFunding.CashoutStatusID, @WithdrawID

**Rules**:
- `WHERE WithdrawID = @WithdrawID AND CashoutStatusID = 3`: Only payment orders that have been approved (fully processed) for this withdrawal are included.
- Pending, in-process, or rejected payment orders are excluded.

### 2.2 Payment Method Label Construction

**What**: Builds a human-readable payment method description for each approved payment order based on the funding type.

**Columns/Parameters Involved**: Dictionary.FundingType.FundingTypeID, BWTF.WithdrawData (XML), BFUN.FundingData (XML), BDEP.PaymentData (XML), @WithdrawToFundingCCLast4DigitsTbl

**Rules**:

| FundingTypeID | Label Pattern | Example | Source |
|---------------|--------------|---------|--------|
| 1 (Credit Card) | `[CardType] ..[last4]` | `Visa ..1234` | CardType from Dictionary.CardType; last4 from @WithdrawToFundingCCLast4DigitsTbl TVP |
| 2 (Wire Transfer) | `Wire Transfer to [PayeeName]` | `Wire Transfer to John Smith` | PayeeName from BWTF.WithdrawData XML: `/Withdraw[1]/PayeeNameAsString[1]` |
| 8 (PayPal refund) | `PayPal [email]` | `PayPal user@example.com` | Email from BFUN.FundingData XML: `/Funding[1]/EmailAsString[1]` |
| 3 (PayPal, no deposit) | `PayPal [email]` | `PayPal user@example.com` | Email from BFUN.FundingData XML: `/Funding[1]/EmailAsString[1]` |
| 3 (PayPal, with deposit) | `PayPal [PayerName]` | `PayPal john.smith` | PayerName from BDEP.PaymentData XML: `/Deposit[1]/PayerAsString[1]` |
| 6, 7, 10, 11, 14 (Skrill, Neteller, etc.) | `[FundingType] Account [AccountID]` | `Skrill Account 123456` | AccountID from BFUN.FundingData XML: `/Funding[1]/AccountIDAsDecimal[1]` |
| 19 (Internal) | `Internal Payment` | `Internal Payment` | Hard-coded |
| Other | `[FundingType]` (empty suffix) | `Moneybookers` | FundingType name only |

For FundingTypeID=1 specifically, the method prefix is the CARD TYPE name (Visa, Mastercard, etc.) from `Dictionary.CardType`, not the funding type name.

### 2.3 Amount Normalization

**What**: Converts the payment order amount to the deposit's original currency for display.

**Columns/Parameters Involved**: BWTF.RefundAmountInDepositCurrency, BWTF.ExchangeRate, BWTF.Amount

**Rules**:
- Priority 1: `RefundAmountInDepositCurrency > 0` - use the pre-computed deposit-currency amount directly.
- Priority 2: `ExchangeRate IS NULL OR ExchangeRate = 0` - use `Amount` (which is in USD when no FX applied).
- Priority 3: `Amount / ExchangeRate` - convert USD amount to deposit currency using the recorded exchange rate.
- Result cast to `money` type for financial precision.

### 2.4 Aggregation by Method + Currency

**What**: Sums amounts for payment orders sharing the same method label and currency.

**Columns/Parameters Involved**: Method, Currency, Amount

**Rules**:
- `GROUP BY Method, Currency; ORDER BY Method`: Multiple payment orders with the same funding method type and currency (e.g., multiple credit card payments on the same card) are combined into one row.
- `SUM(Amount)` with `CONVERT(varchar(100), SUM(Amount), 1)`: Money format style 1 = with comma separator (e.g., "1,234.56").
- Currency: `ISNULL(DCUR.DisplayName, DCUR.Abbreviation)` - uses the display name if available, otherwise the abbreviation (e.g., "USD", "EUR").

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INT | NO | - | CODE-BACKED | The withdrawal record ID. Scopes results to payment orders for this specific withdrawal. All approved payment orders for this withdrawal are included. |
| 2 | @WithdrawToFundingCCLast4DigitsTbl | Billing.WithdrawToFundingCCLast4Digits (TVP) | NO | - | CODE-BACKED | Table-valued parameter. Provides masked credit card last 4 digits per payment order ID (ID, CreditCardLast4). Passed by the caller to avoid PCI-sensitive data access inside this SP. Required even if no credit card payments exist (pass empty TVP). |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Method | NVARCHAR | YES | - | CODE-BACKED | Human-readable payment method label. Aggregated label combining FundingType name with payment-specific details (card last4, email, account ID, beneficiary name). See Section 2.2 for per-type formatting rules. |
| 2 | Amount | VARCHAR(100) | NO | - | CODE-BACKED | Formatted sum of amounts for this method+currency combination. Format: comma-separated with 2 decimal places (CONVERT style 1). E.g., "1,234.56". |
| 3 | Currency | NVARCHAR | NO | - | CODE-BACKED | Display currency name (Dictionary.Currency.DisplayName if set, else Abbreviation). Identifies which currency the Amount is expressed in. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Main data | Billing.WithdrawToFunding | Read (INNER JOIN base) | Payment order amounts, exchange rates, status, WithdrawID filter |
| Funding details | Billing.Funding | INNER JOIN | FundingTypeID, FundingData XML (email, account ID) |
| Funding type name | Dictionary.FundingType | INNER JOIN | Payment method type name for label construction |
| Currency display | Dictionary.Currency | INNER JOIN | Currency display name/abbreviation |
| Card type name | Dictionary.CardType | LEFT JOIN | Visa/Mastercard/etc. name for FundingTypeID=1 |
| Deposit PayPal payer | Billing.Deposit | LEFT JOIN | PayerName from PaymentData XML for PayPal refunds with linked deposit |
| CC last 4 digits | @WithdrawToFundingCCLast4DigitsTbl | TVP correlated lookup | Masked card number suffix for credit card labels |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| prod-WithdrawNotif-func-ne (Azure function) | EXECUTE | Step 5 of 5 | Final step in withdrawal notification email pipeline. Called by WithdrawalServiceUser. |
| BOUserTaskScheduler | EXECUTE | Legacy caller | Legacy scheduler also has EXECUTE rights. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
prod-WithdrawNotif-func-ne (Azure function, every 5 min)
  -> ... (steps 1-4) ...
  -> BackOffice.GetPaymentsDetailsHTMLTable (step 5 - this SP)
     +-- Billing.WithdrawToFunding (table)
     +-- Billing.Funding (table)
     +-- Dictionary.FundingType (table)
     +-- Dictionary.Currency (table)
     +-- Dictionary.CardType (table)
     +-- Billing.Deposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | FROM clause; approved payment orders for the withdrawal |
| Billing.Funding | Table | INNER JOIN; FundingTypeID and FundingData XML |
| Dictionary.FundingType | Table | INNER JOIN; payment method type name |
| Dictionary.Currency | Table | INNER JOIN; currency display name/abbreviation |
| Dictionary.CardType | Table | LEFT JOIN (FundingTypeID=1 only); card brand name (Visa, MC, etc.) |
| Billing.Deposit | Table | LEFT JOIN (DepositID>0 only); PayPal payer name for linked deposits |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| prod-WithdrawNotif-func-ne | Azure function | Email body payment table data (step 5 of pipeline) |
| BackOffice.GetNotificationRecordsForProcessing | Stored Procedure | Called earlier in the same pipeline (step 2); see its documentation for full pipeline context |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CashoutStatusID = 3 | Business filter | Only approved payment orders included in email summary |
| OUTER subquery + GROUP BY | Aggregation | Inner SELECT builds per-row data; outer GROUP BY aggregates duplicate method+currency combos |
| CONVERT(varchar, SUM(Amount), 1) | Formatting | Style 1 = money format with commas ("1,234.56") for email display |
| FundingTypeID=1 card label | PCI design | CC last4 digits provided externally via TVP instead of joining card storage tables |
| XML value extraction | FundingData | Multiple XML path extractions from Billing.Funding.FundingData and Billing.Deposit.PaymentData |

---

## 8. Sample Queries

### 8.1 Execute for a completed withdrawal

```sql
DECLARE @CCDigits Billing.WithdrawToFundingCCLast4Digits;
-- Populate if credit card payments exist:
-- INSERT INTO @CCDigits VALUES (payment_order_id, 'last4');

EXEC BackOffice.GetPaymentsDetailsHTMLTable
    @WithdrawID = 9876543,
    @WithdrawToFundingCCLast4DigitsTbl = @CCDigits;
-- Returns: e.g., Method='Visa ..1234', Amount='1,234.56', Currency='USD'
```

### 8.2 Check approved payment orders for a withdrawal directly

```sql
SELECT bwtf.ID, bwtf.CashoutStatusID, bwtf.Amount, bwtf.ProcessCurrencyID,
       bwtf.RefundAmountInDepositCurrency, bwtf.ExchangeRate,
       f.FundingTypeID, ft.Name AS FundingTypeName
FROM Billing.WithdrawToFunding bwtf WITH (NOLOCK)
JOIN Billing.Funding f WITH (NOLOCK) ON f.FundingID = bwtf.FundingID
JOIN Dictionary.FundingType ft WITH (NOLOCK) ON ft.FundingTypeID = f.FundingTypeID
WHERE bwtf.WithdrawID = 9876543 AND bwtf.CashoutStatusID = 3;
```

---

## 9. Atlassian Knowledge Sources

- **Confluence** (indirect): "Task scheduler for sending Email" (page ID: 12562301093) - confirms this SP as step 5 in the `prod-WithdrawNotif-func-ne` Azure function pipeline for withdrawal notification emails. Full pipeline: AuditActionAdd -> GetNotificationRecordsForProcessing -> NotificationsUpdate -> GetWithdrawProcessEmailParams -> **GetPaymentsDetailsHTMLTable**.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 1 Confluence (indirect) + 0 Jira | Procedures: 2 app service consumers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetPaymentsDetailsHTMLTable | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetPaymentsDetailsHTMLTable.sql*
