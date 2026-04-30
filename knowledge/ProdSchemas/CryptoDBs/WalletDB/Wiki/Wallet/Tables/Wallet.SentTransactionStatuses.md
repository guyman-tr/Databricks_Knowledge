# Wallet.SentTransactionStatuses

> Event-sourced status history for sent blockchain transactions, tracking each lifecycle transition from pending through confirmation to final verification or error.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 5 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table tracks the blockchain confirmation lifecycle of every sent transaction. Each row represents a status transition - when a sent transaction moves from Pending to Confirmed to Verified (or to Error/Timeout). This is distinct from `Wallet.RequestStatuses` which tracks the business request lifecycle; this table tracks the on-chain confirmation state.

The status progression reflects blockchain reality: after broadcast, a transaction waits for network confirmations, then is internally verified, and either succeeds or fails. Error monitoring policies (from `Dictionary.ErrorMonitoringPolicies`) determine retry behavior for failed transactions.

Rows are created by `Wallet.InsertSentTransactionStatus` as the blockchain provider reports transaction state changes.

---

## 2. Business Logic

### 2.1 Transaction Confirmation Lifecycle

**What**: Sent transactions progress through blockchain confirmation states.

**Columns/Parameters Involved**: `SentTransactionId`, `StatusId`, `Occurred`

**Rules**:
- 0=Pending: Transaction broadcast, awaiting confirmations
- 1=Confirmed: Sufficient network confirmations received
- 2=Verified: Internal verification checks passed
- 3=Error: Transaction encountered an error
- 4=Timeout: Transaction timed out waiting for confirmations
- 5=PermanentError: Unrecoverable failure
- 6=WavedError: Error was dismissed/auto-resolved
- See [Transaction Status](../../_glossary.md#transaction-status). FK to Dictionary.TransactionStatus.
- Filtered index on StatusId IN (0, 1, 3) optimizes queries for active/problematic transactions

---

## 3. Data Overview

N/A - High-volume event table. Status events follow the pattern: Pending -> Confirmed -> Verified for successful transactions.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing event identifier. |
| 2 | SentTransactionId | bigint | NO | - | VERIFIED | The sent transaction this status event belongs to. FK to Wallet.SentTransactions.Id. Multiple rows per transaction. |
| 3 | StatusId | tinyint | NO | - | VERIFIED | Blockchain confirmation status: 0=Pending, 1=Confirmed, 2=Verified, 3=Error, 4=Timeout, 5=PermanentError, 6=WavedError. See [Transaction Status](../../_glossary.md#transaction-status). FK to Dictionary.TransactionStatus. |
| 4 | Occurred | datetime2(7) | YES | getutcdate() | CODE-BACKED | Timestamp of this status transition. Used for confirmation time calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SentTransactionId | Wallet.SentTransactions | FK | Links to the parent sent transaction |
| StatusId | Dictionary.TransactionStatus | FK | Identifies the blockchain confirmation status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.InsertSentTransactionStatus | - | Writer | Appends status events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.SentTransactionStatuses (table)
├── Wallet.SentTransactions (table)
└── Dictionary.TransactionStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | FK target for SentTransactionId |
| Dictionary.TransactionStatus | Table | FK target for StatusId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertSentTransactionStatus | Stored Procedure | Inserts status events |
| Wallet.GetPendingSentTransactions | Stored Procedure | Finds transactions in pending states |
| Wallet.StuckTransactionsInTheBlockchain | Stored Procedure | Finds stuck transactions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SentTransactionStatuses | CLUSTERED PK | Id ASC | - | - | Active |
| IX_occured_SentTransactionId_StatusId | NC | Occurred | SentTransactionId, StatusId | - | Active |
| IX_SentTransactionStatuses_SentId_Occurred_Inc | NC | SentTransactionId, Occurred DESC | StatusId | - | Active |
| IX_SentTransactionStatuses_Status_SentTransactionId | NC | StatusId | SentTransactionId | WHERE StatusId IN (0,1,3) | Active |
| IX_StatusTransactionId | NC | StatusId | SentTransactionId | - | Active |
| IX_Wallet_SentTransactionStatuses_SentTransactionId_Id | NC | SentTransactionId, Id DESC | - | - | Active |
| IX_Wallet_SentTransactionStatuses_SentTransactionId_Occurred | NC | SentTransactionId, Occurred DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Wallet_SentTransactionStatuses__Occurred | DEFAULT | getutcdate() |
| FK_...SentTransactionId | FK | -> Wallet.SentTransactions.Id |
| FK_...StatusId | FK | -> Dictionary.TransactionStatus.Id |

---

## 8. Sample Queries

### 8.1 Get status history for a sent transaction
```sql
SELECT sts.Id, ts.Name AS Status, sts.Occurred
FROM Wallet.SentTransactionStatuses sts WITH (NOLOCK)
JOIN Dictionary.TransactionStatus ts WITH (NOLOCK) ON sts.StatusId = ts.Id
WHERE sts.SentTransactionId = 1907239
ORDER BY sts.Id
```

### 8.2 Find transactions stuck in pending
```sql
SELECT sts.SentTransactionId, sts.Occurred AS PendingSince,
    DATEDIFF(MINUTE, sts.Occurred, GETUTCDATE()) AS MinutesPending
FROM Wallet.SentTransactionStatuses sts WITH (NOLOCK)
WHERE sts.StatusId = 0
  AND NOT EXISTS (SELECT 1 FROM Wallet.SentTransactionStatuses sts2 WITH (NOLOCK)
      WHERE sts2.SentTransactionId = sts.SentTransactionId AND sts2.Id > sts.Id)
ORDER BY sts.Occurred
```

### 8.3 Latest status per transaction
```sql
SELECT sts.SentTransactionId, ts.Name AS CurrentStatus, sts.Occurred
FROM Wallet.SentTransactionStatuses sts WITH (NOLOCK)
JOIN Dictionary.TransactionStatus ts WITH (NOLOCK) ON sts.StatusId = ts.Id
WHERE sts.Id = (SELECT MAX(sts2.Id) FROM Wallet.SentTransactionStatuses sts2 WITH (NOLOCK) WHERE sts2.SentTransactionId = sts.SentTransactionId)
  AND sts.SentTransactionId > 1907200
ORDER BY sts.SentTransactionId DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.SentTransactionStatuses | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.SentTransactionStatuses.sql*
