---
name: domain-staking
description: "The StakingMonthID convention, the 6-digit-vs-7-digit re-run trap, the shadow direction rule, and the delta-airdrop pattern that follows a re-run. StakingMonthID is normally 6-digit YYYYMM (202604 = April 2026); re-runs after distribution incidents use 7-digit YYYYMM0 form (2025030 = March 2025 re-run, 2024100 = October 2024 re-run). The shadow direction is counter-intuitive: the BROKEN rows move to the 7-digit ID and the NEW authoritative numbers land under the original 6-digit ID. This means `MAX(StakingMonthID)` lands on a shadow re-run, not the latest real month — always filter WHERE StakingMonthID < 1000000 or use MAX(StakingEndDate) instead. The delta-airdrop pattern: after a re-run, Trading Ops only airdrops `new_USD - old_USD > $1` and CIDs whose original payout already exceeded the corrected amount are marked ActualCompensationType = 'Already received <reRunID>'. Covers the canonical query patterns (last completed month, all-time stake totals, audit a specific re-run, dedupe across shadow IDs), the three classes of historical issue (wrong-data execution, eligibility-logic regression, upstream-staleness) framed as forward-looking gotchas with audit queries to apply or avoid, the AirdropOccurred sentinel handling ('1900-01-01' pre-Aug-2025 + NULL post-Aug-2025 both meaning no airdrop), the SP_Staking_Emails-on-failed-airdrop pattern, and the in-place reset vs shadow-id-and-rerun choice that drives whether a 7-digit ID exists for a given month."
triggers:
  - StakingMonthID
  - 7-digit
  - 6-digit
  - re-run
  - rerun
  - re-run id
  - shadow id
  - shadow StakingMonthID
  - "2024100"
  - "2025030"
  - "202503"
  - "202410"
  - MAX StakingMonthID
  - last completed month
  - last distribution
  - delta airdrop
  - second airdrop
  - second distribution
  - Already received
  - ActualCompensationType
  - dedupe shadow
  - "1900-01-01"
  - AirdropOccurred IS NULL
  - sentinel
  - in-place reset
  - reset Results
  - DELETE Compensation
  - reverse Results
  - StakingEndDate
  - audit re-run
  - which month is the latest
  - why is MAX returning 7 digits
required_tables:
  - main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
  - main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-28"
---

# StakingMonthID & Re-runs

## When to Use

Load when the question is about:

- "Why is `MAX(StakingMonthID)` returning a 7-digit number?"
- "What's a re-run StakingMonthID?"
- "What does `StakingMonthID = 2025030` mean?"
- "How do I get the last completed staking month?"
- "How does the delta airdrop work after a re-run?"
- "What's the `'Already received 2025030'` ActualCompensationType marker?"
- "I have rows for both 202503 and 2025030 — which is the truth?"
- "Has [X failure pattern] happened before?" (forward-looking gotcha consultation)
- "Why does `AirdropOccurred = '1900-01-01'` appear?"

Do **not** load for:

