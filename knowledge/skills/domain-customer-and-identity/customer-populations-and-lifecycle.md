---
name: domain-customer-and-identity
description: "Customer population segments (Funded, Active Trader, Portfolio Only, Balance Only) and lifecycle milestones (FTD dates, First Time Funded / FTF, registration, first action). Anchored on the SCD population fact `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` (point-in-time, compressed into FromDateID/ToDateID ranges — the fast default for 'how many funded customers today?'), with five additional surfaces: the pre-aggregated `BI_DB_DDR_Customer_Periodic_Status` (weekly/monthly/quarterly), the full-detail daily `BI_DB_DDR_Customer_Daily_Status` (slow — billions of rows), the enriched daily snapshot `etoro_kpi.vg_customer_daily_snapshot`, the per-customer milestone-dates fact `etoro_kpi.vg_customer_customer_first_dates`, and three population view families (`v_population_first_time_funded` for the canonical FTF formula, `v_population_first_trading_action` for the asset-class breakdown of a customer's first trade, `v_population_active_traders` for the 12 per-day Active Trader sub-flags including ActiveTradedCryptoCFD/CryptoReal, ActiveTradedStocksCFD/StocksReal, ActiveTradedCopy/CopyFund, ActiveTradedOptions). Owns: the mutual-exclusion population hierarchy (Active > Portfolio Only > Balance Only, all orthogonal to IsFunded), the canonical IsFunded definition (FirstFundedDateID <= DateID AND combined equity > 0 across TP + eMoney + Options legs), the First Time Funded formula (`GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID))`), and the InstrumentTypeID lookup behind first-trade classification (Forex 1/2/4, Crypto 10, Stocks 5/6, Copy via MirrorID). Load for any population-count, segment-breakdown, lifecycle-milestone, FTF-cohort, or first-trading-action question — go-to BEFORE Dim_Customer-based aggregates for any 'how many <segment>' query."
triggers:
  - funded customer
  - funded customers
  - active trader
  - active traders
  - portfolio only
  - balance only
  - population count
  - population segment
  - segment breakdown
  - segment split
  - first time funded
  - FTF
  - FTF cohort
  - first funded
  - FirstFundedDateID
  - customer lifecycle
  - milestone dates
  - lifecycle milestones
  - first trading action
  - first trade type
  - first action breakdown
  - ActiveTraded
  - ActiveTradedManual
  - ActiveTradedCFD
  - ActiveTradedCryptoCFD
  - ActiveTradedCryptoReal
  - ActiveTradedStocksCFD
  - ActiveTradedStocksReal
  - ActiveTradedETFCFD
  - ActiveTradedETFReal
  - ActiveTradedCopy
  - ActiveTradedCopyFund
  - ActiveTradedOptions
  - IsFunded
  - PI
  - dailystatus_scd
  - customer_dailystatus_scd
  - customer_periodic_status
  - customer_daily_status
  - vg_customer_daily_snapshot
  - vg_customer_customer_first_dates
  - v_population_first_time_funded
  - v_population_first_trading_action
  - v_population_active_traders
  - how many funded
  - funded account
  - funded accounts
  - how many funded accounts
  - number of funded accounts
  - IsGlobalFTD
  - global FTD
  - global first time deposit
  - daily active traders
  - population trend
  - funded trend
  - cohort size
required_tables:
  - main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
  - main.etoro_kpi.vg_customer_daily_snapshot
  - main.etoro_kpi.vg_customer_customer_first_dates
  - main.etoro_kpi_prep.v_population_first_time_funded
  - main.etoro_kpi_prep.v_population_first_trading_action
  - main.etoro_kpi_prep.v_population_active_traders
sample_questions:
  - "How many funded customers do we have today?"
  - "Active traders today vs last month?"
  - "FTF cohort size for Q1 2026?"
  - "Population breakdown: funded vs portfolio-only vs balance-only?"
  - "What did new funded users trade first this quarter?"
  - "When did customer 12345 deposit / register / first trade?"
  - "Daily active traders time series for March 2026"
  - "How many customers became funded each week this quarter?"
domain_tags:
  - customer
  - populations
  - lifecycle
  - ftf
  - segmentation
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-28"
---

# Customer Populations & Lifecycle

Population segments (Funded / Active Trader / Portfolio Only / Balance Only) and lifecycle milestones (FTD, First Time Funded, registration, first trade) are the **point-in-time customer state** layer of this super-domain. They answer "how many customers WERE X on date Y?" — a different question from `customer-master-record.md` (current-state attributes) and from `identity-jurisdiction-and-regulation.md` (historical regulation/jurisdiction state). The eight tables here form a tight cluster: one SCD population fact, two DDR aggregates, two enriched per-customer views, and three `v_population_*` builders that hold the canonical formulas (IsFunded, FTF, first trading action, Active Trader sub-flags).

