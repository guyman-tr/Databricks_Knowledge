---
name: domain-staking
description: "The 13 supported staking currencies and their per-coin parameters from Dealing_Staking_Parameters: InstrumentID (100001 ETH, 100017 ADA, 100026 TRX, 100037 DOT, 100047 ATOM, 100056 POL, 100063 SOL, 100085 AVAX, 100110 ETHEUR, 100337 NEAR, 100340 SUI, 100456 SOLEUR, 100458 ADAEUR), IntroDays (9 for ADA, 7 for TRX/SOL/NEAR/POL/ATOM/DOT/SUI/AVAX, 60 for ETH dynamic 15-70), LiquidityBuffer (0.60 DOT, 0.70 ATOM, 0.80 TRX/SOL, 0.85 NEAR/POL/AVAX, 0.90 ADA/SUI, 1.00 ETH), Distribution_StartDate (2023-09-01 for ADA/TRX through 2026-04-01 for AVAX), DailyPool_StartDate and WelcomeEmail_StartDate. Covers the ETH opt-out-by-default exception, the EUR-variant remapping convention (ETHEUR/SOLEUR/ADAEUR get their own Parameters rows but downstream Position/Results/Summary use the USD-denominated InstrumentID), the live-config vs frozen-per-month rule (Parameters is current state; Summary.IntroDays and OptedOut.LiquidityBuffer are the values actually used in past distributions), and the four-step Process of Adding a New Currency cascade (Synapse Parameters row → SP_Staking_Emails columns and #Emails temp table → four Tableau views — Opted Out Monitoring / Proposal Overview / Proposal Drill-Down / Airdrops List / Main KPIs Over Months — sized for the new row + Marketing template update)."
triggers:
  - currency
  - currencies
  - coin
  - coins
  - ADA
  - TRX
  - SOL
  - NEAR
  - POL
  - ATOM
  - DOT
  - SUI
  - AVAX
  - ETHEUR
  - SOLEUR
  - ADAEUR
  - EUR variant
  - Dealing_Staking_Parameters
  - dealing_staking_parameters
  - IntroDays
  - intro days
  - LiquidityBuffer
  - liquidity buffer
  - Distribution_StartDate
  - DailyPool_StartDate
  - WelcomeEmail_StartDate
  - program start date
  - launch date
  - supported currencies
  - new currency
  - add currency
  - new coin
  - Avg_Daily_Holdings_Threshold
  - opted-out monitoring
  - Proposal Overview
  - Proposal Drill-Down
  - Airdrops List
  - Main KPIs Over Months
  - dynamic intro days
  - ETH 60 days
  - opt-out buffer
  - dynamic 15-70
required_tables:
  - main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary
  - main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-28"
---

# Currency Catalogue & Parameters

## When to Use

Load when the question is about:

- "Which currencies does eToro stake?"
- "What's the IntroDays for [coin]?"
- "When did [coin] start staking?"
- "What's ETH's liquidity buffer?"
- "What InstrumentID is ADA?"
- "What's the EUR variant of [coin]?"
- "Why does Parameters have 13 rows when only 10 unique coins?"
- "How do we add a new currency to the staking program?"
- "What's the historical IntroDays for [coin] in [past month]?"

Do **not** load for:

- The reward calculation that USES these parameters — see [`rewards-formula-and-calculation.md`](rewards-formula-and-calculation.md).
- The eligibility gates per CountryID / RegulationID — see [`eligibility-and-gates.md`](eligibility-and-gates.md). Country and regulation lists are separate from currency parameters.
- The stored procedures that read Parameters at run time — see [`distribution-pipeline.md`](distribution-pipeline.md).
- The customer-facing instrument catalogue and asset-class semantics — see `../domain-trading/instruments-and-asset-classes.md`. That sub-skill owns the full Dim_Instrument enrichment; this file owns only the staking-specific subset (13 InstrumentIDs).

## Scope

