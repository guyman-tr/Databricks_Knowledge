---
id: domain-revenue-and-fees
name: "Revenue & Fees Super-Domain"
description: "Cross-product revenue and fee accounting. Every kind of money eToro **earns or charges**, across every product line. Anchored on three canonical artefacts: (1) `BI_DB_DDR_Fact_Revenue_Generating_Actions` — the pre-aggregated daily revenue panel keyed by `(DateID, RealCID, RevenueMetricID, ActionTypeID, InstrumentTypeID)` covering 18 metrics in 5 categories (TradeTransactional, Overnight, MIMO, RevShare, Other) — best for grand-totals, KPI dashboards, IncludedInTotalRevenue logic; (2) `de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` — **THE most granular fee source** at position-action grain (98 columns including `Commission`, `FullCommission`, `RollOverFee`, `Dividend`, `SDRT`, `AdminFee`, `SpotAdjustFee`, `TicketFeeOpen`/`Close`, share-lending splits, conversion-fee triplet, cashout/transfercoin, copy amounts — for asset-specific / per-position / per-leverage / per-copy drill-downs this is fastest AND most granular, prefer it over DDR aggregation); (3) the `etoro_kpi_prep.v_revenue_*` view family (15 atomic per-fee views) and `etoro_kpi_prep.mv_revenue_trading` materialised cross-fee union — for fee-specific quirks and the fixed-vs-percent ticket-fee split. Incorporates the DataPlatform DE workspace skill `revenue` as authoritative content (the 18-metric dictionary, the 5-category bucketing, trade-classification flag logic). References the DE workspace skill `spaceship` as the source-of-truth for Spaceship product details. Load this hub for any question about WHAT eToro earned or charged and to be routed to the right fee-family sub-skill."
triggers:
  - revenue
  - fee
  - fees
  - total net revenue
  - how much did we make
  - how much did we earn
  - revenue breakdown
  - fee breakdown
  - revenue by stream
  - revenue by instrument
  - revenue by asset
  - revenue by product
  - commission
  - full commission
  - FullCommission
  - rollover
  - rollover fee
  - overnight fee
  - ticket fee
  - ticket fees
  - TicketFees
  - admin fee
  - AdminFee
  - spot adjust
  - SpotPriceAdjustment
  - conversion fee
  - cashout fee
  - transfercoin
  - redeem fee
  - crypto to fiat
  - C2F
  - dividend
  - dividend pass-through
  - index dividend
  - SDRT
  - UK stamp duty
  - dormant fee
  - interest fee
  - share lending
  - staking fee
  - staking revenue
  - PFOF
  - Options_PFOF
  - options revenue
  - apex fee
  - gatsby
  - spaceship revenue
  - spaceship fees
  - moneyfarm fees
  - trading revenue
  - non-trading revenue
  - IncludedInTotalRevenue
  - RevenueMetricID
  - RevenueMetricCategory
  - Dim_Revenue_Metrics
  - fact_customeraction_w_metrics
  - per-position fees
  - per-action fees
  - per-asset revenue
  - asset-specific fees
  - fee drilldown
  - fact_revenue_generating_actions
  - mv_revenue_trading
  - vg_ddr_revenue
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
  - main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics
  - main.etoro_kpi_prep.mv_revenue_trading
  - main.etoro_kpi.vg_ddr_revenue
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics
version: 1
owner: "guyman@etoro.com"
last_validated_at: "2026-05-10"
---

# Revenue & Fees Super-Domain

This super-domain owns **every kind of money eToro earns or charges**, across every product line and every acquired platform. It is intentionally horizontal because the same question — *"what did we earn from X?"*, *"what fee did we charge for Y?"* — has a different anchor object for each fee family, but the structure of the answer is identical.

The DDR layer (Daily Data Report) pre-aggregates **18 canonical revenue metrics** into `BI_DB_DDR_Fact_Revenue_Generating_Actions`. On top of that, the `etoro_kpi_prep.v_revenue_*` view family isolates **one fee type per view** with its product-specific quirks, and `etoro_kpi_prep.mv_revenue_trading` materialises the 8-component cross-fee trading rollup.

**For per-position / per-asset / per-leverage / per-copy drill-down at native action grain, the answer is almost always `de_output.de_output_etoro_kpi_fact_customeraction_w_metrics`** — 98 columns at position-action grain with every trading-platform direct-action fee as a NAMED COLUMN. Reach for it before the DDR fact when the question demands granularity below `(date × RealCID × metric × instrument-type)`. See the dedicated section below.

## When to Use

- "What's our total revenue last month / quarter / year?"
- "Revenue breakdown by stream / by category / by instrument type"
- "Which fee type generates the most revenue?"
- "Daily revenue trend"
- "Trading vs non-trading revenue split"
- Any specific fee question: rollover, ticket fees, commission, conversion fee, cashout fee, transfercoin, C2F, share lending, staking, dormant, options PFOF, dividends, SDRT, etc.
- "Revenue from a specific asset / instrument / position / copy trade / leverage bucket" — route to H.1 `trading-revenue-and-fees.md` which uses `fact_customeraction_w_metrics` for the granular drilldown
- "Spaceship / MoneyFarm / Options-platform revenue" — route to the regional sub-skills (H.5 Options, H.6 Spaceship, H.7 MoneyFarm)
- Any question about fee definitions, revenue composition, `IncludedInTotalRevenue` logic, `RevenueMetricID` lookups, or the canonical 18-metric framework
- Apex / Gatsby disambiguation (Options product vs broker identity)

