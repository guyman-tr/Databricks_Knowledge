# BackOffice.UpdateCustomerNote

> Updates the content and modification metadata of an existing free-text customer note in the BackOffice note-taking system.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @noteId + @cid - targets BackOffice.CustomerNotes by NoteID and CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UpdateCustomerNote` edits an existing note in the `BackOffice.CustomerNotes` system - updating its subject, body, and modification metadata (who last changed it and when). The CID is included in the WHERE clause as an ownership check to prevent a note being modified using the wrong customer context.

The procedure is part of a three-operation CRUD system (Insert/Update/Get) for BackOffice.CustomerNotes. In practice, this feature is functionally dormant: the CustomerNotes table contains only 1 row (dated 2016) and has seen no activity since. The note-taking function was likely superseded by Zendesk, Salesforce, or internal ticketing.

---

## 2. Business Logic

### 2.1 Note Ownership Verification

**What**: Both NoteID and CID must match to allow the update, preventing cross-customer note modification.

**Columns/Parameters Involved**: `@noteId`, `@cid`

**Rules**:
- `WHERE NoteID = @noteId AND CID = @cid`: the CID check ensures a note can only be updated in the context of the correct customer. If CID is wrong, the UPDATE silently matches 0 rows.
- No error is raised if rows affected = 0 (NoteID not found or CID mismatch).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @noteId | int | NO | - | CODE-BACKED | NoteID of the note to update. Matches BackOffice.CustomerNotes.NoteID (NONCLUSTERED PK). Combined with @cid for ownership verification. |
| 2 | @cid | int | NO | - | CODE-BACKED | Customer ID. Must match the CID stored on the note to allow the update (ownership check). Prevents updating a note under the wrong customer context. |
| 3 | @lastModifiedOn | smalldatetime | NO | - | CODE-BACKED | Client-supplied timestamp of when the note was last edited. Written to BackOffice.CustomerNotes.LastModifiedOn (smalldatetime, 1-minute resolution). |
| 4 | @lastModifiedBy | nvarchar(160) | NO | - | CODE-BACKED | Display name of the BackOffice agent making the edit. Free-text string (not a ManagerID integer). Written to BackOffice.CustomerNotes.LastModifiedBy. |
| 5 | @subject | nvarchar(500) | NO | - | CODE-BACKED | Updated subject/headline of the note. Written to BackOffice.CustomerNotes.Subject. |
| 6 | @body | ntext | NO | - | CODE-BACKED | Updated full body text of the note. Written to BackOffice.CustomerNotes.Body. Note: ntext is a deprecated data type (pre-SQL Server 2005). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @noteId / @cid | [BackOffice.CustomerNotes](../Tables/BackOffice.CustomerNotes.md) | UPDATE target | Updates the note identified by NoteID AND CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No direct callers found in BackOffice SPs. | - | - | Called from the back-office UI note editor (functionally dormant since 2016). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpdateCustomerNote (procedure)
+-- BackOffice.CustomerNotes (table) [UPDATE target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [BackOffice.CustomerNotes](../Tables/BackOffice.CustomerNotes.md) | Table | UPDATE target - sets LastModifiedOn, LastModifiedBy, Subject, Body WHERE NoteID=@noteId AND CID=@cid |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo. | - | Called from back-office application. Table functionally dormant (1 row, last activity 2016). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update note subject and body

```sql
EXEC BackOffice.UpdateCustomerNote
    @noteId         = 1,
    @cid            = 12345,
    @lastModifiedOn = '2026-03-18 10:00:00',
    @lastModifiedBy = N'John Smith',
    @subject        = N'Updated: Account inquiry follow-up',
    @body           = N'Customer contacted support again regarding...';
```

### 8.2 Verify note content after update

```sql
SELECT
    NoteID,
    CID,
    Subject,
    CAST(Body AS NVARCHAR(MAX)) AS Body,
    LastModifiedBy,
    LastModifiedOn
FROM BackOffice.CustomerNotes WITH (NOLOCK)
WHERE NoteID = 1 AND CID = 12345;
```

### 8.3 Retrieve all notes for a customer

```sql
SELECT
    NoteID,
    Subject,
    CAST(Body AS NVARCHAR(MAX)) AS Body,
    CreatedBy,
    CreatedOn,
    LastModifiedBy,
    LastModifiedOn
FROM BackOffice.CustomerNotes WITH (NOLOCK)
WHERE CID = 12345
ORDER BY CreatedOn DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Dependency Inheritance, Caller Scan, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpdateCustomerNote | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpdateCustomerNote.sql*
