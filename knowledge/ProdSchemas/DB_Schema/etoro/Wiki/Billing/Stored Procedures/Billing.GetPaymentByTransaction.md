# Billing.GetPaymentByTransaction

> Retrieves full payment details for a specific provider transaction reference (TransactionID), returning a payment header row plus the payment-method-specific detail rows for that customer - used by billing managers and BI to investigate a payment by its external transaction ID.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 2-3 result sets: Billing.Payment row + payment-method detail rows depending on FundingTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetPaymentByTransaction` is a lookup procedure that resolves an external transaction reference code (TransactionID, a CHAR(6) identifier assigned by the payment provider) to the internal eToro payment record, then returns that payment's full header plus the associated payment-method-specific details. It answers the question: "Given this provider transaction reference for this customer, what payment was it, and what do we know about the instrument used?"

The procedure exists to support billing manager investigations and BI analysis. When a customer reports a payment issue referencing a provider transaction ID, or when BI analysts need to trace a specific transaction, this procedure bridges the external TransactionID (stored in History.PaymentAction) to the internal Billing.Payment record and its detail tables (credit card, PayPal, WireTransfer, WesternUnion).

Data flows as follows: the caller provides a TransactionID (from an external payment provider confirmation or a History.PaymentAction record) and a CID for security scoping. The procedure first joins `Billing.Payment` and `History.PaymentAction` to resolve the PaymentID and FundingTypeID. It then returns the payment header, followed by one or more additional result sets from the appropriate payment-method detail table (CreditCardToPayment/CreditCard, WireTransferToPayment, PayPalToPayment/PayPal, or WesternUnionToPayment) depending on the funding type.

---

## 2. Business Logic

### 2.1 Polymorphic Result Sets by Funding Type

**What**: The procedure returns different sets of additional rows depending on the payment method used, enabling the caller to see the full instrument details without knowing the funding type in advance.

**Columns/Parameters Involved**: `@FundingTypeID` (local variable from first query), `Billing.Payment.FundingTypeID`

**Rules**:
- FundingTypeID=1 (Credit Card): returns `Billing.CreditCardToPayment` row by PaymentID + `Billing.CreditCard` row by CardID
- FundingTypeID=2 (Wire Transfer): returns `Billing.WireTransferToPayment` by PaymentID + `Billing.WireTransferToPayment` by WireTransferID (two queries on same table with different filters)
- FundingTypeID=3 (PayPal): returns `Billing.PayPalToPayment` by PaymentID + `Billing.PayPal` by PayPalID
- FundingTypeID=5 (Western Union): returns `Billing.WesternUnionToPayment` by PaymentID + `Billing.WesternUnionToPayment` by WesternUnionID
- FundingTypeID=4 (Neteller) and all other types: only the Payment header is returned (no additional result set)

**Diagram**:
```
@TransactionID + @CID
        |
        v
  JOIN Billing.Payment + History.PaymentAction
        |
        v
  Result Set 1: Billing.Payment (header - always returned)
        |
        v
  SWITCH on FundingTypeID:
    =1 (CC)  -> CreditCardToPayment + CreditCard
    =2 (Wire)-> WireTransferToPayment (by PaymentID)
               WireTransferToPayment (by WireTransferID)
    =3 (PPal)-> PayPalToPayment + PayPal
    =5 (WU)  -> WesternUnionToPayment (by PaymentID)
               WesternUnionToPayment (by WesternUnionID)
    other   -> (no additional result set)
