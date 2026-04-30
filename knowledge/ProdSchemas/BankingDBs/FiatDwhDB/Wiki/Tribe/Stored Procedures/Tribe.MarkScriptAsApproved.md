# Tribe.MarkScriptAsApproved

> Simple procedure that transitions a script to Approved status (ScriptStatusId=1) by inserting a new status record.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into FilesScriptHistoryStatus with StatusId=1 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MarkScriptAsApproved transitions a Tribe schema script from Unapproved to Approved by inserting ScriptStatusId=1 into FilesScriptHistoryStatus. Part of the Unapproved(0) -> Approved(1) -> Executed(2) workflow.

---

## 2. Business Logic

Simple INSERT with hardcoded StatusId=1.

---

## 3. Data Overview

N/A.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @scriptId | bigint | NO | - | CODE-BACKED | FilesScriptHistory.Id to approve. |

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

### 8.1 Approve a script
```sql
EXEC Tribe.MarkScriptAsApproved @scriptId = 100;
```

### 8.2 Verify
```sql
SELECT ScriptStatusId, Created FROM Tribe.FilesScriptHistoryStatus WITH (NOLOCK)
WHERE FileScriptHistoryId = 100 ORDER BY Created DESC;
```

### 8.3 Full workflow
```sql
-- Step 1: Add script (returns ScriptId)
EXEC Tribe.AddUpdateScript @fileName='test.json', @fileId=1, @script='...', @schemaIsUpdated=1, @scriptStatusId=0;
-- Step 2: Approve
EXEC Tribe.MarkScriptAsApproved @scriptId = 100;
-- Step 3: Execute
EXEC Tribe.MarkScriptAsExecuted @scriptId = 100;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.MarkScriptAsApproved | Type: Stored Procedure*
