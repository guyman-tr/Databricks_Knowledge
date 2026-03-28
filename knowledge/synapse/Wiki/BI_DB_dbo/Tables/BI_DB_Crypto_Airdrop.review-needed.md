# Review Sidecar: BI_DB_dbo.BI_DB_Crypto_Airdrop

> Generated: 2026-03-28 | Quality: 8.5/10 | Tier 4: 0

## Reviewer Corrections

_None yet — awaiting domain expert review._

## Tier 4 (UNVERIFIED) Columns

_None — all 37 columns are Tier 1 (4) or Tier 2 (33)._

## Columns Needing Clarification

### 1. Column Name Typos — "WasTarded" instead of "WasTraded"

**Columns**: `WasTardedCFDIn30Days`, `WasTardedCFDAfter30Days`

**Question**: Both columns have "Tarded" instead of "Traded". Is this a known typo that's too risky to rename due to downstream consumers?

### 2. Sentinel Values — Non-Standard

**Columns**: Multiple (OpenOccurredAD, FirstPositionOpenOccured, MinOpenOccuredCFD, FirstPositionID, FirstPositionAmount, FirstPositionInstrument)

**Question**: The SP uses 5 different sentinel values (`1900-01-01`, `2900-01-01`, `-1`, `'A'`, `0`). This is fragile — should these be standardized to NULL?

### 3. DesignatedRegulationID Exclusions

**Column**: `DesignatedRegulation`

**Question**: The SP excludes `DesignatedRegulationID NOT IN (7, 8)`. Based on context, 7 = NFA and 8 = eToroUS. Is this correct? Are there other regulation IDs that should be excluded?

### 4. Eligible Instruments — Hardcoded List

**SP Logic**: Airdrop eligibility checks `BuyCurrency IN ('BTC', 'ETH', 'DOGE', 'SHIBxM', 'LTC', 'COMP', 'LINK', 'BCH', 'XLM')`.

**Question**: Is this list still current? Were any crypto instruments added or removed since the initial campaign?

### 5. IsDepositor — Point-in-Time vs Current

**Column**: `IsDepositor`

**Question**: The SP joins Fact_SnapshotCustomer with Dim_Range to get the depositor status at the V3 verification date. However, the Dim_Range join logic (`DateRangeID BETWEEN FromDateID AND ToDateID`) with the V3 date gives the snapshot AT verification time. Is this the intended behaviour, or should it reflect current depositor status?

## Structural Questions

### S1. Country Rollout — Wave Assignment

The SP hardcodes 30 countries with 3 rollout waves (2023-05-15, 2023-05-22, 2023-05-29). However, not all countries in the WHERE clause have a CASE assignment for RolloutDate (e.g., US=219, Spain=191, Poland=164, Austria=13, Belgium=19, Norway=154, Denmark=57, Finland=72, Sweden=196). These countries get `RolloutDate = NULL`, which means `IsRelevant = CASE WHEN registered >= NULL = 0` — they are effectively excluded from the population despite being in the country list. Is this intentional?

### S2. No Parameters in SP

The SP has no `@Date` parameter — the variable declarations are commented out. It rebuilds the entire population daily. Is there a reason for not accepting a date parameter?

### S3. 60-Day Metrics — Non-Cumulative

The 60-day count/amount columns capture activity in the 31–60 day window ONLY (`OpenOccurred > 30DaysAfterAD/FA AND <= 60DaysAfterAD/FA`). This is non-standard — most analysts expect "60-day" to mean cumulative from day 0. This should be prominently flagged.

### S4. HEAP + ROUND_ROBIN

No indexing or distribution optimization for a 1.7M row table. If query patterns focus on CID lookups, HASH(CID) + CLUSTERED INDEX(CID) would be more efficient.
