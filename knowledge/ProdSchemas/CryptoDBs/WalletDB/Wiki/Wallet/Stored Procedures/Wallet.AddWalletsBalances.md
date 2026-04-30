# Wallet.AddWalletsBalances

> Processes a batch of wallet balance updates from the blockchain, maintaining a temporal balance history by closing previous balance periods and inserting new time-ranged balance records in a transactional operation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Modified/new rows in Wallet.WalletBalances; returns affected WalletIds |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the core balance update mechanism for the wallet system. It receives a batch of balance snapshots from blockchain providers (via the WalletBalanceType TVP) and maintains a complete temporal history of every wallet's balance over time. Each balance record has a DateFrom and DateTo range, enabling point-in-time balance queries and historical reconciliation.

Without this procedure, the system could not track wallet balance changes over time, making it impossible to generate accurate balance reports, reconcile with blockchain data, or investigate discrepancies. This is one of the most critical procedures in the wallet infrastructure.

The procedure performs complex temporal logic: it resolves provider wallet IDs to internal wallet IDs via WalletPool, removes redundant balance records (where the balance hasn't changed or the new snapshot predates existing records), then within a transaction updates the DateTo of current open-ended records and inserts the new balance periods with windowed functions to calculate next-period boundaries.

---

## 2. Business Logic

### 2.1 Temporal Balance Record Management

**What**: Maintains a time-series of wallet balances where each row represents a period during which the balance was constant.

**Columns/Parameters Involved**: `WalletBalances.DateFrom`, `WalletBalances.DateTo`, `WalletBalances.Balance`

**Rules**:
- Current (active) balance records have DateTo = '3000-01-01' (sentinel value for "still current")
- When a new balance arrives, the current record's DateTo is updated to the new balance's timestamp
- New balance records are inserted with DateTo calculated via LEAD() window function
- The last balance in a batch gets DateTo = '3000-01-01' (becomes the new current record)
- Balance records are partitioned by WalletId + CryptoId

### 2.2 Redundant Record Cleanup

**What**: Removes incoming balance records that add no new information.

**Columns/Parameters Involved**: Temp tables #WalletBalances, WalletBalances

**Rules**:
- Deletes incoming records where the current open balance has the same value AND the incoming record is the earliest in the batch (MinRowNum = 1) - no change to report
- Also deletes incoming records whose timestamp is at or before the current record's DateFrom - they are backdated and would corrupt the timeline
- This prevents balance table bloat from repeated identical readings

### 2.3 Transactional Integrity

**What**: UPDATE of existing records and INSERT of new records happen atomically.

**Columns/Parameters Involved**: WalletBalances

**Rules**:
- Wrapped in BEGIN TRAN / COMMIT with TRY/CATCH
- On error: ROLLBACK if single transaction, COMMIT if nested (preserves outer transaction)
- Returns the list of affected WalletIds after successful commit

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletBalances | Wallet.WalletBalanceType (READONLY) | NO | - | CODE-BACKED | Table-valued parameter containing balance snapshots from blockchain providers. Columns: ProviderWalletId (mapped to internal WalletId via WalletPool), CryptoId, Balance (decimal), BalanceDateTime (when the balance was observed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderWalletId | Wallet.WalletPool | JOIN | Resolves provider wallet IDs to internal wallet IDs |
| INSERT/UPDATE/DELETE | Wallet.WalletBalances | Writer/Modifier/Deleter | Maintains temporal balance history |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by blockchain sync services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddWalletsBalances (procedure)
  ├── Wallet.WalletPool (table)
  ├── Wallet.WalletBalances (table)
  └── Wallet.WalletBalanceType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | JOIN to resolve ProviderWalletId to WalletId |
| Wallet.WalletBalances | Table | INSERT/UPDATE/DELETE target |
| Wallet.WalletBalanceType | User Defined Type | Table-valued parameter |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses temp tables #WalletBalances and #RemainWalletBalances with ROW_NUMBER() and LEAD() window functions
- Creates a temp index (#ix_WalletBalances) for performance
- Explicit BEGIN TRAN / COMMIT / ROLLBACK with TRY/CATCH
- RAISERROR on failure to propagate error to caller
- NOLOCK hints on WalletPool reads

---

## 8. Sample Queries

### 8.1 View current balances (DateTo = sentinel)
```sql
SELECT TOP 20 WalletId, CryptoId, Balance, DateFrom
FROM Wallet.WalletBalances WITH (NOLOCK)
WHERE DateTo = '3000-01-01'
ORDER BY DateFrom DESC
```

### 8.2 Balance history for a specific wallet
```sql
SELECT CryptoId, Balance, DateFrom, DateTo
FROM Wallet.WalletBalances WITH (NOLOCK)
WHERE WalletId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
ORDER BY DateFrom DESC
```

### 8.3 Point-in-time balance query
```sql
DECLARE @AsOf DATETIME2 = '2026-04-01'
SELECT WalletId, CryptoId, Balance
FROM Wallet.WalletBalances WITH (NOLOCK)
WHERE DateFrom <= @AsOf AND DateTo > @AsOf
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddWalletsBalances | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AddWalletsBalances.sql*
