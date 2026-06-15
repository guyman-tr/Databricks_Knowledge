---
name: domain-staking
description: "The four-stored-procedure monthly distribution pipeline that materialises staking rewards. SP_Staking (main, @Date DATE parameter) runs in five steps — pull parameters from Fivetran_google_sheets.platform_rewards joined to Dealing_Staking_Parameters; build the daily opt-in/opt-out calendar per GCID with UserProgramID=2 default for non-ETH and UserProgramID=3 default for ETH; apply the eight eligibility exclusions; pull open positions from BI_DB_PositionPnL and closed from Dim_Position then compute Eligible_Staking_Days and the proportional reward; write four output tables (Dealing_Staking_Results per-CID-per-coin ledger, Dealing_Staking_Summary per-coin monthly totals, Dealing_Staking_Club per-tier threshold, Dealing_Staking_Position per-position eligibility detail). SP_Staking_Emails (post-airdrop, @Date DATE) triggers when etoro_Trade_AdminPositionLog contains airdrop rows with OpenActionType=11 AND latest record arrived more than 3 hours ago AND Dealing_Staking_Compensation is empty for the month — it updates Results with AirdropID / AirdropOccurred / IsAirdropSuccess / ActualAirdropUnits / FailReasonID / ActualCompensationType, populates Dealing_Staking_Compensation (cash list for CS), and populates Dealing_Staking_Emails_New (Mailing_Group assignments — AirDropClubs / AirDropBronze / AirDropUSAOnly / FailedNegativeBalance / FailedMaxLeverage / Excluded_Countries / Technical_Issue). SP_Staking_DailyPool tracks daily totals plus monthly average for Labs and excludes opted-out units (since August 2024) within the LiquidityBuffer range. SP_Staking_WelcomeEmail (still on old DWH, migration pending) sends a CSV twice a week with new-position openers. Covers all seven FailReasonID codes (Success / Max Leverage / Negative balance / Compliance block / RealTrade not available / Min Leverage / GetUserOpenPositionSettingsAsync failed) and their compensation outcomes (Airdrop / Cash / None), the trigger logic for each SP, and the full operational monthly timeline (Reconciliation → Calculation → Distribution → Compensation → Post Distribution)."
triggers:
  - SP_Staking
  - SP_Staking_Emails
  - SP_Staking_DailyPool
  - SP_Staking_WelcomeEmail
  - stored procedure
  - staking SP
  - staking pipeline
  - staking workflow
  - monthly distribution
  - airdrop pipeline
  - Fivetran_google_sheets.platform_rewards
  - platform_rewards
  - etoro_Trade_AdminPositionLog
  - OpenActionType
  - OpenActionType = 11
  - AirdropID
  - AirdropOccurred
  - IsAirdropSuccess
  - ActualAirdropUnits
  - FailReasonID
  - ActualCompensationType
  - OriginalCompensationType
  - Cash
  - None
  - Success
  - Max Leverage exceeded
  - Negative balance
  - User blocked by Compliance
  - RealTrade not available
  - Min Leverage variant
  - GetUserOpenPositionSettingsAsync
  - Mailing_Group
  - AirDropClubs
  - AirDropBronze
  - AirDropUSAOnly
  - FailedNegativeBalance
  - FailedMaxLeverage
  - Excluded_Countries
  - Technical_Issue
  - DailyTotalStakingPool
  - Avg_DailyTotalStakingPool
  - Dealing_Staking_Results
  - Dealing_Staking_Summary
  - Dealing_Staking_Compensation
  - Dealing_Staking_Emails_New
  - Dealing_Staking_Position
  - Dealing_Staking_Club
  - Dealing_Staking_DailyPool
  - Dealing_Staking_OptedOut
  - Dealing_Staking_OptedOut_PerCID
  - BI_DB_PositionPnL
  - Proposal Overview
  - Proposal Drill-Down
  - Airdrops List
  - rewards calculation
  - rewards distribution
  - compensation list
  - operational timeline
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary
  - main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_dailypool
  - main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout
  - main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_parameters
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-28"
---

