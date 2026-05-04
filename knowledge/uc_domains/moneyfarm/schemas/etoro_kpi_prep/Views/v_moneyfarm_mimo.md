---
object: main.etoro_kpi_prep.v_moneyfarm_mimo
domain: moneyfarm
table_type: VIEW
format: null
column_count: 12
row_count: null
generated_at: "2026-05-04T13:00:00Z"
tier_breakdown:
  tier1_columns: 12
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

# v_moneyfarm_mimo

## 1. What it is

Money-In / Money-Out (MIMO) daily fact view for MoneyFarm — one row per
`(date, gcid)` aggregating gross deposits and withdrawals from the live
sub-accounts event-hub MoneyFarm stream. Source: filters
`compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` for
`ProviderName = 'Moneyfarm'` and event types
`('PORTFOLIO_DEPOSIT','PORTFOLIO_WITHDRAW')`, parses event JSON, aggregates by
day. Adds `is_ftd` (first-deposit-date marker per GCID), GBP/USD conversion
via `fact_currencypricewithsplit` InstrumentID=2, and per-direction event
counts. The view-level UC COMMENT is analyst-authored (165 chars) and
preserved verbatim.

## 2. Identity & Lineage

| Attribute | Value | Source |
|-----------|-------|--------|
| Full name | `main.etoro_kpi_prep.v_moneyfarm_mimo` | UC inventory |
| Type | VIEW | UC inventory |
| Format | n/a | n/a |
| Owner | analyst-authored, eToro DataPlatform | n/a |
| Row count | n/a | n/a |
| Upstream | `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` (filtered `ProviderName='Moneyfarm'` and `EventType IN ('PORTFOLIO_DEPOSIT','PORTFOLIO_WITHDRAW')`); `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` (InstrumentID=2 GBP/USD) | view DDL |
| Downstream | Tableau `main__etoro_kpi`; eToro KPI MIMO panels; per-event detail in `bi_output.bi_output_moneyfarm_fact_transactions` (one row per event, this view aggregates to day-grain) | view DDL + Tableau index |

## 3. Columns

> Tier source: view DDL is the eToro-authored Tier 1 anchor. Citation tag
> `[view_def]`. Column comments are written grounded in the explicit SELECT-
> clause expressions and CTE rules.

