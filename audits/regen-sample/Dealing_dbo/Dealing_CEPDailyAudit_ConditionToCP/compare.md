# Compare — `Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +0.8; slop 2 -> 0 (delta -2))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.7 | 8.5 | 0.8 |
| Slop hits (`Tier 4 ... inferred`) | 2 | 0 | -2 |
| Element rows | 11 | 11 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 10 | 11 | +1 |
| T3 count | 0 | 0 | +0 |
| T4 count | 1 | 0 | -1 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 10 |
| completeness | 10 | 8 |
| data_evidence | 5 | 7 |
| shape_fidelity | 7 | 8 |
| tier_accuracy | 7 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `2` | 0.256 | 2 | 2 | **CEP Rule** whose **CP** gained or lost a condition — from **`#Dim_CPtoRule`** explosion; may repeat across rows for multi-rule CPs. (Tier 2 — SP_CEPDailyAudit) | **CEP Rule** containing the compound property involved in this mapping change — resolved via the **CP-to-Rule dimension chain** in the SP. **NULL** when the CP is not mapped to any rule (~18% of rows) |
| `4` | 0.405 | 2 | 2 | **Hedge server context** for the rule (from CP-to-rule dimension) — ties the event to **which server stack** the rule belongs to. (Tier 2 — SP_CEPDailyAudit) | **Hedge server** associated with the parent rule — identifies which hedging backend stack processes the rule. **NULL** when `RuleID` is NULL. (Tier 2 — SP_CEPDailyAudit) |
| `6` | 0.487 | 2 | 2 | **CP display name** resolved via **`#CPLog`** for analyst-friendly output. (Tier 2 — SP_CEPDailyAudit) | **Name of the Compound Property** at the time of the change — resolved from the latest CP name via `#CPLog`. (Tier 2 — SP_CEPDailyAudit) |
| `5` | 0.521 | 2 | 2 | **CP** that gained or lost the **condition** — the **grouping entity** under the rule. (Tier 2 — SP_CEPDailyAudit) | **Identifier** of the **Compound Property** that the condition was added to or removed from. (Tier 2 — SP_CEPDailyAudit) |
| `9` | 0.534 | 2 | 2 | **CEP application user** making the change (`COALESCE` across temporal columns). (Tier 2 — SP_CEPDailyAudit) | **CEP application user** who performed the mapping change (**`COALESCE(AppLoginName, PreviousAppLoginName)`** from temporal history). **NULL** in ~63% of rows (system-driven operations). (Tier 2 — SP_ |
| `7` | 0.659 | 2 | 2 | **Condition** that was **added** to or **removed** from the CP — join to **conditions audit** for predicate details. (Tier 2 — SP_CEPDailyAudit) | **Identifier** of the **condition** that was added to or removed from the CP. (Tier 2 — SP_CEPDailyAudit) |
| `10` | 0.699 | 2 | 2 | **Exact source timestamp** (`SysStartTime` / `SysEndTime` per add vs remove path). (Tier 2 — SP_CEPDailyAudit) | **Source timestamp** of the mapping event — **`SysStartTime`** for additions, **`SysEndTime`** for removals. (Tier 2 — SP_CEPDailyAudit) |
| `3` | 0.702 | 2 | 2 | **Rule name** denormalized for readability alongside **`RuleID`**. (Tier 2 — SP_CEPDailyAudit) | **Rule name** denormalized from the latest rule state for reporting alongside **`RuleID`**. **NULL** when `RuleID` is NULL. (Tier 2 — SP_CEPDailyAudit) |
| `11` | 0.763 | 4 | 2 | **DWH insert time** via **`GETDATE()`** in the SP — **not** business event time. [UNVERIFIED] (Tier 4 — inferred) | **DWH load timestamp** via **`GETDATE()`** in the SP — **not** the business event time. (Tier 2 — SP_CEPDailyAudit) |
| `1` | 0.777 | 2 | 2 | **Audit business date** for the condition membership event — equals **`@Date`** supplied to **`SP_CEPDailyAudit`**. (Tier 2 — SP_CEPDailyAudit) | **Business date** on which this condition-to-CP mapping change was recorded — equals **`@Date`** passed to **`SP_CEPDailyAudit`**. (Tier 2 — SP_CEPDailyAudit) |

## Top issues — regen wiki (per judge)

- [medium] `Section 6.2` — Lists Dealing_CEPWeeklyAudit_ConditionToCP as a downstream reference with '(if exists)' caveat, but the review-needed sidecar explicitly states this table was not found in the SSDT repo. Speculative relationship is misleading.
- [low] `Footer` — No explicit Phase Gate Checklist (P1/P2/P3 checkboxes) and no 'Phases completed' line in the footer. Data evidence appears real but phase completion is unauditable.
- [low] `HedgeServerID (element 4)` — Description does not mention original source column name HedgeRuleActionTypeID. Sibling wiki (Dealing_CEPDailyAudit_Rules) includes this for traceability.
- [low] `Footer` — Footer lacks 'Phases completed: [P1, P2, P3]' notation expected by golden reference shape.
