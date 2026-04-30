# Wallet.AddressResolverProviderContracts

> Maps each cryptocurrency to its blockchain-specific address resolver provider, determining which validation service handles address format checking for each crypto asset.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC UNIQUE + 1 clustered PK |

---

## 1. Business Meaning

This table maps each supported cryptocurrency to its address resolver provider - the service that validates and normalizes blockchain addresses for that crypto. Each blockchain has a different address format (Bitcoin uses base58/bech32, Ethereum uses hex, XRP uses base58check with tags, etc.), and the address resolver provider understands the specific format rules. With 12 rows matching the 12 supported blockchains, this is a small configuration table.

See [Address Resolver Provider](../../_glossary.md#address-resolver-provider) for provider definitions. FK to Dictionary.AddressResolverProviders and Wallet.CryptoTypes.

---

## 2. Business Logic

No complex logic. Simple 1:1 mapping between crypto and address resolver implementation.

---

## 3. Data Overview

| Id | CryptoId | AddressResolverProviderId | Meaning |
|---|---|---|---|
| 1 | 1 (BTC) | 2 (BitcoinAddressResolverProvider) | Bitcoin addresses validated by dedicated BTC resolver |
| 3 | 2 (ETH) | 5 (EthAddressResolverProvider) | Ethereum addresses validated by ETH resolver (also handles ERC-20) |
| 6 | 4 (XRP) | 6 (RippleAddressResolverProvider) | XRP addresses with destination tag support |
| 13 | 64 (SOL) | 1 (CryptoAddressResolverBaseProvider) | Solana uses the base/generic resolver (newest chain) |
| 9 | 27 (TRX) | 1 (CryptoAddressResolverBaseProvider) | TRON also uses the base resolver |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. |
| 2 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency this mapping applies to. FK to Wallet.CryptoTypes.CryptoID. Unique constraint - one resolver per crypto. |
| 3 | AddressResolverProviderId | int | NO | - | VERIFIED | The address resolver implementation: 1=Base, 2=Bitcoin, 3=BCH, 4=Litecoin, 5=Ethereum, 6=Ripple, 7=Stellar, 8=EOS, 9=ETC. See [Address Resolver Provider](../../_glossary.md#address-resolver-provider). FK to Dictionary.AddressResolverProviders. |
| 4 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | When this mapping was created. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CryptoId | Wallet.CryptoTypes | FK | Which crypto |
| AddressResolverProviderId | Dictionary.AddressResolverProviders | FK | Which resolver |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetAddressResolverProviderContracts | - | Reader | Reads all mappings |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddressResolverProviderContracts (table)
├── Wallet.CryptoTypes (table)
└── Dictionary.AddressResolverProviders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FK target for CryptoId |
| Dictionary.AddressResolverProviders | Table | FK target for AddressResolverProviderId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetAddressResolverProviderContracts | Stored Procedure | Reads mappings |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AddressResolverProviderContracts | CLUSTERED PK | Id ASC | - | - | Active |
| IX_...CryptoId | NC UNIQUE | CryptoId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_...Created | DEFAULT | getutcdate() |
| FK_...CryptoId | FK | -> Wallet.CryptoTypes.CryptoID |
| FK_...AddressResolverProviderId | FK | -> Dictionary.AddressResolverProviders.Id |

---

## 8. Sample Queries

### 8.1 List all crypto-resolver mappings
```sql
SELECT ct.Name AS Crypto, arp.Name AS Resolver, arpc.Created
FROM Wallet.AddressResolverProviderContracts arpc WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON arpc.CryptoId = ct.CryptoID
JOIN Dictionary.AddressResolverProviders arp WITH (NOLOCK) ON arpc.AddressResolverProviderId = arp.Id
ORDER BY ct.Name
```

### 8.2 Find resolver for a crypto
```sql
SELECT arp.Name AS Resolver FROM Wallet.AddressResolverProviderContracts arpc WITH (NOLOCK)
JOIN Dictionary.AddressResolverProviders arp WITH (NOLOCK) ON arpc.AddressResolverProviderId = arp.Id
WHERE arpc.CryptoId = 1
```

### 8.3 Cryptos using the base resolver
```sql
SELECT ct.Name FROM Wallet.AddressResolverProviderContracts arpc WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON arpc.CryptoId = ct.CryptoID
WHERE arpc.AddressResolverProviderId = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddressResolverProviderContracts | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.AddressResolverProviderContracts.sql*
