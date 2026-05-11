---
id: revenue-spaceship
name: revenue-and-fees-revenue-spaceship
description: |
  Thin routing skill for Spaceship-revenue questions. Spaceship is eToro's
  Australian acquired investment platform — Super (superannuation), Voyager
  (ETF managed funds), Nova (stock trading, clears on Alpaca), Money (cash
  wallet) — with 53 raw tables in main.spaceship, three prep views in
  etoro_kpi (v_spaceship_aum, v_spaceship_mimo, v_spaceship_fees), and a
  weekly KPI dashboard.

  AUTHORITATIVE SOURCE: the DataPlatform DE workspace skill at
  /Workspace/.assistant/skills/spaceship (6 sub-files: SKILL.md, source-tables.md,
  metric-definitions.md, views-architecture.md, dashboard-queries.md,
  data-patterns.md). That skill carries all the Spaceship-specific quirks:
  per-product warnings (Super signed aud_amount, Money classification rules),
  ETL pipeline detail, weekend fill-forward mechanics, AUD currency conversion,
  Sydney-timezone conversion, the FTD definitions, internal-transfer
  semantics, weekly dashboard SQL.

  Also see knowledge/uc_domains/spaceship/_domain_card.md for the local
  domain-card view.
triggers: [Spaceship, spaceship, AU investment, Australian investment,
           Australia, Super, superannuation, Voyager, Nova, Money,
           v_spaceship_aum, v_spaceship_mimo, v_spaceship_fees,
           bronze_spaceship_metabase, FTD, F30DD, FUM, Funded Accounts,
           Net Deposits, Voyager mgmt fee, Nova platform fee, Nova FX fee,
           AUD, Sydney, weekend fill-forward, signed aud_amount,
           Australian dollar, alpaca, alpaca_account_id]
load_after: [_router.md, revenue-and-fees/SKILL.md]
intersects_with:
  - customer-and-identity/SKILL.md   # GCID bridge — Spaceship user_id → eToro GCID
  - payments/SKILL.md                # Spaceship MIMO also lands in BI_DB_DDR_Fact_MIMO_AllPlatforms
primary_objects:
  - main.etoro_kpi.v_spaceship_fees
  - main.etoro_kpi.v_spaceship_aum
  - main.etoro_kpi.v_spaceship_mimo
  - main.spaceship.bronze_spaceship_metabase_user_beta              # canonical user table
  - main.spaceship.bronze_spaceship_metabase_super_transactions     # Super transactions
  - main.spaceship.bronze_spaceship_analytics_fct_money_transactions # Money cash-wallet transactions
  - main.bi_db.bronze_sub_accounts_accounts                          # GCID bridge (providerName='Spaceship')
authoritative_external_skills:
  - "/Workspace/.assistant/skills/spaceship"   # DataPlatform DE skill — 6 sub-files, fully authoritative
out_of_scope:
  - eToro-native trading revenue (FullCommission, Rollover, Ticket etc.) → trading-revenue-and-fees.md
  - eToro-native MIMO fees → fees-deposit-withdraw-fx.md
  - Cross-platform customer identity → customer-and-identity/SKILL.md

version: 1
owner: "dataplatform"

required_tables:
  - main.etoro_kpi.v_spaceship_fees
  - main.etoro_kpi.v_spaceship_aum
  - main.etoro_kpi.v_spaceship_mimo
  - main.spaceship.bronze_spaceship_metabase_user_beta
  - main.spaceship.bronze_spaceship_metabase_super_transactions
  - main.spaceship.bronze_spaceship_analytics_fct_money_transactions
  - main.bi_db.bronze_sub_accounts_accounts
last_validated_at: "2026-05-10"

---

# H.6 — Spaceship revenue (thin router)


## When to Use
Load when the question is about Spaceship platform revenue or fee income from Australian products (Super, Voyager, Nova, Money).