In scope: the 13 rows of `Dealing_Staking_Parameters` as of 2026-05-28 (`InstrumentID`, `Currency`, `IntroDays`, `LiquidityBuffer`, `Distribution_StartDate`, `DailyPool_StartDate`, `WelcomeEmail_StartDate`); the per-coin IntroDays and LiquidityBuffer values; the EUR-variant convention (ETHEUR / SOLEUR / ADAEUR each have their own `Parameters` row but downstream tables use the USD-denominated `InstrumentID`); the live-config-vs-frozen-history rule (`Parameters` is current state; `Summary.IntroDays` and `OptedOut.LiquidityBuffer` are the values actually used for any past distribution); ETH's dynamic 15-70 day intro semantics; the four-step "Process of Adding a New Currency" cascade (Synapse Parameters row → SP_Staking_Emails extension → Tableau view updates → Marketing template); the relationship between Parameters and the `Dealing_Staking_Club` threshold table.
Out of scope: the reward calculation that consumes these parameters (`rewards-formula-and-calculation.md`); eligibility gates (`eligibility-and-gates.md`); the SP_Staking trigger logic and step-by-step execution (`distribution-pipeline.md`); the full `Dim_Instrument` catalogue and asset-class semantics (`../domain-trading/instruments-and-asset-classes.md`).
Last verified: 2026-05-28

## Critical Warnings

1. **Tier 1 — `Dealing_Staking_Parameters` is LIVE config, not history.** It has one row per supported coin with the CURRENT `IntroDays` and `LiquidityBuffer`. For historical analyses ("what value was actually used in March 2025?") use `Dealing_Staking_Summary.IntroDays` (per-month frozen value) and `Dealing_Staking_OptedOut.LiquidityBuffer` (per-day frozen value). Querying `Parameters` and assuming it applies to a past month silently produces wrong results when settings have changed since.
2. **Tier 1 — EUR-variant rows in `Parameters` use distinct `InstrumentID`s (100110 / 100456 / 100458) but downstream `Position` / `Results` / `Summary` remap them to USD InstrumentIDs (100001 / 100063 / 100017).** Joining `Parameters` to `Results` on `InstrumentID` for an EUR-variant client returns no rows. Either join on `Currency` text (handling the `LIKE 'ADA%'` pattern) or pre-resolve the remapping with a CASE statement.
3. **Tier 2 — ETH's `IntroDays` is currently 60 but is documented as dynamic 15-70.** The customer-facing FAQ explicitly says "Based on network conditions". When ETH `IntroDays` changes, the new value applies going forward — `Summary.IntroDays` records the value used for that month's distribution.
4. **Tier 2 — `LiquidityBuffer` is the fraction of opted-in units actually staked.** `0.60` means 60% of pool is staked, 40% is held liquid. This buffer is enforced at the dealer-trading level — the `Opted-Out Monitoring` Tableau report ensures opted-out units stay within the buffer range. When this buffer is breached (e.g. clients un-opt at scale), the dealer side cannot match its hedge book and yield can drop.
5. **Tier 3 — `WelcomeEmail_StartDate` controls when first-time-position welcome emails ship.** `SP_Staking_WelcomeEmail` sends a CSV twice a week to Marketing listing users who opened a position for the first time on a staked cryptocurrency, so they can receive a welcome email and choose to waive participation. A coin without this date set won't trigger welcome emails. Currently this SP still lives in the old DWH (see Status / Maintenance in the source README).
6. **Tier 3 — `DailyPool_StartDate` controls when daily pool tracking begins for a coin.** Before that date, no row exists in `Dealing_Staking_DailyPool` for that coin. Used by Labs to monitor client holdings and verify consistency with their own staking data.

## The 13 rows of `Dealing_Staking_Parameters` (snapshot 2026-05-28)

Sorted by Distribution_StartDate so the program's evolution is visible:

