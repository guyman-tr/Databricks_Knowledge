# Wallet.InsertTransactionsSyncRun

> Records a blockchain transaction synchronization run's pagination state, with change detection to avoid inserting duplicate cursor positions when the sync hasn't progressed.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.TransactionsSyncRuns with change detection |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records the pagination state of a blockchain transaction synchronization run. The transaction sync service polls the blockchain provider for new transactions in batches, tracking its cursor position (Prev/Next tokens). This procedure inserts a new sync run record only if the cursor position has changed from the last run for the same provider - avoiding redundant records when the sync is idle.

---

## 2. Business Logic

### 2.1 Change Detection Before Insert

**What**: Only inserts if pagination cursor has changed from the last run.

**Columns/Parameters Involved**: `@WalletProviderId`, `@Prev`, `@Next`

**Rules**:
- OUTER APPLY gets the most recent TransactionsSyncRuns for this provider (TOP 1 ORDER BY Created DESC)
- Only inserts when: no previous run exists (sr1.Id IS NULL) OR Prev/Next values differ from last run
- ISNULL handles NULL cursor values for comparison
- Prevents sync run table bloat when the provider has no new transactions

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletProviderId | bigint | NO | - | VERIFIED | Blockchain provider being synced. FK to Dictionary.WalletProvider. |
| 2 | @Prev | nvarchar(256) | YES | - | CODE-BACKED | Previous page cursor token from the provider's API. |
| 3 | @Next | varchar(256) | YES | - | CODE-BACKED | Next page cursor token. NULL when at the end of available data. |
| 4 | @Received | int | NO | - | CODE-BACKED | Number of transactions received in this sync batch. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.TransactionsSyncRuns | INSERT + change check | Sync run record with dedup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TransactionSyncUser | - | EXECUTE | Blockchain sync pagination tracking |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertTransactionsSyncRun (procedure)
+-- Wallet.TransactionsSyncRuns (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionsSyncRuns | Table | INSERT + last-run lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TransactionSyncUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses temp table for OUTER APPLY comparison.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record a sync run
```sql
EXEC Wallet.InsertTransactionsSyncRun @WalletProviderId=1, @Prev='cursor-abc', @Next='cursor-def', @Received=50;
```

### 8.2 Check latest sync runs per provider
```sql
SELECT TOP 5 * FROM Wallet.TransactionsSyncRuns WITH (NOLOCK) WHERE WalletProviderId = 1 ORDER BY Created DESC;
```

### 8.3 Check if sync is progressing
```sql
SELECT WalletProviderId, COUNT(*) AS Runs, MAX(Created) AS LastRun, SUM(Received) AS TotalReceived
FROM Wallet.TransactionsSyncRuns WITH (NOLOCK) WHERE Created > DATEADD(HOUR, -24, GETDATE()) GROUP BY WalletProviderId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertTransactionsSyncRun | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertTransactionsSyncRun.sql*
