# Wallet.GetWalletAddresses

> Retrieves all blockchain addresses associated with a specific wallet, including their balance account IDs, by joining WalletAddresses with CustomerWalletsView for crypto and customer context.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns WalletAddresses rows by WalletId with customer context |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns all blockchain addresses registered for a specific wallet. A wallet can have multiple addresses (e.g., on UTXO chains where new receiving addresses are generated). Each address includes its balance account ID for provider-side reconciliation, plus the crypto ID and customer Gcid from CustomerWalletsView. The balance service uses this for address management and reconciliation.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct JOIN between WalletAddresses and CustomerWalletsView by WalletId.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | VERIFIED | Wallet to retrieve addresses for. |
| 2 | WalletId (output) | uniqueidentifier | NO | - | CODE-BACKED | Echo of the wallet ID. |
| 3 | Address (output) | nvarchar(512) | NO | - | CODE-BACKED | Blockchain address registered to this wallet. |
| 4 | BalanceAccountID (output) | nvarchar | YES | - | CODE-BACKED | Provider-side balance account identifier for this address. |
| 5 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency for this wallet. From CustomerWalletsView. |
| 6 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer who owns this wallet. From CustomerWalletsView. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletId | Wallet.WalletAddresses.WalletId | Filter | Address records for this wallet |
| @WalletId | Wallet.CustomerWalletsView.Id | JOIN | Customer and crypto context |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BalanceUser | - | EXECUTE | Address management and reconciliation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletAddresses (procedure)
+-- Wallet.WalletAddresses (table)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletAddresses | Table | Address records by WalletId |
| Wallet.CustomerWalletsView | View | JOINed for crypto and customer context |

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

### 8.1 Get all addresses for a wallet
```sql
EXEC Wallet.GetWalletAddresses @WalletId = 'C0D5EF83-1234-5678-9ABC-DEF012345678';
```

### 8.2 Direct equivalent
```sql
SELECT wa.WalletId, wa.Address, wa.BalanceAccountID, cwv.CryptoId, cwv.Gcid
FROM Wallet.WalletAddresses wa WITH (NOLOCK)
    JOIN Wallet.CustomerWalletsView cwv WITH (NOLOCK) ON cwv.Id = wa.WalletId
WHERE wa.WalletId = 'C0D5EF83-...';
```

### 8.3 Count addresses per wallet for a customer
```sql
SELECT cwv.Id AS WalletId, cwv.CryptoId, COUNT(wa.Id) AS AddressCount
FROM Wallet.CustomerWalletsView cwv WITH (NOLOCK)
    LEFT JOIN Wallet.WalletAddresses wa WITH (NOLOCK) ON wa.WalletId = cwv.Id
WHERE cwv.Gcid = 30351701
GROUP BY cwv.Id, cwv.CryptoId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletAddresses | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletAddresses.sql*
