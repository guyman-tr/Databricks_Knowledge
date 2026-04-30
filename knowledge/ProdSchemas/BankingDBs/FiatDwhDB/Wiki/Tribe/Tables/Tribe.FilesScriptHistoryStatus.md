# Tribe.FilesScriptHistoryStatus

> Status tracking table for the script approval workflow, recording the progression of each script through Unapproved -> Approved -> Executed states.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (+ PK) |

---

## 1. Business Meaning

FilesScriptHistoryStatus tracks the approval workflow for Tribe schema scripts stored in FilesScriptHistory. Each row records a status transition for a script: Unapproved (0) -> Approved (1) -> Executed (2). This workflow ensures DDL changes from Tribe data files are reviewed before being applied. See [Tribe Script Status](../../_glossary.md#tribe-script-status) for status values.

---

## 2. Business Logic

### 2.1 Script Approval Workflow

**What**: Three-step approval: Unapproved -> Approved -> Executed.

**Columns/Parameters Involved**: `FileScriptHistoryId`, `ScriptStatusId`

**Rules**:
- ScriptStatusId: 0=Unapproved, 1=Approved, 2=Executed (Dictionary.TribeScriptStatus)
- AddUpdateScript creates initial Unapproved status
- MarkScriptAsApproved transitions to Approved
- MarkScriptAsExecuted transitions to Executed

---

## 3. Data Overview

N/A - workflow status data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. |
| 2 | FileScriptHistoryId | bigint | NO | - | CODE-BACKED | Implicit FK to Tribe.FilesScriptHistory.Id. The script this status belongs to. |
| 3 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | When this status transition occurred. |
| 4 | ScriptStatusId | tinyint | NO | - | CODE-BACKED | Status: 0=Unapproved, 1=Approved, 2=Executed. See [Tribe Script Status](../../_glossary.md#tribe-script-status). (Dictionary.TribeScriptStatus) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FileScriptHistoryId | Tribe.FilesScriptHistory | Implicit FK | Parent script record |
| ScriptStatusId | Dictionary.TribeScriptStatus | Implicit | Status value lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tribe.MarkScriptAsApproved | INSERT | Writer | Sets Approved status |
| Tribe.MarkScriptAsExecuted | INSERT | Writer | Sets Executed status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.FilesScriptHistoryStatus (table)
└── Tribe.FilesScriptHistory (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.FilesScriptHistory | Table | Implicit FK from FileScriptHistoryId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Tribe.AddUpdateScript | Stored Procedure | Inserts initial status |
| Tribe.MarkScriptAsApproved | Stored Procedure | Updates to Approved |
| Tribe.MarkScriptAsExecuted | Stored Procedure | Updates to Executed |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FilesScriptHistoryStatus | CLUSTERED | Id ASC | - | - | Active |
| FilesScriptHistoryStatus_FileScriptHistoryId | NONCLUSTERED | FileScriptHistoryId ASC | - | - | Active |
| ix_FilesScriptHistoryStatus_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (default) | DEFAULT | Created defaults to getutcdate() |

---

## 8. Sample Queries

### 8.1 Get script with status
```sql
SELECT fsh.FileName, fss.ScriptStatusId, ds.Name AS Status, fss.Created
FROM Tribe.FilesScriptHistoryStatus fss WITH (NOLOCK)
JOIN Tribe.FilesScriptHistory fsh WITH (NOLOCK) ON fsh.Id = fss.FileScriptHistoryId
JOIN Dictionary.TribeScriptStatus ds WITH (NOLOCK) ON ds.Id = fss.ScriptStatusId
ORDER BY fss.Created DESC;
```

### 8.2 Find unapproved scripts
```sql
SELECT fsh.Id, fsh.FileName, fsh.IncludeSchemaUpdate, fss.Created
FROM Tribe.FilesScriptHistoryStatus fss WITH (NOLOCK)
JOIN Tribe.FilesScriptHistory fsh WITH (NOLOCK) ON fsh.Id = fss.FileScriptHistoryId
WHERE fss.ScriptStatusId = 0 ORDER BY fss.Created DESC;
```

### 8.3 Script workflow timeline
```sql
SELECT fss.FileScriptHistoryId, fss.ScriptStatusId, ds.Name, fss.Created
FROM Tribe.FilesScriptHistoryStatus fss WITH (NOLOCK)
JOIN Dictionary.TribeScriptStatus ds WITH (NOLOCK) ON ds.Id = fss.ScriptStatusId
WHERE fss.FileScriptHistoryId = 100 ORDER BY fss.Created;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.FilesScriptHistoryStatus | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.FilesScriptHistoryStatus.sql*
