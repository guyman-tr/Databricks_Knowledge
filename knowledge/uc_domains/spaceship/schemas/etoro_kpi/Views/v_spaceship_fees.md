---
object: main.etoro_kpi.v_spaceship_fees
domain: spaceship
table_type: VIEW
format: null
column_count: 7
row_count: null
generated_at: "2026-05-04T08:05:00Z"
tier_breakdown:
  tier1_columns: 7
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  unverified_columns: 0
sources:
  confluence:
    - "12918358038"  # Spaceship Data transfer to eToro Datalake (BDP)
    - "13335789570"  # Spaceship (retirement funds in Australia) (CS)
    - "13131186194"  # SpaceShip Integration - LLD (BG)
  tableau: []
  databricks: []
  notebooks: []
  uc_comment: true
  knowledge_skills:
    - knowledge/skills/_kpi_views_index.json
    - knowledge/skills/_brief_cluster_13.md
    - knowledge/skills/revenue-and-fees/SKILL.md
---

# v_spaceship_fees

## 1. What it is

`main.etoro_kpi.v_spaceship_fees` is the canonical eToro-side **fee-revenue panel for Spaceship**, materialising one row per `(date, product, user_id)` across **five Spaceship fee streams**: Super admin/member fees, Voyager account fees, Voyager management fees (pro-rated), Nova platform fees, and Nova FX-spread fees. It is the per-fee analyst entry-point feeding the eToro DDR `BI_DB_DDR_Fact_Revenue_Generating_Actions` rollup.

> **Tier-1 anchor (analyst-authored UC comment, 2026-04-16):**
>
> *"Fee revenue by product, user, and day across all Spaceship fee types. Spaceship is an Australian investment platform with five fee streams: (1) Super — admin/member fees from super_transactions (type=Fees). Excludes the one-off SFT event on 2024-05-18. (2) Voyager (account) — account-level fees from voyager_account_fees, keyed by account_fee_created_at_date. (3) Voyager (mgmt) — daily management fees pro-rated to each user by their balance share of portfolio NAV. For portfolios with NAV>0 (ORIGIN, UNIVERSE): user_fee = total_fee × (user_balance / NAV). For portfolios with NAV=0 (EARTH, EXPLORER, GALAXY): falls back to SUM(user_balance) as denominator. (4) Nova (platform) — platform fees from nova_fees, keyed by coverage_start_date. (5) Nova (FX) — foreign-exchange spread fees from nova_transactions (order_fx_aud_fee on finalised orders). Granularity: one row per date × product × user_id."*

> **Tier-1 business primer ([Confluence/CS/13335789570](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/13335789570/)):**
>
> *"Spaceship is a financial platform offering its own mutual funds, retirement funds and US-market share trading in Australia. eToro acquired Spaceship in November 2024."* — establishes the source-system identity and acquisition date, so analysts know `v_spaceship_fees` only carries fee events from acquisition forward.

## 2. Identity & Lineage

| Attribute | Value | Source |
|-----------|-------|--------|
| Full name | `main.etoro_kpi.v_spaceship_fees` | UC inventory |
| Type | `VIEW` | `system.information_schema.tables` |
| Format | n/a (VIEW) | UC `DESCRIBE EXTENDED` |
| Owner | `guyman@etoro.com` | UC `DESCRIBE EXTENDED` |
| Created | `Thu Apr 16 12:32:55 UTC 2026` | UC `DESCRIBE EXTENDED` |
| DDL size | 5,140 chars | `_kpi_views_index.json` |

### Upstream — direct refs from view DDL

(Source: `knowledge/skills/_kpi_views_index.json[etoro_kpi.v_spaceship_fees].refs`, Tier-4 auto-extract.)

