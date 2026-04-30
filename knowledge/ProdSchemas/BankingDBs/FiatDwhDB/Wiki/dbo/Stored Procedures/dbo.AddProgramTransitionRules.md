# dbo.AddProgramTransitionRules

> Full-replacement procedure that deletes all existing program transition rules and bulk-inserts a new complete rule set from the ProgramTransitionRulesType TVP.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | DELETE + bulk INSERT into ProgramTransitionRules from TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddProgramTransitionRules performs a full replacement of all program transition rules, identical in pattern to AddEligibilityRules. DELETEs all existing rows from ProgramTransitionRules, then bulk INSERTs the complete new rule set from the ProgramTransitionRulesType TVP. Atomic within a single TRANSACTION. Sets LastTimeOverride to GETUTCDATE() on INSERT.

---

## 2. Business Logic

### 2.1 Full Replacement Pattern

**What**: Atomic delete-all + bulk-insert for complete rule set consistency.

**Rules**:
- DELETE FROM ProgramTransitionRules removes ALL existing rules
- TVP copied to temp table, then INSERT with GETUTCDATE() for LastTimeOverride
- Same pattern as AddEligibilityRules

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProgramTransitionRules | dbo.ProgramTransitionRulesType | NO | READONLY | CODE-BACKED | TVP containing the complete new rule set. See dbo.ProgramTransitionRulesType. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE/INSERT | dbo.ProgramTransitionRules | Write | Full replacement target |
| @param | dbo.ProgramTransitionRulesType | Type | TVP parameter type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddProgramTransitionRules (procedure)
├── dbo.ProgramTransitionRules (table)
└── dbo.ProgramTransitionRulesType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.ProgramTransitionRules | Table | DELETE + INSERT target |
| dbo.ProgramTransitionRulesType | UDT | TVP parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Replace all transition rules
```sql
DECLARE @Rules dbo.ProgramTransitionRulesType;
INSERT INTO @Rules (FiatId, TransitionType, Enabled, SourceSubProgramId, DestinationSubProgramId, UpdateTime)
VALUES (15, 1, 1, 13, 14, SYSUTCDATETIME()),
       (16, 1, 1, 15, 16, SYSUTCDATETIME());
EXEC dbo.AddProgramTransitionRules @ProgramTransitionRules = @Rules;
```

### 8.2 Verify replacement
```sql
SELECT COUNT(*) AS RuleCount FROM dbo.ProgramTransitionRules WITH (NOLOCK);
SELECT TOP 5 * FROM dbo.ProgramTransitionRules WITH (NOLOCK) ORDER BY Id DESC;
```

### 8.3 Check LastTimeOverride
```sql
SELECT TOP 1 LastTimeOverride FROM dbo.ProgramTransitionRules WITH (NOLOCK) ORDER BY Id DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddProgramTransitionRules | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddProgramTransitionRules.sql*
