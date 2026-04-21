# EXW_dbo.Hourly_OmnibusBalances

> Hourly pre-aggregated omnibus (system) crypto balance table — one row per WalletID × CryptoID × BalanceDate (today through today-3), rebuilt on every SP_EXW_Hourly run. Covers only omnibus/system wallets (Gcid ≤ 0), providing wallet-level balances for 36 system wallets across 77 cryptos, with a total USD footprint of ~$25.3M. The counterpart to Hourly_CustomerBalances, which covers customer-owned wallets.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances → SP_EXW_Hourly |
| **Refresh** | Hourly — TRUNCATE + INSERT on each run. @d DATE param accepted but ignored; all dates from GETDATE(). |
| **Synapse Distribution** | HASH (CryptoID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only operational KPI feed |

---

## 1. Business Meaning

Hourly_OmnibusBalances tracks the balance position of the 36 omnibus/system wallets managed by eToro Wallet Exchange, broken down by cryptocurrency and by balance-as-of date. It is one of six tables rebuilt each hour by SP_EXW_Hourly and is designed to feed operational KPI dashboards (e.g., Tableau) with near-real-time visibility into how much crypto is held in eToro's own inventory wallets — separate from customer wallets.

**Scope**: Gcid ≤ 0 wallets only. These are pre-funded pool wallets, omnibus wallets for specific transaction types (Redeem, Payment, Funding, Conversion, C2F, StakingRefund), and system wallets not belonging to individual customers.

**Row structure**: One row per WalletID × CryptoID per BalanceDate. Unlike Hourly_CustomerBalances, this table retains the per-wallet granularity (not aggregated to crypto-level totals). ReportDate is always the SP run date; BalanceDate cycles through today, today-1, today-2, today-3.

**Current footprint** (as of 2026-04-12): 404 rows across 4 BalanceDates, 36 distinct wallets, 77 cryptos, ~$25.3M total USD. Redeem wallets hold the dominant position (BTC Redeem: $10.5M, XRP Redeem: $5.4M, ETH Redeem: $4.1M).

---

## 2. Business Logic

### 2.1 Omnibus Wallet Scope

**What**: Only omnibus/system wallets are included. Customer wallets are excluded.

**Columns Involved**: WalletID, WalletType

**Rules**:
- Filter: `Gcid <= 0` on EXW_Wallet.CustomerWalletsView — non-customer/system wallets only
- No hotspot exclusion (unlike CustomerBalances, which excludes 6 specific BlockchainProviderWalletId values)
- Each WalletID is a GUID identifying a specific system wallet in WalletDB.Wallet.WalletPool

### 2.2 WalletType Classification

**What**: WalletType classifies omnibus wallets by their functional purpose.

**Columns Involved**: WalletType, CryptoID

**Rules**:
- CASE WHEN `CryptoTypes.BlockchainCryptoId <> CryptoTypes.CryptoID` THEN `'Conversion'` ELSE `WalletDB_Dictionary_WalletTypes.Name` END
- ERC-20 token wallets (BlockchainCryptoId ≠ CryptoID) are always classified as `'Conversion'` regardless of their WalletTypeId
- Native coin wallets use the name from WalletDB_Dictionary_WalletTypes: `Redeem`, `Payment`, `Funding`, `C2F`, `StakingRefund`
- **Current distribution**: Conversion (292 rows, 9 wallets), Redeem (48, 12), Payment (28, 7), Funding (28, 7), C2F (4, 1), StakingRefund (4, 1)

### 2.3 Balance Deduplication

**What**: WalletDB can have multiple balance records per WalletId × CryptoId; the SP selects the most recent.

**Columns Involved**: Balance, WalletID, CryptoID, BalanceDate

**Rules**:
- `ROW_NUMBER() OVER (PARTITION BY WalletId, wb.CryptoId ORDER BY wb.DateFrom DESC) = 1`
- No `Balance <> 0` filter is applied for OmnibusBalances (all 4 snapshot dates include zero-balance wallets), unlike CustomerBalances which has a zero-balance filter

### 2.4 Rolling 4-Day Window

**What**: Each SP run inserts 4 snapshot dates relative to GETDATE().

**Columns Involved**: BalanceDate, ReportDate

**Rules**:
- 4 UNION ALL members: BalanceDate = today, today-1, today-2, today-3
- ReportDate = CAST(GETDATE() AS DATE) — the actual SP run date, same for all rows in a given run
- TRUNCATE before INSERT means only data from the latest run persists — no historical accumulation

### 2.5 USD Valuation

**What**: USDBalance converts native-unit Balance into USD using daily prices.

**Columns Involved**: USDBalance, Balance, CryptoID

**Rules**:
- Price source: `#DailyPrices` (daily AvgPrice from EXW_Wallet.EXW_Price, last 7 days)
- LEFT JOIN on CryptoID + FullDate — NULL USDBalance when no price available
- ERC-20 tokens without a price mapping show USDBalance = NULL or 0

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CryptoID) — co-located with Hourly_CustomerBalances for co-located JOINs on CryptoID + BalanceDate. HEAP — inexpensive full scans given 404 total rows. No need to specify CryptoID in WHERE for performance (already at partition level).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| Current omnibus holdings by WalletType | `WHERE BalanceDate = CAST(GETDATE() AS DATE) GROUP BY WalletType, CryptoID` |
| Redeem wallet BTC position trend | `WHERE CryptoID = 1 AND WalletType = 'Redeem' ORDER BY BalanceDate` |
| Total system-wallet USD holdings | `SELECT SUM(USDBalance) WHERE BalanceDate = (SELECT MAX(BalanceDate) FROM EXW_dbo.Hourly_OmnibusBalances)` |
| Compare omnibus vs customer for same crypto | `JOIN Hourly_CustomerBalances ON CryptoID + BalanceDate` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.Hourly_CustomerBalances | `CryptoID + BalanceDate` | Compare customer vs system wallet balances for the same crypto |
| EXW_dbo.EXW_WalletInventory | `WalletID` | Enrich with wallet pool status and allocation metadata |

