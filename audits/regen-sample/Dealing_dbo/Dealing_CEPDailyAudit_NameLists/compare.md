# Compare — `Dealing_dbo.Dealing_CEPDailyAudit_NameLists`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +1.05; slop 2 -> 0 (delta -2))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.8 | 8.85 | 1.05 |
| Slop hits (`Tier 4 ... inferred`) | 2 | 0 | -2 |
| Element rows | 7 | 7 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 6 | 7 | +1 |
| T3 count | 0 | 0 | +0 |
| T4 count | 1 | 0 | -1 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 10 | 10 |
| data_evidence | 5 | 8 |
| shape_fidelity | 8 | 8 |
| tier_accuracy | 7 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `4` | 0.403 | 2 | 2 | **`New Name List`**, **`Name List Deleted`**, **`Change In CIDs`** — exact SP literals. (Tier 2 — SP_CEPDailyAudit) | **Event type** — one of: **`New Name List`** (list created, `RN=1`), **`Change In CIDs`** (CID membership modified), **`Name List Deleted`** (list removed, `RN_desc=1` + `SysEndDate=@Date`). Current d |
| `2` | 0.416 | 2 | 2 | **Identifier** of the **Named List** that changed. (Tier 2 — SP_CEPDailyAudit) | **Named List identifier** whose lifecycle or membership changed — corresponds to **`NamedListID`** from **`External_Etoro_CEP_NamedLists`**. 22 distinct lists observed. (Tier 2 — SP_CEPDailyAudit) |
| `5` | 0.426 | 2 | 2 | **CEP user** who performed the change (`COALESCE` across temporal columns). (Tier 2 — SP_CEPDailyAudit) | **CEP application user** who performed the change — **`COALESCE(AppLoginName, PreviousAppLoginName)`** from the temporal source via `LEAD()`. **Note:** sampled values contain null-byte padding. (Tier  |
| `3` | 0.462 | 2 | 2 | **Human-readable list name** at the time of resolution in the SP. (Tier 2 — SP_CEPDailyAudit) | **Human-readable list name** at the time of the event — passthrough from **`#NameLists_Log`** (latest temporal state). Examples: **`CopyFunds`**, **`New Abusers List - Stocks`**, **`EU Real Stocks HBC |
| `7` | 0.557 | 4 | 2 | **DWH load timestamp** from **`GETDATE()`** — **not** business time. [UNVERIFIED] (Tier 4 — inferred) | **DWH insert time** via **`GETDATE()`** in the SP — **ETL metadata**, not the business event instant. (Tier 2 — SP_CEPDailyAudit) |
| `6` | 0.635 | 2 | 2 | **Source event timestamp** (`SysStartTime` / `SysEndTime` per path). (Tier 2 — SP_CEPDailyAudit) | **Source timestamp** of the event — **`SysStartTime`** for creation/modification paths; **`SysEndTime`** for deletion paths. Not the ETL load time. (Tier 2 — SP_CEPDailyAudit) |
| `1` | 0.664 | 2 | 2 | **Business date** of the Named List event — **`@Date`** for the SP run. (Tier 2 — SP_CEPDailyAudit) | **Business date** on which this Named List change was recorded — equals **`@Date`** passed to **`SP_CEPDailyAudit`**. Clustered index key. (Tier 2 — SP_CEPDailyAudit) |

## Top issues — regen wiki (per judge)

- [low] `Section 2.1` — End-date path description omits the SysEndTime < '9999-01-01' guard from the SP. Wiki says 'RN_desc=1 + SysEndDate=@Date' but SP also requires SysEndTime < '9999-01-01'.
- [low] `Section 2.1` — Statement 'Both paths can produce rows for the same list on the same date if the list was modified and then deleted' is narrower than reality — both paths produce 'Change In CIDs' for non-deletion changes too, which gotchas section covers better.
- [low] `Footer` — No phases-completed list (P1/P2/P3 checkmarks) in footer — minor shape deviation from golden reference.
- [info] `Gotchas / review-needed` — Review-needed flags potential duplicate rows from UNION of both temporal paths. Wiki covers this in gotchas but frames as expected behavior rather than flagging as potential SP logic issue.
- [info] `LoginName` — Description says COALESCE(AppLoginName, PreviousAppLoginName) which is functionally correct but elides the aliasing chain: LEAD() produces PreviousAppLoginName in #NameLists_Log, COALESCE result is re-aliased as PreviousAppLoginName in #NameLists_ChangesFinal, then inserted as AppLoginName.
