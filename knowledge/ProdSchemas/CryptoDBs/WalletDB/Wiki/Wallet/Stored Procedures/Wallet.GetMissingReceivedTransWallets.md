# Wallet.GetMissingReceivedTransWallets

> Identifies eToro customer wallets that received crypto via a sent transaction output but have no corresponding received transaction record, indicating a missing receive-side sync.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns wallet IDs missing received transaction records |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure detects a data integrity gap: when crypto is sent from one eToro wallet to another, the system should record both a sent transaction (sender side) and a received transaction (receiver side). This procedure finds cases where the sent transaction was confirmed (status=2) and the output address belongs to an eToro customer wallet, but no received transaction was created for that delivery. These missing records need to be back-filled to ensure accurate balance tracking.

Without detecting and fixing these gaps, the receiving wallet's transaction history would be incomplete, potentially causing balance discrepancies between the blockchain state and the internal ledger. This is a reconciliation and self-healing mechanism.

The procedure joins `Wallet.SentTransactions` to `Wallet.SentTransactionOutputs` (the individual outputs of a transaction), matches output addresses to eToro wallets via `Wallet.CustomerWalletsView`, and LEFT JOINs to `Wallet.ReceivedTransactions` to find missing records. Only confirmed sent transactions (latest StatusId=2) and non-fee outputs (IsEtoroFee=0) are checked.

---

## 2. Business Logic

### 2.1 Missing Receive Detection

**What**: Finds sent transaction outputs to eToro wallets without matching received transactions.

**Columns/Parameters Involved**: `BlockchainTransactionId`, `NormalizedReceiverAddress`, `NormalizedToAddress`, `IsEtoroFee`, `StatusId`

**Rules**:
- A sent transaction output goes to an eToro address (JOIN CustomerWalletsView on so.ToAddress = cw.Address)
- The destination wallet is NOT the sender (cw.Id <> st.WalletId - excludes change outputs back to sender)
- No received transaction exists for this blockchain tx + address combo (LEFT JOIN ReceivedTransactions IS NULL)
- Only confirmed sends: latest SentTransactionStatuses.StatusId = 2
- Fee outputs excluded: IsEtoroFee = 0 (network fees don't generate receive records)
- Only transactions since @FromDate (default 2018-01-01)

**Diagram**:
```
SentTransactions (confirmed, StatusId=2)
    |
    +-- SentTransactionOutputs (IsEtoroFee=0)
    |     |
    |     +-- ToAddress matches CustomerWalletsView.Address
    |     |     (destination is an eToro wallet, not the sender)
    |     |
    |     +-- LEFT JOIN ReceivedTransactions ON BlockchainTransactionId + NormalizedAddress
    |           -> IS NULL = MISSING receive record
    |
    v
Result: Wallet Id, ProviderWalletId, CryptoId (wallets needing receive sync)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME2(7) | YES | NULL (defaults to '2018-01-01') | CODE-BACKED | Start date for the search window. Only sent transactions with Occurred >= @FromDate are checked. Default of 2018-01-01 covers the platform's crypto history from inception. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | Id | BIGINT | NO | - | CODE-BACKED | The wallet record ID from CustomerWalletsView. Identifies the destination wallet missing the received transaction. |
| 3 | BlockchainProviderWalletId | NVARCHAR | YES | - | CODE-BACKED | Custody provider wallet ID for the receiving wallet. Backward-compatible column name. |
| 4 | ProviderWalletId | NVARCHAR | YES | - | CODE-BACKED | Same as BlockchainProviderWalletId (alias for backward compatibility). Used by sync services to query the provider for transaction details. |
| 5 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency of the receiving wallet. FK to Wallet.CryptoTypes. Needed to determine which blockchain to query for the missing transaction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.SentTransactions | FROM | Source of confirmed sent transactions |
| SentTransactionId | Wallet.SentTransactionOutputs | JOIN | Individual outputs per sent transaction |
| Address | Wallet.CustomerWalletsView | JOIN | Matches output addresses to eToro wallets |
| BlockchainTransactionId | Wallet.ReceivedTransactions | LEFT JOIN | Checks for missing received records |
| SentTransactionId | Wallet.SentTransactionStatuses | CROSS APPLY | Gets latest sent transaction status |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by reconciliation/sync services to detect and back-fill missing receive records.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetMissingReceivedTransWallets (procedure)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionOutputs (table)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.SentTransactionStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | FROM - confirmed sent transactions |
| Wallet.SentTransactionOutputs | Table | JOIN - individual outputs per transaction |
| Wallet.CustomerWalletsView | View | JOIN - matches addresses to eToro wallets |
| Wallet.ReceivedTransactions | Table | LEFT JOIN - detects missing received records |
| Wallet.SentTransactionStatuses | Table | CROSS APPLY - confirms sent transaction status |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find all wallets with missing received transactions
```sql
EXEC Wallet.GetMissingReceivedTransWallets;
```

### 8.2 Check for missing receives since a specific date
```sql
EXEC Wallet.GetMissingReceivedTransWallets @FromDate = '2026-01-01';
```

### 8.3 Count missing received transactions by crypto
```sql
-- Run the SP logic inline to aggregate
SELECT cw.CryptoId, ct.Name, COUNT(DISTINCT cw.Id) AS MissingWalletCount
FROM Wallet.SentTransactions st WITH (NOLOCK)
JOIN Wallet.SentTransactionOutputs so WITH (NOLOCK) ON so.SentTransactionId = st.Id AND so.IsEtoroFee = 0
JOIN Wallet.CustomerWalletsView cw WITH (NOLOCK) ON cw.Address = so.ToAddress AND cw.Id <> st.WalletId
LEFT JOIN Wallet.ReceivedTransactions rt WITH (NOLOCK) ON rt.BlockchainTransactionId = st.BlockchainTransactionId AND rt.NormalizedReceiverAddress = so.NormalizedToAddress
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = cw.CryptoId
CROSS APPLY (SELECT TOP 1 StatusId FROM Wallet.SentTransactionStatuses sts WITH (NOLOCK) WHERE sts.SentTransactionId = st.Id ORDER BY sts.Id DESC) sts
WHERE st.Occurred >= '2026-01-01' AND rt.Id IS NULL AND sts.StatusId = 2
GROUP BY cw.CryptoId, ct.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetMissingReceivedTransWallets | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetMissingReceivedTransWallets.sql*
