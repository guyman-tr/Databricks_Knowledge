---
name: domain-aum-and-aua
description: |
  Cross-platform AUM / AUA super-domain. Owns the canonical answer to
  "what is our AUM?" / "what is our AUA?" / "total platform equity" / "assets
  under management or administration" — questions that are NOT really about
  trading, payments, or revenue. AUM/AUA is a balance-sheet / customer-equity
  question that spans every product eToro offers (Trading Platform, eMoney IBAN,
  US Options/Apex, EXW non-custodial crypto wallet, Spaceship AU,
  MoneyFarm UK — covers ALL their products (3 eToro-funnel ISAs PLUS legacy
  Cash ISA / GIA / SIPP / Junior ISA from pre-acquisition direct customers),
  WealthFrance FR ISA-equivalent) plus acquired-but-not-yet-flowing platforms
  (Zengo, Bit2C).

  This is a thin super-domain — it does not own per-platform sub-skills. It owns:
    1. The MANDATORY rollup contract (top-line + per-platform breakdown).
    2. A verified Databricks SQL block that decomposes BI_DB_DDR_Fact_AUM
       into TP / IBAN / Options and adds Spaceship (USD pre-converted in
       v_spaceship_aum) and MoneyFarm (USD pre-converted in v_moneyfarm_aum,
       BUT FX-null on same-day → use yesterday).
    3. The synonym definition (AUM == AUA at eToro, for this purpose).
    4. The unrealized-PnL-is-part-of-AUM rule (see domain-trading for
       transactional PnL deltas, which is a different question).
    5. Routing pointers to per-platform skills: domain-spaceship and
       domain-moneyfarm own the platform-level deep dives.
    6. Explicit TBD treatment for WealthFrance, Zengo, Bit2C, Spaceship
       Money wallet, and Subscription — none have a curated AUM surface today.

  AUM/AUA does NOT belong to:
    - domain-trading (positions and transactional PnL changes live there)
    - domain-payments (money-flow events live there)
    - domain-revenue-and-fees (fee/revenue events live there)
  Those domains all touch AUM but none own it. This super-domain owns it.

triggers:
  - AUM
  - AUA
  - aum
  - aua
  - assets under management
  - assets under administration
  - total AUM
  - total AUA
  - all-platform AUM
  - all-platform AUA
  - group AUM
  - group AUA
  - total platform equity
  - total customer equity
  - total client equity
  - what is our AUM
  - what is our AUA
  - EquityGlobal
  - TotalEquityTP
  - IBANBalance
  - OptionsTotalEquity
  - balance under custody
  - assets under custody
  - non-custodial wallet AUM
  - EXW AUM
  - eToro wallet AUM
  - on-chain crypto AUM
  - self-custody AUM
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
  - main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew   # EXW non-custodial wallet AUM
  - main.etoro_kpi.v_spaceship_aum            # NOTE: lives in etoro_kpi, NOT etoro_kpi_prep
  - main.etoro_kpi_prep.v_moneyfarm_aum
  # bi_output_vg_club.WealthFrance was investigated and is NOT a viable AUM source
  # (1.1M rows, only 57 non-null values, $603K total, 3-month-stale snapshot).
  # No curated WealthFrance AUM surface exists today — only raw JSON in
  # main.bi_db.bronze_wealth_france_wealth_france_users_data. Treat as TBD.
intersects_with:
  - domain-trading/SKILL.md                       # transactional PnL (delta) lives there
  - domain-trading/portfolio-value-aum-pnl.md     # legacy AUM balance detail; this hub supersedes
  - domain-exw-wallet/SKILL.md                    # authoritative for EXW non-custodial crypto wallet AUM
  - domain-spaceship/SKILL.md                     # authoritative for Spaceship AUM
  - domain-moneyfarm/SKILL.md                     # authoritative for MoneyFarm AUM
  - domain-options/SKILL.md                       # authoritative for Options/Apex AUM detail
  - domain-customer-and-identity/SKILL.md         # vg_club snapshot (NOT a viable WealthFrance AUM source — see notes)
  - domain-payments/SKILL.md                      # IBAN balance source (eMoneyClientBalance); MIMO panel
out_of_scope:
  - Daily PnL change / realized PnL deltas       # transactional → domain-trading (BI_DB_DDR_Fact_PnL)
  - Position lifecycle / state at open           # → domain-trading
  - Deposit / withdrawal flow events             # → domain-payments
  - Fee revenue                                  # → domain-revenue-and-fees
version: 1
owner: "guyman@etoro.com"
last_validated_at: "2026-06-09"
---

# AUM / AUA Super-Domain

> **Tier 0 — Data-Latency & Roll-Forward Contract (cross-cutting).** Every snapshot value in this hub (TP equity, IBAN, Options/Apex, Spaceship per-product, MoneyFarm USD/GBP, any other AUM line) MUST follow [`../cross-cutting/data-latency-and-rollforward.md`](../cross-cutting/data-latency-and-rollforward.md): silent 3-day roll-forward to the latest clean snapshot when the requested date is missing / partial / FX-null / behind a known per-platform lag (Apex weekend plateau, Spaceship Super+Voyager source-system gaps, MoneyFarm same-day FX-null), per-column not per-table, effective-date shown only when it differs from requested, 7-day escalation with explicit staleness warning if the 3-day lookback fails. Polarity is DEFAULT-ON — never produce 0/NULL/partial when a fresh snapshot exists, never ask "do you want yesterday instead?" before answering. Opt-out only on literal phrases ("no roll-forward" / "exact date only" / "raw value" / "show me what's actually there").

## When to Use

Load this skill when the user asks about:
- "what is our AUM / AUA / total platform equity / total customer equity?"
- "AUM by platform" / "AUM breakdown" / "all-platform AUM" / "group AUM"
- Any cross-platform balance-sheet question that touches more than one product (TP + IBAN + Options + EXW + Spaceship + MoneyFarm)
- The synonym question ("is AUM the same as AUA?") — yes, at eToro they are interchangeable
- Where unrealized PnL fits (balance — owned by this hub) vs. transactional PnL change (delta — owned by `domain-trading`)
- Whether to include or exclude EXW non-custodial crypto in AUM (default: include, additive to TP `TotalRealCrypto`)
- Why a per-platform AUM number is missing (WealthFrance / Zengo / Bit2C / Spaceship Money wallet / Subscription — explicit TBD treatment)
- The canonical SQL that decomposes `BI_DB_DDR_Fact_AUM` into TP / IBAN / Options and adds EXW + Spaceship + MoneyFarm USD lines
- MoneyFarm product/funnel-source drill-down (eToro-funnel ISAs vs. legacy Cash ISA / GIA / SIPP / Junior ISA)
- Floating-point non-determinism on Spaceship `SUM` (round to $1M for stability)
- Apex weekend plateau, Spaceship Super/Voyager source-system gaps, MoneyFarm same-day FX-null — all handled by the cross-cutting roll-forward contract

