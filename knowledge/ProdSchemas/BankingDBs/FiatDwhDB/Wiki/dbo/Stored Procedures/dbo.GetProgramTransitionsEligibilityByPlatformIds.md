# dbo.GetProgramTransitionsEligibilityByPlatformIds

> Batch lookup that retrieves program transition eligibility records by a list of PlatformIds passed via the GuidListType TVP.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT from ProgramTransitionsEligibility INNER JOIN GuidListType TVP on PlatformId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetProgramTransitionsEligibilityByPlatformIds retrieves eligibility records by batch of PlatformIds. Same pattern as GetFiatAccountsByAccountGuids: copies TVP to temp table, JOINs on PlatformId. Returns all eligibility fields for matching records. Uses WITH(NOLOCK).

---

## 2. Business Logic

### 2.1 TVP-Based Batch Lookup by PlatformId

**Rules**:
- Copies GuidListType TVP to #PlatformIds temp table
- INNER JOIN ProgramTransitionsEligibility.PlatformId = #PlatformIds.Guid
- Returns Id, AccountId, Gcid, SourceSubProgramId, DestinationSubProgramId, SourceId, Created, PlatformId

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlatformIds | dbo.GuidListType | NO | READONLY | CODE-BACKED | TVP containing list of PlatformIds to look up. See dbo.GuidListType. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT/JOIN | dbo.ProgramTransitionsEligibility | Read | Batch PlatformId lookup |
| @param | dbo.GuidListType | Type | TVP parameter type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetProgramTransitionsEligibilityByPlatformIds (procedure)
├── dbo.ProgramTransitionsEligibility (table)
└── dbo.GuidListType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.ProgramTransitionsEligibility | Table | JOIN source |
| dbo.GuidListType | UDT | TVP parameter type |

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

### 8.1 Batch lookup by PlatformIds
```sql
DECLARE @ids dbo.GuidListType;
INSERT INTO @ids VALUES ('D04C0E26-89D4-452D-A297-4F42883E20B4');
EXEC dbo.GetProgramTransitionsEligibilityByPlatformIds @PlatformIds = @ids;
```

### 8.2 Equivalent query
```sql
SELECT * FROM dbo.ProgramTransitionsEligibility WITH (NOLOCK)
WHERE PlatformId = 'D04C0E26-89D4-452D-A297-4F42883E20B4';
```

### 8.3 Multiple IDs
```sql
DECLARE @ids dbo.GuidListType;
INSERT INTO @ids VALUES ('D04C0E26-89D4-452D-A297-4F42883E20B4'), ('82B47F4C-3C60-43F5-BC24-40D274C2E41F');
EXEC dbo.GetProgramTransitionsEligibilityByPlatformIds @PlatformIds = @ids;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.GetProgramTransitionsEligibilityByPlatformIds | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.GetProgramTransitionsEligibilityByPlatformIds.sql*
