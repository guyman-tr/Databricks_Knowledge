---
object: main.etoro_kpi_prep.v_spaceship_mimo
domain: spaceship
table_type: VIEW
format: null
column_count: 15
row_count: null
generated_at: "2026-05-04T12:40:00Z"
tier_breakdown:
  tier1_columns: 15
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
sources:
  confluence: ["BDP/12918358038", "BG/13131186194", "CS/13335789570"]
  tableau:    ["main__etoro_kpi"]
  databricks: []
  uc_comment: false
---

# v_spaceship_mimo

## 1. What it is

Money-In / Money-Out (MIMO) daily fact view for Spaceship — one row per
`(date, product, is_internal_transfer, user_id)` aggregating gross deposit/
withdrawal flows in AUD across the four Spaceship products (Super, Money,
Voyager, Nova). The view is the canonical Tier-1 source: it is the eToro-
authored CTE pipeline that defines what counts as a deposit vs withdrawal per
product. The mirror view `main.etoro_kpi.v_spaceship_mimo` is a thin
`SELECT * FROM` pass-through and inherits all column semantics from this view.

## 2. Identity & Lineage

| Attribute | Value | Source |
|-----------|-------|--------|
| Full name | `main.etoro_kpi_prep.v_spaceship_mimo` | UC inventory |
| Type | VIEW | `system.information_schema.tables` |
| Format | n/a | `SHOW CREATE TABLE` |
| Owner | analyst-authored, eToro DataPlatform | n/a |
| Row count | n/a (view) | n/a |
| Upstream | `main.spaceship.bronze_spaceship_metabase_super_transactions` (Super), `main.spaceship.bronze_spaceship_analytics_fct_money_transactions` (Money), `main.spaceship.spaceship_metabase_voyager_user_balances` (Voyager — uses `inflow_aud_amount`/`outflow_aud_amount`/`inflow_count`/`outflow_count`), `main.spaceship.bronze_spaceship_metabase_nova_transactions` (Nova), `main.spaceship.bronze_spaceship_metabase_user_beta` (member→user_id; orphan-FTD source: `super_first_became_financial_date`, `voyager_first_became_financial_date`, `nova_first_transaction_at`), `main.spaceship.bronze_spaceship_metabase_contact` (account_id→user_id), `main.bi_db.bronze_sub_accounts_accounts` (GCID, providerName='Spaceship'), `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` (AUD/USD InstrumentID=7) | view DDL |
| Downstream | `main.etoro_kpi.v_spaceship_mimo` (`SELECT *` mirror); Tableau workbooks under `main__etoro_kpi`; eToro KPI dashboards | view DDL + Tableau index |

## 3. Columns

> Tier source: the view DDL itself is the authoritative anchor. Every column's
> meaning is derived **directly from the SELECT clause and CTE rules**, which
> are eToro-authored SQL — Tier 1. Citation tag in `Description` is `[view_def]`.

