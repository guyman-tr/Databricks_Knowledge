# BackOffice.DocumentAuthenticationReasons

> Records the authentication outcome reasons for each KYC document by verification type (POI/POA/Selfie), storing the results returned by automated verification systems like Au10tix. 932,866 rows covering 886,923 documents; 89.7% have ReasonID=0 (Ok - document passed).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | (DocumentID, ReasonID, TypeID) - NC PK; CLUSTERED on DocumentID |
| **Partition** | No (stored ON [MAIN] filegroup) |
| **Indexes** | 2 active (1 NC PK on 3 columns + 1 CLUSTERED on DocumentID) |

---

## 1. Business Meaning

BackOffice.DocumentAuthenticationReasons stores the authentication outcome for each KYC document upload. When a customer's Proof of Identity, Proof of Address, or Selfie/Liveliness document is processed by the verification engine (typically Au10tix), the system records one or more reason codes explaining the authentication result. Each row represents one outcome reason for one document under one verification type.

The dominant outcome is ReasonID=0 ("Ok") - 836,756 rows (89.7%) - meaning the document passed authentication. When documents fail, the reason codes identify specific issues: expired document, name mismatch, forged document, face not detected, address mismatch, etc. Since documents may have multiple concurrent reasons (e.g., "Face Was Not Detected" + "Expired Document"), the PK includes all three columns.

932,866 rows across 886,923 distinct documents as of 2026-03-17. TypeID distribution: POI (1) dominates at 81.1%, POA (2) at 17.7%, Selfie/Liveliness types at ~1.2%.

The write lifecycle: SetDocumentAuthenticationReasons replaces all reasons for a document atomically (DELETE existing rows, INSERT new set via STRING_SPLIT on comma-separated reason IDs). GetDocument and GetAllUserDocuments join this table to surface the reasons in BackOffice document views. The JUNKYulia0325-tagged functions and procedure are deprecated.

Feature created for COMOP-391/468 (March 2020 - "Adding reason column to BO document section") with selfie support added April 2020.

---

## 2. Business Logic

### 2.1 Authentication Result Recording via Delete-Replace Pattern

**What**: SetDocumentAuthenticationReasons replaces all reasons for a document in one atomic operation.

**Columns Involved**: `DocumentID`, `ReasonID`, `TypeID`

**Rules**:
- SetDocumentAuthenticationReasons(@documentId, @reasonId [comma-separated], @typeID [default=1]):
  1. DELETE all existing rows WHERE DocumentID=@documentId.
  2. INSERT one row per value from STRING_SPLIT(@reasonId, ','), each with the same @documentId and @typeID.
- A document may receive multiple reason codes simultaneously (e.g., Au10tix returns "Face Not Detected" + "Name Mismatch").
- @typeID defaults to 1 (POI). Selfie/Liveliness checks pass typeID=3/4/5 explicitly.
- The delete-replace ensures stale reasons do not accumulate across re-evaluations.
- ReasonID=0 ("Ok") means the document passed all checks for that TypeID.

---

## 3. Data Overview

932,866 rows across 886,923 documents as of 2026-03-17.

**TypeID distribution**:

| TypeID | Type | Rows | Pct |
|--------|------|------|-----|
| 1 | POI (Proof of Identity) | 757,014 | 81.1% |
| 2 | POA (Proof of Address) | 164,712 | 17.7% |
| 4 | SelfieLiveliness | 5,769 | 0.6% |
| 3 | Selfie | 4,838 | 0.5% |
| 5 | SelfieMotion | 533 | 0.06% |

**Top ReasonID distribution**:

