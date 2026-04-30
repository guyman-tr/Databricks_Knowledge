# Apex.InvestigationDocument

> Tracks identity verification documents submitted during Sketch CIP (Customer Identification Program) investigations, linking each document to a specific investigation snapshot and document type.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) + 2 nonclustered (GCID, SketchID) |

---

## 1. Business Meaning

Apex.InvestigationDocument records every identity verification document submitted as part of a Sketch CIP (Customer Identification Program) investigation during the Apex account onboarding process. When a customer's identity cannot be automatically verified, an investigation is opened with Sketch (the identity verification provider), and the customer must submit supporting documents. Each row represents one document within one investigation snapshot.

This table exists to maintain an audit trail of all documents submitted for identity verification, which is a regulatory requirement under the USA PATRIOT Act and FINRA KYC (Know Your Customer) rules. The clearing house (Apex) and the introducing broker must be able to demonstrate what documents were reviewed and when during the CIP process.

Data is created through Apex.SaveInvestigationDocument when the application receives document submission events from the Sketch investigation workflow. Documents are retrieved by Apex.GetInvestigationDocuments using GCID+SketchID to get all documents for a specific investigation. Apex.DeleteInvestigationDocuments removes all documents for a customer (used during account cleanup/closure).

---

## 2. Business Logic

### 2.1 Investigation Document Lifecycle

**What**: Documents are accumulated per investigation (SketchID) and per snapshot (SnapID), building a complete evidence record for CIP compliance.

**Columns/Parameters Involved**: `GCID`, `SketchID`, `SnapID`, `DocumentID`, `DocumentTypeID`

**Rules**:
- Multiple documents can exist per customer (GCID) and per investigation (SketchID)
- Each SnapID represents a point-in-time snapshot within an investigation - a single investigation may have multiple snapshots as additional documents are submitted
- DocumentID of 0 (observed in recent data for type 10) indicates a synthetic/composite record rather than an individual uploaded document
- DocumentTypeID 10 (ALL_PASSING_CIP_RESULTS) is the most common type, representing a composite confirmation that all CIP checks passed

### 2.2 Document Type Distribution Pattern

**What**: The distribution reveals the typical CIP investigation outcome - most records are auto-generated passing results, with smaller numbers of actual document uploads.

**Columns/Parameters Involved**: `DocumentTypeID`

**Rules**:
- Type 10 ALL_PASSING_CIP_RESULTS (32,692 records, 74%) dominates - created automatically when CIP checks pass
- Type 1 DRIVERS_LICENSE (6,273 records, 14%) is the most common actual document submitted
- Type 8 OTHER_GOVERNMENT_ID (1,845 records, 4%) for alternative identification
- Type 2 STATE_ID_CARD (1,585 records, 4%) for state-issued non-driver IDs
- Type 5 SSN_CARD (941 records, 2%) for Social Security verification
- Type 3 PASSPORT (615 records, 1%) for passport submissions

---

## 3. Data Overview

