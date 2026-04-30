# History.Rules

> System-versioned temporal history table for CEP.Rules, recording all past states of the Complex Event Processing hedging automation rules - the configuration that controls how eToro's automated trading system routes hedge orders between hedge servers.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite temporal key (SysEndTime, SysStartTime) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

This table is the **active system-versioned temporal history table** for `CEP.Rules` (source declares `HISTORY_TABLE = [History].[Rules]`). SQL Server automatically archives superseded rule states here when any row in `CEP.Rules` is updated or deleted.

`CEP.Rules` is the core configuration table for eToro's **Complex Event Processing (CEP) hedging rules engine** - the automated system that routes hedge orders to the appropriate hedge server. Each rule combines a rule type (how routing decisions are made), an action type (what the routing action is), a name and description, an active flag, and a priority order.

Rule types from Dictionary.RuleType: 0=NONE, 1=ManualHedgeRouting (operator-defined routing rules), 2=HierarchyHedgeRouting (rules derived from hedging hierarchy). Priority=-1001 in sample data suggests this is a system-level rule with very high priority. The sample rule "HedgingAutomationInstrumentID5ToHsId1Rule" shows that rules can encode specific instrument-to-hedge-server routing logic.

With 14,228 history rows and activity as recent as March 2026, rules are actively managed. `CEP.Rules` also has trigger-based history in `History.CEP_LOG_Rules` (for UPDATE/DELETE), providing a dual history trail.

---

## 2. Business Logic

### 2.1 Rule Priority and Execution Order

**What**: Rules are evaluated in priority order to determine hedge routing.

**Columns/Parameters Involved**: `Priority`, `RuleTypeID`, `IsActive`

**Rules**:
- `Priority` determines evaluation order; negative values (like -1001) have highest priority
- `IsActive=1` means the rule participates in routing; `IsActive=0` means it is disabled
- Only ManualHedgeRouting (type 1) and HierarchyHedgeRouting (type 2) rules actively route
- `CEP.GetRules` returns rules ordered by Priority for the engine to apply sequentially

**Diagram**:
```
CEP Engine Rule Evaluation:
  All active rules ordered by Priority (lowest value = highest priority)
  |
  Rule 1: Priority=-1001, RuleType=1 (ManualHedgeRouting) -> Check condition -> Route to HedgeServer
  Rule 2: Priority=-500, RuleType=2 (HierarchyHedgeRouting) -> Check condition -> Route to HedgeServer
  ...
  Rule N: Priority=1 (default), HedgeAction -> Apply if no prior rule matched
```

### 2.2 Dual History Architecture

**What**: `CEP.Rules` maintains two parallel history trails.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `ValidFrom`

**Rules**:
- System versioning temporal history (-> this table, `History.Rules`): tracks ALL changes via SQL Server's automatic mechanism
- Trigger-based history (-> `History.CEP_LOG_Rules`): trigger `CEPRulesUpdate` fires on UPDATE, trigger `CEPRulesDelete` fires on DELETE, both inserting the `deleted` row into `History.CEP_LOG_Rules`
- `ValidFrom` is updated to `getutcdate()` by the `CEPRulesUpdate` trigger on every UPDATE - tracks when the rule last changed at the application level
- On UPDATE: both temporal history (SysStartTime/SysEndTime) AND trigger history (ValidFrom reset) are maintained

---

## 3. Data Overview

