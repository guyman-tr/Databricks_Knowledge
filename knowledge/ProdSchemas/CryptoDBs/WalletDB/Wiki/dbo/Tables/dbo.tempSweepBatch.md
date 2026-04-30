# dbo.tempSweepBatch

> Staging table for preparing new cryptocurrency sweep batches, holding candidate wallets with balances and allowances before promotion to dbo.SweepBatch.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | None (no PK) |
| **Partition** | No |
| **Indexes** | 0 active |

---

## 1. Business Meaning

This table is a staging area for preparing new sweep batch operations. Before wallets are added to the operational `dbo.SweepBatch` table, candidates are assembled here with their current balances, USD valuations, and user wallet allowances. The staging step allows operators to review and validate the sweep scope before committing to the live batch.

With 13,751 rows, this table holds a pending or recently prepared sweep batch. The additional columns compared to SweepBatch (Balance vs Amount, BalanceUSD vs AmountUSD, UserWalletAllowance) suggest this table captures the pre-sweep state including the user's configured allowance threshold.

No stored procedures reference this table directly. Sweep batch preparation is likely managed by application code or ad-hoc operational scripts.

---

## 2. Business Logic

### 2.1 Sweep Candidate Evaluation

**What**: Each row represents a wallet being evaluated for sweeping, with balance and allowance information for threshold decisions.

**Columns/Parameters Involved**: `Balance`, `BalanceUSD`, `UserWalletAllowance`, `BatchNumber`

**Rules**:
- Balance/BalanceUSD capture current wallet state before sweep
- UserWalletAllowance defines the minimum balance the customer wants retained
- Sweep amount = Balance - UserWalletAllowance (conceptually)
- BatchNumber groups candidates for sequential on-chain execution

---

## 3. Data Overview

| WalletID | CryptoID | GCID | Balance | BalanceUSD | UserWalletAllowance | BatchNumber | Meaning |
|---|---|---|---|---|---|---|---|
| (GUID) | 2 (ETH) | (int) | 0.5 | 1000.00 | 0.1 | 1 | ETH wallet with 0.5 ETH balance, user wants to keep 0.1 ETH - eligible to sweep 0.4 ETH in batch 1 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WalletID | nvarchar(512) | NO | - | CODE-BACKED | Internal wallet identifier (GUID format). Identifies the candidate wallet for sweeping. |
| 2 | PublicAddress | nvarchar(512) | NO | - | CODE-BACKED | Blockchain public address of the wallet. The on-chain address from which funds would be swept. |
| 3 | CryptoID | int | NO | - | CODE-BACKED | Cryptocurrency identifier. Maps to Wallet.CryptoTypes: 1=BTC, 2=ETH, etc. Int type (vs nvarchar in SweepBatch). |
| 4 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. The customer whose wallet is a sweep candidate. |
| 5 | Balance | decimal(18,10) | NO | - | CODE-BACKED | Current wallet balance in native crypto units at the time of staging. The full amount available before any sweep deductions. |
| 6 | BalanceUSD | decimal(18,10) | NO | - | CODE-BACKED | USD equivalent of the wallet balance at staging time. Used for threshold evaluation and reporting. |
| 7 | UserWalletAllowance | nvarchar(50) | NO | - | CODE-BACKED | User's configured minimum wallet retention allowance. The amount the customer wants to keep in their wallet. Stored as string - may represent a configurable threshold value or policy name. |
| 8 | BatchNumber | int | NO | - | CODE-BACKED | Assigned batch number for the sweep operation. Groups wallets for sequential on-chain processing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CryptoID | Wallet.CryptoTypes | Implicit | Cryptocurrency in the wallet (1=BTC, 2=ETH, etc.) |

### 5.2 Referenced By (other objects point to this)

No other objects reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Sweep candidates by crypto type
```sql
SELECT CryptoID, COUNT(*) AS Wallets, SUM(Balance) AS TotalCrypto, SUM(BalanceUSD) AS TotalUSD
FROM dbo.tempSweepBatch WITH (NOLOCK)
GROUP BY CryptoID
ORDER BY TotalUSD DESC
```

### 8.2 Find high-value sweep candidates
```sql
SELECT WalletID, GCID, CryptoID, Balance, BalanceUSD, UserWalletAllowance
FROM dbo.tempSweepBatch WITH (NOLOCK)
WHERE BalanceUSD > 1000
ORDER BY BalanceUSD DESC
```

### 8.3 Batch summary
```sql
SELECT BatchNumber, COUNT(*) AS Wallets, SUM(BalanceUSD) AS TotalUSD
FROM dbo.tempSweepBatch WITH (NOLOCK)
GROUP BY BatchNumber
ORDER BY BatchNumber
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 5.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tempSweepBatch | Type: Table | Source: WalletDB/dbo/Tables/dbo.tempSweepBatch.sql*
