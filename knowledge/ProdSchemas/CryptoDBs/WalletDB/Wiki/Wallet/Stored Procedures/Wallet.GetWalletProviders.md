# Wallet.GetWalletProviders

> Returns the complete list of wallet infrastructure providers (e.g., BitGo, Fireblocks) from the Dictionary, ordered by ID, used by the transaction sync service for provider enumeration.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from Dictionary.WalletProvider |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the complete catalog of wallet infrastructure providers. Each provider represents a blockchain wallet service (e.g., BitGo for custodial wallets, Fireblocks for MPC wallets) that the platform integrates with. The transaction sync service uses this to enumerate all available providers at startup.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Full table scan of Dictionary.WalletProvider ordered by Id.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id (output) | int | NO | - | CODE-BACKED | Provider ID. |
| 2 | Name (output) | varchar(64) | NO | - | CODE-BACKED | Provider display name (e.g., 'BitGo', 'Fireblocks'). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Dictionary.WalletProvider | Full scan | All provider records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TransactionSyncUser | - | EXECUTE | Provider enumeration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletProviders (procedure)
+-- Dictionary.WalletProvider (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.WalletProvider | Table | Full table read |

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

### 8.1 List all providers
```sql
EXEC Wallet.GetWalletProviders;
```

### 8.2 Direct equivalent
```sql
SELECT Id, Name FROM Dictionary.WalletProvider WITH (NOLOCK) ORDER BY Id;
```

### 8.3 Find provider by name
```sql
EXEC Wallet.GetWalletProviderByName @Name = 'BitGo';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletProviders | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletProviders.sql*
