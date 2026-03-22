# Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP

> Daily audit of Condition-to-Compound Property mapping changes in CEP — when atomic rule conditions are added to or removed from a CP’s condition bundle.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal tables |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

## 1. Business Meaning

This table captures **Condition → Compound Property (CP)** membership changes in the **Client Execution Platform (CEP)** hedging rule engine. **Conditions** are the **atomic predicates** (e.g. comparisons on instrument or account attributes) that, when grouped, define what must hold true for a **compound property** to “fire” inside a **rule**.

**CEP hierarchy (conceptual):**

```
Rule
  └── Compound Property (CP)   [linked via CPToRule]
        └── Condition           [linked via ConditionToCP]  ← audited here
              └── Property + Operator + Value (see Conditions audit table)
```

**What each row means:** On business date **`Date`**, a **condition** was **linked to** or **unlinked from** a **CP**. That changes **which atomic tests** participate in the CP’s bundle — and therefore **which client/trade facts** can satisfy the CP under a rule.

**Why it matters:** Unexpected hedging or routing behavior often traces to **“someone added/removed a condition from the CP we thought was stable.”** This audit gives Dealing and Risk a **replayable history** of those edits with **user attribution** and **timestamps**.

**Scale (sampled):** On the order of **~1,219 rows** from **2023-12-12** through **2026-03-09** — **lower churn** than CP-to-Rule mapping (which can rewire CPs across many rules frequently). **No PII.**

**Load pattern:** `SP_CEPDailyAudit` **DELETE + INSERT** per **`@Date`** for this table, same as siblings. **Daily** OpsDB / Service Broker schedule; **SLA** — typically **next business day** availability for date *D*.

## 2. Business Logic

- **Sources:** `Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty` (**current**) and `External_Etoro_History_ConditionToCompoundProperty` (**temporal history**).
- **Add vs remove detection:** If the **start** of the temporal row’s validity lands on **`@Date`**, classify **`Condition Added To CP`**; if the **end** date aligns with **`@Date`**, classify **`Condition Removed from CP`** (see SP for exact `SysStartDate` / `SysEndDate` logic).
- **Rule context (`RuleID`, `RuleName`, `HedgeServerID`):** Resolved by joining through **`#Dim_CPtoRule`** (built from CP-to-rule logs and rules logs). **Important:** If a CP is attached to **multiple rules**, the **same underlying condition membership change** can appear as **multiple rows** — one **per rule context** — mirroring how the dimension explodes for reporting.
- **`CP_Name`:** From **`#CPLog`** “latest state” style resolution — human-readable CP label for the `CompoundPropertyID` on the event.
- **`LoginName`:** `COALESCE(AppLoginName, PreviousAppLoginName)` — **CEP application user**.
- **`ChangeTime`:** **`SysStartTime`** for additions; removals align with **`SysEndTime`** semantics in SP — **source event time**.
- **`UpdateDate`:** **`GETDATE()`** in the SP — **ETL metadata**.

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — fine for small audit tables. |
| **Clustered index** | **`Date` ASC** — matches primary access path. |
| **Scale** | **Low thousands** of rows in sample window — no tuning required for routine queries. |

### 3.2 Recommended patterns

- **`WHERE Date = @d`** for daily investigations.
- Join to **`Dealing_CEPDailyAudit_Conditions`** on **`ConditionID`** (and often **`Date`**) to pull **property/operator/value** semantics for the condition that moved.
- Join to **`Dealing_CEPDailyAudit_CP`** / **`CPToRule`** to place the change in **full rule context**.

### 3.3 Freshness

- **ACTIVE**; sampled **max `Date` 2026-03-09**. Treat as **daily** batch aligned to **`@Date`**.

### 3.4 Gotchas

