---
name: domain-moneyfarm
description: "Full DDLs and CTE walkthroughs for the three MoneyFarm prep views in
  main.etoro_kpi_prep — v_moneyfarm_aum (silver-AUM-fed daily AUM with GBP/USD
  conversion via fact_currencypricewithsplit InstrumentID=2), v_moneyfarm_mimo
  (live-event-stream-fed deposit/withdrawal flow with FTD detection via
  first_deposit_dates CTE; sources EventPayloadRowData.EventMetadata.Gcid filter
  ProviderName='Moneyfarm' EventType IN PORTFOLIO_DEPOSIT/PORTFOLIO_WITHDRAW), and
  v_moneyfarm_fees (PLACEHOLDER — DDL is literally SELECT NULL CASTS WHERE 1=0;
  no fee data ingested today). Each section gives the verbatim DDL, the CTE
  ladder explained, the row-grain reasoning, the cadence/freshness notes, and
  the warnings (FX missing-rate→0 USD; FTD only post-Oct-2025; case-sensitive
  ProviderName='Moneyfarm'; portfolio_count for multi-ISA-wrapper customers;
  the table-level COMMENT example query referencing the deprecated date_id
  column name vs the actual dateid). Includes the deprecated note that
  v_moneyfarm_fees is reserved schema-only — when fees do eventually land
  (e.g. a Finance booked-fee feed or an analyst-agreed synthetic estimate),
  this view's body is the swap point so downstream consumers don't break."
triggers:
  - v_moneyfarm_aum
  - v_moneyfarm_mimo
  - v_moneyfarm_fees
  - moneyfarm view ddl
  - moneyfarm view definition
  - moneyfarm aum view
  - moneyfarm mimo view
  - moneyfarm fees view
  - moneyfarm fees placeholder
  - first_deposit_dates CTE
  - gbp_usd_rates CTE
  - aggregated_balances CTE
  - daily_portfolio_balances
  - mimo_daily CTE
  - parsed_events CTE
  - raw_events CTE
  - InstrumentID=2
  - gbp_to_usd_rate
sample_questions:
  - "What's the DDL of v_moneyfarm_aum?"
  - "How is is_ftd computed on v_moneyfarm_mimo?"
  - "Why is v_moneyfarm_fees always empty?"
  - "What does the silver-AUM-fed cadence mean for v_moneyfarm_aum freshness?"
  - "How does the MIMO view convert GBP to USD?"
  - "How does v_moneyfarm_mimo handle a withdrawal sign?"
required_tables:
  - main.etoro_kpi_prep.v_moneyfarm_aum
  - main.etoro_kpi_prep.v_moneyfarm_mimo
  - main.etoro_kpi_prep.v_moneyfarm_fees
  - main.money_farm.silver_moneyfarm_etoro_mf_aum
  - main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-31"
---

# MoneyFarm — Prep Views Architecture

Full verbatim DDLs (captured 2026-05-31 via `SHOW CREATE TABLE`), CTE walkthroughs, and the row-grain / freshness / FX caveats for the 3 views in `main.etoro_kpi_prep` that drive MoneyFarm DDR rows.

## 1. `v_moneyfarm_aum` — daily AUM panel

**Granularity**: one row per `(date, gcid)`. All of a customer's MoneyFarm portfolios are summed for the day.
**Source of truth**: silver back-fill ladder `main.money_farm.silver_moneyfarm_etoro_mf_aum` — NOT the live event stream. Cadence trails the silver pipeline (nightly SFTP).
**Used by**: Tableau `main__etoro_kpi`; eToro KPI dashboards; Ben Thompson's `ISA Market Value (SFTP data)` workbook (likely directly).

### Verbatim DDL

