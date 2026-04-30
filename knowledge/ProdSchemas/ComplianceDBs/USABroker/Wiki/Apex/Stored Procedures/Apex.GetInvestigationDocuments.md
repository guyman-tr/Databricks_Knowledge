# Apex.GetInvestigationDocuments

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetInvestigationDocuments.sql`  
**Author:** Alyona Makarova  
**Created:** 2021-08-02  
**Ticket:** COAKV-3021  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetInvestigationDocuments` retrieves the set of documents attached to a compliance investigation sketch for a specific user. Investigations may involve multiple document types (identity proofs, financial statements, compliance notes); this procedure returns all documents associated with a particular sketch snapshot (`SketchID`) for a given customer (`GCID`).

It is used by the compliance workflow services when assembling the document package for a sketch review — either to display to a compliance officer, to validate completeness before submitting to Apex, or to pass to a downstream document-processing pipeline.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID identifying the user whose investigation documents are requested. |
| `@SketchId` | `uniqueidentifier` | No | The GUID identifying the specific sketch (compliance investigation snapshot) to retrieve documents for. |

---

## 3. Result Sets

**Result Set 1 – Investigation Document Records**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `ID` | `Apex.InvestigationDocument` | Surrogate primary key of the document association record. |
| `GCID` | `Apex.InvestigationDocument` | Global Customer ID (echoed). |
| `SketchID` | `Apex.InvestigationDocument` | The investigation sketch GUID (echoed). |
| `SnapID` | `Apex.InvestigationDocument` | GUID identifying the document content snapshot. |
| `DocumentID` | `Apex.InvestigationDocument` | ID of the document in the document management system. |
| `DocumentTypeID` | `Apex.InvestigationDocument` | Numeric type code classifying the document (e.g., ID proof, address proof). |

Returns 0 rows if no documents are associated with the given GCID + SketchID combination.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `InvestigationDocument` | `Apex` | SELECT | Read with `NOLOCK`; compound filter on `GCID` + `SketchID`. |

---

## 5. Logic Flow

1. `NOLOCK` read on `Apex.InvestigationDocument`.
2. Filters by `GCID = @GCID AND SketchID = @SketchId`.
3. Returns all six columns for each matching document record.

A single sketch may have multiple documents (one per `DocumentTypeID`). All matching rows are returned.

---

## 6. Error Handling

No explicit error handling. An empty result set indicates no documents are registered for the sketch.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.InvestigationDocument` | Table | Only data source |
| `Apex.SaveInvestigationDocument` | Stored Procedure | Companion writer; inserts the records returned here |

---

## 8. Usage Notes

- The `SketchID` is a GUID assigned when the compliance sketch is created; it uniquely identifies one investigation snapshot for a user.
- `SnapID` links to the versioned document content store (a different system); it identifies the exact revision of a document at the time of the sketch.
- Multiple rows may be returned for the same sketch if the investigation required several different document types.
- `NOLOCK` is safe here because investigation documents are append-only (inserted once, never updated).

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetInvestigationDocuments.sql` | Quality Score: 8.5/10*