- **Fan-out across rules** — **not all duplicates are errors**; verify whether multiple rows for one `ConditionID` + `Date` are explained by **multi-rule CP attachment**.
- **`TypeOfChange` values** are **exact strings** from SP: `Condition Added To CP`, `Condition Removed from CP` — case and spacing matter in filters.
- Compare volume to **`Dealing_CEPDailyAudit_CPToRule`** — **lower here** is **expected** if **condition bundles** change less often than **CP-to-rule wiring**.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Audit business date** for the condition membership event — equals **`@Date`** supplied to **`SP_CEPDailyAudit`**. (Tier 2 — SP_CEPDailyAudit) |
| 2 | RuleID | int | YES | **CEP Rule** whose **CP** gained or lost a condition — from **`#Dim_CPtoRule`** explosion; may repeat across rows for multi-rule CPs. (Tier 2 — SP_CEPDailyAudit) |
| 3 | RuleName | varchar(max) | YES | **Rule name** denormalized for readability alongside **`RuleID`**. (Tier 2 — SP_CEPDailyAudit) |
| 4 | HedgeServerID | int | YES | **Hedge server context** for the rule (from CP-to-rule dimension) — ties the event to **which server stack** the rule belongs to. (Tier 2 — SP_CEPDailyAudit) |
| 5 | CompoundPropertyID | int | YES | **CP** that gained or lost the **condition** — the **grouping entity** under the rule. (Tier 2 — SP_CEPDailyAudit) |
| 6 | CP_Name | varchar(max) | YES | **CP display name** resolved via **`#CPLog`** for analyst-friendly output. (Tier 2 — SP_CEPDailyAudit) |
| 7 | ConditionID | int | YES | **Condition** that was **added** to or **removed** from the CP — join to **conditions audit** for predicate details. (Tier 2 — SP_CEPDailyAudit) |
| 8 | TypeOfChange | varchar(max) | YES | **`Condition Added To CP`** or **`Condition Removed from CP`** — encodes membership direction. (Tier 2 — SP_CEPDailyAudit) |
| 9 | LoginName | varchar(max) | YES | **CEP application user** making the change (`COALESCE` across temporal columns). (Tier 2 — SP_CEPDailyAudit) |
| 10 | ChangeTime | datetime | YES | **Exact source timestamp** (`SysStartTime` / `SysEndTime` per add vs remove path). (Tier 2 — SP_CEPDailyAudit) |
| 11 | UpdateDate | datetime | YES | **DWH insert time** via **`GETDATE()`** in the SP — **not** business event time. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

ETL flow from lineage artifact:

```
[CEP System — ConditionToCompoundProperty temporal table]
    ↓
Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty  (current)
Dealing_staging.External_Etoro_History_ConditionToCompoundProperty  (history)
    ↓
SP_CEPDailyAudit(@Date)
    — JOIN to #CPLog for CP names, #Dim_CPtoRule for rule context
    — SysStartDate = @Date → Condition Added; SysEndDate = @Date → Condition Removed
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP  ← DELETE + INSERT for @Date
```

**Column lineage (summary):** `Date` ← `@Date`; `CompoundPropertyID`, `ConditionID`, `LoginName`, `ChangeTime` ← condition-to-CP external / history; `RuleID`, `RuleName`, `HedgeServerID` ← `#Dim_CPtoRule`; `CP_Name` ← `#CPLog`; `TypeOfChange` ← derived from temporal start/end vs `@Date`; `UpdateDate` ← `GETDATE()`.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_CP` | **Parent CP** entity changes — same **`CompoundPropertyID`**, often same **`Date`**. |
| `Dealing_dbo.Dealing_CEPDailyAudit_CPToRule` | **CP-to-rule wiring** — explains **which rules** see the CP whose membership changed. |
| `Dealing_dbo.Dealing_CEPDailyAudit_Conditions` | **Condition definition** audit — **predicate** details for **`ConditionID`**. |
| `Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty` | **Source** — current links. |
| `Dealing_staging.External_Etoro_History_ConditionToCompoundProperty` | **Source** — temporal **history** of links. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP` | **Weekly rollup** of the same event types. |

## 7. Sample Queries

**7.1 — All condition membership changes on a date**

```sql
SELECT
      Date
    , RuleID
    , RuleName
    , CompoundPropertyID
    , CP_Name
    , ConditionID
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP
WHERE Date = '2026-03-09'
ORDER BY RuleID, CompoundPropertyID, ChangeTime;
```

**7.2 — Removed conditions with CP and rule context**

```sql
SELECT
      Date
    , ConditionID
    , CompoundPropertyID
    , CP_Name
    , RuleID
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP
WHERE TypeOfChange = 'Condition Removed from CP'
  AND Date >= '2026-01-01'
ORDER BY Date DESC, ChangeTime DESC;
```

**7.3 — Same-day join: condition removal + CP-to-rule activity**

```sql
SELECT
      c.Date
    , c.ConditionID
    , c.CompoundPropertyID
    , c.TypeOfChange   AS ConditionToCP_Event
    , m.TypeOfChange   AS CPToRule_Event
    , m.RuleID
FROM Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP AS c
LEFT JOIN Dealing_dbo.Dealing_CEPDailyAudit_CPToRule AS m
       ON m.CompoundPropertyID = c.CompoundPropertyID
      AND m.Date = c.Date
WHERE c.Date = '2026-03-09'
ORDER BY c.ConditionID, m.RuleID;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 7.8/10 (★★★★☆) | Batch: 7/8 (redo)*  
*Tiers: 0 T1, 10 T2, 0 T3, 1 T4 | Elements: 8.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 5.5/10*  
*Object: Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP | Type: Table | Production Source: Dealing_staging CEP tables*
