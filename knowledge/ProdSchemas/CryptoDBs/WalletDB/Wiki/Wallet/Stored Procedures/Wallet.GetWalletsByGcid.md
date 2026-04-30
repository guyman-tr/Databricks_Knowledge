# Wallet.GetWalletsByGcid

> Returns all wallets owned by a customer across all cryptocurrencies, providing the primary wallet lookup by Global Customer ID for five service consumers.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all CustomerWalletsView rows for a Gcid |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns all wallets belonging to a customer, identified by their Global Customer ID (Gcid). It is one of the most broadly consumed wallet lookup procedures, used by the back-office API, billing notification, conversion, executer, and staking services. Each result row includes the wallet's ID, crypto, address, provider details, creation timestamp, and internal record references.

The result includes BlockchainProviderWalletId twice (once by name, once aliased as ProviderWalletId) for backward compatibility with older consumers. Returns all crypto wallets for the customer, including both base-chain and token sub-wallets.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct single-table read from CustomerWalletsView filtered by Gcid.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Global Customer ID to look up wallets for. |
| 2 | Id (output) | uniqueidentifier | NO | - | CODE-BACKED | Internal wallet ID. |
| 3 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer ID (echo of @Gcid). |
| 4 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency for this wallet entry. |
| 5 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Primary blockchain address. |
| 6 | BlockchainProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference (backward compat). |
| 7 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference alias. |
| 8 | RecordId (output) | bigint | YES | - | CODE-BACKED | Internal wallet record ID (aliased from WalletRecordId). |
| 9 | BlockchainCryptoId (output) | int | YES | - | CODE-BACKED | Base-chain crypto ID. |
| 10 | Occurred (output) | datetime2(7) | YES | - | CODE-BACKED | Wallet creation timestamp. |
| 11 | WalletProviderId (output) | int | YES | - | CODE-BACKED | Wallet infrastructure provider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcid | Wallet.CustomerWalletsView.Gcid | Filter | Customer wallet lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Back-office wallet display |
| BillingNotificationUser | - | EXECUTE | Billing wallet resolution |
| ConversionUser | - | EXECUTE | Conversion wallet lookup |
| ExecuterUser | - | EXECUTE | Execution wallet context |
| StakingUser | - | EXECUTE | Staking wallet lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletsByGcid (procedure)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Filtered by Gcid |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser, BillingNotificationUser, ConversionUser, ExecuterUser, StakingUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get all wallets for a customer
```sql
EXEC Wallet.GetWalletsByGcid @Gcid = 30351701;
```

### 8.2 Direct equivalent
```sql
SELECT Id, Gcid, CryptoId, Address, BlockchainProviderWalletId, BlockchainProviderWalletId AS ProviderWalletId,
    WalletRecordId AS RecordId, BlockchainCryptoId, Occurred, WalletProviderId
FROM Wallet.CustomerWalletsView WITH (NOLOCK) WHERE Gcid = 30351701;
```

### 8.3 Count wallets per crypto for a customer
```sql
SELECT CryptoId, COUNT(*) FROM Wallet.CustomerWalletsView WITH (NOLOCK) WHERE Gcid = 30351701 GROUP BY CryptoId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletsByGcid | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletsByGcid.sql*
