---
object: main.etoro_kpi.v_spaceship_aum
domain: spaceship
table_type: VIEW
format: null
column_count: 13
row_count: null
generated_at: "2026-05-04T12:35:00Z"
tier_breakdown:
  tier1_columns: 13
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
sources:
  confluence: ["BDP/12918358038", "BG/13131186194", "CS/13335789570"]
  tableau:    ["main__etoro_kpi"]
  databricks: []
  uc_comment: true
---

# v_spaceship_aum

## 1. What it is

Daily per-user Assets Under Management (FUM) across Spaceship — an Australian
investment platform acquired by eToro. Granularity: one row per `date × user_id`,
spanning four products (Super, Voyager, Nova, Money). The view normalises three
weekday-only and 7-day source balance tables into a single calendar-complete
panel and converts all AUD balances to USD via a mid-rate. The full operational
narrative — products, fill-forward rules, user-id deduplication, GCID cross-sell
linkage, AUD/USD InstrumentID — is encoded verbatim in the view-level UC
COMMENT (1131 chars) and is the authoritative source for column meaning.

## 2. Identity & Lineage

| Attribute | Value | Source |
|-----------|-------|--------|
| Full name | `main.etoro_kpi.v_spaceship_aum` | UC inventory |
| Type | VIEW (Spark logical view) | `system.information_schema.tables` |
| Format | n/a (logical view, no storage) | `SHOW CREATE TABLE` |
| Owner | analyst-authored, eToro DataPlatform | n/a |
| Row count | n/a (computed at query time) | n/a |
| Upstream | `main.spaceship.bronze_spaceship_metabase_super_user_balances` (Super), `main.spaceship.spaceship_metabase_voyager_user_balances` (Voyager), `main.spaceship.bronze_spaceship_metabase_nova_user_balances` (Nova), `main.spaceship.bronze_spaceship_metabase_user_beta` (member→user_id resolution), `main.spaceship.bronze_spaceship_metabase_contact` (account_id→user_id), `main.bi_db.bronze_sub_accounts_accounts` (GCID linkage), `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` (AUD/USD InstrumentID=7) | view DDL |
| Downstream | Tableau `main__etoro_kpi`; eToro KPI dashboards via Genie | Tableau index |

## 3. Columns

> **Description column policy**: this view's UC column comments are
> analyst-authored (58–141 chars each). Per the framework's *Existing UC
> comment preservation* policy, the `Description` column for every row below
> matches the live UC comment **byte-for-byte verbatim** with no `[uc_comment]`
> citation tag. Re-deploying the `.alter.sql` is therefore a no-op against the
> current UC state and serves as the recovery audit trail. All wiki-only
> enrichment context (pipeline traces, FK semantics, gotcha cross-refs) lives
> exclusively in the `Notes & citations` column.

