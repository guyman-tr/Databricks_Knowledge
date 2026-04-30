# dbo.ProgramTransitionsEligibility

> Tracks customer eligibility for program transitions (sub-program upgrades/downgrades), recording the source, destination, and triggering context for each eligibility assessment.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

ProgramTransitionsEligibility records when a customer becomes eligible (or is assessed) for a program transition. Each row represents a specific transition assessment: which customer, what they're transitioning from and to, who/what initiated it, and the correlation/platform IDs for tracing.

This table exists because program transitions (upgrades, downgrades, cross-program migrations) are significant business events that need tracking. When a customer becomes eligible for an upgrade (e.g., IBAN EU Green -> Card Green EU), this table records that eligibility. The actual outcome is tracked in ProgramTransitionsEligibilityStatuses (Pending, Completed, Rejected, etc.).

Data is created by dbo.AddProgramTransitionEligibility. Live data shows active transitions between EU sub-programs (IBAN EU Green <-> Card Green EU).

---

## 2. Business Logic

### 2.1 Transition Eligibility Tracking

**What**: Records each customer's eligibility assessment for a program transition with full traceability.

**Columns/Parameters Involved**: `AccountId`, `Gcid`, `SourceSubProgramId`, `DestinationSubProgramId`, `SourceId`, `CorrelationId`, `PlatformId`

**Rules**:
- SourceId identifies how the eligibility was determined: 0=Unknown, 1=UserAPI (automated), 2=Manual. See [Program Transition Eligibility Source](../../_glossary.md#program-transition-eligibility-source).
- Live data shows SourceId=1 (UserAPI) and SourceId=4 (unknown/extended value beyond Dictionary)
- CorrelationId enables end-to-end tracing of the transition across services
- PlatformId identifies the platform context

---

## 3. Data Overview

| Id | AccountId | Gcid | SourceSP | DestSP | SourceId | Meaning |
|---|---|---|---|---|---|---|
| 418000 | 2089131 | 46909625 | 6 (IBAN EU Green) | 11 (Card Green EU) | 1 | Auto-assessed: customer eligible for Card Green EU (cross-program) |
| 417999 | 2121902 | 47486932 | 11 (Card Green EU) | 6 (IBAN EU Green) | 4 | Extended-source assessment for reverse transition |
| 417998 | 2023105 | 46370801 | 6 (IBAN EU Green) | 11 (Card Green EU) | 1 | Auto-assessed: another customer eligible for Card Green EU |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | AccountId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatAccount.Id. The account being assessed for transition. |
| 3 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID. Denormalized from FiatAccount for efficient querying. |
| 4 | SourceSubProgramId | tinyint | NO | - | CODE-BACKED | Current sub-program the customer is in. FK to dbo.SubPrograms. See [Sub-Program](../../_glossary.md#sub-program). |
| 5 | DestinationSubProgramId | tinyint | NO | - | CODE-BACKED | Target sub-program the customer would move to. FK to dbo.SubPrograms. |
| 6 | SourceId | tinyint | NO | - | CODE-BACKED | How eligibility was determined: 0=Unknown, 1=UserAPI, 2=Manual. See [Program Transition Eligibility Source](../../_glossary.md#program-transition-eligibility-source). Live data also shows value 4 (extended/undocumented). |
| 7 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this eligibility record was created. |
| 8 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Unique ID linking this eligibility assessment to the triggering business operation. Enables distributed tracing. |
| 9 | PlatformId | uniqueidentifier | NO | - | CODE-BACKED | Platform context identifier. Links to the platform instance where the eligibility was assessed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountId | dbo.FiatAccount | FK | The account being assessed |
| SourceSubProgramId | dbo.SubPrograms | FK | Current sub-program |
| DestinationSubProgramId | dbo.SubPrograms | FK | Target sub-program |
| SourceId | Dictionary.ProgramTransitionEligibilitySources | Implicit | How eligibility was determined |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.ProgramTransitionsEligibilityStatuses | ProgramTransitionEligibilityId | FK | Outcome status of this eligibility |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.ProgramTransitionsEligibility (table)
├── dbo.FiatAccount (table)
└── dbo.SubPrograms (table) [x2]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatAccount | Table | FK from AccountId |
| dbo.SubPrograms | Table | FK from Source/DestinationSubProgramId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.ProgramTransitionsEligibilityStatuses | Table | FK from ProgramTransitionEligibilityId |
| dbo.AddProgramTransitionEligibility | Stored Procedure | Inserts eligibility records |
| dbo.GetProgramTransitionsEligibilityByPlatformIds | Stored Procedure | Batch lookup by platform IDs |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ProgramTransitionsEligibility | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_..._DestinationSubProgramId_dbo_SubPrograms_Id | FK | DestinationSubProgramId -> dbo.SubPrograms.Id |
| FK_..._SourceSubProgramId_dbo_SubPrograms_Id | FK | SourceSubProgramId -> dbo.SubPrograms.Id |
| FK_ProgramTransitionsEligibility_AccountId_FiatAccount_Id | FK | AccountId -> dbo.FiatAccount.Id |

---

## 8. Sample Queries

### 8.1 Get transition eligibility for a customer (from Confluence pattern)
```sql
SELECT te.*, sp_src.Name AS FromProgram, sp_dst.Name AS ToProgram
FROM dbo.ProgramTransitionsEligibility te WITH (NOLOCK)
JOIN dbo.SubPrograms sp_src WITH (NOLOCK) ON sp_src.Id = te.SourceSubProgramId
JOIN dbo.SubPrograms sp_dst WITH (NOLOCK) ON sp_dst.Id = te.DestinationSubProgramId
WHERE te.Gcid = 46909625 ORDER BY te.Created DESC;
```

### 8.2 Get eligibility with status outcome
```sql
SELECT te.Id, te.Gcid, sp_src.Name AS FromProg, sp_dst.Name AS ToProg,
       tes.StatusId, ds.Name AS StatusName, tes.Created AS StatusDate
FROM dbo.ProgramTransitionsEligibility te WITH (NOLOCK)
JOIN dbo.SubPrograms sp_src WITH (NOLOCK) ON sp_src.Id = te.SourceSubProgramId
JOIN dbo.SubPrograms sp_dst WITH (NOLOCK) ON sp_dst.Id = te.DestinationSubProgramId
JOIN dbo.ProgramTransitionsEligibilityStatuses tes WITH (NOLOCK) ON tes.ProgramTransitionEligibilityId = te.Id
JOIN Dictionary.ProgramTransitionEligibilityStatuses ds WITH (NOLOCK) ON ds.Id = tes.StatusId
WHERE te.Gcid = 46909625 ORDER BY tes.Created DESC;
```

### 8.3 Count recent transitions by direction
```sql
SELECT sp_src.Name AS FromProg, sp_dst.Name AS ToProg, COUNT(*) AS Cnt
FROM dbo.ProgramTransitionsEligibility te WITH (NOLOCK)
JOIN dbo.SubPrograms sp_src WITH (NOLOCK) ON sp_src.Id = te.SourceSubProgramId
JOIN dbo.SubPrograms sp_dst WITH (NOLOCK) ON sp_dst.Id = te.DestinationSubProgramId
WHERE te.Created >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY sp_src.Name, sp_dst.Name ORDER BY Cnt DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | Program transition eligibility is queried with status join and Dictionary lookup; documented as a key operational pattern |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.ProgramTransitionsEligibility | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.ProgramTransitionsEligibility.sql*
