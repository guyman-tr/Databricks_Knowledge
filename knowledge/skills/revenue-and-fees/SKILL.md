---
name: revenue-and-fees-super-domain
description: |
  Cross-product revenue and fee accounting. Use when the question is about
  any kind of fee or revenue eToro charges/earns: trading commission,
  overnight rollover, dividend pass-through, FX/conversion fee, cashout fee,
  transfercoin / redeem fee, deposit fee, withdraw fee, share lending,
  dormant fee, ticket fee, admin fee, SDRT, spot adjustment, options revenue,
  staking rewards/fees, spaceship fees, moneyfarm fees, dealing LP fees,
  affiliate commission, US Apex fees, dividends. Anchored on
  BI_DB_DDR_Fact_Revenue_Generating_Actions and the 20+ etoro_kpi_prep.v_revenue_*
  view family (each = one fee TYPE in canonical UC form).
keywords: [revenue, fee, commission, rollover, dividend, FX, conversion fee,
           exchange fee, spread, cashout fee, transfercoin, redeem fee,
           deposit fee, withdraw fee, share lending, dormant, ticket fee,
           admin fee, SDRT, spot adjust, options fee, staking, spaceship,
           moneyfarm, ISA, SIPP, LP fees, affiliate, Apex, IndexDividends,
           pipscalculation, BaseExchangeRate, ExchangeRate, mv_revenue]
load_after: [_router.md]
sub_skills:
  - trading-revenue-canonical
  - fees-trading-platform
  - fees-emoney
  - fees-crypto-wallet
  - revenue-options-platform
  - revenue-staking
  - revenue-spaceship
  - revenue-moneyfarm
  - dividends-and-tax
  - affiliate-commission
  - lp-fees-and-cogs
out_of_scope:
  - Customer money flow (deposits/withdrawals as VOLUMES) → Payments super-domain
  - Bonuses paid TO customers → Compensation super-domain (planned)
  - Treasury / company-level FX history / GL → Finance super-domain
---

# Revenue & Fees Super-Domain

This super-domain owns **every kind of fee or revenue eToro books**, across
every product line. It is intentionally horizontal because the same kind of
question — "what did we earn from X?", "what fee did we charge for Y?" — has
a different answer for each product, but the structure of the answer is
identical.

The DDR layer (Daily Data Report) already pre-aggregates most of the canonical
revenue events into `BI_DB_DDR_Fact_Revenue_Generating_Actions` keyed by
`(DateID, RealCID, ActionTypeID, RevenueMetricID, InstrumentTypeID)`. On
top of that, Unity Catalog has a per-fee `v_revenue_*` view family that each
isolates ONE fee/revenue type with its product-specific quirks.

## Mental model