**Use the SCD table as the default.** `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` is the pre-materialized SCD-2 compression of `BI_DB_DDR_Customer_Daily_Status` — billions of rows of daily population state collapsed into `FromDateID`/`ToDateID` ranges. A population count on any single date is a `BETWEEN` filter, not a daily scan.

## When to Use

Load when the question concerns customer-state aggregates or lifecycle dates:

- "How many funded customers?", "active traders today", "balance-only customers right now", "population breakdown"
- "New funded this quarter", "FTF cohort size", "how many customers became funded this month?"
- "Daily active traders over time", "funded trend this month", "population time series"
- "When did customer X deposit?", "what was customer X's registration date?", "first trade date?"
- "First trading action breakdown" — what did new users trade first (Forex / Crypto / Copy / Copy Fund / Stocks)
- "Active trader sub-flags" — split active traders by manual vs copy, CFD vs real, by asset class
- Any question about segment counts, population splits, or customer lifecycle events

Do **not** load for:

- Current-state attribute lookup on a specific customer (master record, country, regulation) → [`customer-master-record.md`](customer-master-record.md)
- Point-in-time **regulation** / **jurisdiction** / **MiFID** walks → [`identity-jurisdiction-and-regulation.md`](identity-jurisdiction-and-regulation.md) (uses the SAME SCD pattern but on `Fact_SnapshotCustomer`, not the dailystatus fact)
- Per-event ledger of WHAT a customer did (which trade, which fee) → [`customer-action-audit-trail.md`](customer-action-audit-trail.md)
- Onboarding **funnel** (reg → KYC → V1/V2/V3 → FTD conversion rates, drop-off, VBD/VBT cohorts) → DE workspace skill `registration-to-ftd-funnel` at `/Workspace/.assistant/skills/registration-to-ftd-funnel/SKILL.md`. The funnel and the populations are adjacent but distinct: funnel measures *conversion rates between stages*; this sub-skill measures *who is in which segment on a given date and when did they cross the FTF milestone*.

## Scope

In scope: population segments (Funded, Active Trader, Portfolio Only, Balance Only) with the mutual-exclusion hierarchy, the canonical IsFunded definition (3-leg equity check across TP + eMoney + Options), the First Time Funded formula (`GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID))`), lifecycle milestone dates (FTD, FTF, registration, first action, first IOB, first options trade), SCD-based point-in-time queries via `FromDateID BETWEEN`/`ToDateID`, pre-aggregated periodic status (weekly/monthly/quarterly), full daily detail (slow — fallback only), the enriched daily snapshot, per-customer milestone first-dates with NULL handling, first trading action classification (Forex / Crypto / Copy / Copy Fund / Stocks via InstrumentTypeID 1/2/4/5/6/10), Active Trader sub-flags (12 per-day flags: `ActiveTradedManual`, `ActiveTradedCFD`, `ActiveTradedCryptoCFD`, `ActiveTradedCryptoReal`, `ActiveTradedStocksCFD`, `ActiveTradedStocksReal`, `ActiveTradedETFCFD`, `ActiveTradedETFReal`, `ActiveTradedCopy`, `ActiveTradedCopyFund`, `ActiveTradedOptions`, with `IsSettled` driving the CFD-vs-Real split).
Out of scope: FTD amounts and the deposit/withdrawal flow (→ Payments super-domain, `domain-payments/mimo-panel-and-ddr.md`), pre-FTD onboarding-funnel analytics — VL0→VL3 timing, EV-provider routing, KYC document SLA, per-vendor performance (→ `../domain-ops-and-onboarding/electronic-verification-and-registration-funnel.md` and `../domain-ops-and-onboarding/kyc-document-pipeline.md`), equity / AUM amounts per customer (→ `domain-trading/portfolio-value-aum-pnl.md`), per-action revenue and fees (→ `domain-revenue-and-fees/SKILL.md`), AML risk classification (→ `domain-compliance-and-aml/SKILL.md`).
Last verified: 2026-05-28

## Critical Warnings

