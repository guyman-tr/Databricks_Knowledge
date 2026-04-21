# EXW_dbo.Hourly_RedeemActivity

> Hourly pre-aggregated redemption activity table — one row per CryptoID × calendar date over a rolling 7-day window, rebuilt on every SP_EXW_Hourly run. Covers sent Redeem transactions only (TransactionTypeId = 0), providing daily redemption volume (count and native units) plus USD value for Tableau operational KPI dashboards. Unlike the Hourly Balance tables (4-day window), RedeemActivity retains 7 days to capture multi-day redemption processing cycles.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | CopyFromLake.WalletDB_Wallet_TransactionsView → External_WalletDB_Wallet_TransactionsView → SP_EXW_Hourly |
| **Refresh** | Hourly — TRUNCATE + INSERT on each run |
| **Synapse Distribution** | HASH (CryptoID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only operational KPI feed |

---

## 1. Business Meaning

Hourly_RedeemActivity summarises customer redemption transaction volume for the rolling 7 most recent calendar days, aggregated to one row per cryptocurrency per day. It is one of six tables rebuilt each hour by SP_EXW_Hourly and feeds Tableau operational KPI dashboards with near-real-time visibility into how many redemption transactions are flowing and their USD value — without requiring queries against the full historical WalletDB transaction tables.

**Scope**: Sent transactions with TransactionTypeId = 0 (Redeem) only. TransactionTypeId = 8 (RedeemAsic) is excluded. Only cryptos that had at least one qualifying redemption on a given date produce a row — there are no zero-count placeholder rows.

**Row structure**: One row per CryptoID × calendar Date per SP run. The `Date` column is the transaction date (when the redeem was sent), not the SP run date. `ReportDate` is the SP run date. The rolling window is today through today-7 (8 calendar dates at most per crypto per run).

**Current footprint** (as of 2026-04-20): 79 rows across 8 dates (2026-04-13→2026-04-20), 17 active cryptos, 1,136 total redemption transactions, ~$2.3M USD value. BTC dominates ($910K), followed by XRP ($622K), USDC ($293K), ETH ($255K). Sparse coverage: not every crypto has a redemption every day (e.g., SHIBA, BCH, COMP, QNT appeared on only 1 of 8 dates).

---

## 2. Business Logic

### 2.1 Redemption Transaction Scope

**What**: Only sent redemption transactions are included.

**Columns Involved**: Date, TotalRedeemTX, TotalRedeemUnits

**Rules**:
- Source: `#tx` temp table = `SELECT * FROM EXW_dbo.External_WalletDB_Wallet_TransactionsView` (which wraps `CopyFromLake.WalletDB_Wallet_TransactionsView`)
- Filter: `TransactionTypeId = 0` — Redeem only. TransactionTypeId=8 (RedeemAsic) is explicitly excluded
- No Gcid filter — all customer and system wallet redemptions included (both Gcid > 0 and Gcid = 0 rows in the COUNT)

### 2.2 7-Day Rolling Window

**What**: Each SP run inserts data for approximately the last 7 calendar days of transactions.

**Columns Involved**: Date, ReportDate

**Rules**:
- Filter: `tv.TransDate >= Convert(DateTime, DATEDIFF(DAY, 7, GETDATE()))` — effective behavior is transactions from the last 7 days
- The original form was `GETDATE() - 7` (commented out by Inessa); the replacement expression produces equivalent results
- `Date` = `CAST(tv.TransDate AS DATE)` — the transaction calendar date (not the SP run date)
- `ReportDate` = `CAST(GETDATE() AS DATE)` — the SP run date; same for all rows in a given run
- TRUNCATE before INSERT means only the latest SP run's data persists — no historical accumulation beyond ~7 days
- Contrast: Hourly_CustomerBalances and Hourly_OmnibusBalances use a 4-day window; RedeemActivity uses 7 days

### 2.3 Aggregation Pattern

**What**: Transactions are aggregated to one row per CryptoID × Date.

**Columns Involved**: TotalRedeemTX, TotalRedeemUnits, CryptoID, Date

**Rules**:
- `GROUP BY CAST(tv.TransDate AS DATE), ct.Name, ct.CryptoID, dp.AvgPrice`
- `TotalRedeemTX` = `COUNT(gcid)` — count of individual redemption records for this crypto on this date
- `TotalRedeemUnits` = `SUM(tv.Amount)` — total native-unit volume redeemed
- Sparse rows: if a crypto has zero redemptions on a date within the window, no row is written for that date (no zero-count placeholder rows)

### 2.4 USD Valuation

**What**: USDValue converts native-unit volume to USD using a daily average price.

**Columns Involved**: USDValue, TotalRedeemUnits, CryptoID, Date

**Rules**:
- Price source: `#DailyPrices` (daily AvgPrice per CryptoID × Date, from EXW_Wallet.EXW_Price, last 7 days)
- LEFT JOIN: `ct.CryptoID = dp.CryptoID AND CAST(tv.TransDate AS DATE) = dp.FullDate`
- Formula: `SUM(tv.Amount) * AvgPrice` — **note**: `AvgPrice` is in the GROUP BY clause, not applied inside the SUM. This means one daily price is applied to the full day's volume per CryptoID. If #DailyPrices had multiple prices per CryptoID per date, rows would multiply.
- In practice 0 NULL USDValue rows — all 17 active redeem cryptos have daily price mappings in #DailyPrices

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CryptoID) — co-located with Hourly_CustomerBalances and Hourly_OmnibusBalances for co-located JOINs on CryptoID. HEAP — trivial full scans given 79 total rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| Today's redeem volume by crypto | `WHERE [Date] = CAST(GETDATE() AS DATE) ORDER BY USDValue DESC` |
| 7-day redeem trend for BTC | `WHERE CryptoID = 1 ORDER BY [Date]` |
| Total USD redeemed in window | `SELECT SUM(USDValue) FROM EXW_dbo.Hourly_RedeemActivity` |
| Daily transaction count across all cryptos | `GROUP BY [Date] ORDER BY [Date]` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.Hourly_OmnibusBalances | `CryptoID` | Compare redeem activity against omnibus wallet inventory for the same crypto |
| EXW_dbo.Hourly_CustomerBalances | `CryptoID` | Compare redemption volume against total customer holdings |

