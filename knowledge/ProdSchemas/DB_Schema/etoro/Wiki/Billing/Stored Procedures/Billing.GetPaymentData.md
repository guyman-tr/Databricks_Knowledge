# Billing.GetPaymentData

> Returns the payment-method junction record (the payment-to-instrument linkage row) for a given PaymentID, dispatching to the appropriate *ToPayment table based on FundingTypeID - the counterpart to GetPaymentDetails which returns the instrument master record.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 0-1 result sets: one row from the matching *ToPayment junction table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetPaymentData` retrieves the junction/linkage record that connects a specific payment to its payment instrument for a given funding type. In eToro's payment model, each Payment in `Billing.Payment` is linked to its specific instrument (credit card, bank transfer, e-wallet) via a junction table (e.g., `Billing.CreditCardToPayment`). This procedure provides that junction row - the "this payment was made using instrument X" record.

The procedure exists as a generic entry point for reading payment method data without the caller needing to know which junction table to query. Billing managers and BI analysts call it with a PaymentID and FundingTypeID to retrieve the instrument linkage details for that payment.

Data flows as follows: the caller already knows the PaymentID (e.g., from `Billing.Payment`) and the FundingTypeID (also available from `Billing.Payment`). The procedure dispatches to the correct junction table using IF/ELSE IF branches and returns the matching row. If the FundingTypeID does not match any handled case (e.g., ACH, types beyond 7), no result set is returned and RETURN 0 is issued.

---

## 2. Business Logic

### 2.1 Funding Type Dispatch (Junction Table Routing)

**What**: The procedure uses FundingTypeID to route to the correct payment-method junction table. Each funding type has a dedicated junction table storing the linkage between a Payment and the specific instrument used.

**Columns/Parameters Involved**: `@FundingTypeID`

**Rules**:
- FundingTypeID=1 (Credit Card): queries `Billing.CreditCardToPayment` (contains CardID, bin data, auth details)
- FundingTypeID=2 (Wire Transfer): queries `Billing.WireTransferToPayment`
- FundingTypeID=3 (PayPal): queries `Billing.PayPalToPayment`
- FundingTypeID=5 (Western Union): queries `Billing.WesternUnionToPayment`
- FundingTypeID=6 (Neteller): queries `Billing.NetellerToPayment`
- FundingTypeID=7 (1-Pay): queries `Billing.NetellerToPayment` (1-Pay shares Neteller infrastructure)
- Other FundingTypeIDs (e.g., ACH, modern methods): no result returned, RETURN 0

**Diagram**:
```
@PaymentID + @FundingTypeID
        |
  SWITCH FundingTypeID:
    1  -> SELECT * FROM Billing.CreditCardToPayment  WHERE PaymentID = @PaymentID
    2  -> SELECT * FROM Billing.WireTransferToPayment WHERE PaymentID = @PaymentID
    3  -> SELECT * FROM Billing.PayPalToPayment       WHERE PaymentID = @PaymentID
    5  -> SELECT * FROM Billing.WesternUnionToPayment WHERE PaymentID = @PaymentID
    6  -> SELECT * FROM Billing.NetellerToPayment     WHERE PaymentID = @PaymentID
    7  -> SELECT * FROM Billing.NetellerToPayment     WHERE PaymentID = @PaymentID
   else -> (no result set)
  RETURN 0