- The reward math (the formula doesn't change between original and re-run, only the inputs do) — see [`rewards-formula-and-calculation.md`](rewards-formula-and-calculation.md).
- The four stored procedures (re-run runs the same SP with a different `@Date`) — see [`distribution-pipeline.md`](distribution-pipeline.md).
- The eligibility gates (a re-run may have new gate values but the gate list is the same) — see [`eligibility-and-gates.md`](eligibility-and-gates.md).

## Scope

In scope: the `StakingMonthID` 6-digit `YYYYMM` convention; the 7-digit re-run convention (`YYYYMM0` form, e.g. `2025030` for March 2025, `2024100` for October 2024); the shadow direction rule (BROKEN rows move to 7-digit, NEW authoritative numbers land under the original 6-digit); the `MAX(StakingMonthID)` trap and the recommended filter (`WHERE StakingMonthID < 1000000`) or alternative (`MAX(StakingEndDate)`); the delta-airdrop pattern after a re-run (Trading Ops airdrops only `new_USD - old_USD > $1`, with `ActualCompensationType = 'Already received <reRunID>'` for over-paid clients); the in-place reset vs shadow-id-and-rerun choice (some incidents corrected in place — April 2024, May 2024 — left no shadow ID); the `AirdropOccurred` sentinel handling (`'1900-01-01'` pre-Aug-2025 + `NULL` post-Aug-2025); the three classes of historical issue framed as forward-looking gotchas (wrong-data execution, eligibility-logic regression, upstream-staleness) with audit queries; canonical query patterns (last-completed-month, all-time totals with deduplication, specific re-run audit, dedupe across shadow IDs).
Out of scope: the reward formula (`rewards-formula-and-calculation.md`); the SPs that execute the re-run (`distribution-pipeline.md`); the eligibility gates (`eligibility-and-gates.md`); the live `Dealing_Staking_Parameters` config (`currency-catalog-and-parameters.md`).
Last verified: 2026-05-28

## Critical Warnings

1. **Tier 1 — `MAX(StakingMonthID)` lands on a shadow re-run, not the latest real month.** `7-digit > 6-digit` numerically, so naive `MAX` returns `2025030` (March 2025 re-run shadow) when the user means `202504` (April 2025 authoritative). **Always filter `WHERE StakingMonthID < 1000000`** or use `MAX(StakingEndDate)`. This is the single most common error on the staking dataset.
2. **Tier 1 — Shadow direction is counter-intuitive.** When a re-run happens, an UPDATE rewrites the OLD, BROKEN rows from `202503` to `2025030` (so the broken numbers move INTO the shadow). The new SP_Staking run then writes the corrected rows into a clean `202503`. So `WHERE StakingMonthID < 1000000` returns the authoritative numbers; the 7-digit IDs are an audit trail. Most analysts guess the opposite (assume the SHADOW is the broken version and the NEW is 7-digit) and end up reading bad data. Confirm before designing a query.
3. **Tier 1 — Trading Ops uses a delta-only airdrop for the second distribution after a re-run.** Only `new_USD - old_USD > $1` is airdropped. CIDs whose original payout already exceeded the corrected amount keep what they got and are marked `ActualCompensationType = 'Already received <reRunID>'` (e.g. `'Already received 2025030'`). When summing total distributed for a month with a re-run, UNION the 6-digit and 7-digit rows and de-duplicate by `(CID, InstrumentID)` taking the MAX payout — do not sum both blindly.
4. **Tier 2 — `AirdropOccurred = '1900-01-01'` AND `NULL` both mean "no airdrop happened".** Pre-August-2025 the SP wrote `'1900-01-01'` as the sentinel; from August 2025 on, the same case writes `NULL`. **Always filter out BOTH** when querying real distributions: `WHERE AirdropOccurred IS NOT NULL AND AirdropOccurred <> '1900-01-01'`. Forgetting either gives inflated airdrop counts and wrong "last airdrop date" results.
5. **Tier 2 — Not every issue produces a 7-digit shadow.** April 2024 (wrong-list execution) and May 2024 (all airdrops failed) were corrected IN PLACE — the Results table was reset and re-populated under the same 6-digit `StakingMonthID`. December 2024 (AML staleness) didn't trigger a Results re-write at all — CS handled compensation case-by-case. Only October 2024 (ETH opt-in) and March 2025 (MICA pop-up) produced shadow IDs visible in the data. **Check both shadow IDs (`2024100`, `2025030`) and look for in-place-reset markers (`AirdropID` cleared, `ActualCompensationType` re-populated mid-month) when scanning historical periods.**
6. **Tier 2 — `SP_Staking_Emails` has fired against ALL-FAILED airdrops in the past (May 2024).** Its trigger has no "all-failed" guard. When auditing post-airdrop data, always verify at least one row in `etoro_Trade_AdminPositionLog` for the month has `State = 3`. If zero, the Compensation table is wrong and the month likely needs a reset. See [`distribution-pipeline.md`](distribution-pipeline.md) Critical Warning #1.
7. **Tier 3 — The SP code base has versioned change history at the top of `SP_Staking_modified.sql` in the source repo.** When investigating a regression, check that change-history block before assuming the SP is unchanged. The March 2025 MICA fix is documented there as "Fix RnD Pop-up issue: default opted-in users for non-ETH coins being marked opted-in for the first time" — dated 2025-04-20.

## The `StakingMonthID` convention

| Form | Example | Meaning |
|---|---|---|
| 6-digit `YYYYMM` | `202604` | Authoritative monthly distribution for April 2026 |
| 7-digit `YYYYMM0` | `2025030` | Shadow ID — the BROKEN run of March 2025 (re-done after the MICA issue) |
| 7-digit `YYYYMM0` | `2024100` | Shadow ID — the BROKEN run of October 2024 (re-done after the ETH opt-in issue) |

The trailing `0` is a marker; it has no meaning beyond "this is a shadow". Newer or future shadows may use other trailing digits if multiple re-runs happen for one month.

`StakingMonthID` is INT, so `2024100 > 202412` numerically — that's the source of the `MAX()` trap.

## The shadow-direction rule

From the source repo's `Issues/<month>/SPs/1- Store old results.sql` scripts:

```sql
-- (paraphrased — actual SQL lives in the source repo)
UPDATE Dealing_dbo.Dealing_Staking_Results
SET    StakingMonthID = 2025030
WHERE  StakingMonthID = 202503;

UPDATE Dealing_dbo.Dealing_Staking_Summary
SET    StakingMonthID = 2025030
WHERE  StakingMonthID = 202503;

-- (same for Position, Compensation)

-- SP_Staking then re-runs with @Date = '2025-04-03'
-- writing the corrected rows into a clean StakingMonthID = 202503.
```

**Mental model**: the BROKEN data gets moved to the 7-digit shadow first; THEN the SP re-runs and writes corrected rows into the now-empty 6-digit slot. The 6-digit ID always ends up holding the authoritative numbers.

This is the opposite of what most analysts assume on first glance — confirm in the source repo SQL before designing any time-series that needs precise month-level numbers around `2024-10` or `2025-03`.

## Canonical query patterns

### "Last completed staking month"

```sql
SELECT MAX(StakingMonthID) AS last_month
FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary
WHERE StakingMonthID < 1000000;
```

Or, equivalently, sort by date instead of ID:

```sql
SELECT StakingMonthID
FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary
WHERE StakingMonthID < 1000000
ORDER BY StakingEndDate DESC
LIMIT 1;
```

### "Total USD distributed in the last completed month, by coin"

```sql
SELECT Currency, ClientUSD, EtoroUSD, RewardsToDistribute_USD
FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary
WHERE StakingMonthID = (
    SELECT MAX(StakingMonthID)
    FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary
    WHERE StakingMonthID < 1000000
)
ORDER BY ClientUSD DESC;
```

Use `Summary` not `Results` for this — 178 rows vs 22M, and `ClientUSD` is already the per-coin aggregate.

### "All-time total USD distributed across all months including re-runs (deduplicated)"

For a month with a re-run, the 6-digit ID holds the authoritative numbers and the 7-digit ID holds the broken numbers — sum the 6-digit IDs only:

```sql
SELECT SUM(ClientUSD) AS all_time_client_usd
FROM main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary
WHERE StakingMonthID < 1000000;
```

If you need to include the second-distribution delta-airdrops explicitly (rare — usually only for accounting reconciliation), join Results to itself with a CASE on the 6/7-digit boundary; see "Audit a specific re-run" below.

### "Audit a specific re-run (March 2025)"

Compare the broken run to the corrected run:

```sql
SELECT
    'broken (2025030)' AS run_id,
    Currency,
    SUM(USD_Compensation) AS client_usd,
    COUNT(DISTINCT CID)   AS clients
FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
WHERE StakingMonthID = 2025030
GROUP BY Currency

UNION ALL

SELECT
    'corrected (202503)' AS run_id,
    Currency,
    SUM(USD_Compensation) AS client_usd,
    COUNT(DISTINCT CID)   AS clients
FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
WHERE StakingMonthID = 202503
GROUP BY Currency
ORDER BY Currency, run_id;
```

### "Per-client compensation after a re-run (which clients got the delta, which got `'Already received'`)"

```sql
SELECT
    CID,
    Currency,
    USD_Compensation AS corrected_usd,
    ActualCompensationType,
    AirdropOccurred,
    IsAirdropSuccess
FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
WHERE StakingMonthID = 202503
  AND IsEligible = 1
  AND CID = <X>;
-- If ActualCompensationType = 'Already received 2025030' →
--   client received the original payout (which was >= corrected) on the first airdrop; no delta.
-- If ActualCompensationType = 'Airdrop' / 'Cash' →
--   client received the delta on the second distribution (Apr 30, 2025).
```

## The delta-airdrop pattern in full

After a re-run, Trading Ops does NOT re-airdrop the corrected reward in full. They compute the delta and airdrop only the difference above the $1 threshold:

```
For each (CID, Currency) where the broken run paid out:
    new_USD = USD_Compensation from the corrected 6-digit run
    old_USD = USD_Compensation from the shadow 7-digit run
    delta   = new_USD - old_USD

    if delta > $1:
        airdrop the delta amount in coin units
        ActualCompensationType for the corrected row = 'Airdrop' / 'Cash'

    elif delta <= 0 OR delta < $1:
        no second airdrop
        ActualCompensationType = 'Already received <reRunID>'
```

CIDs whose original payout already exceeded the corrected amount (e.g. the broken run over-paid them) keep what they got — eToro does not claw back.

**Audit pattern**: for a month with a re-run, sum the deliveries correctly:

```sql
-- Total USD actually paid to clients across the original + second distribution
WITH original AS (
    SELECT CID, Currency, USD_Compensation AS original_usd
    FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
    WHERE StakingMonthID = 2025030
      AND IsAirdropSuccess = 1
),
corrected AS (
    SELECT CID, Currency, USD_Compensation AS corrected_usd, ActualCompensationType
    FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
    WHERE StakingMonthID = 202503
)
SELECT
    Currency,
    SUM(GREATEST(COALESCE(original_usd, 0), COALESCE(corrected_usd, 0))) AS total_paid_usd
FROM original
FULL OUTER JOIN corrected USING (CID, Currency)
GROUP BY Currency;
```

The `GREATEST` covers the "Already received" case where the client kept the higher original.

## Three classes of historical issue — as forward-looking patterns

Past incidents are documented in the source repo's `Issues/` folder and distilled in `agent/context/issues.md`. Rather than reproducing the postmortems here (per user preference: "static history isn't useful as a skill"), they are encoded as forward-looking patterns.

### Class 1 — wrong-data execution

**Pattern**: an upstream input (Fivetran row, Trading Ops manual upload, or the airdrop list itself) is the wrong file or fires at the wrong time. SP logic is unchanged.

**Examples in history**: April 2024 (Trading Ops ran February's airdrop list against the April distribution); May 2024 (all first-attempt airdrops failed; `SP_Staking_Emails` auto-fired on bad data).

**Fix pattern (in-place reset, no shadow ID)**:
1. `DELETE FROM Dealing_dbo.Dealing_Staking_Compensation WHERE StakingMonthID = <month>;`
2. `UPDATE Dealing_dbo.Dealing_Staking_Results SET AirdropID = NULL, AirdropOccurred = NULL, IsAirdropSuccess = NULL, ActualAirdropUnits = NULL, FailReasonID = NULL WHERE StakingMonthID = <month>;` and recompute `ActualCompensationType` from scratch.
3. Wait for Trading Ops to re-execute the airdrops correctly.
4. `SP_Staking_Emails` re-runs against the corrected data.

**Forward-looking audit query**: before trusting post-airdrop data for a month, verify the airdrop execution succeeded:

```sql
SELECT
    StakingMonthID,
    Currency,
    COUNT(*) AS rows_with_outcome,
    SUM(CASE WHEN IsAirdropSuccess = 1 THEN 1 ELSE 0 END) AS success_count,
    MIN(AirdropOccurred) AS first_airdrop,
    MAX(AirdropOccurred) AS last_airdrop
FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
WHERE StakingMonthID = <month>
  AND OriginalCompensationType = 'Airdrop'
GROUP BY StakingMonthID, Currency;
```

If `success_count` is zero or close to zero for an eligible coin, the airdrop likely failed and the month needs a reset before `SP_Staking_Emails` re-runs.

### Class 2 — eligibility-logic regression

**Pattern**: a code path inside `SP_Staking` Step 1 / Step 2 (opt-in capture, regulation gate, country list) silently miscategorises a population. Inputs and SP are deployed correctly; the output is wrong.

**Examples in history**: October 2024 (ETH opt-in capture broken — only ETH affected); March 2025 (MICA consent pop-up reset opt-in dates → IntroDays gate excluded long-standing clients).

**Fix pattern (shadow ID + delta airdrop)**:
1. `1- Store old results.sql` moves the broken rows from `<month>` to `<month>0` (e.g. `202503 → 2025030`).
2. SP_Staking patched, re-runs and writes corrected rows into the original 6-digit ID.
3. `4 - Custom Query Post Distribution.sql` builds the delta airdrop list for Trading Ops (compare corrected vs broken on `(CID, Currency)`, ship rows where `corrected_USD - broken_USD > $1`).
4. Trading Ops executes the second distribution; `SP_Staking_Emails` re-runs to update `Dealing_Staking_Compensation`.

**Forward-looking audit query**: after any SP_Staking deploy or upstream UI change (consent flows, regulation cuts, opt-in mechanics), spot-check eligible-CID counts MoM:

```sql
SELECT
    StakingMonthID,
    Currency,
    COUNT(DISTINCT CID) AS eligible_clients,
    SUM(USD_Compensation) AS client_usd
FROM main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results
WHERE StakingMonthID BETWEEN <prev_month> AND <current_month>
  AND StakingMonthID < 1000000
  AND IsEligible = 1
GROUP BY StakingMonthID, Currency
ORDER BY Currency, StakingMonthID;
```

A drop > 10-20% MoM on a coin without a known volume / yield reason is the regression signal.

### Class 3 — upstream-staleness

**Pattern**: SP logic is correct; SP inputs are correct in shape; but upstream data freshness is off (most often `DWH_dbo.Fact_SnapshotCustomer.IsAML_Restricted` or opt-in timestamps).

**Examples in history**: December 2024 (AML status fields not kept current; CIDs whose AML changed during the staking period were screened against stale data).

**Fix pattern**: no Results re-write. Retrospective analysis only; CS handles compensation case-by-case. (Implies the fix is to refresh the upstream and prevent recurrence.)

**Forward-looking audit query**: when staking numbers look off but no SP change shipped, check upstream freshness FIRST:

```sql
SELECT
    'Fact_SnapshotCustomer' AS source,
    MAX(UpdateDate) AS latest_update,
    DATEDIFF(DAY, MAX(UpdateDate), '<expected_run_date>') AS staleness_days
FROM DWH_dbo.Fact_SnapshotCustomer;
-- staleness > 1 day at run time is suspect
```

Repeat for any other input table the eligibility step touches (Tangany source, opt-in source, customer master).

## In-place reset vs shadow-id-and-rerun — when each is used

| Choice | Used when | Marker in data |
|---|---|---|
| **In-place reset** | Wrong-data execution before the airdrop result is on-chain final; the broken data can be cleanly UPDATEd back to NULL/0 | No 7-digit shadow ID; `UpdateDate` jumps mid-month |
| **Shadow ID + re-run** | Airdrop has been executed and rewards have landed in customer wallets; the broken numbers must be preserved for audit but the new authoritative numbers go in their place | 7-digit `StakingMonthID` exists alongside the original 6-digit; `'Already received <reRunID>'` markers in `ActualCompensationType` of the corrected row |

The choice is irreversible — once Trading Ops executes the airdrop, in-place reset is not viable because customer wallets already hold the original units.

## Skill provenance

- 6/7-digit convention and shadow direction from `eToro/Staking/agent/context/tables.md` § "Quick join keys" and `agent/context/issues.md` § "Direction of the shadow".
- Delta-airdrop pattern from `agent/context/issues.md` § "Patterns to watch for — Delta-only second airdrop" and the March 2025 `4 - Custom Query Post Distribution.sql` script in the source repo's `Issues/March 2025 Issue - MICA Pop-Up/SPs/` folder.
- `'1900-01-01'` and `NULL` `AirdropOccurred` sentinel from `agent/context/glossary.md` § "Time".
- Three issue classes derived from the five documented incidents (April 2024, May 2024, October 2024 ETH, December 2024 AML, March 2025 MICA) and abstracted into forward-looking patterns per the user's preference for "knowledge + gotchas + query filters to apply or avoid" rather than static history.
- In-place reset vs shadow-id-and-rerun choice deduced from the same five incidents — April 2024 and May 2024 used in-place reset (no shadow); October 2024 and March 2025 used shadow + re-run; December 2024 used neither (CS case-by-case).
- v1 (2026-05-28): initial authoring. Personal-workspace only.
