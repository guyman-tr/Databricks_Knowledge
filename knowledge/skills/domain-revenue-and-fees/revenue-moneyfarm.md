---
id: revenue-moneyfarm
name: revenue-and-fees-revenue-moneyfarm
description: |
  Revenue & AUM for MoneyFarm — eToro's UK digital wealth-management /
  robo-advisor acquisition (2024). MoneyFarm has its own production stack
  and ships data to UC only as a read-only feed, sourced from CosmosDB
  document export (NOT BigQuery like Spaceship). Owned here (no DE workspace
  skill exists). Anchored to knowledge/uc_domains/moneyfarm/_domain_card.md.

  Three KPI prep views live in main.etoro_kpi_prep (NOT etoro_kpi like
  Spaceship — naming inconsistency to be aware of): v_moneyfarm_aum (per-user
  daily AUM), v_moneyfarm_mimo (Money In / Money Out flows), v_moneyfarm_fees
  (the canonical fee view — 254-char DDL, likely placeholder, verify before
  use). Two bizops fact tables sit in bi_output:
  bi_output_moneyfarm_fact_portfolio_snapshot,
  bi_output_moneyfarm_fact_transactions. Source silver:
  money_farm.silver_moneyfarm_etoro_mf_aum. Raw bronze:
  general.bronze_moneyfarm_users (Cosmos export with _rid/_self/_etag
  metadata).

  GCID bridge same pattern as Spaceship — via bi_db.bronze_sub_accounts_accounts.
  MoneyFarm MIMO ALSO rolls up to BI_DB_DDR_Fact_MIMO_AllPlatforms (Payments).
triggers: [MoneyFarm, moneyfarm, UK robo-advisor, managed investing, ISA, SIPP,
           v_moneyfarm_aum, v_moneyfarm_mimo, v_moneyfarm_fees,
           bi_output_moneyfarm_fact_portfolio_snapshot,
           bi_output_moneyfarm_fact_transactions,
           silver_moneyfarm_etoro_mf_aum, bronze_moneyfarm_users,
           Cosmos, CosmosDB, moneyfarmUserId, externalUserId,
           moneyfarm AUM, moneyfarm fees, moneyfarm MIMO,
           AccountTypeID 4, UK BA Genie space, robo-advisor]
load_after: [_router.md, domain-revenue-and-fees/SKILL.md]
intersects_with:
  - domain-customer-and-identity/SKILL.md   # moneyfarmUserId / externalUserId bridge to GCID
  - domain-payments/SKILL.md                # MoneyFarm MIMO also lands in BI_DB_DDR_Fact_MIMO_AllPlatforms
primary_objects:
  - main.etoro_kpi_prep.v_moneyfarm_aum
  - main.etoro_kpi_prep.v_moneyfarm_mimo
  - main.etoro_kpi_prep.v_moneyfarm_fees   # known to be ~254-char DDL — verify content before relying
  - main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot
  - main.bi_output.bi_output_moneyfarm_fact_transactions
  - main.bi_output.bi_output_moneyfarm_customers
  - main.money_farm.silver_moneyfarm_etoro_mf_aum
  - main.general.bronze_moneyfarm_users
  - main.experience.bronze_fivetran_experience_money_farm_product_names
  - main.bi_db.bronze_sub_accounts_accounts   # GCID bridge (providerName='MoneyFarm')
authoritative_external_files:
  - knowledge/uc_domains/moneyfarm/_domain_card.md   # rich local domain card with 6 phases of discovery
out_of_scope:
  - eToro-native trading revenue → trading-revenue-and-fees.md
  - eToro-native MIMO fees → fees-deposit-withdraw-fx.md
  - Cross-platform customer identity → domain-customer-and-identity/SKILL.md
  - WealthFrance (French equivalent — not yet ingested)

version: 1
owner: "dataplatform"

required_tables:
  - main.etoro_kpi_prep.v_moneyfarm_aum
  - main.etoro_kpi_prep.v_moneyfarm_mimo
  - main.etoro_kpi_prep.v_moneyfarm_fees
  - main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot
  - main.bi_output.bi_output_moneyfarm_fact_transactions
  - main.bi_output.bi_output_moneyfarm_customers
  - main.money_farm.silver_moneyfarm_etoro_mf_aum
  - main.general.bronze_moneyfarm_users
  - main.experience.bronze_fivetran_experience_money_farm_product_names
  - main.bi_db.bronze_sub_accounts_accounts
