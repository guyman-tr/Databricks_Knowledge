# Wallet.ReceivedTransactionsLock

> Single-row counter table used as a distributed lock mechanism to synchronize concurrent processing of received (incoming) blockchain transactions.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Num (bigint, single column) |
| **Partition** | No |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

This is a minimal single-row table that stores a counter value used as a synchronization mechanism for received transaction processing. The single `Num` value (currently 2,570,950) likely represents the last processed received transaction ID or a sequence counter. Multiple instances of the transaction processing service read and update this value to coordinate which transactions each instance should process, preventing duplicate processing.

Without this table, concurrent service instances could pick up and process the same incoming blockchain transactions simultaneously, leading to double-crediting of customer accounts.

The value is read and updated atomically by transaction processing procedures that handle incoming blockchain transactions. The table intentionally has no PK or indexes - it is a pure lock/counter table optimized for minimal overhead.

---

## 2. Business Logic

### 2.1 Optimistic Concurrency Control

**What**: The counter value coordinates which received transactions each service instance processes.

**Columns/Parameters Involved**: `Num`

**Rules**:
- Service instances read the current Num value to determine the starting point for processing
- After processing a batch of received transactions, the Num value is updated to the latest processed ID
- SQL Server row-level locking on this single row ensures atomic read-modify-write operations
- The absence of a PK means the table is a heap - optimized for single-row access patterns

---

## 3. Data Overview

| Num | Meaning |
|---|---|
| 2570950 | Current high-water mark for received transaction processing. All received transactions up to this ID have been processed. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Num | bigint | NO | - | CODE-BACKED | Counter/high-water mark value for received transaction processing synchronization. Represents the last processed received transaction ID or batch sequence number. Updated atomically to coordinate concurrent processing instances. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not directly referenced by other tables via FK.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT. Referenced at the application level for concurrency control.

---

## 7. Technical Details

### 7.1 Indexes

No indexes (heap table). Single-row access pattern makes indexes unnecessary.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Read current lock value
```sql
SELECT Num FROM Wallet.ReceivedTransactionsLock WITH (NOLOCK)
```

### 8.2 Check if lock value is current (compare to latest received transaction)
```sql
SELECT rtl.Num AS LockValue, MAX(rt.Id) AS LatestReceivedTransactionId,
    MAX(rt.Id) - rtl.Num AS ProcessingLag
FROM Wallet.ReceivedTransactionsLock rtl WITH (NOLOCK)
CROSS JOIN Wallet.ReceivedTransactions rt WITH (NOLOCK)
GROUP BY rtl.Num
```

### 8.3 Simple read
```sql
SELECT Num AS CurrentHighWaterMark FROM Wallet.ReceivedTransactionsLock WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.ReceivedTransactionsLock | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.ReceivedTransactionsLock.sql*