## Scope
**In scope:** the rollup contract (top-line + per-platform breakdown); the canonical SQL block over `main.bi_db.bi_db_ddr_fact_aum` + `main.etoro_kpi.v_spaceship_aum` + `main.etoro_kpi_prep.v_moneyfarm_aum` + `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew` (EXW); per-platform sanity rules (FX-null behaviour, Apex lag, Spaceship Money exclusion, MoneyFarm dedup, EXW valid-cohort triplet); explicit TBD lines for WealthFrance / Zengo / Bit2C / Spaceship Money / Subscription; AUM↔AUA synonym; unrealized-PnL-as-balance rule; routing pointers to per-platform hubs.

**Out of scope:**
- Daily PnL change / realized PnL deltas — transactional → `domain-trading` (`BI_DB_DDR_Fact_PnL`)
- Position lifecycle / state at open / instrument-level holdings → `domain-trading`
- Deposit / withdrawal flow events → `domain-payments` (`mimo-panel-and-ddr`)
- Fee revenue / PFOF / overnight financing → `domain-revenue-and-fees`
- Per-platform deep dives (Spaceship product detail, MoneyFarm provider mechanics, EXW conversion flows) → respective `domain-spaceship` / `domain-moneyfarm` / `domain-exw-wallet` hubs
- Customer master / GCID semantics → `domain-customer-and-identity`

Last verified: 2026-06-09

## Critical Warnings

### Tier 1 — Silent wrong numbers

1. **Spaceship `SUM` is floating-point non-deterministic** — repeated `SUM(super_balance_usd + voyager_balance_usd + nova_balance_usd)` on the same date can vary by tens of thousands of dollars due to `DOUBLE` accumulation order. Always round to $1M ceiling when quoting. Also the `_money` column is *excluded* from `v_spaceship_aum` totals because Spaceship Money is a transactional wallet, not invested capital — adding it inflates AUM.
2. **MoneyFarm USD column is FX-null on same-day** — `total_aum_usd` in `v_moneyfarm_aum` is computed via `fact_currencypricewithsplit InstrumentID=2` mid-rate; if the same-day GBP/USD rate row hasn't landed, the USD column comes back as 0 while GBP is correct. The roll-forward contract handles this per-column (T-0 GBP, T-1 USD) — never quote a same-day MoneyFarm USD without checking `total_aum_gbp > 0 AND total_aum_usd > 0`.
3. **EXW must be filtered by the valid-cohort triplet** — `IsTestAccount = 0 AND IsValidCustomer = 1 AND AMLClosureEvent = 0` covers ~98.5% of dollar value; without these filters EXW AUM is inflated by test wallets and AML-flagged shells. The `etr_ymd` partition is a **STRING** in `'YYYY-MM-DD'` format (not INT), and EXW is **additive** to TP `TotalRealCrypto` — the trading-side balance reflects in-platform crypto, EXW reflects withdrawn-to-chain crypto.
4. **`BI_DB_DDR_Fact_AUM` lags T-1** — the most recent `DateID` is yesterday at most; querying for "today" returns nothing. Do not silently return 0 — apply the cross-cutting roll-forward and surface the effective date when it differs from requested.
5. **WealthFrance is NOT a viable AUM source today** — `bi_output_vg_club.WealthFrance` is a legacy customer-segments artefact, not a balance ledger. The only WealthFrance balance fact is raw JSON in `main.bi_db.bronze_wealth_france_wealth_france_users_data` and is not USD-normalised. The rollup line stays TBD until a curated AUM view exists.

### Tier 2 — Aggregate / interpretation

6. **AUM = AUA at eToro** — both phrases route to the same answer. Do not present "AUM" and "AUA" as different totals. Internally the canonical phrase is "Assets Under Administration" but the public-facing term is "AUM"; treat as synonyms in every output.
7. **Unrealized PnL is part of AUM, not a separate balance** — the `BI_DB_DDR_Fact_AUM` columns already include unrealized PnL inside `TotalEquity`. Don't add it again. For transactional PnL changes (realized PnL on close, intraday MtM movement), route to `domain-trading`.
8. **MoneyFarm is multi-product and multi-source-funnel** — the top-line covers ALL their products (3 eToro-funnel ISAs PLUS legacy Cash ISA / GIA / SIPP / Junior ISA). Drill-down by `Source_Type` (`Live Event` = eToro-funnel, `Silver History` = legacy MoneyFarm-direct). One GCID can hold many `PortfolioID`s — don't dedup at GCID level when summing.
9. **Apex/Options plateaus on weekends + holidays** — `Fact_AUM` Options/Apex contributions show identical values Friday → Monday with no real change. This is a source-system property, not a missing-data bug. The roll-forward contract treats this as healthy data, not a stale snapshot to skip.

### Tier 3 — Operational / TBD

10. **Always surface Zengo, Bit2C, Spaceship Money, WealthFrance, and Subscription as TBD lines** — even though no UC data exists for them, every breakdown must include the explicit "(TBD — no UC data; verified 2026-06-09)" line so the user sees the gap. Silently omitting them inflates the implicit completeness of the rollup.
11. **Spaceship views live in `main.etoro_kpi`, NOT `main.etoro_kpi_prep`** — `v_spaceship_aum`, `v_spaceship_fees`, and `v_spaceship_mimo` are all in `etoro_kpi` (note: `v_spaceship_mimo` exists in BOTH schemas, prefer the `etoro_kpi` one for consistency).

## Why this super-domain exists

