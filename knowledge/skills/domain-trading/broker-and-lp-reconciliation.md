---
id: broker-and-lp-reconciliation
name: "Broker & Liquidity-Provider Reconciliation"
description: "Daily end-of-day and intraday reconciliation between eToro's hedge book and external broker / liquidity-provider records. Anchored on Duco (the two-part eToro-internal reconciliation between hedge holdings and client NOP) and the family of per-LP recon tables (Apex for US equity + dividends + trade activity, BNY-Virtu for non-US equity, Saxo for real stocks + employee accounts, Marex for futures, plus Goldman Sachs, Interactive Brokers, IG, JPM, Vision, CloseOnly). Covers EOD holdings recon vs trade-activity recon, the three-way comparison pattern (LP vs eToro hedge vs client NOP), discrepancy diff columns, and the SOD-file backbone for Apex."
triggers:
  - reconciliation
  - recon
  - EOD recon
  - Duco
  - DealingDuco
  - Duco_EODRecon
  - Duco_ActivityRecon
  - Apex recon
  - ApexRecon_Holdings
  - ApexRecon_TradeActivity
  - ApexRecon_Hedging
  - BNY Mellon
  - BNY Virtu
  - Virtu
  - Saxo recon
  - Marex recon
  - Marex futures
  - Goldman Sachs hedge
  - IG hedge
  - JPM hedge
  - Vision recon
  - SOD files
  - SOD reconciliation
  - broker break
  - position discrepancy
  - LP holdings
  - liquidity account
  - settlement risk
  - failed trade investigation
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Broker & Liquidity-Provider Reconciliation

Every day the Dealing team runs a multi-way reconciliation: what did eToro execute on the hedge side, what did the liquidity provider (LP) confirm, and what do client positions demand? Mismatches between those three views are **settlement risk** — failed trades, data-sync gaps, corporate-action drift, or genuine errors that the operations team must investigate before they become losses. The reconciliation stack has two layers:

1. **`Dealing_Duco_EODRecon`** + **`Dealing_Duco_ActivityRecon`** — the eToro-internal two-part reconciliation between hedge holdings and client NOP. The **foundation** for everything downstream.
2. **Per-LP recon tables** — one or more tables per liquidity provider (Apex Clearing, BNY-Mellon/Virtu, Saxo Bank, Marex, Goldman Sachs, Interactive Brokers, IG, JPM, Vision, CloseOnly) — each comparing the LP's official custodian / trade-activity file against eToro's internal view at the granularity that LP supports.

This sub-skill is the analyst-facing map of the reconciliation stack. Use it when the question is about position/holdings mismatches, daily LP breaks, or settlement investigations.

## When to Use

Load when the question is about:

- "Apex EOD recon for last week", "any breaks today on Apex?", "Apex holdings discrepancy"
- "BNY-Virtu recon", "non-US equity recon", "what broke with BNY on March 4?"
- "Saxo recon", "real stocks recon vs Saxo"
- "Marex futures recon", "client futures vs Marex lots"
- "Duco EOD recon", "Duco activity recon", "hedge holdings vs client NOP discrepancy"
- "Why is `Etoro_Units != Apex_Units` for instrument X?"
- "Settlement risk on date Y", "failed-trade investigation"
- "Which LPs broke today?"
- "SOD file ingestion status for Apex"

Do **not** load for:

