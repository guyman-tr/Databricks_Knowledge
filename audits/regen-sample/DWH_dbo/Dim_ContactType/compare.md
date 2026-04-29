# Compare — `DWH_dbo.Dim_ContactType`

**Bucket**: `dormant`

**Verdict**: **EQUIVALENT**  (score delta +0.4; slop 1 -> 0 (delta -1))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.1 | 8.5 | 0.4 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 0 | -1 |
| Element rows | 6 | 6 | +0 |
| Untagged count | 5 | 0 | -5 |
| T1 count | 0 | 0 | +0 |
| T2 count | 0 | 0 | +0 |
| T3 count | 0 | 6 | +6 |
| T4 count | 1 | 0 | -1 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 8 | 8 |
| completeness | 8 | 10 |
| data_evidence | 5 | 5 |
| shape_fidelity | 9 | 9 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `5` | 0.322 | None | 3 | ETL insert timestamp — would record GETDATE() when row first loaded. Currently NULL (0 rows, no ETL). (Tier 3b — SSDT DDL, SP_Dictionaries pattern) | Timestamp of the initial ETL insert of this row. Standard DWH audit column. NULL handling is unusual — most DWH tables enforce NOT NULL on InsertDate. (Tier 3 — DDL structure, no upstream) |
| `4` | 0.35 | None | 3 | ETL load timestamp — would record GETDATE() on each SP_Dictionaries refresh. Currently NULL (0 rows, no ETL). (Tier 3b — SSDT DDL, SP_Dictionaries pattern) | Timestamp of the last ETL update to this row. Standard DWH audit column. NULL if the row has never been updated after initial insert. (Tier 3 — DDL structure, no upstream) |
| `3` | 0.379 | None | 3 | DWH surrogate key — standard DWH pattern where DWH{X}ID mirrors the source PK. Expected to equal ContactTypeID if loaded by SP_Dictionaries pattern. 0 rows — never populated. (Tier 3b — SSDT DDL DWH d | DWH-assigned surrogate key for the contact type dimension. Follows the standard `DWH{Entity}ID` naming pattern used across DWH dimension tables. (Tier 3 — DDL structure, no upstream) |
| `6` | 0.413 | None | 3 | Active/inactive flag — standard SP_Dictionaries convention (1 = active). Currently NULL (0 rows, no ETL). (Tier 3b — SSDT DDL, SP_Dictionaries pattern) | Active/inactive flag. Expected: 1 = active, 0 = inactive. NULL may indicate uninitialized state. Standard DWH dimension soft-delete pattern. (Tier 3 — DDL structure, no upstream) |
| `1` | 0.462 | None | 3 | Natural key identifying the contact type. 0 rows — values never loaded. Expected to match a production Dictionary.ContactType.ContactTypeID if ETL is ever implemented. (Tier 3b — SSDT DDL, DWH_dbo.Dim | Natural/source key identifying the contact type. Clustered index key. No writer SP or upstream source found to confirm origin. (Tier 3 — DDL structure, no upstream) |
| `2` | 0.571 | 4 | 3 | [UNVERIFIED] Short label for the contact type category (e.g., "Email", "Phone", "Chat"). No data exists to confirm actual values. (Tier 4 — inferred) | Human-readable label for the contact type (e.g., expected values like phone, email, chat). Max 20 characters. No data available to confirm actual values. (Tier 3 — DDL structure, no upstream) |

## Top issues — regen wiki (per judge)

- [low] `Phase Gate Checklist` — No explicit Phase Gate Checklist subsection present. Footer claims 'Phases: 11/14' but reader cannot verify which phases were completed vs. skipped.
- [low] `Section 1` — No date range stated. Should explicitly say 'No date range — table has never been populated' rather than omitting silently.
- [low] `Name` — Description includes speculative examples ('e.g., expected values like phone, email, chat') that are unverifiable for a 0-row table.
- [low] `Section 5.2` — Pipeline diagram uses generic placeholders throughout. Could be simplified to 'No ETL pipeline exists' for a dormant table.
- [low] `Footer` — Quality self-assessment at 5/10 with Logic 3/10 and Lineage 2/10 subscores are honest but the Phase Gate detail that supports them is missing from the body.
