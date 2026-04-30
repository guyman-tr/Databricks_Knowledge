# dbo.ProgramTransitionRulesType

> User-defined table type for bulk insertion or update of program transition rules into dbo.ProgramTransitionRules.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type mirroring dbo.ProgramTransitionRules structure |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ProgramTransitionRulesType is a table-valued parameter type that mirrors the structure of dbo.ProgramTransitionRules. It enables bulk configuration of rules that define how customers transition between sub-programs (e.g., upgrading from Card Standard UK to Card Premium UK, or migrating from Card to IBAN).

This type exists to support efficient batch deployment of transition rule configurations. When the business updates which program transitions are available, enabled, or disabled, the rules are assembled as a batch and passed through this type to the AddProgramTransitionRules procedure.

Data flows through this type during configuration deployments. Each row defines a single transition path: source sub-program, destination sub-program, whether the transition is automatic or manual, and whether it's currently enabled.

---

## 2. Business Logic

### 2.1 Program Transition Rule Configuration

**What**: Rules that define available paths for customers to move between fiat sub-programs.

**Columns/Parameters Involved**: `FiatId`, `TransitionType`, `Enabled`, `SourceSubProgramId`, `DestinationSubProgramId`

**Rules**:
- Each rule defines a directed path: SourceSubProgramId -> DestinationSubProgramId
- TransitionType controls whether the transition happens automatically (1) or requires manual initiation (2). See [Transition Type](../../_glossary.md#transition-type).
- Enabled flag controls whether the path is currently active (1) or disabled (0)
- The combination of source and destination sub-programs creates the transition graph

**Diagram**:
```
Transition Rule Graph (example):
Card Standard UK (2) --[Automatic]--> Card Premium UK (1)
IBAN Standard UK (4) --[Automatic]--> IBAN Premium UK (3)
Card Standard UK (2) --[Manual]-----> IBAN Standard UK (4)
Card Premium UK (1)  --[Manual]-----> IBAN Premium UK (3)
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FiatId | int | NO | - | NAME-INFERRED | Internal identifier for the fiat configuration context. Links the rule to a specific fiat platform instance. |
| 2 | TransitionType | tinyint | NO | - | CODE-BACKED | How the transition is triggered: 0=Unknown, 1=Automatic, 2=Manual. See [Transition Type](../../_glossary.md#transition-type). (Dictionary.TransitionTypes) |
| 3 | Enabled | bit | NO | - | CODE-BACKED | Whether this transition path is currently active. 1=enabled (customers can use this path), 0=disabled (path exists but is not available). |
| 4 | SourceSubProgramId | tinyint | NO | - | CODE-BACKED | Sub-program the customer is currently in. FK to dbo.SubPrograms. See [Sub-Program](../../_glossary.md#sub-program). |
| 5 | DestinationSubProgramId | tinyint | NO | - | CODE-BACKED | Sub-program the customer would move to. FK to dbo.SubPrograms. See [Sub-Program](../../_glossary.md#sub-program). |
| 6 | UpdateTime | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this rule configuration was last modified. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TransitionType | Dictionary.TransitionTypes | Implicit | Determines if the transition is automatic or manual |
| SourceSubProgramId | dbo.SubPrograms | Implicit | Identifies the starting sub-program for the transition |
| DestinationSubProgramId | dbo.SubPrograms | Implicit | Identifies the target sub-program for the transition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddProgramTransitionRules | Parameter | Parameter Type | Accepts batch of transition rules for bulk insertion/merge |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddProgramTransitionRules | Stored Procedure | TVP parameter type for bulk transition rule configuration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate with a transition rule
```sql
DECLARE @Rules dbo.ProgramTransitionRulesType;
INSERT INTO @Rules (FiatId, TransitionType, Enabled, SourceSubProgramId, DestinationSubProgramId, UpdateTime)
VALUES (1, 1, 1, 2, 1, SYSUTCDATETIME());  -- Auto upgrade: Card Standard UK -> Card Premium UK
EXEC dbo.AddProgramTransitionRules @ProgramTransitionRules = @Rules;
```

### 8.2 Populate with multiple rules including a disabled path
```sql
DECLARE @Rules dbo.ProgramTransitionRulesType;
INSERT INTO @Rules (FiatId, TransitionType, Enabled, SourceSubProgramId, DestinationSubProgramId, UpdateTime)
VALUES (1, 1, 1, 4, 3, SYSUTCDATETIME()),  -- Auto upgrade: IBAN Standard UK -> IBAN Premium UK
       (1, 2, 1, 2, 4, SYSUTCDATETIME()),  -- Manual: Card Standard UK -> IBAN Standard UK
       (1, 2, 0, 1, 3, SYSUTCDATETIME());  -- Disabled: Card Premium UK -> IBAN Premium UK
```

### 8.3 Check the type definition
```sql
SELECT c.name AS ColumnName, t.name AS DataType, c.precision, c.scale, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'ProgramTransitionRulesType' AND tt.schema_id = SCHEMA_ID('dbo')
ORDER BY c.column_id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.ProgramTransitionRulesType | Type: User Defined Type | Source: FiatDwhDB/dbo/User Defined Types/dbo.ProgramTransitionRulesType.sql*
