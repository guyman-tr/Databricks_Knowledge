# Tribe.AddUpdateScript

> Compound procedure that inserts a new script into FilesScriptHistory and creates an initial status record in FilesScriptHistoryStatus in a single operation.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into FilesScriptHistory + INSERT into FilesScriptHistoryStatus |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddUpdateScript is the entry point for the Tribe script management workflow. When a new Tribe data file generates DDL/DML scripts, this procedure stores both the script (in FilesScriptHistory) and creates an initial status record (in FilesScriptHistoryStatus) with the provided @scriptStatusId (typically 0=Unapproved). Uses OUTPUT INSERTED to capture the new script Id. Returns the ScriptId.

---

## 2. Business Logic

### 2.1 Compound Insert

**Rules**:
- INSERT into FilesScriptHistory with OUTPUT to capture new Id
- Immediately INSERT status into FilesScriptHistoryStatus with captured Id
- Returns ScriptId for caller reference

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fileName | nvarchar(max) | NO | - | CODE-BACKED | Source data file name. |
| 2 | @fileId | bigint | NO | - | CODE-BACKED | Source file identifier. |
| 3 | @script | nvarchar(max) | NO | - | CODE-BACKED | DDL script content. |
| 4 | @schemaIsUpdated | bit | NO | - | CODE-BACKED | Whether script includes schema changes. |
| 5 | @scriptStatusId | tinyint | NO | - | CODE-BACKED | Initial status (0=Unapproved). |
| 6 | @insertScript | nvarchar(max) | YES | NULL | CODE-BACKED | DML insert script (optional). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | Tribe.FilesScriptHistory | Write | Script storage |
| INSERT | Tribe.FilesScriptHistoryStatus | Write | Initial status |

### 5.2 Referenced By (other objects point to this)

Not analyzed.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.AddUpdateScript (procedure)
├── Tribe.FilesScriptHistory (table)
└── Tribe.FilesScriptHistoryStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.FilesScriptHistory | Table | INSERT target |
| Tribe.FilesScriptHistoryStatus | Table | Status INSERT target |

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

### 8.1 Add a script
```sql
EXEC Tribe.AddUpdateScript @fileName = 'AccountsActivities_2026-04-14.json',
    @fileId = 12345, @script = 'CREATE TABLE ...', @schemaIsUpdated = 1,
    @scriptStatusId = 0, @insertScript = 'INSERT INTO ...';
```

### 8.2 Verify
```sql
SELECT TOP 1 * FROM Tribe.FilesScriptHistory WITH (NOLOCK) ORDER BY Created DESC;
SELECT TOP 1 * FROM Tribe.FilesScriptHistoryStatus WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.3 Check script with status
```sql
SELECT fsh.FileName, fss.ScriptStatusId, ds.Name FROM Tribe.FilesScriptHistory fsh WITH (NOLOCK)
JOIN Tribe.FilesScriptHistoryStatus fss WITH (NOLOCK) ON fss.FileScriptHistoryId = fsh.Id
JOIN Dictionary.TribeScriptStatus ds WITH (NOLOCK) ON ds.Id = fss.ScriptStatusId
ORDER BY fsh.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Object: Tribe.AddUpdateScript | Type: Stored Procedure | Source: FiatDwhDB/Tribe/Stored Procedures/Tribe.AddUpdateScript.sql*
