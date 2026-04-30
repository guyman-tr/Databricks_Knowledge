# Tribe.FilesScriptHistory

> Stores the history of DDL and DML scripts generated for Tribe data file processing, including SQL scripts for schema creation and data insertion.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 3 active (+ PK) |

---

## 1. Business Meaning

FilesScriptHistory stores the SQL scripts generated during Tribe data file processing. When a new data file arrives from Tribe, the system generates DDL scripts (to create/update tables) and DML scripts (to insert data). Both scripts are stored here along with the file identifier and a flag indicating whether the schema needed updating.

This enables audit trail, replay capability, and the script approval workflow (via FilesScriptHistoryStatus). The AddUpdateScript procedure creates records here.

---

## 2. Business Logic

### 2.1 Script Generation and Approval Workflow

**What**: Records generated scripts and feeds them into the approval workflow.

**Columns/Parameters Involved**: `FileId`, `FileName`, `SqlScript`, `IncludeSchemaUpdate`, `InsertSqlScript`

**Rules**:
- SqlScript: DDL script for table schema creation/update
- InsertSqlScript: DML script for data insertion
- IncludeSchemaUpdate: 1 if schema changes are needed, 0 if data-only
- After insertion, AddUpdateScript also creates a FilesScriptHistoryStatus record
- Scripts go through: Unapproved -> Approved -> Executed workflow

---

## 3. Data Overview

N/A - script storage table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. Referenced by FilesScriptHistoryStatus. |
| 2 | FileId | bigint | NO | - | CODE-BACKED | Identifier of the Tribe data file that generated these scripts. |
| 3 | FileName | nvarchar(4000) | YES | - | CODE-BACKED | Name of the Tribe data file (e.g., JSON file name). |
| 4 | SqlScript | nvarchar(max) | YES | - | CODE-BACKED | DDL script for schema creation/update. May include CREATE TABLE or ALTER TABLE statements. |
| 5 | IncludeSchemaUpdate | bit | NO | - | CODE-BACKED | Whether this script includes schema changes. 1=DDL changes needed, 0=data insertion only. |
| 6 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | When this script record was created. |
| 7 | InsertSqlScript | nvarchar(max) | YES | - | CODE-BACKED | DML script for inserting data from the file into Tribe tables. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tribe.FilesScriptHistoryStatus | FileScriptHistoryId | Implicit FK | Status records reference script records |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Tribe.FilesScriptHistoryStatus | Table | References via FileScriptHistoryId |
| Tribe.AddUpdateScript | Stored Procedure | Inserts script + status records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FilesScriptHistory | CLUSTERED | Id ASC | - | - | Active |
| ix_FilesScriptHistory_Created | NONCLUSTERED | Created ASC | - | - | Active |
| ix_FilesScriptHistory_FileId | NONCLUSTERED | FileId ASC | - | - | Active |
| IX_FilesScriptHistoryCreated | NONCLUSTERED | Created DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (default) | DEFAULT | Created defaults to getutcdate() |

---

## 8. Sample Queries

### 8.1 View recent scripts
```sql
SELECT TOP 10 Id, FileId, FileName, IncludeSchemaUpdate, Created
FROM Tribe.FilesScriptHistory WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Find scripts for a specific file
```sql
SELECT * FROM Tribe.FilesScriptHistory WITH (NOLOCK) WHERE FileId = 12345;
```

### 8.3 Join with status to see approval state
```sql
SELECT fsh.Id, fsh.FileName, fsh.IncludeSchemaUpdate, fsh.Created,
       fss.ScriptStatusId, ds.Name AS Status
FROM Tribe.FilesScriptHistory fsh WITH (NOLOCK)
JOIN Tribe.FilesScriptHistoryStatus fss WITH (NOLOCK) ON fss.FileScriptHistoryId = fsh.Id
JOIN Dictionary.TribeScriptStatus ds WITH (NOLOCK) ON ds.Id = fss.ScriptStatusId
ORDER BY fsh.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.FilesScriptHistory | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.FilesScriptHistory.sql*
