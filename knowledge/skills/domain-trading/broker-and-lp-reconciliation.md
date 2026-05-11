---
id: broker-and-lp-reconciliation
name: "Broker & Liquidity-Provider Reconciliation"
description: "Daily end-of-day and intraday reconciliation between eToro's hedge book and external broker / liquidity-provider records. Bridge-side skill: connects broker (client NOP from BI_DB_PositionPnL) to dealer (LP hedge holdings from etoro_Hedge_Netting). Anchored on the Duco foundation (V_Dealing_Duco_EODRecon view as canonical entry point, ~18.6M rows weekdays-only 2023-01-02→present, 27 columns + the HedgingPercent KPI) and the per-LP recon tables: Apex (US equity holdings + trade activity + 7 SOD-file family), BNY-Virtu (non-US equity), Saxo (real stocks + employee accounts), Marex (futures with unique client-level grain), Goldman Sachs / Interactive Brokers / IG / JPM / Vision (bronze layer). Covers the EOD-holdings-vs-trade-activity split, the three-way comparison pattern (LP vs eToro hedge vs client NOP), HedgingPercent interpretation, weekend-gap rule, FULL OUTER JOIN NULL artifacts, SOD-file health gating, the Marex-futures-grain anomaly, and the BuyOrSell column-naming workaround."
triggers:
  - reconciliation
  - recon
  - EOD recon
  - Duco
  - DealingDuco
  - Duco_EODRecon
  - Duco_ActivityRecon
  - V_Dealing_Duco_EODRecon
  - HedgingPercent
  - hedge coverage
  - Apex recon
  - ApexRecon_Holdings
  - ApexRecon_TradeActivity
  - SodFiles
  - SOD files
  - SOD reconciliation
  - BNY Mellon
  - BNY Virtu
  - Virtu
  - Saxo recon
  - SAXORecon
  - Marex recon
  - Marex futures
  - GSRecon
  - Goldman Sachs hedge
  - IGRecon
  - IG hedge
  - JPMRecon
  - JPM hedge
  - Vision recon
  - VisionRecon
  - CloseOnly
  - broker break
  - position discrepancy
  - LP holdings
  - liquidity account
  - LiquidityAccountID
  - HedgeServerID
  - settlement risk
  - failed trade investigation
  - hedge gap
  - eToro_Units
  - ClientUnits
required_tables:
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures
  - main.finance.bronze_sodreconciliation_apex_sodfiles
version: 2
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Broker & Liquidity-Provider Reconciliation

Every day the Dealing team runs a multi-way reconciliation: what did eToro execute on the hedge side, what did the liquidity provider (LP) confirm, and what do client positions demand? Mismatches between those three views are **settlement risk** — failed trades, data-sync gaps, corporate-action drift, or genuine errors that the operations team must investigate before they become losses.

**Side classification**: **Bridge**. This sub-skill sits at the broker ↔ dealer junction. It joins broker-side artifacts (`BI_DB_PositionPnL` = client NOP) against dealer-side artifacts (`etoro_Hedge_Netting` = LP hedge holdings) through the Duco view. Every recon question is a bridge question by construction.

The reconciliation stack has **two layers**:

