# Dictionary.Merchant

> Lookup table defining the payment processing companies (merchants/gateways) that handle deposit and withdrawal transactions on the eToro platform.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, PK CLUSTERED) |
| **Partition** | No — on PRIMARY |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.Merchant defines the payment gateway providers that process financial transactions for eToro. Each merchant represents a company that provides payment processing services — card processing (Checkout, WorldPay), e-wallet integration (PayPal, Neteller/PaySafe, Skrill), bank transfers (Trustly, RapidTransfer), and alternative payment methods (POLi, iDEAL, Giropay).

This table is the parent level of the payment routing hierarchy: Merchant → MerchantAccount → individual transactions. A single merchant (e.g., Checkout) can have multiple merchant accounts configured for different regions, regulations, or currencies (e.g., CheckoutEU, CheckoutUK, CheckoutAU).

The MerchantID is stored on deposit and payment records and used by the billing engine to route transactions to the correct payment processor.

---

## 2. Business Logic

### 2.1 Payment Gateway Routing

**What**: Each deposit/withdrawal is routed to a specific payment gateway based on the customer's payment method and region.

**Columns/Parameters Involved**: `ID`, `Name`, `Description`

**Rules**:
- Each FundingType (CreditCard, PayPal, Wire, etc.) maps to one or more merchants that can process it
- The billing engine selects the appropriate merchant based on funding type, region, and availability
- Merchant availability can change — payment gateways may be added, replaced, or deactivated
- A merchant can support multiple payment methods (e.g., Checkout processes both credit cards and alternative methods)

---

## 3. Data Overview

| ID | Name | Description | Meaning |
|---|---|---|---|
| 1 | Checkout | - | Checkout.com — primary credit card processing gateway. Handles card deposits/withdrawals for EU, UK, and global markets. |
| 2 | WorldPay | - | WorldPay (FIS) — secondary card processor. Provides geographic redundancy and specific market coverage (Australia, UK). |
| 4 | PayPal | - | PayPal e-wallet integration — handles PayPal deposits and withdrawals. Instant payment confirmation. |
| 7 | Trustly - IXOPAY-powercash | - | Trustly via IXOPAY aggregator — online banking payment method. Pay directly from bank account without card. |
| 9 | RapidTransfer | - | Rapid Transfer — online bank transfer service. Deposit-only, faster than traditional wire. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Payment gateway identifier. Key merchants: 1=Checkout, 2=WorldPay, 3=Neteller-PaySafe, 4=PayPal, 5=POLi, 6=iDEAL-IXOPAY-Worldpay, 7=Trustly-IXOPAY-powercash, 8=Skrill-PaySafe, 9=RapidTransfer, 10=Giropay-Sofort. |
| 2 | Name | varchar(100) | NO | - | CODE-BACKED | Payment gateway company/product name. Includes integration provider suffix for aggregated gateways (e.g., "Trustly - IXOPAY-powercash"). |
| 3 | Description | varchar(100) | YES | - | CODE-BACKED | Optional description. Currently NULL for all rows — name is self-descriptive. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.MerchantAccount | MerchantID | Implicit | Child table — each merchant has multiple regional accounts |
| Billing.Deposit | MerchantID | Implicit | Each deposit records which gateway processed it |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.Merchant (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.MerchantAccount | Table | References MerchantID as parent |
| Billing.Deposit | Table | Records processing merchant per transaction |
| Billing procedures | Stored Procedures | Route transactions to correct gateway |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.Merchant_New | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary.Merchant_New | PRIMARY KEY | Unique merchant, FILLFACTOR 95, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all merchants
```sql
SELECT  ID, Name, Description
FROM    Dictionary.Merchant WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Show merchants with their accounts
```sql
SELECT  m.Name              AS Merchant,
        ma.MerchantAccountID,
        ma.Name             AS AccountName,
        ma.BODescription
FROM    Dictionary.Merchant m WITH (NOLOCK)
JOIN    Dictionary.MerchantAccount ma WITH (NOLOCK)
        ON m.ID = ma.MerchantID
ORDER BY m.ID, ma.MerchantAccountID;
```

### 8.3 Count merchant accounts per gateway
```sql
SELECT  m.Name              AS Merchant,
        COUNT(*)            AS AccountCount
FROM    Dictionary.Merchant m WITH (NOLOCK)
JOIN    Dictionary.MerchantAccount ma WITH (NOLOCK)
        ON m.ID = ma.MerchantID
GROUP BY m.Name
ORDER BY COUNT(*) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Merchant | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Merchant.sql*