### 3.4 Gotchas

- **Per-wallet, not aggregated**: Unlike Hourly_CustomerBalances, OmnibusBalances retains individual wallet granularity — one row per WalletID × CryptoID × BalanceDate
- **InstrumentID NULL for 17% of rows**: 68/404 rows have NULL InstrumentID — cryptos with no mapping in EXW_Wallet.CryptoTypes (e.g., ERC-20 tokens without eToro instrument)
- **Conversion wallets dominate by count**: 292 of 404 rows (72%) are ERC-20 token Conversion wallets, but Redeem wallets dominate by USD value (~85% of total)
- **No zero-balance filter**: All 4 snapshots include zero-balance wallets (unlike CustomerBalances which filters Balance <> 0 for 3 of 4 dates)
- **TRUNCATE each hour**: All historical data is dropped on each SP run — this table cannot be used for trends beyond 4 days

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (WalletDB.Wallet.V_BI_WalletBalances) |
| Tier 2 | Derived from SP code analysis — computed, lookup-enriched, or ETL-generated |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ReportDate | date | NULL | Date of the SP_EXW_Hourly run that created this row. CAST(GETDATE() AS DATE). Same for all rows inserted in a single run. (Tier 2 — SP_EXW_Hourly) |
| 2 | WalletID | nvarchar(max) | NULL | The wallet this balance belongs to. Implicit reference to Wallet.WalletPool.WalletId. DWH note: stored as nvarchar(max) (GUID serialized as string from Parquet); scoped to omnibus wallets (Gcid≤0) only. (Tier 1 — WalletDB.Wallet.V_BI_WalletBalances) |
| 3 | CryptoID | int | NULL | The cryptocurrency this balance measures. FK to Wallet.CryptoTypes.CryptoID. Combined with WalletId and DateTo for unique identification. (Tier 1 — WalletDB.Wallet.V_BI_WalletBalances) |
| 4 | InstrumentID | int | NULL | eToro trading instrument ID from EXW_Wallet.CryptoTypes.InstrumentId. NULL for 68/404 rows (ERC-20 tokens without a direct eToro instrument mapping). Distribution key for co-location. (Tier 2 — SP_EXW_Hourly JOIN CryptoTypes) |
| 5 | Balance | decimal(38,8) | NULL | The confirmed crypto balance in native units (e.g., BTC, ETH). NULL is possible but rare — indicates balance could not be determined. Uses high-precision decimal for sub-unit accuracy across all crypto types. DWH note: deduped per WalletId×CryptoId by ROW_NUMBER(DateFrom DESC)=1. (Tier 1 — WalletDB.Wallet.V_BI_WalletBalances) |
| 6 | WalletType | nvarchar(1000) | NULL | Functional classification of the omnibus wallet. CASE logic: ERC-20 tokens (BlockchainCryptoId ≠ CryptoID) → 'Conversion'; native coins → WalletDB_Dictionary_WalletTypes.Name. Values: Conversion, Redeem, Payment, Funding, C2F, StakingRefund. (Tier 2 — SP_EXW_Hourly) |
| 7 | BalanceDate | date | NULL | The snapshot date this balance represents: today, today-1, today-2, or today-3 relative to the SP run time. (Tier 2 — SP_EXW_Hourly) |
| 8 | UpdateDate | datetime | NULL | ETL timestamp set to GETDATE() at INSERT time. Reflects the specific hourly run that produced this row. (Tier 2 — SP_EXW_Hourly) |
| 9 | USDBalance | numeric(38,8) | NULL | USD value of Balance: Balance × AvgPrice from #DailyPrices (daily avg price at BalanceDate). NULL when no price available for this CryptoID on BalanceDate. (Tier 2 — SP_EXW_Hourly) |