# Distribution Pipeline & Stored Procedures

## When to Use

Load when the question is about:

- "Walk me through what SP_Staking does"
- "When does SP_Staking_Emails fire?"
- "What's the trigger condition for SP_Staking?"
- "What FailReasonID means [X]?"
- "What's the difference between OriginalCompensationType and ActualCompensationType?"
- "Which `Mailing_Group` does this client belong to?"
- "What's in `Dealing_Staking_Compensation`?"
- "What runs daily vs monthly vs twice-weekly?"
- "Why didn't the airdrop happen?" (FailReasonID drill-down)
- "What's the monthly operational timeline?"

Do **not** load for:

- The reward math (what the SP computes) — see [`rewards-formula-and-calculation.md`](rewards-formula-and-calculation.md).
- The eligibility gates (what the SP filters on) — see [`eligibility-and-gates.md`](eligibility-and-gates.md).
- The currency parameters the SP reads — see [`currency-catalog-and-parameters.md`](currency-catalog-and-parameters.md).
- The re-run convention when an SP needs to be re-executed — see [`staking-month-id-and-reruns.md`](staking-month-id-and-reruns.md).

## Scope

In scope: the four stored procedures (`Dealing_dbo.SP_Staking`, `Dealing_dbo.SP_Staking_Emails`, `Dealing_dbo.SP_Staking_DailyPool`, `Dealing_dbo.SP_Staking_WelcomeEmail`); their trigger conditions, `@Date DATE` parameter semantics, step-by-step logic, and output tables; the seven `FailReasonID` codes (1=Success, 2=Max Leverage, 3=Negative balance, 4=Compliance, 5=RealTrade not available, 6=Min Leverage, 7=GetUserOpenPositionSettings failed) and their `Airdrop` / `Cash` / `None` compensation outcomes; the seven `Mailing_Group` categories assigned by `SP_Staking_Emails` (AirDropClubs / AirDropBronze / AirDropUSAOnly / FailedNegativeBalance / FailedMaxLeverage / Excluded_Countries / Technical_Issue); the distinction between `OriginalCompensationType` (assigned by `SP_Staking` pre-airdrop based on country list) and `ActualCompensationType` (updated by `SP_Staking_Emails` post-airdrop based on actual outcome); the role of `etoro_Trade_AdminPositionLog` with `OpenActionType = 11` as the post-airdrop trigger source; the monthly operational timeline (Reconciliation → Rewards Calculation → Rewards Distribution → Compensation → Post Distribution); the cross-SP dependency cascade.
Out of scope: reward math (`rewards-formula-and-calculation.md`); eligibility gates (`eligibility-and-gates.md`); per-coin Parameters (`currency-catalog-and-parameters.md`); re-run convention (`staking-month-id-and-reruns.md`); customer-facing T&Cs for staking; on-chain settlement / wallet (`../domain-payments/crypto-wallet.md`).
Last verified: 2026-05-28

## Critical Warnings

