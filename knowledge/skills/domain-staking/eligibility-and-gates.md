---
name: domain-staking
description: "Who qualifies for a staking distribution and why. Covers the eight exclusion rules SP_Staking applies in Step 2 against DWH_dbo.Fact_SnapshotCustomer (US regulation RegulationID IN (6,7,8,14); Tangany custody TanganyStatusID IS NOT NULL AND TanganyStatusID <> 4 AND IsCreditReportValidCB = 1; no regulation RegulationID = 0; Smart Portfolio AccountTypeID = 9; Etorian CountryID = 250; ~80 ineligible CountryIDs hard-coded in the SP; AML restricted PlayerStatusID IN (2,9,15,4) or specific SubReasonIDs; inactive AccountStatusID = 2), the seven cash-equivalent CountryIDs that receive USD compensation instead of crypto airdrops (63, 67, 94, 96, 105, 148, 167 — Hungary 94 added Oct 2025), the ETH opt-out-by-default inversion (UserProgramID = 3 for ETH vs UserProgramID = 2 for every other coin) and the post-Nov-2024 IsOptedIn_ETH flag added to Dealing_Staking_Position, the waiver mechanic (IsWaiver = 1 lets a CID through a failed gate), the per-position vs per-(CID, coin, month) eligibility relationship, the forward-looking platform-consent-pop-up gotcha distilled from the March 2025 MICA incident (any new UI consent flow can reset opt-in timestamps and re-trigger IntroDays), the upstream-staleness gotcha distilled from the December 2024 AML incident (SP_Staking is only as fresh as Fact_SnapshotCustomer), and audit query patterns for each gate."
triggers:
  - eligibility
  - eligible
  - not eligible
  - ineligible
  - exclusion
  - excluded
  - IsClientEligible
  - IsEligibleCountry
  - IsCashEquivalentCountry
  - IsRegulationEligible
  - IsAML_Restricted
  - IsAccountStatusEligible
  - IsWaiver
  - waiver
  - IsPI
  - UK_Prohibited
  - IsEtorian
  - Tangany
  - TanganyStatusID
  - IsCreditReportValidCB
  - RegulationID
  - PlayerStatusID
  - AccountStatusID
  - AccountTypeID
  - CountryID
  - PlayerLevelID
  - SubReasonID
  - cash equivalent country
  - cash compensation country
  - ineligible country
  - Smart Portfolio
  - Etorian
  - inactive account
  - MICA
  - MICA pop-up
  - consent pop-up
  - regulatory pop-up
  - opt-in reset
  - first-time opted-in
  - opt-out default
  - opt-in default
  - UserProgramID
  - IsOptedIn_ETH
  - ETH opt-in
  - ETH opt-out
  - why didn't CID
  - why not eligible
  - NonEligible_PrimaryReason
  - AML restricted
  - PlayerStatus
  - Normal
  - blocked by Compliance
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary
  - main.finance.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_optedout
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-28"
---

# Eligibility & Gates

## When to Use

Load when the question is about:

- "Why didn't CID X receive a reward?"
- "What are the eligibility gates for staking?"
- "Which countries get cash compensation instead of crypto?"
- "Why is ETH opt-out by default?"
- "What does `IsOptedIn_ETH` mean and when was it added?"
- "What's a `Waiver` and how is it applied?"
- "What's the `Tangany` exclusion?"
- "How can a long-standing client suddenly fail the `IntroDays` gate?" (MICA pop-up pattern)
- "Why is `IsAML_Restricted` showing the wrong value for [old month]?" (AML-stale pattern)
- "What's the relationship between `Dealing_Staking_Position.IsClientEligible` and `Dealing_Staking_Results.IsEligible`?"

Do **not** load for:

- The reward formula / RevShare math (the gates here filter who enters the formula) — see [`rewards-formula-and-calculation.md`](rewards-formula-and-calculation.md).
- The currency catalogue (`IntroDays` etc. per coin) — see [`currency-catalog-and-parameters.md`](currency-catalog-and-parameters.md).
- The stored procedures that apply the gates — see [`distribution-pipeline.md`](distribution-pipeline.md).
- The master-data definitions of `RegulationID`, `AccountTypeID`, `PlayerStatusID`, etc. — those are in `../domain-customer-and-identity/customer-master-record.md`. This file describes how staking USES those IDs, not what they mean in general.
- The AML screening operation itself — `../domain-compliance-and-aml/SKILL.md`.

