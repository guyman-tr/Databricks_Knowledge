---
name: domain-revenue-and-fees
description: |
  REDIRECT — MoneyFarm now has its own dedicated domain skill at
  knowledge/skills/domain-moneyfarm/. This sub-skill remains as a thin pointer
  for backward compatibility with any router/index that still references the
  old path. All MoneyFarm content (AUM, MIMO, FTD, fee schedule, source
  tables, prep views, Ben Thompson's UK/ISA Tableau workbooks, the UK BA Genie
  space, identity bridge, AccountTypeID=4 dictionary, providerName='Moneyfarm'
  filter conventions, and the v_moneyfarm_fees placeholder caveat) lives in
  domain-moneyfarm/SKILL.md and its 5 sub-files. This redirect must always
  resolve to domain-moneyfarm and never carry independent content.
triggers:
  - moneyfarm
  - MoneyFarm
  - Moneyfarm
  - money farm
  - uk isa
  - isa
  - v_moneyfarm_aum
  - v_moneyfarm_mimo
  - v_moneyfarm_fees
  - bi_output_moneyfarm_customers
  - bi_output_moneyfarm_fact_portfolio_snapshot
  - bi_output_moneyfarm_fact_transactions
  - silver_moneyfarm_etoro_mf_aum
  - bronze_moneyfarm_users
  - moneyfarm aum
  - moneyfarm mimo
  - moneyfarm fees
  - moneyfarm cohort
  - ben thompson
  - benth
load_after: [_router.md, domain-revenue-and-fees/SKILL.md]
intersects_with:
  - domain-moneyfarm/SKILL.md
out_of_scope:
  - eToro-native trading revenue → trading-revenue-and-fees.md
  - eToro-native MIMO fees → fees-deposit-withdraw-fx.md
  - Cross-platform customer identity → domain-customer-and-identity/SKILL.md

version: 2
owner: "dataplatform"

required_tables:
  - main.etoro_kpi_prep.v_moneyfarm_aum
  - main.etoro_kpi_prep.v_moneyfarm_mimo
  - main.etoro_kpi_prep.v_moneyfarm_fees
  - main.bi_output.bi_output_moneyfarm_customers
  - main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot
  - main.bi_output.bi_output_moneyfarm_fact_transactions
  - main.money_farm.silver_moneyfarm_etoro_mf_aum
  - main.general.bronze_moneyfarm_users
  - main.bi_db.bronze_sub_accounts_accounts
last_validated_at: "2026-05-31"
---

# REDIRECT — MoneyFarm content has moved

> **Where to go**: `knowledge/skills/domain-moneyfarm/SKILL.md`

## When to Use

Load `domain-moneyfarm/SKILL.md` (NOT this file) for any MoneyFarm question. This file remains only as a thin redirect for backward-compatibility with old router / index references.

## Scope

**In scope:** redirect pointer only.

**Out of scope:** all MoneyFarm content — fee schedules, AUM, MIMO, FTD, cohort segmentation, identity bridge, Tableau workbooks, Genie space joins, source tables, prep view DDLs, SQL patterns. Every one of these is now in `domain-moneyfarm/*.md`.

Last verified: 2026-05-31

## Critical Warnings

1. **Do NOT add new MoneyFarm content here** — this file is a redirect. Any update to MoneyFarm knowledge belongs in `domain-moneyfarm/SKILL.md` or one of its 5 sub-files (`source-tables.md`, `views-architecture.md`, `metric-definitions.md`, `dashboard-queries.md`, `data-patterns.md`).
2. **`v_moneyfarm_fees` is a confirmed placeholder** — `WHERE 1=0`, all NULL CASTs. Querying always returns 0 rows. The customer-facing fee schedule lives in Confluence as informational knowledge only — see `domain-moneyfarm/metric-definitions.md` §7.
3. **`providerName = 'Moneyfarm'` is the canonical case** (capital M, single word). Don't use `'MoneyFarm'` (camel-case) — it matches zero rows in `bi_db.bronze_sub_accounts_accounts` and `compliance.bronze_event_hub_*`.

## What this redirect resolves to

MoneyFarm — eToro's UK ISA / robo-advisor acquisition (2024) — was promoted from a `domain-revenue-and-fees` sub-skill into a standalone domain skill on **2026-05-31**.

The dedicated skill `domain-moneyfarm` covers:
- The full 23-table UC catalog across 10 schemas (`source-tables.md`).
- Full DDLs and CTE walkthroughs of the 3 prep views (`views-architecture.md`).
- KPI definitions for AUM, MIMO, FTD, Funded, Cohort — plus the documented Managed-ISA tiered fee schedule from Confluence as **knowledge without data** (`metric-definitions.md`).
- Ben Thompson's 5 `UK/ISA` Tableau workbooks + the UK BA Genie space [WIP] with 16 MoneyFarm join_specs (`dashboard-queries.md`).
- 12 reusable SQL patterns + 6 anti-patterns (`data-patterns.md`).

## What changed since v1 of this redirect

| Concern | Old (v1) | New (`domain-moneyfarm`) |
|---|---|---|
| `providerName` filter | `'MoneyFarm'` (camel-case, **incorrect**) | `'Moneyfarm'` (capital M, single word — **correct**) |
| `v_moneyfarm_fees` status | "may be a placeholder, verify before use" | **Confirmed placeholder** — `WHERE 1=0`, intentional schema reservation |
| Fee schedule | not documented | **Tiered Managed-ISA fee schedule from Confluence CS/11942330382** documented as informational knowledge (no UC data backing) |
| Tableau coverage | "zero workbook hits (clean negative)" | **5 active workbooks** owned by Ben Thompson under UK/ISA project 485 |
| Genie joins | "16 join_specs" mentioned vaguely | All 16 quoted verbatim with cardinality + instruction text |
| Identity bridge | basic GCID-via-sub-accounts mention | Full bridge table including `Identifier_Value ↔ externalUserId` alternative join |
| Dictionary mapping | `AccountTypeID = 4` only | `AccountTypeID=4 / FundingTypeID=44 / PaymentMethodTypeId=44 / FTDPlatformID=4 / DefaultCurrency=5` |
| Patterns | 3 sample queries | 12 patterns + 6 anti-patterns |

## Why a thin redirect (rather than deleting)

Several index files and the previous `_router.md` reference this path. Keeping a redirect (rather than deleting the file) preserves backward compatibility for any agent or pipeline that loads the old anchor. The redirect should **never accumulate independent content** — when a knowledge update lands, write it to `domain-moneyfarm/*.md` and not here.

## See also

- `domain-moneyfarm/SKILL.md` — the new hub.
- `domain-spaceship/SKILL.md` — the parallel BigQuery-sourced robo-advisor (similar pattern, different upstream).
- `domain-payments/mimo-panel-and-ddr.md` — for the cross-platform DDR aggregation that includes MoneyFarm `AccountTypeID=4` rows.
- `domain-customer-and-identity/SKILL.md` — for the identity-bridge model.
- `knowledge/uc_domains/moneyfarm/_domain_card.md` — the 6-phase discovery output that powers the new skill.