A question like *"what is our AUM as of June 7?"* is not really a trading
question, not really a payments question, and not really a revenue question.
It is a **balance-sheet / customer-equity** question that spans every product
eToro offers. It used to live awkwardly inside `domain-trading` (alongside
positions and PnL deltas) — that was wrong. It now lives here.

Mental model: AUM/AUA is what customers HOLD with eToro at end-of-day, totaled
across every product line. The DDR fact `BI_DB_DDR_Fact_AUM` already merges
three of those product lines (TP equity + IBAN + Options) into `EquityGlobal`,
but the rest (Spaceship, MoneyFarm, WealthFrance, Zengo, Bit2C) are not on the
DDR graph and must be added explicitly.

## Synonyms (lock these in)

- **AUM = AUA** at eToro for the purposes of this skill.
  - "Assets Under Management" and "Assets Under Administration" are used
    interchangeably across product / finance / analyst contexts. Treat them
    as identical when answering top-line questions. If a regulator-specific
    distinction is being asked (rare), surface that you're computing the
    consolidated figure and let the user narrow.
- **Equity, total equity, customer equity, client equity, account value, balance
  under custody, assets under custody** all map to the same answer here unless
  the user explicitly narrows.

## Unrealized PnL: balance vs. delta — which side is this?

Unrealized PnL appears in two places, and you must keep them straight:

| Question shape | Type | Where to go |
|---|---|---|
| "What is our AUM?" / "what's a customer's account value?" | **Balance** (snapshot) | **HERE** — `BI_DB_DDR_Fact_AUM.TotalPositionPNL` is part of the customer's EOD equity. Source: `V_Liabilities` / `Fact_CustomerUnrealized_PnL`. |
| "How much unrealized PnL did our customers gain today?" | **Delta** (change) | `domain-trading/portfolio-value-aum-pnl.md` — `BI_DB_DDR_Fact_PnL.UnrealizedPnLChange` |
| "What was last quarter's realized profit?" | **Delta** (transactional) | `domain-trading/portfolio-value-aum-pnl.md` — `BI_DB_DDR_Fact_PnL.NetProfit` |

It is OK that unrealized PnL appears on both sides — the same underlying
phenomenon answered from two different angles. Just route by question shape.

## ⚠️ MANDATORY ROLLUP CONTRACT (non-negotiable)

For any "what is our AUM/AUA?" question — top-level, no platform specified —
you MUST produce **both** of the following in the answer:

1. **Top-line total** — a single number labelled clearly as "Total AUM/AUA across
   all currently-quantifiable platforms". This is the sum of every line where
   data is currently flowing.
2. **Per-platform breakdown** — one row per platform/service, with a USD number
   for each line that has data, and an explicit **TBD** marker for every line
   where data is not yet flowing. Within DDR, **always split** TP equity / IBAN
   equity / Options equity individually — never just `EquityGlobal` as a single
   line, because the user usually wants to see the platform composition.

If the user did not specify a platform, this is the default response shape —
never collapse silently to `EquityGlobal` alone. The breakdown is the point —
it makes the M&A coverage gaps visible.

### The required line items (in order)

All line item shapes below were verified by live UC queries on 2026-06-09.

| # | Line item | Source (verified columns) | Status |
|---|-----------|---------------------------|--------|
| 1 | **Trading Platform equity (TP)** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum.TotalEquityTP` (USD) | ✅ live (DDR). On 2026-06-07: ~$16.68B summed across 4.56M `RealCID`s. |
| 2 | **eMoney IBAN balance** | `…ddr_fact_aum.IBANBalance` (already USD-converted via `USDApproxRate` upstream in `eMoneyClientBalance`) | ✅ live (DDR). On 2026-06-07: ~$215M. |
| 3 | **Options / Apex equity** | `…ddr_fact_aum.OptionsTotalEquity` (USD, from `Function_AUM_OptionsPlatform`) | ✅ live (DDR), but **lags on weekends/holidays — value plateaus then catches up** (verified Jun 6=Jun 7=Jun 8 = $4.636M; Jun 1 = Jun 2 = $5.027M). On 2026-06-07: ~$4.6M. |
|   | _DDR subtotal (= 1+2+3 = `EquityGlobal`)_ | `…ddr_fact_aum.EquityGlobal` (algebraic identity verified to 7 decimal places) | ✅ live |
| 4 | **EXW (eToro non-custodial crypto wallet)** | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew.BalanceUSD` (USD pre-converted via daily price). Filter `etr_ymd = 'YYYY-MM-DD'` (STRING, not INT) AND the canonical valid-cohort triplet `IsTestAccount=0 AND IsValidCustomer=1 AND AMLClosureEvent=0`. | ✅ live (T-1, daily). On 2026-06-08: **$105.1M** (valid-cohort) / $106.7M (gross). BTC ~60%, XRP ~22%, ETH ~12%. Owned by [`../domain-exw-wallet/SKILL.md`](../domain-exw-wallet/SKILL.md). |
| 5 | **Spaceship — Super + Voyager + Nova** (AU) | `main.etoro_kpi.v_spaceship_aum` columns: `super_balance_usd`, `voyager_balance_usd`, `nova_balance_usd`, `total_balance_usd` (USD pre-converted from AUD). Filter on `date_id` (INT YYYYMMDD). | ✅ live — but **see Spaceship caveats below**. View has 3 products, NOT 4. The Spaceship "Money wallet" is **excluded** per view's own column comment. |
| 5a | _Spaceship Money wallet_ | No curated AUM/balance table found. Only `main.spaceship.bronze_spaceship_analytics_fct_money_transactions` (a transactions ledger). Computing balance from the ledger is non-trivial. | **TBD — AUM surface not built** |
| 6 | **MoneyFarm (UK digital wealth manager — covers ALL their products)** | `main.etoro_kpi_prep.v_moneyfarm_aum` (top-line, per-(date × GCID) grain): `total_balance_gbp` (native), `total_balance_usd` (pre-converted). Filter on `dateid` (INT YYYYMMDD; lower-case). **Includes all MoneyFarm-side products: Cash ISA, DIY ISA, Managed ISA, GIA, Junior ISA, SIPP — both eToro-funnel customers and legacy MoneyFarm-direct customers (acquired pre-2024).** | ✅ live with caveat: **same-day USD is null → 0** (FX rate not yet published). On 2026-06-09: GBP £362.84M / USD $0 (FX null today). On 2026-06-07: GBP £363M / USD $484M. Use yesterday as the safe USD date. |
| 6a | _MoneyFarm — by product / funnel-source (drill-down)_ | `main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot` (per Customer × Portfolio). 9 distinct products under 5 families (Cash ISA, DIY ISA, Managed ISA, GIA, JISA, SIPP). `Source_Type` splits `'Live Event'` (eToro-funnel: 3 ISA products only) vs `'Silver History'` (legacy MoneyFarm-direct: long-tail incl. SIPP/GIA/JISA). **Cash ISA dominates ~80% of book.** | ✅ live. On 2026-06-09 (Live Event): Cash ISA £292.4M, DIY ISA £29.0M, Managed ISA £6.7M. (Silver History): legacy ISAs £34.7M, GIA/SIPP/JISA <£0.5M long-tail. **WARN**: don't `SUM(Current_Market_Value_GBP)` naïvely across both `Source_Type`s — there is overlap; the dedup is in `v_moneyfarm_aum`. For drill-downs: route to [`../domain-moneyfarm/SKILL.md`](../domain-moneyfarm/SKILL.md). |
| 7 | **WealthFrance (FR ISA-equivalent — eToro-native)** | **No curated AUM source.** `bi_output.bi_output_vg_club.WealthFrance` exists but is **dead/marginal**: 57 non-null values out of 1.11M rows, $603K total, 3-month-stale (last `DateID` = 20260308). Raw JSON dump exists at `main.bi_db.bronze_wealth_france_wealth_france_users_data` (no parsed columns). | **TBD — eToro-native, no AUM surface.** Do NOT use the vg_club column. |
| 8 | **Zengo (crypto, acquired)** | **No UC ingestion.** Verified 2026-06-09 against `system.information_schema.tables`: zero rows match `%zengo%` in any schema or table name. Customer self-custody crypto wallet, acquired 2024. Their balance/transaction data lives on Zengo's own infrastructure and has not been onboarded to eToro UC yet. | **TBD — acquired, ingestion pending. ALWAYS surface as a TBD line in any total-AUM answer.** |
| 9 | **Bit2C (crypto, acquired)** | **No UC ingestion.** Verified 2026-06-09 against `system.information_schema.tables`: zero rows match `%bit2c%` or `%bit_2c%` in any schema or table name. Israeli crypto exchange, acquired. Their order-book / customer-balance data lives on Bit2C's own infrastructure and has not been onboarded to eToro UC yet. | **TBD — acquired, ingestion pending. ALWAYS surface as a TBD line in any total-AUM answer.** |
| 10 | **Subscription / future B2C platforms** | **No UC surface.** Subscription is a new revenue product (in launch). Treezor/eMoney-Tribe accounts and other future platforms have no AUM/balance feed in UC today. | **TBD — surface in any total-AUM answer that's about M&A or product breadth.** |