---

## 5. Lineage

See [Hourly_OmnibusBalances.lineage.md](Hourly_OmnibusBalances.lineage.md) for full column-level lineage.

### 5.2 ETL Pipeline

```
WalletDB.Wallet.WalletBalances (production — blockchain balance snapshots)
  |-- Wallet.V_BI_WalletBalances (rolling 20-day view) --|
  v
CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances
  (Bronze External Table — Parquet from ADLS, Generic Pipeline Override ~60min)
  |-- SP_EXW_Hourly (hourly TRUNCATE + INSERT, Gcid<=0 filter, 4-day window) --|
  v
EXW_dbo.Hourly_OmnibusBalances
  (404 rows, 36 wallets, 77 cryptos, 4 BalanceDates, HASH(CryptoID), HEAP)
  UC Target: _Not_Migrated (operational KPI, Synapse-only)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| WalletID | WalletDB.Wallet.WalletPool | Omnibus wallet GUID sourced from WalletPool via CustomerWalletsView (Gcid≤0) |
| CryptoID | EXW_Wallet.CryptoTypes | Crypto type metadata (name, InstrumentId, BlockchainCryptoId) |
| InstrumentID | EXW_Wallet.CryptoTypes.InstrumentId | eToro instrument mapping |

### 6.2 Referenced By (other objects point to this)

No SSDT stored procedures or views found that reference EXW_dbo.Hourly_OmnibusBalances. This table is consumed directly by Tableau dashboards for operational KPI monitoring of omnibus wallet positions.

---

## 7. Sample Queries

### 7.1 Current omnibus holdings by wallet type and crypto

```sql
SELECT
    WalletType,
    CryptoID,
    SUM(Balance) AS TotalBalance,
    SUM(USDBalance) AS TotalUSD
FROM [EXW_dbo].[Hourly_OmnibusBalances]
WHERE BalanceDate = CAST(GETDATE() AS DATE)
GROUP BY WalletType, CryptoID
ORDER BY TotalUSD DESC
```

### 7.2 Redeem wallet BTC position over the rolling window

```sql
SELECT
    BalanceDate,
    WalletID,
    Balance,
    USDBalance
FROM [EXW_dbo].[Hourly_OmnibusBalances]
WHERE CryptoID = 1  -- BTC
  AND WalletType = 'Redeem'
ORDER BY BalanceDate DESC, USDBalance DESC
```

### 7.3 Customer vs omnibus total for top 5 cryptos

```sql
SELECT
    c.CryptoID,
    c.UnitBalance AS CustomerBalance,
    o.TotalBalance AS OmnibusBalance,
    c.BalanceDate
FROM (
    SELECT CryptoID, UnitBalance, BalanceDate
    FROM EXW_dbo.Hourly_CustomerBalances
    WHERE BalanceDate = CAST(GETDATE() AS DATE)
) c
JOIN (
    SELECT CryptoID, SUM(Balance) AS TotalBalance
    FROM EXW_dbo.Hourly_OmnibusBalances
    WHERE BalanceDate = CAST(GETDATE() AS DATE)
    GROUP BY CryptoID
) o ON c.CryptoID = o.CryptoID
ORDER BY c.UnitBalance DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-20 | Quality: 8.7/10 | Phases: 13/14*
*Tiers: 3 T1, 6 T2, 0 T3, 0 T4, 0 T5 | Elements: 9/9, Logic: 9/10*
*Object: EXW_dbo.Hourly_OmnibusBalances | Type: Table | Production Source: SP_EXW_Hourly ← CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances*