1. **Foundation — Duco**: `V_Dealing_Duco_EODRecon` (view, not the base table — Warning #1) + `Dealing_Duco_ActivityRecon`. The eToro-internal three-way reconciliation between LP hedge holdings, the aggregated client NOP, and the FX-converted USD amounts.
2. **Per-LP recon family**: one or more tables per LP that consume the Duco view as canonical input and overlay the LP's official custodian / trade-activity file. ~9 LPs in production: **Apex Clearing** (US equity), **BNY-Mellon/Virtu** (non-US equity), **Saxo Bank** (real stocks + employee accounts), **Marex** (futures), **Goldman Sachs (GS)**, **Interactive Brokers (IB)**, **IG**, **JPM**, **Vision**, plus the **CloseOnly** wind-down flag.

This sub-skill is the analyst-facing map. Load it for any question about position/holdings mismatches, daily LP breaks, hedge coverage, settlement investigations, or SOD-file health.

## When to Use

Load when the question is about:

- **Daily LP-coverage health**: "Are we hedged correctly?", "Duco breaks today", "any breaks today on Apex?", "Apex holdings discrepancy"
- **Per-instrument hedge gap**: "Why is `eToro_Units != Apex_Units` for instrument X?", "BNY-Virtu break on March 4", "Saxo break", "Marex futures discrepancy"
- **Hedge coverage ratio**: "What's our HedgingPercent on US equity?", "where are we under-hedged?", "over-hedged positions"
- **Settlement risk**: "settlement risk on date Y", "failed-trade investigation", "what could fail to settle?"
- **LP file ingestion**: "did Apex files load today?", "SOD file health for date X", "why is Apex recon showing zero breaks?" (always: rule out a load failure first)
- **GS / IB / IG / JPM / Vision / CloseOnly recon** — bronze-only recon tables, less-mature pipelines
- **Finance external recon**: "CMR DB external reconciliation", "cash activity vs stock activity recon"

Do **not** load for:

- Hedge order execution forensics (single-position investigation, `Hedge.ExecutionLog`) → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)
- LP contract terms / fees paid TO providers / COGS → [`lp-contracts-and-cogs.md`](lp-contracts-and-cogs.md)
- Pricing / FX rates / instrument prices → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Crypto redemption recon (it's wallet-side, not LP-side) → `domain-payments` (the crypto-payments sub-skill)
- Customer-level position state at open / lifecycle → [`position-state-and-grain.md`](position-state-and-grain.md)
- Best-execution / TCA (latency, market impact) → [`best-execution.md`](best-execution.md)

## Scope

In scope: the Duco view (`V_Dealing_Duco_EODRecon` — 27 columns + `BuyOrSell` alias, 18.6M rows, ~9 LP feeds upstream), the Duco activity recon (`Dealing_Duco_ActivityRecon`), the Apex Clearing recon trio (holdings + trade activity + the bronze SOD-file family of 7 files: cash, stock, trade, dividend, new accounts, closed accounts, revenue reports — plus the `sodfiles` registry), the BNY-Virtu non-US equity recon, the Saxo three-way recon, the Marex futures recon (client-level grain), the Marex non-futures recon (bronze), the GS/IB/IG/JPM/Vision bronze recon variants (each holdings + trades), the CloseOnly flag, the CMR DB external/internal recon tables for finance, the crypto-recon counterparty/tickers mapping tables, the three-way diff pattern (LP vs eToro hedge vs client NOP), the HedgingPercent column semantics (1.0=hedged, >1=over, <1=under, NULL=client-zero), settlement-risk interpretation, weekend-gap rule, FULL OUTER JOIN NULL artifacts, SOD-file health gating before trusting downstream recons, the Marex-futures unique grain (CID × Contract — no `eToro_Units`), the `Buy/Sell` column-name workaround.

Out of scope: hedge-order execution events (`dealing-investigation-and-execution.md` — the `Hedge.ExecutionLog` family), LP fee contracts and pricing terms (`lp-contracts-and-cogs.md`), pricing data sources (`pricing-and-currency-history.md`), customer-side position state (`position-state-and-grain.md`), crypto-wallet redemption recon (`domain-payments`), best-execution / TCA (`best-execution.md`).

Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — Use `V_Dealing_Duco_EODRecon` (the view), NOT `Dealing_Duco_EODRecon` (the base table).** The view is the canonical entry point — it (a) filters to `Date >= '2023-01-01'`, (b) applies `DISTINCT *` to suppress DELETE+INSERT duplicates, and (c) adds a bracket-free `BuyOrSell` alias (the underlying `[Buy/Sell]` column has a `/` in its name and chokes Spark SQL & BI tools). **All downstream broker-recon tables and dashboards use this view.** Going to the base table bypasses the alias and re-includes pre-2023 history. The `required_tables` anchor reflects this — use `main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon`.

2. **Tier 1 — `HedgingPercent` is the headline KPI — interpret with care.** `HedgingPercent = eToro_Units / ClientUnits` per row. Values: **1.0 = fully hedged**, **>1.0 = over-hedged** (LP holds more than client demand), **<1.0 = under-hedged**, **NULL = ClientUnits = 0** (LP holds a position with no matching client demand — typically corporate-action or position-roll artifacts). For aggregate "are we hedged?" questions, weight by absolute USD exposure (`ABS(eToroUSDAmount)`), not by row count.

3. **Tier 1 — Weekend gaps: `SP_DataForDuco` does not run on Saturdays/Sundays.** `V_Dealing_Duco_EODRecon` and all downstream LP recons have **no rows for weekends**. A query like `SELECT MAX(Date)` will return the most recent weekday. When computing "last 7 days", expect only 5 dates of data. The base writer SP runs at Priority 0 (highest priority) daily on weekdays via the `SB_Daily` Service Broker.

4. **Tier 1 — FULL OUTER JOIN artifacts: rows can have NULLs on either side.** The base writer uses `FULL OUTER JOIN` between LP holdings (left) and client NOP (right). A row with **`eToro_Units` NULL but `ClientUnits` non-zero** = client position not yet hedged. A row with **`ClientUnits` NULL but `eToro_Units` non-zero** = LP holds a position with no matching client demand (corporate action, position roll, error). Both are valid reconciliation events; filter `WHERE x IS NOT NULL` only if you're sure what you want.

5. **Tier 1 — The Marex futures recon (`Dealing_Marex_Recon_EODHoldings_Futures`) has a different grain than every other recon.** Every other per-LP recon is at `Date × LiquidityAccountID × InstrumentID × Buy/Sell` grain (LP custodian file vs eToro *hedge-book aggregate*). The Marex futures table is at `Date × CID × Contract × IsBuy × OrderID` grain — comparing Marex's lots against the *individual client position* (`Clients_Lots` / `ClientUnits`). **There is no `eToro_Units` column** on the futures recon, because in the futures model client positions pass through to Marex 1:1. Don't try to join the futures recon to Duco the same way you'd join equity recons. The non-futures Marex recon (`Dealing_Marex_Recon_EODHoldings`, bronze only) follows the standard grain.

6. **Tier 1 — Apex SOD files are append-only and idempotent — and recon CAN show "clean" when files failed to load.** The `apex.SodFiles` master registry (`main.finance.bronze_sodreconciliation_apex_sodfiles`) tracks every file ingested from Apex's Azure Blob Storage. When a file fails (`Status != 'Success'`), the recon pipelines silently use the **previous day's snapshot** — recon results may look clean because there's no fresh data to compare. **Always check SOD file status before trusting an Apex recon result for a given date.** Apex's SOD-file family in finance: `ext869_cashactivity`, `ext870_stockactivity`, `ext872_tradeactivity`, `ext922_dividendreport`, `ext1034_newaccountfinancialinformation` (bi_db), `ext538_closedaccounts` (bi_db), `ext1047_revenuereports`, `sodfiles` (the registry).

7. **Tier 2 — Diff columns answer different questions; don't conflate them.** Reading the Saxo recon as the canonical example:
   - `SAXO_Units − eToro_Units` → does the LP custodian match what eToro thinks it's hedging? Mismatch = **settlement break** (LP didn't confirm what we sent).
   - `SAXO_Units − Clients_Units` → does the LP custodian match what clients are net long/short? Mismatch = the combined hedge-gap + settlement-break delta.
   - `eToro_Units − Clients_Units` → does our hedge match client demand? Mismatch = **hedge gap** (we executed too much / too little).
   - `Reality − Supposed` (Saxo specific) → similar to (LP - eToro) but explicitly the "what we paid for" delta.
   - `Reality − Client` (Saxo specific) → similar to (LP - Client).
   
   Hedge gaps are operational / risk problems (Trading-Desk fix). Settlement breaks are LP / ops problems (Operations team fix). Treat them differently.

