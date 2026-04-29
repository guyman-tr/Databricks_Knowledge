# Dealing_dbo.Dealing_CEPDailyAudit_Conditions

> Daily audit of **CEP Condition** definition changes — property, operator, and threshold **value** edits, plus condition creation and deletion, in the Client Execution Platform hedging rule engine.

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
| **PII** | No |

## 1. Business Meaning

This table tracks **condition definition changes** in the **CEP (Client Execution Platform)** hedging rule engine. A **condition** is the atomic unit of rule logic: a **`Property OPERATOR Value`** expression that evaluates client trade or position attributes.

**What each row means:** On business date **`Date`**, a condition’s **property type**, **comparison operator**, or **threshold value** changed — or a condition was **created** or **deleted**. Use this table to answer: *“What exactly changed in a CEP rule condition on date X?”*

**Condition anatomy (ETL-resolved):**

- **`Property`** — attribute under test (e.g. instrument type, position size). Names come from **`External_Etoro_Dictionary_ConditionProperties`**.
- **`Operator`** — comparison (e.g. equals, greater than). Names from **`External_Etoro_Dictionary_ConditionOperators`**.
- **`Value`** — threshold or target, stored as **`varchar(100)`** to hold numeric, string, or enum-like literals.

**CEP hierarchy (conceptual):**

```
Rule
  └── Compound Property (CP)
        └── Condition   ← definition changes audited here
              └── Property + Operator + Value
```

**Why it matters:** Conditions encode the **business logic** of hedging rules. A **`Value Change`** or **`Operator Change`** can change **which trades** trigger hedging. This audit supports **replay**, **governance**, and **incident analysis** with **user** and **timestamp** attribution.

**Scale (documented sample):** About **3,189 rows** from **2023-12-12** through **2026-03-09**. **Higher churn** than **Condition-to-CP** mapping alone — attribute edits are common.

**Load pattern:** **`Dealing_dbo.SP_CEPDailyAudit`** performs **DELETE + INSERT** for the supplied **`@Date`**. **Daily** refresh (OpsDB / Service Broker **Priority 0**). **SLA:** typically **next business day** for date *D*.

## 2. Business Logic

- **Sources:** **`Dealing_staging.External_Etoro_CEP_Conditions`** (current) and **`External_Etoro_History_Conditions`** (temporal history); dictionary joins to **`External_Etoro_Dictionary_ConditionProperties`** and **`External_Etoro_Dictionary_ConditionOperators`**.
- **Change detection:** **`LAG()`**-style comparisons in the SP detect **property**, **operator**, and **value** transitions; events are classified as **`Property Change`**, **`Operator Change`**, **`Value Change`**, **`New Condition`**, **`Condition Deleted`** (exact strings from SP).
- **`RuleID` / `RuleName` / `HedgeServerID`:** Resolved through the **condition → CP → rule** chain (e.g. **`#Dim_ConditionRule`** style logic in SP) — attribution can be **non-trivial** when wiring spans multiple rules.
- **`Comments`:** For change events, carries the **previous** property, operator, or value (e.g. `"Previous Value: {old}"`); **NULL** for pure create/delete rows.
- **`LoginName`:** **`COALESCE(AppLoginName, PreviousAppLoginName)`** from the temporal source — **CEP application user**.
- **`ChangeTime`:** **`SysStartTime`** (and analogous semantics per SP path) — **source event time**.
- **`UpdateDate`:** **`GETDATE()`** in the SP — **ETL metadata**, not business time.

## 3. Query Advisory

### 3.1 Distribution and indexing

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — appropriate for **small** audit fact tables. |
| **Clustered index** | **`Date` ASC** — aligns with **daily** reload and **`WHERE Date = @d`** filters. |
| **Scale** | **Low thousands** of rows — routine analytics do not require special tuning. |

### 3.2 Recommended patterns

- Filter **`WHERE Date = @d`** for **daily** investigations.
- Filter **`WHERE ConditionID = @cid`** (often with **`Date`**) for **single-condition** timelines.
- Join **`RuleID`** / context to **`Dealing_CEPDailyAudit_CPToRule`** and **`Dealing_CEPDailyAudit_ConditionToCP`** for **full rule wiring**.

### 3.3 Freshness

- **ACTIVE** in documented window; **max `Date` 2026-03-09**. Expect **one batch row set per calendar date** processed by the SP.

### 3.4 Gotchas

