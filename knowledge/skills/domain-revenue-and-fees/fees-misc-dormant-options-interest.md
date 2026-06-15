---
name: domain-revenue-and-fees
description: |
  Catch-all for the Other-category fees (DDR RevenueMetricCategoryID = 5) that
  don't fit the trading-side (H.1), MIMO-side (H.2), RevShare-side (H.3), or
  product-line (H.5–H.7) buckets. Owns DormantFee (monthly inactivity fee,
  CompensationReasonID = 30, available in `etoro_kpi_prep.v_revenue_dormantfee`
  AND as a NAMED column in `fact_customeraction_w_metrics.DormantFee`) and
  InterestFee (historical margin interest, DEPRECATED post-Jul-2023, available
  in `etoro_kpi_prep.v_revenue_interestfee`).

  Options_PFOF (also Other-category) is referenced here for completeness but
  the dedicated source lives in revenue-options-platform.md (H.5).
  Dividends-pass-through and SDRT (also Other-category) are owned by
  trading-revenue-and-fees.md (H.1) because they flow on position events.
triggers: [DormantFee, dormant fee, inactivity fee, monthly inactivity,
           CompensationReasonID 30, account-level fee, InterestFee,
           margin interest, deprecated interest, Other category,
           v_revenue_dormantfee, v_revenue_interestfee]
load_after: [_router.md, domain-revenue-and-fees/SKILL.md]
intersects_with:
  - domain-revenue-and-fees/revenue-options-platform     # Options_PFOF lives there
  - domain-revenue-and-fees/trading-revenue-and-fees     # Dividends + SDRT live there
primary_objects:
  - main.etoro_kpi_prep.v_revenue_dormantfee
  - main.etoro_kpi_prep.v_revenue_interestfee     # deprecated post-Jul-2023
  - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics  # DormantFee column at action grain
out_of_scope:
  - Options_PFOF detail → revenue-options-platform.md
  - Dividends + SDRT pass-through → trading-revenue-and-fees.md
  - All other trading / MIMO / RevShare / acquired-platform fees → their respective sub-skills

version: 1
owner: "dataplatform"

required_tables:
  - main.etoro_kpi_prep.v_revenue_dormantfee
  - main.etoro_kpi_prep.v_revenue_interestfee
  - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
last_validated_at: "2026-05-10"

---

# H.4 — Misc Other-category fees (Dormant, Interest)


## When to Use
Load when the question is about dormant fees, interest fees, or miscellaneous non-trading fee categories.

## Scope
In scope: DormantFee (CompensationReasonID=30), InterestFee, Options PFOF in DDR context, misc non-trading fees
Out of scope: Trading fees → trading-revenue-and-fees.md; MIMO-side fees → fees-deposit-withdraw-fx.md; Options platform revenue detail → revenue-options-platform.md
Last verified: 2026-05-10

This sub-skill is the lightest in the H super-domain. It owns two small Other-category metrics that don't logically belong with the headline fee families.

## The 2 metrics this sub-skill owns

| RevenueMetricID | Metric | Category | What it is | Anchor |
|-----------------|--------|----------|------------|--------|
| 14 | `DormantFee` | Other | Monthly account-level inactivity fee. `CompensationReasonID = 30`. Account-level → `InstrumentTypeID = -1`. | `etoro_kpi_prep.v_revenue_dormantfee` + `fact_customeraction_w_metrics.DormantFee` column |
| 15 | `InterestFee` | Other | Historical margin interest. **DEPRECATED post-Jul-2023** — largely zero since Aug 2023. Account-level → `InstrumentTypeID = -1`. | `etoro_kpi_prep.v_revenue_interestfee` |

## Where DormantFee lives

- **DDR fact**, `Metric = 'DormantFee'` — daily aggregated per CID for KPI use.
- **`etoro_kpi_prep.v_revenue_dormantfee`** — atomic per-event view.
- **`de_output.de_output_etoro_kpi_fact_customeraction_w_metrics.DormantFee`** — per-action column; the row's `ActionTypeID = 36` AND `CompensationReasonID = 30`.

