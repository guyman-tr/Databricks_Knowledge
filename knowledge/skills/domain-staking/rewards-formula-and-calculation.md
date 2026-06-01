---
name: domain-staking
description: "End-to-end derivation of a client's monthly staking reward — from the 00:00-GMT daily-holdings snapshot all the way to the USD value that lands in the wallet. Covers the seven-step formula (daily snapshot → IntroDays haircut → sum (units × eligible_days) → average daily eligible → gross via monthly yield → club RevShare → USD conversion), the six-tier RevShare ladder (Bronze 0.45 / Silver 0.55 / Gold 0.65 / Platinum 0.75 / Platinum Plus 0.85 / Diamond 0.90 against PlayerLevelID 1/5/3/2/6/7), the $1 USD eligibility floor introduced August 2024 (and how forfeited rewards accrue to Etoro_Amount), the IntroDays semantics for ADA (9), TRX/SOL/NEAR/POL/ATOM/DOT/SUI/AVAX (7), and ETH (dynamic 15–70), the EUR-variant InstrumentID remapping rule for calculation (ETHEUR→ETH, SOLEUR→SOL, ADAEUR→ADA), worked SQL patterns against Dealing_Staking_OptedOut_PerCID / Dealing_Staking_Position / Dealing_Staking_Summary / Dealing_Staking_Results, and the six-step `why is this number lower than expected` diagnostic chain (coin price drop, network yield slip, intro haircut, opt-out flips, eligibility gate fails, sub-$1 forfeit)."
triggers:
  - staking formula
  - reward calculation
  - how rewards are calculated
  - reward math
  - reward derivation
  - Raw_Staking_Amount
  - Client_Airdrop
  - Etoro_Amount
  - USD_Compensation
  - Etoro_Amount_USD
  - RevShare
  - Bronze
  - Silver
  - Gold
  - Platinum
  - Platinum Plus
  - Diamond
  - PlayerLevelID
  - ClubCategory
  - AnnualizedYield
  - monthly yield
  - EtoroYield
  - USD_ConversionRate
  - IntroDays
  - intro period
  - Eligible_Staking_Days
  - Effective_OpenDate
  - Effective_CloseDate
  - $1 threshold
  - Less than $1
  - Less than \$1
  - sub-dollar
  - dollar floor
  - average daily holdings
  - avg_daily_eligible
  - sum_units_days
  - ADAEUR
  - SOLEUR
  - ETHEUR
  - EUR variant
  - InstrumentID remap
  - why is my reward
  - reward lower than expected
  - lower reward
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary
  - main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool
  - main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-28"
---

# Rewards Formula & Calculation

## When to Use

Load when the question is about:

- "How is a client's monthly staking reward calculated?"
- "Why did CID X get $Y for [coin] in [month]?"
- "What's the math behind `Raw_Staking_Amount` / `Client_Airdrop` / `USD_Compensation`?"
- "What does the Diamond / Platinum / etc. revenue share work out to?"
- "What's the `< $1 USD` threshold rule?"
- "How do intro days affect a reward?"
- "Why does the EUR variant calculate against the USD instrument?"
- "Show me the reproduction query for a specific CID × coin × month"

Do **not** load for:

- The eligibility gates themselves (regulation, AML, country, club) — see [`eligibility-and-gates.md`](eligibility-and-gates.md). The formula here ASSUMES the client passed the gates.
- The currency catalogue / `IntroDays` per-coin parameters — see [`currency-catalog-and-parameters.md`](currency-catalog-and-parameters.md). The formula reads `IntroDays`; it doesn't define it per coin.
- The four stored procedures that materialise the formula — see [`distribution-pipeline.md`](distribution-pipeline.md).
- The `StakingMonthID` re-run convention and `MAX()` trap — see [`staking-month-id-and-reruns.md`](staking-month-id-and-reruns.md).
- eToro-booked revenue / DDR `StakingLagOneMonth` — see `../domain-revenue-and-fees/revenue-staking-and-share-lending.md`.

## Scope

