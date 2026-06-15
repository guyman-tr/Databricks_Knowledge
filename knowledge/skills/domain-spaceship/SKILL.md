---
name: domain-spaceship
description: "Australian investment platform (Super, Voyager, Nova, Money) data, KPIs,
  and view architecture. Covers FTDs, F30DD, FUM, Funded Accounts, Net Deposits,
  Registrations, weekly dashboard datasets, ETL pipeline, and cross-platform
  eToro integration. 53 raw tables in main.spaceship plus 3 prep views.
  Renamed from `spaceship` to `domain-spaceship` on 2026-05-28 / DA-72 to align with
  the post-DD-1747 super-domain naming convention (`domain-*` for workspace skills
  that own a full product/concept hub with 5 sibling sub-skill files)."
triggers:
  - spaceship
  - super voyager nova money
  - spaceship FTD
  - spaceship FUM
  - spaceship funded accounts
  - spaceship net deposits
  - v_spaceship_aum
  - v_spaceship_mimo
  - v_spaceship_fees
  - australian investment
  - spaceship weekly dashboard
required_tables:
  - main.spaceship.bronze_spaceship_metabase_user_beta
  - main.spaceship.bronze_spaceship_metabase_super_transactions
  - main.spaceship.bronze_spaceship_analytics_fct_money_transactions
  - main.etoro_kpi_prep.v_spaceship_aum
  - main.etoro_kpi_prep.v_spaceship_mimo
  - main.etoro_kpi_prep.v_spaceship_fees
sub_skills:
  - spaceship-dashboard-queries.md
  - spaceship-data-patterns.md
  - spaceship-metric-definitions.md
  - spaceship-source-tables.md
  - spaceship-views-architecture.md
version: 3
owner: "dataplatform"
last_validated_at: "2026-05-28"
---

# Spaceship Skill

## When to Use
Load this skill when the user asks about:
- Spaceship data, tables, metrics, or KPI reporting
- Australian investment products (Super, Voyager, Nova, Money)
- Spaceship weekly dashboard, FTDs, F30DD, FUM, Funded Accounts, Net Deposits, Registrations
- Cross-platform analysis (Spaceship <-> eToro users)
- Spaceship view architecture (v_spaceship_aum, v_spaceship_mimo, v_spaceship_fees)
- Spaceship ETL pipeline (BigQuery to Delta full-overwrite daily)

## Scope
In scope: main.spaceship (53 raw tables), main.etoro_kpi_prep (v_spaceship_aum, v_spaceship_mimo, v_spaceship_fees), Spaceship KPIs (FTDs, F30DD, FUM, Funded Accounts, Net Deposits, Registrations), weekly dashboard datasets, ETL pipeline, eToro GCID bridge
Out of scope: eToro-native revenue (see revenue skill), eToro portfolio value/AUM (see portfolio-value skill), eToro deposit/withdrawal flows (see mimo skill), eToro customer populations (see `domain-customer-and-identity/customer-populations-and-lifecycle.md`)
Last verified: 2026-05-28

## Sub-File Index

| File | Load When | Contents |
|------|-----------|----------|
| `spaceship-source-tables.md` | Exploring raw data, "what tables have...", column lookups | 53-table catalog, key columns, data quirks (incl. Super signed aud_amount) |
| `spaceship-metric-definitions.md` | Computing KPIs, QA, "how is X calculated", validation | Matt's Excel definitions: FTDs, F30DD, Funded, FUM, Net Deposits, Registrations |
| `spaceship-views-architecture.md` | Building/fixing views, understanding prep layer, ETL | Prep views (AUM, MIMO, Fees), CTE architecture, ETL pipeline, dashboard migration |
| `spaceship-dashboard-queries.md` | Dashboard edits, replicating charts, column schemas | All 6 production SQL datasets + MIMO-based Net Deposits replacement |
| `spaceship-data-patterns.md` | Writing any Spaceship SQL query | Reusable CTEs: dedup, Money mapping, weekend fill-forward, currency, timezone, joins |

**Routing guidance:** Most questions need `spaceship-data-patterns.md` (common CTEs) + one domain file. Load `spaceship-data-patterns.md` first when writing queries.