8. **Tier 2 — In UC, the bracketed `[Buy/Sell]` column name is sanitized.** Spark cannot handle `/` in column names. The view's `BuyOrSell` alias is the safe column to reference. The original `[Buy/Sell]` is exposed as `Buy_Sell` (underscore) or similar Spark-safe sanitization — verify with `DESCRIBE TABLE` if you must use it. Prefer `BuyOrSell`.

9. **Tier 2 — GS, IB, IG, JPM, Vision recon tables are bronze-only.** They have not yet been promoted to gold layer. Bronze tables: `bronze_sql_dp_prod_we_dealing_dbo_dealing_gsreconeodholding`, `..._gsrecontrades`, `..._igreconeodholding`, `..._igrecontrades`, `..._jpmreconeodholding`, `..._jpmrecontrades`, `..._visionrecon_eodholdings`, `..._visionrecon_trades`. They're queryable but: (a) more likely to break on schema drift, (b) less validation, (c) not the canonical input for downstream dashboards. Use with caution.

10. **Tier 3 — Two locations of the Duco EOD recon in UC.** `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon` (base table, BI-published copy) and `main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon` (the canonical view). The bi_db copy is the base table; the dealing copy is the view. **Use the view per Warning #1.** The base copy exists for BI-team historical reasons.