| RuleID | RuleTypeID | Name | IsActive | HedgeRuleActionTypeID | Priority | ValidFrom | Meaning |
|---|---|---|---|---|---|---|---|
| 4858 | 1 (ManualHedgeRouting) | HedgingAutomationIntrumentID5ToHsId1Rule | true | 1 | -1001 | 2026-03-20 23:22 | High-priority manual rule routing InstrumentID 5 to HedgeServer 1; was active for about 1 minute before being updated - a rapid test configuration |
| 4858 | 1 | (same) | true | 1 | -1001 | same | A second history entry for the same RuleID within the same second - rapid succession updates |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RuleID | int | NO | - | CODE-BACKED | Identifier of the original `CEP.Rules` row (IDENTITY int in source, NOT an identity here). Same RuleID can appear multiple times - one per historical state. Uniquely identifies which rule this history entry belongs to. |
| 2 | RuleTypeID | int | NO | - | VERIFIED | Classifies the rule's routing mechanism. FK to Dictionary.RuleType. Values: 0=NONE, 1=ManualHedgeRouting (operator-configured explicit routing), 2=HierarchyHedgeRouting (computed from hedging hierarchy). Determines how the CEP engine evaluates the rule. |
| 3 | Name | varchar(50) | YES | - | CODE-BACKED | Human-readable rule identifier. Convention observed: "{RuleContext}{Entity}{RoutingTarget}Rule" (e.g., "HedgingAutomationInstrumentID5ToHsId1Rule"). Supports operator understanding and management UI display. |
| 4 | Description | nvarchar(1000) | YES | - | NAME-INFERRED | Longer explanation of the rule's purpose and conditions. In sample data, populated as literal "Description" - may be auto-generated or sparsely populated in practice. |
| 5 | IsActive | bit | NO | - | CODE-BACKED | Whether the rule participates in CEP engine evaluation. 1=active (evaluated by engine), 0=disabled (skipped). `CEP.GetRules` reads all rows without IsActive filter - the engine may apply its own active check. |
| 6 | HedgeRuleActionTypeID | int | NO | - | CODE-BACKED | The type of hedging action this rule triggers when matched. No FK defined in DDL; no Dictionary.HedgeRuleActionType table found in SSDT. Value 1 seen in sample data. Likely an embedded enumeration in the CEP application code defining the routing action type. |
| 7 | Occurred | datetime | YES | getutcdate() | CODE-BACKED | Original creation timestamp of the rule. Set by default on INSERT. Represents when the rule was first defined, even if it has been modified since (unlike ValidFrom which is reset on updates). |
| 8 | ValidFrom | datetime | YES | getutcdate() | CODE-BACKED | Tracks the most recent modification time of the rule at the application level. Reset to `getutcdate()` by the `CEPRulesUpdate` trigger on every UPDATE. Can be used to detect recently-changed rules. |
| 9 | Priority | int | YES | 1 | CODE-BACKED | Determines evaluation order among active rules. Lower (more negative) values = higher priority. Default=1. Value -1001 in sample = system-level high-priority rule. Rules are applied in ascending order; the first matching rule determines the routing action. |
| 10 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | Computed in source as `suser_name()` - SQL Server login that last modified this rule. Stored as a plain value in history. Enables accountability: shows whether a change came from an application service (e.g., "DevTradingSTG") or a human admin. |
| 11 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Computed in source as `CONVERT(varchar(500), context_info())` - the application-set session context at the time of the change. NULL when context_info() was not set (e.g., direct SQL changes). |
| 12 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC instant when this rule state became current in `CEP.Rules`. Automatically managed by SQL Server temporal system versioning. Nanosecond precision. |
| 13 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | UTC instant when this rule state was superseded. Automatically set by SQL Server. Leading key of the clustered index. Default '9999-12-31' in source represents the currently active state. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RuleID | CEP.Rules | Temporal History | Each row is a past state of the source rule; RuleID identifies which rule. |
| RuleTypeID | Dictionary.RuleType | Implicit (FK on source) | 0=NONE, 1=ManualHedgeRouting, 2=HierarchyHedgeRouting. |
| HedgeRuleActionTypeID | Unknown lookup (application code) | Implicit | Hedge action type: value 1 seen; full value set defined in application. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CEP.Rules | HISTORY_TABLE | Temporal History | Active source table; all expired rule states archived here by SQL Server. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Rules (table)
  (temporal history - no code-level dependencies; populated by SQL Server from CEP.Rules)
```

---

### 6.1 Objects This Depends On

No dependencies. Temporal history table.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CEP.Rules | Table | Active source table; expired rule states archived here by SQL Server temporal versioning. |

Note: CEP.Rules also writes to `History.CEP_LOG_Rules` via triggers (a parallel, trigger-based history trail separate from this temporal table).

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_Rules | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

Note: DATA_COMPRESSION = PAGE on both table and clustered index.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page compression for archival data. |

---

## 8. Sample Queries

### 8.1 View recent rule configuration changes
```sql
SELECT
    h.RuleID,
    dr.Description AS RuleType,
    h.Name,
    h.IsActive,
    h.HedgeRuleActionTypeID,
    h.Priority,
    h.DbLoginName,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidTo,
    DATEDIFF(second, h.SysStartTime, h.SysEndTime) AS DurationSeconds
FROM [History].[Rules] h WITH (NOLOCK)
JOIN [Dictionary].[RuleType] dr WITH (NOLOCK) ON dr.RuleTypeID = h.RuleTypeID
ORDER BY h.SysEndTime DESC
```

### 8.2 Restore a specific rule to its state at a past date
```sql
SELECT RuleID, RuleTypeID, Name, Description, IsActive, HedgeRuleActionTypeID, Priority, DbLoginName
FROM [CEP].[Rules]
FOR SYSTEM_TIME AS OF '2026-03-01T00:00:00'
ORDER BY Priority
```

### 8.3 Track all state changes for a specific rule
```sql
SELECT
    Name,
    IsActive,
    HedgeRuleActionTypeID,
    Priority,
    DbLoginName,
    AppLoginName,
    SysStartTime AS EffectiveFrom,
    SysEndTime AS EffectiveTo
FROM [History].[Rules] WITH (NOLOCK)
WHERE RuleID = @RuleID
ORDER BY SysStartTime ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9.2/10, Logic: 10/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 3 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Rules | Type: Table | Source: etoro/etoro/History/Tables/History.Rules.sql*