**On vg_club**: it's a **monthly-cadence** snapshot (not daily). The `MoneyBalance` and `MoneyFarmBalance` columns there are sometimes used as alternatives but the canonical AUM sources are DDR Fact_AUM (for IBAN/MoneyBalance equivalent) and `v_moneyfarm_aum` (for MoneyFarm). Don't duplicate via vg_club.

### Sanity rules (Tier-1 don't-screw-this-up — verified 2026-06-09)

1. **Never `SUM(EquityGlobal)` across multiple `DateID`s.** AUM is a snapshot.
   Use a single `DateID`, or `AVG(per-date total)` for a trend. Applies to
   every column on `Fact_AUM`, `v_spaceship_aum`, and `v_moneyfarm_aum`.
2. **`EquityGlobal = TotalEquityTP + IBANBalance + OptionsTotalEquity`** —
   verified to 7 decimal places against live data on 2026-06-07. Use
   `EquityGlobal` for the DDR subtotal but always show the three components
   as separate breakdown rows (the breakdown is the point of the contract).
3. **Latency & roll-forward are governed by the cross-cutting contract.** When
   the requested date isn't fully landed (Apex weekend plateau, Spaceship
   Super/Voyager source-system gaps, MoneyFarm same-day FX-null, Fact_AUM T-1),
   apply silent 3-day roll-forward per
   [`../cross-cutting/data-latency-and-rollforward.md`](../cross-cutting/data-latency-and-rollforward.md).
   Don't ask "do you want yesterday?" — just roll, per-column. Show effective
   date only when it differs from requested. The verified per-source latency
   reference table lives in the contract.
4. **`Fact_AUM` excludes rows where `EquityGlobal = 0`** — confirmed 4.56M
   rows = 4.56M distinct `RealCID` on 2026-06-07 (1:1). So
   `COUNT(DISTINCT RealCID)` on one DateID = "customers with non-zero global
   equity", NOT total customer count.
5. **Spaceship `v_spaceship_aum` excludes the Money wallet.** The view's own
   `total_balance_aud` column comment: "Does NOT include Money wallet
   balances." Three products only: Super, Voyager, Nova. Money is TBD.
6. **WealthFrance is genuinely TBD.** Do NOT use `bi_output_vg_club.WealthFrance`
   as an AUM proxy: 57 non-null rows, $603K total, 3-month-stale snapshot.
   Report as TBD with the explanation that the JSON-only bronze table is the
   only source today.
7. **EXW partition is STRING `'YYYY-MM-DD'`, not INT.** The DDR/Spaceship habit
   of `etr_ymd = 20260608` will silently match nothing on the EXW fact. Use
   `etr_ymd = '2026-06-08'`. The `BalanceDateID` column on the same row is
   the INT form (20260608) and is also a valid filter — the canonical pattern
   is to use both for tightest pruning.
8. **EXW valid-cohort triplet is canonical for AUM**: `IsTestAccount = 0 AND
   IsValidCustomer = 1 AND AMLClosureEvent = 0`. Captures 98.5% of total USD
   value. Without it, gross EXW is ~$106.7M; with it, valid AUM is ~$105.1M.
   The rollup line uses the valid-cohort number.
9. **EXW is additive to TP, NOT a duplicate of `TotalRealCrypto`.** Real-crypto
   on TP (`Fact_AUM.TotalRealCrypto`) is custodied within the platform. The
   moment a customer withdraws to their EXW wallet, the asset leaves TP equity
   and lands on EXW. Adding both is the right thing — they don't overlap. See
   [`../domain-exw-wallet/SKILL.md`](../domain-exw-wallet/SKILL.md).

