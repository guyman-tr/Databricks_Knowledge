---
object: main.etoro_kpi_prep.v_moneyfarm_aum
domain: moneyfarm
table_type: VIEW
format: null
column_count: 7
row_count: null
generated_at: "2026-05-04T12:55:00Z"
tier_breakdown:
  tier1_columns: 7
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
---

# v_moneyfarm_aum

## 1. What it is

Daily per-GCID Assets Under Management (FUM) view for MoneyFarm — one row per
`(date, gcid)` summing GBP market value across **all** of a customer's
MoneyFarm portfolios. The view also produces a USD denomination via the
GBP/USD mid-rate, and an `is_funded` flag (`total_balance_gbp > 0`). Source of
truth is the `silver_moneyfarm_etoro_mf_aum` daily AUM ladder in
`main.money_farm` — i.e. the back-fill ladder, NOT the live event stream.

## 2. Identity & Lineage

| Attribute | Value | Source |
|-----------|-------|--------|
| Full name | `main.etoro_kpi_prep.v_moneyfarm_aum` | UC inventory |
| Type | VIEW | `system.information_schema.tables` |
| Format | n/a | `SHOW CREATE TABLE` |
| Owner | analyst-authored, eToro DataPlatform | n/a |
| Row count | n/a (view) | n/a |
| Upstream | `main.money_farm.silver_moneyfarm_etoro_mf_aum` (daily snapshot ladder, columns `etr_ymd`, `GCID`, `Portfolio_Id`, `Product`, `Market_Value`); `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` filtered on `InstrumentID = 2` for GBP/USD mid-rate | view DDL |
| Downstream | Tableau `main__etoro_kpi`; eToro KPI dashboards | Tableau index |

## 3. Columns

> Tier source: the view DDL is eToro-authored SQL — Tier 1 anchor. Citation
> tag in `Description` is `[view_def]`. The view-level table COMMENT is also
> analyst-authored (200 chars) and is preserved verbatim in the deployed
> table-level COMMENT.

| # | Column | Type | Tier | Description | Notes & citations | Sample values |
|---|--------|------|------|-------------|-------------------|---------------|
| 0 | `date` | DATE | T1 | "Snapshot date from silver_moneyfarm_etoro_mf_aum.etr_ymd. One row per (date, GCID) — all of a customer's portfolios are summed for the day. [view_def]" | Sources: view DDL CTE `daily_portfolio_balances` (`etr_ymd AS date`). Wiki-only enrichment: `etr_ymd` is the eToro-side daily ladder timestamp; the silver table is a daily back-fill, not the live stream — so this view trails the live event hub by the silver pipeline cadence. | `2026-04-23`, `2026-04-12` |
| 1 | `dateid` | INT | T1 | "Date in YYYYMMDD integer format. CAST(DATE_FORMAT(date,'yyyyMMdd') AS INT). Prefer for partition-friendly filtering. [view_def]" | Sources: view DDL final SELECT. Note this view names it `dateid` (lowercase, no underscore) while the Spaceship views use `date_id` — keep consistent in cross-domain queries. | `20260423`, `20260412` |
| 2 | `gcid` | INT | T1 | "eToro Global Customer ID. Filtered NOT NULL upstream (GCID IS NOT NULL in CTE). FK to main.bi_db.gold_sub_accounts_accounts.gcid (providerName='Moneyfarm'). [view_def]" | Sources: view DDL CTE `daily_portfolio_balances WHERE GCID IS NOT NULL`. Wiki-only enrichment: source column type is INT, not LONG (different from bi_output_moneyfarm_* facts which use LONG). | `33920009`, `6754779`, `26777932` |
| 3 | `total_balance_gbp` | DOUBLE | T1 | "Sum of Market_Value across all the GCID's portfolios for the date, in GBP. From silver_moneyfarm_etoro_mf_aum. [view_def]" | Sources: view DDL CTE `aggregated_balances.SUM(market_value)`. Wiki-only enrichment: `Market_Value` is cast to DOUBLE upstream; 0.0 indicates a customer enrolled in MoneyFarm but holding no balance for that day. | `33647.62`, `0.0` |
| 4 | `total_balance_usd` | DOUBLE | T1 | "total_balance_gbp × COALESCE(GBP/USD mid-rate, 0). Mid-rate from fact_currencypricewithsplit InstrumentID=2 ((Ask+Bid)/2). Missing rate → 0.0. [view_def]" | Sources: view DDL CTE `gbp_usd_rates` + final SELECT. Wiki-only enrichment: NOTE — Spaceship uses InstrumentID=7 (AUD/USD), MoneyFarm uses InstrumentID=2 (GBP/USD). Don't confuse the InstrumentIDs across domains. | `45309.21213960001`, `0.0` |
| 5 | `is_funded` | BOOLEAN | T1 | "TRUE when total_balance_gbp > 0. Aligned with eToro DDR's IsFunded semantic. [view_def]" | Sources: view DDL final SELECT (`CASE WHEN total_balance_gbp > 0 THEN TRUE ELSE FALSE END`). | `true`, `false` |
| 6 | `portfolio_count` | LONG | T1 | "Distinct PortfolioID count for (date, GCID). One GCID can hold multiple MoneyFarm portfolios concurrently (e.g. Managed ISA + DIY ISA + Cash ISA). [view_def]" | Sources: view DDL CTE `aggregated_balances.COUNT(DISTINCT PortfolioID)`. Wiki-only enrichment: typical sample shows `portfolio_count = 1`, but customers with multiple ISA wrappers can have higher counts. The product-name dimension itself is not preserved in this view — see `bi_output_moneyfarm_fact_portfolio_snapshot.Product_Name` for per-portfolio product. | `1` |

## 4. Common usage / JOINs

- **Customer-level AUM dashboard**: directly query this view filtered by `dateid`. For trend lines, group by `date` and SUM `total_balance_gbp`/`total_balance_usd`.
- **Cross-domain bridge**: `gcid` joins to `main.bi_db.gold_sub_accounts_accounts` for cross-sell roll-ups.
- **Per-portfolio drill-down**: `bi_output.bi_output_moneyfarm_fact_portfolio_snapshot` (one row per `(GCID, PortfolioID)`) is the next-level grain; join on `gcid + date` for date-aligned reconciliation.
- **Funded cohort**: filter `is_funded = TRUE` for active-investing customer counts.

## 5. Gotchas

- This view uses the **back-fill ladder** (`silver_moneyfarm_etoro_mf_aum`),
  NOT the live event stream. There is a cadence lag relative to the
  `bi_output_moneyfarm_fact_transactions` event-level fact. [view_def]
- `total_balance_usd = 0.0` does NOT mean "zero balance" — check
  `total_balance_gbp` first. The USD value is forced to 0.0 when the
  GBP/USD rate row is missing for the date (`COALESCE(rate, 0)`). [view_def]
- The view-level COMMENT (200 chars, analyst-authored) is preserved verbatim
  in the deployed table COMMENT — the example query in it
  (`WHERE date_id = 20251231`) uses `date_id` which is the column
  spelling used by Spaceship views, but **this view's column is named
  `dateid`** without the underscore. Treat the example as illustrative;
  the deployed column is `dateid`. [uc_comment vs view_def]

## 6. UC ALTER provenance

The companion `.alter.sql` re-states the live UC view-level COMMENT verbatim
(preservation) and emits 7 new column-level COMMENTs grounded in the view DDL
(`[view_def]` Tier 1). All 7 columns are deployed. The view-level COMMENT is
preserved byte-for-byte to keep re-deploys idempotent.
