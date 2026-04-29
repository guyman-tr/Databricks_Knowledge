# Compare — `Dealing_dbo.Dealing_CEPDailyAudit_CPToRule`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +0.6; slop 2 -> 0 (delta -2))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.0 | 8.6 | 0.6 |
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
| completeness | 8 | 9 |
| data_evidence | 6 | 6 |
| shape_fidelity | 8 | 8 |
| tier_accuracy | 9 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `8` | 0.079 | 2 | 2 | Change event type. Values: `CP Added to Rule`, `CP Removed from Rule`, `Mapping Changed from Not True to True`, `Mapping Changed from True to Not True`. (Tier 2 — SP_CEPDailyAudit) | **Event type** — one of: **`CP Added to Rule`**, **`CP Removed from Rule`**, **`Mapping Changed from Not True to True`**, **`Mapping Changed from True to Not True`**. Derived from temporal `SysStartDa |
| `2` | 0.203 | 2 | 2 | ID of the CEP Rule that the Compound Property was added to or removed from. (Tier 2 — SP_CEPDailyAudit) | **CEP Rule** whose CP mapping changed — from **`External_Etoro_CEP_CompoundPropertyToRule.RuleID`** via **`#CPToRule_Log`**. Can appear multiple times per CP event due to rule fan-out. (Tier 2 — SP_CE |
| `3` | 0.241 | 2 | 2 | Name of the CEP Rule at the time of the change. Denormalized for query convenience. (Tier 2 — SP_CEPDailyAudit) | **Rule name** at the time of the SP run — resolved via **`#Dim_CPtoRule`** from the latest temporal state of **`#RulesLog`** (`RN_Desc = 1`). NULL if rule context could not be resolved. (Tier 2 — SP_C |
| `7` | 0.272 | 2 | 2 | Whether the CP must evaluate as True (1) or Not True (0) within the rule's logic. Controls boolean polarity of the CP clause. (Tier 2 — SP_CEPDailyAudit) | **Truth polarity** of the CP-to-Rule mapping — `True` means the CP must evaluate true for the rule to fire; `False` means it must evaluate false. Source: **`External_Etoro_CEP_CompoundPropertyToRule.V |
| `6` | 0.347 | 2 | 2 | Name of the Compound Property at the time of the change. Note: field named `CP_Name` (with underscore), unlike the CP table's `CPName`. (Tier 2 — SP_CEPDailyAudit) | **CP display name** resolved via **`#CPLog`** (latest state by `RN_Desc = 1`) — human-readable label for `CompoundPropertyID`. (Tier 2 — SP_CEPDailyAudit) |
| `11` | 0.393 | 4 | 2 | ETL metadata: `GETDATE()` at SP execution time. Not the business change time. [UNVERIFIED] (Tier 4 — inferred) | **DWH insert time** via **`GETDATE()`** in the SP — **ETL metadata**, not the business event instant. (Tier 2 — SP_CEPDailyAudit) |
| `9` | 0.644 | 2 | 2 | Application login of the user who made the change. Uses `COALESCE(AppLoginName, PreviousAppLoginName)` to capture identity even for removal events. (Tier 2 — SP_CEPDailyAudit) | **CEP application user** who made the mapping change — **`COALESCE(AppLoginName, PreviousAppLoginName)`** from the temporal source to ensure attribution even on removal events. (Tier 2 — SP_CEPDailyAu |
| `1` | 0.687 | 2 | 2 | Business date on which this CP-to-Rule mapping change occurred. Clustered index key. (Tier 2 — SP_CEPDailyAudit) | **Business date** on which this CP-to-Rule mapping change was recorded — equals **`@Date`** passed to **`SP_CEPDailyAudit`**. (Tier 2 — SP_CEPDailyAudit) |
| `4` | 0.692 | 2 | 2 | Hedge server ID associated with this Rule — identifies which hedging server processes this rule. (Tier 2 — SP_CEPDailyAudit) | **Hedge server** associated with the rule — identifies which backend hedging stack processes the rule. Resolved from **`HedgeRuleActionTypeID`** via **`#Dim_CPtoRule`**. (Tier 2 — SP_CEPDailyAudit) |
| `10` | 0.759 | 2 | 2 | Exact timestamp of the change event (SysStartTime for additions/changes, SysEndTime for removals). (Tier 2 — SP_CEPDailyAudit) | **Source timestamp** of the mapping event — **`SysStartTime`** for additions and value changes; **`SysEndTime`** for removals. Not the DWH load time. (Tier 2 — SP_CEPDailyAudit) |

## Top issues — regen wiki (per judge)

- [medium] `Footer / Structure` — No Phase Gate Checklist section. Data claims (39,440 rows, event breakdowns) cannot be verified as grounded in live queries without P2/P3 confirmation.
- [low] `UpdateDate` — Tagged Tier 2 based on visible GETDATE() in SP code, but all sibling CEPDailyAudit tables tag the identical pattern as Tier 4 — inferred. Creates family-wide inconsistency.
- [low] `IsTrue` — Element description does not clarify that on 'CP Removed from Rule' events, the stored value is the last known truth-polarity before unlinking, not a current state.
- [low] `Section 6.2` — Dealing_CEPWeeklyAudit_CPToRule listed as 'weekly rollup counterpart' but no wiki or DDL for it appears in the bundle. Reference is plausible but unverified.
- [low] `RuleName` — Wiki does not note that RuleName resolution via #RulesLog (RN_Desc=1) can return names of deleted or inactive rules — analyst may assume non-NULL RuleName implies an active rule.