**NOT for this skill:**

- Customer money MOVEMENT (deposits, withdrawals, MIMO volumes) → **Payments super-domain (C)**. We own the FEE EVENTS extracted from those transactions, not the gross dollar flows.
- Bonuses, club perks, manual compensation paid TO customers → **Compensation super-domain** (planned).
- GL / treasury / company-level finance reporting → **Finance & Treasury super-domain (E)**. We feed their pipelines but don't own the GL.
- Affiliate commission — **not revenue**. It's either a cost-of-acquisition (affiliate-paid-out) or a sub-component of general commission revenue (the partner share already embedded in `FullCommission`). Do not single it out.
- LP fee reconciliations (`bi_dealing.bi_output_dealing_lp_fees_*` family — Saxo, Virtu daily-fee recons) — **not revenue and not COGS in the accounting sense**. They are operational recons: dealing-team artefacts that match what LPs invoice us against what our internal trade records say. They are NOT booked into the revenue / cost-of-goods framework. Route those questions to the Trading super-domain (`dealing_dbo` / dealing recon), not here.

## Scope

In scope: All 18 revenue/fee metrics in `Dim_Revenue_Metrics`, the DDR fact and its derivatives (`vg_ddr_revenue`, `mv_revenue_trading`), the 15 `etoro_kpi_prep.v_revenue_*` atomic per-fee views, the per-action granular `de_output_etoro_kpi_fact_customeraction_w_metrics`, regional revenue surfaces (Spaceship, MoneyFarm, Options/Apex), share-lending revenue splits, staking lag mechanics, dividend pass-through and SDRT, the `IncludedInTotalRevenue` semantics, and `Total Net Revenue` calculation.
Out of scope: Customer money flow as VOLUMES (Payments super-domain owns deposits / withdrawals / cashouts / MIMO panel), bonuses paid out (Compensation), treasury / GL / company-level finance (Finance & Treasury), affiliate commission (per-domain decision: ignored — folded into FullCommission as partner-share, or treated as marketing cost), LP-fee reconciliation tables (`bi_dealing.bi_output_dealing_lp_fees_*` — operational dealing recon, not a revenue / COGS line; belongs in Trading super-domain).
Last verified: 2026-05-10

## Critical Warnings