```sql
CREATE VIEW etoro_kpi_prep.v_moneyfarm_aum (
  date COMMENT '...',
  dateid COMMENT '...',
  gcid COMMENT '...',
  total_balance_gbp COMMENT '...',
  total_balance_usd COMMENT '...',
  is_funded COMMENT '...',
  portfolio_count COMMENT '...'
)
COMMENT 'MoneyFarm AUM snapshot by date_id (YYYYMMDD int) and customer keys.
External MoneyFarm feed; filter date_id. Example: SELECT COUNT(*) FROM
main.etoro_kpi_prep.v_moneyfarm_aum WHERE date_id = 20251231;'
WITH SCHEMA COMPENSATION
AS
WITH daily_portfolio_balances AS (
    SELECT
        etr_ymd AS date,
        GCID,
        Portfolio_Id AS PortfolioID,
        Product,
        CAST(Market_Value AS DOUBLE) AS market_value
    FROM main.money_farm.silver_moneyfarm_etoro_mf_aum
    WHERE GCID IS NOT NULL
),
gbp_usd_rates AS (
    SELECT
        CAST(OccurredDate AS DATE) AS rate_date,
        (Ask + Bid) / 2 AS gbp_to_usd_rate
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
    WHERE InstrumentID = 2
),
aggregated_balances AS (
    SELECT
        date,
        GCID,
        SUM(market_value) AS total_balance_gbp,
        COUNT(DISTINCT PortfolioID) AS portfolio_count
    FROM daily_portfolio_balances
    GROUP BY date, GCID
)
SELECT
    a.date,
    CAST(DATE_FORMAT(a.date, 'yyyyMMdd') AS INT) AS dateid,
    a.GCID AS gcid,
    a.total_balance_gbp,
    a.total_balance_gbp * COALESCE(r.gbp_to_usd_rate, 0) AS total_balance_usd,
    CASE
        WHEN a.total_balance_gbp > 0 THEN TRUE
        ELSE FALSE
    END AS is_funded,
    a.portfolio_count
FROM aggregated_balances a
LEFT JOIN gbp_usd_rates r
    ON a.date = r.rate_date
```

### CTE walkthrough

1. **`daily_portfolio_balances`** — pulls `(etr_ymd, GCID, Portfolio_Id, Product, Market_Value)` from the silver SFTP-fed AUM ladder, filtering `GCID IS NOT NULL`. Note: `Market_Value` is cast to DOUBLE upstream.
2. **`gbp_usd_rates`** — extracts the GBP/USD mid-rate per date from `dwh.fact_currencypricewithsplit` filtered `InstrumentID = 2` (GBP/USD pair). Mid-rate is `(Ask + Bid) / 2`.
3. **`aggregated_balances`** — collapses to `(date, GCID)` with `SUM(market_value)` (GBP) and `COUNT(DISTINCT PortfolioID)` (so a customer with Managed ISA + DIY ISA + Cash ISA shows portfolio_count=3).
4. **Final SELECT** — joins `aggregated_balances LEFT JOIN gbp_usd_rates ON date = rate_date`, casts `dateid` (lowercase, no underscore), computes `total_balance_usd = GBP * COALESCE(rate, 0)`, and `is_funded = (GBP > 0)`.

### Caveats (verbatim from cached wiki)

- **Cadence trails live activity** — the view trails the live event hub by the silver pipeline cadence. For real-time MIMO use `v_moneyfarm_mimo` instead; for AUM the silver-fed view is the canonical answer.
- **`total_balance_usd = 0.0` doesn't mean zero balance** — it means missing GBP/USD rate row for that date. Always check `total_balance_gbp` first. The `COALESCE(rate, 0)` is the cause.
- **The view-level COMMENT says `date_id`**, but the actual column is `dateid` (no underscore). Consistency with other moneyfarm views; treat the COMMENT example as illustrative only.
- **Spaceship uses `InstrumentID=7` (AUD/USD)**; MoneyFarm uses `InstrumentID=2` (GBP/USD). Don't confuse.
- **`gcid` is INT here**, not LONG. The silver source is INT-typed; the bi_output facts are LONG-typed. Cast on the join boundary.
- **`portfolio_count = 1` is the typical value**. Multi-ISA-wrapper customers (Managed + DIY + Cash) push it to 2 or 3.

## 2. `v_moneyfarm_mimo` — daily Money-In / Money-Out panel

