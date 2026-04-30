# Tribe.MarkScriptAsExecuted

> Simple procedure that transitions a script to Executed status (ScriptStatusId=2) by inserting a new status record.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into FilesScriptHistoryStatus with StatusId=2 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MarkScriptAsExecuted marks a Tribe schema script as successfully executed by inserting ScriptStatusId=2 into FilesScriptHistoryStatus. Final step: Unapproved(0) -> Approved(1) -> Executed(2). After this, IsSchemaAlligned returns 1.

---

## 2. Business Logic

Simple INSERT with hardcoded StatusId=2.

---

## 3. Data Overview

N/A.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @scriptId | bigint | NO | - | CODE-BACKED | FilesScriptHistory.Id to mark as executed. |

---

## 5. Relationships

Writes: FilesScriptHistoryStatus.

---

## 6. Dependencies

Depends on: FilesScriptHistoryStatus.

---

## 7-9. Standard SP sections.

---

## 8. Sample Queries

### 8.1 Mark as executed
```sql
EXEC Tribe.MarkScriptAsExecuted @scriptId = 100;
```

### 8.2 Verify
```sql
SELECT ScriptStatusId, ds.Name, Created FROM Tribe.FilesScriptHistoryStatus WITH (NOLOCK)
JOIN Dictionary.TribeScriptStatus ds WITH (NOLOCK) ON ds.Id = ScriptStatusId
WHERE FileScriptHistoryId = 100 ORDER BY Created DESC;
```

### 8.3 Check schema is now aligned
```sql
EXEC Tribe.IsSchemaAlligned;
-- Should return 1 after execution
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.MarkScriptAsExecuted | Type: Stored Procedure*