11. **Tier 3 — The base writer SP is `SP_DataForDuco` (authored by Jenia, 2021-10-25, P0 priority, `SB_Daily`).** Author + priority + cadence are useful for incident response. The SP writes BOTH `Dealing_Duco_EODRecon` AND `Dealing_Duco_ActivityRecon`. Activity recon uses the same join logic but on intraday trade activity instead of EOD holdings.

12. **Tier 3 — `MKTcap` column is used to size recon thresholds, not for reporting.** Downstream pipelines reference `Dim_Instrument.MKTcap` (joined here) to set acceptable break tolerances per instrument — a $1M break on a $200B mega-cap is different from a $1M break on a $50M micro-cap. Don't repurpose `MKTcap` for valuation work; it's reference data injected for threshold logic.

## Tables — the reconciliation stack

### Foundation (eToro-internal three-way recon)

| Table | Grain | Layer | Rows | What it answers |
|---|---|---|---|---|
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon` ★ | `Date × LiquidityAccountID × InstrumentID × Buy/Sell × HedgeServer` | **Gold view (canonical entry point)** | ~18.6M (2023-01→) | **Daily EOD holdings recon**: LP hedge vs client NOP, units + USD, with HedgingPercent ratio. Weekdays only. |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon` | Same grain, trade-activity flow | Gold | — | **Daily trade-activity recon**: hedge-server executions vs client trade activity (opens/closes). |
| `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon` | Same as view | Gold base | — | Base table copy (BI-published). Prefer the view per Warning #1. |

★ = canonical entry point. The view's 27 columns: `Date`, `LiquidityAccountID`, `LiquidityAccountName`, `HedgeServerID`, `InstrumentID`, `ISINCode`, `InstrumentDisplayName`, `Buy/Sell` (use `BuyOrSell` alias), `eToro_Units`, `ClientUnits`, `eToroLocalAmount`, `eToroUSDAmount`, `ClientAmount`, `eToroRate` (LP-side weighted-avg price), `HedgingPercent`, `UpdateDate`, `Symbol`, `SellCurrency`, `Exchange`, `MKTcap`, `Clients_Units_Buy`, `Clients_Units_Sell`, `Clients_NOP_Buy`, `Clients_NOP_Sell`, `FXratetoUSD`, `CUSIP`, `BuyOrSell`.

### Per-LP — Apex Clearing (US equity)

