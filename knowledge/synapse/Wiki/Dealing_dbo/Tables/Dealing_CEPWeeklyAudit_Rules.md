# Dealing_dbo.Dealing_CEPWeeklyAudit_Rules

> Weekly audit of CEP Rule definition and lifecycle changes (top-level hedging policy objects), loaded from Dealing_staging temporal/external sources by `SP_W_CEPWeeklyAudit` each Sunday.

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

This table captures **weekly** audit events for **CEP Rules** — the highest-level configuration objects in the Client Execution Platform hedging model. Each row describes a **change that occurred within the Monday–Sunday window** (`FromDate` / `ToDate`), including creates, deletes, activations, deactivations, and attribute updates (name, description, hedge server, priority).

It is the **long-history** counterpart to `Dealing_CEPDailyAudit_Rules` (daily granularity from approximately December 2023). For **September 2021 through late 2023**, this weekly table is often the **only** Synapse-native audit of rule changes at any granularity.

**Weekly vs daily — LoginName (preserve for review):** The weekly writer uses **`AppLoginName` directly** for `LoginName`. It does **not** apply the `COALESCE(AppLoginName, PreviousAppLoginName)` pattern used in the daily Rules audit. Deletion and certain history rows may therefore show **NULL `LoginName`** more often than the daily table. Treat this as an **expected behavioral difference** unless the procedure is aligned with daily logic.

## 2. Source & ETL

| Aspect | Detail |
|--------|--------|
| **Writer** | `Dealing_dbo.SP_W_CEPWeeklyAudit` |
| **Staging / external** | `Dealing_staging.External_Etoro_CEP_Rules`, `Dealing_staging.External_Etoro_History_Rules` |
| **Week boundaries** | `@weekStart` = Monday, `@weekEnd` = Sunday; changes filtered by `ChangeTime` (and deletion semantics via `SysEndTime` where applicable) |
| **Load pattern** | DELETE + INSERT for the week key |
| **SLA (typical)** | Data available Monday morning after Sunday load |

The procedure applies LAG-style comparisons over temporal history to derive `TypeOfChange` and `Comments` (previous-value context), consistent with the daily audit semantics but at weekly grain.

## 3. Synapse Design & Row Profile

| Metric | Value (as documented) |
|--------|------------------------|
| **Approx. row count** | 1,914 |
| **Date range** | 2021-09-26 → 2026-03-01 |
| **Distribution** | ROUND_ROBIN |
| **Clustered index** | `[FromDate]` ASC |
| **PII** | No |

Volume is moderate; cluster on `FromDate` supports **week-oriented** reporting. Combine with `TypeOfChange` filters for change-only extracts.

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
| 1 | FromDate | datetime | YES | Audit week start (Monday 00:00:00). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 2 | ToDate | datetime | YES | Audit week end (Sunday 00:00:00). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 3 | RuleID | int | YES | CEP Rule identifier; NULL for **no-change** placeholder weeks (LEFT JOIN pattern). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 4 | RuleName | varchar(max) | YES | Rule name at time of change. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 5 | Description | varchar(max) | YES | Rule description; for description-change events, holds the **new** value while prior text may appear in `Comments`. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 6 | HedgeServerID | int | YES | Hedge server / action type identifier carried from source (`HedgeRuleActionTypeID` lineage). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 7 | Priority | int | YES | Execution priority (lower = higher precedence). For priority-change events, holds the **new** value; old value may be in `Comments`. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 8 | TypeOfChange | varchar(max) | YES | Event type: `New Rule`, `Rule Deleted`, `Activated`, `Deactivated`, `Name Change`, `Description Change`, `HedgeServerID Change`, `Priority Change`; NULL for no-change weeks. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 9 | Comments | varchar(max) | YES | Previous-value context (e.g. `CONCAT('Previous X: ', prior_value)`); NULL where not applicable (e.g. simple activate/deactivate/new/delete). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 10 | LoginName | varchar(max) | YES | Application login from `AppLoginName` only — **no** `PreviousAppLoginName` COALESCE fallback in the weekly SP; expect more NULLs than daily audit for some deletes. (Tier 2 — SP_W_CEPWeeklyAudit) |
| 11 | ChangeTime | datetime | YES | Precise event timestamp (`SysStartTime` / `SysEndTime` lineage). (Tier 2 — SP_W_CEPWeeklyAudit) |
| 12 | UpdateDate | datetime | YES | Row load time: `GETDATE()` at SP execution. (Tier 4 — SP_W_CEPWeeklyAudit) |

## 5. Relationships & Related Objects

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_Rules` | Daily counterpart; prefer for **Dec 2023+** when daily grain is required |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CP` | Child **Coverage Profile** changes under rules |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule` | Mapping changes between CPs and Rules |
| `Dealing_staging.External_Etoro_CEP_Rules` | Current-state external source |
| `Dealing_staging.External_Etoro_History_Rules` | Temporal history source |

## 6. Usage & Sample Queries

- Filter **`WHERE TypeOfChange IS NOT NULL`** for dashboards that must exclude weekly **no-change** placeholders.
- When reconciling to **daily** audit, compare `RuleID` + `ChangeTime` + `TypeOfChange` semantics; allow for **NULL `LoginName`** on weekly rows where daily shows a value (COALESCE difference).
- Use this table when the question is **historical governance before daily audit existed** or **week-level** summaries.

**Sample Query 1 — Change events only, recent weeks**

```sql
SELECT FromDate,
       ToDate,
       RuleID,
       RuleName,
       TypeOfChange,
       LoginName,
       ChangeTime
FROM   Dealing_dbo.Dealing_CEPWeeklyAudit_Rules
WHERE  TypeOfChange IS NOT NULL
  AND  FromDate >= DATEADD(WEEK, -8, CAST(GETDATE() AS date))
ORDER BY ChangeTime DESC;
```

**Sample Query 2 — Full detail for one Rule across history**

```sql
SELECT FromDate,
       ToDate,
       RuleID,
       RuleName,
       Description,
       HedgeServerID,
       Priority,
       TypeOfChange,
       Comments,
       LoginName,
       ChangeTime
FROM   Dealing_dbo.Dealing_CEPWeeklyAudit_Rules
WHERE  RuleID = @RuleID
ORDER BY FromDate DESC, ChangeTime DESC;
```

**Sample Query 3 — Count of event types by year**

```sql
SELECT YEAR(FromDate) AS audit_year,
       TypeOfChange,
       COUNT(*) AS cnt
FROM   Dealing_dbo.Dealing_CEPWeeklyAudit_Rules
WHERE  TypeOfChange IS NOT NULL
GROUP BY YEAR(FromDate), TypeOfChange
ORDER BY audit_year DESC, TypeOfChange;
```

## 7. Data Quality & Operational Notes

| Topic | Guidance |
|-------|----------|
| **LoginName gaps** | Weekly SP intentionally omits `PreviousAppLoginName`; do not assume parity with daily `LoginName` population. |
| **No-change rows** | Expect NULL core attributes for weeks with no detected changes — filter them out for event-centric reporting. |
| **Eight change types** | Values align with daily Rules audit (`TypeOfChange` enumeration from SP logic). |
| **Lineage artifact** | See `Dealing_CEPWeeklyAudit_Rules.lineage.md` for column mapping and ETL flow. |

## 8. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Quality score: 8.5 / 10*

*Tier counts: Tier 2 — 11 columns; Tier 4 — 1 column*

*Object: Dealing_dbo.Dealing_CEPWeeklyAudit_Rules — Table*