## Scope

In scope: the eight `Dealing_dbo.SP_Staking` Step 2 exclusion rules (US regulation, Tangany custody, no regulation, Smart Portfolio, Etorian, hard-coded ineligible CountryID list, AML restricted, inactive); the seven cash-equivalent CountryIDs that receive USD compensation in lieu of crypto airdrops (63, 67, 94, 96, 105, 148, 167 — Hungary added October 2025); the ETH opt-out-by-default convention (`UserProgramID = 3`) vs every-other-coin opt-in-by-default (`UserProgramID = 2`) and the post-November-2024 `IsOptedIn_ETH` flag added to `Dealing_Staking_Position`; the waiver mechanic (`IsWaiver = 1` overrides a failed gate); the relationship between per-position eligibility (`IsClientEligible` on `Position`) and per-(CID, coin, month) eligibility (`IsEligible` on `Results`); the per-gate flag column map (`IsEligibleCountry`, `IsCashEquivalentCountry`, `IsRegulationEligible`, `IsAML_Restricted`, `IsAccountStatusEligible`, `UK_Prohibited`, `IsEtorian`, `IsPI`); the forward-looking platform-consent-pop-up gotcha (any new UI consent flow can re-stamp opt-in dates and re-trigger the `IntroDays` gate — pattern from MICA); the upstream-staleness gotcha (SP_Staking is only as fresh as `Fact_SnapshotCustomer`); audit query patterns to identify ineligible populations.
Out of scope: the reward formula / RevShare math (`rewards-formula-and-calculation.md`); the per-coin `IntroDays` config (`currency-catalog-and-parameters.md`); the stored procedures (`distribution-pipeline.md`); the master-data semantics of CountryID / RegulationID etc. (`../domain-customer-and-identity/customer-master-record.md`); AML screening operations (`../domain-compliance-and-aml/SKILL.md`).
Last verified: 2026-05-28

## Critical Warnings

