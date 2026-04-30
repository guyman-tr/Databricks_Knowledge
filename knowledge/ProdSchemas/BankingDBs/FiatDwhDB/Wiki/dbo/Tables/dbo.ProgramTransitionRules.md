# dbo.ProgramTransitionRules

> Configuration table defining available program transition paths between sub-programs, controlling which upgrades, downgrades, and cross-program moves are enabled.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (INT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

ProgramTransitionRules defines the directed graph of allowed transitions between fiat sub-programs. Each rule specifies a source sub-program, a destination sub-program, whether the transition is automatic or manual, and whether it is currently enabled. These rules govern which upgrade/downgrade/migration paths are available to customers.

This table exists because the fiat platform needs configurable transition paths between its sub-programs. As new regions and tiers launch, the business team configures which transitions are allowed (e.g., Card Standard UK -> Card Premium UK upgrade) without requiring code changes.

Data is maintained by the dbo.AddProgramTransitionRules stored procedure via the ProgramTransitionRulesType TVP. Rules are periodically refreshed (LastTimeOverride is recent).

---

## 2. Business Logic

### 2.1 Transition Path Graph

**What**: Directed graph of allowed program transitions with enable/disable control.

**Columns/Parameters Involved**: `SourceSubProgramId`, `DestinationSubProgramId`, `TransitionType`, `Enabled`

**Rules**:
- Each rule defines a one-way path: Source -> Destination
- TransitionType: 1=Automatic (system-triggered), 2=Manual (operator-initiated), 3+ may represent additional types beyond the Dictionary definition
- Enabled: 1=path is active, 0=path exists but is disabled
- Live data shows upgrades like IBAN Green DKK(15) -> IBAN Black DKK(16) and downgrades like Card Black EU(12) -> Card Green EU(11)

**Diagram**:
```
Example transitions (from live data):
  IBAN Green DKK (15) --[Auto]--> IBAN Black DKK (16)   [upgrade]
  IBAN Green AUS (13) --[Auto]--> IBAN Black AUS (14)   [upgrade]
  Card Black EU (12)  --[type 3]-> Card Green EU (11)   [downgrade]
```

---

## 3. Data Overview

| Id | FiatId | TransitionType | Enabled | SourceSubProgramId | DestinationSubProgramId | Meaning |
|---|---|---|---|---|---|---|
| 18057 | 16 | 1 | true | 15 | 16 | Auto upgrade from IBAN Green DKK to IBAN Black DKK |
| 18056 | 15 | 1 | true | 13 | 14 | Auto upgrade from IBAN Green AUS to IBAN Black AUS |
| 18055 | 14 | 3 | true | 12 | 11 | Type-3 transition (downgrade) from Card Black EU to Card Green EU |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | FiatId | int | NO | - | NAME-INFERRED | Fiat platform instance identifier. Groups rules by deployment context. |
| 3 | TransitionType | tinyint | NO | - | CODE-BACKED | How the transition is triggered: 1=Automatic, 2=Manual, 3+ extended types. See [Transition Type](../../_glossary.md#transition-type). (Dictionary.TransitionTypes) |
| 4 | Enabled | bit | NO | - | CODE-BACKED | Whether this transition path is currently active. 1=customers can use this path, 0=path is disabled. |
| 5 | SourceSubProgramId | tinyint | NO | - | CODE-BACKED | Sub-program the customer is currently in. Implicit FK to dbo.SubPrograms. See [Sub-Program](../../_glossary.md#sub-program). |
| 6 | DestinationSubProgramId | tinyint | NO | - | CODE-BACKED | Sub-program the customer would move to. Implicit FK to dbo.SubPrograms. |
| 7 | UpdateTime | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this rule was last configured. |
| 8 | LastTimeOverride | datetime2(7) | NO | - | CODE-BACKED | Timestamp of the most recent bulk refresh of this rule. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TransitionType | Dictionary.TransitionTypes | Implicit | Transition trigger type |
| SourceSubProgramId | dbo.SubPrograms | Implicit | Source sub-program |
| DestinationSubProgramId | dbo.SubPrograms | Implicit | Destination sub-program |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddProgramTransitionRules | INSERT/MERGE | Writer | Bulk configures transition rules |
| dbo.GetCountProgramTransitionRules | SELECT | Reader | Returns rule count |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (table is a leaf node).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddProgramTransitionRules | Stored Procedure | Writes rules |
| dbo.GetCountProgramTransitionRules | Stored Procedure | Reads rule count |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None (beyond PK). No explicit FKs despite referencing SubPrograms.

---

## 8. Sample Queries

### 8.1 List all enabled transition paths with sub-program names
```sql
SELECT r.Id, s.Name AS FromProgram, d.Name AS ToProgram, r.TransitionType, r.Enabled
FROM dbo.ProgramTransitionRules r WITH (NOLOCK)
JOIN dbo.SubPrograms s WITH (NOLOCK) ON s.Id = r.SourceSubProgramId
JOIN dbo.SubPrograms d WITH (NOLOCK) ON d.Id = r.DestinationSubProgramId
WHERE r.Enabled = 1
ORDER BY s.Region, s.Name;
```

### 8.2 Find all automatic upgrades
```sql
SELECT s.Name AS FromProgram, d.Name AS ToProgram
FROM dbo.ProgramTransitionRules r WITH (NOLOCK)
JOIN dbo.SubPrograms s WITH (NOLOCK) ON s.Id = r.SourceSubProgramId
JOIN dbo.SubPrograms d WITH (NOLOCK) ON d.Id = r.DestinationSubProgramId
WHERE r.TransitionType = 1 AND r.Enabled = 1;
```

### 8.3 Count rules per transition type
```sql
SELECT TransitionType, Enabled, COUNT(*) AS RuleCount
FROM dbo.ProgramTransitionRules WITH (NOLOCK)
GROUP BY TransitionType, Enabled ORDER BY TransitionType;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | Program transition eligibility is a key operational query pattern |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 8.8/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.ProgramTransitionRules | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.ProgramTransitionRules.sql*
