# Wallet.GetAmlProviders

> Stored procedure that returns all configured AML (Anti-Money Laundering) provider definitions from the Dictionary schema.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all Dictionary.AmlProviders rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetAmlProviders returns the master list of AML provider definitions configured in the system. AML providers are external services used for blockchain transaction screening and compliance checks (e.g., Chainalysis, Elliptic). Each provider has a unique ID and name.

This data is used by the wallet application to populate AML provider configuration and to resolve provider IDs to names in compliance reporting.

---

## 2. Business Logic

No complex business logic. Direct SELECT of Id, Name from Dictionary.AmlProviders with NOLOCK.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | AML provider identifier. Referenced by Wallet.AmlProviderContracts.AmlProviderId. |
| 2 | Name | varchar | NO | - | CODE-BACKED | Human-readable name of the AML provider (e.g., 'Chainalysis', 'Elliptic'). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Dictionary.AmlProviders | FROM | Reads all AML provider definitions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | - | EXEC | AML provider configuration loading |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetAmlProviders (procedure)
+-- Dictionary.AmlProviders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AmlProviders | Table | FROM with NOLOCK |

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

### 8.1 Get all AML providers
```sql
EXEC Wallet.GetAmlProviders
```

### 8.2 Find AML contracts for a specific provider
```sql
SELECT ap.Name, apc.*
FROM Dictionary.AmlProviders ap WITH (NOLOCK)
JOIN Wallet.AmlProviderContracts apc WITH (NOLOCK) ON apc.AmlProviderId = ap.Id
WHERE ap.Name = 'Chainalysis'
```

### 8.3 List all providers with contract counts
```sql
SELECT ap.Id, ap.Name, COUNT(apc.Id) AS ContractCount
FROM Dictionary.AmlProviders ap WITH (NOLOCK)
LEFT JOIN Wallet.AmlProviderContracts apc WITH (NOLOCK) ON apc.AmlProviderId = ap.Id
GROUP BY ap.Id, ap.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetAmlProviders | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetAmlProviders.sql*