## Product Structure

**Spaceship** is an Australian investment platform acquired by eToro:
- **Super** -- Superannuation (retirement accounts). Key: `member_id` to `user_id` via `user_beta`
- **Voyager** -- ETF managed funds. Key: `user_id`. 5 portfolios: EARTH, EXPLORER, GALAXY (NAV=0), ORIGIN, UNIVERSE (NAV>0)
- **Nova** -- Stock trading. Key: `user_id`. Timestamps in UTC (convert to Sydney)
- **Money** -- Cash wallet. Key: `account_id` to `user_id` via `contact` table

**Schema:** `main.spaceship` (53 raw tables) + `main.etoro_kpi_prep` (3 prep views)

## Critical Warnings

### Tier 1 — Silent wrong numbers
1. **Currency**: All source tables are AUD. Convert via `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` (InstrumentID=7).
2. **Deduplication**: `user_beta` has 1:MANY member_id to user_id. Must use canonical user_id pattern.
3. **FTD excludes Money**: Per PDF glossary, FTDs = first investment into Super/Voyager/Nova only.
4. **Super aud_amount is SIGNED**: Do NOT use ABS() -- it inflates outflows by ~39%. Use negation (`-CAST(aud_amount)`) for withdrawals.
5. **Money classification**: Use `transaction_type` (not `transaction_direction`) for deposit/withdrawal splits. Use `status NOT IN ('CANCELLED','FAILED','REJECTED')` filter.
6. **FTD counting: do NOT filter is_internal_transfer**: When counting FTDs from `v_spaceship_mimo`, use `is_ftd = TRUE` alone — do NOT add `is_internal_transfer = FALSE`. Voyager and Nova FTDs are predominantly internal transfers (Money→Voyager, Money→Nova). Users deposit cash into Money first, then invest into a qualifying product. The Money deposit itself is NOT an FTD (Money excluded per #3), so there is no double-counting risk. Filtering external-only loses ~56% of FTDs (all Voyager + Nova). Always use `COUNT(DISTINCT user_id)` since a user can have `is_ftd=TRUE` on multiple product rows for the same date. Verified 2026-04-15: MIMO view FTD counts match `user_beta` FTD dates exactly (0 daily gap YTD) when no internal_transfer filter is applied.
7. **Super Premium type**: `type='Premium'` (insurance premiums) exists in `super_transactions` — always negative, classified as withdrawal in `v_spaceship_mimo` (added 2026-04-20). The `type='Other'` category is NOT included — mixed signs, unclear classification. Super MIMO now filters: `type IN ('Contributions', 'Benefit Payment', 'Fees', 'Tax', 'Premium')`.

### Tier 2 — Aggregate inflation
8. **Weekend fill-forward**: Super & Voyager balance tables are weekday-only. Sat/Sun need fill-forward from Friday. Affects AUM snapshots AND Voyager mgmt fee pro-rating.
9. **Voyager mgmt fee weekends**: Management fees accrue daily incl. weekends, but balance table is weekday-only. Must fill-forward Friday balances for Sat/Sun pro-rating (~7-8K AUD/day otherwise dropped).
10. **Fill-forward window partition trap**: When fill-forward maps N fee dates to 1 balance date, `SUM() OVER (PARTITION BY balance_date)` sees N x expected rows, deflating per-day allocation. Always partition by the business/fee date, NOT the physical balance lookup date. Cost ~968 AUD/day on Voyager mgmt for NAV=0 portfolios (EARTH/EXPLORER/GALAXY).

### Tier 3 — Dependencies / edge cases
11. **Timezone**: Nova + Money timestamps are UTC. Must `FROM_UTC_TIMESTAMP(..., 'Australia/Sydney')`.
12. **Super SFT exclusion**: Exclude `paid_date = '2024-05-18'` from Super transactions.
13. **Super backdating**: T+2 settlement causes FTD dates to shift retroactively (~10-20% variance for recent weeks).
14. **Week-ending = Sunday**: `DATE_TRUNC('WEEK', date) + INTERVAL 6 DAYS`. Snapshots use `DAYOFWEEK(date) = 1`.
15. **Nova FX fee dates**: `order_filled_at` is UTC -- must convert to Sydney time before DATE cast or fees land 1 day early. Use `CAST(FROM_UTC_TIMESTAMP(order_filled_at, 'Australia/Sydney') AS DATE)`.

## eToro Integration

**Bridge table:** `main.bi_db.bronze_sub_accounts_accounts` (providerName='Spaceship')
- Links Spaceship `accountId` to eToro `GCID`
- Join pattern in `spaceship-data-patterns.md`

## Dashboard Reference

**Name:** Spaceship Weekly KPI Dashboard
**Dashboard ID:** `01f12d17075f19c7bcd920286696e32c`
**Tree Node ID:** `3302260643916982`
**6 datasets:** Funded Accounts, FUM, Registrations, FTDs & F30DD, Net Deposits, Voyager Net Deposits
**Full SQL:** See `spaceship-dashboard-queries.md`
**Migration:** Net Deposits dataset being migrated from raw tables to `v_spaceship_mimo` (2026-04-13).
Other 5 datasets stay on raw tables (balance snapshots, user profiles, windowed F30DD, portfolio splits).

## View Reference

| View | Purpose | Key Facts |
|------|---------|----------|
| `v_spaceship_aum` | Daily per-user balances | Super+Voyager+Nova (no Money yet). Weekend fill-forward. For "latest available" snapshots: use 7-day window + per-product carry-forward (Super lags T+2). |
| `v_spaceship_mimo` | Money In/Money Out flows | Aligned with dashboard (2026-04-13). Updated 2026-04-20: added `type='Premium'` to Super withdrawals. Authoritative `is_ftd` flag — reconciled with `user_beta` (0 gap verified 2026-04-15). Do NOT filter `is_internal_transfer` when counting FTDs (see warning #6). Super uses negation, Money uses type-based classification. Orphan FTD rows for T+2 backdating. |
| `v_spaceship_fees` | Fee analysis by product | Super/Voyager(acct+mgmt)/Nova(platform+FX). 3 fixes (2026-04-13): weekend fill-forward, window partition by fee date, Nova FX Sydney timezone. |

**Canonical view scripts:** `/Users/guyman@etoro.com/a_semantic_etoro_kpi_prep/`

## ETL Pipeline

All 53 Spaceship tables loaded via **full overwrite** from BigQuery, daily ~07:30 UTC.
- **Entry point:** [Spaceship- Main](#notebook-1353348094096079) -- launches up to 10 concurrent workers
- **Worker:** [Spaceship - process table](#notebook-1353348094099614) -- reads entire table, writes mode='overwrite' to Delta
- No incremental/CDC. Every run replaces entire table.
- See `spaceship-views-architecture.md` for full details.

## Source of Truth

**Matt's Excel file:** `/Workspace/Users/guyman@etoro.com/spaceship/sps reports from matt.xlsx`
**PDF reports:** Weekly "Spaceship Reporting Metrics" PDFs, parsed via `ai_parse_document`
**QA notebook:** `/Users/guyman@etoro.com/spaceship/parse_kpi_report`

## Skill provenance

Renamed 2026-05-28 / DA-72 from workspace skill `spaceship` to `domain-spaceship` to align with the post-DD-1747 hub naming convention (super-domain skills carrying multiple sibling sub-skill files are prefixed `domain-`). Content unchanged from v1 except this provenance note, the v1→v2 version bump, the `last_validated_at` refresh, and the updated cross-reference for customer-populations (absorbed into `domain-customer-and-identity/customer-populations-and-lifecycle.md` in the same commit). The legacy `spaceship/` folder is `git rm`'d in the same commit; the 5 sibling sub-skill files (`spaceship-source-tables.md`, `spaceship-metric-definitions.md`, `spaceship-views-architecture.md`, `spaceship-dashboard-queries.md`, `spaceship-data-patterns.md`) ride along verbatim — they continue to be silently dropped by the MCP loader until Layer 2 sub-skill routing ships, but remain readable when this hub points to them.