### 3.4 Gotchas

- **`[Date]` is a reserved keyword**: The column name `Date` must be quoted as `[Date]` in all queries — unquoted references will cause parse errors
- **7-day window, not 4**: Unlike the Hourly Balance tables, RedeemActivity covers 7 calendar dates. Queries combining it with CustomerBalances or OmnibusBalances should account for the date range difference
- **Sparse rows**: No zero-count placeholder rows. If a crypto had no redemptions on a day within the window, that day-crypto combination is absent. `GROUP BY [Date]` will show varying crypto counts across dates
- **USDValue GROUP BY dependency**: `AvgPrice` is part of the GROUP BY clause. In practice #DailyPrices has one price per CryptoID per date, but be aware that the structure creates a fan-out risk if that invariant breaks
- **TRUNCATE each hour**: All data is dropped on each SP run — this table cannot be used for trends beyond ~7 days
- **TransactionTypeId=8 excluded**: RedeemAsic transactions are not counted. This table reflects standard Redeem (type 0) only

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis — aggregated, computed, or lookup-enriched. No direct passthrough columns; all values are aggregated or transformed. |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NULL | Calendar date of the redemption transactions this row summarises. CAST(TransDate AS DATE) from External_WalletDB_Wallet_TransactionsView.TransDate. Note: `Date` is a SQL reserved keyword — always quote as `[Date]`. (Tier 2 — SP_EXW_Hourly) |
| 2 | CryptoID | int | NULL | Cryptocurrency identifier. From EXW_Wallet.CryptoTypes.CryptoID (INNER JOIN on tv.CryptoId = ct.CryptoID). Distribution key. (Tier 2 — SP_EXW_Hourly JOIN CryptoTypes) |
| 3 | CryptoName | nvarchar(1000) | NULL | Human-readable cryptocurrency name from EXW_Wallet.CryptoTypes.Name (e.g., BTC, XRP, USDC). (Tier 2 — SP_EXW_Hourly JOIN CryptoTypes) |
| 4 | TotalRedeemTX | int | NULL | Count of individual redemption transactions (TransactionTypeId=0) for this CryptoID on this Date. COUNT(gcid) — system/omnibus redemptions (Gcid=0) are included alongside customer redemptions. (Tier 2 — SP_EXW_Hourly) |
| 5 | TotalRedeemUnits | decimal(38,8) | NULL | Total native-unit volume redeemed for this CryptoID on this Date. SUM(Amount) from External_WalletDB_Wallet_TransactionsView.Amount. (Tier 2 — SP_EXW_Hourly) |
| 6 | ReportDate | date | NULL | Date of the SP_EXW_Hourly run that created this row. CAST(GETDATE() AS DATE). Same for all rows inserted in a single run, regardless of the `Date` column value. (Tier 2 — SP_EXW_Hourly) |
| 7 | UpdateDate | datetime | NULL | ETL timestamp set to GETDATE() at INSERT time. Reflects the specific hourly run that produced this row. (Tier 2 — SP_EXW_Hourly) |
| 8 | USDValue | numeric(38,8) | NULL | USD value of TotalRedeemUnits: SUM(Amount) × AvgPrice from #DailyPrices (daily avg price at Date). AvgPrice is in the GROUP BY clause — one daily price per CryptoID per Date. NULL when no price available (does not occur for currently active redeem cryptos). (Tier 2 — SP_EXW_Hourly) |

