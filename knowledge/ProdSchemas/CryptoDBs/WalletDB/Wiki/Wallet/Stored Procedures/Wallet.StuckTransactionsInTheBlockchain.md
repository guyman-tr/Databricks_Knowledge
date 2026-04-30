# Wallet.StuckTransactionsInTheBlockchain

> Identifies sent blockchain transactions stuck in Pending (0) or Error (3) status for longer than a threshold but less than 3 months old, excluding completed requests, with full transaction details for monitoring investigation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns stuck SentTransactions with enriched details |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the primary monitoring procedure for stuck blockchain transactions. It finds sent transactions whose latest blockchain status is Pending (0) or Error (3), that are older than @MaxMinutes but less than 3 months old (to exclude very old historical records). It excludes transactions whose associated request has already reached Done status (RequestStatusId=1), preventing false alerts for transactions that completed through an alternate path.

The monitoring team, monitor service, and Splunk use this for real-time blockchain stall detection. Returns enriched details including wallet info, crypto name, transaction type name, output amounts, and destination addresses - everything needed for investigation.

---

## 2. Business Logic

### 2.1 Multi-Criteria Stuck Detection

**What**: Finds transactions in problematic blockchain states within a time window.

**Columns/Parameters Involved**: `SentTransactionStatuses.StatusId`, `SentTransactions.Occurred`, `RequestStatuses`

**Rules**:
- Latest SentTransactionStatuses.StatusId IN (0=Pending, 3=Error)
- Age: DATEADD(MINUTE, @MaxMinutes, Occurred) < GETDATE() (older than threshold)
- Recency: DATEADD(MONTH, 3, Occurred) > GETDATE() (less than 3 months old)
- NOT EXISTS request with RequestStatusId=1 (Done) - excludes completed operations
- Enriched with: CryptoTypes.Name, TransactionTypes.Name, CustomerWalletsView, SentTransactionOutputs

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxMinutes | int | YES | 720 | VERIFIED | Threshold in minutes. Default 12 hours. |
| 2 | BlockchainTransactionId (output) | nvarchar(100) | NO | - | CODE-BACKED | On-chain hash for blockchain explorer lookup. |
| 3 | WalletId (output) | uniqueidentifier | NO | - | CODE-BACKED | Source wallet. |
| 4 | Occurred (output) | datetime2(7) | YES | - | CODE-BACKED | Transaction broadcast time. |
| 5 | CorrelationId (output) | uniqueidentifier | YES | - | CODE-BACKED | Business correlation. |
| 6 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency. |
| 7 | BlockchainProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference. |
| 8 | gcid (output) | bigint | NO | - | CODE-BACKED | Customer. |
| 9 | cryptoname (output) | varchar | NO | - | CODE-BACKED | Crypto display name. |
| 10 | transactiontype (output) | varchar | NO | - | CODE-BACKED | Transaction type name. |
| 11 | Amount (output) | decimal(36,18) | NO | - | CODE-BACKED | Output amount. |
| 12 | ToAddress (output) | nvarchar(512) | NO | - | CODE-BACKED | Destination address. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.SentTransactions | Source | Stuck transactions |
| - | Wallet.SentTransactionStatuses | Subquery | Latest status check |
| - | Wallet.SentTransactionOutputs | JOIN | Output details |
| - | Wallet.CustomerWalletsView | JOIN | Wallet/customer info |
| - | Wallet.CryptoTypes | JOIN | Crypto name |
| - | Dictionary.TransactionTypes | JOIN | Transaction type name |
| - | Wallet.Requests + RequestStatuses | NOT EXISTS | Exclude completed |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MonitorTeam, MonitorUser, SplunkUser | - | EXECUTE | Blockchain stall alerting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.StuckTransactionsInTheBlockchain (procedure)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionStatuses (table)
+-- Wallet.SentTransactionOutputs (table)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.CryptoTypes (table)
+-- Dictionary.TransactionTypes (table)
+-- Wallet.Requests (table)
+-- Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | Source of stuck transactions |
| Wallet.SentTransactionStatuses | Table | Latest status subquery |
| Wallet.SentTransactionOutputs | Table | Output details |
| Wallet.CustomerWalletsView | View | Wallet enrichment |
| Wallet.CryptoTypes | Table | Crypto name |
| Dictionary.TransactionTypes | Table | Type name |
| Wallet.Requests + RequestStatuses | Tables | Done-status exclusion |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MonitorTeam, MonitorUser, SplunkUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Find stuck transactions (default 12h)
```sql
EXEC Wallet.StuckTransactionsInTheBlockchain;
```

### 8.2 Custom threshold (1 hour)
```sql
EXEC Wallet.StuckTransactionsInTheBlockchain @MaxMinutes = 60;
```

### 8.3 Count by crypto
```sql
EXEC Wallet.StuckTransactionsInTheBlockchinCountByCrypto @MaxMinutes = 720;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.StuckTransactionsInTheBlockchain | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.StuckTransactionsInTheBlockchain.sql*
