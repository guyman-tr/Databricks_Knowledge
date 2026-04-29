# Dealing_dbo.Dealing_CEPDailyAudit_CPToRule

> 39,440-row daily audit of **Compound Property (CP) to Rule mapping** changes in the CEP hedging rule engine — tracks when CPs are added to, removed from, or have their truth-value toggled on rules, from **2023-12-15** to **2026-03-25**. Written by `SP_CEPDailyAudit` via DELETE+INSERT per business date.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule` + `External_Etoro_History_CompoundPropertyToRule` via `SP_CEPDailyAudit` |
| **Refresh** | Daily (Priority 0 — OpsDB / Service Broker) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

This table records **CP-to-Rule wiring changes** in eToro's **Client Execution Platform (CEP)** hedging rule engine. A **Compound Property (CP)** is a bundle of conditions that, when attached to a **Rule**, determines whether the rule "fires" for a given trade or client context. The **mapping** between CPs and Rules — including the **truth polarity** (`IsTrue`) — is what this table audits.

**CEP hierarchy (conceptual):**

```
Rule
  └── CP-to-Rule mapping  ← audited here (add, remove, truth-value toggle)
        └── Compound Property (CP)
              └── Condition
```

**What each row means:** On business date **`Date`**, a CP was **added to** a rule, **removed from** a rule, or had its **truth-value mapping toggled** (True ↔ Not True). The truth-value controls whether the CP must evaluate to **true** or **false** for the rule to match — toggling it **inverts** the condition logic.

**Why it matters:** CP-to-Rule wiring directly controls **which hedging policies apply** to which client trades. An unexpected addition or removal of a CP from a rule can change trade routing. This audit trail supports **governance**, **post-incident investigation**, and **regulatory replay** with **user attribution** and **timestamps**.

**Scale:** **39,440 rows** from **2023-12-15** through **2026-03-25**. This is the **highest-volume** table in the CEPDailyAudit family — CP-to-Rule rewiring occurs frequently as the Dealing team adjusts hedging policies. Event breakdown: **21,679** `CP Added to Rule`, **17,587** `CP Removed from Rule`, **157** `Mapping Changed from Not True to True`, **17** `Mapping Changed from True to Not True`.

**Load pattern:** `SP_CEPDailyAudit(@Date)` performs **DELETE + INSERT** for the supplied **`@Date`**. Runs on the **daily** OpsDB / Service Broker schedule. SLA: typically **next business day** for date *D*.

**Fan-out behavior:** A single CP can be attached to **multiple rules**. When a CP mapping event occurs, the SP resolves rule context via `#Dim_CPtoRule` (LEFT JOIN), which means the same `CompoundPropertyID` event can produce **multiple rows** — one per rule it is mapped to. This is **expected**, not duplicate data.

---

## 2. Business Logic

### 2.1 CP-to-Rule Mapping Events

**What**: The SP detects three categories of mapping changes by comparing successive temporal versions of `External_Etoro_CEP_CompoundPropertyToRule`.

**Columns Involved**: `TypeOfChange`, `IsTrue`

**Rules**:
- **`CP Added to Rule`** — `SysStartDate = @Date` AND `RN = 1` (first temporal version for that RuleID + CompoundPropertyID pair)
- **`Mapping Changed from Not True to True`** — `SysStartDate = @Date` AND `RN > 1` AND `Value <> PreviousValue` AND `Value = 1`
- **`Mapping Changed from True to Not True`** — same conditions but `Value = 0`
- **`CP Removed from Rule`** — `SysEndDate = @Date` AND `SysEndTime < '9999-01-01'` AND `SysStartTime <> SysEndTime`

### 2.2 Rule Context Resolution

**What**: Rule-level attributes (`RuleName`, `HedgeServerID`) are resolved by joining through `#Dim_CPtoRule`, which links CPs to rules using the latest-state snapshot of `#CPToRule_Log` and `#RulesLog`.

**Columns Involved**: `RuleID`, `RuleName`, `HedgeServerID`

**Rules**:
- `RuleName` comes from `#RulesLog.Name` where `RN_Desc = 1` (latest temporal state of the rule)
- `HedgeServerID` comes from `#RulesLog.HedgeRuleActionTypeID` (same latest-state resolution)
- The LEFT JOIN means a CP event can appear with **NULL** rule context if the CP is not currently attached to any rule in the dimension snapshot

### 2.3 CP Name Resolution

**What**: `CP_Name` is resolved from `#CPLog` (latest CP state by `RN_Desc = 1`), reflecting the CP's name at the time of SP execution.

**Columns Involved**: `CP_Name`, `CompoundPropertyID`

**Rules**:
- Name reflects **current** state at SP run time — if the CP was renamed between the event and the SP execution, the name shown is the **post-rename** name

### 2.4 User Attribution

**What**: `LoginName` captures the CEP application user who made the mapping change.

**Columns Involved**: `LoginName`