| ReasonID | Reason | Rows | Pct |
|---------|--------|------|-----|
| 0 | Ok | 836,756 | 89.7% |
| 40 | Document Issue Date Not Present | 41,009 | 4.4% |
| 10 | Document Type Not Accepted By Etoro | 34,251 | 3.7% |
| 46 | Match | 5,195 | 0.6% |
| 53 | Missing Address Details | 3,248 | 0.3% |
| 3 | Name Mismatch | 2,063 | 0.2% |
| 47 | Faces Do Not Match | 1,947 | 0.2% |
| 1 | Expired Document | 1,691 | 0.2% |
| 48 | Indecisive | 1,565 | 0.2% |
| 32 | Face Was Not Detected | 1,138 | 0.1% |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentID | int | NO | - | VERIFIED | The KYC document being authenticated. Implicit FK to BackOffice.CustomerDocument(DocumentID) - no declared FK constraint. CLUSTERED INDEX leading key - physical storage order is by DocumentID for efficient document-level lookups. Part of NC PK. 886,923 distinct values. |
| 2 | ReasonID | int | NO | - | VERIFIED | Authentication outcome reason code. FK (WITH CHECK) to Dictionary.AuthenticationReason(ReasonID). 107 possible values (0-107 with gaps): 0=Ok (document passed), 1=Expired Document, 3=Name Mismatch, 4=Forged Document, 5=Multipage Document Do Not Match, 6=Not Authentic, 10=Document Type Not Accepted By Etoro, 32=Face Was Not Detected, 34=Address Mismatch, 40=Document Issue Date Not Present, 46=Match (face match check for selfie), 47=Faces Do Not Match, 48=Indecisive, 52=Forged Selfie, 53=Missing Address Details, 80-84=Not Authentic subtypes, 85-90=Bad Quality subtypes, 101=Not Authentic - Inconsistent POA, 103=Fake Webcam, 105=Liveliness Not Detected, 106=Spoofing. Part of NC PK. |
| 3 | TypeID | int | NO | - | VERIFIED | The verification type under which this reason was generated. FK (WITH CHECK) to Dictionary.DocumentAutheticationType(TypeID). Values: 1=POI (81.1%), 2=POA (17.7%), 3=Selfie (0.5%), 4=SelfieLiveliness (0.6%), 5=SelfieMotion (0.06%). Note: "DocumentAutheticationType" has a typo in the dictionary table name (Authe_tic_ation). Default in SetDocumentAuthenticationReasons: 1 (POI). Part of NC PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ReasonID | Dictionary.AuthenticationReason | FK (WITH CHECK) | 107 authentication outcome reason codes |
| TypeID | Dictionary.DocumentAutheticationType | FK (WITH CHECK) | 5 verification types (POI/POA/Selfie/Liveliness/Motion) |
| DocumentID | BackOffice.CustomerDocument | Implicit | Parent document record (no FK constraint) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.SetDocumentAuthenticationReasons | DocumentID, ReasonID, TypeID | WRITER (delete-replace) | Primary write path - replaces all reasons for a document |
| BackOffice.GetDocument | DocumentID | READER | Returns document details with authentication reasons |
| BackOffice.GetAllUserDocuments | DocumentID | READER | Returns all documents for a customer with reasons |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.DocumentAuthenticationReasons (table)
- FK targets:
  |- Dictionary.AuthenticationReason (table)
  |- Dictionary.DocumentAutheticationType (table)
- Implicit: BackOffice.CustomerDocument (DocumentID)
- Written by: BackOffice.SetDocumentAuthenticationReasons
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AuthenticationReason | Table | FK on ReasonID |
| Dictionary.DocumentAutheticationType | Table | FK on TypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.SetDocumentAuthenticationReasons | Procedure | WRITER - delete-replace via STRING_SPLIT |
| BackOffice.GetDocument | Procedure | READER |
| BackOffice.GetAllUserDocuments | Procedure | READER |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOffice_DocumentAuthenticationReasons | NC PK | DocumentID ASC, ReasonID ASC, TypeID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |
| Idx_BackOffice_DocumentAuthenticationReasons_DocumentID | CLUSTERED | DocumentID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |

The CLUSTERED INDEX on DocumentID (separate from the NC PK) provides efficient row access by document - the dominant query pattern. The NC PK enforces uniqueness of (DocumentID, ReasonID, TypeID) while the clustered index drives physical storage.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BackOffice_DocumentAuthenticationReasons | PK | Uniqueness of (DocumentID, ReasonID, TypeID) |
| FK_BackOffice_DocumentAuthenticationReasons_AuthenticationReasonID | FK (WITH CHECK) | ReasonID -> Dictionary.AuthenticationReason(ReasonID) |
| FK_BackOffice_DocumentAuthneticationReasons_TypeID | FK (WITH CHECK) | TypeID -> Dictionary.DocumentAutheticationType(TypeID) (note typo in FK name: "Authe_n_ticationReasons") |

---

## 8. Sample Queries

### 8.1 Get authentication reasons for a specific document
```sql
SELECT dar.TypeID, dt.Type AS VerificationType,
       dar.ReasonID, ar.Reason
FROM BackOffice.DocumentAuthenticationReasons dar WITH (NOLOCK)
JOIN Dictionary.AuthenticationReason ar WITH (NOLOCK)
    ON ar.ReasonID = dar.ReasonID
JOIN Dictionary.DocumentAutheticationType dt WITH (NOLOCK)
    ON dt.TypeID = dar.TypeID
WHERE dar.DocumentID = @DocumentID
ORDER BY dar.TypeID, dar.ReasonID
```

### 8.2 Count failed documents by reason (last 30 days via CustomerDocument join)
```sql
SELECT dar.ReasonID, ar.Reason,
       COUNT(DISTINCT dar.DocumentID) AS FailedDocuments
FROM BackOffice.DocumentAuthenticationReasons dar WITH (NOLOCK)
JOIN Dictionary.AuthenticationReason ar WITH (NOLOCK)
    ON ar.ReasonID = dar.ReasonID
WHERE dar.ReasonID <> 0  -- exclude Ok
GROUP BY dar.ReasonID, ar.Reason
ORDER BY FailedDocuments DESC
```

---

## 9. Atlassian Knowledge Sources

SetDocumentAuthenticationReasons comments cite COMOP-391/468 (March 2020, "Adding reason column to BO document section") as the origin and April 2020 ("DocApi Support for Selfie Reasons SP") for selfie type support.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.DocumentAuthenticationReasons | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.DocumentAuthenticationReasons.sql*
