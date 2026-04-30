# Wallet.GetReceivedTransactionByBlockchainId

> Retrieves received transaction details by blockchain transaction ID, enabling lookup of inbound transfers recorded on the blockchain.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns received transactions matching a blockchain transaction hash |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure looks up received (inbound) crypto transactions by their blockchain transaction ID (hash). When the system detects an on-chain transaction or needs to verify a deposit, it uses the blockchain transaction ID as the lookup key to find the corresponding record in the wallet system.

Without this procedure, there would be no way to quickly cross-reference blockchain transaction hashes with the wallet system's internal records. It supports both automated transaction processing (matching blockchain notifications to internal records) and customer support (verifying a customer's claimed deposit by transaction hash).

Data comes from `Wallet.ReceivedTransactions` filtered by BlockchainTransactionId. The procedure uses NOLOCK for non-blocking reads. Note: the @FromDate parameter is declared but not used in the WHERE clause (legacy parameter kept for backward compatibility).

Granted to `BillingNotificationsUser`, indicating it is used by the billing notification system to verify received transactions.

---

## 2. Business Logic

### 2.1 Blockchain Hash Lookup

**What**: Simple lookup of received transactions by blockchain transaction hash.

**Columns/Parameters Involved**: `@BlockchainTransactionId`, `ReceivedTransactions.BlockchainTransactionId`

**Rules**:
- Exact match on BlockchainTransactionId (nvarchar 100)
- May return multiple rows if the same blockchain transaction ID maps to multiple received transaction records (e.g., multi-output transactions)
- @FromDate parameter is declared but NOT used in the query (legacy, not applied)
- Uses NOLOCK hint for non-blocking reads

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BlockchainTransactionId | nvarchar(100) | NO | - | CODE-BACKED | The blockchain transaction hash to search for. Matches against ReceivedTransactions.BlockchainTransactionId. |
| 2 | @FromDate | datetime | YES | NULL | CODE-BACKED | Legacy parameter - declared but NOT used in the WHERE clause. Kept for backward compatibility with existing callers. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Occurred | datetime2(7) | NO | - | CODE-BACKED | Timestamp when the received transaction was recorded in the wallet system. |
| 2 | WalletId | uniqueidentifier | NO | - | CODE-BACKED | The wallet that received the transaction. FK to Wallet.Wallets. |
| 3 | SenderAddress | nvarchar | YES | - | CODE-BACKED | Blockchain address of the sender. May be NULL for certain blockchain types. |
| 4 | ReceiverAddress | nvarchar | NO | - | CODE-BACKED | Blockchain address that received the funds. |
| 5 | Amount | decimal | NO | - | CODE-BACKED | Amount of crypto received in this transaction. |
| 6 | BlockchainFee | decimal | YES | - | CODE-BACKED | Blockchain network fee associated with this transaction. |
| 7 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Correlation identifier linking this received transaction to the request pipeline. |
| 8 | BlockchainTransactionId | nvarchar(100) | NO | - | CODE-BACKED | The blockchain transaction hash (echoed back from input for confirmation). |
| 9 | BlockchainTransactionDate | datetime2(7) | YES | - | CODE-BACKED | Timestamp of the transaction on the blockchain (block time), as opposed to Occurred (system recording time). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Wallet.ReceivedTransactions | FROM | Main data source for received transaction lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BillingNotificationsUser | GRANT EXECUTE | Permission | Billing notification system verifies received transactions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetReceivedTransactionByBlockchainId (procedure)
└── Wallet.ReceivedTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ReceivedTransactions | Table | SELECT with NOLOCK - lookup by BlockchainTransactionId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (BillingNotificationsUser service) | External | Calls to verify received transactions by blockchain hash |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK hint | Read isolation | Non-blocking read for real-time lookups |
| Unused parameter | Legacy | @FromDate is declared but not referenced in the query |

---

## 8. Sample Queries

### 8.1 Look up a received transaction by blockchain hash
```sql
EXEC Wallet.GetReceivedTransactionByBlockchainId
    @BlockchainTransactionId = '0xabc123def456...';
```

### 8.2 Find all received transactions for a specific blockchain hash with status
```sql
SELECT rt.BlockchainTransactionId, rt.WalletId, rt.Amount, rt.ReceiverAddress,
    rts.StatusId AS LatestStatus
FROM Wallet.ReceivedTransactions rt WITH (NOLOCK)
    CROSS APPLY (
        SELECT TOP 1 StatusId FROM Wallet.ReceivedTransactionStatuses WITH (NOLOCK)
        WHERE ReceivedTransactionId = rt.Id ORDER BY Id DESC
    ) rts
WHERE rt.BlockchainTransactionId = '0xabc123def456...';
```

### 8.3 Count received transactions per blockchain hash (detect duplicates)
```sql
SELECT BlockchainTransactionId, COUNT(*) AS RecordCount
FROM Wallet.ReceivedTransactions WITH (NOLOCK)
GROUP BY BlockchainTransactionId
HAVING COUNT(*) > 1
ORDER BY RecordCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetReceivedTransactionByBlockchainId | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetReceivedTransactionByBlockchainId.sql*
