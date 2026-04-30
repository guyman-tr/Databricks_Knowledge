# Wallet.GetWalletProviderByName

> Resolves a wallet infrastructure provider's internal ID by its name, used by the transaction sync service to identify the provider for downstream operations.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar Id from Dictionary.WalletProvider by Name |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure resolves a wallet infrastructure provider's internal ID from its display name. Wallet providers (e.g., BitGo, Fireblocks) are registered in Dictionary.WalletProvider with a numeric ID and string name. The transaction sync service uses this to look up the provider ID when it only has the provider name from configuration or API responses.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct scalar lookup on Dictionary.WalletProvider by Name.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Name | varchar(64) | NO | - | VERIFIED | Provider name to look up (e.g., 'BitGo', 'Fireblocks'). Matched against Dictionary.WalletProvider.Name. |
| 2 | Id (output) | int | NO | - | CODE-BACKED | Internal provider ID. FK target used throughout the wallet system. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Name | Dictionary.WalletProvider.Name | Lookup | Provider name-to-ID resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TransactionSyncUser | - | EXECUTE | Transaction sync provider identification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletProviderByName (procedure)
+-- Dictionary.WalletProvider (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.WalletProvider | Table | Lookup by Name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TransactionSyncUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Look up provider ID by name
```sql
EXEC Wallet.GetWalletProviderByName @Name = 'BitGo';
```

### 8.2 Direct equivalent
```sql
SELECT Id FROM Dictionary.WalletProvider WITH (NOLOCK) WHERE Name = 'BitGo';
```

### 8.3 List all providers
```sql
EXEC Wallet.GetWalletProviders;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletProviderByName | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletProviderByName.sql*