1. **Tier 1 — `BI_DB_DDR_Customer_Daily_Status` is multi-billion rows and slow.** Counting populations from this table is technically correct but operationally catastrophic. Use `gold_de_user_dim_ddr_customer_dailystatus_scd` (SCD-2 compressed into date ranges) as the default. Reach for the daily-status table ONLY when you need a column not present on the SCD compaction, AND you've narrowed the date range to a few days.
2. **Tier 1 — Deposit ≠ Funded.** A customer with a deposit on file is NOT automatically funded. The canonical Funded definition is `FirstFundedDateID <= DateID AND combined equity > 0` where `FirstFundedDateID` requires all three of (1) deposited on any platform, (2) verified to level 3 (`VerificationLevelID = 3`), (3) acted (first trade, IOB, or options trade). A deposited-but-unverified customer is `IsDepositor = 1` but NOT `IsFunded = 1`. Filtering on `IsDepositor` for "funded customers" silently undercounts the gap and overcounts the not-yet-acted.
3. **Tier 1 — `FirstDepositDate` carries the sentinel `1900-01-01`.** Customers with no deposit have `FirstDepositDate = '1900-01-01'`, not NULL. A `MIN(FirstDepositDate)` or "earliest deposit" query without a sentinel filter returns 1900 — visually obviously wrong, statistically silently wrong if averaged. Filter with `YEAR(FirstDepositDate) != 1900` or prefer `etoro_kpi.cidfirstdates_v` (sibling sub-skill `identity-jurisdiction-and-regulation.md`'s preferred surface) which converts sentinels to NULL.
4. **Tier 2 — `IsChurned` / `IsWinBack` columns on the SCD table are NOT stable.** They exist physically and refresh on every cycle, but their definitions are still being refined upstream by DE. Do not build long-lived business logic on these two flags. The predictive churn signals live in `customer-models-and-segmentation.md` (`Is_Churn_over_14/30/60` on `customer_segments_v`, plus the `churn_winback_*` model output). Treat the SCD's `IsChurned` as informational only.
5. **Tier 2 — `vg_customer_daily_snapshot` is a VIEW over the daily-status fact.** For large date ranges it inherits the daily-status fact's row count and is just as slow. The view is convenient (it joins dimension dates and adds named enrichments), but if you're scanning more than ~30 days, fall back to the SCD population fact or the `BI_DB_DDR_Customer_Periodic_Status` pre-aggregate.
6. **Tier 2 — `v_population_first_trading_action` returns ALL customers, not just depositors.** The view emits one row per customer who has ever taken a trading action (ActionTypeID IN (1, 17, 39) with `IsAirDrop = 0`). It does NOT pre-filter for `IsDepositor = 1`. If the analytical question is "what did new funded users trade first?", join to `v_population_first_time_funded` (1 row per funded customer with `FirstFundedDateID`) and filter the joined set — do NOT add `WHERE IsDepositor = 1` to the view alone, because it doesn't carry that column.
7. **Tier 2 — Copy positions count as trading activity for FTF; airdrops do NOT.** The FirstAction component of the FTF formula uses the earliest of (first trade in `Dim_Position`, first IOB in `Fact_CustomerAction` with `ActionTypeID = 36` / CompensationReasonID = 57, first options trade). Copy positions DO count (a `MirrorID > 0` trade qualifies). Airdrops do NOT (the upstream views apply `IsAirDrop = 0`). This matters for FTF cohort sizing — never reinvent the formula from the underlying facts; load the view. **For the IOB revenue lens** (consent table, paid-out side, gross-vs-net economics), see `../domain-revenue-and-fees/interest-on-balance.md` — this skill owns the funnel lens, that one owns the revenue lens.
8. **Tier 3 — SCD point-in-time filter is `FromDateID <= @date AND ToDateID >= @date`.** Both bounds are inclusive. Forgetting the inclusivity on either side either drops the day a customer's segment changed or double-counts a customer whose segment was identical across two compacted runs. Always use `BETWEEN @date AND @date` in the form `FromDateID <= @date AND ToDateID >= @date`.

## Core Concepts

| Concept | What It Is | Aliases |
|---|---|---|
| **Funded** | Customer with equity > 0 AND past First Time Funded milestone (V3 + FTD + first action). Orthogonal to the Active/Portfolio/Balance hierarchy below. | funded user, funded account |
| **First Time Funded (FTF)** | One-time milestone = `GREATEST(FTD date, V3 date, first trade/IOB/options date)`. Never reverts. | first funded, FTF milestone, FirstFundedDateID |
| **Active Trader** | Traded on that day (ActionTypeID 1/39/15/17 on TP, or ActionTypeID=1 on Options). **Highest priority** in the mutual-exclusion hierarchy. | active user, trader |
| **Portfolio Only** | Holds open positions but didn't trade that day. Excludes Active Traders via NOT EXISTS. **2nd priority.** | position holder, passive holder |
| **Balance Only** | Has equity but no positions or trades. Excludes Active + Portfolio. **3rd / lowest priority.** | cash only, idle account |
| **First Trading Action** | Customer's earliest trade classified by asset type (Forex / Crypto / Copy / Copy Fund / Stocks). | first trade type, first asset class |
| **Active Trader Sub-Flags** | 12 per-day flags decomposing the Active Trader segment by manual vs copy, CFD vs real, and asset class. Live on `v_population_active_traders`. | active sub-flags |
| **PI** | Popular Investor — eToro's social trading program. Surfaced via `IsPI` on the snapshot. NOT `PlayerLevelID` (see hub Critical Warning). | popular investor |
| **FirstDepositDate sentinel** | `'1900-01-01'` means "no deposit". Filter with `YEAR(...) != 1900`. | sentinel date, never deposited |

### Population Hierarchy

```
  ┌──────────────────────────────────────────────────────┐
  │   FUNDED  (Equity > 0 AND past First-Funded date)    │
  │  ┌────────────┐  ┌──────────────┐  ┌──────────────┐  │
  │  │   ACTIVE   │  │  PORTFOLIO   │  │   BALANCE    │  │
  │  │   TRADER   │  │    ONLY      │  │     ONLY     │  │
  │  └────────────┘  └──────────────┘  └──────────────┘  │
  │     1st priority ──► 2nd ──────────► 3rd             │
  └──────────────────────────────────────────────────────┘
```

Mutually exclusive: Active > Portfolio > Balance (each excludes the one above via NOT EXISTS). **Funded is orthogonal** — overlaps with any of the three.

### Funded Equity Check — 3 legs

A customer is funded on a `DateID` if `FirstFundedDateID <= DateID` AND combined equity > 0:

| Leg | Source Table | Formula |
|---|---|---|
| Trading Platform (TP) | `bi_db_client_balance_cid_level_new` | `SUM(COALESCE(TotalLiability, 0) + COALESCE(actualNWA, 0))` |
| eMoney | `emoneyclientbalance` | `ClosingBalanceBO * USDApproxRate` where `ClosingBalanceCalc > 0` |
| Options | `v_options_aum` (joined via GCID) | `OptionsTotalEquity` where > 0 |

### First Time Funded Formula

All THREE must be met:

1. **Deposited** on any platform (global FTD from `v_mimo_first_deposit_all_platforms`)
2. **Verified** to level 3 (`v_fact_snapshotcustomer_fromdateid_masked`, `VerificationLevelID = 3`)
3. **Acted** — earliest of: first trade (`dim_position`), first IOB (`fact_customeraction` `ActionTypeID = 36` / CompensationReasonID = 57), or first options trade

```
FirstFundedDateID = GREATEST(
  FTDDateID,
  FirstVerifiedDateID,
  LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID)
)
```

**Caveats**: Copy positions count as activity. Airdrops do NOT (`IsAirDrop = 0`).

### First Trading Action Classification

From `v_population_first_trading_action` — one row per customer, earliest `fact_customeraction` where `ActionTypeID IN (1, 17, 39)` and `IsAirDrop = 0`:

| FirstActionType | Condition |
|---|---|
| Forex | `InstrumentTypeID IN (1, 2, 4)` |
| Crypto | `InstrumentTypeID = 10` |
| Copy | `MirrorID > 0`, `IsCopyFund = 0` |
| Copy Fund | `MirrorID > 0`, `IsCopyFund = 1` |
| Stocks | `InstrumentTypeID IN (5, 6)` |

### Active Trader Sub-Flags

Available on `v_population_active_traders` (per `RealCID` / `DateID`):

| Flag | Condition |
|---|---|
| `ActiveTradedManual` | `MirrorID = 0` |
| `ActiveTradedCFD` | Manual + `InstrumentTypeID IN (1, 2, 4)` |
| `ActiveTradedCryptoCFD` | Manual + `InstrumentTypeID = 10`, `IsSettled = 0` |
| `ActiveTradedCryptoReal` | Manual + `InstrumentTypeID = 10`, `IsSettled = 1` |
| `ActiveTradedStocksCFD` | Manual + `InstrumentTypeID = 5`, `IsSettled = 0` |
| `ActiveTradedStocksReal` | Manual + `InstrumentTypeID = 5`, `IsSettled = 1` |
| `ActiveTradedETFCFD` | Manual + `InstrumentTypeID = 6`, `IsSettled = 0` |
| `ActiveTradedETFReal` | Manual + `InstrumentTypeID = 6`, `IsSettled = 1` |
| `ActiveTradedCopy` | `MirrorID > 0`, `ActionTypeID IN (15, 17)` |
| `ActiveTradedCopyFund` | Copy + `IsCopyFund = 1` |
| `ActiveTradedOptions` | `InstrumentTypeID = 9` (Options platform) |

**InstrumentTypeID reference** (the canonical lookup lives in `../domain-trading/instruments-and-asset-classes.md`): `1, 2, 4` = Forex / Commodities / Indices; `5` = Stocks; `6` = ETFs; `9` = Options; `10` = Crypto.

### SCD Table — Point-in-time Filter

```sql
WHERE FromDateID <= @date AND ToDateID >= @date
```

Both bounds inclusive. A customer's segment-state can span multiple SCD rows over time; this predicate selects the single row valid on `@date`.

## Table Selection

| Need | Use This Table |
|---|---|
| Population counts on a date (fast) | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` |
| Pre-aggregated weekly / monthly / quarterly | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` |
| Full daily detail with all flags (slow) | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` |
| Daily status + date dimensions enriched | `main.etoro_kpi.vg_customer_daily_snapshot` |
| Customer milestone dates (1 row / customer) | `main.etoro_kpi.vg_customer_customer_first_dates` |
| FTF calculation logic / `FirstFundedDateID` | `main.etoro_kpi_prep.v_population_first_time_funded` |
| First-trade classification per customer | `main.etoro_kpi_prep.v_population_first_trading_action` |
| Active Trader sub-flags per customer per day | `main.etoro_kpi_prep.v_population_active_traders` |

> **Default**: SCD population fact. Pre-materialized, compressed into date ranges, fast on any single-date query.

## Query Patterns

### Pattern 1 — Population breakdown on a date

```sql
SELECT
  SUM(CASE WHEN ActiveTraded = 1 THEN 1 ELSE 0 END) AS active_traders,
  SUM(CASE WHEN Portfolio_Only = 1 THEN 1 ELSE 0 END) AS portfolio_only,
  SUM(CASE WHEN BalanceOnlyAccount = 1 THEN 1 ELSE 0 END) AS balance_only,
  SUM(CASE WHEN IsFunded = 1 THEN 1 ELSE 0 END) AS funded
FROM main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd
WHERE FromDateID <= 20260401 AND ToDateID >= 20260401;
```

**Use when:** "how many funded?", "active traders today", "population breakdown", "segment split"

### Pattern 2 — FTF cohort in a date range

```sql
SELECT COUNT(DISTINCT RealCID) AS ftf_cohort_size
FROM main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd
WHERE FirstTimeFunded = 1
  AND FirstFundedDateID BETWEEN 20260101 AND 20260331;
```

**Use when:** "new funded customers this quarter", "FTF cohort", "how many became funded?"

### Pattern 3 — Daily time series (expand the SCD)

```sql
SELECT d.DateID, COUNT(DISTINCT s.RealCID) AS active_traders
FROM main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd s
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date d
  ON d.DateID BETWEEN s.FromDateID AND s.ToDateID
WHERE s.ActiveTraded = 1
  AND d.DateID BETWEEN 20260301 AND 20260331
GROUP BY d.DateID
ORDER BY d.DateID;
```

**Use when:** "daily active traders over time", "funded trend this month", "population time series"

### Pattern 4 — Customer milestone lookup

```sql
SELECT RealCID, RegistrationDate, FirstDepositDate, FirstAction, FirstFundedDate
FROM main.etoro_kpi.vg_customer_customer_first_dates
WHERE YEAR(FirstDepositDate) != 1900;
```

**Use when:** "when did customer X deposit?", "registration date", "first trade date", "milestone dates"

### Pattern 5 — FTF cohort first-action breakdown

```sql
SELECT fta.FirstActionType, COUNT(DISTINCT fta.RealCID) AS n
FROM main.etoro_kpi_prep.v_population_first_trading_action fta
JOIN main.etoro_kpi_prep.v_population_first_time_funded ftf
  ON fta.RealCID = ftf.RealCID
WHERE ftf.FirstFundedDateID BETWEEN 20260101 AND 20260331
GROUP BY fta.FirstActionType
ORDER BY n DESC;
```

**Use when:** "what did new funded users trade first?", "first action breakdown for FTF cohort"

## Skill provenance

Absorbed 2026-05-28 from the legacy workspace skill `customer-populations` (v2, owner dataplatform) into the Customer & Identity super-domain. Content preserved verbatim; restructured to match the hub's sub-skill template (frontmatter `name: domain-customer-and-identity`, Tier-ordered warnings, cross-references to sibling sub-skills). The legacy `customer-populations/SKILL.md` is tombstoned in the same commit (DA-72) and redirects here. Hard-delete of the legacy folder is deferred ~30 days to let the MCP embedding corpus re-train against this sub-skill's fingerprint.