## Canonical SQL — top-line + breakdown for one date (VERIFIED, EXECUTABLE)

Substitute `20260607` (or whatever date) for the three `:date_id` placeholders
below. This block runs as-is on Databricks; it was executed end-to-end during
the construction of this skill.

```sql
-- ========================================================================
-- AUM / AUA top-line + per-platform breakdown
-- All amounts are USD unless explicitly suffixed _native_*.
-- Use yesterday's date for "as of today" questions to avoid same-day FX-null.
-- ========================================================================

WITH ddr AS (
  -- eToro core: TP + IBAN + Options from the DDR AUM fact (already USD)
  SELECT
    SUM(TotalEquityTP)       AS aum_tp_usd,
    SUM(IBANBalance)         AS aum_iban_usd,
    SUM(OptionsTotalEquity)  AS aum_options_usd,
    SUM(EquityGlobal)        AS aum_ddr_subtotal_usd,
    SUM(TotalPositionPNL)    AS unrealized_pnl_in_tp_equity,
    COUNT(DISTINCT RealCID)  AS customers_with_nonzero_equity
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
  WHERE DateID = 20260607
),
exw AS (
  -- EXW: non-custodial crypto wallets. STRING etr_ymd, valid-cohort filter.
  SELECT
    SUM(BalanceUSD)            AS aum_exw_usd,
    COUNT(DISTINCT GCID)       AS exw_distinct_customers
  FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew
  WHERE etr_ymd = '2026-06-07'
    AND BalanceDateID = 20260607
    AND IsTestAccount = 0
    AND IsValidCustomer = 1
    AND AMLClosureEvent = 0
),
sps AS (
  -- Spaceship: USD pre-converted in the view; BEWARE same-day FX-null defaults to 0
  SELECT
    SUM(super_balance_usd)    AS aum_spaceship_super_usd,
    SUM(voyager_balance_usd)  AS aum_spaceship_voyager_usd,
    SUM(nova_balance_usd)     AS aum_spaceship_nova_usd,
    SUM(total_balance_usd)    AS aum_spaceship_total_usd,
    SUM(total_balance_aud)    AS aum_spaceship_total_aud_native
  FROM main.etoro_kpi.v_spaceship_aum
  WHERE date_id = 20260607
),
mf AS (
  -- MoneyFarm: USD pre-converted; BEWARE same-day FX-null defaults to 0
  SELECT
    SUM(total_balance_usd)  AS aum_moneyfarm_usd,
    SUM(total_balance_gbp)  AS aum_moneyfarm_gbp_native
  FROM main.etoro_kpi_prep.v_moneyfarm_aum
  WHERE dateid = 20260607
)

SELECT
  -- =================== Per-platform breakdown ===================
  d.aum_tp_usd                       AS line_1_trading_platform_usd,
  d.aum_iban_usd                     AS line_2_emoney_iban_usd,
  d.aum_options_usd                  AS line_3_options_apex_usd,
  d.aum_ddr_subtotal_usd             AS subtotal_ddr_equityglobal_usd,

  e.aum_exw_usd                      AS line_4_exw_wallet_usd,
  e.exw_distinct_customers           AS line_4_exw_distinct_customers,

  s.aum_spaceship_super_usd          AS line_5a_spaceship_super_usd,
  s.aum_spaceship_voyager_usd        AS line_5b_spaceship_voyager_usd,
  s.aum_spaceship_nova_usd           AS line_5c_spaceship_nova_usd,
  s.aum_spaceship_total_usd          AS subtotal_spaceship_excl_money_usd,
  s.aum_spaceship_total_aud_native   AS subtotal_spaceship_excl_money_aud_native,
  CAST(NULL AS DOUBLE)               AS line_5d_spaceship_money_usd_TBD,

  m.aum_moneyfarm_usd                AS line_6_moneyfarm_usd,
  m.aum_moneyfarm_gbp_native         AS line_6_moneyfarm_gbp_native,

  CAST(NULL AS DOUBLE)               AS line_7_wealthfrance_usd_TBD,
  CAST(NULL AS DOUBLE)               AS line_8_zengo_usd_TBD,
  CAST(NULL AS DOUBLE)               AS line_9_bit2c_usd_TBD,
  CAST(NULL AS DOUBLE)               AS line_10_subscription_usd_TBD,

  -- =================== Top-line total (USD) ===================
  -- Sum of currently-quantifiable USD lines. TBDs are excluded by definition.
  -- If Spaceship or MoneyFarm USD is 0 due to same-day FX-null, fall back to
  -- yesterday's date or report the native-currency value separately.
  COALESCE(d.aum_ddr_subtotal_usd, 0)
  + COALESCE(e.aum_exw_usd, 0)
  + COALESCE(s.aum_spaceship_total_usd, 0)
  + COALESCE(m.aum_moneyfarm_usd, 0)        AS top_line_total_aum_usd,

  -- =================== Context ===================
  d.unrealized_pnl_in_tp_equity      AS unrealized_pnl_already_in_TP,
  d.customers_with_nonzero_equity    AS ddr_cids_with_nonzero_equity
FROM ddr d
CROSS JOIN exw e
CROSS JOIN sps s
CROSS JOIN mf m;
```

### Worked answer — "What's our AUM as of 2026-06-07?"

Numbers below are from live executions of the above SQL on 2026-06-09.
**DDR figures are exact to the cent** (DECIMAL columns, deterministic).
**Spaceship figures are rounded to $1M** because `v_spaceship_aum` uses
`DOUBLE` columns aggregated over 393k rows — repeat executions drift by
~$10–50k due to floating-point accumulation order in Spark. **The drift is
a precision artifact, not a data update.** Don't copy-paste exact dollars
from this example into Slack — round consistently.