## Scope
In scope: Spaceship platform revenue (Super, Voyager, Nova, Money products), management fees, FUM-based revenue
Out of scope: Spaceship KPIs/FUM/registrations (operational, not revenue) → spaceship skill; TP trading revenue → trading-revenue-and-fees.md
Last verified: 2026-05-10

This sub-skill is **deliberately thin**. Spaceship has its own dedicated DataPlatform DE workspace skill that's been refined over weeks of work with multiple correction cycles. Do not duplicate or compete with it — route to it.

## The bottom line

For ANY substantive Spaceship question — fees, AUM, FTDs, F30DD, FUM, Funded Accounts, Net Deposits, Registrations, weekly dashboard, ETL, source tables, metric definitions, AUD conversion, weekend fill-forward, timezone handling — **load `/Workspace/.assistant/skills/spaceship`**. It owns everything Spaceship-specific.

This file exists to:

1. Tell the Revenue-and-Fees hub that Spaceship is the AU acquisition (so the hub doesn't have to know the detail).
2. Route the user to the authoritative DE skill.
3. Cross-link to the eToro-side identity bridge (GCID).

## Quick facts (don't write SQL from these alone — go to the DE skill)

- **Four product lines**: Super (superannuation), Voyager (ETF managed funds), Nova (stock trading; clears on Alpaca), Money (cash wallet).
- **53 raw tables** in `main.spaceship` (full-overwrite daily from BigQuery, ~07:30 UTC).
- **3 prep views** in `main.etoro_kpi`: `v_spaceship_aum`, `v_spaceship_mimo`, `v_spaceship_fees`.
- **Currency**: Source is AUD throughout. Convert to USD via `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` with `InstrumentID = 7`.
- **FTD definition (per Matt's PDF glossary)**: First investment into Super / Voyager / Nova only. **Money is excluded.**
- **Identity bridge**: `main.bi_db.bronze_sub_accounts_accounts` with `providerName = 'Spaceship'` maps Spaceship `accountId` to eToro `GCID`.
- **DOES NOT flow into DDR `BI_DB_DDR_Fact_Revenue_Generating_Actions`** — Spaceship fees stay inside the Spaceship-side panel. The DDR fact is eToro-native only.

## Critical Warnings (the absolute must-knows — full set is in the DE skill)

1. **Super `aud_amount` is SIGNED.** Do NOT use `ABS()` for outflows — inflates withdrawals by ~39%. Use negation (`-CAST(aud_amount AS DECIMAL)`) for withdrawals.
2. **Money classification**: use `transaction_type` (NOT `transaction_direction`). Filter `status NOT IN ('CANCELLED', 'FAILED', 'REJECTED')`.
3. **FTD counting**: do NOT filter `is_internal_transfer` when counting FTDs from `v_spaceship_mimo` — Voyager and Nova FTDs are predominantly internal transfers (Money → Voyager, Money → Nova). Use `is_ftd = TRUE` alone with `COUNT(DISTINCT user_id)`.
4. **Weekend fill-forward**: Super and Voyager balance tables are weekday-only. Sat / Sun balances require fill-forward from Friday. Affects AUM snapshots AND Voyager management-fee pro-rating.
5. **Timezone**: Nova + Money timestamps are UTC. `FROM_UTC_TIMESTAMP(..., 'Australia/Sydney')` before casting to date.

## When you should NOT use this file

If the question is anything more than "Spaceship exists and lives in `main.spaceship` and rolls up via `v_spaceship_*`", load the DE workspace skill directly. Do not try to answer Spaceship-specific questions from this file — go to `/Workspace/.assistant/skills/spaceship`.

## Cluster provenance

- `v_spaceship_*` and the `bronze_spaceship_metabase_*` family — Cluster 13 (DDR/MIMO).
- The Spaceship-eToro identity bridge `bronze_sub_accounts_accounts` lives in `bi_db` and feeds the Customer & Identity super-domain too.
