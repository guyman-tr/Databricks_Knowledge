# BackOffice.GetCustomerNotes

> Returns all columns from BackOffice.CustomerNotes for a given customer: note subject, body, creation/modification timestamps, and agent display names.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid - single customer lookup |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice agents can attach freeform notes (subject + body) to customer accounts using the note-taking feature in the BackOffice UI. This procedure retrieves all notes attached to a given customer so the agent can review prior annotations made by themselves or colleagues.

Each note records who created it and who last modified it by display name (not ManagerID), along with client-supplied timestamps for creation and last modification. The Body field uses the legacy `ntext` type (pre-SQL Server 2005 era).

Created September 2014 (AlonNa). The underlying table (`BackOffice.CustomerNotes`) contains only 1 row in production (from 2016), indicating the feature is functionally dormant - note-taking in BackOffice is either unused or has been superseded by an external system (e.g., Zendesk or Salesforce). The procedure and table remain in place for compatibility.

No ORDER BY is applied; the single existing production row means ordering is not observable in practice.

---

## 2. Business Logic

### 2.1 Single-Customer All-Notes Retrieval

**What**: Returns every note for the customer with no filtering or pagination.

**Rules**:
- `WHERE CID = @cid` - all notes for this customer
- No ORDER BY - results are in heap insertion order
- No status/soft-delete filter - all rows are returned

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Matched against BackOffice.CustomerNotes.CID (NC indexed). |
| **Output Columns** | | | | | | |
| 2 | NoteID | INT | NO | - | CODE-BACKED | Auto-incrementing note identifier. PK of BackOffice.CustomerNotes. |
| 3 | CID | INT | NO | - | CODE-BACKED | Customer account ID the note is attached to. Same as @cid input. |
| 4 | CreatedOn | SMALLDATETIME | YES | - | CODE-BACKED | When the note was created (client-supplied timestamp, 1-minute resolution). |
| 5 | LastModifiedOn | SMALLDATETIME | YES | - | CODE-BACKED | When the note was last edited (client-supplied, updated on each change). |
| 6 | CreatedBy | NVARCHAR(160) | NO | - | CODE-BACKED | Display name of the BackOffice agent who created the note. Free-text string - not a ManagerID FK. |
| 7 | LastModifiedBy | NVARCHAR(160) | NO | - | CODE-BACKED | Display name of the agent who last modified the note. Same free-text naming pattern as CreatedBy. |
| 8 | Subject | NVARCHAR(500) | YES | - | CODE-BACKED | Short title/headline of the note. |
| 9 | Body | NTEXT | YES | - | CODE-BACKED | Full note text. Legacy ntext type (modern equivalent: nvarchar(MAX)). Cast to NVARCHAR(MAX) when processing in application code. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | BackOffice.CustomerNotes | Direct READ | All notes for the given CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Notes tab in customer profile |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerNotes (procedure)
+-- BackOffice.CustomerNotes (all notes for CID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerNotes | Table | Source of all note rows for the given customer |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Notes tab in customer profile - display all agent-written notes |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `WITH(NOLOCK)` on BackOffice.CustomerNotes.
- Explicit column list (no `SELECT *`): NoteID, CID, CreatedOn, LastModifiedOn, CreatedBy, LastModifiedBy, Subject, Body.

---

## 8. Sample Queries

### 8.1 Get all notes for a customer

```sql
EXEC BackOffice.GetCustomerNotes @cid = 12345678;
```

### 8.2 Direct base-table query

```sql
SELECT NoteID, CID, CreatedOn, LastModifiedOn, CreatedBy, LastModifiedBy, Subject, Body
FROM BackOffice.CustomerNotes WITH(NOLOCK)
WHERE CID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira records found for this procedure.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerNotes | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerNotes.sql*
