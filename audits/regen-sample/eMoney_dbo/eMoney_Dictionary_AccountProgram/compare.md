# Compare — `eMoney_dbo.eMoney_Dictionary_AccountProgram`

**Bucket**: `random`

**Verdict**: **EQUIVALENT**  (score delta -0.2; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 9.25 | 9.05 | -0.2 |
| Slop hits (`Tier 4 ... inferred`) | 0 | 0 | +0 |
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
| completeness | 10 | 10 |
| data_evidence | 7 | 6 |
| shape_fidelity | 9 | 8 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 9 | 9 |

## Top 10 column changes (by edit distance)

_No element-row text changes detected._

## Top issues — regen wiki (per judge)

- [low] `Footer` — No explicit Phase Gate Checklist with P2/P3 checkboxes. Data evidence claims (3 rows, enum values, 2023-06-12 date) cannot be verified as live-queried vs. copied from upstream wiki.
- [low] `Footer` — Footer uses non-standard quality breakdown format instead of canonical phases-completed list.
- [info] `AccountProgramID, AccountProgram` — Tier 1 descriptions append enum values (0=Unknown, 1=card, 2=iban) not present in upstream Element descriptions, though values come from upstream Section 3. Additive, not lossy.
