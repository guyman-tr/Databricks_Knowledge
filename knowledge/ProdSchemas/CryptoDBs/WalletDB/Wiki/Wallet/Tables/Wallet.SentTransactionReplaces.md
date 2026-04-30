# Wallet.SentTransactionReplaces

> Tracks Replace-By-Fee (RBF) events where a stuck blockchain transaction is replaced with a new one at a higher fee, recording the old and new transaction hashes.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 3 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table records transaction replacement events, primarily for Bitcoin's Replace-By-Fee (RBF) mechanism. When a sent transaction gets stuck in the mempool due to low fees, the system can broadcast a replacement transaction with a higher fee. This table links the original (old) transaction hash to the replacement (new) transaction hash, maintaining the audit trail.

Without this table, the system could not track that a transaction hash changed mid-flight, potentially causing reconciliation issues. The replacement preserves the same sent transaction record (SentTransactionId) but updates the on-chain identity.

---

## 2. Business Logic

### 2.1 Transaction Replacement Chain

**What**: A single sent transaction can be replaced multiple times, forming a chain of hash replacements.

**Columns/Parameters Involved**: `SentTransactionId`, `OldBlockchainTransactionId`, `NewBlockchainTransactionId`

**Rules**:
- Each row records one replacement event: old hash -> new hash
- The SentTransactionId remains constant across all replacements
- Multiple replacements for the same transaction form a chain
- Only UTXO-based blockchains support RBF (primarily Bitcoin)

---

## 3. Data Overview

N/A - Low-volume table. Entries are created only when RBF is triggered for stuck transactions.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. |
| 2 | SentTransactionId | bigint | NO | - | VERIFIED | The sent transaction being replaced. FK to Wallet.SentTransactions.Id. Stays constant across replacements. |
| 3 | OldBlockchainTransactionId | nvarchar(255) | NO | - | CODE-BACKED | The blockchain hash of the transaction being replaced (the stuck one). |
| 4 | NewBlockchainTransactionId | nvarchar(255) | NO | - | CODE-BACKED | The blockchain hash of the replacement transaction (with higher fee). This becomes the new active hash. |
| 5 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp of the replacement event. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SentTransactionId | Wallet.SentTransactions | FK | The sent transaction being replaced |

### 5.2 Referenced By (other objects point to this)

Not directly referenced by other tables.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.SentTransactionReplaces (table)
└── Wallet.SentTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | FK target for SentTransactionId |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SentTransactionReplaces | CLUSTERED PK | Id ASC | - | - | Active |
| IX_...NewBlockchainTransactionId | NC | NewBlockchainTransactionId | - | - | Active |
| IX_...OldBlockchainTransactionId | NC | OldBlockchainTransactionId | - | - | Active |
| IX_...SentTransactionId | NC | SentTransactionId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_...Occurred | DEFAULT | getutcdate() |
| FK_...SentTransactionId | FK | -> Wallet.SentTransactions.Id |

---

## 8. Sample Queries

### 8.1 Find all replacements for a transaction
```sql
SELECT str.OldBlockchainTransactionId, str.NewBlockchainTransactionId, str.Occurred
FROM Wallet.SentTransactionReplaces str WITH (NOLOCK)
WHERE str.SentTransactionId = 12345
ORDER BY str.Id
```

### 8.2 Trace replacement chain by hash
```sql
SELECT str.SentTransactionId, str.OldBlockchainTransactionId, str.NewBlockchainTransactionId, str.Occurred
FROM Wallet.SentTransactionReplaces str WITH (NOLOCK)
WHERE str.OldBlockchainTransactionId = '0xabc123...'
   OR str.NewBlockchainTransactionId = '0xabc123...'
```

### 8.3 Recent replacements
```sql
SELECT TOP 20 str.SentTransactionId, str.OldBlockchainTransactionId, str.NewBlockchainTransactionId, str.Occurred
FROM Wallet.SentTransactionReplaces str WITH (NOLOCK)
ORDER BY str.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.SentTransactionReplaces | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.SentTransactionReplaces.sql*
