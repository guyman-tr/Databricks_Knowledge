# Compare — `Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +1.1; slop 2 -> 0 (delta -2))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.9 | 9.0 | 1.1 |
| Slop hits (`Tier 4 ... inferred`) | 2 | 0 | -2 |
| Element rows | 8 | 8 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 7 | 8 | +1 |
| T3 count | 0 | 0 | +0 |
| T4 count | 1 | 0 | -1 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 10 |
| completeness | 10 | 10 |
| data_evidence | 6 | 8 |
| shape_fidelity | 8 | 8 |
| tier_accuracy | 7 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `6` | 0.422 | 2 | 2 | **CEP application user** who performed the add/remove. (Tier 2 — SP_CEPDailyAudit) | **CEP application user** who made the change. Uses `COALESCE(AppLoginName, PreviousAppLoginName)` from the temporal history. **NULL or empty** for ~85% of rows (system-driven changes). (Tier 2 — SP_CE |
| `3` | 0.544 | 2 | 2 | **Human-readable list name** (from **`#NameLists_Log`**) for analyst-friendly reporting. (Tier 2 — SP_CEPDailyAudit) | **Human-readable name** of the Named List at the time of the event — resolved via JOIN to `#NameLists_Log` (latest row: `RN_Desc=1`) on `NamedListID`. (Tier 2 — SP_CEPDailyAudit) |
| `7` | 0.557 | 2 | 2 | **Exact source timestamp** of the mapping event. (Tier 2 — SP_CEPDailyAudit) | **Source timestamp** of the membership change — **`SysStartTime`** for `CID Added` events; **`SysEndTime`** for `CID Deleted` events. (Tier 2 — SP_CEPDailyAudit) |
| `4` | 0.572 | 2 | 2 | **Client ID** added or removed — **PII**; join to **customer / account** dimensions only under **governance**. (Tier 2 — SP_CEPDailyAudit) | **Customer identifier** that was added to or removed from the Named List. **PII** — treat as sensitive. (Tier 2 — SP_CEPDailyAudit) |
| `2` | 0.581 | 2 | 2 | **Named List** identifier whose membership changed. (Tier 2 — SP_CEPDailyAudit) | **Identifier** of the **Named List** whose CID membership changed. Corresponds to `NamedListID` in the staging temporal tables. (Tier 2 — SP_CEPDailyAudit) |
| `5` | 0.619 | 2 | 2 | **`CID Added`** or **`CID Deleted`**. (Tier 2 — SP_CEPDailyAudit) | **Event type**: **`CID Added`** (membership began on this date) or **`CID Deleted`** (membership ended on this date). (Tier 2 — SP_CEPDailyAudit) |
| `1` | 0.65 | 2 | 2 | **Business date** of the CID mapping change — **`@Date`** for the SP partition. (Tier 2 — SP_CEPDailyAudit) | **Business date** on which this CID membership change was recorded — equals **`@Date`** passed to **`SP_CEPDailyAudit`**. Clustered index key. (Tier 2 — SP_CEPDailyAudit) |
| `8` | 0.75 | 4 | 2 | **DWH load time** via **`GETDATE()`** — **not** business event time. [UNVERIFIED] (Tier 4 — inferred) | **DWH load timestamp** via **`GETDATE()`** in the SP — **not** the business event time. (Tier 2 — SP_CEPDailyAudit) |

## Top issues — regen wiki (per judge)

- [low] `Footer / Shape` — No formal Phase Gate Checklist section with [x] P2/P3 markers. Data evidence appears authentic but the standardized checklist is absent.
- [low] `Footer` — Footer missing 'Phases completed: P1, P2, P3' line for harness compliance tracking.
