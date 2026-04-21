# EXW_dbo.EXW_FactBalance

> Daily end-of-day snapshot of eToro Wallet user crypto balances. Each row represents one user (GCID) × one crypto asset (CryptoId) × one date (FullDate), with balance in native crypto units and USD equivalent. 2.37 billion rows spanning 2018-07-12 to 2026-04-11. The largest fact table in EXW_dbo. Used for daily balance reporting, fund monitoring, and financial reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances (WalletDB balance snapshots) |
| **Writer SP** | EXW_dbo.SP_EXW_FactBalance |
| **Refresh** | Daily (date-partitioned replace: DELETE + INSERT by FullDateID) |
| **Row Count** | 2,372,510,113 rows |
| **Date Range** | FullDate: 2018-07-12 to 2026-04-11 |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — not exported to data lake |

---

## 1. Business Meaning

This is the primary Wallet balance fact table. It stores a daily snapshot of every Wallet user's crypto holdings across all crypto assets they hold. Each row represents one user (identified by GCID) holding one crypto asset (CryptoId/CryptoName) as of the snapshot date (FullDate), with Balance in native crypto units and BalanceUSD as the USD equivalent at that day's price.

At 2.37 billion rows, this is the largest table in EXW_dbo. It grows by approximately 700,000 rows per day (one row per active Wallet × crypto pair). The table is managed by a daily DELETE + INSERT pattern: SP_EXW_FactBalance deletes all rows for the target date and re-inserts from the WalletDB balance source, ensuring each day's snapshot is authoritative.

The balance source is the CopyFromLake pipeline view of WalletDB's WalletBalances table, filtered by DateFrom/DateTo window. The scope is EXW_Wallet.CustomerWalletsView (wallet users registered before the target date), and 6 specific Bitcoin wallet addresses are excluded (hardcoded legacy Beta wallets). USD conversion uses EXW_PriceDaily (LEFT JOIN — Balance is 0 when no price exists, e.g., for BTT).

The table supports fund monitoring, daily NAV calculations, and financial reconciliation. eMoney_dbo.SP_EXW_FactBalance_EXT is the only confirmed downstream consumer, serving cross-schema balance reporting for eMoney regulatory purposes.

---

## 2. Business Logic

### 2.1 Daily Snapshot Replace

**What**: Each run replaces one day's balance snapshot — the full set of end-of-day positions for all Wallet users and crypto assets on that date.

**Columns Involved**: FullDateID, FullDate, GCID, CryptoId, Balance

**Rules**:
- IF EXISTS (SELECT TOP 1 FROM EXW_FactBalance WHERE FullDateID = @d_i) → DELETE WHERE FullDateID = @d_i
- INSERT from #data × EXW_PriceDaily for FullDate = @d
- Scope: CustomerWalletsView where Occurred < @EndDate
- Excluded wallets: 6 specific BTC addresses (hardcoded Beta wallets from blockchain provider migration pre-2021)
- One row per (GCID, CryptoId) per FullDate

### 2.2 Balance and USD Calculation

**What**: Native crypto balance and USD equivalent are both zero-defaulted when no source record exists.

**Columns Involved**: Balance, BalanceUSD, InstrumentID

**Rules**:
- Balance = ISNULL(WalletBalances.Balance, 0) — zero when a wallet has no WalletBalances record for that date window (DateFrom < @EndDate AND DateTo >= @EndDate)
- BalanceUSD = ISNULL(Balance × EXW_PriceDaily.AvgPrice, 0) — zero when no daily price available (LEFT JOIN on FullDate + InstrumentID OR CryptoId)
- Price lookup: `F.InstrumentID = P.InstrumentID OR F.CryptoId = P.InstrumentID` — dual join condition handles cryptos where InstrumentID may be NULL

### 2.3 Blockchain Hierarchy

**What**: Each crypto asset belongs to a parent blockchain. Both the asset and its underlying blockchain are recorded.

**Columns Involved**: CryptoId, CryptoName, InstrumentID, BlockchainCryptoId, BlockchainCryptoName

**Rules**:
- CryptoTypes is self-joined: CT (asset) → CT1 (blockchain) via CT.BlockchainCryptoId = CT1.CryptoID
- Example: BTT (CryptoId=197) has BlockchainCryptoId=2 (ETH) → BlockchainCryptoName='ETH'
- InstrumentID can be NULL for some cryptos that lack a DWH instrument mapping (observed for BTT in live data)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) with HEAP. At 2.37 billion rows, query performance is critically dependent on GCID in the WHERE clause or JOIN condition to avoid cross-distribution shuffles. FullDate filtering alone (without GCID) causes full table scans across all distributions.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current balance for a user | `SELECT * FROM EXW_dbo.EXW_FactBalance WHERE GCID = @gcid AND FullDate = (SELECT MAX(FullDate) FROM EXW_dbo.EXW_FactBalance)` |
| Total USD balance for a date | `SELECT SUM(BalanceUSD) FROM EXW_dbo.EXW_FactBalance WHERE FullDate = @date` |
| Balance by crypto for a date | `SELECT CryptoName, SUM(Balance), SUM(BalanceUSD) FROM EXW_dbo.EXW_FactBalance WHERE FullDate = @date GROUP BY CryptoName ORDER BY SUM(BalanceUSD) DESC` |
| User balance trend | `SELECT FullDate, SUM(BalanceUSD) FROM EXW_dbo.EXW_FactBalance WHERE GCID = @gcid GROUP BY FullDate ORDER BY FullDate` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_DimUser | `EXW_DimUser.GCID = EXW_FactBalance.GCID` | User profile enrichment |

