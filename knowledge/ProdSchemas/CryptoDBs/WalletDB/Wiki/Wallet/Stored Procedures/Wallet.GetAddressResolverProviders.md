# Wallet.GetAddressResolverProviders

> Stored procedure that returns all configured address resolver provider definitions from the Dictionary schema.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all Dictionary.AddressResolverProviders rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetAddressResolverProviders returns the master list of address resolver providers - external services used for resolving or validating blockchain addresses. These providers handle tasks like address format validation, ENS/domain resolution, and address-to-identity mapping.

---

## 2. Business Logic

No complex business logic. Direct SELECT of Id, Name from Dictionary.AddressResolverProviders with NOLOCK.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Address resolver provider identifier. Referenced by Wallet.AddressResolverProviderContracts. |
| 2 | Name | varchar | NO | - | CODE-BACKED | Human-readable name of the address resolver provider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Dictionary.AddressResolverProviders | FROM | Reads all provider definitions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | - | EXEC | Address resolver provider configuration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetAddressResolverProviders (procedure)
+-- Dictionary.AddressResolverProviders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AddressResolverProviders | Table | FROM with NOLOCK |

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

### 8.1 Get all address resolver providers
```sql
EXEC Wallet.GetAddressResolverProviders
```

### 8.2 Inline equivalent
```sql
SELECT Id, Name FROM Dictionary.AddressResolverProviders WITH (NOLOCK)
```

### 8.3 Providers with their contract counts
```sql
SELECT arp.Id, arp.Name, COUNT(arpc.Id) AS ContractCount
FROM Dictionary.AddressResolverProviders arp WITH (NOLOCK)
LEFT JOIN Wallet.AddressResolverProviderContracts arpc WITH (NOLOCK) ON arpc.AddressResolverProviderId = arp.Id
GROUP BY arp.Id, arp.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetAddressResolverProviders | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetAddressResolverProviders.sql*
