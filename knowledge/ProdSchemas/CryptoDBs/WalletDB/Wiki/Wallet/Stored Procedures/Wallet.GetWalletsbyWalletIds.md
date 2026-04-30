# Wallet.GetWalletsbyWalletIds

> Retrieves wallet details for a list of wallet IDs via TVP, returning core identity fields and activation status, used by the balance service for bulk wallet resolution.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CustomerWalletsView rows by GuidListType TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure resolves multiple wallets by their IDs in a single call. The balance service passes a list of wallet GUIDs via the GuidListType TVP and receives each wallet's customer ID, crypto, provider reference, and activation status. Results are ordered by Id then CryptoId to group all crypto entries for the same wallet together.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. TVP JOIN to CustomerWalletsView.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletIds | Wallet.GuidListType | NO | - | VERIFIED | TVP of wallet GUIDs to look up. |
| 2 | Id (output) | uniqueidentifier | NO | - | CODE-BACKED | Wallet ID. |
| 3 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer ID. |
| 4 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency. |
| 5 | BlockchainProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference (backward compat). |
| 6 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference alias. |
| 7 | IsActivated (output) | bit | YES | - | CODE-BACKED | Whether wallet is activated on the blockchain. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletIds | Wallet.CustomerWalletsView.Id | JOIN | Bulk wallet lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BalanceUser | - | EXECUTE | Bulk wallet resolution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletsbyWalletIds (procedure)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | JOIN via TVP |

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

### 8.1 Look up multiple wallets
```sql
DECLARE @ids Wallet.GuidListType;
INSERT INTO @ids VALUES ('C0D5EF83-...'), ('A1B2C3D4-...');
EXEC Wallet.GetWalletsbyWalletIds @WalletIds = @ids;
```

### 8.2 Direct equivalent
```sql
SELECT Id, Gcid, CryptoId, BlockchainProviderWalletId, BlockchainProviderWalletId AS ProviderWalletId, IsActivated
FROM Wallet.CustomerWalletsView WITH (NOLOCK)
WHERE Id IN ('C0D5EF83-...', 'A1B2C3D4-...')
ORDER BY Id, CryptoId;
```

### 8.3 Check activation status for specific wallets
```sql
DECLARE @ids Wallet.GuidListType;
INSERT INTO @ids VALUES ('C0D5EF83-...');
EXEC Wallet.GetWalletsbyWalletIds @WalletIds = @ids;
-- IsActivated = 0 means wallet needs blockchain activation
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletsbyWalletIds | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletsbyWalletIds.sql*
