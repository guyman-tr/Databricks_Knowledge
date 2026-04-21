# EXW_dbo.Hourly_CustomerBalances

> Hourly pre-aggregated customer crypto balance table — one row per CryptoId per balance snapshot date (today through today-3), rebuilt on every SP_EXW_Hourly run. Covers only customer-owned wallets (Gcid > 0), providing a lightweight cross-crypto balance and USD value view for Tableau KPI dashboards. The complement to Hourly_OmnibusBalances, which covers omnibus/inventory wallets.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances (via WalletDB) |
| **Writer SP** | EXW_dbo.SP_EXW_Hourly |
| **Refresh** | Hourly — TRUNCATE + INSERT on each run |
| **Synapse Distribution** | HASH (CryptoID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only Tableau feed |

---

## 1. Business Meaning

Hourly_CustomerBalances provides a rolling 4-day (today through today-3) snapshot of total customer crypto balances aggregated by cryptocurrency. It is one of six tables rebuilt by SP_EXW_Hourly and is designed to feed lightweight operational KPI dashboards (Tableau) that require near-real-time balance views without querying the full WalletDB balance history.

Each row represents the total balance held across all customer wallets for a given crypto on a specific snapshot date. Unlike EXW_FactBalance (which is per-user per-day), this table is only per-crypto per-day — it is an aggregate. The table always contains at most 4 BalanceDates: today, today-1, today-2, today-3 (relative to the latest SP run).

---

## 2. Business Logic

### 2.1 Customer Wallet Scope

**What**: Only customer-owned wallets are included. Omnibus and pool wallets are excluded.

**Columns Involved**: UnitBalance, CryptoID

**Rules**:
- Filter: `Gcid > 0` on EXW_Wallet.CustomerWalletsView — only allocated (customer-owned) wallets
- 6 specific `BlockchainProviderWalletId` values are hardcoded-excluded (internal/hot wallets)
- Omnibus wallets (Gcid ≤ 0) go to Hourly_OmnibusBalances (same SP run)

### 2.2 Balance Deduplication and Aggregation

**What**: The SCD-style WalletDB balance table can have multiple rows per WalletId × CryptoId; the SP takes the most recent and aggregates.

**Columns Involved**: UnitBalance, CryptoID, BalanceDate

**Rules**:
- `ROW_NUMBER() OVER (PARTITION BY WalletId, CryptoId ORDER BY DateFrom DESC) = 1` — most recent balance record per wallet-crypto
- `Balance <> 0` filter applied for today, today-1, and today-3 snapshots
- **today-2 snapshot has NO Balance <> 0 filter** — zero-balance wallets included; this may be intentional or an oversight (see review-needed)
- After dedup, `SUM(Balance) GROUP BY CryptoName, CryptoId` produces one row per crypto per snapshot date

### 2.3 Rolling 4-Day Window

**What**: Each run inserts 4 snapshot dates, covering today through today-3.

**Columns Involved**: BalanceDate, ReportDate

**Rules**:
- 4 UNION ALL members in the INSERT SELECT, one per date offset (0, -1, -2, -3 from GETDATE())
- BalanceDate = the snapshot date; ReportDate = CAST(GETDATE() AS DATE) = today on this run (same for all 4 rows of a given crypto)
- After TRUNCATE, only 4 snapshots remain — older dates are dropped each run
- Because the SP runs hourly, each hour the window shifts (e.g., after midnight, today-3 is replaced with a new today-3)

### 2.4 USD Valuation

**What**: USDBalance is computed using a daily price (not hourly), despite the SP running hourly.

**Columns Involved**: USDBalance, UnitBalance, CryptoID

**Rules**:
- Price source: `#DailyPrices` = UNION of EXW_Wallet.EXW_Price (last 7 days, most recent per date) + hourly rates from EXW_Currency.vInstrumentRatesForWeek
- JOIN: `a.CryptoId = dp.CryptoID AND a.BalanceDate = dp.FullDate`
- For intraday runs, the "today" BalanceDate row uses the most recent available price, not a strict end-of-day price
- NULL AvgPrice → NULL USDBalance (LEFT JOIN on price)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CryptoID) — unusual choice given few distinct cryptos (~174) and only 4 rows per crypto. Co-located with Hourly_OmnibusBalances (also HASH(CryptoId)). HEAP — no index; full scans are inexpensive given small row count.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| Today's total customer balance by crypto | `WHERE BalanceDate = CAST(GETDATE() AS DATE)` |
| 3-day trend per crypto | `GROUP BY CryptoName, BalanceDate ORDER BY CryptoName, BalanceDate` |
| Total USD customer balance (latest) | `SELECT SUM(USDBalance) WHERE BalanceDate = MAX(BalanceDate)` |
| Compare to omnibus | Join Hourly_OmnibusBalances on CryptoId + BalanceDate |

