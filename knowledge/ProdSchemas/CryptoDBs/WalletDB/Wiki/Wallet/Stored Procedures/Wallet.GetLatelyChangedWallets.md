# Wallet.GetLatelyChangedWallets

> Finds all customer wallets that had any activity (received, sent, balance changes, or creation) within a specified date range, returning their full wallet details.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns wallet details for wallets with activity in [@From, @To] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies all customer wallets that experienced any change within a time window. "Change" encompasses four types of activity: received transactions (incoming crypto), sent transactions (outgoing crypto), balance updates, and new wallet creation. This is used by synchronization and reconciliation services to determine which wallets need attention, avoiding full-table scans of the entire wallet population.

The delta-detection approach is critical for efficient wallet synchronization. Rather than re-checking every wallet's state on every sync cycle, the system only needs to process wallets that actually had activity, dramatically reducing the workload for balance verification and external system updates.

Data is collected from four activity sources (ReceivedTransactions, SentTransactions, WalletBalances, CustomerWalletsView) via UNION ALL into a temp table, then joined back to CustomerWalletsView for full wallet details. Only customer wallets (Gcid <> 0) are returned - internal/system wallets are excluded.

---

## 2. Business Logic

### 2.1 Multi-Source Change Detection

**What**: Detects wallet activity from four independent sources within a date range.

**Columns/Parameters Involved**: `@From`, `@To`, `WalletId`, `CryptoId`

**Rules**:
- ReceivedTransactions: Incoming crypto - filtered by BlockchainTransactionDate
- SentTransactions: Outgoing crypto - filtered by Occurred
- WalletBalances: Balance snapshots - filtered by Occurred
- CustomerWalletsView: Wallet creation/modification - filtered by Occurred
- UNION ALL collects wallet IDs from all sources (allows duplicates; DISTINCT is applied later)
- Date filter uses BETWEEN (inclusive on both ends)

**Diagram**:
```
@From -- @To (date range)
    |
    +-- ReceivedTransactions (BlockchainTransactionDate)
    +-- SentTransactions (Occurred)
    +-- WalletBalances (Occurred)
    +-- CustomerWalletsView (Occurred)
    |
    v
#ChangedWallet (WalletId, CryptoId) -- UNION ALL
    |
    +-- JOIN CustomerWalletsView ON Id = WalletId
    +-- WHERE Gcid <> 0 (customer wallets only)
    |
    v
DISTINCT wallet details (WalletId, CryptoId, Id, Gcid, ProviderWalletId, WalletProviderId, BlockchainCryptoId)
```

### 2.2 Customer-Only Filtering

**What**: Excludes internal/system wallets from the result.

**Columns/Parameters Involved**: `Gcid`

**Rules**:
- Gcid <> 0 filters to customer wallets only
- Internal wallets (Gcid=0) are managed separately and do not need delta-based sync

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @From | DATETIME | NO | - | CODE-BACKED | Start of the date range (inclusive). Wallets with any activity on or after this timestamp are included. Typically set to the last sync run time. |
| 2 | @To | DATETIME | NO | - | CODE-BACKED | End of the date range (inclusive). Wallets with any activity on or before this timestamp are included. Typically set to current time. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | WalletId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | The wallet GUID from the change detection. Identifies which wallet had activity. |
| 4 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency identifier for the activity. FK to Wallet.CryptoTypes. |
| 5 | Id | BIGINT | NO | - | CODE-BACKED | Internal record ID from CustomerWalletsView. Unique wallet record identifier. |
| 6 | Gcid | BIGINT | NO | - | CODE-BACKED | Global Customer ID owning this wallet. Always > 0 (customer wallets only). |
| 7 | BlockchainProviderWalletId | NVARCHAR | YES | - | CODE-BACKED | Custody provider's wallet identifier (e.g., BitGo wallet ID). Used to query external provider for current balance. |
| 8 | ProviderWalletId | NVARCHAR | YES | - | CODE-BACKED | Backward-compatible alias for BlockchainProviderWalletId. Same value. |
| 9 | WalletProviderId | INT | NO | - | CODE-BACKED | Custody provider ID. FK to Dictionary.WalletProvider (1=Bitgo, 2=CUG, 3=None). |
| 10 | BlockchainCryptoId | INT | NO | - | CODE-BACKED | Blockchain crypto identifier from CustomerWalletsView. May differ from CryptoId for token-on-chain scenarios. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.ReceivedTransactions | SELECT | Detects incoming crypto activity by date |
| - | Wallet.SentTransactions | SELECT | Detects outgoing crypto activity by date |
| - | Wallet.WalletBalances | SELECT | Detects balance update activity by date |
| - | Wallet.CustomerWalletsView | SELECT + JOIN | Detects wallet creation AND provides full wallet details for results |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by wallet synchronization services to identify wallets needing sync.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetLatelyChangedWallets (procedure)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.SentTransactions (table)
+-- Wallet.WalletBalances (table)
+-- Wallet.CustomerWalletsView (view)
      +-- Wallet.Wallets (table)
      +-- Wallet.WalletAddresses (table)
      +-- Wallet.WalletBalances (table)
      +-- Wallet.BlockchainCryptoProviders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ReceivedTransactions | Table | SELECT - received transaction activity detection |
| Wallet.SentTransactions | Table | SELECT - sent transaction activity detection |
| Wallet.WalletBalances | Table | SELECT - balance update activity detection |
| Wallet.CustomerWalletsView | View | SELECT + JOIN - wallet creation detection and result enrichment |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Temp table | #ChangedWallet | Collects WalletId+CryptoId from all activity sources before joining for details |

---

## 8. Sample Queries

### 8.1 Get wallets changed in the last 24 hours
```sql
EXEC Wallet.GetLatelyChangedWallets
    @From = '2026-04-14',
    @To = '2026-04-15';
```

### 8.2 Check activity counts per source in a date range
```sql
SELECT 'ReceivedTransactions' AS Source, COUNT(DISTINCT WalletId) AS WalletCount
FROM Wallet.ReceivedTransactions WITH (NOLOCK) WHERE BlockchainTransactionDate BETWEEN '2026-04-14' AND '2026-04-15'
UNION ALL
SELECT 'SentTransactions', COUNT(DISTINCT WalletId)
FROM Wallet.SentTransactions WITH (NOLOCK) WHERE Occurred BETWEEN '2026-04-14' AND '2026-04-15'
UNION ALL
SELECT 'WalletBalances', COUNT(DISTINCT WalletId)
FROM Wallet.WalletBalances WITH (NOLOCK) WHERE Occurred BETWEEN '2026-04-14' AND '2026-04-15';
```

### 8.3 Find the most active wallets in a period
```sql
SELECT TOP 10 WalletId, COUNT(*) AS ActivityCount
FROM (
    SELECT WalletId FROM Wallet.ReceivedTransactions WITH (NOLOCK) WHERE BlockchainTransactionDate BETWEEN '2026-04-14' AND '2026-04-15'
    UNION ALL
    SELECT WalletId FROM Wallet.SentTransactions WITH (NOLOCK) WHERE Occurred BETWEEN '2026-04-14' AND '2026-04-15'
) activity
GROUP BY WalletId
ORDER BY ActivityCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetLatelyChangedWallets | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetLatelyChangedWallets.sql*
