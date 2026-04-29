# Compare — `Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +1.0; slop 2 -> 0 (delta -2))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.75 | 8.75 | 1.0 |
| Slop hits (`Tier 4 ... inferred`) | 2 | 0 | -2 |
| Element rows | 14 | 14 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 13 | 13 | +0 |
| T3 count | 0 | 0 | +0 |
| T4 count | 1 | 1 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 8 | 9 |
| completeness | 8 | 10 |
| data_evidence | 6 | 7 |
| shape_fidelity | 7 | 8 |
| tier_accuracy | 9 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `3` | 0.2 | 2 | 2 | **Parent rule** ID resolved via weekly **ConditionToCP → CPToRule** style chain. (Tier 2 — SP_W_CEPWeeklyAudit) | CEP Rule associated with this condition via the Condition → ConditionToCP → CPToRule resolution chain; **NULL** on placeholder rows or when the condition's CP/rule association could not be resolved. ( |
| `9` | 0.294 | 2 | 2 | **Threshold or target literal** for the predicate. (Tier 2 — SP_W_CEPWeeklyAudit) | The condition's threshold or match value (e.g. instrument ID `1714`, leverage level). For **Value Change** events, holds the **new** value; the previous value appears in `Comments`. (Tier 2 — SP_W_CEP |
| `12` | 0.434 | 2 | 2 | **CEP application user** for the change. (Tier 2 — SP_W_CEPWeeklyAudit) | CEP application login (`AppLoginName`) from source conditions. May contain trailing null-byte padding in some rows (data quality note). **NULL** on placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `4` | 0.437 | 2 | 2 | **Rule display name**. (Tier 2 — SP_W_CEPWeeklyAudit) | Human-readable rule name denormalized from the rule resolution chain (latest name per `RN_Desc=1`). (Tier 2 — SP_W_CEPWeeklyAudit) |
| `2` | 0.444 | 2 | 2 | **Sunday** — end of the weekly audit window. (Tier 2 — SP_W_CEPWeeklyAudit) | **Week end marker** — Sunday, computed as `DATEADD(DAY,6,@weekStart)`. Stored as 00:00:00, **not** end-of-day 23:59:59. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `6` | 0.462 | 2 | 2 | **Condition** that was created, deleted, or had definition fields changed. (Tier 2 — SP_W_CEPWeeklyAudit) | CEP Condition identifier from source; **NULL** on no-change placeholder weeks (LEFT JOIN pattern). (Tier 2 — SP_W_CEPWeeklyAudit) |
| `13` | 0.511 | 2 | 2 | **Source timestamp** of the condition event. (Tier 2 — SP_W_CEPWeeklyAudit) | Source event timestamp: `SysStartTime` for change events (Property/Operator/Value/New); `SysEndTime` for Condition Deleted events. **NULL** on placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `8` | 0.515 | 2 | 2 | **Comparison operator** — resolved from **`External_Etoro_Dictionary_ConditionOperators`**. (Tier 2 — SP_W_CEPWeeklyAudit) | Comparison operator name (e.g. `NotEqual`, `Equal`, `Contains`, `Greater Equal Than`, `Equal Smaller Than`, `SmallerThan`, `Greater Than`, `Not Contains`). Resolved from `External_Etoro_Dictionary_Con |
| `11` | 0.518 | 2 | 2 | **Previous value** context such as `"Previous Property: …"`, `"Previous Operator: …"`, `"Previous Value: …"` when applicable. (Tier 2 — SP_W_CEPWeeklyAudit) | Previous-value context for attribute changes: `Previous Property: {old}`, `Previous Operator: {old}`, `Previous Value: {old}`; **NULL** for New Condition, Condition Deleted, and placeholder rows. (Tie |
| `7` | 0.519 | 2 | 2 | **Attribute under test** — resolved from **`External_Etoro_Dictionary_ConditionProperties`**. (Tier 2 — SP_W_CEPWeeklyAudit) | Condition property name — the attribute being tested (e.g. `InstrumentID`, `InstrumentType`, `CountryID`, `CID`). Resolved from `External_Etoro_Dictionary_ConditionProperties.Name` via PropertyID join |

## Top issues — regen wiki (per judge)

- [low] `Footer` — Missing explicit phases-completed list (e.g., 'Phases: P1 P2 P3') in footer line. Golden reference shape expects this.
- [low] `Section 4 / general` — No Phase Gate Checklist with P2/P3 checkboxes despite clearly live-data-derived statistics (12,661 rows, distribution counts, NULL rates).
- [low] `Section 4 tier legend` — Tier legend only lists Tier 2 and Tier 4. Including Tier 1 and Tier 3 as N/A entries would match the full golden reference shape.
- [info] `Section 2.2 / ConditionID` — Condition Deleted detection uses RN=1 AND RN_Desc=1, potentially undercounting deletions for multi-record conditions. Wiki correctly flags this — no documentation defect, just a noted SP behavior.
- [info] `LoginName` — Null-byte padding correctly documented with remediation advice. No documentation defect.