1. **Tier 1 — ETH is opt-OUT by default (`UserProgramID = 3`); every other coin is opt-IN by default (`UserProgramID = 2`).** This single inversion has produced one full Results re-write (October 2024). When querying ETH eligibility, always check `IsOptedIn_ETH = 1` on `Dealing_Staking_Position` — this flag was added in November 2024 specifically to make the opt-out-default queryable without re-deriving the inversion. For every other coin, the default opt-in is implicit and `IsOptedIn_ETH` does NOT apply (will be NULL or 0).
2. **Tier 1 — `IsClientEligible = 1` on `Dealing_Staking_Position` does not guarantee `IsEligible = 1` on `Dealing_Staking_Results`.** `Position` evaluates the gates per (StakingMonth, CID, PositionID) — a client with multiple positions might have some pass and some fail. `Results` aggregates to (StakingMonth, CID, InstrumentID). The final `Results.IsEligible` also folds in the **`< $1` USD floor** (see [`rewards-formula-and-calculation.md`](rewards-formula-and-calculation.md) Critical Warning #2). A client can pass every gate per-position but still end up `IsEligible = 0` if their pooled reward is sub-dollar.
3. **Tier 1 — Platform consent flows can silently re-stamp opt-in timestamps for long-standing clients.** The March 2025 MICA pop-up forced an EU consent click-through and the platform recorded the click as a NEW opt-in. For non-ETH coins (opt-in by default), this re-stamping then collided with the `IntroDays` gate — long-standing eligible clients were filtered out as "still in intro period" against their pop-up-date opt-in. **Pattern**: whenever a new pop-up, consent flow, or UI re-acknowledgement ships on the platform, audit opt-in timestamps with `SELECT CID, MIN(OptedInDate), MAX(OptedInDate) FROM <opt-in source> WHERE Currency = '<coin>' GROUP BY CID HAVING MIN(OptedInDate) > '<program_start_date>'` to find clients whose oldest opt-in moved.
4. **Tier 2 — `Dealing_Staking_Results.NonEligible_PrimaryReason` is descriptive text, not an enum.** Common values: `'Less than $1'`, `'Inactive account'`, `'AML restricted'`, `'Excluded country'`. When grouping by reason, do `GROUP BY NonEligible_PrimaryReason` directly but treat it as fuzzy — minor text changes between SP versions break LIKE-based filters.
5. **Tier 2 — `Tangany` exclusion has THREE conditions in AND.** `TanganyStatusID IS NOT NULL AND TanganyStatusID <> 4 AND IsCreditReportValidCB = 1`. Status 4 (whatever it means downstream) is the only Tangany status that passes. Forgetting the `IsCreditReportValidCB = 1` condition flags too many CIDs as Tangany-excluded; forgetting `TanganyStatusID <> 4` flags too few.
6. **Tier 2 — `IsWaiver = 1` overrides a failed gate.** A CID can be e.g. AML-restricted but still receive an airdrop if a manual `Waiver` row applies for that (StakingMonth, CID, Currency). When auditing the ineligible population, exclude waivers explicitly: `WHERE IsEligible = 0 AND IsWaiver = 0`. The waiver table itself is in Synapse only (`Dealing_dbo.Dealing_Staking_Waivers` or similar — confirm with `SP_Staking_modified.sql`).
7. **Tier 3 — Cash-equivalent CountryIDs do NOT fail the eligibility gate — they pass through with `OriginalCompensationType = 'Cash'`.** Don't conflate "ineligible country" (filtered out entirely) with "cash-equivalent country" (eligible, but paid in USD rather than crypto). The seven cash-equivalent CountryIDs (63, 67, 94, 96, 105, 148, 167 — Hungary added October 2025) ARE part of the eligible population for revenue / yield accounting; they just get a different `ActualCompensationType` downstream.
8. **Tier 3 — `RegulationID = 0` (no regulation) is a hard exclude.** It looks like a missing value, but in SP_Staking's gate logic `RegulationID = 0` is explicitly checked and excluded — it represents clients whose regulation has not yet been assigned. Don't `COALESCE(RegulationID, default)` in a staking-eligibility audit query.

## The eight exclusion gates (SP_Staking Step 2)

From `eToro/Staking/SQL scripts/SP_Staking_modified.sql` Step 2. Each row of `Fact_SnapshotCustomer` is evaluated; if ANY of the eight conditions is true, the client is excluded for that staking month. The remaining clients enter Step 3 (units and reward calculation).

| # | Exclusion | Condition (SQL form) | Reason |
|---|---|---|---|
| 1 | US regulation | `RegulationID IN (6, 7, 8, 14)` | US clients (Finra, US states, etc.) |
| 2 | Tangany custody | `TanganyStatusID IS NOT NULL AND TanganyStatusID <> 4 AND IsCreditReportValidCB = 1` | Tangany-custodied positions are not staked (separate custody chain) |
| 3 | No regulation | `RegulationID = 0` | Regulation not yet assigned |
| 4 | Smart Portfolio | `AccountTypeID = 9` | Smart Portfolio accounts have their own yield treatment |
| 5 | Etorian | `CountryID = 250` | Internal staff accounts |
| 6 | Ineligible country | Hard-coded ~80-element `IN (...)` list | Sanctioned, OFAC-restricted, or otherwise prohibited jurisdictions |
| 7 | AML restricted | `PlayerStatusID IN (2, 9, 15, 4)` OR specific `SubReasonIDs` | Compliance-blocked accounts |
| 8 | Inactive account | `AccountStatusID = 2` | Closed / dormant |

The corresponding boolean columns on `Dealing_Staking_Position` are:

| Gate # | `Position` column | `Position` column meaning when `= 1` |
|---:|---|---|
| 1 | `IsRegulationEligible` | passed gate 1 (NOT US) |
| 2 | (folded into IsClientEligible) | passed gate 2 (NOT Tangany-blocked) |
| 3 | `IsRegulationEligible` | passed gate 3 (regulation IS assigned) |
| 4 | (folded into IsClientEligible) | passed gate 4 (NOT Smart Portfolio) |
| 5 | `IsEtorian` reversed | `IsEtorian = 0` means passed |
| 6 | `IsEligibleCountry` | passed gate 6 (country NOT on hard-coded ineligible list) |
| 7 | `IsAML_Restricted` reversed | `IsAML_Restricted = 0` means passed |
| 8 | `IsAccountStatusEligible` | passed gate 8 |
| — | `UK_Prohibited` | UK-specific regulatory block (not in the original 8 but applied) |
| — | `IsPI` | professional-investor flag — informational, not a gate |
| — | `IsClientEligible` | aggregate: passed all gates |

`IsClientEligible = 1` ⟺ all eight gates passed for THAT (StakingMonth, CID, PositionID).

## The seven cash-equivalent CountryIDs

These ARE eligible — they pass all eight gates — but pay out in USD instead of crypto airdrop:

| CountryID | Country | Added |
|---:|---|---|
| 63 | (verify against `Dim_Country`) | Original list |
| 67 | (verify) | Original list |
| 94 | Hungary | **October 2025** |
| 96 | (verify) | Original list |
| 105 | (verify) | Original list |
| 148 | (verify) | Original list |
| 167 | (verify) | Original list |

`Dealing_Staking_Position.IsCashEquivalentCountry = 1` flags membership. `OriginalCompensationType = 'Cash'` is written to `Dealing_Staking_Results`. After airdrop time, `ActualCompensationType = 'Cash'` and the entry on `Dealing_Staking_Compensation` carries the USD payout list.

To audit the cash-equivalent population for a month:

```sql
SELECT
    CountryID,
    Country,
    COUNT(DISTINCT CID) AS clients,
    SUM(USD_Compensation) AS total_usd_cash_paid
FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results r
JOIN <Position table for CountryID/Country>  /* Position table is Synapse only */
USING (CID, StakingMonthID, Currency)
WHERE r.StakingMonthID = 202604
  AND r.OriginalCompensationType = 'Cash'
  AND r.IsEligible = 1
GROUP BY CountryID, Country
ORDER BY total_usd_cash_paid DESC;
```

## ETH opt-out-by-default — the single biggest gotcha

For every coin EXCEPT ETH, SP_Staking Step 1 builds a daily opt-in calendar with `UserProgramID = 2` (opt-in-by-default). A client who hasn't explicitly opted OUT is counted as opted-in for every day of the staking window.

For ETH, the same Step 1 uses `UserProgramID = 3` (opt-out-by-default). A client who hasn't explicitly opted IN is counted as opted-OUT for every day of the staking window — i.e. ineligible.

This inversion exists because ETH staking has a 60-day intro period and on-chain unbonding constraints that make the program economically very different from other coins. The customer-facing UI surfaces ETH-staking as an opt-in choice; for other coins it's framed as automatic with an opt-out.

**The October 2024 incident** was an instance where SP_Staking's opt-in capture failed for clients who HAD explicitly opted into ETH — they got `0` reward for October. The fix was to:

1. Move the broken `Currency = 'ETH'` rows from `StakingMonthID = 202410` to `2024100` (shadow re-run ID).
2. Re-run `SP_Staking` for ETH only with the corrected opt-in capture.
3. Add the `IsOptedIn_ETH` boolean column to `Dealing_Staking_Position` so future queries can check ETH eligibility explicitly without re-deriving the inversion.

**Query pattern for ETH eligibility going forward:**

```sql
SELECT
    StakingMonthID,
    COUNT(*) AS positions,
    SUM(CASE WHEN IsOptedIn_ETH = 1 THEN 1 ELSE 0 END) AS opted_in,
    SUM(CASE WHEN IsClientEligible = 1 THEN 1 ELSE 0 END) AS fully_eligible
FROM Dealing_dbo.Dealing_Staking_Position
WHERE Currency = 'ETH'
  AND StakingMonthID = 202604
GROUP BY StakingMonthID;
```

For every other coin, opted-in is implicit unless `Dealing_Staking_OptedOut_PerCID.IsOptedIn = 0` is present for the (CID, Date, InstrumentID) row.

## The MICA / consent-pop-up forward-looking pattern

The March 2025 MICA incident is the canonical example: a regulatory pop-up forced an EU consent click-through, and the platform recorded the click as a NEW opt-in. Combined with the `IntroDays` gate (which requires N days of opt-in before a position starts counting), long-standing eligible clients were filtered out.

**Forward-looking pattern**: whenever any platform UI change ships that requires re-acknowledgement (new T&Cs, region-specific consent, age verification, KYC refresh, etc.), audit:

```sql
-- Did opt-in dates move for long-standing clients on this coin?
SELECT
    Currency,
    COUNT(DISTINCT CID) AS clients_with_recent_optin,
    MIN(MinOptInDate)   AS earliest_min,
    MAX(MinOptInDate)   AS latest_min
FROM (
  SELECT
      Currency,
      CID,
      MIN(Date) FILTER (WHERE IsOptedIn = 1) AS MinOptInDate
  FROM Dealing_dbo.Dealing_Staking_OptedOut_PerCID
  WHERE Date >= '<program_start_date_for_coin>'
  GROUP BY Currency, CID
) t
WHERE MinOptInDate >= '<suspected_popup_date>'
GROUP BY Currency;
```

If `clients_with_recent_optin` jumps for a coin around a known UI-change date, the gate may filter them out for the next `IntroDays` window. Trigger a Proposal-Review audit before SP_Staking runs against that month.

## The AML-staleness forward-looking pattern

The December 2024 AML incident: `DWH_dbo.Fact_SnapshotCustomer.IsAML_Restricted` and related AML fields were stale; clients whose AML status changed during a staking month were screened against outdated data. SP_Staking logic was unchanged — the input was wrong.

**Forward-looking pattern**: SP_Staking's eligibility is only as fresh as `Fact_SnapshotCustomer`. When staking numbers look off but no SP change shipped, before opening an SP bug check:

```sql
SELECT
    MAX(UpdateDate) AS latest_snapshot,
    DATEDIFF(DAY, MAX(UpdateDate), '<expected_run_date>') AS staleness_days
FROM DWH_dbo.Fact_SnapshotCustomer;
-- staleness > 1 day at run time is suspect
```

Other gates with upstream-staleness risk: `IsCreditReportValidCB` (CB credit report), `PlayerStatusID` (compliance status updates), `TanganyStatusID` (custody chain).

## Audit queries

**Why is CID X not eligible for month M, coin C?**

```sql
SELECT
    CID,
    Currency,
    StakingMonthID,
    IsEligible,
    NonEligible_PrimaryReason,
    OriginalCompensationType,
    Raw_Staking_Amount,
    Client_Airdrop,
    USD_Compensation
FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
WHERE CID = <X>
  AND StakingMonthID = <M>
  AND Currency = '<C>';
```

If `NonEligible_PrimaryReason` is set, that's the answer. If `IsEligible = 1` but `USD_Compensation = 0`, check the `< $1` floor — `Etoro_Amount > 0` and `Client_Airdrop = 0` indicates the floor fired.

For deeper inspection (per-position breakdown of WHICH gate fired), drop into `Dealing_Staking_Position` (Synapse only):

```sql
SELECT
    PositionID,
    IsClientEligible,
    IsEligibleCountry,
    IsCashEquivalentCountry,
    IsRegulationEligible,
    IsAML_Restricted,
    IsAccountStatusEligible,
    IsWaiver,
    IsPI,
    UK_Prohibited,
    IsEtorian,
    IsOptedIn_ETH,
    PlayerLevel,
    PlayerStatus,
    Regulation,
    Country
FROM Dealing_dbo.Dealing_Staking_Position
WHERE CID = <X>
  AND StakingMonthID = <M>
  AND Currency = '<C>';
```

The first column that is `0` (or for `IsAML_Restricted` / `UK_Prohibited` / `IsEtorian`, the first that is `1`) identifies which gate fired.

**Per-gate ineligible population for a month, all coins:**

```sql
SELECT
    Currency,
    NonEligible_PrimaryReason,
    COUNT(DISTINCT CID) AS clients,
    SUM(Etoro_Amount_USD) AS etoro_keeps_usd
FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
WHERE StakingMonthID = 202604
  AND IsEligible = 0
GROUP BY Currency, NonEligible_PrimaryReason
ORDER BY Currency, clients DESC;
```

## Skill provenance

- Eight exclusion gates distilled from `eToro/Staking/README.md` § "Step 2 — Eligible population" and `SP_Staking_modified.sql` Step 2.
- Cash-equivalent CountryID list (63, 67, 94, 96, 105, 148, 167; Hungary added October 2025) from `README.md` § "Step 2 — Cash-equivalent countries".
- ETH opt-out / `IsOptedIn_ETH` flag history from `README.md` § "Step 1 — Opt-in / Opt-out calendar" and `agent/context/issues.md` § "Oct 2024 — ETH opt-ins not captured".
- MICA pop-up pattern distilled from `agent/context/issues.md` § "Mar 2025 — MICA consent pop-up reset opt-in dates" — encoded here as a forward-looking audit query (per user preference: "knowledge + gotchas + query filters", not static history).
- AML-staleness pattern from `agent/context/issues.md` § "Sept/Oct/Nov 2024 — AML screening stale".
- `IsOptedIn_ETH` confirmed against `agent/context/tables.md` § "Dealing_Staking_Position" — added ~Nov 2024.
- v1 (2026-05-28): initial authoring. Personal-workspace only.
