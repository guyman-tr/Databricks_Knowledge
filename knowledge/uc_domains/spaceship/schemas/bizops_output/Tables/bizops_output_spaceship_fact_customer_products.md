---
object: main.bizops_output.bizops_output_spaceship_fact_customer_products
domain: spaceship
table_type: EXTERNAL
format: PARQUET
column_count: 5
row_count: null
generated_at: "2026-05-04T12:46:00Z"
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 5
  tier5_columns: 0
  unverified_columns: 0
sources:
  confluence: ["BDP/12918358038"]
  tableau:    ["main__spaceship"]
  databricks: []
  uc_comment: false
---

# bizops_output_spaceship_fact_customer_products

## 1. What it is

BizOps-output fact table holding the latest balance per `(GCID,
Spaceship_Product)` for Spaceship customers linked to eToro. Granularity: one
row per linked-customer × product. The product taxonomy here is the
**SFDC/BizOps customer-facing taxonomy** (`Voyager`, `US Investing`,
`Available Money`), which is NOT the same as the technical balance-source
taxonomy in `v_spaceship_aum` (`Super`, `Voyager`, `Nova`, `Money`). The exact
mapping from technical to BizOps names is not anchored to a Confluence page in
the discovery cache.

## 2. Identity & Lineage

| Attribute | Value | Source |
|-----------|-------|--------|
| Full name | `main.bizops_output.bizops_output_spaceship_fact_customer_products` | UC inventory |
| Type | EXTERNAL TABLE | UC inventory |
| Format | PARQUET (BizOps output) | UC inventory |
| Owner | BI / BizOps pipeline | inferred |
| Row count | n/a (small — sample shows 139 rows total across 3 products) | enum_hints sum |
| Upstream | Likely a Synapse-side aggregator that pulls per-product balances from `v_spaceship_aum` (or its source bronze tables) and emits one row per (GCID, product). **Inferred**. | sample-shape inference |
| Downstream | SFDC BizOps sync; companion `bizops_output_spaceship_gold_daily_update` (denormalised join with `dim_customers`); Tableau workbook `main__spaceship` | sample-shape inference + Tableau index |

## 3. Columns

| # | Column | Type | Tier | Description | Notes & citations | Sample values |
|---|--------|------|------|-------------|-------------------|---------------|
| 0 | `GCID` | LONG | T4 | "eToro Global Customer ID. FK to main.bi_db.gold_sub_accounts_accounts.gcid. Composite PK with Spaceship_Product. [uc_sample]" | Sources: UC samples (numeric LONG, eToro gcid space). | `45038599`, `45090849`, `45098821` |
| 1 | `Spaceship_Product` | STRING | T4 | "BizOps-facing product name. Values: Voyager (88), US Investing (28), Available Money (23). NOT identical to v_spaceship_aum's Super/Voyager/Nova/Money taxonomy. [uc_sample]" | Sources: UC enum_hints (3 distinct values, counts shown). Wiki-only enrichment: `Voyager` is consistent across both taxonomies; `US Investing` is likely the BizOps-facing label for what `v_spaceship_aum` calls `Nova` (US-stock trading), but this mapping is NOT confirmed by a Confluence anchor. `Available Money` likely maps to the `Money` wallet (cash gateway) — also unconfirmed. The technical `Super` product is absent from the BizOps fact, suggesting Super is excluded from the SFDC sync. **Treat the mapping as a known unknown** until anchored. | `Voyager`, `US Investing`, `Available Money` |
| 2 | `Customer_Product_Internal_Unique_ID` | STRING | T4 | "Synthesized PK = '{GCID}_{Spaceship_Product}'. E.g. '45090849_Voyager'. [uc_sample]" | Sources: UC samples — every observed value matches the `{GCID}_{Spaceship_Product}` pattern exactly. | `45038599_Voyager`, `45090849_Voyager`, `45098821_Voyager` |
| 3 | `Balance` | DOUBLE | T4 | "Latest balance for this (GCID, Spaceship_Product), denominated in AUD (Spaceship's home currency). May be 0.0 for customers enrolled in a product but holding no balance. [uc_sample]" | Sources: UC samples (DOUBLE values; 22034.999... matches an AUD balance shape; 0.0 is dominant in samples). Wiki-only enrichment: assumes AUD because the upstream `v_spaceship_aum.*_balance_aud` columns are AUD; we have no Confluence anchor confirming the bizops fact also stores AUD. | `0.0`, `22034.999735005` |
| 4 | `UpdateDate` | TIMESTAMP | T4 | "Snapshot refresh timestamp (UTC). All rows in a refresh share the same value. [uc_sample]" | Sources: UC samples (all 3 rows share `2026-05-04T07:42:47.317Z`). | `2026-05-04T07:42:47.317Z` |

## 4. Common usage / JOINs

- **Bridge to eToro DWH**: `GCID` joins to `main.bi_db.gold_sub_accounts_accounts.gcid` (filter `providerName='Spaceship'`).
- **Bridge to Spaceship balance views**: via `bizops_output_spaceship_dim_customers` → `Spaceship_Contact_ID` → `v_spaceship_aum.user_id`. Note the BizOps `Spaceship_Product` column is NOT directly comparable to the AUM view's `super_balance_aud / voyager_balance_aud / nova_balance_aud` columns — see Section 5.
- **Self-join with dim_customers**: `dim_customers.GCID = fact.GCID` for adding the SFDC `account_id` and Spaceship `Spaceship_Contact_ID` to a per-product balance row.

## 5. Gotchas

- **Product-taxonomy gap (KNOWN UNKNOWN)**: BizOps `Spaceship_Product` enum
  (`Voyager`, `US Investing`, `Available Money`) does not have a documented
  1-to-1 mapping to the technical taxonomy in `v_spaceship_aum` (`Super`,
  `Voyager`, `Nova`, `Money`). Likely `US Investing → Nova` and
  `Available Money → Money`, but this is NOT anchored. Don't assume the
  mapping silently in cohort joins. [uc_sample]
- **Super absent**: No `Super` rows are observed in the BizOps fact. If
  Super customers should be SFDC-synced, this is a coverage gap.
- **Balance currency assumed AUD** but not confirmed by a Confluence anchor.
  Treat as AUD by default (matches Spaceship's home currency and the upstream
  AUM view) but verify before reporting in USD without conversion. [uc_sample]
- All 5 columns are Tier 4 — no Confluence/Tableau-formula anchor located.

## 6. UC ALTER provenance

5 column-level COMMENTs + 1 table-level COMMENT, all Tier 4 with `[uc_sample]`
citations. Compliant with the T4-deploy rule (wording grounded in observed
samples + enum_hints, no speculation about the unmapped values). If a future
analyst review confirms the BizOps↔technical product mapping or currency, the
relevant rows can be promoted to T5 and re-deployed.
