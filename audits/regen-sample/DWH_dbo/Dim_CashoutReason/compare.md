# Compare — `DWH_dbo.Dim_CashoutReason`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +1.8; slop 1 -> 0 (delta -1))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.05 | 8.85 | 1.8 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 0 | -1 |
| Element rows | 3 | 3 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 2 | 2 | +0 |
| T2 count | 1 | 1 | +0 |
| T3 count | 0 | 0 | +0 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 10 | 8 |
| data_evidence | 7 | 7 |
| shape_fidelity | 9 | 9 |
| tier_accuracy | 6 | 10 |
| upstream_fidelity | 3 | 9 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `1` | 0.286 | 1 | 1 | Primary key identifying the withdrawal reason. Values 1-19 in DWH. Stored in Billing.Withdraw and History.WithdrawAction on production. Special routing for IN (12, 14, 15) in Billing.WithdrawToFunding | Primary key identifying the withdrawal reason. Range 1-19. Stored in Billing.Withdraw, History.WithdrawAction. Default 16 (user request) in WithdrawRequestAdd. Special processing for IN (12, 14, 15) i |
| `2` | 0.51 | 1 | 1 | Human-readable withdrawal reason label. E.g., "Requested by User" (most common), "PI Payment", "Foreclose account". Displayed in BackOffice withdrawal screens and used in audit trails. (Tier 1 - upstr | Human-readable reason label. No unique constraint. Displayed in BackOffice withdrawal screens via LEFT JOIN. Used in reports, audit trails, and customer-facing credit history. (Tier 1 -- Dictionary.Ca |
| `3` | 0.686 | 2 | 2 | ETL load timestamp set to GETDATE() on each daily reload. Reflects when SP_Dictionaries_DL_To_Synapse last ran - NOT when the reason was added or changed in production. (Tier 2 - SP_Dictionaries_DL_To | ETL run timestamp set to GETDATE() on each daily TRUNCATE+INSERT cycle. Reflects last SP_Dictionaries_DL_To_Synapse execution, not production modification time. (Tier 2 -- SP_Dictionaries_DL_To_Synaps |

## Top issues — regen wiki (per judge)

- [low] `Section 1` — No date range mentioned. Static 19-row enum has no temporal dimension, but writer should explicitly state this rather than omit.
- [low] `Footer` — No explicit Phase Gate Checklist (P2/P3 markers). Writer self-scored quality but did not indicate which validation phases were completed vs. skipped.
- [low] `Section 6.2` — Referenced By lists production-side objects (Billing.Withdraw, History.WithdrawAction) without confirming DWH-side equivalents. Review-needed sidecar correctly flags Fact_BillingWithdraw as unverified.
- [trivial] `CashoutReasonID` — Inline values list uses bare names only. Upstream Data Overview (Section 3) had richer per-value business descriptions that were not carried into the DWH wiki element description.
- [trivial] `Section 2` — Business logic references production-side procedures (Billing.WithdrawToFundingProcess) without noting whether DWH-side equivalents exist.
