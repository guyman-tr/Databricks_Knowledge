# Wallet.WalletBalances

> Time-series balance snapshots for each wallet-crypto combination, recording the confirmed balance at regular intervals for historical tracking, reporting, and reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Composite PK: (WalletId, CryptoId, DateTo) |
| **Partition** | No |
| **Indexes** | 2 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table stores periodic balance snapshots for every wallet-crypto combination. Each row records the confirmed balance of a specific crypto in a specific wallet during a time window defined by `DateFrom` and `DateTo`. With ~4.31M rows, it is the largest balance-tracking table and provides the historical record of how wallet balances change over time.

Without this table, there would be no historical balance data for reporting, auditing, finance reconciliation, or customer support investigations. When a user asks "what was my BTC balance on March 1st?", this table provides the answer.

Rows are created by the `UpdateWalletBalances` background process (Wallet.Processes Id=1), which periodically queries the blockchain provider for current balances and inserts/updates snapshots. The `DateTo` value of `3000-01-01` indicates the current/latest balance snapshot (open-ended). When a new snapshot is taken, the previous row's `DateTo` is updated to the new snapshot's `DateFrom`, closing the time window.

---

## 2. Business Logic

### 2.1 Temporal Balance Windows

**What**: Each balance record has a validity window (DateFrom to DateTo) enabling point-in-time balance queries.

**Columns/Parameters Involved**: `WalletId`, `CryptoId`, `DateFrom`, `DateTo`, `Balance`

**Rules**:
- Current balance: DateTo = 3000-01-01 (far-future sentinel indicating "current")
- Historical balances: DateTo = the DateFrom of the next snapshot
- The composite PK (WalletId, CryptoId, DateTo) ensures at most one open balance per wallet-crypto
- A balance of 0 is explicitly stored (not deleted) to track when a wallet was emptied
- Balance uses decimal(36,18) for sub-satoshi precision across all crypto types

---

## 3. Data Overview

| WalletId | CryptoId | DateFrom | DateTo | Balance | Meaning |
|---|---|---|---|---|---|
| F05F83B8-... | 4 (XRP) | 2026-04-14 14:42 | 3000-01-01 | 75.541217 | Current XRP balance - the 3000-01-01 DateTo marks this as the latest snapshot |
| F8128277-... | 19 (DOGE) | 2026-04-14 14:37 | 3000-01-01 | 30912.199638 | Current DOGE balance - a substantial holding |
| 69C3B517-... | 1 (BTC) | 2026-04-14 14:32 | 3000-01-01 | 0 | Current BTC balance is zero - wallet was emptied but record retained |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key for row identification. Not used as FK by other tables - the composite PK is the business key. |
| 2 | WalletId | uniqueidentifier | NO | - | VERIFIED | The wallet this balance belongs to. Part of composite clustered PK. Implicit reference to Wallet.WalletPool.WalletId. |
| 3 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency this balance measures. FK to Wallet.CryptoTypes.CryptoID. Part of composite clustered PK. |
| 4 | DateFrom | datetime2(7) | NO | - | CODE-BACKED | Start of this balance snapshot's validity window. Set to the time the balance was confirmed by the provider. |
| 5 | DateTo | datetime2(7) | NO | - | CODE-BACKED | End of this balance snapshot's validity window. 3000-01-01 = current/open balance. Updated to the next snapshot's DateFrom when a new balance is recorded. Part of composite clustered PK. |
| 6 | Balance | decimal(36,18) | YES | - | VERIFIED | The confirmed crypto balance in native units (e.g., BTC, ETH). NULL is possible but rare - indicates the balance could not be determined. Uses high-precision decimal for sub-unit accuracy. |
| 7 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this balance record was created/updated in the database. May differ from DateFrom if there was processing delay. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CryptoId | Wallet.CryptoTypes | FK | Identifies which crypto the balance is for |
| WalletId | Wallet.WalletPool | Implicit | Links to the wallet (no explicit FK) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.AddWalletsBalances | - | Writer | Inserts/updates balance snapshots |
| Wallet.GetWalletsBalance | - | Reader | Reads current balances for wallets |
| Wallet.GetWalletBalanceReport | - | Reader | Reads balance data for reporting |
| Wallet.vw_WalletBalanaces | - | JOIN | View joins this table for balance snapshot data enriched with wallet address context |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.WalletBalances (table)
└── Wallet.CryptoTypes (table)
      └── Wallet.BlockchainCryptos (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FK target for CryptoId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AddWalletsBalances | Stored Procedure | Inserts balance snapshots |
| Wallet.GetWalletsBalance | Stored Procedure | Reads current balances |
| Wallet.GetWalletBalanceReport | Stored Procedure | Reads for reporting |
| Multiple vu_GetWalletBalanceReport* views | View | Balance reporting views |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WalletBalances_WalletId_CryptoId_DateTo1 | CLUSTERED PK | WalletId, CryptoId, DateTo | - | - | Active |
| IX_Wallet_WalletBalances_DateFrom_DateTo_Inc | NC | DateFrom, DateTo | Id, Balance, Occurred | - | Active |
| IX_Wallet_WalletBalances_Occurred | NC | Occurred | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Wallet_WalletBalances__Occurred | DEFAULT | getutcdate() |
| FK_...CryptoId__Wallet_CryptoTypes_CryptoId | FK | CryptoId -> Wallet.CryptoTypes.CryptoID |

---

## 8. Sample Queries

### 8.1 Get current balance for a wallet
```sql
SELECT ct.Name AS Crypto, wb.Balance, wb.DateFrom AS BalanceSince
FROM Wallet.WalletBalances wb WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON wb.CryptoId = ct.CryptoID
WHERE wb.WalletId = 'F05F83B8-963A-4796-B160-3BC1E018AAFB'
  AND wb.DateTo = '3000-01-01'
```

### 8.2 Get balance at a specific point in time
```sql
SELECT ct.Name AS Crypto, wb.Balance
FROM Wallet.WalletBalances wb WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON wb.CryptoId = ct.CryptoID
WHERE wb.WalletId = 'F05F83B8-963A-4796-B160-3BC1E018AAFB'
  AND wb.DateFrom <= '2026-03-01' AND wb.DateTo > '2026-03-01'
```

### 8.3 Find wallets with non-zero current balance for a crypto
```sql
SELECT wb.WalletId, wb.Balance, wb.DateFrom
FROM Wallet.WalletBalances wb WITH (NOLOCK)
WHERE wb.CryptoId = 1  -- BTC
  AND wb.DateTo = '3000-01-01'
  AND wb.Balance > 0
ORDER BY wb.Balance DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.WalletBalances | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.WalletBalances.sql*
