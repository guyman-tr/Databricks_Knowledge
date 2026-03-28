# Review Sidecar: BI_DB_dbo.BI_DB_ChargebackReport

> Generated: 2026-03-28 | Quality: 8.5/10 | Tier 4: 0

## Reviewer Corrections

_None yet — awaiting domain expert review._

## Tier 4 (UNVERIFIED) Columns

_None — all 19 columns are Tier 1 (4) or Tier 2 (15)._

## Columns Needing Clarification

### 1. Column Name Typo — "Ammount"

**Column**: `CHB/ Refund $ Ammount * (-1)`

**Question**: The column name contains a typo ("Ammount" instead of "Amount"). Is this known / too risky to rename?

### 2. CHB Reason — Source Mismatch

**Column**: `CHB Reason`

**Question**: This is sourced from `Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName`, not from a dedicated chargeback reason table. Is this the correct business mapping, or should it come from a chargeback-specific source?

### 3. CHB Loss vs CHB Loss by Risk USE — Difference

**Columns**: `CHB Loss`, `CHB Loss by Risk USE`

**Question**: Both measure chargeback loss but differ:
- `CHB Loss` considers payment status (CHB vs Refund) and can be positive or negative
- `CHB Loss by Risk USE` ignores payment status and only looks at negative balance

Which metric is preferred for reporting? Is there documentation on when to use each?

### 4. Final — Net Credit Change

**Column**: `Final`

**Question**: This column calculates credit change from Fact_SnapshotEquity. The calculation uses `#chbkloss` which filters to `Credit < 0` accounts only. Does this mean the `Final` column is NULL/0 for customers whose balance remained positive after the chargeback?

### 5. PaymentStatus — varchar(max)

**Column**: `PaymentStatus`

**Question**: Defined as `varchar(max)` but only contains short status names (Chargeback, Refund, RefundAsChargeback). Should this be `varchar(100)` for consistency with other columns?

## Structural Questions

### S1. Cashout Refund Path — Limited Funding Types

The cashout refund path only includes FundingTypeID 29 (ACH) and 32 (PWMB). Why are other funding types excluded? Is this a business rule or an omission?

### S2. PlayerLevelID != 4 and LabelID != 26

The deposit path excludes `PlayerLevelID = 4` and `LabelID = 26`. What do these exclusions represent? (PlayerLevelID=4 is likely "Internal/Test", LabelID=26 is unknown.)

### S3. RN Column — ORDER BY CID DESC

`ROW_NUMBER() OVER (PARTITION BY CID ORDER BY CID DESC)` — ordering by CID within a partition of CID is deterministic (always 1 for single events), but for multiple events per CID within the same run, the order is effectively arbitrary. Should this be `ORDER BY Occurred DESC` instead?

### S4. No Unique Key

No primary key or unique constraint. Multiple rows per CID are possible (one per event). The `RN` column provides intra-customer ordering but doesn't guarantee uniqueness across the full table.
