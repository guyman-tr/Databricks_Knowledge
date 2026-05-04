---
object: main.bizops_output.bizops_output_spaceship_gold_daily_update
domain: spaceship
table_type: EXTERNAL
format: PARQUET
column_count: 8
row_count: null
generated_at: "2026-05-04T12:47:00Z"
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 8
  tier5_columns: 0
  unverified_columns: 0
sources:
  confluence: ["BDP/12918358038"]
  tableau:    ["main__spaceship"]
  databricks: []
  uc_comment: false
---

# bizops_output_spaceship_gold_daily_update

## 1. What it is

BizOps-output denormalised gold table that joins `dim_customers` (GCID +
Spaceship contact identity + SFDC `account_id`) with `fact_customer_products`
(per-product balance) to produce a single row per `(GCID, product)` carrying
all five identity fields plus the balance. Granularity: one row per linked
customer × product, including customers who have a Spaceship contact but no
active product (those rows have empty `Spaceship_Product` and NULL
`Spaceship_Product_External_ID`). This is the table the BizOps SFDC sync
actually reads — the dim+fact pair are the building blocks.

## 2. Identity & Lineage

| Attribute | Value | Source |
|-----------|-------|--------|
| Full name | `main.bizops_output.bizops_output_spaceship_gold_daily_update` | UC inventory |
| Type | EXTERNAL TABLE | UC inventory |
| Format | PARQUET (BizOps output) | UC inventory |
| Owner | BI / BizOps pipeline | inferred |
| Row count | n/a (~118 sampled rows: 91 unmapped + 20 Voyager + 4 Available Money + 3 US Investing) | enum_hints |
| Upstream | Likely a Synapse-side LEFT JOIN of `bizops_output_spaceship_dim_customers` (one row per GCID) onto `bizops_output_spaceship_fact_customer_products` (one row per (GCID, product)). LEFT-side preservation explains the 91 rows with empty `Spaceship_Product` (linked customer with no product balance). **Inferred**. | sample-shape inference |
| Downstream | SFDC BizOps sync (likely the actual sync target — naming "gold_daily_update" suggests the daily refresh feed); BizOps Tableau workbook `main__spaceship` | naming + Tableau index |

## 3. Columns

| # | Column | Type | Tier | Description | Notes & citations | Sample values |
|---|--------|------|------|-------------|-------------------|---------------|
| 0 | `GCID` | LONG | T4 | "eToro Global Customer ID. FK to main.bi_db.gold_sub_accounts_accounts.gcid. PK component (composite with Spaceship_Product). [uc_sample]" | Sources: UC samples (numeric LONG, eToro gcid space). | `2468109`, `11333973`, `15462483` |
| 1 | `Connected_Spaceship_Customer` | BOOLEAN | T4 | "TRUE when this GCID is linked to a Spaceship contact. Always TRUE in observed samples (consistent with the dim_customers source). [uc_sample]" | Sources: UC samples (all TRUE). Wiki-only enrichment: same column as in `bizops_output_spaceship_dim_customers` — preserved on the left side of the join. | `true` |
| 2 | `Spaceship_Product` | STRING | T4 | "BizOps product name. Values: '' (91, no product on file), Voyager (20), Available Money (4), US Investing (3). Empty string indicates a linked customer with no active product balance. [uc_sample]" | Sources: UC enum_hints. Wiki-only enrichment: the empty-string-dominant distribution suggests this gold table preserves customers who have a Spaceship contact (left side of the join) but no fact_customer_products row — i.e. linked-but-not-funded. Treat empty `Spaceship_Product` as "no product, do not aggregate balance" and filter it out for product-level reporting. | `Voyager`, `''`, `Available Money`, `US Investing` |
| 3 | `Spaceship_Product_External_ID` | STRING | T4 | "Equals fact_customer_products.Customer_Product_Internal_Unique_ID, format '{GCID}_{Spaceship_Product}'. NULL when no product (matches empty Spaceship_Product). [uc_sample]" | Sources: UC samples + enum_hints. Wiki-only enrichment: same synthesized PK pattern as the fact table. NULL-vs-empty correlates with empty `Spaceship_Product`. | `11333973_Voyager`, NULL |
| 4 | `Balance` | DOUBLE | T4 | "Balance from fact_customer_products in AUD. 0.0 for customers with no product. [uc_sample]" | Sources: UC samples (DOUBLE, dominant 0.0). Currency assumption (AUD) inherited from the upstream fact. | `0.0`, `22034.99` |
| 5 | `Spaceship_Contact_ID` | STRING | T4 | "Spaceship contact UUID v4 (from dim_customers). FK to main.spaceship.bronze_spaceship_metabase_contact.user_id. [uc_sample]" | Sources: UC samples (UUID v4 format). Same column as `dim_customers.Spaceship_Contact_ID`. | `582c3434-cf7d-4e19-86ed-bbc9f64f9716` |
| 6 | `account_id` | STRING | T4 | "Salesforce 18-char account_id (from dim_customers). FK to SFDC Account.Id. [uc_sample]" | Sources: UC samples (`001…` SFDC prefixes). | `0011p00002cphqQAAQ`, `0012400000TF2i1AAD` |
| 7 | `UpdateDate` | TIMESTAMP | T4 | "Snapshot refresh timestamp (UTC). All rows in a refresh share the same value. [uc_sample]" | Sources: UC samples (`2025-11-18T07:36:34.647Z` shared across the 3-row sample). | `2025-11-18T07:36:34.647Z` |

## 4. Common usage / JOINs

- This table is the canonical SFDC-sync feed for Spaceship customer/product data. Filter by latest `UpdateDate` for the freshest snapshot.
- For per-product reporting: filter `Spaceship_Product <> ''` before aggregating `Balance`.
- Bridge to eToro DWH via `GCID` (FK to `gold_sub_accounts_accounts`).
- Bridge to Spaceship balance views via `Spaceship_Contact_ID = v_spaceship_aum.user_id`.

## 5. Gotchas

- **Empty-string product rows are intentional** — they preserve linked
  customers with no active product balance (left side of the underlying
  join). Don't treat empty as missing-data; treat it as "no product on
  file". [uc_sample]
- The 91:20:4:3 sample distribution (empty:Voyager:AvailableMoney:USInvesting)
  is dominated by the empty-product cohort. If a downstream consumer
  expects every row to carry a product, they need to pre-filter. [uc_sample]
- Product-taxonomy gap from `fact_customer_products` propagates here unchanged
  (US Investing/Available Money likely map to Nova/Money but unconfirmed).
- All 8 columns are Tier 4 — no Confluence anchor located for this specific
  BizOps gold table.

## 6. UC ALTER provenance

8 column-level COMMENTs + 1 table-level COMMENT, all Tier 4 with `[uc_sample]`
citations. Compliant with the T4-deploy rule (wording grounded in observed
samples and enum_hints, no speculation about the unmapped product values).
