# Compare — `Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule`

**Bucket**: `slop`

**Verdict**: **EQUIVALENT**  (score delta +0.0; slop 2 -> 0 (delta -2))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.35 | 8.35 | 0.0 |
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
| completeness | 9 | 8 |
| data_evidence | 6 | 7 |
| shape_fidelity | 7 | 8 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `8` | 0.21 | 2 | 2 | **Polarity** — **1** = must evaluate **true**, **0** = **not true** in rule logic. (Tier 2 — SP_W_CEPWeeklyAudit) | Boolean mapping state from `CompoundPropertyToRule.Value`: True (1) = CP is active in the rule, False (0) = CP is inactive. For `CP Added to Rule` events, reflects the initial mapping state; for toggl |
| `2` | 0.342 | 2 | 2 | **Week end marker** (**Sunday**) paired with **`FromDate`** per SP derivation. (Tier 2 — SP_W_CEPWeeklyAudit) | End of the audit week (Sunday 00:00:00) — computed as `DATEADD(DAY,6,@weekStart)`. Not end-of-day; use as a week boundary marker. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `4` | 0.359 | 2 | 2 | **Human-readable rule name** denormalized onto the event. (Tier 2 — SP_W_CEPWeeklyAudit) | Denormalized rule display name resolved via `#Dim_CPtoRule` from the latest rule state (`#RulesLog` where `RN_Desc=1`); reflects current name, not necessarily the name at event time. (Tier 2 — SP_W_CE |
| `10` | 0.411 | 2 | 2 | **CEP application user** attributed to the change. (Tier 2 — SP_W_CEPWeeklyAudit) | CEP application login (`AppLoginName`) for the mapping change; NULL on placeholder rows and frequently NULL (~54%) on event rows where temporal history lacks attribution. (Tier 2 — SP_W_CEPWeeklyAudit |
| `7` | 0.449 | 2 | 2 | **CP name** — note **`CP_Name`** here vs **`CPName`** in **`Dealing_CEPWeeklyAudit_CP`**. (Tier 2 — SP_W_CEPWeeklyAudit) | CP display name denormalized from the latest CP state (`#CPLog` where `RN_Desc=1`); name may differ from event-time name if the CP was renamed. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `5` | 0.5 | 2 | 2 | **Hedge server** context for the rule (**from dimension join path** in SP). (Tier 2 — SP_W_CEPWeeklyAudit) | Hedge server / action type identifier resolved via `#Dim_CPtoRule` from `HedgeRuleActionTypeID` in the rules temporal source; NULL on placeholders. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `6` | 0.506 | 2 | 2 | **Compound property** participating in the mapping. (Tier 2 — SP_W_CEPWeeklyAudit) | Compound Property that was added to, removed from, or had its mapping toggled on a rule; NULL on no-change placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `11` | 0.533 | 2 | 2 | **Source temporal timestamp** for the mapping event. (Tier 2 — SP_W_CEPWeeklyAudit) | Source event timestamp: `SysStartTime` for add and value-change events, `SysEndTime` for removal events; NULL on placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `1` | 0.541 | 2 | 2 | **Week start** (**Monday 00:00:00**) for the audit bucket. (Tier 2 — SP_W_CEPWeeklyAudit) | Start of the audit week (Monday 00:00:00) — computed as `DATEADD(DAY,1,DATEADD(WW,-1,@dd))` in the SP. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `12` | 0.556 | 4 | 4 | **`GETDATE()`** at SP run — **load metadata**, not business time. [UNVERIFIED] (Tier 4 — inferred) | Row insert time in the warehouse via `GETDATE()` at SP execution — ETL metadata, not business event time. (Tier 4 — SP_W_CEPWeeklyAudit) |

## Top issues — regen wiki (per judge)

- [medium] `Section 4 — Tier Legend` — Only Tier 2 and Tier 4 listed in the confidence tier legend. The standard four-tier legend (T1–T4) should be present even when tiers are unused, to orient readers.
- [medium] `Footer / missing section` — No explicit Phase Gate Checklist section. Data claims appear backed by live queries (specific counts, percentages) but the formal P1/P2/P3 checkboxes are absent.
- [low] `LoginName (Section 3.4 Gotchas)` — Review-needed sidecar documents null-byte padding in LoginName values (e.g. 'jasonha\0\0\0...') requiring RTRIM/strip, but this is omitted from the wiki Gotchas section.
- [low] `Section 6.2 header` — Header says 'Referenced By (other objects point to this)' but lists sibling/counterpart tables that do not actually reference this table. Should be 'Related Objects' or 'Sibling Tables'.
- [low] `RuleName (#4), HedgeServerID (#5)` — Element descriptions note the dimension join but do not explicitly warn that RuleName/HedgeServerID may refer to a different rule than RuleID when a CP is mapped to multiple rules. The JOIN is on CompoundPropertyID, not RuleID.