1. **Tier 1 — `SP_Staking_Emails` has no `"all airdrops failed"` guard.** Its trigger is (a) airdrop rows in `etoro_Trade_AdminPositionLog` for the month with `OpenActionType = 11`, (b) latest airdrop arrived > 3 hours ago, (c) `Dealing_Staking_Compensation` is empty for the month. If every airdrop FAILED (every row has `State <> 3`), the SP still fires and writes a wrong Compensation table classifying everyone as `Cash` or `None`. **Audit pattern**: before trusting post-airdrop data, verify at least one `State = 3` row in `etoro_Trade_AdminPositionLog` for the month. If zero, the Compensation table is suspect and an analyst should reset & re-run (see the May 2024 incident).
2. **Tier 1 — `SP_Staking` writes a chain of FOUR output tables; an analyst running the SP partially or aborting mid-run can leave them inconsistent.** Order: `Results` → `Summary` → `Position` → `Club`. If `Results` updates but `Summary` doesn't, dashboards built on `Summary` will show stale aggregate even though `Results` is current. After a manual re-run, always verify `MAX(UpdateDate)` matches across the four tables.
3. **Tier 1 — `OriginalCompensationType` vs `ActualCompensationType` are different columns at different lifecycle stages.** `SP_Staking` writes `OriginalCompensationType` (pre-airdrop classification — `'Airdrop'` for normal eligible, `'Cash'` for cash-equivalent countries, `'None'` for ineligible). `SP_Staking_Emails` (post-airdrop) writes `ActualCompensationType` which reflects what actually happened (`'Airdrop'` if successful, `'Cash'` if airdrop failed but eligible for cash compensation, `'None'` if failed and not eligible for compensation). Filter on the right one depending on the question: `Original` for pre-airdrop pool analysis, `Actual` for post-distribution accounting.
4. **Tier 2 — The post-2026-03-30 source for `platform_rewards` is SharePoint via Fivetran (`Fivetran_google_sheets.platform_rewards`); the pre-migration source was `Dealing_staging.Fivetran_google_sheets_platform_rewards`.** Any analyst running historical SPs against months before 2026-03-30 should be aware that the old staging table no longer auto-populates. The two tables share a schema but the data path differs.
5. **Tier 2 — `Fact_SnapshotCustomer` is read in Step 2; staleness silently breaks eligibility.** See `eligibility-and-gates.md` Critical Warning on AML-staleness. SP_Staking is only as fresh as its master-data inputs.
6. **Tier 3 — `SP_Staking_WelcomeEmail` still runs on the OLD DWH (pre-Synapse migration).** Per `README.md` § "Status and Maintenance" — "needs to be migrated from the old DWH". When auditing welcome-email coverage for a new coin, route the question to the old DWH, not Synapse.
7. **Tier 3 — `SP_Staking_DailyPool` excludes opted-out clients from the pool (since August 2024).** Before August 2024 the daily pool tracked total opted-in + opted-out; after, opted-out clients are out of the numerator. Time-series analyses spanning that boundary need to account for the methodology change.

## The four stored procedures at a glance

| SP | Cadence | Trigger | `@Date` parameter | Output tables |
|---|---|---|---|---|
| `Dealing_dbo.SP_Staking` | Monthly (~5th of following month) | `Fivetran_google_sheets.platform_rewards` has an active row for the month AND `Dealing_Staking_Results` empty for that month | The "as-of" date for the calculation (sets `StakingMonthID` and the staking window) | `Dealing_Staking_Results`, `Dealing_Staking_Summary`, `Dealing_Staking_Position`, `Dealing_Staking_Club` |
| `Dealing_dbo.SP_Staking_Emails` | Post-airdrop (~6th of following month, after Trading Ops) | `etoro_Trade_AdminPositionLog` has `OpenActionType = 11` rows for the month AND latest arrived > 3 hours ago AND `Dealing_Staking_Compensation` empty for the month | Same `@Date` as `SP_Staking` for the month | Updates `Dealing_Staking_Results`; writes `Dealing_Staking_Compensation`, `Dealing_Staking_Emails_New` |
| `Dealing_dbo.SP_Staking_DailyPool` | Daily | (verify scheduling — likely cron) | Date (current calendar day) | `Dealing_Staking_DailyPool` |
| `Dealing_dbo.SP_Staking_WelcomeEmail` | Twice weekly (old DWH) | (verify scheduling) | (verify) | CSV file to Marketing — no Synapse table |

## SP_Staking — step-by-step

From `eToro/Staking/SQL scripts/SP_Staking_modified.sql`. The `@Date DATE` parameter is the "as-of" date which determines `StakingMonthID` and the staking window boundaries.