### 3.4 Gotchas

- **2.37 billion rows — always filter on GCID**: Without a GCID filter, queries will scan all 2.37B rows across distributions. HEAP means no CCI compression or segment elimination.
- **GCID is bigint here, int elsewhere**: EXW_DimUser.GCID is int; EXW_FactBalance.GCID is bigint — implicit cast occurs on JOINs. Ensure parameter types match to avoid implicit conversions that defeat distribution pruning.
- **RealCID from LEFT JOIN**: RealCID is NULL for any GCID not in EXW_DimUser at the time of the SP run. Analytics requiring RealCID must handle NULLs.
- **BalanceUSD = 0 ≠ no position**: A zero BalanceUSD may mean: (a) the user holds 0 crypto, (b) no price was available for that crypto on that date, or (c) Balance is 0 because no WalletBalances record matched the date window. Distinguish by checking Balance first.
- **InstrumentID can be NULL**: Cryptos without a DWH instrument mapping have NULL InstrumentID (observed for BTT). Joining to DWH instrument tables requires handling NULLs.
- **HEAP is intentional**: At this scale, CCI would be appropriate — however, HEAP was retained possibly due to daily delete+insert pattern performance considerations.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production DB wiki |
| Tier 2 | Derived from SP code (source-to-target mapping confirmed in code) |
| Tier 3 | Inferred from column name, type, and surrounding context |
| Tier 4 | Best available — limited lineage confidence |
| Tier 5 | Glossary or domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FullDate | date | YES | Snapshot reporting date — the date for which this balance row represents the end-of-day position. Equals the @d parameter passed to SP_EXW_FactBalance. (Tier 2 — SP_EXW_FactBalance) |
| 2 | FullDateID | int | YES | Snapshot date as YYYYMMDD integer (e.g., 20260411). Computed from FullDate: CAST(CONVERT(VARCHAR(8), @d, 112) AS INT). Used for partition-level DELETE. (Tier 2 — SP_EXW_FactBalance) |
| 3 | GCID | bigint | YES | Group Customer ID — cross-product identity key for the Wallet user holding this crypto balance. HASH distribution key. Sourced from EXW_Wallet.CustomerWalletsView.Gcid. Note: declared bigint here vs. int in EXW_DimUser. (Tier 2 — SP_EXW_FactBalance) |
| 4 | RealCID | bigint | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Joined from EXW_DimUser via LEFT JOIN on GCID; NULL when GCID not in EXW_DimUser. (Tier 1 — Customer.CustomerStatic) |
| 5 | CryptoId | int | YES | Crypto asset identifier. FK to EXW_Wallet.CryptoTypes. Source: CustomerWalletsView.CryptoId. (Tier 2 — SP_EXW_FactBalance) |
| 6 | CryptoName | nvarchar(256) | YES | Crypto asset name (e.g., BTC, ETH, LTC, BTT). Denormalized from EXW_Wallet.CryptoTypes.Name via JOIN on CryptoId. (Tier 2 — SP_EXW_FactBalance) |
| 7 | InstrumentID | int | YES | DWH instrument dimension FK for this crypto asset. Denormalized from EXW_Wallet.CryptoTypes.InstrumentId. NULL for cryptos without a DWH instrument mapping (e.g., BTT). (Tier 2 — SP_EXW_FactBalance) |
| 8 | WalletID | uniqueidentifier | YES | Unique identifier for the individual Wallet account (wallet instance). Source: EXW_Wallet.CustomerWalletsView.Id. One GCID can have multiple WalletIDs across different crypto assets. (Tier 2 — SP_EXW_FactBalance) |
| 9 | Balance | numeric(38,8) | YES | End-of-day balance in native crypto units as of FullDate. ISNULL(WalletBalances.Balance, 0) — zero when no WalletBalances record matched the DateFrom/DateTo window for this date. (Tier 2 — SP_EXW_FactBalance) |
| 10 | BalanceUSD | numeric(38,8) | YES | Balance converted to USD using the daily average price: ISNULL(Balance × EXW_PriceDaily.AvgPrice, 0). Zero when no price is available for the crypto on this date (LEFT JOIN). (Tier 2 — SP_EXW_FactBalance) |
| 11 | UpdateDate | datetime | YES | ETL timestamp set to GETDATE() at INSERT. Reflects when SP_EXW_FactBalance wrote this row. (Tier 2 — SP_EXW_FactBalance) |
| 12 | BlockchainCryptoId | int | YES | Parent blockchain's crypto identifier. From EXW_Wallet.CryptoTypes.BlockchainCryptoId. Used to identify the underlying chain (e.g., ETH for ERC-20 tokens). (Tier 2 — SP_EXW_FactBalance) |
| 13 | BlockchainCryptoName | nvarchar(500) | YES | Parent blockchain's name (e.g., ETH, LTC, BTC). Denormalized from a self-join on CryptoTypes via BlockchainCryptoId. (Tier 2 — SP_EXW_FactBalance) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| FullDate | SP parameter | @d | Direct |
| FullDateID | SP parameter | @d | CAST(CONVERT(VARCHAR(8), @d, 112) AS INT) |
| GCID | EXW_Wallet.CustomerWalletsView | Gcid | Passthrough |
| RealCID | etoro.Customer.CustomerStatic (via EXW_DimUser) | RealCID | LEFT JOIN EXW_DimUser on GCID |
| CryptoId | EXW_Wallet.CustomerWalletsView | CryptoId | Passthrough |
| CryptoName | EXW_Wallet.CryptoTypes | Name | JOIN on CryptoId |
| InstrumentID | EXW_Wallet.CryptoTypes | InstrumentId | JOIN on CryptoId |
| WalletID | EXW_Wallet.CustomerWalletsView | Id | Passthrough (aliased) |
| Balance | CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances | Balance | ISNULL(Balance, 0) |
| BalanceUSD | WalletDB balance + EXW_Wallet.EXW_PriceDaily | Balance × AvgPrice | ISNULL(product, 0) |
| UpdateDate | — | — | GETDATE() |
| BlockchainCryptoId | EXW_Wallet.CryptoTypes | BlockchainCryptoId | JOIN (self) |
| BlockchainCryptoName | EXW_Wallet.CryptoTypes | Name (blockchain alias) | Self-join via BlockchainCryptoId |

