---
object: main.etoro_kpi.v_spaceship_mimo
domain: spaceship
table_type: VIEW
format: null
column_count: 15
row_count: null
generated_at: "2026-05-04T12:42:00Z"
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
  pass_through_of: "main.etoro_kpi_prep.v_spaceship_mimo"
---

# v_spaceship_mimo (etoro_kpi mirror)

## 1. What it is

`SELECT * FROM main.etoro_kpi_prep.v_spaceship_mimo` — verbatim pass-through.
This view's only purpose is to expose `etoro_kpi_prep.v_spaceship_mimo` under
the `etoro_kpi` schema where most consumer-facing dashboards point. There is
**no transformation** here; column meanings are identical to the prep view.

## 2. Identity & Lineage

| Attribute | Value | Source |
|-----------|-------|--------|
| Full name | `main.etoro_kpi.v_spaceship_mimo` | UC inventory |
| Type | VIEW | `system.information_schema.tables` |
| Format | n/a | `SHOW CREATE TABLE` |
| Owner | analyst-authored, eToro DataPlatform | n/a |
| Row count | n/a | n/a |
| Upstream | `main.etoro_kpi_prep.v_spaceship_mimo` (`SELECT *` pass-through) | view DDL |
| Downstream | Tableau workbooks under `main__etoro_kpi`; eToro KPI dashboards | Tableau index |

## 3. Columns

> Source semantics are inherited verbatim from the prep view. The `Description`
> texts deployed here are the same byte-for-byte as the prep view's so a single
> source of truth lives upstream and the mirror's UC comments stay aligned.
> See `../../etoro_kpi_prep/Views/v_spaceship_mimo.md` for `Notes & citations`.

| # | Column | Type | Tier | Description | Sample values |
|---|--------|------|------|-------------|---------------|
| 0 | `date` | DATE | T1 | "Activity date in Australia/Sydney. Money/Nova use FROM_UTC_TIMESTAMP from UTC. Super uses paid_date; Voyager uses effective_date. [view_def]" | `2025-12-31` |
| 1 | `date_id` | INT | T1 | "Date in YYYYMMDD integer format for partition-friendly filtering. Equals CAST(DATE_FORMAT(date,'yyyyMMdd') AS INT). [view_def]" | `20251231` |
| 2 | `product` | STRING | T1 | "Spaceship product. Values: Super, Money, Voyager, Nova. Each has distinct deposit/withdrawal rules in the source CTEs. [view_def]" | `Voyager` |
| 3 | `is_internal_transfer` | BOOLEAN | T1 | "TRUE for moves inside Spaceship (Voyager/Nova purchases, Super pension events, etc.); FALSE only for true external wallet inflow/outflow (Money: USER_DEPOSIT/USER_WITHDRAWAL/etc.). [view_def]" | `true` |
| 4 | `user_id` | STRING | T1 | "Canonical Spaceship user_id. UUID v4 from Spaceship Metabase. Resolved via member_canonical for Super and contact_mapping for Money. [view_def]" | `62a59e09-71d2-4c12-b8a9-70a1d9e34225` |
| 5 | `gcid` | LONG | T1 | "eToro Global Customer ID from sub_accounts (providerName='Spaceship'). NULL when the user is Spaceship-only (no eToro cross-sell). [view_def]" | NULL |
| 6 | `total_deposits_aud` | DOUBLE | T1 | "Sum of deposit amounts in AUD for (date, product, user_id). Per-product rules: Super=Contributions/Tax; Money=USER_DEPOSIT family; Voyager=inflow_aud_amount; Nova=BUY trades. [view_def]" | `0.0` |
| 7 | `total_withdrawals_aud` | DOUBLE | T1 | "Sum of withdrawal amounts in AUD (positive). Per-product: Super=Benefit/Fees/Tax/Premium; Money=USER_WITHDRAWAL family; Voyager=outflow_aud_amount; Nova=SELL trades. [view_def]" | `2.999999983` |
| 8 | `net_flow_aud` | DOUBLE | T1 | "total_deposits_aud - total_withdrawals_aud for (date, product, user_id). Negative when withdrawals exceed deposits. [view_def]" | `-2.999999983` |
| 9 | `total_deposits_usd` | DOUBLE | T1 | "total_deposits_aud × COALESCE(AUD/USD mid-rate, 0). Rate from fact_currencypricewithsplit InstrumentID=7. Missing rate → 0.0. [view_def]" | `0.0` |
| 10 | `total_withdrawals_usd` | DOUBLE | T1 | "total_withdrawals_aud × COALESCE(AUD/USD mid-rate, 0). [view_def]" | `2.122904987970205` |
| 11 | `net_flow_usd` | DOUBLE | T1 | "net_flow_aud × COALESCE(AUD/USD mid-rate, 0). Sign-preserving USD net flow. [view_def]" | `-2.122904987970205` |
| 12 | `count_deposits` | LONG | T1 | "Count of deposit events for (date, product, user_id). Per-product is_deposit flags rolled up via SUM. [view_def]" | `0` |
| 13 | `count_withdrawals` | LONG | T1 | "Count of withdrawal events for (date, product, user_id). [view_def]" | `1` |
| 14 | `is_ftd` | BOOLEAN | T1 | "TRUE on a user's first-deposit date (any product, MIN per user). Includes orphan-FTD rows synthesised from user_beta when no transaction row exists for the FTD date. [view_def]" | `false` |

## 4. Common usage / JOINs

Identical to the prep view. Most consumers (Tableau, Genie) reference this
mirror, not the prep version, because `etoro_kpi.*` is the conventional
analyst-facing schema.

## 5. Gotchas

All gotchas from the prep view apply unchanged. See
`../../etoro_kpi_prep/Views/v_spaceship_mimo.md §5` for the full list.

## 6. UC ALTER provenance

The companion `.alter.sql` deploys the same `Description` text as the prep
view's ALTER, byte-for-byte. This keeps both copies of the UC comments
aligned — re-deploying either is a guaranteed no-op against the other once
both are deployed. Maintenance contract: when the prep view's column
descriptions change, this mirror must be kept in lock-step.
