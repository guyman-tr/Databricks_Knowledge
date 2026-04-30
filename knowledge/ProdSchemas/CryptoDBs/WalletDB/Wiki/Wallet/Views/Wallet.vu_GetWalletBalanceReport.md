# Wallet.vu_GetWalletBalanceReport

> Balance reconciliation view computing TotalReceived, TotalSent, TotalBalance, and a derived TotalAmount for every active customer wallet, enabling discrepancy detection between transaction-based and provider-reported balances.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | View |
| **Key Identifier** | WalletId (uniqueidentifier) + CryptoId (int) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view is a balance reconciliation tool that computes the expected balance for every active customer wallet from two independent sources: (1) summing all received and sent transaction amounts ("transaction-based balance"), and (2) reading the provider-reported balance from WalletBalances ("snapshot balance"). By presenting both side by side, it enables detection of discrepancies that could indicate missed transactions, double-counted amounts, or provider sync issues.

Without this view, finance and operations teams would need to manually calculate received totals, sent totals, and compare them against the latest balance snapshot for each wallet - a process involving complex joins across transaction tables with status filtering and self-send exclusion logic. The view encapsulates all of this.

The view uses 4 CTEs: Customers (from CustomerWalletsView - all active customer wallets), Receives (summed received amounts with Verified/Pending status), Sends (summed sent amounts including blockchain fees, with special UTXO handling for ETH/XRP CryptoId 4,21), and Balance (current snapshot from WalletBalances where DateTo='3000-01-01'). These are LEFT JOINed to ensure every customer wallet appears even if it has no transactions or balance. The TotalAmount column computes `TotalReceived - TotalSent` with a special 0.0225 deduction for CryptoId=4 (XRP activation reserve).

---

## 2. Business Logic

### 2.1 Transaction-Based vs Snapshot Balance

**What**: The view computes a "transaction-based" expected balance and shows it alongside the "snapshot" balance for reconciliation.

**Columns/Parameters Involved**: `TotalRecive`, `TotalSend`, `TotalBalance`, `TotalAmount`

**Rules**:
- `TotalRecive`: SUM of all received amounts where the latest status is Verified(1) or Pending(2), excluding self-receives (NormalizedSenderAddress != own addresses)
- `TotalSend`: SUM of all sent amounts (from SentTransactionOutputs) where status is Pending(1) or Verified(2), plus blockchain fees for those statuses. Special case: for CryptoId 4 (XRP) and 21, status 3/5/6 transactions only count BlockchainFees (not amount)
- `TotalBalance`: Current provider-reported balance from WalletBalances (DateTo='3000-01-01'). Cast to DECIMAL(36,18)
- `TotalAmount`: `TotalRecive - TotalSend - (0.0225 if CryptoId=4 else 0)` - the expected balance based on transactions minus the XRP activation reserve

**Diagram**:
```
TotalRecive = SUM(ReceivedTransactions.Amount) [verified/pending, no self-receives]
TotalSend   = SUM(SentOutputs.Amount + Fees) [verified/pending, excl self-sends]
TotalBalance = WalletBalances.Balance (current snapshot)
TotalAmount  = TotalRecive - TotalSend - XRP_reserve

Discrepancy = TotalAmount - TotalBalance (should be ~0)
```

### 2.2 XRP Activation Reserve

**What**: XRP wallets require a 0.0225 XRP reserve to keep the account activated on the XRP Ledger.

**Columns/Parameters Involved**: `CryptoId`, `TotalAmount`

**Rules**:
- When CryptoId = 4 (XRP): TotalAmount deducts 0.0225 from the transaction-based balance
- This accounts for the XRP ledger's reserve requirement that locks a small amount and makes it unspendable
- Other cryptos have no reserve deduction

### 2.3 Fee Handling for eToro-Managed Fees

**What**: For cryptos where eToro handles blockchain fees (IsEtoroHandlingFee), fees are excluded from the TotalSend calculation.

**Columns/Parameters Involved**: `IsEtoroHandlingFee` (from CryptoTypes), `total_fee`, `TotalSend`

**Rules**:
- `IsEtoroHandlingFee = 0`: Blockchain fees ARE included in TotalSend (user pays)
- `IsEtoroHandlingFee = 1`: Blockchain fees are NOT included in TotalSend (eToro absorbs the fee)
- `TotalSend = total_send + CASE WHEN IsEtoroHandlingFee = 0 THEN total_fee ELSE 0 END`

---

## 3. Data Overview

