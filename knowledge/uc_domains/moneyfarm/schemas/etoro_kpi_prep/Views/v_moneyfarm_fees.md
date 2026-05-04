---
object: main.etoro_kpi_prep.v_moneyfarm_fees
domain: moneyfarm
table_type: VIEW
format: null
column_count: 5
row_count: 0
generated_at: "2026-05-04T12:57:00Z"
tier_breakdown:
  tier1_columns: 5
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
sources:
  confluence: ["XP/13551468545", "XP/12216961926", "MG/13600227427"]
  tableau:    ["main__etoro_kpi"]
  databricks: []
  uc_comment: true
status: PLACEHOLDER
---

# v_moneyfarm_fees

## 1. What it is

**Empty placeholder view** for MoneyFarm fee facts. The view definition is
intentionally `WHERE 1=0` so the view exists with the documented schema but
returns 0 rows — the SQL body carries an inline comment from the author:
`-- this is currently a placeholder, no fee logic exists yet`. Granularity
target (when populated): one row per `(date, gcid)` of fee revenue. The
table-level UC comment (analyst-authored, 159 chars) is preserved verbatim.

## 2. Identity & Lineage

| Attribute | Value | Source |
|-----------|-------|--------|
| Full name | `main.etoro_kpi_prep.v_moneyfarm_fees` | UC inventory |
| Type | VIEW (PLACEHOLDER — `WHERE 1=0`) | view DDL |
| Format | n/a | n/a |
| Owner | analyst-authored, eToro DataPlatform (placeholder pending fee logic) | n/a |
| Row count | 0 (always — until fee logic is implemented) | view DDL |
| Upstream | None — view body is `SELECT NULLs WHERE 1=0`. Future: likely a MoneyFarm fee event stream (analogous to the V2 deposit-event HLD) once defined. | view DDL |
| Downstream | Tableau `main__etoro_kpi` (will surface 0-row data); future eToro KPI fee dashboards | Tableau index |

## 3. Columns

> All 5 columns are NULL in every row (placeholder). Tier source is the view
> DDL — the column types and intended semantics come directly from the
> CAST'd NULL definitions in the SELECT. Citation tag `[view_def]`.

| # | Column | Type | Tier | Description | Notes & citations | Sample values |
|---|--------|------|------|-------------|-------------------|---------------|
| 0 | `date` | DATE | T1 | "Activity date for the fee event. PLACEHOLDER (always NULL until fee logic is implemented). [view_def]" | Sources: view DDL `CAST(NULL AS DATE) AS date`. Wiki-only enrichment: when fee logic lands, this will likely match the event-date convention used by other MoneyFarm views (`etr_ymd` from silver, or event `CreatedAt` UTC from the EH stream). | NULL |
| 1 | `dateid` | INT | T1 | "Date in YYYYMMDD integer format. PLACEHOLDER (always NULL). [view_def]" | Sources: view DDL `CAST(NULL AS INT) AS dateid`. | NULL |
| 2 | `gcid` | LONG | T1 | "eToro Global Customer ID at fee-event time. PLACEHOLDER (always NULL). FK to main.bi_db.gold_sub_accounts_accounts.gcid (providerName='Moneyfarm') once populated. [view_def]" | Sources: view DDL `CAST(NULL AS BIGINT) AS gcid`. | NULL |
| 3 | `total_fees_gbp` | DOUBLE | T1 | "Sum of fee amounts in GBP for (date, gcid). PLACEHOLDER (always NULL). [view_def]" | Sources: view DDL `CAST(NULL AS DOUBLE) AS total_fees_gbp`. Wiki-only enrichment: the table-level COMMENT mentions a column named `fee_amount` in its example query, which doesn't exist on this view — the example was written against the future schema. | NULL |
| 4 | `total_fees_usd` | DOUBLE | T1 | "total_fees_gbp × GBP/USD mid-rate. PLACEHOLDER (always NULL). [view_def]" | Sources: view DDL. Once populated, will use the same `fact_currencypricewithsplit` InstrumentID=2 mid-rate as `v_moneyfarm_aum.total_balance_usd`. | NULL |

## 4. Common usage / JOINs

Currently no usable rows. Consumers should NOT depend on this view producing
non-empty results until the fee logic is implemented. When populated, expected
joins:

- `gcid + date` to `v_moneyfarm_aum` for fee-revenue-vs-balance dashboards
- `gcid + date` to `v_moneyfarm_mimo` for fee-vs-MIMO panels
- `gcid` to `bi_output_moneyfarm_customers` for cohort splits

## 5. Gotchas

- **The view is a placeholder** — every column is `CAST(NULL AS …) WHERE 1=0`.
  No rows. This is intentional; the view exists as a schema reservation. The
  inline SQL comment (`-- this is currently a placeholder, no fee logic
  exists yet`) is the author's note. [view_def]
- The view-level table COMMENT example query (`SELECT SUM(fee_amount) ...`)
  references a column `fee_amount` that does NOT exist on the current view
  schema (`total_fees_gbp` / `total_fees_usd`). The example anticipates a
  future schema; treat it as forward-looking. [uc_comment vs view_def]
- All 5 columns are typed but always NULL. `LENGTH(comment)` on
  `system.information_schema.columns` will be 0 until this ALTER deploys.

## 6. UC ALTER provenance

The companion `.alter.sql` re-states the live UC view-level COMMENT verbatim
(preservation) and emits 5 new column-level COMMENTs grounded in the view DDL
(`[view_def]` Tier 1). All 5 columns are deployed. Each comment text
explicitly notes the PLACEHOLDER status so agents reading
`system.information_schema` won't be confused by the empty result set.
