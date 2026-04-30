# Wallet.GetWalletsFromDate

> Returns all customer wallets created after a specified date with their address and balance account details, used by balance and redeem scheduler services for incremental wallet discovery.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CustomerWalletsView + WalletAddresses rows by creation date |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns wallets created after a specified date, joined with their address records from WalletAddresses. The balance and redeem scheduler services use this for incremental wallet discovery - finding newly created wallets that need to be registered with the blockchain provider or added to monitoring. Each result includes the wallet's balance account ID for provider-side reconciliation.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. CustomerWalletsView filtered by Occurred > @FromDate, JOINed to WalletAddresses.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | datetime | NO | - | VERIFIED | Only return wallets created after this date. |
| 2 | Id (output) | uniqueidentifier | NO | - | CODE-BACKED | Wallet ID. |
| 3 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer ID. |
| 4 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency. |
| 5 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Wallet address from WalletAddresses. |
| 6 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference. |
| 7 | AccountId (output) | nvarchar | YES | - | CODE-BACKED | Balance account ID (aliased from BalanceAccountID). |
| 8 | RecordId (output) | bigint | YES | - | CODE-BACKED | Internal record ID. |
| 9 | BlockchainCryptoId (output) | int | YES | - | CODE-BACKED | Base-chain crypto. |
| 10 | WalletProviderId (output) | int | YES | - | CODE-BACKED | Provider ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FromDate | Wallet.CustomerWalletsView.Occurred | Filter | Creation date threshold |
| WalletId | Wallet.WalletAddresses | JOIN | Address details |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BalanceUser | - | EXECUTE | New wallet discovery |
| RedeemSchedulerUser | - | EXECUTE | New wallet monitoring |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletsFromDate (procedure)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.WalletAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Filtered by creation date |
| Wallet.WalletAddresses | Table | Address + balance account |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BalanceUser, RedeemSchedulerUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get wallets created in the last 24 hours
```sql
EXEC Wallet.GetWalletsFromDate @FromDate = DATEADD(DAY, -1, GETDATE());
```

### 8.2 Direct equivalent
```sql
SELECT cw.Id, cw.Gcid, cw.CryptoId, wa.Address, cw.BlockchainProviderWalletId AS ProviderWalletId,
    wa.BalanceAccountID AS AccountId, cw.WalletRecordId AS RecordId, cw.BlockchainCryptoId, cw.WalletProviderId
FROM Wallet.CustomerWalletsView cw WITH (NOLOCK) JOIN Wallet.WalletAddresses wa ON wa.WalletId = cw.Id
WHERE cw.Occurred > DATEADD(DAY, -1, GETDATE());
```

### 8.3 Count new wallets per day
```sql
SELECT CAST(Occurred AS DATE) AS Day, COUNT(*) FROM Wallet.CustomerWalletsView WITH (NOLOCK)
WHERE Occurred > DATEADD(DAY, -7, GETDATE()) GROUP BY CAST(Occurred AS DATE) ORDER BY 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletsFromDate | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletsFromDate.sql*