### 3.3 Gotchas

- **4-row limit per crypto per run**: The table is rebuilt from scratch each hour. Querying it after a midnight run drops yesterday's "today" which becomes "today-1" — the BalanceDates shift on every run
- **today-2 zero-balance wallets**: Unlike the other 3 snapshots, today-2 does not filter Balance <> 0, which may cause inflated row counts and include zero-balance records
- **USDBalance is NULL when price data is missing**: LEFT JOIN on #DailyPrices; cryptos with no price (e.g., new listings) will have NULL USDBalance
- **Not per-user**: UnitBalance is the TOTAL across all customer wallets for that crypto — cannot be broken down by GCID from this table
- **ReportDate ≠ BalanceDate for today-1/today-2/today-3**: ReportDate is always the day of the SP run; BalanceDate varies across the 4 offsets

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis — aggregated, computed, or sourced from tables without upstream wiki |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ReportDate | date | NULL | Date of the SP_EXW_Hourly run that created this row. CAST(GETDATE() AS DATE). Same for all rows inserted in a single run, regardless of BalanceDate. (Tier 2 — SP_EXW_Hourly) |
| 2 | CryptoID | int | NULL | Cryptocurrency identifier from EXW_Wallet.CryptoTypes. Distribution key. (Tier 2 — SP_EXW_Hourly) |
| 3 | CryptoName | nvarchar(1000) | NULL | Human-readable cryptocurrency name from EXW_Wallet.CryptoTypes.Name (e.g., BTC, ETH). (Tier 2 — SP_EXW_Hourly) |
| 4 | UnitBalance | decimal(38,8) | NULL | Total native-unit balance across all customer wallets for this CryptoID at BalanceDate. SUM(WalletDB_Wallet_V_BI_WalletBalances.Balance), deduplicated per WalletId×CryptoId (most recent DateFrom). Zero-balance wallets included for today-2 only. (Tier 2 — SP_EXW_Hourly) |
| 5 | BalanceDate | date | NULL | The snapshot date this balance represents: today, today-1, today-2, or today-3 relative to the SP run time. (Tier 2 — SP_EXW_Hourly) |
| 6 | UpdateDate | datetime | NULL | ETL timestamp set to GETDATE() at INSERT time. Reflects the specific hourly run that produced this row. (Tier 2 — SP_EXW_Hourly) |
| 7 | USDBalance | numeric(38,8) | NULL | USD value of UnitBalance: UnitBalance × AvgPrice from #DailyPrices (daily price for BalanceDate). NULL if no price available for this CryptoID on BalanceDate. (Tier 2 — SP_EXW_Hourly) |

---

## 5. Lineage

See [Hourly_CustomerBalances.lineage.md](Hourly_CustomerBalances.lineage.md) for full column-level lineage.

---

## 6. Data Quality Notes

- **today-2 zero-balance inconsistency**: Balance <> 0 filter is missing for today-2, while today, today-1, and today-3 all filter zero balances
- **Hourly TRUNCATE**: All prior data is dropped on each run — no historical trend beyond 4 days is retained in this table

---

## 7. Open Questions / Review Needed

See [Hourly_CustomerBalances.review-needed.md](Hourly_CustomerBalances.review-needed.md).

---

## 8. Tier Footer

| Tier | Count | Columns |
|---|---|---|
| Tier 2 | 7 | All columns — aggregated or SP-computed from WalletDB; no upstream wiki |
