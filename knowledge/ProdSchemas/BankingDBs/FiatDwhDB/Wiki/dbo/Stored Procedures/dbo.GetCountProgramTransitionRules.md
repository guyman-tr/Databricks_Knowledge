# dbo.GetCountProgramTransitionRules

> Returns the total count of program transition rules. No parameters. Used as a health check after rule replacement.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT COUNT(*) FROM ProgramTransitionRules |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetCountProgramTransitionRules returns the count of rows in dbo.ProgramTransitionRules. No parameters. Uses WITH(NOLOCK). Called after AddProgramTransitionRules to verify the expected rule count.

---

## 2. Business Logic

No complex logic. Simple COUNT(*).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No parameters.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.ProgramTransitionRules | Read | COUNT query |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetCountProgramTransitionRules (procedure)
└── dbo.ProgramTransitionRules (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.ProgramTransitionRules | Table | COUNT source |

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

### 8.1 Get rule count
```sql
EXEC dbo.GetCountProgramTransitionRules;
```

### 8.2 Equivalent query
```sql
SELECT COUNT(*) FROM dbo.ProgramTransitionRules WITH (NOLOCK);
```

### 8.3 Verify after rule replacement
```sql
EXEC dbo.AddProgramTransitionRules @ProgramTransitionRules = @Rules;
EXEC dbo.GetCountProgramTransitionRules;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.GetCountProgramTransitionRules | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.GetCountProgramTransitionRules.sql*
