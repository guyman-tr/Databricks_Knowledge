# Wallet.vu_GetWalletBalanceReportV2

> V2 of the wallet balance reconciliation view - identical logic to vu_GetWalletBalanceReport but excludes CryptoId 228 and uses DECIMAL(19,10) precision for TotalBalance instead of DECIMAL(36,18).

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | View |
| **Key Identifier** | WalletId (uniqueidentifier) + CryptoId (int) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view is the V2 iteration of the wallet balance reconciliation report (see [Wallet.vu_GetWalletBalanceReport](Wallet.vu_GetWalletBalanceReport.md) for full business context). It computes TotalReceived, TotalSent, TotalBalance, and TotalAmount for every active customer wallet, enabling discrepancy detection between transaction-based and provider-reported balances.

Two differences from V1:
1. **CryptoId 228 exclusion**: The Customers CTE filters `WHERE T1.CryptoId <> 228`, excluding a specific crypto asset (likely a test, deprecated, or special-purpose token) from the reconciliation
2. **Reduced TotalBalance precision**: Casts TotalBalance to `DECIMAL(19,10)` instead of V1's `DECIMAL(36,18)`, reducing storage precision. This may be optimized for specific downstream consumers that don't need sub-satoshi precision

All other logic (Receives CTE, Sends CTE with UTXO handling, Balance CTE, XRP reserve deduction, IsEtoroHandlingFee logic) is identical to V1.

---

## 2. Business Logic

### 2.1 CryptoId 228 Exclusion

**What**: This version excludes CryptoId 228 from the reconciliation scope.

**Columns/Parameters Involved**: `CryptoId`

**Rules**:
- `WHERE T1.CryptoId <> 228` in the Customers CTE
- CryptoId 228 wallets are excluded from all calculations (receives, sends, balance)
- This likely excludes a test or deprecated token that would create noise in reconciliation

### 2.2 Balance Precision

**What**: TotalBalance uses reduced precision.

**Columns/Parameters Involved**: `TotalBalance`

**Rules**:
- V1: `CAST(ISNULL(b.total_balance, 0) AS DECIMAL(36, 18))`
- V2: `CAST(ISNULL(b.total_balance, 0) AS DECIMAL(19, 10))`
- 10 decimal places is sufficient for most cryptos (Bitcoin uses 8, Ethereum uses 18 but most practical amounts fit in 10)

### 2.3 All Other Logic

See [Wallet.vu_GetWalletBalanceReport](Wallet.vu_GetWalletBalanceReport.md) Section 2 for: Transaction-Based vs Snapshot Balance, XRP Activation Reserve, Fee Handling for eToro-Managed Fees.

---

## 3. Data Overview

| WalletId (truncated) | Gcid | CryptoId | TotalRecive | TotalSend | TotalBalance | TotalAmount | Meaning |
|---|---|---|---|---|---|---|---|
| 55AC9E57-... | 9248755 | 2 (ETH) | 0.1 | 0.099945 | 0.000055 | 0.000055 | ETH wallet with perfect reconciliation: received 0.1, sent 0.099945, dust remainder matches both TotalBalance and TotalAmount. |
| 0350C985-... | 7624226 | 2 (ETH) | 0.1 | 0.01 | 0.09 | 0.09 | ETH wallet: received 0.1, sent 0.01, remaining 0.09. No discrepancy. TotalBalance precision is DECIMAL(19,10). |
| 3FB081AB-... | 6630253 | 2 (ETH) | 0.1 | 0.099945 | 0.000055 | 0.000055 | Another dust-balance ETH wallet. CryptoId 228 rows are excluded from this version. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WalletId | uniqueidentifier | NO | - | VERIFIED | The wallet being reconciled. From CustomerWalletsView.Id. |
| 2 | Gcid | bigint | NO | - | VERIFIED | Global Customer ID. From CustomerWalletsView.Gcid. |
| 3 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency (excluding 228). From CustomerWalletsView.CryptoId. FK to Wallet.CryptoTypes.CryptoID. |
| 4 | Address | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address. From CustomerWalletsView.Address. |
| 5 | BitgoWalletId | nvarchar(100) | NO | - | CODE-BACKED | Provider wallet identifier. From CustomerWalletsView.BlockchainProviderWalletId. |
| 6 | TotalRecive | decimal | NO | - | CODE-BACKED | Total crypto received (verified + pending, no self-receives). ISNULL defaults to 0. Legacy misspelling preserved. |
| 7 | TotalSend | decimal | NO | - | CODE-BACKED | Total crypto sent (verified + pending, including fees if not eToro-managed). ISNULL defaults to 0. |
| 8 | TotalBalance | decimal(19,10) | NO | - | VERIFIED | Current provider-reported balance. DECIMAL(19,10) precision (reduced from V1's 36,18). ISNULL defaults to 0. |
| 9 | TotalAmount | decimal | NO | - | CODE-BACKED | Expected balance: TotalRecive - TotalSend - XRP_reserve. Discrepancy = TotalAmount - TotalBalance. |
| 10 | LastSentOccurred | datetime2(7) | YES | - | CODE-BACKED | Timestamp of most recent sent transaction. NULL if no sends. |
| 11 | LastReceivedOccurred | datetime2(7) | YES | - | CODE-BACKED | Timestamp of most recent received transaction. NULL if no receives. |

---

## 5. Relationships

### 5.1 References To (this object points to)

Same as [Wallet.vu_GetWalletBalanceReport](Wallet.vu_GetWalletBalanceReport.md) Section 5.1.

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this view.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.vu_GetWalletBalanceReportV2 (view)
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

Same as [Wallet.vu_GetWalletBalanceReport](Wallet.vu_GetWalletBalanceReport.md) Section 6.1.

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

### 8.1 Find wallets with balance discrepancies (excluding CryptoId 228)
```sql
SELECT WalletId, Gcid, CryptoId, TotalRecive, TotalSend, TotalBalance, TotalAmount,
    TotalAmount - TotalBalance AS Discrepancy
FROM Wallet.vu_GetWalletBalanceReportV2 WITH (NOLOCK)
WHERE ABS(TotalAmount - TotalBalance) > 0.00001
  AND Gcid > 0
ORDER BY ABS(TotalAmount - TotalBalance) DESC
```

### 8.2 Verify CryptoId 228 is excluded
```sql
SELECT DISTINCT CryptoId
FROM Wallet.vu_GetWalletBalanceReportV2 WITH (NOLOCK)
WHERE CryptoId = 228
-- Should return 0 rows
```

### 8.3 Compare V1 vs V2 precision for a wallet
```sql
SELECT v1.TotalBalance AS V1_Balance_36_18, v2.TotalBalance AS V2_Balance_19_10
FROM Wallet.vu_GetWalletBalanceReport v1 WITH (NOLOCK)
JOIN Wallet.vu_GetWalletBalanceReportV2 v2 WITH (NOLOCK)
    ON v1.WalletId = v2.WalletId AND v1.CryptoId = v2.CryptoId
WHERE v1.Gcid = 9248755
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.vu_GetWalletBalanceReportV2 | Type: View | Source: WalletDB/Wallet/Views/Wallet.vu_GetWalletBalanceReportV2.sql*