| Table | Grain | Layer | Use |
|---|---|---|---|
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings` | `Date × InstrumentID × HedgeServer` | Gold | EOD shares-held recon: `Etoro_Units` vs `Apex_Units`. |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity` | `Date × LiquidityAccountID × InstrumentID × IsBuy` | Gold | Daily trade-execution recon: eToro units + rate vs Apex's reported trade activity. |
| `main.finance.bronze_sodreconciliation_apex_sodfiles` | `FileName` | Bronze | **SOD-file ingestion registry. Always check `Status='Success'` before trusting downstream Apex recons** (Warning #6). |
| `main.finance.bronze_sodreconciliation_apex_ext869_cashactivity` | Per-file | Bronze | Apex cash activity (daily deposits/withdrawals on Apex sub-accounts). |
| `main.finance.bronze_sodreconciliation_apex_ext870_stockactivity` | Per-file | Bronze | Apex stock activity. |
| `main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity` | Per-file | Bronze | Apex trade activity (the feed for ApexRecon_TradeActivity). |
| `main.finance.bronze_sodreconciliation_apex_ext922_dividendreport` | Per-file | Bronze | Apex dividend report — feeds the **Tier-1 dividend revenue path** under `domain-revenue-and-fees` (see that domain for divident-flow accounting). |
| `main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports` | Per-file | Bronze | Apex revenue reports (cross-fee detail at Apex level). |
| `main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation` | Per-file | Bronze | New account opens at Apex with financial KYC info. |
| `main.bi_db.bronze_sodreconciliation_apex_ext538_closedaccounts` | Per-file | Bronze | Apex closed accounts. |

### Per-LP — BNY-Mellon / Virtu (non-US equity)

| Table | Grain | Layer | Use |
|---|---|---|---|
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding` | `Date × InstrumentID` | Gold | EOD holdings recon: BNY custodian vs `eToro_Units` (hedge) vs `Clients_Units` (NOP). Same three-way pattern as Saxo. |

### Per-LP — Saxo Bank (real stocks + employee accounts)

| Table | Grain | Layer | Use |
|---|---|---|---|
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings` | `Date × InstrumentID × HedgeServer × AccountNumber` | Gold | **Three-way recon**: `SAXO_Units` vs `eToro_Units` vs `Clients_Units`. AccountNumbers like `20xxxxx` are Saxo's account format. Real stocks + employee accounts. Four diff columns — see Warning #7. |

### Per-LP — Marex (futures with unique grain)

| Table | Grain | Layer | Use |
|---|---|---|---|
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures` ★ | `Date × CID × Contract × IsBuy × OrderID` — **CLIENT-LEVEL** | Gold | Marex's lots vs **individual client position** (`Clients_Lots` / `ClientUnits`). **No `eToro_Units` — futures model is 1:1 pass-through.** WA Marex price included. Added May 2025. **Don't try to join this against Duco like the equity recons** (Warning #5). |
| `main.dealing.bronze_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings` | Standard `Date × LiquidityAccountID × InstrumentID × Buy/Sell` | Bronze | Non-futures Marex EOD holdings (standard equity-like grain). |
| `main.dealing.bronze_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_trades` | Standard | Bronze | Non-futures Marex trade activity. |
| `main.dealing.bronze_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_trades_futures` | Same as futures EOD | Bronze | Futures trade activity. |

★ Unique grain. See Warning #5.

### Per-LP — Bronze-only LPs (less-mature pipelines)

| LP | Holdings table (bronze) | Trades table (bronze) | Side |
|---|---|---|---|
| **Goldman Sachs** | `main.dealing.bronze_sql_dp_prod_we_dealing_dbo_dealing_gsreconeodholding` | `..._gsrecontrades` | CFD / equity hedging |
| **IG** | `..._igreconeodholding` | `..._igrecontrades` | CFD hedging |
| **JPM** | `..._jpmreconeodholding` | `..._jpmrecontrades` | Equity / FX hedging |
| **Vision** | `..._visionrecon_eodholdings` | `..._visionrecon_trades` | Institutional flow |
| **Interactive Brokers (IB)** | — *(future, not yet ingested)* | — | US equity backup / specific products |
| **CloseOnly** | — *(flag column on positions)* | — | Wind-down recon for retired LP relationships |

### Finance external / internal recon (CMR DB)

| Table | Layer | Use |
|---|---|---|
| `main.finance.bronze_cmrdb_dbo_externalreconciliation` | Bronze | External party reconciliation feed (Finance domain). |
| `main.finance.bronze_cmrdb_dbo_externalreconciliationtotalpriority` | Bronze | External recon with priority weighting. |
| `main.finance.bronze_cmrdb_dbo_internalreconciliation` | Bronze | Internal eToro reconciliation (cross-system / inter-entity). |

### Crypto recon (mapping tables — counterparty + tickers)

| Table | Layer | Use |
|---|---|---|
| `main.dealing.bronze_fivetran_google_sheets_mappingsforcryptoreconcilation_counterparty` | Bronze | Counterparty mapping for crypto recon (Google Sheets via Fivetran). |
| `main.dealing.bronze_fivetran_google_sheets_mappingsforcryptoreconcilation_tickers` | Bronze | Ticker mapping for crypto recon. |

---

## Query Patterns

### Pattern 1 — Daily "are we clean?" (Duco view, hedge coverage)
```sql
SELECT Date,
       COUNT(*)                              AS rows_reconciled,
       SUM(ABS(eToroUSDAmount))              AS total_lp_exposure_usd,
       COUNT(CASE WHEN HedgingPercent IS NULL THEN 1 END)                AS lp_only_positions,
       COUNT(CASE WHEN HedgingPercent BETWEEN 0.99 AND 1.01 THEN 1 END)  AS rows_well_hedged,
       COUNT(CASE WHEN HedgingPercent < 0.99 OR HedgingPercent > 1.01 THEN 1 END) AS rows_out_of_band,
       SUM(CASE WHEN HedgingPercent IS NULL OR ABS(HedgingPercent - 1) > 0.01
                THEN ABS(eToroUSDAmount) ELSE 0 END)                     AS usd_at_risk
FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon
WHERE Date BETWEEN '2026-05-01' AND '2026-05-09'
GROUP BY Date
ORDER BY Date;
```
**Use when:** "are we hedged correctly this week?", "Duco breaks summary", "hedge coverage report"

### Pattern 2 — Drill into the worst breaks today (Duco view)
```sql
SELECT LiquidityAccountName, InstrumentDisplayName, Symbol, BuyOrSell,
       eToro_Units, ClientUnits, HedgingPercent,
       eToroUSDAmount, ClientAmount,
       (eToro_Units - ClientUnits) AS hedge_gap_units,
       (eToroUSDAmount - ClientAmount) AS hedge_gap_usd
FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon
WHERE Date = (SELECT MAX(Date)
              FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon)
  AND (HedgingPercent IS NULL OR ABS(HedgingPercent - 1) > 0.01)
ORDER BY ABS(eToroUSDAmount - ClientAmount) DESC
LIMIT 50;
```
**Use when:** "show me the worst breaks", "biggest hedge gap today", "what are we under/over-hedged on?"

### Pattern 3 — Apex EOD holdings discrepancy (per-instrument)
```sql
SELECT Date, InstrumentID, HedgeServer,
       Etoro_Units, Apex_Units,
       (Etoro_Units - Apex_Units) AS diff_units
FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings
WHERE Date = '2026-05-09'
  AND Etoro_Units != Apex_Units
ORDER BY ABS(Etoro_Units - Apex_Units) DESC;
```
**Use when:** "Apex breaks today", "biggest LP-side mismatch on US equity"

### Pattern 4 — Apex SOD file health (always run before trusting Pattern 3)
```sql
SELECT Date, FileName, Status, ErrorMessage
FROM main.finance.bronze_sodreconciliation_apex_sodfiles
WHERE Date >= CURRENT_DATE - 7
ORDER BY Date DESC, FileName;
```
**Use when:** Before any Apex-recon investigation. A clean recon may just mean the file failed to load (Warning #6).

### Pattern 5 — Saxo three-way diff (the canonical four-diff pattern)
```sql
SELECT Date, InstrumentID, HedgeServer, AccountNumber,
       SAXO_Units, eToro_Units, Clients_Units,
       `SAXO-eToro_Units`     AS lp_vs_etoro_units,    -- settlement break
       `SAXO-Clients_Units`   AS lp_vs_clients_units,  -- combined gap+break
       `Reality-Supposed`     AS reality_vs_supposed,  -- "what we paid for" delta
       `Reality-Client`       AS reality_vs_client     -- LP vs client demand
FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings
WHERE Date = '2026-05-09'
  AND (ABS(`SAXO-eToro_Units`) > 0 OR ABS(`SAXO-Clients_Units`) > 0);
```
**Use when:** "Saxo break", "real stocks recon on May 9". The four diff columns each answer a different operational question — see Warning #7.

### Pattern 6 — BNY-Virtu non-US equity recon
```sql
SELECT Date, InstrumentID,
       BNY_Units, eToro_Units, Clients_Units,
       (BNY_Units - eToro_Units)  AS lp_minus_etoro,
       (BNY_Units - Clients_Units) AS lp_minus_clients
FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding
WHERE Date BETWEEN '2026-05-01' AND '2026-05-09'
  AND (BNY_Units != eToro_Units OR BNY_Units != Clients_Units);
```
**Use when:** "BNY recon", "non-US equity break"

### Pattern 7 — Marex futures client-level recon (no eToro_Units!)
```sql
SELECT Date, CID, Contract, IsBuy, OrderID,
       Marex_Lots, Clients_Lots,
       (Marex_Lots - Clients_Lots) AS diff_lots,
       WA_Marex_Price
FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures
WHERE Date = '2026-05-09'
  AND Marex_Lots != Clients_Lots;
```
**Use when:** "Marex futures break", "client futures recon", "which clients have a futures discrepancy?"

### Pattern 8 — LP coverage discovery (every recon table for an LP)
```sql
SELECT table_schema, table_name,
       CASE WHEN table_name LIKE 'gold_%' THEN 'gold' ELSE 'bronze' END AS layer
FROM main.information_schema.tables
WHERE LOWER(table_name) LIKE '%recon%'
  AND LOWER(table_name) LIKE '%saxo%'   -- change for other LPs
ORDER BY layer DESC, table_name;
```
**Use when:** "what tables do we have for LP X?", validating coverage before authoring an aggregate. Replace `%saxo%` with `%gs%`, `%ig%`, `%jpm%`, `%vision%`, `%marex%`, `%apex%`, `%bny%`, etc.

---

## Cross-references

- Hedge-order execution forensics (single-position) → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md) — uses `Hedge.ExecutionLog`, `HBCExecutionLog`, etc.
- LP contracts, fees TO providers, COGS → [`lp-contracts-and-cogs.md`](lp-contracts-and-cogs.md)
- Pricing inputs to recon (`Fact_CurrencyPriceWithSplit`) → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Customer-side position state → [`position-state-and-grain.md`](position-state-and-grain.md)
- Apex dividend revenue path → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md) (the `ext922_dividendreport` feed)
- Crypto redemption recon (wallet) → [`../domain-payments/SKILL.md`](../domain-payments/SKILL.md)
- Best-execution / TCA → [`best-execution.md`](best-execution.md)

## Sources Consulted (per `/speckit.skill` Phase 2.5)

`Class`: H = Hybrid (Synapse + Lake). `Tier`: 1a wiki, 1b UC comment, 2 procs/SP source, 3 lineage, 4 live distincts.

| Anchor | Class | Tier | Source | Notes |
|---|---|---|---|---|
| Dealing_Duco_EODRecon (view + base) | H | 1a | knowledge/synapse/Wiki/Dealing_dbo/Views/V_Dealing_Duco_EODRecon.md | **Critical**: the VIEW is canonical, not the base table. 27 columns + `BuyOrSell` alias. `HedgingPercent` KPI semantics. Weekday-only rule. FULL OUTER JOIN NULL artifacts. NOLOCK semantics. |
| Dealing_Duco_EODRecon (base) | H | 1a | knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_Duco_EODRecon.{md,review-needed.md,lineage.md} | Base table + writer SP context. |
| Per-LP recon family | H | 1a | knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_{ApexRecon,SAXORecon,JPMRecon,GSRecon,IGRecon,VisionRecon,Marex_Recon,BNY_VIRTU_Recon,IBRecon,CloseOnly}*.md | ~33 LP recon wikis covering the 9-LP family across holdings + trade activity variants. Saxo's four-diff pattern documented in `Dealing_SAXORecon_EODHoldings.md`. |
| SP_DataForDuco | S | 2 | Wiki lineage refs | Writer SP (Jenia 2021-10-25, P0, SB_Daily, weekdays only). Writes BOTH `Dealing_Duco_EODRecon` AND `Dealing_Duco_ActivityRecon`. |
| Apex SOD-file family | H | 1a + 4 | knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/ + UC information_schema | 7 ext-files in finance + 2 in bi_db. SodFiles registry is the gate (Warning #6). |
| Recon-table inventory | H | 4 | UC information_schema.tables (live, 2026-05-11) | Live 33-table inventory across `main.dealing`, `main.bi_db`, `main.finance` schemas. Bronze-only LPs identified: GS, IG, JPM, Vision. Two locations of Duco EOD recon confirmed. CMR DB + crypto-recon mapping tables surfaced. |

## Provenance

v2 rebuilt 2026-05-11 per `/speckit.skill` Phase 2.5. v1 was authored from UC table-level comments only; v2 adds the deep `V_Dealing_Duco_EODRecon` wiki, the per-LP recon family wikis, the live UC table inventory, and explicit Bridge-side classification.

**Key v2 additions vs v1**:
- **Canonical entry point switched** to `V_Dealing_Duco_EODRecon` (view) — v1 used the base table (Warning #1)
- **`HedgingPercent` KPI exposition** — the headline column for "are we hedged?" — entirely missing from v1 (Warning #2)
- **Weekend-gap rule** — `SP_DataForDuco` doesn't run weekends; LP recons inherit this (Warning #3)
- **FULL OUTER JOIN NULL artifacts** — LP-only and client-only rows are valid recon events (Warning #4)
- **Full 27-column reference** for the Duco view (v1 listed only 5 columns informally)
- **Apex SOD-file family** expanded from 1 (sodfiles) to 9 (ext869/ext870/ext872/ext922/ext1034/ext538/ext1047 + sodfiles + integration with downstream Apex recons)
- **Bronze-only LP recon family** documented: GS, IG, JPM, Vision (Warning #9)
- **CMR DB external/internal recon** (Finance domain) — entirely missing from v1
- **Crypto-recon mapping tables** (counterparty + tickers, Google Sheets via Fivetran)
- **SP_DataForDuco author + cadence** (Jenia, 2021-10-25, P0) — useful for incident response (Warning #11)
- **`MKTcap` purpose** (threshold sizing, not valuation) — Warning #12
- **`Buy/Sell` column-naming workaround** + UC sanitization (Warning #8)
- **Pattern 1 redesigned** to use `HedgingPercent` as the central metric
- **Pattern 2 new** — drill-into-worst-breaks pattern
- **Pattern 4 promoted** — SOD file health check (now mandatory before any Apex investigation)
- **Bridge-side classification** explicitly stated (broker ↔ dealer junction at the row level)