| WalletId (truncated) | Gcid | CryptoId | TotalRecive | TotalSend | TotalBalance | TotalAmount | Meaning |
|---|---|---|---|---|---|---|---|
| 55AC9E57-... | 9248755 | 2 (ETH) | 0.1 | 0.099945 | 0.000055 | 0.000055 | ETH wallet with perfect reconciliation: received 0.1, sent 0.099945, remaining dust of 0.000055 matches both TotalBalance and TotalAmount. |
| 0350C985-... | 7624226 | 2 (ETH) | 0.1 | 0.01 | 0.09 | 0.09 | ETH wallet: received 0.1, sent 0.01, remaining 0.09. TotalBalance matches TotalAmount - no discrepancy. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WalletId | uniqueidentifier | NO | - | VERIFIED | The wallet being reconciled. From CustomerWalletsView.Id. Primary identifier for each row. |
| 2 | Gcid | bigint | NO | - | VERIFIED | Global Customer ID. From CustomerWalletsView.Gcid. Only active customer wallets included. |
| 3 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency being reconciled. From CustomerWalletsView.CryptoId. FK to Wallet.CryptoTypes.CryptoID. |
| 4 | Address | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address of the wallet. From CustomerWalletsView.Address. |
| 5 | BitgoWalletId | nvarchar(100) | NO | - | CODE-BACKED | Provider wallet identifier. Aliased from CustomerWalletsView.BlockchainProviderWalletId. Named "Bitgo" for legacy reasons but applies to all providers. |
| 6 | TotalRecive | decimal | NO | - | CODE-BACKED | Total crypto received by this wallet (verified + pending transactions, excluding self-receives). ISNULL defaults to 0. Uses ROUND(..., 8, 1) for precision. Legacy misspelling of "Receive" preserved. |
| 7 | TotalSend | decimal | NO | - | CODE-BACKED | Total crypto sent from this wallet (verified + pending, including blockchain fees if not eToro-managed). ISNULL defaults to 0. Includes special UTXO handling for XRP/ETH. |
| 8 | TotalBalance | decimal(36,18) | NO | - | VERIFIED | Current provider-reported balance from WalletBalances (DateTo='3000-01-01'). ISNULL defaults to 0. This is the "actual" balance to compare against TotalAmount. |
| 9 | TotalAmount | decimal | NO | - | CODE-BACKED | Expected balance from transactions: TotalRecive - TotalSend - XRP_reserve. When this differs from TotalBalance, a reconciliation discrepancy exists. |
| 10 | LastSentOccurred | datetime2(7) | YES | - | CODE-BACKED | Timestamp of the most recent sent transaction for this wallet. NULL if no sends. From MAX(SentTransactions.Occurred). |
| 11 | LastReceivedOccurred | datetime2(7) | YES | - | CODE-BACKED | Timestamp of the most recent received transaction for this wallet. NULL if no receives. From MAX(ReceivedTransactions.Occurred). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletId | Wallet.CustomerWalletsView | CTE source | All active customer wallets |
| Receives | Wallet.ReceivedTransactions | CTE aggregation | Summed received amounts |
| Receives | Wallet.ReceivedTransactionStatuses | CROSS APPLY | Verified/pending status filter |
| Receives | Wallet.WalletAddresses | Subquery | Self-receive exclusion |
| Sends | Wallet.SentTransactions | CTE aggregation | Sent transaction amounts |
| Sends | Wallet.SentTransactionOutputs | JOIN | Output amounts and fees |
| Sends | Wallet.SentTransactionStatuses | CROSS APPLY | Status filter |
| Sends | Dictionary.TransactionTypes | JOIN | Transaction type filter |
| Sends | Wallet.CryptoTypes | JOIN | Crypto type info |
| Balance | Wallet.WalletBalances | CTE | Current snapshot balance |
| (final) | Wallet.CryptoTypes | LEFT JOIN | IsEtoroHandlingFee flag |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this view. Consumed by finance/operations reconciliation tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.vu_GetWalletBalanceReport (view)
+-- Wallet.CustomerWalletsView (view)
|   +-- Wallet.Wallets (table)
|   +-- Wallet.WalletPool (table)
|   +-- Wallet.WalletAssets (table)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.ReceivedTransactionStatuses (table)
+-- Wallet.WalletAddresses (table)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionOutputs (table)
+-- Wallet.SentTransactionStatuses (table)
+-- Wallet.WalletBalances (table)
+-- Wallet.CryptoTypes (table)
+-- Dictionary.TransactionTypes (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | CTE: Customers - all active wallets |
| Wallet.ReceivedTransactions | Table | CTE: Receives - incoming amounts |
| Wallet.ReceivedTransactionStatuses | Table | Status filter for receives |
| Wallet.WalletAddresses | Table | Self-receive exclusion |
| Wallet.SentTransactions | Table | CTE: Sends - outgoing amounts |
| Wallet.SentTransactionOutputs | Table | Output amounts and fees |
| Wallet.SentTransactionStatuses | Table | Status filter for sends |
| Wallet.WalletBalances | Table | CTE: Balance - current snapshot |
| Wallet.CryptoTypes | Table | IsEtoroHandlingFee flag |
| Dictionary.TransactionTypes | Table (cross-schema) | Transaction type JOIN |

### 6.2 Objects That Depend On This

No dependents found. Consumed by external reconciliation tools.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find wallets with balance discrepancies
```sql
SELECT WalletId, Gcid, CryptoId, TotalRecive, TotalSend, TotalBalance, TotalAmount,
    TotalAmount - TotalBalance AS Discrepancy
FROM Wallet.vu_GetWalletBalanceReport WITH (NOLOCK)
WHERE ABS(TotalAmount - TotalBalance) > 0.00001
  AND Gcid > 0
ORDER BY ABS(TotalAmount - TotalBalance) DESC
```

### 8.2 Get balance summary for a specific customer
```sql
SELECT CryptoId, Address, TotalRecive, TotalSend, TotalBalance, LastSentOccurred, LastReceivedOccurred
FROM Wallet.vu_GetWalletBalanceReport WITH (NOLOCK)
WHERE Gcid = 9248755
ORDER BY CryptoId
```

### 8.3 Identify inactive wallets with remaining balance
```sql
SELECT WalletId, Gcid, CryptoId, TotalBalance, LastSentOccurred, LastReceivedOccurred
FROM Wallet.vu_GetWalletBalanceReport WITH (NOLOCK)
WHERE TotalBalance > 0
  AND LastSentOccurred < DATEADD(month, -6, GETDATE())
  AND Gcid > 0
ORDER BY TotalBalance DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.vu_GetWalletBalanceReport | Type: View | Source: WalletDB/Wallet/Views/Wallet.vu_GetWalletBalanceReport.sql*
