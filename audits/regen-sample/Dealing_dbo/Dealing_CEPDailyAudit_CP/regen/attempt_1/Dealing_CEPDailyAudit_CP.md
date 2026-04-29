# Dealing_dbo.Dealing_CEPDailyAudit_CP

> Daily audit of **Compound Property (CP)** definition changes — creation, deletion, and name edits for the mid-level grouping entities in the CEP hedging rule engine. **~1,034 rows** from **2023-12-15** through **2026-04-19**, written by **`SP_CEPDailyAudit`** via daily DELETE + INSERT.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `Dealing_staging.External_Etoro_CEP_CompoundProperties` + `External_Etoro_History_CompoundProperties` via `SP_CEPDailyAudit` |
| **Refresh** | Daily (Priority 0 — OpsDB / Service Broker) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED on `[Date]` ASC |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |
| **PII** | No |

---

## 1. Business Meaning

This table is the **daily change log** for **Compound Properties (CPs)** — the **mid-level** grouping entities in the CEP hedging rule engine. In the CEP hierarchy, a **Rule** contains one or more **CPs** (via CP-to-Rule mappings), and each CP contains one or more **Conditions** (via Condition-to-CP mappings). This table captures **CP-shell changes** only: when a CP is created, when its **name** is edited, and when it is deleted.

**CEP hierarchy (conceptual):**

```
Rule
  └── Compound Property (CP)   ← definition changes audited HERE
        └── Condition
              └── Property + Operator + Value
```

**What each row means:** On business date **`Date`**, a compound property was **created**, **renamed**, or **deleted**. The **`RuleID`** / **`RuleName`** / **`HedgeServerID`** columns provide **rule context** resolved through the CP-to-rule mapping dimension — these can be **NULL** when a CP exists without any active rule attachment.

**Why it matters:** Compound properties group the atomic conditions that determine how trades and positions are routed and hedged. A CP creation, rename, or deletion can signal structural changes to the hedging logic. This audit supports **governance**, **incident investigation**, and **regulatory** questions about what CP configuration looked like on a given date.

**Scale:** **~1,034 rows** from **2023-12-15** through **2026-04-19**. Three event types: **`Compound Property Deleted`** (727 rows — 70%), **`New Compound Property`** (209 — 20%), **`Name Change`** (98 — 10%). **375** distinct rules, **697** distinct CPs, **58** distinct hedge servers, **4** distinct login users in the sampled data.

**Load pattern:** **`Dealing_dbo.SP_CEPDailyAudit(@Date)`** performs **DELETE + INSERT** for the supplied **`@Date`**. Daily OpsDB / Service Broker schedule. **SLA:** typically **next business day** for date *D*.

---

## 2. Business Logic

### 2.1 Change Detection and Event Classification

**What**: The SP detects compound property lifecycle events by comparing successive temporal versions using `LAG()` and row-number logic.

**Columns Involved**: `TypeOfChange`, `Comments`, `ChangeTime`

**Rules**:
- **`New Compound Property`** — `RN=1` (first temporal row) AND `ChangeDate = @Date` AND `DATEDIFF(MINUTE, ValidFrom, ChangeTime) <= 60`. The 60-minute window confirms genuine creation vs historical data.
- **`Name Change`** — `Name <> PreviousName` AND `PreviousName IS NOT NULL` AND `ChangeDate = @Date`. **`Comments`** carries `'Previous Name: {old_name}'`.
- **`Compound Property Deleted`** — `RN_Desc=1` (latest temporal row) AND `CAST(SysEndTime AS DATE) = @Date`. The CP's temporal validity ended on this date.

### 2.2 Rule Context Resolution

**What**: Each CP row is enriched with the rule that owns it, via a LEFT JOIN to the `#Dim_CPtoRule` dimension.

**Columns Involved**: `RuleID`, `RuleName`, `HedgeServerID`

**Rules**:
- **`#Dim_CPtoRule`** is built from `#CPToRule_Log` (latest CP-to-rule mapping, `RN_Desc=1`) joined to `#RulesLog` (latest rule state, `RN_Desc=1`).
- **LEFT JOIN** means a CP with **no active rule mapping** has **NULL** `RuleID`, `RuleName`, and `HedgeServerID` — **314 of 1,034 rows** (30%) exhibit this pattern.
- A single CP mapped to **multiple rules** can produce **multiple rows** for the same CP event — one per rule context.

### 2.3 ChangeTime Semantics

**What**: The SP derives `ChangeTime` differently for active vs deleted CPs.

**Columns Involved**: `ChangeTime`

**Rules**:
- `SysEndTime > '3000-01-01'` (still active) → `ChangeTime = SysStartTime`
- `SysEndTime <= '3000-01-01'` (closed/deleted) → `ChangeTime = SysEndTime`

### 2.4 Login Attribution

**What**: `LoginName` captures the CEP application user who made the change.

**Columns Involved**: `LoginName`