| ID | GCID | SketchID | DocumentTypeID | DocumentID | Meaning |
|----|------|----------|----------------|------------|---------|
| 45002 | 16482263 | F649CF0D-... | 10 | 0 | Automatic CIP passing result record. DocumentID=0 indicates this is a system-generated composite record, not a user-uploaded document. The most common pattern - identity verification passed all checks. |
| (earlier) | (varies) | (varies) | 1 | (non-zero) | A driver's license was submitted as part of a CIP investigation where automatic verification failed and manual document review was needed. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Used only for row identification - not referenced by other tables. |
| 2 | GCID | int | NO | - | CODE-BACKED | Global Customer ID identifying the customer whose identity is being investigated. Indexed (NC_InvestigationDocument_GCID) for fast lookup. Used with SketchID as the compound lookup key in GetInvestigationDocuments. DeleteInvestigationDocuments removes all documents by GCID. |
| 3 | SketchID | uniqueidentifier | NO | - | CODE-BACKED | The unique identifier of the Sketch identity verification investigation. A GUID assigned by the Sketch CIP provider. Each investigation may have multiple documents and multiple snapshots. Indexed (NC_InvestigationDocument_SketchID) for lookup. Used with GCID as the compound lookup key in GetInvestigationDocuments. |
| 4 | SnapID | uniqueidentifier | NO | - | CODE-BACKED | The unique identifier of a snapshot within a Sketch investigation. Represents a point-in-time capture of the investigation state. Multiple documents may share the same SnapID if they were submitted together. A GUID assigned by the Sketch system. |
| 5 | DocumentID | int | YES | - | CODE-BACKED | The identifier of the specific document within the Sketch system. A value of 0 indicates a system-generated composite record (e.g., ALL_PASSING_CIP_RESULTS) rather than an individual user-uploaded document. Non-zero values reference actual document uploads in the Sketch/document storage system. |
| 6 | DocumentTypeID | int | NO | - | VERIFIED | Classification of the identity document. FK to Dictionary.DocumentType. Distribution: 10=ALL_PASSING_CIP_RESULTS (74%), 1=DRIVERS_LICENSE (14%), 8=OTHER_GOVERNMENT_ID (4%), 2=STATE_ID_CARD (4%), 5=SSN_CARD (2%), 3=PASSPORT (1%). See [Document Type](_glossary.md#document-type) for full definitions. (Dictionary.DocumentType) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DocumentTypeID | Dictionary.DocumentType | FK | Classification of the identity document submitted for CIP investigation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.SaveInvestigationDocument | @GCID, @SketchId, @SnapId | Writer | Inserts new document records during CIP investigation |
| Apex.GetInvestigationDocuments | @GCID, @SketchId | Reader | Retrieves all documents for a specific customer+investigation |
| Apex.DeleteInvestigationDocuments | @GCID | Deleter | Removes all investigation documents for a customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.InvestigationDocument (table)
└── Dictionary.DocumentType (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.DocumentType | Table | FK target for DocumentTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.SaveInvestigationDocument | Stored Procedure | Writer - inserts document records |
| Apex.GetInvestigationDocuments | Stored Procedure | Reader - retrieves by GCID+SketchID |
| Apex.DeleteInvestigationDocuments | Stored Procedure | Deleter - removes all by GCID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_InvestigationDocument | CLUSTERED PK | ID ASC | - | - | Active |
| NC_InvestigationDocument_GCID | NONCLUSTERED | GCID ASC | - | - | Active |
| NC_InvestigationDocument_SketchID | NONCLUSTERED | SketchID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_InvestigationDocument | PRIMARY KEY | Clustered on ID |
| FK_InvestigationDocument_DocumentType | FOREIGN KEY | DocumentTypeID -> Dictionary.DocumentType(DocumentTypeID) |

---

## 8. Sample Queries

### 8.1 Get all investigation documents for a customer with type names

```sql
SELECT d.ID, d.GCID, d.SketchID, d.SnapID, d.DocumentID,
       d.DocumentTypeID, dt.Name AS DocumentTypeName
FROM Apex.InvestigationDocument d WITH (NOLOCK)
INNER JOIN Dictionary.DocumentType dt WITH (NOLOCK) ON dt.DocumentTypeID = d.DocumentTypeID
WHERE d.GCID = 16482263
ORDER BY d.ID DESC;
```

### 8.2 Count documents per type across all investigations

```sql
SELECT dt.Name AS DocumentType, COUNT(*) AS DocumentCount
FROM Apex.InvestigationDocument d WITH (NOLOCK)
INNER JOIN Dictionary.DocumentType dt WITH (NOLOCK) ON dt.DocumentTypeID = d.DocumentTypeID
GROUP BY dt.Name
ORDER BY DocumentCount DESC;
```

### 8.3 Find customers with multiple investigation snapshots

```sql
SELECT GCID, SketchID, COUNT(DISTINCT SnapID) AS SnapshotCount, COUNT(*) AS TotalDocs
FROM Apex.InvestigationDocument WITH (NOLOCK)
GROUP BY GCID, SketchID
HAVING COUNT(DISTINCT SnapID) > 1
ORDER BY SnapshotCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.InvestigationDocument | Type: Table | Source: USABroker/Apex/Tables/Apex.InvestigationDocument.sql*