| `InstrumentID` | `Currency` | `IntroDays` | `LiquidityBuffer` | `Distribution_StartDate` | Notes |
|---:|---|---:|---:|---|---|
| 100017 | ADA | 9 | 0.90 | 2023-09-01 | Original launch coin |
| 100026 | TRX | 7 | 0.80 | 2023-09-01 | Original launch coin |
| 100063 | SOL | 7 | 0.80 | 2024-08-01 | $1 USD floor introduced same month |
| 100001 | ETH | 60 | 1.00 | 2024-09-01 | **Opt-out by default** — `UserProgramID = 3`. Dynamic intro 15-70 day range; current 60. `LiquidityBuffer = 1.00` means full pool is staked. |
| 100337 | NEAR | 7 | 0.85 | 2025-02-01 | |
| 100056 | POL | 7 | 0.85 | 2025-02-01 | |
| 100047 | ATOM | 7 | 0.70 | 2025-05-01 | |
| 100037 | DOT | 7 | 0.60 | 2025-05-01 | Lowest liquidity buffer — only 60% of pool staked |
| 100340 | SUI | 7 | 0.90 | 2026-02-01 | |
| 100110 | ETHEUR | 60 | 1.00 | 2026-03-01 | EUR variant — **remapped to ETH (100001) for calculation** |
| 100456 | SOLEUR | 7 | 0.80 | 2026-03-01 | EUR variant — **remapped to SOL (100063) for calculation** |
| 100458 | ADAEUR | 9 | 0.90 | 2026-03-01 | EUR variant — **remapped to ADA (100017) for calculation** |
| 100085 | AVAX | 7 | 0.85 | 2026-04-01 | |

Live re-query (UC OK):

```sql
SELECT
    InstrumentID,
    Currency,
    IntroDays,
    LiquidityBuffer,
    DailyPool_StartDate,
    WelcomeEmail_StartDate,
    Distribution_StartDate,
    UpdateDate
FROM main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters
ORDER BY Distribution_StartDate, Currency;
```

## EUR-variant InstrumentID remapping

The three EUR-variant currencies exist in `Parameters` as distinct rows with their own `InstrumentID`s, but downstream tables `Position` / `Results` / `Summary` use the USD-denominated `InstrumentID` for the calculation:

| EUR variant `Currency` | EUR variant `InstrumentID` | USD-denominated `InstrumentID` used in calc | USD-denominated `Currency` |
|---|---:|---:|---|
| ETHEUR | 100110 | 100001 | ETH |
| SOLEUR | 100456 | 100063 | SOL |
| ADAEUR | 100458 | 100017 | ADA |

**Why this exists**: an EUR-denominated ADA position is mechanically the same asset as a USD-denominated ADA position — it just settles in a different fiat currency on close. The on-chain ADA tokens are staked from the same pool. SP_Staking's Step 0 inserts EUR variants separately (so the `Fivetran_google_sheets.platform_rewards` row for ETHEUR can be picked up if Labs files it that way), then remaps the `InstrumentID` to the USD equivalent before joining to positions, eligibility, and yield.

**Query pattern**: to count ADA-staking clients across both USD- and EUR-denomination:

```sql
SELECT COUNT(DISTINCT CID)
FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
WHERE StakingMonthID = 202604
  AND IsEligible = 1
  AND Currency IN ('ADA', 'ADAEUR');
```

Or, since `Position` / `Results` / `Summary` remap, querying just `Currency = 'ADA'` (USD-denominated) captures both variants on these tables — confirm with the data, but the remapping holds throughout post-Step-0 of SP_Staking. The distinct `ADAEUR` row may still appear on `Results` if the SP author kept it for marketing-segmentation reasons; treat both forms as ADA for the calculation.

## Live config vs frozen per-month — when to read which table