```mermaid
graph TB
    subgraph Trading["Trading Platform (CFD / stocks / crypto CFD)"]
        Fxd[v_revenue_fullcommission<br/>Function_Revenue_FullCommissions]
        Tk1[v_revenue_ticketfee_fixed<br/>v_revenue_ticketfee_bypercent]
        Roll[v_revenue_rollover<br/>BI_DB_RollOverFee_ByInstrument]
        Div[v_revenue_dividend<br/>BI_DB_DailyDividendsByPosition]
        Spot[v_revenue_spotadjustfee]
        Conv[v_revenue_conversionfee<br/>v_revenue_conversionfee_withpositiondata]
        Lend[v_revenue_share_lending]
        Dorm[v_revenue_dormantfee]
        Int[v_revenue_interestfee]
        AdmFee[v_revenue_adminfee]
        Sdrt[v_revenue_sdrt UK Stamp Duty]
    end

    subgraph Payments["Payments-side fees"]
        DepFee[BI_DB_DepositWithdrawFee<br/>BI_DB_DepositWithdrawFee_Reversals<br/>Fact_Deposit_Fees / Fact_Withdraw_Fees]
        Cash[v_revenue_cashoutfee_excluderedeem<br/>v_revenue_cashoutfee_incredeem<br/>EY_Audit_CashoutFees]
        Tcf[v_revenue_transfercoinfee]
        C2f[v_revenue_cryptotofiat_c2f]
    end

    subgraph Crypto["Crypto / staking"]
        Stk[v_revenue_stakingfee<br/>Staking.StakingRewards<br/>Staking_BI_Version_*<br/>BI_DB_Staking_Platform_Compensations<br/>BI_DB_Finance_Staking_Report]
    end

    subgraph Options["Options (Apex)"]
        Opt[v_revenue_optionsplatform<br/>BI_DB_US_Apex_Fees_Charge]
    end

    subgraph Spaceship["Spaceship (UK SIPP/ISA/Voyager/Nova/Super)"]
        Sp[v_spaceship_fees<br/>v_spaceship_aum<br/>v_spaceship_mimo<br/>bronze_spaceship_metabase_*]
    end

    subgraph MoneyFarm["MoneyFarm (UK managed investing)"]
        Mf[v_moneyfarm_aum<br/>v_moneyfarm_mimo<br/>bi_output_moneyfarm_*<br/>silver_moneyfarm_etoro_mf_aum]
    end

    subgraph Aff["Affiliate / partner"]
        Affc[Fact_AffiliateCommission<br/>fiktivo_AffiliateCommission_*]
    end

    subgraph LP["LP / cost-of-goods (NEGATIVE revenue)"]
        Lpfees[bi_dealing.bi_output_dealing_lp_fees_saxo<br/>...lp_fees_virtu_*<br/>...lp_fees_virtu_stamp_duty]
    end

    Fxd --> DDR[BI_DB_DDR_Fact_Revenue_Generating_Actions<br/>= canonical pre-aggregated revenue events<br/>keyed (DateID, RealCID, ActionTypeID, RevenueMetricID)]
    Tk1 --> DDR
    Roll --> DDR
    Div --> DDR
    Spot --> DDR
    Conv --> DDR
    Lend --> DDR
    Dorm --> DDR
    Int --> DDR
    AdmFee --> DDR
    Sdrt --> DDR

    DDR --> MV[etoro_kpi_prep.mv_revenue_trading<br/>materialized cross-fee trading revenue]
    Cash --> MV
    Tcf --> MV
    C2f --> MV
    Opt --> MV
    Stk --> MV

    MV --> DR[etoro_kpi_prep.v_ddr_revenues<br/>final analyst-facing revenue panel]
```

The **canonical pattern** is:

1. Each fee TYPE has its own `etoro_kpi_prep.v_revenue_<feetype>` view in
   Unity Catalog. Each isolates the per-customer revenue events for that
   fee type with the right product-specific quirks (rebates, exemptions,
   leverage scaling, etc.).
2. They feed into `etoro_kpi_prep.mv_revenue_trading` (materialized) which
   is the canonical "revenue per CID per day" rollup.
3. The DDR / `BI_DB_DDR_Fact_Revenue_Generating_Actions` is the Synapse-side
   equivalent for analysts who don't want to hit UC.
4. `Dim_Revenue_Metrics` defines what each `RevenueMetricID` MEANS — always
   join to it for human-readable metric names.

## Sub-skill routing

Each sub-skill below takes one fee family. Most questions hit a single
sub-skill; cross-fee questions ("trading + cashout + staking last quarter")
hit the canonical `mv_revenue_trading` materialization which already
unions them.

