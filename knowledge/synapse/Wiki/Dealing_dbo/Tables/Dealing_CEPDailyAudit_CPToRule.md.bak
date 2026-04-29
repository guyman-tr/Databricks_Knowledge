# Dealing_dbo.Dealing_CEPDailyAudit_CPToRule

> Daily audit trail of **Compound Property-to-Rule mapping changes** in the CEP hedging rule engine — tracks when CPs are added to, removed from, or have their truth-value toggled within rules.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging CEP temporal tables |
| **Refresh** | Daily (Priority 0 — OpsDB/Service Broker) |
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

This is the **highest-volume** table in the CEPDailyAudit family (~32K rows vs ~300–3K for sibling tables). It records every time a Compound Property is added to a Rule, removed from a Rule, or has its `IsTrue` boolean polarity toggled within a rule's logic.

**Source and lineage**: Data flows from `Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule` (current state) and `External_Etoro_History_CompoundPropertyToRule` (temporal history). The writer SP `SP_CEPDailyAudit` uses `LAG()` window functions to detect state changes, then classifies each event.

**Freshness**: Runs daily. Active pipeline — max date 2026-03-09. 32,274 rows since Dec 2023 — high volume confirms frequent CP-to-Rule reconfiguration activity by the Dealing team.

**Why it matters**: CP-to-Rule mappings define which compound property "clauses" are active in each hedging rule. Changing these mappings directly affects eToro's order routing and hedging behavior. This audit trail supports post-incident investigation, governance oversight, and regulatory compliance.

---

## 2. Business Logic

### 2.1 Change Detection and Event Classification

**What**: The SP detects CP-to-Rule mapping changes by comparing successive system-time versions using `LAG()`.

**Columns Involved**: `TypeOfChange`, `IsTrue`, `ChangeTime`, `LoginName`

**Rules**:
- `CP Added to Rule` — CP newly mapped to a rule
- `CP Removed from Rule` — CP removed from a rule
- `Mapping Changed from Not True to True` — IsTrue flipped 0→1
- `Mapping Changed from True to Not True` — IsTrue flipped 1→0
- `LoginName` uses `COALESCE(AppLoginName, PreviousAppLoginName)` to capture identity even for removal events

### 2.2 IsTrue Polarity

**What**: Controls whether the CP must evaluate as true or false within the rule's logic.

**Columns Involved**: `IsTrue`

