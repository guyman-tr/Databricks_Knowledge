# Dealing_dbo.V_Dealing_Duco_EODRecon

**Schema**: Dealing_dbo | **UC Target**: `dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon`
**Row count**: ~18.6M (2023-01-02 → 2026-05-06) | **Refresh**: daily (Merge generic pipeline, weekdays only)
**Type**: VIEW | **Base table**: `Dealing_dbo.Dealing_Duco_EODRecon`

---

## 1. Business Meaning

Filtered, deduplicated **view** over `Dealing_Duco_EODRecon` — the daily end-of-day reconciliation between eToro's LP (liquidity provider) hedge holdings and aggregated client NOP. This view is the **canonical entry point** for all downstream broker-specific reconciliation tables (Apex, GS, IB, IG, JPM, SAXO, VISION, BNY VIRTU, CloseOnly).

Three transformations vs. the base table:

1. **Date filter** — `WHERE Date >= '2023-01-01'` (hard-coded cutoff; no rolling window). Excludes pre-2023 history.
2. **DISTINCT** — `SELECT DISTINCT *` removes duplicates from the base table that may arise from edge cases in the writer SP's DELETE+INSERT pattern.
3. **`BuyOrSell` alias** — adds a bracket-free alias column for `[Buy/Sell]`, since BI tools and Spark SQL choke on `/` in column names. The base column is still present (via `*`) — `BuyOrSell` is in addition.

For full business context, ETL semantics, weekend gaps, FULL OUTER JOIN logic, and downstream broker-recon dependencies, see the base table wiki: [Dealing_Duco_EODRecon.md](../Tables/Dealing_Duco_EODRecon.md).

---

## 2. View Definition

```sql
CREATE VIEW [Dealing_dbo].[V_Dealing_Duco_EODRecon] AS
SELECT DISTINCT *, [Buy/Sell] AS BuyOrSell
FROM [Dealing_dbo].[Dealing_Duco_EODRecon] WITH (NOLOCK)
WHERE Date >= '2023-01-01';
```

---

## 3. Lineage

| Layer | Object |
|-------|--------|
| LP source | `Dealing_staging.etoro_Hedge_Netting` + `etoro_History_Netting_History` |
| Client source | `BI_DB_dbo.BI_DB_PositionPnL` |
| FX | `DWH_dbo.Fact_CurrencyPriceWithSplit` |
| Instrument metadata | `DWH_dbo.Dim_Instrument` |
| LP account | `Dealing_staging.etoro_Trade_LiquidityAccounts` |
| Writer SP | `SP_DataForDuco` (Author: Jenia 2021-10-25; daily, weekdays only, P0) |
| Base table | `Dealing_dbo.Dealing_Duco_EODRecon` (~22.6M rows; ROUND_ROBIN, ClusteredIndex Date) |
| **This view** | `V_Dealing_Duco_EODRecon` — date filter + DISTINCT + BuyOrSell alias |
| UC target | `dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon` |

---

## 4. Query Advisory

### 4.1 Use This View, Not the Base
Downstream broker-recon tables and dashboards consistently use this view. Going to the base table directly bypasses the BuyOrSell alias and re-includes pre-2023 history.

### 4.2 Weekend Gaps
Inherited from base: `SP_DataForDuco` does not run on Saturdays/Sundays. Expect missing dates for weekends.

### 4.3 BuyOrSell vs [Buy/Sell] Duplication
Because the view is `SELECT DISTINCT *, [Buy/Sell] AS BuyOrSell`, **both** columns appear in the result set:
- `[Buy/Sell]` (from `*` expansion) — values 'Buy'/'Sell', requires bracket quoting in T-SQL
- `BuyOrSell` (explicit alias) — same values, no brackets needed

In Unity Catalog the bracketed name is exposed as `Buy_Sell` (or similar Spark-safe sanitization) — verify against UC `DESCRIBE TABLE`. Use `BuyOrSell` for portability.

### 4.4 HedgingPercent Interpretation
- `HedgingPercent = 1.0` → fully hedged
- `> 1.0` → over-hedged (LP holds more than client NOP requires)
- `< 1.0` → under-hedged
- `NULL` → ClientUnits = 0 (LP holds position with no matching client demand)

### 4.5 FULL OUTER JOIN Artifacts
Base writer uses FULL OUTER JOIN between LP holdings and client NOP. Rows may have NULLs on either side: LP-only positions (no client NOP) or client-only positions (no LP holding) — both are valid reconciliation events.

### 4.6 NOLOCK in View
The view uses `WITH (NOLOCK)`. May read uncommitted rows during the writer SP's DELETE+INSERT window — typically not a problem since the SP is single-threaded and the window is short.

### 4.7 DISTINCT Cost
`SELECT DISTINCT *` over 18.6M rows is expensive. The DISTINCT exists to suppress accidental duplicates; in well-behaved batches it is a no-op. UC export is via Merge generic pipeline so the Delta target naturally deduplicates.

