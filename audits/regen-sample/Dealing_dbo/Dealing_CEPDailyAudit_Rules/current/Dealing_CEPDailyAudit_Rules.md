# Dealing_dbo.Dealing_CEPDailyAudit_Rules

> Daily audit of **CEP Rule** definition changes — creates, deletes, activations, renames, priority moves, and hedge-server moves for the top-level hedging policy objects in the Client Execution Platform.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `Dealing_staging.External_Etoro_CEP_Rules` + `External_Etoro_History_Rules` |
| **Refresh** | Daily (Priority 0 — OpsDB / Service Broker) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table is the **daily change log** for **CEP Rules** — the **top-level** entities in the CEP hedging rule engine. Each row records **one rule-level event** on business date **`Date`**: creation, deletion, activation/deactivation, rename, description edit, hedge-server reassignment, or **priority** reordering.

**Rule semantics (conceptual):** A rule has **`RuleName`**, **`Description`**, **`Priority`** (evaluation order — **lower numeric value = higher precedence**, with **0** evaluated first), **`HedgeServerID`** (which hedging backend stack processes the rule), and **`IsActive`**. Rules contain **compound properties (CPs)** and **conditions**; **this table only captures rule-shell changes**, not CP or condition internals (those live in sibling audit tables).

**Why it matters:** Rules **directly govern** how client positions are routed and hedged. Governance, post-incident review, and regulatory questions about **“what hedging policy looked like on date D”** lean on this trail. The table has the **richest `TypeOfChange` vocabulary** in the **CEPDailyAudit** family (**eight** distinct event types, including **Activated** / **Deactivated**).

**Scale (documented sample):** On the order of **~1,003 rows** from **2023-12-13** through **2026-03-09**. **No PII** in the sampled semantics.

**Cadence vs weekly:** **`Dealing_CEPWeeklyAudit_Rules`** holds a **weekly** rollup with history from **Sep 2021**; this **daily** table starts **Dec 2023** and offers **per-day** granularity for investigations after that cutover.

## 2. Business Logic

- **Writer:** `Dealing_dbo.SP_CEPDailyAudit(@Date)` — **DELETE + INSERT** for the target **`Date`** (same pattern as other **CEPDailyAudit** tables).
- **Sources:** Current rules from **`External_Etoro_CEP_Rules`** and temporal history from **`External_Etoro_History_Rules`**.
- **Change detection (high level):** **`LAG()`**-style comparisons detect **name**, **description**, **`IsActive`**, **`HedgeServerID`**, and **`Priority`** changes; **RN / RN_Desc** logic classifies **new rule** and **rule deleted** events (see SP for exact predicates).
- **`TypeOfChange`:** Derived strings such as **`New Rule`**, **`Rule Deleted`**, **`Activated`**, **`Deactivated`**, **`Name Change`**, **`Description Change`**, **`HedgeServerID Change`**, **`Priority Change`** — **exact spelling matters** in filters.
- **`Comments`:** For edits, carries **previous** values (e.g. **Previous Name**, **Previous Priority**) — use for **before/after** reconstructions.
- **`LoginName`:** **`COALESCE(AppLoginName, PreviousAppLoginName)`** so deletions still attribute an actor when the current row’s login is null.
- **`ChangeTime`:** **`SysStartTime`** for most paths; **`SysEndTime`** for deletions — **source event time**, not load time.
- **`UpdateDate`:** **`GETDATE()`** in the SP — **ETL metadata**.

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — appropriate for **low thousands** of rows. |
| **Clustered index** | **`Date` ASC** — align filters to **`Date`** for partition-style mental model and index seek. |
| **Scale** | Small — routine audit queries need **no special tuning**. |

### 3.2 Recommended patterns

- **`WHERE Date = @d`** for **daily** governance review.
- **`WHERE RuleID = @r ORDER BY Date, ChangeTime`** for **full rule timeline** after Dec 2023.
- Join siblings on **`RuleID`** and **`Date`** for **same-day** CP / CP-to-rule / condition context.

### 3.3 Freshness

- **ACTIVE** in documented sample; **max `Date` 2026-03-09**. Expect **next business day** availability for date *D* after the daily batch.

### 3.4 Gotchas

