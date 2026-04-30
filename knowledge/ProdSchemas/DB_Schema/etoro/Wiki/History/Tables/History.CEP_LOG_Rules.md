# History.CEP_LOG_Rules

> Trigger-based audit log capturing previous versions of CEP rule definitions; each row records a past state of a rule's type, name, active status, action type, priority, and validity period.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (RuleID, ValidFrom, ValidTo) - composite PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.CEP_LOG_Rules is the most actively populated of the CEP_LOG audit tables, with 9,574 rows and changes recorded as recently as 2026-03-18. It captures the complete version history of rules in the CEP (Complex Event Processing) rules engine - the top-level orchestration objects that determine how eToro's hedge server responds to market and position events.

CEP.Rules stores the live rule definitions. Each rule has a type (RuleTypeID), a name, an action to take when triggered (HedgeRuleActionTypeID), an active flag, and a priority. When a rule is modified or deleted, triggers copy the old row here.

The naming convention "HedgingAutomationIntrumentID{N}ToHsId{N}Rule" (note: "Intrument" is a typo in the production name pattern) reveals the primary use case: automated hedging rules that route specific instruments (InstrumentID) to specific hedge servers (HsId). All observed rules have RuleTypeID=1, and 97% use HedgeRuleActionTypeID=1, indicating a single dominant rule type dominates the configuration.

---

## 2. Business Logic

### 2.1 Rule Change Audit Pattern

**What**: Each row is a snapshot of one CEP rule definition before it was changed.

**Columns/Parameters Involved**: `RuleID`, `RuleTypeID`, `Name`, `IsActive`, `HedgeRuleActionTypeID`, `Priority`, `ValidFrom`, `ValidTo`

**Rules**:
- UPDATE trigger (CEPRulesUpdate): refreshes ValidFrom on the live row, then copies OLD row here
- DELETE trigger (CEPRulesDelete): copies the deleted row here
- Priority can be negative (e.g., -1001) - lower (more negative) values indicate higher urgency or specific override rules
- HedgeRuleActionTypeID=1 is the dominant action type (97% of history); values like 5, 8, 9, 11, 21, 22 represent less common hedge actions
- All historical rows have RuleTypeID=1, indicating all hedge automation rules are of a single unified type

---

## 3. Data Overview

9,574 rows, with the most recent change on 2026-03-18 (actively used). RuleTypeID=1 exclusively.

| HedgeRuleActionTypeID | Count | % |
|---|---|---|
| 1 | 9,311 | 97.2% |
| 21 | 52 | 0.5% |
| 9 | 43 | 0.4% |
| 5 | 35 | 0.4% |
| 11 | 34 | 0.4% |
| others | 99 | 1.0% |

Recent example: "HedgingAutomationIntrumentID4820ToHsId1Rule" - routes instrument 4820 to hedge server 1 with priority -1001.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RuleID | int | NO | - | CODE-BACKED | Identifies the rule that was changed. IDENTITY PK in CEP.Rules. Part of composite PK here. |
| 2 | RuleTypeID | int | NO | - | CODE-BACKED | The type of rule. FK to Dictionary.RuleType in parent table. All observed values are 1 (single rule type in use). |
| 3 | Name | varchar(50) | YES | - | CODE-BACKED | Human-readable rule name at time of change. Convention: "HedgingAutomationIntrumentID{N}ToHsId{N}Rule". Note the typo "Intrument" is present in production rule names. |
| 4 | Description | nvarchar(1000) | YES | - | CODE-BACKED | Optional extended description of the rule's purpose. Typically NULL for auto-generated hedging rules. |
| 5 | IsActive | bit | NO | - | CODE-BACKED | Whether this rule was active (evaluating and triggering) at time of change. Rules can be disabled without deletion. |
| 6 | HedgeRuleActionTypeID | int | NO | - | CODE-BACKED | The action the hedge server takes when this rule fires. Value 1 dominates (97%); values 5, 8, 9, 11, 21, 22 represent other hedge actions like position routing, risk controls, etc. |
| 7 | Occurred | datetime | YES | - | CODE-BACKED | Timestamp when the rule event was last processed by the CEP engine. Defaults to getutcdate() in parent. |
| 8 | ValidFrom | datetime | NO | - | CODE-BACKED | Timestamp when this rule version became active. Copied from parent row. Part of composite PK. |
| 9 | ValidTo | datetime | NO | getutcdate() | CODE-BACKED | Timestamp when this rule was superseded. Defaults to getutcdate() at INSERT. Part of composite PK. |
| 10 | Priority | int | YES | 1 | CODE-BACKED | Rule evaluation priority. Negative values (e.g., -1001) observed for high-specificity routing rules. Lower (more negative) = higher override precedence. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RuleID | CEP.Rules | Trigger audit | Past version of a live rule |
| RuleTypeID | Dictionary.RuleType | Implicit | Type classification of the rule |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CEP.Rules | CEPRulesDelete trigger | Writer | Copies deleted rule rows here |
| CEP.Rules | CEPRulesUpdate trigger | Writer | Copies pre-update rule rows here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CEP_LOG_Rules (table)
```

---

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CEP.Rules | Table | Trigger writer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CEP_LOG_RULES | CLUSTERED PK | RuleID ASC, ValidFrom ASC, ValidTo ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CEP_LOG_RULES | PRIMARY KEY | (RuleID, ValidFrom, ValidTo) |
| (DEFAULT) | DEFAULT | ValidTo = getutcdate() |

Storage: ON [PRIMARY] filegroup.

---

## 8. Sample Queries

### 8.1 View all versions of a specific rule
```sql
SELECT RuleID, Name, IsActive, HedgeRuleActionTypeID, Priority, ValidFrom, ValidTo
FROM [History].[CEP_LOG_Rules]
WHERE RuleID = @RuleID
ORDER BY ValidFrom DESC
```

### 8.2 Rules changed in the last 24 hours
```sql
SELECT RuleID, Name, IsActive, HedgeRuleActionTypeID, Priority, ValidFrom, ValidTo
FROM [History].[CEP_LOG_Rules]
WHERE ValidTo >= DATEADD(HOUR, -24, GETUTCDATE())
ORDER BY ValidTo DESC
```

### 8.3 Rules for a specific instrument ID (from name pattern)
```sql
SELECT RuleID, Name, HedgeRuleActionTypeID, Priority, ValidFrom, ValidTo
FROM [History].[CEP_LOG_Rules]
WHERE Name LIKE '%IntrumentID' + CAST(@InstrumentID AS varchar) + '%'
ORDER BY ValidFrom DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (written by triggers) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CEP_LOG_Rules | Type: Table | Source: etoro/etoro/History/Tables/History.CEP_LOG_Rules.sql*