- Hedge order execution forensics (single-position investigation) → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)
- LP contract terms / fees paid TO providers → [`lp-contracts-and-cogs.md`](lp-contracts-and-cogs.md)
- Pricing / FX rates → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Crypto redemption recon (it's wallet-side) → `domain-payments` (the crypto-payments sub-skill)
- Customer-level position state → [`position-state-and-grain.md`](position-state-and-grain.md)

## Scope

In scope: Duco EOD holdings recon (`Dealing_Duco_EODRecon` — the foundation of the stack, 18.6M rows daily merge), Duco trade-activity recon (`Dealing_Duco_ActivityRecon`), Apex Clearing recon trio (`ApexRecon_Holdings` for daily holdings, `ApexRecon_TradeActivity` for daily trade activity, `ApexRecon_Hedging` for the hedge side), Apex SOD file registry, BNY-Mellon/Virtu EOD holdings recon (non-US equity), Saxo EOD recon (real stocks + employee accounts), Marex futures recon (client-level grain — distinct from base Marex recon), JPM / IG / Vision / Goldman / IB / CloseOnly per-LP recon variants, the three-way diff pattern (LP vs eToro vs Clients), settlement-risk interpretation, common diff columns.
Out of scope: hedge-order execution events (`dealing-investigation-and-execution.md`), LP contracts and pricing terms (`lp-contracts-and-cogs.md`), pricing data (`pricing-and-currency-history.md`), customer-side position state (`position-state-and-grain.md`), crypto-wallet redemption recon (`domain-payments`).
Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — `Dealing_Duco_EODRecon` is the eToro-internal reconciliation, not the LP-side recon.** The "Duco" name is the internal toolname; it compares the hedge servers' EOD holdings against the aggregated client NOP, expressed in units AND USD. It is the FOUNDATION for the 11+ per-LP recon tables (Apex, GS, IB, IG, JPM, SAXO, VISION, BNY-Virtu, CloseOnly) — those join Duco against the LP-confirmed file. When someone asks "did we break today?", check Duco first; it tells you whether the eToro-internal picture is consistent. Then drill into the per-LP table to see if the LP confirms it.
2. **Tier 1 — The Marex futures recon (`Marex_Recon_EODHoldings_Futures`) has a different grain than every other recon.** Every other per-LP recon is at `Date × LiquidityAccountID × InstrumentID × Buy/Sell` grain — comparing the LP's custodian file against eToro's *hedge-book* aggregate (`eToro_Units`). The Marex futures table is at `Date × CID × Contract × IsBuy × OrderID` grain — comparing Marex's lots against the *client's individual* position (`ClientUnits` / `Clients_Lots`). **There is no `eToro_Units` column** on the futures recon, because in the futures model client positions pass through to Marex 1:1. Don't try to join the futures recon to Duco the same way you'd join the equity recons.
3. **Tier 2 — Apex SOD files are append-only and idempotent.** The `apex.SodFiles` master registry tracks every file ingested from Apex's Azure Blob Storage. When a file fails to ingest (`Status != 'Success'`), the recon pipelines downstream silently use the previous day's snapshot — recon results may look "clean" because there's no fresh data to compare. Always check SOD file status (`finance.bronze_sodreconciliation_apex_sodfiles.Status`) before trusting an Apex recon result for a given date.
4. **Tier 2 — Diff columns answer different questions.** Reading the Saxo recon as an example:
   - `SAXO_Units − eToro_Units` → does the LP custodian match what eToro thinks it's hedging?
   - `SAXO_Units − Clients_Units` → does the LP custodian match what clients are net-long/short?
   - `Reality − Supposed` → is reality (LP) matching the expected hedge?
   - `Reality − Client` → is reality (LP) matching client demand?
   Mismatches between (`eToro_Units` − `Clients_Units`) are **hedge gaps** (we executed too much / too little); mismatches between (`SAXO_Units` − `eToro_Units`) are **settlement breaks** (the LP didn't confirm what we sent). They mean different operational problems.
5. **Tier 3 — `gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon` lives in BOTH `main.bi_db` AND `main.dealing`.** The `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon` listing is the BI-team-published copy; `main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon` is the view alias at the same grain. Use the `main.bi_db.*` FQN per the `required_tables` and naming-convention skill — they're equivalent for analytical queries.

## Tables — the reconciliation stack

### Foundation (eToro-internal)

| Table | Grain | What it answers |
|---|---|---|
| `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon` | `Date × LiquidityAccountID × InstrumentID × Buy/Sell` | **Daily EOD holdings recon** between hedge-server holdings and client NOP. Units AND USD. Foundation for all per-LP recons. ~18.6M rows (2023-01-02 → 2026-05-06), merge generic pipeline daily (weekdays only). |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_activityrecon` | `Date × LiquidityAccountID × InstrumentID × Buy/Sell` | **Daily trade-activity recon** between hedge-server executions and client trade activity (positions opened/closed). |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_v_dealing_duco_eodrecon` | view alias of above | Same data, view layer. |

### Per-LP — Apex Clearing (US equity)

| Table | Grain | What it answers |
|---|---|---|
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings` | `Date × InstrumentID × HedgeServer` (Apex only) | EOD shares-held recon: `Etoro_Units` vs `Apex_Units`. Mismatches → settlement risk. Apex is the LP for US real-stock execution. |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity` | `Date × LiquidityAccountID × InstrumentID × IsBuy` | Daily trade-execution recon: eToro units & rate vs Apex's reported trade activity. |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_hedging` *(not yet in UC harvest but referenced by `SP_Apex_Recon`)* | hedge side | The hedge-side companion to holdings & trade activity. |
| `main.finance.bronze_sodreconciliation_apex_sodfiles` | `FileName` | SOD-file ingestion registry — check Status before trusting downstream recons. |

### Per-LP — BNY-Mellon / Virtu (non-US equity)

| Table | Grain | What it answers |
|---|---|---|
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding` | `Date × InstrumentID` (BNY account scope implicit via LP mapping) | EOD holdings recon: BNY custodian position vs `eToro_Units` (hedge) vs `Clients_Units` (NOP). Diff columns expose discrepancies between LP / eToro / clients. |

### Per-LP — Saxo Bank (real stocks + employee accounts)

| Table | Grain | What it answers |
|---|---|---|
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings` | `Date × InstrumentID × HedgeServer × AccountNumber` | Three-way recon: `SAXO_Units` vs `eToro_Units` vs `Clients_Units`. AccountNumbers like `20xxxxx` are Saxo's account format. Real stocks + employee accounts. |

### Per-LP — Marex (futures)

| Table | Grain | What it answers |
|---|---|---|
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures` | `Date × CID × Contract × IsBuy × OrderID` — **CLIENT-LEVEL** | Futures EOD recon: Marex's lots vs the **individual client position** (`Clients_Lots` / `ClientUnits`). No `eToro_Units` — futures model is 1:1 pass-through. WA Marex price included. Added May 2025. |

### Other LPs

The Duco-foundation comment cites 11+ downstream LP recons; the named ones in production are:

- **Goldman Sachs (GS)** — CFD / equity hedging
- **Interactive Brokers (IB)** — US equity backup / specific products
- **IG** — CFD hedging
- **JPM** — equity / FX hedging
- **Vision** — institutional flow
- **CloseOnly** — flag for positions whose LP closed the relationship (recon to verify wind-down)

Each follows the same three-way pattern (LP vs eToro vs Clients) or a variant. Discover the table set per-LP via the discovery query below.

---

## Query Patterns

### Pattern 1 — Duco EOD breaks (the daily "are we clean?" question)
```sql
SELECT Date,
       COUNT(*) AS instruments_reconciled,
       COUNT(CASE WHEN ABS(eToro_Units - Clients_Units) > 0 THEN 1 END) AS instruments_with_hedge_gap,
       SUM(ABS(eToro_USD - Clients_USD)) AS total_usd_gap
FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon
WHERE Date BETWEEN '2026-05-01' AND '2026-05-09'
GROUP BY Date
ORDER BY Date;
```
**Use when:** "are we hedged correctly this week?", "Duco breaks summary"

### Pattern 2 — Apex recon discrepancies (per-instrument)
```sql
SELECT Date, InstrumentID, HedgeServer,
       Etoro_Units, Apex_Units,
       (Etoro_Units - Apex_Units) AS diff_units
FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings
WHERE Date = '2026-05-09'
  AND Etoro_Units != Apex_Units
ORDER BY ABS(Etoro_Units - Apex_Units) DESC;
```
**Use when:** "Apex breaks today", "which instruments have the biggest hedge mismatch?"

### Pattern 3 — Saxo three-way diff
```sql
SELECT Date, InstrumentID, HedgeServer, AccountNumber,
       SAXO_Units, eToro_Units, Clients_Units,
       `SAXO-eToro_Units` AS lp_vs_etoro,
       `SAXO-Clients_Units` AS lp_vs_clients,
       `Reality-Supposed` AS reality_vs_supposed,
       `Reality-Client` AS reality_vs_client
FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings
WHERE Date = '2026-05-09'
  AND (ABS(`SAXO-eToro_Units`) > 0 OR ABS(`SAXO-Clients_Units`) > 0);
```
**Use when:** "Saxo break", "real stocks recon for May 9". The four diff columns answer four different operational questions — see Critical Warning #4.

### Pattern 4 — BNY-Virtu non-US equity recon
```sql
SELECT Date, InstrumentID,
       BNY_Units, eToro_Units, Clients_Units,
       (BNY_Units - eToro_Units) AS lp_minus_etoro,
       (BNY_Units - Clients_Units) AS lp_minus_clients
FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding
WHERE Date BETWEEN '2026-05-01' AND '2026-05-09'
  AND (BNY_Units != eToro_Units OR BNY_Units != Clients_Units);
```
**Use when:** "BNY recon", "non-US equity break"

### Pattern 5 — Marex futures (client-level, no eToro_Units!)
```sql
SELECT Date, CID, Contract, IsBuy, OrderID,
       Marex_Lots, Clients_Lots,
       (Marex_Lots - Clients_Lots) AS diff_lots,
       WA_Marex_Price
FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures
WHERE Date = '2026-05-09'
  AND Marex_Lots != Clients_Lots;
```
**Use when:** "Marex futures break", "client futures recon"

### Pattern 6 — Apex SOD file health (always check before trusting Apex recon)
```sql
SELECT Date, FileName, Status, ErrorMessage
FROM main.finance.bronze_sodreconciliation_apex_sodfiles
WHERE Date >= CURRENT_DATE - 7
ORDER BY Date DESC, FileName;
```
**Use when:** "did Apex files load today?", "why is Apex recon showing zero breaks?" (always rule out a load failure first)

### Pattern 7 — Discovery query: every recon table for an LP
```sql
SELECT table_schema, table_name, LEFT(comment, 200) AS table_comment
FROM main.information_schema.tables
WHERE LOWER(table_name) LIKE '%recon%'
  AND LOWER(table_name) LIKE '%saxo%'   -- change for other LPs
ORDER BY table_name;
```
**Use when:** "what tables do we have for LP X?", validating coverage before authoring an aggregate.

---

## Cross-references

- Hedge-order execution detail (single-position) → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)
- LP contracts, fees TO providers, COGS → [`lp-contracts-and-cogs.md`](lp-contracts-and-cogs.md)
- Pricing inputs to recon → [`pricing-and-currency-history.md`](pricing-and-currency-history.md)
- Customer-side position state → [`position-state-and-grain.md`](position-state-and-grain.md)
- Crypto redemption recon (wallet) → [`../domain-payments/SKILL.md`](../domain-payments/SKILL.md)

## Provenance

Authored from Unity Catalog table-level comments harvested 2026-05-11 on `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_duco_eodrecon` (foundation), `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_*` family, `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_saxorecon_eodholdings`, `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_bny_virtu_reconeodholding`, `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_marex_recon_eodholdings_futures`. Each table's `comment` field traces back to a Tier 1 wiki under `knowledge/synapse/Wiki/Dealing/Tables/` or `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/`. Pending: deeper detail on GS, IB, IG, JPM, Vision, CloseOnly recon variants (table-level comments visible in UC; per-LP query patterns to be filled when dealing-analyst skills land).
