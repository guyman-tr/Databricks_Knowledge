# Compare — `DWH_dbo.Dim_ExecutionOperationType`

**Bucket**: `median`

**Verdict**: **EQUIVALENT**  (score delta -0.1; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.25 | 8.15 | -0.1 |
| Slop hits (`Tier 4 ... inferred`) | 0 | 0 | +0 |
| Element rows | 3 | 3 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 3 | 3 | +0 |
| T3 count | 0 | 0 | +0 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 8 | 8 |
| data_evidence | 6 | 6 |
| shape_fidelity | 8 | 7 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `1` | 0.101 | 2 | 2 | Primary key. Integer code identifying the trading execution operation type. Values: 0=OrderForOpen, 1=OrderForOpenInMirror, 2=OrderForClose, 3=OrderForCloseInMirror, 4=CancelDelayedOrderForOpen, 5=Can | Surrogate key identifying the execution operation type. Renamed from `[Id]` in the production source `HistoryCosts.Dictionary.ExecutionOperationType`. Integer sequence 0–24 covering order operations ( |
| `2` | 0.144 | 2 | 2 | Human-readable operation type name. Passthrough from source column with same name. Uses nvarchar(max) in DWH (oversized for these short strings). (Tier 2 - SP_Dictionaries_DL_To_Synapse) | Descriptive label for the execution operation type. Passthrough from `HistoryCosts.Dictionary.ExecutionOperationType`. Values include: OrderForOpen, OrderForOpenInMirror, OrderForClose, OrderForCloseI |
| `3` | 0.286 | 2 | 2 | ETL load timestamp set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. NOT NULL constraint (unlike most other DWH dict tables). Does not reflect production source update time. (Tier 2 - SP_Dicti | ETL load timestamp set to `getdate()` at each SP_Dictionaries_DL_To_Synapse execution. Reflects when the dictionary was last refreshed, not when individual operation types were created. (Tier 2 — SP_D |

## Top issues — regen wiki (per judge)

- [medium] `Section 7.3` — Sample query uses fabricated table name `DWH_dbo.SomeHistoryCostsFact` instead of a real downstream consumer. Analysts copying this query will get an error.
- [low] `Section 1` — No date range mentioned. Even for a static dictionary, should explicitly note 'no temporal dimension' rather than silently omitting.
- [low] `Section 2.1` — Operation type ID-range categorizations (0-11 orders, 12-19 positions, etc.) are inferred from names, not sourced from documentation. Should carry an inference caveat.
- [low] `Footer` — No explicit Phase Gate Checklist section. Footer says 'Phases: 7/14' without specifying which phases were completed vs. skipped.
- [low] `Section 4 Tier Legend` — Tier 1 definition includes parenthetical '(no upstream wiki available for this object)' — either omit the unused tier or keep the legend clean.