**Rules**:
- `IsTrue = 1` — the CP clause must be satisfied (evaluate true) to match the rule
- `IsTrue = 0` — the CP clause must NOT be satisfied — effectively an exclusion clause
- Polarity toggles are tracked as distinct `TypeOfChange` events

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on `Date`. Moderate size (~32K rows). ROUND_ROBIN appropriate for an audit/log table with no natural join key.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What CP-to-Rule changes happened on date X? | `WHERE Date = 'YYYY-MM-DD'` |
| Which CPs were added to a specific rule? | `WHERE RuleID = @id AND TypeOfChange = 'CP Added to Rule'` |
| All IsTrue polarity toggles in a range | `WHERE Date BETWEEN @start AND @end AND TypeOfChange LIKE 'Mapping Changed%'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Dealing_CEPDailyAudit_CP | `CompoundPropertyID + Date` | Correlate CP property changes with mapping changes on the same day |
| Dealing_CEPDailyAudit_Rules | `RuleID + Date` | See rule-level changes alongside mapping changes |

### 3.4 Gotchas

- **Highest volume** of all CEPDailyAudit tables — CP-to-Rule mappings change more frequently than the entities themselves
- A single CP can be mapped to many rules, so one CP change can generate multiple CPToRule rows
- `IsTrue` semantic is counterintuitive: `IsTrue=0` doesn't mean "inactive" — it means "CP must NOT be true" (exclusion logic)
- This is one of 7 CEPDailyAudit tables, all written by the same SP

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code | `(Tier 2 — SP_CEPDailyAudit)` |
| ★ | Tier 4 — inferred | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Business date on which this CP-to-Rule mapping change occurred. Clustered index key. (Tier 2 — SP_CEPDailyAudit) |
| 2 | RuleID | int | YES | ID of the CEP Rule that the Compound Property was added to or removed from. (Tier 2 — SP_CEPDailyAudit) |
| 3 | RuleName | varchar(max) | YES | Name of the CEP Rule at the time of the change. Denormalized for query convenience. (Tier 2 — SP_CEPDailyAudit) |
| 4 | HedgeServerID | int | YES | Hedge server ID associated with this Rule — identifies which hedging server processes this rule. (Tier 2 — SP_CEPDailyAudit) |
| 5 | CompoundPropertyID | int | YES | ID of the Compound Property that was mapped to or removed from the rule. (Tier 2 — SP_CEPDailyAudit) |
| 6 | CP_Name | varchar(max) | YES | Name of the Compound Property at the time of the change. Note: field named `CP_Name` (with underscore), unlike the CP table's `CPName`. (Tier 2 — SP_CEPDailyAudit) |
| 7 | IsTrue | bit | YES | Whether the CP must evaluate as True (1) or Not True (0) within the rule's logic. Controls boolean polarity of the CP clause. (Tier 2 — SP_CEPDailyAudit) |
| 8 | TypeOfChange | varchar(max) | YES | Change event type. Values: `CP Added to Rule`, `CP Removed from Rule`, `Mapping Changed from Not True to True`, `Mapping Changed from True to Not True`. (Tier 2 — SP_CEPDailyAudit) |
| 9 | LoginName | varchar(max) | YES | Application login of the user who made the change. Uses `COALESCE(AppLoginName, PreviousAppLoginName)` to capture identity even for removal events. (Tier 2 — SP_CEPDailyAudit) |
| 10 | ChangeTime | datetime | YES | Exact timestamp of the change event (SysStartTime for additions/changes, SysEndTime for removals). (Tier 2 — SP_CEPDailyAudit) |
| 11 | UpdateDate | datetime | YES | ETL metadata: `GETDATE()` at SP execution time. Not the business change time. [UNVERIFIED] (Tier 4 — inferred) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| All columns | Dealing_staging CEP temporal tables | Various | LAG()-based change detection |

No Generic Pipeline mapping — CEP is an internal eToro system.

### 5.2 ETL Pipeline

```
CEP Internal System
    → Dealing_staging.External_Etoro_CEP_CompoundPropertyToRule (current state)
    → Dealing_staging.External_Etoro_History_CompoundPropertyToRule (temporal history)
        → SP_CEPDailyAudit (LAG() change detection)
            → Dealing_dbo.Dealing_CEPDailyAudit_CPToRule
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RuleID | Dealing_CEPDailyAudit_Rules | Parent rule entity |
| CompoundPropertyID | Dealing_CEPDailyAudit_CP | Parent CP entity whose mapping changed |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_CEPWeeklyAudit_CPToRule | CompoundPropertyID | Weekly rollup of same change events |

---

## 7. Sample Queries

### 7.1 All CP-to-Rule changes on a specific date
```sql
SELECT Date, RuleName, CP_Name, TypeOfChange, IsTrue, LoginName, ChangeTime
FROM   Dealing_dbo.Dealing_CEPDailyAudit_CPToRule
WHERE  Date = '2026-03-01'
ORDER BY ChangeTime;
```

### 7.2 CPs added to a specific rule over time
```sql
SELECT Date, CompoundPropertyID, CP_Name, IsTrue, LoginName
FROM   Dealing_dbo.Dealing_CEPDailyAudit_CPToRule
WHERE  RuleID = 15
  AND  TypeOfChange = 'CP Added to Rule'
ORDER BY Date DESC;
```

### 7.3 All IsTrue polarity toggles in last 90 days
```sql
SELECT Date, RuleName, CP_Name, TypeOfChange, LoginName
FROM   Dealing_dbo.Dealing_CEPDailyAudit_CPToRule
WHERE  Date >= DATEADD(DAY, -90, GETDATE())
  AND  TypeOfChange LIKE 'Mapping Changed%'
ORDER BY Date DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 8.0/10 (★★★★☆) | Batch: 8 (redo)*
*Tiers: 0 T1, 10 T2, 0 T3, 1 T4 | Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10*
*Object: Dealing_dbo.Dealing_CEPDailyAudit_CPToRule | Type: Table | Production Source: Dealing_staging CEP tables*