### Step 0 — Pull parameters
- Source: `Fivetran_google_sheets.platform_rewards` (SharePoint-backed since 2026-03-30; previously `Dealing_staging.Fivetran_google_sheets_platform_rewards`).
  - **UC mirror for Databricks-side queries**: `main.sharepoint.silver_sharepoint_platform_rewards` (live, Excel-on-SharePoint via Fivetran). The Synapse table above is the operational SP_Staking input; the UC mirror is the analyst-facing copy.
- Joined to `Dealing_dbo.Dealing_Staking_Parameters` for per-coin config.
- EUR variants (ETHEUR / SOLEUR / ADAEUR) are inserted separately and their `InstrumentID` remapped to the USD equivalent for the downstream calculation — see [`currency-catalog-and-parameters.md`](currency-catalog-and-parameters.md).

### Step 1 — Opt-in / Opt-out calendar
Builds a daily calendar per GCID for the full staking window (including IntroDays look-back):
- All non-ETH coins: opted-in by default (`UserProgramID = 2`).
- ETH: opted-out by default (`UserProgramID = 3`).

Output materialised into `Dealing_Staking_OptedOut_PerCID` (the per-CID daily eligibility ledger, ~661M rows over the program's lifetime).

### Step 2 — Eligible population
Applies the eight exclusion gates. See [`eligibility-and-gates.md`](eligibility-and-gates.md) for the full list. Output: the eligible (CID, Currency, Date) population.

Cash-equivalent CountryIDs (63, 67, 94, 96, 105, 148, 167 — Hungary added October 2025) pass through but are flagged with `OriginalCompensationType = 'Cash'`.

### Step 3 — Units and airdrop calculation
- Open positions sourced from `BI_DB_PositionPnL`; closed positions from `Dim_Position`.
- Each position earns `AmountInUnitsDecimal × Eligible_Staking_Days`; reward is proportional to that weighted sum across the pool.
- `IntroDays` must elapse after BOTH the position open date AND the first opt-in date before a position starts counting.
- Minimum: `Client_Airdrop × USD_ConversionRate < $1` flags the row `IsEligible = 0` (since August 2024).
- Distribution based on number of opt-in days within the staking period (since March 2025) — pre-March-2025 used a binary opt-in flag at start-of-month.

The six-tier RevShare ladder (Bronze 0.45 → Diamond 0.90) is applied via `PlayerLevelID`. See [`rewards-formula-and-calculation.md`](rewards-formula-and-calculation.md).

### Step 4 — Output table writes
| Table | Grain | Content |
|---|---|---|
| `Dealing_Staking_Results` | 1 row per (StakingMonthID, CID, InstrumentID) | Per-client ledger: eligibility, `Raw_Staking_Amount`, `Client_Airdrop`, `Etoro_Amount`, `USD_Compensation`, `Etoro_Amount_USD`, `OriginalCompensationType` |
| `Dealing_Staking_Summary` | 1 row per (StakingMonthID, InstrumentID) | Aggregate per coin: `RewardsToDistribute`, `ClientUSD`, `EtoroUSD`, `AnnualizedYield`, `IntroDays` (frozen for this month) |
| `Dealing_Staking_Position` | 1 row per (StakingMonthID, CID, PositionID) | Per-position eligibility flags: `IsClientEligible`, `IsEligibleCountry`, `IsRegulationEligible`, `IsAML_Restricted`, `IsAccountStatusEligible`, `IsOptedIn_ETH`, `PlayerLevel`, `RevShare`, `Eligible_Staking_Days` |
| `Dealing_Staking_Club` | 1 row per (StakingMonthID, InstrumentID, PlayerLevel) | The `Avg_Daily_Holdings_Threshold` to reach `$1 USD` reward per tier — reference for the `< $1` floor |

## SP_Staking_Emails — step-by-step

Triggered after Trading Ops executes the actual airdrop. Reads `Dealing_staging.etoro_Trade_AdminPositionLog` filtered to `OpenActionType = 11` (the airdrop action type) for the month.

### What it updates and writes

1. **Updates `Dealing_Staking_Results`** with actual outcomes:
   - `AirdropID` — the Trading Ops execution ID
   - `AirdropOccurred` — actual blockchain airdrop date (or `1900-01-01` pre-Aug-2025 / `NULL` post-Aug-2025 for "no airdrop")
   - `IsAirdropSuccess` — 1 if `State = 3` on the AdminPositionLog row
   - `ActualAirdropUnits` — what actually got airdropped (`decimal(38,8)`)
   - `FailReasonID` — see code table below
   - `ActualCompensationType` — `'Airdrop'` / `'Cash'` / `'None'` depending on outcome

2. **Writes `Dealing_Staking_Compensation`** — the cash compensation list for CS (per CID × currency).

3. **Writes `Dealing_Staking_Emails_New`** — marketing email groups (per GCID × currency). Note: grain key is `GCID`, not `CID` (see hub Critical Warning #14).

### The seven `FailReasonID` codes

| `FailReasonID` | `ErrorCode` | Meaning | `ActualCompensationType` |
|---:|---|---|---|
| 1 | — | Success | Airdrop |
| 2 | 619 | Max Leverage exceeded | Cash |
| 3 | 604 | Negative balance | Cash |
| 4 | 623 / 765 / 766 / 813 / 1051 | User blocked by Compliance | None |
| 5 | 815 | RealTrade not available (excluded country) | Cash |
| 6 | 764 + GCID in FailReason | Min Leverage variant | Cash |
| 7 | 798 | `GetUserOpenPositionSettingsAsync` failed | Cash |

Of these:
- Reason 1 = customer received crypto.
- Reasons 2, 3, 5, 6, 7 = customer eligible but airdrop technically failed → paid in cash from `Dealing_Staking_Compensation`.
- Reason 4 = compliance block, no compensation.

To audit fail-reason distribution for a month:

```sql
SELECT
    Currency,
    FailReasonID,
    ActualCompensationType,
    COUNT(*) AS rows,
    SUM(USD_Compensation) AS usd_paid,
    SUM(Etoro_Amount_USD) AS etoro_usd
FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
WHERE StakingMonthID = 202604
  AND AirdropOccurred IS NOT NULL
  AND AirdropOccurred <> '1900-01-01'
GROUP BY Currency, FailReasonID, ActualCompensationType
ORDER BY Currency, FailReasonID;
```

### The seven `Mailing_Group` categories

`Dealing_Staking_Emails_New.Mailing_Group` segments the post-airdrop population for Marketing Automation:

| `Mailing_Group` | Condition |
|---|---|
| `AirDropClubs` | `IsAirdropSuccess = 1` AND non-US (CountryID <> 219) AND non-Bronze (PlayerLevelID <> 1) |
| `AirDropBronze` | `IsAirdropSuccess = 1` AND non-US AND Bronze (PlayerLevelID = 1) |
| `AirDropUSAOnly` | `IsAirdropSuccess = 1` AND US (CountryID = 219) |
| `FailedNegativeBalance` | `FailReasonID = 3` |
| `FailedMaxLeverage` | `FailReasonID IN (2, 6)` (both max and min leverage variants) |
| `Excluded_Countries` | `FailReasonID = 5` OR `OriginalCompensationType = 'Cash'` |
| `Technical_Issue` | `FailReasonID = 7` |

Marketing Automation uses these groups to send tier- and outcome-appropriate emails (e.g. Diamond clients get a different message than Bronze).

## SP_Staking_DailyPool

Daily-cadence SP. Writes `Dealing_Staking_DailyPool` with one row per (Date, InstrumentID):

- `DailyTotalStakingPool` — the current day's eligible pool in units.
- `Avg_DailyTotalStakingPool` — running 30-day average for the cycle.

Used by Labs for two things:
1. Monitor client holdings and verify consistency with their own staking data.
2. Drive the `Opted-Out Monitoring` Tableau report — ensures opted-out units stay within the `LiquidityBuffer` range. If clients un-opt at scale, this report flags the breach so the dealer side can adjust the hedge book.

**Since August 2024**: opted-out clients are excluded from `DailyTotalStakingPool`. Time-series analyses spanning that boundary need to know about the methodology change.

## SP_Staking_WelcomeEmail

Sends a CSV file twice a week to Marketing listing users who opened a position for the first time on a staked cryptocurrency. The customer receives a welcome email and can choose to waive participation (which then writes to the waiver table consumed by `SP_Staking` Step 2).

**Migration pending**: still runs on the old DWH per `README.md` § "Status and Maintenance" — to be moved to Synapse.

## Monthly operational timeline

Adapted from `eToro/Staking/README.md` § "Operational Process — Example: Oct 2024 Timeline". Days are relative to the following month (rewards for October distribute in November).

| Day | Phase | Activities | Departments |
|---|---|---|---|
| Day 4 (Nov 4) | Reconciliation | Monthly results available; reconciliation with Labs and Middle Office | Staking PM, Labs, Middle Office, Finance |
| Day 5 (Nov 5) | Rewards Calculation | `SP_Staking` runs; BI Trading reviews the Proposal Overview | Staking PM, Labs, BI Trading |
| Day 6 (Nov 6) | Rewards Distribution | Preparation of Airdrops List from Tableau; Trading Ops executes airdrops | Staking PM, BI Trading, Trading Ops |
| Day 7 (Nov 7) | Compensation | `SP_Staking_Emails` runs (~3 hours after last airdrop); CS receives cash list | Staking PM, BI Trading, CS |
| Day 7 (Nov 7) | Post Distribution | Marketing emails distributed via Marketing Automation | Staking PM, Marketing automation, BI Trading |

The full Staking Workbook (Tableau workbook 6291) contains Post-Distribution dashboards as well as views for CS, Labs, and other stakeholders.

## Cross-SP dependency cascade

Any change to one SP must be replicated in the others — they share hard-coded eligibility lists (country, regulation, status, account-type) and column extension patterns:

| Change | Touches |
|---|---|
| Add a new currency | `Parameters` (row) → `SP_Staking_Emails` (4 columns + `#Emails` temp table) → 4 Tableau views (Opted-Out Monitoring, Proposal Overview, Drill-Down, Airdrops List) → Main KPIs Over Months (legend/axis) → Marketing template |
| Change eligibility logic (e.g. add a country to ineligible list) | `SP_Staking` (Step 2) → `SP_Staking_Emails` (post-airdrop classification) → `SP_Staking_DailyPool` (pool computation) → Tableau custom queries embedded with same lists |
| Change RevShare ladder | `SP_Staking` (Step 3) → `Dealing_Staking_Club` regeneration → Tableau dashboards |

See `currency-catalog-and-parameters.md` § "Process of Adding a New Currency" for the full cascade table for new-coin onboarding.

## Skill provenance

- SP trigger conditions and step-by-step logic from `eToro/Staking/README.md` § "Procedure Structure, Parameters, Technical Details" (§§ 1-4).
- `FailReasonID` code table from `README.md` § "Airdrop fail reason codes".
- `Mailing_Group` table from `README.md` § "Marketing email groups (Mailing_Group)".
- Operational timeline from `README.md` § "Operational Process — Example: Oct 2024 Timeline".
- `SP_Staking_WelcomeEmail` old-DWH status from `README.md` § "Status and Maintenance".
- `OriginalCompensationType` vs `ActualCompensationType` distinction from `agent/context/tables.md` § "Dealing_Staking_Results".
- v1 (2026-05-28): initial authoring. Personal-workspace only.
