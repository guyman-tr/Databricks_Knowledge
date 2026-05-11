---
id: crypto-trading-ops-nixar
name: "Crypto Trading Ops — Nixar & Fireblocks (Placeholder)"
description: "Crypto-specific trading operations — the Nixar hedge-analytics pipeline (Beta target / Delta diffusion analysis), Fireblocks settlement and custody, the crypto hedge book, on-chain confirmation flow, and crypto-redemption reconciliation. PLACEHOLDER content — final methodology (beta target derivation, delta-diffusion modelling, Nixar pipeline architecture) lands when the dealing-analyst skill set is delivered. Until then, this skill maps the known Nixar tables, Fireblocks-adjacent views, and crypto-redemption recon to their analytical questions and routes deeper questions to the BI-Dealing/Nixar production code."
triggers:
  - crypto trading ops
  - crypto hedge
  - Nixar
  - Nixar pipeline
  - beta target
  - daily beta
  - delta diffusion
  - diffusion analysis
  - Fireblocks
  - crypto custody
  - on-chain settlement
  - crypto redemption
  - crypto redeem
  - hedge dash
  - newhedgedash
required_tables:
  - main.bi_dealing.bi_output_dealing_nixar_beta_dailybetatarget_v
  - main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod_v
  - main.bi_dealing.bi_output_dealing_nixar_delta_diffusionanalysis_v
  - main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-11"
---

# Crypto Trading Ops — Nixar & Fireblocks (Placeholder)

Crypto positions on eToro settle differently from CFD positions: real crypto holdings (where `IsSettled = 1` and `InstrumentTypeID = 10`) require **on-chain settlement** via custody at Fireblocks. The hedge book for crypto runs through a dedicated analytics pipeline called **Nixar**, which publishes Beta-target and Delta-diffusion analytics views consumed by the dealing desk. The crypto-redemption recon — the wallet-side of the customer pulling crypto OUT of eToro custody — lives in the wallet schema as a view that filters to only fully-processed redemptions.

This sub-skill is currently a **placeholder**. The dealing-analyst skill set will deliver the Nixar methodology (beta-target derivation, delta-diffusion model interpretation, hedge-book Greeks). Until then, this skill maps the known Nixar views to their analytical questions and routes deeper questions into the BI-Dealing production code at `/Workspace/Repos/dealing/BI-Dealing/databricks/Nixar/`.

## When to Use

Load when the question is about:

- "Nixar beta target", "daily beta production"
- "Delta diffusion analysis"
- "Crypto hedge book", "Fireblocks settlement"
- "Crypto redemption recon", "completed crypto withdrawals matched to on-chain"
- "Newhedgedash" — the operational hedge-dashboard snapshot
- "On-chain confirmation flow for a redemption"

Do **not** load for:

- Crypto trading by customers (volume, AUM, PnL) → [`trading-volumes.md`](trading-volumes.md), [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md), [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md) with `InstrumentTypeID = 10`
- Crypto-redemption FLOW (the customer money-out movement, fees, FundingTypeID=27) → `domain-payments`
- Crypto-redemption REVENUE / fees → `domain-revenue-and-fees`
- Generic position state → [`position-state-and-grain.md`](position-state-and-grain.md)
- Best-execution on crypto → [`best-execution.md`](best-execution.md)

## Scope

In scope: the Nixar analytics view family in `main.bi_dealing` (`bi_output_dealing_nixar_beta_dailybetatarget_v`, `bi_output_dealing_nixar_beta_dailybetaprod_v`, `bi_output_dealing_nixar_delta_diffusionanalysis_v` and their `bi_dealing_stg` counterparts), the `newhedgedash_email_csv` operational hedge-dashboard snapshot view, the wallet-side crypto-redemption recon view (`EXW_V_RedeemReconciliation` — filters to `EntryAppears = 'BothSidesEntry'` AND `[etoro - RedeemStatus] = 'TransactionDone'`), references to the BI-Dealing production-code path under `/Workspace/Repos/dealing/BI-Dealing/databricks/Nixar/`.
Out of scope: deep Nixar methodology (Beta-target derivation logic, Delta-diffusion model interpretation, hedge-book Greeks) — pending the dealing-analyst skill set, customer-side crypto trading metrics (`trading-volumes.md`, etc.), crypto MIMO flow (`domain-payments`), revenue (`domain-revenue-and-fees`).
Last verified: 2026-05-11

## Critical Warnings