**Granularity**: one row per `(date, gcid)` aggregating gross deposits and withdrawals from the live sub-accounts EH MoneyFarm stream.
**Source of truth**: `main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` filtered `ProviderName='Moneyfarm'` and `EventType IN ('PORTFOLIO_DEPOSIT','PORTFOLIO_WITHDRAW')`.
**Used by**: Tableau `main__etoro_kpi`; eToro KPI MIMO panels; Ben's `ISA MIMO (Events API data)` workbook; per-event detail in `bi_output_moneyfarm_fact_transactions`.
**Coverage**: live-stream-fed — **Oct 2025 onwards only**. Pre-Oct-2025 deposits are not in this view.

### Verbatim DDL

```sql
CREATE VIEW etoro_kpi_prep.v_moneyfarm_mimo (
  date,
  dateid,
  gcid,
  total_deposits_gbp,
  total_withdrawals_gbp,
  net_flow_gbp,
  total_deposits_usd,
  total_withdrawals_usd,
  net_flow_usd,
  count_deposits,
  count_withdrawals,
  is_ftd
)
COMMENT 'MoneyFarm MIMO (first deposit) style facts by date_id. Filter date_id.
Example: SELECT * FROM main.etoro_kpi_prep.v_moneyfarm_mimo WHERE date_id = 20251231 LIMIT 50;'
WITH SCHEMA COMPENSATION
AS
WITH raw_events AS (
    SELECT
        EventPayloadRowData.EventMetadata.Gcid AS GCID,
        EventPayloadRowData.EventMetadata.EventType AS event_type,
        EventPayloadRowData.EventMetadata.CreatedAt AS created_at,
        EventPayloadRowData.EventData AS event_data_json
    FROM main.compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts
    WHERE EventPayloadRowData.ProviderName = 'Moneyfarm'
      AND EventPayloadRowData.EventMetadata.EventType IN ('PORTFOLIO_DEPOSIT','PORTFOLIO_WITHDRAW')
      AND EventPayloadRowData.EventMetadata.Gcid IS NOT NULL
),
parsed_events AS (
    SELECT
        GCID,
        event_type,
        CAST(SUBSTRING(created_at, 1, 10) AS DATE) AS date,
        CAST(get_json_object(get_json_object(event_data_json, '$.data'), '$.amount') AS DOUBLE) AS amount,
        get_json_object(get_json_object(event_data_json, '$.data'), '$.portfolioId') AS portfolio_id,
        get_json_object(get_json_object(event_data_json, '$.data'), '$.valueDate') AS value_date
    FROM raw_events
),
mimo_daily AS (
    SELECT
        date,
        GCID,
        SUM(CASE WHEN event_type = 'PORTFOLIO_DEPOSIT'  AND amount > 0 THEN amount      ELSE 0 END) AS total_deposits,
        SUM(CASE WHEN event_type = 'PORTFOLIO_WITHDRAW' AND amount < 0 THEN ABS(amount) ELSE 0 END) AS total_withdrawals,
        SUM(CASE WHEN event_type = 'PORTFOLIO_DEPOSIT'  AND amount > 0 THEN 1 ELSE 0 END) AS count_deposits,
        SUM(CASE WHEN event_type = 'PORTFOLIO_WITHDRAW' AND amount < 0 THEN 1 ELSE 0 END) AS count_withdrawals
    FROM parsed_events
    GROUP BY date, GCID
),
first_deposit_dates AS (
    SELECT GCID, MIN(date) AS first_deposit_date
    FROM mimo_daily
    WHERE total_deposits > 0
    GROUP BY GCID
),
gbp_usd_rates AS (
    SELECT
        CAST(OccurredDate AS DATE) AS rate_date,
        (Ask + Bid) / 2 AS gbp_to_usd_rate
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
    WHERE InstrumentID = 2
)
SELECT
    m.date,
    CAST(DATE_FORMAT(m.date, 'yyyyMMdd') AS INT) AS dateid,
    m.GCID AS gcid,
    m.total_deposits AS total_deposits_gbp,
    m.total_withdrawals AS total_withdrawals_gbp,
    m.total_deposits - m.total_withdrawals AS net_flow_gbp,
    m.total_deposits     * COALESCE(r.gbp_to_usd_rate, 0) AS total_deposits_usd,
    m.total_withdrawals  * COALESCE(r.gbp_to_usd_rate, 0) AS total_withdrawals_usd,
    (m.total_deposits - m.total_withdrawals) * COALESCE(r.gbp_to_usd_rate, 0) AS net_flow_usd,
    m.count_deposits,
    m.count_withdrawals,
    CASE
        WHEN m.date = f.first_deposit_date AND m.total_deposits > 0 THEN TRUE
        ELSE FALSE
    END AS is_ftd
FROM mimo_daily m
LEFT JOIN first_deposit_dates f ON m.GCID = f.GCID
LEFT JOIN gbp_usd_rates       r ON m.date = r.rate_date
```