---

## 5. Elements

All 27 columns are passthrough from the base table. Plus one computed alias.

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | Date | date | Report date (EOD reconciliation date). Weekdays only — no Sat/Sun rows. |
| 2 | LiquidityAccountID | int | LP account identifier from `Dealing_staging.etoro_Trade_LiquidityAccounts`. |
| 3 | LiquidityAccountName | varchar(MAX) | LP account display name. |
| 4 | HedgeServerID | int | Hedge server identifier associated with the LP position. |
| 5 | InstrumentID | int | eToro instrument identifier. Joins to `DWH_dbo.Dim_Instrument`. |
| 6 | ISINCode | varchar(MAX) | ISIN code from LP netting or instrument master. |
| 7 | InstrumentDisplayName | varchar(MAX) | Instrument display name. |
| 8 | Buy/Sell | varchar(10) | Position direction — 'Buy' or 'Sell' — derived from net units sign. Requires bracket quoting in T-SQL. Use `BuyOrSell` alias instead. |
| 9 | eToro_Units | float | Total LP hedge units held at EOD on the eToro side. |
| 10 | ClientUnits | float | Total client NOP units from `BI_DB_PositionPnL` for the instrument. |
| 11 | eToroLocalAmount | money | LP hedge position value in the instrument's local currency. |
| 12 | eToroUSDAmount | money | LP hedge position value in USD (= `eToroLocalAmount * FXratetoUSD`). |
| 13 | ClientAmount | money | Client NOP position value in USD. |
| 14 | eToroRate | float | Average rate of the eToro hedge holding (LP-side weighted average price). |
| 15 | HedgingPercent | float | `eToro_Units / ClientUnits` — hedge coverage ratio. NULL when ClientUnits = 0. |
| 16 | UpdateDate | datetime | Batch execution timestamp (`GETDATE()`). |
| 17 | Symbol | varchar(50) | Instrument ticker symbol (from `Dim_Instrument.Symbol`). |
| 18 | SellCurrency | varchar(10) | Trade currency of the instrument. |
| 19 | Exchange | varchar(MAX) | Exchange name for the instrument. |
| 20 | MKTcap | decimal(13,2) | Market capitalization of the instrument from external reference, used by downstream to size reconciliation thresholds. |
| 21 | Clients_Units_Buy | float | Client units on the buy side (long positions). |
| 22 | Clients_Units_Sell | float | Client units on the sell side (short positions). |
| 23 | Clients_NOP_Buy | float | Client NOP USD value for buy/long positions. |
| 24 | Clients_NOP_Sell | float | Client NOP USD value for sell/short positions. |
| 25 | FXratetoUSD | float | FX rate from instrument trade currency to USD for amount conversion. |
| 26 | CUSIP | varchar(MAX) | CUSIP identifier from the LP netting / external reference data source. |
| 27 | BuyOrSell | varchar(10) | **Computed alias** for `[Buy/Sell]` — bracket-free name for BI tool compatibility. Same values as `[Buy/Sell]`. |

---

## 6. Relationships

| Related Object | Relationship |
|----------------|--------------|
| [`Dealing_Duco_EODRecon`](../Tables/Dealing_Duco_EODRecon.md) | Base table — all columns passthrough |
| `SP_DataForDuco` | Writer SP for the base table (also writes `Dealing_Duco_ActivityRecon`) |
| `Dealing_ApexRecon_*`, `Dealing_GSRecon_*`, `Dealing_IBRecon_*`, `Dealing_IGRecon_*`, `Dealing_SAXORecon_*`, `Dealing_VisionRecon_*`, `Dealing_BNY_VIRTU_Recon_*`, `Dealing_JPMRecon_*`, `Dealing_CloseOnly_Recon` | Downstream broker reconciliation tables — consume this view |

---

## 7. Sample Queries

```sql
-- Latest hedge coverage by LP account and instrument type
SELECT TOP 20
    LiquidityAccountName,
    InstrumentDisplayName,
    BuyOrSell,
    eToro_Units,
    ClientUnits,
    HedgingPercent,
    eToroUSDAmount
FROM Dealing_dbo.V_Dealing_Duco_EODRecon
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.V_Dealing_Duco_EODRecon)
ORDER BY ABS(eToroUSDAmount) DESC;
```

```sql
-- Daily aggregate hedge USD exposure
SELECT Date, SUM(ABS(eToroUSDAmount)) AS total_lp_exposure_usd
FROM Dealing_dbo.V_Dealing_Duco_EODRecon
WHERE Date >= '2026-04-01'
GROUP BY Date
ORDER BY Date;
```

---

*Generated as part of Wave 2 medium-priority documentation effort. For full base-table context see [`Dealing_Duco_EODRecon.md`](../Tables/Dealing_Duco_EODRecon.md).*
