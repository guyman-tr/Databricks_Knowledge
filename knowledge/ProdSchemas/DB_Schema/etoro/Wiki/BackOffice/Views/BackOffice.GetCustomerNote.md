# BackOffice.GetCustomerNote

> Enriched customer notes view joining History.CustomerNote with manager names and note type labels for display in the back-office customer profile.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | (CID, RegistrationRequestID) from History.CustomerNote |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.GetCustomerNote` presents customer notes (back-office annotations added during customer management) with human-readable manager names and note type labels, by joining three source tables:

1. **History.CustomerNote** (`HCNT`): The note records themselves - one row per note per customer, with CID, ManagerID (who wrote it), NoteTypeID, the note text, occurrence timestamp, and RegistrationRequestID.

2. **BackOffice.Manager** (`BMNG`): Resolves `ManagerID` to a display name (`FirstName + ' ' + LastName`).

3. **Dictionary.NoteType** (`DCNT`): Resolves `NoteTypeID` to a human-readable category name (e.g., "General", "KYC", "Risk").

The view uses INNER JOINs for both Manager and NoteType (via implicit WHERE clause syntax), meaning notes with a NULL or invalid ManagerID or NoteTypeID will NOT appear in results. This ensures all returned notes have valid attribution.

---

## 2. Business Logic

### 2.1 Note Display Enrichment

**What**: Enriches raw note records with manager display name and type label.

**Columns Involved**: All output columns

**Rules**:
- `WHERE HCNT.ManagerID = BMNG.ManagerID` - INNER JOIN on Manager. Notes written by non-existent managers are excluded.
- `WHERE DCNT.NoteTypeID = HCNT.NoteTypeID` - INNER JOIN on NoteType. Notes with invalid NoteTypeID are excluded.
- ManagerName is composed as `FirstName + ' ' + LastName` - no null-guard. If either is NULL, the concatenation returns NULL.
- All notes for all customers returned - no CID filter. Callers must filter by CID.

---

## 3. Data Overview

Row count matches History.CustomerNote rows that have valid ManagerID and NoteTypeID references.

---

## 4. Elements

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | CID | int | CODE-BACKED | Customer ID whose note this is. FK to Customer.Customer.CID. |
| 2 | RegistrationRequestID | int | CODE-BACKED | Registration request associated with the note, if applicable. From History.CustomerNote. |
| 3 | ManagerName | nvarchar | CODE-BACKED | Full name of the back-office manager who wrote the note. Composed as FirstName + ' ' + LastName from BackOffice.Manager. |
| 4 | Note | nvarchar | CODE-BACKED | The note text content written by the manager. Free-form text. |
| 5 | NoteType | nvarchar | CODE-BACKED | Category of the note (e.g., "General", "KYC", "Risk"). From Dictionary.NoteType.Name. |
| 6 | Occurred | datetime | CODE-BACKED | Timestamp when the note was created/applied. From History.CustomerNote.Occurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, Note, Occurred | History.CustomerNote | Base Table | Source of note records |
| ManagerName | BackOffice.Manager | INNER JOIN | Resolves ManagerID to manager display name |
| NoteType | Dictionary.NoteType | INNER JOIN | Resolves NoteTypeID to note category label |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No BackOffice SP consumers identified in SSDT repo) | - | - | Note: BackOffice.GetCustomerNotes SP queries BackOffice.CustomerNotes (different table), not this view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerNote (view)
+-- History.CustomerNote (cross-schema)
+-- BackOffice.Manager
+-- Dictionary.NoteType (cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CustomerNote | Table (cross-schema) | Base note data source |
| BackOffice.Manager | Table | INNER JOIN - resolves ManagerID to display name |
| Dictionary.NoteType | Table (cross-schema) | INNER JOIN - resolves NoteTypeID to category name |

### 6.2 Objects That Depend On This

No stored procedure consumers identified in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. History.CustomerNote should have an index on CID for efficient per-customer queries.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Get all notes for a customer

```sql
SELECT ManagerName, NoteType, Note, Occurred
FROM BackOffice.GetCustomerNote WITH (NOLOCK)
WHERE CID = 12345
ORDER BY Occurred DESC;
```

### 8.2 Find KYC notes added recently

```sql
SELECT CID, ManagerName, Note, Occurred
FROM BackOffice.GetCustomerNote WITH (NOLOCK)
WHERE NoteType = 'KYC'
  AND Occurred >= DATEADD(DAY, -7, GETDATE())
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this view.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11 (DDL, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerNote | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.GetCustomerNote.sql*
