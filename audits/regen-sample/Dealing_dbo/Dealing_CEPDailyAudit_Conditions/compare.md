# Compare — `Dealing_dbo.Dealing_CEPDailyAudit_Conditions`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +0.85; slop 2 -> 0 (delta -2))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.8 | 8.65 | 0.85 |
| Slop hits (`Tier 4 ... inferred`) | 2 | 0 | -2 |
| Element rows | 13 | 13 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 12 | 13 | +1 |
| T3 count | 0 | 0 | +0 |
| T4 count | 1 | 0 | -1 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 10 | 10 |
| data_evidence | 5 | 6 |
| shape_fidelity | 8 | 8 |
| tier_accuracy | 7 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `6` | 0.298 | 2 | 2 | **Attribute** under test — resolved name from **condition properties** dictionary. (Tier 2 — SP_CEPDailyAudit) | **Condition property name** — the attribute being tested (e.g. `InstrumentID`, `CID`, `CountryID`, `InstrumentType`, `RootHedgeServerID`). Resolved from `External_Etoro_Dictionary_ConditionProperties` |
| `10` | 0.378 | 2 | 2 | **Prior value** context for changes (e.g. previous property/operator/value); **NULL** for create/delete-only rows. (Tier 2 — SP_CEPDailyAudit) | **Prior-value context** for change events: `"Previous Property: {old}"`, `"Previous Operator: {old}"`, `"Previous Value: {old}"`. NULL for `New Condition` and `Condition Deleted`. (Tier 2 — SP_CEPDail |
| `7` | 0.394 | 2 | 2 | **Comparison operator** — resolved name from **condition operators** dictionary. (Tier 2 — SP_CEPDailyAudit) | **Comparison operator** applied to the property (e.g. `Equal`, `NotEqual`, `Contains`, `Greater Equal Than`, `SmallerThan`, `Not Contains`). Resolved from `External_Etoro_Dictionary_ConditionOperators |
| `8` | 0.396 | 2 | 2 | **Threshold or literal** compared against the property — stored as **varchar** for mixed types. (Tier 2 — SP_CEPDailyAudit) | **Comparison value** for the condition predicate — the right-hand side of the `Property Operator Value` expression (e.g. instrument IDs, country codes). (Tier 2 — SP_CEPDailyAudit) |
| `2` | 0.506 | 2 | 2 | **CEP Rule** containing the **compound property** that contains this **condition** (via CP / mapping chain in SP). (Tier 2 — SP_CEPDailyAudit) | **CEP Rule** that ultimately uses this condition (resolved via condition → CP → rule chain in `#Dim_ConditionRule`). NULL if the condition's CP is not mapped to any rule. (Tier 2 — SP_CEPDailyAudit) |
| `12` | 0.557 | 2 | 2 | **Exact source timestamp** of the change event. (Tier 2 — SP_CEPDailyAudit) | **Source timestamp** of the change event — `SysStartTime` for property/operator/value changes and new conditions; `SysEndTime` for deletions. (Tier 2 — SP_CEPDailyAudit) |
| `9` | 0.614 | 2 | 2 | **`Property Change`**, **`Operator Change`**, **`Value Change`**, **`New Condition`**, **`Condition Deleted`**. (Tier 2 — SP_CEPDailyAudit) | **Event type** — one of: **`New Condition`**, **`Condition Deleted`**, **`Property Change`**, **`Operator Change`**, **`Value Change`**. (Tier 2 — SP_CEPDailyAudit) |
| `4` | 0.623 | 2 | 2 | **Hedge server** associated with the parent rule context. (Tier 2 — SP_CEPDailyAudit) | **Hedge server** associated with the rule — identifies which backend stack processes the rule containing this condition. From `#Dim_ConditionRule`. (Tier 2 — SP_CEPDailyAudit) |
| `11` | 0.649 | 2 | 2 | **CEP application user** who made the change (`COALESCE` across temporal columns). (Tier 2 — SP_CEPDailyAudit) | **CEP application user** who performed the change — `COALESCE(AppLoginName, PreviousAppLoginName)` from the temporal history to capture identity even for deletion events. (Tier 2 — SP_CEPDailyAudit) |
| `5` | 0.696 | 2 | 2 | **Identifier** of the **condition** that changed. (Tier 2 — SP_CEPDailyAudit) | **Unique identifier** of the condition that changed. The atomic predicate entity in the CEP hierarchy. (Tier 2 — SP_CEPDailyAudit) |

## Top issues — regen wiki (per judge)

- [low] `UpdateDate (element #13)` — Tagged Tier 2 but all 6 sibling CEPDailyAudit tables tag UpdateDate as Tier 4 — inferred. Cross-family inconsistency. Review-needed sidecar item #3 acknowledges this.
- [low] `Overall structure` — No Phase Gate Checklist section with P2/P3 checkboxes. Data claims (row count, enum values, distinct counts) appear grounded but completion of data profiling phases is unverifiable.
- [low] `Section 2.1 / Section 3.4` — Condition Deleted edge case (multi-version conditions whose SysEndTime closes on @Date but SysStartDate != @Date are not captured) documented only in review-needed sidecar at medium severity. Should be surfaced in Section 3.4 Gotchas for analyst visibility.
- [info] `ChangeTime (element #12)` — For Condition Deleted events, the SP uses SysEndTime as ChangeTime but SysStartDate as ChangeDate/Date filter. Wiki doesn't call out that Date and ChangeTime reference different temporal anchors for deletion rows.
- [info] `Value (element #8)` — varchar(100) holds heterogeneous data (instrument IDs, country codes, numeric thresholds). No note about casting requirements for numeric comparisons.
