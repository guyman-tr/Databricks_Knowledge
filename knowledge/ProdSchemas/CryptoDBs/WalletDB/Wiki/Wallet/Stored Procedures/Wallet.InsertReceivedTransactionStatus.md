# Wallet.InsertReceivedTransactionStatus

> Appends a blockchain confirmation status event to a received transaction, identified by blockchain hash or internal ID, with deduplication to prevent inserting the same status twice.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into ReceivedTransactionStatuses with status dedup |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records a blockchain confirmation status change for a received (inbound) transaction. The executer and monitor services call this as incoming transactions progress through confirmation states (Pending -> Confirmed -> Done). It supports two lookup methods: by BlockchainTransactionId (legacy, for backward compatibility) or by ReceiveTransactionId (preferred). The procedure deduplicates: it only inserts if the latest status differs from the new one.

---

## 2. Business Logic

### 2.1 Status Deduplication

**What**: Only inserts if the latest status is different from the new status.

**Columns/Parameters Involved**: `@StatusId`, `ReceivedTransactionStatuses`

**Rules**:
- CROSS APPLY gets latest StatusId (TOP 1 ORDER BY Occurred DESC)
- WHERE ts.StatusId <> @StatusId (skip if already at this status)
- Both @BlockchainTransactionId and @ReceiveTransactionId are optional (ISNULL pattern)
- At least one must be provided to identify the transaction

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BlockchainTransactionId | nvarchar(100) | YES | NULL | VERIFIED | On-chain hash. Legacy lookup method - to be removed in future. |
| 2 | @StatusId | tinyint | NO | - | VERIFIED | New blockchain status. FK to Dictionary.TransactionStatus (0=Pending, 1=Done, etc.). |
| 3 | @DetailsJson | varchar(max) | YES | NULL | CODE-BACKED | Optional JSON details for this status event. |
| 4 | @ReceiveTransactionId | bigint | YES | NULL | VERIFIED | Internal transaction ID. Preferred lookup method. FK to ReceivedTransactions.Id. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BlockchainTransactionId or @ReceiveTransactionId | Wallet.ReceivedTransactions | Lookup | Transaction identification |
| - | Wallet.ReceivedTransactionStatuses | CROSS APPLY + INSERT | Dedup check + status insertion |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | - | EXECUTE | Blockchain confirmation tracking |
| MonitorUser | - | EXECUTE | Status monitoring |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertReceivedTransactionStatus (procedure)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.ReceivedTransactionStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ReceivedTransactions | Table | Transaction lookup |
| Wallet.ReceivedTransactionStatuses | Table | Dedup check + INSERT |

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

### 8.1 Update status by transaction ID
```sql
EXEC Wallet.InsertReceivedTransactionStatus @ReceiveTransactionId = 12345, @StatusId = 1;
```

### 8.2 Update status by blockchain hash (legacy)
```sql
EXEC Wallet.InsertReceivedTransactionStatus @BlockchainTransactionId = '0xabc...', @StatusId = 1;
```

### 8.3 Check status history
```sql
SELECT * FROM Wallet.ReceivedTransactionStatuses WITH (NOLOCK) WHERE ReceivedTransactionId = 12345 ORDER BY Occurred;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertReceivedTransactionStatus | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertReceivedTransactionStatus.sql*