- **`TypeOfChange`** values are **fixed literals** — match **case and spacing** in predicates.
- **`Value`** is **varchar** — cast or compare carefully when treating as numeric.
- **`Property`** and **`Operator`** are **human-readable** at load time — not raw IDs in this table.
- Multiple **change types** for the **same `ConditionID`** on the **same `Date`** can occur if several attributes changed.

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Business date** on which this condition change was recorded — equals **`@Date`** for the SP run. (Tier 2 — SP_CEPDailyAudit) |
| 2 | RuleID | int | YES | **CEP Rule** containing the **compound property** that contains this **condition** (via CP / mapping chain in SP). (Tier 2 — SP_CEPDailyAudit) |
| 3 | RuleName | varchar(max) | YES | **Rule name** denormalized for reporting alongside **`RuleID`**. (Tier 2 — SP_CEPDailyAudit) |
| 4 | HedgeServerID | int | YES | **Hedge server** associated with the parent rule context. (Tier 2 — SP_CEPDailyAudit) |
| 5 | ConditionID | int | YES | **Identifier** of the **condition** that changed. (Tier 2 — SP_CEPDailyAudit) |
| 6 | Property | varchar(max) | YES | **Attribute** under test — resolved name from **condition properties** dictionary. (Tier 2 — SP_CEPDailyAudit) |
| 7 | Operator | varchar(max) | YES | **Comparison operator** — resolved name from **condition operators** dictionary. (Tier 2 — SP_CEPDailyAudit) |
| 8 | Value | varchar(100) | YES | **Threshold or literal** compared against the property — stored as **varchar** for mixed types. (Tier 2 — SP_CEPDailyAudit) |
| 9 | TypeOfChange | varchar(max) | YES | **`Property Change`**, **`Operator Change`**, **`Value Change`**, **`New Condition`**, **`Condition Deleted`**. (Tier 2 — SP_CEPDailyAudit) |
| 10 | Comments | varchar(max) | YES | **Prior value** context for changes (e.g. previous property/operator/value); **NULL** for create/delete-only rows. (Tier 2 — SP_CEPDailyAudit) |
| 11 | LoginName | varchar(max) | YES | **CEP application user** who made the change (`COALESCE` across temporal columns). (Tier 2 — SP_CEPDailyAudit) |
| 12 | ChangeTime | datetime | YES | **Exact source timestamp** of the change event. (Tier 2 — SP_CEPDailyAudit) |
| 13 | UpdateDate | datetime | YES | **DWH load timestamp** via **`GETDATE()`** in the SP — **not** the business event time. [UNVERIFIED] (Tier 4 — inferred) |

## 5. Lineage

ETL flow (see **`.lineage.md`** for full column mapping):

```
[CEP System — Conditions temporal table]
    ↓
Dealing_staging.External_Etoro_CEP_Conditions  (current)
Dealing_staging.External_Etoro_History_Conditions  (history)
    ↓ JOIN dictionaries (Property, Operator names)
SP_CEPDailyAudit(@Date)
    — LAG() / comparison logic → change types
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_Conditions  ← DELETE + INSERT for @Date
```

**Column lineage (summary):** `Date` ← `@Date`; `ConditionID`, `Value`, `LoginName`, `ChangeTime` ← condition external / history; `Property`, `Operator` ← dictionary joins; `RuleID`, `RuleName`, `HedgeServerID` ← derived dimension chain; `TypeOfChange`, `Comments` ← SP logic; `UpdateDate` ← `GETDATE()`.

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP` | **Membership** of conditions in **CPs** — pairs with **definition** changes here. |
| `Dealing_dbo.Dealing_CEPDailyAudit_CP` | **Compound property**-level audit — parent entity in the hierarchy. |
| `Dealing_staging.External_Etoro_CEP_Conditions` | **Current** condition rows. |
| `Dealing_staging.External_Etoro_History_Conditions` | **Temporal history** driving diffs. |
| `Dealing_staging.External_Etoro_Dictionary_ConditionProperties` | **Property** name resolution. |
| `Dealing_staging.External_Etoro_Dictionary_ConditionOperators` | **Operator** name resolution. |
| `Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions` | **Weekly rollup** of the same event family. |

## 7. Sample Queries

**7.1 — All condition changes on a business date**

```sql
SELECT
      Date
    , RuleID
    , RuleName
    , ConditionID
    , Property
    , Operator
    , Value
    , TypeOfChange
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_Conditions
WHERE Date = '2026-03-09'
ORDER BY RuleID, ConditionID, ChangeTime;
```

**7.2 — Value changes with previous value in `Comments`**

```sql
SELECT
      Date
    , ConditionID
    , Value
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_Conditions
WHERE TypeOfChange = 'Value Change'
  AND Date >= '2026-01-01'
ORDER BY Date DESC, ChangeTime DESC;
```

**7.3 — New and deleted conditions with rule context**

```sql
SELECT
      Date
    , RuleID
    , RuleName
    , ConditionID
    , TypeOfChange
    , Property
    , Operator
    , Value
    , LoginName
FROM Dealing_dbo.Dealing_CEPDailyAudit_Conditions
WHERE TypeOfChange IN ('New Condition', 'Condition Deleted')
ORDER BY Date DESC, RuleID, ConditionID;
```

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 8.0/10 (★★★★☆) | Batch: manual template reformat*  
*Tiers: 0 T1, 12 T2, 0 T3, 1 T4 | Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 5.5/10*  
*Object: Dealing_dbo.Dealing_CEPDailyAudit_Conditions | Type: Table | Production Source: Dealing_staging CEP temporal tables*
