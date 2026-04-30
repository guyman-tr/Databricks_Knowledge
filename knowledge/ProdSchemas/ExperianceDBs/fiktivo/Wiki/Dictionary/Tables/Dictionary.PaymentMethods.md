# Dictionary.PaymentMethods

> Lookup table defining the available methods for paying affiliate commissions, determining payment processing rules, fees, and settlement timelines.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PaymentMethodID (int IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.PaymentMethods defines the nine payment channels through which affiliate commissions can be disbursed. When an affiliate registers, they select a payment method and provide the corresponding payment details. The selected method determines processing fees, settlement timelines, geographic availability, and the data required from the affiliate.

Without this table, the payment system would not know how to route commission payouts. Each method has different integration requirements - PayPal uses email addresses, wire transfers need bank details, and China Union Pay has specific routing requirements.

This is static reference data with IDENTITY-generated IDs. The dbo.tblaff_PaymentDetails table stores PaymentMethodID for each affiliate's payment configuration. Multiple admin and KYP procedures reference this table.

---

## 2. Business Logic

### 2.1 Payment Channel Classification

**What**: Nine payment methods spanning electronic wallets, bank transfers, card payments, and platform credits.

**Columns/Parameters Involved**: `PaymentMethodID`, `Name`

**Rules**:
- ID=1 (None) means no payment method selected - commissions accumulate but are not paid until a method is configured
- Electronic wallets: PayPal (2), Neteller (5), Skrill (6), Webmoney (7) - fastest settlement, lower minimums
- Bank: Wire Transfer (3) - slower settlement, higher fees, no maximum limits
- Platform: eToro Trading Account (4) - commission credited directly, no external payout needed
- Card/Regional: Credit Card (8), China Union Pay (9) - specific to certain regions or affiliate preferences

---

## 3. Data Overview

| PaymentMethodID | Name | Meaning |
|---|---|---|
| 1 | None | No payment method configured. Commissions accrue but are not disbursed. Affiliate must select a method to receive payouts |
| 2 | PayPal | Commission paid via PayPal electronic transfer. Most popular method globally due to speed and simplicity. Affiliate provides PayPal email address |
| 3 | Wire Transfer | International bank wire transfer. Used for larger payouts where electronic wallets are impractical. Requires full banking details (SWIFT/IBAN) |
| 4 | eToro Trading Account | Commission credited directly to the affiliate's own eToro trading account. Zero external processing fees - funds are immediately available for trading |
| 9 | China Union Pay | Payment via China UnionPay network. Specifically for affiliates operating in the Chinese market or with CUP-compatible bank accounts |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentMethodID | int | NO | - | VERIFIED | Primary key (IDENTITY) identifying the payment method. Values: 1=None, 2=PayPal, 3=Wire Transfer, 4=eToro Trading Account, 5=Neteller, 6=Skrill, 7=Webmoney, 8=Credit Card, 9=China Union Pay. See [Payment Methods](../../_glossary.md#payment-methods) for full definitions. IDENTITY column - NOT FOR REPLICATION. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable label for the payment method. Used in admin UIs, payment processing screens, and affiliate self-service portals. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_PaymentDetails | PaymentMethodID | Implicit FK | Stores selected payment method for each affiliate |
| dbo.CreateAffiliate | Parameter | Lookup | Sets initial payment method during affiliate registration |
| AffiliateAdmin.UpdateInsertAffiliate | Parameter | Lookup | Updates payment method during admin edits |
| KYP.GetAffiliateData | JOIN | Lookup | Returns payment method in KYP data |
| KYP.UpdateAffiliateData | Parameter | Lookup | Updates payment method during KYP review |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_PaymentDetails | Table | Stores PaymentMethodID for each affiliate |
| dbo.CreateAffiliate | Stored Procedure | WRITER - sets payment method on creation |
| AffiliateAdmin.UpdateInsertAffiliate | Stored Procedure | MODIFIER - updates payment method |
| KYP.GetAffiliateData | Stored Procedure | READER - includes payment method |
| dbo.GetAffiliatesInfo | Stored Procedure | READER - returns affiliate payment info |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.PaymentMethods | CLUSTERED PK | PaymentMethodID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all payment methods
```sql
SELECT PaymentMethodID, Name
FROM Dictionary.PaymentMethods WITH (NOLOCK)
ORDER BY PaymentMethodID
```

### 8.2 Count affiliates by payment method
```sql
SELECT pm.PaymentMethodID, pm.Name, COUNT(*) AS AffiliateCount
FROM dbo.tblaff_PaymentDetails pd WITH (NOLOCK)
JOIN Dictionary.PaymentMethods pm WITH (NOLOCK) ON pd.PaymentMethodID = pm.PaymentMethodID
GROUP BY pm.PaymentMethodID, pm.Name
ORDER BY AffiliateCount DESC
```

### 8.3 Find affiliates with no payment method configured
```sql
SELECT pd.*
FROM dbo.tblaff_PaymentDetails pd WITH (NOLOCK)
WHERE pd.PaymentMethodID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PaymentMethods | Type: Table | Source: fiktivo/Dictionary/Tables/Dictionary.PaymentMethods.sql*
