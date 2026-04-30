# dbo.ProgramTransitionsEligibilityStatuses

> Event-sourced status table tracking the outcome of program transition eligibility assessments (Pending, Completed, Rejected, Disabled, Expired).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

ProgramTransitionsEligibilityStatuses records the outcome of each program transition eligibility assessment. When a customer is assessed for eligibility (recorded in ProgramTransitionsEligibility), the result - Pending, Completed, Rejected, Disabled, or Expired - is tracked here. Multiple status records per eligibility allow tracking the full progression.

Data is created by dbo.AddProgramTransitionEligibilityStatus.

---

## 2. Business Logic

### 2.1 Eligibility Outcome Tracking

**What**: Tracks the progression of each transition eligibility from assessment to outcome.

**Columns/Parameters Involved**: `ProgramTransitionEligibilityId`, `StatusId`, `Created`

**Rules**:
- StatusId: 0=Pending, 1=Completed, 2=Rejected, 3=Disabled, 4=Expired. See [Program Transition Eligibility Status](../../_glossary.md#program-transition-eligibility-status).
- Normal flow: Pending(0) -> Completed(1) or Rejected(2)
- Administrative: Disabled(3) when transition path is turned off
- Expiry: Expired(4) when eligibility window passes

---

## 3. Data Overview

N/A - querying live status data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. |
| 2 | ProgramTransitionEligibilityId | bigint | NO | - | CODE-BACKED | FK to dbo.ProgramTransitionsEligibility.Id. The eligibility assessment this status belongs to. |
| 3 | StatusId | tinyint | NO | - | CODE-BACKED | Outcome status: 0=Pending, 1=Completed, 2=Rejected, 3=Disabled, 4=Expired. See [Program Transition Eligibility Status](../../_glossary.md#program-transition-eligibility-status). (Dictionary.ProgramTransitionEligibilityStatuses) |
| 4 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this status was recorded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProgramTransitionEligibilityId | dbo.ProgramTransitionsEligibility | FK | The eligibility assessment |
| StatusId | Dictionary.ProgramTransitionEligibilityStatuses | Implicit | Status value |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddProgramTransitionEligibilityStatus | INSERT | Writer | Records status changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.ProgramTransitionsEligibilityStatuses (table)
└── dbo.ProgramTransitionsEligibility (table)
    ├── dbo.FiatAccount (table)
    └── dbo.SubPrograms (table) [x2]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.ProgramTransitionsEligibility | Table | FK from ProgramTransitionEligibilityId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddProgramTransitionEligibilityStatus | Stored Procedure | Writes status records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ProgramTransitionsEligibilityStatuses | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_...ProgramTransitionEligibilityId_ProgramTransitionsEligibility_Id | FK | ProgramTransitionEligibilityId -> dbo.ProgramTransitionsEligibility.Id |

---

## 8. Sample Queries

### 8.1 Get eligibility with status (from Confluence pattern)
```sql
SELECT te.Gcid, sp_src.Name AS FromProg, sp_dst.Name AS ToProg,
       tes.StatusId, ds.Name AS StatusName, tes.Created
FROM dbo.ProgramTransitionsEligibility te WITH (NOLOCK)
JOIN dbo.ProgramTransitionsEligibilityStatuses tes WITH (NOLOCK) ON tes.ProgramTransitionEligibilityId = te.Id
JOIN dbo.SubPrograms sp_src WITH (NOLOCK) ON sp_src.Id = te.SourceSubProgramId
JOIN dbo.SubPrograms sp_dst WITH (NOLOCK) ON sp_dst.Id = te.DestinationSubProgramId
JOIN Dictionary.ProgramTransitionEligibilityStatuses ds WITH (NOLOCK) ON ds.Id = tes.StatusId
WHERE te.Gcid = 46909625 ORDER BY tes.Created DESC;
```

### 8.2 Count outcomes by status
```sql
SELECT ds.Name AS Status, COUNT(*) AS Cnt
FROM dbo.ProgramTransitionsEligibilityStatuses tes WITH (NOLOCK)
JOIN Dictionary.ProgramTransitionEligibilityStatuses ds WITH (NOLOCK) ON ds.Id = tes.StatusId
WHERE tes.Created >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY ds.Name ORDER BY Cnt DESC;
```

### 8.3 Find recently expired eligibilities
```sql
SELECT te.Gcid, te.AccountId, tes.Created
FROM dbo.ProgramTransitionsEligibilityStatuses tes WITH (NOLOCK)
JOIN dbo.ProgramTransitionsEligibility te WITH (NOLOCK) ON te.Id = tes.ProgramTransitionEligibilityId
WHERE tes.StatusId = 4 AND tes.Created >= DATEADD(DAY, -1, GETUTCDATE())
ORDER BY tes.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | "Program transition eligibility" query pattern joins this table with ProgramTransitionsEligibility and Dictionary |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.ProgramTransitionsEligibilityStatuses | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.ProgramTransitionsEligibilityStatuses.sql*
