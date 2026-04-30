# dbo.GetCountEligibilityRules

> Returns the total count of eligibility rules currently in the system. No parameters. Used as a health check after rule replacement.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT COUNT(*) FROM EligibilityRules |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetCountEligibilityRules returns the count of rows in dbo.EligibilityRules. No parameters. Uses WITH(NOLOCK). Typically called after AddEligibilityRules (which does DELETE + INSERT) to verify the expected number of rules were loaded.

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
| SELECT | dbo.EligibilityRules | Read | COUNT query |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetCountEligibilityRules (procedure)
└── dbo.EligibilityRules (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.EligibilityRules | Table | COUNT source |

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
EXEC dbo.GetCountEligibilityRules;
```

### 8.2 Equivalent query
```sql
SELECT COUNT(*) FROM dbo.EligibilityRules WITH (NOLOCK);
```

### 8.3 Use after rule replacement
```sql
EXEC dbo.AddEligibilityRules @EligibilityRules = @Rules;
EXEC dbo.GetCountEligibilityRules; -- Verify expected count
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.GetCountEligibilityRules | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.GetCountEligibilityRules.sql*