---

## 5. Lineage

See [Hourly_RedeemActivity.lineage.md](Hourly_RedeemActivity.lineage.md) for full column-level lineage.

### 5.2 ETL Pipeline

```
WalletDB.Wallet.SentTransactions (production — blockchain redemption records)
  |-- Wallet.TransactionsView (unified tx view, types 0/5/6/7/8/9 + received) --|
  v
CopyFromLake.WalletDB_Wallet_TransactionsView
  (Bronze External Table — Parquet from ADLS)
  |-- EXW_dbo.External_WalletDB_Wallet_TransactionsView (view wrapper) --|
  |-- SP_EXW_Hourly: SELECT * → #tx (HASH(gcid), HEAP) --|
  |-- WHERE TransactionTypeId = 0 AND TransDate >= last 7 days --|
  |-- GROUP BY CAST(TransDate AS DATE), CryptoID, CryptoName, dp.AvgPrice --|
  v
EXW_dbo.Hourly_RedeemActivity
  (79 rows, 17 cryptos, 8 dates, 7-day rolling window, HASH(CryptoID), HEAP)
  UC Target: _Not_Migrated (operational KPI, Synapse-only)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CryptoID + CryptoName | EXW_Wallet.CryptoTypes | Crypto type lookup (name, CryptoID) |
| Date + TotalRedeemUnits | EXW_dbo.External_WalletDB_Wallet_TransactionsView | Source of redemption transaction records (TransactionTypeId=0) |
| USDValue (price) | EXW_Wallet.EXW_Price (via #DailyPrices) | Daily avg USD price for redemption volume valuation |

### 6.2 Referenced By (other objects point to this)

No SSDT stored procedures or views found that reference EXW_dbo.Hourly_RedeemActivity. This table is consumed directly by Tableau dashboards for operational KPI monitoring of redemption activity.

---

## 7. Sample Queries

### 7.1 Today's redeem volume by crypto

```sql
SELECT
    CryptoName,
    CryptoID,
    TotalRedeemTX,
    TotalRedeemUnits,
    USDValue
FROM [EXW_dbo].[Hourly_RedeemActivity]
WHERE [Date] = CAST(GETDATE() AS DATE)
ORDER BY USDValue DESC
```

### 7.2 7-day BTC redemption trend

```sql
SELECT
    [Date],
    TotalRedeemTX,
    TotalRedeemUnits,
    USDValue
FROM [EXW_dbo].[Hourly_RedeemActivity]
WHERE CryptoID = 1  -- BTC
ORDER BY [Date] DESC
```

### 7.3 Daily total redeem USD across all cryptos

```sql
SELECT
    [Date],
    SUM(TotalRedeemTX) AS DailyTX,
    SUM(USDValue) AS DailyUSD
FROM [EXW_dbo].[Hourly_RedeemActivity]
GROUP BY [Date]
ORDER BY [Date] DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-20 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 0 T1, 8 T2, 0 T3, 0 T4, 0 T5 | Elements: 8/8, Logic: 8/10*
*Object: EXW_dbo.Hourly_RedeemActivity | Type: Table | Production Source: SP_EXW_Hourly ← External_WalletDB_Wallet_TransactionsView*