1. **Tier 1 — `SUM(Amount)` without `IncludedInTotalRevenue = 1` silently double-counts and produces wrong totals.** The DDR fact contains `Commission` (a subset of `FullCommission` — excluding partner share), `Dividends` (paid TO customers, often negative), and `SDRT` (UK tax collected, not earned). All three have `IncludedInTotalRevenue = 0`. Always filter `WHERE IncludedInTotalRevenue = 1` for total-revenue numbers.
2. **Tier 1 — `Metric IN ('FullCommission', 'Commission')` double-counts.** `Commission` is a SUBSET of `FullCommission` (excludes partner share). Pick ONE. Same trap applies inside `fact_customeraction_w_metrics`: `FullCommissionTotal = FullCommission + FullCommissionOnClose` and `CommissionTotal = Commission + CommissionOnClose` — sum only one family per KPI.
3. **Tier 1 — `GROUP BY InstrumentTypeID` without excluding `-1` pollutes the breakdown.** Account-level fees (`ConversionFee`, `DormantFee`, `CashoutFee`, `InterestFee`) have `InstrumentTypeID = -1` (sentinel for "not applicable"). Always `WHERE InstrumentTypeID != -1` for per-instrument splits.
4. **Tier 1 — `StakingLagOneMonth` is lagged 1 month.** It lands in the FOLLOWING month's `DateID`, not when earned. If you do "revenue in March 2026" without considering this, February's staking revenue shows up in March. Document the lag in any time-series.
5. **Tier 1 — `CountTransactions` is NULL for `ShareLending` and `StakingLagOneMonth`** — these are not per-transaction streams. Don't compute "average revenue per transaction" for these metrics.
6. **Tier 1 — `fact_customeraction_w_metrics` has 98 columns of which ~30 are fee/amount columns.** Do NOT `SELECT *` and `SUM` everything — many columns are mutually exclusive (e.g. a position-open row has `TicketFeeOpen` populated and `TicketFeeClose = 0`, and vice versa). Sum only the columns relevant to the fee family in the question.
7. **Tier 2 — `TicketFee` and `TicketFeeByPercent` are being CONSOLIDATED into a single `TicketFees` metric in `fact_customeraction_w_metrics` (and going forward in the DDR fact too).** The canonical fact carries one `TicketFees` value going forward — no fixed-vs-percent split at the row level. The atomic views `etoro_kpi_prep.v_revenue_ticketfee_fixed` and `etoro_kpi_prep.v_revenue_ticketfee_bypercent` retain the breakdown — drop down to them if and only if the question explicitly requires the fixed-vs-percent split. Do NOT `GROUP BY` a `TicketFee` vs `TicketFeeByPercent` distinction inside the canonical fact going forward — that distinction no longer exists there.
8. **Tier 2 — `mv_revenue_trading` already unions 8 trading fees.** Don't `UNION ALL` the `v_revenue_*` views manually — the materialisation has the right rules and bug fixes baked in.
9. **Tier 2 — `de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` is the most granular source AND the fastest** for asset-specific drill-down (per-position, per-instrument, per-copy, per-leverage). For "what's our crypto vs stocks ticket-fee revenue per asset" use this table, NOT the DDR fact. The DDR is aggregated at `(date × RealCID × metric × instrumentType)` — it has lost the per-position grain you need.
10. **Tier 2 — DDR fact has ~3.1 billion rows** — always filter `WHERE DateID BETWEEN ... AND ...`. Same rule for `mv_revenue_trading` and `vg_ddr_revenue`.
11. **Tier 2 — `mv_revenue_trading` is trading-side only (8 fee components: FullCommission, Rollover, TicketFee*, AdminFee, SpotAdjust, ConversionFee w/ position-data, Share-Lending).** It does NOT contain MIMO-side fees from non-position events (the deposit/withdraw fee tables), nor crypto-wallet fees (TransferCoin / C2F), nor staking revenue. For "everything we earned" use the DDR fact.
12. **Tier 3 — `InterestFee` is deprecated post-Jul-2023.** Historical margin interest, largely zero from Aug 2023 onwards. Mention it for back-fill questions only.
13. **Tier 3 — `Options_PFOF` only started October 2025.** `Dim_Revenue_Metrics.UpdateDate = 2025-10-22` for this row. Don't pre-date its existence.
14. **Tier 3 — `Dividends` rows can be negative** when an instrument distributes a tax-withheld or rebated amount. Sentinel `IsBuy` is overridden to 1 if `Amount > 0` and 0 if `Amount < 0` for dividends.
15. **Tier 3 — Spaceship fees do NOT flow into the DDR fact.** Spaceship has its own `etoro_kpi.v_spaceship_fees` view (Super management fees, Voyager management fees, Nova platform + FX). Same for MoneyFarm and Options/Apex — each regional acquisition has its own fee surface. The DDR fact is **eToro-native trading only**.
16. **Tier 3 — `fact_customeraction_w_metrics` columns `ConversionFeeDeposit`, `ConversionFeeWithdraw`, `ConversionFeeReversal` are three SEPARATE columns** — the DDR metric `ConversionFee` is the sum. If you need the directional split (deposit-side vs withdraw-side), use the w_metrics table directly.
17. **Tier 3 — `bi_dealing.bi_output_dealing_lp_fees_*` (Saxo / Virtu daily fee recons) are NOT revenue and NOT COGS** in the accounting sense. They are operational dealing-team recons matching LP invoices against internal trade records. Do not query them from this skill — route to the Trading super-domain.

---

## Mental model — fee families and their anchor objects

```mermaid
graph TB
    subgraph TP["Trading-platform fees (eToro-native)"]
        direction TB
        WM[fact_customeraction_w_metrics<br/><b>THE per-action granular source</b><br/>98 columns, per-position grain]
        FC[v_revenue_fullcommission / v_revenue_commission]
        TF[v_revenue_ticketfee_fixed<br/>v_revenue_ticketfee_bypercent<br/><i>fixed/percent split available here only</i>]
        RO[v_revenue_rollover]
        AD[v_revenue_adminfee]
        SA[v_revenue_spotadjustfee]
        SD[v_revenue_sdrt]
        DV[v_revenue_dividend]
        MV[mv_revenue_trading<br/><b>materialised 8-fee union</b>]
    end

    subgraph MIMO["MIMO-side fees (deposit/withdraw/FX)"]
        direction TB
        CO[v_revenue_conversionfee<br/>v_revenue_conversionfee_withpositiondata]
        CA[v_revenue_cashoutfee_excluderedeem<br/>v_revenue_cashoutfee_incredeem]
        TC[v_revenue_transfercoinfee]
        C2F[v_revenue_cryptotofiat_c2f]
        DWF[bi_db_depositwithdrawfee<br/>bi_db_depositwithdrawfee_reversals]
    end

    subgraph RS["Rev-share / yield"]
        direction TB
        SL[v_revenue_share_lending<br/><i>40/40/20 eToro/user/broker split</i>]
        ST[v_revenue_stakingfee<br/><i>1-month lag — lands month+1</i>]
    end

    subgraph OT["Other fees"]
        direction TB
        DF[v_revenue_dormantfee]
        IF[v_revenue_interestfee<br/><i>deprecated post Jul-2023</i>]
        OP[v_revenue_optionsplatform<br/><i>Options_PFOF — since Oct 2025</i>]
    end

    subgraph REG["Regional acquired-platform revenue"]
        direction TB
        SS[v_spaceship_fees<br/>Super / Voyager / Nova<br/><b>defer to DE skill</b>]
        MF[v_moneyfarm_fees<br/>UK managed investing]
        APX[v_revenue_optionsplatform<br/>+ Apex SFTP feed]
        WF[WealthFrance — not ingested]
    end

    WM --> DDR[BI_DB_DDR_Fact_Revenue_Generating_Actions<br/><b>canonical pre-aggregated panel</b><br/>18 metrics × 5 categories<br/>keyed (DateID, RealCID, RevenueMetricID, ActionTypeID, InstrumentTypeID)]
    FC --> DDR
    TF --> DDR
    RO --> DDR
    AD --> DDR
    SA --> DDR
    SD --> DDR
    DV --> DDR
    CO --> DDR
    CA --> DDR
    TC --> DDR
    C2F --> DDR
    SL --> DDR
    ST --> DDR
    DF --> DDR
    IF --> DDR
    OP --> DDR

    DDR --> VG[vg_ddr_revenue<br/><i>view with InstrumentType + Category names</i>]
    DDR --> MV

    DWF -.-> CO

    SS -.->|"Spaceship rolls up to<br/>BI_DB_DDR_Fact_AUM / MIMO"| OUTAUM[BI_DB_DDR_Fact_AUM<br/>BI_DB_DDR_Fact_MIMO_AllPlatforms]
    MF -.->|"MoneyFarm rolls up similarly"| OUTAUM
```