1. **Tier 1 — `EXW_V_RedeemReconciliation` is FILTERED — it only contains fully-processed crypto redemptions.** The view applies two filters: `EntryAppears = 'BothSidesEntry'` (both eToro billing AND blockchain wallet have matching records) AND `[etoro - RedeemStatus] = 'TransactionDone'` (eToro platform marked the redemption fully complete, status 8). Rows where only one side has data (request submitted but not yet blockchain-confirmed) AND in-progress redemptions (`TransactionInProcess`) are excluded. If you need to count failed or pending redemptions, query the base table `main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_redeemreconciliation` (or equivalent) — the view will give you a wrong total.
2. **Tier 1 — The Nixar Beta-target views (`*_v`) return only the MOST RECENT target / production beta.** Comment text: *"A View To Get Only The Most Recent Beta Target"*. To get a historical time series of beta targets, query the underlying fact table (not the `_v` view). Treating the view as a time series will give a single row.
3. **Tier 2 — Crypto positions are NOT all "real crypto".** `InstrumentTypeID = 10` includes spot crypto (`IsSettled = 1` for real custody), crypto CFDs (`IsSettled = 0`), AND crypto micro futures (`IsFuture = 1`). The Nixar pipeline cares mostly about the real-custody flow. Apply `InstrumentTypeID = 10 AND IsSettled = 1 AND IsFuture = 0` to scope to real-crypto-only.
4. **Tier 3 — Nixar publishes both `_v` (Get-Latest) views AND the `bi_output_*` fact-style tables.** Joins between Nixar views and other domain skills should use the timestamp on the underlying fact, not the view (the view doesn't expose a date filter cleanly). When in doubt, query the base table directly.

## Tables (placeholder coverage)

### Nixar analytics — `main.bi_dealing` + `main.bi_dealing_stg`

| View | Comment | Use For |
|---|---|---|
| `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetatarget_v` | "A View To Get Only The Most Recent Beta Target" | Current daily beta target |
| `main.bi_dealing.bi_output_dealing_nixar_beta_dailybetaprod_v` | "A View To Get Only The Most Recent Beta" | Current daily beta in production |
| `main.bi_dealing.bi_output_dealing_nixar_delta_diffusionanalysis_v` | "A View To Get Only The Most Recent Delta Targets" | Current delta-diffusion analysis output |
| `main.bi_dealing.newhedgedash_email_csv` | "View to fetch the latest Date snapshot of NHD" | Latest Newhedgedash snapshot (operational hedge dashboard) |
| `main.bi_dealing_stg.*` (mirrored staging variants) | (staging) | Staging variants for the same views — use the `bi_dealing` (prod) versions for analyst queries. |

### Crypto-redemption recon — `main.wallet`

| Table | Use For |
|---|---|
| `main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation` | **Completed only** — fully-processed crypto redemptions matched both sides. Use for "how many crypto redemptions completed last month?". |
| (base table — verify FQN) | All states including pending / failed. Use for "what's stuck in the queue?". |

### Production code reference

| Path | Use For |
|---|---|
| `/Workspace/Repos/dealing/BI-Dealing/databricks/Nixar/` | The dealing team's production Nixar code. Source of truth for pipeline behaviour, scheduling, dependency map. **Read-only reference** — not a skill, not analyst-facing. |
| `/Workspace/Repos/dealing/BI-Dealing/databricks_sql/data.json` | Dealing team's SQL definitions (likely Genie / dashboard SQL). |
| `/Workspace/Repos/dealing/BI-Dealing/Production - Daily Beta` | Production notebook for daily beta computation (Python). |

---

## Query Patterns (placeholder)

### Pattern 1 — Latest Nixar beta target
```sql
SELECT *
FROM main.bi_dealing.bi_output_dealing_nixar_beta_dailybetatarget_v;
```
**Use when:** "what's the current beta target?". The view returns only the most recent row.

### Pattern 2 — Latest delta-diffusion output
```sql
SELECT *
FROM main.bi_dealing.bi_output_dealing_nixar_delta_diffusionanalysis_v;
```
**Use when:** "current delta-diffusion analysis"

### Pattern 3 — Completed crypto redemptions in a date range
```sql
SELECT COUNT(*) AS completed_redemptions,
       SUM(AmountUSD) AS total_usd,
       SUM(AmountCrypto) AS total_crypto
FROM main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation
WHERE RedeemDate BETWEEN '2026-01-01' AND '2026-03-31';
```
**Use when:** "how much crypto did customers withdraw on-chain?". **Completed only** — does NOT include pending or failed.

### Pattern 4 — Latest Newhedgedash snapshot
```sql
SELECT *
FROM main.bi_dealing.newhedgedash_email_csv;
```
**Use when:** "current Newhedgedash status", "what does the operations dashboard look like right now?"

---

## When the dealing-analyst skill lands

The dealing-analyst skill set is expected to deliver:

- The exact Beta-target derivation methodology (which inputs, which lookback, which model)
- The Delta-diffusion model: what it predicts, what it doesn't, when to trust it
- The Nixar pipeline architecture (upstream feeds, scheduling, recovery)
- Hedge-book Greeks (delta, gamma, vega) at the crypto level
- Fireblocks-specific custody-flow mapping (deposits, redemptions, internal moves, fee paths)
- Pending / failed crypto redemption forensics

When that skill lands, this placeholder will be expanded into authoritative content; the production code references will be cross-referenced with concrete notebooks; Nixar's role in best-execution will be linked from [`best-execution.md`](best-execution.md).

## Cross-references

- Customer-side crypto trading (volume, AUM, PnL) → [`trading-volumes.md`](trading-volumes.md), [`portfolio-value-aum-pnl.md`](portfolio-value-aum-pnl.md), [`instruments-and-asset-classes.md`](instruments-and-asset-classes.md) (`InstrumentTypeID = 10`)
- Crypto MIMO flow (customer money-out via on-chain redemption) → [`../domain-payments/SKILL.md`](../domain-payments/SKILL.md)
- Crypto revenue / fees (`CryptoToFiatFee`, `TransferCoinFee`) → [`../domain-revenue-and-fees/SKILL.md`](../domain-revenue-and-fees/SKILL.md)
- Hedge-execution event log (covers crypto hedge orders too) → [`dealing-investigation-and-execution.md`](dealing-investigation-and-execution.md)
- Best-execution on crypto → [`best-execution.md`](best-execution.md)
- LP contracts (which providers hedge crypto) → [`lp-contracts-and-cogs.md`](lp-contracts-and-cogs.md)

## Provenance

Placeholder skill authored 2026-05-11 from a Unity Catalog scan of `main.bi_dealing.*` Nixar views, `main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation`, and a folder scan of `/Workspace/Repos/dealing/BI-Dealing/databricks/Nixar/`. Deeper methodology — beta-target derivation, delta-diffusion model, Fireblocks custody flow, pending-redemption forensics — pending the dealing-analyst skill set commissioned by the data team.
