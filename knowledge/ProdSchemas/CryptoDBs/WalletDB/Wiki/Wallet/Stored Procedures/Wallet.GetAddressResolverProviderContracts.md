# Wallet.GetAddressResolverProviderContracts

> Stored procedure that returns the best-matching address resolver provider contract per cryptocurrency, using the same priority scheme as GetAmlProviderContracts.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns one address resolver contract per CryptoId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetAddressResolverProviderContracts determines which address resolver provider should handle address operations for each cryptocurrency. Like its AML counterpart (`GetAmlProviderContracts`), it uses a priority scheme: crypto-specific contracts take precedence over blockchain-level defaults.

Address resolvers handle blockchain address validation, format normalization, ENS/domain resolution, and similar address-related operations.

---

## 2. Business Logic

### 2.1 Priority-Based Contract Selection

**What**: Selects one address resolver contract per CryptoId using ROW_NUMBER with preference for crypto-specific matches.

**Columns/Parameters Involved**: CryptoTypes.CryptoId, AddressResolverProviderContracts.CryptoId, CryptoTypes.BlockchainCryptoId

**Rules**:
- JOINs CryptoTypes to AddressResolverProviderContracts on direct match (CryptoId) or blockchain-level match (BlockchainCryptoId)
- ROW_NUMBER partitioned by CryptoID, ordered by: direct match = 0, blockchain match = 1
- Filters to RowNum = 1 (best match per crypto)
- Resolves provider name from Dictionary.AddressResolverProviders

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | AddressResolverProviderContracts record ID. |
| 2 | CryptoId | int | NO | - | CODE-BACKED | The CryptoId this contract applies to (from CryptoTypes). |
| 3 | ProviderId | int | NO | - | CODE-BACKED | Address resolver provider ID (aliased from AddressResolverProviderId). |
| 4 | ProviderName | varchar | NO | - | CODE-BACKED | Human-readable address resolver provider name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.CryptoTypes | FROM | Iterates all cryptos |
| - | Wallet.AddressResolverProviderContracts | JOIN | Contract mappings |
| ProviderId | Dictionary.AddressResolverProviders | JOIN | Provider name resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Address resolution services | - | EXEC | Provider routing for address operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetAddressResolverProviderContracts (procedure)
+-- Wallet.CryptoTypes (table)
+-- Wallet.AddressResolverProviderContracts (table)
+-- Dictionary.AddressResolverProviders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FROM - iterates all cryptos |
| Wallet.AddressResolverProviderContracts | Table | JOIN - contract lookup with priority |
| Dictionary.AddressResolverProviders | Table | JOIN - provider name resolution |

### 6.2 Objects That Depend On This

No database object dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all address resolver contracts
```sql
EXEC Wallet.GetAddressResolverProviderContracts
```

### 8.2 See contract priority data
```sql
SELECT ct.CryptoId, ct.Name, arpc.CryptoId AS ContractCryptoId,
    CASE WHEN arpc.CryptoId = ct.CryptoID THEN 'Direct' ELSE 'Blockchain' END AS MatchType,
    arp.Name AS ProviderName
FROM Wallet.CryptoTypes ct WITH (NOLOCK)
JOIN Wallet.AddressResolverProviderContracts arpc WITH (NOLOCK) ON arpc.CryptoId = ct.CryptoID OR arpc.CryptoId = ct.BlockchainCryptoId
JOIN Dictionary.AddressResolverProviders arp WITH (NOLOCK) ON arp.Id = arpc.AddressResolverProviderId
ORDER BY ct.CryptoId
```

### 8.3 Compare AML and address resolver providers per crypto
```sql
-- Use both provider contract procedures to see the full provider landscape per crypto
EXEC Wallet.GetAmlProviderContracts
EXEC Wallet.GetAddressResolverProviderContracts
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetAddressResolverProviderContracts | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetAddressResolverProviderContracts.sql*
