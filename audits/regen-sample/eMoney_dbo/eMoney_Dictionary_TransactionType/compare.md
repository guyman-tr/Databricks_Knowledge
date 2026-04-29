# Compare — `eMoney_dbo.eMoney_Dictionary_TransactionType`

**Bucket**: `good`

**Verdict**: **EQUIVALENT**  (score delta -0.2; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.95 | 8.75 | -0.2 |
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
| completeness | 8 | 8 |
| data_evidence | 8 | 7 |
| shape_fidelity | 9 | 8 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 9 | 9 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `3` | 0.856 | 2 | 2 | Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Static since 2023-06-12. (Tier 2 — Generic Pipeline) | Timestamp of last Generic Pipeline ETL load from FiatDwhDB source. Currently static at 2023-06-12 across all 15 rows. (Tier 2 — Generic Pipeline) |

## Top issues — regen wiki (per judge)

- [low] `Footer` — T1 COPY VERIFICATION debug block leaked into wiki output. This is the writer's self-check, not end-user content. Should be removed.
- [low] `Missing section` — No explicit Phase Gate Checklist section with P2/P3 checkboxes. Footer implies 'Phases: 8/11' but the formal checklist is absent.
- [low] `Section 1` — UpdateDate static value (2023-06-12) mentioned only in header summary, not in Section 1 body. Analyst skimming Section 1 could miss this.
- [low] `Section 6.2` — Referenced-By list includes 10 downstream objects but does not clarify which are direct JOINs to this dictionary vs. indirect references via TxTypeID on fact/dim tables. Most SPs reference TxTypeID through eMoney_Fact_Transaction_Status, not this dictionary directly.
- [info] `UC Target` — UC target main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactiontype is unresolved in the bundle. May not exist yet or may use a different naming convention.
