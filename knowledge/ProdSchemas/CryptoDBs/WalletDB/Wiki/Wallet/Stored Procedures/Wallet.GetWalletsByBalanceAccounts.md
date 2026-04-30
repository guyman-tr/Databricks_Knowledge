# Wallet.GetWalletsByBalanceAccounts

> Retrieves wallet details for a set of provider balance account IDs, including last sync time, used by the balance service to map provider-side accounts back to internal wallets.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns wallet rows by BalanceAccountId TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure maps provider-side balance account IDs back to internal wallet details. When the blockchain provider reports balance updates using their own account identifiers, the balance service needs to resolve which internal wallet each account belongs to. The procedure joins WalletAddresses (which holds the BalanceAccountID) through CustomerWalletsView and optionally to ReceivedTransactionSynced for last sync timestamps.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Multi-table JOIN resolving BalanceAccountId to wallet details with optional sync time.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BalanceAccountIds | Wallet.BalanceAccountIds | NO | - | VERIFIED | TVP containing provider balance account IDs to look up. |
| 2 | BalanceAccountID (output) | nvarchar | NO | - | CODE-BACKED | Provider balance account ID (echo). |
| 3 | BlockchainProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider wallet reference (backward compat). |
| 4 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider wallet reference alias. |
| 5 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Primary wallet address. |
| 6 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer ID. |
| 7 | Id (output) | uniqueidentifier | NO | - | CODE-BACKED | Internal wallet ID. |
| 8 | WalletId (output) | uniqueidentifier | NO | - | CODE-BACKED | Alias of Id (backward compat). |
| 9 | LastSynced (output) | datetime2(7) | YES | - | CODE-BACKED | Last sync timestamp from ReceivedTransactionSynced. NULL if never synced. |
| 10 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BalanceAccountIds | Wallet.WalletAddresses.BalanceAccountID | JOIN | Account-to-wallet resolution |
| WalletId | Wallet.CustomerWalletsView | JOIN | Wallet details |
| CryptoId | Wallet.BlockchainCryptos | JOIN | Crypto validation |
| WalletId | Wallet.ReceivedTransactionSynced | LEFT JOIN | Last sync time |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BalanceUser | - | EXECUTE | Provider account-to-wallet mapping |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletsByBalanceAccounts (procedure)
+-- Wallet.WalletAddresses (table)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.BlockchainCryptos (table)
+-- Wallet.ReceivedTransactionSynced (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletAddresses | Table | BalanceAccountID lookup |
| Wallet.CustomerWalletsView | View | Wallet details |
| Wallet.BlockchainCryptos | Table | Crypto validation |
| Wallet.ReceivedTransactionSynced | Table | Last sync timestamp |

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

### 8.1 Look up wallets by balance accounts
```sql
DECLARE @ids Wallet.BalanceAccountIds;
INSERT INTO @ids VALUES ('BA-12345'), ('BA-67890');
EXEC Wallet.GetWalletsByBalanceAccounts @BalanceAccountIds = @ids;
```

### 8.2 Direct equivalent
```sql
SELECT wa.BalanceAccountID, cw.BlockchainProviderWalletId, cw.Address, cw.Gcid, cw.Id, cw.CryptoId
FROM Wallet.WalletAddresses wa WITH (NOLOCK)
    JOIN Wallet.CustomerWalletsView cw WITH (NOLOCK) ON wa.WalletId = cw.Id
WHERE wa.BalanceAccountID = 'BA-12345';
```

### 8.3 Find all balance accounts for a customer
```sql
SELECT wa.BalanceAccountID, cw.CryptoId
FROM Wallet.WalletAddresses wa WITH (NOLOCK)
    JOIN Wallet.CustomerWalletsView cw WITH (NOLOCK) ON wa.WalletId = cw.Id
WHERE cw.Gcid = 30351701;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletsByBalanceAccounts | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletsByBalanceAccounts.sql*
