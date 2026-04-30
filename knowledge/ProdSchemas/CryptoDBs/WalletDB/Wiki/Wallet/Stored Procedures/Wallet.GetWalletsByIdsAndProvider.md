# Wallet.GetWalletsByIdsAndProvider

> Filters a set of wallet IDs to return only those belonging to a specific wallet infrastructure provider, used by the balance service for provider-specific wallet operations.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns WalletIds from WalletPool filtered by provider name |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure takes a list of wallet IDs (via GuidListType TVP) and a provider name, returning only those wallet IDs that belong to the specified provider. It queries WalletPool (not CustomerWalletsView) and JOINs to Dictionary.WalletProvider by name. The balance service uses this to partition wallet operations by provider when different providers require different handling.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. TVP JOIN to WalletPool filtered by provider name via Dictionary.WalletProvider.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Ids | Wallet.GuidListType | NO | - | VERIFIED | TVP of wallet IDs to filter. |
| 2 | @ProviderName | varchar(64) | NO | - | VERIFIED | Provider name to filter by (e.g., 'BitGo'). Matched against Dictionary.WalletProvider.Name. |
| 3 | WalletId (output) | uniqueidentifier | NO | - | CODE-BACKED | Wallet IDs that belong to the specified provider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Ids | Wallet.WalletPool.WalletId | JOIN | Pool wallet filter |
| @ProviderName | Dictionary.WalletProvider.Name | JOIN | Provider name match |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BalanceUser | - | EXECUTE | Provider-specific wallet filtering |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletsByIdsAndProvider (procedure)
+-- Wallet.WalletPool (table)
+-- Dictionary.WalletProvider (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | Wallet-to-provider resolution |
| Dictionary.WalletProvider | Table | Provider name filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BalanceUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Filter wallets by provider
```sql
DECLARE @ids Wallet.GuidListType;
INSERT INTO @ids VALUES ('C0D5EF83-...'), ('A1B2C3D4-...');
EXEC Wallet.GetWalletsByIdsAndProvider @Ids = @ids, @ProviderName = 'BitGo';
```

### 8.2 Direct equivalent
```sql
SELECT wp.WalletId FROM Wallet.WalletPool wp WITH (NOLOCK)
    JOIN Dictionary.WalletProvider wp1 WITH (NOLOCK) ON wp1.Id = wp.WalletProviderId AND wp1.Name = 'BitGo'
WHERE wp.WalletId IN ('C0D5EF83-...', 'A1B2C3D4-...');
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
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletsByIdsAndProvider | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletsByIdsAndProvider.sql*
