# Dictionary.MerchantAccount

> Lookup table defining the regional/entity-specific merchant accounts under each payment gateway, controlling which eToro entity processes each transaction.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MerchantAccountID (INT, PK CLUSTERED) |
| **Partition** | No — on PRIMARY |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.MerchantAccount defines the sub-accounts within each payment gateway (Merchant) that correspond to specific eToro legal entities or regional configurations. A single merchant like Checkout has multiple accounts — one for eToro EU, one for eToro UK, one for eToro Australia — each routing payments to the correct legal entity's bank account.

This level of granularity is essential for regulatory compliance: EU deposits must be processed through EU-licensed entities, UK deposits through FCA-regulated entities, Australian deposits through ASIC-regulated entities. The correct MerchantAccount ensures funds land in the right corporate bank account and are reported to the correct regulator.

The MerchantAccountID is stored on deposit records and used by the billing engine to select the correct processing account based on customer regulation, country, and payment method.

---

## 2. Business Logic

### 2.1 Regional Payment Routing

**What**: Each merchant account maps to a specific eToro legal entity and geographic scope.

**Columns/Parameters Involved**: `MerchantAccountID`, `MerchantID`, `Name`, `BODescription`

**Rules**:
- Account names encode the merchant + region: "CheckoutEUROW" = Checkout for EU Rest-of-World, "WorldpayAU" = Worldpay for Australia
- BODescription indicates the eToro entity: "eToroEU", "eToroUK", "eToroAU", "EMUK"
- Multiple accounts per merchant enable regulatory-compliant fund routing
- The billing engine selects MerchantAccountID based on: customer regulation + country + payment method

**Diagram**:
```
Dictionary.Merchant (parent)
  ├── Checkout (ID=1)
  │   ├── CheckoutEUROW (MerchantAccountID=1) → eToroEU
  │   ├── CheckoutEUEEA (ID=4) → eToroEU
  │   ├── CheckoutUKEEA (ID=5) → eToroUK
  │   ├── CheckoutEMUK (ID=6) → EMUK
  │   ├── CheckoutEU (ID=9) → eToroEU
  │   └── CheckoutUK (ID=10) → eToroUK
  └── WorldPay (ID=2)
      ├── CheckoutUKROW (ID=2) → eToroUK
      ├── WorldpayEU (ID=7) → eToroEU
      ├── WorldpayAU (ID=8) → eToroAU
      └── WorldpayUK (ID=11) → eToroUK
```

---

## 3. Data Overview

| MerchantAccountID | MerchantID | Name | BODescription | Meaning |
|---|---|---|---|---|
| 1 | 1 (Checkout) | CheckoutEUROW | eToroEU | Checkout account for EU customers in Rest-of-World countries — funds processed under eToro EU entity |
| 2 | 2 (WorldPay) | CheckoutUKROW | eToroUK | WorldPay account for UK Rest-of-World routing — funds under eToro UK entity |
| 8 | 2 (WorldPay) | WorldpayAU | eToroAU | WorldPay account for Australian customers — funds under ASIC-regulated eToro Australia entity |
| 9 | 1 (Checkout) | CheckoutEU | eToroEU | Primary Checkout account for EU deposits — standard European Economic Area processing |
| 10 | 1 (Checkout) | CheckoutUK | eToroUK | Primary Checkout account for UK deposits — FCA-regulated entity processing |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MerchantAccountID | int | NO | - | CODE-BACKED | Unique merchant account identifier. Each ID represents a specific gateway + entity combination used for payment processing. |
| 2 | MerchantID | int | NO | - | CODE-BACKED | Parent merchant/gateway: references Dictionary.Merchant.ID. Multiple accounts per merchant. 1=Checkout, 2=WorldPay, etc. |
| 3 | Name | varchar(100) | NO | - | CODE-BACKED | Account name encoding merchant + region: "CheckoutEU", "WorldpayAU", "CheckoutEMUK". Used as technical identifier in payment processing. |
| 4 | BODescription | varchar(100) | YES | - | CODE-BACKED | Back-office entity label: "eToroEU", "eToroUK", "eToroAU", "EMUK". Identifies which eToro legal entity receives the funds. Used in reconciliation and regulatory reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MerchantID | Dictionary.Merchant | Implicit | Parent payment gateway provider |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Deposit | MerchantAccountID | Implicit | Each deposit records which merchant account processed it |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.MerchantAccount (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Records MerchantAccountID per transaction |
| Billing.DepositUpdate | Stored Procedure | Updates MerchantAccountID on deposit records |
| Payment routing procedures | Stored Procedures | Select correct account based on regulation/region |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.MerchantAccount | CLUSTERED PK | MerchantAccountID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary.MerchantAccount | PRIMARY KEY | Unique merchant account, FILLFACTOR 95, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all merchant accounts with parent merchant
```sql
SELECT  ma.MerchantAccountID,
        m.Name              AS Merchant,
        ma.Name             AS AccountName,
        ma.BODescription    AS Entity
FROM    Dictionary.MerchantAccount ma WITH (NOLOCK)
JOIN    Dictionary.Merchant m WITH (NOLOCK)
        ON ma.MerchantID = m.ID
ORDER BY m.ID, ma.MerchantAccountID;
```

### 8.2 Find all accounts for a specific entity
```sql
SELECT  ma.MerchantAccountID,
        m.Name              AS Merchant,
        ma.Name             AS AccountName
FROM    Dictionary.MerchantAccount ma WITH (NOLOCK)
JOIN    Dictionary.Merchant m WITH (NOLOCK)
        ON ma.MerchantID = m.ID
WHERE   ma.BODescription = 'eToroEU'
ORDER BY m.Name, ma.Name;
```

### 8.3 Count accounts per entity
```sql
SELECT  BODescription       AS Entity,
        COUNT(*)            AS AccountCount
FROM    Dictionary.MerchantAccount WITH (NOLOCK)
GROUP BY BODescription
ORDER BY COUNT(*) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MerchantAccount | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.MerchantAccount.sql*
