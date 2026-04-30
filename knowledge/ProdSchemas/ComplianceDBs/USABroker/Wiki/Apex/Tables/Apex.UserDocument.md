# Apex.UserDocument

> Tracks documents uploaded by users during the Apex account lifecycle, linking each document to the customer, a storage snapshot, and a document type classification.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) + 1 nonclustered (GCID) |

---

## 1. Business Meaning

Apex.UserDocument records every document uploaded by a customer during the Apex brokerage account lifecycle. Unlike InvestigationDocument (which tracks CIP/identity verification documents from Sketch), this table tracks user-submitted documents such as signature images, ID copies, IRA deposit slips, account transfer forms, and affiliated approval letters.

Documents are stored externally (referenced by SnapID and DocumentID) with metadata tracked here. Data is written by Apex.SaveUserDocument and read by Apex.GetUserDocuments. Deletion by Apex.DeleteUserDocuments.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple document registry linking customers to their uploaded files.

---

## 3. Data Overview

| ID | GCID | UserDocumentTypeID | Meaning |
|----|------|--------------------|---------|
| 1728 | 46229773 | 2 (ID_DOCUMENT) | Customer uploaded a copy of their identification document. |
| 1727 | 47547564 | 5 (AFFILIATED_APPROVAL) | Pre-approval letter from employer for broker-dealer affiliated customer. |
| 1726 | 47530655 | 5 (AFFILIATED_APPROVAL) | Another affiliated approval document. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. ~1,728 documents to date. |
| 2 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Indexed for lookup. Multiple documents per customer possible. |
| 3 | SnapID | uniqueidentifier | NO | - | CODE-BACKED | GUID referencing the document storage snapshot. Links to the external document storage system. |
| 4 | DocumentID | int | NO | - | CODE-BACKED | Document identifier within the storage system. Combined with SnapID to locate the actual file. |
| 5 | UserDocumentTypeID | int | NO | - | VERIFIED | Classification of the uploaded document. FK to Dictionary.UserDocumentType: 1=SIGNATURE_IMAGE, 2=ID_DOCUMENT, 3=IRA_DEPOSIT_SLIP, 4=ACCOUNT_TRANSFER_FORM, 5=AFFILIATED_APPROVAL, 6=OTHER. See [User Document Type](_glossary.md#user-document-type). (Dictionary.UserDocumentType) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UserDocumentTypeID | Dictionary.UserDocumentType | FK | Document type classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.SaveUserDocument | all params | Writer | Inserts document records |
| Apex.GetUserDocuments | @GCID | Reader | Retrieves documents by customer |
| Apex.DeleteUserDocuments | @GCID | Deleter | Removes all documents for a customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.UserDocument (table)
└── Dictionary.UserDocumentType (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.UserDocumentType | Table | FK for UserDocumentTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.SaveUserDocument | Stored Procedure | Writer |
| Apex.GetUserDocuments | Stored Procedure | Reader |
| Apex.DeleteUserDocuments | Stored Procedure | Deleter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_UserDocument | CLUSTERED PK | ID ASC | - | - | Active |
| ix_UserDocument_GCID | NONCLUSTERED | GCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_UserDocument | PRIMARY KEY | Clustered on ID |
| FK_UserDocument_UserDocumentType | FOREIGN KEY | UserDocumentTypeID -> Dictionary.UserDocumentType(UserDocumentTypeID) |

---

## 8. Sample Queries

### 8.1 Get all documents for a customer with type names

```sql
SELECT d.ID, d.GCID, d.SnapID, d.DocumentID, dt.Name AS DocumentType
FROM Apex.UserDocument d WITH (NOLOCK)
INNER JOIN Dictionary.UserDocumentType dt WITH (NOLOCK) ON dt.UserDocumentTypeID = d.UserDocumentTypeID
WHERE d.GCID = 46229773;
```

### 8.2 Count documents by type

```sql
SELECT dt.Name AS DocumentType, COUNT(*) AS DocCount
FROM Apex.UserDocument d WITH (NOLOCK)
INNER JOIN Dictionary.UserDocumentType dt WITH (NOLOCK) ON dt.UserDocumentTypeID = d.UserDocumentTypeID
GROUP BY dt.Name ORDER BY DocCount DESC;
```

### 8.3 Find customers with affiliated approval documents

```sql
SELECT DISTINCT d.GCID
FROM Apex.UserDocument d WITH (NOLOCK)
WHERE d.UserDocumentTypeID = 5;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.UserDocument | Type: Table | Source: USABroker/Apex/Tables/Apex.UserDocument.sql*