**Rules**:
- Uses `COALESCE(AppLoginName, PreviousAppLoginName)` from LEAD() over temporal history — ensures deletions still attribute an actor when the current row's login is NULL

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — appropriate for audit tables without a clear hash key. |
| **Clustered index** | **`Date` ASC** — align filters to **`Date`** for index seek. |
| **Scale** | ~39K rows — no special tuning required. Full scans are cheap. |

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What CP-to-Rule changes happened on date X? | `WHERE Date = 'YYYY-MM-DD'` |
| Which rules had CPs removed recently? | `WHERE TypeOfChange = 'CP Removed from Rule' AND Date >= DATEADD(DAY, -30, GETDATE())` |
| Full wiring history for a specific CP? | `WHERE CompoundPropertyID = @id ORDER BY Date, ChangeTime` |
| Truth-value toggles (rare but impactful)? | `WHERE TypeOfChange LIKE 'Mapping Changed%'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `Dealing_CEPDailyAudit_CP` | `CompoundPropertyID + Date` | Correlate CP lifecycle (create/delete/rename) with mapping changes on the same day |
| `Dealing_CEPDailyAudit_Rules` | `RuleID + Date` | See rule-level changes (activation, priority, rename) alongside CP wiring changes |
| `Dealing_CEPDailyAudit_ConditionToCP` | `CompoundPropertyID + Date` | Trace condition membership changes for the same CP on the same day |
| `Dealing_CEPDailyAudit_Conditions` | `RuleID + Date` | Full condition-level detail for the affected rule |

### 3.4 Gotchas

- **Fan-out across rules**: The same `CompoundPropertyID` event can produce **multiple rows** if the CP is mapped to multiple rules — this is **expected** behavior from the `#Dim_CPtoRule` LEFT JOIN, not duplicate data.
- **`TypeOfChange` values are exact strings** — match case and spacing in predicates: `'CP Added to Rule'`, `'CP Removed from Rule'`, `'Mapping Changed from Not True to True'`, `'Mapping Changed from True to Not True'`.
- **`IsTrue`** is a **bit** column storing the CP's truth-polarity on the rule — `True` means the CP must evaluate true for the rule to fire; `False` means it must evaluate false.
- **`CP_Name`** reflects the **latest** name at SP execution time — may differ from the name at the time of the original mapping event if the CP was renamed between the event and the next daily audit run.
- **`LoginName`** may contain trailing NULL bytes in the source data — applications should RTRIM or handle accordingly.
- Prefer **`ChangeTime`** / **`Date`** for **business timelines**; avoid treating **`UpdateDate`** as the event clock.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Business date** on which this CP-to-Rule mapping change was recorded — equals **`@Date`** passed to **`SP_CEPDailyAudit`**. (Tier 2 — SP_CEPDailyAudit) |
| 2 | RuleID | int | YES | **CEP Rule** whose CP mapping changed — from **`External_Etoro_CEP_CompoundPropertyToRule.RuleID`** via **`#CPToRule_Log`**. Can appear multiple times per CP event due to rule fan-out. (Tier 2 — SP_CEPDailyAudit) |
| 3 | RuleName | varchar(max) | YES | **Rule name** at the time of the SP run — resolved via **`#Dim_CPtoRule`** from the latest temporal state of **`#RulesLog`** (`RN_Desc = 1`). NULL if rule context could not be resolved. (Tier 2 — SP_CEPDailyAudit) |
| 4 | HedgeServerID | int | YES | **Hedge server** associated with the rule — identifies which backend hedging stack processes the rule. Resolved from **`HedgeRuleActionTypeID`** via **`#Dim_CPtoRule`**. (Tier 2 — SP_CEPDailyAudit) |
| 5 | CompoundPropertyID | int | YES | **Compound Property** that was added to, removed from, or toggled on the rule. (Tier 2 — SP_CEPDailyAudit) |
| 6 | CP_Name | varchar(max) | YES | **CP display name** resolved via **`#CPLog`** (latest state by `RN_Desc = 1`) — human-readable label for `CompoundPropertyID`. (Tier 2 — SP_CEPDailyAudit) |
| 7 | IsTrue | bit | YES | **Truth polarity** of the CP-to-Rule mapping — `True` means the CP must evaluate true for the rule to fire; `False` means it must evaluate false. Source: **`External_Etoro_CEP_CompoundPropertyToRule.Value`**. (Tier 2 — SP_CEPDailyAudit) |
| 8 | TypeOfChange | varchar(max) | YES | **Event type** — one of: **`CP Added to Rule`**, **`CP Removed from Rule`**, **`Mapping Changed from Not True to True`**, **`Mapping Changed from True to Not True`**. Derived from temporal `SysStartDate`/`SysEndDate` vs `@Date` and `Value` vs `PreviousValue` comparisons. (Tier 2 — SP_CEPDailyAudit) |
| 9 | LoginName | varchar(max) | YES | **CEP application user** who made the mapping change — **`COALESCE(AppLoginName, PreviousAppLoginName)`** from the temporal source to ensure attribution even on removal events. (Tier 2 — SP_CEPDailyAudit) |
| 10 | ChangeTime | datetime | YES | **Source timestamp** of the mapping event — **`SysStartTime`** for additions and value changes; **`SysEndTime`** for removals. Not the DWH load time. (Tier 2 — SP_CEPDailyAudit) |
| 11 | UpdateDate | datetime | YES | **DWH insert time** via **`GETDATE()`** in the SP — **ETL metadata**, not the business event instant. (Tier 2 — SP_CEPDailyAudit) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | SP parameter | @Date | Direct assignment |
| RuleID | External_Etoro_CEP_CompoundPropertyToRule | RuleID | Passthrough via #CPToRule_Log |
| RuleName | External_Etoro_CEP_Rules / History_Rules | Name | Latest state via #RulesLog → #Dim_CPtoRule |
| HedgeServerID | External_Etoro_CEP_Rules / History_Rules | HedgeRuleActionTypeID | Latest state via #RulesLog → #Dim_CPtoRule |
| CompoundPropertyID | External_Etoro_CEP_CompoundPropertyToRule | CompoundPropertyID | Passthrough via #CPToRule_Log |
| CP_Name | External_Etoro_CEP_CompoundProperties / History | Name | Latest state via #CPLog (RN_Desc=1) |
| IsTrue | External_Etoro_CEP_CompoundPropertyToRule | Value | Passthrough via #CPToRule_Log |
| TypeOfChange | SP logic | — | Derived: RN/SysStartDate/SysEndDate/Value comparison |
| LoginName | External_Etoro_CEP_CompoundPropertyToRule / History | AppLoginName | COALESCE(AppLoginName, PreviousAppLoginName) |
| ChangeTime | External_Etoro_CEP_CompoundPropertyToRule / History | SysStartTime / SysEndTime | SysStartTime for adds; SysEndTime for removals |
| UpdateDate | SP logic | GETDATE() | ETL metadata |

