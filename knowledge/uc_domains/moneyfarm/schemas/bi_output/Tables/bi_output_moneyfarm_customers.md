---
object: main.bi_output.bi_output_moneyfarm_customers
domain: moneyfarm
table_type: EXTERNAL
format: PARQUET
column_count: 4
row_count: null
generated_at: "2026-05-04T12:50:00Z"
tier_breakdown:
  tier1_columns: 1
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 3
  tier5_columns: 0
  unverified_columns: 0
sources:
  confluence: ["XP/13551468545", "XP/12216961926", "MG/13600227427", "CS/13209534657"]
  tableau:    ["main__etoro_kpi"]
  databricks: []
  uc_comment: false
---

# bi_output_moneyfarm_customers

## 1. What it is

eToro-side dim of MoneyFarm-onboarded customers. Granularity: one row per
`GCID` (eToro Global Customer ID) for every customer who has ever appeared on
either the live MoneyFarm event stream OR the silver back-fill ladder.
`MF_Journey_Beginning` is the **earliest** date this GCID was observed as a
MoneyFarm customer; `Date_Source_Type` records which provenance ladder rung
that earliest observation came from. The same three-rung provenance ladder
(`Live Event`, `Bronze Table`, `Silver AUM Snapshot`) appears on the companion
fact `bi_output_moneyfarm_fact_portfolio_snapshot.Source_Type`.

## 2. Identity & Lineage

| Attribute | Value | Source |
|-----------|-------|--------|
| Full name | `main.bi_output.bi_output_moneyfarm_customers` | UC inventory |
| Type | EXTERNAL TABLE | UC inventory |
| Format | PARQUET (BI output) | UC inventory |
| Owner | BI / data-platform | inferred |
| Row count | ~96k (sum of enum_hints: 49,189 Live Event + 45,270 Bronze Table + 1,797 Silver AUM Snapshot) | enum_hints |
| Upstream | Live Event rung: `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` filtered for `EventPayloadRowData.ProviderName = 'Moneyfarm'` and event types in (`USER_CASH_ACCOUNT_ACTIVATED`, `PORTFOLIO_DEPOSIT`); Bronze Table rung: `main.general.bronze_moneyfarm_users` (recent users); Silver AUM Snapshot rung: `main.money_farm.silver_moneyfarm_etoro_mf_aum` (back-fill from balance history). Same ladder as the MoneyFarm fact_portfolio_snapshot. | XP/13551468545 + sample correlation |
| Downstream | eToro KPI dashboards, Tableau workbook `main__etoro_kpi` | Tableau index |

## 3. Columns

| # | Column | Type | Tier | Description | Notes & citations | Sample values |
|---|--------|------|------|-------------|-------------------|---------------|
| 0 | `GCID` | LONG | T4 | "eToro Global Customer ID. Primary key. FK to main.bi_db.gold_sub_accounts_accounts.gcid (filter providerName='Moneyfarm'). [uc_sample]" | Sources: UC samples (numeric LONG, eToro gcid space). | `29066999`, `47397446`, `47411560` |
| 1 | `MF_Journey_Beginning` | DATE | T4 | "Earliest date this GCID was observed as a MoneyFarm customer across the Live Event / Bronze / Silver ladder. NOT the eToro account creation date. [uc_sample]" | Sources: UC samples (DATE, e.g. `2026-03-30` clusters). Wiki-only enrichment: when `Date_Source_Type = 'Live Event (New)'` this is typically the date of `USER_CASH_ACCOUNT_ACTIVATED` or first `PORTFOLIO_DEPOSIT`; when `'Bronze Table (Recent)'` it's derived from `bronze_moneyfarm_users`; when `'Silver AUM Snapshot (Legacy)'` it's the earliest `etr_ymd` in `silver_moneyfarm_etoro_mf_aum` for that GCID. The exact derivation per rung is not anchored in Confluence. | `2026-03-30` |
| 2 | `Date_Source_Type` | STRING | T1 | "Provenance flag for MF_Journey_Beginning. Values: 'Live Event (New)' (49189 rows), 'Bronze Table (Recent)' (45270), 'Silver AUM Snapshot (Legacy)' (1797). Live Event = streamed from sub-accounts EH; Silver AUM Snapshot = back-fill from money_farm.silver_moneyfarm_etoro_mf_aum. [Confluence/XP/13551468545]" | Sources: live UC enum_hints + Confluence XP/13551468545 §"General Flow" + §"Rollout Info". Wiki-only enrichment: same three-rung ladder as `bi_output_moneyfarm_fact_portfolio_snapshot.Source_Type` (which uses 2-value subset `Live Event` and `Silver History`). The 3-rung version here adds the "Bronze Table (Recent)" middle rung — likely for users sourced from `bronze_moneyfarm_users` who haven't yet streamed an event. Filter `Date_Source_Type = 'Live Event (New)'` to count newly-acquired MoneyFarm customers from the streaming pipeline. | `Live Event (New)`, `Bronze Table (Recent)`, `Silver AUM Snapshot (Legacy)` |
| 3 | `UpdateDate` | TIMESTAMP | T4 | "Snapshot refresh timestamp (UTC). All rows in a refresh share the same value. [uc_sample]" | Sources: UC samples (`2026-03-31T05:43:12.587Z` shared across the 3-row sample). | `2026-03-31T05:43:12.587Z` |

## 4. Common usage / JOINs

- **MoneyFarm cohort building**: count `GCID` filtered by `Date_Source_Type` to size each provenance cohort. For "newly acquired" cohorts use `'Live Event (New)'` only.
- **Cross-domain bridge**: `GCID` joins to `main.bi_db.gold_sub_accounts_accounts` (filter `providerName='Moneyfarm'`).
- **Companion fact**: `bi_output_moneyfarm_fact_portfolio_snapshot` is keyed on `(GCID, PortfolioID)` and shares the (truncated 2-rung) provenance ladder via its `Source_Type` column.
- **Companion fact**: `bi_output_moneyfarm_fact_transactions` is keyed on per-event UUID and provides the per-event flow detail.

## 5. Gotchas

- The 3-rung ladder here (`Live Event (New)` / `Bronze Table (Recent)` /
  `Silver AUM Snapshot (Legacy)`) is **wider** than the 2-rung ladder on
  `fact_portfolio_snapshot.Source_Type` (`Live Event` / `Silver History`).
  When joining customers→snapshots, don't expect 1:1 source labels. [uc_sample]
- `MF_Journey_Beginning` is NOT a transaction date — it's a derived earliest-
  observation date. Use `bi_output_moneyfarm_fact_transactions.Transaction_Date`
  for actual deposit/withdrawal timing. [uc_sample]
- The bronze rung counts (45k) are surprisingly close to the live-event rung
  (49k), suggesting `bronze_moneyfarm_users` and the live event stream have
  overlapping populations. Don't double-count when SUMing across rungs. [uc_sample]

## 6. UC ALTER provenance

4 column-level COMMENTs + 1 table-level COMMENT. `Date_Source_Type` is
Tier 1 anchored on Confluence XP/13551468545 (the same V2 deposit-event HLD
that anchors the MoneyFarm fact_portfolio_snapshot's `Source_Type`). The other
3 columns are Tier 4 sample-anchored. All 4 are deployed (T4 deploys are
permitted when grounded in samples; this file complies).
