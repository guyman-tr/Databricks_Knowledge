# BackOffice.CustomerNotes

> Free-text note repository for BackOffice agents to attach subject/body notes to customer accounts. Functionally dormant - contains 1 row (2016) and has seen no activity since.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | NoteID (INT IDENTITY, NONCLUSTERED PK) |
| **Partition** | No (heap with NC PK, stored ON [PRIMARY]) |
| **Indexes** | 2 active (1 NC PK + 1 NC on CID) |

---

## 1. Business Meaning

BackOffice.CustomerNotes is a simple customer note-taking system designed to allow BackOffice agents to attach freeform notes (subject + body) to customer accounts. Each row represents one note with a subject line, body text, creation/modification timestamps, and the agent's name.

The table was created in September 2014 (based on procedure comment) and has only 1 row in production (dated 2016-10-05). It is effectively dormant - the note-taking feature in BackOffice is unused or was superseded by another system (e.g., Zendesk, Salesforce notes, or BackOffice task tracking). The table and its CRUD procedures remain in place but no agent activity is occurring.

---

## 2. Business Logic

### 2.1 Simple CRUD Note-Taking

**What**: Notes can be created (InsertCustomerNote) and updated (UpdateCustomerNote) per customer. No delete procedure exists.

**Columns Involved**: All columns

**Rules**:
- InsertCustomerNote: Inserts a new note for a CID. CreatedBy and LastModifiedBy are passed as free-text agent names (not ManagerID integers).
- UpdateCustomerNote: Updates subject, body, LastModifiedOn, LastModifiedBy for an existing NoteID.
- GetCustomerNotes: Returns all notes for a given CID.
- Occurred column: Set via DEFAULT to GETUTCDATE() at INSERT time. Not included in InsertCustomerNote parameters - represents server-side row creation time.
- CreatedOn: Set by the calling application from client-side time (@createdOn parameter).
- No FK on CreatedBy/LastModifiedBy - agent identification by name string only.

---

## 3. Data Overview

Only 1 row exists in production (as of 2026-03-17), dated 2016-10-05. The table is functionally inactive.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NoteID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-incrementing note identifier. NONCLUSTERED PK - table is a heap. NOT FOR REPLICATION flag set. |
| 2 | CID | int | NO | - | VERIFIED | Customer account ID the note is attached to. NC index for lookup by customer. Implicit FK to Customer.CustomerStatic.CID. |
| 3 | CreatedOn | smalldatetime | YES | - | CODE-BACKED | When the note was created (client-supplied timestamp, smalldatetime precision = 1-minute resolution). Passed by the application at INSERT time. |
| 4 | LastModifiedOn | smalldatetime | YES | - | CODE-BACKED | When the note was last edited (client-supplied, updated on each edit). Same precision as CreatedOn. |
| 5 | CreatedBy | nvarchar(160) | NO | - | CODE-BACKED | Display name of the BackOffice agent who created the note. Free-text string - not a ManagerID FK. Older design pattern. |
| 6 | LastModifiedBy | nvarchar(160) | NO | - | CODE-BACKED | Display name of the agent who last modified the note. Same free-text pattern as CreatedBy. |
| 7 | Subject | nvarchar(500) | YES | - | CODE-BACKED | Short title/headline of the note. Nullable - one record has a subject. |
| 8 | Body | ntext | YES | - | CODE-BACKED | Full note text content. Uses deprecated ntext type (pre-SQL Server 2005 era - modern equivalent would be nvarchar(MAX)). Stored in TEXTIMAGE_ON [PRIMARY]. Average body length from the single row: 13 characters. |
| 9 | Occurred | datetime | YES | GETUTCDATE() | CODE-BACKED | Server-side timestamp set at INSERT time (DEFAULT GETUTCDATE()). Not passed via InsertCustomerNote procedure - records when the database row was created. Distinct from CreatedOn (client time). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit FK | Customer account link |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.InsertCustomerNote | CID, NoteID | WRITER | Creates new notes |
| BackOffice.UpdateCustomerNote | NoteID | MODIFIER | Updates existing notes |
| BackOffice.GetCustomerNotes | CID | READER | Returns all notes for a customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerNotes (table)
- No FK constraints
- Leaf table
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Implicit CID scope |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.InsertCustomerNote | Procedure | WRITER |
| BackOffice.UpdateCustomerNote | Procedure | MODIFIER |
| BackOffice.GetCustomerNotes | Procedure | READER |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerNotes_NoteID | NONCLUSTERED PK | NoteID ASC | - | - | Active |
| IX_CustomerNotes_CID | NC | CID ASC | - | - | Active |

**Storage**: Heap (no clustered index). NC PK on NoteID. TEXTIMAGE_ON [PRIMARY] for ntext Body column.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CustomerNotes_NoteID | PK (NC) | NoteID uniqueness |
| (unnamed) DEFAULT | DEFAULT | Occurred = GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Get all notes for a customer
```sql
SELECT
    n.NoteID,
    n.Subject,
    CAST(n.Body AS NVARCHAR(MAX)) AS Body,
    n.CreatedBy,
    n.CreatedOn,
    n.LastModifiedBy,
    n.LastModifiedOn
FROM BackOffice.CustomerNotes n WITH (NOLOCK)
WHERE n.CID = 12345
ORDER BY n.CreatedOn DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.8/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerNotes | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CustomerNotes.sql*
