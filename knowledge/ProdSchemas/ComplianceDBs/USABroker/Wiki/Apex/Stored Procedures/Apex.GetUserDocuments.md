# Apex.GetUserDocuments

> Retrieves all user-uploaded documents for a customer by GCID, returning document metadata including type, storage snapshot ID, and document ID.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns UserDocument rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Apex.GetUserDocuments retrieves all documents uploaded by a specific customer from the UserDocument table. Returns the document metadata (ID, SnapID, DocumentID, UserDocumentTypeID) needed to locate and classify each uploaded file. Used by the account management UI and the Apex API integration to know what documents are on file.

---

## 2. Business Logic

No complex business logic. Simple SELECT by GCID with NOLOCK.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID to retrieve documents for. |

**Returns**: ID, GCID, SnapID, DocumentID, UserDocumentTypeID from Apex.UserDocument.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Apex.UserDocument | Read | Retrieves all documents by GCID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.GetUserDocuments (procedure)
└── Apex.UserDocument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Apex.UserDocument | Table | Read by GCID |

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

### 8.1 Get all documents for a customer

```sql
EXEC Apex.GetUserDocuments @GCID = 46229773;
```

### 8.2 Get documents for debugging

```sql
EXEC Apex.GetUserDocuments @GCID = 47547564;
-- Returns affiliated approval documents
```

### 8.3 Verify document upload

```sql
EXEC Apex.GetUserDocuments @GCID = 12345;
-- Check if expected documents are present
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.GetUserDocuments | Type: Stored Procedure | Source: USABroker/Apex/Stored Procedures/Apex.GetUserDocuments.sql*