| Sub-skill | Fee family | Anchor | When to load |
|-----------|------------|--------|--------------|
| `trading-revenue-canonical.md` _(planned)_ | Cross-fee trading revenue | `mv_revenue_trading`, `BI_DB_DDR_Fact_Revenue_Generating_Actions`, `Dim_Revenue_Metrics` | "What did we earn from trading last month/quarter/year (all fees combined)" |
| `fees-trading-platform.md` _(planned)_ | Per-fee TP revenue | `v_revenue_commission`, `v_revenue_fullcommission`, `v_revenue_rollover`, `v_revenue_ticketfee_*`, `v_revenue_spotadjustfee`, `v_revenue_share_lending`, `v_revenue_dormantfee`, `v_revenue_interestfee`, `v_revenue_adminfee`, `v_revenue_sdrt`, `Function_Revenue_*` | Specific TP fee questions, e.g. "rollover fee revenue this month", "share-lending revenue last quarter" |
| `fees-emoney.md` _(planned)_ | eMoney / IBAN side fees | `v_revenue_conversionfee`, `v_revenue_conversionfee_withpositiondata`, eMoney exchange spread tables | "FX markup we earned from eMoney IBAN deposits", "OpenBanking conversion fee" |
| `fees-crypto-wallet.md` _(planned)_ | Crypto fees | `v_revenue_transfercoinfee`, `v_revenue_cryptotofiat_c2f`, `EXW_EthFeeSent_Blockchain`, `EXW_ETH_FeeData_Blockchain` | "Transfercoin fee revenue", "C2F revenue", "ETH gas fee charged" |
| `revenue-options-platform.md` _(planned)_ | Options fees | `v_revenue_optionsplatform`, `BI_DB_US_Apex_Fees_Charge` | Options/Apex revenue questions |
| `revenue-staking.md` _(planned)_ | Staking | `v_revenue_stakingfee`, `Staking.Staking*`, `EXW_dbo.Staking_*`, `BI_DB_Finance_Staking_Report`, `BI_DB_Staking_Platform_Compensations`, `BI_DB_PositionPnL_Agg_daily_Staking` | Staking rewards distribution, staking platform compensation, our cut |
| `revenue-spaceship.md` _(planned)_ | UK Spaceship (SIPP / ISA / Voyager / Nova / Super) | `v_spaceship_fees`, `v_spaceship_aum`, `v_spaceship_mimo`, `bronze_spaceship_metabase_*` | UK pension / ISA fees and AUM. Spaceship has multiple products: Voyager, Nova, Super. |
| `revenue-moneyfarm.md` _(planned)_ | MoneyFarm UK managed investing | `v_moneyfarm_aum`, `v_moneyfarm_mimo`, `bi_output_moneyfarm_fact_portfolio_snapshot`, `silver_moneyfarm_etoro_mf_aum` | MoneyFarm-specific fee/AUM questions. (Note: MoneyFarm FTDs ALSO appear in `BI_DB_DDR_Fact_MIMO_AllPlatforms` — that's a Payments view.) |
| `dividends-and-tax.md` _(planned)_ | Dividend pass-through + index dividend tax | `BI_DB_Index_Dividend_TaxReport*`, `BI_DB_DailyDividendsByPosition`, `BI_DB_Daily_CID_Dividend_TaxReport`, `BI_DB_IndexDividends_Alert`, `Trade.IndexDividends`, `v_revenue_dividend` | "Dividend revenue per regulation", "tax-withheld dividend report", index dividend reconciliation |
| `affiliate-commission.md` _(planned)_ | Affiliate / partner payouts | `Fact_AffiliateCommission`, `BI_DB_fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube`, `AffiliateCommission.*` | Affiliate-paid revenue share. **NEGATIVE revenue** from eToro POV (it's a cost of acquisition). |
| `lp-fees-and-cogs.md` _(planned)_ | LP (liquidity provider) fees + dealing COGS | `bi_dealing.bi_output_dealing_lp_fees_saxo`, `bi_dealing.bi_output_dealing_lp_fees_virtu_real_by_exchange`, `bi_dealing.bi_output_dealing_lp_fees_virtu_stamp_duty` | What we PAY brokers. Cost-of-goods, NEGATIVE revenue. Owned with Trading super-domain (broker-side). |

## Cross-cutting facts

- **`RevenueMetricID` is the master ID for "what kind of revenue is this".**
  Always join `BI_DB_dbo.Dim_Revenue_Metrics` to get the human-readable
  metric name + category + inclusion rules. Don't guess metric names.
- **`mv_revenue_trading` is the materialized cross-fee rollup**. Use it for
  "total trading revenue" questions. Don't UNION ALL the v_revenue_* views
  yourself — `mv_revenue_trading` already does that with the right rules.
- **Naming convention** in UC: `etoro_kpi_prep.v_revenue_<feetype>` for
  the per-fee primary view, `etoro_kpi.vg_ddr_revenue` for the gold-tier
  DDR rollup, `etoro_kpi_prep.mv_revenue_trading` for the materialized
  consolidation.
- **NEGATIVE-revenue items** (affiliate commission, LP fees, broker
  pass-through) are still "revenue events" in the metric framework but
  have negative values. Don't filter them out unless you specifically
  want gross-revenue-before-COGS.
- **DDR vs raw Synapse**: For SQL generation, prefer the UC `v_revenue_*`
  views (they have already-applied rules and bug fixes). Fall back to
  Synapse `BI_DB_DDR_Fact_Revenue_Generating_Actions` only if the UC view
  doesn't exist for that fee type or if you need a Synapse-only join.
- **`pipscalculation`** — production-side conversion math. Lives on
  `Fact_Deposit_State` / `Fact_Cashout_State` (Payments C.1). When per-deposit
  fee accuracy matters (audit, recon), use `pipscalculation` rather than
  recomputing from `(ExchangeRate - BaseExchangeRate) * Amount`.
- **Reversals on the fee side**: `BI_DB_DepositWithdrawFee_Reversals` carries
  pre-signed amounts. Refunds/chargebacks negative; chargeback-reversals
  positive. The reversal-type enum has 8+ values, don't naively filter on
  string match — use the wiki's lookup table.

## What this skill is NOT

- It does not own customer money flow (deposits/withdrawals AS VOLUMES) —
  that's Payments. We own the FEE EVENTS extracted from those transactions.
- It does not own bonuses or club perks — those are pay-OUT, not earned
  revenue. Compensation super-domain.
- It does not own GL / treasury / company-level financial reporting —
  Finance & Treasury super-domain. We feed THEIR pipelines but don't own
  the GL.

## Cluster provenance

This super-domain is a **cross-cluster collection** rather than a single
Louvain cluster. The fee/revenue tables are sprinkled across multiple
clusters by the join graph because each fee type has different join
partners, but the BUSINESS DOMAIN ("anything we charge or earn") is one
cohesive thing.

Anchor evidence:
- `BI_DB_DDR_Fact_Revenue_Generating_Actions` — Cluster 13 (DDR)
- `mv_revenue_trading` — Cluster 47 (Finance Recon, outflow)
- `v_revenue_*` family (~20 views) — scattered across kpi_prep
- Staking subgraph — Cluster ~ (EXW-related)
- Spaceship subgraph — Cluster 13 (DDR/MIMO)
- MoneyFarm subgraph — Cluster 13 (DDR/MIMO)
- Affiliate commission — Cluster ~ (separate)
- LP fees — Cluster ~ (Trading)

When a sub-skill is drafted, its cluster provenance gets recorded
specifically.

## Methodology note

This super-domain was created in response to feedback that fees are
NOT a payment concept — they are their own world joining from many
domains. The DDR fact (`BI_DB_DDR_Fact_Revenue_Generating_Actions`) and
the materialized `mv_revenue_trading` already do most of the cross-domain
join work. The skill family above mostly routes to those canonical
artifacts, with sub-skills dedicated to per-product quirks
(staking on-chain, spaceship Voyager/Nova split, moneyfarm portfolio
schema, etc.) that are NOT in the canonical rollups.