```

### 2.2 TransactionID Resolution via History.PaymentAction

**What**: TransactionID is an external provider reference stored in History.PaymentAction (the audit/action log schema), not in Billing.Payment directly. The procedure uses an old-style implicit join to resolve it.

**Columns/Parameters Involved**: `@TransactionID`, `History.PaymentAction.TransactionID`, `Billing.Payment.PaymentID`

**Rules**:
- The join `FROM Billing.Payment BPAM, History.PaymentAction BPMA WHERE BPAM.PaymentID = BPMA.PaymentID` uses implicit (comma-join) syntax - an older coding style
- If no matching TransactionID+CID is found, @PaymentID remains NULL and the subsequent SELECT from Billing.Payment returns 0 rows; no error is raised
- The CID filter (`BPAM.CID = @CID`) provides a security scope - callers cannot retrieve payments for a different customer using a known TransactionID

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TransactionID | CHAR(6) | NO | - | CODE-BACKED | External payment provider transaction reference code. Stored in `History.PaymentAction.TransactionID`. CHAR(6) reflects legacy provider format. The procedure uses this to look up the internal `Billing.Payment.PaymentID`. |
| 2 | @CID | INTEGER | NO | - | CODE-BACKED | Customer identifier used as a security scope filter. Ensures the TransactionID resolves only to payments belonging to this customer, preventing cross-customer data exposure. |

**Return columns (Result Set 1 - Billing.Payment header, always returned):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | PaymentID | INTEGER | NO | - | CODE-BACKED | Internal eToro payment identifier. PK of Billing.Payment. |
| 4 | CurrencyID | - | - | - | CODE-BACKED | Currency of the payment. FK to Dictionary.Currency. |
| 5 | CID | INTEGER | - | - | CODE-BACKED | Customer identifier confirming the payment owner. |
| 6 | PaymentStatusID | - | - | - | CODE-BACKED | Current payment status. FK to Dictionary.PaymentStatus (1=New, 2=Approved, 3=Declined, etc.). |
| 7 | PaymentTypeID | - | - | - | CODE-BACKED | Type of payment (deposit/withdrawal direction indicator). FK to Dictionary.PaymentType. |
| 8 | FundingTypeID | - | - | - | CODE-BACKED | Payment method type (1=CreditCard, 2=WireTransfer, 3=PayPal, 5=WesternUnion, etc.). Determines which additional result set follows. |
| 9 | TerminalID | - | - | - | CODE-BACKED | Processing terminal/MID that handled this payment. FK to Billing.Terminal. |
| 10 | Amount | - | - | - | CODE-BACKED | Payment amount in the payment's currency. |
| 11 | ExchangeRate | - | - | - | CODE-BACKED | Exchange rate applied if currency conversion was needed. |
| 12 | TotalFee | - | - | - | CODE-BACKED | Total fee charged for this payment. |
| 13 | DirectAcceptFee | - | - | - | CODE-BACKED | Fee for direct acceptance processing. |
| 14 | PaymentDate | - | - | - | CODE-BACKED | Timestamp when the payment was recorded. |
| 15 | TransactionID | - | - | - | CODE-BACKED | External provider transaction reference echoed back from Billing.Payment (may differ from History.PaymentAction.TransactionID in edge cases). |
| 16 | IPAddress | - | - | - | CODE-BACKED | Customer IP address at time of payment submission. Used for fraud/geo analysis. |

**Result sets 2+ vary by FundingTypeID - see Section 2.1.**

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TransactionID | History.PaymentAction.TransactionID | Lookup | Resolves external transaction reference to internal PaymentID |
| @CID | Billing.Payment.CID | Filter | Security scope - limits results to the specified customer |
| (JOIN) | Billing.Payment | JOIN | Primary payment header data source |
| (JOIN) | History.PaymentAction | JOIN | Cross-schema join to resolve TransactionID -> PaymentID |
| (conditional) | Billing.CreditCardToPayment | Lookup | FundingTypeID=1: returns CC-to-payment linkage |
| (conditional) | Billing.CreditCard | Lookup | FundingTypeID=1: returns credit card instrument details |
| (conditional) | Billing.WireTransferToPayment | Lookup | FundingTypeID=2: returns wire transfer details (queried twice) |
| (conditional) | Billing.PayPalToPayment | Lookup | FundingTypeID=3: returns PayPal-to-payment linkage |
| (conditional) | Billing.PayPal | Lookup | FundingTypeID=3: returns PayPal instrument details |
| (conditional) | Billing.WesternUnionToPayment | Lookup | FundingTypeID=5: returns WU details (queried twice) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BILLING_MANAGER | GRANT EXECUTE | Permission | Billing management role uses for payment investigation |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI admin role uses for reporting and data analysis |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetPaymentByTransaction (procedure)
├── Billing.Payment (table)
├── History.PaymentAction (table - cross-schema)
├── Billing.CreditCardToPayment (table - conditional, FundingTypeID=1)
├── Billing.CreditCard (table - conditional, FundingTypeID=1)
├── Billing.WireTransferToPayment (table - conditional, FundingTypeID=2)
├── Billing.PayPalToPayment (table - conditional, FundingTypeID=3)
├── Billing.PayPal (table - conditional, FundingTypeID=3)
└── Billing.WesternUnionToPayment (table - conditional, FundingTypeID=5)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Payment | Table | Primary data source; header row returned unconditionally |
| History.PaymentAction | Table | Cross-schema; joined to resolve @TransactionID to PaymentID |
| Billing.CreditCardToPayment | Table | Conditionally queried for FundingTypeID=1 |
| Billing.CreditCard | Table | Conditionally queried for FundingTypeID=1 |
| Billing.WireTransferToPayment | Table | Conditionally queried for FundingTypeID=2 (queried twice) |
| Billing.PayPalToPayment | Table | Conditionally queried for FundingTypeID=3 |
| Billing.PayPal | Table | Conditionally queried for FundingTypeID=3 |
| Billing.WesternUnionToPayment | Table | Conditionally queried for FundingTypeID=5 (queried twice) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BILLING_MANAGER | DB Security Principal | EXECUTE permission - billing management investigation queries |
| PROD_BIadmins | DB Security Principal | EXECUTE permission - BI admin analysis |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Notable**: The first SELECT uses old-style implicit (comma) JOIN syntax. FundingTypeID=4 (Neteller) is not handled by any IF branch - callers receive only the Payment header for Neteller payments. RETURN 0 at the end returns a success code.

---

## 8. Sample Queries

### 8.1 Execute for a known TransactionID and CID (credit card payment)
```sql
-- Returns: Billing.Payment header + CreditCardToPayment + CreditCard rows
EXEC [Billing].[GetPaymentByTransaction]
    @TransactionID = 'ABC123',
    @CID = 12345678