```

### 2.2 Relationship to GetPaymentDetails

**What**: `GetPaymentData` and `Billing.GetPaymentDetails` are complementary procedures that together expose the two layers of payment instrument data.

**Rules**:
- `GetPaymentData` (this procedure): returns the **junction record** (the *ToPayment row) - contains payment-specific transaction data like auth codes, amounts, timestamps
- `Billing.GetPaymentDetails`: returns the **instrument master record** (CreditCard, PayPal, Neteller) - contains static instrument data like card number hash, expiry, email
- Both accept the same signature (@PaymentID, @FundingTypeID) and are typically called together

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentID | INTEGER | NO | - | CODE-BACKED | Internal eToro payment identifier. PK of `Billing.Payment`. Used to filter the junction table to the specific payment's linkage record. |
| 2 | @FundingTypeID | INTEGER | NO | - | CODE-BACKED | Payment method type. Controls which junction table is queried. Values: 1=CreditCard (->CreditCardToPayment), 2=WireTransfer (->WireTransferToPayment), 3=PayPal (->PayPalToPayment), 5=WesternUnion (->WesternUnionToPayment), 6=Neteller (->NetellerToPayment), 7=1-Pay (->NetellerToPayment). Other values yield no result. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PaymentID | Billing.CreditCardToPayment.PaymentID | Lookup | FundingTypeID=1: filters junction table to this payment |
| @PaymentID | Billing.WireTransferToPayment.PaymentID | Lookup | FundingTypeID=2: filters junction table to this payment |
| @PaymentID | Billing.PayPalToPayment.PaymentID | Lookup | FundingTypeID=3: filters junction table to this payment |
| @PaymentID | Billing.WesternUnionToPayment.PaymentID | Lookup | FundingTypeID=5: filters junction table to this payment |
| @PaymentID | Billing.NetellerToPayment.PaymentID | Lookup | FundingTypeID=6/7: filters junction table to this payment |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BILLING_MANAGER | GRANT EXECUTE | Permission | Billing management role - payment investigation |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI admin role - reporting and analysis |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetPaymentData (procedure)
├── Billing.CreditCardToPayment (table - conditional, FundingTypeID=1)
├── Billing.WireTransferToPayment (table - conditional, FundingTypeID=2)
├── Billing.PayPalToPayment (table - conditional, FundingTypeID=3)
├── Billing.WesternUnionToPayment (table - conditional, FundingTypeID=5)
└── Billing.NetellerToPayment (table - conditional, FundingTypeID=6/7)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CreditCardToPayment | Table | Conditionally queried for FundingTypeID=1 |
| Billing.WireTransferToPayment | Table | Conditionally queried for FundingTypeID=2 |
| Billing.PayPalToPayment | Table | Conditionally queried for FundingTypeID=3 |
| Billing.WesternUnionToPayment | Table | Conditionally queried for FundingTypeID=5 |
| Billing.NetellerToPayment | Table | Conditionally queried for FundingTypeID=6 and 7 (1-Pay shares Neteller) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BILLING_MANAGER | DB Security Principal | EXECUTE permission - payment investigation queries |
| PROD_BIadmins | DB Security Principal | EXECUTE permission - BI admin analysis |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Notable**: FundingTypeID=7 (1-Pay) reuses `Billing.NetellerToPayment` - 1-Pay was an e-wallet service processed through the same Neteller infrastructure. FundingTypeIDs not in this list (e.g., ACH, newer payment methods added after this procedure was written) silently return no results.

---

## 8. Sample Queries

### 8.1 Get payment junction data for a credit card payment
```sql
-- FundingTypeID=1 = Credit Card
EXEC [Billing].[GetPaymentData]
    @PaymentID = 9876543,
    @FundingTypeID = 1
```

### 8.2 Get payment junction data for a Neteller payment
```sql
-- FundingTypeID=6 = Neteller
EXEC [Billing].[GetPaymentData]
    @PaymentID = 9876543,
    @FundingTypeID = 6
```

### 8.3 Use GetPaymentData alongside GetPaymentDetails for complete instrument picture
```sql
-- Step 1: Get PaymentID and FundingTypeID from Billing.Payment
SELECT PaymentID, FundingTypeID, Amount, PaymentStatusID
FROM Billing.Payment WITH (NOLOCK)
WHERE CID = 12345678
  AND PaymentStatusID = 2 -- Approved
ORDER BY PaymentDate DESC

-- Step 2: Call GetPaymentData for the junction record (instrument-to-payment linkage)
EXEC [Billing].[GetPaymentData] @PaymentID = 9876543, @FundingTypeID = 1

-- Step 3: Call GetPaymentDetails for the instrument master record (card/wallet details)
EXEC [Billing].[GetPaymentDetails] @PaymentID = 9876543, @FundingTypeID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.4/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetPaymentData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetPaymentData.sql*
