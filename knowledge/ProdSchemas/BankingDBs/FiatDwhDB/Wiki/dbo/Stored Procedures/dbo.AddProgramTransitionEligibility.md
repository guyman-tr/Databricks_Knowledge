# dbo.AddProgramTransitionEligibility

> Simple INSERT procedure that records a program transition eligibility assessment for a customer.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Simple INSERT into ProgramTransitionsEligibility |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddProgramTransitionEligibility records a new eligibility assessment for a customer's program transition. Simple INSERT with no deduplication - every call creates a new eligibility record. Used when the system assesses whether a customer qualifies for a sub-program upgrade/downgrade.

---

## 2. Business Logic

No complex logic. Simple INSERT without deduplication or conditional logic.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AccountId | bigint | NO | - | CODE-BACKED | FK to FiatAccount.Id. |
| 2 | @Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID (denormalized). |
| 3 | @SourceSubProgramId | tinyint | NO | - | CODE-BACKED | Current sub-program. See [Sub-Program](../../_glossary.md#sub-program). |
| 4 | @DestinationSubProgramId | tinyint | NO | - | CODE-BACKED | Target sub-program. |
| 5 | @SourceId | tinyint | NO | - | CODE-BACKED | How eligibility determined: 0=Unknown, 1=UserAPI, 2=Manual. See [Program Transition Eligibility Source](../../_glossary.md#program-transition-eligibility-source). |
| 6 | @Created | datetime2(7) | NO | - | CODE-BACKED | Event timestamp. |
| 7 | @CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Distributed tracing ID. |
| 8 | @PlatformId | uniqueidentifier | NO | - | CODE-BACKED | Platform context identifier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | dbo.ProgramTransitionsEligibility | Write | Insert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddProgramTransitionEligibility (procedure)
└── dbo.ProgramTransitionsEligibility (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.ProgramTransitionsEligibility | Table | INSERT target |

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

### 8.1 Record an automatic eligibility assessment
```sql
EXEC dbo.AddProgramTransitionEligibility @AccountId = 2089131, @Gcid = 46909625,
    @SourceSubProgramId = 6, @DestinationSubProgramId = 11, @SourceId = 1,
    @Created = SYSUTCDATETIME(), @CorrelationId = NEWID(), @PlatformId = NEWID();
```

### 8.2 Verify
```sql
SELECT * FROM dbo.ProgramTransitionsEligibility WITH (NOLOCK) WHERE Gcid = 46909625 ORDER BY Created DESC;
```

### 8.3 Count recent eligibility assessments
```sql
SELECT SourceId, COUNT(*) AS Cnt FROM dbo.ProgramTransitionsEligibility WITH (NOLOCK)
WHERE Created >= DATEADD(DAY, -1, GETUTCDATE()) GROUP BY SourceId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddProgramTransitionEligibility | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddProgramTransitionEligibility.sql*