- **Multiple rows per `RuleID` per `Date`** are **valid** if several edits occurred the same calendar day.
- **`Description`** on **`Description Change`** rows holds the **new** text; **old** text is in **`Comments`**.
- **`Priority`** on **`Priority Change`** rows holds the **new** value; **old** is in **`Comments`**.
- Prefer **`ChangeTime`** / **`Date`** for **business timelines**; avoid treating **`UpdateDate`** as the event clock.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Business date** on which this rule change was recorded — equals **`@Date`** passed to **`SP_CEPDailyAudit`**. (Tier 2 — SP_CEPDailyAudit) |
| 2 | RuleID | int | YES | **CEP Rule** identifier that changed. (Tier 2 — SP_CEPDailyAudit) |
| 3 | RuleName | varchar(max) | YES | **Rule name** at the time of the event. (Tier 2 — SP_CEPDailyAudit) |
| 4 | Description | varchar(max) | YES | **Rule description** at the time of the event; on **`Description Change`**, this is the **new** description (previous text in **`Comments`**). (Tier 2 — SP_CEPDailyAudit) |
| 5 | HedgeServerID | int | YES | **Hedge server** associated with the rule (**source column family**: **`HedgeRuleActionTypeID`**) — which backend stack executes the rule. (Tier 2 — SP_CEPDailyAudit) |
| 6 | Priority | int | YES | **Execution priority** — **lower value = higher precedence** (**0** first). On **`Priority Change`**, this is the **new** priority (previous in **`Comments`**). (Tier 2 — SP_CEPDailyAudit) |
| 7 | TypeOfChange | varchar(max) | YES | **Event type** — one of: **`New Rule`**, **`Rule Deleted`**, **`Activated`**, **`Deactivated`**, **`Name Change`**, **`Description Change`**, **`HedgeServerID Change`**, **`Priority Change`**. (Tier 2 — SP_CEPDailyAudit) |
| 8 | Comments | varchar(max) | YES | **Prior-value context** for edits (**Previous Name / Description / HedgeServerID / Priority**); **NULL** for simple lifecycle events where not applicable. (Tier 2 — SP_CEPDailyAudit) |
| 9 | LoginName | varchar(max) | YES | **CEP application user** who performed the change (**`COALESCE`** across temporal columns). (Tier 2 — SP_CEPDailyAudit) |
| 10 | ChangeTime | datetime | YES | **Source timestamp** of the event (**`SysStartTime`** vs **`SysEndTime`** per path). (Tier 2 — SP_CEPDailyAudit) |
| 11 | UpdateDate | datetime | YES | **DWH insert time** via **`GETDATE()`** in the SP — **not** the business event instant. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

ETL flow from lineage artifact:

```
[CEP System — Rules temporal table]
    ↓
Dealing_staging.External_Etoro_CEP_Rules  (current)
Dealing_staging.External_Etoro_History_Rules  (history)
    ↓
SP_CEPDailyAudit(@Date)
    — LAG() detects Name/Description/IsActive/HedgeServerID/Priority changes
    — RN=1 + created within 60 min of ValidFrom → New Rule
    — RN_Desc=1 + SysEndDate=@Date → Rule Deleted
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_Rules  ← DELETE + INSERT for @Date
```

**Column lineage (summary):** `Date` ← `@Date`; identifiers and attributes ← **`External_Etoro_CEP_Rules`**; `TypeOfChange` / `Comments` ← **SP derivation**; `LoginName` ← **`COALESCE(AppLoginName, PreviousAppLoginName)`**; `ChangeTime` ← **`SysStartTime` / `SysEndTime`**; `UpdateDate` ← **`GETDATE()`**.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_CP` | **CP** changes **under** rules documented here — join on **`RuleID`** + **`Date`**. |
| `Dealing_dbo.Dealing_CEPDailyAudit_CPToRule` | **CP-to-rule mapping** changes — same **`Date`** grain. |
| `Dealing_dbo.Dealing_CEPDailyAudit_Conditions` | **Condition** definition changes within CPs under these rules. |
| `Dealing_dbo.V_Dealing_CEPDailyAudit_Rules_Last180Days` | **View** over recent rows (referenced by email-related SPs). |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Rules` | **Weekly** counterpart with **longer history** (from **Sep 2021**). |
| `Dealing_staging.External_Etoro_CEP_Rules` | **Current** rule state **source**. |
| `Dealing_staging.External_Etoro_History_Rules` | **Temporal history** **source**. |

## 7. Sample Queries

**7.1 — All rule events on a business date**

```sql
SELECT
      Date
    , RuleID
    , RuleName
    , TypeOfChange
    , Priority
    , HedgeServerID
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_Rules
WHERE Date = '2026-03-09'
ORDER BY ChangeTime, RuleID;
```

**7.2 — Activation and deactivation events (recent window)**

```sql
SELECT
      Date
    , RuleID
    , RuleName
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_Rules
WHERE TypeOfChange IN ('Activated', 'Deactivated')
  AND Date >= '2026-01-01'
ORDER BY Date DESC, ChangeTime DESC;
```

**7.3 — Single-rule timeline with comment context**

```sql
SELECT
      Date
    , TypeOfChange
    , RuleName
    , Description
    , Priority
    , HedgeServerID
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_Rules
WHERE RuleID = @RuleID
ORDER BY Date, ChangeTime;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 8.5/10 (★★★★☆) | Batch: CEP audit wiki reformat*  
*Tiers: 0 T1, 10 T2, 0 T3, 1 T4 | Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 5.5/10*  
*Object: Dealing_dbo.Dealing_CEPDailyAudit_Rules | Type: Table | Production Source: Dealing_staging CEP Rules + history*
