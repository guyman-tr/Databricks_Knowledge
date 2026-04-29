# Compare — `Dealing_dbo.Dealing_CEPWeeklyAudit_CP`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +0.65; slop 2 -> 0 (delta -2))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.05 | 8.7 | 0.65 |
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
| business_meaning | 9 | 10 |
| completeness | 8 | 8 |
| data_evidence | 5 | 9 |
| shape_fidelity | 7 | 8 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `2` | 0.421 | 2 | 2 | **Week end marker** — **Sunday 00:00:00** as derived in the SP (**six** days after **`FromDate`** in the documented logic), **not** **23:59:59**. (Tier 2 — SP_W_CEPWeeklyAudit) | End of the audit week (Sunday 00:00:00). (Tier 2 — SP_W_CEPWeeklyAudit) |
| `11` | 0.427 | 2 | 2 | **Source event timestamp** — **NULL** on **no-change** weeks. (Tier 2 — SP_W_CEPWeeklyAudit) | Event timestamp derived as `CASE WHEN SysEndTime>'3000-01-01' THEN SysStartTime ELSE SysEndTime END` from temporal source columns. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `12` | 0.427 | 4 | 4 | **DWH insert time** via **`GETDATE()`** — **ETL metadata**. [UNVERIFIED] (Tier 4 — inferred) | Row load time: `GETDATE()` at SP execution — DWH metadata, not business event time. (Tier 4 — SP_W_CEPWeeklyAudit) |
| `6` | 0.486 | 2 | 2 | **CP display name** — weekly column name (**`CPName`**) differs from **daily** **`CP_Name`**. (Tier 2 — SP_W_CEPWeeklyAudit) | CP display name at the time of the change event. For name-change rows, this is the **new** name; the previous name appears in `Comments`. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `3` | 0.523 | 2 | 2 | **Rule** associated with the CP context when resolved; **NULL** on **no-change** placeholders or when not resolved. (Tier 2 — SP_W_CEPWeeklyAudit) | CEP Rule associated with the CP via `#Dim_CPtoRule` dimension join; NULL when the CP has no active rule mapping at snapshot time. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `9` | 0.548 | 2 | 2 | **`Previous Name: …`** text for **`Name Change`**; otherwise **NULL**. (Tier 2 — SP_W_CEPWeeklyAudit) | Previous-value context: `Previous Name: {old_name}` for name changes; NULL for new CP, deleted CP, and placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `4` | 0.558 | 2 | 2 | **Denormalized rule name** for the **`RuleID`** context. (Tier 2 — SP_W_CEPWeeklyAudit) | Human-readable rule name denormalized from the latest rule snapshot (`RN_Desc=1` in `#RulesLog`). (Tier 2 — SP_W_CEPWeeklyAudit) |
| `10` | 0.582 | 2 | 2 | **CEP application login** for the change — **NULL** on **no-change** weeks. (Tier 2 — SP_W_CEPWeeklyAudit) | CEP application user (`AppLoginName`) for the change. NULL for ~72% of rows — deletions and certain history paths do not carry login attribution. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `7` | 0.593 | 2 | 2 | **Hedge server** of the parent rule context when present. (Tier 2 — SP_W_CEPWeeklyAudit) | Hedge server / action type identifier from the rule context dimension (`HedgeRuleActionTypeID` lineage via `#Dim_CPtoRule`). (Tier 2 — SP_W_CEPWeeklyAudit) |
| `5` | 0.609 | 2 | 2 | **CP** identifier that changed — **NULL** on **no-change** weeks. (Tier 2 — SP_W_CEPWeeklyAudit) | Compound Property that was created, deleted, or renamed; NULL for no-change placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |

## Top issues — regen wiki (per judge)

- [low] `Section 4 — Tier Legend` — Tier legend only lists Tier 2 and Tier 4. Should include all four tiers as reference rows even when unused, so analysts understand the full classification system.
- [low] `Section 3/4 — Phase Gate` — No explicit Phase Gate Checklist subsection with P2/P3 checkboxes. Data claims are specific enough to imply live queries, but the formal checkpoint is missing.
- [low] `LoginName` — Description presents ~72% NULL rate as definitive, but review-needed sidecar flags it as an open question (expected behavior vs data gap in source system). Wiki should note the uncertainty.
- [low] `HedgeServerID` — Leading description says 'Hedge server / action type identifier' — the dual identity could confuse analysts. The parenthetical clarification (HedgeRuleActionTypeID lineage) helps but the primary label is ambiguous.
- [low] `Section 3.4 — Gotchas` — Does not mention CPName vs CP_Name cross-table naming inconsistency with Dealing_CEPWeeklyAudit_CPToRule, though review-needed sidecar correctly flags it.
