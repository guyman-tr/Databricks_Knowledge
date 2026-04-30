# BackOffice.InsertCustomerNote

> Inserts a new customer note (subject + body) into BackOffice.CustomerNotes - used by BI admin tools to record notes on customer accounts.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid (customer ID); no return value |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`InsertCustomerNote` creates a new free-text note on a customer record in `BackOffice.CustomerNotes`. Notes are used by Back Office staff to record observations, decisions, or actions taken on a customer account - for example, "Customer called to dispute withdrawal" or "Manual verification completed by compliance team."

The procedure was created in September 2014 (TRAD\AlonNa) and is one of the oldest procedures in the BackOffice schema. It performs a simple INSERT with no validation, duplicate check, or GCID resolution - the caller supplies CID directly and provides both creation and modification timestamps explicitly (allowing back-dated imports from BI tooling).

Called by `PROD_BIadmins` - the BI admin user group with elevated privileges for bulk data operations.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID for the note. Maps to `BackOffice.CustomerNotes.CID`. |
| 2 | @createdOn | SMALLDATETIME | NO | - | CODE-BACKED | Timestamp when the note was originally created. The caller provides this explicitly, allowing historical notes to be imported with the original creation date. |
| 3 | @lastModifiedOn | SMALLDATETIME | NO | - | CODE-BACKED | Timestamp of last modification. On initial insert, typically equal to @createdOn. |
| 4 | @createdBy | NVARCHAR(160) | NO | - | CODE-BACKED | Username or display name of the person who created the note. Free text - not validated against BackOffice.Manager. |
| 5 | @lastModifiedBy | NVARCHAR(160) | NO | - | CODE-BACKED | Username of the last person to modify the note. On initial insert, typically equal to @createdBy. |
| 6 | @subject | NVARCHAR(500) | NO | - | CODE-BACKED | Short summary title of the note, shown in note list views. |
| 7 | @body | NTEXT | NO | - | CODE-BACKED | Full text content of the note. Uses the legacy `ntext` type (deprecated in SQL Server but still functional). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @cid | BackOffice.CustomerNotes | Writer | Inserts a new note record for this customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | @cid | Caller | BI admin group uses this for bulk note imports and Back Office data operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.InsertCustomerNote (procedure)
└── BackOffice.CustomerNotes (table) [INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerNotes | Table | INSERT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | External user/group | BI admin operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No NOCOUNT | Omission | SET NOCOUNT ON is NOT present - row count is returned to caller |
| No TRY/CATCH | Omission | Errors propagate directly to the caller |
| No validation | Design | No CID existence check; if CID does not exist in Customer.CustomerStatic, the note is still inserted (BackOffice.CustomerNotes may not have a FK constraint to CustomerStatic) |

---

## 8. Sample Queries

### 8.1 Insert a note for a customer

```sql
EXEC [BackOffice].[InsertCustomerNote]
    @cid = 123456,
    @createdOn = '2026-03-18 10:00:00',
    @lastModifiedOn = '2026-03-18 10:00:00',
    @createdBy = N'john.smith',
    @lastModifiedBy = N'john.smith',
    @subject = N'KYC Review Completed',
    @body = N'Manual KYC review completed. All documents verified. No issues found.';
```

### 8.2 Read notes for a customer

```sql
SELECT
    NoteID,
    CID,
    Subject,
    CAST(Body AS NVARCHAR(MAX)) AS Body,
    CreatedBy,
    CreatedOn,
    LastModifiedBy,
    LastModifiedOn
FROM BackOffice.CustomerNotes WITH (NOLOCK)
WHERE CID = 123456
ORDER BY CreatedOn DESC;
```

### 8.3 Find recent notes by a specific author

```sql
SELECT TOP 10
    CID,
    Subject,
    CreatedOn
FROM BackOffice.CustomerNotes WITH (NOLOCK)
WHERE CreatedBy = N'john.smith'
  AND CreatedOn >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY CreatedOn DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 9.0/10, Logic: 5.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: PROD_BIadmins caller | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.InsertCustomerNote | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.InsertCustomerNote.sql*