In scope: the seven-step monthly reward derivation (daily snapshot at 00:00 GMT → `IntroDays` exclusion → sum of `units × eligible_days` per position → average daily eligible units → `Raw_Staking_Amount` via monthly yield → `Client_Airdrop` via club `RevShare` → `USD_Compensation` via `USD_ConversionRate`); the six-tier `PlayerLevelID` → `RevShare` mapping (1=Bronze 0.45, 5=Silver 0.55, 3=Gold 0.65, 2=Platinum 0.75, 6=Platinum Plus 0.85, 7=Diamond 0.90); the `ClubCategory` coarser grouping (Bronze / "Silver, Gold & Platinum" / "Diamond & Platinum Plus"); the `< $1 USD` eligibility floor (since August 2024) and how forfeited rewards accrue to `Etoro_Amount`; the `IntroDays` semantics by coin (ADA 9; TRX/SOL/NEAR/POL/ATOM/DOT/SUI/AVAX 7; ETH dynamic 15–70 days); the EUR-variant remapping rule (`ETHEUR → ETH (100001)`, `SOLEUR → SOL (100063)`, `ADAEUR → ADA (100017)` for `Position` / `Results` / `Summary`); a worked CID × coin × month example with the reproduction SQL chain; the six-step "why is my number lower than expected" diagnostic.
Out of scope: eligibility gates / who qualifies (see `eligibility-and-gates.md`); the `IntroDays` and `LiquidityBuffer` per-coin live config (see `currency-catalog-and-parameters.md`); the stored procedures (see `distribution-pipeline.md`); the re-run convention (see `staking-month-id-and-reruns.md`); the revenue side (see `../domain-revenue-and-fees/revenue-staking-and-share-lending.md`).
Last verified: 2026-05-28

## Critical Warnings

