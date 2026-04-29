# Compare — `Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +1.95; slop 2 -> 0 (delta -2))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 6.95 | 8.9 | 1.95 |
| Slop hits (`Tier 4 ... inferred`) | 2 | 0 | -2 |
| Element rows | 9 | 9 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 8 | 8 | +0 |
| T3 count | 0 | 0 | +0 |
| T4 count | 1 | 1 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 10 |
| completeness | 5 | 10 |
| data_evidence | 5 | 7 |
| shape_fidelity | 7 | 8 |
| tier_accuracy | 8 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `7` | 0.434 | 2 | 2 | **CEP application user** performing the change. (Tier 2 — SP_W_CEPWeeklyAudit) | Application login from `AppLoginName` in the source `ListCIDMappings` tables; NULL in ~92% of rows — CID membership changes frequently lack login attribution. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `9` | 0.462 | 4 | 4 | **DWH insert time** via **`GETDATE()`** — not business event time. [UNVERIFIED] (Tier 4 — inferred) | Row load time: `GETDATE()` at SP execution. (Tier 4 — SP_W_CEPWeeklyAudit) |
| `2` | 0.473 | 2 | 2 | **Sunday** — end of the weekly audit window. (Tier 2 — SP_W_CEPWeeklyAudit) | End of the audit week (Sunday 00:00:00); six days after `FromDate` as computed in the SP, **not** end-of-day 23:59:59. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `8` | 0.502 | 2 | 2 | **Source timestamp** of the list membership event. (Tier 2 — SP_W_CEPWeeklyAudit) | Source event timestamp: `SysStartTime` for `CID Added` events, `SysEndTime` for `CID Deleted` events; NULL on placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `5` | 0.508 | 2 | 2 | **Client identifier** added or removed — **PII**; restrict access and avoid unnecessary export. (Tier 2 — SP_W_CEPWeeklyAudit) | Customer ID that was added to or removed from the Named List; NULL on placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `4` | 0.526 | 2 | 2 | **List display name** at the time of the change. (Tier 2 — SP_W_CEPWeeklyAudit) | Named List display name resolved via JOIN to `#NameLists_Log` on `NamedListID` (latest version); NULL on placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `3` | 0.639 | 2 | 2 | **Named List** identifier whose membership changed. (Tier 2 — SP_W_CEPWeeklyAudit) | CEP Named List identifier from the source `ListCIDMappings` tables; NULL on no-change placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) |
| `1` | 0.707 | 2 | 2 | **Monday** — start of the weekly audit window. (Tier 2 — SP_W_CEPWeeklyAudit) | Start of the audit week (Monday 00:00:00). (Tier 2 — SP_W_CEPWeeklyAudit) |
| `6` | 0.833 | 2 | 2 | **`CID Added`** or **`CID Deleted`**; **NULL** for no-change placeholder rows. (Tier 2 — SP_W_CEPWeeklyAudit) | `CID Added` or `CID Deleted`; NULL for no-change placeholder rows from the LEFT JOIN pattern. (Tier 2 — SP_W_CEPWeeklyAudit) |

## Top issues — regen wiki (per judge)

- [low] `Footer / Phase Gate` — Footer states 'Phases: 12/14' but no Phase Gate Checklist section enumerates which phases were completed or skipped. Cannot verify P2/P3 completion.
- [low] `Section 6.2` — Six sibling tables listed as 'Referenced By' are peer tables loaded by the same SP, not objects that reference this table via FK or JOIN in their own ETL. Relationship type is correctly labeled as 'Sibling' but placement under 'Referenced By' could mislead.
- [low] `NameListID` — Source column is NamedListID (with 'd') but element description does not flag the positional rename. Lineage table catches it but element description omits it.
- [low] `ListName` — Element description references temp table #NameLists_Log rather than the actual production source (External_Etoro_CEP_NamedLists.Name / External_Etoro_History_NamedLists.Name).
- [info] `Section 3.4 Gotchas` — Does not mention that this table's INSERT uses the correct JOIN pattern (unlike the NameLists path's suspected fdtd.ToDate = fdtd.ToDate bug). Review-needed sidecar covers this but the wiki's Gotchas section does not.
