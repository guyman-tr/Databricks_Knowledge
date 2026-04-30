# Apex.SaveInvestigationDocument

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveInvestigationDocument.sql`  
**Author:** Alyona Makarova  
**Created:** 2021-08-02  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveInvestigationDocument` registers a document in the context of a compliance investigation sketch for a specific customer. Each call records one document association: which customer it belongs to, which sketch it supports, which content snapshot it references, and what type of document it is. Multiple documents of different types can be linked to a single sketch by calling this procedure once per document.

It is called by the investigation-management service when a new document is attached to a compliance sketch — for example, when a customer submits identity verification, proof of address, or other supporting documentation during an Apex account review.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID of the customer the document belongs to. |
| `@SketchId` | `uniqueidentifier` | No | GUID of the compliance investigation sketch this document supports. |
| `@SnapId` | `uniqueidentifier` | No | GUID identifying the versioned document content snapshot in the document management system. |
| `@DocumentId` | `int` | No | ID of the document in the document management system. |
| `@DocumentTypeId` | `int` | No | Type code classifying the document (e.g., passport, bank statement). |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `InvestigationDocument` | `Apex` | INSERT | Append-only; no check for duplicates before inserting. |

---

## 5. Logic Flow

1. Single `INSERT INTO Apex.InvestigationDocument` with all five provided columns: `GCID`, `SketchID`, `SnapID`, `DocumentID`, `DocumentTypeID`.
2. The `ID` column is an identity; it is not returned.

No existence check, no MERGE, no duplicate prevention — this is a pure append operation. Multiple rows with the same `GCID + SketchID + DocumentTypeID` can be inserted.

---

## 6. Error Handling

No explicit error handling. Constraint violations (e.g., foreign key failures) propagate to the caller.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.InvestigationDocument` | Table | Append target |
| `Apex.GetInvestigationDocuments` | Stored Procedure | Reads the documents inserted here |

---

## 8. Usage Notes

- This procedure has **no duplicate detection** — calling it twice with the same arguments will create two rows. Callers are responsible for ensuring idempotency if required.
- `@SnapId` references a versioned content snapshot in an external document store; it is not a foreign key in this database but must be a valid snapshot GUID for downstream processing.
- `@DocumentTypeId` references a document-type lookup table; ensure the value is valid before calling to avoid orphaned records.
- Documents inserted here are readable via `Apex.GetInvestigationDocuments` by providing the same `GCID` + `SketchID`.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveInvestigationDocument.sql` | Quality Score: 8.5/10*
