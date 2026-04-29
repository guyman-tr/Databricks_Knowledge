# Compare — `Dealing_dbo.Dealing_CEPDailyAudit_CP`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +1.1; slop 2 -> 0 (delta -2))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.8 | 8.9 | 1.1 |
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
| completeness | 10 | 10 |
| data_evidence | 5 | 7 |
| shape_fidelity | 8 | 8 |
| tier_accuracy | 7 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `11` | 0.393 | 4 | 2 | ETL metadata: `GETDATE()` at SP execution time. Not the business change time. [UNVERIFIED] (Tier 4 — inferred) | **DWH insert time** via **`GETDATE()`** in the SP — **ETL metadata**, not the business event instant. (Tier 2 — SP_CEPDailyAudit) |
| `8` | 0.4 | 2 | 2 | Context for `Name Change` events: `"Previous Name: {oldName}"`. NULL for creation/deletion events and sentinel rows. (Tier 2 — SP_CEPDailyAudit) | **Prior-value context** for edits — `'Previous Name: {old}'` for **`Name Change`** rows; **NULL** for **`New Compound Property`** and **`Compound Property Deleted`** events. (Tier 2 — SP_CEPDailyAudit |
| `2` | 0.439 | 2 | 2 | ID of the CEP Rule this Compound Property is associated with (via CP-to-Rule mapping). NULL if the CP change is not linked to a rule (e.g., standalone CP creation). (Tier 2 — SP_CEPDailyAudit) | **CEP Rule** that owns this CP via **`#Dim_CPtoRule`** (LEFT JOIN on `CompoundPropertyID`). **NULL** when the CP has no active rule mapping. (Tier 2 — SP_CEPDailyAudit) |
| `6` | 0.459 | 2 | 2 | Hedge server associated with this Rule. Identifies which hedging server processes the parent rule. (Tier 2 — SP_CEPDailyAudit) | **Hedge server** associated with the parent rule (from **`#Dim_CPtoRule`**, originally **`HedgeRuleActionTypeID`** in rules source). **NULL** when `RuleID` is NULL. (Tier 2 — SP_CEPDailyAudit) |
| `4` | 0.462 | 2 | 2 | Unique identifier of the Compound Property that changed. NULL on sentinel rows. (Tier 2 — SP_CEPDailyAudit) | **Identifier** of the **compound property** that was created, renamed, or deleted. Sourced from **`External_Etoro_*_CompoundProperties`**. (Tier 2 — SP_CEPDailyAudit) |
| `9` | 0.462 | 2 | 2 | Application login of the user who made the change. Uses `COALESCE(AppLoginName, PreviousAppLoginName)` from the temporal history to capture identity even for deletion events. NULL on sentinel rows. (T | **CEP application user** who performed the change — **`COALESCE(AppLoginName, PreviousAppLoginName)`** from temporal source columns. May contain trailing null bytes from source system. (Tier 2 — SP_CE |
| `5` | 0.477 | 2 | 2 | Name of the Compound Property at the time of the change. (Tier 2 — SP_CEPDailyAudit) | **CP display name** at the time of the event. On **`Name Change`**, this is the **new** name (previous name in **`Comments`**). (Tier 2 — SP_CEPDailyAudit) |
| `3` | 0.507 | 2 | 2 | Name of the associated CEP Rule. Denormalized from the Rule dimension for query convenience. (Tier 2 — SP_CEPDailyAudit) | **Rule name** denormalized from latest **`#RulesLog`** state (`RN_Desc=1`) for reporting alongside **`RuleID`**. **NULL** when `RuleID` is NULL. (Tier 2 — SP_CEPDailyAudit) |
| `10` | 0.601 | 2 | 2 | Exact timestamp of the change event (SysStartTime or SysEndTime from the temporal record). NULL on sentinel rows. (Tier 2 — SP_CEPDailyAudit) | **Source timestamp** of the event — **`SysStartTime`** for active CPs, **`SysEndTime`** for deleted CPs. Use for **business timelines**, not `UpdateDate`. (Tier 2 — SP_CEPDailyAudit) |
| `1` | 0.609 | 2 | 2 | Business date on which this CP change occurred. Clustered index key. NULL on sentinel rows (no changes detected). (Tier 2 — SP_CEPDailyAudit) | **Business date** on which this CP change was recorded — equals **`@Date`** passed to **`SP_CEPDailyAudit`**. Clustered index key. (Tier 2 — SP_CEPDailyAudit) |

## Top issues — regen wiki (per judge)

- [low] `Footer` — No phases-completed list in footer (e.g., 'Phases: P1 ✓, P2 ✓, P3 ✓'). Footer has quality score and tier counts but omits phase attestation.
- [low] `Missing section` — No formal Phase Gate Checklist section with explicit [x] P2 / [x] P3 markers. Data evidence is convincing but lacks the structural attestation the rubric expects.
- [low] `UpdateDate` — Tier 2 assignment is defensible (GETDATE() visible in SP INSERT) but inconsistent with sibling CEPDailyAudit tables that mark UpdateDate as Tier 4. May confuse analysts comparing across the family.
- [info] `Section 6.2` — V_Dealing_CEPDailyAudit_CP_Last180Days listed as referencing view but its wiki is not in the bundle and could not be verified. Plausible from naming convention.
- [info] `Section 3.4` — LoginName trailing-null-bytes gotcha is a valuable operational detail — noting as a strength, not an issue.
