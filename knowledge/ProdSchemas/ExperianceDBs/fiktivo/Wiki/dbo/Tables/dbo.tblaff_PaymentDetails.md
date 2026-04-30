# dbo.tblaff_PaymentDetails

> Affiliate payment method configurations storing bank, PayPal, Neteller, Skrill, credit card, and wire transfer details for commission payouts.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | PaymentDetailsID (BIGINT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered PK, 1 nonclustered on Username+PaymentMethodID) |

---

## 1. Business Meaning

This table stores the payment method details for affiliate commission payouts. Each row represents a complete set of payment information for a specific method (PayPal, wire transfer, credit card, Skrill, Neteller, WebMoney, China UnionPay). An affiliate can have up to 3 payment detail records (via tblaff_Affiliates.PaymentDetailsID, PaymentDetails2ID, PaymentDetails3ID).

Without this table, the platform could not process affiliate commission payments. When a payment batch is generated, the system reads the affiliate's active payment details to route the payment through the correct provider. Payment details must be verified by an admin user (VerifiedBy FK to tblaff_User) before payouts can be processed.

---

## 2. Business Logic

### 2.1 Multi-Method Payment Support

**What**: Each record supports exactly one payment method with method-specific fields populated accordingly.

**Columns/Parameters Involved**: `PaymentMethodID`, all Wire*, PayPal*, Neteller*, Moneybookers*, WebMoney*, CreditCard*, ChinaUnionPay* columns

