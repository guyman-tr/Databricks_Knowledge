# Wallet.GetAmlProviderContracts

> Stored procedure that returns the best-matching AML provider contract per cryptocurrency, using a priority scheme that prefers crypto-specific contracts over blockchain-level defaults.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns one AML provider contract per CryptoId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetAmlProviderContracts determines which AML provider should be used for each cryptocurrency. AML contracts can be configured at two levels: directly for a specific CryptoId, or for a blockchain (BlockchainCryptoId) which covers all tokens on that chain. The procedure uses a priority scheme: a crypto-specific contract takes precedence over a blockchain-level contract.

For example, BTC might have its own Chainalysis contract, while all ERC-20 tokens on Ethereum share a single blockchain-level Elliptic contract. This procedure ensures each crypto gets its most specific AML provider.

---

## 2. Business Logic

### 2.1 Priority-Based Contract Selection

**What**: Selects one AML provider contract per CryptoId using ROW_NUMBER with preference for crypto-specific matches.

**Columns/Parameters Involved**: CryptoTypes.CryptoId, AmlProviderContracts.CryptoId, CryptoTypes.BlockchainCryptoId

**Rules**:
- JOINs CryptoTypes to AmlProviderContracts on either `apc.CryptoId = ct.CryptoID` (direct match) or `apc.CryptoId = ct.BlockchainCryptoId` (blockchain-level)
- ROW_NUMBER partitioned by CryptoID, ordered by: direct match = 0 (higher priority), blockchain match = 1 (lower priority)
- Filters to RowNum = 1 to get the best match per crypto
- Resolves provider name from Dictionary.AmlProviders

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | AmlProviderContracts record ID. |
| 2 | CryptoId | int | NO | - | CODE-BACKED | The CryptoId this contract applies to (from CryptoTypes, not the contract's CryptoId). |
| 3 | AmlProviderId | int | NO | - | CODE-BACKED | AML provider identifier (FK to Dictionary.AmlProviders). |
| 4 | ProviderName | varchar | NO | - | CODE-BACKED | Human-readable AML provider name (e.g., 'Chainalysis', 'Elliptic'). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.CryptoTypes | FROM | Iterates all cryptos |
| - | Wallet.AmlProviderContracts | JOIN | Contract mappings (direct or blockchain-level) |
| AmlProviderId | Dictionary.AmlProviders | JOIN | Provider name resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AML screening services | - | EXEC | Determines which AML provider to use per crypto |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetAmlProviderContracts (procedure)
+-- Wallet.CryptoTypes (table)
+-- Wallet.AmlProviderContracts (table)
+-- Dictionary.AmlProviders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FROM - iterates all cryptos |
| Wallet.AmlProviderContracts | Table | JOIN - contract lookup with priority |
| Dictionary.AmlProviders | Table | JOIN - provider name |

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

### 8.1 Get all AML provider contracts
```sql
EXEC Wallet.GetAmlProviderContracts
```

### 8.2 Find the AML provider for Bitcoin
```sql
EXEC Wallet.GetAmlProviderContracts
-- Filter result client-side for CryptoId = 1
```

### 8.3 See raw contract priority data
```sql
SELECT ct.CryptoId, ct.Name, apc.CryptoId AS ContractCryptoId,
    CASE WHEN apc.CryptoId = ct.CryptoID THEN 'Direct' ELSE 'Blockchain' END AS MatchType,
    ap.Name AS ProviderName
FROM Wallet.CryptoTypes ct WITH (NOLOCK)
JOIN Wallet.AmlProviderContracts apc WITH (NOLOCK) ON apc.CryptoId = ct.CryptoID OR apc.CryptoId = ct.BlockchainCryptoId
JOIN Dictionary.AmlProviders ap WITH (NOLOCK) ON ap.Id = apc.AmlProviderId
ORDER BY ct.CryptoId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetAmlProviderContracts | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetAmlProviderContracts.sql*