**Rules**:
- Uses `COALESCE(AppLoginName, PreviousAppLoginName)` so deletions still have user attribution when the current row's login is NULL.
- **480 of 1,034 rows** have NULL `LoginName` — system-generated events or temporal rows lacking user attribution.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

| Topic | Detail |
|-------|--------|
| **Distribution** | `ROUND_ROBIN` — appropriate for **~1K rows**. |
| **Clustered index** | **`Date` ASC** — aligns with daily reload and `WHERE Date = @d` filters. |
| **Scale** | Small — routine audit queries need **no special tuning**. |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What CP changes happened on date X? | `WHERE Date = 'YYYY-MM-DD'` |
| History of a specific CP | `WHERE CompoundPropertyID = @cpid ORDER BY Date, ChangeTime` |
| All name changes with before/after context | `WHERE TypeOfChange = 'Name Change'` — check `Comments` for previous name |
| CPs created or deleted in a period | `WHERE TypeOfChange IN ('New Compound Property', 'Compound Property Deleted') AND Date BETWEEN @start AND @end` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `Dealing_CEPDailyAudit_CPToRule` | `CompoundPropertyID + Date` | Correlate CP definition changes with CP-to-rule wiring changes on the same day |
| `Dealing_CEPDailyAudit_ConditionToCP` | `CompoundPropertyID + Date` | See condition membership changes under this CP on the same day |
| `Dealing_CEPDailyAudit_Rules` | `RuleID + Date` | See rule-level changes alongside CP changes |
| `Dealing_CEPDailyAudit_Conditions` | `RuleID + Date` | See condition-level changes in the same rule context |

### 3.4 Gotchas

- **NULL rule context is valid** — **30%** of rows have NULL `RuleID`/`RuleName`/`HedgeServerID` because the CP was not mapped to any rule at the time (or the mapping was resolved via LEFT JOIN).
- **Fan-out across rules** — if a CP is mapped to multiple rules, the **same CP event** appears as **multiple rows** (one per rule). Not all duplicates are errors.
- **`TypeOfChange`** values are **exact string literals** — match **case and spacing** in predicates: `'New Compound Property'`, `'Name Change'`, `'Compound Property Deleted'`.
- **`Comments`** is NULL for all event types except **`Name Change`** (which carries `'Previous Name: {old}'`).
- **`LoginName`** may contain trailing null bytes from the source system — handle with `RTRIM` or `LEFT(LoginName, CHARINDEX(CHAR(0), LoginName + CHAR(0)) - 1)` if comparing programmatically.
- Prefer **`ChangeTime`** / **`Date`** for business timelines; avoid treating **`UpdateDate`** as the event clock.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | **Business date** on which this CP change was recorded — equals **`@Date`** passed to **`SP_CEPDailyAudit`**. Clustered index key. (Tier 2 — SP_CEPDailyAudit) |
| 2 | RuleID | int | YES | **CEP Rule** that owns this CP via **`#Dim_CPtoRule`** (LEFT JOIN on `CompoundPropertyID`). **NULL** when the CP has no active rule mapping. (Tier 2 — SP_CEPDailyAudit) |
| 3 | RuleName | varchar(max) | YES | **Rule name** denormalized from latest **`#RulesLog`** state (`RN_Desc=1`) for reporting alongside **`RuleID`**. **NULL** when `RuleID` is NULL. (Tier 2 — SP_CEPDailyAudit) |
| 4 | CompoundPropertyID | int | YES | **Identifier** of the **compound property** that was created, renamed, or deleted. Sourced from **`External_Etoro_*_CompoundProperties`**. (Tier 2 — SP_CEPDailyAudit) |
| 5 | CPName | varchar(max) | YES | **CP display name** at the time of the event. On **`Name Change`**, this is the **new** name (previous name in **`Comments`**). (Tier 2 — SP_CEPDailyAudit) |
| 6 | HedgeServerID | int | YES | **Hedge server** associated with the parent rule (from **`#Dim_CPtoRule`**, originally **`HedgeRuleActionTypeID`** in rules source). **NULL** when `RuleID` is NULL. (Tier 2 — SP_CEPDailyAudit) |
| 7 | TypeOfChange | varchar(max) | YES | **Event type** — one of: **`New Compound Property`**, **`Name Change`**, **`Compound Property Deleted`**. Derived from SP `RN`/`RN_Desc`/`NameChange` logic. (Tier 2 — SP_CEPDailyAudit) |
| 8 | Comments | varchar(max) | YES | **Prior-value context** for edits — `'Previous Name: {old}'` for **`Name Change`** rows; **NULL** for **`New Compound Property`** and **`Compound Property Deleted`** events. (Tier 2 — SP_CEPDailyAudit) |
| 9 | LoginName | varchar(max) | YES | **CEP application user** who performed the change — **`COALESCE(AppLoginName, PreviousAppLoginName)`** from temporal source columns. May contain trailing null bytes from source system. (Tier 2 — SP_CEPDailyAudit) |
| 10 | ChangeTime | datetime | YES | **Source timestamp** of the event — **`SysStartTime`** for active CPs, **`SysEndTime`** for deleted CPs. Use for **business timelines**, not `UpdateDate`. (Tier 2 — SP_CEPDailyAudit) |
| 11 | UpdateDate | datetime | YES | **DWH insert time** via **`GETDATE()`** in the SP — **ETL metadata**, not the business event instant. (Tier 2 — SP_CEPDailyAudit) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | SP parameter | @Date | Direct assignment |
| RuleID | #Dim_CPtoRule (← External_Etoro_*_CompoundPropertyToRule + External_Etoro_*_Rules) | RuleID | LEFT JOIN on CompoundPropertyID |
| RuleName | #Dim_CPtoRule (← External_Etoro_*_Rules) | Name | LEFT JOIN; latest rule state |
| CompoundPropertyID | External_Etoro_*_CompoundProperties | CompoundPropertyID | Passthrough |
| CPName | External_Etoro_*_CompoundProperties | Name | Aliased as CPName |
| HedgeServerID | #Dim_CPtoRule (← External_Etoro_*_Rules) | HedgeRuleActionTypeID | LEFT JOIN; aliased |
| TypeOfChange | SP logic | Derived | RN/RN_Desc/NameChange classification |
| Comments | SP logic | Derived | CONCAT for name changes; NULL otherwise |
| LoginName | External_Etoro_*_CompoundProperties | COALESCE(AppLoginName, PreviousAppLoginName) | Temporal user attribution |
| ChangeTime | External_Etoro_*_CompoundProperties | SysStartTime / SysEndTime | Conditional on active vs deleted |
| UpdateDate | SP runtime | GETDATE() | ETL metadata |