| # | Column | Type | Tier | Description | Notes & citations | Sample values |
|---|--------|------|------|-------------|-------------------|---------------|
| 0 | `date` | DATE | T1 | "Activity date in Australia/Sydney. Money/Nova use FROM_UTC_TIMESTAMP from UTC. Super uses paid_date; Voyager uses effective_date. [view_def]" | Sources: view DDL CTEs `super_mimo`, `money_mimo`, `voyager_mimo`, `nova_mimo`. Wiki-only enrichment: per-product date sources differ — Super: `CAST(st.paid_date AS DATE)`; Money: `CAST(FROM_UTC_TIMESTAMP(mt.completed_at, 'Australia/Sydney') AS DATE)`; Voyager: `vb.effective_date` (already date); Nova: `CAST(FROM_UTC_TIMESTAMP(nt.order_filled_at, 'Australia/Sydney') AS DATE)`. The 2024-05-18 SFT one-off is excluded for Super (`CAST(st.paid_date AS DATE) <> DATE '2024-05-18'`). | `2025-12-31`, `2026-04-07` |
| 1 | `date_id` | INT | T1 | "Date in YYYYMMDD integer format for partition-friendly filtering. Equals CAST(DATE_FORMAT(date,'yyyyMMdd') AS INT). [view_def]" | Sources: view DDL final SELECT (`CAST(DATE_FORMAT(m.date, 'yyyyMMdd') AS INT) AS date_id`). Wiki-only enrichment: prefer `date_id = 20251231` over `date = '2025-12-31'`. | `20251231`, `20260407` |
| 2 | `product` | STRING | T1 | "Spaceship product. Values: Super, Money, Voyager, Nova. Each has distinct deposit/withdrawal rules in the source CTEs. [view_def]" | Sources: view DDL — 4 product CTEs (`super_mimo`, `money_mimo`, `voyager_mimo`, `nova_mimo`) UNION ALL'd in `mimo_aggregated`. Wiki-only enrichment: orphan-FTD synthesis can also populate `product` from `first_deposit_dates.ftd_product` (Super | Voyager | Nova) when a user's FTD date is in `user_beta` but no transaction row exists for that date — these rows have all amounts = 0 and `is_ftd = TRUE`. | `Super`, `Money`, `Voyager`, `Nova` |
| 3 | `is_internal_transfer` | BOOLEAN | T1 | "TRUE for moves inside Spaceship (Voyager/Nova purchases, Super pension events, etc.); FALSE only for true external wallet inflow/outflow (Money: USER_DEPOSIT/USER_WITHDRAWAL/etc.). [view_def]" | Sources: view DDL — Money CTE only flags as FALSE for the explicit external whitelist (`USER_DEPOSIT`, `USER_WITHDRAWAL`, their reversals, plus Nova fees/dividend/M&A). Super is hard-coded FALSE (Contributions are external by definition). Voyager and Nova are hard-coded TRUE (intra-platform purchases/sales). Wiki-only enrichment: when computing **net external** flow, filter `is_internal_transfer = FALSE`. When computing **gross product activity**, ignore the flag. | `false` (external Money), `true` (internal) |
| 4 | `user_id` | STRING | T1 | "Canonical Spaceship user_id. UUID v4 from Spaceship Metabase. Resolved via member_canonical for Super and contact_mapping for Money. [view_def]" | Sources: view DDL CTEs `member_canonical`, `contact_mapping`, `user_id_map`. Wiki-only enrichment: dedup logic = lowest user_id per member_id. For Super, falls back to `st.member_id` if no canonical user_id is found. UUID format (8-4-4-4-12 with hyphens). | `62a59e09-71d2-4c12-b8a9-70a1d9e34225` |
| 5 | `gcid` | LONG | T1 | "eToro Global Customer ID from sub_accounts (providerName='Spaceship'). NULL when the user is Spaceship-only (no eToro cross-sell). [view_def]" | Sources: view DDL CTE `user_gcid` joining `bi_db.bronze_sub_accounts_accounts` to `bronze_spaceship_metabase_contact` on `accountId = c.user_id`. Wiki-only enrichment: NULL is the dominant value (Spaceship-only customers). FK to `main.bi_db.gold_sub_accounts_accounts.gcid`. | NULL, `2468109`, `45090849` |
| 6 | `total_deposits_aud` | DOUBLE | T1 | "Sum of deposit amounts in AUD for (date, product, user_id). Per-product rules: Super=Contributions/Tax; Money=USER_DEPOSIT family; Voyager=inflow_aud_amount; Nova=BUY trades. [view_def]" | Sources: view DDL CTEs (each product's `deposit_amount` CASE) + `mimo_aggregated.SUM(deposit_amount)`. Wiki-only enrichment: Voyager uses `inflow_aud_amount` directly from `voyager_user_balances`. Nova: `BUY` direction only, on `order_status IN ('FINALISED','EXECUTED','PAYMENT_INITIATED')`. Money excludes status `('CANCELLED','FAILED','REJECTED')` and `transaction_direction NOT IN ('CREDIT','DEBIT')`. Orphan-FTD rows have 0.0. | `0.0`, `2.999999983`, `1500.00` |
| 7 | `total_withdrawals_aud` | DOUBLE | T1 | "Sum of withdrawal amounts in AUD (positive). Per-product: Super=Benefit/Fees/Tax/Premium; Money=USER_WITHDRAWAL family; Voyager=outflow_aud_amount; Nova=SELL trades. [view_def]" | Sources: view DDL CTEs + `mimo_aggregated`. Wiki-only enrichment: Super excludes 'Contributions Tax' from withdrawals (it's classified as deposit). Money's withdrawal whitelist includes Nova fees (`NOVA_TAF_FEE`, `NOVA_REG_FEE`, `NOVA_MONTHLY_FEE`). Withdrawal amounts are stored as positive (ABS in CTEs). Orphan-FTD rows have 0.0. | `0.0`, `2.999999983`, `500.00` |
| 8 | `net_flow_aud` | DOUBLE | T1 | "total_deposits_aud - total_withdrawals_aud for (date, product, user_id). Negative when withdrawals exceed deposits. [view_def]" | Sources: view DDL `SUM(deposit_amount) - SUM(withdrawal_amount)` in `mimo_aggregated`. | `-2.999999983`, `1000.00` |
| 9 | `total_deposits_usd` | DOUBLE | T1 | "total_deposits_aud × COALESCE(AUD/USD mid-rate, 0). Rate from fact_currencypricewithsplit InstrumentID=7. Missing rate → 0.0. [view_def]" | Sources: view DDL `total_deposits * COALESCE(r.aud_to_usd_rate, 0)` joined on `m.date = r.rate_date`. Wiki-only enrichment: AUD/USD mid-rate = (Ask+Bid)/2. Same InstrumentID=7 used in v_spaceship_aum and v_spaceship_fees. | `0.0`, `2.122904987970205` |
| 10 | `total_withdrawals_usd` | DOUBLE | T1 | "total_withdrawals_aud × COALESCE(AUD/USD mid-rate, 0). [view_def]" | Sources: view DDL final SELECT. | `0.0`, `2.122904987970205` |
| 11 | `net_flow_usd` | DOUBLE | T1 | "net_flow_aud × COALESCE(AUD/USD mid-rate, 0). Sign-preserving USD net flow. [view_def]" | Sources: view DDL final SELECT. | `-2.122904987970205`, `0.0` |
| 12 | `count_deposits` | LONG | T1 | "Count of deposit events for (date, product, user_id). Per-product is_deposit flags rolled up via SUM. [view_def]" | Sources: view DDL CTEs `is_deposit` + `mimo_aggregated.SUM(is_deposit)`. Wiki-only enrichment: For Voyager this uses `inflow_count` from `voyager_user_balances`; for the other 3 products it sums 1-or-0 flags per qualifying transaction. Orphan-FTD rows = 0. | `0`, `1`, `5` |
| 13 | `count_withdrawals` | LONG | T1 | "Count of withdrawal events for (date, product, user_id). [view_def]" | Sources: view DDL CTEs `is_withdrawal` + `mimo_aggregated.SUM(is_withdrawal)`. | `0`, `1`, `3` |
| 14 | `is_ftd` | BOOLEAN | T1 | "TRUE on a user's first-deposit date (any product, MIN per user). Includes orphan-FTD rows synthesised from user_beta when no transaction row exists for the FTD date. [view_def]" | Sources: view DDL CTE `first_deposit_dates` (computes MIN per user from `super_first_became_financial_date`, `voyager_first_became_financial_date`, `nova_first_transaction_at`) + `mimo_final` UNION-ALL of `mimo_aggregated` and orphan-FTD rows. Wiki-only enrichment: orphan-FTD synthesis = "user_beta says FTD was on date D for product P, but no actual transaction row exists in our fact CTEs for that (user, date)" — these rows get all amounts = 0 and `_is_orphan_ftd = TRUE` internally, surfaced as `is_ftd = TRUE`. Use this column for FTD cohort dashboards regardless of fact-table coverage. | `true`, `false` |

## 4. Common usage / JOINs

- **Mirror view**: `main.etoro_kpi.v_spaceship_mimo` is `SELECT * FROM main.etoro_kpi_prep.v_spaceship_mimo` (verbatim pass-through). Wiki at `../../etoro_kpi/Views/v_spaceship_mimo.md`.
- **Tableau coverage**: `main__etoro_kpi` MIMO dashboards filter `is_ftd = TRUE` for FTD funnels and `is_internal_transfer = FALSE` for true money-in/money-out.
- **Cross-domain bridge**: join on `gcid` (when non-NULL) to eToro DWH facts to roll Spaceship MIMO into eToro panels.

## 5. Gotchas

- Per-product **date semantics differ**: Money and Nova convert UTC→Sydney; Super uses raw `paid_date`; Voyager uses raw `effective_date`. [view_def]
- The 2024-05-18 SFT (Successor Fund Transfer) one-off is **excluded** for Super (`CAST(st.paid_date AS DATE) <> DATE '2024-05-18'`). [view_def]
- **Orphan-FTD rows** can show `is_ftd = TRUE` on a date with `total_deposits_aud = 0`. This is intentional — it preserves the user's actual FTD date from `user_beta` even when the fact tables don't carry the corresponding transaction. Filter them out via `total_deposits_aud > 0` if you only want fact-anchored FTDs. [view_def]
- `is_internal_transfer = TRUE` for ALL Voyager and Nova rows — those are intra-platform investment moves, not external wallet flows. Only Money rows have a mix of TRUE/FALSE based on transaction_type whitelist. [view_def]
- Voyager flow uses **count fields directly** from `voyager_user_balances` (`inflow_count`, `outflow_count`); other products synthesize 0/1 flags per row. This means a single Voyager-balance row can contribute >1 to `count_deposits`. [view_def]
- AUD/USD rate is `COALESCE(rate, 0)` — a date with no rate row produces USD = 0.0, not NULL. Always check `total_deposits_aud > 0 AND total_deposits_usd = 0` to detect missing rate rows. [view_def]

## 6. UC ALTER provenance

The companion `.alter.sql` emits 1 view-level COMMENT + 15 column-level
`ALTER VIEW ... ALTER COLUMN ... COMMENT '...'` statements. Every comment text
is the `Description` column from Section 3 verbatim. Tier source is the view
DDL itself (eToro-authored SQL, Tier 1). All 15 columns are anchored to
specific CTEs / SELECT-clause expressions in the view definition; no UNVERIFIED
columns. The `[view_def]` citation tag indicates the source is the live view
DDL accessible via `SHOW CREATE TABLE main.etoro_kpi_prep.v_spaceship_mimo`.
