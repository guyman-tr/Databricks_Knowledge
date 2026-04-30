# Wallet.GetSentTransactionByBlockchainTransactionId

> Lightweight lookup that returns the internal ID and wallet association for a sent transaction given its on-chain blockchain hash, used by the executer and billing notification services for quick existence/identity checks.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns Id, BlockchainTransactionId, WalletId by hash match |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure performs a minimal lookup of a sent transaction by its blockchain transaction hash (BlockchainTransactionId). Unlike the more comprehensive `Wallet.GetSentTransactionByBlockchainId` which also resolves the latest status and aggregates outputs as JSON, this procedure returns only three columns: the internal ID, the hash itself, and the source wallet ID.

This lightweight design serves two consumers that need fast existence checks: the executer service (verifying a transaction was recorded before proceeding) and the billing notification service (correlating an on-chain hash to its internal wallet for billing events). Neither consumer needs the full transaction details - they just need to confirm the transaction exists and identify which wallet it belongs to.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a direct single-table lookup by BlockchainTransactionId with NOLOCK hint for non-blocking reads.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BlockchainTransactionId | nvarchar(100) | NO | - | VERIFIED | The on-chain transaction hash to look up. Matched against SentTransactions.BlockchainTransactionId (unique index). Format varies by blockchain. |
| 2 | Id (output) | bigint | NO | - | CODE-BACKED | Internal auto-incrementing ID of the matching sent transaction record. |
| 3 | BlockchainTransactionId (output) | nvarchar(100) | NO | - | CODE-BACKED | Echo of the on-chain hash confirming the match. |
| 4 | WalletId (output) | uniqueidentifier | NO | - | VERIFIED | Source wallet the transaction was sent from. Enables the caller to identify which customer/omnibus wallet originated the transaction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BlockchainTransactionId | Wallet.SentTransactions.BlockchainTransactionId | Lookup | Primary search key |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | - | EXECUTE | Verifies transaction existence before proceeding |
| BillingNotificationUser | - | EXECUTE | Correlates on-chain hash to wallet for billing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetSentTransactionByBlockchainTransactionId (procedure)
+-- Wallet.SentTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | Single-table lookup by BlockchainTransactionId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ExecuterUser | Service Account | EXECUTE grant |
| BillingNotificationUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Relies on SentTransactions unique index on BlockchainTransactionId.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check if a blockchain transaction exists in the system
```sql
EXEC Wallet.GetSentTransactionByBlockchainTransactionId
    @BlockchainTransactionId = '0xabc123def456...';
```

### 8.2 Direct equivalent query
```sql
SELECT Id, BlockchainTransactionId, WalletId
FROM Wallet.SentTransactions WITH (NOLOCK)
WHERE BlockchainTransactionId = '0xabc123def456...';
```

### 8.3 Compare with the full-detail version
```sql
-- Lightweight (this SP):
EXEC Wallet.GetSentTransactionByBlockchainTransactionId @BlockchainTransactionId = '0xabc...';
-- Full details (sibling SP):
EXEC Wallet.GetSentTransactionByBlockchainId @BlockchainId = '0xabc...';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetSentTransactionByBlockchainTransactionId | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetSentTransactionByBlockchainTransactionId.sql*
