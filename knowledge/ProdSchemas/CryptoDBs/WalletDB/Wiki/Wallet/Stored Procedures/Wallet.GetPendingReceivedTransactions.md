# Wallet.GetPendingReceivedTransactions

> Retrieves received crypto transactions still in a pending state (statuses 0, 1, or 3 only) from the last 3 months, enriched with wallet and transaction context.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns pending received transactions with wallet and status details |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure finds incoming crypto transactions that are still being processed and have not yet reached a terminal state. The processing service polls this to find transactions that need continued monitoring - checking blockchain confirmations, updating balances, or completing downstream processing.

"Pending" is defined as transactions whose ENTIRE status history contains only statuses 0, 1, and 3 (no terminal statuses like Done, Failed, etc.). This ensures the procedure only returns truly in-flight transactions, not ones that were once pending but have since completed. The 3-month lookback window prevents scanning the full historical table.

Data uses a temp table approach: first finds ReceivedTransactionStatuses entries from the last 3 months that have no non-pending status, then joins to ReceivedTransactions and CustomerWalletsView for full context. A LEFT JOIN to SentTransactions provides TransactionTypeId when the received transaction corresponds to a known sent transaction.

---

## 2. Business Logic

### 2.1 Pending Status Definition

**What**: Transactions are pending when their entire status history only contains pending-class statuses.

**Columns/Parameters Involved**: `StatusId`, `ReceivedTransactionId`

**Rules**:
- Statuses 0, 1, 3 are the "pending" statuses (0=New, 1=Pending, 3=Processing or similar)
- NOT EXISTS with StatusId NOT IN (0, 1, 3) ensures NO terminal status exists for this transaction
- RANK() OVER PARTITION BY ReceivedTransactionId ORDER BY Id DESC gets the latest status
- rnk=1 in the JOIN ensures only the most recent status is reported
- 3-month lookback: @From = DATEADD(MONTH, -3, GETUTCDATE())

### 2.2 Transaction Type Resolution

**What**: Determines if the received transaction corresponds to a known sent transaction.

**Columns/Parameters Involved**: `BlockchainTransactionId`, `TransactionTypeId`

**Rules**:
- LEFT JOIN SentTransactions ON BlockchainTransactionId matches received and sent sides of the same on-chain transaction
- When matched, st.TransactionTypeId provides classification (e.g., customer send, redemption, etc.)
- When not matched (NULL), the receive is from an external source

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxResultsToReturn | INT | YES | 100 | CODE-BACKED | Maximum number of pending transactions to return. Default 100. Controls batch size for the processing service. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | Id | BIGINT | NO | - | CODE-BACKED | ReceivedTransactions record ID. |
| 3 | BlockchainTransactionId | NVARCHAR | YES | - | CODE-BACKED | On-chain transaction hash/ID. Used to check confirmation status on the blockchain. |
| 4 | WalletId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Receiving wallet ID. FK to Wallet.Wallets. |
| 5 | StatusId | INT | NO | - | CODE-BACKED | Latest status ID (0, 1, or 3). From the temp table ranked results. |
| 6 | CorrelationId | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Correlation ID linking to the broader request flow. |
| 7 | BlockchainProviderWalletId | NVARCHAR | YES | - | CODE-BACKED | Custody provider wallet ID for the receiving wallet. |
| 8 | Occurred | DATETIME2 | NO | - | CODE-BACKED | When the received transaction was recorded in the system. |
| 9 | BlockchainTransactionDate | DATETIME2 | YES | - | CODE-BACKED | When the transaction occurred on the blockchain (may differ from Occurred). |
| 10 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency. FK to Wallet.CryptoTypes. |
| 11 | Amount | DECIMAL | NO | - | CODE-BACKED | Amount of crypto received. |
| 12 | SenderAddress | NVARCHAR | YES | - | CODE-BACKED | Blockchain address that sent the crypto. |
| 13 | ReceiverAddress | NVARCHAR | YES | - | CODE-BACKED | Blockchain address that received the crypto. |
| 14 | Gcid | BIGINT | NO | - | CODE-BACKED | Customer's Global ID from CustomerWalletsView. |
| 15 | TransactionTypeId | INT | YES | - | CODE-BACKED | Transaction type from the corresponding sent transaction (if any). NULL for external receives. |
| 16 | ReceivedTransactionTypeId | INT | YES | - | CODE-BACKED | Receive-specific transaction type classification. |
| 17 | WalletProviderId | INT | NO | - | CODE-BACKED | Custody provider ID. FK to Dictionary.WalletProvider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.ReceivedTransactionStatuses | Temp table | Finds pending statuses from last 3 months |
| - | Wallet.ReceivedTransactions | JOIN | Transaction details |
| WalletId + CryptoId | Wallet.CustomerWalletsView | JOIN | Wallet and customer context |
| BlockchainTransactionId | Wallet.SentTransactions | LEFT JOIN | Transaction type resolution |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by the received transaction processing service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPendingReceivedTransactions (procedure)
+-- Wallet.ReceivedTransactionStatuses (table)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.SentTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ReceivedTransactionStatuses | Table | Temp table source - status filtering |
| Wallet.ReceivedTransactions | Table | JOIN - transaction details |
| Wallet.CustomerWalletsView | View | JOIN - wallet/customer context |
| Wallet.SentTransactions | Table | LEFT JOIN - transaction type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Temp table | #temp | Pre-filters pending statuses from last 3 months for efficient JOIN |

---

## 8. Sample Queries

### 8.1 Get pending received transactions
```sql
EXEC Wallet.GetPendingReceivedTransactions @MaxResultsToReturn = 50;
```

### 8.2 Count pending receives by status
```sql
SELECT tmp.StatusId, COUNT(*) AS PendingCount
FROM (
    SELECT ReceivedTransactionId, StatusId, RANK() OVER (PARTITION BY ReceivedTransactionId ORDER BY Id DESC) rnk
    FROM Wallet.ReceivedTransactionStatuses WITH (NOLOCK)
    WHERE Occurred > DATEADD(MONTH, -3, GETUTCDATE())
        AND NOT EXISTS (SELECT 1 FROM Wallet.ReceivedTransactionStatuses b WITH (NOLOCK)
            WHERE b.ReceivedTransactionId = Wallet.ReceivedTransactionStatuses.ReceivedTransactionId AND b.StatusId NOT IN (0,1,3))
) tmp WHERE tmp.rnk = 1
GROUP BY tmp.StatusId;
```

### 8.3 Find oldest pending received transactions
```sql
SELECT TOP 5 rt.Id, rt.Occurred, rt.CryptoId, rt.Amount, DATEDIFF(HOUR, rt.Occurred, GETUTCDATE()) AS HoursPending
FROM Wallet.ReceivedTransactions rt WITH (NOLOCK)
WHERE rt.Occurred > DATEADD(MONTH, -3, GETUTCDATE())
ORDER BY rt.Occurred ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPendingReceivedTransactions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetPendingReceivedTransactions.sql*