| Question | Read from |
|---|---|
| "What's the IntroDays for ADA right now?" | `Dealing_Staking_Parameters.IntroDays` (single live row) |
| "What was the IntroDays for ADA in March 2025?" | `Dealing_Staking_Summary.IntroDays` with `Currency = 'ADA' AND StakingMonthID = 202503` (frozen) |
| "What's ETH's current LiquidityBuffer?" | `Dealing_Staking_Parameters.LiquidityBuffer` |
| "What LiquidityBuffer was applied on 2025-03-15 for ETH?" | `Dealing_Staking_OptedOut.LiquidityBuffer` with `Date = '2025-03-15' AND Currency = 'ETH'` (frozen per-day) |
| "When did SUI staking start?" | `Dealing_Staking_Parameters.Distribution_StartDate` (live; doesn't change) |
| "What was the per-tier threshold for ADA in March 2025?" | `Dealing_Staking_Club.Avg_Daily_Holdings_Threshold` with `Currency = 'ADA' AND StakingMonthID = 202503` |

The `Parameters` table never holds historical values — when a coin's IntroDays changes from 9 to 7, the Parameters row is UPDATEd in place and the old value is only visible in past `Summary` rows.

## ETH's dynamic IntroDays

ETH is documented as "Dynamic (15-70 days) — Based on network conditions" in the customer-facing FAQ (`How are staking rewards calculated.md`). The current setting is 60.

**Why 15-70**:
- Lower bound (15 days): eToro's internal minimum opt-in window before a position becomes eligible.
- Upper bound (70 days): on-chain ETH validator unbonding cycle — when the protocol-level unstaking queue is long, the program lengthens its intro period to avoid liquidity gaps.

When the value changes:
1. `Dealing_Staking_Parameters.IntroDays` is UPDATEd in place — usually around month-end before the next staking cycle.
2. `SP_Staking`'s Step 1 reads the new value for the next run.
3. `Summary.IntroDays` for the new month captures the value used.

For an ETH-specific intro-days history reconstruction:

```sql
SELECT StakingMonthID, IntroDays
FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary
WHERE Currency = 'ETH'
ORDER BY StakingMonthID;
```

## Process of Adding a New Currency

From `eToro/Staking/README.md` § "Process of Adding a New Currency". When eligibility settings stay the same as an existing coin, update:

| System | Where | What | Notes |
|---|---|---|---|
| Synapse | `Dealing_dbo.Dealing_Staking_Parameters` | Add new currency entry | Set `InstrumentID`, `Currency`, `IntroDays`, `LiquidityBuffer`, `Distribution_StartDate`, optionally `DailyPool_StartDate` and `WelcomeEmail_StartDate` |
| Synapse | `Dealing_dbo.SP_Staking_Emails` and `Dealing_dbo.Dealing_Staking_Emails` | Add 4 columns: `<coin>_Units`, `<coin>_MPercentage`, `<coin>_CPercentage`, `<coin>_Reward` | Also add to the `#Emails` temp table inside `SP_Staking_Emails`. Ask Marketing automation to update the email template before the first distribution. |
| Tableau | Opted-Out Monitoring, Proposal Overview, Proposal Drill-Down, Airdrops List | Ensure enough vertical space for new rows | Sized layouts may truncate the new row otherwise |
| Tableau | Main KPIs Over Months | Adjust graph size, axis, and legend | The legend gets a new colour swatch |

If eligibility settings differ (e.g. different regulation cuts, different country list), `SP_Staking`, `SP_Staking_Emails`, and `SP_Staking_DailyPool` ALL need the cascade — see Critical Warning #15 on the hub.

## Skill provenance

- 13-row snapshot queried live from `main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters` on 2026-05-28.
- IntroDays / LiquidityBuffer / Distribution_StartDate values cross-checked against `eToro/Staking/README.md` "Currently supported currencies" table and `agent/context/tables.md` § "Dealing_Staking_Parameters".
- EUR-variant remapping rule from `README.md` § "Step 0 — Parameters" — "EUR variants (ETHEUR, SOLEUR, ADAEUR) are inserted separately and their InstrumentIDs remapped to their USD equivalents for downstream calculation."
- ETH dynamic 15-70 day range from `How are staking rewards calculated.md` § "Currency / Intro Days / Rewards Begin" table.
- "Process of Adding a New Currency" cascade verbatim from `README.md`.
- v1 (2026-05-28): initial authoring. Personal-workspace only.
