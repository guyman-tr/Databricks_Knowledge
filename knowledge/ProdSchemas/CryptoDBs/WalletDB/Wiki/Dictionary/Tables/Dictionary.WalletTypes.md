# Dictionary.WalletTypes

> Lookup table classifying wallets by their operational purpose - redeem, conversion, funding, payment, customer, crypto-to-fiat, or staking refund.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) + 1 unique (Name) |

---

## 1. Business Meaning

This table classifies wallets by their operational purpose. Different types of crypto operations require different wallets - a customer's personal wallet is separate from the platform's operational wallets used for redemption processing, conversion execution, or funding operations.

FK-referenced by `Wallet.Wallets`. Consumed by internal wallet management SPs.

---

## 2. Business Logic

### 2.1 Wallet Purpose Classification

**What**: Seven wallet types serving distinct operational roles.

**Rules**:
- `Redeem` (1): Wallets used for processing crypto redemption (sell) operations
- `Conversion` (2): Wallets used for crypto-to-crypto conversion operations
- `Funding` (3): Wallets used for funding customer wallets from platform reserves
- `Payment` (4): Wallets used for fiat payment processing operations
- `Customer` (5): Customer-facing personal wallets where customers hold their crypto
- `C2F` (6): Crypto-to-Fiat wallets for off-ramp operations
- `StakingRefund` (7): Wallets used for returning staked crypto and staking rewards

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | Redeem | Platform operational wallets for redemption processing. When a customer sells crypto, the proceeds flow through redeem wallets. |
| 2 | Conversion | Platform operational wallets for swap operations. Hold crypto temporarily during the conversion execution window. |
| 5 | Customer | Customer-facing personal wallets. Each customer has wallets of this type for each supported cryptocurrency they hold. The primary wallet type visible to customers. |
| 6 | C2F | Crypto-to-Fiat off-ramp wallets. Receive crypto that is being converted to fiat currency for customer withdrawal. |
| 7 | StakingRefund | Wallets for returning staked assets and distributing staking rewards back to customers. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier. Values: 1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 5=Customer, 6=C2F, 7=StakingRefund. FK target for Wallet.Wallets.WalletTypeId. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Unique wallet type label. Used in wallet management logic to route operations to the correct wallet type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.Wallets | WalletTypeId | FK | Classifies each wallet by operational purpose |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Wallets | Table | FK on WalletTypeId |
| Wallet.GetInternalWallets | Stored Procedure | Filters by wallet type |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WalletTypes | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UQ_WalletTypes_Name | UNIQUE | Name - Ensures no duplicate wallet type names |

---

## 8. Sample Queries

### 8.1 List all wallet types
```sql
SELECT Id, Name FROM Dictionary.WalletTypes WITH (NOLOCK) ORDER BY Id
```

### 8.2 Count wallets by type
```sql
SELECT wt.Name, COUNT(w.WalletId) AS Count
FROM Dictionary.WalletTypes wt WITH (NOLOCK)
LEFT JOIN Wallet.Wallets w WITH (NOLOCK) ON w.WalletTypeId = wt.Id
GROUP BY wt.Name ORDER BY Count DESC
```

### 8.3 Customer wallets only
```sql
SELECT w.WalletId, wt.Name AS Type FROM Wallet.Wallets w WITH (NOLOCK)
JOIN Dictionary.WalletTypes wt WITH (NOLOCK) ON w.WalletTypeId = wt.Id
WHERE wt.Id = 5 -- Customer
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.WalletTypes | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.WalletTypes.sql*
