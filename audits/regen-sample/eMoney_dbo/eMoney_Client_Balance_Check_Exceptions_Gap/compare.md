# Compare — `eMoney_dbo.eMoney_Client_Balance_Check_Exceptions_Gap`

**Bucket**: `median`

**Verdict**: **EQUIVALENT**  (score delta +0.25; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.85 | 9.1 | 0.25 |
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
| business_meaning | 9 | 10 |
| completeness | 10 | 10 |
| data_evidence | 7 | 8 |
| shape_fidelity | 9 | 9 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `2` | 0.478 | 2 | 2 | Aggregate reconciliation gap for the check date. Computed as `SUM(CheckCalc)` from eMoneyClientBalance, where CheckCalc = ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO − ClosingBalanceBO. Non- | Aggregate balance decomposition error: `SUM(eMoneyClientBalance.CheckCalc)` across all accounts for the business date. CheckCalc = ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO - ClosingBalanc |
| `3` | 0.484 | 2 | 2 | The @Date parameter passed to SP_eMoney_Client_Balance_Check_Exceptions_Gap when this check was run. Represents the execution date of the SP, which may differ from Date if the check is run retroactive | Business date parameter (@Date) passed to SP_eMoney_Client_Balance_Check_Exceptions_Gap. Represents the reconciliation date, not a load timestamp. (Tier 2 — SP_eMoney_Client_Balance_Check_Exceptions_G |
| `1` | 0.554 | 2 | 2 | The balance date (BalanceDateID converted to date) for which a reconciliation exception was detected. Derived via `CAST(CONVERT(DATETIME, CONVERT(CHAR(8), BalanceDateID)) AS DATE)` from eMoneyClientBa | Business date for which the balance decomposition exception was detected. Converted from eMoneyClientBalance.BalanceDateID integer (YYYYMMDD) to date via `CAST(CONVERT(DATETIME, CONVERT(CHAR(8), DateI |

## Top issues — regen wiki (per judge)

- [low] `Section 5.2` — ETL step ordering shows TRUNCATE as Step 1, SELECT as Step 2. In the actual SP code, SELECT into #final executes before TRUNCATE. Functionally equivalent due to temp table isolation, but misleading as an execution sequence.
- [low] `Section 7.2` — Drill-down query uses unnecessarily complex date-to-int conversion (CAST(CONVERT(VARCHAR(8), Date, 112) AS INT)) when simpler alternatives exist.
- [info] `Section 3.4` — Could more prominently warn that the TRUNCATE pattern means external monitoring must poll between SP runs or the exception signal is lost at next execution.