| # | Column | Type | Tier | Description | Notes & citations | Sample values |
|---|--------|------|------|-------------|-------------------|---------------|
| 0 | `date` | DATE | T1 | "Event date in UTC. From CAST(SUBSTRING(EventMetadata.CreatedAt, 1, 10) AS DATE). [view_def]" | Sources: view DDL CTE `parsed_events.date`. Wiki-only enrichment: this is event-CreatedAt UTC truncated to date — there is NO timezone conversion (unlike Spaceship's MIMO which converts UTC→Sydney). MoneyFarm operates in GBP/UK so UTC is close enough to UK time most of the year. The settlement `value_date` is parsed as a separate field in the same CTE but is NOT surfaced in the final SELECT. | `2025-12-31`, `2026-04-12` |
| 1 | `dateid` | INT | T1 | "Date in YYYYMMDD integer format. CAST(DATE_FORMAT(date,'yyyyMMdd') AS INT). [view_def]" | Sources: view DDL final SELECT. Note `dateid` (lowercase, no underscore) consistent with other moneyfarm views. | `20251231` |
| 2 | `gcid` | INT | T1 | "eToro Global Customer ID from EventPayloadRowData.EventMetadata.Gcid (filtered NOT NULL upstream). FK to main.bi_db.gold_sub_accounts_accounts.gcid (providerName='Moneyfarm'). [view_def]" | Sources: view DDL CTE `raw_events.GCID`. | `33920009` |
| 3 | `total_deposits_gbp` | DOUBLE | T1 | "Sum of PORTFOLIO_DEPOSIT amounts (positive) for (date, gcid) in GBP. From event_data_json $.data.amount when amount > 0 AND event_type = 'PORTFOLIO_DEPOSIT'. [view_def]" | Sources: view DDL CTE `mimo_daily.total_deposits` (`SUM(CASE WHEN event_type = 'PORTFOLIO_DEPOSIT' AND amount > 0 THEN amount ELSE 0 END)`). | `0.0`, `1500.00` |
| 4 | `total_withdrawals_gbp` | DOUBLE | T1 | "Sum of PORTFOLIO_WITHDRAW amounts (ABS, positive) for (date, gcid) in GBP. Source amounts are negative; the view stores them as positive. [view_def]" | Sources: view DDL CTE `mimo_daily.total_withdrawals` (`SUM(CASE WHEN event_type = 'PORTFOLIO_WITHDRAW' AND amount < 0 THEN ABS(amount) ELSE 0 END)`). Wiki-only enrichment: source events use negative amounts for withdrawals; this view normalises to positive for SUM-friendly aggregation. | `0.0`, `500.00` |
| 5 | `net_flow_gbp` | DOUBLE | T1 | "total_deposits_gbp - total_withdrawals_gbp. Negative when withdrawals exceed deposits. [view_def]" | Sources: view DDL final SELECT. | `1000.00`, `-500.00` |
| 6 | `total_deposits_usd` | DOUBLE | T1 | "total_deposits_gbp × COALESCE(GBP/USD mid-rate, 0). Mid-rate from fact_currencypricewithsplit InstrumentID=2 ((Ask+Bid)/2). Missing rate → 0.0. [view_def]" | Sources: view DDL CTE `gbp_usd_rates`. | `0.0`, `2034.55` |
| 7 | `total_withdrawals_usd` | DOUBLE | T1 | "total_withdrawals_gbp × COALESCE(GBP/USD mid-rate, 0). [view_def]" | Sources: view DDL final SELECT. | `0.0`, `678.18` |
| 8 | `net_flow_usd` | DOUBLE | T1 | "net_flow_gbp × COALESCE(GBP/USD mid-rate, 0). Sign-preserving USD net flow. [view_def]" | Sources: view DDL final SELECT. | `1356.36` |
| 9 | `count_deposits` | LONG | T1 | "Count of PORTFOLIO_DEPOSIT events for (date, gcid). [view_def]" | Sources: view DDL CTE `mimo_daily.count_deposits` (`SUM(CASE WHEN event_type = 'PORTFOLIO_DEPOSIT' AND amount > 0 THEN 1 ELSE 0 END)`). | `0`, `1`, `3` |
| 10 | `count_withdrawals` | LONG | T1 | "Count of PORTFOLIO_WITHDRAW events for (date, gcid). [view_def]" | Sources: view DDL CTE `mimo_daily.count_withdrawals`. | `0`, `1` |
| 11 | `is_ftd` | BOOLEAN | T1 | "TRUE on a GCID's first-deposit date (MIN(date) where total_deposits > 0). Computed via the first_deposit_dates CTE. [view_def]" | Sources: view DDL CTE `first_deposit_dates` (`MIN(date) FROM mimo_daily WHERE total_deposits > 0 GROUP BY GCID`). Wiki-only enrichment: unlike Spaceship's MIMO which has orphan-FTD synthesis, MoneyFarm's FTD is anchored entirely on the event stream — there is no back-fill from a profile table. So `is_ftd = TRUE` always coincides with `total_deposits_gbp > 0`. | `true`, `false` |

## 4. Common usage / JOINs

- **Daily MIMO panel**: directly query this view filtered by `dateid`. For trend lines, group by `date`.
- **Per-event detail**: `bi_output.bi_output_moneyfarm_fact_transactions` is the per-event grain (one row per `event_correlation_ID`); join on `gcid + date` for date-level reconciliation.
- **AUM cross-check**: `v_moneyfarm_aum` (silver-back-fill ladder, `gcid + date`) for balance vs. flow joins. Note the cadence difference — MIMO is live-stream; AUM is silver back-fill.
- **Cross-domain bridge**: `gcid` to eToro DWH (`gold_sub_accounts_accounts`).
- **FTD cohort**: filter `is_ftd = TRUE` for first-deposit dashboards.

## 5. Gotchas

- **No timezone conversion** — `date` is event `CreatedAt` UTC truncated.
  Spaceship's MIMO converts UTC→Sydney; MoneyFarm does not. Cross-domain
  panels need to handle this difference. [view_def]
- **`Full Withdrawal` events are NOT distinguished here** — the upstream EH
  stream has only `PORTFOLIO_WITHDRAW` (no separate full-withdrawal event
  type), so this view aggregates them into `total_withdrawals_gbp` /
  `count_withdrawals` together. The 3-value `TransactionType` enum
  (Deposit / Withdrawal / Full Withdrawal) lives only on
  `bi_output_moneyfarm_fact_transactions`, not on this aggregate. [view_def]
- The view's filter requires `ProviderName='Moneyfarm'` (capital M, single
  word). Don't use `ProviderName='MoneyFarm'` — the source events store the
  single-word lowercase variant. [view_def]
- USD = 0.0 when GBP/USD rate row is missing for the date. Always check
  `total_deposits_gbp > 0 AND total_deposits_usd = 0` to detect missing
  rate rows. [view_def]
- `is_ftd = TRUE` only on dates where the user actually had a deposit —
  unlike Spaceship's MIMO there is no orphan-FTD row synthesis. [view_def]

## 6. UC ALTER provenance

The companion `.alter.sql` re-states the live UC view-level COMMENT verbatim
(preservation) and emits 12 new column-level COMMENTs grounded in the view DDL
(`[view_def]` Tier 1). All 12 columns are deployed.