**Rules**:
- PaymentMethodID determines which set of columns is relevant. See [Payment Methods](../../_glossary.md#payment-methods): 1=None, 2=PayPal, 3=Wire, 4=eToro Account, 5=Neteller, 6=Skrill, 7=Webmoney, 8=Credit Card, 9=China Union Pay
- Only the columns for the selected method are populated; others remain NULL
- Wire transfers have two tiers: primary bank (Wire*) and intermediary bank (Intermediary*) for international routing

### 2.2 Payment Verification

**What**: Payment details require admin verification before they can be used for payouts.

**Columns/Parameters Involved**: `VerifiedBy`, `VerifiedOn`

**Rules**:
- VerifiedBy (FK to tblaff_User) records which admin verified the payment details
- VerifiedOn records when the verification occurred
- Both default to NULL (unverified) - must be explicitly set by admin action

---

## 3. Data Overview

N/A - Payment details contain sensitive financial data (masked columns). See element descriptions.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentDetailsID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Referenced by tblaff_Affiliates.PaymentDetailsID/PaymentDetails2ID/PaymentDetails3ID and tblaff_PaymentHistory.PaymentDetailsID. |
| 2 | PaymentMethodID | tinyint | NO | 0 | CODE-BACKED | Payment method selector. See [Payment Methods](../../_glossary.md#payment-methods): 1=None, 2=PayPal, 3=Wire Transfer, 4=eToro Trading Account, 5=Neteller, 6=Skrill, 7=Webmoney, 8=Credit Card, 9=China Union Pay. |
| 3 | Amount | bigint | YES | - | NAME-INFERRED | Payment amount or limit associated with this payment detail record. |
| 4 | PayPalAccount | varchar(100) | YES | - | CODE-BACKED | PayPal email address for PayPal payments (PaymentMethodID=2). |
| 5 | WireBeneficiary | varchar(100) | YES | - | CODE-BACKED | Wire transfer beneficiary name (PaymentMethodID=3). |
| 6 | WireBankName | varchar(100) | YES | - | CODE-BACKED | Wire transfer bank name. |
| 7 | WireBankAddress | varchar(200) | YES | - | CODE-BACKED | Wire transfer bank address. |
| 8 | WireBranchNumber | varchar(50) | YES | - | CODE-BACKED | Wire transfer branch/routing number. |
| 9 | WireAccountNumber | varchar(100) | YES | - | CODE-BACKED | Wire transfer account number. |
| 10 | WireSwiftCode | varchar(100) | YES | - | CODE-BACKED | Wire transfer SWIFT/BIC code for international routing. |
| 11 | WireIBAN | varchar(200) | YES | - | CODE-BACKED | Wire transfer IBAN (International Bank Account Number). |
| 12 | Username | varchar(50) | YES | - | CODE-BACKED | General username field for e-wallet services. Indexed for lookups. |
| 13 | NetellerAccount | varchar(30) | YES | - | CODE-BACKED | Neteller account ID (PaymentMethodID=5). |
| 14 | NetellerEmail | varchar(100) | YES | - | CODE-BACKED | Neteller registered email address. |
| 15 | MoneybookersAccount | varchar(100) | YES | - | CODE-BACKED | Skrill (formerly Moneybookers) account ID (PaymentMethodID=6). |
| 16 | WebMoneyAccount | varchar(100) | YES | - | CODE-BACKED | WebMoney account ID (PaymentMethodID=7). |
| 17 | WebMoneyPurseID | varchar(100) | YES | - | CODE-BACKED | WebMoney purse identifier for specific currency wallets. |
| 18 | CreditCardNumber | varchar(100) | YES | - | CODE-BACKED | Credit card number (PaymentMethodID=8). MASKED with partial display (all X's). |
| 19 | CreditCardExpMonth | varchar(2) | YES | - | CODE-BACKED | Credit card expiration month (01-12). |
| 20 | CreditCardExpYear | varchar(4) | YES | - | CODE-BACKED | Credit card expiration year (4-digit). |
| 21 | PayeeID | nvarchar(50) | YES | - | CODE-BACKED | External payee identifier for payment processor integration. |
| 22 | IntermediaryBankName | varchar(100) | YES | - | CODE-BACKED | Intermediary/correspondent bank name for international wire transfers. MASKED. |
| 23 | IntermediaryBankAddress | varchar(200) | YES | - | CODE-BACKED | Intermediary bank address. MASKED. |
| 24 | IntermediaryAccountNumber | varchar(100) | YES | - | CODE-BACKED | Account number at the intermediary bank. |
| 25 | IntermediarySwiftCode | varchar(100) | YES | - | CODE-BACKED | SWIFT code of the intermediary bank. |
| 26 | IntermediaryIBAN | varchar(200) | YES | - | CODE-BACKED | IBAN at the intermediary bank. |
| 27 | VerifiedBy | int | YES | NULL | CODE-BACKED | FK to [dbo.tblaff_User](dbo.tblaff_User.md).UserID. Admin user who verified these payment details. NULL = unverified. |
| 28 | VerifiedOn | datetime | YES | NULL | CODE-BACKED | Timestamp when payment details were verified. NULL = unverified. |
| 29 | ChinaUnionPayBeneficiaryFullName | nvarchar(100) | YES | - | CODE-BACKED | China UnionPay beneficiary full name (PaymentMethodID=9). |
| 30 | ChinaUnionPayBankName | nvarchar(100) | YES | - | CODE-BACKED | China UnionPay bank name. |
| 31 | ChinaUnionPayBankAddress | nvarchar(200) | YES | - | CODE-BACKED | China UnionPay bank address. |
| 32 | ChinaUnionPayBranchNumber | nvarchar(50) | YES | - | CODE-BACKED | China UnionPay branch number. |
| 33 | ChinaUnionPayAccountNumber | nvarchar(100) | YES | - | CODE-BACKED | China UnionPay account number. |
| 34 | WireSortCode | nvarchar(100) | YES | - | CODE-BACKED | UK sort code for domestic wire transfers. |
| 35 | WireBankCountryID | int | YES | - | CODE-BACKED | Country of the wire transfer bank. References tblaff_Country for bank location. |
| 36 | WireRoutingNumber | nvarchar(100) | YES | - | CODE-BACKED | US ABA routing number for domestic wire transfers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| VerifiedBy | [dbo.tblaff_User](dbo.tblaff_User.md) | Explicit FK | Admin user who verified the payment details. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_Affiliates | PaymentDetailsID | Implicit FK | Primary payment details for the affiliate. |
| dbo.tblaff_Affiliates | PaymentDetails2ID | Implicit FK | Secondary payment details. |
| dbo.tblaff_Affiliates | PaymentDetails3ID | Implicit FK | Tertiary payment details. |
| dbo.tblaff_PaymentHistory | PaymentDetailsID | Implicit FK | Payment details used for a specific payout. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.tblaff_PaymentDetails (table)
+-- dbo.tblaff_User (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [dbo.tblaff_User](dbo.tblaff_User.md) | Table | FK: VerifiedBy |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | PaymentDetailsID/2ID/3ID reference this |
| dbo.tblaff_PaymentHistory | Table | PaymentDetailsID reference |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_tblaff_PaymentDetails | CLUSTERED PK | PaymentDetailsID | - | - | Active |
| tblaff_PaymentDetails_PaymentDetailsID | NC | Username, PaymentMethodID | PaymentDetailsID | - | Active (PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_PaymentDetails_PaymentMethodID | DEFAULT | 0 (None) |
| DF_tblaff_PaymentDetails_VerifiedBy | DEFAULT | NULL (unverified) |
| DF_tblaff_PaymentDetails_VerifiedOn | DEFAULT | NULL (unverified) |
| FK_VerifiedBy | FOREIGN KEY | VerifiedBy -> dbo.tblaff_User.UserID |

---

## 8. Sample Queries

### 8.1 Find payment details for an affiliate
```sql
SELECT pd.PaymentDetailsID, pm.Name AS PaymentMethod, pd.VerifiedBy, pd.VerifiedOn
FROM dbo.tblaff_PaymentDetails pd WITH (NOLOCK)
JOIN Dictionary.PaymentMethods pm WITH (NOLOCK) ON pd.PaymentMethodID = pm.PaymentMethodID
WHERE pd.PaymentDetailsID IN (
    SELECT PaymentDetailsID FROM dbo.tblaff_Affiliates WITH (NOLOCK) WHERE AffiliateID = 100
)
```

### 8.2 Count payment details by method
```sql
SELECT pm.Name AS PaymentMethod, COUNT(*) AS DetailCount
FROM dbo.tblaff_PaymentDetails pd WITH (NOLOCK)
JOIN Dictionary.PaymentMethods pm WITH (NOLOCK) ON pd.PaymentMethodID = pm.PaymentMethodID
GROUP BY pm.Name
ORDER BY DetailCount DESC
```

### 8.3 Find unverified payment details
```sql
SELECT pd.PaymentDetailsID, pd.PaymentMethodID, pd.Username
FROM dbo.tblaff_PaymentDetails pd WITH (NOLOCK)
WHERE pd.VerifiedBy IS NULL
  AND pd.PaymentMethodID > 1
ORDER BY pd.PaymentDetailsID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 9.7/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 35 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_PaymentDetails | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_PaymentDetails.sql*