### CTE walkthrough

1. **`raw_events`** — pulls 4 event metadata fields from `compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts`:
   - `GCID` (already-resolved by the `sub-accounts-experience-worker` enrichment).
   - `event_type` — must be `'PORTFOLIO_DEPOSIT'` or `'PORTFOLIO_WITHDRAW'`.
   - `created_at` — UTC timestamp string.
   - `event_data_json` — the raw event payload struct.
   - **Filter**: `ProviderName = 'Moneyfarm'` (case-sensitive — capital M, single word) AND event-type IN deposits/withdrawals AND `Gcid IS NOT NULL`.

2. **`parsed_events`** — extracts business fields from `event_data_json`:
   - `date` = `CAST(SUBSTRING(created_at, 1, 10) AS DATE)` — the event-creation date in UTC (no timezone conversion).
   - `amount` = `event_data_json.data.amount` cast to DOUBLE. **For deposits this is positive; for withdrawals this is negative.**
   - `portfolio_id` and `value_date` are extracted but NOT used in the final SELECT.

3. **`mimo_daily`** — aggregates by `(date, GCID)`:
   - `total_deposits` = SUM of `amount` only when event is DEPOSIT and amount > 0.
   - `total_withdrawals` = SUM of `ABS(amount)` only when event is WITHDRAW and amount < 0 (the ABS makes withdrawals positive for SUM-friendly aggregation).
   - `count_deposits` / `count_withdrawals` = same WHEN-conditioned sums but counting events.

4. **`first_deposit_dates`** — per-GCID `MIN(date) WHERE total_deposits > 0`. This is the FTD anchor.

5. **`gbp_usd_rates`** — same as in `v_moneyfarm_aum`. Mid-rate from `fact_currencypricewithsplit InstrumentID=2`.

6. **Final SELECT** — joins `mimo_daily LEFT JOIN first_deposit_dates ON GCID LEFT JOIN gbp_usd_rates ON date`, casts `dateid`, computes net flow (GBP and USD), and stamps `is_ftd = TRUE` only on the FTD-date row where deposits were actually positive.

### Caveats

- **`is_ftd = TRUE` only on dates where the user actually had a deposit** — unlike Spaceship's MIMO there is no orphan-FTD row synthesis. `is_ftd = TRUE` always coincides with `total_deposits_gbp > 0`. (See cached wiki.)
- **No timezone conversion** — `date` is event `CreatedAt` UTC truncated. Spaceship's MIMO converts UTC→Sydney; MoneyFarm does NOT. UK is GMT/BST so most days UTC ≈ UK local; cross-domain panels with Spaceship need to handle the discrepancy.
- **`Full Withdrawal` events are NOT distinguished here** — the upstream EH stream has only `PORTFOLIO_WITHDRAW` (no separate full-withdrawal event type). The 3-value `TransactionType` enum (Deposit / Withdrawal / Full Withdrawal) lives only on `bi_output_moneyfarm_fact_transactions`.
- **`ProviderName='Moneyfarm'`** is case-sensitive — capital M, single word. Don't use `'MoneyFarm'`, `'Money Farm'`, or `'money_farm'`.
- **USD = 0.0 on missing-rate days** — same `COALESCE(rate, 0)` pattern as `v_moneyfarm_aum`. Always check `total_deposits_gbp > 0 AND total_deposits_usd = 0` to detect missing rate rows.
- **Coverage starts Oct 2025** — the live EH pipeline only began feeding deposits in October 2025. For earlier history use `bi_output_moneyfarm_fact_transactions` (which carries `Source_Type='Silver History'` for the back-fill) or the silver `historical_events` table.