last_validated_at: "2026-05-10"

---

# H.7 — MoneyFarm revenue (UK managed investing)


## When to Use
Load when the question is about MoneyFarm platform revenue or management fee income from MoneyFarm products.

## Scope
In scope: MoneyFarm platform revenue, management fees, AUM-based fee income, MoneyFarm product lines
Out of scope: MoneyFarm operational data (AUM levels, client counts) → moneyfarm-data skill; TP trading revenue → trading-revenue-and-fees.md
Last verified: 2026-05-10

MoneyFarm is the UK equivalent of Spaceship — managed investing — but with fundamentally different upstream contract (CosmosDB document store, NOT BigQuery). This sub-skill owns MoneyFarm fee and AUM questions, with the rich local `knowledge/uc_domains/moneyfarm/_domain_card.md` as the secondary reference.

## The product

MoneyFarm is a digital wealth management / robo-advisor platform headquartered in the UK that eToro acquired in 2024. MoneyFarm runs its own production stack and ships data to the eToro lake **only as a read-only feed**, sourced from CosmosDB document export (`Cosmos-MoneyFarm` server). This shapes how bronze tables look (key-value blobs vs the relational shapes that Spaceship has).

## Layer architecture in UC

| Layer | UC Schema | Table family | What it is |
|-------|-----------|--------------|------------|
| Bronze (raw Cosmos) | `general.*` | `bronze_moneyfarm_users` | Raw user docs from Cosmos export with `_rid`/`_self`/`_etag`/`_attachments` metadata. 24K rows. PII-bearing. |
| Bronze (Fivetran aux) | `experience.*` | `bronze_fivetran_experience_money_farm_product_names` | MoneyFarm portfolio-product name reference (9 rows) |
| Silver (aggregated) | `money_farm.*` | `silver_moneyfarm_etoro_mf_aum` | Per-user AUM aggregation. The only `money_farm.*` table — primary silver target. |
| eToro-side bizops | `bi_output.*` | `bi_output_moneyfarm_fact_portfolio_snapshot`, `bi_output_moneyfarm_fact_transactions`, `bi_output_moneyfarm_customers` | Three fact / dim tables curated by the BI team for MoneyFarm reporting |
| eToro-side KPI prep | `etoro_kpi_prep.*` | `v_moneyfarm_aum`, `v_moneyfarm_mimo`, `v_moneyfarm_fees` | Three rollup views feeding DDR |

**Naming inconsistency**: MoneyFarm's KPI views live in `etoro_kpi_prep` (NOT `etoro_kpi` like Spaceship). This is a quirk; both names are valid.

## Identity bridge

| MoneyFarm-side ID | UC location | Cross-ref back to eToro GCID |
|-------------------|-------------|------------------------------|
| `moneyfarmUserId` (sometimes `externalUserId`) | `general.bronze_moneyfarm_users` (raw Cosmos export); `bi_output.bi_output_moneyfarm_customers` (curated) | Via `main.bi_db.bronze_sub_accounts_accounts` with `providerName = 'MoneyFarm'` (same pattern as Spaceship) |

See `domain-customer-and-identity/SKILL.md` for the full identity-layer model and the Acquired-platform user IDs lookup table.

## What rolls into DDR — and what doesn't

| Stream | DDR target | Notes |
|--------|------------|-------|
| MoneyFarm AUM | `BI_DB_DDR_Fact_AUM` | Yes — AUM lands in the cross-platform AUM panel. |
| MoneyFarm MIMO (Money In / Out) | `BI_DB_DDR_Fact_MIMO_AllPlatforms` | Yes — MoneyFarm MIMO lands in the Payments-side cross-platform MIMO panel. |
| MoneyFarm FEES | _(NOT in `BI_DB_DDR_Fact_Revenue_Generating_Actions`)_ | MoneyFarm fees stay inside the MoneyFarm panel. The DDR revenue fact is eToro-native trading only. Use `v_moneyfarm_fees` directly. |

## Query patterns

### Pattern 1 — MoneyFarm AUM trend
```sql
SELECT DateID, SUM(AumUSD) AS aum_usd, COUNT(DISTINCT GCID) AS n_customers
FROM main.etoro_kpi_prep.v_moneyfarm_aum
WHERE DateID BETWEEN 20260101 AND 20260331
GROUP BY DateID
ORDER BY DateID;
```