| Line | Source | USD |
|---|---|---|
| 1. Trading Platform equity (TP) | `Fact_AUM.TotalEquityTP` | **$16,683,517,699** |
| 2. eMoney IBAN balance | `Fact_AUM.IBANBalance` | **$214,944,675** |
| 3. Options / Apex equity (latest available ≤ 06-07) | `Fact_AUM.OptionsTotalEquity` | **$4,636,525** |
|   _Subtotal — DDR `EquityGlobal`_ | 1+2+3 | **$16,903,098,899** |
| 4. EXW (eToro non-custodial crypto wallet, valid cohort) | `EXW_FinanceReportsBalancesNew.BalanceUSD` | **$104,487,482** (637K customers) |
| 5a. Spaceship Super (AU) | `v_spaceship_aum.super_balance_usd` | **~$829M** |
| 5b. Spaceship Voyager (AU) | `v_spaceship_aum.voyager_balance_usd` | **~$499M** |
| 5c. Spaceship Nova (AU) | `v_spaceship_aum.nova_balance_usd` | **~$48M** |
|   _Subtotal Spaceship (excl. Money wallet)_ | Super+Voyager+Nova | **~$1.376B** |
| 5d. Spaceship Money wallet | _no AUM surface today_ | **TBD** |
| 6. MoneyFarm (UK — all products) | `v_moneyfarm_aum.total_balance_usd` | **$484,040,105** (GBP £363M) |
|   _drill: by product (Cash ISA dominant)_ | `bi_output_moneyfarm_fact_portfolio_snapshot` | Cash ISA £292.4M (80%) · DIY ISA £29.0M · Managed ISA £6.7M · long-tail GIA/SIPP/JISA <£0.5M each |
|   _drill: by funnel-source_ | `Source_Type` on snapshot fact | eToro-funnel (3 ISAs) £328M · Legacy MoneyFarm-direct (long-tail incl. SIPP/GIA/JISA) £35M |
| 7. WealthFrance (FR ISA-equivalent — eToro-native) | _no AUM surface today; vg_club column dead, bronze JSON unparsed_ | **TBD — surface in answer** |
| 8. Zengo (crypto, acquired) | _zero UC tables match `%zengo%` (verified 2026-06-09); ingestion pending_ | **TBD — surface in answer** |
| 9. Bit2C (crypto, acquired) | _zero UC tables match `%bit2c%` (verified 2026-06-09); ingestion pending_ | **TBD — surface in answer** |
| 10. Subscription / future B2C | _new product in launch, no AUM surface yet_ | **TBD — surface in answer** |
| **Top line — Total AUM/AUA across currently-quantifiable platforms** | | **≈ $18.87B USD** |

**Caveats to surface in the answer:**
- Options/Apex value plateaued Jun 6=Jun 7=Jun 8 ($4.636M) — this is the
  expected weekend lag, not a bug.
