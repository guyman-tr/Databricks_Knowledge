# Billing.GetPaymentDetails

> Returns the payment instrument master record (the credit card, PayPal account, Neteller wallet, or wire transfer details) for a given PaymentID, dispatching to the instrument table via the *ToPayment junction - the counterpart to GetPaymentData which returns the junction row itself.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 0-1 result sets: one row from the instrument master table (CreditCard, PayPal, Neteller, or WireTransferToPayment) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetPaymentDetails` retrieves the full instrument master record for the payment method used in a specific payment. Where `Billing.GetPaymentData` returns the junction/linkage record (the *ToPayment row that links the payment to its instrument), this procedure traverses through that junction to return the instrument entity itself - the credit card record, the PayPal account record, or the Neteller wallet record with all stored instrument attributes.

The procedure exists to provide a single entry point for instrument data retrieval regardless of payment method type. Billing managers use it to see full card/wallet details for a payment (e.g., card expiry, BIN country, PayPal email) without needing to query the junction table first.

Data flows as follows: the caller provides a PaymentID and FundingTypeID. The procedure uses a subquery through the junction table (*ToPayment) to find the instrument ID (CardID, PayPalID, NetellerID), then returns the full instrument master row. For WireTransfer (FundingTypeID=2), the *ToPayment table itself contains all transfer details, so it returns that directly.

---

## 2. Business Logic

### 2.1 Funding Type Dispatch (Instrument Table Routing)

**What**: The procedure routes to the instrument master table for the funding type, using the *ToPayment junction to resolve PaymentID -> instrument ID -> instrument record.

**Columns/Parameters Involved**: `@FundingTypeID`

**Rules**:
- FundingTypeID=1 (Credit Card): finds CardID via CreditCardToPayment subquery, returns `Billing.CreditCard` master row
- FundingTypeID=2 (Wire Transfer): returns `Billing.WireTransferToPayment` directly (no separate instrument master table for wire transfers)
- FundingTypeID=3 (PayPal): finds PayPalID via PayPalToPayment subquery, returns `Billing.PayPal` master row
- FundingTypeID=5 (Western Union): returns `Billing.WesternUnionToPayment` directly (same pattern as wire transfer)
- FundingTypeID=6 (Neteller): finds NetellerID via NetellerToPayment subquery, returns `Billing.Neteller` master row
- FundingTypeID=7 (1-Pay): same as Neteller - finds NetellerID via NetellerToPayment, returns `Billing.Neteller` master row
- Other FundingTypeIDs: no result returned

**Diagram**:
```
@PaymentID + @FundingTypeID
        |
  SWITCH FundingTypeID:
    1  -> CreditCardToPayment (subquery for CardID)
           -> SELECT * FROM Billing.CreditCard WHERE CardID IN (...)
    2  -> SELECT * FROM Billing.WireTransferToPayment WHERE PaymentID = @PaymentID
    3  -> PayPalToPayment (subquery for PayPalID)
           -> SELECT * FROM Billing.PayPal WHERE PayPalID IN (...)
    5  -> SELECT * FROM Billing.WesternUnionToPayment WHERE PaymentID = @PaymentID
    6  -> NetellerToPayment (subquery for NetellerID)
           -> SELECT * FROM Billing.Neteller WHERE NetellerID IN (...)
    7  -> NetellerToPayment (subquery for NetellerID)
           -> SELECT * FROM Billing.Neteller WHERE NetellerID IN (...)
   else -> (no result set)
  RETURN 0