### Pattern 2 — MoneyFarm MIMO last quarter
```sql
SELECT
    DateID,
    SUM(CASE WHEN flow_direction = 'IN'  THEN AmountUSD ELSE 0 END) AS money_in,
    SUM(CASE WHEN flow_direction = 'OUT' THEN AmountUSD ELSE 0 END) AS money_out
FROM main.etoro_kpi_prep.v_moneyfarm_mimo
WHERE DateID BETWEEN 20260101 AND 20260331
GROUP BY DateID
ORDER BY DateID;
```
(Column names approximate — confirm with view DDL.)

### Pattern 3 — Identity bridge — MoneyFarm user → eToro GCID
```sql
SELECT
    sa.GCID,
    sa.accountId AS moneyfarm_account_id,
    mu.<moneyfarm_user_id_column>,
    dc.RegulationName,
    dc.CountryName
FROM main.bi_db.bronze_sub_accounts_accounts sa
LEFT JOIN main.bi_output.bi_output_moneyfarm_customers mu
  ON mu.<account_id_or_user_id> = sa.accountId
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  ON dc.GCID = sa.GCID
WHERE sa.providerName = 'MoneyFarm';
```

## Critical Warnings

1. **`v_moneyfarm_fees` may be a placeholder.** The discovery card notes the DDL is unusually short (~254 chars). Inspect the view before relying on it for SQL — it may be a stub that returns no rows, or it may have been completed since the discovery scan. Confirm with `SHOW CREATE TABLE main.etoro_kpi_prep.v_moneyfarm_fees`.
2. **MoneyFarm fees do NOT flow into `BI_DB_DDR_Fact_Revenue_Generating_Actions`.** Use `v_moneyfarm_fees` directly.
3. **MoneyFarm AUM and MIMO DO roll up** into `BI_DB_DDR_Fact_AUM` and `BI_DB_DDR_Fact_MIMO_AllPlatforms` respectively. Cross-product KPIs (eToro + Spaceship + MoneyFarm) use those.
4. **`AccountTypeID = 4` = MoneyFarm** in the global payments configurations (per Confluence anchor `MoneyFarm global payments configurations`). Use this for MoneyFarm-specific filters in payment-fact tables.
5. **PII**: `general.bronze_moneyfarm_users` carries PII from the Cosmos export. Restricted-access catalog. For analyst work use the masked / curated `bi_output_moneyfarm_*` family.
6. **`general.bronze_moneyfarm_users` has CosmosDB document metadata** — `_rid`, `_self`, `_etag`, `_attachments`. These are NOT business columns; ignore them in analytics SQL.
7. **No DataPlatform DE workspace skill exists for MoneyFarm.** We own this sub-skill. The local `knowledge/uc_domains/moneyfarm/_domain_card.md` is the authoritative discovery card (P0–P5 phases complete, P6 deferred).

## Cluster provenance

- `silver_moneyfarm_etoro_mf_aum` — Cluster 13 (DDR/MIMO), weight 38 (highest-traffic MoneyFarm node).
- `bi_output_moneyfarm_fact_portfolio_snapshot` — Cluster 13, weight 24.
- `bi_output_moneyfarm_fact_transactions` — Cluster 13, weight 24.
- `v_moneyfarm_*` — `etoro_kpi_prep` schema, joined to DDR via GCID.

## Authoritative discovery

The local `knowledge/uc_domains/moneyfarm/_domain_card.md` carries the result of a 6-phase discovery process:

| Phase | Status | Output |
|-------|--------|--------|
| P0 Domain card | done | the `_domain_card.md` itself |
| P1 UC discovery | done | 9 UC objects, 82 columns, 29% with comments |
| P2 Confluence discovery | done | 3 Tier-1 + 1 Tier-2 anchor pages |
| P3 Tableau discovery | done | zero workbook hits (clean negative) |
| P4 Databricks-native discovery | done | 3 Genie spaces match — including UK BA WIP with 16 join_specs touching MoneyFarm objects |
| P5 Doc generation pilot | done | first pilot wiki for `bi_output_moneyfarm_fact_portfolio_snapshot` |
| P6 Cross-object enrichment + UC deploy | deferred | _deploy-index.md not yet built |

The **UK BA Genie space WIP** (52 join_specs across MoneyFarm + Spaceship + DDR objects) is the Tier-3 goldmine — analyst-authored joins that double as documentation. When in doubt about join keys or cardinalities, consult that Genie space.