| # | Column | Type | Tier | Description | Notes & citations | Sample values |
|---|--------|------|------|-------------|-------------------|---------------|
| 0 | `date` | DATE | T1 | "Calendar date including weekends. Super and Voyager balances are fill-forwarded from Friday for Sat/Sun since source tables are weekday-only." | Sources: live UC comment (preserved); view DDL CTEs `super_last_weekday`, `voyager_last_weekday`. Wiki-only enrichment: the fill-forward window uses `NEXT_DAY(date,'SA')` and `DATE_ADD(NEXT_DAY(date,'SA'),1)` to map last weekday balances to Sat+Sun. Nova balances do NOT participate in fill-forward — Nova is 7-day from source. | `2025-06-13`, `2025-06-14`, `2025-06-15` |
| 1 | `date_id` | INT | T1 | "Date in YYYYMMDD integer format for partition-friendly filtering." | Sources: live UC comment (preserved); view DDL `CAST(DATE_FORMAT(c.date, 'yyyyMMdd') AS INT)`. Wiki-only enrichment: prefer `WHERE date_id = 20251231` (integer equality, partition-eligible) over `WHERE date = '2025-12-31'` for performance. | `20250613`, `20250614`, `20250615` |
| 2 | `user_id` | STRING | T1 | "Canonical Spaceship user_id, deduplicated via member_canonical (Super) and user_id_map (Voyager/Nova) to resolve 1:many member_id mappings." | Sources: live UC comment (preserved); view DDL CTEs `member_canonical`, `user_id_map`. Wiki-only enrichment: dedup logic = `ROW_NUMBER() OVER (PARTITION BY member_id ORDER BY user_id) = 1` (i.e. the lowest user_id per member is canonical). UUID format (8-4-4-4-12 with hyphens) per Spaceship Metabase identity convention. | `62a59e09-71d2-4c12-b8a9-70a1d9e34225`, `7e1b1d85-49e7-4a14-9f6d-fdb9d33e0c7d` |
| 3 | `gcid` | LONG | T1 | "eToro Global Customer ID from the sub_accounts bridge table (providerName=Spaceship). NULL if the user has no eToro cross-sell linkage." | Sources: live UC comment (preserved); view DDL CTE `user_gcid`. Wiki-only enrichment: join path = `bronze_sub_accounts_accounts.accountId = bronze_spaceship_metabase_contact.user_id` filtered by `providerName = 'Spaceship'`. NULL is the dominant case for Spaceship-only customers (no eToro account). FK to `main.bi_db.gold_sub_accounts_accounts.gcid`. | `2468109`, `3777215`, NULL |
| 4 | `super_balance_aud` | DOUBLE | T1 | "Superannuation closing balance in AUD. Weekend values are fill-forwarded from last weekday (Friday)." | Sources: live UC comment (preserved); view DDL CTE `super_bal_raw → super_last_weekday → super_bal`. Wiki-only enrichment: source column is `bronze_spaceship_metabase_super_user_balances.super_closing_aud_balance`. NAV=0 portfolios still produce rows; treat 0.0 as "user is enrolled in Super but holds no balance". | `0.0`, `15234.50` |
| 5 | `voyager_balance_aud` | DOUBLE | T1 | "Voyager managed fund balance in AUD (sum across all portfolios: EARTH, EXPLORER, GALAXY, ORIGIN, UNIVERSE). Weekend fill-forwarded." | Sources: live UC comment (preserved); view DDL CTE `voyager_bal_raw → voyager_last_weekday → voyager_bal`. Wiki-only enrichment: source column is `spaceship_metabase_voyager_user_balances.aud_balance`. EARTH/EXPLORER/GALAXY have NAV=0 (per `v_spaceship_fees` mgmt-fee gotcha — these portfolios use SUM(user_balance) as denominator); ORIGIN/UNIVERSE have NAV>0. The 5 portfolios are summed before joining here. | `0.0`, `22034.99` |
| 6 | `nova_balance_aud` | DOUBLE | T1 | "Nova stock trading balance in AUD. Available 7 days/week from source — no fill-forward needed." | Sources: live UC comment (preserved); view DDL CTE `nova_bal`. Wiki-only enrichment: source column is `bronze_spaceship_metabase_nova_user_balances.aud_balance`. Nova FX/trade activity timestamps are UTC and need `FROM_UTC_TIMESTAMP(..., 'Australia/Sydney')` per `v_spaceship_fees` gotcha (d) — but the user_balances table is already date-keyed correctly. | `0.0`, `1234.56` |
| 7 | `total_balance_aud` | DOUBLE | T1 | "Sum of super_balance_aud + voyager_balance_aud + nova_balance_aud. Does NOT include Money wallet balances." | Sources: live UC comment (preserved); view DDL final SELECT. Wiki-only enrichment: Money wallet (`bronze_spaceship_analytics_fct_money_transactions`) is the gateway for Voyager/Nova purchases per the view-level COMMENT, but is NOT counted as AUM (it's transactional, not investment-held). | `0.0`, `38503.55` |
| 8 | `super_balance_usd` | DOUBLE | T1 | "Super balance converted to USD using AUD/USD mid-rate ((Ask+Bid)/2) from fact_currencypricewithsplit (InstrumentID=7)." | Sources: live UC comment (preserved); view DDL CTE `aud_usd_rates`. Wiki-only enrichment: rate source is `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` filtered by `InstrumentID=7` (AUD/USD). When the rate is missing for a date, `COALESCE(r.aud_to_usd_rate, 0)` makes the USD column 0.0 — important for downstream consumers. | `0.0`, `10500.32` |
| 9 | `voyager_balance_usd` | DOUBLE | T1 | "Voyager balance converted to USD using same AUD/USD mid-rate." | Sources: live UC comment (preserved); same `aud_usd_rates` CTE as `super_balance_usd`. | `0.0`, `15191.82` |
| 10 | `nova_balance_usd` | DOUBLE | T1 | "Nova balance converted to USD using same AUD/USD mid-rate." | Sources: live UC comment (preserved); same `aud_usd_rates` CTE. | `0.0`, `851.07` |
| 11 | `total_balance_usd` | DOUBLE | T1 | "Total balance (Super+Voyager+Nova) in USD. Excludes Money wallet." | Sources: live UC comment (preserved); view DDL final SELECT. | `0.0`, `26543.21` |
| 12 | `is_funded` | BOOLEAN | T1 | "TRUE when total_balance_aud > 0, indicating the user holds a positive balance across any product." | Sources: live UC comment (preserved); view DDL final SELECT (`CASE WHEN ... > 0 THEN TRUE ELSE FALSE END`). Wiki-only enrichment: Spaceship's "funded user" definition aligns with eToro DDR's `IsFunded` semantic — useful for cross-domain cohort joins. | `true`, `false` |

## 4. Common usage / JOINs

- **Tableau workbook coverage**: `main__etoro_kpi` references this view; calc fields use `total_balance_usd` for AUM dashboards filtered by `is_funded = TRUE`.
- **Cross-domain bridge to eToro DWH**: join on `gcid` to `main.bi_db.gold_sub_accounts_accounts` (filter `providerName = 'Spaceship'`) to roll Spaceship balances into eToro panels.
- **Bronze-side joins** (use only when the view is insufficient): `user_id ↔ bronze_spaceship_metabase_contact.user_id` for SFDC contact lookups; `member_id ↔ bronze_spaceship_metabase_user_beta.member_id` for Super-specific drill-downs.

## 5. Gotchas

Direct verbatim quotes from the live UC view-level COMMENT (Tier 1, 1131 chars):

> "(a) All source amounts are in AUD; USD columns use the AUD/USD mid-rate from fact_currencypricewithsplit (InstrumentID=7). (b) Super and Voyager balance tables are weekday-only — Sat/Sun are fill-forwarded from Friday. Nova is 7-day. (c) user_id deduplication is critical — user_beta has 1:many member_id to user_id; this view uses the canonical (lowest) user_id per member. (d) Cross-sell linkage to eToro is via main.bi_db.bronze_sub_accounts_accounts (providerName=Spaceship), joining on contact.user_id = accountId to gcid. Granularity: one row per date x user_id."

## 6. UC ALTER provenance

The companion `.alter.sql` re-states the **live UC comments verbatim** for one
view-level COMMENT and 13 column-level COMMENTs. This is the *preservation*
pattern: every COMMENT statement is byte-for-byte identical to what
`system.information_schema` returns today, so a P6 deploy is a guaranteed no-op
against current UC state — the value is the recovery audit trail (e.g. after a
CTAS-style rebuild that wipes column comments). No citation tags are appended
in the deployed text; that would mutate live UC. All framework-derived
enrichments (CTE names, source-column mappings, FK paths, NAV=0 cohort notes)
are wiki-only via the `Notes & citations` column.