## 3. `v_moneyfarm_fees` — PLACEHOLDER

**Granularity (target)**: one row per `(date, gcid)` of fee revenue.
**Current state**: returns 0 rows. The DDL is literally `SELECT NULL CASTS WHERE 1=0`.
**Status**: PLACEHOLDER — schema reservation only; no fee-data ingestion exists today. The customer-facing fee schedule lives in Confluence (page `11942330382` — see `moneyfarm-metric-definitions.md`) but **no UC table holds per-portfolio or per-customer fee deductions**.

### Verbatim DDL

```sql
CREATE VIEW etoro_kpi_prep.v_moneyfarm_fees (
  date,
  dateid,
  gcid,
  total_fees_gbp,
  total_fees_usd
)
COMMENT 'MoneyFarm fee facts by date_id. Filter date_id for one day.
Example: SELECT SUM(fee_amount) FROM main.etoro_kpi_prep.v_moneyfarm_fees WHERE date_id = 20251231;'
WITH SCHEMA COMPENSATION
AS
SELECT  -- this is currently a placeholder, no fee logic exists yet
    CAST(NULL AS DATE)   AS date,
    CAST(NULL AS INT)    AS dateid,
    CAST(NULL AS BIGINT) AS gcid,
    CAST(NULL AS DOUBLE) AS total_fees_gbp,
    CAST(NULL AS DOUBLE) AS total_fees_usd
WHERE 1=0
```

### Why it exists in this state

The view is intentionally a **schema reservation**. It exists so that:

1. **Downstream Tableau / Genie / KPI queries** can reference `main.etoro_kpi_prep.v_moneyfarm_fees` with the documented column shape today, and continue to work without any change when fee data lands.
2. **Cross-domain DDR aggregations** (when authored) can `LEFT JOIN` against this view without breaking on a missing relation.
3. **The author's intent is documented inline** — the SQL body carries the comment `-- this is currently a placeholder, no fee logic exists yet`.

### What's missing

There is currently **no UC table holding MoneyFarm fee deductions**:

- `bi_output.bi_output_moneyfarm_fact_transactions` carries `TransactionType IN ('Deposit', 'Withdrawal', 'Full Withdrawal')` only — no `Fee` event type.
- `compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` has events `PORTFOLIO_DEPOSIT`, `PORTFOLIO_WITHDRAW`, `PORTFOLIO_CREATED`, `USER_CASH_ACCOUNT_ACTIVATED` for MoneyFarm — there is no `PORTFOLIO_FEE` event type registered today.
- `money_farm.silver_moneyfarm_etoro_mf_aum` carries `Market_Value` only — fees are presumably netted out before NAV mark-to-market, so they're invisible at this layer.
- `bi_output.bi_output_moneyfarm_fact_portfolio_snapshot.Current_Market_Value_GBP` is similarly net-of-fees.
- Ben Thompson's 5 `UK/ISA` Tableau workbooks **do not compute or surface fees** — the lineage of `AM - ISA Performance V1` confirms 27 tracked fields cover AUM, MIMO, funding, AM attribution, but zero fee columns.

The actual booked fee revenue lives in **Finance's ledger** (off-Databricks). Ask Finance directly for the booked-fee aggregate.

### What the customer-facing fee schedule looks like

Documented in Confluence page `11942330382` ("Individual Savings Account (ISA) - MoneyFarm", last updated 2026-04-24):