### 5.2 ETL Pipeline

```
[CEP System — CompoundProperties temporal table]
    ↓
Dealing_staging.External_Etoro_CEP_CompoundProperties  (current)
Dealing_staging.External_Etoro_History_CompoundProperties  (history)
    ↓ UNION ALL → #CPLog (LAG for name changes, RN/RN_Desc for lifecycle)
    ↓ → #CPChangesFinal (New CP / Name Change / CP Deleted)
    ↓
    ↓ LEFT JOIN #Dim_CPtoRule (RuleID, RuleName, HedgeServerID)
    ↓   ← built from #CPToRule_Log + #RulesLog
    ↓
SP_CEPDailyAudit(@Date)
    — DELETE + INSERT for @Date
    ↓
Dealing_dbo.Dealing_CEPDailyAudit_CP  (~1,034 rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RuleID | Dealing_dbo.Dealing_CEPDailyAudit_Rules | Parent **rule** entity — same `RuleID` + `Date` for correlated changes |
| CompoundPropertyID | Dealing_staging.External_Etoro_CEP_CompoundProperties | **Source** CP definitions (current state) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_dbo.V_Dealing_CEPDailyAudit_CP_Last180Days | * | **View** — recent 180 days of this table |
| Dealing_dbo.Dealing_CEPDailyAudit_CPToRule | CompoundPropertyID | **CP-to-Rule mapping** changes — same CP entity |
| Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP | CompoundPropertyID | **Condition-to-CP membership** changes under this CP |
| Dealing_dbo.Dealing_CEPWeeklyAudit_CP | CompoundPropertyID | **Weekly rollup** of the same CP change events |

---

## 7. Sample Queries

### 7.1 All CP changes on a business date

```sql
SELECT
      Date
    , RuleID
    , RuleName
    , CompoundPropertyID
    , CPName
    , HedgeServerID
    , TypeOfChange
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_CP
WHERE Date = '2026-04-19'
ORDER BY ChangeTime, CompoundPropertyID;
```

### 7.2 Name changes with before/after context

```sql
SELECT
      Date
    , CompoundPropertyID
    , CPName        AS NewName
    , Comments      AS PreviousNameContext
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_CP
WHERE TypeOfChange = 'Name Change'
  AND Date >= '2026-01-01'
ORDER BY Date DESC, ChangeTime DESC;
```

### 7.3 Single CP timeline across all dates

```sql
SELECT
      Date
    , TypeOfChange
    , CPName
    , RuleID
    , RuleName
    , Comments
    , LoginName
    , ChangeTime
FROM Dealing_dbo.Dealing_CEPDailyAudit_CP
WHERE CompoundPropertyID = @CompoundPropertyID
ORDER BY Date, ChangeTime;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 8.5/10 (★★★★☆) | Batch: regen-harness attempt 1*
*Tiers: 0 T1, 11 T2, 0 T3, 0 T4 | Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 7.0/10*
*Object: Dealing_dbo.Dealing_CEPDailyAudit_CP | Type: Table | Production Source: Dealing_staging CEP CompoundProperties + SP_CEPDailyAudit*