```

### 8.2 Find PaymentActions with TransactionIDs to use as test input
```sql
-- Find recent PaymentAction records with TransactionIDs for a customer
SELECT TOP 10
    PA.PaymentID,
    PA.TransactionID,
    PA.ActionDate,
    P.FundingTypeID,
    P.PaymentStatusID,
    P.Amount
FROM History.PaymentAction PA WITH (NOLOCK)
INNER JOIN Billing.Payment P WITH (NOLOCK)
    ON PA.PaymentID = P.PaymentID
WHERE P.CID = 12345678
  AND PA.TransactionID IS NOT NULL
  AND PA.TransactionID != ''
ORDER BY PA.ActionDate DESC
```

### 8.3 Understand what TransactionIDs exist per funding type
```sql
-- Count payments with TransactionIDs by funding type
SELECT
    P.FundingTypeID,
    COUNT(DISTINCT PA.TransactionID) AS UniqueTransactionIDs,
    COUNT(*) AS TotalActions
FROM History.PaymentAction PA WITH (NOLOCK)
INNER JOIN Billing.Payment P WITH (NOLOCK)
    ON PA.PaymentID = P.PaymentID
WHERE PA.TransactionID IS NOT NULL
  AND LEN(PA.TransactionID) = 6
GROUP BY P.FundingTypeID
ORDER BY TotalActions DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetPaymentByTransaction | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetPaymentByTransaction.sql*