## Where InterestFee lives

- **DDR fact**, `Metric = 'InterestFee'` — daily aggregated. Most rows are pre-Aug-2023.
- **`etoro_kpi_prep.v_revenue_interestfee`** — atomic per-event view.

**`InterestFee` is functionally deprecated.** New questions involving "interest" almost certainly mean something else:

- **Interest on Balance (IOB)** — interest *paid TO customers* on idle cash, with eToro keeping the spread vs the gross treasury yield as **net revenue**. `ActionTypeID = 36 AND CompensationReasonID = 57` on `fact_customeraction`. Economic twin of staking. **This is the most common modern meaning of "interest".** → `interest-on-balance.md`.
- **`RollOverFee`** (overnight financing on leveraged positions) → `trading-revenue-and-fees.md`.
- **Staking yield** (`StakingLagOneMonth`) → `revenue-staking-and-share-lending.md`.
- **Treasury MMF / counterparty yield** (the GROSS side that produces IOB) — owned by Finance, not yet in UC. Surfaced in `interest-on-balance.md` as a known gap.

If a user asks about "interest", clarify intent before falling back to this deprecated metric. **`InterestFee` (charged TO customer for borrowing) and IOB (paid TO customer for lending us cash) are polar opposites — easy to confuse, never the same answer.**

## Query patterns

### Pattern 1 — Dormant-fee revenue by month
```sql
SELECT
    FLOOR(DateID / 100) AS yyyymm,
    SUM(Amount)         AS dormant_fee_revenue,
    COUNT(DISTINCT RealCID) AS n_dormant_customers
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
WHERE Metric = 'DormantFee'
  AND DateID BETWEEN 20260101 AND 20260331
GROUP BY yyyymm
ORDER BY yyyymm;
```
**Use when:** "Dormant-fee revenue last quarter", "How many customers are paying dormant fee?"

### Pattern 2 — Dormant-fee per regulation / jurisdiction
```sql
SELECT
    dc.RegulationName,
    SUM(w.DormantFee) AS dormant_fee_revenue,
    COUNT(DISTINCT w.RealCID) AS n_customers
FROM main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics w
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  ON dc.CID = w.RealCID
WHERE w.DateID BETWEEN 20260101 AND 20260331
  AND w.DormantFee > 0
GROUP BY dc.RegulationName
ORDER BY dormant_fee_revenue DESC;
```
**Use when:** "Dormant-fee revenue broken out by entity / regulation."

## Critical Warnings

1. **`InterestFee` is deprecated** — only relevant for historical / back-fill questions. Most rows are zero or near-zero from Aug 2023 onwards.
2. **`DormantFee` is account-level, `InstrumentTypeID = -1`.** Including it in a `GROUP BY InstrumentTypeID` per-instrument breakdown pollutes the result. Filter `WHERE InstrumentTypeID != -1` or aggregate separately.
3. **`Dim_Revenue_Metrics` `RevenueMetricCategoryID = 5` (Other)** contains 5 metrics: `DormantFee` (this sub-skill), `InterestFee` (this sub-skill, deprecated), `Dividends` (→ H.1 pass-through), `SDRT` (→ H.1 pass-through), `Options_PFOF` (→ H.5). Don't assume "Other category = this sub-skill" — the routing splits by business meaning.
4. **Dormant-fee customers tend to also be liquidation candidates** — when answering churn / winback questions, cross-reference `customer-and-identity` skill (Customer & Identity super-domain) for the customer-property view.

## Cluster provenance

- `v_revenue_dormantfee`, `v_revenue_interestfee` — `etoro_kpi_prep`, scattered by their CID-join partners.
- DDR rows for these metrics — Cluster 13.

## Source of truth

- `v_revenue_dormantfee` and `v_revenue_interestfee` are defined in `/Users/guyman@etoro.com/a_semantic_etoro_kpi_prep/`.
- The dormant-fee charge logic lives upstream in the Synapse SP that builds the customer-action rows for `ActionTypeID = 36, CompensationReasonID = 30`.
