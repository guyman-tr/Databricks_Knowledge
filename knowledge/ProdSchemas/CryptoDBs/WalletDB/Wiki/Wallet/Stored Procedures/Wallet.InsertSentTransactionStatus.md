# Wallet.InsertSentTransactionStatus

> Appends a blockchain confirmation status event to a sent transaction identified by its on-chain hash, with deduplication to prevent inserting the same status twice.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into SentTransactionStatuses by BlockchainTransactionId with dedup |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records a blockchain confirmation status change for a sent (outbound) transaction. The executer and monitor services call this as outbound transactions progress through blockchain confirmation states (Pending -> Confirmed -> Verified, or Error/Timeout). The transaction is identified by its on-chain BlockchainTransactionId. Deduplicates by checking if the latest status already matches the new one.

---

## 2. Business Logic

### 2.1 Status Deduplication

**What**: Only inserts if latest status differs from new status.

**Rules**:
- CROSS APPLY gets latest StatusId (TOP 1 ORDER BY Occurred DESC)
- WHERE ts.StatusId <> @StatusId - skip if already at this status
- Lookup by BlockchainTransactionId on SentTransactions

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BlockchainTransactionId | nvarchar(100) | NO | - | VERIFIED | On-chain hash identifying the sent transaction. |
| 2 | @StatusId | tinyint | NO | - | VERIFIED | New status: 0=Pending, 1=Confirmed, 2=Verified, 3=Error, 4=Timeout, 5=PermanentError, 6=WavedError. See [Transaction Status](../../_glossary.md#transaction-status). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BlockchainTransactionId | Wallet.SentTransactions | Lookup | Transaction identification |
| - | Wallet.SentTransactionStatuses | CROSS APPLY + INSERT | Dedup check + status insertion |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser, MonitorUser | - | EXECUTE | Blockchain confirmation tracking |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertSentTransactionStatus (procedure)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | Transaction lookup |
| Wallet.SentTransactionStatuses | Table | Dedup check + INSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ExecuterUser, MonitorUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Update sent transaction status
```sql
EXEC Wallet.InsertSentTransactionStatus @BlockchainTransactionId = '0xabc123...', @StatusId = 2;
```

### 8.2 Check status history
```sql
SELECT sts.* FROM Wallet.SentTransactionStatuses sts WITH (NOLOCK) JOIN Wallet.SentTransactions st WITH (NOLOCK) ON st.Id = sts.SentTransactionId WHERE st.BlockchainTransactionId = '0xabc123...' ORDER BY sts.Occurred;
```

### 8.3 Compare with received transaction status SP
```sql
-- Sent (this SP): EXEC Wallet.InsertSentTransactionStatus @BlockchainTransactionId='...', @StatusId=2;
-- Received: EXEC Wallet.InsertReceivedTransactionStatus @BlockchainTransactionId='...', @StatusId=1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertSentTransactionStatus | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertSentTransactionStatus.sql*