1. **Tier 1 — `IntroDays` is applied to BOTH endpoints of a position's eligibility window.** `Effective_OpenDate = MAX(OpenDate + IntroDays, StakingStartDate)`; if the position was opened mid-month, the first N days of holding don't count. ETH has DYNAMIC intro days (15–70 based on network conditions) — `Dealing_Staking_Parameters` shows the current value (60 at 2026-05-28), but historical months may differ. **Always use `Dealing_Staking_Summary.IntroDays`** for historical reconstructions, not `Parameters.IntroDays`.
2. **Tier 1 — The `< $1 USD` floor is a HARD eligibility gate, not a rounding rule.** Rows with `Client_Airdrop × USD_ConversionRate < $1` are flagged `IsEligible = 0`, `NonEligible_PrimaryReason = 'Less than $1'`, `Client_Airdrop` set to `0`, and the would-be reward goes into `Etoro_Amount` instead. The customer gets nothing; eToro keeps the full unit. In effect since August 2024. Forgetting this rule when summing client rewards understates the eToro side and misses the "tiny holdings forfeit" population.
3. **Tier 1 — EUR-variant InstrumentIDs remap to USD-denominated InstrumentIDs in `Position` / `Results` / `Summary`.** `Dealing_Staking_Parameters` has 13 distinct rows (ETHEUR / SOLEUR / ADAEUR ARE listed separately with their own InstrumentIDs 100110 / 100456 / 100458) but `Position` / `Results` / `Summary` rows for those clients carry the USD InstrumentID (100001 / 100063 / 100017). When joining `Parameters.InstrumentID` to `Results.InstrumentID` for an EUR-variant client, the join misses. Use `Currency LIKE '<coin>%'` or join on `Currency` text instead.
4. **Tier 2 — `Distribution based on number of opt-in days within staking period` (since March 2025).** A client who opts in mid-month gets a pro-rata share of the reward, not the full monthly amount. Affects `Eligible_Staking_Days` directly on `Dealing_Staking_Position`. Pre-March-2025 distributions used a binary opt-in flag at start-of-month; do not retroactively apply the post-March-2025 rule to older periods.
5. **Tier 2 — `RevShare` on `Results` is the value USED for the calculation, not a club-tier lookup at query time.** If a customer's club tier changed mid-month, `Position.PlayerLevel` and `Results.RevShare` are frozen at SP_Staking run time (typically the 5th of the following month). Don't re-derive `RevShare` from `PlayerLevelID` at query time — the customer may have been upgraded since.
6. **Tier 3 — `Raw_Staking_Amount` is BEFORE the eToro/client split; `Client_Airdrop` is AFTER.** `Client_Airdrop = Raw_Staking_Amount × RevShare`; `Etoro_Amount = Raw_Staking_Amount × (1 − RevShare)`. The two sum back to `Raw_Staking_Amount` exactly (no rounding loss in the table — they're `decimal(38,8)`).
7. **Tier 3 — `USD_Compensation = Client_Airdrop × USD_ConversionRate` and `Etoro_Amount_USD = Etoro_Amount × USD_ConversionRate`.** Both use the SAME conversion rate stamped on `Summary.USD_ConversionRate`. If a client's USD compensation looks off, check `Summary` for the conversion rate used — coins can drop 30% within a staking window, and the rate is set at distribution time.

## The formula

From [How are staking rewards calculated.md](./SKILL.md) (the customer-facing explainer, distilled in the source repo) and `Staking_Presentation.md` (the BI-Trading internal slide deck, October 2024):

```
1.  Daily snapshot (00:00 GMT)  →   eligible_units per position
2.  Apply IntroDays haircut     →   exclude first N days per position
3.  Σ (units × eligible_days)   →   sum_units_days  across all positions
4.  Avg daily eligible          =   sum_units_days / days_in_staking_month
5.  Raw_Staking_Amount          =   avg_daily_eligible × monthly_yield
6.  Client_Airdrop              =   Raw_Staking_Amount × RevShare (club %)
7.  Etoro_Amount                =   Raw_Staking_Amount × (1 − RevShare)
8.  USD_Compensation            =   Client_Airdrop × USD_ConversionRate
9.  Etoro_Amount_USD            =   Etoro_Amount × USD_ConversionRate
```

with `monthly_yield = AnnualizedYield / 12` from `Dealing_Staking_Summary` and `IntroDays` from the same row (or live from `Parameters` for the current month).

Equivalent dealer-side form (from `Staking_Presentation.md`):

```
Effective_OpenDate    = MAX(OpenDate + IntroDays, StakingStartDate)
Effective_CloseDate   = MIN(CloseDate,             StakingEndDate)
Eligible_Staking_Days = Effective_CloseDate − Effective_OpenDate   (if positive, else 0)

Reward = (RevShare × Units × Eligible_Days × Total_Rewards) /
         (Σ Total_Eligible_Units × Eligible_Days across all eligible positions)
```

Both forms produce the same `Client_Airdrop`. The first is the customer-facing "annual yield × club share" framing; the second is the pool-sharing framing that SP_Staking uses internally.

## The RevShare ladder

`PlayerLevelID` (numeric) maps to club tier and revenue share as follows. The Synapse `PlayerLevelID` ordering is **not** sequential — that's an oddity of legacy master data; don't try to derive `RevShare` from `PlayerLevelID` ordering, look it up explicitly.

| `PlayerLevelID` | Club tier | Client `RevShare` | eToro share |
|---:|---|---:|---:|
| 1 | Bronze | 0.45 | 0.55 |
| 5 | Silver | 0.55 | 0.45 |
| 3 | Gold | 0.65 | 0.35 |
| 2 | Platinum | 0.75 | 0.25 |
| 6 | Platinum Plus | 0.85 | 0.15 |
| 7 | Diamond | 0.90 | 0.10 |

`Dealing_Staking_Results.ClubCategory` is a coarser grouping used in dashboards:

| `ClubCategory` value | Includes |
|---|---|
| `'Bronze'` | Bronze |
| `'Silver, Gold & Platinum'` | Silver, Gold, Platinum |
| `'Diamond & Platinum Plus'` | Diamond, Platinum Plus |

Useful for fast three-bucket revenue splits in dashboards. For precise tier-level analysis, join back to `Dealing_Staking_Position.PlayerLevel` (text) which carries the full six-value enum.

## `IntroDays` by coin (live config as of 2026-05-28)

From `Dealing_Staking_Parameters`. Historical months may differ — use `Dealing_Staking_Summary.IntroDays` for historical reconstructions.

| Currency | `IntroDays` | Notes |
|---|---:|---|
| ADA | 9 | |
| TRX | 7 | |
| SOL | 7 | |
| ETH | 60 | **Dynamic** 15–70 day range historically; current setting 60 |
| NEAR | 7 | |
| POL | 7 | |
| ATOM | 7 | |
| DOT | 7 | |
| SUI | 7 | |
| AVAX | 7 | |
| ETHEUR | 60 | Mapped to ETH for calculation |
| SOLEUR | 7 | Mapped to SOL for calculation |
| ADAEUR | 9 | Mapped to ADA for calculation |

ETH's `IntroDays` is unique in being publicly framed as "dynamic 15–70 days based on network conditions" in the customer-facing FAQ. The on-chain unbonding cycle for ETH validators drives the upper bound; the lower bound is eToro's internal minimum. When ETH `IntroDays` is changed, the new value applies going forward — `Summary.IntroDays` records the value used for that month's distribution.

## Worked example — CID 10614403, ADA, April 2026

**Staking window:** 2026-03-21 → 2026-04-19 (30 days; per `Summary.StakingStartDate` / `StakingEndDate`).
**Client parameters:** Diamond tier (`PlayerLevelID = 7`), Bahrain / FCA regulation, account Normal, opted in every day, no AML restriction, no waiver.

### Step 1 — Daily snapshot from `OptedOut_PerCID` (Synapse only)

```sql
SELECT
    MIN(Date) AS first_date,
    MAX(Date) AS last_date,
    COUNT(*)  AS days,
    AVG(EligibleUnits) AS avg_daily_units,
    SUM(EligibleUnits) AS sum_units_days,
    AVG(USD_Rate)      AS avg_usd_rate
FROM Dealing_dbo.Dealing_Staking_OptedOut_PerCID
WHERE CID = 10614403
  AND Currency = 'ADA'
  AND Date BETWEEN '2026-03-21' AND '2026-04-19';
```

Result: 30 daily snapshots, `sum_units_days = 54,752,047` ADA-days.

### Step 2 — Apply `IntroDays` exclusion via `Position` (Synapse only)

`Dealing_Staking_Position.Eligible_Staking_Days` already encodes the IntroDays haircut.

```sql
SELECT COUNT(*) AS positions,
       SUM(Eligible_Staking_Days) AS sum_eligible_days,
       MAX(PlayerLevel)           AS player_level,
       MAX(RevShare)              AS rev_share
FROM Dealing_dbo.Dealing_Staking_Position
WHERE CID = 10614403
  AND StakingMonthID = 202604
  AND Currency = 'ADA';
```

Result: 417 positions, 12,482 eligible-days (of 12,510 max — ~28 days lost to intro). `PlayerLevel = 'Diamond'`, `RevShare = 0.90`.

### Step 3 — Average daily eligible

```
avg_daily_eligible_units = sum_units_days / days_in_window
                         = 54,752,047 / 30
                         = 1,825,068 ADA per day
```

### Step 4 — Compute the gross monthly reward

Pull network yield from `Summary` (UC OK):

```sql
SELECT AnnualizedYield, USD_ConversionRate, IntroDays
FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary
WHERE Currency = 'ADA' AND StakingMonthID = 202604;
-- AnnualizedYield = 0.02015163  →  monthly = 0.001679
-- USD_ConversionRate = 0.2425
```

Theoretical gross (no intro haircut):
```
1,825,068 × 0.001679 ≈ 3,064 ADA
```

Actual gross after the intro-day haircut already encoded in `Eligible_Staking_Days` (= `Raw_Staking_Amount`):
```
Raw_Staking_Amount = 2,991.33 ADA   -- ~2.4% lower than the theoretical max
```

### Step 5 — Apply the Diamond club share

```
Client_Airdrop = Raw_Staking_Amount × RevShare
              = 2,991.33 × 0.90
              = 2,692.20 ADA
```
eToro's portion = `2,991.33 × 0.10 = 299.13 ADA`, recorded in `Etoro_Amount`.

### Step 6 — Convert to USD

```
USD_Compensation = Client_Airdrop × USD_ConversionRate
                = 2,692.20 × $0.2425
                = $652.86
```

### Step 7 — Verify against the canonical row in `Results`

```sql
SELECT
    Raw_Staking_Amount,
    Client_Airdrop,
    ActualAirdropUnits,
    USD_Compensation,
    Etoro_Amount,
    Etoro_Amount_USD,
    AirdropOccurred,
    IsAirdropSuccess,
    ActualCompensationType
FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
WHERE CID = 10614403
  AND StakingMonthID = 202604
  AND Currency = 'ADA';
-- ActualAirdropUnits = 2,692.197219 ADA
-- AirdropOccurred = 2026-05-05
-- IsAirdropSuccess = 1
-- ActualCompensationType = 'Airdrop'
```

`ActualAirdropUnits` ties to `Client_Airdrop` within rounding (the SP rounds to 6 decimals at airdrop time).

## End-to-end ledger (one-page summary)

```
1,825,068 ADA × 30 days       =  54,752,047 ADA-days       (snapshot sum)
÷ 30 days                      =   1,825,068 ADA / day      (avg daily eligible — gross)
× 0.001679 monthly yield       ≈       3,064 ADA            (theoretical max)
                                                            ↑ intro-day haircut
                                =       2,991 ADA            (Raw_Staking_Amount)
× 0.90 Diamond RevShare         =       2,692 ADA            (Client_Airdrop)
× $0.2425 USD rate              =      $652.86               (USD_Compensation)
```

eToro's side, same ledger:

```
2,991.33 × (1 − 0.90)          =       299.13 ADA            (Etoro_Amount)
× $0.2425                      =       $72.54                (Etoro_Amount_USD)
```

## The `< $1 USD` floor — what happens to tiny positions

A client holding a few TRX (say 50 TRX with `USD_ConversionRate = $0.12` and a Bronze RevShare on a low-yield month) might compute:

```
Client_Airdrop in TRX × $0.12 < $1
                              → flagged IsEligible = 0
                              → NonEligible_PrimaryReason = 'Less than $1'
                              → Client_Airdrop forced to 0
                              → the entire Raw_Staking_Amount moves into Etoro_Amount
                              → USD_Compensation = $0
                              → no airdrop, no cash
```

The client sees nothing. eToro keeps the unit. To audit this population for a month:

```sql
SELECT
    Currency,
    COUNT(*) AS clients_below_threshold,
    SUM(Etoro_Amount_USD) AS etoro_pickup_from_floor_usd
FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
WHERE StakingMonthID = 202604
  AND IsEligible = 0
  AND NonEligible_PrimaryReason = 'Less than $1'
GROUP BY Currency
ORDER BY etoro_pickup_from_floor_usd DESC;
```

## Reproducing the formula for any CID × coin × month

1. **Pull `Summary`** for `(Currency, StakingMonthID)` — gets `AnnualizedYield`, `USD_ConversionRate`, `IntroDays`, `StakingStartDate` / `StakingEndDate`, `MonthlyPool`. (UC OK.)
2. **Pull `OptedOut_PerCID`** filtered to `Date BETWEEN StakingStartDate AND StakingEndDate` — gets `avg_daily_eligible_units` and the per-day `IsOptedIn` history. (Synapse only — 661M rows; always filter by `(CID, Date)`.)
3. **Pull `Position`** for `(CID, StakingMonthID, Currency)` — gets `SUM(Eligible_Staking_Days)`, `RevShare`, `PlayerLevel`, and the eligibility flags. (Synapse only.)
4. **Pull `Results`** for `(CID, StakingMonthID, Currency)` — gets the canonical `Raw_Staking_Amount`, `Client_Airdrop`, `USD_Compensation` to compare against the derivation. (UC OK.)

## The `why is my reward lower than expected` diagnostic

Order of likelihood (from the most-asked-in-CS to the least):

1. **Coin price dropped** — compare `USD_ConversionRate` across months. Most "my reward shrank" complaints trace here.
2. **Network yield slipped** — compare `AnnualizedYield` across months in `Summary`. Network yield can move 20–40% month-over-month, especially for ETH and SOL.
3. **Intro-day haircut** — newly opened positions don't count their first `IntroDays`. A client who topped up mid-month sees a smaller numerator.
4. **Opt-out flips during the month** — check `OptedOut_PerCID.IsOptedIn` for any `0` days within the staking window. Even one opt-out day reduces `Eligible_Staking_Days`.
5. **Eligibility gate failed** — check `Position.IsClientEligible`, `IsAML_Restricted`, `IsRegulationEligible`, `IsEligibleCountry`, `PlayerStatus`. If `IsClientEligible = 0`, the gate fired — see [`eligibility-and-gates.md`](eligibility-and-gates.md).
6. **`< $1` floor** — small positions in low-yield coins forfeit. Check `Results.NonEligible_PrimaryReason = 'Less than $1'`.

If none of the six explain the drop, suspect upstream data staleness — see Critical Warning #6 on the hub. The December 2024 AML incident is the canonical example.

## Skill provenance

- Worked example, formula, RevShare ladder, and `< $1` floor distilled from `eToro/Staking` repo's `README.md`, `How are staking rewards calculated.md`, `Staking_Presentation.md` (October 2024 BI-Trading internal deck), and `agent/examples/reward_calculation_walkthrough.md`.
- `IntroDays` per-coin table queried live from `main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters` on 2026-05-28.
- `PlayerLevelID` ↔ club tier ↔ `RevShare` ladder verified against `README.md` § "Revenue share brackets".
- The "Distribution based on number of opt-in days" rule (since March 2025) is documented in `README.md` § "Step 3 — Units and airdrop calculation".
- v1 (2026-05-28): initial authoring against the post-DD-1747 sub-skill schema. Personal-workspace only.