```

### 2.2 Relationship to GetPaymentData

**What**: These two procedures are designed to be called together to retrieve the full two-layer picture of a payment instrument.

**Rules**:
- `Billing.GetPaymentData`: returns the junction record (*ToPayment) - payment-specific transaction linkage data
- `GetPaymentDetails` (this procedure): returns the instrument master - static account/card/wallet attributes
- WireTransfer and WesternUnion have no separate instrument master table; both procedures return the *ToPayment row for those types
- For CreditCard, PayPal, and Neteller, the two procedures return different rows from different tables

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentID | INTEGER | NO | - | CODE-BACKED | Internal eToro payment identifier. PK of `Billing.Payment`. Used to navigate through the junction table to find the instrument ID. |
| 2 | @FundingTypeID | INTEGER | NO | - | CODE-BACKED | Payment method type controlling instrument table routing. Values: 1=CreditCard (->Billing.CreditCard via CreditCardToPayment), 2=WireTransfer (->WireTransferToPayment), 3=PayPal (->Billing.PayPal via PayPalToPayment), 5=WesternUnion (->WesternUnionToPayment), 6=Neteller (->Billing.Neteller via NetellerToPayment), 7=1-Pay (->Billing.Neteller via NetellerToPayment). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PaymentID | Billing.CreditCardToPayment | Lookup | FundingTypeID=1: subquery to resolve PaymentID -> CardID |
| @PaymentID | Billing.CreditCard | Lookup | FundingTypeID=1: instrument master returned |
| @PaymentID | Billing.WireTransferToPayment | Lookup | FundingTypeID=2: junction table returned directly (no separate master) |
| @PaymentID | Billing.PayPalToPayment | Lookup | FundingTypeID=3: subquery to resolve PaymentID -> PayPalID |
| @PaymentID | Billing.PayPal | Lookup | FundingTypeID=3: instrument master returned |
| @PaymentID | Billing.WesternUnionToPayment | Lookup | FundingTypeID=5: junction table returned directly |
| @PaymentID | Billing.NetellerToPayment | Lookup | FundingTypeID=6/7: subquery to resolve PaymentID -> NetellerID |
| @PaymentID | Billing.Neteller | Lookup | FundingTypeID=6/7: instrument master returned |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BILLING_MANAGER | GRANT EXECUTE | Permission | Billing management role - payment investigation |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI admin role - reporting and analysis |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetPaymentDetails (procedure)
├── Billing.CreditCardToPayment (table - subquery, FundingTypeID=1)
├── Billing.CreditCard (table - result, FundingTypeID=1)
├── Billing.WireTransferToPayment (table - result, FundingTypeID=2)
├── Billing.PayPalToPayment (table - subquery, FundingTypeID=3)
├── Billing.PayPal (table - result, FundingTypeID=3)
├── Billing.WesternUnionToPayment (table - result, FundingTypeID=5)
├── Billing.NetellerToPayment (table - subquery, FundingTypeID=6/7)
└── Billing.Neteller (table - result, FundingTypeID=6/7)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CreditCardToPayment | Table | FundingTypeID=1: subquery to find CardID |
| Billing.CreditCard | Table | FundingTypeID=1: instrument master rows returned |
| Billing.WireTransferToPayment | Table | FundingTypeID=2: returned directly as instrument data |
| Billing.PayPalToPayment | Table | FundingTypeID=3: subquery to find PayPalID |
| Billing.PayPal | Table | FundingTypeID=3: instrument master rows returned |
| Billing.WesternUnionToPayment | Table | FundingTypeID=5: returned directly as instrument data |
| Billing.NetellerToPayment | Table | FundingTypeID=6/7: subquery to find NetellerID |
| Billing.Neteller | Table | FundingTypeID=6/7: instrument master rows returned |

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

**Notable**: WireTransfer (FundingTypeID=2) and WesternUnion (FundingTypeID=5) have no instrument master table - all data is in the *ToPayment table, so these cases are identical between GetPaymentData and GetPaymentDetails. FundingTypeID=7 (1-Pay) uses the Neteller infrastructure entirely.

---

## 8. Sample Queries

### 8.1 Get credit card instrument details for a payment
```sql
-- Returns the CreditCard master row (card hash, BIN, expiry, etc.)
EXEC [Billing].[GetPaymentDetails]
    @PaymentID = 9876543,
    @FundingTypeID = 1
```

### 8.2 Get Neteller wallet details for a payment
```sql
EXEC [Billing].[GetPaymentDetails]
    @PaymentID = 9876543,
    @FundingTypeID = 6
```

### 8.3 Compare junction data vs instrument master for the same payment
```sql
-- GetPaymentData: returns the junction linkage row
EXEC [Billing].[GetPaymentData] @PaymentID = 9876543, @FundingTypeID = 3   -- PayPal junction

-- GetPaymentDetails: returns the PayPal instrument master
EXEC [Billing].[GetPaymentDetails] @PaymentID = 9876543, @FundingTypeID = 3 -- PayPal master

-- Manual equivalent for PayPal:
SELECT pp.*
FROM Billing.PayPal pp WITH (NOLOCK)
WHERE pp.PayPalID IN (
    SELECT PayPalID FROM Billing.PayPalToPayment WITH (NOLOCK) WHERE PaymentID = 9876543
)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetPaymentDetails | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetPaymentDetails.sql*