- Spaceship USD does NOT include the Money wallet (per view comment).
- Spaceship totals drift by ~$10–50k between executions due to DOUBLE
  precision; report rounded to the nearest $1M unless the user asks for
  decimals (in which case explicitly call out that they're approximate).
- MoneyFarm USD on Jun 7 is good; on Jun 9 (today) it is null/0 due to
  same-day FX-null behavior — that's why the worked example uses Jun 7.
- **The top line explicitly excludes WealthFrance, Zengo, Bit2C, Spaceship Money,
  and Subscription. ALWAYS surface ALL FIVE as TBD lines** — every total-AUM
  answer must list them so the reader can see the M&A coverage gap. Do not
  collapse them into "and other platforms"; do not omit any one of them.
  The full TBD ladder is part of the answer, not a footnote.

## Routing — when this skill is the right one

Load this skill first when the user asks any of:

- "What is our AUM?" / "What is our AUA?" / "Total customer equity?"
- "AUM / AUA on date X" / "AUM trend last month"
- "How much do customers hold across all platforms?"
- "Total platform equity"
- "Account value across all products"
- "Real vs CFD AUM" (within TP — `TotalRealCrypto` / `TotalRealStocks`)
- Any breakdown by platform of equity/balance

When the user is asking something AUM-adjacent that is NOT this skill:

| User question | Route to |
|---|---|
| "Daily PnL change" / "realized profit this quarter" | `domain-trading/portfolio-value-aum-pnl.md` (PnL fact, deltas) |
| "Position state at open" | `domain-trading/position-state-and-grain.md` |
| "Deposits and withdrawals" | `domain-payments/SKILL.md` |
| "Net MIMO" / "money flow" | `domain-payments/mimo-panel-and-ddr.md` |
| "Funded customer count" | `domain-customer-and-identity/customer-populations-and-lifecycle.md` |
| "Spaceship deep dive" | `domain-spaceship/SKILL.md` |
| "MoneyFarm AUM" / "MoneyFarm UK total" / general MoneyFarm question | `domain-moneyfarm/SKILL.md` (top-line) |
| "MoneyFarm by product" / "Cash ISA AUM" / "SIPP / GIA / Junior ISA breakdown" / "eToro-funnel vs legacy MoneyFarm-direct customers" | `domain-moneyfarm/SKILL.md` (drill-down via `bi_output_moneyfarm_fact_portfolio_snapshot`) |
| "Options product detail" | `domain-options/SKILL.md` |
| "EXW / non-custodial wallet AUM" / "BTC on wallet" / "currency mix" | `domain-exw-wallet/balance-and-aum.md` |
| "Crypto activity for customer X" / "redeem volume" / "wallet send/receive" | `domain-exw-wallet/transactions.md` |
| "Wallet redemption" / "TP→wallet withdraw" | `domain-exw-wallet/redemptions.md` |
| "C2F" / "crypto→fiat off-ramp" | `domain-exw-wallet/conversions-c2f.md` |
| "C2P" / "crypto→position funding" | `domain-exw-wallet/conversions-c2p.md` |
| "On-chain hash forensics" / "AML pre-check" / "BitGo replacement" | `domain-exw-wallet/on-chain-ledger.md` |
| "EXW super-domain (any other entry)" | `domain-exw-wallet/SKILL.md` |
| "WealthFrance JSON / parsing question" | `domain-cross` (no curated skill yet — bronze JSON only) |

## Per-platform notes (read these before quoting numbers — verified 2026-06-09)

- **Trading Platform (TP)**: `TotalEquityTP = SUM(TotalLiability + ActualNWA)`
  per CID/DateID. `ActualNWA` is bonus-capped net worth. The unrealized PnL
  on open positions is already inside `TotalEquityTP` via `TotalPositionPNL`.
  DECIMAL precision — exact to the cent.
- **eMoney IBAN**: `IBANBalance = SUM(ClosingBalanceBO * USDApproxRate)` from
  `eMoneyClientBalance`, excluding `GCID IS NULL OR GCID = 0`. Uses approximate
  USD rate, not spot. For tight FX recon, query the eMoney source directly.
- **Options / Apex**: `OptionsTotalEquity` uses the latest available Apex date
  ≤ requested DateID. **Verified to plateau on weekends/holidays** (Jun 6 = Jun 7
  = Jun 8 = $4.636M; Jun 1 = Jun 2 over Memorial Day weekend). Excludes house
  accounts (`4GS43999`, `4GS00100-104`).
- **EXW (eToro non-custodial crypto wallet)** — `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew`:
  - Per-Customer × per-Wallet × per-Crypto × per-Day grain. Aggregate to GCID
    for customer-level analysis.
  - Partition `etr_ymd` is STRING `'YYYY-MM-DD'` (not INT). `BalanceDateID` is
    the INT mirror. Use both for tightest pruning.
  - `BalanceUSD` is pre-converted via daily price; 0 (not NULL) when `Rate IS
    NULL`. ~80% of rows have `Balance = 0` (empty shell wallets) — sum is
    correct without filtering.
  - Canonical valid-cohort filter: `IsTestAccount = 0 AND IsValidCustomer = 1
    AND AMLClosureEvent = 0`. Captures 98.5% of dollar value.
  - Currency mix: BTC ~60%, XRP ~22%, ETH ~12% (verified 2026-06-08).
  - Additive to TP `TotalRealCrypto` — not a duplicate. Custodied real-crypto
    sits on TP; once withdrawn to wallet, lives here.
  - For deep dives: [`../domain-exw-wallet/SKILL.md`](../domain-exw-wallet/SKILL.md).
- **Spaceship (AU)** — `main.etoro_kpi.v_spaceship_aum` (NOT `etoro_kpi_prep`):
  - **3 products visible**: Super, Voyager, Nova. The "Money" wallet — the 4th
    Spaceship product brand — **is NOT in this view**, per the view's own
    `total_balance_aud` comment ("Does NOT include Money wallet balances").
    Money wallet AUM = TBD. (`main.spaceship.bronze_spaceship_analytics_fct_money_transactions`
    is a transactions ledger, not a balance.)
  - **USD pre-converted**: `super_balance_usd`, `voyager_balance_usd`,
    `nova_balance_usd`, `total_balance_usd` columns all exist. No FX work
    required by the analyst — but **same-day FX-null defaults to 0** (per the
    column comment). Use yesterday for "today" answers.
  - **DOUBLE precision**: aggregates over 393k rows drift by ~$10–50k between
    executions. Round to nearest $1M.
  - **Gap days exist beyond weekends**: verified Mon Jun 1 and Fri Jun 5 had
    Super=$0; Sun Jun 8 had Super=$0 and Voyager=$0. Source-system gaps go
    beyond the documented Sat/Sun fill-forward. Nova publishes daily 7-day.
  - For deep dives: `domain-spaceship/SKILL.md`.
- **MoneyFarm (UK digital wealth manager — covers ALL their products)** — `main.etoro_kpi_prep.v_moneyfarm_aum`:
  - **GBP-native**. Columns: `total_balance_gbp`, `total_balance_usd`
    (pre-converted via `fact_currencypricewithsplit` `InstrumentID=2`). Filter
    on `dateid` (lower-case INT YYYYMMDD).
  - **Top-line view rolls up the entire MoneyFarm-side book** to the `(date ×
    GCID)` grain — does NOT carry product breakdown. For just-right
    granularity on general "what's MoneyFarm AUM?" questions, use this view.
  - **Same-day FX-null = USD 0** (verified Jun 9 2026 has GBP £362.84M but
    USD $0). USD typically arrives T-1; per the cross-cutting roll-forward
    contract, walk back the USD column independently.
  - **Product breakdown — when drilling down**: 9 distinct products across 5
    families, all included in the top-line: **Cash ISA, DIY ISA, Managed
    ISA** (the 3 eToro-funnel products) PLUS **GIA, Junior ISA,
    Self-Invested Personal Pension** (legacy MoneyFarm-direct customers
    acquired pre-2024). Use
    `bi_output.bi_output_moneyfarm_fact_portfolio_snapshot` (per Customer ×
    Portfolio grain) and split by `Product_Name`. **Cash ISA dominates 80%
    of book** (£292M of £363M on Jun 9 2026).
  - **Funnel-source breakdown** is a second drill-down dimension via
    `Source_Type`: `'Live Event'` = customers acquired through the eToro
    funnel post-acquisition (3 ISA products only, ~£328M); `'Silver
    History'` = customers who joined MoneyFarm directly pre-eToro-acquisition
    and have legacy products eToro doesn't sell on its funnel
    (long-tail SIPP/GIA/JISA, ~£35M).
  - **Don't `SUM(Current_Market_Value_GBP)` naïvely across both
    `Source_Type`s on the snapshot fact** — there's overlap on customers who
    appear in both layers. The dedup logic is already in `v_moneyfarm_aum`
    (use it for top-line; only descend to the snapshot fact for product
    breakdown).
  - For deep dives: [`../domain-moneyfarm/SKILL.md`](../domain-moneyfarm/SKILL.md).
- **WealthFrance (FR ISA-equivalent — eToro-native, NOT an acquisition)**:
  - **No curated AUM source today.** Investigated:
    - `bi_output.bi_output_vg_club.WealthFrance` is a per-customer balance
      column — but only **57 of 1.11M rows** are non-null, total ~$603K, and
      the latest snapshot is **2026-03-08** (3 months stale; the table is
      monthly-cadence). Do NOT use it as an AUM proxy.
    - `main.bi_db.bronze_wealth_france_wealth_france_users_data` exists but
      stores only raw JSON (`json_text`, `insert_date`, `file_name`,
      `file_creation_date`, `running_id`) — no parsed balance columns.
  - Report as **TBD** with explanation. Don't approximate.
- **Zengo (crypto self-custody wallet — acquired)**:
  - **No UC ingestion as of 2026-06-09.** Verified via `system.information_schema.tables`: zero rows match `%zengo%` in any catalog/schema/table name.
  - Acquired 2024. Customer self-custody non-custodial wallet (similar product category to EXW but external infrastructure).
  - Customer balance / transaction data lives on Zengo's own platform and has not been onboarded to eToro UC.
  - **Always include as a TBD line in any total-AUM answer — never silently omit.** The fact that data is missing is itself the answer.
  - When ingestion lands: expect a new schema (likely `main.zengo_*` mirroring the `main.wallet.*` / `main.spaceship.*` pattern). Update this hub at that point.
- **Bit2C (Israeli crypto exchange — acquired)**:
  - **No UC ingestion as of 2026-06-09.** Verified via `system.information_schema.tables`: zero rows match `%bit2c%` or `%bit_2c%` in any catalog/schema/table name.
  - Acquired. Order-book / customer-balance data lives on Bit2C's own infrastructure.
  - **Always include as a TBD line in any total-AUM answer — never silently omit.**
  - When ingestion lands: expect a new schema (likely `main.bit2c_*`). Update this hub at that point.
- **Subscription / future B2C products (new launch)**:
  - Subscription revenue is a new product still ramping up. There is **no AUM/balance surface in UC today**.
  - Treezor/eMoney-Tribe envelopes and other future B2C platforms have no UC AUM feed today.
  - **Always include as a TBD line in any total-AUM answer to make the M&A / product-breadth coverage gap visible to the reader.**

## What this skill is NOT

- It does not own **transactional PnL change** (`UnrealizedPnLChange`,
  `NetProfit` from `BI_DB_DDR_Fact_PnL`) — that lives in `domain-trading`.
- It does not own **per-position lifecycle** (open, close, modify) — that's
  `domain-trading`.
- It does not own **the funded customer segment definition** — that's
  `domain-customer-and-identity/customer-populations-and-lifecycle.md`.
- It does not own **deposits / withdrawals / MIMO flow** — that's
  `domain-payments`.
- It does not own **fees or revenue** — that's `domain-revenue-and-fees`.

## Provenance

v1 — created 2026-06-09. Promoted out of `domain-trading/portfolio-value-aum-pnl.md`
because AUM/AUA is a balance-sheet / customer-equity question that does not
naturally belong in trading, payments, or revenue. The decision was driven by
observed routing failures (Genie agent reasoning loaded `domain-payments` for
an AUM question because that hub mentioned `Fact_AUM 43c` in its description —
correct fact, wrong super-domain).

This is a **thin** super-domain — no per-platform sub-skills are owned here.
All platform deep-dives live in their own existing skills (`domain-spaceship`,
`domain-moneyfarm`, etc.) and this hub routes to them.

### Verification log (2026-06-09)

The following claims were verified by live UC queries before being committed:

- ✅ `EquityGlobal = TotalEquityTP + IBANBalance + OptionsTotalEquity` (matches
  to 7 decimal places on 2026-06-07; diff = -0.000007 due to DECIMAL summation
  rounding only).
- ✅ `Fact_AUM` row count == `COUNT(DISTINCT RealCID)` on a single DateID
  (4,556,073 = 4,556,073 on 2026-06-07).
- ✅ Spaceship view path: `main.etoro_kpi.v_spaceship_aum` (NOT `etoro_kpi_prep`
  as initially documented in v0). Schema: 13 columns including pre-converted
  USD per product (no FX work needed by analyst).
- ✅ MoneyFarm view path: `main.etoro_kpi_prep.v_moneyfarm_aum`. 7 columns
  including pre-converted `total_balance_usd`. Filter column is lower-case
  `dateid` INT, not `DateID`.
- ✅ Same-day FX-null behavior on Spaceship and MoneyFarm USD columns
  reproduced on 2026-06-09 — both show GBP/AUD natives healthy but USD = 0.
- ✅ Apex weekend lag on `OptionsTotalEquity` reproduced (Jun 6 = Jun 7 = Jun 8;
  Jun 1 = Jun 2 over Memorial Day weekend).
- ✅ vg_club WealthFrance column is dead/marginal: 57 non-null rows out of
  1.11M, $603K total, stale at DateID=20260308. Confirmed monthly cadence.
- ✅ WealthFrance bronze table (`main.bi_db.bronze_wealth_france_wealth_france_users_data`)
  contains only raw JSON columns; no parsed balance surface.
- ✅ Spaceship Money wallet has no balance table; only
  `main.spaceship.bronze_spaceship_analytics_fct_money_transactions` (a
  transactions ledger).
- ⚠️ Spaceship USD `SUM` is non-deterministic at ~$10–50k scale across repeated
  executions due to DOUBLE precision over 393k rows. Round to $1M when reporting.
- ⚠️ Spaceship has Super=0 / Voyager=0 days that are NOT weekends (Mon Jun 1,
  Fri Jun 5 in 2026-06) — source-system gaps go beyond the documented Sat/Sun
  fill-forward.
- ✅ EXW canonical fact: `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew`,
  45 columns, partitioned on `etr_ymd` STRING `'YYYY-MM-DD'`. Latest partition
  `'2026-06-08'` on 2026-06-09 (T-1).
- ✅ EXW grain verified: per-Customer × per-Wallet × per-Crypto × per-Day. On
  2026-06-08 partition: 1.83M rows / 717K distinct GCID.
- ✅ EXW gross AUM 2026-06-08 = $106,733,525; valid-cohort
  (`IsTestAccount=0 AND IsValidCustomer=1 AND AMLClosureEvent=0`) =
  $105,126,184 (98.5% of gross). Valid-cohort 2026-06-07 = $104,487,482
  across 637,372 distinct customers.
- ✅ EXW currency mix on 2026-06-08 (valid cohort): BTC $63.1M (~60%),
  XRP $23.1M (~22%), ETH $12.9M (~12%), TRX $1.9M, then long tail.
- ✅ EXW partition column `etr_ymd` is STRING `'YYYY-MM-DD'` (not INT). The
  `IN ('20260605',…)` shape returns 0 rows; `IN ('2026-06-05',…)` works.
- ⚠️ The Synapse `EXW_FactBalance` is NOT migrated to UC (`UC Target:
  _Not_Migrated` per Synapse wiki). EXW AUM in UC must use
  `EXW_FinanceReportsBalancesNew`, NOT `EXW_FactBalance`.