### 5.2 ETL Pipeline

```
[CEP System — CompoundPropertyToRule temporal table]
    ↓
Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule  (current)
Dealing_staging.External_Etoro_History_CompoundPropertyToRule  (history)
    ↓ JOIN #CPLog (CP names), #Dim_CPtoRule (rule context)
SP_CEPDailyAudit(@Date)
    — RN=1 + SysStartDate=@Date → CP Added to Rule
    — RN>1 + Value≠PreviousValue → Mapping Changed (True ↔ Not True)
    — SysEndDate=@Date → CP Removed from Rule
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_CPToRule  ← DELETE + INSERT for @Date
    (39,440 rows, 2023-12-15 to 2026-03-25)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RuleID | Dealing_CEPDailyAudit_Rules | Parent rule whose CP wiring changed |
| CompoundPropertyID | Dealing_CEPDailyAudit_CP | CP entity whose mapping to a rule changed |
| CompoundPropertyID | Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule | Source CP-to-Rule mapping entity |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_CEPDailyAudit_ConditionToCP | CompoundPropertyID | Condition membership changes reference the same CP |
| Dealing_CEPDailyAudit_Conditions | RuleID | Condition definition changes for the same rule context |
| Dealing_CEPWeeklyAudit_CPToRule | — | Weekly rollup counterpart |

---

## 7. Sample Queries

### 7.1 All CP-to-Rule mapping changes on a business date

```sql
SELECT
      Date
    , RuleID
    , RuleName
    , CompoundPropertyID
    , CP_Name
    , IsTrue
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_CPToRule
WHERE Date = '2026-03-25'
ORDER BY RuleID, CompoundPropertyID, ChangeTime;
```

### 7.2 Truth-value toggles (rare but impactful)

```sql
SELECT
      Date
    , RuleID
    , RuleName
    , CompoundPropertyID
    , CP_Name
    , IsTrue
    , TypeOfChange
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_CPToRule
WHERE TypeOfChange LIKE 'Mapping Changed%'
ORDER BY Date DESC, ChangeTime DESC;
```

### 7.3 Same-day correlation: CP wiring + CP lifecycle changes

```sql
SELECT
      cpr.Date
    , cpr.CompoundPropertyID
    , cpr.CP_Name
    , cpr.TypeOfChange   AS CPToRule_Event
    , cp.TypeOfChange    AS CP_Event
    , cpr.RuleID
    , cpr.RuleName
    , cpr.LoginName
FROM Dealing_dbo.Dealing_CEPDailyAudit_CPToRule AS cpr
LEFT JOIN Dealing_dbo.Dealing_CEPDailyAudit_CP AS cp
       ON cp.CompoundPropertyID = cpr.CompoundPropertyID
      AND cp.Date = cpr.Date
WHERE cpr.Date = '2026-03-25'
ORDER BY cpr.CompoundPropertyID, cpr.RuleID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 8.5/10 (★★★★☆) | Batch: regen-harness attempt 1*
*Tiers: 0 T1, 11 T2, 0 T3, 0 T4 | Elements: 9/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 6/10*
*Object: Dealing_dbo.Dealing_CEPDailyAudit_CPToRule | Type: Table | Production Source: Dealing_staging CEP CompoundPropertyToRule tables*
