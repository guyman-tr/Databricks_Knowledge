# Wallet.AddEtoroExternalAddress

> Registers a new eToro-controlled external blockchain address (e.g., hot/cold wallet, omnibus address) if no matching active entry already exists.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | New row in Wallet.EtoroExternalAddresses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure adds an eToro-owned external blockchain address to the known addresses registry. eToro maintains lists of its own blockchain addresses (hot wallets, cold storage, omnibus addresses, fee collection addresses) that the system must recognize as "internal" when processing incoming or outgoing transactions. This distinction is critical for AML screening, transaction classification, and balance reconciliation.

Without this registry, the system could not distinguish between transfers to/from eToro's own infrastructure and transfers to/from external third-party addresses. Misclassification would trigger false AML alerts, incorrect balance calculations, and broken transaction routing.

The procedure is called by administrative or automated provisioning processes when new eToro wallet infrastructure is deployed. It performs an idempotent upsert pattern - only inserting if no active entry with the same Address + CryptoId + ExternalAddressTypeId combination exists, preventing duplicates.

---

## 2. Business Logic

### 2.1 Idempotent Insert (Duplicate Prevention)

**What**: Ensures only one active entry exists per address/crypto/type combination.

**Columns/Parameters Involved**: `@Address`, `@CryptoId`, `@ExternalAddressTypeId`

**Rules**:
- Before inserting, checks if an active record (IsActive=1) already exists with the same Address, CryptoId, and ExternalAddressTypeId
- If a match exists, the INSERT is silently skipped (no error raised)
- The IsActive column is always set to 1 on insert
- This allows the same physical address to be registered for different crypto IDs or different address types

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Address | nvarchar(512) | NO | - | CODE-BACKED | The blockchain address to register as eToro-owned. Must be a valid address for the specified cryptocurrency. |
| 2 | @Comment | nvarchar(256) | NO | - | CODE-BACKED | Free-text description of the address purpose (e.g., "BTC Hot Wallet", "ETH Cold Storage", "Fee Collection"). |
| 3 | @CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency this address belongs to. Maps to Wallet.CryptoTypes.CryptoID. |
| 4 | @ExternalAddressTypeId | tinyint | NO | - | CODE-BACKED | Classification of the external address type. Stored in Wallet.EtoroExternalAddresses.ExternalAddressTypeId. Determines how the address is used (e.g., hot wallet, cold storage, omnibus). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CryptoId | Wallet.CryptoTypes | Implicit | Cryptocurrency for the registered address |
| INSERT target | Wallet.EtoroExternalAddresses | Writer | Inserts new external address records |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by application services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddEtoroExternalAddress (procedure)
  └── Wallet.EtoroExternalAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.EtoroExternalAddresses | Table | INSERT target + existence check |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Duplicate prevention is handled via WHERE NOT EXISTS pattern in the INSERT.

---

## 8. Sample Queries

### 8.1 Register a new BTC hot wallet address
```sql
EXEC Wallet.AddEtoroExternalAddress
    @Address = 'bc1qexamplehotwalletaddress123',
    @Comment = 'BTC Hot Wallet - Production',
    @CryptoId = 1,
    @ExternalAddressTypeId = 1
```

### 8.2 View all active eToro external addresses for a crypto
```sql
SELECT Address, Comment, ExternalAddressTypeId, CreatedDate
FROM Wallet.EtoroExternalAddresses WITH (NOLOCK)
WHERE CryptoId = 1 AND IsActive = 1
ORDER BY CreatedDate DESC
```

### 8.3 Check all registered addresses with crypto names
```sql
SELECT eea.Address, eea.Comment, ct.CryptoName, eea.ExternalAddressTypeId, eea.IsActive
FROM Wallet.EtoroExternalAddresses eea WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = eea.CryptoId
WHERE eea.IsActive = 1
ORDER BY ct.CryptoName, eea.ExternalAddressTypeId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddEtoroExternalAddress | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AddEtoroExternalAddress.sql*
