# dbo.AddEligibilityRules

> Full-replacement procedure that deletes all existing eligibility rules and bulk-inserts a new complete rule set from the EligibilityRulesType TVP.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | DELETE + bulk INSERT into EligibilityRules from TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddEligibilityRules performs a full replacement of all eligibility rules. Unlike other "Add" procedures that use upsert logic, this one DELETES all existing rows from dbo.EligibilityRules and then bulk INSERTs the complete new rule set from the EligibilityRulesType TVP. This is a transactional operation - both the DELETE and INSERT happen within a single transaction.

This full-replacement pattern ensures the rule set is always consistent and complete. It avoids incremental update complexity where orphaned or conflicting rules could accumulate. The LastTimeOverride column is set to GETUTCDATE() on INSERT, providing a timestamp of the most recent full refresh.

---

## 2. Business Logic

### 2.1 Full Replacement Pattern

**What**: Atomic delete-all + bulk-insert for complete rule set consistency.

**Columns/Parameters Involved**: `@EligibilityRules` (TVP)

**Rules**:
- DELETE FROM EligibilityRules removes ALL existing rules (no filter)
- TVP data is first copied to a temp table (#EligibilityRules) for processing
- INSERT includes all columns from TVP plus GETUTCDATE() for LastTimeOverride
- Entire operation is wrapped in a TRANSACTION for atomicity
- If the transaction fails, no rules are deleted (rollback)

**Diagram**:
```
@EligibilityRules TVP
      |
      v
BEGIN TRANSACTION
  1. DELETE FROM EligibilityRules (all rows)
  2. SELECT * INTO #EligibilityRules FROM @TVP
  3. INSERT INTO EligibilityRules FROM #EligibilityRules + GETUTCDATE()
COMMIT TRANSACTION
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @EligibilityRules | dbo.EligibilityRulesType | NO | READONLY | CODE-BACKED | TVP containing the complete new rule set. All existing rules are replaced by this set. See dbo.EligibilityRulesType for column details. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE/INSERT | dbo.EligibilityRules | Write | Full replacement target |
| @EligibilityRules | dbo.EligibilityRulesType | Type | TVP parameter type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddEligibilityRules (procedure)
├── dbo.EligibilityRules (table)
└── dbo.EligibilityRulesType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.EligibilityRules | Table | DELETE + INSERT target |
| dbo.EligibilityRulesType | UDT | TVP parameter type |

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

### 8.1 Replace all eligibility rules
```sql
DECLARE @Rules dbo.EligibilityRulesType;
INSERT INTO @Rules (FiatId, DesignatedRegulationId, CountryId, ClubId, SubProgramId, RolloutPercentage, RegulationId, UpdateTime, Priority)
VALUES (1, 5, 57, 1, 15, 100.0, 5, SYSUTCDATETIME(), 0),
       (2, 10, 57, 7, 16, 100.0, 10, SYSUTCDATETIME(), 0);
EXEC dbo.AddEligibilityRules @EligibilityRules = @Rules;
```

### 8.2 Verify replacement
```sql
SELECT COUNT(*) AS RuleCount FROM dbo.EligibilityRules WITH (NOLOCK);
SELECT TOP 5 * FROM dbo.EligibilityRules WITH (NOLOCK) ORDER BY Id;
```

### 8.3 Check LastTimeOverride was set
```sql
SELECT TOP 1 LastTimeOverride FROM dbo.EligibilityRules WITH (NOLOCK) ORDER BY Id DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddEligibilityRules | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddEligibilityRules.sql*