| Upstream | Domain |
|----------|--------|
| `spaceship.bronze_spaceship_metabase_user_beta` | spaceship (this domain) — identity bridge |
| `spaceship.bronze_spaceship_metabase_super_transactions` | spaceship — Super fee source (stream 1) |
| `spaceship.bronze_spaceship_metabase_voyager_account_fees` | spaceship — Voyager account-fee source (stream 2) |
| `spaceship.bronze_spaceship_metabase_voyager_management_fees` | spaceship — Voyager mgmt-fee source (stream 3) |
| `spaceship.spaceship_metabase_voyager_product_balances` | spaceship — Voyager NAV / pro-rating denominator |
| `spaceship.bronze_spaceship_metabase_nova_fees` | spaceship — Nova platform-fee source (stream 4) |
| `spaceship.bronze_spaceship_metabase_nova_transactions` | spaceship — Nova FX-fee source (stream 5) |
| `spaceship.bronze_spaceship_metabase_contact` | spaceship — eToro `gcid` mapping |
| `bi_db.bronze_sub_accounts_accounts` | bi_db (out-of-domain) — Spaceship `user_id` ↔ eToro `gcid` bridge |
| `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | dwh (out-of-domain) — AUD→USD mid-rate (InstrumentID=7) |

### Ingest provenance

The `bronze_spaceship_*` tables are written by `databricks/de/Spaceship/Spaceship- Main.py` orchestrator (and per-table worker `Spaceship - process table.py`) which copies from the Spaceship-side **GCP/BigQuery `Spaceship.metabase` and `Spaceship.analytics` schemas** under the **read-only ingest contract** defined in [Confluence/BDP/12918358038](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/12918358038/). PII is sequestered into a separate schema before reaching the bronze layer. (Tier-1 from BDP page; Tier-3 from notebook listing in `databricks_assets.json`.)

### Downstream

(Source: `knowledge/skills/_brief_cluster_13.md` — Tier-4 cluster derivation.)

- `etoro_kpi.vg_ddr_revenue` (Cluster 13) reads the eToro DDR which absorbs `v_spaceship_fees` revenue events.
- Direct downstream Tableau workbooks: **none** today (Tier-3 negative finding from `tableau_index.json`).
- Direct downstream Genie spaces: **none** today (Tier-3 negative finding from `databricks_assets.json`).

## 3. Columns

> **Format note:** the `Description` column is the **deployable** comment text — it lands verbatim in the UC `COMMENT ON COLUMN` for this view (so it's what an agent sees via `DESCRIBE`). The `Notes & citations` column is **wiki-only** — full provenance, pipeline traces, gotcha cross-refs, and caveats for humans and domain-skill agents seeking deeper reference. See `.cursor/rules/uc-domain-doc/05-generate-doc.mdc` §"Description vs Notes & citations".

> **Pre-existing UC comments — preservation policy:** every column on this view already has an analyst-authored UC comment (`uc_comment: true` in frontmatter, authored 2026-04-16). Per `05-generate-doc.mdc §"Existing UC comment preservation"`, the **`Description` column is the live UC comment verbatim** — no citation tag, no enrichment, no rewording. The `.alter.sql` matches the live state byte-for-byte so re-deploy is a no-op. Wiki-only enrichments (Confluence cross-references, UUID format notes, per-stream upstream-table mappings) live in the `Notes & citations` column.

| # | Column | Type | Tier | Description | Notes & citations | Sample values |
|---|--------|------|------|-------------|-------------------|---------------|
| 0 | `date` | DATE | T1 | Fee accrual date. Nova FX uses order_filled_at converted from UTC to Australia/Sydney. Voyager mgmt weekend fees retain the actual fee date even though the balance lookup falls back to Friday. | Source: `uc_comment §gotchas (b) + (d)`. The Australia/Sydney conversion is critical — without it, trades after ~2pm UTC land one day early vs Metabase. The Voyager-mgmt weekend fill-forward is necessary because the balance table is weekday-only; Friday balance is reused as the pro-rating denominator for Sat/Sun fees, but the fee date itself stays accurate. | `2025-01-07` |
| 1 | `date_id` | INT | T1 | Date in YYYYMMDD integer format. | Source: `uc_comment`. Standard eToro DDR-compatible date encoding (e.g. 20250107 = 2025-01-07). | `20250107` |
| 2 | `product` | STRING | T1 | Fee category: Super (admin fees from super_transactions), Voyager (account) (from voyager_account_fees), Voyager (mgmt) (pro-rated management fees), Nova (platform) (from nova_fees), or Nova (FX) (from nova_transactions FX spread). | Source: `uc_comment §scope`. The existing UC comment already gives per-stream upstream-table mappings inline — no enrichment needed. Full ingest provenance (each `bronze_spaceship_metabase_*` table is loaded by the `databricks/de/Spaceship/` notebooks per `databricks_assets.json`) is documented in §2 Lineage. | `Voyager (account)` |
| 3 | `user_id` | STRING | T1 | Canonical Spaceship user_id (deduplicated). | **Wiki-only enrichment context** (NOT in deployed UC comment): Sample shows 5 distinct UUIDs in 5-row sample — UUID format is from Spaceship Metabase. Resolved via `spaceship.bronze_spaceship_metabase_user_beta` (identity bridge); cross-sell to eToro happens via `bi_db.bronze_sub_accounts_accounts` filtered by `providerName='Spaceship'`. | `9986bef0-9956-479a-99f4-4e5e8553b099`, `fc0fac77-4674-4331-a764-64b953298ffe` |
| 4 | `gcid` | LONG | T1 | eToro Global Customer ID. NULL if no cross-sell linkage. | **Wiki-only enrichment context** (NOT in deployed UC comment): the cross-sell linkage refers to the customer linking their Spaceship account to eToro via the Wallet flow described in `Confluence/CS/13335789570 §"Linking a Spaceship account to eToro"`. All 5 sample rows are NULL — confirms most fee rows today are unlinked. When populated, resolves to `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.RealCID`. The cross-sell rate (% of fee rows with a non-NULL `gcid`) is itself a useful KPI for the Spaceship integration. | (all NULL in 5-row sample) |
| 5 | `total_fees_aud` | DOUBLE | T1 | Absolute total fees in AUD. Voyager mgmt fees are pro-rated: user_fee = total_fee x (user_balance / portfolio_NAV). For zero-NAV portfolios (EARTH, EXPLORER, GALAXY), falls back to SUM(user_balance) as denominator. Excludes Super SFT event (2024-05-18). | Source: `uc_comment §scope + §gotchas (a) + (c)`. The pro-rating window MUST partition by fee date, NOT balance lookup date — partitioning by balance date triples the denominator for NAV=0 portfolios (~968 AUD/day error). All source amounts are AUD; downstream USD conversion via `total_fees_usd` uses the AUD/USD mid-rate. | `3.0` |
| 6 | `total_fees_usd` | DOUBLE | T1 | Total fees converted to USD via AUD/USD mid-rate ((Ask+Bid)/2 from fact_currencypricewithsplit, InstrumentID=7). | Source: `uc_comment §gotcha (a)`. Mid-rate (not bid or ask) is the convention here. The currency-rate fact is in the DWH out-of-domain — joining requires `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` filtered by `InstrumentID=7`. | `1.8702450000000002` |

**Tier breakdown:** 7 / 7 columns at Tier 1 (UC comment + Confluence anchors). 0 columns Tier 4 / UNVERIFIED. This is the documentation goal — every column tied to authored evidence.

## 4. Common usage / JOINs

There are **no Tableau workbooks, custom-SQL queries, or calc fields** that reference this view (Tier-3 negative, `tableau_index.json`). There are **no Genie spaces** with this view in `data_sources.tables[]` (Tier-3 negative, `databricks_assets.json`). The only confirmed downstream consumer is the DDR rollup `etoro_kpi.vg_ddr_revenue`.

The eToro-side analyst pattern is therefore:

```sql
-- canonical revenue panel join
SELECT
    f.date_id,
    f.product,
    f.user_id,
    f.gcid,
    f.total_fees_usd,
    dim_c.RealCID,
    dim_c.RegistrationCountryID
