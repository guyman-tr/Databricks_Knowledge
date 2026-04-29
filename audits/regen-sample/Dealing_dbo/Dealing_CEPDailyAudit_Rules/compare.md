# Compare — `Dealing_dbo.Dealing_CEPDailyAudit_Rules`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +1.6; slop 2 -> 0 (delta -2))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.3 | 8.9 | 1.6 |
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
| completeness | 8 | 10 |
| data_evidence | 5 | 7 |
| shape_fidelity | 7 | 8 |
| tier_accuracy | 7 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `7` | 0.122 | 2 | 2 | **Event type** — one of: **`New Rule`**, **`Rule Deleted`**, **`Activated`**, **`Deactivated`**, **`Name Change`**, **`Description Change`**, **`HedgeServerID Change`**, **`Priority Change`**. (Tier 2 | Change event type. Values: `Name Change`, `Description Change`, `Activated`, `Deactivated`, `HedgeServerID Change`, `Priority Change`, `New Rule`, `Rule Deleted`. No NULLs in production data — unlike  |
| `9` | 0.183 | 2 | 2 | **CEP application user** who performed the change (**`COALESCE`** across temporal columns). (Tier 2 — SP_CEPDailyAudit) | Application login of the CEP user who made the change. Uses `COALESCE(AppLoginName, PreviousAppLoginName)` from the temporal history to capture identity even for deletion events. Note: values may cont |
| `5` | 0.393 | 2 | 2 | **Hedge server** associated with the rule (**source column family**: **`HedgeRuleActionTypeID`**) — which backend stack executes the rule. (Tier 2 — SP_CEPDailyAudit) | Hedge server associated with this rule — identifies which hedging server processes the rule. Renamed from source column `HedgeRuleActionTypeID`. For `HedgeServerID Change` events, this is the NEW valu |
| `3` | 0.399 | 2 | 2 | **Rule name** at the time of the event. (Tier 2 — SP_CEPDailyAudit) | Name of the CEP Rule at the time of the change. Mapped from source column `Name` (renamed to `RuleName` in DDL). For `Name Change` events, this is the NEW name; the previous name is in `Comments`. (Ti |
| `8` | 0.45 | 2 | 2 | **Prior-value context** for edits (**Previous Name / Description / HedgeServerID / Priority**); **NULL** for simple lifecycle events where not applicable. (Tier 2 — SP_CEPDailyAudit) | Context for change events: `"Previous Name: {old}"`, `"Previous Description: {old}"`, `"Previous HedgeServerID: {old}"`, `"Previous Priority: {old}"`. NULL for `Activated`, `Deactivated`, `New Rule`,  |
| `11` | 0.46 | 4 | 2 | **DWH insert time** via **`GETDATE()`** in the SP — **not** the business event instant. [UNVERIFIED] (Tier 4 — inferred) | ETL metadata: `GETDATE()` at SP execution time. Not the business change time — use `ChangeTime` for event timing. (Tier 2 — SP_CEPDailyAudit) |
| `2` | 0.611 | 2 | 2 | **CEP Rule** identifier that changed. (Tier 2 — SP_CEPDailyAudit) | Unique identifier of the CEP Rule that changed. From `External_Etoro_CEP_Rules.RuleID`. (Tier 2 — SP_CEPDailyAudit) |
| `10` | 0.624 | 2 | 2 | **Source timestamp** of the event (**`SysStartTime`** vs **`SysEndTime`** per path). (Tier 2 — SP_CEPDailyAudit) | Exact timestamp of the change event. `SysStartTime` for attribute changes, activations, and new rules; `SysEndTime` for `Rule Deleted` events. (Tier 2 — SP_CEPDailyAudit) |
| `6` | 0.656 | 2 | 2 | **Execution priority** — **lower value = higher precedence** (**0** first). On **`Priority Change`**, this is the **new** priority (previous in **`Comments`**). (Tier 2 — SP_CEPDailyAudit) | Rule priority value controlling evaluation order within CEP. For `Priority Change` events, this is the NEW priority; the previous is in `Comments`. (Tier 2 — SP_CEPDailyAudit) |
| `4` | 0.76 | 2 | 2 | **Rule description** at the time of the event; on **`Description Change`**, this is the **new** description (previous text in **`Comments`**). (Tier 2 — SP_CEPDailyAudit) | Description text of the CEP Rule at the time of the change. For `Description Change` events, this is the NEW description; the previous is in `Comments`. (Tier 2 — SP_CEPDailyAudit) |

## Top issues — regen wiki (per judge)

- [low] `Section 8 / Footer` — No formal Phase Gate Checklist section with P2/P3 checkboxes. Data claims appear genuine but lack formal phase-completion markers.
- [low] `Section 2` — IsActive is used for Activated/Deactivated change detection but the current activation state is not stored in this table. Could be noted more explicitly to prevent analyst confusion.
- [low] `Section 6.2` — V_Dealing_CEPDailyAudit_Rules_Last180Days listed as referencing view but existence cannot be verified from the bundle.
- [info] `LoginName` — SP alias chain is confusing (PreviousAppLoginName is actually COALESCE of both) but wiki correctly describes final semantics.
- [info] `Footer` — Footer lacks 'Phases completed' list — minor shape deviation.
