# Wallet.GetPendingSentTransactions

> Retrieves sent crypto transactions in pending state (statuses 0, 1, or 3 only) from the last 4 months, with two result formats: legacy (flat outputs) and AKS (JSON outputs).

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns pending sent transactions with outputs and wallet context |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure finds outgoing crypto transactions that are still being processed. The send monitoring service polls this to track blockchain confirmations, detect stuck transactions, and update statuses when sends complete or fail. It mirrors the pattern of `Wallet.GetPendingReceivedTransactions` but for the send side.

The @AksVersion flag supports two consuming services: the legacy service (@AksVersion=0) expects transaction outputs as flat joined rows, while the newer AKS (Azure Kubernetes Service) version (@AksVersion=1) expects outputs serialized as a JSON array per transaction. Both versions share the same pending-detection logic.

Data uses a temp table to pre-filter `Wallet.SentTransactionStatuses` for pending entries (4-month lookback), then joins to `Wallet.SentTransactions`, `Wallet.CustomerWalletsView`, and `Wallet.SentTransactionOutputs`.

---

## 2. Business Logic

### 2.1 Pending Status Definition

**What**: Sent transactions are pending when their entire status history contains only pending-class statuses.

**Columns/Parameters Involved**: `StatusId`, `SentTransactionId`

**Rules**:
- Statuses 0, 1, 3 are the "pending" statuses
- NOT EXISTS with StatusId NOT IN (0, 1, 3) ensures no terminal status exists
- RANK() partitioned by SentTransactionId ORDER BY Id DESC gets the latest status
- 4-month lookback: DATEADD(MONTH, -4, GETUTCDATE())
- Index IX_temp created on #temp(SentTransactionId) for efficient JOIN

### 2.2 Dual Output Format

**What**: Supports legacy (flat) and AKS (JSON) result formats.

**Columns/Parameters Involved**: `@AksVersion`, `Outputs`

**Rules**:
- @AksVersion=0 (default): INNER JOIN to SentTransactionOutputs produces one row per output (flat/denormalized). Includes per-output columns: ToAddress, Amount, EtoroFees, BlockchainFees, IsEtoroFee, SourceId, SourceIdType
- @AksVersion=1: Outputs are serialized as JSON via correlated subquery FOR JSON AUTO. One row per transaction with an Outputs JSON array column. Also adds BlockchainTransactionDate alias for Occurred

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxResultsToReturn | INT | YES | 100 | CODE-BACKED | Maximum transactions to return. Default 100. |
| 2 | @AksVersion | BIT | YES | 0 | CODE-BACKED | Output format flag: 0=legacy flat outputs (one row per output), 1=AKS JSON outputs (one row per transaction with Outputs JSON array). |

### Return Columns (Legacy - @AksVersion=0)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | Id | BIGINT | NO | - | CODE-BACKED | SentTransactions record ID. |
| 4 | BlockchainTransactionId | NVARCHAR | YES | - | CODE-BACKED | On-chain transaction hash. |
| 5 | WalletId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Sending wallet ID. |
| 6 | StatusId | INT | NO | - | CODE-BACKED | Latest pending status (0, 1, or 3). |
| 7 | CorrelationId | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Correlation ID for request tracking. |
| 8 | BlockchainProviderWalletId | NVARCHAR | YES | - | CODE-BACKED | Custody provider's wallet ID. |
| 9 | Address | NVARCHAR | YES | - | CODE-BACKED | Sending wallet's blockchain address. |
| 10 | Occurred | DATETIME2 | NO | - | CODE-BACKED | When the sent transaction was recorded. |
| 11 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency. FK to Wallet.CryptoTypes. |
| 12 | ToAddress | NVARCHAR | YES | - | CODE-BACKED | Destination address for this output. |
| 13 | Amount | DECIMAL | NO | - | CODE-BACKED | Crypto amount for this output. |
| 14 | EtoroFees | DECIMAL | YES | - | CODE-BACKED | eToro fee amount for this output. |
| 15 | BlockchainFees | DECIMAL | YES | - | CODE-BACKED | Blockchain network fee (ISNULL defaulted to 0). |
| 16 | IsEtoroFee | BIT | NO | - | CODE-BACKED | Whether this output is an eToro fee output (vs. the actual transfer). |
| 17 | SourceId | BIGINT | YES | - | CODE-BACKED | Source identifier linking the output to its origin (e.g., redemption ID). |
| 18 | SourceIdType | INT | YES | - | CODE-BACKED | Type of the SourceId reference. |
| 19 | TransactionTypeId | INT | YES | - | CODE-BACKED | Transaction type classification. |
| 20 | Gcid | BIGINT | NO | - | CODE-BACKED | Customer's Global ID. |
| 21 | WalletProviderId | INT | NO | - | CODE-BACKED | Custody provider ID. FK to Dictionary.WalletProvider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.SentTransactionStatuses | Temp table | Finds pending statuses from last 4 months |
| - | Wallet.SentTransactions | JOIN | Transaction details |
| WalletId + CryptoId | Wallet.CustomerWalletsView | JOIN | Wallet and customer context |
| SentTransactionId | Wallet.SentTransactionOutputs | JOIN | Per-output details (flat or JSON) |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by the sent transaction monitoring service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPendingSentTransactions (procedure)
+-- Wallet.SentTransactionStatuses (table)
+-- Wallet.SentTransactions (table)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.SentTransactionOutputs (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactionStatuses | Table | Temp table - pending status filtering |
| Wallet.SentTransactions | Table | JOIN - transaction details |
| Wallet.CustomerWalletsView | View | JOIN - wallet/customer context |
| Wallet.SentTransactionOutputs | Table | JOIN - output details (flat or JSON) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Temp table + index | #temp with IX_temp | Pre-filters pending statuses with index for efficient JOIN |

---

## 8. Sample Queries

### 8.1 Get pending sent transactions (legacy format)
```sql
EXEC Wallet.GetPendingSentTransactions @MaxResultsToReturn = 50, @AksVersion = 0;
```

### 8.2 Get pending sent transactions (AKS JSON format)
```sql
EXEC Wallet.GetPendingSentTransactions @MaxResultsToReturn = 50, @AksVersion = 1;
```

### 8.3 Count pending sends by crypto
```sql
SELECT st.CryptoId, COUNT(DISTINCT st.Id) AS PendingCount
FROM Wallet.SentTransactions st WITH (NOLOCK)
JOIN Wallet.SentTransactionStatuses sts WITH (NOLOCK) ON sts.SentTransactionId = st.Id
WHERE sts.Occurred > DATEADD(MONTH, -4, GETUTCDATE())
    AND NOT EXISTS (SELECT 1 FROM Wallet.SentTransactionStatuses b WITH (NOLOCK)
        WHERE b.SentTransactionId = st.Id AND b.StatusId NOT IN (0,1,3))
GROUP BY st.CryptoId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPendingSentTransactions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetPendingSentTransactions.sql*