FROM main.etoro_kpi.v_spaceship_fees f
LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dim_c
       ON dim_c.RealCID = f.gcid       -- only joins when Spaceship account is linked
WHERE f.date_id BETWEEN 20260101 AND 20260131
```

`[cluster_brief]` patterns from `knowledge/skills/_brief_cluster_13.md` (Tier-4) suggest secondary joins to `Dim_ActionType`, `Dim_Revenue_Metrics`, and `BI_DB_DDR_CID_Level` once a row is mapped through the DDR rollup.

## 5. Gotchas (verbatim from Tier-1 sources)

All four gotchas come from the analyst-authored UC comment on this view (`[uc_comment]`):

1. **AUD-by-source / USD-via-mid-rate.** *"All source amounts are AUD; USD uses AUD/USD mid-rate from fact_currencypricewithsplit (InstrumentID=7)."*
2. **Voyager-mgmt weekend fill-forward.** *"Voyager mgmt fees accrue daily including weekends, but the balance table is weekday-only. Weekend fees use fill-forwarded Friday balances for the pro-rating denominator (~7-8K AUD/day would be lost without this)."*
3. **Pro-rating partition correctness.** *"The pro-rating window must partition by fee date, NOT balance lookup date. Since fill-forward maps Fri+Sat+Sun fees to the same Friday balance rows, partitioning by balance date triples the denominator for NAV=0 portfolios (~968 AUD/day error)."*
4. **Nova-FX timezone.** *"Nova FX `order_filled_at` is UTC — must convert to Australia/Sydney before DATE cast, otherwise trades after ~2pm UTC land one day early vs Metabase."*

Additional Tier-1 gotcha from [Confluence/CS/13335789570](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/13335789570/):

5. **Daily-not-realtime balance.** *"Your Spaceship product balances in the eToro app are populated once a day by Spaceship. This means intra-day movements in your product balances may not be reflected in the eToro app in real time."* — Implication: aggregating fees by `date` reflects Spaceship-side fee accrual day, not the eToro Wallet visibility day.

## 6. UC ALTER provenance

The companion `v_spaceship_fees.alter.sql` deploys the view-level comment + 7 column-level comments. **Each deployed comment is the existing live UC comment, byte-for-byte verbatim** — re-deploy is a no-op. The wiki Section 3 `Description` column matches the live UC text exactly; the `Notes & citations` column carries wiki-only enrichments (Confluence Wallet-flow cross-reference for `gcid`, UUID-format note for `user_id`, etc.) that NEVER land in UC.

All 7 column comments + the view-level comment were authored 2026-04-16 by `guyman@etoro.com` as part of the eToro DDR work. Per `05-generate-doc.mdc §"Existing UC comment preservation"`, when an object already has high-quality analyst-authored UC comments the framework's job is preservation, not modification — improvements only happen via explicit analyst review (T5) logged in a `.review-log.md` sidecar. **No Tier-4 or UNVERIFIED comments are deployed.**

**Format restructure (2026-05-04):** Section 3 was split from a single `Description (cited)` column into separate `Description` (deployable to UC) and `Notes & citations` (wiki-only verbose context) columns, per `05-generate-doc.mdc §"Description vs Notes & citations"`. For Spaceship the `Description` column was set to match live UC text exactly so re-deploy stays idempotent; enrichment context was moved to `Notes & citations`.

## 7. Discovery summary (per-source roll-up)

| Source | Hits for this view | Quality |
|--------|--------------------|---------|
| UC inventory | 1 | Tier 1 (full UC comment, 1.5 KB) |
| Confluence | 3 anchor pages (BDP, CS, BG) | Tier 1 |
| Tableau | 0 workbooks, 0 custom-SQL, 0 calc-fields | None — view is not used in Tableau |
| Genie spaces | 0 of 144 | None — Spaceship has no Genie coverage |
| Notebooks (`DataPlatform/databricks/de/Spaceship/`) | 2 ingest notebooks (orchestrator + worker) | Tier 3 (provenance for upstream `bronze_spaceship_*`, not this view) |
| KPI views index | 1 (this view) | Tier 4 — auto-extracted refs |
| Cluster brief | Cluster 13 (DDR/MIMO) | Tier 4 — inferred join graph |
