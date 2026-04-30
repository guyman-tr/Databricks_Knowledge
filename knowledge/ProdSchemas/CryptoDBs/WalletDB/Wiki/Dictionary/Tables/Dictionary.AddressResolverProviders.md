# Dictionary.AddressResolverProviders

> Lookup table of blockchain-specific address resolver providers used to validate and resolve cryptocurrency wallet addresses across different blockchain networks.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (int IDENTITY, PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK clustered + unique Name) |

---

## 1. Business Meaning

This table registers the different address resolver provider implementations used by the system to validate and resolve cryptocurrency addresses. Each blockchain network (Bitcoin, Ethereum, Litecoin, etc.) has its own address format and validation rules, so the platform maintains a separate resolver provider for each supported blockchain.

Without this table, the system could not map incoming addresses to the correct blockchain validation logic. When a customer provides a wallet address for deposit or withdrawal, the system must identify which blockchain the address belongs to and apply the correct validation rules.

Rows are added when new blockchain support is introduced. The `Created` timestamp records when each provider was registered. The table is referenced by `Wallet.AddressResolverProviderContracts` which maps these providers to specific crypto contracts, and by stored procedures `GetAddressResolverProviders` and `GetAddressResolverProviderContracts`.

---

## 2. Business Logic

### 2.1 Blockchain-Specific Address Resolution

**What**: Each provider handles a specific blockchain's address format and validation rules.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- Provider names follow the pattern `{Blockchain}AddressResolverProvider`, indicating which blockchain they handle
- `CryptoAddressResolverBaseProvider` (1) is the base/default provider, likely used as a fallback
- Each blockchain-specific provider (Bitcoin, Bch, Litecoin, Eth, Ripple, Stellar, EOS, Etc) implements unique address validation logic
- Providers are registered chronologically as new blockchains are onboarded - Bitcoin (2018-07) through ETC (2025-03)

**Diagram**:
```
Incoming Address --> Identify Blockchain --> Select Provider
                                                |
    +-------------------------------------------+
    |           |          |         |           |
  Bitcoin(2)  BCH(3)  Litecoin(4)  ETH(5)  Ripple(6) ...
    |           |          |         |           |
  Validate   Validate  Validate  Validate   Validate
  & Resolve  & Resolve & Resolve & Resolve  & Resolve
```

---

## 3. Data Overview

| Id | Name | Created | Meaning |
|---|---|---|---|
| 1 | CryptoAddressResolverBaseProvider | 2018-07-26 | Base provider implementation serving as the foundation or fallback for address resolution. First provider registered when the system launched. |
| 2 | BitcoinAddressResolverProvider | 2018-07-26 | Handles Bitcoin (BTC) address validation and resolution. Supports legacy (1xxx), SegWit (3xxx), and native SegWit (bc1xxx) address formats. |
| 5 | EthAddressResolverProvider | 2018-11-19 | Handles Ethereum (ETH) address validation. Supports EIP-55 checksummed addresses and ERC-20 token addresses on the Ethereum network. |
| 6 | RippleAddressResolverProvider | 2018-12-10 | Handles Ripple (XRP) address validation including destination tag support for exchange addresses. |
| 9 | EtcAddressResolverProvider | 2025-03-06 | Most recently added provider for Ethereum Classic (ETC). Added years after initial launch, indicating gradual blockchain expansion. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing unique identifier for the address resolver provider. FK target for Wallet.AddressResolverProviderContracts. Values: 1=Base, 2=Bitcoin, 3=BCH, 4=Litecoin, 5=ETH, 6=Ripple, 7=Stellar, 8=EOS, 9=ETC. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Unique name of the resolver provider implementation. Follows the pattern `{Blockchain}AddressResolverProvider`. Maps to a class name in application code that implements blockchain-specific address logic. |
| 3 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC timestamp when the provider was registered. Defaults to current UTC time on insert. Tracks when blockchain support was onboarded to the platform. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.AddressResolverProviderContracts | AddressResolverProviderId | FK | Maps resolver providers to specific crypto provider contracts |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AddressResolverProviderContracts | Table | FK on AddressResolverProviderId |
| Wallet.GetAddressResolverProviders | Stored Procedure | Reads all providers |
| Wallet.GetAddressResolverProviderContracts | Stored Procedure | Reads providers via JOIN |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AddressResolverProviders | CLUSTERED | Id ASC | - | - | Active |
| IX_Wallet_AddressResolverProviders_Name | NONCLUSTERED UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_AddressResolverProviders_Created | DEFAULT | getutcdate() - Auto-sets creation timestamp to current UTC time |

---

## 8. Sample Queries

### 8.1 List all address resolver providers with registration dates
```sql
SELECT Id, Name, Created
FROM Dictionary.AddressResolverProviders WITH (NOLOCK)
ORDER BY Id
```

### 8.2 Find the provider for a specific blockchain
```sql
SELECT Id, Name
FROM Dictionary.AddressResolverProviders WITH (NOLOCK)
WHERE Name LIKE '%Eth%'
```

### 8.3 List providers with their crypto contracts
```sql
SELECT arp.Id, arp.Name AS ProviderName, arpc.CryptoProviderContractId
FROM Dictionary.AddressResolverProviders arp WITH (NOLOCK)
JOIN Wallet.AddressResolverProviderContracts arpc WITH (NOLOCK)
  ON arpc.AddressResolverProviderId = arp.Id
ORDER BY arp.Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AddressResolverProviders | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.AddressResolverProviders.sql*
