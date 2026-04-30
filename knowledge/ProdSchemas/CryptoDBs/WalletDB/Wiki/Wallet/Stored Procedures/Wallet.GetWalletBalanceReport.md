# Wallet.GetWalletBalanceReport

> Generates a comprehensive balance report for all customer wallets by computing total received, total sent (including blockchain fees), and cached balance using CTEs across five core tables.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns balance report for all wallets with receive/send/balance totals |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure generates a platform-wide wallet balance report by computing three balance components for every customer wallet: total received (sum of ReceivedTransactions amounts), total sent (sum of SentTransactionOutputs amounts + blockchain fees), and latest cached balance (from WalletBalances). It also calculates total_amount as received minus sent, revealing any discrepancy with the cached balance.

The balance service uses this for reconciliation - comparing the computed (receive - send) balance against the cached balance to detect inconsistencies. The procedure uses four CTEs: Customers (base wallet list), Receives (aggregated inbound), Sends (aggregated outbound), and Balance (latest cached value per wallet).

---

## 2. Business Logic

### 2.1 Balance Reconciliation Formula

**What**: Computes expected balance from transaction history and compares to cached balance.

**Columns/Parameters Involved**: `total_recive`, `total_send`, `total_balance`, `total_amount`

**Rules**:
- total_recive = SUM(ReceivedTransactions.Amount) per wallet per crypto, rounded to 8 decimals
- total_send = SUM(SentTransactionOutputs.Amount) + SUM(SentTransactions.BlockchainFee) per wallet per crypto, rounded to 8 decimals
- total_balance = latest WalletBalances.Balance (ROW_NUMBER partitioned by WalletId+CryptoId, ordered by Id DESC)
- total_amount = total_recive - total_send (computed balance from transaction history)
- When total_amount != total_balance, a reconciliation discrepancy exists

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WalletId (output) | uniqueidentifier | NO | - | CODE-BACKED | Customer wallet ID. |
| 2 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer ID. |
| 3 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency. FK to Wallet.CryptoTypes. |
| 4 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Primary wallet address from WalletAddresses. |
| 5 | BlockchainProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider's reference for this wallet. |
| 6 | BalanceAccountID (output) | nvarchar | YES | - | CODE-BACKED | Provider balance account ID. |
| 7 | total_recive (output) | decimal | YES | 0 | CODE-BACKED | Sum of all received amounts, rounded to 8 decimals. Note: column name has legacy typo. |
| 8 | total_send (output) | decimal | YES | 0 | CODE-BACKED | Sum of all sent output amounts + blockchain fees, rounded to 8 decimals. |
| 9 | total_balance (output) | decimal | YES | 0 | CODE-BACKED | Latest cached balance from WalletBalances (most recent record). |
| 10 | total_amount (output) | decimal | YES | 0 | CODE-BACKED | Computed balance: total_recive - total_send. Discrepancy with total_balance indicates reconciliation issue. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.CustomerWalletsView | CTE (Customers) | Base wallet list |
| - | Wallet.WalletAddresses | LEFT JOIN | Address details |
| - | Wallet.ReceivedTransactions | CTE (Receives) | Total received aggregation |
| - | Wallet.SentTransactions + SentTransactionOutputs | CTE (Sends) | Total sent aggregation |
| - | Wallet.WalletBalances + WalletAddresses | CTE (Balance) | Latest cached balance |
| - | Dictionary.TransactionTypes | JOIN | Transaction type filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BalanceUser | - | EXECUTE | Reconciliation reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletBalanceReport (procedure)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.WalletAddresses (table)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionOutputs (table)
+-- Wallet.WalletBalances (table)
+-- Dictionary.TransactionTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Base wallet list |
| Wallet.WalletAddresses | Table | Address details + balance lookup |
| Wallet.ReceivedTransactions | Table | Receive amount aggregation |
| Wallet.SentTransactions | Table | Send amount + fee aggregation |
| Wallet.SentTransactionOutputs | Table | Output amount aggregation |
| Wallet.WalletBalances | Table | Latest cached balance |
| Dictionary.TransactionTypes | Table | Transaction type classification |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BalanceUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses 4 CTEs for modular computation.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run the full balance report
```sql
EXEC Wallet.GetWalletBalanceReport;
```

### 8.2 Find discrepancies
```sql
-- After running the SP, filter for mismatches:
-- WHERE ABS(total_amount - total_balance) > 0.00000001
```

### 8.3 Check a specific wallet's balance components
```sql
SELECT SUM(Amount) AS TotalReceived
FROM Wallet.ReceivedTransactions WITH (NOLOCK)
WHERE WalletId = 'C0D5EF83-...' AND CryptoId = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletBalanceReport | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletBalanceReport.sql*