## Sub-skill routing

Each sub-skill takes one fee family. Most questions hit a single sub-skill; cross-fee questions ("trading + cashout + staking last quarter") hit `mv_revenue_trading` for the trading slice plus the DDR fact for the rest.

| Sub-skill | Fee family | Primary anchor | When to load |
|-----------|------------|----------------|--------------|
| **H.1** `trading-revenue-and-fees.md` | Trading-platform fees: FullCommission, Commission, TicketFees, RollOverFee, AdminFee, SpotPriceAdjustment, Dividends, SDRT — **AND the per-action granular drill-down** | `de_output_etoro_kpi_fact_customeraction_w_metrics`, `mv_revenue_trading`, DDR fact, `v_revenue_{fullcommission, commission, ticketfee_fixed, ticketfee_bypercent, rollover, adminfee, spotadjustfee, dividend, sdrt}` | Any per-asset / per-position / per-copy / per-leverage / per-instrument trading-fee question. ALSO: TradeTransactional + Overnight category questions. |
| **H.2** `fees-deposit-withdraw-fx.md` | MIMO-side fees: ConversionFee, CashoutFeeExclRedeem, TransferCoinFee, CryptoToFiatFee + raw deposit/withdraw fee tables | `v_revenue_{conversionfee, conversionfee_withpositiondata, cashoutfee_excluderedeem, cashoutfee_incredeem, transfercoinfee, cryptotofiat_c2f}`, `bi_db_depositwithdrawfee`, `bi_db_depositwithdrawfee_reversals` | FX-conversion markup, cashout fees, crypto transfer fees, crypto-to-fiat fees, fee reversals/refunds |
| **H.3** `revenue-staking-and-share-lending.md` | StakingLagOneMonth, ShareLending | `v_revenue_stakingfee`, `v_revenue_share_lending`, `bi_db_finance_staking_report`, Synapse `Staking.*` | Staking rewards distribution, share-lending revenue (40/40/20 split), the 1-month staking lag mechanics |
| **H.4** `fees-misc-dormant-options-interest.md` | DormantFee, Options_PFOF, InterestFee (deprecated) | `v_revenue_{dormantfee, interestfee, optionsplatform}` | Inactivity fees, options PFOF, deprecated margin-interest |
| **H.5** `revenue-options-platform.md` | Options product revenue end-to-end — Gatsby brand, Apex broker (= USABroker), Apex SFTP fees | `v_revenue_optionsplatform`, `etoro_kpi_prep.v_options_aum`, `etoro_kpi_prep.v_mimo_options_platform`, `finance.bronze_sodreconciliation_apex_ext1047_revenuereports`, `finance.bronze_usabroker_apex_*` | Any Options product question. **Gatsby = brand, Apex = broker.** US-equity rows from Apex land in regular trading tables (`Dim_Position`, etc.) — NOT in this sub-skill. |
| **H.6** `revenue-spaceship.md` | Spaceship — AU acquisition (Super / Voyager / Nova / Money) | `v_spaceship_fees`, `v_spaceship_aum`, `v_spaceship_mimo` — **thin router; defer to DE workspace skill** | Australian acquisition with its own 53-table source + KPI dashboard. Authoritative content lives in DE workspace skill `/Workspace/.assistant/skills/spaceship` and in `knowledge/uc_domains/spaceship/_domain_card.md`. |
| **H.7** `revenue-moneyfarm.md` | MoneyFarm — UK managed investing | `v_moneyfarm_{aum, mimo, fees}`, `bi_output_moneyfarm_*`, `money_farm.silver_moneyfarm_etoro_mf_aum`, `general.bronze_moneyfarm_users` | UK managed-investing platform. Source: CosmosDB document store. Owned here (no DE skill). Anchored to `knowledge/uc_domains/moneyfarm/_domain_card.md`. |

**Affiliate commission is intentionally excluded** — it is not revenue. It is either a marketing cost (affiliate-paid-out) or already embedded in the partner-share component of `FullCommission`. If a question explicitly asks about affiliate-paid amounts, point at `Fact_AffiliateCommission` directly but explain it's a cost, not revenue.

**LP fee recons (`bi_dealing.bi_output_dealing_lp_fees_*`) are intentionally excluded** — Saxo / Virtu daily fee recons are dealing-team operational artefacts matching LP-invoiced fees against internal trade records. They are neither revenue nor a COGS-accounting line. Route those questions to the Trading super-domain (dealing recon).