- **Stocks & Shares ISA** (Mar 2023): "Same fees as standard MoneyFarm pricing" — points externally to `moneyfarm.com/uk/pricing/`.
- **Managed ISA** (Oct 21, 2025): explicit tiered AUM fee — Under £100K: 0.75% / 0.70% / 0.65% / 0.60% across £10K / £20K / £50K / £100K bands. Over £100K: 0.45% / 0.40% / 0.35%.
- **Cash ISA** (Oct 21, 2025): Standard Variable Rate + 12-month boost (interest *paid to* customer, not a fee).

Full schedule with exact thresholds + cashback offer details in `moneyfarm-metric-definitions.md`.

### When fees do eventually land

This view's body is the natural swap point:

```sql
-- HYPOTHETICAL future shape — not yet implemented
CREATE OR REPLACE VIEW etoro_kpi_prep.v_moneyfarm_fees AS
WITH fee_events AS (
    SELECT
        date,
        GCID,
        SUM(fee_amount) AS total_fees_gbp
    FROM <future-fee-source>
    GROUP BY date, GCID
),
gbp_usd_rates AS (
    SELECT
        CAST(OccurredDate AS DATE) AS rate_date,
        (Ask + Bid) / 2 AS gbp_to_usd_rate
    FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
    WHERE InstrumentID = 2
)
SELECT
    f.date,
    CAST(DATE_FORMAT(f.date, 'yyyyMMdd') AS INT) AS dateid,
    f.GCID AS gcid,
    f.total_fees_gbp,
    f.total_fees_gbp * COALESCE(r.gbp_to_usd_rate, 0) AS total_fees_usd
FROM fee_events f
LEFT JOIN gbp_usd_rates r ON f.date = r.rate_date
```

Two probable feed sources when the time comes:
1. A Finance-shipped booked-fee CSV (most likely — fees are fundamentally a Finance ledger concern, not a stream concern).
2. A new `PORTFOLIO_FEE` event type added to the sub-accounts EH stream (would require MoneyFarm-side and eToro-side code change; less likely in the near term).

A third option — **synthesise an estimated fee from AUM** using the documented Managed-ISA tiered schedule — was **explicitly considered and declined** during the 2026-05-31 skill-build conversation. The reason: tiered AUM fees are charged on the *time-weighted average* portfolio balance, not the snapshot, so a daily approximation is inaccurate; and the Stocks-and-Shares ISA fee schedule isn't documented eToro-side at all (points externally to moneyfarm.com pricing). Without analyst sign-off the synthetic estimate would silently produce wrong numbers, which is worse than producing no numbers.

## Cross-view consistency

| Concern | `v_moneyfarm_aum` | `v_moneyfarm_mimo` | `v_moneyfarm_fees` |
|---|---|---|---|
| `date` | silver `etr_ymd` | event `CreatedAt` UTC truncated | NULL |
| `gcid` type | INT | INT | LONG (BIGINT) |
| FX leg | `InstrumentID=2` | `InstrumentID=2` | `InstrumentID=2` (when populated) |
| Missing FX → 0 USD | yes (`COALESCE`) | yes (`COALESCE`) | n/a today |
| `dateid` spelling | `dateid` | `dateid` | `dateid` |
| Cadence | silver-fed (daily SFTP) | live-stream-fed (Oct 2025+) | none |
| FTD logic | n/a | `MIN(date) WHERE total_deposits > 0` per GCID | n/a |
| Funded flag | `is_funded` (GBP > 0) | n/a (only on AUM view) | n/a |

The shared FX leg and `dateid` spelling make the 3 views composable as `(date, gcid)` rollups. When fees land, the natural cross-view join is:

```sql
SELECT
    a.date,
    a.gcid,
    a.total_balance_gbp,
    m.total_deposits_gbp,
    m.total_withdrawals_gbp,
    f.total_fees_gbp                    -- always NULL today
FROM main.etoro_kpi_prep.v_moneyfarm_aum a
LEFT JOIN main.etoro_kpi_prep.v_moneyfarm_mimo m USING (date, gcid)
LEFT JOIN main.etoro_kpi_prep.v_moneyfarm_fees f USING (date, gcid)
WHERE a.dateid = 20260101
```
