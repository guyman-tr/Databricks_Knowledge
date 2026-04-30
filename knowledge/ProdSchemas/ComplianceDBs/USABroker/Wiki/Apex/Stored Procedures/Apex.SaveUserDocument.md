# Apex.SaveUserDocument

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveUserDocument.sql`  
**Author:** Alyona Makarova  
**Created:** 2021-09-03  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveUserDocument` registers a document in the context of a user's brokerage account onboarding or compliance process. Unlike `SaveInvestigationDocument` (which links documents to a compliance sketch), this procedure records documents attached directly to the user's account snapshot — such as identity documents, proof of address, and KYC supporting materials submitted during account opening.

It is called by the document-management service when a user uploads or a backend process captures a document that must be linked to the user's account record for submission to Apex Clearing or for internal compliance records.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID of the customer the document belongs to. |
| `@SnapId` | `uniqueidentifier` | No | GUID identifying the versioned document content snapshot in the document management system. |
| `@DocumentId` | `int` | No | ID of the document in the document management system. |
| `@UserDocumentTypeId` | `int` | No | Type code classifying the document (e.g., passport, utility bill). |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `UserDocument` | `Apex` | INSERT | Append-only; no duplicate check. |

---

## 5. Logic Flow

1. Single `INSERT INTO Apex.UserDocument (GCID, SnapID, DocumentID, UserDocumentTypeID) VALUES (...)`.
2. No existence check, no MERGE — pure append.

---

## 6. Error Handling

No explicit error handling. Constraint violations propagate to the caller.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.UserDocument` | Table | User document association store — INSERT target |

---

## 8. Usage Notes

- This procedure has **no duplicate detection**. Calling it twice with the same arguments creates two rows. Callers must implement idempotency if needed.
- `@SnapId` is a content-versioning GUID from an external document store — it identifies the specific revision of the document at the time of capture. It is not enforced as a foreign key within this database.
- `@UserDocumentTypeId` must reference a valid document type in the reference data; an invalid type will produce orphaned records that cannot be decoded by downstream systems.
- User documents registered here are separate from investigation documents (`Apex.InvestigationDocument`) — the former are account-level, the latter are sketch/investigation-level.
- No read procedure for this table is listed among the 49 in scope; use direct table queries or extend the API if retrieval is needed.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveUserDocument.sql` | Quality Score: 8.5/10*