**WealthFrance** — French managed-investing acquisition, **not yet ingested into UC**. Mention but do not fabricate tables.

## DE workspace skills incorporated / referenced

| DE workspace skill | Disposition | Notes |
|--------------------|-------------|-------|
| `/Workspace/.assistant/skills/revenue` | **INCORPORATED** (this hub supersedes it after deployment) | 215-line DE skill with the 18-metric dictionary, 3-layer architecture, trade-classification flag tables (IsSettled / IsCopy / IsICC / IsSQF / IsMarginTrade), and SettlementTypeID / ActionTypeID / IsFeeDividend / CompensationReasonID lookups. All ported into this hub and H.1. |
| `/Workspace/.assistant/skills/spaceship` | **REFERENCED** (authoritative for Spaceship product detail) | 6 sub-files, 53 source tables, ETL pipeline, weekly KPI dashboard. Too deep to replicate. Same pattern as `customer-populations` / `registration-to-ftd-funnel` references in the Customer & Identity hub. |

---

## Revenue metrics dictionary — `Dim_Revenue_Metrics` ground truth

Source: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics` — 18 rows.

| ID | Metric (exact value) | Category | In Total? | What it is |
|----|----------------------|----------|-----------|------------|
| 1 | `FullCommission` | TradeTransactional | ✅ Yes | Spread markup on trades INCLUDING partner/affiliate share. Primary driver (~60% of total revenue). |
| 2 | `Commission` | TradeTransactional | ❌ No | Spread markup EXCLUDING partner share. Subset of `FullCommission`. Informational only. |
| 3 | `TicketFee` | TradeTransactional | ✅ Yes | Fixed ticket fee per trade. **CONSOLIDATING — see Critical Warning #8.** |
| 4 | `TicketFeeByPercent` | TradeTransactional | ✅ Yes | Percentage ticket fee on notional. **CONSOLIDATING — see Critical Warning #8.** |
| 5 | `RollOverFee` | Overnight | ✅ Yes | Overnight financing fee for CFD / FX positions held past close. |
| 6 | `SpotPriceAdjustment` | Overnight | ✅ Yes | Spot-price adjustment fee. `CompensationReasonID = 118`. |
| 7 | `AdminFee` | Overnight | ✅ Yes | Administrative fee. `CompensationReasonID = 117`. |
| 8 | `CashoutFeeExclRedeem` | MIMO | ✅ Yes | Fee on fiat withdrawals, excludes crypto redeem. |
| 9 | `TransferCoinFee` | MIMO | ✅ Yes | Crypto transfer fee (`ActionTypeID = 30`, `IsRedeem = 1`). |
| 10 | `ConversionFee` | MIMO | ✅ Yes | FX markup on deposit / withdrawal currency conversion vs USD. |
| 11 | `CryptoToFiatFee` | MIMO | ✅ Yes | Crypto-to-fiat conversion fee (C2F). |
| 12 | `StakingLagOneMonth` | RevShare | ✅ Yes | Crypto-staking revenue. **Lagged 1 month** — lands in `DateID` of the following month. |
| 13 | `ShareLending` | RevShare | ✅ Yes | Revenue from lending real stocks to short-sellers. **40/40/20 split** (eToro / user / broker). |
| 14 | `DormantFee` | Other | ✅ Yes | Monthly inactivity fee. `CompensationReasonID = 30`. |
| 15 | `InterestFee` | Other | ✅ Yes | Historical margin interest. **Largely discontinued after Jul 2023.** |
| 16 | `Dividends` | Other | ❌ No | Dividends paid TO customers on real stocks. Can be negative. Not earned by eToro — pass-through. |
| 17 | `SDRT` | Other | ❌ No | UK Stamp Duty Reserve Tax. Tax COLLECTED, not fee earned. Pass-through to HMRC. |
| 18 | `Options_PFOF` | Other | ✅ Yes | Payment For Order Flow from options routing. **Added 2025-10-22** — does not exist in earlier data. |

**Total Net Revenue** = `SUM(Amount) WHERE IncludedInTotalRevenue = 1` against the DDR fact.

**Footnote — TicketFee consolidation (Critical Warning #8):** Storage of `TicketFee` vs `TicketFeeByPercent` is being consolidated into a single `TicketFees` metric in `de_output_etoro_kpi_fact_customeraction_w_metrics` going forward, and the same change is planned for the DDR fact. The atomic views `etoro_kpi_prep.v_revenue_ticketfee_fixed` and `etoro_kpi_prep.v_revenue_ticketfee_bypercent` retain the fixed-vs-percent breakdown — drop down to them only if the question explicitly requires the split.

### Categories — the 5-bucket grouping in `Dim_Revenue_Metrics.RevenueMetricCategoryID`

| ID | Category | Metrics |
|----|----------|---------|
| 1 | TradeTransactional | FullCommission, Commission, TicketFee, TicketFeeByPercent |
| 2 | Overnight | RollOverFee, SpotPriceAdjustment, AdminFee |
| 3 | MIMO | CashoutFeeExclRedeem, TransferCoinFee, ConversionFee, CryptoToFiatFee |
| 4 | RevShare | StakingLagOneMonth, ShareLending |
| 5 | Other | DormantFee, InterestFee, Dividends, SDRT, Options_PFOF |

Use these categories for the canonical "Trading vs Non-Trading revenue" split:
- **Trading Revenue** = categories 1 + 2 (TradeTransactional + Overnight)
- **Non-Trading Revenue** = categories 3 + 4 + 5 (MIMO + RevShare + Other)

### Trade classification flags (in DDR fact and `mv_revenue_trading`)

| Flag | Meaning | How determined |
|------|---------|----------------|
| `IsSettled` | 1 = real asset (stocks / ETFs / crypto with ownership); 0 = CFD; -1 = N/A (account-level fee) | `SettlementTypeID` or fallback `IsBuy = 1 AND Leverage = 1 AND TypeID IN (10, 5, 6)` |
| `IsCopy` | 1 = copy-trade | `MirrorID > 0` |
| `IsCopyFund` | 1 = Smart Portfolio | `MirrorTypeID = 4` |
| `IsICC` | 1 = ICC instrument | `IsFuture = 1 OR InstrumentTypeID IN (1, 2, 4)` |
| `IsSQF` | 1 = Sustainable & Quality-Focused instrument | Instrument in `GroupID = 59` |
| `IsMarginTrade` | 1 = margin trade | `SettlementTypeID = 5` |
| `IsBuy` | 1 = long, 0 = short, -1 = N/A | Source position direction; overridden for dividends to match `Amount` sign |
| `IsLeveraged` | 1 = leveraged trade | `Leverage > 1` |
| `IsFuture` | 1 = futures contract | From source or `Dim_Instrument.IsFuture` |
| `IsAirDrop` | 1 = free-share airdrop | From revenue function; excluded from active-trade counts |
| `IsOpenedFromIBAN`, `IsClosedToIBAN` | Position opened from / closed to eMoney IBAN | UPDATE-JOIN from external parquet tables |
| `IsRecurring` | Recurring-investment position | UPDATE-JOIN from `recurringinvestment_positions_parquet` |
| `IsC2P` | Copy-to-Portfolio | `V_C2P_Positions.PositionID IS NOT NULL` |

### `InstrumentTypeID` values

| ID | Type | Notes |
|----|------|-------|
| -1 | N/A (account-level fee) | `DormantFee`, `ConversionFee`, `CashoutFee`, `InterestFee` have no instrument |
| 1 | Stocks | |
| 2 | Currencies (FX) | |
| 3 | Commodities | |
| 4 | Indices | |
| 5 | Crypto | |
| 6 | ETFs | |

### Reference lookups (used in the source `fact_customeraction` and TVFs)

**`ActionTypeID`** (in `fact_customeraction_w_metrics.ActionTypeID`):
| Value | Meaning |
|-------|---------|
| 1, 2, 3, 39 | Position opens |
| 4, 5, 6, 28, 40 | Position closes |
| 30 | Cashout / withdraw |
| 35 | Fee / dividend (use `IsFeeDividend` to disambiguate) |
| 36 | Compensation / admin (use `CompensationReasonID` to disambiguate) |

**`IsFeeDividend`** (for `ActionTypeID = 35`):
| Value | Revenue type |
|-------|--------------|
| 1 | RolloverFee |
| 2 | Dividend |
| 4 | TicketFee (fixed or by-percent — distinction not preserved going forward) |
| 5 | SDRT |

**`CompensationReasonID`** (for `ActionTypeID = 36`):
| Value | Revenue type |
|-------|--------------|
| 30 | DormantFee |
| 117 | AdminFee |
| 118 | SpotAdjustFee |
| 119 | ShareLending |

**`SettlementTypeID`** (instrument settlement class):
| Value | Meaning |
|-------|---------|
| 0 | CFD |
| 1 | Real asset |
| 2 | TRS (Total Return Swap) |
| 3 | CMT (crypto settled) |
| 4 | Real futures |
| 5 | Margin trade |

---

## Special honour — `fact_customeraction_w_metrics` as THE per-action granular source

For any question that needs to drill below the DDR fact's aggregation grain — *per-position*, *per-asset*, *per-leverage-bucket*, *per-copy-status*, *per-IBAN-flag*, *per-mirror-target* — go straight to **`main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics`**. It is:

1. **At native position-action grain** — one row per customer-action event (a position open, a position close, a fee event). The DDR fact is aggregated at `(DateID × RealCID × Metric × InstrumentTypeID × flags)` — it has already lost the per-position dimension.
2. **The fastest source** for granular drill-down — purpose-built for KPI queries with the right partitioning.
3. **Every trading-platform direct-action fee is a NAMED COLUMN** (no `GROUP BY Metric` needed):
   - `Commission`, `FullCommission`, `CommissionOnClose`, `FullCommissionOnClose`, `CommissionTotal`, `FullCommissionTotal`
   - `RollOverFee`, `Dividend`, `SDRT`, `AdminFee`, `SpotAdjustFee`
   - `TicketFeeOpen`, `TicketFeeClose` *(consolidating — see Critical Warning #8)*
   - `ConversionFeeDeposit`, `ConversionFeeWithdraw`, `ConversionFeeReversal`
   - `CashoutFeeExludingRedeem`, `TransferCoinFee`, `DormantFee`
   - `ShareLendingFeeEtoroShare`, `ShareLendingFeeUserShare`, `ShareLendingFeeBrokerShare`, `ShareLendingGrossAmount`
4. **Carries the full position context inline** — `PositionID`, `InstrumentID`, `MirrorID` (copy-source), `Leverage`, `IsBuy`, `OpenDateID` / `CloseDateID`, `VolumeOpen` / `VolumeClose`, `NetProfit`, `IsActiveTrade`, `IsCopyFund`, `IsSQF`, `IsRedeem`, `IsAirDrop`, `IsFTD`, plus the IBAN flags `IsOpenFromIBAN` / `IsClosedToIBAN` and the recurring / C2P flags.
5. **Maintains the same `IsBuy`, `IsCopy` (via `MirrorID`), `IsLeveraged` semantics** as the DDR fact — flag interpretation transfers directly.

**Routing rule:** if the question can be answered at the `(date × CID × metric × instrument-type)` aggregation, use the DDR fact (cheaper / smaller). If the question demands per-position / per-asset / per-copy-mirror / per-leverage-bucket granularity, use `fact_customeraction_w_metrics`. This routing rule is reinforced and exemplified inside H.1 `trading-revenue-and-fees.md`.

---

## Regional acquired products — DO NOT GUESS

Each regional product is its own UC domain with a curated `_domain_card.md`. **Read the card before writing SQL or describing the product.** All heavy lifting is already done there.

| Product | Region | UC domain card | Status | Notes |
|---------|--------|----------------|--------|-------|
| **Spaceship** | Australia | `knowledge/uc_domains/spaceship/_domain_card.md` | Ingested (`spaceship.*`, 53 tables) | Four product lines: Super (superannuation — NOT UK SIPP), Voyager (goal-based investing), Nova (newer, US-flavoured), Money (cash wallet). Source: Spaceship-side BigQuery + Metabase. **DE workspace skill `/Workspace/.assistant/skills/spaceship` is authoritative.** |
| **MoneyFarm** | UK | `knowledge/uc_domains/moneyfarm/_domain_card.md` | Ingested (`bi_output_moneyfarm_*`, `money_farm.silver_*`, `general.bronze_moneyfarm_*`) | UK managed investing — the UK equivalent of Spaceship. Source: MoneyFarm-side CosmosDB document store (different contract from Spaceship's BigQuery). KPI views live in `etoro_kpi_prep.v_moneyfarm_*` (NOT `etoro_kpi` like Spaceship). |
| **Options (Gatsby + Apex)** | US | _(see H.5 sub-skill)_ | Ingested via Apex SFTP | Gatsby = product brand; Apex (= USABroker) = broker. Two ingest paths: Options → Apex SFTP → `v_revenue_optionsplatform`; US-equity → regular trading tables. See disambiguation below. |
| **WealthFrance** | France | _(not yet ingested)_ | Acquired, no UC schema | French equivalent of MoneyFarm. Mention but do not invent tables. |
| **Zengo** | _various_ | _(not yet ingested)_ | Acquired, no UC schema | Out of scope until ingest lands. |

## Apex / Gatsby disambiguation

`Apex` and `Gatsby` appear in some legacy wiki text as if they were two brokers. They are NOT. Lock this in before answering any Options or US-stocks question:

- **Gatsby** = the eToro Options product (acquired). A **product brand**, not a broker. Gatsby-side systems were **never ingested** into the lake.
- **Apex** = the actual broker (= **USABroker**). Apex feeds the lake via daily SFTP reports.
- **Two ingest paths off the same broker:**
  - **Gatsby Options** → Apex SFTP → `etoro_kpi_prep.v_revenue_optionsplatform`, the `finance.bronze_sodreconciliation_apex_*` family, and the Apex options-status / userdata reference tables. **Options revenue (Options_PFOF) lives here.**
  - **US-resident customer equities** (regular stock trading for US customers cleared by Apex) → **regular trading tables** (`Dim_Position`, `Fact_Position`, etc.). Same broker, ordinary trading pipeline. No "Apex" silo for US equities.
- Therefore: **never claim US-equity revenue lives under Options/Gatsby**, and never claim Gatsby has its own ingest. See H.5 for the full Options skill.

---

## Cross-cutting facts

- **`RevenueMetricID` is the master ID for "what kind of revenue is this."** Always join `BI_DB_dbo.Dim_Revenue_Metrics` for human-readable names and `IncludedInTotalRevenue` semantics. Don't hardcode metric strings — the dictionary is the source of truth.
- **The 18-metric dictionary is stable** but evolves: `Options_PFOF` was added 2025-10-22. New revenue surfaces (when added) will appear here first.
- **`mv_revenue_trading` covers 8 trading components** (FullCommission, RollOverFee, TicketFee*, AdminFee, SpotAdjust, ConversionFee w/ position-data, Share-Lending). Use it for "total trading revenue" or trading-side breakdowns. Don't UNION ALL the atomic views yourself.
- **`vg_ddr_revenue`** is the analyst-friendly view: same data as the DDR fact, but with `InstrumentType` and `RevenueMetricCategory` resolved to NAMES (no need to join `Dim_Revenue_Metrics` for category breakdown).
- **Naming convention** in UC: `etoro_kpi_prep.v_revenue_<feetype>` for per-fee atomic views; `etoro_kpi.vg_ddr_revenue` for the gold-tier DDR rollup; `etoro_kpi_prep.mv_revenue_trading` for the materialised trading union.
- **Negative-revenue items** (share-lending broker share, dividend rebates) are still "revenue events" in the metric framework but have negative values. Don't filter them out unless the question specifically asks for gross-revenue-only.
- **DDR vs raw Synapse:** prefer the UC artefacts (`vg_ddr_revenue`, `mv_revenue_trading`, `v_revenue_*`). Fall back to Synapse `BI_DB_DDR_Fact_Revenue_Generating_Actions` only if needed for Synapse-only joins.
- **Broker / LP identity is NOT in this skill.** Cross-broker questions ("which LP charged X?", "what's the hedge mapping for instrument Y?") resolve through `dealing_dbo` (hedge server + LP IDs) — Trading & Markets super-domain. Payment-side `BankName` / `MID` / `PaymentProviderName` are PSP identities, NOT broker identities; do not conflate.
- **`pipscalculation`** is the production-side conversion math. It lives on `Fact_Deposit_State` / `Fact_Cashout_State` in the Payments super-domain. When per-deposit fee accuracy matters (audit, recon), use `pipscalculation` rather than recomputing from `(ExchangeRate - BaseExchangeRate) * Amount`.
- **Reversals on the fee side:** `bi_db.gold_*_bi_db_depositwithdrawfee_reversals` carries pre-signed amounts. Refunds / chargebacks are negative; chargeback-reversals are positive. The reversal-type enum has 8+ values — don't naively filter on string match.

## What this skill is NOT

- It does NOT own customer money flow as VOLUMES (deposits / withdrawals / MIMO) — that's the **Payments super-domain (C)**. We own the FEE EVENTS extracted from those transactions, not the gross dollar flows.
- It does NOT own bonuses, club perks, manual compensation paid TO customers — that's the **Compensation super-domain** (planned).
- It does NOT own GL / treasury / company-level financial reporting — that's the **Finance & Treasury super-domain (E)**. We feed their pipelines but don't own the GL.
- It does NOT own **affiliate commission** — per explicit decision, this is treated as either a cost-of-acquisition (affiliate-paid-out → marketing cost) or already embedded in the partner-share component of `FullCommission`. Not revenue.
- It does NOT own **LP fee recons** (`bi_dealing.bi_output_dealing_lp_fees_*` — Saxo, Virtu daily fee recons). Those are operational dealing-team artefacts (matching LP invoices against internal trade records), neither revenue nor COGS — route to Trading super-domain.
- It does NOT own **broker / LP identity**. Broker / LP mapping lives in the Trading super-domain (`dealing_dbo`).

## Cluster provenance

This super-domain is a **cross-cluster collection** rather than a single Louvain cluster. The fee/revenue tables are sprinkled across multiple clusters because each fee type has different join partners, but the BUSINESS DOMAIN ("anything we charge or earn") is one cohesive thing. Anchor evidence:

- `BI_DB_DDR_Fact_Revenue_Generating_Actions` — Cluster 13 (DDR)
- `fact_customeraction_w_metrics` — Cluster 13 (DDR — sits alongside the DDR fact)
- `mv_revenue_trading` — Cluster 47 (Finance Recon, outflow)
- `v_revenue_*` family (~15 views) — scattered across `etoro_kpi_prep`
- Staking subgraph — separate sub-cluster (EXW-related)
- Spaceship subgraph (AU) — Cluster 13 (DDR/MIMO); see `knowledge/uc_domains/spaceship/_domain_card.md`
- MoneyFarm subgraph (UK) — Cluster 13 (DDR/MIMO); see `knowledge/uc_domains/moneyfarm/_domain_card.md`
- Options / Apex subgraph — `finance.*` + `bi_db.bronze_sodreconciliation_apex_*`

When a sub-skill is drafted, its cluster provenance is recorded in the sub-skill front matter.

## Methodology note

This super-domain was created in response to the insight that fees are **NOT a payment concept** — they are their own world joining from many domains. The DDR fact and the materialised `mv_revenue_trading` already do most of the cross-domain join work. The sub-skill family above mostly routes to those canonical artefacts, with sub-skills dedicated to per-product quirks (staking on-chain, Spaceship Voyager/Nova split, MoneyFarm portfolio schema, Apex SFTP feed) that are NOT in the canonical rollups.

The DataPlatform DE workspace skill `revenue` (215 lines, version 2, validated 2026-05-07) was incorporated VERBATIM for the 18-metric dictionary, the 5-category bucketing, the trade-classification flag definitions, and the `ActionTypeID` / `IsFeeDividend` / `CompensationReasonID` lookups. After deployment of this hub to `/Workspace/Users/guyman@etoro.com/.assistant/skills/dwh-domain/domain-revenue-and-fees/`, the DE workspace `revenue` skill is intended to be superseded.

The DataPlatform DE workspace skill `spaceship` (6 sub-files, 53 source tables, KPI dashboard reference) is REFERENCED as authoritative for Spaceship product detail. Our H.6 sub-skill is a thin router.
