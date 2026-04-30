# Tribe.IsSchemaAlligned

> Health check procedure that verifies whether the latest Tribe schema script has been approved/executed. Returns 1 (aligned) or 0 (not aligned).

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1/0 based on latest script status |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

IsSchemaAlligned (note: typo "Alligned" preserved) checks if the Tribe schema is in a healthy state by examining the latest script's status. Gets the MAX(Id) from FilesScriptHistory, then checks if the latest status for that script is Approved(1) or Executed(2) -> returns 1 (aligned). If Unapproved(0) -> returns 0 (not aligned). Used as a gate before processing new Tribe data files.

---

## 2. Business Logic

### 2.1 Schema Alignment Check

**Rules**:
- Gets MAX(Id) from FilesScriptHistory (the most recent script)
- Gets TOP 1 status for that script (latest by Created)
- If ScriptStatusId = 1 (Approved) or 2 (Executed) -> IsSchemaAlligned = 1
- If ScriptStatusId = 0 (Unapproved) -> IsSchemaAlligned = 0
- @StartDate parameter exists but the original CTE logic is commented out

---

## 3. Data Overview

N/A.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | datetime2 | YES | NULL | CODE-BACKED | Optional date filter (currently unused - original CTE logic commented out). |

---

## 5. Relationships

Reads: FilesScriptHistory, FilesScriptHistoryStatus.

---

## 6. Dependencies

Depends on: FilesScriptHistory, FilesScriptHistoryStatus.

---

## 7-9. Standard SP sections.

---

## 8. Sample Queries

### 8.1 Check alignment
```sql
EXEC Tribe.IsSchemaAlligned;
-- Returns 1 = aligned (safe to process), 0 = pending scripts need attention
```

### 8.2 Manual check
```sql
DECLARE @MaxId BIGINT = (SELECT MAX(Id) FROM Tribe.FilesScriptHistory);
SELECT TOP 1 ScriptStatusId, ds.Name FROM Tribe.FilesScriptHistoryStatus WITH (NOLOCK)
JOIN Dictionary.TribeScriptStatus ds WITH (NOLOCK) ON ds.Id = ScriptStatusId
WHERE FileScriptHistoryId = @MaxId ORDER BY Created DESC;
```

### 8.3 Find unapproved scripts blocking alignment
```sql
SELECT fsh.Id, fsh.FileName, fss.ScriptStatusId FROM Tribe.FilesScriptHistory fsh WITH (NOLOCK)
CROSS APPLY (SELECT TOP 1 ScriptStatusId FROM Tribe.FilesScriptHistoryStatus WITH (NOLOCK)
WHERE FileScriptHistoryId = fsh.Id ORDER BY Created DESC) fss
WHERE fss.ScriptStatusId = 0 ORDER BY fsh.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.2/10*
*Object: Tribe.IsSchemaAlligned | Type: Stored Procedure*
