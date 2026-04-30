# Dictionary.Merchant_Old

> Legacy payment merchant/PSP (Payment Service Provider) registry, superseded by Dictionary.Merchant. Retains historical merchant definitions for backward compatibility with older billing records.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.Merchant_Old is the deprecated predecessor of Dictionary.Merchant. It stores definitions of external payment service providers (PSPs) and payment gateways that the platform uses to process deposits and withdrawals. Each row represents a distinct merchant integration (e.g., Checkout, WorldPay, PayPal, Skrill).

This table still exists because historical billing records reference these merchant IDs. The active merchant table (Dictionary.Merchant) has a different structure with additional columns. Merchant_Old preserves the original IDs for referential integrity with archived transactions.

The table uses IDENTITY with NOT FOR REPLICATION, indicating it participates in database replication where IDs must be preserved across replicas. Currently contains 22 merchants spanning credit card processors, e-wallets, bank transfers, and crypto wallets.

---

## 2. Business Logic

### 2.1 Payment Method Coverage

**What**: Comprehensive registry of payment integration partners across multiple payment categories.

**Columns/Parameters Involved**: `ID`, `Name`, `Description`

**Rules**:
- IDs 1-14: Original payment methods (Checkout, WorldPay, PayPal, etc.)
- IDs 16-25: Newer payment methods added over time (Payoneer, OpenBanking, Ecommpay)
- ID 15 is missing — likely a deleted or never-used merchant
- ID 11 (eToroMoney) and ID 24 (eToroCryptoWallet) are internal eToro payment rails
- Description column is largely NULL — only a few entries have descriptions (Wire="WireTransfer", eToroOptions="eToro Options")

---

## 3. Data Overview

| ID | Name | Description | Meaning |
|---|---|---|---|
| 1 | Checkout | NULL | Credit card processing via Checkout.com — one of the primary card payment gateways |
| 4 | PayPal | NULL | PayPal e-wallet integration for deposits and withdrawals |
| 11 | eToroMoney | NULL | Internal eToro Money wallet — inter-product transfers between trading platform and eToro Money app |
| 20 | Wire | WireTransfer | Bank wire transfer processing for large deposits/withdrawals, typically used by high-value customers |
| 24 | eToroCryptoWallet | eToroCryptoWallet | Crypto wallet integration for transferring crypto assets between trading platform and eToro crypto wallet |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int (IDENTITY) | NO | - | CODE-BACKED | Auto-incrementing primary key. NOT FOR REPLICATION ensures ID consistency across database replicas. Values 1-25 (with gaps). Referenced by historical billing records as the merchant identifier. |
| 2 | Name | varchar(100) | NO | - | VERIFIED | Short name identifying the payment provider or integration: Checkout, WorldPay, PayPal, Skrill, Wire, eToroMoney, etc. Used in billing reports and payment routing logic. |
| 3 | Description | varchar(100) | YES | - | CODE-BACKED | Optional longer description of the merchant. Mostly NULL — only populated for Wire ("WireTransfer"), eToroOptions ("eToro Options"), and eToroCryptoWallet. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Historical billing records | MerchantID | Implicit | Legacy billing transactions reference this table for merchant identification |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Merchant | Table | Successor table — new merchants are added there |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary.Merchant | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None beyond PK. Note: PK constraint name retains the original "Dictionary.Merchant" name from before the table was renamed.

---

## 8. Sample Queries

### 8.1 List all legacy merchants
```sql
SELECT  ID,
        Name,
        Description
FROM    [Dictionary].[Merchant_Old] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find merchants with descriptions
```sql
SELECT  ID,
        Name,
        Description
FROM    [Dictionary].[Merchant_Old] WITH (NOLOCK)
WHERE   Description IS NOT NULL
ORDER BY ID;
```

### 8.3 Compare old vs new merchant tables
```sql
SELECT  'Old' AS Source, ID, Name
FROM    [Dictionary].[Merchant_Old] WITH (NOLOCK)
UNION ALL
SELECT  'New' AS Source, MerchantID, MerchantName
FROM    [Dictionary].[Merchant] WITH (NOLOCK)
ORDER BY Source, ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Merchant_Old | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Merchant_Old.sql*