### 5.2 ETL Pipeline

```
CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances
  (balance snapshot: DateFrom < @EndDate AND DateTo >= @EndDate)
  |-- #source temp table (HASH on WalletId) --|
  v
EXW_Wallet.CustomerWalletsView (scope: Wallet users, Occurred < @EndDate)
  |-- LEFT JOIN #source on WalletId + CryptoId --|
  |-- JOIN CryptoTypes (asset metadata) --|
  |-- #data temp table (HASH on Gcid) --|
  v
EXW_Wallet.EXW_PriceDaily (LEFT JOIN: USD price for FullDate + InstrumentID/CryptoId)
EXW_dbo.EXW_DimUser (LEFT JOIN: RealCID enrichment on GCID)
  |-- DELETE WHERE FullDateID = @d_i --|
  v
EXW_dbo.EXW_FactBalance
  |-- eMoney_dbo.SP_EXW_FactBalance_EXT (eMoney regulatory balance reporting)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | EXW_Wallet.CustomerWalletsView | Scope source — all Wallet users |
| CryptoId | EXW_Wallet.CryptoTypes | Asset metadata (name, instrument, blockchain) |
| InstrumentID | DWH_dbo.Dim_Instrument | FK to instrument dimension (nullable) |
| GCID | EXW_dbo.EXW_DimUser | RealCID enrichment source |

### 6.2 Referenced By (other objects point to this)

| Object | Usage |
|--------|-------|
| eMoney_dbo.SP_EXW_FactBalance_EXT | Cross-schema consumer for eMoney balance reporting |

---

## 7. Sample Queries

### Latest balance for a user across all crypto assets

```sql
SELECT FullDate, CryptoName, Balance, BalanceUSD, BlockchainCryptoName
FROM [EXW_dbo].[EXW_FactBalance]
WHERE GCID = @gcid
  AND FullDate = (SELECT MAX(FullDate) FROM [EXW_dbo].[EXW_FactBalance])
ORDER BY BalanceUSD DESC;
```

### Total wallet AUM by crypto on a specific date

```sql
SELECT CryptoName, BlockchainCryptoName,
       SUM(Balance) AS total_balance,
       SUM(BalanceUSD) AS total_usd
FROM [EXW_dbo].[EXW_FactBalance]
WHERE FullDate = @date
GROUP BY CryptoName, BlockchainCryptoName
ORDER BY total_usd DESC;
```

### Users with non-zero BTC balance on a date

```sql
SELECT GCID, RealCID, Balance, BalanceUSD
FROM [EXW_dbo].[EXW_FactBalance]
WHERE FullDate = @date
  AND CryptoName = 'BTC'
  AND Balance > 0
ORDER BY BalanceUSD DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. WalletDB balance architecture details may be in Confluence under Crypto Wallet or EXW Engineering workspaces.

---

*Generated: 2026-04-20 | Quality: 8.0/10 | Phases: 12/14*
*Tiers: 1 T1, 12 T2, 0 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 8/10, Source: CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances*
*Object: EXW_dbo.EXW_FactBalance | Type: Table | Production Source: WalletDB (via CopyFromLake pipeline)*
