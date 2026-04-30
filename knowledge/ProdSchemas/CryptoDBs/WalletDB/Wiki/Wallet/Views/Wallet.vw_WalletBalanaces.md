# Wallet.vw_WalletBalanaces

> Denormalized view enriching wallet balance snapshots with blockchain address identifiers by joining WalletBalances to active customer wallets and their addresses, answering "what balance does this wallet address hold?"

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | View |
| **Key Identifier** | Id (int, from WalletBalances.Id) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view maps wallet balance snapshots to their corresponding blockchain wallet address records. While WalletBalances stores balances by WalletId, some consumers need the WalletAddressesId (the specific address record) rather than just the wallet. This view bridges the gap by joining through CustomerWalletsView to resolve the wallet's public address, then matching it to the WalletAddresses record.

Without this view, consumers would need to manually join WalletBalances -> CustomerWalletsView -> WalletAddresses to get the address ID for a given balance. The view simplifies this to a single query surface.

Note: the view name contains a typo ("Balanaces" instead of "Balances") which is preserved as-is in the SSDT. The view has no procedure or view consumers in the SSDT - it is likely consumed by external tools or reports.

---

## 2. Business Logic

### 2.1 Address Resolution via CustomerWalletsView

**What**: The view resolves which WalletAddresses record corresponds to each balance by matching the public address string.

**Columns/Parameters Involved**: `WalletId`, `CryptoId`, `Address`, `WalletAddressesId`

**Rules**:
- JOIN CustomerWalletsView ON `cwv.Id = wb.WalletId AND cwv.CryptoId = wb.CryptoId`: Links balance to active wallet
- JOIN WalletAddresses ON `wa.Address = cwv.Address`: Matches the blockchain address string to get WalletAddresses.Id
- Only active wallets with shown assets appear (CustomerWalletsView filters)
- The Address-based JOIN means wallets without a WalletAddresses record matching their public address are excluded

---

## 3. Data Overview

| Id | WalletAddressesId | DateFrom | DateTo | Balance | CryptoId | Meaning |
|---|---|---|---|---|---|---|
| 6133042 | 2363973 | 2025-11-03 | 3000-01-01 | 1.200001 | 4 (XRP) | Current XRP balance snapshot mapped to address record 2363973. The 3000-01-01 DateTo marks it as the latest snapshot. |
| 6133041 | 1250988 | 2026-04-15 | 3000-01-01 | 0.002103 | 107 | Current balance for crypto 107 (USDC). Very recent snapshot. |
| 6133040 | 1252814 | 2026-04-15 | 3000-01-01 | 0.000055 | 2 (ETH) | Current ETH balance - dust amount, mapped to a specific address record. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Balance snapshot surrogate key. From Wallet.WalletBalances.Id. |
| 2 | WalletAddressesId | bigint | NO | - | CODE-BACKED | The specific WalletAddresses record for this balance's blockchain address. Resolved by JOIN WalletAddresses ON Address = CustomerWalletsView.Address. From Wallet.WalletAddresses.Id. |
| 3 | DateFrom | datetime2(7) | NO | - | CODE-BACKED | Start of balance snapshot validity window. From Wallet.WalletBalances.DateFrom. |
| 4 | DateTo | datetime2(7) | NO | - | CODE-BACKED | End of balance snapshot validity window. 3000-01-01 = current balance. From Wallet.WalletBalances.DateTo. |
| 5 | Balance | decimal(36,18) | YES | - | VERIFIED | Confirmed crypto balance in native units. From Wallet.WalletBalances.Balance. |
| 6 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency. From Wallet.WalletBalances.CryptoId. FK to Wallet.CryptoTypes.CryptoID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Id, DateFrom, DateTo, Balance, CryptoId | Wallet.WalletBalances | JOIN (source) | Balance snapshot data |
| WalletId, CryptoId | Wallet.CustomerWalletsView | JOIN | Resolves wallet address for address matching |
| Address | Wallet.WalletAddresses | JOIN | Resolves WalletAddressesId by matching public address string |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this view.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.vw_WalletBalanaces (view)
+-- Wallet.WalletBalances (table)
+-- Wallet.CustomerWalletsView (view)
|   +-- Wallet.Wallets (table)
|   +-- Wallet.WalletPool (table)
|   +-- Wallet.WalletAssets (table)
+-- Wallet.WalletAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletBalances | Table | Source of balance snapshots |
| Wallet.CustomerWalletsView | View | Resolves wallet public address |
| Wallet.WalletAddresses | Table | Resolves WalletAddressesId by address match |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get current balance by wallet address ID
```sql
SELECT WalletAddressesId, CryptoId, Balance
FROM Wallet.vw_WalletBalanaces WITH (NOLOCK)
WHERE DateTo = '3000-01-01'
  AND WalletAddressesId = 2363973
```

### 8.2 Balance history for a specific address
```sql
SELECT DateFrom, DateTo, Balance
FROM Wallet.vw_WalletBalanaces WITH (NOLOCK)
WHERE WalletAddressesId = 1252814
ORDER BY DateFrom DESC
```

### 8.3 Current non-zero balances with crypto details
```sql
SELECT vw.WalletAddressesId, ct.CryptoName, vw.Balance
FROM Wallet.vw_WalletBalanaces vw WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = vw.CryptoId
WHERE vw.DateTo = '3000-01-01'
  AND vw.Balance > 0
ORDER BY vw.Balance DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.vw_WalletBalanaces | Type: View | Source: WalletDB/Wallet/Views/Wallet.vw_WalletBalanaces.sql*
