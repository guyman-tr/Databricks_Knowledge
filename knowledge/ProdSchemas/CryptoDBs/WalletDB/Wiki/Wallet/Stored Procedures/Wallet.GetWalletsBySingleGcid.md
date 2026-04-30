# Wallet.GetWalletsBySingleGcid

> Returns wallets for a customer filtered by a list of specific cryptocurrencies, providing a targeted wallet lookup with status and activation details for five service consumers.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CustomerWalletsView rows by Gcid + CryptoIds TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns wallets for a single customer filtered to specific cryptocurrencies via the CryptoIds TVP. Unlike GetWalletsByGcid (which returns all cryptos), this returns only the requested ones. Results are ordered by CryptoId and include wallet status and IsActivated flag. Five services consume this: AML, back-office API, balance, executer, and redeem persistor.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. CustomerWalletsView filtered by Gcid JOIN CryptoIds TVP.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Customer ID. |
| 2 | @CryptoIds | Wallet.CryptoIds | NO | - | VERIFIED | TVP of CryptoIds to filter by. |
| 3 | Id (output) | uniqueidentifier | NO | - | CODE-BACKED | Wallet ID. |
| 4 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer ID. |
| 5 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency. |
| 6 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Primary address. |
| 7 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference. |
| 8 | WalletStatus (output) | tinyint | YES | - | CODE-BACKED | Wallet status from CustomerWalletsView. |
| 9 | RecordId (output) | bigint | YES | - | CODE-BACKED | Internal record ID. |
| 10 | BlockchainCryptoId (output) | int | YES | - | CODE-BACKED | Base-chain crypto. |
| 11 | Occurred (output) | datetime2(7) | YES | - | CODE-BACKED | Creation time. |
| 12 | WalletProviderId (output) | int | YES | - | CODE-BACKED | Provider ID. |
| 13 | IsActivated (output) | bit | YES | - | CODE-BACKED | Whether wallet is activated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcid + @CryptoIds | Wallet.CustomerWalletsView | JOIN | Filtered wallet lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AmlUser, BackApiUser, BalanceUser, ExecuterUser, RedeemPersistorUser | - | EXECUTE | Targeted wallet lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletsBySingleGcid (procedure)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Filtered by Gcid + CryptoIds |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AmlUser, BackApiUser, BalanceUser, ExecuterUser, RedeemPersistorUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get BTC and DOGE wallets for a customer
```sql
DECLARE @cryptos Wallet.CryptoIds;
INSERT INTO @cryptos VALUES (1), (19);
EXEC Wallet.GetWalletsBySingleGcid @Gcid = 30351701, @CryptoIds = @cryptos;
```

### 8.2 Direct equivalent
```sql
SELECT Id, Gcid, CryptoId, Address, BlockchainProviderWalletId AS ProviderWalletId, Status AS WalletStatus,
    WalletRecordId AS RecordId, BlockchainCryptoId, Occurred, WalletProviderId, IsActivated
FROM Wallet.CustomerWalletsView WITH (NOLOCK) WHERE Gcid = 30351701 AND CryptoId IN (1, 19) ORDER BY CryptoId;
```

### 8.3 Compare with multi-Gcid version
```sql
-- Single customer, specific cryptos (this SP):
EXEC Wallet.GetWalletsBySingleGcid @Gcid = 30351701, @CryptoIds = @cryptos;
-- Multiple customers (sibling SP):
EXEC Wallet.GetWalletsByMultiGcids @GcidAndCryptoIds = @pairs;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletsBySingleGcid | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletsBySingleGcid.sql*
