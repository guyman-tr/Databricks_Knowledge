# Compare — `eMoney_dbo.eMoney_Client_Balance_Check_Opening_Balance`

**Bucket**: `slop`

**Verdict**: **WORSE**  (score delta -0.5; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.85 | 8.35 | -0.5 |
| Slop hits (`Tier 4 ... inferred`) | 0 | 0 | +0 |
| Element rows | 3 | 3 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 3 | 3 | +0 |
| T3 count | 0 | 0 | +0 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 10 | 8 |
| data_evidence | 7 | 6 |
| shape_fidelity | 9 | 9 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `2` | 0.401 | 2 | 2 | Aggregate opening balance gap for the check date. Computed as `SUM(OpeningBalanceGAP)` from eMoneyClientBalance, where OpeningBalanceGAP = OpeningBalanceByCB − OpeningBalance per account. Non-zero val | Aggregate opening balance gap across all Tribe fiat accounts for the business date. Computed as SUM(eMoneyClientBalance.OpeningBalanceGAP) WHERE BalanceDateID = @DateID, filtered by HAVING SUM <> 0. A |
| `3` | 0.485 | 2 | 2 | The @Date parameter passed to SP_eMoney_Client_Balance_Check_Opening_Balance when this check was run. Represents the SP execution date, which may differ from Date if the check is run retroactively. (T | The business date passed as the @Date input parameter to SP_eMoney_Client_Balance_Check_Opening_Balance. Set to the same value as the @d parameter from the calling SP_eMoney_ClientBalance daily run. ( |
| `1` | 0.529 | 2 | 2 | The balance date (BalanceDateID converted to date) for which an opening balance discrepancy was detected. Derived via `CAST(CONVERT(DATETIME, CONVERT(CHAR(8), BalanceDateID)) AS DATE)` from eMoneyClie | Business date for which the opening balance gap was detected. Derived from eMoneyClientBalance.BalanceDateID by converting the integer YYYYMMDD back to a date type via CAST(CONVERT(DATETIME, CONVERT(c |

## Top issues — regen wiki (per judge)

- [low] `Section 2.1` — Wiki states TRUNCATE is called 'at the start of every SP run' but SP code builds #final first, then TRUNCATEs, then INSERTs. TRUNCATE is mid-SP, not at the start.
- [low] `Section 2.2 — Openning_Balance_Gap` — Wiki describes per-account OpeningBalanceGAP formula as ISNULL(prior_day_ClosingBalanceBO - current_OpeningBalance, 0). Actual SP uses CASE WHEN oc.AccountId IS NULL THEN 0 ELSE (oc.OpeningBalanceByCB - b.OpeningBalance) END — semantically similar but technically different construct.
- [low] `Footer` — Footer claims P3 (distribution analysis) completed, but table has 0 rows — distribution analysis is vacuous for an empty table.
- [low] `Section 1` — No date range stated. While defensible for a 0-row table, an explicit note acknowledging absence would be clearer.
- [low] `Section 7.2` — Drill-down query uses SELECT TOP 1 Date as subquery; could note that the query returns 0 rows (not an error) when the alert table is empty.
