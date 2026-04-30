# Dictionary.AssetTypes

> Lookup table distinguishing between native blockchain coins and token-based assets (e.g., ERC-20), used to determine transaction handling and address resolution logic.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) + 1 unique constraint (Name) |

---

## 1. Business Meaning

This table classifies cryptocurrency assets into two fundamental categories: native coins and tokens. This distinction is critical because coins and tokens require fundamentally different handling for address resolution, transaction construction, fee calculation, and blockchain interaction.

A native coin (e.g., BTC, ETH, LTC) has its own blockchain, while a token (e.g., USDT, LINK, UNI as ERC-20) runs on top of another blockchain. The platform must know this distinction to select the correct transaction handling logic, fee structure, and address validation.

The table is FK-referenced by `Wallet.CryptoTypes`, which stores the master list of all supported cryptocurrencies. Each crypto in the system has an `AssetTypeId` that points back to this table.

---

## 2. Business Logic

### 2.1 Asset Type Determines Transaction Handling

**What**: The asset type dictates which blockchain interaction layer is used for transactions.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Coin` (1): Native blockchain asset with its own chain. Transactions are submitted directly to the asset's blockchain. Address formats are chain-specific. Gas/fee calculations use the native coin's fee model.
- `ERC20` (2): Token running on the Ethereum blockchain (or compatible EVM chain). Transactions are smart contract interactions, not simple transfers. Gas fees are paid in ETH (not the token itself). Address format is always Ethereum-compatible.

**Diagram**:
```
Crypto Asset
    |
    +---> Coin (1):  BTC, ETH, LTC, XRP, etc.
    |       Native chain, own fee model, chain-specific addresses
    |
    +---> ERC20 (2): USDT, LINK, UNI, etc.
            Token contract on Ethereum, gas in ETH, ETH address format
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | Coin | Native blockchain cryptocurrency with its own chain. Examples: Bitcoin (BTC), Ethereum (ETH), Litecoin (LTC). Each has unique address formats, consensus mechanisms, and fee models. Transaction logic is blockchain-specific. |
| 2 | ERC20 | Token built on the Ethereum blockchain following the ERC-20 standard. Examples: USDT (Tether), LINK (Chainlink), UNI (Uniswap). All share Ethereum addresses and require ETH for gas fees. Transactions are smart contract calls to the token contract's `transfer` function. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the asset type. Values: 1=Coin, 2=ERC20. FK target for Wallet.CryptoTypes.AssetTypeId, which classifies every supported cryptocurrency. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Unique label for the asset type. Used in application logic to branch transaction handling between native coin and token flows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.CryptoTypes | AssetTypeId | FK | Every supported cryptocurrency is classified as Coin or ERC20 |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FK on AssetTypeId - classifies each crypto asset |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AssetTypes | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UQ_AssetTypes_Name | UNIQUE | Name - Ensures no duplicate asset type names |

---

## 8. Sample Queries

### 8.1 List all asset types
```sql
SELECT Id, Name
FROM Dictionary.AssetTypes WITH (NOLOCK)
ORDER BY Id
```

### 8.2 Count cryptocurrencies by asset type
```sql
SELECT at.Name AS AssetType, COUNT(ct.CryptoTypeId) AS CryptoCount
FROM Dictionary.AssetTypes at WITH (NOLOCK)
LEFT JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.AssetTypeId = at.Id
GROUP BY at.Name
ORDER BY at.Name
```

### 8.3 List all ERC-20 tokens supported by the platform
```sql
SELECT ct.CryptoTypeId, ct.Name AS TokenName, at.Name AS AssetType
FROM Wallet.CryptoTypes ct WITH (NOLOCK)
JOIN Dictionary.AssetTypes at WITH (NOLOCK) ON ct.AssetTypeId = at.Id
WHERE at.Id = 2 -- ERC20
ORDER BY ct.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AssetTypes | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.AssetTypes.sql*
