# Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists

> Weekly audit of CEP Named List definition and membership changes, loaded from Dealing_staging temporal/external sources by `SP_W_CEPWeeklyAudit` each Sunday.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal tables |
| **Refresh** | Weekly (Sunday) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[FromDate]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table is the **weekly** change log for **CEP Named Lists** — collections of customer IDs (CIDs) referenced by CEP rule conditions. It records when lists are created, when CID membership changes, and when lists are deleted, scoped to a **Monday–Sunday** audit week (`FromDate` / `ToDate`).

It is the historical sibling of `Dealing_CEPDailyAudit_NameLists` (daily, from approximately December 2023 onward). For **September 2021 through late 2023**, this weekly table may be the only Synapse audit trail for Named List events, subject to the data-quality caveat below.

**Suspected writer defect (preserve for review):** In `Dealing_dbo.SP_W_CEPWeeklyAudit`, the NameLists path around **line 878** uses a **LEFT JOIN** whose second predicate is effectively `fdtd.ToDate = fdtd.ToDate` (self-join) instead of matching `fdtd.ToDate` to the change row’s `ToDate` (e.g. `rcf.ToDate`). That condition is always true and can cause **every week to emit rows** with **NULL change attributes** (placeholder rows) rather than only emitting placeholders when there were genuinely no changes. **Validate before treating this table as authoritative:** compare to daily audit where available, and check whether `TypeOfChange` is ever populated.

## 2. Source & ETL

| Aspect | Detail |
|--------|--------|
| **Writer** | `Dealing_dbo.SP_W_CEPWeeklyAudit` |
| **Staging / external** | `Dealing_staging.External_Etoro_CEP_NamedLists`, `Dealing_staging.External_Etoro_History_NamedLists` |
| **Load pattern** | DELETE + INSERT for the target audit week |
| **Ops context** | Weekly Sunday job (Priority 0 in orchestration metadata where applicable) |

Intermediate logic builds `#NameLists_ChangesFinal` from a week-window filter on temporal history, then inserts into this table. Exact predicates and join keys are documented in the paired `.lineage.md` file (not modified here).

## 3. Synapse Design & Row Profile

| Metric | Value (as documented) |
|--------|------------------------|
| **Approx. row count** | 698 |
| **Date range** | 2021-09-26 → 2026-03-01 |
| **Distribution** | ROUND_ROBIN |
| **Clustered index** | `[FromDate]` |
| **PII** | No |

The table is small; routine reporting and ad hoc filters on `FromDate` / `ToDate` are not expected to stress the pool. Prefer **narrow date filters** for consistency with other audit tables.

## 4. Elements

> **Confidence Tier Legend**
>
> | Tier | Meaning |
> |------|--------|
> | **Tier 1** | Confirmed from declared FK, catalog constraint, or upstream dictionary |
> | **Tier 2** | Inferred from ETL / writer procedure logic (`SP_W_CEPWeeklyAudit`) |
> | **Tier 3** | Operational parameter, runtime constant, or deployment convention |
> | **Tier 4** | ETL metadata (load timestamp, surrogate audit fields) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromDate | datetime | YES | Start of the audit week (Monday). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 2 | ToDate | datetime | YES | End of the audit week (Sunday). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 3 | NameListID | int | YES | Named List identifier from CEP. May be NULL if rows are placeholders from the suspected line-878 JOIN issue. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | Name | varchar(max) | YES | Named List display name. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | TypeOfChange | varchar(max) | YES | Change category: e.g. `New Name List`, `Change In CIDs`, `Name List Deleted`. May be NULL for placeholder rows or if the JOIN bug prevents propagation. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | LoginName | varchar(max) | YES | Application login associated with the change. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | ChangeTime | datetime | YES | Event time from temporal columns (`SysStartTime` / `SysEndTime` lineage). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | UpdateDate | datetime | YES | Row load time: `GETDATE()` at SP execution. (Tier 4 — SP_W_CEPWeeklyAudit) |

## 5. Relationships & Related Objects

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_NameLists` | Daily counterpart; **preferred** for Named List lifecycle from ~Dec 2023 when non-null change rows exist there |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping` | Per-CID mapping changes for the same weekly job; documented as not sharing the NameLists JOIN defect |
| `Dealing_staging.External_Etoro_CEP_NamedLists` | Current-state external source |
| `Dealing_staging.External_Etoro_History_NamedLists` | Temporal history source |

## 6. Usage & Sample Queries

- Treat `TypeOfChange IS NOT NULL` as the primary filter for **real** change events once data quality is confirmed.
- For governance reporting after daily audit exists, **reconcile** weekly rows against `Dealing_CEPDailyAudit_NameLists` for overlapping periods.
- **Do not** assume completeness of `LoginName` or `TypeOfChange` until the line-878 hypothesis is ruled in or out.

**Sample Query 1 — Weeks with any non-null change type (data-quality probe)**

```sql
SELECT DISTINCT
       FromDate,
       ToDate,
       COUNT(*) AS row_cnt
FROM   Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists
WHERE  TypeOfChange IS NOT NULL
GROUP BY FromDate, ToDate
ORDER BY FromDate DESC;
```

**Sample Query 2 — Latest week raw extract**

```sql
SELECT TOP (500) *
FROM   Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists
WHERE  FromDate = (SELECT MAX(FromDate) FROM Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists)
ORDER BY ChangeTime;
```

**Sample Query 3 — Named List history for one ID (if populated)**

```sql
SELECT FromDate,
       ToDate,
       NameListID,
       Name,
       TypeOfChange,
       LoginName,
       ChangeTime
FROM   Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists
WHERE  NameListID = @NameListID   -- parameter
ORDER BY FromDate DESC, ChangeTime DESC;
```

## 7. Data Quality & Operational Notes

| Topic | Guidance |
|-------|----------|
| **JOIN bug hypothesis** | Re-read `SP_W_CEPWeeklyAudit` near **line 878**; confirm whether `fdtd.ToDate` should join to `rcf.ToDate`. |
| **Placeholder rows** | If `TypeOfChange` is always NULL, the table may contain no usable change facts until the procedure is corrected. |
| **Authority** | Use daily audit where available; use this table for **pre-daily** history with explicit validation. |
| **Lineage artifact** | Column-level flow and the JOIN warning are recorded in `Dealing_CEPWeeklyAudit_NameLists.lineage.md`. |

## 8. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Quality score: 7.5 / 10*

*Tier counts: Tier 2 — 7 columns; Tier 4 — 1 column*

*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists — Table*
