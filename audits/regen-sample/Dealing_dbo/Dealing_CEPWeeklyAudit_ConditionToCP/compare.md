# Compare — `Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP`

**Bucket**: `slop`

**Verdict**: **EQUIVALENT**  (score delta +0.1; slop 2 -> 0 (delta -2))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.65 | 8.75 | 0.1 |
| Slop hits (`Tier 4 ... inferred`) | 2 | 0 | -2 |
| Element rows | 12 | 12 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 11 | 11 | +0 |
| T3 count | 0 | 0 | +0 |
| T4 count | 1 | 1 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 10 | 10 |
| data_evidence | 6 | 7 |
| shape_fidelity | 8 | 8 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `7` | 0.228 | 2 | 2 | **CP display name** for analyst-friendly output. (Tier 2 — SP_W_CEPWeeklyAudit) | Compound property display name — note `CP_Name` (with underscore) here vs `CPName` (no underscore) in `Dealing_CEPWeeklyAudit_CP`. Resolved from latest CP record in `#CPLog` (`RN_Desc=1`). (Tier 2 — S |
| `3` | 0.273 | 2 | 2 | **CEP Rule** whose CP gained or lost the condition — from weekly CP-to-rule resolution in the SP. (Tier 2 — SP_W_CEPWeeklyAudit) | Parent rule ID resolved via CP→Rule dimension join (`#Dim_CPtoRule`); NULL when the CP has no active rule mapping (~13% of rows). Fan-out: one condition-to-CP event may yield multiple rows for differe |
| `1` | 0.507 | 2 | 2 | **Start of the audit week (Monday)** — lower bound of the weekly window written by **`SP_W_CEPWeeklyAudit`**. (Tier 2 — SP_W_CEPWeeklyAudit) | Week start — Monday 00:00:00 for the audit window. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `2` | 0.511 | 2 | 2 | **End of the audit week (Sunday)** — upper bound of the weekly window. (Tier 2 — SP_W_CEPWeeklyAudit) | Week end marker — Sunday 00:00:00 as derived in the SP (six days after FromDate), not 23:59:59. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `5` | 0.584 | 2 | 2 | **Hedge server** associated with the rule context. (Tier 2 — SP_W_CEPWeeklyAudit) | Hedge server / action type identifier from the parent rule context (`HedgeRuleActionTypeID` lineage via `#Dim_CPtoRule`). (Tier 2 — SP_W_CEPWeeklyAudit) |
| `6` | 0.597 | 2 | 2 | **Compound Property** that gained or lost the **condition**. (Tier 2 — SP_W_CEPWeeklyAudit) | Compound property whose condition membership changed; NULL on no-change placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `11` | 0.617 | 2 | 2 | **Source-system timestamp** of the membership event (add vs remove path per SP). (Tier 2 — SP_W_CEPWeeklyAudit) | Source event timestamp — `SysStartTime` for adds, `SysEndTime` for removes; NULL on placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `12` | 0.621 | 4 | 4 | **Row insert time** in the warehouse via **`GETDATE()`** in the SP — not the business event time. [UNVERIFIED] (Tier 4 — inferred) | DWH insert time via `GETDATE()` at SP execution — not business event time. (Tier 4 — SP_W_CEPWeeklyAudit) |
| `10` | 0.655 | 2 | 2 | **CEP application user** attributed to the change (temporal / login resolution per SP). (Tier 2 — SP_W_CEPWeeklyAudit) | CEP application user (`AppLoginName` from source) attributed to the membership change. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `8` | 0.669 | 2 | 2 | **Condition** added to or removed from the CP — join to **weekly conditions audit** for predicate detail. (Tier 2 — SP_W_CEPWeeklyAudit) | Condition that was added to or removed from the CP; NULL on no-change placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |

## Top issues — regen wiki (per judge)

- [low] `Footer` — No Phase Gate Checklist or phases-completed marker. Data claims (row counts, distributions) appear credible but lack formal provenance documentation.
- [low] `Section 4 (Tier Legend)` — Tier legend lists only Tier 2 and Tier 4. Including Tier 1/3 as 'not applicable' would be more consistent with the golden reference shape.
- [low] `HedgeServerID` — Description correctly traces HedgeRuleActionTypeID lineage but the term 'action type identifier' alongside 'Hedge server' could confuse analysts. The column name is a legacy misnomer from the SP alias.
- [info] `Section 6.2` — Dealing_CEPDailyAudit_ConditionToCP listed as related object but has no wiki — cross-reference consistency unverifiable.
- [info] `Section 1` — 'History from 2021-09-26 to present' — 'present' is imprecise. Use the concrete max date (2026-04-19) for durability.
