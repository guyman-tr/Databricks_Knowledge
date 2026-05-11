---
id: revenue-staking-and-share-lending
name: revenue-and-fees-revenue-staking-and-share-lending
description: |
  RevShare-category fee revenue (DDR RevenueMetricCategoryID = 4) — the two
  yield-sharing revenue streams where eToro takes a cut of yield/income
  generated on customer-owned assets: ShareLending (revenue from lending real
  stocks to short-sellers, 40/40/20 eToro/user/broker split) and
  StakingLagOneMonth (crypto staking rewards, lagged ONE month — lands in the
  following month's DateID).

  Owns the lag mechanics, the share-lending 3-way split (and the per-side
  columns in `fact_customeraction_w_metrics`), the EXW / wallet / dealing
  staking source-table chain, and the staking-countries-classification
  reference for jurisdiction-eligibility questions.
triggers: [share lending, ShareLending, share-lending, ShareLendingFeeEtoroShare,
           ShareLendingFeeUserShare, ShareLendingFeeBrokerShare,
           ShareLendingGrossAmount, 40/40/20 split, lending revenue,
           short selling revenue, staking, staking fee, StakingLagOneMonth,
           staking rewards, staking lag, one month lag, crypto staking,
           rewards distribution, staking platform compensation, EXW staking,
           dealing staking, walletdb staking, stakingtransactions,
           stakingrewards, staking_data, treasury staking,
           staking_countries_classification, staking eligibility,
           v_revenue_share_lending, v_revenue_stakingfee, RevShare]
load_after: [_router.md, revenue-and-fees/SKILL.md]
intersects_with:
  - revenue-and-fees/trading-revenue-and-fees   # share-lending columns ALSO in w_metrics
  - payments/crypto-wallet                      # EXW / wallet staking source tables
  - cross-domain/dealing-staking-bridge                # planned — dealing-side staking pool
primary_objects:
  - main.etoro_kpi_prep.v_revenue_share_lending
  - main.etoro_kpi_prep.v_revenue_stakingfee
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary
  - main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
  - main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool
  - main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout
  - main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters
  - main.wallet.bronze_walletdb_staking_staking
  - main.wallet.bronze_walletdb_staking_stakingrewards
  - main.wallet.bronze_walletdb_staking_stakingtransactions
  - main.wallet.bronze_walletdb_staking_stakingexternaladdress
  - main.general.gold_tres_staking_data_staking_data    # treasury report
  - main.general.bronze_fivetran_google_sheets_staking_countries_classification
  - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics  # per-action share-lending columns
out_of_scope:
  - Trading-platform fees → trading-revenue-and-fees.md
  - MIMO-side fees → fees-deposit-withdraw-fx.md
  - Crypto transfer / C2F (different DDR category) → fees-deposit-withdraw-fx.md
  - Spaceship staking-equivalent revenue (Super contributions, etc.) → revenue-spaceship.md

version: 1
owner: "dataplatform"

required_tables:
  - main.etoro_kpi_prep.v_revenue_share_lending
  - main.etoro_kpi_prep.v_revenue_stakingfee
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary
  - main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
  - main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool
  - main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout
  - main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters
  - main.wallet.bronze_walletdb_staking_staking
  - main.wallet.bronze_walletdb_staking_stakingrewards
  - main.wallet.bronze_walletdb_staking_stakingtransactions
  - main.wallet.bronze_walletdb_staking_stakingexternaladdress
  - main.general.gold_tres_staking_data_staking_data
  - main.general.bronze_fivetran_google_sheets_staking_countries_classification
  - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
last_validated_at: "2026-05-10"

---

# H.3 — Staking & share-lending revenue


## When to Use
Load when the question is about staking revenue, share lending revenue, or the split between eToro/user/broker shares of lending income.

## Scope
In scope: StakingLagOneMonth revenue, share lending revenue splits (EtoroShare, UserShare, BrokerShare, GrossAmount), staking lag mechanics, CompensationReasonID=119, v_revenue_sharelending, v_revenue_staking
Out of scope: Trading fees (commission, rollover, tickets) → trading-revenue-and-fees.md; Crypto wallet staking operations (not revenue) → Payments/crypto-wallet; Security lending operational data (Equilend) → separate domain
Last verified: 2026-05-10

This sub-skill owns the two **RevShare-category** revenue metrics (DDR `RevenueMetricCategoryID = 4`) — where eToro takes a CUT of yield or income generated on customer-owned assets.

| RevenueMetricID | Metric | What it is | Anchor view |
|-----------------|--------|------------|-------------|
| 13 | `ShareLending` | Revenue from lending real stocks to short-sellers — **40/40/20** split (eToro / user / broker) | `etoro_kpi_prep.v_revenue_share_lending` |
| 12 | `StakingLagOneMonth` | Crypto-staking revenue — **lagged 1 month** (lands in the FOLLOWING month's `DateID`) | `etoro_kpi_prep.v_revenue_stakingfee` |

Both metrics carry `CountTransactions = NULL` (Critical Warning #5 of the hub) — they have no per-transaction grain in the DDR fact.

## Share lending — the 40/40/20 split

Customers who hold REAL stocks (not CFDs — `IsSettled = 1`) can have their shares lent to short-sellers via the broker. The interest paid by the short-seller is split three ways:

| Recipient | Share | Column in `fact_customeraction_w_metrics` |
|-----------|-------|--------------------------------------------|
| eToro | 40% | `ShareLendingFeeEtoroShare` |
| User | 40% | `ShareLendingFeeUserShare` |
| Broker | 20% | `ShareLendingFeeBrokerShare` |
| **Total (gross)** | 100% | `ShareLendingGrossAmount` |

**The DDR `ShareLending` metric carries eToro's 40% share only** — that's what the company books as revenue. The user's 40% accrues to the customer's balance; the broker's 20% is paid to the LP.

### Where share-lending lives in UC

| Object | Grain | When to use |
|--------|-------|-------------|
| `etoro_kpi_prep.v_revenue_share_lending` | Per-event share-lending revenue (eToro's 40% share) | Canonical KPI view. Use for monthly / quarterly share-lending revenue. |
| `de_output_etoro_kpi_fact_customeraction_w_metrics.ShareLendingFee*` (4 columns) | Per-action grain | When you need ALL THREE sides of the split, or to attribute the revenue to specific positions / customers. |
| DDR fact rows where `Metric = 'ShareLending'` | Daily aggregated per CID | Already filtered to eToro's 40%. Use for grand totals. |

### Share-lending query patterns

**Pattern 1 — Share-lending revenue, all three sides:**
```sql
SELECT
    SUM(ShareLendingFeeEtoroShare)  AS etoro_revenue,
    SUM(ShareLendingFeeUserShare)   AS user_payout,
    SUM(ShareLendingFeeBrokerShare) AS broker_payout,
    SUM(ShareLendingGrossAmount)    AS gross_lending_revenue,
    SUM(ShareLendingFeeEtoroShare) / NULLIF(SUM(ShareLendingGrossAmount), 0) * 100
        AS etoro_share_pct  -- should be ~40
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
WHERE DateID BETWEEN 20260101 AND 20260331
  AND ShareLendingGrossAmount > 0;
```

**Pattern 2 — eToro share-lending revenue (canonical) from the DDR side:**
```sql
SELECT DateID, SUM(Amount) AS etoro_share_lending_revenue
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE Metric = 'ShareLending'
  AND DateID BETWEEN 20260101 AND 20260331
GROUP BY DateID
ORDER BY DateID;
```

## Staking — the 1-month lag

Crypto-staking is the major source of confusion here. The metric is called **`StakingLagOneMonth`** for a reason:

- When a customer's crypto is staked and accrues rewards in (say) February 2026, those rewards distribute and book to revenue in **March 2026**, not February.
- The DDR row has `DateID` = the **booking** date (March), not the earn date (February).
- A naive "revenue in February 2026" query will miss February's staking revenue. A naive "revenue in March 2026" will include February's staking revenue as if it was earned in March.

**Always document this lag** in any time-series chart that involves staking. If the consumer is doing month-on-month % changes, the lag distorts the picture for both March (overstated by February's accrual) and February (understated).

### Where staking revenue lives

| Layer | Object | What it is |
|-------|--------|------------|
| DDR (canonical KPI) | `bi_db.gold_*_bi_db_ddr_fact_revenue_generating_actions` with `Metric = 'StakingLagOneMonth'` | eToro's net staking revenue, lagged 1 month |
| Atomic view | `etoro_kpi_prep.v_revenue_stakingfee` | Canonical per-event eToro staking-fee revenue |
| Dealing-side rollup | `dealing.gold_*_dealing_staking_summary` | Daily summary per customer × instrument |
| Dealing-side raw | `bi_db.gold_*_dealing_staking_results` | Daily distribution results |
| Dealing-side pool | `finance.gold_*_dealing_staking_dailypool` | Daily pool snapshot |
| Dealing-side opt-out | `finance.gold_*_dealing_staking_optedout` | Customers opted out of staking |
| Dealing-side params | `finance.gold_*_dealing_staking_parameters` | Staking parameter config (per instrument) |
| Wallet / EXW source | `wallet.bronze_walletdb_staking_staking`, `_stakingrewards`, `_stakingtransactions`, `_stakingexternaladdress` | Production-OLTP staking truth source |
| Treasury report | `general.gold_tres_staking_data_staking_data` | Finance-team treasury report |
| Eligibility ref | `general.bronze_fivetran_google_sheets_staking_countries_classification` | Country-by-country staking eligibility lookup |

### Staking query patterns

**Pattern 1 — Staking revenue (canonical, with lag callout):**
```sql
SELECT
    DateID            AS booking_dateid,
    -- StakingLagOneMonth lands in the FOLLOWING month's DateID
    DATE_FORMAT(DATE_SUB(TO_DATE(CAST(DateID AS STRING), 'yyyyMMdd'), 30), 'yyyyMM')
                      AS approx_earn_yyyymm,
    SUM(Amount)       AS staking_revenue
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE Metric = 'StakingLagOneMonth'
  AND DateID BETWEEN 20260101 AND 20260331
GROUP BY DateID
ORDER BY DateID;
```

**Pattern 2 — Staking pool snapshot for a given day:**
```sql
SELECT *
FROM main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool
WHERE DateID = 20260301
ORDER BY InstrumentID;
```

**Pattern 3 — Country eligibility lookup:**
```sql
SELECT *
FROM main.general.bronze_fivetran_google_sheets_staking_countries_classification;
```

## Critical Warnings (specific to RevShare metrics)

1. **`StakingLagOneMonth` is lagged 1 month.** Reported in the FOLLOWING month's `DateID`, not when earned. Document the lag on any time-series. Do NOT try to "un-lag" by shifting the DateID back — the booking dates are the canonical revenue dates for accounting purposes.
2. **`CountTransactions` is NULL** for both `ShareLending` and `StakingLagOneMonth` in the DDR fact. Don't compute "per-transaction" averages.
3. **`v_revenue_share_lending` returns eToro's 40% only.** To get user-side or broker-side amounts, use `fact_customeraction_w_metrics.ShareLendingFeeUserShare` / `ShareLendingFeeBrokerShare`.
4. **The user's 40% accrues to customer balance — it's a customer payout, NOT eToro revenue.** Don't add `ShareLendingFeeUserShare` to a Total Net Revenue query.
5. **Share lending requires `IsSettled = 1`** (real assets only). CFD positions cannot be lent. Filtering `WHERE IsSettled = 0` will drop share-lending revenue.
6. **Staking eligibility varies by country** — `general.bronze_fivetran_google_sheets_staking_countries_classification` is the lookup. Some jurisdictions (US for most coins, certain EU countries for specific coins) are opted-out entirely.
7. **Staking-data lineage**: customer-level staking transactions live in `wallet.bronze_walletdb_staking_*` (OLTP truth). The dealing-side `dealing.*` / `finance.*` staking tables are eToro-internal distribution / pool / params. The DDR `StakingLagOneMonth` is the final booked-revenue rollup. For OLTP-level audit, route through wallet; for revenue, route through DDR / `v_revenue_stakingfee`.
8. **`general.gold_tres_staking_data_staking_data`** is a TREASURY report (treasury cluster), not the canonical revenue source. Use it for finance / treasury reconciliation only — not for KPI revenue answers.

## Cluster provenance

- `v_revenue_stakingfee` — `etoro_kpi_prep` (multi-cluster).
- `dealing.*` and `finance.*` staking — Dealing / treasury sub-cluster.
- `wallet.bronze_walletdb_staking_*` — Wallet / EXW source cluster (Cluster 3 / 4 range).
- DDR `StakingLagOneMonth` rows — Cluster 13 (DDR).
- Share-lending columns in `fact_customeraction_w_metrics` — Cluster 13 (DDR family).

## Source of truth

- `v_revenue_stakingfee` and `v_revenue_share_lending` are defined in `/Users/guyman@etoro.com/a_semantic_etoro_kpi_prep/`.
- Wallet-side staking truth is the OLTP `Wallet.dbo.Staking_*` family (mirrored to UC as `wallet.bronze_walletdb_staking_*`).
- Country-eligibility lookup is maintained as a Google Sheet, ingested via Fivetran into `general.bronze_fivetran_google_sheets_staking_countries_classification`.
