# dbo.AddProgramTransitionEligibilityStatus

> Simple INSERT procedure that records the outcome status of a program transition eligibility assessment.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Simple INSERT into ProgramTransitionsEligibilityStatuses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddProgramTransitionEligibilityStatus records the outcome (Pending, Completed, Rejected, Disabled, Expired) of a program transition eligibility assessment. Simple INSERT with no deduplication.

---

## 2. Business Logic

No complex logic. Simple INSERT.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProgramTransitionEligibilityId | bigint | NO | - | CODE-BACKED | FK to ProgramTransitionsEligibility.Id. |
| 2 | @StatusId | tinyint | NO | - | CODE-BACKED | Status: 0=Pending, 1=Completed, 2=Rejected, 3=Disabled, 4=Expired. See [Program Transition Eligibility Status](../../_glossary.md#program-transition-eligibility-status). |
| 3 | @Created | datetime2(7) | NO | - | CODE-BACKED | Event timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | dbo.ProgramTransitionsEligibilityStatuses | Write | Insert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddProgramTransitionEligibilityStatus (procedure)
└── dbo.ProgramTransitionsEligibilityStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.ProgramTransitionsEligibilityStatuses | Table | INSERT target |

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

### 8.1 Record completion
```sql
EXEC dbo.AddProgramTransitionEligibilityStatus @ProgramTransitionEligibilityId = 418000,
    @StatusId = 1, @Created = SYSUTCDATETIME();
```

### 8.2 Record rejection
```sql
EXEC dbo.AddProgramTransitionEligibilityStatus @ProgramTransitionEligibilityId = 418000,
    @StatusId = 2, @Created = SYSUTCDATETIME();
```

### 8.3 Verify
```sql
SELECT StatusId, Created FROM dbo.ProgramTransitionsEligibilityStatuses WITH (NOLOCK)
WHERE ProgramTransitionEligibilityId = 418000 ORDER BY Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddProgramTransitionEligibilityStatus | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddProgramTransitionEligibilityStatus.sql*
