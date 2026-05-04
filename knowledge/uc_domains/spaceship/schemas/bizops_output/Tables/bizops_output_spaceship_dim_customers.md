---
object: main.bizops_output.bizops_output_spaceship_dim_customers
domain: spaceship
table_type: EXTERNAL
format: PARQUET
column_count: 5
row_count: null
generated_at: "2026-05-04T12:45:00Z"
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

# bizops_output_spaceship_dim_customers

## 1. What it is

BizOps-output bridge dim mapping eToro `GCID` to Spaceship's contact identity
(`Spaceship_Contact_ID` UUID + Salesforce `account_id`) for every customer who
has been linked across the two systems. Granularity: one row per linked
customer (GCID-keyed). The table is the **eToro side of the cross-sell bridge**
and is read by SFDC sync jobs and BizOps reporting that need both identity
spaces in one row. Source semantics for individual columns are inferred from
sample-value shapes and naming conventions only — no Tier-1 Confluence anchor
was located for this specific table.

## 2. Identity & Lineage

| Attribute | Value | Source |
|-----------|-------|--------|
| Full name | `main.bizops_output.bizops_output_spaceship_dim_customers` | UC inventory |
| Type | EXTERNAL TABLE | `system.information_schema.tables` |
| Format | PARQUET (BizOps output schema) | UC inventory |
| Owner | BI / BizOps pipeline (Synapse-materialised, surfaced in UC) | inferred from naming |
| Row count | n/a (not measured) | n/a |
| Upstream | Likely populated by a Synapse stored procedure / ADF pipeline that joins `main.bi_db.bronze_sub_accounts_accounts` (providerName='Spaceship') with `main.spaceship.bronze_spaceship_metabase_contact` (for `account_id`/`Spaceship_Contact_ID`). **Inferred**, not anchored. | sample-shape inference |
| Downstream | SFDC sync (account_id is SFDC 18-char format); BizOps Tableau workbook `main__spaceship`; companion bridge `bizops_output_spaceship_gold_daily_update` re-uses these 5 columns | sample-shape inference + Tableau index |

## 3. Columns

| # | Column | Type | Tier | Description | Notes & citations | Sample values |
|---|--------|------|------|-------------|-------------------|---------------|
| 0 | `GCID` | LONG | T4 | "eToro Global Customer ID. FK to main.bi_db.gold_sub_accounts_accounts.gcid. Primary key for this bridge dim. [uc_sample]" | Sources: UC samples (numeric LONG, range 2.4M–8M observed, matches eToro gcid space). Wiki-only enrichment: in the eToro DWH this is the canonical customer identity used across Trading/Wallet/Marketing facts. The bridge filters on `providerName = 'Spaceship'` upstream. | `2468109`, `3777215`, `8002155` |
| 1 | `Connected_Spaceship_Customer` | BOOLEAN | T4 | "TRUE when this GCID has been linked to a Spaceship contact via the cross-sell bridge. Always TRUE in observed samples. [uc_sample]" | Sources: UC samples (all rows in the 3-row sample show `true`). Wiki-only enrichment: if the table only stores linked customers (rows with FALSE absent), the column is functionally redundant — but its presence suggests the table can also hold customers who **were** previously linked and were later marked disconnected. We do not have a Confluence anchor confirming this. | `true` |
| 2 | `Spaceship_Contact_ID` | STRING | T4 | "Spaceship contact UUID v4. FK to main.spaceship.bronze_spaceship_metabase_contact.user_id. [uc_sample]" | Sources: UC samples — strings match UUID v4 format (8-4-4-4-12 with hyphens). Wiki-only enrichment: this is the same identifier space as `user_id` in `main.spaceship.bronze_spaceship_metabase_contact`, which is the dedup-target in `v_spaceship_aum.user_id` and `v_spaceship_mimo.user_id`. Joining this table on `Spaceship_Contact_ID = v_spaceship_aum.user_id` is the canonical eToro→Spaceship balance roll-up path. | `582c3434-cf7d-4e19-86ed-bbc9f64f9716`, `14f56998-3098-45db-84d6-5b04b848742c` |
| 3 | `account_id` | STRING | T4 | "Salesforce account_id (18-char SFDC format). FK to SFDC Account.Id. Used by BizOps SFDC sync as the customer-side join key. [uc_sample]" | Sources: UC samples — strings start with `001` (SFDC Account record-type prefix) and are 15–18 chars. Wiki-only enrichment: SFDC's 18-char `Id` is the case-insensitive variant of the 15-char `Id`; both prefixes `0011p` (newer org) and `0012400` (older org) are observed in samples — likely a Spaceship-AU vs Spaceship-acquired-org distinction, but we do not have a Confluence anchor confirming that. | `0011p00002cphqQAAQ`, `0012400000TF2i1AAD` |
| 4 | `UpdateDate` | TIMESTAMP | T4 | "Snapshot refresh timestamp (UTC, microsecond precision). All rows in a refresh share the same UpdateDate. [uc_sample]" | Sources: UC samples (all 3 sample rows share `2026-05-04T07:41:35.142Z`, indicating a full-table refresh pattern). Wiki-only enrichment: filter on the latest `UpdateDate` for the freshest snapshot; do NOT use it as an event timestamp. | `2026-05-04T07:41:35.142Z` |

## 4. Common usage / JOINs

- **Bridge to Spaceship balance views**: `dim_customers.Spaceship_Contact_ID = v_spaceship_aum.user_id` (or `v_spaceship_mimo.user_id`) — joins eToro GCID-keyed reporting to the Spaceship balance/MIMO panels.
- **Bridge to eToro DWH**: `dim_customers.GCID` is the FK side of `main.bi_db.gold_sub_accounts_accounts` (filter `providerName='Spaceship'` to match).
- **Companion fact**: `bizops_output_spaceship_fact_customer_products` is GCID-grouped at one row per `(GCID, Spaceship_Product)`; this dim is one row per GCID.

## 5. Gotchas

- All 5 columns are Tier 4 (sample-anchored). The semantics encoded here are
  inferred from naming conventions, sample-value shapes, and the well-known
  GCID/UUID/SFDC ID conventions in the eToro stack. They are NOT anchored to
  a Confluence page describing this specific BizOps output table — none was
  located in the discovery cache.
- `Connected_Spaceship_Customer` was TRUE in 100% of the 3-row sample. If
  consumers rely on this flag to filter, verify upstream that FALSE rows
  actually exist (or treat the column as redundant). [uc_sample]
- The `account_id` 15-char vs 18-char SFDC format is not normalised here —
  consumers MUST handle both lengths when joining to SFDC. [uc_sample]

## 6. UC ALTER provenance

The companion `.alter.sql` emits 1 table-level COMMENT + 5 column-level
`COMMENT ON COLUMN ... IS '...'` statements. Every column is Tier 4 and
carries a `[uc_sample]` citation tag. Tier 4 deployments are permitted by the
framework rule when the wording is fully grounded in observed sample values
with no speculation; this file complies. If a future Confluence anchor or
analyst review elevates any column to T1/T5, the sidecar review-log should be
created and the ALTER updated.
